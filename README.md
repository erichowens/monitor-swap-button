# Monitor Swap

A macOS menu bar utility to quickly swap your dual-monitor arrangement between two positions.

## Use Case

When working at a desk with a laptop and an ultrawide monitor, you might switch positions:
- **Desk**: Laptop in front, ultrawide to the right
- **Easy Chair**: Sitting on the other side, monitors are flipped

This app lets you toggle between these layouts with a single click.

## Installation

### Prerequisites
- macOS 12.0+
- [displayplacer](https://github.com/jakehilborn/displayplacer) - Install via Homebrew:
  ```bash
  brew install jakehilborn/jakehilborn/displayplacer
  ```

### Building
```bash
# Compile the app
swiftc -O -o MonitorSwap.app/Contents/MacOS/MonitorSwap main.swift -framework Cocoa

# Install to Applications
cp -R MonitorSwap.app /Applications/

# Launch
open /Applications/MonitorSwap.app
```

### Generate Icon (optional)
```bash
swift generate_icon.swift
iconutil -c icns MonitorSwap.iconset -o MonitorSwap.app/Contents/Resources/AppIcon.icns
```

## Usage

| Action | Method |
|--------|--------|
| Toggle position | Click menu bar icon |
| Desk mode | ⌘D |
| Easy Chair mode | ⌘E |
| Quick swap | ⌘S |

**Menu bar icons:**
- 🖥️ = Desk (ultrawide on RIGHT)
- 🪑 = Easy Chair (ultrawide on LEFT)

## Configuration

Edit `main.swift` to customize your monitor positions. The key values are:

```swift
// Your display IDs from `displayplacer list`
let macbookID = "YOUR-MACBOOK-ID"
let ultrawideID = "YOUR-ULTRAWIDE-ID"

// Position configurations - adjust origin coordinates
// Positive X = right of laptop, Negative X = left of laptop
// Negative Y = above laptop's bottom edge
```

Run `displayplacer list` to get your display IDs and current coordinates.

## Auto-start at Login

The app can be added to login items:
```bash
osascript -e 'tell application "System Events" to make login item at end with properties {path:"/Applications/MonitorSwap.app", hidden:false}'
```

## License

MIT
