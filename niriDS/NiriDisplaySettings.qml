import "./shared"
import QtQuick
import qs.Common
import qs.DCommon.Widgets
import qs.Modules.Plugins
import qs.Modules.Settings.Widgets

PluginSettings {
    id: root
    pluginId: "niriDS"

    readonly property string defaultConnectionAction: "show_menu"
    readonly property bool defaultEnableFallback: true
    readonly property string defaultFallbackDisplay: ""
    readonly property int defaultBgOpacity: 50

    property string connectionAction: defaultConnectionAction
    property bool enableFallback: defaultEnableFallback
    property string fallbackDisplay: defaultFallbackDisplay
    property int bgOpacity: defaultBgOpacity

    function loadSettings() {
        if (!pluginService)
            return;
        connectionAction = loadValue("connectionAction", defaultConnectionAction);
        enableFallback = loadValue("enableFallback", defaultEnableFallback);
        fallbackDisplay = loadValue("fallbackDisplay", defaultFallbackDisplay);
        bgOpacity = loadValue("bgOpacity", defaultBgOpacity);
        ipcSection.expanded = loadValue("ipcCommandsExpanded", false);
        usageSection.expanded = loadValue("usageGuideExpanded", true);
    }

    Component.onCompleted: loadSettings()
    onPluginServiceChanged: loadSettings()

    Column {
        width: parent ? parent.width : 0
        spacing: 0

        SettingsSectionLabel {
            width: parent.width
            text: I18n.trFor("niriDS", "Display Behavior")
        }

        SettingsGroup {
            width: parent.width
            slotColor: SettingsMetrics.controlColor

            SettingsDropdownRow {
                text: I18n.trFor("niriDS", "When monitor is connected")
                description: I18n.trFor("niriDS", "Choose what happens automatically when an external monitor is plugged in")
                options: [
                    I18n.trFor("niriDS", "Show Menu"),
                    I18n.trFor("niriDS", "External Only"),
                    I18n.trFor("niriDS", "Extended"),
                    I18n.trFor("niriDS", "Internal Only"),
                    I18n.trFor("niriDS", "Mirror"),
                    I18n.trFor("niriDS", "Do Nothing")
                ]
                optionValues: ["show_menu", "external_only", "extend", "internal_only", "mirror", "none"]
                currentValue: root.connectionAction
                modified: root.connectionAction !== root.defaultConnectionAction
                resetByKeys: false
                onResetRequested: {
                    root.connectionAction = root.defaultConnectionAction;
                    root.saveValue("connectionAction", root.defaultConnectionAction);
                }
                onValueChanged: val => {
                    root.connectionAction = val;
                    root.saveValue("connectionAction", val);
                }
            }

            SettingsToggleRow {
                text: I18n.trFor("niriDS", "Enable safety fallback")
                description: I18n.trFor("niriDS", "Re-enable laptop screen when all external monitors disconnect.")
                checked: root.enableFallback
                modified: root.enableFallback !== root.defaultEnableFallback
                resetByKeys: false
                onResetRequested: {
                    root.enableFallback = root.defaultEnableFallback;
                    root.saveValue("enableFallback", root.defaultEnableFallback);
                }
                onToggled: isChecked => {
                    root.enableFallback = isChecked;
                    root.saveValue("enableFallback", isChecked);
                }
            }

            SettingsTextFieldRow {
                id: fallbackDisplayField
                text: I18n.trFor("niriDS", "Preferred internal display")
                description: I18n.trFor("niriDS", "The name of your laptop display (e.g. eDP-1). Leave empty for auto-detection.")
                placeholderText: "eDP-1"
                value: root.fallbackDisplay
                modified: root.fallbackDisplay !== root.defaultFallbackDisplay
                onResetRequested: {
                    root.fallbackDisplay = root.defaultFallbackDisplay;
                    fallbackDisplayField.value = root.defaultFallbackDisplay;
                    root.saveValue("fallbackDisplay", root.defaultFallbackDisplay);
                }
                onValueEdited: newValue => {
                    root.fallbackDisplay = newValue;
                    root.saveValue("fallbackDisplay", newValue);
                }
            }

            SettingsSliderRow {
                text: I18n.trFor("niriDS", "Modal Background Opacity")
                description: I18n.trFor("niriDS", "Adjust the background dimming opacity when the display settings modal is open")
                minimum: 0
                maximum: 100
                step: 5
                unit: "%"
                value: root.bgOpacity
                modified: root.bgOpacity !== root.defaultBgOpacity
                resetByKeys: false
                onResetRequested: {
                    root.bgOpacity = root.defaultBgOpacity;
                    root.saveValue("bgOpacity", root.defaultBgOpacity);
                }
                onSliderDragFinished: finalValue => {
                    root.bgOpacity = finalValue;
                    root.saveValue("bgOpacity", finalValue);
                }
            }
        }
    }

    Column {
        id: ipcSection
        width: parent ? parent.width : 0
        spacing: 0

        property bool expanded: false

        SettingsSectionLabel {
            width: parent.width
            text: I18n.trFor("niriDS", "IPC Commands")
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
                    label: I18n.trFor("niriDS", "Toggle Modal")
                    text: "dms ipc call niriDS toggle"
                }

                CopyBox {
                    label: I18n.trFor("niriDS", "Open Modal")
                    text: "dms ipc call niriDS open"
                }

                CopyBox {
                    label: I18n.trFor("niriDS", "Close Modal")
                    text: "dms ipc call niriDS close"
                }

                CopyBox {
                    label: I18n.trFor("niriDS", "Apply: Internal Only")
                    text: "dms ipc call niriDS apply internal_only"
                }

                CopyBox {
                    label: I18n.trFor("niriDS", "Apply: External Only")
                    text: "dms ipc call niriDS apply external_only"
                }

                CopyBox {
                    label: I18n.trFor("niriDS", "Apply: Extend Displays")
                    text: "dms ipc call niriDS apply extend"
                }

                CopyBox {
                    label: I18n.trFor("niriDS", "Apply: Mirror Displays")
                    text: "dms ipc call niriDS apply mirror"
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: Theme.outline
                    opacity: 0.1
                }

                CopyBox {
                    label: I18n.trFor("niriDS", "Niri Binding Configuration")
                    text: "Mod+P { spawn \"dms\" \"ipc\" \"call\" \"niriDS\" \"toggle\"; }"
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
            text: I18n.trFor("niriDS", "How to Use")
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
                        icon: "monitor",
                        title: I18n.trFor("niriDS", "Display Selector"),
                        subtitle: I18n.trFor("niriDS", "Open the display selector from the Control Center or configured keybindings.")
                    },
                    {
                        icon: "tune",
                        title: I18n.trFor("niriDS", "Manual Control"),
                        subtitle: I18n.trFor("niriDS", "Manual Control toggles are session-only; use DMS Settings → Displays for persistent settings.")
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
