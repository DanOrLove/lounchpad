import SwiftUI

@main
struct LunchpadApp: App {
    @StateObject private var store = LauncherStore()
    @StateObject private var windowPresentation = WindowPresentationState()

    var body: some Scene {
        WindowGroup {
            LauncherView()
                .environmentObject(store)
                .environmentObject(windowPresentation)
                .background(WindowConfigurator(presentation: windowPresentation))
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

@MainActor
final class WindowPresentationState: ObservableObject {
    @Published var isFullScreen = false
}

@MainActor
struct WindowConfigurator: NSViewRepresentable {
    let presentation: WindowPresentationState

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async { configure(view.window, coordinator: context.coordinator) }
        return view
    }
    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async { configure(nsView.window, coordinator: context.coordinator) }
    }
    func makeCoordinator() -> Coordinator { Coordinator(presentation: presentation) }

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
        coordinator.observe(window)
        guard !coordinator.didRequestFullScreen else { return }
        coordinator.didRequestFullScreen = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            if !window.styleMask.contains(.fullScreen) { window.toggleFullScreen(nil) }
        }
    }

    @MainActor
    final class Coordinator {
        private let presentation: WindowPresentationState
        private weak var observedWindow: NSWindow?
        private var observers: [NSObjectProtocol] = []
        var didRequestFullScreen = false

        init(presentation: WindowPresentationState) { self.presentation = presentation }

        func observe(_ window: NSWindow) {
            guard observedWindow !== window else { return }
            for observer in observers { NotificationCenter.default.removeObserver(observer) }
            observers.removeAll()
            observedWindow = window
            presentation.isFullScreen = window.styleMask.contains(.fullScreen)

            let center = NotificationCenter.default
            observers.append(center.addObserver(forName: NSWindow.didEnterFullScreenNotification, object: window, queue: .main) { [weak presentation] _ in
                Task { @MainActor in presentation?.isFullScreen = true }
            })
            observers.append(center.addObserver(forName: NSWindow.didExitFullScreenNotification, object: window, queue: .main) { [weak presentation] _ in
                Task { @MainActor in presentation?.isFullScreen = false }
            })
        }
    }
}
