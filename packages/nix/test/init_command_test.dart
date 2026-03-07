import 'dart:io';

import 'package:nix/src/commands/init_command.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'test_support/cli_harness.dart';

void main() {
  group('detectExistingFlakePath', () {
    late Directory tmp;

    setUp(() {
      tmp = Directory.systemTemp.createTempSync('init_command_test_');
    });

    tearDown(() {
      tmp.deleteSync(recursive: true);
    });

    test('finds vendored flakes below nested subtree roots', () {
      final flakeDir = Directory(
        '${tmp.path}/vendor/tools/nix/nix',
      )..createSync(recursive: true);
      File('${flakeDir.path}/flake.nix').writeAsStringSync('{}');

      expect(detectExistingFlakePath(tmp), 'vendor/tools/nix/nix');
    });
  });

  group('cli init', () {
    late Directory project;

    setUp(() {
      project = Directory.systemTemp.createTempSync('init_command_cli_test_');
    });

    tearDown(() {
      if (project.existsSync()) {
        project.deleteSync(recursive: true);
      }
    });

    test('pins a fresh flake inside a clean git repo without git add',
        () async {
      await Process.run('git', ['init', '-q'], workingDirectory: project.path);

      final fakeBin = Directory(p.join(project.path, 'fake-bin'))
        ..createSync(recursive: true);
      final logFile = File(p.join(project.path, 'fake-nix.log'));
      writeExecutable(fakeBin, 'nix', '''
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "\$*" >> "${logFile.path}"
if [ "\${1:-}" = "--version" ]; then
  echo "nix (Nix) 2.33.3"
  exit 0
fi
if [ "\${1:-}" = "flake" ] && [ "\${2:-}" = "update" ]; then
  if [ "\${3:-}" != "--flake" ] || [[ "\${4:-}" != path:* ]]; then
    echo "expected --flake path:<dir>, got: \$*" >&2
    exit 1
  fi
  flake_dir="\${4#path:}"
  printf '{"version":7,"root":"root","nodes":{"root":{"inputs":{}}}}' > "\$flake_dir/flake.lock"
  exit 0
fi
echo "unexpected nix invocation: \$*" >&2
exit 1
''');

      final result = await runCli(
        workingDirectory: project,
        args: ['init', 'linux', 'android', 'web'],
        environment: {'PATH': prependPath(fakeBin.path)},
      );

      expect(result.exitCode, 0, reason: result.combined);
      expect(
        File(p.join(project.path, 'nix', 'flake.lock')).existsSync(),
        isTrue,
      );
      expect(result.stdout, contains('Created nix/flake.lock'));
      expect(
        logFile.readAsStringSync(),
        contains('--flake path:${p.join(project.resolveSymbolicLinksSync(), 'nix')}'),
      );
    });
  });
}
