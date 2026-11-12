# ClipClap

A free clipboard history manager for macOS, in the spirit of Windows' Win+V: a menu bar app that keeps what the user copies and pastes it back from a popup. It is open source (MIT), distributed as a notarized DMG on GitHub Releases, and runs on macOS 12 and later.

This file is what an agent needs to work on this repo. It holds facts about this repo only; my working agreement holds the rules for every repo.

## Layout

- `ClipClap/` the AppKit app in Swift 5: `main.swift` and `AppDelegate.swift` (lifecycle, menu bar), `ClipClap.swift` (clipboard polling), `ClipboardItem.swift`, `PopupWindowController.swift`, `HotkeyManager.swift` (global hotkeys), `Settings.swift` (UserDefaults), `PreferencesWindowController.swift`, `Info.plist`, `ClipClap.entitlements`.
- `ClipClap.xcodeproj` is checked in, scheme `ClipClap`, bundle id `com.clipclap.app`, deployment target macOS 12.0. No tests and no package dependencies.
- `.github/workflows/` has `pr-validation.yml` and `release.yml`.

## Build, test and run

```bash
xcodebuild -project ClipClap.xcodeproj -scheme ClipClap -configuration Release -derivedDataPath build clean build CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO
```

- That is the unsigned build CI runs. For a local run, open the project in Xcode and press run.
- The `verify` skill covers it. There are no tests.
- The app needs the Accessibility permission for global hotkeys, and the sandbox is off in the entitlements.

## Deploy

A push to `main` runs `.github/workflows/release.yml`: an unsigned validation build, then, in the `release` environment, a signed Developer ID archive, notarization of the app and the DMG, a `v<version>` tag, and a GitHub Release with the DMG. The version is read from `ClipClap/Info.plist`; the patch number goes up until no tag with it exists, and the build number is the plist's plus one. The version is not committed back. Pull requests to `main` run `pr-validation.yml`, the unsigned build. The signing and notarization values are GitHub secrets (`APPLE_CERTIFICATE_BASE64`, `APPLE_CERTIFICATE_PASSWORD`, `APPLE_TEAM_ID`, `APPLE_ID`, `APPLE_APP_SPECIFIC_PASSWORD`). Deploying is ask-first, and merging to `main` releases.

## Data sources

None. History and preferences live in UserDefaults (domain `com.clipboard.manager` per the README); the app does not use the network.

## Conventions

None beyond the general standards.

## Known traps

None recorded yet.
