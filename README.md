# ClipClap for macOS

A free, open-source clipboard history manager for macOS — bringing Windows-style clipboard history (Win+V) to your Mac.

![macOS](https://img.shields.io/badge/macOS-12.0+-blue)
![Swift](https://img.shields.io/badge/Swift-5.0-orange)
![License](https://img.shields.io/badge/License-MIT-green)

## Features

- **📋 Clipboard History** — Automatically saves everything you copy (text, images, files, rich text)
- **⌨️ Keyboard Shortcut** — Press `⌘⇧V` to instantly access your clipboard history
- **🔢 Quick Paste** — Press `1-9` to quickly paste recent items
- **🔍 Search** — Filter through your clipboard history
- **⚙️ Configurable** — Customize hotkeys, history size (2-50 items), and more
- **🔒 Privacy-First** — All data stays local on your Mac
- **🚀 Lightweight** — Native Swift app, minimal memory footprint
- **🆓 Free & Open Source** — No ads, no subscriptions, no tracking

## Installation

### Download Pre-built Release
1. Go to [Releases](https://github.com/GertianMici/ClipClap/releases)
2. Download the latest `ClipClap.dmg`
3. Open the DMG and drag ClipClap to your Applications folder
4. Launch ClipClap from Applications

### Option 3: Build from Source
```bash
# Clone the repository
git clone https://github.com/GertianMici/ClipClap.git
cd ClipClap

# Open in Xcode
open ClipClap.xcodeproj

# Build and run (⌘R) or archive for distribution
```

**Requirements:**
- macOS 12.0 (Monterey) or later
- Xcode 15.0+ (for building from source)

## First Launch Setup

1. **Grant Accessibility Permissions** — Required for global hotkeys
   - Go to **System Settings → Privacy & Security → Accessibility**
   - Click the `+` button and add ClipClap
   - Toggle it **ON**

2. **Restart the app** if needed

## Usage

### Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `⌘⇧V` | Open clipboard history popup |
| `⌘⇧C` | Copy without adding to history |
| `1-9` | Quick paste item by number (in popup) |
| `↑/↓` | Navigate history |
| `Enter` | Paste selected item |
| `Esc` | Close popup |

### Menu Bar

- **Left-click** the 📋 icon → View clipboard history
- **Right-click** → Access Preferences and Quit

### Preferences

Access via menu bar right-click → Preferences, or `⌘,`

- **History size**: 2-50 items (default: 25)
- **Custom hotkeys**: Change keyboard shortcuts
- **Launch at login**: Start automatically with macOS
- **Show in Dock**: Toggle dock icon visibility

## How It Works

1. ClipClap monitors your system clipboard every 0.5 seconds
2. When you copy something, it's added to the history queue (FIFO)
3. Duplicates are automatically removed (keeping the newest)
4. When you paste from history, focus returns to your previous app automatically

## Privacy

- ✅ **100% Local** — All data stored on your Mac only
- ✅ **No Analytics** — No tracking, no telemetry
- ✅ **No Network** — App never connects to the internet
- ✅ **Open Source** — Fully auditable code

Data is stored in `~/Library/Preferences/` via UserDefaults.

## Contributing

Contributions are welcome! Here's how you can help:

1. **Fork** the repository
2. **Create** a feature branch (`git checkout -b feature/amazing-feature`)
3. **Commit** your changes (`git commit -m 'Add amazing feature'`)
4. **Push** to the branch (`git push origin feature/amazing-feature`)
5. **Open** a Pull Request

### Development Setup

```bash
git clone https://github.com/GertianMici/ClipClap.git
cd ClipClap
open ClipClap.xcodeproj
```

### Project Structure

```
ClipClap/
├── AppDelegate.swift          # App lifecycle & menu bar
├── ClipClap.swift             # Core clipboard monitoring
├── ClipboardItem.swift        # Data model for clipboard items
├── PopupWindowController.swift # History popup UI
├── HotkeyManager.swift        # Global hotkey handling
├── Settings.swift             # User preferences
├── PreferencesWindowController.swift # Settings UI
└── main.swift                 # App entry point
```

## Troubleshooting

### Hotkeys not working?
1. Check Accessibility permissions are granted
2. Ensure no other app uses the same shortcut
3. Try resetting hotkeys in Preferences

### Menu bar icon not showing?
1. Your menu bar might be full — try removing some icons
2. Toggle "Show in Dock" in Preferences to refresh

### App not starting?
1. Check if it's running in Activity Monitor
2. Try deleting preferences: `defaults delete com.clipboard.manager`

## License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Inspired by Windows 10/11 clipboard history (Win+V)
- Built with Swift and AppKit

---

**Made with ❤️ for the Mac community**

[Report Bug](https://github.com/GertianMici/ClipClap/issues) · [Request Feature](https://github.com/GertianMici/ClipClap/issues)
