import Cocoa

// MARK: - Configuration

/// Your display IDs from `displayplacer list`
let macbookID = "37D8832A-2D66-02CA-B9F7-8F30A301B230"
let ultrawideID = "36B23281-E071-42D2-94E4-C6C177689F7C"

/// Position configurations
/// - Desk: Laptop at origin, ultrawide to the RIGHT and UP (20% overlap)
/// - EasyChair: Laptop at origin, ultrawide to the LEFT and UP
struct MonitorConfig {
    static let desk = """
    displayplacer \
    "id:\(macbookID) res:1728x1117 hz:120 color_depth:8 enabled:true scaling:on origin:(0,0) degree:0" \
    "id:\(ultrawideID) res:2048x853 hz:144 color_depth:8 enabled:true scaling:on origin:(1728,-253) degree:0"
    """

    static let easyChair = """
    displayplacer \
    "id:\(macbookID) res:1728x1117 hz:120 color_depth:8 enabled:true scaling:on origin:(0,0) degree:0" \
    "id:\(ultrawideID) res:2048x853 hz:144 color_depth:8 enabled:true scaling:on origin:(-2048,-253) degree:0"
    """
}

// MARK: - Position State

enum Position: String {
    case desk = "Desk"
    case easyChair = "Easy Chair"

    var icon: String {
        switch self {
        case .desk: return "🖥️"  // Monitor on right
        case .easyChair: return "🪑"  // Chair mode
        }
    }

    var toggled: Position {
        self == .desk ? .easyChair : .desk
    }
}

// MARK: - App Delegate

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var currentPosition: Position = .easyChair  // Default assumption based on current config

    func applicationDidFinishLaunching(_ notification: Notification) {
        detectCurrentPosition()
        setupMenuBar()
    }

    private func detectCurrentPosition() {
        // Run displayplacer list and check the origin of the ultrawide
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/opt/homebrew/bin/displayplacer")
        task.arguments = ["list"]

        let pipe = Pipe()
        task.standardOutput = pipe

        do {
            try task.run()
            task.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                // Look for the ultrawide's origin
                // If origin contains negative X (like -2048), it's on the left (easy chair)
                // If origin contains positive X (like 1728), it's on the right (desk)
                let lines = output.components(separatedBy: "\n")
                var foundUltrawide = false

                for line in lines {
                    if line.contains("38 inch external") {
                        foundUltrawide = true
                    }
                    if foundUltrawide && line.contains("Origin:") {
                        if line.contains("(-") {
                            currentPosition = .easyChair
                        } else {
                            currentPosition = .desk
                        }
                        break
                    }
                }
            }
        } catch {
            print("Failed to detect position: \(error)")
        }
    }

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        updateIcon()

        let menu = NSMenu()

        // Current status
        let statusItem = NSMenuItem(title: "Current: \(currentPosition.rawValue)", action: nil, keyEquivalent: "")
        statusItem.isEnabled = false
        menu.addItem(statusItem)

        menu.addItem(NSMenuItem.separator())

        // Toggle action
        let toggleItem = NSMenuItem(
            title: "Switch to \(currentPosition.toggled.rawValue)",
            action: #selector(togglePosition),
            keyEquivalent: "s"
        )
        toggleItem.target = self
        menu.addItem(toggleItem)

        menu.addItem(NSMenuItem.separator())

        // Manual position options
        let deskItem = NSMenuItem(title: "Desk Position", action: #selector(setDeskPosition), keyEquivalent: "d")
        deskItem.target = self
        if currentPosition == .desk {
            deskItem.state = .on
        }
        menu.addItem(deskItem)

        let chairItem = NSMenuItem(title: "Easy Chair Position", action: #selector(setEasyChairPosition), keyEquivalent: "e")
        chairItem.target = self
        if currentPosition == .easyChair {
            chairItem.state = .on
        }
        menu.addItem(chairItem)

        menu.addItem(NSMenuItem.separator())

        // Quit
        let quitItem = NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quitItem)

        self.statusItem.menu = menu
    }

    private func updateIcon() {
        if let button = statusItem.button {
            button.title = currentPosition.icon
        }
    }

    private func rebuildMenu() {
        setupMenuBar()
    }

    @objc private func togglePosition() {
        let newPosition = currentPosition.toggled
        applyPosition(newPosition)
    }

    @objc private func setDeskPosition() {
        applyPosition(.desk)
    }

    @objc private func setEasyChairPosition() {
        applyPosition(.easyChair)
    }

    private func applyPosition(_ position: Position) {
        let command = position == .desk ? MonitorConfig.desk : MonitorConfig.easyChair

        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/bash")
        task.arguments = ["-c", command]

        do {
            try task.run()
            task.waitUntilExit()

            if task.terminationStatus == 0 {
                currentPosition = position
                updateIcon()
                rebuildMenu()
                showNotification(position: position)
            } else {
                showErrorAlert()
            }
        } catch {
            print("Failed to apply position: \(error)")
            showErrorAlert()
        }
    }

    private func showNotification(position: Position) {
        // Simple visual feedback - the icon change is enough
        // Could add UserNotifications framework later if needed
        print("Switched to \(position.rawValue) position")
    }

    private func showErrorAlert() {
        let alert = NSAlert()
        alert.messageText = "Failed to swap monitors"
        alert.informativeText = "Make sure displayplacer is installed and your monitors are connected."
        alert.alertStyle = .warning
        alert.runModal()
    }
}

// MARK: - Main

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
