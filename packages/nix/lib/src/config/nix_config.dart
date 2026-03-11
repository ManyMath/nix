import 'dart:io';
import 'package:yaml/yaml.dart';
import 'package:path/path.dart' as p;

class NixConfig {
  final String projectName;
  final FlutterConfig flutter;
  final String flakePath;
  final Map<String, PlatformConfig> platforms;
  final Map<String, ProfileConfig> profiles;

  NixConfig({
    required this.projectName,
    required this.flutter,
    required this.flakePath,
    required this.platforms,
    this.profiles = const {},
  });

  static NixConfig load([String path = 'nix.yaml']) {
    final file = File(path);
    if (!file.existsSync()) {
      throw FileSystemException('Config file not found', path);
    }
    final content = file.readAsStringSync();
    final yaml = loadYaml(content) as YamlMap;
    return NixConfig.fromYaml(yaml);
  }

  factory NixConfig.fromYaml(YamlMap yaml) {
    final project = yaml['project'] as YamlMap? ?? YamlMap();
    final flutter = yaml['flutter'] as YamlMap? ?? YamlMap();
    final nix = yaml['nix'] as YamlMap? ?? YamlMap();
    final platformsYaml = yaml['platforms'] as YamlMap? ?? YamlMap();
    final profilesYaml = yaml['profiles'] as YamlMap? ?? YamlMap();

    final platforms = <String, PlatformConfig>{};
    for (final entry in platformsYaml.entries) {
      final name = entry.key as String;
      platforms[name] = PlatformConfig.fromYaml(name, entry.value as YamlMap);
    }

    final profiles = <String, ProfileConfig>{};
    for (final entry in profilesYaml.entries) {
      final name = entry.key as String;
      profiles[name] = ProfileConfig.fromYaml(entry.value as YamlMap);
    }

    final checksums = flutter['checksums'] as YamlMap?;

    return NixConfig(
      projectName:
          (project['name'] as String?) ?? p.basename(Directory.current.path),
      flutter: FlutterConfig(
        version: flutter['version'] as String? ?? '',
        channel: flutter['channel'] as String? ?? 'stable',
        checksumMacosX64: checksums?['macos_x64'] as String? ?? '',
        checksumMacosArm64: checksums?['macos_arm64'] as String? ?? '',
        checksumLinuxX64: checksums?['linux_x64'] as String? ?? '',
        checksumLinuxArm64: checksums?['linux_arm64'] as String? ?? '',
      ),
      flakePath: nix['flake'] as String? ?? 'nix',
      platforms: platforms,
      profiles: profiles,
    );
  }

  String get normalizedFlakePath => flakePath.endsWith('/')
      ? flakePath.substring(0, flakePath.length - 1)
      : flakePath;

  /// Return a flake reference that `nix develop` will resolve as a local path.
  ///
  /// Bare relative paths like `nix` are interpreted by Nix as registry refs,
  /// so local vendored flakes need an explicit `./` prefix.
  String get flakeRef {
    final path = normalizedFlakePath;
    if (path.isEmpty) return './.';
    if (p.isAbsolute(path) || _looksLikeExternalFlakeRef(path)) return path;

    final normalized = p.normalize(path);
    if (normalized == '.') return './.';
    if (normalized.startsWith('./') || normalized.startsWith('../')) {
      return normalized;
    }
    return './$normalized';
  }

  String get toolkitRoot {
    final dir = p.dirname(normalizedFlakePath);
    return dir.isEmpty ? '.' : dir;
  }

  String scriptPath(String scriptName) =>
      p.join(toolkitRoot, 'scripts', scriptName);

  PlatformConfig? platformFor(String name) {
    if (platforms.containsKey(name)) return platforms[name];
    final profile = profiles[name];
    if (profile != null && platforms.containsKey(profile.platform)) {
      final base = platforms[profile.platform]!;
      return PlatformConfig(
        name: base.name,
        shell: base.shell,
        sdk: base.sdk,
        buildCommand: profile.command,
        buildOutput: profile.output ?? base.buildOutput,
      );
    }
    return null;
  }

  List<String> get platformNames => platforms.keys.toList();
}

bool _looksLikeExternalFlakeRef(String value) =>
    RegExp(r'^[A-Za-z][A-Za-z0-9+.-]*:').hasMatch(value);

class FlutterConfig {
  final String version;
  final String channel;
  final String checksumMacosX64;
  final String checksumMacosArm64;
  final String checksumLinuxX64;
  final String checksumLinuxArm64;

  const FlutterConfig({
    required this.version,
    required this.channel,
    this.checksumMacosX64 = '',
    this.checksumMacosArm64 = '',
    this.checksumLinuxX64 = '',
    this.checksumLinuxArm64 = '',
  });
}

class PlatformConfig {
  final String name;
  final String shell;
  final Map<String, String> sdk;
  final String buildCommand;
  final String buildOutput;

  const PlatformConfig({
    required this.name,
    required this.shell,
    this.sdk = const {},
    required this.buildCommand,
    required this.buildOutput,
  });

  factory PlatformConfig.fromYaml(String name, YamlMap yaml) {
    final sdkYaml = yaml['sdk'] as YamlMap?;
    final buildYaml = yaml['build'] as YamlMap? ?? YamlMap();
    final defaultShell = name == 'macos' ? 'default' : name;

    return PlatformConfig(
      name: name,
      shell: yaml['shell'] as String? ?? defaultShell,
      sdk: sdkYaml != null
          ? Map<String, String>.fromEntries(
              sdkYaml.entries.map(
                (e) => MapEntry(e.key as String, '${e.value}'),
              ),
            )
          : {},
      buildCommand:
          buildYaml['command'] as String? ?? 'flutter build $name --release',
      buildOutput: buildYaml['output'] as String? ?? 'build/',
    );
  }
}

class ProfileConfig {
  final String platform;
  final String command;
  final String? output;

  const ProfileConfig({
    required this.platform,
    required this.command,
    this.output,
  });

  factory ProfileConfig.fromYaml(YamlMap yaml) {
    return ProfileConfig(
      platform: yaml['platform'] as String,
      command: yaml['command'] as String,
      output: yaml['output'] as String?,
    );
  }
}
