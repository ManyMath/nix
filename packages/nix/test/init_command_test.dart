import 'dart:io';

import 'package:nix/src/commands/init_command.dart';
import 'package:test/test.dart';

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
}
