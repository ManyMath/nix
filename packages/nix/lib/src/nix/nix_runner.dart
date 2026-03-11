import 'dart:convert';
import 'dart:io';

/// Wraps invocations of the `nix` system binary.
class NixRunner {
  final bool verbose;
  static const String _flakesProbeFlake = '''
{
  description = "nix_dart flakes probe";
  outputs = { self }: { };
}
''';

  const NixRunner({this.verbose = false});

  /// Check if `nix` is on PATH.
  Future<bool> isInstalled() async {
    try {
      final result = await Process.run('nix', ['--version']);
      return result.exitCode == 0;
    } on ProcessException {
      return false;
    }
  }

  /// Get the nix version string, or null if not installed.
  Future<String?> version() async {
    try {
      final result = await Process.run('nix', ['--version']);
      if (result.exitCode != 0) return null;
      return (result.stdout as String).trim().split('\n').first;
    } on ProcessException {
      return null;
    }
  }

  /// Parse the nix version number from the version string, e.g. "nix (Nix) 2.18.1" → [2, 18, 1].
  /// Returns null if the version cannot be parsed.
  Future<List<int>?> versionNumbers() async {
    final v = await version();
    if (v == null) return null;
    final match = RegExp(r'(\d+)\.(\d+)\.(\d+)').firstMatch(v);
    if (match == null) return null;
    return [
      int.parse(match.group(1)!),
      int.parse(match.group(2)!),
      int.parse(match.group(3)!),
    ];
  }

  /// Check whether the `nix-command` and `flakes` experimental features are enabled.
  /// Returns a [FlakesStatus] indicating which (if any) features are enabled.
  Future<FlakesStatus> checkFlakesEnabled() async {
    final probeStatus = await _probeFlakesEnabled();
    if (probeStatus != FlakesStatus.unknown) {
      return probeStatus;
    }

    return _checkConfiguredFlakesEnabled();
  }

  Future<FlakesStatus> _probeFlakesEnabled() async {
    Directory? probeDir;
    try {
      probeDir = Directory.systemTemp.createTempSync('nix_flakes_probe_');
      File('${probeDir.path}/flake.nix').writeAsStringSync(_flakesProbeFlake);

      final result = await Process.run('nix', [
        'flake',
        'metadata',
        'path:${probeDir.absolute.path}',
      ]);
      if (result.exitCode == 0) {
        return FlakesStatus.enabled;
      }
      return _classifyFlakesFailure(result.stderr as String);
    } on ProcessException {
      return FlakesStatus.unknown;
    } finally {
      if (probeDir != null && probeDir.existsSync()) {
        probeDir.deleteSync(recursive: true);
      }
    }
  }

  Future<FlakesStatus> _checkConfiguredFlakesEnabled() async {
    try {
      final result = await Process.run('nix', [
        'config',
        'show',
        'experimental-features',
      ]);
      if (result.exitCode != 0) return FlakesStatus.unknown;
      final features = (result.stdout as String).trim();
      if (features.isEmpty) return FlakesStatus.unknown;
      final hasNixCommand = features.contains('nix-command');
      final hasFlakes = features.contains('flakes');
      if (hasNixCommand && hasFlakes) return FlakesStatus.enabled;
      if (hasFlakes) return FlakesStatus.missingNixCommand;
      if (hasNixCommand) return FlakesStatus.missingFlakes;
      return FlakesStatus.disabled;
    } on ProcessException {
      return FlakesStatus.unknown;
    }
  }

  FlakesStatus _classifyFlakesFailure(String stderr) {
    final message = stderr.toLowerCase();
    final mentionsExperimental =
        message.contains('experimental') && message.contains('feature');
    if (!mentionsExperimental) {
      return FlakesStatus.unknown;
    }

    final mentionsNixCommand = message.contains('nix-command');
    final mentionsFlakes = message.contains('flakes');
    if (mentionsNixCommand && mentionsFlakes) return FlakesStatus.disabled;
    if (mentionsFlakes) return FlakesStatus.missingNixCommand;
    if (mentionsNixCommand) return FlakesStatus.missingFlakes;
    return FlakesStatus.disabled;
  }

  /// Return the age in days of the nixpkgs input in [lockPath], or -1 on error.
  ///
  /// Reads `nodes.nixpkgs.locked.lastModified` (a Unix timestamp) from the
  /// JSON flake.lock file. Warns when the lock is older than [warnAfterDays].
  int flakeLockAgeDays(String lockPath) {
    try {
      final content = File(lockPath).readAsStringSync();
      final json = jsonDecode(content) as Map<String, dynamic>;
      final nodes = json['nodes'] as Map<String, dynamic>?;
      if (nodes == null) return -1;
      // The nixpkgs input may be named 'nixpkgs', 'nixpkgs-linux', etc.
      // Find the first node with a 'lastModified' field.
      for (final node in nodes.values) {
        final locked =
            (node as Map<String, dynamic>)['locked'] as Map<String, dynamic>?;
        if (locked == null) continue;
        final ts = locked['lastModified'];
        if (ts is int) {
          final lockTime = DateTime.fromMillisecondsSinceEpoch(
            ts * 1000,
            isUtc: true,
          );
          return DateTime.now().toUtc().difference(lockTime).inDays;
        }
      }
      return -1;
    } catch (_) {
      return -1;
    }
  }

  /// Check whether [lockPath] is tracked by git.
  /// Returns true if tracked, false if untracked or not in a git repo.
  Future<bool> isTrackedByGit(String lockPath) async {
    try {
      final result = await Process.run('git', [
        'ls-files',
        '--error-unmatch',
        lockPath,
      ]);
      return result.exitCode == 0;
    } on ProcessException {
      return false;
    }
  }

  /// Update flake.lock by running `nix flake update` inside [flakeDir].
  Future<ProcessResult> pinFlake(String flakeDir) async {
    final absoluteFlakeDir = Directory(flakeDir).absolute.path;
    _log('nix flake update --flake path:$absoluteFlakeDir');
    return Process.run('nix', [
      'flake',
      'update',
      '--flake',
      'path:$absoluteFlakeDir',
    ]);
  }

  /// Build the shell ref for nix develop: `$flakePath#$shellName`, or just
  /// `$flakePath` when [shellName] is empty or 'default' (uses the default devShell).
  String _shellRef(String flakePath, String shellName) =>
      (shellName.isEmpty || shellName == 'default')
          ? flakePath
          : '$flakePath#$shellName';

  /// Enter an interactive nix development shell.
  ///
  /// Sets PROJECT_ROOT so the flake.nix shellHook can find the Flutter SDK.
  /// [refresh] uses the latest nixpkgs instead of the pinned flake.lock.
  Future<int> enterShell({
    required String flakePath,
    required String shellName,
    bool refresh = false,
    String? sdkPath,
  }) async {
    final args = ['develop', _shellRef(flakePath, shellName)];
    if (refresh) args.add('--refresh');

    _log('nix ${args.join(' ')}');

    final env = Map<String, String>.from(Platform.environment);
    env['PROJECT_ROOT'] = Directory.current.absolute.path;
    if (sdkPath != null) {
      env['FLUTTER_ROOT'] = sdkPath;
    }

    final process = await Process.start(
      'nix',
      args,
      mode: ProcessStartMode.inheritStdio,
      environment: env,
    );
    return process.exitCode;
  }

  /// Run a command inside a nix shell (non-interactive, for builds).
  ///
  /// [refresh] uses the latest nixpkgs instead of the pinned flake.lock.
  Future<int> runInShell({
    required String flakePath,
    required String shellName,
    bool refresh = false,
    String? sdkPath,
    required String command,
  }) async {
    final args = ['develop', _shellRef(flakePath, shellName)];
    if (refresh) args.add('--refresh');

    final sdkDir =
        sdkPath ?? '${Directory.current.absolute.path}/.flutter-sdk/flutter';
    final innerCmd = [
      'export PATH="$sdkDir/bin:\$PATH"',
      'export FLUTTER_ROOT="$sdkDir"',
      'export PROJECT_ROOT="${Directory.current.absolute.path}"',
      command,
    ].join('\n');

    args.addAll(['--command', 'bash', '-c', innerCmd]);
    _log('nix ${args.join(' ')}');

    final process = await Process.start(
      'nix',
      args,
      mode: ProcessStartMode.inheritStdio,
      environment: Map<String, String>.from(Platform.environment)
        ..['PROJECT_ROOT'] = Directory.current.absolute.path,
    );
    return process.exitCode;
  }

  void _log(String msg) {
    if (verbose) {
      print('  \$ $msg');
    }
  }
}

enum FlakesStatus {
  enabled,
  missingFlakes,
  missingNixCommand,
  disabled,
  unknown,
}
