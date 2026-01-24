import Cocoa

// MARK: - Configuration

/// Your display IDs from `displayplacer list`
let macbookID = "37D8832A-2D66-02CA-B9F7-8F30A301B230"
let ultrawideID = "36B23281-E071-42D2-94E4-C6C177689F7C"

/// Monitor dimensions (scaled resolution)
let macbookSize = NSSize(width: 1728, height: 1117)
let ultrawideSize = NSSize(width: 2048, height: 853)

// MARK: - Snap Position

enum SnapPosition: String, CaseIterable {
    case left = "Left"
    case right = "Right"
    case topLeft = "Top Left"
    case topCenter = "Top Center"
    case topRight = "Top Right"
    case bottomLeft = "Bottom Left"
    case bottomCenter = "Bottom Center"
    case bottomRight = "Bottom Right"

    /// Calculate ultrawide origin relative to MacBook at (0,0)
    /// Position name = where MacBook appears relative to ultrawide
    /// So "left" means MacBook on left → ultrawide must be to the RIGHT (positive X)
    func ultrawideOrigin() -> NSPoint {
        // MacBook stays at (0,0). Position describes where MacBook appears.
        // If MacBook is "left" of ultrawide, ultrawide goes to the right (positive X).
        switch self {
        case .left:
            // MacBook on left → ultrawide to the RIGHT of MacBook
            return NSPoint(x: macbookSize.width, y: -(ultrawideSize.height - macbookSize.height) / 2)
        case .right:
            // MacBook on right → ultrawide to the LEFT of MacBook
            return NSPoint(x: -ultrawideSize.width, y: -(ultrawideSize.height - macbookSize.height) / 2)
        case .topLeft:
            // MacBook top-left → ultrawide below and to the right
            return NSPoint(x: macbookSize.width - 200, y: macbookSize.height)
        case .topCenter:
            // MacBook top-center → ultrawide directly below
            return NSPoint(x: (macbookSize.width - ultrawideSize.width) / 2, y: macbookSize.height)
        case .topRight:
            // MacBook top-right → ultrawide below and to the left
            return NSPoint(x: -ultrawideSize.width + 200, y: macbookSize.height)
        case .bottomLeft:
            // MacBook bottom-left → ultrawide above and to the right
            return NSPoint(x: macbookSize.width - 200, y: -ultrawideSize.height)
        case .bottomCenter:
            // MacBook bottom-center → ultrawide directly above
            return NSPoint(x: (macbookSize.width - ultrawideSize.width) / 2, y: -ultrawideSize.height)
        case .bottomRight:
            // MacBook bottom-right → ultrawide above and to the left
            return NSPoint(x: -ultrawideSize.width + 200, y: -ultrawideSize.height)
        }
    }

    var icon: String {
        switch self {
        case .left: return "←"
        case .right: return "→"
        case .topLeft: return "↖"
        case .topCenter: return "↑"
        case .topRight: return "↗"
        case .bottomLeft: return "↙"
        case .bottomCenter: return "↓"
        case .bottomRight: return "↘"
        }
    }
}

// MARK: - Position Picker View

class PositionPickerView: NSView {
    weak var delegate: PositionPickerDelegate?

    private var hoveredPosition: SnapPosition?
    private var trackingArea: NSTrackingArea?

    // Layout constants
    private let padding: CGFloat = 20
    private let scale: CGFloat = 0.08  // Scale down monitors for display
    private let snapZoneSize: CGFloat = 40

    override var isFlipped: Bool { true }

    override init(frame: NSRect) {
        super.init(frame: frame)
        setupTrackingArea()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupTrackingArea()
    }

    private func setupTrackingArea() {
        trackingArea = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .mouseMoved, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(trackingArea!)
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        guard let context = NSGraphicsContext.current?.cgContext else { return }

        // Background
        NSColor(white: 0.15, alpha: 1).setFill()
        bounds.fill()

        // Calculate scaled sizes
        let scaledUltrawide = NSSize(
            width: ultrawideSize.width * scale,
            height: ultrawideSize.height * scale
        )
        let scaledMacbook = NSSize(
            width: macbookSize.width * scale,
            height: macbookSize.height * scale
        )

        // Center the ultrawide in the view
        let centerX = bounds.midX
        let centerY = bounds.midY

        let ultrawideRect = NSRect(
            x: centerX - scaledUltrawide.width / 2,
            y: centerY - scaledUltrawide.height / 2,
            width: scaledUltrawide.width,
            height: scaledUltrawide.height
        )

        // Draw ultrawide monitor
        let ultrawidePath = NSBezierPath(roundedRect: ultrawideRect, xRadius: 4, yRadius: 4)
        NSColor(white: 0.3, alpha: 1).setFill()
        ultrawidePath.fill()
        NSColor(white: 0.5, alpha: 1).setStroke()
        ultrawidePath.lineWidth = 2
        ultrawidePath.stroke()

        // Label
        let label = "Ultrawide"
        let labelAttrs: [NSAttributedString.Key: Any] = [
            .foregroundColor: NSColor(white: 0.7, alpha: 1),
            .font: NSFont.systemFont(ofSize: 10)
        ]
        let labelSize = label.size(withAttributes: labelAttrs)
        label.draw(at: NSPoint(
            x: ultrawideRect.midX - labelSize.width / 2,
            y: ultrawideRect.midY - labelSize.height / 2
        ), withAttributes: labelAttrs)

        // Draw snap zones
        for position in SnapPosition.allCases {
            let zoneRect = snapZoneRect(for: position, ultrawideRect: ultrawideRect, scaledMacbook: scaledMacbook)
            drawSnapZone(context: context, rect: zoneRect, position: position, isHovered: position == hoveredPosition)
        }

        // Instructions
        let instructions = "Click where to place your MacBook"
        let instrAttrs: [NSAttributedString.Key: Any] = [
            .foregroundColor: NSColor(white: 0.6, alpha: 1),
            .font: NSFont.systemFont(ofSize: 11)
        ]
        let instrSize = instructions.size(withAttributes: instrAttrs)
        instructions.draw(at: NSPoint(
            x: bounds.midX - instrSize.width / 2,
            y: bounds.height - 25
        ), withAttributes: instrAttrs)
    }

    private func snapZoneRect(for position: SnapPosition, ultrawideRect: NSRect, scaledMacbook: NSSize) -> NSRect {
        let w = scaledMacbook.width
        let h = scaledMacbook.height

        switch position {
        case .left:
            return NSRect(x: ultrawideRect.minX - w - 10, y: ultrawideRect.midY - h/2, width: w, height: h)
        case .right:
            return NSRect(x: ultrawideRect.maxX + 10, y: ultrawideRect.midY - h/2, width: w, height: h)
        case .topLeft:
            return NSRect(x: ultrawideRect.minX, y: ultrawideRect.minY - h - 10, width: w, height: h)
        case .topCenter:
            return NSRect(x: ultrawideRect.midX - w/2, y: ultrawideRect.minY - h - 10, width: w, height: h)
        case .topRight:
            return NSRect(x: ultrawideRect.maxX - w, y: ultrawideRect.minY - h - 10, width: w, height: h)
        case .bottomLeft:
            return NSRect(x: ultrawideRect.minX, y: ultrawideRect.maxY + 10, width: w, height: h)
        case .bottomCenter:
            return NSRect(x: ultrawideRect.midX - w/2, y: ultrawideRect.maxY + 10, width: w, height: h)
        case .bottomRight:
            return NSRect(x: ultrawideRect.maxX - w, y: ultrawideRect.maxY + 10, width: w, height: h)
        }
    }

    private func drawSnapZone(context: CGContext, rect: NSRect, position: SnapPosition, isHovered: Bool) {
        let path = NSBezierPath(roundedRect: rect, xRadius: 3, yRadius: 3)

        if isHovered {
            NSColor(red: 0.3, green: 0.6, blue: 1.0, alpha: 0.8).setFill()
            NSColor(red: 0.4, green: 0.7, blue: 1.0, alpha: 1).setStroke()
        } else {
            NSColor(white: 0.25, alpha: 1).setFill()
            NSColor(white: 0.4, alpha: 1).setStroke()
        }

        path.fill()
        path.lineWidth = 1.5
        path.stroke()

        // Draw icon
        let icon = position.icon
        let iconAttrs: [NSAttributedString.Key: Any] = [
            .foregroundColor: isHovered ? NSColor.white : NSColor(white: 0.6, alpha: 1),
            .font: NSFont.systemFont(ofSize: 14, weight: .medium)
        ]
        let iconSize = icon.size(withAttributes: iconAttrs)
        icon.draw(at: NSPoint(
            x: rect.midX - iconSize.width / 2,
            y: rect.midY - iconSize.height / 2
        ), withAttributes: iconAttrs)
    }

    override func mouseMoved(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        updateHoveredPosition(at: point)
    }

    override func mouseExited(with event: NSEvent) {
        hoveredPosition = nil
        needsDisplay = true
    }

    override func mouseDown(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        if let position = positionAt(point) {
            delegate?.positionPicker(self, didSelect: position)
        }
    }

    private func updateHoveredPosition(at point: NSPoint) {
        let newHovered = positionAt(point)
        if newHovered != hoveredPosition {
            hoveredPosition = newHovered
            needsDisplay = true
        }
    }

    private func positionAt(_ point: NSPoint) -> SnapPosition? {
        let scaledUltrawide = NSSize(
            width: ultrawideSize.width * scale,
            height: ultrawideSize.height * scale
        )
        let scaledMacbook = NSSize(
            width: macbookSize.width * scale,
            height: macbookSize.height * scale
        )

        let ultrawideRect = NSRect(
            x: bounds.midX - scaledUltrawide.width / 2,
            y: bounds.midY - scaledUltrawide.height / 2,
            width: scaledUltrawide.width,
            height: scaledUltrawide.height
        )

        for position in SnapPosition.allCases {
            let rect = snapZoneRect(for: position, ultrawideRect: ultrawideRect, scaledMacbook: scaledMacbook)
            if rect.contains(point) {
                return position
            }
        }
        return nil
    }
}

// MARK: - Position Picker Delegate

protocol PositionPickerDelegate: AnyObject {
    func positionPicker(_ picker: PositionPickerView, didSelect position: SnapPosition)
}

// MARK: - Position Picker Window Controller

class PositionPickerWindowController: NSWindowController, PositionPickerDelegate {

    init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 450, height: 320),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Position MacBook"
        window.isReleasedWhenClosed = false
        window.level = .floating

        super.init(window: window)

        let pickerView = PositionPickerView(frame: window.contentView!.bounds)
        pickerView.autoresizingMask = [.width, .height]
        pickerView.delegate = self
        window.contentView?.addSubview(pickerView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func showPicker() {
        window?.center()
        showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func positionPicker(_ picker: PositionPickerView, didSelect position: SnapPosition) {
        applyPosition(position)
        close()
    }

    private func applyPosition(_ position: SnapPosition) {
        let origin = position.ultrawideOrigin()

        let command = """
        displayplacer \
        "id:\(macbookID) res:1728x1117 hz:120 color_depth:8 enabled:true scaling:on origin:(0,0) degree:0" \
        "id:\(ultrawideID) res:2048x853 hz:144 color_depth:8 enabled:true scaling:on origin:(\(Int(origin.x)),\(Int(origin.y))) degree:0"
        """

        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/bash")
        task.arguments = ["-c", command]

        do {
            try task.run()
            task.waitUntilExit()

            if task.terminationStatus == 0 {
                NotificationCenter.default.post(name: .positionChanged, object: position)
            } else {
                showErrorAlert()
            }
        } catch {
            print("Failed to apply position: \(error)")
            showErrorAlert()
        }
    }

    private func showErrorAlert() {
        let alert = NSAlert()
        alert.messageText = "Failed to reposition monitors"
        alert.informativeText = "Make sure displayplacer is installed and your monitors are connected."
        alert.alertStyle = .warning
        alert.runModal()
    }
}

extension Notification.Name {
    static let positionChanged = Notification.Name("positionChanged")
}

// MARK: - App Delegate

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var pickerController: PositionPickerWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenuBar()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(positionDidChange(_:)),
            name: .positionChanged,
            object: nil
        )
    }

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.title = "🖥️"
            button.action = #selector(statusItemClicked)
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
    }

    @objc private func statusItemClicked(_ sender: NSStatusBarButton) {
        let event = NSApp.currentEvent!

        if event.type == .rightMouseUp {
            // Right-click shows menu
            showMenu()
        } else {
            // Left-click opens picker
            openPicker()
        }
    }

    @objc private func openPicker() {
        if pickerController == nil {
            pickerController = PositionPickerWindowController()
        }
        pickerController?.showPicker()
    }

    private func showMenu() {
        let menu = NSMenu()

        let openItem = NSMenuItem(title: "Position Picker...", action: #selector(openPicker), keyEquivalent: "p")
        openItem.target = self
        menu.addItem(openItem)

        menu.addItem(NSMenuItem.separator())

        // Quick positions
        let leftItem = NSMenuItem(title: "← Left (Desk)", action: #selector(quickLeft), keyEquivalent: "d")
        leftItem.target = self
        menu.addItem(leftItem)

        let rightItem = NSMenuItem(title: "→ Right (Easy Chair)", action: #selector(quickRight), keyEquivalent: "e")
        rightItem.target = self
        menu.addItem(rightItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        menu.addItem(quitItem)

        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil  // Clear so left-click works again
    }

    @objc private func quickLeft() {
        applyQuickPosition(.left)
    }

    @objc private func quickRight() {
        applyQuickPosition(.right)
    }

    private func applyQuickPosition(_ position: SnapPosition) {
        let origin = position.ultrawideOrigin()

        let command = """
        displayplacer \
        "id:\(macbookID) res:1728x1117 hz:120 color_depth:8 enabled:true scaling:on origin:(0,0) degree:0" \
        "id:\(ultrawideID) res:2048x853 hz:144 color_depth:8 enabled:true scaling:on origin:(\(Int(origin.x)),\(Int(origin.y))) degree:0"
        """

        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/bash")
        task.arguments = ["-c", command]

        do {
            try task.run()
            task.waitUntilExit()
        } catch {
            print("Failed to apply position: \(error)")
        }
    }

    @objc private func positionDidChange(_ notification: Notification) {
        // Could update icon based on position if desired
    }
}

// MARK: - Main

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
