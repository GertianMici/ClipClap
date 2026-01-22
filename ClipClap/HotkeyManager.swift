import Cocoa
import Carbon

enum HotkeyType {
    case showHistory
    case copyWithoutHistory
    case paste
}

protocol HotkeyManagerDelegate: AnyObject {
    func hotkeyTriggered(_ hotkey: HotkeyType)
}

class HotkeyManager {
    static let shared = HotkeyManager()

    weak var delegate: HotkeyManagerDelegate?

    private var showHistoryHotkeyRef: EventHotKeyRef?
    private var copyWithoutHistoryHotkeyRef: EventHotKeyRef?

    private var eventHandler: EventHandlerRef?

    private init() {}

    // MARK: - Registration

    func registerHotkeys() {
        unregisterHotkeys()

        // Install event handler
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))

        let handler: EventHandlerUPP = { _, event, userData -> OSStatus in
            guard let event = event else { return OSStatus(eventNotHandledErr) }

            var hotkeyID = EventHotKeyID()
            GetEventParameter(event,
                            EventParamName(kEventParamDirectObject),
                            EventParamType(typeEventHotKeyID),
                            nil,
                            MemoryLayout<EventHotKeyID>.size,
                            nil,
                            &hotkeyID)

            let manager = HotkeyManager.shared

            switch hotkeyID.id {
            case 1:
                DispatchQueue.main.async {
                    manager.delegate?.hotkeyTriggered(.showHistory)
                }
            case 2:
                DispatchQueue.main.async {
                    manager.delegate?.hotkeyTriggered(.copyWithoutHistory)
                }
            default:
                break
            }

            return noErr
        }

        InstallEventHandler(GetApplicationEventTarget(), handler, 1, &eventType, nil, &eventHandler)

        // Register show history hotkey
        let showHistorySettings = Settings.shared.showHistoryHotkey
        registerHotkey(
            id: 1,
            keyCode: showHistorySettings.keyCode,
            modifiers: showHistorySettings.carbonModifiers,
            hotkeyRef: &showHistoryHotkeyRef
        )

        // Register copy without history hotkey
        let copyNoHistorySettings = Settings.shared.copyWithoutHistoryHotkey
        registerHotkey(
            id: 2,
            keyCode: copyNoHistorySettings.keyCode,
            modifiers: copyNoHistorySettings.carbonModifiers,
            hotkeyRef: &copyWithoutHistoryHotkeyRef
        )
    }

    private func registerHotkey(id: UInt32, keyCode: UInt32, modifiers: UInt32, hotkeyRef: inout EventHotKeyRef?) {
        let hotkeyID = EventHotKeyID(signature: OSType(0x434C4950), id: id) // 'CLIP'

        let status = RegisterEventHotKey(
            keyCode,
            modifiers,
            hotkeyID,
            GetApplicationEventTarget(),
            0,
            &hotkeyRef
        )

        if status != noErr {
            print("Failed to register hotkey \(id): \(status)")
        }
    }

    func unregisterHotkeys() {
        if let ref = showHistoryHotkeyRef {
            UnregisterEventHotKey(ref)
            showHistoryHotkeyRef = nil
        }

        if let ref = copyWithoutHistoryHotkeyRef {
            UnregisterEventHotKey(ref)
            copyWithoutHistoryHotkeyRef = nil
        }
    }

    // MARK: - Key Code Helpers

    static func keyCodeToString(_ keyCode: UInt32) -> String {
        let keyCodeMap: [UInt32: String] = [
            0x00: "A", 0x01: "S", 0x02: "D", 0x03: "F", 0x04: "H",
            0x05: "G", 0x06: "Z", 0x07: "X", 0x08: "C", 0x09: "V",
            0x0B: "B", 0x0C: "Q", 0x0D: "W", 0x0E: "E", 0x0F: "R",
            0x10: "Y", 0x11: "T", 0x12: "1", 0x13: "2", 0x14: "3",
            0x15: "4", 0x16: "6", 0x17: "5", 0x18: "=", 0x19: "9",
            0x1A: "7", 0x1B: "-", 0x1C: "8", 0x1D: "0", 0x1E: "]",
            0x1F: "O", 0x20: "U", 0x21: "[", 0x22: "I", 0x23: "P",
            0x25: "L", 0x26: "J", 0x27: "'", 0x28: "K", 0x29: ";",
            0x2A: "\\", 0x2B: ",", 0x2C: "/", 0x2D: "N", 0x2E: "M",
            0x2F: ".", 0x32: "`", 0x24: "Return", 0x30: "Tab",
            0x31: "Space", 0x33: "Delete", 0x35: "Escape",
            0x7A: "F1", 0x78: "F2", 0x63: "F3", 0x76: "F4",
            0x60: "F5", 0x61: "F6", 0x62: "F7", 0x64: "F8",
            0x65: "F9", 0x6D: "F10", 0x67: "F11", 0x6F: "F12"
        ]

        return keyCodeMap[keyCode] ?? "Key \(keyCode)"
    }

    static func stringToKeyCode(_ string: String) -> UInt32? {
        let keyCodeMap: [String: UInt32] = [
            "A": 0x00, "S": 0x01, "D": 0x02, "F": 0x03, "H": 0x04,
            "G": 0x05, "Z": 0x06, "X": 0x07, "C": 0x08, "V": 0x09,
            "B": 0x0B, "Q": 0x0C, "W": 0x0D, "E": 0x0E, "R": 0x0F,
            "Y": 0x10, "T": 0x11, "1": 0x12, "2": 0x13, "3": 0x14,
            "4": 0x15, "6": 0x16, "5": 0x17, "=": 0x18, "9": 0x19,
            "7": 0x1A, "-": 0x1B, "8": 0x1C, "0": 0x1D, "]": 0x1E,
            "O": 0x1F, "U": 0x20, "[": 0x21, "I": 0x22, "P": 0x23,
            "L": 0x25, "J": 0x26, "'": 0x27, "K": 0x28, ";": 0x29,
            "\\": 0x2A, ",": 0x2B, "/": 0x2C, "N": 0x2D, "M": 0x2E,
            ".": 0x2F, "`": 0x32
        ]

        return keyCodeMap[string.uppercased()]
    }

    static func modifiersToString(_ modifiers: UInt32) -> String {
        var parts: [String] = []

        if modifiers & UInt32(cmdKey) != 0 {
            parts.append("⌘")
        }
        if modifiers & UInt32(shiftKey) != 0 {
            parts.append("⇧")
        }
        if modifiers & UInt32(optionKey) != 0 {
            parts.append("⌥")
        }
        if modifiers & UInt32(controlKey) != 0 {
            parts.append("⌃")
        }

        return parts.joined()
    }
}

// MARK: - Hotkey Settings

struct HotkeySettings: Codable {
    var keyCode: UInt32
    var modifiers: NSEvent.ModifierFlags

    var carbonModifiers: UInt32 {
        var result: UInt32 = 0
        if modifiers.contains(.command) { result |= UInt32(cmdKey) }
        if modifiers.contains(.shift) { result |= UInt32(shiftKey) }
        if modifiers.contains(.option) { result |= UInt32(optionKey) }
        if modifiers.contains(.control) { result |= UInt32(controlKey) }
        return result
    }

    var displayString: String {
        let modString = HotkeyManager.modifiersToString(carbonModifiers)
        let keyString = HotkeyManager.keyCodeToString(keyCode)
        return modString + keyString
    }

    // Default hotkeys
    static var showHistoryDefault: HotkeySettings {
        // Cmd+Shift+V (like Windows Win+V)
        HotkeySettings(keyCode: 0x09, modifiers: [.command, .shift])
    }

    static var copyWithoutHistoryDefault: HotkeySettings {
        // Cmd+Shift+C
        HotkeySettings(keyCode: 0x08, modifiers: [.command, .shift])
    }

    // Codable
    enum CodingKeys: String, CodingKey {
        case keyCode
        case modifiersRawValue
    }

    init(keyCode: UInt32, modifiers: NSEvent.ModifierFlags) {
        self.keyCode = keyCode
        self.modifiers = modifiers
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        keyCode = try container.decode(UInt32.self, forKey: .keyCode)
        let rawValue = try container.decode(UInt.self, forKey: .modifiersRawValue)
        modifiers = NSEvent.ModifierFlags(rawValue: rawValue)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(keyCode, forKey: .keyCode)
        try container.encode(modifiers.rawValue, forKey: .modifiersRawValue)
    }
}
