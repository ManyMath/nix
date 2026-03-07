import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;
import 'package:nix/src/config/nix_config.dart';
import 'package:nix/src/flutter_sdk.dart';
import 'package:nix/src/nix/nix_runner.dart';
import 'package:nix/src/nix/wsl.dart';

class DoctorCommand extends Command<int> {
  @override
  final String name = 'doctor';

  @override
  final String description = 'Check prerequisites and configuration.';

  DoctorCommand() {
    argParser.addFlag('verbose', help: 'Show details for each check');
  }

  @override
  Future<int> run() async {
    final verbose = argResults!['verbose'] as bool ||
        (globalResults?['verbose'] as bool? ?? false);

    print('Nix Doctor');
    print('-' * 40);

    var issues = 0;
    final nix = NixRunner(verbose: verbose);

    // On Windows, check WSL availability first.
    if (Platform.isWindows) {
      final wslOk = await isWslAvailable();
      if (wslOk) {
        _pass('WSL2 available (Nix commands will run inside WSL)');
      } else {
        _fail('WSL2 not available');
        _hint('Install WSL2: wsl --install');
        _hint('Then install Nix inside WSL: https://nixos.org/download');
        return 1;
      }
    }

    final nixInstalled = await nix.isInstalled();
    if (nixInstalled) {
      final versionLabel = await nix.version();
      if (Platform.isWindows) {
        _pass('Nix installed in WSL ($versionLabel)');
      } else {
        _pass('Nix installed ($versionLabel)');
      }
    } else {
      if (Platform.isWindows) {
        _fail('Nix not found in WSL');
        _hint('Install Nix inside WSL: https://nixos.org/download');
      } else {
        _fail('Nix not found on PATH');
        _hint('Install Nix: https://nixos.org/download');
      }
      return 1;
    }

    final flakesStatus = await nix.checkFlakesEnabled();
    switch (flakesStatus) {
      case FlakesStatus.enabled:
        _pass('Experimental features enabled (nix-command flakes)');
        break;
      case FlakesStatus.missingFlakes:
      case FlakesStatus.missingNixCommand:
      case FlakesStatus.disabled:
        _fail('Flakes are not fully enabled');
        _hint('Add to ~/.config/nix/nix.conf:');
        _hint('  experimental-features = nix-command flakes');
        issues++;
        break;
      case FlakesStatus.unknown:
        _warn('Could not confirm experimental-features');
        break;
    }

    late final NixConfig config;
    try {
      config = NixConfig.load();
      _pass('nix.yaml found and valid');
    } on Exception catch (error) {
      _fail('nix.yaml has errors: $error');
      _hint('Run: nix_dart init');
      return 1;
    }

    final flakeDir = Directory(config.normalizedFlakePath);
    if (flakeDir.existsSync()) {
      _pass('Flake directory exists (${config.normalizedFlakePath})');
    } else {
      _fail('Flake directory not found: ${config.normalizedFlakePath}');
      _hint('Run: nix_dart init --from-existing or fix nix.flake in nix.yaml');
      issues++;
    }

    final lockFile = File(p.join(config.normalizedFlakePath, 'flake.lock'));
    if (lockFile.existsSync()) {
      final tracked = await nix.isTrackedByGit(lockFile.path);
      if (tracked) {
        _pass('flake.lock present');
      } else {
        _warn('flake.lock present but not tracked by git');
        _hint('Run: git add ${lockFile.path}');
      }
      final ageDays = nix.flakeLockAgeDays(lockFile.path);
      if (ageDays > 90) {
        _warn('flake.lock is $ageDays days old');
        _hint('Run: nix_dart pin');
      } else if (ageDays >= 0 && verbose) {
        _pass('flake.lock is $ageDays days old');
      }
    } else {
      _fail('flake.lock missing');
      _hint('Run: nix_dart pin');
      issues++;
    }

    final sdkDir = Directory('.flutter-sdk/flutter');
    if (!sdkDir.existsSync()) {
      _fail('Flutter SDK not fetched');
      _hint('Run: nix_dart setup');
      issues++;
    } else {
      final version = await detectInstalledFlutterVersion();
      if (version == config.flutter.version) {
        _pass('Flutter SDK fetched ($version)');
      } else {
        _warn(
          'Flutter SDK version mismatch${version == null ? '' : ' (have: $version, want: ${config.flutter.version})'}',
        );
        _hint('Run: nix_dart setup');
        issues++;
      }
    }

    final scriptsDir = Directory(p.join(config.toolkitRoot, 'scripts'));
    if (scriptsDir.existsSync()) {
      _pass('Vendored toolkit scripts found (${scriptsDir.path})');
    } else {
      _warn('Vendored toolkit scripts not found at ${scriptsDir.path}');
      _hint(
        'CLI-only setup uses bundled assets. Run nix_dart eject if you want scripts checked in.',
      );
    }

    if (config.platforms.containsKey('android')) {
      final androidSdk = Directory('.android-sdk/cmdline-tools');
      if (androidSdk.existsSync()) {
        _pass('Android SDK fetched');
      } else {
        _warn('Android SDK not fetched');
        _hint('Run: nix_dart setup android');
      }
    }

    if (Platform.isMacOS && config.platforms.containsKey('macos')) {
      final xcodeDir = Directory('/Applications/Xcode.app/Contents/Developer');
      if (xcodeDir.existsSync()) {
        _pass('Xcode.app found');
      } else {
        _fail('Xcode.app not found');
        _hint('Install Xcode for macOS/iOS compilation.');
        issues++;
      }
    }

    if (File('pubspec.lock').existsSync()) {
      if (verbose) {
        _pass('pubspec.lock present');
      }
    } else {
      _warn('pubspec.lock missing');
    }

    print('');
    print(
      issues == 0 ? 'No blocking issues found.' : '$issues issue(s) found.',
    );
    return issues == 0 ? 0 : 1;
  }

  void _pass(String message) => print('[pass] $message');
  void _fail(String message) => print('[FAIL] $message');
  void _warn(String message) => print('[warn] $message');
  void _hint(String message) => print('       $message');
}
