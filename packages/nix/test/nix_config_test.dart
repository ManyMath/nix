import 'package:nix/src/config/nix_config.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

void main() {
  group('NixConfig.flakeRef', () {
    NixConfig configWithFlake(String flakePath) {
      final yaml = loadYaml('''
project:
  name: wallet
nix:
  flake: $flakePath
platforms:
  web:
    shell: web
''') as YamlMap;
      return NixConfig.fromYaml(yaml);
    }

    test('prefixes bare relative paths with ./', () {
      expect(configWithFlake('nix').flakeRef, './nix');
      expect(configWithFlake('nix/nix').flakeRef, './nix/nix');
    });

    test('preserves explicit relative paths', () {
      expect(configWithFlake('./nix').flakeRef, './nix');
      expect(configWithFlake('../shared/nix').flakeRef, '../shared/nix');
    });

    test('preserves absolute paths and external refs', () {
      expect(configWithFlake('/tmp/tool/nix').flakeRef, '/tmp/tool/nix');
      expect(
        configWithFlake('github:ManyMath/nix').flakeRef,
        'github:ManyMath/nix',
      );
    });
  });
}
