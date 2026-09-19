import QtQuick
import QtQuick.Controls
import Quickshell
import qs.Common
import qs.Widgets
import qs.Modules.Plugins
import "./dms-common"

PluginSettings {
    id: root

    pluginId: "mediaDownloader"



    SettingsCard {
        SectionTitle {
            text: "General Settings"
            icon: "settings"
        }

        StringSettingPlus {
            settingKey: "downloadPathAudio"
            label: "Audio Download Folder"
            defaultValue: Quickshell.env("HOME") + "/Music"
            placeholder: "e.g. " + Quickshell.env("HOME") + "/Music"
            isDirectory: true
        }

        StringSettingPlus {
            settingKey: "downloadPathVideo"
            label: "Video Download Folder"
            defaultValue: Quickshell.env("HOME") + "/Videos"
            placeholder: "e.g. " + Quickshell.env("HOME") + "/Videos"
            isDirectory: true
        }
    }

    SettingsCard {
        SectionTitle {
            text: "Quick Video Defaults"
            icon: "videocam"
        }

        SelectionSettingPlus {
            settingKey: "quickVideoFormat"
            label: "Preferred Format"
            defaultValue: "mp4"
            options: [
                { label: "MP4 (Compatible)", value: "mp4" },
                { label: "WebM (Open Format)", value: "webm" }
            ]
        }

        SelectionSettingPlus {
            settingKey: "quickVideoRes"
            label: "Max Resolution"
            defaultValue: "1080p"
            options: [
                { label: "Best Available Quality", value: "best" },
                { label: "1080p (Full HD)", value: "1080p" },
                { label: "720p (HD)", value: "720p" },
                { label: "480p (SD)", value: "480p" }
            ]
        }
    }

    SettingsCard {
        SectionTitle {
            text: "Quick Audio Defaults"
            icon: "audiotrack"
        }

        SelectionSettingPlus {
            settingKey: "quickAudioFormat"
            label: "Preferred Audio Format"
            defaultValue: "mp3"
            options: [
                { label: "MP3 (Most Compatible)", value: "mp3" },
                { label: "Opus (Low Bitrate efficient)", value: "opus" },
                { label: "FLAC (Lossless)", value: "flac" },
                { label: "WAV (Uncompressed)", value: "wav" }
            ]
        }

        SelectionSettingPlus {
            settingKey: "quickAudioQuality"
            label: "Audio Quality"
            defaultValue: "best"
            options: [
                { label: "Best Available Quality", value: "best" },
                { label: "320 kbps (High Quality)", value: "320k" },
                { label: "192 kbps (Medium Quality)", value: "192k" },
                { label: "128 kbps (Low Quality)", value: "128k" }
            ]
        }
    }

    SettingsCard {
        SectionTitle {
            text: "Advanced Downloader Settings"
            icon: "tune"
        }

        ToggleSettingPlus {
            settingKey: "sponsorBlock"
            label: "Enable SponsorBlock"
            description: "Automatically skip sponsor blocks in YouTube videos."
            defaultValue: true
        }

        ToggleSettingPlus {
            settingKey: "embedThumbnail"
            label: "Embed Thumbnail"
            defaultValue: true
        }

        ToggleSettingPlus {
            settingKey: "cropThumbnail"
            label: "Crop Thumbnail (1:1)"
            description: "Crop the thumbnail to a perfect square before embedding."
            defaultValue: false
            enabled: pluginData.embedThumbnail ?? true
        }

        ToggleSettingPlus {
            settingKey: "embedMetadata"
            label: "Embed Metadata"
            description: "Write metadata tags (title, artist, etc.) to the output file."
            defaultValue: true
        }

        ToggleSettingPlus {
            settingKey: "embedSubs"
            label: "Embed Subtitles"
            defaultValue: false
        }

        ToggleSettingPlus {
            id: limitToggle
            settingKey: "limitRate"
            label: "Limit Download Speed"
            description: "Throttle downloads to prevent network congestion."
            defaultValue: false
        }

        SliderSettingPlus {
            settingKey: "maxRate"
            label: "Max Speed Limit"
            defaultValue: 5000
            minimum: 500
            maximum: 50000
            unit: " KB/s"
            enabled: limitToggle.value
        }
    }

    SettingsCard {
        SectionTitle {
            id: usageTitle
            text: "Usage Guide"
            icon: "menu_book"
            collapsible: true
            settingKey: "usageGuideExpanded"
        }

        UsageGuide {
            expanded: usageTitle.isExpanded
            items: [
                "<b>Left-click</b> the pill to open the downloader popout.",
                "<b>Right-click</b> the pill to paste a URL from your clipboard and open the popout.",
                "<b>Drag and drop</b> links directly onto the pill to paste and open the popout."
            ]
        }
    }

    PluginAbout {
        repoUrl: "https://github.com/hthienloc/dms-media-downloader"
    }
}
