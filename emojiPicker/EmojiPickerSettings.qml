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

            Repeater {
                model: [
                    {
                        icon: "content_copy",
                        title: I18n.trFor("emojiPicker", "Left-click / Enter"),
                        subtitle: I18n.trFor("emojiPicker", "Copy the selected emoji when the queue is empty.")
                    },
                    {
                        icon: "content_paste",
                        title: I18n.trFor("emojiPicker", "Right-click"),
                        subtitle: I18n.trFor("emojiPicker", "Copy and paste the selected emoji, or press Ctrl+Enter.")
                    },
                    {
                        icon: "playlist_add",
                        title: I18n.trFor("emojiPicker", "Queue Emojis"),
                        subtitle: I18n.trFor("emojiPicker", "Hold Shift while clicking or pressing Enter to add emojis to the queue.")
                    },
                    {
                        icon: "done_all",
                        title: I18n.trFor("emojiPicker", "Confirm Queue"),
                        subtitle: I18n.trFor("emojiPicker", "Press Enter to copy the queued sequence or Ctrl+Enter to paste it.")
                    },
                    {
                        icon: "backspace",
                        title: I18n.trFor("emojiPicker", "Remove Queued"),
                        subtitle: I18n.trFor("emojiPicker", "Press Backspace to remove the last queued emoji.")
                    },
                    {
                        icon: "keyboard_arrow_down",
                        title: I18n.trFor("emojiPicker", "Focus Grid"),
                        subtitle: I18n.trFor("emojiPicker", "Press Down or Tab to move from the search box to the first emoji.")
                    },
                    {
                        icon: "open_with",
                        title: I18n.trFor("emojiPicker", "Grid Navigation"),
                        subtitle: I18n.trFor("emojiPicker", "Use Ctrl+H/J/K/L for Vim-style navigation across the grid.")
                    },
                    {
                        icon: "search_off",
                        title: I18n.trFor("emojiPicker", "Clear Search"),
                        subtitle: I18n.trFor("emojiPicker", "Press Backspace or Delete in the grid with an empty queue to reset search.")
                    },
                    {
                        icon: "close",
                        title: I18n.trFor("emojiPicker", "Escape"),
                        subtitle: I18n.trFor("emojiPicker", "Discard the queue, or close the picker when the queue is empty.")
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
