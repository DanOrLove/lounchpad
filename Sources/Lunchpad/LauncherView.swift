import SwiftUI
import UniformTypeIdentifiers

struct LauncherView: View {
    @EnvironmentObject private var store: LauncherStore
    @FocusState private var searchFocused: Bool
    @State private var renameFolderID: UUID?
    @State private var folderName = ""

    private let columns = [GridItem(.adaptive(minimum: 104, maximum: 132), spacing: 22)]

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(Color(nsColor: .windowBackgroundColor).opacity(max(0.08, 1 - store.transparency)))
            VStack(spacing: 0) {
                header
                if !store.folders.isEmpty && store.selectedFolder == nil { folderStrip }
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 24) {
                        ForEach(store.visibleApps) { app in appTile(app) }
                    }
                    .padding(.horizontal, 30)
                    .padding(.vertical, 24)
                    .frame(maxWidth: .infinity)
                    if store.visibleApps.isEmpty {
                        ContentUnavailableView(store.searchText.isEmpty ? "Нет приложений" : "Ничего не найдено",
                                               systemImage: store.searchText.isEmpty ? "square.grid.3x3" : "magnifyingglass",
                                               description: Text(store.searchText.isEmpty ? "В папке пока нет приложений." : "Попробуйте изменить запрос."))
                            .padding(.top, 40)
                    }
                }
                footer
            }
            .padding(12)
        }
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .padding(10)
        .frame(minWidth: 680, minHeight: 520)
        .preferredColorScheme(.dark)
        .sheet(item: Binding(get: { renameFolderID.map(FolderEditor.init(id:)) }, set: { renameFolderID = $0?.id })) { editor in
            folderEditor(editor.id)
        }
    }

    private var header: some View {
        HStack(spacing: 14) {
            if store.selectedFolder != nil {
                Button { store.closeFolder() } label: { Image(systemName: "chevron.left").font(.system(size: 15, weight: .semibold)) }
                    .buttonStyle(.plain).help("Все приложения")
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(store.selectedFolder.flatMap { id in store.folders.first(where: { $0.id == id })?.name } ?? "Приложения")
                    .font(.system(size: 23, weight: .semibold, design: .rounded))
                Text(store.selectedFolder == nil ? "\(store.apps.count) приложений" : "Папка")
                    .font(.system(size: 12)).foregroundStyle(.secondary)
            }
            Spacer()
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                TextField("Поиск", text: $store.searchText).textFieldStyle(.plain).focused($searchFocused)
                    .onSubmit { searchFocused = false }
                if !store.searchText.isEmpty {
                    Button { store.searchText = "" } label: { Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary) }.buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12).padding(.vertical, 9)
            .frame(width: 210).background(.white.opacity(0.09), in: RoundedRectangle(cornerRadius: 11))
            Button { store.createFolder() } label: { Image(systemName: "folder.badge.plus") }
                .buttonStyle(ToolbarIconStyle()).help("Создать папку")
            Button { store.isEditing.toggle() } label: { Image(systemName: store.isEditing ? "checkmark" : "slider.horizontal.3") }
                .buttonStyle(ToolbarIconStyle()).help("Настроить прозрачность")
        }
        .padding(.horizontal, 20).padding(.top, 16).padding(.bottom, 18)
    }

    private var folderStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(store.folders) { folder in
                    Button { store.openFolder(folder.id) } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "folder.fill").foregroundStyle(.cyan)
                            Text(folder.name).lineLimit(1)
                            Text("\(folder.appPaths.count)").font(.caption2).foregroundStyle(.secondary)
                        }
                        .font(.system(size: 12, weight: .medium))
                        .padding(.horizontal, 12).padding(.vertical, 8)
                        .background(.white.opacity(0.08), in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button("Переименовать") { folderName = folder.name; renameFolderID = folder.id }
                        Button("Удалить папку", role: .destructive) { store.deleteFolder(folder.id) }
                    }
                    .dropDestination(for: String.self) { paths, _ in
                        guard let app = paths.first.flatMap({ path in store.apps.first(where: { $0.path == path }) }) else { return false }
                        store.move(app, to: folder.id); return true
                    }
                }
            }
            .padding(.horizontal, 20).padding(.bottom, 14)
        }
    }

    private func appTile(_ app: LauncherApp) -> some View {
        VStack(spacing: 9) {
            Image(nsImage: app.icon)
                .resizable().interpolation(.high).frame(width: 66, height: 66)
                .shadow(color: .black.opacity(0.24), radius: 8, y: 4)
            Text(app.name).font(.system(size: 12, weight: .medium)).lineLimit(2).multilineTextAlignment(.center)
                .frame(maxWidth: 112, minHeight: 30, alignment: .top)
        }
        .frame(maxWidth: .infinity, minHeight: 112)
        .contentShape(Rectangle())
        .onTapGesture(count: 2) { store.open(app) }
        .onTapGesture(count: 1) { }
        .draggable(app.path)
        .contextMenu {
            Button("Открыть") { store.open(app) }
            if let folderID = store.selectedFolder {
                Button("Убрать из папки") { store.remove(app, from: folderID) }
            } else {
                Button("Создать папку с приложением") { store.createFolder(with: app) }
                if !store.folders.isEmpty {
                    Menu("Переместить в папку") {
                        ForEach(store.folders) { folder in Button(folder.name) { store.move(app, to: folder.id) } }
                    }
                }
            }
            Button("Показать в Finder") { NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: app.path)]) }
        }
        .dropDestination(for: String.self) { paths, _ in
            guard store.selectedFolder == nil,
                  let source = paths.first.flatMap({ path in store.apps.first(where: { $0.path == path }) }), source.path != app.path else { return false }
            let folder = LauncherFolder(name: "Папка", appPaths: [source.path, app.path])
            store.folders.append(folder)
            store.move(source, to: folder.id)
            store.move(app, to: folder.id)
            store.openFolder(folder.id)
            return true
        }
        .help("Двойное нажатие — открыть · Перетяните на приложение, чтобы создать папку")
    }

    private var footer: some View {
        HStack(spacing: 12) {
            if store.isEditing {
                Image(systemName: "circle.lefthalf.filled")
                Slider(value: $store.transparency, in: 0.35...1)
                    .frame(width: 150)
                Text("Прозрачность \(Int(store.transparency * 100))%")
                    .font(.system(size: 11, weight: .medium)).foregroundStyle(.secondary)
            } else {
                Text(store.selectedFolder == nil ? "Двойное нажатие — открыть приложение" : "Перетяните сюда приложение, чтобы добавить его в папку")
                    .font(.system(size: 11)).foregroundStyle(.secondary)
            }
            Spacer()
            Button { store.reloadApps() } label: { Label("Обновить", systemImage: "arrow.clockwise") }
                .buttonStyle(.plain).font(.system(size: 11, weight: .medium)).foregroundStyle(.secondary)
                .help("Повторно просканировать /Applications")
        }
        .padding(.horizontal, 20).padding(.vertical, 12)
        .background(.black.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
    }

    private func folderEditor(_ id: UUID) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Переименовать папку").font(.headline)
            TextField("Название", text: $folderName)
                .textFieldStyle(.roundedBorder)
            HStack {
                Button("Отмена") { renameFolderID = nil }.keyboardShortcut(.cancelAction)
                Spacer()
                Button("Сохранить") { store.renameFolder(id, to: folderName); renameFolderID = nil }
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(22).frame(width: 320)
    }
}

private struct FolderEditor: Identifiable { let id: UUID }

private struct ToolbarIconStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.system(size: 15, weight: .medium))
            .frame(width: 34, height: 34)
            .background(.white.opacity(configuration.isPressed ? 0.18 : 0.09), in: RoundedRectangle(cornerRadius: 10))
            .contentShape(RoundedRectangle(cornerRadius: 10))
    }
}
