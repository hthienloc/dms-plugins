# Contributing to dms-plugins

Contributions to plugins in this repository are welcome. Follow these guidelines to ensure consistency, clean code, and stability.

---

## 1. Core Principles

- **No Magic Numbers:** Never hardcode pixel sizes, margins, padding, or colors. Always use tokens from `Theme` (`qs.Common`).
- **Reuse Built-in Primitives:** Always prefer official Dux Shell components (`DActionButton`, `DDropdown`, `DSlider`, `StyledText`) over custom ad-hoc shapes.
- **Minimal Dependencies:** Never declare external package dependencies for tools Dux Shell provides natively.
- **One Plugin per PR:** Scope each PR strictly to a single plugin directory (`<pluginName>/`).

---

## 2. Technical Documentation & Guides

Consult these focused guides before implementing or updating plugin UI:

- **[Design System & Tokens](docs/design-system.md):** Complete reference for `Theme.buttonHeight*`, `Theme.iconSize*`, spacing, corner radius, and color roles.
- **[Components Reference](docs/components.md):** Official Dux Shell widgets and shared settings components.
- **[Conventions & Native Services](docs/conventions.md):** Directory standards, settings layout, and native CLI/QML replacements.
- **[Development & Testing](docs/development.md):** IPC hot-reloading commands, testing workflows, and linting scripts.

---

## 3. Contribution Workflow

1. **Branching:** Create a feature branch from `main`:
   ```bash
   git checkout -b feat/<pluginName>-<feature>
   ```
2. **Conventional Commits:** Format commit messages with the plugin name as the scope:
   ```
   feat(<pluginName>): <short description>
   fix(<pluginName>): <short description>
   ```
3. **Verification:** Validate your changes locally:
   ```bash
   qmllint <pluginName>/*.qml
   python3 scripts/check_unused_imports.py <pluginName>
   python3 scripts/refactor_dcommon.py --check --requires-dms ">=2.0.0"
   ```
4. **Pull Requests:**
   - Target `main`.
   - Keep PR description concise: **What**, **Why**, and **How tested**.
   - Enable `maintainer_can_modify=true`.
