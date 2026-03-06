import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'nix_method_channel.dart';
import 'src/models.dart';

abstract class NixPlatform extends PlatformInterface {
  NixPlatform() : super(token: _token);

  static final Object _token = Object();

  static NixPlatform _instance = MethodChannelNix();

  static NixPlatform get instance => _instance;

  static set instance(NixPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('getPlatformVersion() has not been implemented.');
  }

  Future<NixEnvironmentInfo> getNixEnvironmentInfo() {
    throw UnimplementedError(
        'getNixEnvironmentInfo() has not been implemented.');
  }

  Future<List<NixPackage>> listNixPackages() {
    throw UnimplementedError('listNixPackages() has not been implemented.');
  }

  Future<bool> isNixAvailable() {
    throw UnimplementedError('isNixAvailable() has not been implemented.');
  }
}
