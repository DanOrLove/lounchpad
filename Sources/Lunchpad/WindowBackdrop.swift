import AppKit
import SwiftUI

/// A fixed macOS desktop material for the launcher's translucent backdrop.
struct WindowBackdrop: NSViewRepresentable {
    var tint: NSColor

    func makeNSView(context: Context) -> BackdropHostView {
        let view = BackdropHostView()
        view.update(tint: tint)
        return view
    }

    func updateNSView(_ view: BackdropHostView, context: Context) {
        view.update(tint: tint)
    }
}

final class BackdropHostView: NSView {
    private let materialView = NSVisualEffectView()
    private let tintView = NSView()

    override var isOpaque: Bool { false }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor

        materialView.material = .underWindowBackground
        materialView.blendingMode = .behindWindow
        materialView.state = .active
        materialView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(materialView)

        tintView.wantsLayer = true
        tintView.layer?.backgroundColor = NSColor.clear.cgColor
        tintView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(tintView)

        NSLayoutConstraint.activate([
            materialView.leadingAnchor.constraint(equalTo: leadingAnchor),
            materialView.trailingAnchor.constraint(equalTo: trailingAnchor),
            materialView.topAnchor.constraint(equalTo: topAnchor),
            materialView.bottomAnchor.constraint(equalTo: bottomAnchor),
            tintView.leadingAnchor.constraint(equalTo: leadingAnchor),
            tintView.trailingAnchor.constraint(equalTo: trailingAnchor),
            tintView.topAnchor.constraint(equalTo: topAnchor),
            tintView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        update(tint: NSColor(lunchpadHex: "#20283A") ?? .black)
    }

    required init?(coder: NSCoder) { nil }

    func update(tint: NSColor) {
        materialView.alphaValue = 1
        let glassTint = tint.withAlphaComponent(0.13)
        tintView.layer?.backgroundColor = glassTint.cgColor
    }
}

extension NSColor {
    convenience init?(lunchpadHex: String) {
        let value = lunchpadHex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        guard value.count == 6, let rgb = UInt32(value, radix: 16) else { return nil }
        self.init(
            srgbRed: CGFloat((rgb >> 16) & 0xFF) / 255,
            green: CGFloat((rgb >> 8) & 0xFF) / 255,
            blue: CGFloat(rgb & 0xFF) / 255,
            alpha: 1
        )
    }

    var lunchpadHex: String {
        guard let color = usingColorSpace(.sRGB) else { return "#20283A" }
        return String(format: "#%02X%02X%02X", Int(color.redComponent * 255), Int(color.greenComponent * 255), Int(color.blueComponent * 255))
    }
}
