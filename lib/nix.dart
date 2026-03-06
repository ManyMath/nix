import 'nix_platform_interface.dart';
import 'src/models.dart';

export 'src/models.dart';

class Nix {
  Future<String?> getPlatformVersion() {
    return NixPlatform.instance.getPlatformVersion();
  }

  Future<NixEnvironmentInfo> getNixEnvironmentInfo() {
    return NixPlatform.instance.getNixEnvironmentInfo();
  }

  Future<List<NixPackage>> listNixPackages() {
    return NixPlatform.instance.listNixPackages();
  }

  Future<bool> isNixAvailable() {
    return NixPlatform.instance.isNixAvailable();
  }
}
