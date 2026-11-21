import QtQuick
import qs.Common
import qs.DCommon.Widgets
import qs.Modules.Plugins
import qs.Modules.Settings.Widgets
import "./shared"

PluginSettings {
    id: root

    pluginId: "emojiPicker"

    readonly property string defaultDefaultAction: "copy"
    readonly property string defaultDefaultCategory: "auto"
    readonly property int defaultRecentLimit: 30
    readonly property string defaultPickerSize: "560"
    readonly property string defaultDefaultSkinTone: "default"
    readonly property int defaultEmojisPerRow: 8
    readonly property bool defaultShowCopyToast: true

    property string defaultAction: defaultDefaultAction
    property string defaultCategory: defaultDefaultCategory
    property int recentLimit: defaultRecentLimit
    property string pickerSize: defaultPickerSize
    property string defaultSkinTone: defaultDefaultSkinTone
    property int emojisPerRow: defaultEmojisPerRow
    property bool showCopyToast: defaultShowCopyToast

    function loadSettings() {
        if (!pluginService)
            return;
        defaultAction = loadValue("defaultAction", defaultDefaultAction);
        defaultCategory = loadValue("defaultCategory", defaultDefaultCategory);
        recentLimit = loadValue("recentLimit", defaultRecentLimit);
        pickerSize = loadValue("pickerSize", defaultPickerSize);
        defaultSkinTone = loadValue("defaultSkinTone", defaultDefaultSkinTone);
        emojisPerRow = loadValue("emojisPerRow", defaultEmojisPerRow);
        showCopyToast = loadValue("showCopyToast", defaultShowCopyToast);
        usageSection.expanded = loadValue("usageGuideExpanded", true);
        ipcSection.expanded = loadValue("ipcCommandsExpanded", true);
        creditsSection.expanded = loadValue("creditsExpanded", true);
    }

    Component.onCompleted: loadSettings()
    onPluginServiceChanged: loadSettings()

    Column {
        width: parent ? parent.width : 0
        spacing: 0

        SettingsSectionLabel {
            width: parent.width
            text: I18n.trFor("emojiPicker", "Picker")
        }

        SettingsGroup {
            width: parent.width
            slotColor: SettingsMetrics.controlColor

            SettingsDropdownRow {
                text: I18n.trFor("emojiPicker", "Default Action")
                description: I18n.trFor("emojiPicker", "Left click and Enter use this action; right click and Ctrl+Enter use the other one.")
                options: [
                    I18n.trFor("emojiPicker", "Copy to clipboard"),
                    I18n.trFor("emojiPicker", "Paste at cursor")
                ]
                optionValues: ["copy", "paste"]
                currentValue: root.defaultAction
                modified: root.defaultAction !== root.defaultDefaultAction
                resetByKeys: false
                onResetRequested: {
                    root.defaultAction = root.defaultDefaultAction;
                    root.saveValue("defaultAction", root.defaultDefaultAction);
                }
                onValueChanged: val => {
                    root.defaultAction = val;
                    root.saveValue("defaultAction", val);
                }
            }

            SettingsDropdownRow {
                text: I18n.trFor("emojiPicker", "Default Category")
                options: [
                    I18n.trFor("emojiPicker", "Auto"),
                    I18n.trFor("emojiPicker", "Recently Used"),
                    I18n.trFor("emojiPicker", "Smileys & People"),
                    I18n.trFor("emojiPicker", "Animals & Nature"),
                    I18n.trFor("emojiPicker", "Food & Drink"),
                    I18n.trFor("emojiPicker", "Activities"),
                    I18n.trFor("emojiPicker", "Travel & Places"),
                    I18n.trFor("emojiPicker", "Objects"),
                    I18n.trFor("emojiPicker", "Symbols"),
                    I18n.trFor("emojiPicker", "Flags")
                ]
                optionValues: ["auto", "recent", "smileys-people", "animals-nature", "food-drink", "activities", "travel-places", "objects", "symbols", "flags"]
                currentValue: root.defaultCategory
                modified: root.defaultCategory !== root.defaultDefaultCategory
                resetByKeys: false
                onResetRequested: {
                    root.defaultCategory = root.defaultDefaultCategory;
                    root.saveValue("defaultCategory", root.defaultDefaultCategory);
                }
                onValueChanged: val => {
                    root.defaultCategory = val;
                    root.saveValue("defaultCategory", val);
                }
            }

            SettingsSliderRow {
                text: I18n.trFor("emojiPicker", "Recent History Size")
                minimum: 5
                maximum: 100
                step: 1
                value: root.recentLimit
                modified: root.recentLimit !== root.defaultRecentLimit
                resetByKeys: false
                onResetRequested: {
                    root.recentLimit = root.defaultRecentLimit;
                    root.saveValue("recentLimit", root.defaultRecentLimit);
                }
                onSliderDragFinished: finalValue => {
                    root.recentLimit = finalValue;
                    root.saveValue("recentLimit", finalValue);
                }
            }

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

                DButton {
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
    }

    Column {
        width: parent ? parent.width : 0
        spacing: 0

        SettingsSectionLabel {
            width: parent.width
            text: I18n.trFor("emojiPicker", "Appearance")
        }

        SettingsGroup {
            width: parent.width
            slotColor: SettingsMetrics.controlColor

            SettingsDropdownRow {
                text: I18n.trFor("emojiPicker", "Picker Size")
                description: I18n.trFor("emojiPicker", "Choose the modal size that best fits your display.")
                options: [
                    I18n.trFor("emojiPicker", "Compact (500 px)"),
                    I18n.trFor("emojiPicker", "Comfortable (560 px)"),
                    I18n.trFor("emojiPicker", "Large (620 px)")
                ]
                optionValues: ["500", "560", "620"]
                currentValue: root.pickerSize
                modified: root.pickerSize !== root.defaultPickerSize
                resetByKeys: false
                onResetRequested: {
                    root.pickerSize = root.defaultPickerSize;
                    root.saveValue("pickerSize", root.defaultPickerSize);
                }
                onValueChanged: val => {
                    root.pickerSize = val;
                    root.saveValue("pickerSize", val);
                }
            }

            SettingsDropdownRow {
                text: I18n.trFor("emojiPicker", "Skin Tone")
                description: I18n.trFor("emojiPicker", "Default skin tone modifier for people and hand emojis.")
                options: [
                    "✋ " + I18n.trFor("emojiPicker", "Default"),
                    "✋🏻 " + I18n.trFor("emojiPicker", "Light"),
                    "✋🏼 " + I18n.trFor("emojiPicker", "Medium-Light"),
                    "✋🏽 " + I18n.trFor("emojiPicker", "Medium"),
                    "✋🏾 " + I18n.trFor("emojiPicker", "Medium-Dark"),
                    "✋🏿 " + I18n.trFor("emojiPicker", "Dark")
                ]
                optionValues: ["default", "1", "2", "3", "4", "5"]
                currentValue: root.defaultSkinTone
                modified: root.defaultSkinTone !== root.defaultDefaultSkinTone
                resetByKeys: false
                onResetRequested: {
                    root.defaultSkinTone = root.defaultDefaultSkinTone;
                    root.saveValue("defaultSkinTone", root.defaultDefaultSkinTone);
                }
                onValueChanged: val => {
                    root.defaultSkinTone = val;
                    root.saveValue("defaultSkinTone", val);
                }
            }

            SettingsSliderRow {
                text: I18n.trFor("emojiPicker", "Emojis Per Row")
                description: I18n.trFor("emojiPicker", "Number of emojis displayed per row. Each emoji stays square.")
                minimum: 4
                maximum: 16
                step: 1
                value: root.emojisPerRow
                modified: root.emojisPerRow !== root.defaultEmojisPerRow
                resetByKeys: false
                onResetRequested: {
                    root.emojisPerRow = root.defaultEmojisPerRow;
                    root.saveValue("emojisPerRow", root.defaultEmojisPerRow);
                }
                onSliderDragFinished: finalValue => {
                    root.emojisPerRow = finalValue;
                    root.saveValue("emojisPerRow", finalValue);
                }
            }
        }
    }

    Column {
        width: parent ? parent.width : 0
        spacing: 0

        SettingsSectionLabel {
            width: parent.width
            text: I18n.trFor("emojiPicker", "Feedback")
        }

        SettingsGroup {
            width: parent.width
            slotColor: SettingsMetrics.controlColor

            SettingsToggleRow {
                text: I18n.trFor("emojiPicker", "Copy Confirmation")
                description: I18n.trFor("emojiPicker", "Show a toast containing the emoji after copying it.")
                checked: root.showCopyToast
                modified: root.showCopyToast !== root.defaultShowCopyToast
                resetByKeys: false
                onResetRequested: {
                    root.showCopyToast = root.defaultShowCopyToast;
                    root.saveValue("showCopyToast", root.defaultShowCopyToast);
                }
                onToggled: isChecked => {
                    root.showCopyToast = isChecked;
                    root.saveValue("showCopyToast", isChecked);
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
            text: I18n.trFor("emojiPicker", "How to Use")
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
                        I18n.trFor("emojiPicker", "With an empty queue, <b>left-click</b> or <b>Enter</b> copies the selected emoji."),
                        I18n.trFor("emojiPicker", "With an empty queue, <b>right-click</b> or <b>Ctrl+Enter</b> copies and pastes the selected emoji."),
                        I18n.trFor("emojiPicker", "Hold <b>Shift</b> while left-clicking or pressing <b>Enter</b> to add emojis to a queue."),
                        I18n.trFor("emojiPicker", "With emojis queued, <b>Enter</b> copies the sequence and <b>Ctrl+Enter</b> pastes it."),
                        I18n.trFor("emojiPicker", "Press <b>Backspace</b> to remove the last queued emoji."),
                        I18n.trFor("emojiPicker", "Press <b>Down</b> or <b>Tab</b> to move from search to the first emoji."),
                        I18n.trFor("emojiPicker", "In the grid, use <b>Ctrl+H/J/K/L</b> for Vim-style left/down/up/right navigation."),
                        I18n.trFor("emojiPicker", "In the grid, press <b>Backspace</b> or <b>Delete</b> with an empty queue to clear the search and return to it."),
                        I18n.trFor("emojiPicker", "Press <b>Escape</b> to discard the queue, or close the picker when the queue is empty.")
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

    Column {
        id: ipcSection
        width: parent ? parent.width : 0
        spacing: 0

        property bool expanded: true

        SettingsSectionLabel {
            width: parent.width
            text: I18n.trFor("emojiPicker", "IPC Commands")
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
                spacing: Theme.spacingM

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

    Column {
        id: creditsSection
        width: parent ? parent.width : 0
        spacing: 0

        property bool expanded: true

        SettingsSectionLabel {
            width: parent.width
            text: I18n.trFor("emojiPicker", "Credits")
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
                        author: "Emote",
                        url: "https://github.com/tom-james-watson/emote",
                        role: I18n.trFor("emojiPicker", "Emoji catalog and inspiration."),
                        icon: "mood"
                    },
                    {
                        author: "OpenMoji",
                        url: "https://openmoji.org/",
                        role: I18n.trFor("emojiPicker", "Emoji metadata."),
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
