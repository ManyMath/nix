import Cocoa
import FlutterMacOS
import XCTest

@testable import nix

class RunnerTests: XCTestCase {
  func testGetPlatformVersion() {
    let plugin = NixPlugin()

    let call = FlutterMethodCall(methodName: "getPlatformVersion", arguments: [])

    let resultExpectation = expectation(description: "result block must be called.")
    plugin.handle(call) { result in
      XCTAssertEqual(result as! String,
                     "macOS " + ProcessInfo.processInfo.operatingSystemVersionString)
      resultExpectation.fulfill()
    }
    waitForExpectations(timeout: 1)
  }
}
