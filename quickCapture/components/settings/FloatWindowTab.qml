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

    property bool autoMinimize: Defaults.values.autoMinimize
    property int minimizeDelay: Defaults.values.minimizeDelay
    property int initialWidth: Defaults.values.initialWidth
    property int maxHeight: Defaults.values.maxHeight
    property int borderWidth: Defaults.values.borderWidth
    property string borderColor: Defaults.values.borderColor
    property bool transparentBg: Defaults.values.transparentBg
    property string spawnPosition: Defaults.values.spawnPosition
    property int edgeSpacing: Defaults.values.edgeSpacing
    property bool autoTiling: Defaults.values.autoTiling

    function loadValue() {
        if (!settings)
            return;
        autoMinimize = settings.loadValue("autoMinimize", Defaults.values.autoMinimize);
        minimizeDelay = settings.loadValue("minimizeDelay", Defaults.values.minimizeDelay);
        initialWidth = settings.loadValue("initialWidth", Defaults.values.initialWidth);
        maxHeight = settings.loadValue("maxHeight", Defaults.values.maxHeight);
        borderWidth = settings.loadValue("borderWidth", Defaults.values.borderWidth);
        borderColor = settings.loadValue("borderColor", Defaults.values.borderColor);
        transparentBg = settings.loadValue("transparentBg", Defaults.values.transparentBg);
        spawnPosition = settings.loadValue("spawnPosition", Defaults.values.spawnPosition);
        edgeSpacing = settings.loadValue("edgeSpacing", Defaults.values.edgeSpacing);
        autoTiling = settings.loadValue("autoTiling", Defaults.values.autoTiling);
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
            text: I18n.trFor("quickCapture", "Float Window")
        }

        SettingsGroup {
            width: parent.width
            slotColor: SettingsMetrics.controlColor

            SettingsToggleRow {
                text: I18n.trFor("quickCapture", "Auto-minimize")
                description: I18n.trFor("quickCapture", "Automatically minimize the float window after a delay")
                checked: root.autoMinimize
                modified: root.autoMinimize !== Defaults.values.autoMinimize
                resetByKeys: false
                onResetRequested: {
                    root.autoMinimize = Defaults.values.autoMinimize;
                    root.save("autoMinimize", Defaults.values.autoMinimize);
                }
                onToggled: isChecked => {
                    root.autoMinimize = isChecked;
                    root.save("autoMinimize", isChecked);
                }
            }

            SettingsSliderRow {
                visible: root.autoMinimize
                text: I18n.trFor("quickCapture", "Minimize Delay")
                value: root.minimizeDelay
                minimum: 500
                maximum: 10000
                step: 100
                unit: "ms"
                modified: root.minimizeDelay !== Defaults.values.minimizeDelay
                resetByKeys: false
                onResetRequested: {
                    root.minimizeDelay = Defaults.values.minimizeDelay;
                    root.save("minimizeDelay", Defaults.values.minimizeDelay);
                }
                onSliderDragFinished: finalValue => {
                    root.minimizeDelay = finalValue;
                    root.save("minimizeDelay", finalValue);
                }
            }

            SettingsSliderRow {
                text: I18n.trFor("quickCapture", "Initial Width")
                value: root.initialWidth
                minimum: 100
                maximum: 2000
                step: 10
                unit: "px"
                modified: root.initialWidth !== Defaults.values.initialWidth
                resetByKeys: false
                onResetRequested: {
                    root.initialWidth = Defaults.values.initialWidth;
                    root.save("initialWidth", Defaults.values.initialWidth);
                }
                onSliderDragFinished: finalValue => {
                    root.initialWidth = finalValue;
                    root.save("initialWidth", finalValue);
                }
            }

            SettingsSliderRow {
                text: I18n.trFor("quickCapture", "Max Height (%1 = no limit)").arg(0)
                value: root.maxHeight
                minimum: 0
                maximum: 2000
                step: 10
                unit: "px"
                modified: root.maxHeight !== Defaults.values.maxHeight
                resetByKeys: false
                onResetRequested: {
                    root.maxHeight = Defaults.values.maxHeight;
                    root.save("maxHeight", Defaults.values.maxHeight);
                }
                onSliderDragFinished: finalValue => {
                    root.maxHeight = finalValue;
                    root.save("maxHeight", finalValue);
                }
            }

            SettingsSliderRow {
                text: I18n.trFor("quickCapture", "Border Width")
                value: root.borderWidth
                minimum: 0
                maximum: 20
                step: 1
                unit: "px"
                modified: root.borderWidth !== Defaults.values.borderWidth
                resetByKeys: false
                onResetRequested: {
                    root.borderWidth = Defaults.values.borderWidth;
                    root.save("borderWidth", Defaults.values.borderWidth);
                }
                onSliderDragFinished: finalValue => {
                    root.borderWidth = finalValue;
                    root.save("borderWidth", finalValue);
                }
            }

            SettingsDropdownRow {
                text: I18n.trFor("quickCapture", "Border Color")
                options: [
                    I18n.trFor("quickCapture", "Outline Variant"),
                    I18n.trFor("quickCapture", "Primary"),
                    I18n.trFor("quickCapture", "Surface Container Highest"),
                    I18n.trFor("quickCapture", "Transparent")
                ]
                optionValues: ["outlineVariant", "primary", "surfaceContainerHighest", "transparent"]
                currentValue: root.borderColor
                modified: root.borderColor !== Defaults.values.borderColor
                resetByKeys: false
                onResetRequested: {
                    root.borderColor = Defaults.values.borderColor;
                    root.save("borderColor", Defaults.values.borderColor);
                }
                onValueChanged: val => {
                    root.borderColor = val;
                    root.save("borderColor", val);
                }
            }

            SettingsToggleRow {
                text: I18n.trFor("quickCapture", "Transparent Background")
                description: I18n.trFor("quickCapture", "Show only the image on a transparent background")
                checked: root.transparentBg
                modified: root.transparentBg !== Defaults.values.transparentBg
                resetByKeys: false
                onResetRequested: {
                    root.transparentBg = Defaults.values.transparentBg;
                    root.save("transparentBg", Defaults.values.transparentBg);
                }
                onToggled: isChecked => {
                    root.transparentBg = isChecked;
                    root.save("transparentBg", isChecked);
                }
            }

            SettingsDropdownRow {
                text: I18n.trFor("quickCapture", "Spawn Position")
                options: [
                    I18n.trFor("quickCapture", "Bottom Left"),
                    I18n.trFor("quickCapture", "Bottom Right"),
                    I18n.trFor("quickCapture", "Top Left"),
                    I18n.trFor("quickCapture", "Top Right"),
                    I18n.trFor("quickCapture", "Bottom"),
                    I18n.trFor("quickCapture", "Top"),
                    I18n.trFor("quickCapture", "Left"),
                    I18n.trFor("quickCapture", "Right"),
                    I18n.trFor("quickCapture", "Center")
                ]
                optionValues: [
                    "bottom-left",
                    "bottom-right",
                    "top-left",
                    "top-right",
                    "bottom",
                    "top",
                    "left",
                    "right",
                    "center"
                ]
                currentValue: root.spawnPosition
                modified: root.spawnPosition !== Defaults.values.spawnPosition
                resetByKeys: false
                onResetRequested: {
                    root.spawnPosition = Defaults.values.spawnPosition;
                    root.save("spawnPosition", Defaults.values.spawnPosition);
                }
                onValueChanged: val => {
                    root.spawnPosition = val;
                    root.save("spawnPosition", val);
                }
            }

            SettingsSliderRow {
                text: I18n.trFor("quickCapture", "Edge Spacing")
                value: root.edgeSpacing
                minimum: 0
                maximum: 100
                step: 1
                unit: "px"
                modified: root.edgeSpacing !== Defaults.values.edgeSpacing
                resetByKeys: false
                onResetRequested: {
                    root.edgeSpacing = Defaults.values.edgeSpacing;
                    root.save("edgeSpacing", Defaults.values.edgeSpacing);
                }
                onSliderDragFinished: finalValue => {
                    root.edgeSpacing = finalValue;
                    root.save("edgeSpacing", finalValue);
                }
            }

            SettingsToggleRow {
                text: I18n.trFor("quickCapture", "Auto-tiling")
                description: I18n.trFor("quickCapture", "Automatically stack windows to avoid overlap")
                checked: root.autoTiling
                modified: root.autoTiling !== Defaults.values.autoTiling
                resetByKeys: false
                onResetRequested: {
                    root.autoTiling = Defaults.values.autoTiling;
                    root.save("autoTiling", Defaults.values.autoTiling);
                }
                onToggled: isChecked => {
                    root.autoTiling = isChecked;
                    root.save("autoTiling", isChecked);
                }
            }
        }
    }
}
