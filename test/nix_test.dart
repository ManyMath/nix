import 'package:flutter_test/flutter_test.dart';
import 'package:nix/nix.dart';
import 'package:nix/nix_platform_interface.dart';
import 'package:nix/nix_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockNixPlatform with MockPlatformInterfaceMixin implements NixPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');

  @override
  Future<NixEnvironmentInfo> getNixEnvironmentInfo() => Future.value(
        const NixEnvironmentInfo(
          isInstalled: true,
          nixVersion: 'nix (Nix) 2.20.0',
          nixStorePath: '/nix/store',
          currentSystem: 'aarch64-darwin',
          platform: 'macos',
        ),
      );

  @override
  Future<List<NixPackage>> listNixPackages() => Future.value([
        const NixPackage(name: 'hello', version: '2.12.1', storePath: '/nix/store/abc-hello-2.12.1'),
      ]);

  @override
  Future<bool> isNixAvailable() => Future.value(true);
}

void main() {
  final NixPlatform initialPlatform = NixPlatform.instance;

  test('MethodChannelNix is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelNix>());
  });

  group('Nix plugin with mock platform', () {
    late Nix nix;

    setUp(() {
      NixPlatform.instance = MockNixPlatform();
      nix = Nix();
    });

    test('getPlatformVersion', () async {
      expect(await nix.getPlatformVersion(), '42');
    });

    test('getNixEnvironmentInfo', () async {
      final info = await nix.getNixEnvironmentInfo();
      expect(info.isInstalled, true);
      expect(info.nixVersion, 'nix (Nix) 2.20.0');
      expect(info.nixStorePath, '/nix/store');
      expect(info.currentSystem, 'aarch64-darwin');
      expect(info.platform, 'macos');
    });

    test('listNixPackages', () async {
      final packages = await nix.listNixPackages();
      expect(packages.length, 1);
      expect(packages.first.name, 'hello');
      expect(packages.first.version, '2.12.1');
    });

    test('isNixAvailable', () async {
      expect(await nix.isNixAvailable(), true);
    });
  });
}
