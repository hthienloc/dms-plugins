import QtQuick
import qs.Common
import qs.DCommon.Widgets
import qs.Modules.Settings.Widgets
import "../core/Defaults.js" as Defaults

Column {
    id: root

    property QtObject config: null
    property var settings: null

    width: parent ? parent.width : 0
    spacing: Theme.spacingM

    property bool showToolbar: Defaults.values.showToolbar
    property string toolbarPosition: Defaults.values.toolbarPosition
    property bool showToolbarBorder: Defaults.values.showToolbarBorder
    property bool show_shortcut_hints: Defaults.values.show_shortcut_hints

    function loadValue() {
        if (!settings)
            return;
        showToolbar = settings.loadValue("showToolbar", Defaults.values.showToolbar);
        toolbarPosition = settings.loadValue("toolbarPosition", Defaults.values.toolbarPosition);
        showToolbarBorder = settings.loadValue("showToolbarBorder", Defaults.values.showToolbarBorder);
        show_shortcut_hints = settings.loadValue("show_shortcut_hints", Defaults.values.show_shortcut_hints);
    }

    function save(key, val) {
        if (settings)
            settings.saveValue(key, val);
    }

    onSettingsChanged: loadValue()
    Component.onCompleted: loadValue()

    Column {
        width: parent.width
        spacing: 0

        SettingsSectionLabel {
            width: parent.width
            text: I18n.trFor("quickCapture", "Toolbar")
        }

        SettingsGroup {
            width: parent.width
            slotColor: SettingsMetrics.controlColor

            SettingsToggleRow {
                text: I18n.trFor("quickCapture", "Show Toolbar")
                checked: root.showToolbar
                modified: root.showToolbar !== Defaults.values.showToolbar
                resetByKeys: false
                onResetRequested: {
                    root.showToolbar = Defaults.values.showToolbar;
                    root.save("showToolbar", Defaults.values.showToolbar);
                }
                onToggled: isChecked => {
                    root.showToolbar = isChecked;
                    root.save("showToolbar", isChecked);
                }
            }

            SettingsButtonGroupRow {
                visible: root.showToolbar
                text: I18n.trFor("quickCapture", "Toolbar Position")
                model: [
                    I18n.trFor("quickCapture", "Top"),
                    I18n.trFor("quickCapture", "Bottom"),
                    I18n.trFor("quickCapture", "Left"),
                    I18n.trFor("quickCapture", "Right")
                ]
                values: ["top", "bottom", "left", "right"]
                value: root.toolbarPosition
                modified: root.toolbarPosition !== Defaults.values.toolbarPosition
                resetByKeys: false
                onResetRequested: {
                    root.toolbarPosition = Defaults.values.toolbarPosition;
                    root.save("toolbarPosition", Defaults.values.toolbarPosition);
                }
                onValueSelected: val => {
                    root.toolbarPosition = val;
                    root.save("toolbarPosition", val);
                }
            }

            SettingsToggleRow {
                visible: root.showToolbar
                text: I18n.trFor("quickCapture", "Show Toolbar Border")
                checked: root.showToolbarBorder
                modified: root.showToolbarBorder !== Defaults.values.showToolbarBorder
                resetByKeys: false
                onResetRequested: {
                    root.showToolbarBorder = Defaults.values.showToolbarBorder;
                    root.save("showToolbarBorder", Defaults.values.showToolbarBorder);
                }
                onToggled: isChecked => {
                    root.showToolbarBorder = isChecked;
                    root.save("showToolbarBorder", isChecked);
                }
            }

            SettingsToggleRow {
                visible: root.showToolbar
                text: I18n.trFor("quickCapture", "Show Keyboard Shortcut Hints")
                checked: root.show_shortcut_hints
                modified: root.show_shortcut_hints !== Defaults.values.show_shortcut_hints
                resetByKeys: false
                onResetRequested: {
                    root.show_shortcut_hints = Defaults.values.show_shortcut_hints;
                    root.save("show_shortcut_hints", Defaults.values.show_shortcut_hints);
                }
                onToggled: isChecked => {
                    root.show_shortcut_hints = isChecked;
                    root.save("show_shortcut_hints", isChecked);
                }
            }
        }
    }
}
