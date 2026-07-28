import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    let channel = FlutterMethodChannel(
      name: "com.borasarang.anywheretv/window",
      binaryMessenger: flutterViewController.engine.binaryMessenger
    )
    channel.setMethodCallHandler { call, result in
      if call.method == "toggleFullscreen" {
        if let window = NSApplication.shared.windows.first {
          window.toggleFullScreen(nil)
          result(nil)
        } else {
          result(FlutterError(code: "NO_WINDOW", message: "No window found", details: nil))
        }
      } else {
        result(FlutterMethodNotImplemented)
      }
    }

    super.awakeFromNib()
  }
}