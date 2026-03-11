import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:nix/src/config/nix_config.dart';
import 'package:nix/src/nix/nix_runner.dart';

class PinCommand extends Command<int> {
  @override
  final String name = 'pin';

  @override
  final String description =
      'Advance flake.lock to the latest nixpkgs revision and commit the result.';

  @override
  Future<int> run() async {
    final verbose = globalResults!['verbose'] as bool;

    String flakePath;
    try {
      flakePath = NixConfig.load().normalizedFlakePath;
    } on FileSystemException {
      flakePath = 'nix';
    }

    final nix = NixRunner(verbose: verbose);

    if (!await nix.isInstalled()) {
      stderr.writeln('Error: nix not found on PATH.');
      return 1;
    }

    if (!Directory(flakePath).existsSync()) {
      stderr.writeln('Flake directory not found: $flakePath');
      stderr.writeln('Run: nix_dart init');
      return 1;
    }

    print('Updating $flakePath/flake.lock to the latest nixpkgs...');
    final result = await nix.pinFlake(flakePath);

    if (result.exitCode == 0) {
      print('flake.lock updated. Commit it to preserve reproducibility:');
      print(
        '  git add $flakePath/flake.lock && git commit -m "chore: pin nixpkgs"',
      );
      return 0;
    }

    stderr.writeln('Failed to update flake.lock.');
    stderr.writeln(result.stderr);
    return 1;
  }
}
