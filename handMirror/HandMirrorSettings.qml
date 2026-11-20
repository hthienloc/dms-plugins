import QtQuick
import QtMultimedia
import qs.Common
import qs.DCommon.Widgets
import qs.Modals.FileBrowser
import qs.Modules.Plugins
import qs.Modules.Settings.Widgets

PluginSettings {
    id: root
    pluginId: "handMirror"

    readonly property string defaultFilterMode: "none"
    readonly property int defaultFilterStrength: 100
    readonly property int defaultSmoothingAmount: 0
    readonly property string defaultCameraIndex: "0"
    readonly property bool defaultMirror: true
    readonly property bool defaultScreenFlash: true
    readonly property real defaultZoomFactor: 1.0
    readonly property int defaultBorderRadius: 16
    readonly property string defaultCaptureDelay: "0"
    readonly property int defaultPopoutScale: 100
    readonly property int defaultWindowScale: 100
    readonly property string defaultAspectRatio: "auto"
    readonly property string defaultSaveDirectory: "~/Pictures/Snaps"

    property string filterMode: defaultFilterMode
    property int filterStrength: defaultFilterStrength
    property int smoothingAmount: defaultSmoothingAmount
    property string cameraIndex: defaultCameraIndex
    property bool mirror: defaultMirror
    property bool screenFlash: defaultScreenFlash
    property real zoomFactor: defaultZoomFactor
    property int borderRadius: defaultBorderRadius
    property string captureDelay: defaultCaptureDelay
    property int popoutScale: defaultPopoutScale
    property int windowScale: defaultWindowScale
    property string aspectRatio: defaultAspectRatio
    property string saveDirectory: defaultSaveDirectory

    MediaDevices {
        id: mediaDevices
    }

    function loadSettings() {
        if (!pluginService)
            return;
        filterMode = loadValue("filterMode", defaultFilterMode);
        filterStrength = loadValue("filterStrength", defaultFilterStrength);
        smoothingAmount = loadValue("smoothingAmount", defaultSmoothingAmount);
        cameraIndex = loadValue("cameraIndex", defaultCameraIndex);
        mirror = loadValue("mirror", defaultMirror);
        screenFlash = loadValue("screenFlash", defaultScreenFlash);
        zoomFactor = loadValue("zoomFactor", defaultZoomFactor);
        borderRadius = loadValue("borderRadius", defaultBorderRadius);
        captureDelay = loadValue("captureDelay", defaultCaptureDelay);
        popoutScale = loadValue("popoutScale", defaultPopoutScale);
        windowScale = loadValue("windowScale", defaultWindowScale);
        aspectRatio = loadValue("aspectRatio", defaultAspectRatio);
        saveDirectory = loadValue("saveDirectory", defaultSaveDirectory);
    }

    Component.onCompleted: loadSettings()
    onPluginServiceChanged: loadSettings()

    function getCameraLabels() {
        const devices = mediaDevices.videoInputs;
        if (!devices || devices.length === 0)
            return [I18n.trFor("handMirror", "Default Camera")];
        let labels = [];
        for (let i = 0; i < devices.length; i++) {
            labels.push(devices[i].description || ("Camera " + i));
        }
        return labels;
    }

    function getCameraValues() {
        const devices = mediaDevices.videoInputs;
        if (!devices || devices.length === 0)
            return ["0"];
        let values = [];
        for (let i = 0; i < devices.length; i++) {
            values.push(String(i));
        }
        return values;
    }

    Column {
        width: parent ? parent.width : 0
        spacing: 0

        SettingsSectionLabel {
            width: parent.width
            text: I18n.trFor("handMirror", "Camera & Layout")
        }

        SettingsGroup {
            width: parent.width
            slotColor: SettingsMetrics.controlColor

            SettingsDropdownRow {
                text: I18n.trFor("handMirror", "Visual Filter")
                options: [
                    I18n.trFor("handMirror", "None"),
                    I18n.trFor("handMirror", "Grayscale"),
                    I18n.trFor("handMirror", "Sepia"),
                    I18n.trFor("handMirror", "High Contrast")
                ]
                optionValues: ["none", "grayscale", "sepia", "contrast"]
                currentValue: root.filterMode
                modified: root.filterMode !== root.defaultFilterMode
                resetByKeys: false
                onResetRequested: {
                    root.filterMode = root.defaultFilterMode;
                    root.saveValue("filterMode", root.defaultFilterMode);
                }
                onValueChanged: val => {
                    root.filterMode = val;
                    root.saveValue("filterMode", val);
                }
            }

            SettingsSliderRow {
                visible: root.filterMode !== "none"
                text: I18n.trFor("handMirror", "Filter Strength")
                minimum: 0
                maximum: 100
                step: 1
                unit: "%"
                value: root.filterStrength
                modified: root.filterStrength !== root.defaultFilterStrength
                resetByKeys: false
                onResetRequested: {
                    root.filterStrength = root.defaultFilterStrength;
                    root.saveValue("filterStrength", root.defaultFilterStrength);
                }
                onSliderDragFinished: finalValue => {
                    root.filterStrength = finalValue;
                    root.saveValue("filterStrength", finalValue);
                }
            }

            SettingsSliderRow {
                text: I18n.trFor("handMirror", "Smoothing (Denoise)")
                description: I18n.trFor("handMirror", "Reduces camera noise by softening the image.")
                minimum: 0
                maximum: 100
                step: 1
                unit: "%"
                value: root.smoothingAmount
                modified: root.smoothingAmount !== root.defaultSmoothingAmount
                resetByKeys: false
                onResetRequested: {
                    root.smoothingAmount = root.defaultSmoothingAmount;
                    root.saveValue("smoothingAmount", root.defaultSmoothingAmount);
                }
                onSliderDragFinished: finalValue => {
                    root.smoothingAmount = finalValue;
                    root.saveValue("smoothingAmount", finalValue);
                }
            }

            SettingsDropdownRow {
                text: I18n.trFor("handMirror", "Select Camera")
                options: root.getCameraLabels()
                optionValues: root.getCameraValues()
                currentValue: root.cameraIndex
                modified: root.cameraIndex !== root.defaultCameraIndex
                resetByKeys: false
                onResetRequested: {
                    root.cameraIndex = root.defaultCameraIndex;
                    root.saveValue("cameraIndex", root.defaultCameraIndex);
                }
                onValueChanged: val => {
                    root.cameraIndex = val;
                    root.saveValue("cameraIndex", val);
                }
            }

            SettingsToggleRow {
                text: I18n.trFor("handMirror", "Mirror Image")
                checked: root.mirror
                modified: root.mirror !== root.defaultMirror
                resetByKeys: false
                onResetRequested: {
                    root.mirror = root.defaultMirror;
                    root.saveValue("mirror", root.defaultMirror);
                }
                onToggled: isChecked => {
                    root.mirror = isChecked;
                    root.saveValue("mirror", isChecked);
                }
            }

            SettingsToggleRow {
                text: I18n.trFor("handMirror", "Screen Flash on Snapshot")
                checked: root.screenFlash
                modified: root.screenFlash !== root.defaultScreenFlash
                resetByKeys: false
                onResetRequested: {
                    root.screenFlash = root.defaultScreenFlash;
                    root.saveValue("screenFlash", root.defaultScreenFlash);
                }
                onToggled: isChecked => {
                    root.screenFlash = isChecked;
                    root.saveValue("screenFlash", isChecked);
                }
            }

            SettingsSliderRow {
                text: I18n.trFor("handMirror", "Digital Zoom")
                minimum: 1.0
                maximum: 3.0
                step: 0.1
                unit: "x"
                value: root.zoomFactor
                modified: root.zoomFactor !== root.defaultZoomFactor
                resetByKeys: false
                onResetRequested: {
                    root.zoomFactor = root.defaultZoomFactor;
                    root.saveValue("zoomFactor", root.defaultZoomFactor);
                }
                onSliderDragFinished: finalValue => {
                    root.zoomFactor = finalValue;
                    root.saveValue("zoomFactor", finalValue);
                }
            }

            SettingsSliderRow {
                text: I18n.trFor("handMirror", "Corner Radius")
                minimum: 0
                maximum: 64
                step: 1
                unit: "px"
                value: root.borderRadius
                modified: root.borderRadius !== root.defaultBorderRadius
                resetByKeys: false
                onResetRequested: {
                    root.borderRadius = root.defaultBorderRadius;
                    root.saveValue("borderRadius", root.defaultBorderRadius);
                }
                onSliderDragFinished: finalValue => {
                    root.borderRadius = finalValue;
                    root.saveValue("borderRadius", finalValue);
                }
            }

            SettingsDropdownRow {
                text: I18n.trFor("handMirror", "Capture Delay")
                options: [
                    I18n.trFor("handMirror", "Instant"),
                    I18n.trFor("handMirror", "3 Seconds"),
                    I18n.trFor("handMirror", "5 Seconds"),
                    I18n.trFor("handMirror", "10 Seconds")
                ]
                optionValues: ["0", "3", "5", "10"]
                currentValue: root.captureDelay
                modified: root.captureDelay !== root.defaultCaptureDelay
                resetByKeys: false
                onResetRequested: {
                    root.captureDelay = root.defaultCaptureDelay;
                    root.saveValue("captureDelay", root.defaultCaptureDelay);
                }
                onValueChanged: val => {
                    root.captureDelay = val;
                    root.saveValue("captureDelay", val);
                }
            }
        }
    }

    Column {
        width: parent ? parent.width : 0
        spacing: 0

        SettingsSectionLabel {
            width: parent.width
            text: I18n.trFor("handMirror", "Popout Configuration")
        }

        SettingsGroup {
            width: parent.width
            slotColor: SettingsMetrics.controlColor

            SettingsSliderRow {
                text: I18n.trFor("handMirror", "Popout Scale")
                minimum: 50
                maximum: 250
                step: 1
                unit: "%"
                value: root.popoutScale
                modified: root.popoutScale !== root.defaultPopoutScale
                resetByKeys: false
                onResetRequested: {
                    root.popoutScale = root.defaultPopoutScale;
                    root.saveValue("popoutScale", root.defaultPopoutScale);
                }
                onSliderDragFinished: finalValue => {
                    root.popoutScale = finalValue;
                    root.saveValue("popoutScale", finalValue);
                }
            }
        }
    }

    Column {
        width: parent ? parent.width : 0
        spacing: 0

        SettingsSectionLabel {
            width: parent.width
            text: I18n.trFor("handMirror", "Standalone Window Configuration")
        }

        SettingsGroup {
            width: parent.width
            slotColor: SettingsMetrics.controlColor

            SettingsSliderRow {
                text: I18n.trFor("handMirror", "Window Scale")
                minimum: 50
                maximum: 250
                step: 1
                unit: "%"
                value: root.windowScale
                modified: root.windowScale !== root.defaultWindowScale
                resetByKeys: false
                onResetRequested: {
                    root.windowScale = root.defaultWindowScale;
                    root.saveValue("windowScale", root.defaultWindowScale);
                }
                onSliderDragFinished: finalValue => {
                    root.windowScale = finalValue;
                    root.saveValue("windowScale", finalValue);
                }
            }

            SettingsDropdownRow {
                text: I18n.trFor("handMirror", "Aspect Ratio")
                options: [
                    I18n.trFor("handMirror", "Auto (Camera default)"),
                    I18n.trFor("handMirror", "16:9 Widescreen"),
                    I18n.trFor("handMirror", "4:3 Standard"),
                    I18n.trFor("handMirror", "1:1 Square")
                ]
                optionValues: ["auto", "16:9", "4:3", "1:1"]
                currentValue: root.aspectRatio
                modified: root.aspectRatio !== root.defaultAspectRatio
                resetByKeys: false
                onResetRequested: {
                    root.aspectRatio = root.defaultAspectRatio;
                    root.saveValue("aspectRatio", root.defaultAspectRatio);
                }
                onValueChanged: val => {
                    root.aspectRatio = val;
                    root.saveValue("aspectRatio", val);
                }
            }
        }
    }

    Column {
        width: parent ? parent.width : 0
        spacing: 0

        SettingsSectionLabel {
            width: parent.width
            text: I18n.trFor("handMirror", "Snapshot Options")
        }

        SettingsGroup {
            width: parent.width
            slotColor: SettingsMetrics.controlColor

            SettingsTextFieldRow {
                id: saveDirectoryField
                text: I18n.trFor("handMirror", "Save Directory")
                placeholderText: "~/Pictures/Snaps"
                value: root.saveDirectory
                modified: root.saveDirectory !== root.defaultSaveDirectory
                onResetRequested: {
                    root.saveDirectory = root.defaultSaveDirectory;
                    saveDirectoryField.value = root.defaultSaveDirectory;
                    root.saveValue("saveDirectory", root.defaultSaveDirectory);
                }
                onValueEdited: val => {
                    root.saveDirectory = val;
                    root.saveValue("saveDirectory", val);
                }
                actions: DActionButton {
                    iconName: "folder_open"
                    tooltipText: I18n.trFor("handMirror", "Select Directory")
                    onClicked: browserModal.open()
                }
            }
        }
    }

    FileBrowserSurfaceModal {
        id: browserModal
        browserTitle: I18n.trFor("handMirror", "Save Directory")
        browserType: "folder_picker"
        folderMode: true
        saveMode: false
        revealPath: root.saveDirectory !== "" ? root.saveDirectory : ""
        onAccepted: paths => {
            if (paths && paths.length > 0) {
                let p = paths[0].toString();
                if (p.startsWith("file://"))
                    p = p.slice(7);
                root.saveDirectory = p;
                saveDirectoryField.value = p;
                root.saveValue("saveDirectory", p);
            }
        }
    }
}
