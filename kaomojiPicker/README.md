# Kaomoji Picker

Browse and copy kaomoji (Japanese emoticons) directly to your clipboard.

<img src="screenshot.png" width="500" alt="Screenshot">

## Install

Use the DMS CLI:
```bash
dms plugins install kaomojiPicker
```

Or manually:
```bash
git clone https://github.com/hthienloc/dms-kaomoji-picker ~/.config/DankMaterialShell/plugins/kaomojiPicker
```

## Features

- **3000+ kaomoji** - Comprehensive local database
- **Fuzzy search** - Filter by tags like `happy`, `sad`, `angry`, `bear`
- **Native copy** - One click to clipboard

## Usage

| Action | Result |
|--------|--------|
| Type `kj` in launcher | Open kaomoji picker |
| Right-click on kaomoji | Pin / Unpin / Remove from history |

## Requirements

- `wtype` - Simulated Wayland keystrokes for Paste on Select (Optional)

## License

MIT

## Roadmap / TODO

- [ ] **Categorical Navigation:** UI for browsing emoticons by mood/type (e.g., Happy, Sad, Animals, Action) instead of just searching.
- [ ] **Custom Additions:** Ability to save personal/unique emoticons directly from the UI or settings.
- [ ] **Binary Storage/Indexing:** Migrate from large JSON to a faster indexed format (SQLite or similar) for near-instant search response.
- [x] **Favorites & Pinning:** Support for permanent favorites that stay at the top regardless of usage frequency.
- [x] **Direct Injection:** Option to paste the selected kaomoji directly into the active window (utilizes `wtype` / `ydotool` / `xdotool`).

## Translations

<!-- TRANSLATIONS_TABLE_START -->
| Language | Locale | Progress | Coverage | Status |
| :--- | :--- | :---: | :---: | :---: |
| Arabic | `ar` | 19/19 | 100.0% | 🟢 Complete |
| Bulgarian | `bg` | 19/19 | 100.0% | 🟢 Complete |
| German | `de` | 19/19 | 100.0% | 🟢 Complete |
| Esperanto | `eo` | 19/19 | 100.0% | 🟢 Complete |
| Spanish | `es` | 19/19 | 100.0% | 🟢 Complete |
| Persian | `fa` | 19/19 | 100.0% | 🟢 Complete |
| French | `fr` | 19/19 | 100.0% | 🟢 Complete |
| Hebrew | `he` | 19/19 | 100.0% | 🟢 Complete |
| Hungarian | `hu` | 19/19 | 100.0% | 🟢 Complete |
| Italian | `it` | 19/19 | 100.0% | 🟢 Complete |
| Japanese | `ja` | 19/19 | 100.0% | 🟢 Complete |
| Korean | `ko` | 19/19 | 100.0% | 🟢 Complete |
| Dutch | `nl` | 19/19 | 100.0% | 🟢 Complete |
| Polish | `pl` | 19/19 | 100.0% | 🟢 Complete |
| Portuguese | `pt` | 19/19 | 100.0% | 🟢 Complete |
| Russian | `ru` | 19/19 | 100.0% | 🟢 Complete |
| Swedish | `sv` | 19/19 | 100.0% | 🟢 Complete |
| Turkish | `tr` | 19/19 | 100.0% | 🟢 Complete |
| Ukrainian | `uk` | 19/19 | 100.0% | 🟢 Complete |
| Vietnamese | `vi` | 19/19 | 100.0% | 🟢 Complete |
| Chinese (Simplified) | `zh_CN` | 19/19 | 100.0% | 🟢 Complete |
| Chinese (Traditional) | `zh_TW` | 19/19 | 100.0% | 🟢 Complete |
<!-- TRANSLATIONS_TABLE_END -->
