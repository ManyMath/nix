import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'nix_platform_interface.dart';
import 'src/models.dart';

class MethodChannelNix extends NixPlatform {
  @visibleForTesting
  final methodChannel = const MethodChannel('nix');

  @override
  Future<String?> getPlatformVersion() async {
    final version =
        await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }

  @override
  Future<NixEnvironmentInfo> getNixEnvironmentInfo() async {
    final result =
        await methodChannel.invokeMapMethod<String, dynamic>(
            'getNixEnvironmentInfo');
    return NixEnvironmentInfo.fromMap(result ?? {});
  }

  @override
  Future<List<NixPackage>> listNixPackages() async {
    final result =
        await methodChannel.invokeListMethod<Map>('listNixPackages');
    if (result == null) return [];
    return result
        .map((m) => NixPackage.fromMap(Map<String, dynamic>.from(m)))
        .toList();
  }

  @override
  Future<bool> isNixAvailable() async {
    final result =
        await methodChannel.invokeMethod<bool>('isNixAvailable');
    return result ?? false;
  }
}
