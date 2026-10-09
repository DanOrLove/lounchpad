import AppKit
import Carbon.HIToolbox

@MainActor
final class GlobalHotKeyManager {
    static let shared = GlobalHotKeyManager()

    var action: (() -> Void)?
    private var hotKey: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?

    private init() {}

    static func keyName(for keyCode: UInt16) -> String {
        let special: [UInt16: String] = [
            36: "Return", 48: "Tab", 49: "Space", 51: "Delete", 53: "Esc",
            76: "Enter", 115: "Home", 116: "Page Up", 117: "Forward Delete",
            119: "End", 121: "Page Down", 123: "←", 124: "→", 125: "↓", 126: "↑"
        ]
        if let name = special[keyCode] { return name }
        guard let source = TISCopyCurrentKeyboardLayoutInputSource()?.takeRetainedValue(),
              let rawLayout = TISGetInputSourceProperty(source, kTISPropertyUnicodeKeyLayoutData) else { return "Key \(keyCode)" }
        let layoutData = unsafeBitCast(rawLayout, to: CFData.self)
        guard let bytes = CFDataGetBytePtr(layoutData) else { return "Key \(keyCode)" }
        let keyboard = UnsafeRawPointer(bytes).assumingMemoryBound(to: UCKeyboardLayout.self)
        var deadKeyState: UInt32 = 0
        var length = 0
        var characters = [UniChar](repeating: 0, count: 4)
        let status = UCKeyTranslate(keyboard, keyCode, UInt16(kUCKeyActionDisplay), 0, UInt32(LMGetKbdType()), OptionBits(kUCKeyTranslateNoDeadKeysBit), &deadKeyState, characters.count, &length, &characters)
        guard status == noErr, length > 0 else { return "Key \(keyCode)" }
        return String(utf16CodeUnits: characters, count: length).uppercased()
    }

    func register(keyCode: UInt16, modifiers: UInt32) throws {
        if let hotKey { UnregisterEventHotKey(hotKey) }
        installEventHandlerIfNeeded()
        let identifier = EventHotKeyID(signature: OSType(0x4C504144), id: 1)
        var newHotKey: EventHotKeyRef?
        let status = RegisterEventHotKey(UInt32(keyCode), modifiers, identifier, GetApplicationEventTarget(), 0, &newHotKey)
        guard status == noErr, let newHotKey else {
            throw NSError(domain: NSOSStatusErrorDomain, code: Int(status), userInfo: [NSLocalizedDescriptionKey: "Не удалось зарегистрировать эту комбинацию клавиш."])
        }
        hotKey = newHotKey
    }

    private func installEventHandlerIfNeeded() {
        guard eventHandler == nil else { return }
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), { _, _, _ in
            DispatchQueue.main.async {
                MainActor.assumeIsolated { GlobalHotKeyManager.shared.action?() }
            }
            return noErr
        }, 1, &eventType, nil, &eventHandler)
    }
}
