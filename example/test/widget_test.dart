import 'package:flutter_test/flutter_test.dart';
import 'package:nix_example/main.dart';

void main() {
  testWidgets('app renders', (tester) async {
    await tester.pumpWidget(const App());
    expect(find.text('Flutter + Nix'), findsOneWidget);
  });
}
