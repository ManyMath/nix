import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

final RegExp _flutterVersionPattern =
    RegExp(r'\b\d+\.\d+\.\d+(?:[-+][0-9A-Za-z.-]+)?\b');

Future<String?> detectInstalledFlutterVersion([
  String sdkRoot = '.flutter-sdk/flutter',
]) async {
  final sdkDir = Directory(sdkRoot);
  if (!sdkDir.existsSync()) {
    return null;
  }

  final versionFiles = <String>[
    p.join(sdkRoot, 'version'),
    p.join(sdkRoot, 'bin', 'cache', 'flutter.version.json'),
  ];

  for (final path in versionFiles) {
    final version = _readFlutterVersionFile(path);
    if (version != null) {
      return version;
    }
  }

  final flutterBinary = File(p.join(sdkRoot, 'bin', 'flutter'));
  if (!flutterBinary.existsSync()) {
    return null;
  }

  try {
    final machineVersion = await Process.run(
      flutterBinary.absolute.path,
      ['--version', '--machine'],
    );
    if (machineVersion.exitCode == 0) {
      final parsed = _parseFlutterVersionJson(machineVersion.stdout as String);
      if (parsed != null) {
        return parsed;
      }
    }
  } on ProcessException {
    // Fall back to the human-readable version output below.
  }

  try {
    final humanVersion = await Process.run(
      flutterBinary.absolute.path,
      ['--version'],
    );
    if (humanVersion.exitCode == 0) {
      return extractFlutterVersion(
        '${humanVersion.stdout}${humanVersion.stderr}',
      );
    }
  } on ProcessException {
    return null;
  }

  return null;
}

String? extractFlutterVersion(String input) {
  final match = _flutterVersionPattern.firstMatch(input.trim());
  return match?.group(0);
}

String? _readFlutterVersionFile(String path) {
  final file = File(path);
  if (!file.existsSync()) {
    return null;
  }

  final content = file.readAsStringSync().trim();
  if (content.isEmpty) {
    return null;
  }

  if (path.endsWith('.json')) {
    return _parseFlutterVersionJson(content);
  }

  return extractFlutterVersion(content);
}

String? _parseFlutterVersionJson(String content) {
  try {
    final json = jsonDecode(content);
    if (json is! Map<String, dynamic>) {
      return null;
    }

    for (final key in <String>[
      'frameworkVersion',
      'flutterVersion',
      'version',
    ]) {
      final value = json[key];
      if (value is String) {
        final version = extractFlutterVersion(value);
        if (version != null) {
          return version;
        }
      }
    }
  } on FormatException {
    return null;
  }

  return null;
}
