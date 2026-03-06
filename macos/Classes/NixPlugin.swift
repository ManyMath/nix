import Cocoa
import FlutterMacOS

public class NixPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "nix", binaryMessenger: registrar.messenger)
    let instance = NixPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPlatformVersion":
      result("macOS " + ProcessInfo.processInfo.operatingSystemVersionString)
    case "getNixEnvironmentInfo":
      DispatchQueue.global(qos: .userInitiated).async {
        let info = self.getNixEnvironmentInfo()
        DispatchQueue.main.async { result(info) }
      }
    case "listNixPackages":
      DispatchQueue.global(qos: .userInitiated).async {
        let packages = self.listNixPackages()
        DispatchQueue.main.async { result(packages) }
      }
    case "isNixAvailable":
      DispatchQueue.global(qos: .userInitiated).async {
        let available = self.isNixAvailable()
        DispatchQueue.main.async { result(available) }
      }
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func getNixEnvironmentInfo() -> [String: Any?] {
    let nixBin = findNixBinary()
    let installed = nixBin != nil
    var version: String? = nil
    var storePath: String? = nil
    var currentSystem: String? = nil

    if let bin = nixBin {
      version = runProcess(bin, arguments: ["--version"])?.trimmingCharacters(in: .whitespacesAndNewlines)
      if FileManager.default.fileExists(atPath: "/nix/store") {
        storePath = "/nix/store"
      }
    }

    var sysinfo = utsname()
    uname(&sysinfo)
    let machine = withUnsafePointer(to: &sysinfo.machine) {
      $0.withMemoryRebound(to: CChar.self, capacity: Int(_SYS_NAMELEN)) {
        String(cString: $0)
      }
    }
    currentSystem = machine == "arm64" ? "aarch64-darwin" : "x86_64-darwin"

    return [
      "isInstalled": installed,
      "nixVersion": version,
      "nixStorePath": storePath,
      "currentSystem": currentSystem,
      "platform": "macos",
    ]
  }

  private func listNixPackages() -> [[String: Any?]] {
    guard let nixBin = findNixBinary() else { return [] }

    guard let output = runProcess(nixBin, arguments: ["profile", "list"]) else { return [] }

    var packages: [[String: Any?]] = []
    for line in output.components(separatedBy: "\n") where !line.isEmpty {
      let parts = line.split(separator: " ", maxSplits: 3).map(String.init)
      if parts.count >= 2 {
        let path = parts.count >= 3 ? parts[2] : nil
        let name = extractPackageName(from: path ?? parts[1])
        let version = extractVersion(from: path ?? parts[1])
        packages.append([
          "name": name,
          "version": version,
          "storePath": path,
        ])
      }
    }
    return packages
  }

  private func isNixAvailable() -> Bool {
    return findNixBinary() != nil
  }

  private func findNixBinary() -> String? {
    let candidates = [
      "\(NSHomeDirectory())/.nix-profile/bin/nix",
      "/nix/var/nix/profiles/default/bin/nix",
      "/nix/var/nix/profiles/per-user/\(NSUserName())/profile/bin/nix",
      "/run/current-system/sw/bin/nix",
      "/usr/local/bin/nix",
      "/etc/profiles/per-user/\(NSUserName())/bin/nix",
    ]
    for path in candidates {
      if FileManager.default.isExecutableFile(atPath: path) {
        return path
      }
    }
    return nil
  }

  private func runProcess(_ path: String, arguments: [String]) -> String? {
    let process = Process()
    let pipe = Pipe()
    process.executableURL = URL(fileURLWithPath: path)
    process.arguments = arguments
    process.standardOutput = pipe
    process.standardError = FileHandle.nullDevice
    do {
      try process.run()
      // Read before waiting to avoid pipe buffer deadlock.
      let data = pipe.fileHandleForReading.readDataToEndOfFile()
      process.waitUntilExit()
      return String(data: data, encoding: .utf8)
    } catch {
      return nil
    }
  }

  private func extractPackageName(from storePath: String) -> String {
    let base = (storePath as NSString).lastPathComponent
    guard let dashIndex = base.firstIndex(of: "-") else { return base }
    return String(base[base.index(after: dashIndex)...])
  }

  private func extractVersion(from storePath: String) -> String? {
    let name = extractPackageName(from: storePath)
    // Find the last hyphen followed by a digit (name-version boundary).
    if let range = name.range(of: #"-\d"#, options: [.regularExpression, .backwards],
                              range: name.startIndex..<name.endIndex) {
      return String(name[name.index(after: range.lowerBound)...])
    }
    return nil
  }
}
