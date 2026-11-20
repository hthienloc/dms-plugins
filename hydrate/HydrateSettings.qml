import QtQuick
import qs.Common
import qs.DCommon.Widgets
import qs.Modules.Plugins
import qs.Modules.Settings.Widgets

PluginSettings {
    id: root
    pluginId: "hydrate"

    readonly property int defaultDailyGoal: 2000
    readonly property int defaultInterval: 60
    readonly property string defaultDisplayMode: "full"
    readonly property bool defaultShowHints: true

    property int dailyGoal: defaultDailyGoal
    property int interval: defaultInterval
    property string displayMode: defaultDisplayMode
    property bool showHints: defaultShowHints

    function loadSettings() {
        if (!pluginService)
            return;
        dailyGoal = loadValue("dailyGoal", defaultDailyGoal);
        interval = loadValue("interval", defaultInterval);
        displayMode = loadValue("displayMode", defaultDisplayMode);
        showHints = loadValue("showHints", defaultShowHints);
        usageSection.expanded = loadValue("usageGuideExpanded", true);
    }

    Component.onCompleted: loadSettings()
    onPluginServiceChanged: loadSettings()

    Column {
        width: parent ? parent.width : 0
        spacing: 0

        SettingsSectionLabel {
            width: parent.width
            text: I18n.trFor("hydrate", "Hydration Goals")
        }

        SettingsGroup {
            width: parent.width
            slotColor: SettingsMetrics.controlColor

            SettingsSliderRow {
                text: I18n.trFor("hydrate", "Daily Target")
                description: I18n.trFor("hydrate", "Target water intake per day.")
                minimum: 500
                maximum: 5000
                step: 100
                unit: I18n.trFor("hydrate", " ml")
                value: root.dailyGoal
                modified: root.dailyGoal !== root.defaultDailyGoal
                resetByKeys: false
                onResetRequested: {
                    root.dailyGoal = root.defaultDailyGoal;
                    root.saveValue("dailyGoal", root.defaultDailyGoal);
                }
                onSliderDragFinished: finalValue => {
                    root.dailyGoal = finalValue;
                    root.saveValue("dailyGoal", finalValue);
                }
            }

            SettingsSliderRow {
                text: I18n.trFor("hydrate", "Reminder Interval")
                description: I18n.trFor("hydrate", "How often the icon shifts to remind you to drink.")
                minimum: 15
                maximum: 180
                step: 5
                unit: I18n.trFor("hydrate", " min")
                value: root.interval
                modified: root.interval !== root.defaultInterval
                resetByKeys: false
                onResetRequested: {
                    root.interval = root.defaultInterval;
                    root.saveValue("interval", root.defaultInterval);
                }
                onSliderDragFinished: finalValue => {
                    root.interval = finalValue;
                    root.saveValue("interval", finalValue);
                }
            }
        }
    }

    Column {
        width: parent ? parent.width : 0
        spacing: 0

        SettingsSectionLabel {
            width: parent.width
            text: I18n.trFor("hydrate", "Behavior")
        }

        SettingsGroup {
            width: parent.width
            slotColor: SettingsMetrics.controlColor

            SettingsDropdownRow {
                text: I18n.trFor("hydrate", "Display Mode")
                description: I18n.trFor("hydrate", "How progress is shown on the bar.")
                options: [
                    I18n.trFor("hydrate", "Full (Logged / Goal)"),
                    I18n.trFor("hydrate", "Logged Only"),
                    I18n.trFor("hydrate", "Percentage"),
                    I18n.trFor("hydrate", "Icon Only"),
                    I18n.trFor("hydrate", "Progress Bar"),
                    I18n.trFor("hydrate", "Text + Bar")
                ]
                optionValues: ["full", "logged", "percentage", "icon", "progress", "text_progress"]
                currentValue: root.displayMode
                modified: root.displayMode !== root.defaultDisplayMode
                resetByKeys: false
                onResetRequested: {
                    root.displayMode = root.defaultDisplayMode;
                    root.saveValue("displayMode", root.defaultDisplayMode);
                }
                onValueChanged: val => {
                    root.displayMode = val;
                    root.saveValue("displayMode", val);
                }
            }

            SettingsToggleRow {
                text: I18n.trFor("hydrate", "Show Hints")
                checked: root.showHints
                modified: root.showHints !== root.defaultShowHints
                resetByKeys: false
                onResetRequested: {
                    root.showHints = root.defaultShowHints;
                    root.saveValue("showHints", root.defaultShowHints);
                }
                onToggled: isChecked => {
                    root.showHints = isChecked;
                    root.saveValue("showHints", isChecked);
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
            text: I18n.trFor("hydrate", "Usage Guide")
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
                        I18n.trFor("hydrate", "<b>Left-click</b> the pill to open the hydration dashboard."),
                        I18n.trFor("hydrate", "<b>Right-click</b> the pill to instantly log <b>+1 cup</b>."),
                        I18n.trFor("hydrate", "The icon will <b>pulse or shift shape</b> when it's time to drink.")
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
}
