import SwiftUI

@main
struct LunchpadApp: App {
    @StateObject private var store = LauncherStore()

    var body: some Scene {
        WindowGroup {
            LauncherView()
                .environmentObject(store)
                .background(WindowConfigurator())
                .frame(minWidth: 680, minHeight: 520)
                .onAppear { store.installSavedShortcut() }
        }
        .defaultSize(width: 920, height: 660)
        .commands {
            CommandGroup(replacing: .newItem) { }
            CommandGroup(after: .appInfo) {
                Button("Обновить список приложений") { store.reloadApps() }
                    .keyboardShortcut("r", modifiers: .command)
            }
        }
    }
}

struct WindowConfigurator: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async { configure(view.window, coordinator: context.coordinator) }
        return view
    }
    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async { configure(nsView.window, coordinator: context.coordinator) }
    }
    func makeCoordinator() -> Coordinator { Coordinator() }

    private func configure(_ window: NSWindow?, coordinator: Coordinator) {
        guard let window else { return }
        window.isOpaque = false
        window.backgroundColor = .clear
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isMovableByWindowBackground = true
        window.standardWindowButton(.closeButton)?.isHidden = false
        window.standardWindowButton(.miniaturizeButton)?.isHidden = false
        window.standardWindowButton(.zoomButton)?.isHidden = false
        guard !coordinator.didRequestFullScreen else { return }
        coordinator.didRequestFullScreen = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            if !window.styleMask.contains(.fullScreen) { window.toggleFullScreen(nil) }
        }
    }

    final class Coordinator {
        var didRequestFullScreen = false
    }
}
