# Lutris Launcher

Browse and launch your Lutris games from the bar.

<img src="screenshot.png" width="400" alt="Screenshot">

## Install

Use the DMS CLI:
```bash
dms plugins install lutrisLauncher
```

Or manually:
```bash
git clone https://github.com/hthienloc/dms-lutris-launcher ~/.config/DankMaterialShell/plugins/lutrisLauncher
```

## Features

- **Game grid** - Visual cover art display
- **Sort & filter** - By name, recently played, most played
- **Favorites & blacklist** - Organize your library
- **Launch stats** - Track play time and last played

## Usage

| Action | Result |
|--------|--------|
| Left click | Launch game |
| Right click | Show stats & hide option |

## Requirements

- `lutris` - Game launcher CLI

## License

GPL-3.0

## Roadmap / TODO

- [ ] **Runner Identification**: Display platform badges (e.g., Wine, Steam, Epic, GOG) on game cards to quickly identify the runner.
- [ ] **SteamGridDB Sync**: Integrate with the SteamGridDB API to automatically fetch missing or high-resolution cover art for your library.
- [ ] **Real-time Status Tracking**: Monitor and display "Now Playing" status on the bar widget when a game process is active.
- [ ] **Quick Process Actions**: Add "Kill Process" and "Open Game Folder" options to the game management menu.
- [ ] **Categorization**: Support user-defined categories/tags to further organize large game libraries beyond simple favorites.
