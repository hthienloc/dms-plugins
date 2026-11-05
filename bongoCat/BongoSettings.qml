import QtQuick
import qs.Common
import qs.Modules.Plugins
import "./shared"

PluginSettings {
    id: root
    pluginId: "bongoCat"

    SettingsCard {
        id: appearanceSection
        SectionTitle { 
            text: I18n.trFor("bongoCat", "Appearance")
            icon: "palette" 
            showReset: catSkin.isDirty || pixelSkinColor.isDirty || catSizePercent.isDirty || catYOffset.isDirty || catColorMode.isDirty || catCustomColor.isDirty || enableBlinking.isDirty || classicIdle.isDirty
            onResetClicked: {
                catSkin.resetToDefault();
                pixelSkinColor.resetToDefault();
                catSizePercent.resetToDefault();
                catYOffset.resetToDefault();
                catColorMode.resetToDefault();
                catCustomColor.resetToDefault();
                enableBlinking.resetToDefault();
                classicIdle.resetToDefault();
            }
        }

        SelectionSettingPlus {
            id: catSkin
            settingKey: "catSkin"
            label: I18n.trFor("bongoCat", "Cat Skin")
            description: I18n.trFor("bongoCat", "Choose between the classic vector font cat or the pixel doodle sprite skin.")
            defaultValue: "classic"
            options: [
                { label: I18n.trFor("bongoCat", "Classic (Vector)"), value: "classic" },
                { label: I18n.trFor("bongoCat", "Pixel Doodle"), value: "pixel" }
            ]
        }

        Separator {}

        SliderSettingPlus {
            id: catSizePercent
            settingKey: "catSizePercent"
            label: I18n.trFor("bongoCat", "Cat Size")
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
            label: I18n.trFor("bongoCat", "Vertical Offset")
            defaultValue: 0
            minimum: -10
            maximum: 10
            unit: "px"
            leftLabel: "-10px"
            rightLabel: "10px"
        }

        Column {
            width: parent.width
            visible: catSkin.value === "pixel"
            height: visible ? implicitHeight : 0
            spacing: appearanceSection.spacing

            function loadValue() {
                pixelSkinColor.loadValue();
            }

            Separator {}

            SelectionSettingPlus {
                id: pixelSkinColor
                settingKey: "pixelSkinColor"
                label: I18n.trFor("bongoCat", "Cat Color")
                description: I18n.trFor("bongoCat", "Choose a color pattern for the Pixel Doodle skin.")
                defaultValue: "white"
                options: [
                    { label: I18n.trFor("bongoCat", "Classic White"), value: "white" },
                    { label: I18n.trFor("bongoCat", "Midnight Black"), value: "black" },
                    { label: I18n.trFor("bongoCat", "Ginger Orange"), value: "orange" },
                    { label: I18n.trFor("bongoCat", "Calico"), value: "calico" },
                    { label: I18n.trFor("bongoCat", "Siamese"), value: "siamese" },
                    { label: I18n.trFor("bongoCat", "Sakura Pink"), value: "pink" },
                    { label: I18n.trFor("bongoCat", "Cyberpunk"), value: "cyberpunk" },
                    { label: I18n.trFor("bongoCat", "Zombie"), value: "zombie" }
                ]
            }
        }

        Column {
            width: parent.width
            visible: catSkin.value !== "pixel"
            height: visible ? implicitHeight : 0
            spacing: appearanceSection.spacing

            function loadValue() {
                catColorMode.loadValue();
                catCustomColor.loadValue();
                classicIdle.loadValue();
            }

            Separator {}

            SelectionSettingPlus {
                id: catColorMode
                settingKey: "catColorMode"
                label: I18n.trFor("bongoCat", "Cat Color")
                description: I18n.trFor("bongoCat", "Recolor the cat. Classic keeps the theme's default black and white, Primary follows the system accent, or pick a custom color.")
                defaultValue: "classic"
                options: [
                    { label: I18n.trFor("bongoCat", "Classic B/W"), value: "classic" },
                    { label: I18n.trFor("bongoCat", "Theme Primary"), value: "primary" },
                    { label: I18n.trFor("bongoCat", "Custom"), value: "custom" }
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
                    label: I18n.trFor("bongoCat", "Custom Color")
                    description: I18n.trFor("bongoCat", "Used when Cat Color is set to Custom.")
                    defaultValue: Theme.primary
                }
            }

            Separator {}

            ToggleSettingPlus {
                id: classicIdle
                settingKey: "classicIdle"
                label: I18n.trFor("bongoCat", "Classic Color on Idle")
                description: I18n.trFor("bongoCat", "Return the cat to the classic black and white color when sleeping or idle.")
                defaultValue: false
            }
        }

        Separator {}

        ToggleSettingPlus {
            id: enableBlinking
            settingKey: "enableBlinking"
            label: I18n.trFor("bongoCat", "Enable Blinking")
            defaultValue: true
        }

    }

    SettingsCard {
        id: inputSection
        SectionTitle { 
            text: I18n.trFor("bongoCat", "Input & Behavior")
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
            label: I18n.trFor("bongoCat", "Sleep Timeout")
            description: I18n.trFor("bongoCat", "Inactivity time before the cat falls asleep.")
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
            label: I18n.trFor("bongoCat", "Paw Hold Duration")
            description: I18n.trFor("bongoCat", "How long the paws stay down after a key press (0 for instant).")
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
            label: I18n.trFor("bongoCat", "Space/Enter Double Slam")
            description: I18n.trFor("bongoCat", "Pressing Space or Enter triggers both paws to slam the table.")
            defaultValue: true
        }

        Separator {}

        ToggleSettingPlus {
            id: mouseEnabled
            settingKey: "mouseEnabled"
            label: I18n.trFor("bongoCat", "Mouse Interaction")
            description: I18n.trFor("bongoCat", "Paws react to mouse input: left and right click hold the matching paw, other buttons slam both, scrolling drums with alternating paws.")
            defaultValue: false
        }

        Separator {}

        ToggleSettingPlus {
            id: showMetrics
            settingKey: "showMetrics"
            label: I18n.trFor("bongoCat", "Show Typing Metrics")
            description: I18n.trFor("bongoCat", "Display live typing speed (WPM) and correction rate in the popout. Only keystroke timing is counted; no key contents are stored.")
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
                label: I18n.trFor("bongoCat", "Show Metrics in Bar")
                description: I18n.trFor("bongoCat", "Also show WPM and correction rate next to the cat in the bar.")
                defaultValue: false
            }

            Separator {}

            SliderSettingPlus {
                id: metricsWindow
                settingKey: "metricsWindowSec"
                label: I18n.trFor("bongoCat", "Measurement Window")
                description: I18n.trFor("bongoCat", "Time span the speed and correction rate are averaged over.")
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
            text: I18n.trFor("bongoCat", "Sounds")
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
            label: I18n.trFor("bongoCat", "Enable Sounds")
            description: I18n.trFor("bongoCat", "Play a soft key-click sound as you type.")
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
                label: I18n.trFor("bongoCat", "Sound Profile")
                description: I18n.trFor("bongoCat", "Choose the type of key-click sound.")
                defaultValue: "bongo"
                options: [
                    { label: I18n.trFor("bongoCat", "Bongo"), value: "bongo" },
                    { label: I18n.trFor("bongoCat", "Pop"), value: "pop" }
                ]
            }

            Separator {}

            SliderSettingPlus {
                id: soundVolume
                settingKey: "soundVolume"
                label: I18n.trFor("bongoCat", "Volume")
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
                label: I18n.trFor("bongoCat", "Mouse Clicks")
                description: I18n.trFor("bongoCat", "Also play a click on mouse buttons.")
                defaultValue: false
            }
        }
    }

    SettingsCard {
        SectionTitle { text: I18n.trFor("bongoCat", "Setup"); icon: "build" }

        InfoText {
            text: I18n.trFor("bongoCat", "Add your user to the 'input' group to detect keyboard activity:")
        }

        Column {
            width: parent.width
            spacing: Theme.spacingS

            Repeater {
                model: [
                    { cmd: "sudo usermod -aG input $USER", label: I18n.trFor("bongoCat", "Add to input group") }
                ]

                delegate: CopyBox {
                    label: modelData.label
                    text: modelData.cmd
                }
            }
        }

        InfoText {
            text: I18n.trFor("bongoCat", "After running the command, logout and login again for changes to take effect.")
            color: Theme.primary
            font.italic: true
        }
    }

    SettingsCard {
        id: desktopSection
        SectionTitle {
            text: I18n.trFor("bongoCat", "Desktop Widget")
            icon: "desktop_windows"
            showReset: desktopBackgroundOpacity.isDirty || desktopShowMetrics.isDirty
            onResetClicked: {
                desktopBackgroundOpacity.resetToDefault();
                desktopShowMetrics.resetToDefault();
            }
        }

        SliderSettingPlus {
            id: desktopBackgroundOpacity
            settingKey: "desktopBackgroundOpacity"
            label: I18n.trFor("bongoCat", "Background Opacity")
            description: I18n.trFor("bongoCat", "Adjust transparency of the desktop widget card.")
            defaultValue: 0
            minimum: 0
            maximum: 100
            unit: "%"
            leftLabel: "0%"
            rightLabel: "100%"
        }

        Separator {}

        ToggleSettingPlus {
            id: desktopShowMetrics
            settingKey: "desktopShowMetrics"
            label: I18n.trFor("bongoCat", "Show Typing Metrics")
            description: I18n.trFor("bongoCat", "Display live WPM and accuracy underneath the cat on the desktop.")
            defaultValue: false
        }
    }

    SettingsCard {
        id: behaviorSection
        SectionTitle { 
            text: I18n.trFor("bongoCat", "Behavior")
            icon: "settings" 
            showReset: showHints.isDirty
            onResetClicked: {
                showHints.resetToDefault();
            }
        }

        ToggleSettingPlus {
            id: showHints
            settingKey: "showHints"
            label: I18n.trFor("bongoCat", "Show Hints")
            defaultValue: true
        }
    }

    SettingsCard {
        SectionTitle { 
            id: usageTitle
            text: I18n.trFor("bongoCat", "Usage Guide")
            icon: "menu_book" 
            collapsible: true
            settingKey: "usageGuideExpanded"
        }

        UsageGuide {
            expanded: usageTitle.isExpanded
            items: [
                I18n.trFor("bongoCat", "<b>Left-click</b> the cat to open the settings popout."),
                I18n.trFor("bongoCat", "<b>Right-click</b> the cat to manually toggle <b>Sleep Mode</b>."),
                I18n.trFor("bongoCat", "The cat will automatically tap its paws as you type.")
            ]
        }
    }

    SettingsCard {
        SectionTitle {
            id: creditsTitle
            text: I18n.trFor("bongoCat", "Credits")
            icon: "favorite"
            collapsible: true
            settingKey: "creditsExpanded"
        }

        CreditsList {
            expanded: creditsTitle.isExpanded
            items: [
                {
                    author: "@StrayRogue",
                    url: "https://x.com/StrayRogue",
                    role: I18n.trFor("bongoCat", "Creator of the original Bongo Cat artwork."),
                    icon: "brush"
                },
                {
                    author: "StrawberryMatchaArt",
                    url: "https://www.etsy.com/shop/StrawberryMatchaArt",
                    role: I18n.trFor("bongoCat", "Creator of the Pixel Doodle Bongo Cat artwork."),
                    icon: "palette"
                }
            ]
        }
    }
}
