import QtQuick
import qs.Common
import qs.DCommon.Widgets
import qs.Modules.Plugins
import qs.Modules.Settings.Widgets
import "./shared"

PluginSettings {
    id: root
    pluginId: "screenkey"

    readonly property bool defaultVisualizerEnabled: true
    readonly property bool defaultClickThrough: true
    readonly property int defaultFadeTimeout: 1500
    readonly property int defaultFontSize: 24
    readonly property string defaultPosition: "bottom_center"
    readonly property string defaultEntryAnimation: "none"
    readonly property string defaultExitAnimation: "none"
    readonly property string defaultKeycapStyle: "default"
    readonly property bool defaultRoundedKeycaps: true
    readonly property int defaultOverlayOpacity: 90
    readonly property int defaultMarginSize: 24
    readonly property int defaultCharLimit: 20
    readonly property int defaultHistoryLimit: 1
    readonly property string defaultCustomSeparator: "+"
    readonly property bool defaultShowShortcuts: true
    readonly property bool defaultMacSymbols: false
    readonly property bool defaultShowModifierStatus: false
    readonly property bool defaultShowOnlyModifiers: false
    readonly property bool defaultIgnoreFilterKeys: true
    readonly property bool defaultShowNormalKeys: false
    readonly property bool defaultShowMouseClicks: false
    readonly property string defaultSelectedDevicePath: "all"

    property bool visualizerEnabled: defaultVisualizerEnabled
    property bool clickThrough: defaultClickThrough
    property int fadeTimeout: defaultFadeTimeout
    property int fontSize: defaultFontSize
    property string position: defaultPosition
    property string entryAnimation: defaultEntryAnimation
    property string exitAnimation: defaultExitAnimation
    property string keycapStyle: defaultKeycapStyle
    property bool roundedKeycaps: defaultRoundedKeycaps
    property int overlayOpacity: defaultOverlayOpacity
    property int marginSize: defaultMarginSize
    property int charLimit: defaultCharLimit
    property int historyLimit: defaultHistoryLimit
    property string customSeparator: defaultCustomSeparator
    property bool showShortcuts: defaultShowShortcuts
    property bool macSymbols: defaultMacSymbols
    property bool showModifierStatus: defaultShowModifierStatus
    property bool showOnlyModifiers: defaultShowOnlyModifiers
    property bool ignoreFilterKeys: defaultIgnoreFilterKeys
    property bool showNormalKeys: defaultShowNormalKeys
    property bool showMouseClicks: defaultShowMouseClicks
    property string selectedDevicePath: defaultSelectedDevicePath

    property var deviceLabels: ["All Keyboards (Auto)"]
    property var deviceValues: ["all"]

    function loadSettings() {
        if (!pluginService)
            return;
        visualizerEnabled = loadValue("visualizerEnabled", defaultVisualizerEnabled);
        clickThrough = loadValue("clickThrough", defaultClickThrough);
        fadeTimeout = loadValue("fadeTimeout", defaultFadeTimeout);
        fontSize = loadValue("fontSize", defaultFontSize);
        position = loadValue("position", defaultPosition);
        entryAnimation = loadValue("entryAnimation", defaultEntryAnimation);
        exitAnimation = loadValue("exitAnimation", defaultExitAnimation);
        keycapStyle = loadValue("keycapStyle", defaultKeycapStyle);
        roundedKeycaps = loadValue("roundedKeycaps", defaultRoundedKeycaps);
        overlayOpacity = loadValue("overlayOpacity", defaultOverlayOpacity);
        marginSize = loadValue("marginSize", defaultMarginSize);
        charLimit = loadValue("charLimit", defaultCharLimit);
        historyLimit = loadValue("historyLimit", defaultHistoryLimit);
        customSeparator = loadValue("customSeparator", defaultCustomSeparator);
        showShortcuts = loadValue("showShortcuts", defaultShowShortcuts);
        macSymbols = loadValue("macSymbols", defaultMacSymbols);
        showModifierStatus = loadValue("showModifierStatus", defaultShowModifierStatus);
        showOnlyModifiers = loadValue("showOnlyModifiers", defaultShowOnlyModifiers);
        ignoreFilterKeys = loadValue("ignoreFilterKeys", defaultIgnoreFilterKeys);
        showNormalKeys = loadValue("showNormalKeys", defaultShowNormalKeys);
        showMouseClicks = loadValue("showMouseClicks", defaultShowMouseClicks);
        selectedDevicePath = loadValue("selectedDevicePath", defaultSelectedDevicePath);
        ipcSection.expanded = loadValue("ipcCommandsExpanded", true);
        usageSection.expanded = loadValue("usageGuideExpanded", true);
        creditsSection.expanded = loadValue("creditsExpanded", true);
    }

    function scanDevices() {
        InputDeviceScanner.scanKeyboards("screenkey.scanDevices", (devices) => {
            const labels = ["All Keyboards (Auto)"];
            const values = ["all"];
            for (let i = 0; i < devices.length; i++) {
                labels.push(devices[i].label);
                values.push(devices[i].value);
            }
            root.deviceLabels = labels;
            root.deviceValues = values;
        });
    }

    Component.onCompleted: {
        loadSettings();
        scanDevices();
    }
    onPluginServiceChanged: loadSettings()

    Column {
        width: parent ? parent.width : 0
        spacing: 0

        SettingsSectionLabel {
            width: parent.width
            text: I18n.trFor("screenkey", "Visualizer")
        }

        SettingsGroup {
            width: parent.width
            slotColor: SettingsMetrics.controlColor

            SettingsToggleRow {
                text: I18n.trFor("screenkey", "Enable Visualizer")
                checked: root.visualizerEnabled
                modified: root.visualizerEnabled !== root.defaultVisualizerEnabled
                resetByKeys: false
                onResetRequested: {
                    root.visualizerEnabled = root.defaultVisualizerEnabled;
                    root.saveValue("visualizerEnabled", root.defaultVisualizerEnabled);
                }
                onToggled: isChecked => {
                    root.visualizerEnabled = isChecked;
                    root.saveValue("visualizerEnabled", isChecked);
                }
            }

            SettingsToggleRow {
                text: I18n.trFor("screenkey", "Click-through")
                description: I18n.trFor("screenkey", "Allow mouse clicks to pass through the overlay to underlying windows")
                checked: root.clickThrough
                modified: root.clickThrough !== root.defaultClickThrough
                resetByKeys: false
                onResetRequested: {
                    root.clickThrough = root.defaultClickThrough;
                    root.saveValue("clickThrough", root.defaultClickThrough);
                }
                onToggled: isChecked => {
                    root.clickThrough = isChecked;
                    root.saveValue("clickThrough", isChecked);
                }
            }

            SettingsSliderRow {
                text: I18n.trFor("screenkey", "Fade Timeout")
                description: I18n.trFor("screenkey", "Inactivity duration before overlay disappears")
                minimum: 500
                maximum: 5000
                step: 100
                unit: "ms"
                value: root.fadeTimeout
                modified: root.fadeTimeout !== root.defaultFadeTimeout
                resetByKeys: false
                onResetRequested: {
                    root.fadeTimeout = root.defaultFadeTimeout;
                    root.saveValue("fadeTimeout", root.defaultFadeTimeout);
                }
                onSliderDragFinished: finalValue => {
                    root.fadeTimeout = finalValue;
                    root.saveValue("fadeTimeout", finalValue);
                }
            }

            SettingsSliderRow {
                text: I18n.trFor("screenkey", "Font Size")
                minimum: 16
                maximum: 64
                step: 1
                unit: "px"
                value: root.fontSize
                modified: root.fontSize !== root.defaultFontSize
                resetByKeys: false
                onResetRequested: {
                    root.fontSize = root.defaultFontSize;
                    root.saveValue("fontSize", root.defaultFontSize);
                }
                onSliderDragFinished: finalValue => {
                    root.fontSize = finalValue;
                    root.saveValue("fontSize", finalValue);
                }
            }
        }
    }

    Column {
        width: parent ? parent.width : 0
        spacing: 0

        SettingsSectionLabel {
            width: parent.width
            text: I18n.trFor("screenkey", "Layout & Animations")
        }

        SettingsGroup {
            width: parent.width
            slotColor: SettingsMetrics.controlColor

            SettingsDropdownRow {
                text: I18n.trFor("screenkey", "Display Position")
                options: [
                    I18n.trFor("screenkey", "Top Left"),
                    I18n.trFor("screenkey", "Top Center"),
                    I18n.trFor("screenkey", "Top Right"),
                    I18n.trFor("screenkey", "Bottom Left"),
                    I18n.trFor("screenkey", "Bottom Center"),
                    I18n.trFor("screenkey", "Bottom Right")
                ]
                optionValues: ["top_left", "top_center", "top_right", "bottom_left", "bottom_center", "bottom_right"]
                currentValue: root.position
                modified: root.position !== root.defaultPosition
                resetByKeys: false
                onResetRequested: {
                    root.position = root.defaultPosition;
                    root.saveValue("position", root.defaultPosition);
                }
                onValueChanged: newValue => {
                    root.position = newValue;
                    root.saveValue("position", newValue);
                }
            }

            SettingsButtonGroupRow {
                text: I18n.trFor("screenkey", "Entry Animation")
                model: [
                    I18n.trFor("screenkey", "Zoom"),
                    I18n.trFor("screenkey", "Fade Only"),
                    I18n.trFor("screenkey", "None")
                ]
                values: ["zoom", "fade", "none"]
                value: root.entryAnimation
                modified: root.entryAnimation !== root.defaultEntryAnimation
                resetByKeys: false
                onResetRequested: {
                    root.entryAnimation = root.defaultEntryAnimation;
                    root.saveValue("entryAnimation", root.defaultEntryAnimation);
                }
                onValueSelected: newValue => {
                    root.entryAnimation = newValue;
                    root.saveValue("entryAnimation", newValue);
                }
            }

            SettingsButtonGroupRow {
                text: I18n.trFor("screenkey", "Exit Animation")
                model: [
                    I18n.trFor("screenkey", "Zoom"),
                    I18n.trFor("screenkey", "Fade Only"),
                    I18n.trFor("screenkey", "None")
                ]
                values: ["zoom", "fade", "none"]
                value: root.exitAnimation
                modified: root.exitAnimation !== root.defaultExitAnimation
                resetByKeys: false
                onResetRequested: {
                    root.exitAnimation = root.defaultExitAnimation;
                    root.saveValue("exitAnimation", root.defaultExitAnimation);
                }
                onValueSelected: newValue => {
                    root.exitAnimation = newValue;
                    root.saveValue("exitAnimation", newValue);
                }
            }

            SettingsDropdownRow {
                text: I18n.trFor("screenkey", "Keycap Style")
                description: I18n.trFor("screenkey", "Visual style for rendered keycaps (Default, Laptop, Low Profile, PBT, Minimal)")
                options: [
                    I18n.trFor("screenkey", "Default"),
                    I18n.trFor("screenkey", "Laptop"),
                    I18n.trFor("screenkey", "Low Profile"),
                    I18n.trFor("screenkey", "PBT"),
                    I18n.trFor("screenkey", "Minimal")
                ]
                optionValues: ["default", "laptop", "lowprofile", "pbt", "minimal"]
                currentValue: root.keycapStyle
                modified: root.keycapStyle !== root.defaultKeycapStyle
                resetByKeys: false
                onResetRequested: {
                    root.keycapStyle = root.defaultKeycapStyle;
                    root.saveValue("keycapStyle", root.defaultKeycapStyle);
                }
                onValueChanged: newValue => {
                    root.keycapStyle = newValue;
                    root.saveValue("keycapStyle", newValue);
                }
            }

            SettingsToggleRow {
                text: I18n.trFor("screenkey", "Rounded Keycap Corners")
                checked: root.roundedKeycaps
                modified: root.roundedKeycaps !== root.defaultRoundedKeycaps
                resetByKeys: false
                onResetRequested: {
                    root.roundedKeycaps = root.defaultRoundedKeycaps;
                    root.saveValue("roundedKeycaps", root.defaultRoundedKeycaps);
                }
                onToggled: isChecked => {
                    root.roundedKeycaps = isChecked;
                    root.saveValue("roundedKeycaps", isChecked);
                }
            }

            SettingsSliderRow {
                text: I18n.trFor("screenkey", "Overlay Opacity")
                minimum: 10
                maximum: 100
                step: 5
                unit: "%"
                value: root.overlayOpacity
                modified: root.overlayOpacity !== root.defaultOverlayOpacity
                resetByKeys: false
                onResetRequested: {
                    root.overlayOpacity = root.defaultOverlayOpacity;
                    root.saveValue("overlayOpacity", root.defaultOverlayOpacity);
                }
                onSliderDragFinished: finalValue => {
                    root.overlayOpacity = finalValue;
                    root.saveValue("overlayOpacity", finalValue);
                }
            }

            SettingsSliderRow {
                text: I18n.trFor("screenkey", "Screen Margin")
                description: I18n.trFor("screenkey", "Adjust the distance of the overlay from screen edges")
                minimum: 0
                maximum: 100
                step: 1
                unit: "px"
                value: root.marginSize
                modified: root.marginSize !== root.defaultMarginSize
                resetByKeys: false
                onResetRequested: {
                    root.marginSize = root.defaultMarginSize;
                    root.saveValue("marginSize", root.defaultMarginSize);
                }
                onSliderDragFinished: finalValue => {
                    root.marginSize = finalValue;
                    root.saveValue("marginSize", finalValue);
                }
            }

            SettingsSliderRow {
                text: I18n.trFor("screenkey", "Normal Typing Limit")
                description: I18n.trFor("screenkey", "Maximum characters buffer shown for normal text")
                minimum: 5
                maximum: 50
                step: 1
                unit: "chars"
                value: root.charLimit
                modified: root.charLimit !== root.defaultCharLimit
                resetByKeys: false
                onResetRequested: {
                    root.charLimit = root.defaultCharLimit;
                    root.saveValue("charLimit", root.defaultCharLimit);
                }
                onSliderDragFinished: finalValue => {
                    root.charLimit = finalValue;
                    root.saveValue("charLimit", finalValue);
                }
            }

            SettingsSliderRow {
                text: I18n.trFor("screenkey", "Keystroke History Limit")
                description: I18n.trFor("screenkey", "Number of lines to display for keystroke history")
                minimum: 1
                maximum: 5
                step: 1
                unit: "lines"
                value: root.historyLimit
                modified: root.historyLimit !== root.defaultHistoryLimit
                resetByKeys: false
                onResetRequested: {
                    root.historyLimit = root.defaultHistoryLimit;
                    root.saveValue("historyLimit", root.defaultHistoryLimit);
                }
                onSliderDragFinished: finalValue => {
                    root.historyLimit = finalValue;
                    root.saveValue("historyLimit", finalValue);
                }
            }

            ColorSettingPlus {
                id: textColorSetting
                settingKey: "textColor"
                label: I18n.trFor("screenkey", "Normal Text Color")
                defaultValue: "primary"
            }

            ColorSettingPlus {
                id: keycapTextColorSetting
                settingKey: "keycapTextColor"
                label: I18n.trFor("screenkey", "Keycap & Mouse Color")
                defaultValue: "primary"
            }

            ColorSettingPlus {
                id: bgColorSetting
                settingKey: "bgColor"
                label: I18n.trFor("screenkey", "Overlay Background Color")
                defaultValue: "#1e2326"
            }

            SettingsTextFieldRow {
                id: customSeparatorField
                text: I18n.trFor("screenkey", "Custom Separator")
                description: I18n.trFor("screenkey", "Connector character between shortcut keys (e.g. +, -, ➔)")
                placeholderText: "+"
                value: root.customSeparator
                modified: root.customSeparator !== root.defaultCustomSeparator
                resetByKeys: false
                onResetRequested: {
                    root.customSeparator = root.defaultCustomSeparator;
                    customSeparatorField.value = root.defaultCustomSeparator;
                    root.saveValue("customSeparator", root.defaultCustomSeparator);
                }
                onValueEdited: newValue => {
                    root.customSeparator = newValue;
                    root.saveValue("customSeparator", newValue);
                }
            }
        }
    }

    Column {
        width: parent ? parent.width : 0
        spacing: 0

        SettingsSectionLabel {
            width: parent.width
            text: I18n.trFor("screenkey", "Visibility Options")
        }

        SettingsGroup {
            width: parent.width
            slotColor: SettingsMetrics.controlColor

            SettingsToggleRow {
                text: I18n.trFor("screenkey", "Show Key Combinations")
                description: I18n.trFor("screenkey", "Toggle to display modifier shortcuts (e.g., Ctrl + Alt + T)")
                checked: root.showShortcuts
                modified: root.showShortcuts !== root.defaultShowShortcuts
                resetByKeys: false
                onResetRequested: {
                    root.showShortcuts = root.defaultShowShortcuts;
                    root.saveValue("showShortcuts", root.defaultShowShortcuts);
                }
                onToggled: isChecked => {
                    root.showShortcuts = isChecked;
                    root.saveValue("showShortcuts", isChecked);
                }
            }

            SettingsToggleRow {
                text: I18n.trFor("screenkey", "Use macOS Symbols")
                description: I18n.trFor("screenkey", "Toggle to display modifiers and control keys as macOS symbols (e.g. ⌘, ⌥, ⇧, ⌃, ⏎)")
                checked: root.macSymbols
                modified: root.macSymbols !== root.defaultMacSymbols
                resetByKeys: false
                onResetRequested: {
                    root.macSymbols = root.defaultMacSymbols;
                    root.saveValue("macSymbols", root.defaultMacSymbols);
                }
                onToggled: isChecked => {
                    root.macSymbols = isChecked;
                    root.saveValue("macSymbols", isChecked);
                }
            }

            SettingsToggleRow {
                text: I18n.trFor("screenkey", "Show Held Modifiers")
                description: I18n.trFor("screenkey", "Show a real-time status bar of active modifier keys currently being held down")
                checked: root.showModifierStatus
                modified: root.showModifierStatus !== root.defaultShowModifierStatus
                resetByKeys: false
                onResetRequested: {
                    root.showModifierStatus = root.defaultShowModifierStatus;
                    root.saveValue("showModifierStatus", root.defaultShowModifierStatus);
                }
                onToggled: isChecked => {
                    root.showModifierStatus = isChecked;
                    root.saveValue("showModifierStatus", isChecked);
                }
            }

            SettingsToggleRow {
                text: I18n.trFor("screenkey", "Show Standalone Modifiers")
                description: I18n.trFor("screenkey", "Toggle to display modifiers like Ctrl or Shift when pressed alone")
                checked: root.showOnlyModifiers
                modified: root.showOnlyModifiers !== root.defaultShowOnlyModifiers
                resetByKeys: false
                onResetRequested: {
                    root.showOnlyModifiers = root.defaultShowOnlyModifiers;
                    root.saveValue("showOnlyModifiers", root.defaultShowOnlyModifiers);
                }
                onToggled: isChecked => {
                    root.showOnlyModifiers = isChecked;
                    root.saveValue("showOnlyModifiers", isChecked);
                }
            }

            SettingsToggleRow {
                text: I18n.trFor("screenkey", "Ignore Lock Keys")
                description: I18n.trFor("screenkey", "Ignore system lock keys (CapsLock, NumLock, ScrollLock) to avoid noise")
                checked: root.ignoreFilterKeys
                modified: root.ignoreFilterKeys !== root.defaultIgnoreFilterKeys
                resetByKeys: false
                onResetRequested: {
                    root.ignoreFilterKeys = root.defaultIgnoreFilterKeys;
                    root.saveValue("ignoreFilterKeys", root.defaultIgnoreFilterKeys);
                }
                onToggled: isChecked => {
                    root.ignoreFilterKeys = isChecked;
                    root.saveValue("ignoreFilterKeys", isChecked);
                }
            }

            SettingsToggleRow {
                text: I18n.trFor("screenkey", "Show Normal Keystrokes")
                description: I18n.trFor("screenkey", "Toggle to display normal letters instead of just modifier shortcuts")
                checked: root.showNormalKeys
                modified: root.showNormalKeys !== root.defaultShowNormalKeys
                resetByKeys: false
                onResetRequested: {
                    root.showNormalKeys = root.defaultShowNormalKeys;
                    root.saveValue("showNormalKeys", root.defaultShowNormalKeys);
                }
                onToggled: isChecked => {
                    root.showNormalKeys = isChecked;
                    root.saveValue("showNormalKeys", isChecked);
                }
            }

            SettingsToggleRow {
                text: I18n.trFor("screenkey", "Show Mouse Clicks")
                checked: root.showMouseClicks
                modified: root.showMouseClicks !== root.defaultShowMouseClicks
                resetByKeys: false
                onResetRequested: {
                    root.showMouseClicks = root.defaultShowMouseClicks;
                    root.saveValue("showMouseClicks", root.defaultShowMouseClicks);
                }
                onToggled: isChecked => {
                    root.showMouseClicks = isChecked;
                    root.saveValue("showMouseClicks", isChecked);
                }
            }
        }
    }

    Column {
        width: parent ? parent.width : 0
        spacing: 0

        SettingsSectionLabel {
            width: parent.width
            text: I18n.trFor("screenkey", "Input Device")
        }

        SettingsGroup {
            width: parent.width
            slotColor: SettingsMetrics.controlColor

            SettingsDropdownRow {
                text: I18n.trFor("screenkey", "Keyboard Device")
                options: root.deviceLabels
                optionValues: root.deviceValues
                currentValue: root.selectedDevicePath
                modified: root.selectedDevicePath !== root.defaultSelectedDevicePath
                resetByKeys: false
                onResetRequested: {
                    root.selectedDevicePath = root.defaultSelectedDevicePath;
                    root.saveValue("selectedDevicePath", root.defaultSelectedDevicePath);
                }
                onValueChanged: newValue => {
                    root.selectedDevicePath = newValue;
                    root.saveValue("selectedDevicePath", newValue);
                }
            }
        }
    }

    Column {
        id: ipcSection
        width: parent ? parent.width : 0
        spacing: 0

        property bool expanded: true

        SettingsSectionLabel {
            width: parent.width
            text: I18n.trFor("screenkey", "IPC Commands")
            collapsible: true
            expanded: ipcSection.expanded
            onToggleRequested: {
                ipcSection.expanded = !ipcSection.expanded;
                if (root.pluginService)
                    root.saveValue("ipcCommandsExpanded", ipcSection.expanded);
            }
        }

        SettingsGroup {
            width: parent.width
            slotColor: SettingsMetrics.controlColor
            visible: ipcSection.expanded

            Column {
                width: parent.width
                spacing: Theme.spacingS

                Repeater {
                    model: [
                        { text: "dms ipc screenkey toggle", label: I18n.trFor("screenkey", "Toggle visualizer") },
                        { text: "dms ipc screenkey enable", label: I18n.trFor("screenkey", "Enable visualizer") },
                        { text: "dms ipc screenkey disable", label: I18n.trFor("screenkey", "Disable visualizer") }
                    ]

                    delegate: CopyBox {
                        required property var modelData
                        label: modelData.label
                        text: modelData.text
                    }
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
            text: I18n.trFor("screenkey", "How to Use")
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

            Repeater {
                model: [
                    {
                        icon: "layers",
                        title: I18n.trFor("screenkey", "Floating Overlay"),
                        subtitle: I18n.trFor("screenkey", "Displays keystrokes on an always-on-top screen overlay.")
                    },
                    {
                        icon: "keyboard",
                        title: I18n.trFor("screenkey", "Keycaps & Text"),
                        subtitle: I18n.trFor("screenkey", "Renders shortcuts as keycaps and normal typing as stream text.")
                    },
                    {
                        icon: "admin_panel_settings",
                        title: I18n.trFor("screenkey", "Input Group"),
                        subtitle: I18n.trFor("screenkey", "Ensure your user belongs to the input group to read keyboard events without root.")
                    }
                ]

                delegate: SettingsRow {
                    required property var modelData
                    iconName: modelData.icon
                    iconBox: true
                    title: modelData.title
                    subtitle: modelData.subtitle
                }
            }
        }
    }

    Column {
        id: creditsSection
        width: parent ? parent.width : 0
        spacing: 0

        property bool expanded: true

        SettingsSectionLabel {
            width: parent.width
            text: I18n.trFor("screenkey", "Credits")
            collapsible: true
            expanded: creditsSection.expanded
            onToggleRequested: {
                creditsSection.expanded = !creditsSection.expanded;
                if (root.pluginService)
                    root.saveValue("creditsExpanded", creditsSection.expanded);
            }
        }

        SettingsGroup {
            width: parent.width
            slotColor: SettingsMetrics.controlColor
            visible: creditsSection.expanded

            Repeater {
                model: [
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

                delegate: SettingsRow {
                    required property var modelData
                    title: modelData.author
                    subtitle: modelData.role
                    iconName: modelData.icon
                    iconBox: true
                    clickable: true
                    showChevron: true
                    onClicked: Qt.openUrlExternally(modelData.url)
                }
            }
        }
    }
}
