import QtQuick
import qs.Common
import qs.DCommon.Widgets
import qs.Modules.Plugins
import qs.Modules.Settings.Widgets

PluginSettings {
    id: root
    pluginId: "lutrisLauncher"

    readonly property string defaultDateFormat: "YYYY - MM - DD"

    property string dateFormat: defaultDateFormat

    function loadSettings() {
        if (!pluginService)
            return;
        dateFormat = loadValue("dateFormat", defaultDateFormat);
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
        id: usageSection
        width: parent ? parent.width : 0
        spacing: 0

        property bool expanded: true

        SettingsSectionLabel {
            width: parent.width
            text: I18n.trFor("lutrisLauncher", "How to Use")
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
                        icon: "play_arrow",
                        title: I18n.trFor("lutrisLauncher", "Left-click"),
                        subtitle: I18n.trFor("lutrisLauncher", "Launch a game tile instantly.")
                    },
                    {
                        icon: "tune",
                        title: I18n.trFor("lutrisLauncher", "Right-click"),
                        subtitle: I18n.trFor("lutrisLauncher", "View stats and manage visibility for a tile.")
                    },
                    {
                        icon: "visibility_off",
                        title: I18n.trFor("lutrisLauncher", "Blacklist Mode"),
                        subtitle: I18n.trFor("lutrisLauncher", "Toggle in the popout to manage hidden games.")
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
}
