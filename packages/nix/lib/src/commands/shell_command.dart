import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:nix/src/config/nix_config.dart';
import 'package:nix/src/nix/nix_runner.dart';

class ShellCommand extends Command<int> {
  @override
  final String name = 'shell';

  @override
  final String description =
      'Enter an interactive Nix development shell (uses flake.lock by default).';

  ShellCommand() {
    argParser.addFlag(
      'refresh',
      help:
          'Run `nix flake update` first to use the latest nixpkgs '
          '(less reproducible; flake.lock will be modified)',
    );
  }

  @override
  String get invocation => '${runner!.executableName} shell [platform]';

  @override
  Future<int> run() async {
    final refresh = argResults!['refresh'] as bool;
    final verbose = globalResults!['verbose'] as bool;
    final config = NixConfig.load();

    // Default platform is host OS when not specified.
    final platformName = argResults!.rest.isEmpty
        ? _defaultPlatform(config)
        : argResults!.rest.first;

    if (platformName == null) {
      stderr.writeln(
        'Error: platform argument required (no platforms configured in nix.yaml).',
      );
      printUsage();
      return 1;
    }

    final platform = config.platforms[platformName];
    if (platform == null) {
      stderr.writeln('Unknown platform: $platformName');
      stderr.writeln('Available: ${config.platformNames.join(', ')}');
      return 1;
    }

    final sdkDir = Directory('.flutter-sdk/flutter');
    if (!sdkDir.existsSync()) {
      stderr.writeln('Flutter SDK not found. Run: nix_dart setup');
      return 1;
    }

    final flakeDir = config.normalizedFlakePath;
    if (!Directory(flakeDir).existsSync()) {
      stderr.writeln('Flake directory not found: $flakeDir');
      stderr.writeln('Run: nix_dart init $platformName');
      return 1;
    }

    final nix = NixRunner(verbose: verbose);
    print(
      'Entering $platformName shell '
      '(${refresh ? "latest nixpkgs" : "pinned flake.lock"})...',
    );

    return nix.enterShell(
      flakePath: config.flakeRef,
      shellName: platform.shell,
      refresh: refresh,
      sdkPath: sdkDir.absolute.path,
    );
  }

  /// Pick a sensible default platform based on the host OS.
  ///
  /// On Windows, prefer 'linux' or 'web' since builds run inside WSL/Nix.
  String? _defaultPlatform(NixConfig config) {
    final preferred = Platform.isMacOS
        ? 'macos'
        : Platform.isWindows
            ? 'linux'
            : 'linux';
    if (config.platforms.containsKey(preferred)) return preferred;
    // On Windows, also try 'web' as a second choice.
    if (Platform.isWindows && config.platforms.containsKey('web')) return 'web';
    return config.platformNames.isEmpty ? null : config.platformNames.first;
  }
}
