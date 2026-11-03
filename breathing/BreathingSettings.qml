import QtQuick
import QtQuick.Controls
import qs.Common
import qs.Modules.Plugins
import "./shared"

PluginSettings {
    id: root
    pluginId: "breathing"

    SettingsCard {
        id: generalSection
        SectionTitle { 
            text: I18n.trFor("breathing", "General")
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
            label: I18n.trFor("breathing", "Auto-start Exercise")
            description: I18n.trFor("breathing", "Start exercise automatically on login.")
            defaultValue: false
        }

        Separator {}

        SelectionSettingPlus {
            id: autoStartExercise
            settingKey: "autoStartExercise"
            label: I18n.trFor("breathing", "Default Exercise")
            options: [
                { label: I18n.trFor("breathing", "Deep Breathing"), value: "0" },
                { label: I18n.trFor("breathing", "4-7-8 Breathing"), value: "1" },
                { label: I18n.trFor("breathing", "Box Breathing"), value: "2" },
                { label: I18n.trFor("breathing", "Equal Breathing"), value: "3" },
                { label: I18n.trFor("breathing", "Resonance"), value: "4" },
                { label: I18n.trFor("breathing", "Alternate Nostril"), value: "5" }
            ]
            defaultValue: "0"
        }

        Separator {}

        SliderSettingPlus {
            id: defaultDuration
            settingKey: "defaultDuration"
            label: I18n.trFor("breathing", "Default Duration")
            description: I18n.trFor("breathing", "Session length for auto-started exercises.")
            minimum: 1
            maximum: 30
            unit: I18n.trFor("breathing", "min")
            defaultValue: 5
            leftLabel: "1m"
            rightLabel: "30m"
        }
    }

    SettingsCard {
        id: feedbackSection
        SectionTitle { 
            text: I18n.trFor("breathing", "Feedback")
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
            label: I18n.trFor("breathing", "Haptic Feedback")
            defaultValue: true
        }

        Separator {}
        
        ToggleSettingPlus {
            id: enableSound
            settingKey: "enableSound"
            label: I18n.trFor("breathing", "Sound Cues")
            defaultValue: true
        }

        Separator {}

        ToggleSettingPlus {
            id: enableTwoTone
            settingKey: "enableTwoTone"
            label: I18n.trFor("breathing", "Two-Tone Model")
            description: I18n.trFor("breathing", "Play falling pitch during exhale (default is inhale only).")
            defaultValue: false
            visible: enableSound.value
        }

        Separator { visible: enableSound.value }

        SelectionSettingPlus {
            id: soundType
            settingKey: "soundType"
            label: I18n.trFor("breathing", "Sound Cue Type")
            options: [
                { label: I18n.trFor("breathing", "Singing Bowl Chime"), value: "chime" },
                { label: I18n.trFor("breathing", "Ambient Meditation"), value: "meditation" },
                { label: I18n.trFor("breathing", "Custom Sound File"), value: "custom" }
            ]
            defaultValue: "chime"
            visible: enableSound.value
        }

        Separator { visible: enableSound.value }

        SliderSettingPlus {
            id: defaultSoundVolume
            settingKey: "defaultSoundVolume"
            label: I18n.trFor("breathing", "Sound Volume")
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
            label: I18n.trFor("breathing", "Custom Sound File")
            description: I18n.trFor("breathing", "Absolute path to custom audio.")
            placeholder: "/home/user/sounds/my-sound.ogg"
            defaultValue: ""
            visible: enableSound.value && soundType.value === "custom"
            isFile: true
            fileExtensions: [I18n.trFor("breathing", "Audio files") + " (*.mp3 *.wav *.ogg *.oga *.flac)", I18n.trFor("breathing", "All files") + " (*)"]
        }
    }

    SettingsCard {
        id: appearanceSection
        SectionTitle { 
            text: I18n.trFor("breathing", "Appearance")
            icon: "palette" 
            showReset: animationStyle.isDirty
            onResetClicked: animationStyle.resetToDefault()
        }

        SelectionSettingPlus {
            id: animationStyle
            settingKey: "animationStyle"
            label: I18n.trFor("breathing", "Animation Style")
            options: [
                { label: I18n.trFor("breathing", "Classic Card"), value: "classic" },
                { label: I18n.trFor("breathing", "Expanding Circle"), value: "circle" },
                { label: I18n.trFor("breathing", "Flowing Wave"), value: "wave" },
                { label: I18n.trFor("breathing", "Pulsating Glow"), value: "pulse" }
            ]
            defaultValue: "pulse"
        }
    }

    SettingsCard {
        id: behaviorSection
        SectionTitle { 
            text: I18n.trFor("breathing", "Behavior")
            icon: "settings" 
            showReset: showHints.isDirty
            onResetClicked: showHints.resetToDefault()
        }

        ToggleSettingPlus {
            id: showHints
            settingKey: "showHints"
            label: I18n.trFor("breathing", "Show Hints")
            defaultValue: true
        }
    }

    SettingsCard {
        SectionTitle { 
            id: usageTitle
            text: I18n.trFor("breathing", "Usage Guide")
            icon: "menu_book" 
            collapsible: true
            settingKey: "usageGuideExpanded"
        }

        UsageGuide {
            expanded: usageTitle.isExpanded
            items: [
                I18n.trFor("breathing", "<b>Left-click</b> the pill to start/pause the breathing session."),
                I18n.trFor("breathing", "<b>Right-click</b> the pill to stop and reset the session."),
                I18n.trFor("breathing", "Open the <b>Popout</b> to choose different breathing techniques."),
                I18n.trFor("breathing", "Follow the <b>visual guide</b> and <b>sound cues</b> to sync your breath.")
            ]
        }
    }
}
