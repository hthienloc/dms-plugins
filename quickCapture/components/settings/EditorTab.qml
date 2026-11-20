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

    property string modalDisplayTarget: Defaults.values.modalDisplayTarget
    property string modalDisplayMode: Defaults.values.modalDisplayMode
    property string modalAspectRatio: Defaults.values.modalAspectRatio
    property int overlayOpacity: Defaults.values.overlayOpacity
    property bool showCanvasBorder: Defaults.values.showCanvasBorder
    property string editQuality: Defaults.values.editQuality
    property bool modalScaleToContent: Defaults.values.modalScaleToContent

    readonly property var displayTargetOptions: root.config ? root.config.screenOptions([
        {
            label: I18n.trFor("quickCapture", "Focused Screen"),
            value: "focused"
        }
    ]) : [
        {
            label: I18n.trFor("quickCapture", "Focused Screen"),
            value: "focused"
        }
    ]

    function loadValue() {
        if (!settings)
            return;
        modalDisplayTarget = settings.loadValue("modalDisplayTarget", Defaults.values.modalDisplayTarget);
        modalDisplayMode = settings.loadValue("modalDisplayMode", Defaults.values.modalDisplayMode);
        modalAspectRatio = settings.loadValue("modalAspectRatio", Defaults.values.modalAspectRatio);
        overlayOpacity = settings.loadValue("overlayOpacity", Defaults.values.overlayOpacity);
        showCanvasBorder = settings.loadValue("showCanvasBorder", Defaults.values.showCanvasBorder);
        editQuality = String(settings.loadValue("editQuality", Defaults.values.editQuality));
        modalScaleToContent = settings.loadValue("modalScaleToContent", Defaults.values.modalScaleToContent);
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
            text: I18n.trFor("quickCapture", "Editor")
        }

        SettingsGroup {
            width: parent.width
            slotColor: SettingsMetrics.controlColor

            SettingsDropdownRow {
                text: I18n.trFor("quickCapture", "Display")
                options: root.displayTargetOptions.map(o => o.label)
                optionValues: root.displayTargetOptions.map(o => o.value)
                currentValue: root.modalDisplayTarget
                modified: root.modalDisplayTarget !== Defaults.values.modalDisplayTarget
                resetByKeys: false
                onResetRequested: {
                    root.modalDisplayTarget = Defaults.values.modalDisplayTarget;
                    root.save("modalDisplayTarget", Defaults.values.modalDisplayTarget);
                }
                onValueChanged: val => {
                    root.modalDisplayTarget = val;
                    root.save("modalDisplayTarget", val);
                }
            }

            SettingsButtonGroupRow {
                text: I18n.trFor("quickCapture", "Display Mode")
                description: I18n.trFor("quickCapture", "Choose whether the editor opens as a modal overlay or a movable floating window.")
                model: [
                    I18n.trFor("quickCapture", "Modal"),
                    I18n.trFor("quickCapture", "Floating")
                ]
                values: ["modal", "floating"]
                value: root.modalDisplayMode
                modified: root.modalDisplayMode !== Defaults.values.modalDisplayMode
                resetByKeys: false
                onResetRequested: {
                    root.modalDisplayMode = Defaults.values.modalDisplayMode;
                    root.save("modalDisplayMode", Defaults.values.modalDisplayMode);
                }
                onValueSelected: val => {
                    root.modalDisplayMode = val;
                    root.save("modalDisplayMode", val);
                }
            }

            SettingsButtonGroupRow {
                text: I18n.trFor("quickCapture", "Aspect Ratio")
                description: I18n.trFor("quickCapture", "Choose the editor shape for portrait or landscape screens.")
                model: [
                    I18n.trFor("quickCapture", "Landscape"),
                    I18n.trFor("quickCapture", "Portrait")
                ]
                values: ["landscape", "portrait"]
                value: root.modalAspectRatio
                modified: root.modalAspectRatio !== Defaults.values.modalAspectRatio
                resetByKeys: false
                onResetRequested: {
                    root.modalAspectRatio = Defaults.values.modalAspectRatio;
                    root.save("modalAspectRatio", Defaults.values.modalAspectRatio);
                }
                onValueSelected: val => {
                    root.modalAspectRatio = val;
                    root.save("modalAspectRatio", val);
                }
            }

            SettingsSliderRow {
                text: I18n.trFor("quickCapture", "Overlay Opacity")
                value: root.overlayOpacity
                minimum: 0
                maximum: 100
                step: 1
                unit: "%"
                modified: root.overlayOpacity !== Defaults.values.overlayOpacity
                resetByKeys: false
                onResetRequested: {
                    root.overlayOpacity = Defaults.values.overlayOpacity;
                    root.save("overlayOpacity", Defaults.values.overlayOpacity);
                }
                onSliderDragFinished: finalValue => {
                    root.overlayOpacity = finalValue;
                    root.save("overlayOpacity", finalValue);
                }
            }

            SettingsToggleRow {
                text: I18n.trFor("quickCapture", "Show Screenshot Border")
                checked: root.showCanvasBorder
                modified: root.showCanvasBorder !== Defaults.values.showCanvasBorder
                resetByKeys: false
                onResetRequested: {
                    root.showCanvasBorder = Defaults.values.showCanvasBorder;
                    root.save("showCanvasBorder", Defaults.values.showCanvasBorder);
                }
                onToggled: isChecked => {
                    root.showCanvasBorder = isChecked;
                    root.save("showCanvasBorder", isChecked);
                }
            }

            SettingsDropdownRow {
                text: I18n.trFor("quickCapture", "Preview Quality")
                options: [
                    I18n.trFor("quickCapture", "Low"),
                    I18n.trFor("quickCapture", "Balanced"),
                    I18n.trFor("quickCapture", "High"),
                    I18n.trFor("quickCapture", "Very High")
                ]
                optionValues: ["150000", "300000", "450000", "600000"]
                currentValue: root.editQuality
                modified: root.editQuality !== String(Defaults.values.editQuality)
                resetByKeys: false
                onResetRequested: {
                    root.editQuality = String(Defaults.values.editQuality);
                    root.save("editQuality", Defaults.values.editQuality);
                }
                onValueChanged: val => {
                    root.editQuality = val;
                    root.save("editQuality", val);
                }
            }

            SettingsNoteRow {
                noteIconName: "info"
                tint: Theme.primary
                tintBackground: Theme.withAlpha(Theme.primary, 0.08)
                text: I18n.trFor("quickCapture", "Controls the preview pixel budget while editing. Lower it if you experience lag. Does not affect the final saved image quality.")
            }

            SettingsToggleRow {
                text: I18n.trFor("quickCapture", "Scale Editor to Screenshot Size")
                description: I18n.trFor("quickCapture", "When enabled, the editor shrinks to match the captured region instead of filling %1% of the screen.").arg(90)
                checked: root.modalScaleToContent
                modified: root.modalScaleToContent !== Defaults.values.modalScaleToContent
                resetByKeys: false
                onResetRequested: {
                    root.modalScaleToContent = Defaults.values.modalScaleToContent;
                    root.save("modalScaleToContent", Defaults.values.modalScaleToContent);
                }
                onToggled: isChecked => {
                    root.modalScaleToContent = isChecked;
                    root.save("modalScaleToContent", isChecked);
                }
            }
        }
    }
}
