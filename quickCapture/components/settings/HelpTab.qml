import QtQuick
import qs.Common
import qs.DCommon.Widgets
import qs.Modules.Settings.Widgets
import "../../shared"

Column {
    id: root

    property QtObject config: null
    property var settings: null

    width: parent ? parent.width : 0
    spacing: Theme.spacingM

    function loadValue() {
    }

    function save(key, val) {
        if (settings)
            settings.saveValue(key, val);
    }

    readonly property var toolRows: root.config ? root.config.tools.filter(t => t.shortcut !== "").map(t => ({
                key: t.shortcut,
                action: t.label
            })) : []

    readonly property var generalRows: [
        {
            key: "Enter",
            action: I18n.trFor("quickCapture", "Done")
        },
        {
            key: "Esc",
            action: I18n.trFor("quickCapture", "Discard & Close")
        },
        {
            key: "Tab",
            action: I18n.trFor("quickCapture", "Toggle between %1 latest presets").arg(2)
        },
        {
            key: "C",
            action: I18n.trFor("quickCapture", "Copy vector / Paste / Duplicate")
        },
        {
            key: "G (Hold)",
            action: I18n.trFor("quickCapture", "Magnifier Loupe")
        },
        {
            key: "O",
            action: I18n.trFor("quickCapture", "OCR")
        },
        {
            key: "X",
            action: I18n.trFor("quickCapture", "Toggle Annotations")
        },
        {
            key: "Ctrl + Z",
            action: I18n.trFor("quickCapture", "Undo")
        },
        {
            key: "Ctrl + Y",
            action: I18n.trFor("quickCapture", "Redo")
        },
        {
            key: "Ctrl + Shift + Z",
            action: I18n.trFor("quickCapture", "Redo")
        },
        {
            key: "Ctrl + S",
            action: I18n.trFor("quickCapture", "Save")
        },
        {
            key: "Ctrl + Shift + S",
            action: I18n.trFor("quickCapture", "Save As")
        },
        {
            key: "Ctrl + C",
            action: I18n.trFor("quickCapture", "Copy")
        },
        {
            key: "Ctrl + Shift + C",
            action: I18n.trFor("quickCapture", "Anonymous Copy")
        },
        {
            key: "Ctrl + V",
            action: I18n.trFor("quickCapture", "Paste from Clipboard")
        },
        {
            key: "Ctrl + A",
            action: I18n.trFor("quickCapture", "Copy & Save")
        },
        {
            key: "Ctrl + F",
            action: I18n.trFor("quickCapture", "Float")
        },
        {
            key: "Ctrl + X",
            action: I18n.trFor("quickCapture", "Crop / Resize")
        },
        {
            key: "Ctrl + 1..4",
            action: I18n.trFor("quickCapture", "Select Color Slots %1").arg("1 - 4")
        },
        {
            key: "Ctrl + Q..R",
            action: I18n.trFor("quickCapture", "Select Color Slots %1").arg("5 - 8")
        }
    ]

    readonly property var screenshotCommands: root.config ? ["region", "full", "all", "output", "window", "last", "scroll"].map(mode => ({
                label: I18n.trFor("quickCapture", "Screenshot") + " · " + root.config.captureModeLabel(mode),
                command: "screenshot " + mode
            })).concat([
        {
            label: I18n.trFor("quickCapture", "File"),
            command: "selectFile"
        },
        {
            label: I18n.trFor("quickCapture", "Clipboard"),
            command: "fromClipboard"
        },
        {
            label: I18n.trFor("quickCapture", "Open Image"),
            command: "openImage /path/to/image.png"
        }
    ]) : []

    readonly property var otherCommands: [
        {
            label: I18n.trFor("quickCapture", "Open %1 menu (Popout)").arg(I18n.trFor("quickCapture", "Quick Capture")),
            command: "toggle"
        },
        {
            label: I18n.trFor("quickCapture", "Close"),
            command: "close"
        },
        {
            label: I18n.trFor("quickCapture", "Recent Edits"),
            command: "showHistory"
        },
        {
            label: I18n.trFor("quickCapture", "Screen Recording") + " · " + I18n.trFor("quickCapture", "Region"),
            command: "recordStart region"
        },
        {
            label: I18n.trFor("quickCapture", "Screen Recording") + " · " + I18n.trFor("quickCapture", "Fullscreen"),
            command: "recordStart screen"
        },
        {
            label: I18n.trFor("quickCapture", "Screen Recording") + " · " + I18n.trFor("quickCapture", "Window / Portal"),
            command: "recordStart portal"
        },
        {
            label: I18n.trFor("quickCapture", "Screen Recording") + " · " + I18n.trFor("quickCapture", "Stop & Save"),
            command: "recordStop"
        },
        {
            label: I18n.trFor("quickCapture", "Screen Recording") + " · " + I18n.trFor("quickCapture", "Pause / Resume"),
            command: "recordPause"
        },
        {
            label: I18n.trFor("quickCapture", "Screen Recording") + " · " + I18n.trFor("quickCapture", "Cancel"),
            command: "recordCancel"
        },
        {
            label: I18n.trFor("quickCapture", "Screen Recording") + " · " + I18n.trFor("quickCapture", "Toggle Start / Stop"),
            command: "recordToggle"
        }
    ]

    readonly property var creditsItems: [
        {
            author: "Gradia Capture",
            url: "https://github.com/AlexanderVanhee/gradia-capture",
            role: I18n.trFor("quickCapture", "Toolbar design and layout inspiration."),
            icon: "palette"
        },
        {
            author: "Flameshot",
            url: "https://github.com/flameshot-org/flameshot",
            role: I18n.trFor("quickCapture", "Radial menu and tool interaction patterns."),
            icon: "camera"
        },
        {
            author: "Snapzy",
            url: "https://github.com/duongductrong/Snapzy",
            role: I18n.trFor("quickCapture", "Floating window and continuous editing workflow."),
            icon: "open_in_new"
        }
    ]

    component ShortcutTable: Column {
        property string keyHeader: ""
        property string actionHeader: ""
        property var rows: []

        width: parent.width
        spacing: 2

        ShortcutRow {
            keyText: parent.keyHeader
            actionText: parent.actionHeader
            isHeader: true
        }

        Repeater {
            model: parent.rows

            delegate: ShortcutRow {
                required property var modelData
                keyText: modelData.key
                actionText: modelData.action
            }
        }
    }

    Column {
        id: usageSection
        width: parent.width
        spacing: 0
        property bool expanded: true

        SettingsSectionLabel {
            width: parent.width
            text: I18n.trFor("quickCapture", "How to Use")
            collapsible: true
            expanded: usageSection.expanded
            onToggleRequested: usageSection.expanded = !usageSection.expanded
        }

        SettingsGroup {
            width: parent.width
            slotColor: SettingsMetrics.controlColor
            visible: usageSection.expanded

            Repeater {
                model: [
                    {
                        icon: "touch_app",
                        title: I18n.trFor("quickCapture", "Left-click"),
                        subtitle: I18n.trFor("quickCapture", "Open the Quick Capture menu popout.")
                    },
                    {
                        icon: "mouse",
                        title: I18n.trFor("quickCapture", "Middle-click"),
                        subtitle: I18n.trFor("quickCapture", "Trigger the configured middle-click capture action.")
                    },
                    {
                        icon: "tune",
                        title: I18n.trFor("quickCapture", "Right-click"),
                        subtitle: I18n.trFor("quickCapture", "Trigger the configured right-click capture action.")
                    },
                    {
                        icon: "image",
                        title: I18n.trFor("quickCapture", "Drag Image"),
                        subtitle: I18n.trFor("quickCapture", "Drop an image onto the bar icon to annotate it.")
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
        id: toolShortcutsSection
        width: parent.width
        spacing: 0
        property bool expanded: false

        SettingsSectionLabel {
            width: parent.width
            text: I18n.trFor("quickCapture", "Annotation Tools")
            collapsible: true
            expanded: toolShortcutsSection.expanded
            onToggleRequested: toolShortcutsSection.expanded = !toolShortcutsSection.expanded
        }

        SettingsGroup {
            width: parent.width
            slotColor: SettingsMetrics.controlColor
            visible: toolShortcutsSection.expanded

            Item {
                width: parent.width
                height: toolShortcutsCol.implicitHeight + Theme.spacingM * 2

                Column {
                    id: toolShortcutsCol
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: Theme.spacingM

                    ShortcutTable {
                        keyHeader: I18n.trFor("quickCapture", "Key")
                        actionHeader: I18n.trFor("quickCapture", "Selected Tool / Action")
                        rows: root.toolRows
                    }
                }
            }
        }
    }

    Column {
        id: generalShortcutsSection
        width: parent.width
        spacing: 0
        property bool expanded: false

        SettingsSectionLabel {
            width: parent.width
            text: I18n.trFor("quickCapture", "General Shortcuts")
            collapsible: true
            expanded: generalShortcutsSection.expanded
            onToggleRequested: generalShortcutsSection.expanded = !generalShortcutsSection.expanded
        }

        SettingsGroup {
            width: parent.width
            slotColor: SettingsMetrics.controlColor
            visible: generalShortcutsSection.expanded

            Item {
                width: parent.width
                height: generalShortcutsCol.implicitHeight + Theme.spacingM * 2

                Column {
                    id: generalShortcutsCol
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: Theme.spacingM

                    ShortcutTable {
                        keyHeader: I18n.trFor("quickCapture", "Key")
                        actionHeader: I18n.trFor("quickCapture", "Shortcut Action")
                        rows: root.generalRows
                    }
                }
            }
        }
    }

    Column {
        id: ipcSection
        width: parent.width
        spacing: 0
        property bool expanded: false

        SettingsSectionLabel {
            width: parent.width
            text: I18n.trFor("quickCapture", "IPC Commands")
            collapsible: true
            expanded: ipcSection.expanded
            onToggleRequested: ipcSection.expanded = !ipcSection.expanded
        }

        SettingsGroup {
            width: parent.width
            slotColor: SettingsMetrics.controlColor
            visible: ipcSection.expanded

            Item {
                width: parent.width
                height: ipcCol.implicitHeight + Theme.spacingM * 2

                Column {
                    id: ipcCol
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: Theme.spacingM
                    spacing: Theme.spacingS

                    StyledText {
                        width: parent.width
                        text: I18n.trFor("quickCapture", "Each command accepts action: %1 (open editor) or %2 (always-on-top window).").arg("<b>edit</b>").arg("<b>float</b>")
                        wrapMode: Text.WordWrap
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.surfaceVariantText
                        textFormat: Text.RichText
                    }

                    Repeater {
                        model: root.screenshotCommands

                        delegate: Column {
                            required property var modelData
                            width: parent.width
                            spacing: Theme.spacingS

                            CopyBox {
                                label: modelData.label + " · " + I18n.trFor("quickCapture", "Edit")
                                text: "dms ipc call quickCapture " + modelData.command + " edit"
                            }

                            CopyBox {
                                label: modelData.label + " · " + I18n.trFor("quickCapture", "Float")
                                text: "dms ipc call quickCapture " + modelData.command + " float"
                            }
                        }
                    }

                    Repeater {
                        model: root.otherCommands

                        delegate: CopyBox {
                            required property var modelData
                            label: modelData.label
                            text: "dms ipc call quickCapture " + modelData.command
                        }
                    }

                    CopyBox {
                        label: I18n.trFor("quickCapture", "Niri Binding Example")
                        text: "binds {\n    Print { spawn \"dms\" \"ipc\" \"call\" \"quickCapture\" \"screenshot\" \"region\" \"edit\"; }\n}"
                    }
                }
            }
        }
    }

    Column {
        id: creditsSection
        width: parent.width
        spacing: 0
        property bool expanded: false

        SettingsSectionLabel {
            width: parent.width
            text: I18n.trFor("quickCapture", "Credits")
            collapsible: true
            expanded: creditsSection.expanded
            onToggleRequested: creditsSection.expanded = !creditsSection.expanded
        }

        SettingsGroup {
            width: parent.width
            slotColor: SettingsMetrics.controlColor
            visible: creditsSection.expanded

            Repeater {
                model: root.creditsItems

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
