# DMS Hand Mirror

Cozy camera preview plugin for DankMaterialShell (DMS). Inspired by the macOS "Hand Mirror" app.

<img src="screenshot.png" width="800" alt="Screenshot">

## Install

Use the DMS CLI:
```bash
dms plugins install handMirror
```

Or manually:
```bash
git clone https://github.com/hthienloc/dms-hand-mirror ~/.config/DankMaterialShell/plugins/handMirror
```

## Features

- **Camera Preview:** Instant camera check from the DankBar status pill.
- **Snapshot:** Capture frames with optional countdown delay (3s, 5s, 10s) and trigger a preview overlay with Save, Copy, or Discard actions.
- **Visual Filters:** Support for Grayscale, Sepia, and High Contrast filters with adjustable strength and smoothing.
- **Native Clipboard:** Uses DMS native API for high-performance file copying to clipboard.
- **Screen Flash:** Toggleable flash animation on snapshot.

### Bar Interactions

| Action | Result |
|--------|--------|
| **Left Click** | Toggle popout preview |
| **Right Click** | Open floating window (pin to desktop) |

### Popout Controls

- **Scroll Wheel:** Adjust digital zoom.
- **Left Drag:** Pan zoom focal position.
- **Snapshot button:** Capture with configured delay and save to configured directory.
- **Pin button:** Detach camera into a floating window.

### Floating Window Controls

- **Right Drag:** Pan zoom focal position.
- **Scroll Wheel:** Adjust digital zoom.

## IPC Commands

Use `dms ipc call handMirror <command>` to control the mirror from scripts or keybindings.

| Command | Description |
|---------|-------------|
| `toggle` | Toggle popout preview |
| `togglePin` | Toggle floating window (pin to desktop) |

### Keybinding examples (Niri)

```kdl
binds {
    Mod+M { spawn "dms" "ipc" "call" "handMirror" "toggle"; }
}
```

## Requirements

- DankMaterialShell >= 1.5

## TODO / Roadmap

- [ ] **Interactive drawing:** Basic annotation tools for snapshots.
- [ ] **Microphone Indicator:** Real-time microphone input peak level indicator.
- [x] **Visual Filters:** Add vintage/cozy filters and skin smoothing effects.
- [x] **Drag-and-Drop:** Drag snapshots directly into other apps (Discord, Telegram, etc.).
- [ ] **Recording:** Support for capturing short video clips or GIFs.
- [ ] **QR/OCR Integration:** Quickly scan QR codes or extract text from the preview.
- [ ] **Customizable Popout Position:** Option to choose where the popout appears (Left, Center, Right, or near the bar icon).
- [x] **Global Hotkey:** Toggle the mirror window with a system-wide shortcut.

## License

MIT
