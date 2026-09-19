import QtQuick
import qs.Common

Item {
    id: root

    required property string settingKey
    required property string label
    property string description: ""
    property string defaultValue: "system"
    property alias value: selector.value

    readonly property bool isDirty: selector.isDirty

    property var _fontOptions: _defaultOptions()
    property bool _enumerated: false

    width: parent.width
    implicitHeight: selector.implicitHeight

    function resetToDefault() {
        selector.resetToDefault();
    }

    function _defaultOptions() {
        return [
            {
                label: I18n.tr("System Default") + (Theme.fontFamily ? " (" + Theme.fontFamily + ")" : ""),
                value: "system"
            }
        ];
    }

    function _enumerateFonts() {
        if (_enumerated)
            return;

        const options = _defaultOptions();
        const fonts = Qt.fontFamilies().filter(f => !f.startsWith("."));
        fonts.sort();

        for (let i = 0; i < fonts.length; i++) {
            options.push({ label: fonts[i], value: fonts[i] });
        }

        _fontOptions = options;
        _enumerated = true;
    }

    Component.onCompleted: Qt.callLater(_enumerateFonts)

    SelectionSettingPlus {
        id: selector
        width: parent.width
        settingKey: root.settingKey
        label: root.label
        description: root.description
        defaultValue: root.defaultValue
        options: root._fontOptions
    }
}
