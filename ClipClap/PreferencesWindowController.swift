import Cocoa
import Carbon

class PreferencesWindowController: NSWindowController {

    // UI Elements
    private var historyToggle: NSSwitch!
    private var maxItemsSlider: NSSlider!
    private var maxItemsLabel: NSTextField!
    private var showHistoryHotkeyField: HotkeyTextField!
    private var copyNoHistoryHotkeyField: HotkeyTextField!
    private var launchAtLoginToggle: NSSwitch!
    private var showInDockToggle: NSSwitch!

    init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 450, height: 420),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )

        window.title = "ClipClap Preferences"
        window.center()

        super.init(window: window)

        setupUI()
        loadSettings()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UI Setup

    private func setupUI() {
        guard let contentView = window?.contentView else { return }

        var yOffset: CGFloat = 380

        // MARK: History Section
        let historyLabel = createSectionLabel("History", y: yOffset)
        contentView.addSubview(historyLabel)
        yOffset -= 35

        // Enable History
        let historyRow = createRow(label: "Enable clipboard history:", y: yOffset)
        contentView.addSubview(historyRow.label)

        historyToggle = NSSwitch()
        historyToggle.frame = NSRect(x: 200, y: yOffset - 2, width: 40, height: 20)
        historyToggle.target = self
        historyToggle.action = #selector(historyToggleChanged)
        contentView.addSubview(historyToggle)
        yOffset -= 35

        // Max History Items (range 2-50)
        let maxItemsRow = createRow(label: "Maximum history items:", y: yOffset)
        contentView.addSubview(maxItemsRow.label)

        maxItemsSlider = NSSlider(value: 25, minValue: 2, maxValue: 50, target: self, action: #selector(maxItemsSliderChanged))
        maxItemsSlider.frame = NSRect(x: 200, y: yOffset, width: 150, height: 20)
        maxItemsSlider.numberOfTickMarks = 0
        maxItemsSlider.allowsTickMarkValuesOnly = false
        contentView.addSubview(maxItemsSlider)

        maxItemsLabel = NSTextField(labelWithString: "25")
        maxItemsLabel.frame = NSRect(x: 360, y: yOffset, width: 50, height: 20)
        contentView.addSubview(maxItemsLabel)
        yOffset -= 45

        // MARK: Hotkeys Section
        let hotkeysLabel = createSectionLabel("Keyboard Shortcuts", y: yOffset)
        contentView.addSubview(hotkeysLabel)
        yOffset -= 35

        // Show History Hotkey
        let showHistoryRow = createRow(label: "Show clipboard history:", y: yOffset)
        contentView.addSubview(showHistoryRow.label)

        showHistoryHotkeyField = HotkeyTextField()
        showHistoryHotkeyField.frame = NSRect(x: 200, y: yOffset - 2, width: 150, height: 24)
        showHistoryHotkeyField.hotkeyDelegate = self
        contentView.addSubview(showHistoryHotkeyField)

        let showHistoryResetBtn = NSButton(title: "Reset", target: self, action: #selector(resetShowHistoryHotkey))
        showHistoryResetBtn.frame = NSRect(x: 360, y: yOffset - 2, width: 60, height: 24)
        showHistoryResetBtn.bezelStyle = .rounded
        contentView.addSubview(showHistoryResetBtn)
        yOffset -= 35

        // Copy Without History Hotkey
        let copyNoHistoryRow = createRow(label: "Copy without history:", y: yOffset)
        contentView.addSubview(copyNoHistoryRow.label)

        copyNoHistoryHotkeyField = HotkeyTextField()
        copyNoHistoryHotkeyField.frame = NSRect(x: 200, y: yOffset - 2, width: 150, height: 24)
        copyNoHistoryHotkeyField.hotkeyDelegate = self
        contentView.addSubview(copyNoHistoryHotkeyField)

        let copyNoHistoryResetBtn = NSButton(title: "Reset", target: self, action: #selector(resetCopyNoHistoryHotkey))
        copyNoHistoryResetBtn.frame = NSRect(x: 360, y: yOffset - 2, width: 60, height: 24)
        copyNoHistoryResetBtn.bezelStyle = .rounded
        contentView.addSubview(copyNoHistoryResetBtn)
        yOffset -= 45

        // MARK: General Section
        let generalLabel = createSectionLabel("General", y: yOffset)
        contentView.addSubview(generalLabel)
        yOffset -= 35

        // Launch at Login and Show in Dock - SIDE BY SIDE
        let launchLabel = NSTextField(labelWithString: "Launch at login:")
        launchLabel.frame = NSRect(x: 20, y: yOffset, width: 110, height: 20)
        launchLabel.alignment = .right
        contentView.addSubview(launchLabel)

        launchAtLoginToggle = NSSwitch()
        launchAtLoginToggle.frame = NSRect(x: 135, y: yOffset - 2, width: 40, height: 20)
        launchAtLoginToggle.target = self
        launchAtLoginToggle.action = #selector(launchAtLoginChanged)
        contentView.addSubview(launchAtLoginToggle)

        let dockLabel = NSTextField(labelWithString: "Show in Dock:")
        dockLabel.frame = NSRect(x: 220, y: yOffset, width: 100, height: 20)
        dockLabel.alignment = .right
        contentView.addSubview(dockLabel)

        showInDockToggle = NSSwitch()
        showInDockToggle.frame = NSRect(x: 325, y: yOffset - 2, width: 40, height: 20)
        showInDockToggle.target = self
        showInDockToggle.action = #selector(showInDockChanged)
        contentView.addSubview(showInDockToggle)

        // MARK: Buttons
        let clearHistoryBtn = NSButton(title: "Clear History", target: self, action: #selector(clearHistory))
        clearHistoryBtn.frame = NSRect(x: 20, y: 20, width: 120, height: 32)
        clearHistoryBtn.bezelStyle = .rounded
        contentView.addSubview(clearHistoryBtn)

        let resetAllBtn = NSButton(title: "Reset All Settings", target: self, action: #selector(resetAllSettings))
        resetAllBtn.frame = NSRect(x: 150, y: 20, width: 140, height: 32)
        resetAllBtn.bezelStyle = .rounded
        contentView.addSubview(resetAllBtn)
    }

    private func createSectionLabel(_ text: String, y: CGFloat) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.frame = NSRect(x: 20, y: y, width: 410, height: 20)
        label.font = NSFont.boldSystemFont(ofSize: 13)
        return label
    }

    private func createRow(label text: String, y: CGFloat) -> (label: NSTextField, yOffset: CGFloat) {
        let label = NSTextField(labelWithString: text)
        label.frame = NSRect(x: 40, y: y, width: 150, height: 20)
        label.alignment = .right
        return (label, y)
    }

    // MARK: - Load/Save Settings

    private func loadSettings() {
        let settings = Settings.shared

        historyToggle.state = settings.historyEnabled ? .on : .off
        maxItemsSlider.integerValue = settings.maxHistoryItems
        maxItemsLabel.stringValue = "\(settings.maxHistoryItems)"
        showHistoryHotkeyField.hotkeySettings = settings.showHistoryHotkey
        copyNoHistoryHotkeyField.hotkeySettings = settings.copyWithoutHistoryHotkey
        launchAtLoginToggle.state = settings.launchAtLogin ? .on : .off
        showInDockToggle.state = settings.showInDock ? .on : .off
    }

    // MARK: - Actions

    @objc private func historyToggleChanged() {
        Settings.shared.historyEnabled = historyToggle.state == .on
    }

    @objc private func maxItemsSliderChanged() {
        let value = maxItemsSlider.integerValue
        maxItemsLabel.stringValue = "\(value)"
        Settings.shared.maxHistoryItems = value
    }

    @objc private func launchAtLoginChanged() {
        Settings.shared.launchAtLogin = launchAtLoginToggle.state == .on
    }

    @objc private func showInDockChanged() {
        Settings.shared.showInDock = showInDockToggle.state == .on
    }

    @objc private func resetShowHistoryHotkey() {
        Settings.shared.showHistoryHotkey = HotkeySettings.showHistoryDefault
        showHistoryHotkeyField.hotkeySettings = Settings.shared.showHistoryHotkey
    }

    @objc private func resetCopyNoHistoryHotkey() {
        Settings.shared.copyWithoutHistoryHotkey = HotkeySettings.copyWithoutHistoryDefault
        copyNoHistoryHotkeyField.hotkeySettings = Settings.shared.copyWithoutHistoryHotkey
    }

    @objc private func clearHistory() {
        let alert = NSAlert()
        alert.messageText = "Clear Clipboard History?"
        alert.informativeText = "This will permanently delete all clipboard history. This action cannot be undone."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Clear")
        alert.addButton(withTitle: "Cancel")

        if alert.runModal() == .alertFirstButtonReturn {
            ClipboardManager.shared.clearHistory()
        }
    }

    @objc private func resetAllSettings() {
        let alert = NSAlert()
        alert.messageText = "Reset All Settings?"
        alert.informativeText = "This will reset all preferences to their default values."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Reset")
        alert.addButton(withTitle: "Cancel")

        if alert.runModal() == .alertFirstButtonReturn {
            Settings.shared.reset()
            loadSettings()
        }
    }
}

// MARK: - HotkeyTextFieldDelegate

extension PreferencesWindowController: HotkeyTextFieldDelegate {
    func hotkeyTextField(_ textField: HotkeyTextField, didRecordHotkey settings: HotkeySettings) {
        if textField === showHistoryHotkeyField {
            Settings.shared.showHistoryHotkey = settings
        } else if textField === copyNoHistoryHotkeyField {
            Settings.shared.copyWithoutHistoryHotkey = settings
        }
    }
}

// MARK: - HotkeyTextField

protocol HotkeyTextFieldDelegate: AnyObject {
    func hotkeyTextField(_ textField: HotkeyTextField, didRecordHotkey settings: HotkeySettings)
}

class HotkeyTextField: NSTextField {

    weak var hotkeyDelegate: HotkeyTextFieldDelegate?

    var hotkeySettings: HotkeySettings? {
        didSet {
            updateDisplay()
        }
    }

    private var isRecording = false

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        isEditable = false
        isSelectable = false
        alignment = .center
        font = NSFont.systemFont(ofSize: 12)
        bezelStyle = .roundedBezel
        placeholderString = "Click to record"
    }

    private func updateDisplay() {
        if let settings = hotkeySettings {
            stringValue = settings.displayString
        } else {
            stringValue = ""
        }
    }

    override func mouseDown(with event: NSEvent) {
        startRecording()
    }

    private func startRecording() {
        isRecording = true
        stringValue = "Press shortcut..."
        window?.makeFirstResponder(self)

        // Temporarily unregister hotkeys while recording
        HotkeyManager.shared.unregisterHotkeys()
    }

    private func stopRecording() {
        isRecording = false
        updateDisplay()

        // Re-register hotkeys
        HotkeyManager.shared.registerHotkeys()
    }

    override func keyDown(with event: NSEvent) {
        guard isRecording else {
            super.keyDown(with: event)
            return
        }

        // Escape to cancel
        if event.keyCode == 53 {
            stopRecording()
            return
        }

        // Require at least one modifier
        let modifiers = event.modifierFlags.intersection([.command, .shift, .option, .control])
        guard !modifiers.isEmpty else {
            return
        }

        // Create new hotkey settings
        let newSettings = HotkeySettings(keyCode: UInt32(event.keyCode), modifiers: modifiers)
        hotkeySettings = newSettings
        hotkeyDelegate?.hotkeyTextField(self, didRecordHotkey: newSettings)

        stopRecording()
    }

    override func flagsChanged(with event: NSEvent) {
        guard isRecording else {
            super.flagsChanged(with: event)
            return
        }

        // Show current modifiers while recording
        let modifiers = event.modifierFlags.intersection([.command, .shift, .option, .control])
        if modifiers.isEmpty {
            stringValue = "Press shortcut..."
        } else {
            var parts: [String] = []
            if modifiers.contains(.control) { parts.append("⌃") }
            if modifiers.contains(.option) { parts.append("⌥") }
            if modifiers.contains(.shift) { parts.append("⇧") }
            if modifiers.contains(.command) { parts.append("⌘") }
            stringValue = parts.joined() + "..."
        }
    }

    override var acceptsFirstResponder: Bool {
        return true
    }

    override func resignFirstResponder() -> Bool {
        if isRecording {
            stopRecording()
        }
        return super.resignFirstResponder()
    }
}
