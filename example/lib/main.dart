import 'package:flutter/material.dart';
import 'package:nix/nix.dart';

void main() {
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nix',
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _nix = Nix();

  String? _platformVersion;
  NixEnvironmentInfo? _envInfo;
  List<NixPackage>? _packages;
  bool? _nixAvailable;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final versionFuture = _nix.getPlatformVersion();
      final envFuture = _nix.getNixEnvironmentInfo();
      final packagesFuture = _nix.listNixPackages();
      final availableFuture = _nix.isNixAvailable();

      final version = await versionFuture;
      final env = await envFuture;
      final packages = await packagesFuture;
      final available = await availableFuture;

      if (!mounted) return;
      setState(() {
        _platformVersion = version;
        _envInfo = env;
        _packages = packages;
        _nixAvailable = available;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Flutter + Nix')),
      body: _error != null
          ? Center(child: Text('Error: $_error'))
          : _envInfo == null
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildEnvCard(),
                    const SizedBox(height: 12),
                    _buildPackagesCard(),
                  ],
                ),
    );
  }

  Widget _buildEnvCard() {
    final env = _envInfo!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  env.isInstalled
                      ? Icons.check_circle_outline
                      : Icons.cancel_outlined,
                  color: env.isInstalled ? Colors.green : Colors.orange,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Text(
                  env.isInstalled ? 'Nix is installed' : 'Nix not detected',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _infoRow('Platform', _platformVersion ?? 'Unknown'),
            _infoRow('Nix version', env.nixVersion ?? 'N/A'),
            _infoRow('Store path', env.nixStorePath ?? 'N/A'),
            _infoRow('System', env.currentSystem ?? 'Unknown'),
            _infoRow('Available', _nixAvailable == true ? 'Yes' : 'No'),
          ],
        ),
      ),
    );
  }

  Widget _buildPackagesCard() {
    final packages = _packages ?? [];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nix packages (${packages.length})',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            if (packages.isEmpty)
              const Text(
                'No packages found in current profile.\n'
                'Install Nix and add packages to see them here.',
              )
            else
              ...packages.map((pkg) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      '${pkg.name}${pkg.version != null ? " ${pkg.version}" : ""}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontFamily: 'monospace',
                          ),
                    ),
                  )),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
