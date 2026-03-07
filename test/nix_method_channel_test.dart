import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nix/nix_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelNix platform = MethodChannelNix();
  const MethodChannel channel = MethodChannel('nix');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      switch (methodCall.method) {
        case 'getPlatformVersion':
          return '42';
        case 'getNixEnvironmentInfo':
          return {
            'isInstalled': true,
            'nixVersion': 'nix (Nix) 2.20.0',
            'nixStorePath': '/nix/store',
            'currentSystem': 'aarch64-darwin',
            'platform': 'macos',
          };
        case 'listNixPackages':
          return [
            {'name': 'git', 'version': '2.43.0', 'storePath': '/nix/store/abc-git-2.43.0'},
          ];
        case 'isNixAvailable':
          return true;
        default:
          return null;
      }
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), '42');
  });

  test('getNixEnvironmentInfo', () async {
    final info = await platform.getNixEnvironmentInfo();
    expect(info.isInstalled, true);
    expect(info.nixVersion, 'nix (Nix) 2.20.0');
    expect(info.currentSystem, 'aarch64-darwin');
  });

  test('listNixPackages', () async {
    final packages = await platform.listNixPackages();
    expect(packages.length, 1);
    expect(packages.first.name, 'git');
  });

  test('isNixAvailable', () async {
    expect(await platform.isNixAvailable(), true);
  });
}
