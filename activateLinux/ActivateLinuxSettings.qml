import QtQuick
import qs.Common
import qs.DCommon.Widgets
import qs.Modules.Plugins
import qs.Modules.Settings.Widgets

PluginSettings {
    id: root
    pluginId: "activateLinux"

    readonly property int defaultWatermarkOpacity: 40
    readonly property int defaultFirstLineSize: 22
    readonly property int defaultSecondLineSize: 14
    readonly property bool defaultCustomizeText: false
    readonly property string defaultFirstLine: "Activate Linux"
    readonly property string defaultSecondLine: "Go to Settings to activate Linux."

    property int watermarkOpacity: defaultWatermarkOpacity
    property int firstLineSize: defaultFirstLineSize
    property int secondLineSize: defaultSecondLineSize
    property bool customizeText: defaultCustomizeText
    property string firstLine: defaultFirstLine
    property string secondLine: defaultSecondLine

    function loadSettings() {
        if (!pluginService)
            return;
        watermarkOpacity = loadValue("watermarkOpacity", defaultWatermarkOpacity);
        firstLineSize = loadValue("firstLineSize", defaultFirstLineSize);
        secondLineSize = loadValue("secondLineSize", defaultSecondLineSize);
        customizeText = loadValue("customizeText", defaultCustomizeText);
        firstLine = loadValue("firstLine", defaultFirstLine);
        secondLine = loadValue("secondLine", defaultSecondLine);
        usageSection.expanded = loadValue("usageGuideExpanded", true);
    }

    Component.onCompleted: loadSettings()
    onPluginServiceChanged: loadSettings()

    Column {
        width: parent ? parent.width : 0
        spacing: 0

        SettingsSectionLabel {
            width: parent.width
            text: I18n.trFor("activateLinux", "Appearance")
        }

        SettingsGroup {
            width: parent.width
            slotColor: SettingsMetrics.controlColor

            SettingsSliderRow {
                text: I18n.trFor("activateLinux", "Opacity")
                description: I18n.trFor("activateLinux", "Adjust the transparency of the watermark.")
                minimum: 0
                maximum: 100
                step: 5
                unit: "%"
                value: root.watermarkOpacity
                modified: root.watermarkOpacity !== root.defaultWatermarkOpacity
                resetByKeys: false
                onResetRequested: {
                    root.watermarkOpacity = root.defaultWatermarkOpacity;
                    root.saveValue("watermarkOpacity", root.defaultWatermarkOpacity);
                }
                onSliderDragFinished: finalValue => {
                    root.watermarkOpacity = finalValue;
                    root.saveValue("watermarkOpacity", finalValue);
                }
            }

            SettingsSliderRow {
                text: I18n.trFor("activateLinux", "First Line Font Size")
                minimum: 8
                maximum: 72
                step: 1
                value: root.firstLineSize
                modified: root.firstLineSize !== root.defaultFirstLineSize
                resetByKeys: false
                onResetRequested: {
                    root.firstLineSize = root.defaultFirstLineSize;
                    root.saveValue("firstLineSize", root.defaultFirstLineSize);
                }
                onSliderDragFinished: finalValue => {
                    root.firstLineSize = finalValue;
                    root.saveValue("firstLineSize", finalValue);
                }
            }

            SettingsSliderRow {
                text: I18n.trFor("activateLinux", "Second Line Font Size")
                minimum: 8
                maximum: 48
                step: 1
                value: root.secondLineSize
                modified: root.secondLineSize !== root.defaultSecondLineSize
                resetByKeys: false
                onResetRequested: {
                    root.secondLineSize = root.defaultSecondLineSize;
                    root.saveValue("secondLineSize", root.defaultSecondLineSize);
                }
                onSliderDragFinished: finalValue => {
                    root.secondLineSize = finalValue;
                    root.saveValue("secondLineSize", finalValue);
                }
            }
        }
    }

    Column {
        width: parent ? parent.width : 0
        spacing: 0

        SettingsSectionLabel {
            width: parent.width
            text: I18n.trFor("activateLinux", "Customization")
        }

        SettingsGroup {
            width: parent.width
            slotColor: SettingsMetrics.controlColor

            SettingsToggleRow {
                text: I18n.trFor("activateLinux", "Customize Text")
                description: I18n.trFor("activateLinux", "Enable manual override for the watermark text.")
                checked: root.customizeText
                modified: root.customizeText !== root.defaultCustomizeText
                resetByKeys: false
                onResetRequested: {
                    root.customizeText = root.defaultCustomizeText;
                    root.saveValue("customizeText", root.defaultCustomizeText);
                }
                onToggled: isChecked => {
                    root.customizeText = isChecked;
                    root.saveValue("customizeText", isChecked);
                }
            }

            SettingsTextFieldRow {
                id: firstLineField
                text: I18n.trFor("activateLinux", "First Line")
                value: root.firstLine
                visible: root.customizeText
                modified: root.firstLine !== root.defaultFirstLine
                onResetRequested: {
                    root.firstLine = root.defaultFirstLine;
                    firstLineField.value = root.defaultFirstLine;
                    root.saveValue("firstLine", root.defaultFirstLine);
                }
                onValueEdited: val => {
                    root.firstLine = val;
                    root.saveValue("firstLine", val);
                }
            }

            SettingsTextFieldRow {
                id: secondLineField
                text: I18n.trFor("activateLinux", "Second Line")
                value: root.secondLine
                visible: root.customizeText
                modified: root.secondLine !== root.defaultSecondLine
                onResetRequested: {
                    root.secondLine = root.defaultSecondLine;
                    secondLineField.value = root.defaultSecondLine;
                    root.saveValue("secondLine", root.defaultSecondLine);
                }
                onValueEdited: val => {
                    root.secondLine = val;
                    root.saveValue("secondLine", val);
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
            text: I18n.trFor("activateLinux", "How to Use")
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

            Column {
                width: parent.width
                spacing: Theme.spacingS

                Repeater {
                    model: [
                        I18n.trFor("activateLinux", "This plugin displays a non-intrusive watermark on your desktop."),
                        I18n.trFor("activateLinux", "Enable <b>Customize Text</b> to override the default message."),
                        I18n.trFor("activateLinux", "You can adjust <b>font sizes</b> and <b>opacity</b> to match your background.")
                    ]

                    delegate: Row {
                        required property string modelData
                        width: parent.width
                        spacing: Theme.spacingS

                        StyledText {
                            id: bullet
                            text: "•"
                            color: Theme.primary
                            font.pixelSize: Theme.fontSizeSmall
                            font.weight: Font.Bold
                        }

                        StyledText {
                            width: parent.width - bullet.width - parent.spacing
                            text: modelData
                            color: Theme.surfaceVariantText
                            font.pixelSize: Theme.fontSizeSmall
                            wrapMode: Text.WordWrap
                            textFormat: Text.StyledText
                        }
                    }
                }
            }
        }
    }
}
