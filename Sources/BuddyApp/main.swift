import Cocoa

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    let controller = BuddyController()
    func applicationDidFinishLaunching(_ notification: Foundation.Notification) {
        NSApp.setActivationPolicy(.accessory)
        controller.start()
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
