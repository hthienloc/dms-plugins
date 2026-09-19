import QtQuick
import qs.Common
import qs.Modules.Plugins
import qs.Widgets
import "./dms-common"

PluginSettings {
    id: root

    pluginId: "emojiPicker"

    SettingsCard {
        SectionTitle {
            text: I18n.tr("General")
            icon: "settings"
            showReset: defaultCategory.isDirty || recentLimit.isDirty
            onResetClicked: {
                defaultCategory.resetToDefault();
                recentLimit.resetToDefault();
            }
        }

        SelectionSettingPlus {
            id: defaultCategory
            settingKey: "defaultCategory"
            label: I18n.tr("Default Category")
            defaultValue: "auto"
            options: [
                { label: I18n.tr("Auto"), value: "auto" },
                { label: I18n.tr("Recently Used"), value: "recent" },
                { label: I18n.tr("Smileys & People"), value: "smileys-people" },
                { label: I18n.tr("Animals & Nature"), value: "animals-nature" },
                { label: I18n.tr("Food & Drink"), value: "food-drink" },
                { label: I18n.tr("Activities"), value: "activities" },
                { label: I18n.tr("Travel & Places"), value: "travel-places" },
                { label: I18n.tr("Objects"), value: "objects" },
                { label: I18n.tr("Symbols"), value: "symbols" },
                { label: I18n.tr("Flags"), value: "flags" }
            ]
        }

        Separator {}

        SliderSettingPlus {
            id: recentLimit
            settingKey: "recentLimit"
            label: I18n.tr("Recent History Size")
            minimum: 5
            maximum: 100
            defaultValue: 30
            leftLabel: "5"
            rightLabel: "100"
        }
    }

    SettingsCard {
        SectionTitle {
            text: I18n.tr("Appearance")
            icon: "palette"
            showReset: pickerSize.isDirty
            onResetClicked: pickerSize.resetToDefault()
        }

        SelectionSettingPlus {
            id: pickerSize
            settingKey: "pickerSize"
            label: I18n.tr("Picker Size")
            description: I18n.tr("Choose the modal size that best fits your display.")
            defaultValue: "560"
            options: [
                { label: I18n.tr("Compact (500 px)"), value: "500" },
                { label: I18n.tr("Comfortable (560 px)"), value: "560" },
                { label: I18n.tr("Large (620 px)"), value: "620" }
            ]
        }
    }

    SettingsCard {
        SectionTitle {
            text: I18n.tr("Feedback")
            icon: "notifications"
            showReset: showCopyToast.isDirty
            onResetClicked: showCopyToast.resetToDefault()
        }

        ToggleSettingPlus {
            id: showCopyToast
            settingKey: "showCopyToast"
            label: I18n.tr("Copy Confirmation")
            description: I18n.tr("Show a toast containing the emoji after copying it.")
            defaultValue: true
        }
    }

    SettingsCard {
        SectionTitle {
            id: usageTitle
            text: I18n.tr("Usage Guide")
            icon: "menu_book"
            collapsible: true
            settingKey: "usageGuideExpanded"
        }

        UsageGuide {
            expanded: usageTitle.isExpanded
            items: [
                I18n.tr("With an empty queue, <b>left-click</b> or <b>Enter</b> copies the selected emoji."),
                I18n.tr("With an empty queue, <b>right-click</b> or <b>Ctrl+Enter</b> copies and pastes the selected emoji."),
                I18n.tr("Hold <b>Shift</b> while left-clicking or pressing <b>Enter</b> to add emojis to a queue."),
                I18n.tr("With emojis queued, <b>Enter</b> copies the sequence and <b>Ctrl+Enter</b> pastes it."),
                I18n.tr("Press <b>Backspace</b> to remove the last queued emoji."),
                I18n.tr("Press <b>Down</b> or <b>Tab</b> to move from search to the emoji grid."),
                I18n.tr("Press <b>Escape</b> to discard the queue, or close the picker when the queue is empty.")
            ]
        }
    }

    SettingsCard {
        SectionTitle {
            id: ipcTitle
            text: I18n.tr("IPC Commands")
            icon: "terminal"
            collapsible: true
            settingKey: "ipcCommandsExpanded"
        }

        Column {
            width: parent.width
            spacing: Theme.spacingM
            visible: ipcTitle.isExpanded

            CopyBox {
                label: I18n.tr("Toggle Picker")
                text: "dms ipc call emojiPicker toggle"
            }

            CopyBox {
                label: I18n.tr("Open Picker")
                text: "dms ipc call emojiPicker open"
            }

            CopyBox {
                label: I18n.tr("Close Picker")
                text: "dms ipc call emojiPicker close"
            }
        }
    }
}
