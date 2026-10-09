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
        }
        .windowStyle(.hiddenTitleBar)
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
        DispatchQueue.main.async { configure(view.window) }
        return view
    }
    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async { configure(nsView.window) }
    }
    private func configure(_ window: NSWindow?) {
        guard let window else { return }
        window.isOpaque = false
        window.backgroundColor = .clear
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isMovableByWindowBackground = true
    }
}
