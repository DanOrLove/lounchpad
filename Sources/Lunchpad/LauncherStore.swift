import AppKit
import Carbon.HIToolbox
import Foundation
import ServiceManagement
import SwiftUI

struct LauncherApp: Identifiable, Hashable {
    let id: String
    let name: String
    let path: String
    var icon: NSImage { NSWorkspace.shared.icon(forFile: path) }
}

struct LauncherFolder: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var appPaths: [String]
}

@MainActor
final class LauncherStore: ObservableObject {
    @Published private(set) var apps: [LauncherApp] = []
    @Published var folders: [LauncherFolder] = []
    @Published var searchText = ""
    @Published var transparency: Double = 0.88 {
        didSet { UserDefaults.standard.set(transparency, forKey: "windowTransparency") }
    }
    @Published var selectedFolder: UUID?
    @Published var isEditing = false
    @Published var onboardingStep: Int? = LauncherStore.initialOnboardingStep()
    @Published var shortcutKeyCode: UInt16 = UInt16(UserDefaults.standard.integer(forKey: "launcherShortcutKeyCode"))
    @Published var shortcutModifiers: UInt32 = UInt32(UserDefaults.standard.integer(forKey: "launcherShortcutModifiers"))
    @Published var startupEnabled = SMAppService.mainApp.status == .enabled || SMAppService.mainApp.status == .requiresApproval
    @Published var startupError: String?

    private let folderURL: URL

    private static func initialOnboardingStep() -> Int? {
        let defaults = UserDefaults.standard
        if defaults.bool(forKey: "didShowOnboarding") { return nil }
        if defaults.bool(forKey: "didCompleteOnboarding") {
            defaults.set(true, forKey: "didShowOnboarding")
            return nil
        }
        defaults.set(true, forKey: "didShowOnboarding")
        return 0
    }

    init() {
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Lunchpad", isDirectory: true)
        try? FileManager.default.createDirectory(at: support, withIntermediateDirectories: true)
        folderURL = support.appendingPathComponent("folders.json")
        transparency = UserDefaults.standard.object(forKey: "windowTransparency") as? Double ?? 0.88
        loadFolders()
        reloadApps()
    }

    var visibleApps: [LauncherApp] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let candidates: [LauncherApp]
        if let selectedFolder, let folder = folders.first(where: { $0.id == selectedFolder }) {
            candidates = folder.appPaths.compactMap { path in apps.first(where: { $0.path == path }) }
        } else {
            let contained = Set(folders.flatMap(\.appPaths))
            candidates = apps.filter { !contained.contains($0.path) }
        }
        guard !query.isEmpty else { return candidates }
        return candidates.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }

    var shortcutTitle: String {
        var title = ""
        if shortcutModifiers & UInt32(cmdKey) != 0 { title += "⌘" }
        if shortcutModifiers & UInt32(optionKey) != 0 { title += "⌥" }
        if shortcutModifiers & UInt32(controlKey) != 0 { title += "⌃" }
        if shortcutModifiers & UInt32(shiftKey) != 0 { title += "⇧" }
        return title + GlobalHotKeyManager.keyName(for: shortcutKeyCode)
    }

    func reloadApps() {
        let roots = [URL(fileURLWithPath: "/Applications", isDirectory: true)]
        var found: [LauncherApp] = []
        for root in roots {
            guard let enumerator = FileManager.default.enumerator(at: root, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles, .skipsPackageDescendants]) else { continue }
            for case let url as URL in enumerator where url.pathExtension == "app" {
                let name = (try? url.resourceValues(forKeys: [.localizedNameKey]).localizedName)
                    ?? url.deletingPathExtension().lastPathComponent
                found.append(LauncherApp(id: url.path, name: name, path: url.path))
                enumerator.skipDescendants()
            }
        }
        apps = found.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
        folders = folders.map { folder in
            var copy = folder
            copy.appPaths = copy.appPaths.filter { path in apps.contains(where: { $0.path == path }) }
            return copy
        }
        saveFolders()
    }

    func open(_ app: LauncherApp) {
        NSWorkspace.shared.open(URL(fileURLWithPath: app.path))
    }

    func installSavedShortcut() {
        if UserDefaults.standard.object(forKey: "launcherShortcutKeyCode") == nil {
            shortcutKeyCode = 49 // Space
            shortcutModifiers = UInt32(optionKey)
            UserDefaults.standard.set(Int(shortcutKeyCode), forKey: "launcherShortcutKeyCode")
            UserDefaults.standard.set(Int(shortcutModifiers), forKey: "launcherShortcutModifiers")
        }
        GlobalHotKeyManager.shared.action = {
            NSApp.activate(ignoringOtherApps: true)
            NSApp.windows.first?.makeKeyAndOrderFront(nil)
        }
        try? GlobalHotKeyManager.shared.register(keyCode: shortcutKeyCode, modifiers: shortcutModifiers)
    }

    func setShortcut(keyCode: UInt16, modifiers: UInt32) throws {
        try GlobalHotKeyManager.shared.register(keyCode: keyCode, modifiers: modifiers)
        shortcutKeyCode = keyCode
        shortcutModifiers = modifiers
        UserDefaults.standard.set(Int(keyCode), forKey: "launcherShortcutKeyCode")
        UserDefaults.standard.set(Int(modifiers), forKey: "launcherShortcutModifiers")
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled { try SMAppService.mainApp.register() }
            else { try SMAppService.mainApp.unregister() }
            let status = SMAppService.mainApp.status
            startupEnabled = status == .enabled || status == .requiresApproval
            startupError = status == .requiresApproval
                ? "Разрешите Lunchpad в Системных настройках → Основные → Объекты входа."
                : nil
        } catch {
            startupError = error.localizedDescription
            startupEnabled = SMAppService.mainApp.status == .enabled || SMAppService.mainApp.status == .requiresApproval
        }
    }

    func finishOnboarding() {
        UserDefaults.standard.set(true, forKey: "didCompleteOnboarding")
        UserDefaults.standard.set(true, forKey: "didShowOnboarding")
        withAnimation(.spring(response: 0.5, dampingFraction: 0.88)) { onboardingStep = nil }
    }

    func openFolder(_ id: UUID) { selectedFolder = id }
    func closeFolder() { selectedFolder = nil }

    func createFolder(with app: LauncherApp? = nil) {
        let folder = LauncherFolder(name: "Новая папка", appPaths: app.map { [$0.path] } ?? [])
        folders.append(folder)
        saveFolders()
        selectedFolder = app == nil ? nil : folder.id
    }

    func renameFolder(_ id: UUID, to name: String) {
        guard let index = folders.firstIndex(where: { $0.id == id }) else { return }
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty { folders[index].name = trimmed; saveFolders() }
    }

    func deleteFolder(_ id: UUID) {
        folders.removeAll { $0.id == id }
        if selectedFolder == id { selectedFolder = nil }
        saveFolders()
    }

    func move(_ app: LauncherApp, to folderID: UUID) {
        for index in folders.indices { folders[index].appPaths.removeAll { $0 == app.path } }
        guard let index = folders.firstIndex(where: { $0.id == folderID }) else { saveFolders(); return }
        folders[index].appPaths.append(app.path)
        saveFolders()
    }

    func remove(_ app: LauncherApp, from folderID: UUID) {
        guard let index = folders.firstIndex(where: { $0.id == folderID }) else { return }
        folders[index].appPaths.removeAll { $0 == app.path }
        saveFolders()
    }

    private func loadFolders() {
        guard let data = try? Data(contentsOf: folderURL), let decoded = try? JSONDecoder().decode([LauncherFolder].self, from: data) else { return }
        folders = decoded
    }
    private func saveFolders() {
        guard let data = try? JSONEncoder().encode(folders) else { return }
        try? data.write(to: folderURL, options: .atomic)
    }
}
