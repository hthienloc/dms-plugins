# IP Indicator

Display your public IP, ISP, and location.

<img src="screenshot.png" width="300" alt="Screenshot">

## Install

Use the DMS CLI:
```bash
dms plugins install ipIndicator
```

Or manually:
```bash
git clone https://github.com/hthienloc/dms-ipIndicator ~/.config/DankMaterialShell/plugins/ipIndicator
```

## Features

- **IP info at a glance** - Country flag, IP address, and ISP details
- **Privacy mode** - Click the eye button in popout header or middle-click the bar icon to toggle IP visibility
- **Smart VPN Detection** - Automatically detects active VPN/proxy interfaces
- **Latency & Local Details** - Real-time latency monitor and local IP network details


## Usage

| Action | Result |
|--------|--------|
| Left click | Open details popout |
| Middle click | Toggle Privacy Mode |
| Right click | Refresh network status |

## Requirements

- `curl` - HTTP requests to ip-api.com

## License

GPL-3.0