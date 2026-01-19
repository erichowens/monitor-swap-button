#!/usr/bin/env swift

import Cocoa

/// Generates a monitor swap icon - two monitors with bidirectional arrow
func generateIcon(size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))

    image.lockFocus()

    let ctx = NSGraphicsContext.current!.cgContext

    // Background - rounded square with gradient
    let bgRect = CGRect(x: size * 0.05, y: size * 0.05, width: size * 0.9, height: size * 0.9)
    let bgPath = CGPath(roundedRect: bgRect, cornerWidth: size * 0.18, cornerHeight: size * 0.18, transform: nil)

    // Gradient background (dark blue to purple)
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let colors = [
        CGColor(red: 0.2, green: 0.3, blue: 0.6, alpha: 1.0),
        CGColor(red: 0.4, green: 0.2, blue: 0.5, alpha: 1.0)
    ] as CFArray
    let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: [0, 1])!

    ctx.saveGState()
    ctx.addPath(bgPath)
    ctx.clip()
    ctx.drawLinearGradient(gradient, start: CGPoint(x: 0, y: size), end: CGPoint(x: size, y: 0), options: [])
    ctx.restoreGState()

    // Monitor dimensions
    let monitorWidth = size * 0.3
    let monitorHeight = size * 0.22
    let screenInset = size * 0.025

    // Left monitor
    let leftMonitorX = size * 0.12
    let monitorY = size * 0.45

    drawMonitor(ctx: ctx, x: leftMonitorX, y: monitorY, width: monitorWidth, height: monitorHeight, screenInset: screenInset, size: size)

    // Right monitor
    let rightMonitorX = size * 0.58
    drawMonitor(ctx: ctx, x: rightMonitorX, y: monitorY, width: monitorWidth, height: monitorHeight, screenInset: screenInset, size: size)

    // Bidirectional arrow between monitors
    let arrowY = monitorY + monitorHeight / 2
    let arrowStartX = leftMonitorX + monitorWidth + size * 0.03
    let arrowEndX = rightMonitorX - size * 0.03
    let arrowMidX = (arrowStartX + arrowEndX) / 2

    ctx.setStrokeColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.95))
    ctx.setLineWidth(size * 0.025)
    ctx.setLineCap(.round)
    ctx.setLineJoin(.round)

    // Top arrow (pointing right)
    let topArrowY = arrowY + size * 0.04
    ctx.move(to: CGPoint(x: arrowStartX, y: topArrowY))
    ctx.addLine(to: CGPoint(x: arrowEndX, y: topArrowY))
    ctx.strokePath()

    // Right arrowhead
    ctx.move(to: CGPoint(x: arrowEndX - size * 0.04, y: topArrowY + size * 0.03))
    ctx.addLine(to: CGPoint(x: arrowEndX, y: topArrowY))
    ctx.addLine(to: CGPoint(x: arrowEndX - size * 0.04, y: topArrowY - size * 0.03))
    ctx.strokePath()

    // Bottom arrow (pointing left)
    let bottomArrowY = arrowY - size * 0.04
    ctx.move(to: CGPoint(x: arrowEndX, y: bottomArrowY))
    ctx.addLine(to: CGPoint(x: arrowStartX, y: bottomArrowY))
    ctx.strokePath()

    // Left arrowhead
    ctx.move(to: CGPoint(x: arrowStartX + size * 0.04, y: bottomArrowY + size * 0.03))
    ctx.addLine(to: CGPoint(x: arrowStartX, y: bottomArrowY))
    ctx.addLine(to: CGPoint(x: arrowStartX + size * 0.04, y: bottomArrowY - size * 0.03))
    ctx.strokePath()

    image.unlockFocus()
    return image
}

func drawMonitor(ctx: CGContext, x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat, screenInset: CGFloat, size: CGFloat) {
    // Monitor bezel (white/light gray)
    let bezelRect = CGRect(x: x, y: y, width: width, height: height)
    let bezelPath = CGPath(roundedRect: bezelRect, cornerWidth: size * 0.02, cornerHeight: size * 0.02, transform: nil)

    ctx.setFillColor(CGColor(red: 0.95, green: 0.95, blue: 0.97, alpha: 1.0))
    ctx.addPath(bezelPath)
    ctx.fillPath()

    // Screen (dark with slight blue tint)
    let screenRect = CGRect(x: x + screenInset, y: y + screenInset + size * 0.02,
                            width: width - screenInset * 2, height: height - screenInset * 2 - size * 0.03)
    let screenPath = CGPath(roundedRect: screenRect, cornerWidth: size * 0.01, cornerHeight: size * 0.01, transform: nil)

    ctx.setFillColor(CGColor(red: 0.15, green: 0.2, blue: 0.3, alpha: 1.0))
    ctx.addPath(screenPath)
    ctx.fillPath()

    // Stand
    let standWidth = size * 0.06
    let standHeight = size * 0.06
    let standX = x + width / 2 - standWidth / 2
    let standY = y - standHeight

    ctx.setFillColor(CGColor(red: 0.7, green: 0.7, blue: 0.72, alpha: 1.0))
    ctx.fill(CGRect(x: standX, y: standY, width: standWidth, height: standHeight))

    // Base
    let baseWidth = size * 0.1
    let baseHeight = size * 0.015
    let baseX = x + width / 2 - baseWidth / 2
    let baseY = standY - baseHeight

    ctx.setFillColor(CGColor(red: 0.6, green: 0.6, blue: 0.62, alpha: 1.0))
    let basePath = CGPath(roundedRect: CGRect(x: baseX, y: baseY, width: baseWidth, height: baseHeight),
                          cornerWidth: size * 0.005, cornerHeight: size * 0.005, transform: nil)
    ctx.addPath(basePath)
    ctx.fillPath()
}

// Generate icons at all required sizes
let sizes: [CGFloat] = [16, 32, 64, 128, 256, 512, 1024]
let iconsetPath = "MonitorSwap.iconset"

// Create iconset directory
let fm = FileManager.default
try? fm.createDirectory(atPath: iconsetPath, withIntermediateDirectories: true)

for size in sizes {
    let image = generateIcon(size: size)

    // Save 1x
    if let tiffData = image.tiffRepresentation,
       let bitmap = NSBitmapImageRep(data: tiffData),
       let pngData = bitmap.representation(using: .png, properties: [:]) {
        let filename = "icon_\(Int(size))x\(Int(size)).png"
        try? pngData.write(to: URL(fileURLWithPath: "\(iconsetPath)/\(filename)"))
        print("Generated \(filename)")
    }

    // Save 2x (for retina) - only for sizes up to 512
    if size <= 512 {
        let image2x = generateIcon(size: size * 2)
        if let tiffData = image2x.tiffRepresentation,
           let bitmap = NSBitmapImageRep(data: tiffData),
           let pngData = bitmap.representation(using: .png, properties: [:]) {
            let filename = "icon_\(Int(size))x\(Int(size))@2x.png"
            try? pngData.write(to: URL(fileURLWithPath: "\(iconsetPath)/\(filename)"))
            print("Generated \(filename)")
        }
    }
}

print("\nIconset created. Run: iconutil -c icns MonitorSwap.iconset")
