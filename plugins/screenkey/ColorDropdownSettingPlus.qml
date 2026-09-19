import QtQuick
import qs.Common
import qs.Widgets

Item {
    id: root

    required property string settingKey
    required property string label
    property string description: ""
    property var defaultValueMode: "default"
    property var defaultValueCustom: "#6750A4"

    property string modeValue: defaultValueMode
    property string customValue: defaultValueCustom

    width: parent.width
    implicitHeight: dropdownRow.implicitHeight

    property bool isInitialized: false
    readonly property bool isDirty: modeValue !== defaultValueMode || customValue !== defaultValueCustom

    function resetToDefault() {
        modeValue = defaultValueMode;
        customValue = defaultValueCustom;
    }

    function loadValues() {
        const settings = findSettings();
        if (settings) {
            modeValue = settings.loadValue(settingKey + "Mode", defaultValueMode);
            customValue = settings.loadValue(settingKey + "Custom", defaultValueCustom);
            isInitialized = true;
        }
    }

    Component.onCompleted: Qt.callLater(loadValues)

    onModeValueChanged: {
        if (!isInitialized) return;
        const settings = findSettings();
        if (settings) settings.saveValue(settingKey + "Mode", modeValue);
    }

    onCustomValueChanged: {
        if (!isInitialized) return;
        const settings = findSettings();
        if (settings) settings.saveValue(settingKey + "Custom", customValue);
    }

    function findSettings() {
        let item = parent;
        while (item) {
            if (item.saveValue !== undefined && item.loadValue !== undefined) return item;
            item = item.parent;
        }
        return null;
    }

    ColorDropdownRow {
        id: dropdownRow
        text: root.label
        description: root.description
        options: [
            { value: "default", label: I18n.tr("Primary") },
            { value: "primaryContainer", label: I18n.tr("Primary Container") },
            { value: "secondary", label: I18n.tr("Secondary") },
            { value: "secondaryContainer", label: I18n.tr("Secondary Container") },
            { value: "tertiary", label: I18n.tr("Tertiary") },
            { value: "tertiaryContainer", label: I18n.tr("Tertiary Container") },
            { value: "custom", label: I18n.tr("Custom") }
        ]
        currentMode: root.modeValue
        customColor: root.customValue
        onModeSelected: mode => { root.modeValue = mode }
        onCustomColorSelected: color => { root.customValue = color.toString() }
    }
}
