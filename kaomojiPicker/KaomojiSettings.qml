import QtQuick
import qs.Common
import qs.Widgets
import qs.Modules.Plugins
import "./dms-common"

PluginSettings {
    id: root
    pluginId: "kaomojiPicker"

    SettingsCard {
        id: generalSection
        SectionTitle { 
            text: I18n.trFor("kaomojiPicker", "General Settings")
            icon: "settings" 
            showReset: triggerKey.isDirty || resultLimit.isDirty || pasteOnSelect.isDirty || enableHistory.isDirty || historyLimit.isDirty
            onResetClicked: {
                triggerKey.resetToDefault();
                resultLimit.resetToDefault();
                pasteOnSelect.resetToDefault();
                enableHistory.resetToDefault();
                historyLimit.resetToDefault();
            }
        }

        StringSettingPlus {
            id: triggerKey
            settingKey: "trigger"
            label: I18n.trFor("kaomojiPicker", "Launcher Trigger")
            description: I18n.trFor("kaomojiPicker", "The keyword to trigger this launcher in the search bar.")
            placeholder: "kj"
            defaultValue: "kj"
        }

        Separator {}

        SliderSettingPlus {
            id: resultLimit
            settingKey: "resultLimit"
            label: I18n.trFor("kaomojiPicker", "Result Limit")
            description: I18n.trFor("kaomojiPicker", "Maximum number of kaomoji to show in search results.")
            minimum: 10
            maximum: 200
            defaultValue: 50
            leftLabel: "10"
            rightLabel: "200"
        }

        Separator {}

        ToggleSettingPlus {
            id: pasteOnSelect
            settingKey: "pasteOnSelect"
            label: I18n.trFor("kaomojiPicker", "Paste on Select")
            defaultValue: true
        }

        InfoText {
            text: I18n.trFor("kaomojiPicker", "Directly paste the selected kaomoji into the active window (Enter to paste, Shift + Enter to copy).")
        }

        Separator {}

        ToggleSettingPlus {
            id: enableHistory
            settingKey: "enableHistory"
            label: I18n.trFor("kaomojiPicker", "Enable History")
            description: I18n.trFor("kaomojiPicker", "Show recently used kaomoji when the search is empty.")
            defaultValue: true
        }

        Separator { visible: enableHistory.value }

        SliderSettingPlus {
            id: historyLimit
            settingKey: "historyLimit"
            label: I18n.trFor("kaomojiPicker", "History Size")
            description: I18n.trFor("kaomojiPicker", "Number of recently used items to keep.")
            minimum: 5
            maximum: 50
            defaultValue: 15
            leftLabel: "5"
            rightLabel: "50"
            visible: enableHistory.value
        }
    }

    SettingsCard {
        SectionTitle { 
            id: usageTitle
            text: I18n.trFor("kaomojiPicker", "Usage Guide")
            icon: "menu_book" 
            collapsible: true
            settingKey: "usageGuideExpanded"
        }

        UsageGuide {
            expanded: usageTitle.isExpanded
            items: [
                I18n.trFor("kaomojiPicker", "Type the <b>Trigger Key</b> (default: <code>kj</code>) in the DMS search bar."),
                I18n.trFor("kaomojiPicker", "Search by category or keyword (e.g., <code>kj cat</code>)."),
                I18n.trFor("kaomojiPicker", "<b>Left-click</b> a kaomoji to copy or paste it instantly."),
                I18n.trFor("kaomojiPicker", "<b>Right-click</b> an entry to <b>Pin/Unpin</b> it or remove it from <b>History</b>.")
            ]
        }
    }

    PluginAbout {
        repoUrl: "https://github.com/hthienloc/dms-kaomoji-picker"
    }
}
