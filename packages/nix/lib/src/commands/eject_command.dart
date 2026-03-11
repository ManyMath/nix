import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;
import 'package:nix/src/commands/sync_command.dart';
import 'package:nix/src/config/nix_config.dart';

class EjectCommand extends Command<int> {
  @override
  final String name = 'eject';

  @override
  final String description =
      'Write .env files from nix.yaml and validate the vendored toolkit files.';

  EjectCommand() {
    argParser.addFlag(
      'write-env',
      defaultsTo: true,
      help:
          'Write flutter_version.env and android_sdk_version.env before validation',
    );
  }

  @override
  Future<int> run() async {
    final config = NixConfig.load();
    if (argResults!['write-env'] as bool) {
      writeEnvFiles(config);
    }

    final toolkitRoot = config.toolkitRoot;
    final scriptsDir = Directory(p.join(toolkitRoot, 'scripts'));
    final makefileInc = File(p.join(toolkitRoot, 'Makefile.inc'));

    if (!scriptsDir.existsSync()) {
      print('No vendored toolkit scripts found at ${scriptsDir.path}.');
      print('Nothing to validate for subtree/script mode.');
      return 0;
    }

    var issues = 0;

    if (makefileInc.existsSync()) {
      print('[pass] ${makefileInc.path}');
    } else {
      print('[FAIL] Missing ${makefileInc.path}');
      issues++;
    }

    for (final platform in config.platformNames) {
      for (final scriptName in _requiredScriptsFor(platform)) {
        final script = File(p.join(scriptsDir.path, scriptName));
        if (script.existsSync()) {
          print('[pass] ${script.path}');
        } else {
          print('[FAIL] Missing ${script.path}');
          issues++;
        }
      }
    }

    print('');
    if (issues == 0) {
      print('Vendored toolkit files look complete.');
    } else {
      print(
        '$issues issue(s) found. Add the missing toolkit files or adjust nix.yaml.',
      );
    }
    return issues == 0 ? 0 : 1;
  }

  Iterable<String> _requiredScriptsFor(String platform) sync* {
    if (platform == 'macos') {
      yield 'fetch-flutter.sh';
      yield 'shell-macos.sh';
      yield 'build-macos.sh';
      return;
    }

    if (platform == 'linux') {
      yield 'fetch-flutter-linux.sh';
      yield 'shell-linux.sh';
      yield 'build-linux.sh';
      return;
    }

    if (platform == 'android') {
      yield 'fetch-android-sdk.sh';
      yield 'shell-android.sh';
      yield 'build-android.sh';
      return;
    }

    if (platform == 'web') {
      yield 'fetch-flutter-web.sh';
      yield 'shell-web.sh';
      yield 'build-web.sh';
    }
  }
}
