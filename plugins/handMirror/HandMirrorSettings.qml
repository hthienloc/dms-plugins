import QtQuick
import qs.Common
import qs.Widgets
import qs.Modules.Plugins
import QtMultimedia
import "./dms-common"

PluginSettings {
    id: root
    pluginId: "handMirror"

    function getCameraOptions() {
        const devices = MediaDevices.videoInputs;
        if (!devices || devices.length === 0) {
            return [{ label: I18n.tr("Default Camera"), value: "0" }];
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
            text: I18n.tr("Camera & Layout")
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
            label: I18n.tr("Visual Filter")
            options: [
                { label: I18n.tr("None"), value: "none" },
                { label: I18n.tr("Grayscale"), value: "grayscale" },
                { label: I18n.tr("Sepia"), value: "sepia" },
                { label: I18n.tr("High Contrast"), value: "contrast" }
            ]
            defaultValue: "none"
        }

        Separator { visible: filterMode.value !== "none" }

        SliderSettingPlus {
            id: filterStrength
            settingKey: "filterStrength"
            label: I18n.tr("Filter Strength")
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
            label: I18n.tr("Smoothing (Denoise)")
            description: I18n.tr("Reduces camera noise by softening the image.")
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
            label: I18n.tr("Select Camera")
            options: root.getCameraOptions()
            defaultValue: "0"
        }

        Separator {}

        ToggleSettingPlus {
            id: mirror
            settingKey: "mirror"
            label: I18n.tr("Mirror Image")
            defaultValue: true
        }

        Separator {}

        ToggleSettingPlus {
            id: screenFlash
            settingKey: "screenFlash"
            label: I18n.tr("Screen Flash on Snapshot")
            defaultValue: true
        }

        Separator {}

        SliderSettingPlus {
            id: zoomFactor
            settingKey: "zoomFactor"
            label: I18n.tr("Digital Zoom")
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
            label: I18n.tr("Corner Radius")
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
            label: I18n.tr("Capture Delay")
            options: [
                { label: I18n.tr("Instant"), value: "0" },
                { label: I18n.tr("3 Seconds"), value: "3" },
                { label: I18n.tr("5 Seconds"), value: "5" },
                { label: I18n.tr("10 Seconds"), value: "10" }
            ]
            defaultValue: "0"
        }
    }

    SettingsCard {
        id: popoutSection
        SectionTitle { 
            text: I18n.tr("Popout Configuration")
            icon: "menu" 
            showReset: popoutScale.isDirty
            onResetClicked: {
                popoutScale.resetToDefault();
            }
        }

        SliderSettingPlus {
            id: popoutScale
            settingKey: "popoutScale"
            label: I18n.tr("Popout Scale")
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
            text: I18n.tr("Standalone Window Configuration")
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
            label: I18n.tr("Window Scale")
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
            label: I18n.tr("Aspect Ratio")
            options: [
                { label: I18n.tr("Auto (Camera default)"), value: "auto" },
                { label: I18n.tr("16:9 Widescreen"), value: "16:9" },
                { label: I18n.tr("4:3 Standard"), value: "4:3" },
                { label: I18n.tr("1:1 Square"), value: "1:1" }
            ]
            defaultValue: "auto"
        }
    }

    SettingsCard {
        id: snapshotSection
        SectionTitle { 
            text: I18n.tr("Snapshot Options")
            icon: "photo_camera" 
            showReset: saveDirectory.isDirty
            onResetClicked: {
                saveDirectory.resetToDefault();
            }
        }

        StringSettingPlus {
            id: saveDirectory
            settingKey: "saveDirectory"
            label: I18n.tr("Save Directory")
            placeholder: "~/Pictures/Snaps"
            defaultValue: "~/Pictures/Snaps"
            isDirectory: true
        }
    }

    PluginAbout {
        repoUrl: "https://github.com/hthienloc/dms-hand-mirror"
    }
}
