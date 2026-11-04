# Translation & Localization Guide

This guide describes how to contribute and manage translations across `dms-plugins`.

---

## 1. Overview & Workflows

Dux Shell 1.6+ supports native sideload translations stored in `<pluginName>/translations/<locale>.json`.

Currently, two workflows are used depending on the plugin:

| Plugin | Workflow | Link / Location |
| :--- | :--- | :--- |
| **Quick Capture** | **POEditor Web Platform** (Online) | [POEditor Project #839330](https://poeditor.com/projects/view?id=839330) |
| **All Other Plugins** | **Manual Translation** (In-Repo) | `<pluginName>/translations/<locale>.json` |

---

## 2. Quick Capture Translation (POEditor)

Quick Capture uses POEditor for crowdsourced web translations.

- **Web Link:** [https://poeditor.com/projects/view?id=839330](https://poeditor.com/projects/view?id=839330)
- **How to contribute:**
  1. Join the POEditor project at the link above.
  2. Select your language (or request a new language).
  3. Translate terms directly in the web UI.
  4. Changes are exported and merged into `quickCapture/translations/*.json`.

---

## 3. Other Plugins (Manual Translation)

All other plugins in `dms-plugins` are translated manually by editing JSON files in each plugin's `translations/` directory.

### File Structure & Format

Each plugin stores translation files under `<pluginName>/translations/<locale>.json` (e.g. `vi.json`, `zh_CN.json`, `de.json`).

Translations use a two-level JSON dictionary keyed by plugin ID:

```json
{
  "ambientSound": {
    "Ambient Sound": "Âm thanh môi trường",
    "Volume": "Âm lượng"
  }
}
```

### Translation Management Script

The repository provides `scripts/i18n.py` to extract strings, check coverage, and update tables:

```bash
# Check translation status across all plugins
python3 scripts/i18n.py status

# Check detailed status for a specific plugin
python3 scripts/i18n.py status --plugin ambientSound

# Extract translatable strings from QML into translation JSONs
python3 scripts/i18n.py extract --plugin ambientSound

# Update the translation coverage table in the plugin's README.md
python3 scripts/i18n.py status --plugin ambientSound --readme
```

---

## 4. QML Translation Conventions

When writing or modifying QML components:

- Always wrap user-facing text with `I18n.trFor("<pluginId>", "English text")`.
  ```qml
  text: I18n.trFor("ambientSound", "Ambient Sound")
  ```
- Use `.arg(...)` for dynamic placeholders instead of string concatenation:
  ```qml
  text: I18n.trFor("quickCapture", "%1 px").arg(root.strokeWidth)
  ```
- Never hardcode translated strings directly in QML files.
