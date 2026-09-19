# Media Downloader

A feature-rich media downloader for DankMaterialShell, inspired by Parabolic. Powered by `yt-dlp`.

<img src="screenshot.png" width="400" alt="Screenshot">

## Install

Use the DMS CLI:
```bash
dms plugins install mediaDownloader
```

Or manually:
```bash
git clone https://github.com/hthienloc/dms-media-downloader ~/.config/DankMaterialShell/plugins/mediaDownloader
```

## Features

- **Multi-format Support:** Download video (up to 4K) or extract high-quality audio.
- **Real-time Feedback:** Live progress bars, download speed, and ETA.
- **Pill Integration:** Monitor active downloads directly from the DankBar.
- **Drag & Drop:** Drag links onto the bar icon to start downloading instantly.
- **SponsorBlock:** Automatically remove sponsor segments from YouTube videos.
- **Thumbnail Cropping:** Option to crop embedded thumbnails to a 1:1 square ratio.

## Usage

| Action | Result |
|--------|--------|
| Left click | Open downloader dashboard |
| Right click | Paste link from clipboard and open |
| Drag link | Drop link onto pill to start download |

## Requirements

- `yt-dlp` - The core downloading engine.
- `ffmpeg` - Required for merging video/audio and format conversion.

## Roadmap / TODO

### Phase 1: History & Management
- [x] **History Actions:** Right-click completed items to "Open Folder" or "Play".
- [x] **Batch Clear:** One-click to remove all completed or failed items from history.
- [ ] **Drag-out Support:** Drag completed files from history into other apps.

### Phase 2: Metadata & Polish
- [x] **Native Info Preview:** Show thumbnail and video duration after pasting a link.
- [x] **Metadata Tagging:** Automatically embed thumbnails and tags into audio files.
- [ ] **Playlist Support:** Select specific tracks when a playlist link is detected.

### Phase 3: Advanced Features
- [ ] **Authentication:** Support for cookies and netrc for private/restricted videos.
- [ ] **Notifications:** System alerts when a large download finishes.

## License

GPL-3.0
