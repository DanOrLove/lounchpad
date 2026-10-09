import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct LauncherView: View {
    @EnvironmentObject private var store: LauncherStore
    @EnvironmentObject private var windowPresentation: WindowPresentationState
    @FocusState private var searchFocused: Bool
    @FocusState private var folderRenameFocused: Bool
    @State private var renameFolderID: UUID?
    @State private var inlineRenameFolderID: UUID?
    @State private var folderName = ""
    @State private var isRecordingShortcut = false
    @State private var showColorEditor = false
    @State private var colorHexDraft = "#20283A"

    private let columns = [GridItem(.adaptive(minimum: 150, maximum: 220), spacing: 42)]

    var body: some View {
        ZStack {
            WindowBackdrop(tint: NSColor(lunchpadHex: store.backgroundHex) ?? .black).ignoresSafeArea()
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
        .onAppear { searchFocused = true }
        .onChange(of: store.onboardingStep) { oldStep, newStep in
            if oldStep != nil && newStep == nil { searchFocused = true }
        }
        .onExitCommand {
            if !store.searchText.isEmpty {
                store.searchText = ""
                searchFocused = true
            } else if store.selectedFolder != nil {
                store.closeFolder()
            } else {
                NSApp.hide(nil)
            }
        }
        .animation(.spring(response: 0.48, dampingFraction: 0.8), value: store.selectedFolder)
        .animation(.spring(response: 0.45, dampingFraction: 0.78), value: store.visibleApps.map(\.id))
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: store.visibleFolders.map(\.id))
        .animation(.spring(response: 0.38, dampingFraction: 0.8), value: store.isEditing)
        .sheet(item: Binding(get: { renameFolderID.map(FolderEditor.init(id:)) }, set: { renameFolderID = $0?.id })) { editor in
            folderEditor(editor.id)
        }
        .onChange(of: store.backgroundHex) { _, newValue in colorHexDraft = newValue }
    }

    private var header: some View {
        HStack(spacing: 18) {
            if windowPresentation.isFullScreen { fullscreenWindowControls }
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
                    .onSubmit {
                        guard !store.searchText.isEmpty else { return }
                        if let app = store.visibleApps.first { store.open(app) }
                        else if let folder = store.visibleFolders.first { store.openFolder(folder.id) }
                    }
                if !store.searchText.isEmpty {
                    Button { store.searchText = "" } label: { Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary) }.buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 15).padding(.vertical, 10)
            .frame(width: 320)
            .background(.ultraThinMaterial, in: Capsule())
            .overlay(Capsule().stroke(.primary.opacity(0.22), lineWidth: 1))
            Spacer(minLength: 30)
            Menu {
                Button("Новая папка", systemImage: "folder.badge.plus") { store.createFolder() }
                Button(store.isEditing ? "Готово" : "Настройки", systemImage: store.isEditing ? "checkmark" : "slider.horizontal.3") { store.isEditing.toggle() }
            } label: {
                Image(systemName: store.isEditing ? "checkmark" : "slider.horizontal.3")
                    .font(.system(size: 15, weight: .medium))
                    .frame(width: 40, height: 40)
                    .background(.ultraThinMaterial, in: Circle())
                    .overlay(Circle().stroke(.primary.opacity(0.22), lineWidth: 1))
            }
            .menuStyle(.borderlessButton)
            .help("Настройки")
        }
        .padding(.horizontal, 54).padding(.top, 34).padding(.bottom, 14)
    }

    private func folderTile(_ folder: LauncherFolder) -> some View {
        VStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 24, style: .continuous).fill(.primary.opacity(0.075))
                    .overlay(RoundedRectangle(cornerRadius: 24).stroke(.primary.opacity(0.12), lineWidth: 1))
                let apps = folder.appPaths.prefix(9).compactMap { path in store.apps.first(where: { $0.path == path }) }
                if apps.isEmpty {
                    Image(systemName: "folder.fill").font(.system(size: 54, weight: .light)).foregroundStyle(.primary.opacity(0.72))
                } else {
                    LazyVGrid(columns: Array(repeating: GridItem(.fixed(25), spacing: 6), count: 3), spacing: 6) {
                        ForEach(apps) { app in Image(nsImage: app.icon).resizable().interpolation(.high).frame(width: 25, height: 25).clipShape(RoundedRectangle(cornerRadius: 6)) }
                    }.padding(13)
                }
            }
            .frame(width: 116, height: 106)
            .contentShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .onTapGesture { store.openFolder(folder.id) }
            if inlineRenameFolderID == folder.id {
                TextField("Название папки", text: $folderName)
                    .textFieldStyle(.plain)
                    .multilineTextAlignment(.center)
                    .font(.system(size: 13, weight: .medium))
                    .frame(maxWidth: 150)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 4)
                    .background(.primary.opacity(0.1), in: RoundedRectangle(cornerRadius: 7))
                    .focused($folderRenameFocused)
                    .onSubmit { commitInlineFolderRename() }
                    .onExitCommand { cancelInlineFolderRename() }
                    .onAppear { folderRenameFocused = true }
            } else {
                Text(folder.name)
                    .font(.system(size: 13, weight: .medium)).lineLimit(1).frame(maxWidth: 150)
                    .contentShape(Rectangle())
                    .onTapGesture(count: 2) { beginInlineFolderRename(folder) }
                    .help("Дважды нажмите, чтобы переименовать")
            }
        }
        .frame(maxWidth: .infinity, minHeight: 150)
        .contentShape(Rectangle())
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
        .help("Нажмите значок, чтобы открыть · Дважды нажмите название, чтобы переименовать")
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
        .onTapGesture { store.open(app) }
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
        .help("Нажмите, чтобы открыть · Перетащите на приложение, чтобы создать папку")
    }

    private var footer: some View {
        HStack(spacing: 16) {
            hotKeyControl
            Divider().frame(height: 22)
            Toggle("Автозапуск", isOn: Binding(get: { store.startupEnabled }, set: { store.setLaunchAtLogin($0) }))
                .toggleStyle(.switch).font(.system(size: 12, weight: .medium)).fixedSize()
            Divider().frame(height: 22)
            Button {
                colorHexDraft = store.backgroundHex
                showColorEditor.toggle()
            } label: {
                Label("Цвет фона", systemImage: "paintpalette")
                    .font(.system(size: 12, weight: .medium))
            }
            .buttonStyle(.plain)
            .popover(isPresented: $showColorEditor, arrowEdge: .bottom) { colorEditor }
        }
        .padding(.horizontal, 24).padding(.vertical, 14)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().stroke(.primary.opacity(0.16), lineWidth: 1))
        .padding(.horizontal, 34).padding(.bottom, 22)
    }

    private var colorEditor: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Цвет фона").font(.system(size: 14, weight: .semibold))
            HStack(spacing: 12) {
                ColorPicker("Выбрать цвет", selection: Binding(
                    get: { Color(nsColor: NSColor(lunchpadHex: store.backgroundHex) ?? .black) },
                    set: { color in
                        let hex = NSColor(color).lunchpadHex
                        colorHexDraft = hex
                        store.backgroundHex = hex
                    }
                ), supportsOpacity: false)
                .labelsHidden()
                TextField("#20283A", text: $colorHexDraft)
                    .font(.system(size: 12, design: .monospaced))
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 100)
                    .onSubmit { applyColorHexDraft() }
            }
            HStack(spacing: 9) {
                ForEach(["#20283A", "#263C52", "#42344D", "#263F3B", "#493A32", "#17191F"], id: \.self) { hex in
                    Button {
                        colorHexDraft = hex
                        store.backgroundHex = hex
                    } label: {
                        Circle().fill(Color(nsColor: NSColor(lunchpadHex: hex) ?? .black))
                            .frame(width: 22, height: 22)
                            .overlay(Circle().stroke(.primary.opacity(0.35), lineWidth: 1))
                            .overlay(Circle().stroke(store.backgroundHex == hex ? .white : .clear, lineWidth: 2).padding(2))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Цвет \(hex)")
                }
            }
        }
        .padding(16)
        .frame(width: 260)
    }

    private func applyColorHexDraft() {
        let normalized = colorHexDraft.hasPrefix("#") ? colorHexDraft : "#" + colorHexDraft
        guard NSColor(lunchpadHex: normalized) != nil else {
            colorHexDraft = store.backgroundHex
            return
        }
        colorHexDraft = normalized.uppercased()
        store.backgroundHex = colorHexDraft
    }

    private var hotKeyControl: some View {
        HotKeyCaptureView(isRecording: $isRecordingShortcut, onCapture: updateShortcut)
            .frame(width: 120, height: 32)
            .overlay {
                Text(isRecordingShortcut ? "Нажмите клавишу…" : store.shortcutTitle)
                    .font(.system(size: isRecordingShortcut ? 10 : 11, weight: .semibold, design: .rounded))
                    .lineLimit(1).minimumScaleFactor(0.7).allowsHitTesting(false)
            }
            .background(isRecordingShortcut ? Color.cyan.opacity(0.19) : Color.primary.opacity(0.08), in: RoundedRectangle(cornerRadius: 9))
            .overlay {
                RoundedRectangle(cornerRadius: 9)
                    .stroke(isRecordingShortcut ? Color.cyan.opacity(0.95) : Color.primary.opacity(0.17), lineWidth: isRecordingShortcut ? 2 : 1)
            }
            .shadow(color: .cyan.opacity(isRecordingShortcut ? 0.35 : 0), radius: 8)
            .animation(.easeInOut(duration: 0.16), value: isRecordingShortcut)
            .help("Нажмите и задайте новую горячую клавишу")
    }

    private var fullscreenWindowControls: some View {
        HStack(spacing: 8) {
            WindowTrafficLight(color: .systemRed, symbol: "xmark", title: "Закрыть") {
                NSApp.keyWindow?.performClose(nil)
            }
            WindowTrafficLight(color: .systemYellow, symbol: "minus", title: "Свернуть") {
                guard let window = NSApp.keyWindow else { return }
                if window.styleMask.contains(.fullScreen) {
                    window.toggleFullScreen(nil)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) { window.miniaturize(nil) }
                } else {
                    window.miniaturize(nil)
                }
            }
            WindowTrafficLight(color: .systemGreen, symbol: "arrow.up.left.and.arrow.down.right", title: "Выйти из полного экрана") {
                NSApp.keyWindow?.toggleFullScreen(nil)
            }
        }
        .padding(.trailing, 3)
        .transition(.opacity.combined(with: .scale(scale: 0.9)))
    }

    private func updateShortcut(keyCode: UInt16, modifiers: UInt32) {
        do { try store.setShortcut(keyCode: keyCode, modifiers: modifiers) }
        catch { store.startupError = error.localizedDescription }
    }

    private func beginInlineFolderRename(_ folder: LauncherFolder) {
        folderName = folder.name
        inlineRenameFolderID = folder.id
    }

    private func commitInlineFolderRename() {
        if let id = inlineRenameFolderID { store.renameFolder(id, to: folderName) }
        inlineRenameFolderID = nil
        folderRenameFocused = false
    }

    private func cancelInlineFolderRename() {
        inlineRenameFolderID = nil
        folderRenameFocused = false
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

private struct WindowTrafficLight: View {
    let color: NSColor
    let symbol: String
    let title: String
    let action: () -> Void
    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            Circle()
                .fill(Color(nsColor: color))
                .frame(width: 14, height: 14)
                .overlay(Circle().stroke(.black.opacity(0.2), lineWidth: 0.7))
                .overlay {
                    Image(systemName: symbol)
                        .font(.system(size: 7, weight: .black))
                        .foregroundStyle(.black.opacity(0.7))
                        .opacity(isHovering ? 1 : 0)
                }
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
        .accessibilityLabel(title)
        .help(title)
    }
}
