import AppKit
import SwiftUI

/// A fixed macOS desktop material for the launcher's translucent backdrop.
struct WindowBackdrop: NSViewRepresentable {
    func makeNSView(context: Context) -> BackdropHostView {
        let view = BackdropHostView()
        return view
    }

    func updateNSView(_ view: BackdropHostView, context: Context) {
        view.update()
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
        update()
    }

    required init?(coder: NSCoder) { nil }

    func update() {
        materialView.alphaValue = 1
        let glassTint = NSColor(srgbRed: 0.14, green: 0.19, blue: 0.34, alpha: 0.13)
        tintView.layer?.backgroundColor = glassTint.cgColor
    }
}
