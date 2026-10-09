import AppKit
import Foundation

let outputDirectory = CommandLine.arguments.dropFirst().first ?? "Resources"
try FileManager.default.createDirectory(atPath: outputDirectory, withIntermediateDirectories: true)
let size = 1024
let image = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size,
                             bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                             isPlanar: false, colorSpaceName: .deviceRGB,
                             bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.saveGraphicsState()
let context = NSGraphicsContext(bitmapImageRep: image)!
NSGraphicsContext.current = context
context.imageInterpolation = .high
NSColor.clear.setFill()
NSRect(x: 0, y: 0, width: size, height: size).fill()

func roundedRect(_ rect: NSRect, radius: CGFloat) -> NSBezierPath {
    NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
}

let base = roundedRect(NSRect(x: 26, y: 26, width: 972, height: 972), radius: 218)
NSGradient(colors: [NSColor(calibratedRed: 0.11, green: 0.2, blue: 0.48, alpha: 1),
                    NSColor(calibratedRed: 0.28, green: 0.24, blue: 0.68, alpha: 1),
                    NSColor(calibratedRed: 0.08, green: 0.53, blue: 0.68, alpha: 1)])!
    .draw(in: base, angle: -42)

// A soft, off-center glow gives the icon some depth at small Dock sizes.
NSColor(calibratedRed: 0.48, green: 0.78, blue: 1, alpha: 0.18).setFill()
NSBezierPath(ovalIn: NSRect(x: 626, y: 616, width: 360, height: 360)).fill()
NSColor(calibratedRed: 0.67, green: 0.42, blue: 1, alpha: 0.14).setFill()
NSBezierPath(ovalIn: NSRect(x: 38, y: 34, width: 400, height: 400)).fill()

// Fine inner edge, similar to macOS system-icon materials.
NSColor.white.withAlphaComponent(0.22).setStroke()
base.lineWidth = 3
base.stroke()

// Floating frosted panel that contains the colorful app tiles.
let panel = roundedRect(NSRect(x: 174, y: 158, width: 676, height: 708), radius: 146)
let shadow = NSShadow()
shadow.shadowColor = NSColor.black.withAlphaComponent(0.3)
shadow.shadowBlurRadius = 38
shadow.shadowOffset = NSSize(width: 0, height: -20)
shadow.set()
NSColor(calibratedWhite: 0.96, alpha: 0.94).setFill()
panel.fill()
NSShadow().set()
NSColor.white.withAlphaComponent(0.84).setStroke()
panel.lineWidth = 2
panel.stroke()

let colors: [[NSColor]] = [
    [NSColor(calibratedRed: 0.12, green: 0.83, blue: 0.36, alpha: 1), NSColor(calibratedRed: 0.08, green: 0.67, blue: 0.25, alpha: 1)],
    [NSColor(calibratedRed: 1.0, green: 0.68, blue: 0.1, alpha: 1), NSColor(calibratedRed: 0.96, green: 0.47, blue: 0.04, alpha: 1)],
    [NSColor(calibratedRed: 1.0, green: 0.82, blue: 0.16, alpha: 1), NSColor(calibratedRed: 0.97, green: 0.65, blue: 0.02, alpha: 1)],
    [NSColor(calibratedRed: 1.0, green: 0.25, blue: 0.4, alpha: 1), NSColor(calibratedRed: 0.87, green: 0.08, blue: 0.28, alpha: 1)],
    [NSColor(calibratedRed: 0.48, green: 0.56, blue: 1.0, alpha: 1), NSColor(calibratedRed: 0.34, green: 0.32, blue: 0.89, alpha: 1)],
    [NSColor(calibratedRed: 0.08, green: 0.78, blue: 0.72, alpha: 1), NSColor(calibratedRed: 0.02, green: 0.61, blue: 0.65, alpha: 1)],
    [NSColor(calibratedRed: 0.82, green: 0.38, blue: 0.96, alpha: 1), NSColor(calibratedRed: 0.65, green: 0.2, blue: 0.86, alpha: 1)],
    [NSColor(calibratedRed: 0.42, green: 0.68, blue: 1.0, alpha: 1), NSColor(calibratedRed: 0.26, green: 0.47, blue: 0.93, alpha: 1)],
    [NSColor(calibratedRed: 0.12, green: 0.82, blue: 0.72, alpha: 1), NSColor(calibratedRed: 0.04, green: 0.64, blue: 0.67, alpha: 1)]
]

let tileSize: CGFloat = 132
let spacing: CGFloat = 38
let startX: CGFloat = 285
let startY: CGFloat = 286
for row in 0..<3 {
    for column in 0..<3 {
        let index = row * 3 + column
        let rect = NSRect(x: startX + CGFloat(column) * (tileSize + spacing),
                          y: startY + CGFloat(2 - row) * (tileSize + spacing),
                          width: tileSize, height: tileSize)
        let tile = roundedRect(rect, radius: 36)
        let tileShadow = NSShadow()
        tileShadow.shadowColor = NSColor.black.withAlphaComponent(0.17)
        tileShadow.shadowBlurRadius = 12
        tileShadow.shadowOffset = NSSize(width: 0, height: -6)
        tileShadow.set()
        NSGradient(colors: colors[index])!.draw(in: tile, angle: 90)
        NSShadow().set()
        NSColor.white.withAlphaComponent(0.2).setStroke()
        tile.lineWidth = 2
        tile.stroke()
        if index == 4 {
            let centerX = rect.midX
            let centerY = rect.midY
            let star = NSBezierPath()
            let points = [
                NSPoint(x: centerX, y: centerY + 42), NSPoint(x: centerX + 10, y: centerY + 10),
                NSPoint(x: centerX + 42, y: centerY), NSPoint(x: centerX + 10, y: centerY - 10),
                NSPoint(x: centerX, y: centerY - 42), NSPoint(x: centerX - 10, y: centerY - 10),
                NSPoint(x: centerX - 42, y: centerY), NSPoint(x: centerX - 10, y: centerY + 10)
            ]
            star.move(to: points[0])
            for point in points.dropFirst() { star.line(to: point) }
            star.close()
            let glow = NSShadow()
            glow.shadowColor = NSColor.white.withAlphaComponent(0.65)
            glow.shadowBlurRadius = 20
            glow.set()
            NSColor.white.setFill()
            star.fill()
            NSShadow().set()
        }
    }
}

context.flushGraphics()
NSGraphicsContext.restoreGraphicsState()
let png = image.representation(using: .png, properties: [:])!
let pngPath = URL(fileURLWithPath: outputDirectory).appendingPathComponent("AppIcon.png")
try png.write(to: pngPath)

let iconsetPath = URL(fileURLWithPath: outputDirectory).appendingPathComponent("AppIcon.iconset")
try? FileManager.default.removeItem(at: iconsetPath)
try FileManager.default.createDirectory(at: iconsetPath, withIntermediateDirectories: true)
let sizes: [(String, Int)] = [
    ("icon_16x16.png", 16), ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32), ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128), ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256), ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512), ("icon_512x512@2x.png", 1024)
]
for (name, dimension) in sizes {
    let destination = iconsetPath.appendingPathComponent(name)
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/sips")
    process.arguments = ["-z", "\(dimension)", "\(dimension)", pngPath.path, "--out", destination.path]
    try process.run()
    process.waitUntilExit()
    guard process.terminationStatus == 0 else { fatalError("Could not create \(name)") }
}
let iconsetProcess = Process()
iconsetProcess.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
iconsetProcess.arguments = ["-c", "icns", iconsetPath.path, "-o", URL(fileURLWithPath: outputDirectory).appendingPathComponent("AppIcon.icns").path]
try iconsetProcess.run()
iconsetProcess.waitUntilExit()
guard iconsetProcess.terminationStatus == 0 else { fatalError("Could not create the ICNS icon") }
print("Generated \(pngPath.path)")
