# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build Commands

```bash
# Compile the app
swiftc -O -o MonitorSwap.app/Contents/MacOS/MonitorSwap main.swift -framework Cocoa

# Install to Applications
cp -R MonitorSwap.app /Applications/

# Launch
open /Applications/MonitorSwap.app

# Regenerate app icon (if generate_icon.swift modified)
swift generate_icon.swift
iconutil -c icns MonitorSwap.iconset -o MonitorSwap.app/Contents/Resources/AppIcon.icns
```

## Prerequisites

- macOS 12.0+
- [displayplacer](https://github.com/jakehilborn/displayplacer): `brew install jakehilborn/jakehilborn/displayplacer`

## Architecture

**Single-file menu bar app** - No Xcode project, no Swift Package Manager. Compiles directly with `swiftc`.

- `main.swift` - Complete app: `AppDelegate` handles menu bar UI, position state, and `displayplacer` CLI invocation
- `generate_icon.swift` - Standalone script that programmatically generates the iconset PNGs using Core Graphics
- `MonitorSwap.app/` - Pre-built app bundle structure (Info.plist sets `LSUIElement=true` for menu-bar-only)

## Configuration

Display IDs and positions are hardcoded in `main.swift`. To customize for different monitors:

1. Run `displayplacer list` to get your display IDs and current coordinates
2. Update `macbookID` and `ultrawideID` constants
3. Modify `MonitorConfig.desk` and `MonitorConfig.easyChair` with your coordinates

Key coordinate logic:
- Positive X origin = monitor to the RIGHT of laptop
- Negative X origin = monitor to the LEFT of laptop
- Negative Y = above laptop's bottom edge

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| ⌘D | Desk position |
| ⌘E | Easy Chair position |
| ⌘S | Toggle/swap |
| ⌘Q | Quit |
