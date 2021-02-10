import Cocoa

class AppDelegate: NSObject {
    private var windowController: NSWindowController?
}

extension AppDelegate: NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        guard NSClassFromString("NSTouchBar") != nil else {
            exit(0)
        }
        windowController = NSWindowController(
            window: NSWindow(
                contentViewController: PomodoroController()
            )
        )
        windowController?.loadWindow()
    }
}
