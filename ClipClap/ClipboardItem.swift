import Cocoa

enum ClipboardItemType: String, Codable {
    case text
    case image
    case file
    case rtf
}

class ClipboardItem: Codable {
    let id: UUID
    let type: ClipboardItemType
    let timestamp: Date

    // Text content
    var textContent: String?

    // Image content (stored as PNG data)
    var imageData: Data?

    // File URLs
    var fileURLs: [String]?

    // RTF content
    var rtfData: Data?

    // Original plain text (for RTF items)
    var plainText: String?

    init(type: ClipboardItemType) {
        self.id = UUID()
        self.type = type
        self.timestamp = Date()
    }

    // MARK: - Display

    var displayText: String {
        let maxLength = 50

        switch type {
        case .text:
            let text = (textContent ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            if text.count > maxLength {
                return String(text.prefix(maxLength)) + "..."
            }
            return text

        case .rtf:
            let text = (plainText ?? textContent ?? "RTF Content").trimmingCharacters(in: .whitespacesAndNewlines)
            if text.count > maxLength {
                return String(text.prefix(maxLength)) + "..."
            }
            return text

        case .image:
            return "📷 Image"

        case .file:
            if let urls = fileURLs, let firstURL = urls.first {
                let name = URL(fileURLWithPath: firstURL).lastPathComponent
                if urls.count > 1 {
                    return "📁 \(name) (+\(urls.count - 1) more)"
                }
                return "📁 \(name)"
            }
            return "📁 File"
        }
    }

    var fullText: String {
        switch type {
        case .text:
            return textContent ?? ""
        case .rtf:
            return plainText ?? textContent ?? ""
        case .image:
            return "Image copied at \(formattedTimestamp)"
        case .file:
            return fileURLs?.joined(separator: "\n") ?? ""
        }
    }

    var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }

    // MARK: - Comparison

    func isEqual(to other: ClipboardItem) -> Bool {
        guard type == other.type else { return false }

        switch type {
        case .text:
            return textContent == other.textContent
        case .rtf:
            return rtfData == other.rtfData
        case .image:
            return imageData == other.imageData
        case .file:
            return fileURLs == other.fileURLs
        }
    }

    // MARK: - Pasteboard Operations

    static func fromPasteboard(_ pasteboard: NSPasteboard) -> ClipboardItem? {
        // Check for files first
        if let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true]) as? [URL], !urls.isEmpty {
            let item = ClipboardItem(type: .file)
            item.fileURLs = urls.map { $0.path }
            return item
        }

        // Check for RTF
        if let rtfData = pasteboard.data(forType: .rtf) {
            let item = ClipboardItem(type: .rtf)
            item.rtfData = rtfData

            // Also get plain text version
            if let string = pasteboard.string(forType: .string) {
                item.plainText = string
            } else if let attributedString = NSAttributedString(rtf: rtfData, documentAttributes: nil) {
                item.plainText = attributedString.string
            }

            return item
        }

        // Check for images
        if let image = NSImage(pasteboard: pasteboard) {
            let item = ClipboardItem(type: .image)
            if let tiffData = image.tiffRepresentation,
               let bitmapRep = NSBitmapImageRep(data: tiffData),
               let pngData = bitmapRep.representation(using: .png, properties: [:]) {
                item.imageData = pngData
            }
            return item
        }

        // Check for plain text
        if let string = pasteboard.string(forType: .string), !string.isEmpty {
            let item = ClipboardItem(type: .text)
            item.textContent = string
            return item
        }

        return nil
    }

    func copyToPasteboard(_ pasteboard: NSPasteboard) {
        pasteboard.clearContents()

        switch type {
        case .text:
            if let text = textContent {
                pasteboard.setString(text, forType: .string)
            }

        case .rtf:
            if let rtfData = rtfData {
                pasteboard.setData(rtfData, forType: .rtf)
            }
            if let plainText = plainText {
                pasteboard.setString(plainText, forType: .string)
            }

        case .image:
            if let imageData = imageData, let image = NSImage(data: imageData) {
                pasteboard.writeObjects([image])
            }

        case .file:
            if let urls = fileURLs {
                let nsurls = urls.compactMap { URL(fileURLWithPath: $0) as NSURL }
                pasteboard.writeObjects(nsurls)
            }
        }
    }
}
