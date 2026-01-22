import Cocoa
import Carbon

class AppDelegate: NSObject, NSApplicationDelegate {

    var statusItem: NSStatusItem!
    var clipboardManager: ClipboardManager!
    var hotkeyManager: HotkeyManager!
    var popupWindowController: PopupWindowController?
    var preferencesWindowController: PreferencesWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Initialize clipboard manager
        clipboardManager = ClipboardManager.shared

        // Setup menu bar
        setupMenuBar()

        // Initialize hotkey manager
        hotkeyManager = HotkeyManager.shared
        hotkeyManager.delegate = self
        hotkeyManager.registerHotkeys()

        // Request accessibility permissions if needed
        requestAccessibilityPermissions()
    }

    func applicationWillTerminate(_ notification: Notification) {
        clipboardManager.saveHistory()
        Settings.shared.save()
    }

    // MARK: - Menu Bar Setup

    func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            // Try SF Symbol first, fall back to text
            if let image = NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: "ClipClap") {
                button.image = image
            } else if let image = NSImage(systemSymbolName: "clipboard", accessibilityDescription: "ClipClap") {
                button.image = image
            } else {
                // Fallback to text if no image available
                button.title = "📋"
            }
            button.action = #selector(statusItemClicked)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            print("Menu bar button created successfully")
        } else {
            print("Failed to create menu bar button")
        }

        updateMenu()
    }

    @objc func statusItemClicked(_ sender: NSStatusBarButton) {
        let event = NSApp.currentEvent!

        if event.type == .rightMouseUp {
            showContextMenu()
        } else {
            showHistoryMenu()
        }
    }

    func showHistoryMenu() {
        let menu = NSMenu()

        let history = clipboardManager.history

        if history.isEmpty {
            let emptyItem = NSMenuItem(title: "No clipboard history", action: nil, keyEquivalent: "")
            emptyItem.isEnabled = false
            menu.addItem(emptyItem)
        } else {
            for (index, item) in history.prefix(Settings.shared.maxHistoryItems).enumerated() {
                let displayText = item.displayText
                let menuItem = NSMenuItem(title: displayText, action: #selector(pasteFromHistory(_:)), keyEquivalent: index < 9 ? "\(index + 1)" : "")
                menuItem.tag = index
                menuItem.toolTip = item.fullText
                menu.addItem(menuItem)
            }
        }

        menu.addItem(NSMenuItem.separator())

        // Toggle history enabled
        let historyToggle = NSMenuItem(title: Settings.shared.historyEnabled ? "Disable History" : "Enable History", action: #selector(toggleHistory), keyEquivalent: "")
        menu.addItem(historyToggle)

        // Clear history
        let clearItem = NSMenuItem(title: "Clear History", action: #selector(clearHistory), keyEquivalent: "")
        menu.addItem(clearItem)

        menu.addItem(NSMenuItem.separator())

        // Preferences
        let prefsItem = NSMenuItem(title: "Preferences...", action: #selector(showPreferences), keyEquivalent: ",")
        menu.addItem(prefsItem)

        // Quit
        let quitItem = NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q")
        menu.addItem(quitItem)

        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    func showContextMenu() {
        let menu = NSMenu()

        let prefsItem = NSMenuItem(title: "Preferences...", action: #selector(showPreferences), keyEquivalent: ",")
        menu.addItem(prefsItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q")
        menu.addItem(quitItem)

        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    func updateMenu() {
        // Menu is built dynamically when clicked
    }

    // MARK: - Actions

    @objc func pasteFromHistory(_ sender: NSMenuItem) {
        let index = sender.tag
        clipboardManager.pasteFromHistory(at: index)
    }

    @objc func toggleHistory() {
        Settings.shared.historyEnabled.toggle()
        Settings.shared.save()
    }

    @objc func clearHistory() {
        clipboardManager.clearHistory()
    }

    @objc func showPreferences() {
        if preferencesWindowController == nil {
            preferencesWindowController = PreferencesWindowController()
        }
        preferencesWindowController?.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc func quitApp() {
        NSApplication.shared.terminate(nil)
    }

    // MARK: - Popup Window

    func showPopupWindow() {
        if popupWindowController == nil {
            popupWindowController = PopupWindowController()
        }
        popupWindowController?.delegate = self
        popupWindowController?.showPopup(with: clipboardManager.history)
    }

    func hidePopupWindow() {
        popupWindowController?.hidePopup()
    }

    // MARK: - Accessibility Permissions

    func requestAccessibilityPermissions() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        let trusted = AXIsProcessTrustedWithOptions(options as CFDictionary)

        if !trusted {
            let alert = NSAlert()
            alert.messageText = "Accessibility Permission Required"
            alert.informativeText = "ClipClap needs accessibility permissions to register global hotkeys. Please grant access in System Preferences > Security & Privacy > Privacy > Accessibility."
            alert.alertStyle = .warning
            alert.addButton(withTitle: "Open System Preferences")
            alert.addButton(withTitle: "Later")

            if alert.runModal() == .alertFirstButtonReturn {
                NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
            }
        }
    }
}

// MARK: - HotkeyManagerDelegate

extension AppDelegate: HotkeyManagerDelegate {
    func hotkeyTriggered(_ hotkey: HotkeyType) {
        switch hotkey {
        case .showHistory:
            showPopupWindow()
        case .copyWithoutHistory:
            clipboardManager.copyWithoutHistory()
        case .paste:
            clipboardManager.pasteCurrentItem()
        }
    }
}

// MARK: - PopupWindowDelegate

extension AppDelegate: PopupWindowDelegate {
    func popupDidSelectItem(at index: Int) {
        // First hide the popup and restore focus to the previous app
        hidePopupWindow()
        popupWindowController?.restorePreviousApp()

        // Give the previous app time to regain focus, then paste
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            self.clipboardManager.pasteFromHistory(at: index)
        }
    }

    func popupDidCancel() {
        hidePopupWindow()
        popupWindowController?.restorePreviousApp()
    }
}
