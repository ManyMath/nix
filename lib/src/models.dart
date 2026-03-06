class NixEnvironmentInfo {
  final bool isInstalled;
  final String? nixVersion;
  final String? nixStorePath;
  final String? currentSystem;
  final String? platform;

  const NixEnvironmentInfo({
    required this.isInstalled,
    this.nixVersion,
    this.nixStorePath,
    this.currentSystem,
    this.platform,
  });

  factory NixEnvironmentInfo.fromMap(Map<String, dynamic> map) {
    return NixEnvironmentInfo(
      isInstalled: map['isInstalled'] as bool? ?? false,
      nixVersion: map['nixVersion'] as String?,
      nixStorePath: map['nixStorePath'] as String?,
      currentSystem: map['currentSystem'] as String?,
      platform: map['platform'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'isInstalled': isInstalled,
        'nixVersion': nixVersion,
        'nixStorePath': nixStorePath,
        'currentSystem': currentSystem,
        'platform': platform,
      };
}

class NixPackage {
  final String name;
  final String? version;
  final String? storePath;

  const NixPackage({
    required this.name,
    this.version,
    this.storePath,
  });

  factory NixPackage.fromMap(Map<String, dynamic> map) {
    return NixPackage(
      name: map['name'] as String? ?? 'unknown',
      version: map['version'] as String?,
      storePath: map['storePath'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'version': version,
        'storePath': storePath,
      };
}
