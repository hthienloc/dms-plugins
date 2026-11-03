import QtQuick
import qs.Common
import qs.Modules.Plugins
import "./shared"

PluginSettings {
    id: root
    pluginId: "niriDS"

    SettingsCard {
        id: generalSettingsSection
        SectionTitle { 
            text: I18n.trFor("niriDS", "General Settings")
            icon: "settings" 
            showReset: connectionAction.isDirty || enableFallback.isDirty || fallbackDisplay.isDirty || bgOpacity.isDirty
            onResetClicked: {
                connectionAction.resetToDefault();
                enableFallback.resetToDefault();
                fallbackDisplay.resetToDefault();
                bgOpacity.resetToDefault();
            }
        }

        SelectionSettingPlus {
            id: connectionAction
            settingKey: "connectionAction"
            label: I18n.trFor("niriDS", "When monitor is connected")
            description: I18n.trFor("niriDS", "Choose what happens automatically when an external monitor is plugged in")
            options: [
                { label: I18n.trFor("niriDS", "Show Menu"), value: "show_menu" },
                { label: I18n.trFor("niriDS", "External Only"), value: "external_only" },
                { label: I18n.trFor("niriDS", "Extended"), value: "extend" },
                { label: I18n.trFor("niriDS", "Internal Only"), value: "internal_only" },
                { label: I18n.trFor("niriDS", "Mirror"), value: "mirror" },
                { label: I18n.trFor("niriDS", "Do Nothing"), value: "none" }
            ]
            defaultValue: "show_menu"
        }

        Separator {}

        ToggleSettingPlus {
            id: enableFallback
            settingKey: "enableFallback"
            label: I18n.trFor("niriDS", "Enable safety fallback")
            description: I18n.trFor("niriDS", "Automatically re-enable the laptop screen if all external monitors are disconnected")
            defaultValue: true
        }

        Separator {}

        StringSettingPlus {
            id: fallbackDisplay
            settingKey: "fallbackDisplay"
            label: I18n.trFor("niriDS", "Preferred internal display")
            description: I18n.trFor("niriDS", "The name of your laptop display (e.g. eDP-1). Leave empty for auto-detection.")
            placeholder: "eDP-1"
            defaultValue: ""
        }

        Separator {}

        SliderSettingPlus {
            id: bgOpacity
            settingKey: "bgOpacity"
            label: I18n.trFor("niriDS", "Modal Background Opacity")
            description: I18n.trFor("niriDS", "Adjust the background dimming opacity when the display settings modal is open")
            minimum: 0
            maximum: 100
            defaultValue: 50
            unit: "%"
            previewType: "opacity"
        }
    }

    SettingsCard {
        SectionTitle {
            id: ipcTitle
            text: I18n.trFor("niriDS", "IPC Commands")
            icon: "terminal"
            collapsible: true
            isExpanded: false
            settingKey: "ipcCommandsExpanded"
        }

        Column {
            width: parent.width
            spacing: Theme.spacingM
            visible: ipcTitle.isExpanded

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

            Separator { opacity: 0.1 }

            CopyBox {
                label: I18n.trFor("niriDS", "Niri Binding Configuration")
                text: "Mod+P { spawn \"dms\" \"ipc\" \"call\" \"niriDS\" \"toggle\"; }"
            }
        }
    }

    SettingsCard {
        SectionTitle { 
            id: usageTitle
            text: I18n.trFor("niriDS", "Usage Guide")
            icon: "menu_book" 
            collapsible: true
            settingKey: "usageGuideExpanded"
        }

        UsageGuide {
            expanded: usageTitle.isExpanded
            items: [
                I18n.trFor("niriDS", "Activate the display selector via the <b>Control Center</b> or configured <b>keybindings</b>."),
                I18n.trFor("niriDS", "Use the <b>IPC commands</b> above to automate display switching.")
            ]
        }
    }
}
