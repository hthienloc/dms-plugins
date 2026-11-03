import QtQuick
import QtMultimedia
import qs.Common
import qs.Modules.Plugins
import "./shared"

PluginSettings {
    id: root
    pluginId: "handMirror"

    MediaDevices {
        id: mediaDevices
    }

    function getCameraOptions() {
        const devices = mediaDevices.videoInputs;
        if (!devices || devices.length === 0) {
            return [{ label: I18n.trFor("handMirror", "Default Camera"), value: "0" }];
        }
        let opts = [];
        for (let i = 0; i < devices.length; i++) {
            opts.push({ label: devices[i].description || ("Camera " + i), value: String(i) });
        }
        return opts;
    }

    SettingsCard {
        id: cameraSection
        SectionTitle { 
            text: I18n.trFor("handMirror", "Camera & Layout")
            icon: "videocam" 
            showReset: cameraIndex.isDirty || zoomFactor.isDirty || borderRadius.isDirty || screenFlash.isDirty || captureDelay.isDirty || filterMode.isDirty || filterStrength.isDirty || smoothingAmount.isDirty
            onResetClicked: {
                cameraIndex.resetToDefault();
                zoomFactor.resetToDefault();
                borderRadius.resetToDefault();
                screenFlash.resetToDefault();
                captureDelay.resetToDefault();
                filterMode.resetToDefault();
                filterStrength.resetToDefault();
                smoothingAmount.resetToDefault();
            }
        }

        SelectionSettingPlus {
            id: filterMode
            settingKey: "filterMode"
            label: I18n.trFor("handMirror", "Visual Filter")
            options: [
                { label: I18n.trFor("handMirror", "None"), value: "none" },
                { label: I18n.trFor("handMirror", "Grayscale"), value: "grayscale" },
                { label: I18n.trFor("handMirror", "Sepia"), value: "sepia" },
                { label: I18n.trFor("handMirror", "High Contrast"), value: "contrast" }
            ]
            defaultValue: "none"
        }

        Separator { visible: filterMode.value !== "none" }

        SliderSettingPlus {
            id: filterStrength
            settingKey: "filterStrength"
            label: I18n.trFor("handMirror", "Filter Strength")
            defaultValue: 100
            minimum: 0
            maximum: 100
            unit: "%"
            leftLabel: "0%"
            rightLabel: "100%"
            visible: filterMode.value !== "none"
        }

        Separator {}

        SliderSettingPlus {
            id: smoothingAmount
            settingKey: "smoothingAmount"
            label: I18n.trFor("handMirror", "Smoothing (Denoise)")
            description: I18n.trFor("handMirror", "Reduces camera noise by softening the image.")
            defaultValue: 0
            minimum: 0
            maximum: 100
            unit: "%"
            leftLabel: "Off"
            rightLabel: "Max"
        }

        Separator {}

        SelectionSettingPlus {
            id: cameraIndex
            settingKey: "cameraIndex"
            label: I18n.trFor("handMirror", "Select Camera")
            options: root.getCameraOptions()
            defaultValue: "0"
        }

        Separator {}

        ToggleSettingPlus {
            id: mirror
            settingKey: "mirror"
            label: I18n.trFor("handMirror", "Mirror Image")
            defaultValue: true
        }

        Separator {}

        ToggleSettingPlus {
            id: screenFlash
            settingKey: "screenFlash"
            label: I18n.trFor("handMirror", "Screen Flash on Snapshot")
            defaultValue: true
        }

        Separator {}

        SliderSettingPlus {
            id: zoomFactor
            settingKey: "zoomFactor"
            label: I18n.trFor("handMirror", "Digital Zoom")
            defaultValue: 1.0
            minimum: 1.0
            maximum: 3.0
            unit: "x"
            leftLabel: "1.0"
            rightLabel: "3.0"
        }

        Separator {}

        SliderSettingPlus {
            id: borderRadius
            settingKey: "borderRadius"
            label: I18n.trFor("handMirror", "Corner Radius")
            defaultValue: 16
            minimum: 0
            maximum: 64
            unit: "px"
            leftLabel: "0"
            rightLabel: "64"
        }

        Separator {}

        SelectionSettingPlus {
            id: captureDelay
            settingKey: "captureDelay"
            label: I18n.trFor("handMirror", "Capture Delay")
            options: [
                { label: I18n.trFor("handMirror", "Instant"), value: "0" },
                { label: I18n.trFor("handMirror", "3 Seconds"), value: "3" },
                { label: I18n.trFor("handMirror", "5 Seconds"), value: "5" },
                { label: I18n.trFor("handMirror", "10 Seconds"), value: "10" }
            ]
            defaultValue: "0"
        }
    }

    SettingsCard {
        id: popoutSection
        SectionTitle { 
            text: I18n.trFor("handMirror", "Popout Configuration")
            icon: "menu" 
            showReset: popoutScale.isDirty
            onResetClicked: {
                popoutScale.resetToDefault();
            }
        }

        SliderSettingPlus {
            id: popoutScale
            settingKey: "popoutScale"
            label: I18n.trFor("handMirror", "Popout Scale")
            defaultValue: 100
            minimum: 50
            maximum: 250
            unit: "%"
            leftLabel: "50%"
            rightLabel: "250%"
        }
    }

    SettingsCard {
        id: windowSection
        SectionTitle { 
            text: I18n.trFor("handMirror", "Standalone Window Configuration")
            icon: "aspect_ratio" 
            showReset: windowScale.isDirty || aspectRatio.isDirty
            onResetClicked: {
                windowScale.resetToDefault();
                aspectRatio.resetToDefault();
            }
        }

        SliderSettingPlus {
            id: windowScale
            settingKey: "windowScale"
            label: I18n.trFor("handMirror", "Window Scale")
            defaultValue: 100
            minimum: 50
            maximum: 250
            unit: "%"
            leftLabel: "50%"
            rightLabel: "250%"
        }

        Separator {}

        SelectionSettingPlus {
            id: aspectRatio
            settingKey: "aspectRatio"
            label: I18n.trFor("handMirror", "Aspect Ratio")
            options: [
                { label: I18n.trFor("handMirror", "Auto (Camera default)"), value: "auto" },
                { label: I18n.trFor("handMirror", "16:9 Widescreen"), value: "16:9" },
                { label: I18n.trFor("handMirror", "4:3 Standard"), value: "4:3" },
                { label: I18n.trFor("handMirror", "1:1 Square"), value: "1:1" }
            ]
            defaultValue: "auto"
        }
    }

    SettingsCard {
        id: snapshotSection
        SectionTitle { 
            text: I18n.trFor("handMirror", "Snapshot Options")
            icon: "photo_camera" 
            showReset: saveDirectory.isDirty
            onResetClicked: {
                saveDirectory.resetToDefault();
            }
        }

        StringSettingPlus {
            id: saveDirectory
            settingKey: "saveDirectory"
            label: I18n.trFor("handMirror", "Save Directory")
            placeholder: "~/Pictures/Snaps"
            defaultValue: "~/Pictures/Snaps"
            isDirectory: true
        }
    }
}
