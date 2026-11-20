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

    property int activePreset: 0
    property bool radialHoverTrigger: Defaults.values.radialHoverTrigger
    property int radialHoverDelay: Defaults.values.radialHoverDelay
    property int radialMenuOpacity: Defaults.values.radialMenuOpacity

    readonly property var presets: [0, 1, 2, 3, 4, 5, 6, 7].map(i => ({
                tool: root.config ? root.config.presetTool(i) : "none",
                color: root.config ? root.config.presetColor(i) : "primary",
                thickness: root.config ? root.config.presetThickness(i) : 3
            }))

    function loadValue() {
        if (!settings)
            return;
        radialHoverTrigger = settings.loadValue("radialHoverTrigger", Defaults.values.radialHoverTrigger);
        radialHoverDelay = settings.loadValue("radialHoverDelay", Defaults.values.radialHoverDelay);
        radialMenuOpacity = settings.loadValue("radialMenuOpacity", Defaults.values.radialMenuOpacity);
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
            text: I18n.trFor("quickCapture", "Presets")
        }

        SettingsGroup {
            width: parent.width
            slotColor: SettingsMetrics.controlColor

            SettingsNoteRow {
                noteIconName: "info"
                tint: Theme.primary
                tintBackground: Theme.withAlpha(Theme.primary, 0.08)
                text: I18n.trFor("quickCapture", "Configure up to %1 quick-access tool presets. Right-click during capture to open the radial menu.").arg(8)
            }

            Item {
                width: parent.width
                height: previewWidget.implicitHeight + Theme.spacingM * 2

                RadialMenuPreview {
                    id: previewWidget
                    anchors.centerIn: parent
                    config: root.config
                    presets: root.presets
                    activeIndex: root.activePreset
                    menuOpacity: root.radialMenuOpacity / 100
                    onActiveIndexChanged: root.activePreset = activeIndex
                }
            }

            Repeater {
                model: 8

                delegate: RadialPresetEditor {
                    required property int index
                    visible: root.activePreset === index
                    config: root.config
                    settings: root.settings
                    presetIndex: index
                }
            }
        }
    }

    Column {
        width: parent.width
        spacing: 0

        SettingsSectionLabel {
            width: parent.width
            text: I18n.trFor("quickCapture", "Radial Menu")
        }

        SettingsGroup {
            width: parent.width
            slotColor: SettingsMetrics.controlColor

            SettingsToggleRow {
                text: I18n.trFor("quickCapture", "Trigger on Hover")
                description: I18n.trFor("quickCapture", "Auto-select a tool preset on hover, without releasing the mouse.")
                checked: root.radialHoverTrigger
                modified: root.radialHoverTrigger !== Defaults.values.radialHoverTrigger
                resetByKeys: false
                onResetRequested: {
                    root.radialHoverTrigger = Defaults.values.radialHoverTrigger;
                    root.save("radialHoverTrigger", Defaults.values.radialHoverTrigger);
                }
                onToggled: isChecked => {
                    root.radialHoverTrigger = isChecked;
                    root.save("radialHoverTrigger", isChecked);
                }
            }

            SettingsSliderRow {
                visible: root.radialHoverTrigger
                text: I18n.trFor("quickCapture", "Hover Trigger Delay")
                value: root.radialHoverDelay
                minimum: 100
                maximum: 500
                step: 10
                unit: "ms"
                modified: root.radialHoverDelay !== Defaults.values.radialHoverDelay
                resetByKeys: false
                onResetRequested: {
                    root.radialHoverDelay = Defaults.values.radialHoverDelay;
                    root.save("radialHoverDelay", Defaults.values.radialHoverDelay);
                }
                onSliderDragFinished: finalValue => {
                    root.radialHoverDelay = finalValue;
                    root.save("radialHoverDelay", finalValue);
                }
            }

            SettingsSliderRow {
                text: I18n.trFor("quickCapture", "Opacity")
                value: root.radialMenuOpacity
                minimum: 0
                maximum: 100
                step: 1
                unit: "%"
                modified: root.radialMenuOpacity !== Defaults.values.radialMenuOpacity
                resetByKeys: false
                onResetRequested: {
                    root.radialMenuOpacity = Defaults.values.radialMenuOpacity;
                    root.save("radialMenuOpacity", Defaults.values.radialMenuOpacity);
                }
                onSliderDragFinished: finalValue => {
                    root.radialMenuOpacity = finalValue;
                    root.save("radialMenuOpacity", finalValue);
                }
            }
        }
    }
}
