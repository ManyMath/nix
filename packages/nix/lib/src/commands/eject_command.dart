import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:nix/src/commands/sync_command.dart';
import 'package:nix/src/config/nix_config.dart';
import 'package:nix/src/tool_scaffold.dart';

class EjectCommand extends Command<int> {
  @override
  final String name = 'eject';

  @override
  final String description =
      'Generate a standalone shell-script toolkit from the current config.';

  EjectCommand() {
    argParser
      ..addOption(
        'output-dir',
        abbr: 'd',
        defaultsTo: '.',
        help: 'Directory that should receive the standalone toolkit',
      )
      ..addFlag(
        'force',
        abbr: 'f',
        help: 'Overwrite existing toolkit files in the output directory',
      )
      ..addFlag(
      'write-env',
      defaultsTo: true,
      help:
          'Write flutter_version.env and android_sdk_version.env into the output directory',
    );
  }

  @override
  Future<int> run() async {
    final config = NixConfig.load();
    final outputDir = argResults!['output-dir'] as String;
    final force = argResults!['force'] as bool;
    final outputRoot = Directory(outputDir);

    if (!outputRoot.existsSync()) {
      outputRoot.createSync(recursive: true);
    }

    if (argResults!['write-env'] as bool) {
      writeEnvFiles(config, dir: outputRoot.path);
    }

    final result = await materializeToolkit(
      toolkitRoot: config.toolkitRoot,
      outputRoot: outputRoot,
      force: force,
    );

    print('');
    print('Toolkit output: ${outputRoot.path}');
    print('  copied from toolkit: ${result.copiedFromToolkit}');
    print('  copied from bundled assets: ${result.copiedFromAssets}');
    print('  skipped existing files: ${result.skipped}');
    print('');
    print('Ejection complete. The output directory now contains:');
    print('  bootstrap.sh');
    print('  Makefile.inc');
    print('  nix/');
    print('  scripts/');
    print('  flutter_version.env and android_sdk_version.env');
    return 0;
  }
}
