import Carbon
import Foundation

final class GlobalShortcutManager {
    private var hotKey: EventHotKeyRef?
    private var handlerRef: EventHandlerRef?
    private let action: () -> Void

    init(action: @escaping () -> Void) { self.action = action }

    func register(_ choice: ShortcutChoice) {
        unregister()
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let pointer = Unmanaged.passUnretained(self).toOpaque()
        InstallEventHandler(GetApplicationEventTarget(), { _, _, userData in
            guard let userData else { return noErr }
            let manager = Unmanaged<GlobalShortcutManager>.fromOpaque(userData).takeUnretainedValue()
            DispatchQueue.main.async { manager.action() }
            return noErr
        }, 1, &eventType, pointer, &handlerRef)
        let identifier = EventHotKeyID(signature: OSType(0x4E54444F), id: 1)
        RegisterEventHotKey(choice.keyCode, UInt32(optionKey), identifier, GetApplicationEventTarget(), 0, &hotKey)
    }

    func unregister() {
        if let hotKey { UnregisterEventHotKey(hotKey); self.hotKey = nil }
        if let handlerRef { RemoveEventHandler(handlerRef); self.handlerRef = nil }
    }

    deinit { unregister() }
}
