import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:nix/src/config/nix_config.dart';
import 'package:nix/src/nix/nix_runner.dart';

class BuildCommand extends Command<int> {
  @override
  final String name = 'build';

  @override
  final String description =
      'Build inside a reproducible Nix environment (uses flake.lock by default).';

  BuildCommand() {
    argParser
      ..addFlag(
        'refresh',
        help:
            'Run `nix flake update` first to use the latest nixpkgs '
            '(less reproducible; flake.lock will be modified)',
      )
      ..addOption('profile', abbr: 'P', help: 'Use a named build profile');
  }

  @override
  String get invocation => '${runner!.executableName} build [platform]';

  @override
  Future<int> run() async {
    final refresh = argResults!['refresh'] as bool;
    final profileName = argResults!['profile'] as String?;
    final verbose = globalResults!['verbose'] as bool;
    final config = NixConfig.load();

    // Default to host OS when no platform given.
    final target = argResults!.rest.isEmpty
        ? _defaultPlatform(config)
        : argResults!.rest.first;

    if (target == null) {
      stderr.writeln(
        'Error: platform argument required (no platforms configured in nix.yaml).',
      );
      printUsage();
      return 1;
    }

    final resolvedName = profileName ?? target;
    final platform =
        config.platformFor(resolvedName) ?? config.platforms[target];
    if (platform == null) {
      stderr.writeln('Unknown platform or profile: $resolvedName');
      stderr.writeln('Platforms: ${config.platformNames.join(', ')}');
      if (config.profiles.isNotEmpty) {
        stderr.writeln('Profiles: ${config.profiles.keys.join(', ')}');
      }
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
      return 1;
    }

    final nix = NixRunner(verbose: verbose);
    final sdkPath = sdkDir.absolute.path;

    print(
      'Building ${platform.name} '
      '(${refresh ? "latest nixpkgs" : "pinned flake.lock"})...',
    );
    print('Command: ${platform.buildCommand}');

    final exitCode = await nix.runInShell(
      flakePath: config.flakeRef,
      shellName: platform.shell,
      refresh: refresh,
      sdkPath: sdkPath,
      command: 'flutter pub get && ${platform.buildCommand}',
    );

    if (exitCode == 0) {
      print('Build complete: ${platform.buildOutput}');
    } else {
      stderr.writeln('Build failed with exit code $exitCode');
    }
    return exitCode;
  }

  String? _defaultPlatform(NixConfig config) {
    final preferred = Platform.isMacOS ? 'macos' : 'linux';
    if (config.platforms.containsKey(preferred)) return preferred;
    return config.platformNames.isEmpty ? null : config.platformNames.first;
  }
}
