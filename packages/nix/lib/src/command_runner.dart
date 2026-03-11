import 'package:args/command_runner.dart';
import 'package:nix/src/commands/init_command.dart';
import 'package:nix/src/commands/setup_command.dart';
import 'package:nix/src/commands/shell_command.dart';
import 'package:nix/src/commands/build_command.dart';
import 'package:nix/src/commands/doctor_command.dart';
import 'package:nix/src/commands/pin_command.dart';
import 'package:nix/src/commands/clean_command.dart';
import 'package:nix/src/commands/eject_command.dart';
import 'package:nix/src/commands/sync_command.dart';

class NixCommandRunner extends CommandRunner<int> {
  NixCommandRunner()
    : super('nix_dart', 'Reproducible Dart and Flutter builds with GNU Nix.') {
    argParser
      ..addFlag('verbose', abbr: 'v', help: 'Show underlying commands')
      ..addFlag('version', negatable: false, help: 'Print version and exit');

    addCommand(InitCommand());
    addCommand(SetupCommand());
    addCommand(ShellCommand());
    addCommand(BuildCommand());
    addCommand(DoctorCommand());
    addCommand(PinCommand());
    addCommand(CleanCommand());
    addCommand(EjectCommand());
    addCommand(SyncCommand());
  }

  @override
  Future<int?> run(Iterable<String> args) async {
    final results = parse(args);
    if (results['version'] == true) {
      print('nix_dart 0.1.0');
      return 0;
    }
    return await runCommand(results);
  }
}
