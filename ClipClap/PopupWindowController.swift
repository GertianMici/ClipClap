import Cocoa

protocol PopupWindowDelegate: AnyObject {
    func popupDidSelectItem(at index: Int)
    func popupDidCancel()
}

class PopupWindowController: NSWindowController {

    weak var delegate: PopupWindowDelegate?

    private var tableView: NSTableView!
    private var scrollView: NSScrollView!
    private var searchField: NSSearchField!
    private var statusLabel: NSTextField!

    private var items: [ClipboardItem] = []
    private var filteredItems: [ClipboardItem] = []
    private var selectedIndex: Int = 0

    private var localMonitor: Any?
    private var globalMonitor: Any?

    // Track the previously active application to restore focus
    private var previousApp: NSRunningApplication?

    init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 450),
            styleMask: [.titled, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        window.title = "Clipboard History"
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isMovableByWindowBackground = true
        window.level = .floating
        window.backgroundColor = NSColor.windowBackgroundColor
        window.hasShadow = true

        super.init(window: window)

        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - UI Setup

    private func setupUI() {
        guard let contentView = window?.contentView else { return }

        // Search field
        searchField = NSSearchField(frame: NSRect(x: 16, y: 410, width: 368, height: 28))
        searchField.placeholderString = "Search clipboard history..."
        searchField.target = self
        searchField.action = #selector(searchFieldChanged)
        searchField.sendsSearchStringImmediately = true
        contentView.addSubview(searchField)

        // Status label
        statusLabel = NSTextField(labelWithString: "")
        statusLabel.frame = NSRect(x: 16, y: 8, width: 368, height: 20)
        statusLabel.font = NSFont.systemFont(ofSize: 11)
        statusLabel.textColor = .secondaryLabelColor
        statusLabel.alignment = .center
        contentView.addSubview(statusLabel)

        // Scroll view with table
        scrollView = NSScrollView(frame: NSRect(x: 0, y: 32, width: 400, height: 370))
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder

        tableView = NSTableView()
        tableView.headerView = nil
        tableView.rowHeight = 50
        tableView.backgroundColor = .clear
        tableView.selectionHighlightStyle = .regular
        tableView.doubleAction = #selector(tableViewDoubleClicked)
        tableView.target = self

        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("ClipboardColumn"))
        column.width = 380
        tableView.addTableColumn(column)

        tableView.dataSource = self
        tableView.delegate = self

        scrollView.documentView = tableView
        contentView.addSubview(scrollView)
    }

    // MARK: - Show/Hide

    func showPopup(with items: [ClipboardItem]) {
        // Remember the currently active app BEFORE we show our window
        previousApp = NSWorkspace.shared.frontmostApplication

        self.items = items
        self.filteredItems = items
        self.selectedIndex = 0

        searchField.stringValue = ""
        tableView.reloadData()

        if !filteredItems.isEmpty {
            tableView.selectRowIndexes(IndexSet(integer: 0), byExtendingSelection: false)
        }

        updateStatusLabel()

        // Center window on screen
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let windowFrame = window!.frame
            let x = screenFrame.midX - windowFrame.width / 2
            let y = screenFrame.midY - windowFrame.height / 2
            window?.setFrameOrigin(NSPoint(x: x, y: y))
        }

        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        searchField.becomeFirstResponder()

        setupEventMonitors()
    }

    func hidePopup() {
        removeEventMonitors()
        window?.orderOut(nil)
    }

    /// Restore focus to the previous application
    func restorePreviousApp() {
        if let app = previousApp {
            app.activate(options: .activateIgnoringOtherApps)
        }
    }

    // MARK: - Event Monitors

    private func setupEventMonitors() {
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            return self?.handleKeyEvent(event)
        }

        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .leftMouseDown) { [weak self] _ in
            self?.delegate?.popupDidCancel()
        }
    }

    private func removeEventMonitors() {
        if let monitor = localMonitor {
            NSEvent.removeMonitor(monitor)
            localMonitor = nil
        }
        if let monitor = globalMonitor {
            NSEvent.removeMonitor(monitor)
            globalMonitor = nil
        }
    }

    private func handleKeyEvent(_ event: NSEvent) -> NSEvent? {
        switch event.keyCode {
        case 53: // Escape
            delegate?.popupDidCancel()
            return nil

        case 36, 76: // Return, Enter
            if selectedIndex >= 0 && selectedIndex < filteredItems.count {
                let originalIndex = items.firstIndex(where: { $0.id == filteredItems[selectedIndex].id }) ?? selectedIndex
                delegate?.popupDidSelectItem(at: originalIndex)
            }
            return nil

        case 125: // Down arrow
            if selectedIndex < filteredItems.count - 1 {
                selectedIndex += 1
                tableView.selectRowIndexes(IndexSet(integer: selectedIndex), byExtendingSelection: false)
                tableView.scrollRowToVisible(selectedIndex)
            }
            return nil

        case 126: // Up arrow
            if selectedIndex > 0 {
                selectedIndex -= 1
                tableView.selectRowIndexes(IndexSet(integer: selectedIndex), byExtendingSelection: false)
                tableView.scrollRowToVisible(selectedIndex)
            }
            return nil

        case 18...27: // Number keys 1-0
            let number = event.keyCode == 29 ? 0 : Int(event.keyCode) - 17
            if number > 0 && number <= filteredItems.count {
                let index = number - 1
                let originalIndex = items.firstIndex(where: { $0.id == filteredItems[index].id }) ?? index
                delegate?.popupDidSelectItem(at: originalIndex)
                return nil
            }

        default:
            break
        }

        return event
    }

    // MARK: - Actions

    @objc private func searchFieldChanged() {
        let searchText = searchField.stringValue.lowercased()

        if searchText.isEmpty {
            filteredItems = items
        } else {
            filteredItems = items.filter { item in
                item.fullText.lowercased().contains(searchText)
            }
        }

        selectedIndex = 0
        tableView.reloadData()

        if !filteredItems.isEmpty {
            tableView.selectRowIndexes(IndexSet(integer: 0), byExtendingSelection: false)
        }

        updateStatusLabel()
    }

    @objc private func tableViewDoubleClicked() {
        let clickedRow = tableView.clickedRow
        if clickedRow >= 0 && clickedRow < filteredItems.count {
            let originalIndex = items.firstIndex(where: { $0.id == filteredItems[clickedRow].id }) ?? clickedRow
            delegate?.popupDidSelectItem(at: originalIndex)
        }
    }

    private func updateStatusLabel() {
        let historyStatus = Settings.shared.historyEnabled ? "History: On" : "History: Off"
        statusLabel.stringValue = "\(filteredItems.count) items • \(historyStatus) • Press 1-9 to quick paste"
    }
}

// MARK: - NSTableViewDataSource

extension PopupWindowController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return filteredItems.count
    }
}

// MARK: - NSTableViewDelegate

extension PopupWindowController: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let item = filteredItems[row]

        let cellView = NSTableCellView()
        cellView.identifier = NSUserInterfaceItemIdentifier("ClipboardCell")

        // Number indicator
        let numberLabel = NSTextField(labelWithString: row < 9 ? "\(row + 1)" : "")
        numberLabel.frame = NSRect(x: 8, y: 15, width: 20, height: 20)
        numberLabel.font = NSFont.monospacedSystemFont(ofSize: 12, weight: .medium)
        numberLabel.textColor = .secondaryLabelColor
        numberLabel.alignment = .center
        cellView.addSubview(numberLabel)

        // Type icon
        let iconView = NSImageView(frame: NSRect(x: 32, y: 12, width: 24, height: 24))
        switch item.type {
        case .text:
            iconView.image = NSImage(systemSymbolName: "doc.text", accessibilityDescription: "Text")
        case .rtf:
            iconView.image = NSImage(systemSymbolName: "doc.richtext", accessibilityDescription: "Rich Text")
        case .image:
            iconView.image = NSImage(systemSymbolName: "photo", accessibilityDescription: "Image")
        case .file:
            iconView.image = NSImage(systemSymbolName: "folder", accessibilityDescription: "File")
        }
        iconView.contentTintColor = .secondaryLabelColor
        cellView.addSubview(iconView)

        // Content text
        let textField = NSTextField(labelWithString: item.displayText)
        textField.frame = NSRect(x: 64, y: 24, width: 300, height: 18)
        textField.font = NSFont.systemFont(ofSize: 13)
        textField.lineBreakMode = .byTruncatingTail
        cellView.addSubview(textField)

        // Timestamp
        let timeLabel = NSTextField(labelWithString: item.formattedTimestamp)
        timeLabel.frame = NSRect(x: 64, y: 6, width: 300, height: 14)
        timeLabel.font = NSFont.systemFont(ofSize: 11)
        timeLabel.textColor = .secondaryLabelColor
        cellView.addSubview(timeLabel)

        return cellView
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        selectedIndex = tableView.selectedRow
    }
}
