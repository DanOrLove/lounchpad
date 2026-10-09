import AppKit
import SwiftUI

/// A real behind-window material whose opacity can be driven all the way to clear.
struct WindowBackdrop: NSViewRepresentable {
    let opacity: Double
    let tint: NSColor

    func makeNSView(context: Context) -> BackdropHostView {
        let view = BackdropHostView()
        view.update(opacity: opacity, tint: tint)
        return view
    }

    func updateNSView(_ view: BackdropHostView, context: Context) {
        view.update(opacity: opacity, tint: tint)
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
    }

    required init?(coder: NSCoder) { nil }

    func update(opacity: Double, tint: NSColor) {
        let value = CGFloat(min(1, max(0, opacity)))
        materialView.alphaValue = value
        tintView.layer?.backgroundColor = tint.withAlphaComponent(value).cgColor
    }
}
