import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:nix/nix.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final plugin = Nix();

  testWidgets('getPlatformVersion', (WidgetTester tester) async {
    final version = await plugin.getPlatformVersion();
    expect(version?.isNotEmpty, true);
  });

  testWidgets('getNixEnvironmentInfo', (WidgetTester tester) async {
    final info = await plugin.getNixEnvironmentInfo();
    expect(info.platform, isNotNull);
    expect(info.currentSystem, isNotNull);
  });

  testWidgets('listNixPackages returns list', (WidgetTester tester) async {
    final packages = await plugin.listNixPackages();
    expect(packages, isA<List<NixPackage>>());
  });

  testWidgets('isNixAvailable returns bool', (WidgetTester tester) async {
    final available = await plugin.isNixAvailable();
    expect(available, isA<bool>());
  });
}
