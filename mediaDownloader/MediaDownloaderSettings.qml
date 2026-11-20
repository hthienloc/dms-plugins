import QtQuick
import Quickshell
import qs.Common
import qs.DCommon.Widgets
import qs.Modals.FileBrowser
import qs.Modules.Plugins
import qs.Modules.Settings.Widgets

PluginSettings {
    id: root
    pluginId: "mediaDownloader"

    readonly property string defaultDownloadPathAudio: Quickshell.env("HOME") + "/Music"
    readonly property string defaultDownloadPathVideo: Quickshell.env("HOME") + "/Videos"
    readonly property string defaultQuickVideoFormat: "mp4"
    readonly property string defaultQuickVideoRes: "1080p"
    readonly property string defaultQuickAudioFormat: "mp3"
    readonly property string defaultQuickAudioQuality: "best"
    readonly property bool defaultSponsorBlock: true
    readonly property bool defaultEmbedThumbnail: true
    readonly property bool defaultCropThumbnail: false
    readonly property bool defaultEmbedMetadata: true
    readonly property bool defaultEmbedSubs: false
    readonly property bool defaultLimitRate: false
    readonly property int defaultMaxRate: 5000

    property string downloadPathAudio: defaultDownloadPathAudio
    property string downloadPathVideo: defaultDownloadPathVideo
    property string quickVideoFormat: defaultQuickVideoFormat
    property string quickVideoRes: defaultQuickVideoRes
    property string quickAudioFormat: defaultQuickAudioFormat
    property string quickAudioQuality: defaultQuickAudioQuality
    property bool sponsorBlock: defaultSponsorBlock
    property bool embedThumbnail: defaultEmbedThumbnail
    property bool cropThumbnail: defaultCropThumbnail
    property bool embedMetadata: defaultEmbedMetadata
    property bool embedSubs: defaultEmbedSubs
    property bool limitRate: defaultLimitRate
    property int maxRate: defaultMaxRate

    function cleanPath(path) {
        if (!path)
            return "";
        return String(path).replace(/^file:\/\//, "");
    }

    function loadSettings() {
        if (!pluginService)
            return;
        downloadPathAudio = loadValue("downloadPathAudio", defaultDownloadPathAudio);
        downloadPathVideo = loadValue("downloadPathVideo", defaultDownloadPathVideo);
        quickVideoFormat = loadValue("quickVideoFormat", defaultQuickVideoFormat);
        quickVideoRes = loadValue("quickVideoRes", defaultQuickVideoRes);
        quickAudioFormat = loadValue("quickAudioFormat", defaultQuickAudioFormat);
        quickAudioQuality = loadValue("quickAudioQuality", defaultQuickAudioQuality);
        sponsorBlock = loadValue("sponsorBlock", defaultSponsorBlock);
        embedThumbnail = loadValue("embedThumbnail", defaultEmbedThumbnail);
        cropThumbnail = loadValue("cropThumbnail", defaultCropThumbnail);
        embedMetadata = loadValue("embedMetadata", defaultEmbedMetadata);
        embedSubs = loadValue("embedSubs", defaultEmbedSubs);
        limitRate = loadValue("limitRate", defaultLimitRate);
        maxRate = loadValue("maxRate", defaultMaxRate);
        usageSection.expanded = loadValue("usageGuideExpanded", true);
    }

    Component.onCompleted: loadSettings()
    onPluginServiceChanged: loadSettings()

    Column {
        width: parent ? parent.width : 0
        spacing: 0

        SettingsSectionLabel {
            width: parent.width
            text: I18n.trFor("mediaDownloader", "Download Folders")
        }

        SettingsGroup {
            width: parent.width
            slotColor: SettingsMetrics.controlColor

            SettingsTextFieldRow {
                id: audioPathField
                text: I18n.trFor("mediaDownloader", "Audio Download Folder")
                placeholderText: I18n.trFor("mediaDownloader", "e.g. %1").arg(Quickshell.env("HOME") + "/Music")
                value: root.downloadPathAudio
                modified: root.downloadPathAudio !== root.defaultDownloadPathAudio
                resetByKeys: false
                onResetRequested: {
                    root.downloadPathAudio = root.defaultDownloadPathAudio;
                    audioPathField.value = root.defaultDownloadPathAudio;
                    root.saveValue("downloadPathAudio", root.defaultDownloadPathAudio);
                }
                onValueEdited: newValue => {
                    root.downloadPathAudio = newValue;
                    root.saveValue("downloadPathAudio", newValue);
                }
                actions: DActionButton {
                    iconName: "folder_open"
                    backgroundColor: Theme.surfaceContainerHigh
                    iconColor: Theme.primary
                    tooltipText: I18n.trFor("mediaDownloader", "Select Directory")
                    onClicked: audioBrowserModal.open()
                }
            }

            SettingsTextFieldRow {
                id: videoPathField
                text: I18n.trFor("mediaDownloader", "Video Download Folder")
                placeholderText: I18n.trFor("mediaDownloader", "e.g. %1").arg(Quickshell.env("HOME") + "/Videos")
                value: root.downloadPathVideo
                modified: root.downloadPathVideo !== root.defaultDownloadPathVideo
                resetByKeys: false
                onResetRequested: {
                    root.downloadPathVideo = root.defaultDownloadPathVideo;
                    videoPathField.value = root.defaultDownloadPathVideo;
                    root.saveValue("downloadPathVideo", root.defaultDownloadPathVideo);
                }
                onValueEdited: newValue => {
                    root.downloadPathVideo = newValue;
                    root.saveValue("downloadPathVideo", newValue);
                }
                actions: DActionButton {
                    iconName: "folder_open"
                    backgroundColor: Theme.surfaceContainerHigh
                    iconColor: Theme.primary
                    tooltipText: I18n.trFor("mediaDownloader", "Select Directory")
                    onClicked: videoBrowserModal.open()
                }
            }
        }
    }

    Column {
        width: parent ? parent.width : 0
        spacing: 0

        SettingsSectionLabel {
            width: parent.width
            text: I18n.trFor("mediaDownloader", "Video Defaults")
        }

        SettingsGroup {
            width: parent.width
            slotColor: SettingsMetrics.controlColor

            SettingsDropdownRow {
                text: I18n.trFor("mediaDownloader", "Preferred Format")
                options: [
                    I18n.trFor("mediaDownloader", "MP4 (Compatible)"),
                    I18n.trFor("mediaDownloader", "WebM (Open Format)")
                ]
                optionValues: ["mp4", "webm"]
                currentValue: root.quickVideoFormat
                modified: root.quickVideoFormat !== root.defaultQuickVideoFormat
                resetByKeys: false
                onResetRequested: {
                    root.quickVideoFormat = root.defaultQuickVideoFormat;
                    root.saveValue("quickVideoFormat", root.defaultQuickVideoFormat);
                }
                onValueChanged: val => {
                    root.quickVideoFormat = val;
                    root.saveValue("quickVideoFormat", val);
                }
            }

            SettingsDropdownRow {
                text: I18n.trFor("mediaDownloader", "Max Resolution")
                options: [
                    I18n.trFor("mediaDownloader", "Best Available Quality"),
                    I18n.trFor("mediaDownloader", "1080p (Full HD)"),
                    I18n.trFor("mediaDownloader", "720p (HD)"),
                    I18n.trFor("mediaDownloader", "480p (SD)")
                ]
                optionValues: ["best", "1080p", "720p", "480p"]
                currentValue: root.quickVideoRes
                modified: root.quickVideoRes !== root.defaultQuickVideoRes
                resetByKeys: false
                onResetRequested: {
                    root.quickVideoRes = root.defaultQuickVideoRes;
                    root.saveValue("quickVideoRes", root.defaultQuickVideoRes);
                }
                onValueChanged: val => {
                    root.quickVideoRes = val;
                    root.saveValue("quickVideoRes", val);
                }
            }
        }
    }

    Column {
        width: parent ? parent.width : 0
        spacing: 0

        SettingsSectionLabel {
            width: parent.width
            text: I18n.trFor("mediaDownloader", "Audio Defaults")
        }

        SettingsGroup {
            width: parent.width
            slotColor: SettingsMetrics.controlColor

            SettingsDropdownRow {
                text: I18n.trFor("mediaDownloader", "Preferred Audio Format")
                options: [
                    I18n.trFor("mediaDownloader", "MP3 (Most Compatible)"),
                    I18n.trFor("mediaDownloader", "Opus (Low Bitrate efficient)"),
                    I18n.trFor("mediaDownloader", "FLAC (Lossless)"),
                    I18n.trFor("mediaDownloader", "WAV (Uncompressed)")
                ]
                optionValues: ["mp3", "opus", "flac", "wav"]
                currentValue: root.quickAudioFormat
                modified: root.quickAudioFormat !== root.defaultQuickAudioFormat
                resetByKeys: false
                onResetRequested: {
                    root.quickAudioFormat = root.defaultQuickAudioFormat;
                    root.saveValue("quickAudioFormat", root.defaultQuickAudioFormat);
                }
                onValueChanged: val => {
                    root.quickAudioFormat = val;
                    root.saveValue("quickAudioFormat", val);
                }
            }

            SettingsDropdownRow {
                text: I18n.trFor("mediaDownloader", "Audio Quality")
                options: [
                    I18n.trFor("mediaDownloader", "Best Available Quality"),
                    I18n.trFor("mediaDownloader", "320 kbps (High Quality)"),
                    I18n.trFor("mediaDownloader", "192 kbps (Medium Quality)"),
                    I18n.trFor("mediaDownloader", "128 kbps (Low Quality)")
                ]
                optionValues: ["best", "320k", "192k", "128k"]
                currentValue: root.quickAudioQuality
                modified: root.quickAudioQuality !== root.defaultQuickAudioQuality
                resetByKeys: false
                onResetRequested: {
                    root.quickAudioQuality = root.defaultQuickAudioQuality;
                    root.saveValue("quickAudioQuality", root.defaultQuickAudioQuality);
                }
                onValueChanged: val => {
                    root.quickAudioQuality = val;
                    root.saveValue("quickAudioQuality", val);
                }
            }
        }
    }

    Column {
        width: parent ? parent.width : 0
        spacing: 0

        SettingsSectionLabel {
            width: parent.width
            text: I18n.trFor("mediaDownloader", "Advanced")
        }

        SettingsGroup {
            width: parent.width
            slotColor: SettingsMetrics.controlColor

            SettingsToggleRow {
                text: I18n.trFor("mediaDownloader", "Enable SponsorBlock")
                description: I18n.trFor("mediaDownloader", "Automatically skip sponsor blocks in YouTube videos.")
                checked: root.sponsorBlock
                modified: root.sponsorBlock !== root.defaultSponsorBlock
                resetByKeys: false
                onResetRequested: {
                    root.sponsorBlock = root.defaultSponsorBlock;
                    root.saveValue("sponsorBlock", root.defaultSponsorBlock);
                }
                onToggled: isChecked => {
                    root.sponsorBlock = isChecked;
                    root.saveValue("sponsorBlock", isChecked);
                }
            }

            SettingsToggleRow {
                text: I18n.trFor("mediaDownloader", "Embed Thumbnail")
                checked: root.embedThumbnail
                modified: root.embedThumbnail !== root.defaultEmbedThumbnail
                resetByKeys: false
                onResetRequested: {
                    root.embedThumbnail = root.defaultEmbedThumbnail;
                    root.saveValue("embedThumbnail", root.defaultEmbedThumbnail);
                }
                onToggled: isChecked => {
                    root.embedThumbnail = isChecked;
                    root.saveValue("embedThumbnail", isChecked);
                }
            }

            SettingsToggleRow {
                text: I18n.trFor("mediaDownloader", "Crop Thumbnail (1:1)")
                description: I18n.trFor("mediaDownloader", "Crop the thumbnail to a perfect square before embedding.")
                checked: root.cropThumbnail
                enabled: root.embedThumbnail
                modified: root.cropThumbnail !== root.defaultCropThumbnail
                resetByKeys: false
                onResetRequested: {
                    root.cropThumbnail = root.defaultCropThumbnail;
                    root.saveValue("cropThumbnail", root.defaultCropThumbnail);
                }
                onToggled: isChecked => {
                    root.cropThumbnail = isChecked;
                    root.saveValue("cropThumbnail", isChecked);
                }
            }

            SettingsToggleRow {
                text: I18n.trFor("mediaDownloader", "Embed Metadata")
                description: I18n.trFor("mediaDownloader", "Write metadata tags (title, artist, etc.) to the output file.")
                checked: root.embedMetadata
                modified: root.embedMetadata !== root.defaultEmbedMetadata
                resetByKeys: false
                onResetRequested: {
                    root.embedMetadata = root.defaultEmbedMetadata;
                    root.saveValue("embedMetadata", root.defaultEmbedMetadata);
                }
                onToggled: isChecked => {
                    root.embedMetadata = isChecked;
                    root.saveValue("embedMetadata", isChecked);
                }
            }

            SettingsToggleRow {
                text: I18n.trFor("mediaDownloader", "Embed Subtitles")
                checked: root.embedSubs
                modified: root.embedSubs !== root.defaultEmbedSubs
                resetByKeys: false
                onResetRequested: {
                    root.embedSubs = root.defaultEmbedSubs;
                    root.saveValue("embedSubs", root.defaultEmbedSubs);
                }
                onToggled: isChecked => {
                    root.embedSubs = isChecked;
                    root.saveValue("embedSubs", isChecked);
                }
            }

            SettingsToggleRow {
                text: I18n.trFor("mediaDownloader", "Limit Download Speed")
                description: I18n.trFor("mediaDownloader", "Throttle downloads to prevent network congestion.")
                checked: root.limitRate
                modified: root.limitRate !== root.defaultLimitRate
                resetByKeys: false
                onResetRequested: {
                    root.limitRate = root.defaultLimitRate;
                    root.saveValue("limitRate", root.defaultLimitRate);
                }
                onToggled: isChecked => {
                    root.limitRate = isChecked;
                    root.saveValue("limitRate", isChecked);
                }
            }

            SettingsSliderRow {
                text: I18n.trFor("mediaDownloader", "Max Speed Limit")
                minimum: 500
                maximum: 50000
                step: 100
                unit: I18n.trFor("mediaDownloader", " KB/s")
                value: root.maxRate
                enabled: root.limitRate
                modified: root.maxRate !== root.defaultMaxRate
                resetByKeys: false
                onResetRequested: {
                    root.maxRate = root.defaultMaxRate;
                    root.saveValue("maxRate", root.defaultMaxRate);
                }
                onSliderDragFinished: finalValue => {
                    root.maxRate = finalValue;
                    root.saveValue("maxRate", finalValue);
                }
            }
        }
    }

    Column {
        id: usageSection
        width: parent ? parent.width : 0
        spacing: 0

        property bool expanded: true

        SettingsSectionLabel {
            width: parent.width
            text: I18n.trFor("mediaDownloader", "How to Use")
            collapsible: true
            expanded: usageSection.expanded
            onToggleRequested: {
                usageSection.expanded = !usageSection.expanded;
                if (root.pluginService)
                    root.saveValue("usageGuideExpanded", usageSection.expanded);
            }
        }

        SettingsGroup {
            width: parent.width
            slotColor: SettingsMetrics.controlColor
            visible: usageSection.expanded

            Column {
                width: parent.width
                spacing: Theme.spacingS

                Repeater {
                    model: [
                        I18n.trFor("mediaDownloader", "<b>Left-click</b> the pill to open the downloader popout."),
                        I18n.trFor("mediaDownloader", "<b>Right-click</b> the pill to paste a URL from your clipboard and open the popout."),
                        I18n.trFor("mediaDownloader", "<b>Drag and drop</b> links directly onto the pill to paste and open the popout.")
                    ]

                    delegate: Row {
                        required property string modelData
                        width: parent.width
                        spacing: Theme.spacingS

                        StyledText {
                            id: bullet
                            text: "•"
                            color: Theme.primary
                            font.pixelSize: Theme.fontSizeSmall
                            font.weight: Font.Bold
                        }

                        StyledText {
                            width: parent.width - bullet.width - parent.spacing
                            text: modelData
                            color: Theme.surfaceVariantText
                            font.pixelSize: Theme.fontSizeSmall
                            wrapMode: Text.WordWrap
                            textFormat: Text.StyledText
                        }
                    }
                }
            }
        }
    }

    FileBrowserSurfaceModal {
        id: audioBrowserModal
        browserTitle: I18n.trFor("mediaDownloader", "Audio Download Folder")
        browserType: "folder_picker"
        folderMode: true
        saveMode: false
        revealPath: root.downloadPathAudio !== "" ? root.downloadPathAudio : ""
        onAccepted: paths => {
            if (paths && paths.length > 0) {
                const cleaned = root.cleanPath(paths[0]);
                root.downloadPathAudio = cleaned;
                audioPathField.value = cleaned;
                root.saveValue("downloadPathAudio", cleaned);
            }
        }
    }

    FileBrowserSurfaceModal {
        id: videoBrowserModal
        browserTitle: I18n.trFor("mediaDownloader", "Video Download Folder")
        browserType: "folder_picker"
        folderMode: true
        saveMode: false
        revealPath: root.downloadPathVideo !== "" ? root.downloadPathVideo : ""
        onAccepted: paths => {
            if (paths && paths.length > 0) {
                const cleaned = root.cleanPath(paths[0]);
                root.downloadPathVideo = cleaned;
                videoPathField.value = cleaned;
                root.saveValue("downloadPathVideo", cleaned);
            }
        }
    }
}
