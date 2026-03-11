import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:nix/src/config/nix_config.dart';

class SyncCommand extends Command<int> {
  @override
  final String name = 'sync';

  @override
  final String description =
      'Write flutter_version.env / android_sdk_version.env from nix.yaml '
      'so that the scripts/ entry points stay in sync with config.';

  SyncCommand() {
    argParser..addFlag(
      'dry-run',
      abbr: 'n',
      help: 'Print what would be written without writing',
    );
  }

  @override
  Future<int> run() async {
    final dryRun = argResults!['dry-run'] as bool;
    final config = NixConfig.load();
    writeEnvFiles(config, dryRun: dryRun);
    return 0;
  }
}

/// Write flutter_version.env and (if android platform present) android_sdk_version.env.
void writeEnvFiles(NixConfig config, {bool dryRun = false, String dir = '.'}) {
  final flutterEnv = _flutterEnvContent(config);
  final flutterPath = '$dir/flutter_version.env';
  if (dryRun) {
    print('# flutter_version.env');
    print(flutterEnv);
  } else {
    File(flutterPath).writeAsStringSync(flutterEnv);
    print('  wrote flutter_version.env');
  }

  final android = config.platforms['android'];
  if (android != null && android.sdk.isNotEmpty) {
    final androidEnv = _androidEnvContent(android);
    final androidPath = '$dir/android_sdk_version.env';
    if (dryRun) {
      print('# android_sdk_version.env');
      print(androidEnv);
    } else {
      File(androidPath).writeAsStringSync(androidEnv);
      print('  wrote android_sdk_version.env');
    }
  }
}

String _flutterEnvContent(NixConfig config) {
  final f = config.flutter;
  return 'FLUTTER_VERSION="${f.version}"\n'
      'FLUTTER_CHANNEL="${f.channel}"\n'
      'FLUTTER_SHA256_X64="${f.checksumMacosX64}"\n'
      'FLUTTER_SHA256_ARM64="${f.checksumMacosArm64}"\n'
      'FLUTTER_SHA256_LINUX_X64="${f.checksumLinuxX64}"\n'
      'FLUTTER_SHA256_LINUX_ARM64="${f.checksumLinuxArm64}"\n';
}

String _androidEnvContent(PlatformConfig android) {
  final sdk = android.sdk;
  return 'ANDROID_CMDLINE_TOOLS_BUILD="${sdk['cmdline_tools_build'] ?? ''}"\n'
      'ANDROID_CMDLINE_TOOLS_SHA256="${sdk['cmdline_tools_sha256_macos'] ?? ''}"\n'
      'ANDROID_CMDLINE_TOOLS_SHA256_LINUX="${sdk['cmdline_tools_sha256_linux'] ?? ''}"\n'
      'ANDROID_PLATFORM_VERSION="${sdk['platform_version'] ?? ''}"\n'
      'ANDROID_BUILD_TOOLS_VERSION="${sdk['build_tools_version'] ?? ''}"\n'
      'ANDROID_NDK_VERSION="${sdk['ndk_version'] ?? ''}"\n';
}
