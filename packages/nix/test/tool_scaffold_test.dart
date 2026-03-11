import 'dart:io';

import 'package:nix/src/tool_scaffold.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('materializeToolkit', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('nix_tool_scaffold_test');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('writes bundled toolkit assets when vendored files are absent', () async {
      final output = Directory(p.join(tempDir.path, 'out'));

      final result = await materializeToolkit(
        toolkitRoot: p.join(tempDir.path, 'missing-toolkit'),
        outputRoot: output,
      );

      expect(result.copiedFromAssets, greaterThan(0));
      expect(File(p.join(output.path, 'bootstrap.sh')).existsSync(), isTrue);
      expect(File(p.join(output.path, 'Makefile.inc')).existsSync(), isTrue);
      expect(File(p.join(output.path, 'nix', 'flake.nix')).existsSync(), isTrue);
      expect(
        File(p.join(output.path, 'scripts', 'build-web.sh')).existsSync(),
        isTrue,
      );
      expect(File(p.join(output.path, 'nix.yaml.example')).existsSync(), isTrue);
    });

    test('preserves existing files unless force is set', () async {
      final toolkitRoot = Directory(p.join(tempDir.path, 'toolkit'))
        ..createSync(recursive: true);
      final output = Directory(p.join(tempDir.path, 'out'))
        ..createSync(recursive: true);

      final source = File(p.join(toolkitRoot.path, 'bootstrap.sh'))
        ..createSync(recursive: true)
        ..writeAsStringSync('source');
      final destination = File(p.join(output.path, 'bootstrap.sh'))
        ..createSync(recursive: true)
        ..writeAsStringSync('dest');

      await materializeToolkit(
        toolkitRoot: toolkitRoot.path,
        outputRoot: output,
      );
      expect(destination.readAsStringSync(), 'dest');

      await materializeToolkit(
        toolkitRoot: toolkitRoot.path,
        outputRoot: output,
        force: true,
      );
      expect(destination.readAsStringSync(), source.readAsStringSync());
    });
  });
}
