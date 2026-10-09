import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct LauncherView: View {
    @EnvironmentObject private var store: LauncherStore
    @EnvironmentObject private var windowPresentation: WindowPresentationState
    @FocusState private var searchFocused: Bool
    @State private var renameFolderID: UUID?
    @State private var folderName = ""
    @State private var showColorEditor = false
    @State private var colorHexDraft = ""
    @State private var showButtonColorEditor = false
    @State private var buttonHexDraft = ""
    @State private var isRecordingShortcut = false

    private let columns = [GridItem(.adaptive(minimum: 150, maximum: 220), spacing: 42)]
    private let presets = ["#20283A", "#263C52", "#42344D", "#263F3B", "#493A32", "#17191F"]

    var body: some View {
        ZStack {
            WindowBackdrop(
                opacity: 1 - min(100, max(0, store.transparency)) / 100,
                tint: NSColor(lunchpadHex: store.backgroundHex) ?? .systemIndigo
            ).ignoresSafeArea()
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
        .preferredColorScheme(store.colorTheme.colorScheme)
        .tint(store.colorTheme.tint(customHex: store.customButtonHex))
        .animation(.spring(response: 0.48, dampingFraction: 0.8), value: store.selectedFolder)
        .animation(.spring(response: 0.45, dampingFraction: 0.78), value: store.visibleApps.map(\.id))
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: store.visibleFolders.map(\.id))
        .animation(.spring(response: 0.38, dampingFraction: 0.8), value: store.isEditing)
        .sheet(item: Binding(get: { renameFolderID.map(FolderEditor.init(id:)) }, set: { renameFolderID = $0?.id })) { editor in
            folderEditor(editor.id)
        }
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
                    .onSubmit { searchFocused = false }
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
                Button(store.isEditing ? "Готово" : "Настроить оформление", systemImage: store.isEditing ? "checkmark" : "slider.horizontal.3") { store.isEditing.toggle() }
                Menu("Цветовое оформление") {
                    ForEach(LauncherColorTheme.allCases) { theme in
                        Button {
                            store.colorTheme = theme
                        } label: {
                            if store.colorTheme == theme { Label(theme.title, systemImage: "checkmark") }
                            else { Text(theme.title) }
                        }
                    }
                }
            } label: {
                Image(systemName: store.isEditing ? "checkmark" : "slider.horizontal.3")
                    .font(.system(size: 15, weight: .medium))
                    .frame(width: 40, height: 40)
                    .background(.ultraThinMaterial, in: Circle())
                    .overlay(Circle().stroke(.primary.opacity(0.22), lineWidth: 1))
            }
            .menuStyle(.borderlessButton)
            .help("Настройки и папки")
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
            Button { prepareColorEditor() } label: { Label("Цвет", systemImage: "paintpalette") }
                .buttonStyle(.bordered).disabled(store.transparency != 0)
                .popover(isPresented: $showColorEditor, arrowEdge: .top) { colorEditor.padding(18).frame(width: 280) }
                .help(store.transparency == 0 ? "Выбрать цвет фона" : "Установите прозрачность 0%, чтобы выбрать цвет")
            if store.colorTheme == .custom {
                Button {
                    buttonHexDraft = store.customButtonHex
                    showButtonColorEditor = true
                } label: { Label("Цвет кнопок", systemImage: "circle.lefthalf.filled") }
                    .buttonStyle(.bordered)
                    .popover(isPresented: $showButtonColorEditor, arrowEdge: .top) {
                        buttonColorEditor.padding(18).frame(width: 260)
                    }
            }
            Divider().frame(height: 22)
            hotKeyControl
            Toggle("Автозапуск", isOn: Binding(get: { store.startupEnabled }, set: { store.setLaunchAtLogin($0) }))
                .toggleStyle(.switch).font(.system(size: 12, weight: .medium)).fixedSize()
        }
        .padding(.horizontal, 24).padding(.vertical, 14)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().stroke(.primary.opacity(0.16), lineWidth: 1))
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
                            .overlay(Circle().stroke(.primary.opacity(store.backgroundHex == hex ? 0.9 : 0.25), lineWidth: store.backgroundHex == hex ? 2 : 1))
                    }.buttonStyle(.plain).help(hex)
                }
            }
            Text("HEX · RGB-колесо доступно в системном выборе цвета")
                .font(.system(size: 10)).foregroundStyle(.secondary)
        }
        .onAppear { colorHexDraft = store.backgroundHex }
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

    private var buttonColorEditor: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Цвет кнопок").font(.system(size: 15, weight: .semibold))
            HStack(spacing: 10) {
                ColorPicker("", selection: Binding(
                    get: { Color(nsColor: NSColor(lunchpadHex: store.customButtonHex) ?? .systemIndigo) },
                    set: { color in
                        if let hex = NSColor(color).lunchpadHex { store.customButtonHex = hex; buttonHexDraft = hex }
                    }
                ), supportsOpacity: false).labelsHidden()
                TextField("#38BDF8", text: $buttonHexDraft)
                    .textFieldStyle(.roundedBorder).font(.system(.body, design: .monospaced))
                    .onChange(of: buttonHexDraft) { _, value in
                        if let color = NSColor(lunchpadHex: value) { store.customButtonHex = color.lunchpadHex ?? store.customButtonHex }
                    }
            }
        }
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

    private func prepareColorEditor() {
        colorHexDraft = store.backgroundHex
        showColorEditor = true
    }

    private func updateShortcut(keyCode: UInt16, modifiers: UInt32) {
        do { try store.setShortcut(keyCode: keyCode, modifiers: modifiers) }
        catch { store.startupError = error.localizedDescription }
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

extension NSColor {
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
