import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'test_support/cli_harness.dart';

void main() {
  group('doctor', () {
    late Directory project;

    setUp(() {
      project = Directory.systemTemp.createTempSync('doctor_command_test_');
    });

    tearDown(() {
      if (project.existsSync()) {
        project.deleteSync(recursive: true);
      }
    });

    test('passes flakes and Flutter checks in a healthy CLI-only repo',
        () async {
      final nowSeconds = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
      _writeProjectFiles(project, lastModifiedSeconds: nowSeconds);

      await Process.run('git', ['init', '-q'], workingDirectory: project.path);
      await Process.run(
        'git',
        ['add', 'nix.yaml', 'nix/flake.nix', 'nix/flake.lock'],
        workingDirectory: project.path,
      );

      final fakeBin = Directory(p.join(project.path, 'fake-bin'))
        ..createSync(recursive: true);
      writeExecutable(fakeBin, 'nix', '''
#!/usr/bin/env bash
set -euo pipefail
if [ "\${1:-}" = "--version" ]; then
  echo "nix (Determinate Nix 3.17.0) 2.33.3"
  exit 0
fi
if [ "\${1:-}" = "config" ] && [ "\${2:-}" = "show" ] && [ "\${3:-}" = "experimental-features" ]; then
  exit 0
fi
if [ "\${1:-}" = "flake" ] && [ "\${2:-}" = "metadata" ]; then
  exit 0
fi
echo "unexpected nix invocation: \$*" >&2
exit 1
''');

      final result = await runCli(
        workingDirectory: project,
        args: ['doctor'],
        environment: {'PATH': prependPath(fakeBin.path)},
      );

      expect(result.exitCode, 0, reason: result.combined);
      expect(
        result.stdout,
        contains('[pass] Experimental features enabled (nix-command flakes)'),
      );
      expect(result.stdout, contains('[pass] Flutter SDK fetched (3.38.2)'));
      expect(result.stdout, contains('No blocking issues found.'));
    });

    test('does not fail when flake.lock has not been staged yet', () async {
      final nowSeconds = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
      _writeProjectFiles(project, lastModifiedSeconds: nowSeconds);

      await Process.run('git', ['init', '-q'], workingDirectory: project.path);

      final fakeBin = Directory(p.join(project.path, 'fake-bin'))
        ..createSync(recursive: true);
      writeExecutable(fakeBin, 'nix', '''
#!/usr/bin/env bash
set -euo pipefail
if [ "\${1:-}" = "--version" ]; then
  echo "nix (Nix) 2.33.3"
  exit 0
fi
if [ "\${1:-}" = "config" ] && [ "\${2:-}" = "show" ] && [ "\${3:-}" = "experimental-features" ]; then
  echo "nix-command flakes"
  exit 0
fi
if [ "\${1:-}" = "flake" ] && [ "\${2:-}" = "metadata" ]; then
  exit 0
fi
echo "unexpected nix invocation: \$*" >&2
exit 1
''');

      final result = await runCli(
        workingDirectory: project,
        args: ['doctor'],
        environment: {'PATH': prependPath(fakeBin.path)},
      );

      expect(result.exitCode, 0, reason: result.combined);
      expect(
        result.stdout,
        contains('[warn] flake.lock present but not tracked by git'),
      );
      expect(result.stdout, contains('No blocking issues found.'));
    });
  });
}

void _writeProjectFiles(
  Directory project, {
  required int lastModifiedSeconds,
}) {
  Directory(p.join(project.path, 'nix')).createSync(recursive: true);
  File(p.join(project.path, 'nix.yaml')).writeAsStringSync('''
project:
  name: smoke
flutter:
  version: "3.38.2"
  channel: stable
nix:
  flake: nix
platforms:
  web:
    shell: web
    build:
      command: flutter build web --release
      output: build/web/
''');
  File(p.join(project.path, 'nix', 'flake.nix')).writeAsStringSync('{}');
  File(p.join(project.path, 'nix', 'flake.lock')).writeAsStringSync(
    jsonEncode({
      'version': 7,
      'root': 'root',
      'nodes': {
        'root': {
          'inputs': {'nixpkgs': 'nixpkgs'},
        },
        'nixpkgs': {
          'locked': {'lastModified': lastModifiedSeconds},
        },
      },
    }),
  );

  final cacheDir = Directory(
    p.join(project.path, '.flutter-sdk', 'flutter', 'bin', 'cache'),
  )..createSync(recursive: true);
  File(
    p.join(cacheDir.path, 'flutter.version.json'),
  ).writeAsStringSync(
    jsonEncode({
      'frameworkVersion': '3.38.2',
      'flutterVersion': '3.38.2',
    }),
  );
}
