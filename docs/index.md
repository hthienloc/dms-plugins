# Dux Shell Plugins Documentation

Welcome to the documentation for the `dms-plugins` ecosystem.

---

## Document Index

1. **[Design System & Tokens](design-system.md)**
   - Strict theme guidelines (no hardcoded colors, sizes, or margins).
   - Dynamic token tables: Colors, button heights, icon sizes, spacing, corner radii, typography.

2. **[Components Reference](components.md)**
   - Official Dux Shell widgets (`DActionButton`, `DDropdown`, `DSlider`, `DButton`).
   - Repository shared components (`SettingsCard`, `UsageGuide`, `CreditsList`, settings rows).

3. **[Conventions & Native Services](conventions.md)**
   - Plugin naming and directory structure.
   - Standard settings layout and card ordering.
   - Native Dux Shell CLI alternatives and in-process QML services.

4. **[Development & Testing](development.md)**
   - Local setup and symlinking.
   - Hot-reloading and testing via IPC.
   - Code validation (`qmllint`).

5. **[Translation & Localization](translations.md)**
   - Translation workflows (POEditor for Quick Capture, manual JSON for other plugins).
   - Translation management scripts (`scripts/i18n.py`).
   - QML internationalization conventions.
