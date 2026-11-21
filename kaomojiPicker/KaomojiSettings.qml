import QtQuick
import qs.Common
import qs.DCommon.Widgets
import qs.Modules.Plugins
import qs.Modules.Settings.Widgets

PluginSettings {
    id: root
    pluginId: "kaomojiPicker"

    readonly property string defaultTrigger: "kj"
    readonly property int defaultResultLimit: 50
    readonly property bool defaultPasteOnSelect: true
    readonly property bool defaultEnableHistory: true
    readonly property int defaultHistoryLimit: 15

    property string trigger: defaultTrigger
    property int resultLimit: defaultResultLimit
    property bool pasteOnSelect: defaultPasteOnSelect
    property bool enableHistory: defaultEnableHistory
    property int historyLimit: defaultHistoryLimit

    function loadSettings() {
        if (!pluginService)
            return;
        trigger = loadValue("trigger", defaultTrigger);
        resultLimit = loadValue("resultLimit", defaultResultLimit);
        pasteOnSelect = loadValue("pasteOnSelect", defaultPasteOnSelect);
        enableHistory = loadValue("enableHistory", defaultEnableHistory);
        historyLimit = loadValue("historyLimit", defaultHistoryLimit);
        usageSection.expanded = loadValue("usageGuideExpanded", true);
    }

    Component.onCompleted: loadSettings()
    onPluginServiceChanged: loadSettings()

    Column {
        width: parent ? parent.width : 0
        spacing: 0

        SettingsSectionLabel {
            width: parent.width
            text: I18n.trFor("kaomojiPicker", "Launcher")
        }

        SettingsGroup {
            width: parent.width
            slotColor: SettingsMetrics.controlColor

            SettingsTextFieldRow {
                id: triggerField
                text: I18n.trFor("kaomojiPicker", "Launcher Trigger")
                description: I18n.trFor("kaomojiPicker", "The keyword to trigger this launcher in the search bar.")
                placeholderText: "kj"
                value: root.trigger
                modified: root.trigger !== root.defaultTrigger
                onResetRequested: {
                    root.trigger = root.defaultTrigger;
                    triggerField.value = root.defaultTrigger;
                    root.saveValue("trigger", root.defaultTrigger);
                }
                onValueEdited: val => {
                    root.trigger = val;
                    root.saveValue("trigger", val);
                }
            }

            SettingsSliderRow {
                text: I18n.trFor("kaomojiPicker", "Result Limit")
                description: I18n.trFor("kaomojiPicker", "Maximum number of kaomoji to show in search results.")
                minimum: 10
                maximum: 200
                step: 10
                value: root.resultLimit
                modified: root.resultLimit !== root.defaultResultLimit
                resetByKeys: false
                onResetRequested: {
                    root.resultLimit = root.defaultResultLimit;
                    root.saveValue("resultLimit", root.defaultResultLimit);
                }
                onSliderDragFinished: finalValue => {
                    root.resultLimit = finalValue;
                    root.saveValue("resultLimit", finalValue);
                }
            }

            SettingsToggleRow {
                text: I18n.trFor("kaomojiPicker", "Paste on Select")
                checked: root.pasteOnSelect
                modified: root.pasteOnSelect !== root.defaultPasteOnSelect
                resetByKeys: false
                onResetRequested: {
                    root.pasteOnSelect = root.defaultPasteOnSelect;
                    root.saveValue("pasteOnSelect", root.defaultPasteOnSelect);
                }
                onToggled: isChecked => {
                    root.pasteOnSelect = isChecked;
                    root.saveValue("pasteOnSelect", isChecked);
                }
            }

            SettingsNoteRow {
                noteIconName: "info"
                tint: Theme.primary
                tintBackground: Theme.withAlpha(Theme.primary, 0.08)
                text: I18n.trFor("kaomojiPicker", "Directly paste the selected kaomoji into the active window (Enter to paste, Shift + Enter to copy).")
            }

            SettingsToggleRow {
                text: I18n.trFor("kaomojiPicker", "Enable History")
                description: I18n.trFor("kaomojiPicker", "Show recently used kaomoji when the search is empty.")
                checked: root.enableHistory
                modified: root.enableHistory !== root.defaultEnableHistory
                resetByKeys: false
                onResetRequested: {
                    root.enableHistory = root.defaultEnableHistory;
                    root.saveValue("enableHistory", root.defaultEnableHistory);
                }
                onToggled: isChecked => {
                    root.enableHistory = isChecked;
                    root.saveValue("enableHistory", isChecked);
                }
            }

            SettingsSliderRow {
                text: I18n.trFor("kaomojiPicker", "History Size")
                description: I18n.trFor("kaomojiPicker", "Number of recently used items to keep.")
                minimum: 5
                maximum: 50
                step: 5
                value: root.historyLimit
                visible: root.enableHistory
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
        }
    }

    Column {
        id: usageSection
        width: parent ? parent.width : 0
        spacing: 0

        property bool expanded: true

        SettingsSectionLabel {
            width: parent.width
            text: I18n.trFor("kaomojiPicker", "How to Use")
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
                        icon: "keyboard",
                        title: I18n.trFor("kaomojiPicker", "Trigger Key"),
                        subtitle: I18n.trFor("kaomojiPicker", "Type the trigger key (default: kj) in the DMS search bar.")
                    },
                    {
                        icon: "search",
                        title: I18n.trFor("kaomojiPicker", "Search"),
                        subtitle: I18n.trFor("kaomojiPicker", "Filter kaomoji by category or keyword, such as kj cat.")
                    },
                    {
                        icon: "content_copy",
                        title: I18n.trFor("kaomojiPicker", "Left-click"),
                        subtitle: I18n.trFor("kaomojiPicker", "Copy or paste a selected kaomoji instantly.")
                    },
                    {
                        icon: "push_pin",
                        title: I18n.trFor("kaomojiPicker", "Right-click"),
                        subtitle: I18n.trFor("kaomojiPicker", "Pin, unpin, or remove an entry from history.")
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
