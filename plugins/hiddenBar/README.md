# Hidden Bar

Hide unused bar widgets and expand them on demand.

<img src="screenshot.png" width="400" alt="Screenshot">

## Install

Use the DMS CLI:
```bash
dms plugins install hiddenBar
```

Or manually:
```bash
git clone https://github.com/hthienloc/dms-hidden-bar ~/.config/DankMaterialShell/plugins/hiddenBar
```

## Features

- **Smart hide** - Collapse widgets to reclaim bar space
- **Hover to expand** - Reveal hidden widgets by hovering over the trigger area
- **Auto-collapse** - Hide again after inactivity
- **Widget control** - Automatically or manually blacklist/whitelist which widgets get hidden
- **Slide animation** - Widgets slide in and out as the bar collapses (toggleable, adjustable duration)
- **Exclude items** - Keep system tray or clock always visible

## Usage

| Action | Result |
|--------|--------|
| Left click | Toggle expand |
| Right click | Pin/unpin expanded state |

> [!NOTE]
> When newly adding this widget or adding other widgets to the status bar (hidden area), you need to restart DankMaterialShell (`dms restart` or reload session) for the plugin to recognize and manage the new widgets.

## IPC Commands

Use `dms ipc call hiddenBar <command>` to control the bar from scripts or keybindings.

| Command | Description |
|---------|-------------|
| `toggle` | Toggle expand/collapse |
| `togglePin` | Toggle pin state (prevents auto-collapse) |

### Keybinding examples

**Niri:**
```kdl
bindings {
    Mod+Backslash { spawn "dms" "ipc" "call" "hiddenBar" "toggle"; }
    Mod+Shift+Backslash { spawn "dms" "ipc" "call" "hiddenBar" "togglePin"; }
}
```

**Hyprland:**
```ini
bind = SUPER, backslash, exec, dms ipc call hiddenBar toggle
bind = SUPER_SHIFT, backslash, exec, dms ipc call hiddenBar togglePin
```

## License

GPL-3.0

## Roadmap / TODO
- [x] **Granular Widget Control:** Settings interface to manually whitelist/blacklist specific widgets for hiding.
- [x] **Smooth Animations:** Slide transition that reclaims the freed space when expanding/collapsing the hidden area.
- [x] **Global Keybinding:** IPC commands (`toggle`, `expand`, `collapse`, `pin`, `unpin`) for use with any compositor keybinding system.
