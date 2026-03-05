import 'package:flutter/material.dart';

void main() {
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nix Reference App',
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
      home: const Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Nix Reference App',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 12),
                Text(
                  'Build this with the Nix wrappers, then check build/web/main.dart.js against expected-hashes/web-main.dart.js.sha256.',
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 12),
                Text(
                  'Start with make setup-web, make build-web, and ./tool/hash_web_release.sh --check.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
