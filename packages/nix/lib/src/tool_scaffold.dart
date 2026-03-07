import 'dart:io';
import 'dart:isolate';

import 'package:path/path.dart' as p;

/// Files that make up the standalone toolkit layout.
const toolAssetPaths = <String>[
  'bootstrap.sh',
  'Makefile.inc',
  'flutter_version.env.example',
  'android_sdk_version.env.example',
  'nix.yaml.example',
  'scripts/build-android.sh',
  'scripts/build-linux.sh',
  'scripts/build-macos.sh',
  'scripts/build-web.sh',
  'scripts/fetch-android-sdk.sh',
  'scripts/fetch-flutter-linux.sh',
  'scripts/fetch-flutter-web.sh',
  'scripts/fetch-flutter.sh',
  'scripts/shell-android.sh',
  'scripts/shell-linux.sh',
  'scripts/shell-macos.sh',
  'scripts/shell-web.sh',
  'nix/flake.lock',
  'nix/flake.nix',
  'nix/pin.sh',
  'nix/shell.nix',
];

class ToolScaffoldResult {
  final int copiedFromToolkit;
  final int copiedFromAssets;
  final int skipped;

  const ToolScaffoldResult({
    required this.copiedFromToolkit,
    required this.copiedFromAssets,
    required this.skipped,
  });
}

/// Materialize a standalone toolkit into [outputRoot].
///
/// Existing vendored files are preferred when present. Missing files fall back
/// to the package-bundled toolkit assets so CLI-only projects can still eject a
/// complete shell-script workflow.
Future<ToolScaffoldResult> materializeToolkit({
  required String toolkitRoot,
  required Directory outputRoot,
  bool force = false,
}) async {
  if (!outputRoot.existsSync()) {
    outputRoot.createSync(recursive: true);
  }

  var copiedFromToolkit = 0;
  var copiedFromAssets = 0;
  var skipped = 0;

  for (final relativePath in toolAssetPaths) {
    final source = File(p.join(toolkitRoot, relativePath));
    final destination = File(p.join(outputRoot.path, relativePath));

    if (source.existsSync() &&
        p.normalize(source.absolute.path) ==
            p.normalize(destination.absolute.path)) {
      skipped++;
      continue;
    }

    if (destination.existsSync() && !force) {
      skipped++;
      continue;
    }

    destination.parent.createSync(recursive: true);

    if (source.existsSync()) {
      source.copySync(destination.path);
      copiedFromToolkit++;
    } else {
      destination.writeAsStringSync(await _readAsset(relativePath));
      copiedFromAssets++;
    }

    if (!Platform.isWindows && _isExecutable(relativePath)) {
      Process.runSync('chmod', ['+x', destination.path]);
    }
  }

  return ToolScaffoldResult(
    copiedFromToolkit: copiedFromToolkit,
    copiedFromAssets: copiedFromAssets,
    skipped: skipped,
  );
}

Future<File> resolveToolAssetFile(String relativePath) async {
  final resolved = await Isolate.resolvePackageUri(
    Uri.parse('package:nix/src/assets/tool/$relativePath'),
  );
  if (resolved == null) {
    throw FileSystemException('Could not resolve toolkit asset', relativePath);
  }
  return File.fromUri(resolved);
}

Future<String> _readAsset(String relativePath) async {
  return (await resolveToolAssetFile(relativePath)).readAsStringSync();
}

bool _isExecutable(String relativePath) =>
    relativePath.endsWith('.sh') || relativePath == 'bootstrap.sh';
