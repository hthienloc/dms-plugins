import QtQuick
import qs.Common
import qs.Widgets
import qs.Modules.Plugins
import Quickshell.Io
import "./dms-common"

PluginSettings {
    id: root
    pluginId: "bongoCat"

    SettingsCard {
        id: appearanceSection
        SectionTitle { 
            text: I18n.tr("Appearance")
            icon: "palette" 
            showReset: catSizePercent.isDirty || catYOffset.isDirty || catColorMode.isDirty || catCustomColor.isDirty || enableBlinking.isDirty || classicIdle.isDirty
            onResetClicked: {
                catSizePercent.resetToDefault();
                catYOffset.resetToDefault();
                catColorMode.resetToDefault();
                catCustomColor.resetToDefault();
                enableBlinking.resetToDefault();
                classicIdle.resetToDefault();
            }
        }

        SliderSettingPlus {
            id: catSizePercent
            settingKey: "catSizePercent"
            label: I18n.tr("Cat Size")
            defaultValue: 100
            minimum: 50
            maximum: 200
            unit: "%"
            leftLabel: "50%"
            rightLabel: "200%"
        }

        Separator {}

        SliderSettingPlus {
            id: catYOffset
            settingKey: "catYOffset"
            label: I18n.tr("Vertical Offset")
            defaultValue: 0
            minimum: -10
            maximum: 10
            unit: "px"
            leftLabel: "-10px"
            rightLabel: "10px"
        }

        Separator {}

        SelectionSettingPlus {
            id: catColorMode
            settingKey: "catColorMode"
            label: I18n.tr("Cat Color")
            description: I18n.tr("Recolor the cat. Classic keeps the theme's default black and white, Primary follows the system accent, or pick a custom color.")
            defaultValue: "classic"
            options: [
                { label: I18n.tr("Classic B/W"), value: "classic" },
                { label: I18n.tr("Theme Primary"), value: "primary" },
                { label: I18n.tr("Custom"), value: "custom" }
            ]
        }

        Column {
            width: parent.width
            visible: catColorMode.value === "custom"
            height: visible ? implicitHeight : 0
            spacing: appearanceSection.spacing

            function loadValue() {
                catCustomColor.loadValue();
            }

            Separator {}

            ColorSettingPlus {
                id: catCustomColor
                settingKey: "catCustomColor"
                label: I18n.tr("Custom Color")
                description: I18n.tr("Used when Cat Color is set to Custom.")
                defaultValue: Theme.primary
            }
        }

        Separator {}

        ToggleSettingPlus {
            id: classicIdle
            settingKey: "classicIdle"
            label: I18n.tr("Classic Color on Idle")
            description: I18n.tr("Return the cat to the classic black and white color when sleeping or idle.")
            defaultValue: false
        }

        Separator {}

        ToggleSettingPlus {
            id: enableBlinking
            settingKey: "enableBlinking"
            label: I18n.tr("Enable Blinking")
            defaultValue: true
        }

    }

    SettingsCard {
        id: inputSection
        SectionTitle { 
            text: I18n.tr("Input & Behavior")
            icon: "keyboard" 
            showReset: waitingTimeout.isDirty || pawHoldTime.isDirty || doubleSlam.isDirty || mouseEnabled.isDirty || showMetrics.isDirty || metricsInBar.isDirty || metricsWindow.isDirty
            onResetClicked: {
                waitingTimeout.resetToDefault();
                pawHoldTime.resetToDefault();
                doubleSlam.resetToDefault();
                mouseEnabled.resetToDefault();
                showMetrics.resetToDefault();
                metricsInBar.resetToDefault();
                metricsWindow.resetToDefault();
            }
        }

        SliderSettingPlus {
            id: waitingTimeout
            settingKey: "waitingTimeout"
            label: I18n.tr("Sleep Timeout")
            description: I18n.tr("Inactivity time before the cat falls asleep.")
            minimum: 1
            maximum: 10
            unit: "s"
            defaultValue: 5
            leftLabel: "1s"
            rightLabel: "10s"
        }

        Separator {}

        SliderSettingPlus {
            id: pawHoldTime
            settingKey: "pawHoldTime"
            label: I18n.tr("Paw Hold Duration")
            description: I18n.tr("How long the paws stay down after a key press (0 for instant).")
            minimum: 0
            maximum: 100
            unit: "ms"
            defaultValue: 0
            leftLabel: "0ms"
            rightLabel: "100ms"
        }

        Separator {}

        ToggleSettingPlus {
            id: doubleSlam
            settingKey: "doubleSlam"
            label: I18n.tr("Space/Enter Double Slam")
            description: I18n.tr("Pressing Space or Enter triggers both paws to slam the table.")
            defaultValue: true
        }

        Separator {}

        ToggleSettingPlus {
            id: mouseEnabled
            settingKey: "mouseEnabled"
            label: I18n.tr("Mouse Interaction")
            description: I18n.tr("Paws react to mouse input: left and right click hold the matching paw, other buttons slam both, scrolling drums with alternating paws.")
            defaultValue: false
        }

        Separator {}

        ToggleSettingPlus {
            id: showMetrics
            settingKey: "showMetrics"
            label: I18n.tr("Show Typing Metrics")
            description: I18n.tr("Display live typing speed (WPM) and correction rate in the popout. Only keystroke timing is counted; no key contents are stored.")
            defaultValue: false
        }

        Column {
            width: parent.width
            visible: showMetrics.value
            height: visible ? implicitHeight : 0
            spacing: inputSection.spacing

            function loadValue() {
                metricsInBar.loadValue();
                metricsWindow.loadValue();
            }

            Separator {}

            ToggleSettingPlus {
                id: metricsInBar
                settingKey: "metricsInBar"
                label: I18n.tr("Show Metrics in Bar")
                description: I18n.tr("Also show WPM and correction rate next to the cat in the bar.")
                defaultValue: false
            }

            Separator {}

            SliderSettingPlus {
                id: metricsWindow
                settingKey: "metricsWindowSec"
                label: I18n.tr("Measurement Window")
                description: I18n.tr("Time span the speed and correction rate are averaged over.")
                minimum: 5
                maximum: 120
                unit: "s"
                defaultValue: 60
                leftLabel: "5s"
                rightLabel: "120s"
            }
        }
    }

    SettingsCard {
        id: soundSection
        SectionTitle {
            text: I18n.tr("Sounds")
            icon: "volume_up"
            showReset: soundEnabled.isDirty || soundProfile.isDirty || soundVolume.isDirty || soundOnMouse.isDirty
            onResetClicked: {
                soundEnabled.resetToDefault();
                soundProfile.resetToDefault();
                soundVolume.resetToDefault();
                soundOnMouse.resetToDefault();
            }
        }

        ToggleSettingPlus {
            id: soundEnabled
            settingKey: "soundEnabled"
            label: I18n.tr("Enable Sounds")
            description: I18n.tr("Play a soft key-click sound as you type.")
            defaultValue: false
        }

        Column {
            width: parent.width
            visible: soundEnabled.value
            height: visible ? implicitHeight : 0
            spacing: soundSection.spacing

            function loadValue() {
                soundProfile.loadValue();
                soundVolume.loadValue();
                soundOnMouse.loadValue();
            }

            Separator {}

            SelectionSettingPlus {
                id: soundProfile
                settingKey: "soundProfile"
                label: I18n.tr("Sound Profile")
                description: I18n.tr("Choose the type of key-click sound.")
                defaultValue: "bongo"
                options: [
                    { label: I18n.tr("Bongo"), value: "bongo" },
                    { label: I18n.tr("Pop"), value: "pop" }
                ]
            }

            Separator {}

            SliderSettingPlus {
                id: soundVolume
                settingKey: "soundVolume"
                label: I18n.tr("Volume")
                minimum: 0
                maximum: 100
                unit: "%"
                defaultValue: 60
                leftLabel: "0%"
                rightLabel: "100%"
            }

            Separator { visible: mouseEnabled.value }

            ToggleSettingPlus {
                id: soundOnMouse
                visible: mouseEnabled.value
                settingKey: "soundOnMouse"
                label: I18n.tr("Mouse Clicks")
                description: I18n.tr("Also play a click on mouse buttons.")
                defaultValue: false
            }
        }
    }

    SettingsCard {
        SectionTitle { text: I18n.tr("Setup"); icon: "build" }

        InfoText {
            text: I18n.tr("Add your user to the 'input' group to detect keyboard activity:")
        }

        Column {
            width: parent.width
            spacing: Theme.spacingS

            Repeater {
                model: [
                    { cmd: "sudo usermod -aG input $USER", label: I18n.tr("Add to input group") }
                ]

                delegate: CopyBox {
                    label: modelData.label
                    text: modelData.cmd
                }
            }
        }

        InfoText {
            text: I18n.tr("After running the command, logout and login again for changes to take effect.")
            color: Theme.primary
            font.italic: true
        }
    }

    SettingsCard {
        id: behaviorSection
        SectionTitle { 
            text: I18n.tr("Behavior")
            icon: "settings" 
            showReset: showHints.isDirty
            onResetClicked: {
                showHints.resetToDefault();
            }
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
                I18n.tr("<b>Left-click</b> the cat to open the settings popout."),
                I18n.tr("<b>Right-click</b> the cat to manually toggle <b>Sleep Mode</b>."),
                I18n.tr("The cat will automatically tap its paws as you type.")
            ]
        }
    }

    PluginAbout {
        repoUrl: "https://github.com/hthienloc/dms-bongo-cat"
    }
}
