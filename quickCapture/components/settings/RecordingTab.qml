import QtQuick
import qs.Common
import qs.DCommon.Widgets
import qs.Modals.FileBrowser
import qs.Modules.Settings.Widgets
import "../core" as Core
import "../core/Defaults.js" as Defaults

Column {
    id: root

    property QtObject config: null
    property var settings: null
    property var daemon: null

    width: parent ? parent.width : 0
    spacing: Theme.spacingM

    property string recordingDirectory: Core.CapturePaths.defaultRecordingDirectory
    property string recordingBackend: Defaults.values.recordingBackend
    property string recordingScreenTarget: Defaults.values.recordingScreenTarget
    property string recordingFormat: Defaults.values.recordingFormat
    property string recordingGifFramerate: String(Defaults.values.recordingGifFramerate)
    property string recordingFramerate: String(Defaults.values.recordingFramerate)
    property string recordingQuality: Defaults.values.recordingQuality
    property string recordingCodec: Defaults.values.recordingCodec
    property bool recordCursor: Defaults.values.recordCursor
    property bool recordingSkipConfirm: Defaults.values.recordingSkipConfirm

    property bool recordSystemAudio: Defaults.values.recordSystemAudio
    property string systemAudioDevice: Defaults.values.systemAudioDevice
    property bool recordMic: Defaults.values.recordMic
    property string micDevice: Defaults.values.micDevice
    property string audioCodec: Defaults.values.audioCodec
    property string recordingStatusLocation: Defaults.values.recordingStatusLocation
    property bool showPillBorder: Defaults.values.showPillBorder
    property bool showRecordingDot: Defaults.values.showRecordingDot
    property bool blinkRecordDot: Defaults.values.blinkRecordDot
    property bool showRecordingTimer: Defaults.values.showRecordingTimer
    property bool showRecordingControls: Defaults.values.showRecordingControls
    property bool showRegionBorder: Defaults.values.showRegionBorder

    readonly property bool gpuBackend: recordingBackend !== "wf-recorder"
    readonly property var fallbackInputs: [
        {
            label: I18n.trFor("quickCapture", "Default Microphone"),
            value: "default_input"
        }
    ]
    readonly property var fallbackOutputs: [
        {
            label: I18n.trFor("quickCapture", "Default Output"),
            value: "default_output"
        }
    ]
    readonly property var screenTargetOptions: root.config ? root.config.screenOptions([
        {
            label: I18n.trFor("quickCapture", "Primary Screen"),
            value: "screen"
        },
        {
            label: I18n.trFor("quickCapture", "Focused Screen"),
            value: "focused"
        }
    ]) : [
        {
            label: I18n.trFor("quickCapture", "Primary Screen"),
            value: "screen"
        },
        {
            label: I18n.trFor("quickCapture", "Focused Screen"),
            value: "focused"
        }
    ]
    readonly property var outputDeviceOptions: (root.daemon && root.daemon.audioOutputsList) ? root.daemon.audioOutputsList : root.fallbackOutputs
    readonly property var inputDeviceOptions: (root.daemon && root.daemon.audioInputsList) ? root.daemon.audioInputsList : root.fallbackInputs

    function cleanPath(url) {
        let path = url.toString();
        if (path.startsWith("file://"))
            path = path.substring(7);
        if (path.length > 1 && path.endsWith("/"))
            path = path.substring(0, path.length - 1);
        return path;
    }

    function loadValue() {
        if (!settings)
            return;
        recordingDirectory = settings.loadValue("recordingDirectory", Core.CapturePaths.defaultRecordingDirectory);
        recordingBackend = settings.loadValue("recordingBackend", Defaults.values.recordingBackend);
        recordingScreenTarget = settings.loadValue("recordingScreenTarget", Defaults.values.recordingScreenTarget);
        recordingFormat = settings.loadValue("recordingFormat", Defaults.values.recordingFormat);
        recordingGifFramerate = String(settings.loadValue("recordingGifFramerate", Defaults.values.recordingGifFramerate));
        recordingFramerate = String(settings.loadValue("recordingFramerate", Defaults.values.recordingFramerate));
        recordingQuality = settings.loadValue("recordingQuality", Defaults.values.recordingQuality);
        recordingCodec = settings.loadValue("recordingCodec", Defaults.values.recordingCodec);
        recordCursor = settings.loadValue("recordCursor", Defaults.values.recordCursor);
        recordingSkipConfirm = settings.loadValue("recordingSkipConfirm", Defaults.values.recordingSkipConfirm);

        recordSystemAudio = settings.loadValue("recordSystemAudio", Defaults.values.recordSystemAudio);
        systemAudioDevice = settings.loadValue("systemAudioDevice", Defaults.values.systemAudioDevice);
        recordMic = settings.loadValue("recordMic", Defaults.values.recordMic);
        micDevice = settings.loadValue("micDevice", Defaults.values.micDevice);
        audioCodec = settings.loadValue("audioCodec", Defaults.values.audioCodec);
        recordingStatusLocation = settings.loadValue("recordingStatusLocation", Defaults.values.recordingStatusLocation);
        showPillBorder = settings.loadValue("showPillBorder", Defaults.values.showPillBorder);
        showRecordingDot = settings.loadValue("showRecordingDot", Defaults.values.showRecordingDot);
        blinkRecordDot = settings.loadValue("blinkRecordDot", Defaults.values.blinkRecordDot);
        showRecordingTimer = settings.loadValue("showRecordingTimer", Defaults.values.showRecordingTimer);
        showRecordingControls = settings.loadValue("showRecordingControls", Defaults.values.showRecordingControls);
        showRegionBorder = settings.loadValue("showRegionBorder", Defaults.values.showRegionBorder);
    }

    function save(key, val) {
        if (settings)
            settings.saveValue(key, val);
    }

    onSettingsChanged: loadValue()
    Component.onCompleted: {
        loadValue();
        if (daemon)
            daemon.refreshAudioDevices();
    }

    Column {
        width: parent.width
        spacing: 0

        SettingsSectionLabel {
            width: parent.width
            text: I18n.trFor("quickCapture", "Video")
        }

        SettingsGroup {
            width: parent.width
            slotColor: SettingsMetrics.controlColor

            SettingsTextFieldRow {
                id: recordingDirectoryField
                text: I18n.trFor("quickCapture", "Recording Folder")
                placeholderText: Core.CapturePaths.defaultRecordingDirectory
                value: root.recordingDirectory
                modified: root.recordingDirectory !== Core.CapturePaths.defaultRecordingDirectory
                onResetRequested: {
                    root.recordingDirectory = Core.CapturePaths.defaultRecordingDirectory;
                    recordingDirectoryField.value = Core.CapturePaths.defaultRecordingDirectory;
                    root.save("recordingDirectory", Core.CapturePaths.defaultRecordingDirectory);
                }
                onValueEdited: val => {
                    root.recordingDirectory = val;
                    root.save("recordingDirectory", val);
                }
                actions: DActionButton {
                    iconName: "folder_open"
                    tooltipText: I18n.trFor("quickCapture", "Browse")
                    onClicked: recordingDirBrowser.open()
                }
            }

            SettingsDropdownRow {
                text: I18n.trFor("quickCapture", "Recording Backend")
                description: I18n.trFor("quickCapture", "Select screen recording backend. Auto attempts GPU first and falls back to CPU (%1). Note: %1 does not support pausing.").arg("wf-recorder")
                options: [
                    I18n.trFor("quickCapture", "Auto"),
                    "GPU Screen Recorder (NVENC / VA-API)",
                    "GPU Screen Recorder (Flatpak)",
                    "wf-recorder (CPU libx264 - no pause)"
                ]
                optionValues: ["auto", "gpu-screen-recorder", "gpu-screen-recorder-flatpak", "wf-recorder"]
                currentValue: root.recordingBackend
                modified: root.recordingBackend !== Defaults.values.recordingBackend
                resetByKeys: false
                onResetRequested: {
                    root.recordingBackend = Defaults.values.recordingBackend;
                    root.save("recordingBackend", Defaults.values.recordingBackend);
                }
                onValueChanged: val => {
                    root.recordingBackend = val;
                    root.save("recordingBackend", val);
                }
            }

            SettingsDropdownRow {
                text: I18n.trFor("quickCapture", "Fullscreen Target")
                description: I18n.trFor("quickCapture", "Choose which monitor to capture during full screen recording.")
                options: root.screenTargetOptions.map(o => o.label)
                optionValues: root.screenTargetOptions.map(o => o.value)
                currentValue: root.recordingScreenTarget
                modified: root.recordingScreenTarget !== Defaults.values.recordingScreenTarget
                resetByKeys: false
                onResetRequested: {
                    root.recordingScreenTarget = Defaults.values.recordingScreenTarget;
                    root.save("recordingScreenTarget", Defaults.values.recordingScreenTarget);
                }
                onValueChanged: val => {
                    root.recordingScreenTarget = val;
                    root.save("recordingScreenTarget", val);
                }
            }

            SettingsDropdownRow {
                text: I18n.trFor("quickCapture", "Container Format")
                options: ["MP4", "MKV", "WebM", "FLV", "GIF"]
                optionValues: ["mp4", "mkv", "webm", "flv", "gif"]
                currentValue: root.recordingFormat
                modified: root.recordingFormat !== Defaults.values.recordingFormat
                resetByKeys: false
                onResetRequested: {
                    root.recordingFormat = Defaults.values.recordingFormat;
                    root.save("recordingFormat", Defaults.values.recordingFormat);
                }
                onValueChanged: val => {
                    root.recordingFormat = val;
                    root.save("recordingFormat", val);
                }
            }

            SettingsDropdownRow {
                visible: root.recordingFormat === "gif"
                text: I18n.trFor("quickCapture", "GIF Framerate")
                options: ["10 FPS", "15 FPS", "24 FPS", "30 FPS"]
                optionValues: ["10", "15", "24", "30"]
                currentValue: root.recordingGifFramerate
                modified: root.recordingGifFramerate !== String(Defaults.values.recordingGifFramerate)
                resetByKeys: false
                onResetRequested: {
                    root.recordingGifFramerate = String(Defaults.values.recordingGifFramerate);
                    root.save("recordingGifFramerate", Defaults.values.recordingGifFramerate);
                }
                onValueChanged: val => {
                    root.recordingGifFramerate = val;
                    root.save("recordingGifFramerate", val);
                }
            }

            SettingsButtonGroupRow {
                text: I18n.trFor("quickCapture", "Framerate")
                model: ["30 FPS", "60 FPS", "120 FPS"]
                values: ["30", "60", "120"]
                value: root.recordingFramerate
                modified: root.recordingFramerate !== String(Defaults.values.recordingFramerate)
                resetByKeys: false
                onResetRequested: {
                    root.recordingFramerate = String(Defaults.values.recordingFramerate);
                    root.save("recordingFramerate", Defaults.values.recordingFramerate);
                }
                onValueSelected: val => {
                    root.recordingFramerate = val;
                    root.save("recordingFramerate", val);
                }
            }

            SettingsDropdownRow {
                text: I18n.trFor("quickCapture", "Quality")
                options: [
                    I18n.trFor("quickCapture", "Very High"),
                    I18n.trFor("quickCapture", "High"),
                    I18n.trFor("quickCapture", "Medium"),
                    I18n.trFor("quickCapture", "Low")
                ]
                optionValues: ["very_high", "high", "medium", "low"]
                currentValue: root.recordingQuality
                modified: root.recordingQuality !== Defaults.values.recordingQuality
                resetByKeys: false
                onResetRequested: {
                    root.recordingQuality = Defaults.values.recordingQuality;
                    root.save("recordingQuality", Defaults.values.recordingQuality);
                }
                onValueChanged: val => {
                    root.recordingQuality = val;
                    root.save("recordingQuality", val);
                }
            }

            SettingsDropdownRow {
                text: I18n.trFor("quickCapture", "Video Codec")
                options: [
                    I18n.trFor("quickCapture", "Auto"),
                    "H.264",
                    "HEVC (H.265)",
                    "AV1",
                    "VP8",
                    "VP9"
                ]
                optionValues: ["auto", "h264", "hevc", "av1", "vp8", "vp9"]
                currentValue: root.recordingCodec
                modified: root.recordingCodec !== Defaults.values.recordingCodec
                resetByKeys: false
                onResetRequested: {
                    root.recordingCodec = Defaults.values.recordingCodec;
                    root.save("recordingCodec", Defaults.values.recordingCodec);
                }
                onValueChanged: val => {
                    root.recordingCodec = val;
                    root.save("recordingCodec", val);
                }
            }

            SettingsToggleRow {
                text: I18n.trFor("quickCapture", "Include Cursor")
                checked: root.recordCursor
                modified: root.recordCursor !== Defaults.values.recordCursor
                resetByKeys: false
                onResetRequested: {
                    root.recordCursor = Defaults.values.recordCursor;
                    root.save("recordCursor", Defaults.values.recordCursor);
                }
                onToggled: isChecked => {
                    root.recordCursor = isChecked;
                    root.save("recordCursor", isChecked);
                }
            }

            SettingsToggleRow {
                text: I18n.trFor("quickCapture", "Skip confirmation")
                checked: root.recordingSkipConfirm
                modified: root.recordingSkipConfirm !== Defaults.values.recordingSkipConfirm
                resetByKeys: false
                onResetRequested: {
                    root.recordingSkipConfirm = Defaults.values.recordingSkipConfirm;
                    root.save("recordingSkipConfirm", Defaults.values.recordingSkipConfirm);
                }
                onToggled: isChecked => {
                    root.recordingSkipConfirm = isChecked;
                    root.save("recordingSkipConfirm", isChecked);
                }
            }
        }
    }

    Column {
        width: parent.width
        spacing: 0

        SettingsSectionLabel {
            width: parent.width
            text: I18n.trFor("quickCapture", "Recording Overlay")
        }

        SettingsGroup {
            width: parent.width
            slotColor: SettingsMetrics.controlColor

            SettingsNoteRow {
                visible: !root.gpuBackend
                noteIconName: "info"
                tint: Theme.primary
                tintBackground: Theme.withAlpha(Theme.primary, 0.08)
                text: I18n.trFor("quickCapture", "Audio recording is disabled when using the %1 backend.").arg("wf-recorder (CPU)")
            }

            SettingsToggleRow {
                visible: root.gpuBackend
                text: I18n.trFor("quickCapture", "Record System Audio")
                checked: root.recordSystemAudio
                modified: root.recordSystemAudio !== Defaults.values.recordSystemAudio
                resetByKeys: false
                onResetRequested: {
                    root.recordSystemAudio = Defaults.values.recordSystemAudio;
                    root.save("recordSystemAudio", Defaults.values.recordSystemAudio);
                }
                onToggled: isChecked => {
                    root.recordSystemAudio = isChecked;
                    root.save("recordSystemAudio", isChecked);
                }
            }

            SettingsDropdownRow {
                visible: root.gpuBackend && root.recordSystemAudio
                text: I18n.trFor("quickCapture", "System Audio Device")
                options: root.outputDeviceOptions.map(o => o.label)
                optionValues: root.outputDeviceOptions.map(o => o.value)
                currentValue: root.systemAudioDevice
                modified: root.systemAudioDevice !== Defaults.values.systemAudioDevice
                resetByKeys: false
                onResetRequested: {
                    root.systemAudioDevice = Defaults.values.systemAudioDevice;
                    root.save("systemAudioDevice", Defaults.values.systemAudioDevice);
                }
                onValueChanged: val => {
                    root.systemAudioDevice = val;
                    root.save("systemAudioDevice", val);
                }
            }

            SettingsToggleRow {
                visible: root.gpuBackend
                text: I18n.trFor("quickCapture", "Record Microphone")
                checked: root.recordMic
                modified: root.recordMic !== Defaults.values.recordMic
                resetByKeys: false
                onResetRequested: {
                    root.recordMic = Defaults.values.recordMic;
                    root.save("recordMic", Defaults.values.recordMic);
                }
                onToggled: isChecked => {
                    root.recordMic = isChecked;
                    root.save("recordMic", isChecked);
                }
            }

            SettingsDropdownRow {
                visible: root.gpuBackend && root.recordMic
                text: I18n.trFor("quickCapture", "Microphone Device")
                options: root.inputDeviceOptions.map(o => o.label)
                optionValues: root.inputDeviceOptions.map(o => o.value)
                currentValue: root.micDevice
                modified: root.micDevice !== Defaults.values.micDevice
                resetByKeys: false
                onResetRequested: {
                    root.micDevice = Defaults.values.micDevice;
                    root.save("micDevice", Defaults.values.micDevice);
                }
                onValueChanged: val => {
                    root.micDevice = val;
                    root.save("micDevice", val);
                }
            }

            SettingsButtonGroupRow {
                visible: root.gpuBackend
                text: I18n.trFor("quickCapture", "Audio Codec")
                model: ["Opus", "AAC", "FLAC"]
                values: ["opus", "aac", "flac"]
                value: root.audioCodec
                modified: root.audioCodec !== Defaults.values.audioCodec
                resetByKeys: false
                onResetRequested: {
                    root.audioCodec = Defaults.values.audioCodec;
                    root.save("audioCodec", Defaults.values.audioCodec);
                }
                onValueSelected: val => {
                    root.audioCodec = val;
                    root.save("audioCodec", val);
                }
            }

            SettingsDropdownRow {
                text: I18n.trFor("quickCapture", "Recording Status Location")
                description: I18n.trFor("quickCapture", "Choose where the recording status and controls appear: Auto (DankBar if present, otherwise Floating Pill), DankBar, Floating Pill, or Both.")
                options: [
                    I18n.trFor("quickCapture", "Auto"),
                    I18n.trFor("quickCapture", "DankBar"),
                    I18n.trFor("quickCapture", "Floating Pill"),
                    I18n.trFor("quickCapture", "Both")
                ]
                optionValues: ["auto", "bar", "floating", "both"]
                currentValue: root.recordingStatusLocation
                modified: root.recordingStatusLocation !== Defaults.values.recordingStatusLocation
                resetByKeys: false
                onResetRequested: {
                    root.recordingStatusLocation = Defaults.values.recordingStatusLocation;
                    root.save("recordingStatusLocation", Defaults.values.recordingStatusLocation);
                }
                onValueChanged: val => {
                    root.recordingStatusLocation = val;
                    root.save("recordingStatusLocation", val);
                }
            }

            SettingsToggleRow {
                visible: root.recordingStatusLocation !== "bar"
                text: I18n.trFor("quickCapture", "Show Pill Border")
                checked: root.showPillBorder
                modified: root.showPillBorder !== Defaults.values.showPillBorder
                resetByKeys: false
                onResetRequested: {
                    root.showPillBorder = Defaults.values.showPillBorder;
                    root.save("showPillBorder", Defaults.values.showPillBorder);
                }
                onToggled: isChecked => {
                    root.showPillBorder = isChecked;
                    root.save("showPillBorder", isChecked);
                }
            }

            SettingsToggleRow {
                text: I18n.trFor("quickCapture", "Show Recording Dot")
                checked: root.showRecordingDot
                modified: root.showRecordingDot !== Defaults.values.showRecordingDot
                resetByKeys: false
                onResetRequested: {
                    root.showRecordingDot = Defaults.values.showRecordingDot;
                    root.save("showRecordingDot", Defaults.values.showRecordingDot);
                }
                onToggled: isChecked => {
                    root.showRecordingDot = isChecked;
                    root.save("showRecordingDot", isChecked);
                }
            }

            SettingsToggleRow {
                visible: root.showRecordingDot
                text: I18n.trFor("quickCapture", "Blink Recording Dot")
                checked: root.blinkRecordDot
                modified: root.blinkRecordDot !== Defaults.values.blinkRecordDot
                resetByKeys: false
                onResetRequested: {
                    root.blinkRecordDot = Defaults.values.blinkRecordDot;
                    root.save("blinkRecordDot", Defaults.values.blinkRecordDot);
                }
                onToggled: isChecked => {
                    root.blinkRecordDot = isChecked;
                    root.save("blinkRecordDot", isChecked);
                }
            }

            SettingsToggleRow {
                text: I18n.trFor("quickCapture", "Show Recording Timer")
                checked: root.showRecordingTimer
                modified: root.showRecordingTimer !== Defaults.values.showRecordingTimer
                resetByKeys: false
                onResetRequested: {
                    root.showRecordingTimer = Defaults.values.showRecordingTimer;
                    root.save("showRecordingTimer", Defaults.values.showRecordingTimer);
                }
                onToggled: isChecked => {
                    root.showRecordingTimer = isChecked;
                    root.save("showRecordingTimer", isChecked);
                }
            }

            SettingsToggleRow {
                text: I18n.trFor("quickCapture", "Show Recording Controls")
                checked: root.showRecordingControls
                modified: root.showRecordingControls !== Defaults.values.showRecordingControls
                resetByKeys: false
                onResetRequested: {
                    root.showRecordingControls = Defaults.values.showRecordingControls;
                    root.save("showRecordingControls", Defaults.values.showRecordingControls);
                }
                onToggled: isChecked => {
                    root.showRecordingControls = isChecked;
                    root.save("showRecordingControls", isChecked);
                }
            }

            SettingsToggleRow {
                text: I18n.trFor("quickCapture", "Show Region Border")
                checked: root.showRegionBorder
                modified: root.showRegionBorder !== Defaults.values.showRegionBorder
                resetByKeys: false
                onResetRequested: {
                    root.showRegionBorder = Defaults.values.showRegionBorder;
                    root.save("showRegionBorder", Defaults.values.showRegionBorder);
                }
                onToggled: isChecked => {
                    root.showRegionBorder = isChecked;
                    root.save("showRegionBorder", isChecked);
                }
            }
        }
    }

    FileBrowserSurfaceModal {
        id: recordingDirBrowser
        browserTitle: I18n.trFor("quickCapture", "Recording Folder")
        browserType: "folder_picker"
        folderMode: true
        saveMode: false
        fileExtensions: []
        revealPath: root.recordingDirectory
        onAccepted: paths => {
            if (paths && paths.length > 0) {
                const cleaned = root.cleanPath(paths[0]);
                root.recordingDirectory = cleaned;
                recordingDirectoryField.value = cleaned;
                root.save("recordingDirectory", cleaned);
            }
        }
    }
}
