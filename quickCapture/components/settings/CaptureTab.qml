import QtQuick
import qs.Common
import qs.DCommon.Widgets
import qs.Modules.Settings.Widgets

Column {
    id: root

    property QtObject config: null
    property var settings: null

    width: parent ? parent.width : 0
    spacing: Theme.spacingM

    readonly property var captureModes: [
        I18n.trFor("quickCapture", "Region"),
        I18n.trFor("quickCapture", "Fullscreen"),
        I18n.trFor("quickCapture", "All Outputs"),
        I18n.trFor("quickCapture", "Specific Output"),
        I18n.trFor("quickCapture", "Window"),
        I18n.trFor("quickCapture", "Last Region"),
        I18n.trFor("quickCapture", "Scrolling"),
        I18n.trFor("quickCapture", "Clipboard"),
        I18n.trFor("quickCapture", "File")
    ]
    readonly property var captureModeValues: [
        "region",
        "full",
        "all",
        "output",
        "window",
        "last",
        "scroll",
        "clipboard",
        "selectFile"
    ]

    readonly property var leftClickModes: [
        I18n.trFor("quickCapture", "Popout Menu"),
        I18n.trFor("quickCapture", "Compact Bottom Toolbar"),
        I18n.trFor("quickCapture", "Toggle Menu (IPC)"),
        ...captureModes
    ]
    readonly property var leftClickModeValues: [
        "popout",
        "compactToolbar",
        "toggle",
        ...captureModeValues
    ]

    property string leftClickAction: "popout"
    property string middleClickAction: "region"
    property string rightClickAction: "clipboard"
    property string menuRightClickAction: "copy"

    property string outputTargetName: ""
    property bool skipConfirm: false
    property bool includeCursor: false
    property bool defaultHideControlCenter: true
    property bool resetLastRegion: false
    property string regionHudScale: "auto"
    property int scrollInterval: 500

    function loadValue() {
        if (!settings)
            return;
        leftClickAction = settings.loadValue("leftClickAction", "popout");
        middleClickAction = settings.loadValue("middleClickAction", "region");
        rightClickAction = settings.loadValue("rightClickAction", "clipboard");
        menuRightClickAction = settings.loadValue("menuRightClickAction", "copy");
        outputTargetName = settings.loadValue("outputTargetName", "");
        skipConfirm = settings.loadValue("skipConfirm", false);
        includeCursor = settings.loadValue("includeCursor", false);
        defaultHideControlCenter = settings.loadValue("defaultHideControlCenter", true);
        resetLastRegion = settings.loadValue("resetLastRegion", false);
        regionHudScale = settings.loadValue("regionHudScale", "auto");
        scrollInterval = settings.loadValue("scrollInterval", 500);
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
            text: I18n.trFor("quickCapture", "Capture Actions")
        }

        SettingsGroup {
            width: parent.width
            slotColor: SettingsMetrics.controlColor

            SettingsDropdownRow {
                text: I18n.trFor("quickCapture", "Left Click Action")
                options: root.leftClickModes
                optionValues: root.leftClickModeValues
                currentValue: root.leftClickAction
                modified: root.leftClickAction !== "popout"
                resetByKeys: false
                onResetRequested: {
                    root.leftClickAction = "popout";
                    root.save("leftClickAction", "popout");
                }
                onValueChanged: val => {
                    root.leftClickAction = val;
                    root.save("leftClickAction", val);
                }
            }

            SettingsDropdownRow {
                text: I18n.trFor("quickCapture", "Middle Click Action")
                options: root.captureModes
                optionValues: root.captureModeValues
                currentValue: root.middleClickAction
                modified: root.middleClickAction !== "region"
                resetByKeys: false
                onResetRequested: {
                    root.middleClickAction = "region";
                    root.save("middleClickAction", "region");
                }
                onValueChanged: val => {
                    root.middleClickAction = val;
                    root.save("middleClickAction", val);
                }
            }

            SettingsDropdownRow {
                text: I18n.trFor("quickCapture", "Right Click Action")
                options: root.captureModes
                optionValues: root.captureModeValues
                currentValue: root.rightClickAction
                modified: root.rightClickAction !== "clipboard"
                resetByKeys: false
                onResetRequested: {
                    root.rightClickAction = "clipboard";
                    root.save("rightClickAction", "clipboard");
                }
                onValueChanged: val => {
                    root.rightClickAction = val;
                    root.save("rightClickAction", val);
                }
            }

            SettingsDropdownRow {
                text: I18n.trFor("quickCapture", "Menu Item Right Click")
                options: [
                    I18n.trFor("quickCapture", "Copy"),
                    I18n.trFor("quickCapture", "Save"),
                    I18n.trFor("quickCapture", "Copy & Save"),
                    I18n.trFor("quickCapture", "Float")
                ]
                optionValues: ["copy", "save", "copyAndSave", "float"]
                currentValue: root.menuRightClickAction
                modified: root.menuRightClickAction !== "copy"
                resetByKeys: false
                onResetRequested: {
                    root.menuRightClickAction = "copy";
                    root.save("menuRightClickAction", "copy");
                }
                onValueChanged: val => {
                    root.menuRightClickAction = val;
                    root.save("menuRightClickAction", val);
                }
            }
        }
    }

    Column {
        width: parent.width
        spacing: 0

        SettingsSectionLabel {
            width: parent.width
            text: I18n.trFor("quickCapture", "Capture Options")
        }

        SettingsGroup {
            width: parent.width
            slotColor: SettingsMetrics.controlColor

            SettingsTextFieldRow {
                id: outputTargetField
                text: I18n.trFor("quickCapture", "Target Output Name")
                placeholderText: "e.g. eDP-1"
                value: root.outputTargetName
                modified: root.outputTargetName !== ""
                onResetRequested: {
                    root.outputTargetName = "";
                    outputTargetField.value = "";
                    root.save("outputTargetName", "");
                }
                onValueEdited: val => {
                    root.outputTargetName = val;
                    root.save("outputTargetName", val);
                }
            }

            SettingsToggleRow {
                text: I18n.trFor("quickCapture", "Skip confirmation")
                checked: root.skipConfirm
                modified: root.skipConfirm !== false
                resetByKeys: false
                onResetRequested: {
                    root.skipConfirm = false;
                    root.save("skipConfirm", false);
                }
                onToggled: isChecked => {
                    root.skipConfirm = isChecked;
                    root.save("skipConfirm", isChecked);
                }
            }

            SettingsToggleRow {
                text: I18n.trFor("quickCapture", "Include Cursor")
                checked: root.includeCursor
                modified: root.includeCursor !== false
                resetByKeys: false
                onResetRequested: {
                    root.includeCursor = false;
                    root.save("includeCursor", false);
                }
                onToggled: isChecked => {
                    root.includeCursor = isChecked;
                    root.save("includeCursor", isChecked);
                }
            }

            SettingsToggleRow {
                text: I18n.trFor("quickCapture", "Hide Control Center on Capture")
                description: I18n.trFor("quickCapture", "Close Control Center before panel-triggered captures.")
                checked: root.defaultHideControlCenter
                modified: root.defaultHideControlCenter !== true
                resetByKeys: false
                onResetRequested: {
                    root.defaultHideControlCenter = true;
                    root.save("defaultHideControlCenter", true);
                }
                onToggled: isChecked => {
                    root.defaultHideControlCenter = isChecked;
                    root.save("defaultHideControlCenter", isChecked);
                }
            }

            SettingsToggleRow {
                text: I18n.trFor("quickCapture", "Reset Last Region")
                description: I18n.trFor("quickCapture", "Clear saved region selection before each capture")
                checked: root.resetLastRegion
                modified: root.resetLastRegion !== false
                resetByKeys: false
                onResetRequested: {
                    root.resetLastRegion = false;
                    root.save("resetLastRegion", false);
                }
                onToggled: isChecked => {
                    root.resetLastRegion = isChecked;
                    root.save("resetLastRegion", isChecked);
                }
            }

            SettingsDropdownRow {
                text: I18n.trFor("quickCapture", "Region HUD Scale")
                description: I18n.trFor("quickCapture", "Keybinding overlay size in interactive region selector.")
                options: [
                    I18n.trFor("quickCapture", "Auto (Screen Scale)"),
                    I18n.trFor("quickCapture", "Off (Hidden)"),
                    "1x",
                    "2x",
                    "3x",
                    "4x"
                ]
                optionValues: ["auto", "off", "1", "2", "3", "4"]
                currentValue: root.regionHudScale
                modified: root.regionHudScale !== "auto"
                resetByKeys: false
                onResetRequested: {
                    root.regionHudScale = "auto";
                    root.save("regionHudScale", "auto");
                }
                onValueChanged: val => {
                    root.regionHudScale = val;
                    root.save("regionHudScale", val);
                }
            }

            SettingsNoteRow {
                noteIconName: "info"
                tint: Theme.primary
                tintBackground: Theme.withAlpha(Theme.primary, 0.08)
                text: I18n.trFor("quickCapture", "Scroll capture: select a region, scroll content, then press %1 to finish.").arg("Enter")
            }

            SettingsSliderRow {
                text: I18n.trFor("quickCapture", "Scroll Interval")
                value: root.scrollInterval
                minimum: 200
                maximum: 2000
                step: 50
                unit: "ms"
                modified: root.scrollInterval !== 500
                resetByKeys: false
                onResetRequested: {
                    root.scrollInterval = 500;
                    root.save("scrollInterval", 500);
                }
                onSliderDragFinished: finalValue => {
                    root.scrollInterval = finalValue;
                    root.save("scrollInterval", finalValue);
                }
            }
        }
    }
}
