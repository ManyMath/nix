String generateConfig({
  required String projectName,
  required List<String> platforms,
  String flutterVersion = '3.38.2',
  String flutterChannel = 'stable',
  String flakePath = 'nix',
  String checksumMacosX64 = '',
  String checksumMacosArm64 = '',
  String checksumLinuxX64 = '',
  String checksumLinuxArm64 = '',
  String cmdlineToolsBuild = '14742923',
  String cmdlineToolsSha256Linux = '',
  String cmdlineToolsSha256Macos = '',
  String platformVersion = 'android-34',
  String buildToolsVersion = '35.0.0',
  String ndkVersion = '28.2.13676358',
}) {
  final buffer = StringBuffer();
  buffer.writeln('# nix.yaml: reproducible build configuration');
  buffer.writeln('# Docs: https://pub.dev/packages/nix');
  buffer.writeln();
  buffer.writeln('project:');
  buffer.writeln('  name: $projectName');
  buffer.writeln();
  buffer.writeln('flutter:');
  buffer.writeln('  version: "$flutterVersion"');
  buffer.writeln('  channel: $flutterChannel');
  buffer.writeln('  checksums:');
  buffer.writeln('    macos_x64: "$checksumMacosX64"');
  buffer.writeln('    macos_arm64: "$checksumMacosArm64"');
  buffer.writeln('    linux_x64: "$checksumLinuxX64"');
  buffer.writeln('    linux_arm64: "$checksumLinuxArm64"');
  buffer.writeln();
  buffer.writeln('nix:');
  buffer.writeln('  flake: $flakePath');

  if (platforms.isNotEmpty) {
    buffer.writeln();
    buffer.writeln('platforms:');
  }

  if (platforms.contains('macos')) {
    buffer.writeln('  macos:');
    buffer.writeln('    shell: default');
    buffer.writeln('    build:');
    buffer.writeln('      command: flutter build macos --release');
    buffer.writeln('      output: build/macos/Build/Products/Release/');
  }

  if (platforms.contains('linux')) {
    buffer.writeln('  linux:');
    buffer.writeln('    shell: linux');
    buffer.writeln('    build:');
    buffer.writeln('      command: flutter build linux --release');
    buffer.writeln('      output: build/linux/x64/release/bundle/');
  }

  if (platforms.contains('android')) {
    buffer.writeln('  android:');
    buffer.writeln('    shell: android');
    buffer.writeln('    sdk:');
    buffer.writeln('      cmdline_tools_build: "$cmdlineToolsBuild"');
    buffer.writeln(
      '      cmdline_tools_sha256_linux: "$cmdlineToolsSha256Linux"',
    );
    buffer.writeln(
      '      cmdline_tools_sha256_macos: "$cmdlineToolsSha256Macos"',
    );
    buffer.writeln('      platform_version: $platformVersion');
    buffer.writeln('      build_tools_version: "$buildToolsVersion"');
    buffer.writeln('      ndk_version: "$ndkVersion"');
    buffer.writeln('    build:');
    buffer.writeln('      command: flutter build apk --release');
    buffer.writeln(
      '      output: build/app/outputs/flutter-apk/app-release.apk',
    );
  }

  if (platforms.contains('web')) {
    buffer.writeln('  web:');
    buffer.writeln('    shell: web');
    buffer.writeln('    build:');
    buffer.writeln('      command: flutter build web --release');
    buffer.writeln('      output: build/web/');
  }

  return buffer.toString();
}
