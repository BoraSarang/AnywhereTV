import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  override func applicationWillFinishLaunching(_ notification: Notification) {
    let bundleId = Bundle.main.bundleIdentifier ?? "com.borasarang.anywheretv"
    let running = NSRunningApplication.runningApplications(withBundleIdentifier: bundleId)
    if running.count > 1 {
      if let existing = running.first(where: { $0 != NSRunningApplication.current }) {
        existing.activate(options: .activateIgnoringOtherApps)
        NSApplication.shared.terminate(nil)
        return
      }
    }
    super.applicationWillFinishLaunching(notification)
  }

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
}