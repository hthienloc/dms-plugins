# Dux Shell Plugin Conventions & Guidelines

Guidelines and structural standards for plugins in `dms-plugins`.

---

## 1. Directory & Naming Structure

- **Plugin Directory:** Must use **camelCase** (e.g. `ambientSound`, `quickCapture`, `screenkey`).
- **Repository / Package Name:** Must use **kebab-case** with `dms-` prefix (e.g. `dms-ambient-sound`).
- **Shared Components:** Always copy and import from `./shared` (`import "./shared"`).

---

## 2. Standard Settings Layout (`*Settings.qml`)

To keep settings consistent across all plugins, organize `SettingsCard` sections in this order:

1. **Usage Guide (`UsageGuide`):** Must be the **first** card below the title. Shows users key actions, mouse clicks, and shortcuts.
2. **General Settings:** Core toggles, primary modes, main features.
3. **Appearance / Display:** Colors, sizing, keycap styles, layouts.
4. **Behavior / Input:** Key bindings, device selection, thresholds.
5. **IPC Commands:** `CopyBox` list showing command strings for shell scripts or window manager shortcuts.
6. **Credits (`CreditsList`):** Optional card at the bottom giving credit to original authors, artwork, and inspirations with clickable chips.

### Example Structure:
```qml
PluginSettings {
    id: root
    pluginId: "myPlugin"

    SettingsCard {
        SectionTitle {
            id: usageTitle
            text: I18n.tr("Usage Guide")
            icon: "menu_book"
            collapsible: true
            settingKey: "usageGuideExpanded"
        }
        UsageGuide {
            expanded: usageTitle.isExpanded
            items: [
                I18n.tr("<b>Left-click</b> the pill to open the menu."),
                I18n.tr("<b>Right-click</b> to toggle mute.")
            ]
        }
    }

    SettingsCard {
        SectionTitle { text: I18n.tr("General"); icon: "tune" }
        ToggleSettingPlus {
            settingKey: "enabled"
            label: I18n.tr("Enable Feature")
            defaultValue: true
        }
    }

    SettingsCard {
        SectionTitle {
            id: creditsTitle
            text: I18n.tr("Credits")
            icon: "favorite"
            collapsible: true
            settingKey: "creditsExpanded"
        }
        CreditsList {
            expanded: creditsTitle.isExpanded
            items: [
                {
                    author: "AuthorName",
                    url: "https://github.com/...",
                    role: I18n.tr("Original artwork and concept."),
                    icon: "palette"
                }
            ]
        }
    }
}
```

---

## 3. Native Services & CLI Replacements

Never require external packages when Dux Shell provides built-in replacements:

| Capability | External Package to Avoid | Dux Shell Native Solution |
| :--- | :--- | :--- |
| **Clipboard** | `wl-clipboard`, `xclip` | `dms cl copy <text>`, `dms cl paste` |
| **Notifications** | `libnotify` (`notify-send`) | `dms notify "<title>" "<message>"` |
| **Screenshots** | `grim`, `slurp`, `flameshot`| `dms screenshot [region\|full\|all]` |
| **Open URL / File** | `xdg-open`, `gio open` | `dms open <url\|path>` |
| **Audio Volume / Mute** | `pactl`, `wpctl` | `AudioService` (`import qs.Services`) |
| **Network / VPN** | `nmcli` | `NetworkService` |
| **Bluetooth** | `bluetoothctl` | `BluetoothService` |
| **Output / Screens** | Polling `hyprctl` / `niri msg` | `CompositorService.screens` / `NiriService` |
| **State Persistence** | Writing ad-hoc JSON files | `PluginService.loadPluginState()` / `savePluginState()` |

---

## 4. Safe Command Execution

When executing external processes:
- Pass arguments as arrays (`command: ["bin", "arg1", "arg2"]`) rather than shell string concatenation.
- Never interpolate variables into `sh -c` strings without escaping. Pass values as positional arguments: `["sh", "-c", 'cmd "$1"', "sh", userInput]`.
