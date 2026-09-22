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
            text: I18n.trFor("emojiPicker", "General")
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
            label: I18n.trFor("emojiPicker", "Default Category")
            defaultValue: "auto"
            options: [
                { label: I18n.trFor("emojiPicker", "Auto"), value: "auto" },
                { label: I18n.trFor("emojiPicker", "Recently Used"), value: "recent" },
                { label: I18n.trFor("emojiPicker", "Smileys & People"), value: "smileys-people" },
                { label: I18n.trFor("emojiPicker", "Animals & Nature"), value: "animals-nature" },
                { label: I18n.trFor("emojiPicker", "Food & Drink"), value: "food-drink" },
                { label: I18n.trFor("emojiPicker", "Activities"), value: "activities" },
                { label: I18n.trFor("emojiPicker", "Travel & Places"), value: "travel-places" },
                { label: I18n.trFor("emojiPicker", "Objects"), value: "objects" },
                { label: I18n.trFor("emojiPicker", "Symbols"), value: "symbols" },
                { label: I18n.trFor("emojiPicker", "Flags"), value: "flags" }
            ]
        }

        Separator {}

        SliderSettingPlus {
            id: recentLimit
            settingKey: "recentLimit"
            label: I18n.trFor("emojiPicker", "Recent History Size")
            minimum: 5
            maximum: 100
            defaultValue: 30
            leftLabel: "5"
            rightLabel: "100"
        }

        Separator {}

        Item {
            width: parent.width
            height: 36

            StyledText {
                text: I18n.trFor("emojiPicker", "Recent History")
                color: Theme.surfaceText
                font.pixelSize: Theme.fontSizeMedium
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
            }

            DankButton {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: I18n.trFor("emojiPicker", "Clear History")
                iconName: "delete_sweep"
                textColor: Theme.error
                backgroundColor: Theme.withAlpha(Theme.error, 0.12)
                onClicked: {
                    PluginService.savePluginState(root.pluginId, "recent", []);
                    ToastService.showInfo(I18n.trFor("emojiPicker", "Recent emoji history cleared"));
                }
            }
        }
    }

    SettingsCard {
        SectionTitle {
            text: I18n.trFor("emojiPicker", "Appearance")
            icon: "palette"
            showReset: pickerSize.isDirty
            onResetClicked: pickerSize.resetToDefault()
        }

        SelectionSettingPlus {
            id: pickerSize
            settingKey: "pickerSize"
            label: I18n.trFor("emojiPicker", "Picker Size")
            description: I18n.trFor("emojiPicker", "Choose the modal size that best fits your display.")
            defaultValue: "560"
            options: [
                { label: I18n.trFor("emojiPicker", "Compact (500 px)"), value: "500" },
                { label: I18n.trFor("emojiPicker", "Comfortable (560 px)"), value: "560" },
                { label: I18n.trFor("emojiPicker", "Large (620 px)"), value: "620" }
            ]
        }
    }

    SettingsCard {
        SectionTitle {
            text: I18n.trFor("emojiPicker", "Feedback")
            icon: "notifications"
            showReset: showCopyToast.isDirty
            onResetClicked: showCopyToast.resetToDefault()
        }

        ToggleSettingPlus {
            id: showCopyToast
            settingKey: "showCopyToast"
            label: I18n.trFor("emojiPicker", "Copy Confirmation")
            description: I18n.trFor("emojiPicker", "Show a toast containing the emoji after copying it.")
            defaultValue: true
        }
    }

    SettingsCard {
        SectionTitle {
            id: usageTitle
            text: I18n.trFor("emojiPicker", "Usage Guide")
            icon: "menu_book"
            collapsible: true
            settingKey: "usageGuideExpanded"
        }

        UsageGuide {
            expanded: usageTitle.isExpanded
            items: [
                I18n.trFor("emojiPicker", "With an empty queue, <b>left-click</b> or <b>Enter</b> copies the selected emoji."),
                I18n.trFor("emojiPicker", "With an empty queue, <b>right-click</b> or <b>Ctrl+Enter</b> copies and pastes the selected emoji."),
                I18n.trFor("emojiPicker", "Hold <b>Shift</b> while left-clicking or pressing <b>Enter</b> to add emojis to a queue."),
                I18n.trFor("emojiPicker", "With emojis queued, <b>Enter</b> copies the sequence and <b>Ctrl+Enter</b> pastes it."),
                I18n.trFor("emojiPicker", "Press <b>Backspace</b> to remove the last queued emoji."),
                I18n.trFor("emojiPicker", "Press <b>Down</b> or <b>Tab</b> to move from search to the emoji grid."),
                I18n.trFor("emojiPicker", "Press <b>Escape</b> to discard the queue, or close the picker when the queue is empty.")
            ]
        }
    }

    SettingsCard {
        SectionTitle {
            id: ipcTitle
            text: I18n.trFor("emojiPicker", "IPC Commands")
            icon: "terminal"
            collapsible: true
            settingKey: "ipcCommandsExpanded"
        }

        Column {
            width: parent.width
            spacing: Theme.spacingM
            visible: ipcTitle.isExpanded

            CopyBox {
                label: I18n.trFor("emojiPicker", "Toggle Picker")
                text: "dms ipc call emojiPicker toggle"
            }

            CopyBox {
                label: I18n.trFor("emojiPicker", "Open Picker")
                text: "dms ipc call emojiPicker open"
            }

            CopyBox {
                label: I18n.trFor("emojiPicker", "Close Picker")
                text: "dms ipc call emojiPicker close"
            }

            CopyBox {
                label: I18n.trFor("emojiPicker", "Clear Recent History")
                text: "dms ipc call emojiPicker clearRecent"
            }
        }
    }
}
