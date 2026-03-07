import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;
import 'package:nix/src/commands/sync_command.dart';
import 'package:nix/src/config/nix_config.dart';
import 'package:nix/src/nix/nix_runner.dart';
import 'package:nix/src/templates/config_template.dart';
import 'package:nix/src/templates/flake_template.dart';

const _flakeCandidateMaxDepth = 4;

String detectExistingFlakePath([Directory? root]) {
  final searchRoot = (root ?? Directory.current).absolute;
  final candidates = <String>{'nix', ...findFlakeCandidates(searchRoot)};
  final existing =
      candidates
          .where(
            (candidate) => File(p.join(searchRoot.path, candidate, 'flake.nix'))
                .existsSync(),
          )
          .toList()
        ..sort((left, right) {
          final lengthCompare = left.length.compareTo(right.length);
          return lengthCompare != 0 ? lengthCompare : left.compareTo(right);
        });

  if (existing.isEmpty) {
    return 'nix';
  }

  return existing.first;
}

Iterable<String> findFlakeCandidates(Directory root) sync* {
  Iterable<String> visit(Directory directory, int depth) sync* {
    if (depth < 0) return;

    final flakeFile = File(p.join(directory.path, 'nix', 'flake.nix'));
    if (flakeFile.existsSync()) {
      yield p.relative(p.join(directory.path, 'nix'), from: root.path).replaceAll(r'\', '/');
    }

    if (depth == 0) return;

    for (final entity in directory.listSync(followLinks: false)) {
      if (entity is! Directory) continue;
      final name = p.basename(entity.path);
      if (name.startsWith('.') ||
          name == 'build' ||
          name == 'ios' ||
          name == 'macos' ||
          name == 'android' ||
          name == 'web' ||
          name == 'linux' ||
          name == '.flutter-sdk' ||
          name == '.android-sdk') {
        continue;
      }
      yield* visit(entity, depth - 1);
    }
  }

  yield* visit(root, _flakeCandidateMaxDepth);
}

class InitCommand extends Command<int> {
  @override
  final String name = 'init';

  @override
  final String description = 'Initialize Nix reproducible build configuration.';

  InitCommand() {
    argParser
      ..addFlag('force', abbr: 'f', help: 'Overwrite existing files')
      ..addFlag(
        'from-existing',
        help:
            'Generate nix.yaml from existing .env files and a vendored toolkit',
      )
      ..addOption(
        'flake-dir',
        help: 'Path to the Nix flake directory relative to the project root',
      );
  }

  @override
  String get invocation =>
      '${runner!.executableName} init [macos] [linux] [android] [web]';

  @override
  Future<int> run() async {
    final force = argResults!['force'] as bool;
    final fromExisting = argResults!['from-existing'] as bool;
    final verbose = globalResults!['verbose'] as bool;
    final projectName = p.basename(Directory.current.path);

    if (fromExisting) {
      return _initFromExisting(projectName, force, verbose);
    }

    final platforms = argResults!.rest.isEmpty
        ? <String>[Platform.isMacOS ? 'macos' : 'linux']
        : argResults!.rest;
    final flakePath = _requestedFlakePath() ?? 'nix';
    var wrote = 0;

    final configFile = File('nix.yaml');
    if (configFile.existsSync() && !force) {
      print('nix.yaml already exists (use --force to overwrite)');
    } else {
      configFile.writeAsStringSync(
        generateConfig(
          projectName: projectName,
          platforms: platforms,
          flakePath: flakePath,
        ),
      );
      print('Created nix.yaml');
      wrote++;
      writeEnvFiles(NixConfig.load());
    }

    final flakeDir = Directory(flakePath);
    if (!flakeDir.existsSync()) {
      flakeDir.createSync(recursive: true);
      File(
        p.join(flakeDir.path, 'flake.nix'),
      ).writeAsStringSync(flakeTemplate.trimLeft());
      print('Created ${p.join(flakePath, 'flake.nix')}');
      wrote++;
    }

    final lockFile = File(p.join(flakePath, 'flake.lock'));
    if (!lockFile.existsSync()) {
      final nix = NixRunner(verbose: verbose);
      if (await nix.isInstalled()) {
        print('Pinning $flakePath/flake.lock...');
        final result = await nix.pinFlake(flakePath);
        if (result.exitCode == 0) {
          print('Created ${p.join(flakePath, 'flake.lock')}');
          wrote++;
        } else {
          stderr.writeln('Failed to pin flake: ${result.stderr}');
          stderr.writeln('You can pin manually later with: nix_dart pin');
        }
      } else {
        print('nix not found: skipping flake pinning.');
        print('Install Nix, then run: nix_dart pin');
      }
    }

    print('');
    if (wrote > 0) {
      print('Initialized $wrote file(s). Next steps:');
      print('  nix_dart setup');
      print('  nix_dart shell ${Platform.isMacOS ? 'macos' : 'linux'}');
    } else {
      print('Nothing to do (all files already exist).');
    }
    return 0;
  }

  Future<int> _initFromExisting(
    String projectName,
    bool force,
    bool verbose,
  ) async {
    var flutterVersion = '3.38.2';
    var flutterChannel = 'stable';
    var checksumMacosX64 = '';
    var checksumMacosArm64 = '';
    var checksumLinuxX64 = '';
    var checksumLinuxArm64 = '';

    final flutterEnv = File('flutter_version.env');
    if (flutterEnv.existsSync()) {
      for (final line in flutterEnv.readAsLinesSync()) {
        _parseEnvLine(line, 'FLUTTER_VERSION', (v) => flutterVersion = v);
        _parseEnvLine(line, 'FLUTTER_CHANNEL', (v) => flutterChannel = v);
        _parseEnvLine(line, 'FLUTTER_SHA256_X64', (v) => checksumMacosX64 = v);
        _parseEnvLine(
          line,
          'FLUTTER_SHA256_ARM64',
          (v) => checksumMacosArm64 = v,
        );
        _parseEnvLine(
          line,
          'FLUTTER_SHA256_LINUX_X64',
          (v) => checksumLinuxX64 = v,
        );
        _parseEnvLine(
          line,
          'FLUTTER_SHA256_LINUX_ARM64',
          (v) => checksumLinuxArm64 = v,
        );
      }
      print('Found flutter_version.env (version: $flutterVersion)');
    }

    var cmdlineToolsBuild = '14742923';
    var cmdlineToolsSha256Linux = '';
    var cmdlineToolsSha256Macos = '';
    var platformVersion = 'android-34';
    var buildToolsVersion = '35.0.0';
    var ndkVersion = '28.2.13676358';

    final androidEnv = File('android_sdk_version.env');
    if (androidEnv.existsSync()) {
      for (final line in androidEnv.readAsLinesSync()) {
        _parseEnvLine(
          line,
          'ANDROID_CMDLINE_TOOLS_BUILD',
          (v) => cmdlineToolsBuild = v,
        );
        _parseEnvLine(
          line,
          'ANDROID_CMDLINE_TOOLS_SHA256_LINUX',
          (v) => cmdlineToolsSha256Linux = v,
        );
        _parseEnvLine(
          line,
          'ANDROID_CMDLINE_TOOLS_SHA256',
          (v) => cmdlineToolsSha256Macos = v,
        );
        _parseEnvLine(
          line,
          'ANDROID_PLATFORM_VERSION',
          (v) => platformVersion = v,
        );
        _parseEnvLine(
          line,
          'ANDROID_BUILD_TOOLS_VERSION',
          (v) => buildToolsVersion = v,
        );
        _parseEnvLine(line, 'ANDROID_NDK_VERSION', (v) => ndkVersion = v);
      }
      print('Found android_sdk_version.env');
    }

    final flakePath = _requestedFlakePath() ?? _detectFlakePath();
    final platforms = _detectPlatforms(flakePath);

    final configFile = File('nix.yaml');
    if (configFile.existsSync() && !force) {
      print('nix.yaml already exists (use --force to overwrite)');
      return 0;
    }

    configFile.writeAsStringSync(
      generateConfig(
        projectName: projectName,
        platforms: platforms,
        flakePath: flakePath,
        flutterVersion: flutterVersion,
        flutterChannel: flutterChannel,
        checksumMacosX64: checksumMacosX64,
        checksumMacosArm64: checksumMacosArm64,
        checksumLinuxX64: checksumLinuxX64,
        checksumLinuxArm64: checksumLinuxArm64,
        cmdlineToolsBuild: cmdlineToolsBuild,
        cmdlineToolsSha256Linux: cmdlineToolsSha256Linux,
        cmdlineToolsSha256Macos: cmdlineToolsSha256Macos,
        platformVersion: platformVersion,
        buildToolsVersion: buildToolsVersion,
        ndkVersion: ndkVersion,
      ),
    );
    print('Created nix.yaml from existing configuration.');

    final config = NixConfig.load();
    writeEnvFiles(config);

    if (verbose) {
      print('Using flake path: $flakePath');
      print('Derived toolkit root: ${config.toolkitRoot}');
    }

    print('');
    print('Your existing scripts and .env files are untouched.');
    print('Both workflows now work in parallel.');
    return 0;
  }

  String _detectFlakePath() {
    final candidates = <String>{'nix', ...findFlakeCandidates(Directory.current)};
    final existing =
        candidates
            .where(
              (candidate) => File(p.join(candidate, 'flake.nix')).existsSync(),
            )
            .toList()
          ..sort((left, right) {
            final lengthCompare = left.length.compareTo(right.length);
            return lengthCompare != 0 ? lengthCompare : left.compareTo(right);
          });

    if (existing.isEmpty) {
      return 'nix';
    }

    if (existing.length > 1) {
      print('Multiple flake directories detected, using ${existing.first}:');
      for (final candidate in existing.skip(1)) {
        print('  $candidate');
      }
    }

    return existing.first;
  }

  List<String> _detectPlatforms(String flakePath) {
    final flakeFile = File(p.join(flakePath, 'flake.nix'));
    if (!flakeFile.existsSync()) {
      return <String>[Platform.isMacOS ? 'macos' : 'linux'];
    }

    final content = flakeFile.readAsStringSync();
    final platforms = <String>[];
    if (content.contains('default =')) {
      platforms.add('macos');
    }
    if (content.contains('linux =')) {
      platforms.add('linux');
    }
    if (content.contains('android =')) {
      platforms.add('android');
    }
    if (content.contains('web =')) {
      platforms.add('web');
    }

    return platforms.isEmpty
        ? <String>[Platform.isMacOS ? 'macos' : 'linux']
        : platforms;
  }

  String? _requestedFlakePath() {
    final flakeDir = argResults!['flake-dir'] as String?;
    if (flakeDir == null || flakeDir.trim().isEmpty) {
      return null;
    }
    return flakeDir.trim();
  }

  void _parseEnvLine(String line, String key, void Function(String) setter) {
    final match = RegExp('^$key="?([^"]*)"?').firstMatch(line);
    if (match != null) setter(match.group(1)!);
  }
}
