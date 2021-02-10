import Foundation

let app = NSApplication.shared
let delegate = AppDelegate()
app.setActivationPolicy(.prohibited)
app.delegate = delegate
app.run()
