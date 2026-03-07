import 'dart:isolate';
import 'dart:io';

import 'package:path/path.dart' as p;

class CliResult {
  final int exitCode;
  final String stdout;
  final String stderr;

  const CliResult({
    required this.exitCode,
    required this.stdout,
    required this.stderr,
  });

  String get combined => '$stdout\n$stderr';
}

Future<CliResult> runCli({
  required Directory workingDirectory,
  required List<String> args,
  Map<String, String> environment = const {},
}) async {
  final packageRoot = await resolvePackageRoot();
  final result = await Process.run(
    Platform.resolvedExecutable,
    [p.join(packageRoot.path, 'bin', 'nix_dart.dart'), ...args],
    workingDirectory: workingDirectory.path,
    environment: environment,
    includeParentEnvironment: true,
  );

  return CliResult(
    exitCode: result.exitCode,
    stdout: result.stdout as String,
    stderr: result.stderr as String,
  );
}

Future<Directory> resolvePackageRoot() async {
  final uri = await Isolate.resolvePackageUri(
    Uri.parse('package:nix/src/command_runner.dart'),
  );
  if (uri == null) {
    throw StateError('Could not resolve package:nix/src/command_runner.dart');
  }

  final sourcePath = uri.toFilePath();
  return Directory(p.dirname(p.dirname(p.dirname(sourcePath))));
}

File writeExecutable(Directory directory, String name, String content) {
  final file = File(p.join(directory.path, name))
    ..createSync(recursive: true)
    ..writeAsStringSync(content);
  if (!Platform.isWindows) {
    Process.runSync('chmod', ['+x', file.path]);
  }
  return file;
}

String prependPath(String pathEntry, [String? basePath]) {
  final separator = Platform.isWindows ? ';' : ':';
  final currentPath = basePath ?? Platform.environment['PATH'] ?? '';
  if (currentPath.isEmpty) {
    return pathEntry;
  }
  return '$pathEntry$separator$currentPath';
}
