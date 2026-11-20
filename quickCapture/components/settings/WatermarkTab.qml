import QtQuick
import qs.Common
import qs.DCommon.Widgets
import qs.Modals.FileBrowser
import qs.Modules.Settings.Widgets
import "../core/Defaults.js" as Defaults

Column {
    id: root

    property QtObject config: null
    property var settings: null

    width: parent ? parent.width : 0
    spacing: Theme.spacingM

    property bool defaultWatermark: Defaults.values.defaultWatermark
    property string watermarkType: Defaults.values.watermarkType
    property string watermarkPosition: Defaults.values.watermarkPosition
    property int watermarkOpacity: Defaults.values.watermarkOpacity
    property string watermarkText: Defaults.values.watermarkText
    property int watermarkTextSize: Defaults.values.watermarkTextSize
    property string watermarkImage: Defaults.values.watermarkImage
    property int watermarkSize: Defaults.values.watermarkSize

    readonly property bool hasText: watermarkType === "text" || watermarkType === "hybrid"
    readonly property bool hasImage: watermarkType === "image" || watermarkType === "hybrid"

    function cleanPath(url) {
        let path = url.toString();
        if (path.startsWith("file://"))
            path = path.substring(7);
        if (path.length > 1 && path.endsWith("/"))
            path = path.substring(0, path.length - 1);
        return path;
    }

    function loadValue() {
        if (!settings)
            return;
        defaultWatermark = settings.loadValue("defaultWatermark", Defaults.values.defaultWatermark);
        watermarkType = settings.loadValue("watermarkType", Defaults.values.watermarkType);
        watermarkPosition = settings.loadValue("watermarkPosition", Defaults.values.watermarkPosition);
        watermarkOpacity = settings.loadValue("watermarkOpacity", Defaults.values.watermarkOpacity);
        watermarkText = settings.loadValue("watermarkText", Defaults.values.watermarkText);
        watermarkTextSize = settings.loadValue("watermarkTextSize", Defaults.values.watermarkTextSize);
        watermarkImage = settings.loadValue("watermarkImage", Defaults.values.watermarkImage);
        watermarkSize = settings.loadValue("watermarkSize", Defaults.values.watermarkSize);
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
            text: I18n.trFor("quickCapture", "Watermark")
        }

        SettingsGroup {
            width: parent.width
            slotColor: SettingsMetrics.controlColor

            SettingsToggleRow {
                text: I18n.trFor("quickCapture", "Default Watermark")
                checked: root.defaultWatermark
                modified: root.defaultWatermark !== Defaults.values.defaultWatermark
                resetByKeys: false
                onResetRequested: {
                    root.defaultWatermark = Defaults.values.defaultWatermark;
                    root.save("defaultWatermark", Defaults.values.defaultWatermark);
                }
                onToggled: isChecked => {
                    root.defaultWatermark = isChecked;
                    root.save("defaultWatermark", isChecked);
                }
            }

            SettingsButtonGroupRow {
                text: I18n.trFor("quickCapture", "Watermark Type")
                model: [
                    I18n.trFor("quickCapture", "Text"),
                    I18n.trFor("quickCapture", "Image"),
                    I18n.trFor("quickCapture", "Image + Text")
                ]
                values: ["text", "image", "hybrid"]
                value: root.watermarkType
                modified: root.watermarkType !== Defaults.values.watermarkType
                resetByKeys: false
                onResetRequested: {
                    root.watermarkType = Defaults.values.watermarkType;
                    root.save("watermarkType", Defaults.values.watermarkType);
                }
                onValueSelected: val => {
                    root.watermarkType = val;
                    root.save("watermarkType", val);
                }
            }

            SettingsDropdownRow {
                text: I18n.trFor("quickCapture", "Position")
                options: [
                    I18n.trFor("quickCapture", "Top Left"),
                    I18n.trFor("quickCapture", "Top Right"),
                    I18n.trFor("quickCapture", "Bottom Left"),
                    I18n.trFor("quickCapture", "Bottom Right"),
                    I18n.trFor("quickCapture", "Center"),
                    I18n.trFor("quickCapture", "Top"),
                    I18n.trFor("quickCapture", "Bottom"),
                    I18n.trFor("quickCapture", "Left"),
                    I18n.trFor("quickCapture", "Right")
                ]
                optionValues: [
                    "top_left",
                    "top_right",
                    "bottom_left",
                    "bottom_right",
                    "center",
                    "top",
                    "bottom",
                    "left",
                    "right"
                ]
                currentValue: root.watermarkPosition
                modified: root.watermarkPosition !== Defaults.values.watermarkPosition
                resetByKeys: false
                onResetRequested: {
                    root.watermarkPosition = Defaults.values.watermarkPosition;
                    root.save("watermarkPosition", Defaults.values.watermarkPosition);
                }
                onValueChanged: val => {
                    root.watermarkPosition = val;
                    root.save("watermarkPosition", val);
                }
            }

            SettingsSliderRow {
                text: I18n.trFor("quickCapture", "Opacity")
                value: root.watermarkOpacity
                minimum: 5
                maximum: 100
                step: 5
                unit: "%"
                modified: root.watermarkOpacity !== Defaults.values.watermarkOpacity
                resetByKeys: false
                onResetRequested: {
                    root.watermarkOpacity = Defaults.values.watermarkOpacity;
                    root.save("watermarkOpacity", Defaults.values.watermarkOpacity);
                }
                onSliderDragFinished: finalValue => {
                    root.watermarkOpacity = finalValue;
                    root.save("watermarkOpacity", finalValue);
                }
            }

            SettingsTextFieldRow {
                id: watermarkTextField
                visible: root.hasText
                text: I18n.trFor("quickCapture", "Text")
                placeholderText: Defaults.values.watermarkText
                value: root.watermarkText
                modified: root.watermarkText !== Defaults.values.watermarkText
                onResetRequested: {
                    root.watermarkText = Defaults.values.watermarkText;
                    watermarkTextField.value = Defaults.values.watermarkText;
                    root.save("watermarkText", Defaults.values.watermarkText);
                }
                onValueEdited: val => {
                    root.watermarkText = val;
                    root.save("watermarkText", val);
                }
            }

            SettingsNoteRow {
                visible: root.hasText
                noteIconName: "info"
                tint: Theme.primary
                tintBackground: Theme.withAlpha(Theme.primary, 0.08)
                text: I18n.trFor("quickCapture", "Format tokens: {user} (Username), \\n (New Line), %Y (Year), %y (2-digit year), %m (Month), %d (Day), %H (Hour), %M (Minute), %S (Second)")
            }

            SettingsSliderRow {
                visible: root.hasText
                text: I18n.trFor("quickCapture", "Text Size")
                value: root.watermarkTextSize
                minimum: 1
                maximum: 50
                step: 1
                unit: "%"
                modified: root.watermarkTextSize !== Defaults.values.watermarkTextSize
                resetByKeys: false
                onResetRequested: {
                    root.watermarkTextSize = Defaults.values.watermarkTextSize;
                    root.save("watermarkTextSize", Defaults.values.watermarkTextSize);
                }
                onSliderDragFinished: finalValue => {
                    root.watermarkTextSize = finalValue;
                    root.save("watermarkTextSize", finalValue);
                }
            }

            SettingsTextFieldRow {
                id: watermarkImageField
                visible: root.hasImage
                text: I18n.trFor("quickCapture", "Image")
                placeholderText: "~/Pictures/watermark.png"
                value: root.watermarkImage
                modified: root.watermarkImage !== Defaults.values.watermarkImage
                onResetRequested: {
                    root.watermarkImage = Defaults.values.watermarkImage;
                    watermarkImageField.value = Defaults.values.watermarkImage;
                    root.save("watermarkImage", Defaults.values.watermarkImage);
                }
                onValueEdited: val => {
                    root.watermarkImage = val;
                    root.save("watermarkImage", val);
                }
                actions: DActionButton {
                    iconName: "file_open"
                    tooltipText: I18n.trFor("quickCapture", "Browse")
                    onClicked: watermarkImageBrowser.open()
                }
            }

            SettingsSliderRow {
                visible: root.hasImage
                text: I18n.trFor("quickCapture", "Image Size")
                value: root.watermarkSize
                minimum: 5
                maximum: 50
                step: 5
                unit: "%"
                modified: root.watermarkSize !== Defaults.values.watermarkSize
                resetByKeys: false
                onResetRequested: {
                    root.watermarkSize = Defaults.values.watermarkSize;
                    root.save("watermarkSize", Defaults.values.watermarkSize);
                }
                onSliderDragFinished: finalValue => {
                    root.watermarkSize = finalValue;
                    root.save("watermarkSize", finalValue);
                }
            }

            Item {
                width: parent.width
                height: previewCol.implicitHeight + Theme.spacingM * 2

                Column {
                    id: previewCol
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: Theme.spacingM
                    spacing: Theme.spacingS

                    StyledText {
                        text: I18n.trFor("quickCapture", "Live Preview")
                        font.pixelSize: Theme.fontSizeSmall
                        font.weight: Font.Bold
                        color: Theme.surfaceVariantText
                    }

                    WatermarkPreview {
                        config: root.config
                        watermarkType: root.watermarkType
                        position: root.watermarkPosition
                        opacityPercent: root.watermarkOpacity
                        text: root.watermarkText
                        textSizePercent: root.watermarkTextSize
                        imagePath: root.watermarkImage
                        imageSizePercent: root.watermarkSize
                    }
                }
            }
        }
    }

    FileBrowserSurfaceModal {
        id: watermarkImageBrowser
        browserTitle: I18n.trFor("quickCapture", "Image")
        browserType: "file_picker"
        folderMode: false
        saveMode: false
        fileExtensions: ["Image files (*.png *.jpg *.jpeg *.svg *.webp)", "All files (*)"]
        revealPath: root.watermarkImage
        onAccepted: paths => {
            if (paths && paths.length > 0) {
                const cleaned = root.cleanPath(paths[0]);
                root.watermarkImage = cleaned;
                watermarkImageField.value = cleaned;
                root.save("watermarkImage", cleaned);
            }
        }
    }
}
