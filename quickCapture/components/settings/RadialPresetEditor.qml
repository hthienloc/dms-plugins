import QtQuick
import qs.Common
import qs.DCommon.Widgets
import qs.Modules.Settings.Widgets
import qs.Services
import "../core/Constants.js" as Constants

Column {
    id: root

    property QtObject config: null
    property var settings: null
    required property int presetIndex

    width: parent ? parent.width : 0
    spacing: 0

    readonly property string defaultTool: Constants.defaultRadialTools[root.presetIndex] ?? "none"
    readonly property string defaultColor: Constants.defaultRadialColors[root.presetIndex]
    readonly property var meta: Constants.getToolMeta(root.presetTool)

    property string presetTool: defaultTool
    property string presetColor: defaultColor
    property int presetThickness: Constants.getToolMeta(defaultTool).defaultValue

    readonly property var toolOptions: [
        {
            label: I18n.trFor("quickCapture", "None"),
            value: "none"
        }
    ].concat(root.config ? root.config.toolOptions(root.config.presetToolIds) : [])

    function loadValue() {
        if (!settings)
            return;
        presetTool = settings.loadValue("preset_" + root.presetIndex + "_tool", root.defaultTool);
        presetColor = settings.loadValue("preset_" + root.presetIndex + "_color", root.defaultColor);
        const toolMeta = Constants.getToolMeta(presetTool);
        presetThickness = settings.loadValue("preset_" + root.presetIndex + "_thickness", toolMeta.defaultValue);
    }

    function save(key, val) {
        if (settings)
            settings.saveValue(key, val);
    }

    onSettingsChanged: loadValue()
    Component.onCompleted: loadValue()

    SettingsDropdownRow {
        text: I18n.trFor("quickCapture", "Tool")
        options: root.toolOptions.map(o => o.label)
        optionValues: root.toolOptions.map(o => o.value)
        currentValue: root.presetTool
        modified: root.presetTool !== root.defaultTool
        resetByKeys: false
        onResetRequested: {
            const oldDefault = root.meta.defaultValue;
            root.presetTool = root.defaultTool;
            root.save("preset_" + root.presetIndex + "_tool", root.defaultTool);
            const newMeta = Constants.getToolMeta(root.defaultTool);
            const inRange = root.presetThickness >= newMeta.min && root.presetThickness <= newMeta.max;
            if (!inRange || root.presetThickness === oldDefault) {
                root.presetThickness = newMeta.defaultValue;
                root.save("preset_" + root.presetIndex + "_thickness", newMeta.defaultValue);
            }
        }
        onValueChanged: val => {
            const oldDefault = root.meta.defaultValue;
            root.presetTool = val;
            root.save("preset_" + root.presetIndex + "_tool", val);
            const newMeta = Constants.getToolMeta(val);
            const inRange = root.presetThickness >= newMeta.min && root.presetThickness <= newMeta.max;
            if (!inRange || root.presetThickness === oldDefault) {
                root.presetThickness = newMeta.defaultValue;
                root.save("preset_" + root.presetIndex + "_thickness", newMeta.defaultValue);
            }
        }
    }

    Item {
        width: parent.width
        height: colorCol.implicitHeight + Theme.spacingM * 2

        Column {
            id: colorCol
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.margins: Theme.spacingM
            spacing: Theme.spacingS

            StyledText {
                text: I18n.trFor("quickCapture", "Color")
                font.pixelSize: Theme.fontSizeLarge
                font.weight: Font.Medium
                color: Theme.surfaceText
            }

            ColorPalettePicker {
                slotColors: root.config ? root.config.slotColors : []
                value: root.presetColor
                customColor: root.config ? root.config.resolveColor(root.presetColor) : Theme.primary
                customLabel: root.presetColor === "primary" ? I18n.trFor("quickCapture", "Primary").toUpperCase() : root.presetColor.toString().toUpperCase()
                onValueSelected: selectedValue => {
                    root.presetColor = selectedValue;
                    root.save("preset_" + root.presetIndex + "_color", selectedValue);
                }
                onCustomRequested: {
                    const picker = PopoutService.colorPickerModal;
                    if (!picker)
                        return;
                    picker.selectedColor = root.config ? root.config.resolveColor(root.presetColor) : Theme.primary;
                    picker.pickerTitle = I18n.trFor("quickCapture", "Color");
                    picker.onColorSelectedCallback = selectedColor => {
                        const hex = selectedColor.toString();
                        root.presetColor = hex;
                        root.save("preset_" + root.presetIndex + "_color", hex);
                    };
                    picker.show();
                }
            }
        }
    }

    SettingsSliderRow {
        text: root.config ? root.config.toolMetricLabel(root.presetTool) : I18n.trFor("quickCapture", "Size")
        value: root.presetThickness
        minimum: root.meta.min
        maximum: root.meta.max
        step: root.meta.step !== undefined ? root.meta.step : 1
        unit: root.meta.unit
        modified: root.presetThickness !== root.meta.defaultValue
        resetByKeys: false
        onResetRequested: {
            root.presetThickness = root.meta.defaultValue;
            root.save("preset_" + root.presetIndex + "_thickness", root.meta.defaultValue);
        }
        onSliderDragFinished: finalValue => {
            root.presetThickness = finalValue;
            root.save("preset_" + root.presetIndex + "_thickness", finalValue);
        }
    }
}
