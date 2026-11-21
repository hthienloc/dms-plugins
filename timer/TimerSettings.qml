import QtQuick
import qs.Common
import qs.DCommon.Widgets
import qs.Modals.FileBrowser
import qs.Modules.Plugins
import qs.Modules.Settings.Widgets

PluginSettings {
    id: root
    pluginId: "timer"

    readonly property string defaultPresets: "1, 2, 5, 10, 15, 20, 25, 30, 45, 60, 90, 120"
    readonly property string defaultQuickStartMinutes: "25"
    readonly property bool defaultShowPillIcon: true
    readonly property bool defaultShowReadyPlaceholder: true
    readonly property string defaultDisplayFormat: "full"
    readonly property string defaultTimeoutBehavior: "reset"
    readonly property bool defaultShowNotification: true
    readonly property string defaultNotificationTitle: I18n.trFor("timer", "Timer")
    readonly property string defaultNotificationBody: I18n.trFor("timer", "Timeout!")
    readonly property bool defaultAutoDND: false
    readonly property string defaultSystemActionOnTimeout: "none"
    readonly property string defaultCustomCommandOnTimeout: ""
    readonly property string defaultSoundPath: ""
    readonly property bool defaultUseSystemNotificationSound: true
    readonly property bool defaultShowTimeoutActions: true

    property string presets: defaultPresets
    property string quickStartMinutes: defaultQuickStartMinutes
    property bool showPillIcon: defaultShowPillIcon
    property bool showReadyPlaceholder: defaultShowReadyPlaceholder
    property string displayFormat: defaultDisplayFormat
    property string timeoutBehavior: defaultTimeoutBehavior
    property bool showNotification: defaultShowNotification
    property string notificationTitle: defaultNotificationTitle
    property string notificationBody: defaultNotificationBody
    property bool autoDND: defaultAutoDND
    property string systemActionOnTimeout: defaultSystemActionOnTimeout
    property string customCommandOnTimeout: defaultCustomCommandOnTimeout
    property string soundPath: defaultSoundPath
    property bool useSystemNotificationSound: defaultUseSystemNotificationSound
    property bool showTimeoutActions: defaultShowTimeoutActions

    function cleanPath(path) {
        if (!path)
            return "";
        return String(path).replace(/^file:\/\//, "");
    }

    function loadSettings() {
        if (!pluginService)
            return;
        presets = loadValue("presets", defaultPresets);
        quickStartMinutes = loadValue("quickStartMinutes", defaultQuickStartMinutes);
        showPillIcon = loadValue("showPillIcon", defaultShowPillIcon);
        showReadyPlaceholder = loadValue("showReadyPlaceholder", defaultShowReadyPlaceholder);
        displayFormat = loadValue("displayFormat", defaultDisplayFormat);
        timeoutBehavior = loadValue("timeoutBehavior", defaultTimeoutBehavior);
        showNotification = loadValue("showNotification", defaultShowNotification);
        notificationTitle = loadValue("notificationTitle", defaultNotificationTitle);
        notificationBody = loadValue("notificationBody", defaultNotificationBody);
        autoDND = loadValue("autoDND", defaultAutoDND);
        systemActionOnTimeout = loadValue("systemActionOnTimeout", defaultSystemActionOnTimeout);
        customCommandOnTimeout = loadValue("customCommandOnTimeout", defaultCustomCommandOnTimeout);
        soundPath = loadValue("soundPath", defaultSoundPath);
        useSystemNotificationSound = loadValue("useSystemNotificationSound", defaultUseSystemNotificationSound);
        showTimeoutActions = loadValue("showTimeoutActions", defaultShowTimeoutActions);
        usageSection.expanded = loadValue("usageGuideExpanded", true);
    }

    Component.onCompleted: loadSettings()
    onPluginServiceChanged: loadSettings()

    Column {
        width: parent ? parent.width : 0
        spacing: 0

        SettingsSectionLabel {
            width: parent.width
            text: I18n.trFor("timer", "Presets")
        }

        SettingsGroup {
            width: parent.width
            slotColor: SettingsMetrics.controlColor

            SettingsTextFieldRow {
                id: presetsField
                text: I18n.trFor("timer", "Quick Presets")
                description: I18n.trFor("timer", "Comma-separated list of minutes for quick start buttons.")
                placeholderText: "1, 2, 5, 10, 15, 20, 25, 30, 45, 60, 90, 120"
                value: root.presets
                modified: root.presets !== root.defaultPresets
                resetByKeys: false
                onResetRequested: {
                    root.presets = root.defaultPresets;
                    presetsField.value = root.defaultPresets;
                    root.saveValue("presets", root.defaultPresets);
                }
                onValueEdited: newValue => {
                    root.presets = newValue;
                    root.saveValue("presets", newValue);
                }
            }

            SettingsTextFieldRow {
                id: quickStartMinutesField
                text: I18n.trFor("timer", "Right-Click Quick Start")
                description: I18n.trFor("timer", "The duration in minutes to start when right-clicking the icon in Ready state.")
                placeholderText: "25"
                value: root.quickStartMinutes
                modified: root.quickStartMinutes !== root.defaultQuickStartMinutes
                resetByKeys: false
                onResetRequested: {
                    root.quickStartMinutes = root.defaultQuickStartMinutes;
                    quickStartMinutesField.value = root.defaultQuickStartMinutes;
                    root.saveValue("quickStartMinutes", root.defaultQuickStartMinutes);
                }
                onValueEdited: newValue => {
                    root.quickStartMinutes = newValue;
                    root.saveValue("quickStartMinutes", newValue);
                }
            }
        }
    }

    Column {
        width: parent ? parent.width : 0
        spacing: 0

        SettingsSectionLabel {
            width: parent.width
            text: I18n.trFor("timer", "Display")
        }

        SettingsGroup {
            width: parent.width
            slotColor: SettingsMetrics.controlColor

            SettingsToggleRow {
                text: I18n.trFor("timer", "Show Icon")
                checked: root.showPillIcon
                modified: root.showPillIcon !== root.defaultShowPillIcon
                resetByKeys: false
                onResetRequested: {
                    root.showPillIcon = root.defaultShowPillIcon;
                    root.saveValue("showPillIcon", root.defaultShowPillIcon);
                }
                onToggled: isChecked => {
                    root.showPillIcon = isChecked;
                    root.saveValue("showPillIcon", isChecked);
                }
            }

            SettingsToggleRow {
                text: I18n.trFor("timer", "Show Ready Placeholder")
                description: I18n.trFor("timer", "Show placeholder digits/text when the timer is in the ready state.")
                checked: root.showReadyPlaceholder
                modified: root.showReadyPlaceholder !== root.defaultShowReadyPlaceholder
                resetByKeys: false
                onResetRequested: {
                    root.showReadyPlaceholder = root.defaultShowReadyPlaceholder;
                    root.saveValue("showReadyPlaceholder", root.defaultShowReadyPlaceholder);
                }
                onToggled: isChecked => {
                    root.showReadyPlaceholder = isChecked;
                    root.saveValue("showReadyPlaceholder", isChecked);
                }
            }

            SettingsDropdownRow {
                text: I18n.trFor("timer", "Display Content")
                options: [
                    "00:00:00",
                    I18n.trFor("timer", "1h 5m 10s"),
                    I18n.trFor("timer", "5m 10s"),
                    I18n.trFor("timer", "Progress Bar"),
                    I18n.trFor("timer", "Icon Only"),
                    I18n.trFor("timer", "Pulse Dot ✦")
                ]
                optionValues: ["full", "compact", "minimal", "progress", "icon", "pulse"]
                currentValue: root.displayFormat
                modified: root.displayFormat !== root.defaultDisplayFormat
                resetByKeys: false
                onResetRequested: {
                    root.displayFormat = root.defaultDisplayFormat;
                    root.saveValue("displayFormat", root.defaultDisplayFormat);
                }
                onValueChanged: newValue => {
                    root.displayFormat = newValue;
                    root.saveValue("displayFormat", newValue);
                }
            }
        }
    }

    Column {
        width: parent ? parent.width : 0
        spacing: 0

        SettingsSectionLabel {
            width: parent.width
            text: I18n.trFor("timer", "Notifications")
        }

        SettingsGroup {
            width: parent.width
            slotColor: SettingsMetrics.controlColor

            SettingsButtonGroupRow {
                text: I18n.trFor("timer", "When Finished")
                model: [
                    I18n.trFor("timer", "Stay at Finished"),
                    I18n.trFor("timer", "Reset to Ready")
                ]
                values: ["stay", "reset"]
                value: root.timeoutBehavior
                modified: root.timeoutBehavior !== root.defaultTimeoutBehavior
                resetByKeys: false
                onResetRequested: {
                    root.timeoutBehavior = root.defaultTimeoutBehavior;
                    root.saveValue("timeoutBehavior", root.defaultTimeoutBehavior);
                }
                onValueSelected: newValue => {
                    root.timeoutBehavior = newValue;
                    root.saveValue("timeoutBehavior", newValue);
                }
            }

            SettingsToggleRow {
                text: I18n.trFor("timer", "Show Desktop Notification")
                checked: root.showNotification
                modified: root.showNotification !== root.defaultShowNotification
                resetByKeys: false
                onResetRequested: {
                    root.showNotification = root.defaultShowNotification;
                    root.saveValue("showNotification", root.defaultShowNotification);
                }
                onToggled: isChecked => {
                    root.showNotification = isChecked;
                    root.saveValue("showNotification", isChecked);
                }
            }

            SettingsTextFieldRow {
                id: notificationTitleField
                visible: root.showNotification
                text: I18n.trFor("timer", "Notification Title")
                placeholderText: I18n.trFor("timer", "Timer")
                value: root.notificationTitle
                modified: root.notificationTitle !== root.defaultNotificationTitle
                resetByKeys: false
                onResetRequested: {
                    root.notificationTitle = root.defaultNotificationTitle;
                    notificationTitleField.value = root.defaultNotificationTitle;
                    root.saveValue("notificationTitle", root.defaultNotificationTitle);
                }
                onValueEdited: newValue => {
                    root.notificationTitle = newValue;
                    root.saveValue("notificationTitle", newValue);
                }
            }

            SettingsTextFieldRow {
                id: notificationBodyField
                visible: root.showNotification
                text: I18n.trFor("timer", "Notification Body")
                placeholderText: I18n.trFor("timer", "Timeout!")
                value: root.notificationBody
                modified: root.notificationBody !== root.defaultNotificationBody
                resetByKeys: false
                onResetRequested: {
                    root.notificationBody = root.defaultNotificationBody;
                    notificationBodyField.value = root.defaultNotificationBody;
                    root.saveValue("notificationBody", root.defaultNotificationBody);
                }
                onValueEdited: newValue => {
                    root.notificationBody = newValue;
                    root.saveValue("notificationBody", newValue);
                }
            }

            SettingsToggleRow {
                text: I18n.trFor("timer", "Automatically Do Not Disturb")
                description: I18n.trFor("timer", "Toggle Do Not Disturb mode when the timer is active.")
                checked: root.autoDND
                modified: root.autoDND !== root.defaultAutoDND
                resetByKeys: false
                onResetRequested: {
                    root.autoDND = root.defaultAutoDND;
                    root.saveValue("autoDND", root.defaultAutoDND);
                }
                onToggled: isChecked => {
                    root.autoDND = isChecked;
                    root.saveValue("autoDND", isChecked);
                }
            }
        }
    }

    Column {
        width: parent ? parent.width : 0
        spacing: 0

        SettingsSectionLabel {
            width: parent.width
            text: I18n.trFor("timer", "Custom Actions")
        }

        SettingsGroup {
            width: parent.width
            slotColor: SettingsMetrics.controlColor

            SettingsDropdownRow {
                text: I18n.trFor("timer", "Trigger System Action")
                description: I18n.trFor("timer", "Automatically perform a system action when the timer finishes.")
                options: [
                    I18n.trFor("timer", "None"),
                    I18n.trFor("timer", "Lock Screen"),
                    I18n.trFor("timer", "Suspend"),
                    I18n.trFor("timer", "Hibernate"),
                    I18n.trFor("timer", "Power Off"),
                    I18n.trFor("timer", "Custom Command")
                ]
                optionValues: ["none", "lock", "suspend", "hibernate", "poweroff", "custom"]
                currentValue: root.systemActionOnTimeout
                modified: root.systemActionOnTimeout !== root.defaultSystemActionOnTimeout
                resetByKeys: false
                onResetRequested: {
                    root.systemActionOnTimeout = root.defaultSystemActionOnTimeout;
                    root.saveValue("systemActionOnTimeout", root.defaultSystemActionOnTimeout);
                }
                onValueChanged: newValue => {
                    root.systemActionOnTimeout = newValue;
                    root.saveValue("systemActionOnTimeout", newValue);
                }
            }

            SettingsTextFieldRow {
                id: customCommandField
                visible: root.systemActionOnTimeout === "custom"
                text: I18n.trFor("timer", "Run Custom Shell Command")
                description: I18n.trFor("timer", "Execute a shell command when the timer finishes.")
                placeholderText: "e.g., systemctl suspend"
                value: root.customCommandOnTimeout
                modified: root.customCommandOnTimeout !== root.defaultCustomCommandOnTimeout
                resetByKeys: false
                onResetRequested: {
                    root.customCommandOnTimeout = root.defaultCustomCommandOnTimeout;
                    customCommandField.value = root.defaultCustomCommandOnTimeout;
                    root.saveValue("customCommandOnTimeout", root.defaultCustomCommandOnTimeout);
                }
                onValueEdited: newValue => {
                    root.customCommandOnTimeout = newValue;
                    root.saveValue("customCommandOnTimeout", newValue);
                }
            }
        }
    }

    Column {
        width: parent ? parent.width : 0
        spacing: 0

        SettingsSectionLabel {
            width: parent.width
            text: I18n.trFor("timer", "Sound")
        }

        SettingsGroup {
            width: parent.width
            slotColor: SettingsMetrics.controlColor

            SettingsTextFieldRow {
                id: soundPathField
                text: I18n.trFor("timer", "Custom Sound Path")
                description: I18n.trFor("timer", "Full path to sound file. Leave empty for default.")
                placeholderText: "/usr/share/sounds/freedesktop/stereo/complete.oga"
                value: root.soundPath
                modified: root.soundPath !== root.defaultSoundPath
                resetByKeys: false
                onResetRequested: {
                    root.soundPath = root.defaultSoundPath;
                    soundPathField.value = root.defaultSoundPath;
                    root.saveValue("soundPath", root.defaultSoundPath);
                }
                onValueEdited: newValue => {
                    root.soundPath = newValue;
                    root.saveValue("soundPath", newValue);
                }
                actions: DActionButton {
                    iconName: "folder_open"
                    backgroundColor: Theme.surfaceContainerHigh
                    iconColor: Theme.primary
                    tooltipText: I18n.trFor("timer", "Select File")
                    onClicked: soundBrowserModal.open()
                }
            }

            SettingsToggleRow {
                text: I18n.trFor("timer", "Use System Notification Sound")
                description: I18n.trFor("timer", "Use system's critical notification sound if no path is set.")
                checked: root.useSystemNotificationSound
                modified: root.useSystemNotificationSound !== root.defaultUseSystemNotificationSound
                resetByKeys: false
                onResetRequested: {
                    root.useSystemNotificationSound = root.defaultUseSystemNotificationSound;
                    root.saveValue("useSystemNotificationSound", root.defaultUseSystemNotificationSound);
                }
                onToggled: isChecked => {
                    root.useSystemNotificationSound = isChecked;
                    root.saveValue("useSystemNotificationSound", isChecked);
                }
            }
        }
    }

    Column {
        width: parent ? parent.width : 0
        spacing: 0

        SettingsSectionLabel {
            width: parent.width
            text: I18n.trFor("timer", "Behavior")
        }

        SettingsGroup {
            width: parent.width
            slotColor: SettingsMetrics.controlColor

            SettingsToggleRow {
                text: I18n.trFor("timer", "Show 'When Done' Section")
                checked: root.showTimeoutActions
                modified: root.showTimeoutActions !== root.defaultShowTimeoutActions
                resetByKeys: false
                onResetRequested: {
                    root.showTimeoutActions = root.defaultShowTimeoutActions;
                    root.saveValue("showTimeoutActions", root.defaultShowTimeoutActions);
                }
                onToggled: isChecked => {
                    root.showTimeoutActions = isChecked;
                    root.saveValue("showTimeoutActions", isChecked);
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
            text: I18n.trFor("timer", "How to Use")
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

            Column {
                width: parent.width
                spacing: Theme.spacingS

                Repeater {
                    model: [
                        I18n.trFor("timer", "<b>Left-click</b> the pill to <b>Pause</b> or <b>Resume</b> the timer."),
                        I18n.trFor("timer", "<b>Right-click</b> the pill to <b>Reset</b> (or <b>Quick Start</b> if ready)."),
                        I18n.trFor("timer", "Open the <b>Popout</b> to select presets or enter custom minutes.")
                    ]

                    delegate: Row {
                        required property string modelData
                        width: parent.width
                        spacing: Theme.spacingS

                        StyledText {
                            id: bullet
                            text: "•"
                            color: Theme.primary
                            font.pixelSize: Theme.fontSizeSmall
                            font.weight: Font.Bold
                        }

                        StyledText {
                            width: parent.width - bullet.width - parent.spacing
                            text: modelData
                            color: Theme.surfaceVariantText
                            font.pixelSize: Theme.fontSizeSmall
                            wrapMode: Text.WordWrap
                            textFormat: Text.StyledText
                        }
                    }
                }
            }
        }
    }

    FileBrowserSurfaceModal {
        id: soundBrowserModal
        browserTitle: I18n.trFor("timer", "Custom Sound Path")
        browserType: "file_picker"
        folderMode: false
        saveMode: false
        fileExtensions: [I18n.trFor("timer", "Audio files") + " (*.mp3 *.wav *.ogg *.oga *.flac)", I18n.trFor("timer", "All files") + " (*)"]
        revealPath: root.soundPath !== "" ? root.soundPath : ""
        onAccepted: paths => {
            if (paths && paths.length > 0) {
                const cleaned = root.cleanPath(paths[0]);
                root.soundPath = cleaned;
                soundPathField.value = cleaned;
                root.saveValue("soundPath", cleaned);
            }
        }
    }
}
