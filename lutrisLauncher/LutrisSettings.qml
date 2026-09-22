import QtQuick
import QtQuick.Controls
import qs.Common
import qs.Widgets
import qs.Modules.Plugins
import "./dms-common"

PluginSettings {
    id: root
    pluginId: "lutrisLauncher"

    SettingsCard {
        id: displaySection
        SectionTitle { 
            text: I18n.trFor("lutrisLauncher", "Display Options")
            icon: "visibility" 
            showReset: dateFormat.isDirty
            onResetClicked: {
                dateFormat.resetToDefault();
            }
        }

        SelectionSettingPlus {
            id: dateFormat
            settingKey: "dateFormat"
            label: I18n.trFor("lutrisLauncher", "Last Played Format")
            options: [
                { label: I18n.trFor("lutrisLauncher", "YYYY - MM - DD"), value: "YYYY - MM - DD" },
                { label: I18n.trFor("lutrisLauncher", "DD / MM / YYYY"), value: "DD / MM / YYYY" },
                { label: I18n.trFor("lutrisLauncher", "MM / DD / YYYY"), value: "MM / DD / YYYY" },
                { label: I18n.trFor("lutrisLauncher", "Relative time"), value: "relative" }
            ]
            defaultValue: "YYYY - MM - DD"
        }
    }

    SettingsCard {
        id: behaviorSection
        SectionTitle { 
            text: I18n.trFor("lutrisLauncher", "Behavior")
            icon: "settings" 
            showReset: showHints.isDirty
            onResetClicked: {
                showHints.resetToDefault();
            }
        }

        ToggleSettingPlus {
            id: showHints
            settingKey: "showHints"
            label: I18n.trFor("lutrisLauncher", "Show Hints")
            defaultValue: true
        }
    }

    SettingsCard {
        SectionTitle { 
            id: usageTitle
            text: I18n.trFor("lutrisLauncher", "Usage Guide")
            icon: "menu_book" 
            collapsible: true
            settingKey: "usageGuideExpanded"
        }

        UsageGuide {
            expanded: usageTitle.isExpanded
            items: [
                I18n.trFor("lutrisLauncher", "<b>Left-click</b> a game tile to launch it instantly."),
                I18n.trFor("lutrisLauncher", "<b>Right-click</b> a tile to view stats and manage visibility."),
                I18n.trFor("lutrisLauncher", "Toggle <b>Blacklist</b> mode in the popout to manage hidden games.")
            ]
        }
    }

    PluginAbout {
        repoUrl: "https://github.com/hthienloc/dms-lutris-launcher"
    }
}
