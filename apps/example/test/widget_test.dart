import 'package:flutter_test/flutter_test.dart';
import 'package:nix/main.dart';

void main() {
  testWidgets('app renders', (tester) async {
    await tester.pumpWidget(const App());
    expect(find.text('Nix Reference App'), findsOneWidget);
    expect(
      find.text(
        'Build this with the Nix wrappers, then check build/web/main.dart.js against expected-hashes/web-main.dart.js.sha256.',
      ),
      findsOneWidget,
    );
  });
}
