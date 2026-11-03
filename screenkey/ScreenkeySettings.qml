import QtQuick
import QtQuick.Controls
import Quickshell
import qs.Common
import qs.Modules.Plugins
import "./shared"

PluginSettings {
    id: root

    pluginId: "screenkey"

    // Keyboard devices scanned dynamically
    property var deviceOptions: [{ label: "All Keyboards (Auto)", value: "all" }]

    Component.onCompleted: {
        scanDevices();
    }

    function scanDevices() {
        InputDeviceScanner.scanKeyboards("screenkey.scanDevices", (devices) => {
            const options = [{ label: "All Keyboards (Auto)", value: "all" }];
            for (let i = 0; i < devices.length; i++) {
                options.push(devices[i]);
            }
            root.deviceOptions = options;
        });
    }

    SettingsCard {
        id: generalSection
        SectionTitle {
            text: I18n.trFor("screenkey", "General Settings")
            icon: "tune"
            showReset: enabledSetting.isDirty || clickThroughSetting.isDirty || fadeTimeoutSetting.isDirty || fontSizeSetting.isDirty
            onResetClicked: {
                enabledSetting.resetToDefault();
                clickThroughSetting.resetToDefault();
                fadeTimeoutSetting.resetToDefault();
                fontSizeSetting.resetToDefault();
            }
        }

        ToggleSettingPlus {
            id: enabledSetting
            settingKey: "visualizerEnabled"
            label: I18n.trFor("screenkey", "Enable Visualizer")
            defaultValue: true
        }

        Separator {}

        ToggleSettingPlus {
            id: clickThroughSetting
            settingKey: "clickThrough"
            label: I18n.trFor("screenkey", "Click-through")
            description: I18n.trFor("screenkey", "Allow mouse clicks to pass through the overlay to underlying windows")
            defaultValue: true
        }

        Separator {}

        SliderSettingPlus {
            id: fadeTimeoutSetting
            settingKey: "fadeTimeout"
            label: I18n.trFor("screenkey", "Fade Timeout")
            description: I18n.trFor("screenkey", "Inactivity duration before overlay disappears")
            minimum: 500
            maximum: 5000
            defaultValue: 1500
            unit: "ms"
            leftLabel: "500ms"
            rightLabel: "5000ms"
        }

        Separator {}

        SliderSettingPlus {
            id: fontSizeSetting
            settingKey: "fontSize"
            label: I18n.trFor("screenkey", "Font Size")
            minimum: 16
            maximum: 64
            defaultValue: 24
            unit: "px"
            leftLabel: "16px"
            rightLabel: "64px"
        }
    }

    SettingsCard {
        id: layoutSection
        SectionTitle {
            text: I18n.trFor("screenkey", "Layout & Animations")
            icon: "display_settings"
            showReset: positionSetting.isDirty || entryAnimationSetting.isDirty || exitAnimationSetting.isDirty || keycapStyleSetting.isDirty || roundedKeycapsSetting.isDirty || overlayOpacitySetting.isDirty || marginSizeSetting.isDirty || charLimitSetting.isDirty || textColorSetting.isDirty || keycapTextColorSetting.isDirty || historyLimitSetting.isDirty || bgColorSetting.isDirty || customSeparatorSetting.isDirty
            onResetClicked: {
                positionSetting.resetToDefault();
                entryAnimationSetting.resetToDefault();
                exitAnimationSetting.resetToDefault();
                keycapStyleSetting.resetToDefault();
                roundedKeycapsSetting.resetToDefault();
                overlayOpacitySetting.resetToDefault();
                marginSizeSetting.resetToDefault();
                charLimitSetting.resetToDefault();
                textColorSetting.resetToDefault();
                keycapTextColorSetting.resetToDefault();
                historyLimitSetting.resetToDefault();
                bgColorSetting.resetToDefault();
                customSeparatorSetting.resetToDefault();
            }
        }

        SelectionSettingPlus {
            id: positionSetting
            settingKey: "position"
            label: I18n.trFor("screenkey", "Display Position")
            options: [
                { label: I18n.trFor("screenkey", "Top Left"), value: "top_left" },
                { label: I18n.trFor("screenkey", "Top Center"), value: "top_center" },
                { label: I18n.trFor("screenkey", "Top Right"), value: "top_right" },
                { label: I18n.trFor("screenkey", "Bottom Left"), value: "bottom_left" },
                { label: I18n.trFor("screenkey", "Bottom Center"), value: "bottom_center" },
                { label: I18n.trFor("screenkey", "Bottom Right"), value: "bottom_right" }
            ]
            defaultValue: "bottom_center"
        }

        Separator {}

        ButtonGroupSettingPlus {
            id: entryAnimationSetting
            settingKey: "entryAnimation"
            label: I18n.trFor("screenkey", "Entry Animation")
            options: [
                { label: I18n.trFor("screenkey", "Zoom"), value: "zoom" },
                { label: I18n.trFor("screenkey", "Fade Only"), value: "fade" },
                { label: I18n.trFor("screenkey", "None"), value: "none" }
            ]
            defaultValue: "none"
        }

        ButtonGroupSettingPlus {
            id: exitAnimationSetting
            settingKey: "exitAnimation"
            label: I18n.trFor("screenkey", "Exit Animation")
            options: [
                { label: I18n.trFor("screenkey", "Zoom"), value: "zoom" },
                { label: I18n.trFor("screenkey", "Fade Only"), value: "fade" },
                { label: I18n.trFor("screenkey", "None"), value: "none" }
            ]
            defaultValue: "none"
        }

        SelectionSettingPlus {
            id: keycapStyleSetting
            settingKey: "keycapStyle"
            label: I18n.trFor("screenkey", "Keycap Style")
            description: I18n.trFor("screenkey", "Visual style for rendered keycaps (Default, Laptop, Low Profile, PBT, Minimal)")
            options: [
                { label: I18n.trFor("screenkey", "Default"), value: "default" },
                { label: I18n.trFor("screenkey", "Laptop"), value: "laptop" },
                { label: I18n.trFor("screenkey", "Low Profile"), value: "lowprofile" },
                { label: I18n.trFor("screenkey", "PBT"), value: "pbt" },
                { label: I18n.trFor("screenkey", "Minimal"), value: "minimal" }
            ]
            defaultValue: "default"
        }

        Separator {}

        ToggleSettingPlus {
            id: roundedKeycapsSetting
            settingKey: "roundedKeycaps"
            label: I18n.trFor("screenkey", "Rounded Keycap Corners")
            defaultValue: true
        }

        Separator {}

        SliderSettingPlus {
            id: overlayOpacitySetting
            settingKey: "overlayOpacity"
            label: I18n.trFor("screenkey", "Overlay Opacity")
            minimum: 10
            maximum: 100
            defaultValue: 90
            unit: "%"
            leftLabel: "10%"
            rightLabel: "100%"
        }

        Separator {}

        SliderSettingPlus {
            id: marginSizeSetting
            settingKey: "marginSize"
            label: I18n.trFor("screenkey", "Screen Margin")
            description: I18n.trFor("screenkey", "Adjust the distance of the overlay from screen edges")
            minimum: 0
            maximum: 100
            defaultValue: 24
            unit: "px"
            leftLabel: "0px"
            rightLabel: "100px"
        }

        Separator {}

        SliderSettingPlus {
            id: charLimitSetting
            settingKey: "charLimit"
            label: I18n.trFor("screenkey", "Normal Typing Limit")
            description: I18n.trFor("screenkey", "Maximum characters buffer shown for normal text")
            minimum: 5
            maximum: 50
            defaultValue: 20
            unit: "chars"
            leftLabel: "5"
            rightLabel: "50"
        }

        Separator {}

        SliderSettingPlus {
            id: historyLimitSetting
            settingKey: "historyLimit"
            label: I18n.trFor("screenkey", "Keystroke History Limit")
            description: I18n.trFor("screenkey", "Number of lines to display for keystroke history")
            minimum: 1
            maximum: 5
            defaultValue: 1
            unit: "lines"
            leftLabel: "1"
            rightLabel: "5"
        }

        Separator {}

        ColorSettingPlus {
            id: textColorSetting
            settingKey: "textColor"
            label: I18n.trFor("screenkey", "Normal Text Color")
            defaultValue: "primary"
        }

        Separator {}

        ColorSettingPlus {
            id: keycapTextColorSetting
            settingKey: "keycapTextColor"
            label: I18n.trFor("screenkey", "Keycap & Mouse Color")
            defaultValue: "primary"
        }

        Separator {}

        ColorSettingPlus {
            id: bgColorSetting
            settingKey: "bgColor"
            label: I18n.trFor("screenkey", "Overlay Background Color")
            defaultValue: "#1e2326"
        }

        Separator {}

        StringSettingPlus {
            id: customSeparatorSetting
            settingKey: "customSeparator"
            label: I18n.trFor("screenkey", "Custom Separator")
            description: I18n.trFor("screenkey", "Connector character between shortcut keys (e.g. +, -, ➔)")
            defaultValue: "+"
            placeholder: "+"
        }
    }

    SettingsCard {
        id: visibilitySection
        SectionTitle {
            text: I18n.trFor("screenkey", "Visibility Options")
            icon: "visibility"
            showReset: showShortcutsSetting.isDirty || macSymbolsSetting.isDirty || showModifierStatusSetting.isDirty || showOnlyModifiersSetting.isDirty || ignoreFilterKeysSetting.isDirty || showNormalKeysSetting.isDirty || showMouseClicksSetting.isDirty
            onResetClicked: {
                showShortcutsSetting.resetToDefault();
                macSymbolsSetting.resetToDefault();
                showModifierStatusSetting.resetToDefault();
                showOnlyModifiersSetting.resetToDefault();
                ignoreFilterKeysSetting.resetToDefault();
                showNormalKeysSetting.resetToDefault();
                showMouseClicksSetting.resetToDefault();
            }
        }

        ToggleSettingPlus {
            id: showShortcutsSetting
            settingKey: "showShortcuts"
            label: I18n.trFor("screenkey", "Show Key Combinations")
            description: I18n.trFor("screenkey", "Toggle to display modifier shortcuts (e.g., Ctrl + Alt + T)")
            defaultValue: true
        }

        Separator {}

        ToggleSettingPlus {
            id: macSymbolsSetting
            settingKey: "macSymbols"
            label: I18n.trFor("screenkey", "Use macOS Symbols")
            description: I18n.trFor("screenkey", "Toggle to display modifiers and control keys as macOS symbols (e.g. ⌘, ⌥, ⇧, ⌃, ⏎)")
            defaultValue: false
        }

        Separator {}

        ToggleSettingPlus {
            id: showModifierStatusSetting
            settingKey: "showModifierStatus"
            label: I18n.trFor("screenkey", "Show Held Modifiers")
            description: I18n.trFor("screenkey", "Show a real-time status bar of active modifier keys currently being held down")
            defaultValue: false
        }

        Separator {}

        ToggleSettingPlus {
            id: showOnlyModifiersSetting
            settingKey: "showOnlyModifiers"
            label: I18n.trFor("screenkey", "Show Standalone Modifiers")
            description: I18n.trFor("screenkey", "Toggle to display modifiers like Ctrl or Shift when pressed alone")
            defaultValue: false
        }

        Separator {}

        ToggleSettingPlus {
            id: ignoreFilterKeysSetting
            settingKey: "ignoreFilterKeys"
            label: I18n.trFor("screenkey", "Ignore Lock Keys")
            description: I18n.trFor("screenkey", "Ignore system lock keys (CapsLock, NumLock, ScrollLock) to avoid noise")
            defaultValue: true
        }

        Separator {}

        ToggleSettingPlus {
            id: showNormalKeysSetting
            settingKey: "showNormalKeys"
            label: I18n.trFor("screenkey", "Show Normal Keystrokes")
            description: I18n.trFor("screenkey", "Toggle to display normal letters instead of just modifier shortcuts")
            defaultValue: false
        }

        Separator {}

        ToggleSettingPlus {
            id: showMouseClicksSetting
            settingKey: "showMouseClicks"
            label: I18n.trFor("screenkey", "Show Mouse Clicks")
            defaultValue: false
        }
    }

    SettingsCard {
        id: deviceSection
        SectionTitle {
            text: I18n.trFor("screenkey", "Input Device")
            icon: "keyboard"
            showReset: selectedDevicePathSetting.isDirty
            onResetClicked: {
                selectedDevicePathSetting.resetToDefault();
            }
        }

        SelectionSettingPlus {
            id: selectedDevicePathSetting
            settingKey: "selectedDevicePath"
            label: I18n.trFor("screenkey", "Keyboard Device")
            options: root.deviceOptions
            defaultValue: "all"
        }
    }

    SettingsCard {
        id: ipcSection
        SectionTitle {
            id: ipcTitle
            text: I18n.trFor("screenkey", "IPC Commands")
            icon: "terminal"
            collapsible: true
            settingKey: "ipcCommandsExpanded"
        }

        Column {
            width: parent.width
            spacing: Theme.spacingS
            visible: ipcTitle.isExpanded

            Repeater {
                model: [
                    { text: "dms ipc screenkey toggle", label: I18n.trFor("screenkey", "Toggle visualizer") },
                    { text: "dms ipc screenkey enable", label: I18n.trFor("screenkey", "Enable visualizer") },
                    { text: "dms ipc screenkey disable", label: I18n.trFor("screenkey", "Disable visualizer") }
                ]

                delegate: CopyBox {
                    label: modelData.label
                    text: modelData.text
                }
            }
        }
    }

    SettingsCard {
        SectionTitle {
            id: usageTitle
            text: I18n.trFor("screenkey", "Usage Guide")
            icon: "menu_book"
            collapsible: true
            settingKey: "usageGuideExpanded"
        }

        UsageGuide {
            expanded: usageTitle.isExpanded
            items: [
                I18n.trFor("screenkey", "Displays keystrokes on an always-on-top floating screen overlay."),
                I18n.trFor("screenkey", "Key combinations are rendered as visual keycaps, and standard typing as stream text."),
                I18n.trFor("screenkey", "Ensure your user belongs to the <b>input</b> group to read keyboard events without root.")
            ]
        }
    }

    SettingsCard {
        SectionTitle {
            id: creditsTitle
            text: I18n.trFor("screenkey", "Credits")
            icon: "favorite"
            collapsible: true
            settingKey: "creditsExpanded"
        }

        CreditsList {
            expanded: creditsTitle.isExpanded
            items: [
                {
                    author: "@Tz-slayer",
                    url: "https://github.com/Tz-slayer/keystrokes",
                    role: I18n.trFor("screenkey", "Keycap styles (Laptop, Low Profile, PBT, Minimal) and icon system ported from <b>keystrokes</b>."),
                    icon: "keyboard"
                },
                {
                    author: "@mulaRahul",
                    url: "https://github.com/mulaRahul/keyviz",
                    role: I18n.trFor("screenkey", "Original visual design and keycap styling inspired by <b>keyviz</b>."),
                    icon: "palette"
                }
            ]
        }
    }
}
