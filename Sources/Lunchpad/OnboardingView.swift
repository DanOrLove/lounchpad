import AppKit
import Carbon.HIToolbox
import ServiceManagement
import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var store: LauncherStore
    @State private var isRecordingShortcut = false

    var body: some View {
        ZStack {
            Rectangle().fill(.ultraThinMaterial).overlay(.black.opacity(0.27))
            VStack(spacing: 0) {
                HStack {
                    Image(systemName: "square.grid.3x3.fill").foregroundStyle(.cyan)
                    Text("LUNCHPAD").font(.system(size: 11, weight: .bold, design: .rounded)).tracking(2)
                    Spacer()
                    Text("\((store.onboardingStep ?? 0) + 1) / 3")
                        .font(.system(size: 12, weight: .medium, design: .rounded)).foregroundStyle(.secondary)
                }
                .padding(.bottom, 28)

                Group {
                    switch store.onboardingStep ?? 0 {
                    case 0: welcomePage
                    case 1: shortcutPage
                    default: startupPage
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .transition(.opacity.combined(with: .move(edge: .trailing)))
                .id(store.onboardingStep)

                HStack {
                    if (store.onboardingStep ?? 0) > 0 {
                        Button("Назад") {
                            withAnimation(.spring(response: 0.42, dampingFraction: 0.88)) {
                                store.onboardingStep = max(0, (store.onboardingStep ?? 1) - 1)
                            }
                        }
                        .buttonStyle(OnboardingSecondaryButtonStyle())
                    }
                    Spacer()
                    Button((store.onboardingStep ?? 0) == 2 ? "Начать работу" : "Продолжить") {
                        if (store.onboardingStep ?? 0) == 2 { store.finishOnboarding() }
                        else {
                            withAnimation(.spring(response: 0.42, dampingFraction: 0.88)) {
                                store.onboardingStep = (store.onboardingStep ?? 0) + 1
                            }
                        }
                    }
                    .buttonStyle(OnboardingPrimaryButtonStyle())
                    .keyboardShortcut(.defaultAction)
                }
                .padding(.top, 30)
            }
            .padding(34)
            .frame(width: 520, height: 490)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 28).stroke(.white.opacity(0.15), lineWidth: 1))
            .shadow(color: .black.opacity(0.35), radius: 44, y: 18)
        }
        .ignoresSafeArea()
    }

    private var welcomePage: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle().fill(.cyan.opacity(0.17)).frame(width: 104, height: 104).blur(radius: 8)
                Image(systemName: "square.grid.3x3.fill")
                    .font(.system(size: 52, weight: .medium)).symbolRenderingMode(.palette)
                    .foregroundStyle(.white, .cyan)
            }
            Text("Всё нужное — под рукой")
                .font(.system(size: 27, weight: .bold, design: .rounded)).multilineTextAlignment(.center)
            Text("Находим приложения на Mac, помогаем разложить их по папкам и открывать одним движением.")
                .font(.system(size: 14)).foregroundStyle(.secondary).multilineTextAlignment(.center)
                .lineSpacing(4).frame(maxWidth: 370)
            Label("Приложения · Папки · Поиск", systemImage: "sparkles")
                .font(.system(size: 12, weight: .medium)).foregroundStyle(.white.opacity(0.76))
                .padding(.top, 6)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var shortcutPage: some View {
        VStack(spacing: 17) {
            Image(systemName: "keyboard")
                .font(.system(size: 42, weight: .light)).foregroundStyle(.cyan)
            Text("Открывайте по нажатию")
                .font(.system(size: 24, weight: .bold, design: .rounded)).multilineTextAlignment(.center)
            Text("Нажмите на поле и задайте удобную клавишу или сочетание. Можно использовать любую клавишу; сочетание с ⌘, ⌥ или ⇧ обычно меньше мешает работе.")
                .font(.system(size: 13)).foregroundStyle(.secondary).multilineTextAlignment(.center)
                .lineSpacing(3).frame(maxWidth: 390)
            ZStack {
                RoundedRectangle(cornerRadius: 12).fill(.white.opacity(isRecordingShortcut ? 0.13 : 0.08))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(isRecordingShortcut ? .cyan.opacity(0.8) : .white.opacity(0.12), lineWidth: 1))
                HotKeyCaptureView(isRecording: $isRecordingShortcut) { keyCode, flags in
                    do { try store.setShortcut(keyCode: keyCode, modifiers: flags) }
                    catch { store.startupError = error.localizedDescription }
                }
                Text(isRecordingShortcut ? "Нажмите клавишу…" : shortcutLabel)
                    .font(.system(size: 17, weight: .semibold, design: .rounded).monospaced())
                    .allowsHitTesting(false)
            }
            .frame(width: 235, height: 48)
            Text("Нажмите, чтобы изменить сочетание")
                .font(.system(size: 11)).foregroundStyle(.tertiary)
            if let error = store.startupError {
                Text(error).font(.system(size: 11)).foregroundStyle(.red).multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var startupPage: some View {
        VStack(spacing: 17) {
            Image(systemName: "power.circle.fill")
                .font(.system(size: 48, weight: .light)).symbolRenderingMode(.palette).foregroundStyle(.white, .green)
            Text("Готово, когда готовы вы")
                .font(.system(size: 24, weight: .bold, design: .rounded)).multilineTextAlignment(.center)
            Text("Добавьте Lunchpad в объекты входа, чтобы он запускался вместе с Mac. Эту настройку всегда можно изменить позже в системных настройках.")
                .font(.system(size: 13)).foregroundStyle(.secondary).multilineTextAlignment(.center)
                .lineSpacing(3).frame(maxWidth: 390)
            Toggle(isOn: Binding(get: { store.startupEnabled }, set: { store.setLaunchAtLogin($0) })) {
                Label("Запускать при входе в систему", systemImage: "arrow.clockwise.circle")
                    .font(.system(size: 13, weight: .medium))
            }
            .toggleStyle(.switch).padding(14)
                .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 14))
                .frame(maxWidth: 365)
            if let error = store.startupError {
                VStack(spacing: 7) {
                    Text(error).font(.system(size: 11)).foregroundStyle(.red).multilineTextAlignment(.center)
                    Button("Открыть настройки объектов входа") { SMAppService.openSystemSettingsLoginItems() }
                        .font(.system(size: 11, weight: .medium))
                }
                .frame(maxWidth: 360)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var shortcutLabel: String {
        let modifiers = store.shortcutModifiers
        var result = ""
        if modifiers & UInt32(cmdKey) != 0 { result += "⌘" }
        if modifiers & UInt32(optionKey) != 0 { result += "⌥" }
        if modifiers & UInt32(controlKey) != 0 { result += "⌃" }
        if modifiers & UInt32(shiftKey) != 0 { result += "⇧" }
        return result + GlobalHotKeyManager.keyName(for: store.shortcutKeyCode)
    }
}

@MainActor
struct HotKeyCaptureView: NSViewRepresentable {
    @Binding var isRecording: Bool
    var onCapture: (UInt16, UInt32) -> Void

    func makeNSView(context: Context) -> HotKeyCaptureNSView {
        let view = HotKeyCaptureNSView()
        view.isRecording = isRecording
        view.onCapture = { keyCode, flags in
            onCapture(keyCode, Self.carbonModifiers(from: flags))
            isRecording = false
        }
        return view
    }

    func updateNSView(_ view: HotKeyCaptureNSView, context: Context) {
        view.isRecording = isRecording
        view.onCapture = { keyCode, flags in
            onCapture(keyCode, Self.carbonModifiers(from: flags))
            isRecording = false
        }
    }

    private static func carbonModifiers(from flags: NSEvent.ModifierFlags) -> UInt32 {
        var result: UInt32 = 0
        if flags.contains(.command) { result |= UInt32(cmdKey) }
        if flags.contains(.option) { result |= UInt32(optionKey) }
        if flags.contains(.control) { result |= UInt32(controlKey) }
        if flags.contains(.shift) { result |= UInt32(shiftKey) }
        return result
    }
}

@MainActor
final class HotKeyCaptureNSView: NSView {
    var isRecording = false
    var onCapture: ((UInt16, NSEvent.ModifierFlags) -> Void)?
    override var acceptsFirstResponder: Bool { true }

    override func mouseDown(with event: NSEvent) {
        isRecording = true
        window?.makeFirstResponder(self)
    }

    override func keyDown(with event: NSEvent) {
        guard isRecording else { return }
        isRecording = false
        onCapture?(event.keyCode, event.modifierFlags)
    }
}

private struct OnboardingPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.system(size: 13, weight: .semibold))
            .padding(.horizontal, 20).padding(.vertical, 11)
            .background(.cyan.opacity(configuration.isPressed ? 0.68 : 0.9), in: Capsule())
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.72), value: configuration.isPressed)
    }
}

private struct OnboardingSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.system(size: 13, weight: .medium))
            .padding(.horizontal, 17).padding(.vertical, 11)
            .background(.white.opacity(configuration.isPressed ? 0.14 : 0.07), in: Capsule())
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.72), value: configuration.isPressed)
    }
}
