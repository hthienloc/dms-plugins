import QtQuick
import QtQuick.Controls
import qs.Common
import qs.Widgets
import qs.Modules.Plugins
import "./dms-common"

PluginSettings {
    id: root
    pluginId: "breathing"

    SettingsCard {
        id: generalSection
        SectionTitle { 
            text: I18n.tr("General")
            icon: "tune" 
            showReset: enableAutoStart.isDirty || autoStartExercise.isDirty || defaultDuration.isDirty
            onResetClicked: {
                enableAutoStart.resetToDefault();
                autoStartExercise.resetToDefault();
                defaultDuration.resetToDefault();
            }
        }

        ToggleSettingPlus {
            id: enableAutoStart
            settingKey: "enableAutoStart"
            label: I18n.tr("Auto-start Exercise")
            description: I18n.tr("Start exercise automatically on login.")
            defaultValue: false
        }

        Separator {}

        SelectionSettingPlus {
            id: autoStartExercise
            settingKey: "autoStartExercise"
            label: I18n.tr("Default Exercise")
            options: [
                { label: I18n.tr("Deep Breathing"), value: "0" },
                { label: I18n.tr("4-7-8 Breathing"), value: "1" },
                { label: I18n.tr("Box Breathing"), value: "2" },
                { label: I18n.tr("Equal Breathing"), value: "3" },
                { label: I18n.tr("Resonance"), value: "4" },
                { label: I18n.tr("Alternate Nostril"), value: "5" }
            ]
            defaultValue: "0"
        }

        Separator {}

        SliderSettingPlus {
            id: defaultDuration
            settingKey: "defaultDuration"
            label: I18n.tr("Default Duration")
            description: I18n.tr("Session length for auto-started exercises.")
            minimum: 1
            maximum: 30
            unit: I18n.tr("min")
            defaultValue: 5
            leftLabel: "1m"
            rightLabel: "30m"
        }
    }

    SettingsCard {
        id: feedbackSection
        SectionTitle { 
            text: I18n.tr("Feedback")
            icon: "vibration" 
            showReset: enableHaptic.isDirty || enableSound.isDirty || enableTwoTone.isDirty || soundType.isDirty || defaultSoundVolume.isDirty || customSoundPath.isDirty
            onResetClicked: {
                enableHaptic.resetToDefault();
                enableSound.resetToDefault();
                enableTwoTone.resetToDefault();
                soundType.resetToDefault();
                defaultSoundVolume.resetToDefault();
                customSoundPath.resetToDefault();
            }
        }

        ToggleSettingPlus {
            id: enableHaptic
            settingKey: "enableHaptic"
            label: I18n.tr("Haptic Feedback")
            defaultValue: true
        }

        Separator {}
        
        ToggleSettingPlus {
            id: enableSound
            settingKey: "enableSound"
            label: I18n.tr("Sound Cues")
            defaultValue: true
        }

        Separator {}

        ToggleSettingPlus {
            id: enableTwoTone
            settingKey: "enableTwoTone"
            label: I18n.tr("Two-Tone Model")
            description: I18n.tr("Play falling pitch during exhale (default is inhale only).")
            defaultValue: false
            visible: enableSound.value
        }

        Separator { visible: enableSound.value }

        SelectionSettingPlus {
            id: soundType
            settingKey: "soundType"
            label: I18n.tr("Sound Cue Type")
            options: [
                { label: I18n.tr("Singing Bowl Chime"), value: "chime" },
                { label: I18n.tr("Ambient Meditation"), value: "meditation" },
                { label: I18n.tr("Custom Sound File"), value: "custom" }
            ]
            defaultValue: "chime"
            visible: enableSound.value
        }

        Separator { visible: enableSound.value }

        SliderSettingPlus {
            id: defaultSoundVolume
            settingKey: "defaultSoundVolume"
            label: I18n.tr("Sound Volume")
            defaultValue: 80
            minimum: 0
            maximum: 100
            unit: "%"
            leftLabel: "0%"
            rightLabel: "100%"
            visible: enableSound.value
        }

        Separator { visible: enableSound.value && soundType.value === "custom" }

        StringSettingPlus {
            id: customSoundPath
            settingKey: "customSoundPath"
            label: I18n.tr("Custom Sound File")
            description: I18n.tr("Absolute path to custom audio.")
            placeholder: "/home/user/sounds/my-sound.ogg"
            defaultValue: ""
            visible: enableSound.value && soundType.value === "custom"
            isFile: true
            fileExtensions: [I18n.tr("Audio files") + " (*.mp3 *.wav *.ogg *.oga *.flac)", I18n.tr("All files") + " (*)"]
        }
    }

    SettingsCard {
        id: appearanceSection
        SectionTitle { 
            text: I18n.tr("Appearance")
            icon: "palette" 
            showReset: animationStyle.isDirty
            onResetClicked: animationStyle.resetToDefault()
        }

        SelectionSettingPlus {
            id: animationStyle
            settingKey: "animationStyle"
            label: I18n.tr("Animation Style")
            options: [
                { label: I18n.tr("Classic Card"), value: "classic" },
                { label: I18n.tr("Expanding Circle"), value: "circle" },
                { label: I18n.tr("Flowing Wave"), value: "wave" },
                { label: I18n.tr("Pulsating Glow"), value: "pulse" }
            ]
            defaultValue: "pulse"
        }
    }

    SettingsCard {
        id: behaviorSection
        SectionTitle { 
            text: I18n.tr("Behavior")
            icon: "settings" 
            showReset: showHints.isDirty
            onResetClicked: showHints.resetToDefault()
        }

        ToggleSettingPlus {
            id: showHints
            settingKey: "showHints"
            label: I18n.tr("Show Hints")
            defaultValue: true
        }
    }

    SettingsCard {
        SectionTitle { 
            id: usageTitle
            text: I18n.tr("Usage Guide")
            icon: "menu_book" 
            collapsible: true
            settingKey: "usageGuideExpanded"
        }

        UsageGuide {
            expanded: usageTitle.isExpanded
            items: [
                I18n.tr("<b>Left-click</b> the pill to start/pause the breathing session."),
                I18n.tr("<b>Right-click</b> the pill to stop and reset the session."),
                I18n.tr("Open the <b>Popout</b> to choose different breathing techniques."),
                I18n.tr("Follow the <b>visual guide</b> and <b>sound cues</b> to sync your breath.")
            ]
        }
    }

    PluginAbout {
        repoUrl: "https://github.com/hthienloc/dms-breathing"
    }
}
