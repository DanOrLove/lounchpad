import AppKit
import Foundation

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

    private let folderURL: URL

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
