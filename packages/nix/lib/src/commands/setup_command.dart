import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:nix/src/config/nix_config.dart';
import 'package:nix/src/flutter_sdk.dart';
import 'package:nix/src/nix/wsl.dart';
import 'package:nix/src/tool_scaffold.dart';

String flutterDownloadUrl({
  required String os,
  required String arch,
  required String version,
  required String channel,
}) {
  final archive = os == 'macos'
      ? 'flutter_macos${arch == 'arm64' ? '_arm64' : '_x64'}_$version-$channel.zip'
      : 'flutter_linux${arch == 'arm64' ? '_arm64' : ''}_$version-$channel.tar.xz';
  return 'https://storage.googleapis.com/flutter_infra_release/releases/'
      '$channel/$os/$archive';
}

class SetupCommand extends Command<int> {
  @override
  final String name = 'setup';

  @override
  final String description = 'Fetch Flutter SDK and platform-specific SDKs.';

  @override
  Future<int> run() async {
    final config = NixConfig.load();
    final targetPlatforms =
        argResults!.rest.isEmpty ? config.platformNames : argResults!.rest;

    print('Setting up Flutter SDK ${config.flutter.version}...');
    final flutterExitCode = await _fetchFlutter(config);
    if (flutterExitCode != 0) {
      return flutterExitCode;
    }

    for (final platformName in targetPlatforms) {
      final platform = config.platforms[platformName];
      if (platform == null) {
        stderr.writeln('Unknown platform: $platformName');
        stderr.writeln('Available: ${config.platformNames.join(', ')}');
        return 1;
      }
      if (platformName == 'android' && platform.sdk.isNotEmpty) {
        print('Setting up android SDK...');
        final androidExitCode = await _fetchAndroidSdk(config);
        if (androidExitCode != 0) {
          return androidExitCode;
        }
      }
    }

    print('Setup complete.');
    return 0;
  }

  Future<int> _fetchFlutter(NixConfig config) async {
    final installedVersion = await detectInstalledFlutterVersion();
    if (installedVersion == config.flutter.version) {
      print('  Flutter ${config.flutter.version} already present.');
      return 0;
    }

    // On Windows, fetch the Linux SDK (builds run in WSL/CI).
    // On macOS/Linux, fetch for the host OS.
    final os = Platform.isWindows
        ? 'linux'
        : (Platform.isMacOS ? 'macos' : 'linux');
    final arch = await _detectArch(os);
    final url = flutterDownloadUrl(
      os: os,
      arch: arch,
      version: config.flutter.version,
      channel: config.flutter.channel,
    );
    final archivePath = os == 'macos'
        ? '.flutter-sdk/flutter.zip'
        : '.flutter-sdk/flutter.tar.xz';
    final expectedHash = os == 'macos'
        ? (arch == 'arm64'
            ? config.flutter.checksumMacosArm64
            : config.flutter.checksumMacosX64)
        : (arch == 'arm64'
            ? config.flutter.checksumLinuxArm64
            : config.flutter.checksumLinuxX64);
    final checksumKey = os == 'macos'
        ? (arch == 'arm64' ? 'macos_arm64' : 'macos_x64')
        : (arch == 'arm64' ? 'linux_arm64' : 'linux_x64');

    print('  Downloading Flutter ${config.flutter.version} ($checksumKey)...');
    print('  $url');

    Directory('.flutter-sdk').createSync(recursive: true);

    final downloadResult = await Process.start(
        'curl',
        [
          '-fSL',
          '-o',
          archivePath,
          url,
        ],
        mode: ProcessStartMode.inheritStdio);
    if (await downloadResult.exitCode != 0) {
      stderr.writeln('  Failed to download Flutter SDK.');
      return 1;
    }

    final checksumCommand = Platform.isMacOS ? 'shasum' : 'sha256sum';
    final checksumArgs =
        Platform.isMacOS ? ['-a', '256', archivePath] : [archivePath];

    // On Windows, use certutil for checksum or fall back to WSL sha256sum.
    ProcessResult checksumResult;
    if (Platform.isWindows) {
      checksumResult = await Process.run(
          'certutil', ['-hashfile', archivePath, 'SHA256']);
      // certutil output: line 0 is header, line 1 is the hash, line 2 is status
      final lines = (checksumResult.stdout as String).trim().split('\n');
      final computedHash = lines.length > 1 ? lines[1].trim() : '';
      return _verifyAndExtract(
          config, os, archivePath, expectedHash, checksumKey, computedHash);
    }

    checksumResult = await Process.run(checksumCommand, checksumArgs);
    final computedHash =
        (checksumResult.stdout as String).split(RegExp(r'\s+')).first;

    return _verifyAndExtract(
        config, os, archivePath, expectedHash, checksumKey, computedHash);
  }

  Future<int> _verifyAndExtract(
    NixConfig config,
    String os,
    String archivePath,
    String expectedHash,
    String checksumKey,
    String computedHash,
  ) async {
    if (expectedHash.isNotEmpty) {
      print('  Verifying SHA-256...');
      if (computedHash != expectedHash) {
        stderr.writeln('  Checksum mismatch!');
        stderr.writeln('  Expected: $expectedHash');
        stderr.writeln('  Got:      $computedHash');
        File(archivePath).deleteSync();
        return 1;
      }
    } else {
      print('  SHA-256: $computedHash');
      print('  Add this to nix.yaml checksums.$checksumKey');
    }

    final existing = Directory('.flutter-sdk/flutter');
    if (existing.existsSync()) {
      existing.deleteSync(recursive: true);
    }

    print('  Extracting...');
    final extract = await Process.start(
      os == 'macos' ? 'unzip' : 'tar',
      os == 'macos'
          ? ['-qo', archivePath, '-d', '.flutter-sdk/']
          : ['xJf', archivePath, '-C', '.flutter-sdk/'],
      mode: ProcessStartMode.inheritStdio,
    );
    if (await extract.exitCode != 0) {
      stderr.writeln('  Failed to extract Flutter SDK.');
      return 1;
    }

    File(archivePath).deleteSync();
    print('  Flutter ${config.flutter.version} ready at .flutter-sdk/flutter/');
    return 0;
  }

  /// Detect CPU architecture. On Windows, defaults to x64.
  Future<String> _detectArch(String targetOs) async {
    if (Platform.isWindows) {
      // Windows builds target Linux x64 for WSL/CI.
      return 'x64';
    }
    final uname =
        ((await Process.run('uname', ['-m'])).stdout as String).trim();
    return uname == 'arm64' || uname == 'aarch64' ? 'arm64' : 'x64';
  }

  Future<int> _fetchAndroidSdk(NixConfig config) async {
    File script = File(config.scriptPath('fetch-android-sdk.sh'));
    if (!script.existsSync()) {
      script = await resolveToolAssetFile('scripts/fetch-android-sdk.sh');
      print('  Using bundled Android SDK setup script.');
    }

    final env = <String, String>{
      ...Platform.environment,
      'PROJECT_ROOT': Directory.current.absolute.path,
      'NIX_FLAKE_DIR': Directory(config.normalizedFlakePath).absolute.path,
    };

    if (Platform.isWindows) {
      // Run the Android SDK fetch script inside WSL with Nix.
      final wslProjectRoot = toWslPath(Directory.current.absolute.path);
      final wslFlakeDir =
          toWslPath(Directory(config.normalizedFlakePath).absolute.path);
      final wslScript = toWslPath(script.absolute.path);
      final process = await Process.start(
        'wsl',
        [
          'env',
          'PROJECT_ROOT=$wslProjectRoot',
          'NIX_FLAKE_DIR=$wslFlakeDir',
          'nix',
          'develop',
          '${config.flakeRef}#android',
          '--command',
          'bash',
          wslScript,
        ],
        mode: ProcessStartMode.inheritStdio,
      );
      return process.exitCode;
    }

    if (Platform.isLinux) {
      final process = await Process.start(
        'nix',
        [
          'develop',
          '${config.flakeRef}#android',
          '--command',
          'bash',
          script.absolute.path,
        ],
        mode: ProcessStartMode.inheritStdio,
        environment: env,
      );
      return process.exitCode;
    }

    final process = await Process.start(
      'bash',
      [script.absolute.path],
      mode: ProcessStartMode.inheritStdio,
      environment: env,
    );
    return process.exitCode;
  }
}
