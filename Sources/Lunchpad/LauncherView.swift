import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct LauncherView: View {
    @EnvironmentObject private var store: LauncherStore
    @FocusState private var searchFocused: Bool
    @State private var renameFolderID: UUID?
    @State private var folderName = ""
    @State private var showColorEditor = false
    @State private var colorHexDraft = ""

    private let columns = [GridItem(.adaptive(minimum: 150, maximum: 220), spacing: 42)]
    private let presets = ["#20283A", "#263C52", "#42344D", "#263F3B", "#493A32", "#17191F"]

    var body: some View {
        ZStack {
            Rectangle().fill(.ultraThinMaterial)
            Color(nsColor: NSColor(lunchpadHex: store.backgroundHex) ?? .systemIndigo)
                .opacity(1 - min(100, max(0, store.transparency)) / 100)
            VStack(spacing: 0) {
                header
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 38) {
                        if store.selectedFolder == nil {
                            ForEach(store.visibleFolders) { folder in folderTile(folder) }
                        }
                        ForEach(store.visibleApps) { app in
                            appTile(app)
                                .transition(.asymmetric(insertion: .scale(scale: 0.82).combined(with: .opacity), removal: .scale(scale: 0.88).combined(with: .opacity)))
                        }
                    }
                    .padding(.horizontal, 46)
                    .padding(.top, 36)
                    .padding(.bottom, 38)
                    .frame(maxWidth: .infinity)
                    if store.visibleApps.isEmpty && store.visibleFolders.isEmpty {
                        ContentUnavailableView(store.searchText.isEmpty ? "Нет приложений" : "Ничего не найдено",
                                               systemImage: store.searchText.isEmpty ? "square.grid.3x3" : "magnifyingglass",
                                               description: Text(store.searchText.isEmpty ? "В папке пока нет приложений." : "Попробуйте изменить запрос."))
                            .padding(.top, 40)
                    }
                }
                if store.isEditing { footer.transition(.move(edge: .bottom).combined(with: .opacity)) }
            }
            if store.onboardingStep != nil {
                OnboardingView().environmentObject(store).transition(.opacity).zIndex(2)
            }
        }
        .ignoresSafeArea()
        .frame(minWidth: 900, minHeight: 620)
        .preferredColorScheme(.dark)
        .animation(.spring(response: 0.48, dampingFraction: 0.8), value: store.selectedFolder)
        .animation(.spring(response: 0.45, dampingFraction: 0.78), value: store.visibleApps.map(\.id))
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: store.visibleFolders.map(\.id))
        .animation(.spring(response: 0.38, dampingFraction: 0.8), value: store.isEditing)
        .onChange(of: store.transparency) { _, value in
            if value == 0 && store.isEditing { prepareColorEditor() }
        }
        .onChange(of: store.isEditing) { _, editing in
            if editing && store.transparency == 0 { prepareColorEditor() }
        }
        .sheet(item: Binding(get: { renameFolderID.map(FolderEditor.init(id:)) }, set: { renameFolderID = $0?.id })) { editor in
            folderEditor(editor.id)
        }
    }

    private var header: some View {
        HStack(spacing: 18) {
            if store.selectedFolder != nil {
                Button { store.closeFolder() } label: { Image(systemName: "chevron.left").font(.system(size: 16, weight: .semibold)) }
                    .buttonStyle(.plain).help("Все приложения")
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(store.selectedFolder.flatMap { id in store.folders.first(where: { $0.id == id })?.name } ?? "Приложения")
                    .font(.system(size: 23, weight: .semibold, design: .rounded))
                Text(store.selectedFolder == nil ? "\(store.apps.count) приложений" : "Папка")
                    .font(.system(size: 12)).foregroundStyle(.secondary)
            }.contentTransition(.opacity)
            Spacer(minLength: 30)
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                TextField("Поиск приложений", text: $store.searchText).textFieldStyle(.plain).focused($searchFocused)
                    .onSubmit { searchFocused = false }
                if !store.searchText.isEmpty {
                    Button { store.searchText = "" } label: { Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary) }.buttonStyle(.plain)
                }
                Menu {
                    Button("Новая папка", systemImage: "folder.badge.plus") { store.createFolder() }
                    Button(store.isEditing ? "Готово" : "Настроить оформление", systemImage: store.isEditing ? "checkmark" : "slider.horizontal.3") { store.isEditing.toggle() }
                    Button("Обновить приложения", systemImage: "arrow.clockwise") { store.reloadApps() }
                } label: { Image(systemName: "ellipsis.circle").font(.system(size: 18)).foregroundStyle(.secondary) }
                    .menuStyle(.borderlessButton).frame(width: 22)
            }
            .padding(.horizontal, 15).padding(.vertical, 10)
            .frame(width: 320)
            .background(.ultraThinMaterial, in: Capsule())
            .overlay(Capsule().stroke(.white.opacity(0.22), lineWidth: 1))
            Spacer(minLength: 30)
            Button { store.isEditing.toggle() } label: { Image(systemName: store.isEditing ? "checkmark" : "slider.horizontal.3") }
                .buttonStyle(ToolbarIconStyle()).help("Настроить оформление")
        }
        .padding(.horizontal, 54).padding(.top, 34).padding(.bottom, 14)
    }

    private func folderTile(_ folder: LauncherFolder) -> some View {
        VStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous).fill(.white.opacity(0.075))
                    .overlay(RoundedRectangle(cornerRadius: 24).stroke(.white.opacity(0.12), lineWidth: 1))
                let apps = folder.appPaths.prefix(9).compactMap { path in store.apps.first(where: { $0.path == path }) }
                if apps.isEmpty {
                    Image(systemName: "folder.fill").font(.system(size: 54, weight: .light)).foregroundStyle(.white.opacity(0.72))
                } else {
                    LazyVGrid(columns: Array(repeating: GridItem(.fixed(25), spacing: 6), count: 3), spacing: 6) {
                        ForEach(apps) { app in Image(nsImage: app.icon).resizable().interpolation(.high).frame(width: 25, height: 25).clipShape(RoundedRectangle(cornerRadius: 6)) }
                    }.padding(13)
                }
            }
            .frame(width: 116, height: 106)
            Text(folder.name).font(.system(size: 13, weight: .medium)).lineLimit(1).frame(maxWidth: 150)
        }
        .frame(maxWidth: .infinity, minHeight: 150)
        .contentShape(Rectangle())
        .onTapGesture(count: 2) { store.openFolder(folder.id) }
        .contextMenu {
            Button("Открыть папку") { store.openFolder(folder.id) }
            Button("Переименовать") { folderName = folder.name; renameFolderID = folder.id }
            Button("Удалить папку", role: .destructive) { store.deleteFolder(folder.id) }
        }
        .dropDestination(for: String.self) { paths, _ in
            guard let app = paths.first.flatMap({ path in store.apps.first(where: { $0.path == path }) }) else { return false }
            withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) { store.move(app, to: folder.id) }
            return true
        }
        .help("Дважды нажмите, чтобы открыть папку")
    }

    private func appTile(_ app: LauncherApp) -> some View {
        VStack(spacing: 13) {
            Image(nsImage: app.icon).resizable().interpolation(.high).frame(width: 88, height: 88)
                .shadow(color: .black.opacity(0.26), radius: 12, y: 6)
            Text(app.name).font(.system(size: 13, weight: .medium)).lineLimit(2).multilineTextAlignment(.center)
                .frame(maxWidth: 160, minHeight: 32, alignment: .top)
        }
        .frame(maxWidth: .infinity, minHeight: 150)
        .contentShape(Rectangle())
        .onTapGesture(count: 2) { store.open(app) }
        .draggable(app.path)
        .contextMenu {
            Button("Открыть") { store.open(app) }
            if let folderID = store.selectedFolder {
                Button("Убрать из папки") { store.remove(app, from: folderID) }
            } else {
                Button("Создать папку с приложением") { store.createFolder(with: app) }
                if !store.folders.isEmpty { Menu("Переместить в папку") { ForEach(store.folders) { folder in Button(folder.name) { store.move(app, to: folder.id) } } } }
            }
            Button("Показать в Finder") { NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: app.path)]) }
        }
        .dropDestination(for: String.self) { paths, _ in
            guard store.selectedFolder == nil,
                  let source = paths.first.flatMap({ path in store.apps.first(where: { $0.path == path }) }), source.path != app.path else { return false }
            let folder = LauncherFolder(name: "Папка", appPaths: [source.path, app.path])
            withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) {
                store.folders.append(folder); store.move(source, to: folder.id); store.move(app, to: folder.id); store.openFolder(folder.id)
            }
            return true
        }
        .help("Дважды нажмите, чтобы открыть · Перетащите на приложение, чтобы создать папку")
    }

    private var footer: some View {
        HStack(spacing: 16) {
            Image(systemName: "circle.lefthalf.filled")
            Slider(value: $store.transparency, in: 0...100, step: 1).frame(width: 190)
            Text("Прозрачность \(Int(store.transparency))%")
                .font(.system(size: 12, weight: .medium, design: .rounded)).monospacedDigit().frame(width: 132, alignment: .leading)
            if store.transparency == 0 {
                Button { prepareColorEditor() } label: { Label("Цвет", systemImage: "paintpalette") }
                    .buttonStyle(.bordered).popover(isPresented: $showColorEditor, arrowEdge: .top) { colorEditor.padding(18).frame(width: 280) }
                    .help("Выбрать цвет фона")
            }
            Divider().frame(height: 22)
            HotKeyCaptureView(isRecording: .constant(false)) { keyCode, modifiers in
                do { try store.setShortcut(keyCode: keyCode, modifiers: modifiers) }
                catch { store.startupError = error.localizedDescription }
            }
            .frame(width: 86, height: 28)
            .overlay(Text(store.shortcutTitle).font(.system(size: 11, weight: .semibold, design: .rounded)).allowsHitTesting(false))
            .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 8))
            .help("Нажмите и задайте новую горячую клавишу")
            Toggle("Автозапуск", isOn: Binding(get: { store.startupEnabled }, set: { store.setLaunchAtLogin($0) }))
                .toggleStyle(.switch).font(.system(size: 12, weight: .medium)).fixedSize()
        }
        .padding(.horizontal, 24).padding(.vertical, 14)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().stroke(.white.opacity(0.16), lineWidth: 1))
        .padding(.horizontal, 34).padding(.bottom, 22)
    }

    private var colorEditor: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Цвет фона").font(.system(size: 15, weight: .semibold))
            HStack(spacing: 10) {
                ColorPicker("", selection: Binding(
                    get: { Color(nsColor: NSColor(lunchpadHex: store.backgroundHex) ?? .systemIndigo) },
                    set: { color in if let hex = NSColor(color).lunchpadHex { store.backgroundHex = hex; colorHexDraft = hex } }
                ), supportsOpacity: false).labelsHidden()
                TextField("#20283A", text: $colorHexDraft).textFieldStyle(.roundedBorder).font(.system(.body, design: .monospaced))
                    .onChange(of: colorHexDraft) { _, value in
                        if let color = NSColor(lunchpadHex: value) { store.backgroundHex = color.lunchpadHex ?? store.backgroundHex }
                    }
            }
            HStack(spacing: 9) {
                ForEach(presets, id: \.self) { hex in
                    Button {
                        store.backgroundHex = hex
                        colorHexDraft = hex
                    } label: {
                        Circle().fill(Color(nsColor: NSColor(lunchpadHex: hex) ?? .systemIndigo))
                            .frame(width: 25, height: 25)
                            .overlay(Circle().stroke(.white.opacity(store.backgroundHex == hex ? 0.9 : 0.25), lineWidth: store.backgroundHex == hex ? 2 : 1))
                    }.buttonStyle(.plain).help(hex)
                }
            }
            Text("HEX · RGB-колесо доступно в системном выборе цвета")
                .font(.system(size: 10)).foregroundStyle(.secondary)
        }
        .onAppear { colorHexDraft = store.backgroundHex }
    }

    private func prepareColorEditor() {
        colorHexDraft = store.backgroundHex
        showColorEditor = true
    }

    private func folderEditor(_ id: UUID) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Переименовать папку").font(.headline)
            TextField("Название", text: $folderName).textFieldStyle(.roundedBorder)
            HStack {
                Button("Отмена") { renameFolderID = nil }.keyboardShortcut(.cancelAction)
                Spacer()
                Button("Сохранить") { store.renameFolder(id, to: folderName); renameFolderID = nil }.keyboardShortcut(.defaultAction)
            }
        }.padding(22).frame(width: 320)
    }
}

private struct FolderEditor: Identifiable { let id: UUID }

private struct ToolbarIconStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.system(size: 15, weight: .medium))
            .frame(width: 36, height: 36)
            .background(.white.opacity(configuration.isPressed ? 0.2 : 0.11), in: RoundedRectangle(cornerRadius: 12))
            .contentShape(RoundedRectangle(cornerRadius: 12))
    }
}

private extension NSColor {
    convenience init?(lunchpadHex: String) {
        let hex = lunchpadHex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        guard hex.count == 6, let value = UInt32(hex, radix: 16) else { return nil }
        self.init(srgbRed: CGFloat((value >> 16) & 0xff) / 255,
                  green: CGFloat((value >> 8) & 0xff) / 255,
                  blue: CGFloat(value & 0xff) / 255, alpha: 1)
    }

    var lunchpadHex: String? {
        guard let rgb = usingColorSpace(.deviceRGB) else { return nil }
        return String(format: "#%02X%02X%02X", Int(rgb.redComponent * 255), Int(rgb.greenComponent * 255), Int(rgb.blueComponent * 255))
    }
}
