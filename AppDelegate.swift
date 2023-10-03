//
// frontapp
// https://github.com/luckman212/frontapp
//
// https://developer.apple.com/documentation/appkit/nsworkspace/1535049-didactivateapplicationnotificati
//

import Cocoa
import AVFoundation
let fontName = "SFMono-Regular"

class NoWrapTextView: NSTextView {
    override func draw(_ dirtyRect: NSRect) {
        self.textContainer?.containerSize = NSMakeSize(CGFloat.greatestFiniteMagnitude, CGFloat.greatestFiniteMagnitude)
        self.textContainer?.widthTracksTextView = false
        self.isHorizontallyResizable = true
        self.textContainer?.lineBreakMode = .byClipping
        self.font = NSFont(name: fontName, size: 12)
        super.draw(dirtyRect)
    }
}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {

    @IBOutlet weak var mainWindow: NSWindow!
    @IBOutlet weak var logTextView: NSTextView!
    @IBOutlet weak var playSoundsMenuItem: NSMenuItem!
    
    var lastActiveAppName: String?
    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    var changeSound: AVAudioPlayer?
    var shouldPlaySounds = false

    @IBAction func toggleSoundPlayback(_ sender: NSMenuItem) {
        shouldPlaySounds.toggle()
        UserDefaults.standard.set(shouldPlaySounds, forKey: "shouldPlaySounds")
        playSoundsMenuItem?.state = shouldPlaySounds ? .on : .off
        self.logToWindowAndConsole("=== play sound: \(shouldPlaySounds) ===")
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        mainWindow.delegate = self
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(appChanged), name: NSWorkspace.didActivateApplicationNotification, object: nil)
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
        if let soundPref = UserDefaults.standard.value(forKey: "shouldPlaySounds") as? Bool {
            shouldPlaySounds = soundPref
        }
        mainWindow.makeKeyAndOrderFront(nil)
        logTextView.isEditable = false
        logTextView.usesFontPanel = false
        logTextView.font = NSFont(name: fontName, size: 12)
        logTextView.backgroundColor = NSColor.black
        //logTextView.textContainer?.lineBreakMode = .byClipping
        statusItem.button?.action = #selector(toggleWindow)
        if let soundPref = UserDefaults.standard.value(forKey: "shouldPlaySounds") as? Bool {
            shouldPlaySounds = soundPref
            playSoundsMenuItem.state = shouldPlaySounds ? .on : .off
        }
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
                self.logTextView.scrollRangeToVisible(NSMakeRange(self.logTextView.string.count, 0))
            }
        }
    }
    
    func playSound() {
        if let soundURL = Bundle.main.url(forResource: "EmptySpace", withExtension: "aiff") {
            changeSound = try? AVAudioPlayer(contentsOf: soundURL)
            changeSound?.play()
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
                    if self.shouldPlaySounds {
                        self.playSound()
                    }
                }
                if let button = statusItem.button {
                    button.title = "\(appName)"
                }
            }
        }
    }
}
