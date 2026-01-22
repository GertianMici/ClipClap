import Cocoa

class ClipboardManager {
    static let shared = ClipboardManager()

    private let pasteboard = NSPasteboard.general
    private var lastChangeCount: Int = 0
    private var timer: Timer?
    private var skipNextCopy = false
    private var currentPasteItem: ClipboardItem?

    private(set) var history: [ClipboardItem] = []

    private init() {
        lastChangeCount = pasteboard.changeCount
        loadHistory()
        startMonitoring()
    }

    // MARK: - Monitoring

    func startMonitoring() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkClipboard()
        }
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }

    private func checkClipboard() {
        guard pasteboard.changeCount != lastChangeCount else { return }
        lastChangeCount = pasteboard.changeCount

        // Skip if this was a programmatic copy without history
        if skipNextCopy {
            skipNextCopy = false
            return
        }

        // Skip if history is disabled
        guard Settings.shared.historyEnabled else { return }

        // Get clipboard content
        guard let item = ClipboardItem.fromPasteboard(pasteboard) else { return }

        // Don't add duplicates at the front
        if let firstItem = history.first, firstItem.isEqual(to: item) {
            return
        }

        // Remove duplicate if exists elsewhere in history
        history.removeAll { $0.isEqual(to: item) }

        // Add to front (FIFO queue - newest first)
        history.insert(item, at: 0)

        // Trim to max size
        let maxItems = Settings.shared.maxHistoryItems
        if history.count > maxItems {
            history = Array(history.prefix(maxItems))
        }

        // Update current paste item
        currentPasteItem = item

        // Auto-save periodically
        saveHistory()

        // Post notification for UI updates
        NotificationCenter.default.post(name: .clipboardHistoryDidChange, object: nil)
    }

    // MARK: - Actions

    func pasteFromHistory(at index: Int) {
        guard index >= 0 && index < history.count else { return }

        let item = history[index]

        // Set the item to clipboard
        item.copyToPasteboard(pasteboard)
        lastChangeCount = pasteboard.changeCount

        // Update current paste item (keep it selected until something else is copied)
        currentPasteItem = item

        // Simulate Cmd+V to paste
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.simulatePaste()
        }
    }

    func pasteCurrentItem() {
        guard let item = currentPasteItem ?? history.first else { return }

        item.copyToPasteboard(pasteboard)
        lastChangeCount = pasteboard.changeCount

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.simulatePaste()
        }
    }

    func copyWithoutHistory() {
        skipNextCopy = true

        // Simulate Cmd+C
        simulateCopy()
    }

    func clearHistory() {
        history.removeAll()
        currentPasteItem = nil
        saveHistory()
        NotificationCenter.default.post(name: .clipboardHistoryDidChange, object: nil)
    }

    // MARK: - Keyboard Simulation

    private func simulatePaste() {
        let source = CGEventSource(stateID: .hidSystemState)

        // Key down
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true) // V key
        keyDown?.flags = .maskCommand
        keyDown?.post(tap: .cghidEventTap)

        // Key up
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false)
        keyUp?.flags = .maskCommand
        keyUp?.post(tap: .cghidEventTap)
    }

    private func simulateCopy() {
        let source = CGEventSource(stateID: .hidSystemState)

        // Key down
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x08, keyDown: true) // C key
        keyDown?.flags = .maskCommand
        keyDown?.post(tap: .cghidEventTap)

        // Key up
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x08, keyDown: false)
        keyUp?.flags = .maskCommand
        keyUp?.post(tap: .cghidEventTap)
    }

    // MARK: - Persistence

    func saveHistory() {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(history) {
            UserDefaults.standard.set(data, forKey: "clipboardHistory")
        }
    }

    func loadHistory() {
        guard let data = UserDefaults.standard.data(forKey: "clipboardHistory") else { return }
        let decoder = JSONDecoder()
        if let savedHistory = try? decoder.decode([ClipboardItem].self, from: data) {
            history = savedHistory
            currentPasteItem = history.first
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let clipboardHistoryDidChange = Notification.Name("clipboardHistoryDidChange")
}
