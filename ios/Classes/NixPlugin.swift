import Flutter
import UIKit

public class NixPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "nix", binaryMessenger: registrar.messenger())
    let instance = NixPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPlatformVersion":
      result("iOS " + UIDevice.current.systemVersion)
    case "getNixEnvironmentInfo":
      result([
        "isInstalled": false,
        "nixVersion": nil,
        "nixStorePath": nil,
        "currentSystem": nil,
        "platform": "ios",
      ] as [String: Any?])
    case "listNixPackages":
      result([] as [[String: Any?]])
    case "isNixAvailable":
      result(false)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
