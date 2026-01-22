import Cocoa

class Settings {
    static let shared = Settings()

    private let defaults = UserDefaults.standard

    // MARK: - Keys

    private enum Keys {
        static let historyEnabled = "historyEnabled"
        static let maxHistoryItems = "maxHistoryItems"
        static let showHistoryHotkey = "showHistoryHotkey"
        static let copyWithoutHistoryHotkey = "copyWithoutHistoryHotkey"
        static let launchAtLogin = "launchAtLogin"
        static let showInDock = "showInDock"
        static let playSoundOnCopy = "playSoundOnCopy"
    }

    // MARK: - Properties

    var historyEnabled: Bool {
        get { defaults.bool(forKey: Keys.historyEnabled) }
        set {
            defaults.set(newValue, forKey: Keys.historyEnabled)
            NotificationCenter.default.post(name: .settingsDidChange, object: nil)
        }
    }

    var maxHistoryItems: Int {
        get {
            let value = defaults.integer(forKey: Keys.maxHistoryItems)
            return value > 0 ? min(value, 50) : 25 // Default to 25, max 50
        }
        set {
            defaults.set(newValue, forKey: Keys.maxHistoryItems)
            NotificationCenter.default.post(name: .settingsDidChange, object: nil)
        }
    }

    var showHistoryHotkey: HotkeySettings {
        get {
            if let data = defaults.data(forKey: Keys.showHistoryHotkey),
               let settings = try? JSONDecoder().decode(HotkeySettings.self, from: data) {
                return settings
            }
            return HotkeySettings.showHistoryDefault
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                defaults.set(data, forKey: Keys.showHistoryHotkey)
            }
            HotkeyManager.shared.registerHotkeys()
            NotificationCenter.default.post(name: .settingsDidChange, object: nil)
        }
    }

    var copyWithoutHistoryHotkey: HotkeySettings {
        get {
            if let data = defaults.data(forKey: Keys.copyWithoutHistoryHotkey),
               let settings = try? JSONDecoder().decode(HotkeySettings.self, from: data) {
                return settings
            }
            return HotkeySettings.copyWithoutHistoryDefault
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                defaults.set(data, forKey: Keys.copyWithoutHistoryHotkey)
            }
            HotkeyManager.shared.registerHotkeys()
            NotificationCenter.default.post(name: .settingsDidChange, object: nil)
        }
    }

    var launchAtLogin: Bool {
        get { defaults.bool(forKey: Keys.launchAtLogin) }
        set {
            defaults.set(newValue, forKey: Keys.launchAtLogin)
            updateLaunchAtLogin(newValue)
            NotificationCenter.default.post(name: .settingsDidChange, object: nil)
        }
    }

    var showInDock: Bool {
        get { defaults.bool(forKey: Keys.showInDock) }
        set {
            defaults.set(newValue, forKey: Keys.showInDock)
            updateDockVisibility(newValue)
            NotificationCenter.default.post(name: .settingsDidChange, object: nil)
        }
    }

    var playSoundOnCopy: Bool {
        get { defaults.bool(forKey: Keys.playSoundOnCopy) }
        set {
            defaults.set(newValue, forKey: Keys.playSoundOnCopy)
            NotificationCenter.default.post(name: .settingsDidChange, object: nil)
        }
    }

    // MARK: - Initialization

    private init() {
        registerDefaults()
    }

    private func registerDefaults() {
        defaults.register(defaults: [
            Keys.historyEnabled: true,
            Keys.maxHistoryItems: 25,
            Keys.launchAtLogin: true,
            Keys.showInDock: false,
            Keys.playSoundOnCopy: false
        ])
    }

    // MARK: - Persistence

    func save() {
        defaults.synchronize()
    }

    func reset() {
        for key in [Keys.historyEnabled, Keys.maxHistoryItems, Keys.showHistoryHotkey,
                    Keys.copyWithoutHistoryHotkey, Keys.launchAtLogin, Keys.showInDock, Keys.playSoundOnCopy] {
            defaults.removeObject(forKey: key)
        }
        registerDefaults()
        HotkeyManager.shared.registerHotkeys()
        NotificationCenter.default.post(name: .settingsDidChange, object: nil)
    }

    // MARK: - System Integration

    private func updateLaunchAtLogin(_ enabled: Bool) {
        // Use SMAppService for macOS 13+ or LSSharedFileList for older versions
        // This is a simplified version - full implementation would use ServiceManagement framework
        #if DEBUG
        print("Launch at login: \(enabled)")
        #endif
    }

    private func updateDockVisibility(_ showInDock: Bool) {
        if showInDock {
            NSApp.setActivationPolicy(.regular)
        } else {
            NSApp.setActivationPolicy(.accessory)
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let settingsDidChange = Notification.Name("settingsDidChange")
}
