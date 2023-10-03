//
// frontapp - luckman212
//
// https://developer.apple.com/documentation/appkit/nsworkspace/1535049-didactivateapplicationnotificati
//

import Cocoa
let fontName = "SFMono-Regular"

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {

    @IBOutlet weak var mainWindow: NSWindow!
    @IBOutlet weak var logTextView: NSTextView!
    
    var lastActiveAppName: String?
    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        mainWindow.delegate = self
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(appChanged), name: NSWorkspace.didActivateApplicationNotification, object: nil)
        logTextView.isEditable = false
        logTextView.usesFontPanel = false
        logTextView.font = NSFont(name: fontName, size: 12)
        if let frontmostApp = NSWorkspace.shared.frontmostApplication,
            let appName = frontmostApp.localizedName {
                if let button = statusItem.button {
                    button.title = "\(appName)"
                }
            }
        mainWindow.orderOut(nil)
        if let frameString = UserDefaults.standard.string(forKey: "windowFrame") {
            mainWindow.setFrame(NSRectFromString(frameString), display: true)
        }
        mainWindow.makeKeyAndOrderFront(nil)
        /*
            let menu = NSMenu()
            let toggleWindowMenuItem = NSMenuItem(title: "Toggle Window", action: #selector(toggleWindow), keyEquivalent: "")
            menu.addItem(toggleWindowMenuItem)
            statusItem.menu = menu
        */
        statusItem.button?.action = #selector(toggleWindow)
        self.logToWindowAndConsole("=== logging started ===")
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        let frameString = NSStringFromRect(mainWindow.frame)
        UserDefaults.standard.set(frameString, forKey: "windowFrame")
    }

    func windowDidResize(_ notification: Notification) {
        let frameString = NSStringFromRect(mainWindow.frame)
        UserDefaults.standard.set(frameString, forKey: "windowFrame")
    }

    func logToWindowAndConsole(_ message: String) {
        //let currentTime = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .medium)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        let currentTime = formatter.string(from: Date())
        let logmsg = "\(currentTime)  \(message)\n"
        print(logmsg, terminator: "")
        DispatchQueue.main.async {
            if let mutableString = self.logTextView.textStorage {
                let attrString = NSAttributedString(string: logmsg, attributes: [.font: NSFont(name: fontName, size: 12)!, .foregroundColor: NSColor.white])
                mutableString.append(attrString)
            }
        }
    }
    
    @objc func toggleWindow() {
        if mainWindow.isVisible {
            mainWindow.orderOut(nil)
        } else {
            mainWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
    
    @objc func appChanged(_ notification: Notification) {
        if let userInfo = notification.userInfo,
           let appInfo = userInfo[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
           let appName = appInfo.localizedName {

            if appName != lastActiveAppName {
                lastActiveAppName = appName
                let appIdentifier = appInfo.bundleIdentifier ?? "Unknown"
                let appPath = appInfo.bundleURL?.path ?? "Unknown"
                let processIdentifier = appInfo.processIdentifier
                DispatchQueue.main.async {
                    let logText = "\(appPath) (\(appName)/\(appIdentifier)/\(processIdentifier))"
                    self.logToWindowAndConsole(logText)
                    /*
                    print(logText, terminator: "")
                    if let mutableString = self.logTextView.textStorage {
                        let attrString = NSAttributedString(string: logText, attributes: [.font: NSFont(name: fontName, size: 12)!])
                        mutableString.append(attrString)
                    }
                    */
                }
                if let button = statusItem.button {
                    button.title = "\(appName)"
                }
            }
        }
    }
}
