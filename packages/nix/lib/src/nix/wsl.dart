import 'dart:io';

/// Detect whether WSL2 is available on this Windows machine.
///
/// Returns false immediately on non-Windows platforms.
Future<bool> isWslAvailable() async {
  if (!Platform.isWindows) return false;
  try {
    final result = await Process.run('wsl', ['--status']);
    // WSL --status exits 0 when a default distro is configured.
    return result.exitCode == 0;
  } on ProcessException {
    return false;
  }
}

/// Convert a Windows path to its WSL mount equivalent.
///
/// `C:\Users\alice\project` → `/mnt/c/Users/alice/project`
///
/// Returns [windowsPath] unchanged on non-Windows platforms.
String toWslPath(String windowsPath) {
  if (!Platform.isWindows) return windowsPath;

  // Already a forward-slash / unix-style path — pass through.
  if (!windowsPath.contains(r'\') && !RegExp(r'^[A-Za-z]:').hasMatch(windowsPath)) {
    return windowsPath;
  }

  final posix = windowsPath.replaceAll(r'\', '/');

  // Drive letter: C:/foo → /mnt/c/foo
  final driveMatch = RegExp(r'^([A-Za-z]):/(.*)$').firstMatch(posix);
  if (driveMatch != null) {
    final drive = driveMatch.group(1)!.toLowerCase();
    final rest = driveMatch.group(2)!;
    return '/mnt/$drive/$rest';
  }

  return posix;
}

/// Convert a WSL mount path back to a Windows path.
///
/// `/mnt/c/Users/alice/project` → `C:\Users\alice\project`
///
/// Returns [wslPath] unchanged if it does not start with `/mnt/`.
String toWindowsPath(String wslPath) {
  final match = RegExp(r'^/mnt/([a-z])/(.*)$').firstMatch(wslPath);
  if (match == null) return wslPath;
  final drive = match.group(1)!.toUpperCase();
  final rest = match.group(2)!.replaceAll('/', r'\');
  return '$drive:\\$rest';
}

/// Whether the current platform needs WSL to run Nix commands.
bool get needsWsl => Platform.isWindows;
