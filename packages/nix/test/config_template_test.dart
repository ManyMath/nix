import 'package:test/test.dart';
import 'package:nix/src/templates/config_template.dart';

void main() {
  group('generateConfig', () {
    test('includes project name and flake path', () {
      final yaml = generateConfig(
        projectName: 'wallet',
        platforms: ['linux'],
        flakePath: 'third_party/nix-flutter/nix',
      );

      expect(yaml, contains('name: wallet'));
      expect(yaml, contains('flake: third_party/nix-flutter/nix'));
    });

    test('includes requested platform shells', () {
      final yaml = generateConfig(
        projectName: 'wallet',
        platforms: ['macos', 'linux', 'android', 'web'],
      );

      expect(yaml, contains('macos:'));
      expect(yaml, contains('shell: default'));
      expect(yaml, contains('linux:'));
      expect(yaml, contains('shell: linux'));
      expect(yaml, contains('android:'));
      expect(yaml, contains('cmdline_tools_build: "14742923"'));
      expect(yaml, contains('web:'));
      expect(yaml, contains('shell: web'));
    });

    test('omits platform sections that were not requested', () {
      final yaml = generateConfig(projectName: 'wallet', platforms: ['web']);

      expect(yaml, contains('web:'));
      expect(yaml, isNot(contains('android:')));
      expect(yaml, isNot(contains('linux:')));
      expect(yaml, isNot(contains('macos:')));
    });
  });
}
