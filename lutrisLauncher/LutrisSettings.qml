import QtQuick
import qs.Common
import qs.DCommon.Widgets
import qs.Modules.Plugins
import qs.Modules.Settings.Widgets

PluginSettings {
    id: root
    pluginId: "lutrisLauncher"

    readonly property string defaultDateFormat: "YYYY - MM - DD"
    readonly property bool defaultShowHints: true

    property string dateFormat: defaultDateFormat
    property bool showHints: defaultShowHints

    function loadSettings() {
        if (!pluginService)
            return;
        dateFormat = loadValue("dateFormat", defaultDateFormat);
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
            text: I18n.trFor("lutrisLauncher", "Display Options")
        }

        SettingsGroup {
            width: parent.width
            slotColor: SettingsMetrics.controlColor

            SettingsDropdownRow {
                text: I18n.trFor("lutrisLauncher", "Last Played Format")
                options: [
                    I18n.trFor("lutrisLauncher", "YYYY - MM - DD"),
                    I18n.trFor("lutrisLauncher", "DD / MM / YYYY"),
                    I18n.trFor("lutrisLauncher", "MM / DD / YYYY"),
                    I18n.trFor("lutrisLauncher", "Relative time")
                ]
                optionValues: [
                    "YYYY - MM - DD",
                    "DD / MM / YYYY",
                    "MM / DD / YYYY",
                    "relative"
                ]
                currentValue: root.dateFormat
                modified: root.dateFormat !== root.defaultDateFormat
                resetByKeys: false
                onResetRequested: {
                    root.dateFormat = root.defaultDateFormat;
                    root.saveValue("dateFormat", root.defaultDateFormat);
                }
                onValueChanged: val => {
                    root.dateFormat = val;
                    root.saveValue("dateFormat", val);
                }
            }
        }
    }

    Column {
        width: parent ? parent.width : 0
        spacing: 0

        SettingsSectionLabel {
            width: parent.width
            text: I18n.trFor("lutrisLauncher", "Behavior")
        }

        SettingsGroup {
            width: parent.width
            slotColor: SettingsMetrics.controlColor

            SettingsToggleRow {
                text: I18n.trFor("lutrisLauncher", "Show Hints")
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
            text: I18n.trFor("lutrisLauncher", "Usage Guide")
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
                        I18n.trFor("lutrisLauncher", "<b>Left-click</b> a game tile to launch it instantly."),
                        I18n.trFor("lutrisLauncher", "<b>Right-click</b> a tile to view stats and manage visibility."),
                        I18n.trFor("lutrisLauncher", "Toggle <b>Blacklist</b> mode in the popout to manage hidden games.")
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
