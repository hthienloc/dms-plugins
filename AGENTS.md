# Agent Guidelines — dms-plugins

Dux Shell plugins collection maintained by [@hthienloc](https://github.com/hthienloc).

Refer to [`docs/`](docs/index.md) for full references:
- **[Design System & Tokens](docs/design-system.md)**: Semantic colors, sizing, spacing, radii, typography.
- **[Components Reference](docs/components.md)**: Built-in widgets (`qs.DCommon.Widgets`) and shared components (`./shared`).
- **[Plugin Conventions](docs/conventions.md)**: Settings card ordering and native Dux Shell CLI/QML services.
- **[Development & Testing](docs/development.md)**: Setup, IPC commands, and validation checks.

---

## 1. Code Standards

- **Modern QML:** Use `pragma ComponentBehavior: Bound` where appropriate. Standard imports: `qs.Common`, `qs.DCommon.Widgets`, `qs.Services`, `qs.Modules.Plugins`. Add `qs.Widgets` only for shell-specific types.
- **Theme Tokens:** Always use `Theme.*` from `qs.Common` and `Theme.withAlpha()`. Never hardcode hex colors or pixel dimensions.
- **Component Reuse:** Prefer built-in Dux Shell primitives (`DIcon`, `DButton`, `DActionButton`, `DKeycap`, `DDropdown`) and `ToastService`.
- **Internationalization (i18n):** Wrap user-facing strings with `I18n.trFor("<pluginId>", "Text")`. Use `.arg(...)` for dynamic values. See [Translation Guide](docs/translations.md) (Quick Capture via [POEditor](https://poeditor.com/projects/view?id=839330), other plugins manual).
- **Process Safety:** Never concatenate strings in shell execution. Pass command arguments as discrete arrays: `command: ["yt-dlp", "--no-warnings", url]`. If shell syntax is required, use positional parameters: `command: ["sh", "-c", 'command "$1"', "sh", userInput]`.
- **Component Sync:** When modifying `./shared` components, run `python3 scripts/sync_shared.py` to propagate changes, and revert accidental diffs in unrelated plugins.

---

## 2. Verification & Testing

```bash
# Symlink plugin for local testing
ln -sfn "$PWD/<pluginName>" "$HOME/.config/DankMaterialShell/plugins/<pluginName>"

# Hot-reload plugin via IPC (do not restart shell)
dms ipc call plugins reload <pluginName>

# Linting & validation (must pass before commit)
qmllint <pluginName>/*.qml <pluginName>/shared/*.qml

# Widget migration and Dux Shell version audit
python3 scripts/refactor_dcommon.py --check --requires-dms ">=2.0.0"
```

---

## 3. Git & Contribution Hygiene

- **Conventional Commits:** `<type>(<pluginName>): <short description>`
  - Examples: `fix(screenkey): handle click-through mask`, `feat(persona5Calendar): add desktop widget`.
- **PR Description:** Include **What**, **Why**, and **How tested** (with IPC commands run). Enable `maintainer_can_modify=true`.
