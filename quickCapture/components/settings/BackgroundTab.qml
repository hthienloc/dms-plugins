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

    property bool backgroundAutoApply: Defaults.values.backgroundAutoApply
    property string backgroundDefaultMode: Defaults.values.backgroundDefaultMode
    property string backgroundImageFolder: Defaults.values.backgroundImageFolder
    property string backgroundDefaultImagePath: Defaults.values.backgroundDefaultImagePath
    property bool backgroundImageBlur: Defaults.values.backgroundImageBlur
    property bool backgroundImageDim: Defaults.values.backgroundImageDim
    property int backgroundImageDimStrength: Defaults.values.backgroundImageDimStrength
    property int backgroundDefaultPadding: Defaults.values.backgroundDefaultPadding
    property int backgroundDefaultRadius: Defaults.values.backgroundDefaultRadius
    property int backgroundDefaultShadow: Defaults.values.backgroundDefaultShadow
    property int backgroundDefaultAngle: Defaults.values.backgroundDefaultAngle
    property string backgroundDefaultAspectRatio: Defaults.values.backgroundDefaultAspectRatio
    property string backgroundDefaultAlignment: Defaults.values.backgroundDefaultAlignment

    readonly property bool imageMode: backgroundDefaultMode === "image"
    readonly property bool gradientMode: ["gradient", "radial", "conic"].includes(backgroundDefaultMode)

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
        backgroundAutoApply = settings.loadValue("backgroundAutoApply", Defaults.values.backgroundAutoApply);
        backgroundDefaultMode = settings.loadValue("backgroundDefaultMode", Defaults.values.backgroundDefaultMode);
        backgroundImageFolder = settings.loadValue("backgroundImageFolder", Defaults.values.backgroundImageFolder);
        backgroundDefaultImagePath = settings.loadValue("backgroundDefaultImagePath", Defaults.values.backgroundDefaultImagePath);
        backgroundImageBlur = settings.loadValue("backgroundImageBlur", Defaults.values.backgroundImageBlur);
        backgroundImageDim = settings.loadValue("backgroundImageDim", Defaults.values.backgroundImageDim);
        backgroundImageDimStrength = settings.loadValue("backgroundImageDimStrength", Defaults.values.backgroundImageDimStrength);
        backgroundDefaultPadding = settings.loadValue("backgroundDefaultPadding", Defaults.values.backgroundDefaultPadding);
        backgroundDefaultRadius = settings.loadValue("backgroundDefaultRadius", Defaults.values.backgroundDefaultRadius);
        backgroundDefaultShadow = settings.loadValue("backgroundDefaultShadow", Defaults.values.backgroundDefaultShadow);
        backgroundDefaultAngle = settings.loadValue("backgroundDefaultAngle", Defaults.values.backgroundDefaultAngle);
        backgroundDefaultAspectRatio = settings.loadValue("backgroundDefaultAspectRatio", Defaults.values.backgroundDefaultAspectRatio);
        backgroundDefaultAlignment = settings.loadValue("backgroundDefaultAlignment", Defaults.values.backgroundDefaultAlignment);
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
            text: I18n.trFor("quickCapture", "Background Defaults")
        }

        SettingsGroup {
            width: parent.width
            slotColor: SettingsMetrics.controlColor

            SettingsToggleRow {
                text: I18n.trFor("quickCapture", "Auto-apply background defaults")
                description: I18n.trFor("quickCapture", "Enable background automatically when opening the editor")
                checked: root.backgroundAutoApply
                modified: root.backgroundAutoApply !== Defaults.values.backgroundAutoApply
                resetByKeys: false
                onResetRequested: {
                    root.backgroundAutoApply = Defaults.values.backgroundAutoApply;
                    root.save("backgroundAutoApply", Defaults.values.backgroundAutoApply);
                }
                onToggled: isChecked => {
                    root.backgroundAutoApply = isChecked;
                    root.save("backgroundAutoApply", isChecked);
                }
            }

            SettingsDropdownRow {
                text: I18n.trFor("quickCapture", "Background Mode")
                options: [
                    I18n.trFor("quickCapture", "Solid Color"),
                    I18n.trFor("quickCapture", "Linear Gradient"),
                    I18n.trFor("quickCapture", "Radial Gradient"),
                    I18n.trFor("quickCapture", "Conic Gradient"),
                    I18n.trFor("quickCapture", "Image")
                ]
                optionValues: ["solid", "gradient", "radial", "conic", "image"]
                currentValue: root.backgroundDefaultMode
                modified: root.backgroundDefaultMode !== Defaults.values.backgroundDefaultMode
                resetByKeys: false
                onResetRequested: {
                    root.backgroundDefaultMode = Defaults.values.backgroundDefaultMode;
                    root.save("backgroundDefaultMode", Defaults.values.backgroundDefaultMode);
                }
                onValueChanged: val => {
                    root.backgroundDefaultMode = val;
                    root.save("backgroundDefaultMode", val);
                }
            }

            SettingsTextFieldRow {
                id: bgImageFolderField
                visible: root.imageMode
                text: I18n.trFor("quickCapture", "Image Folder")
                placeholderText: Defaults.values.backgroundImageFolder
                value: root.backgroundImageFolder
                modified: root.backgroundImageFolder !== Defaults.values.backgroundImageFolder
                onResetRequested: {
                    root.backgroundImageFolder = Defaults.values.backgroundImageFolder;
                    bgImageFolderField.value = Defaults.values.backgroundImageFolder;
                    root.save("backgroundImageFolder", Defaults.values.backgroundImageFolder);
                }
                onValueEdited: val => {
                    root.backgroundImageFolder = val;
                    root.save("backgroundImageFolder", val);
                }
                actions: DActionButton {
                    iconName: "folder_open"
                    tooltipText: I18n.trFor("quickCapture", "Browse")
                    onClicked: bgFolderBrowser.open()
                }
            }

            SettingsTextFieldRow {
                id: bgDefaultImageField
                visible: root.imageMode
                text: I18n.trFor("quickCapture", "Background image")
                description: I18n.trFor("quickCapture", "Image selected automatically when using Image Background mode")
                placeholderText: "~/Pictures/Wallpaper/image.jpg"
                value: root.backgroundDefaultImagePath
                modified: root.backgroundDefaultImagePath !== Defaults.values.backgroundDefaultImagePath
                onResetRequested: {
                    root.backgroundDefaultImagePath = Defaults.values.backgroundDefaultImagePath;
                    bgDefaultImageField.value = Defaults.values.backgroundDefaultImagePath;
                    root.save("backgroundDefaultImagePath", Defaults.values.backgroundDefaultImagePath);
                }
                onValueEdited: val => {
                    root.backgroundDefaultImagePath = val;
                    root.save("backgroundDefaultImagePath", val);
                }
                actions: DActionButton {
                    iconName: "file_open"
                    tooltipText: I18n.trFor("quickCapture", "Browse")
                    onClicked: bgImageBrowser.open()
                }
            }

            SettingsToggleRow {
                visible: root.imageMode
                text: I18n.trFor("quickCapture", "Blur Background Image")
                description: I18n.trFor("quickCapture", "Soften image details so screenshot content stands out")
                checked: root.backgroundImageBlur
                modified: root.backgroundImageBlur !== Defaults.values.backgroundImageBlur
                resetByKeys: false
                onResetRequested: {
                    root.backgroundImageBlur = Defaults.values.backgroundImageBlur;
                    root.save("backgroundImageBlur", Defaults.values.backgroundImageBlur);
                }
                onToggled: isChecked => {
                    root.backgroundImageBlur = isChecked;
                    root.save("backgroundImageBlur", isChecked);
                }
            }

            SettingsToggleRow {
                visible: root.imageMode
                text: I18n.trFor("quickCapture", "Dim Background Image")
                description: I18n.trFor("quickCapture", "Darken the image to improve foreground contrast")
                checked: root.backgroundImageDim
                modified: root.backgroundImageDim !== Defaults.values.backgroundImageDim
                resetByKeys: false
                onResetRequested: {
                    root.backgroundImageDim = Defaults.values.backgroundImageDim;
                    root.save("backgroundImageDim", Defaults.values.backgroundImageDim);
                }
                onToggled: isChecked => {
                    root.backgroundImageDim = isChecked;
                    root.save("backgroundImageDim", isChecked);
                }
            }

            SettingsSliderRow {
                visible: root.imageMode && root.backgroundImageDim
                text: I18n.trFor("quickCapture", "Dim Intensity")
                value: root.backgroundImageDimStrength
                minimum: 0
                maximum: 80
                step: 5
                unit: "%"
                modified: root.backgroundImageDimStrength !== Defaults.values.backgroundImageDimStrength
                resetByKeys: false
                onResetRequested: {
                    root.backgroundImageDimStrength = Defaults.values.backgroundImageDimStrength;
                    root.save("backgroundImageDimStrength", Defaults.values.backgroundImageDimStrength);
                }
                onSliderDragFinished: finalValue => {
                    root.backgroundImageDimStrength = finalValue;
                    root.save("backgroundImageDimStrength", finalValue);
                }
            }

            Item {
                visible: root.backgroundDefaultMode === "solid"
                width: parent.width
                height: solidColorSetting.implicitHeight + Theme.spacingM * 2

                BackgroundColorSetting {
                    id: solidColorSetting
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: Theme.spacingM
                    settingKey: "backgroundDefaultSolidColor"
                    label: I18n.trFor("quickCapture", "Solid Color")
                    defaultValue: Defaults.values.backgroundDefaultSolidColor
                    config: root.config
                }
            }

            Item {
                visible: root.gradientMode
                width: parent.width
                height: gradStartSetting.implicitHeight + Theme.spacingM * 2

                BackgroundColorSetting {
                    id: gradStartSetting
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: Theme.spacingM
                    settingKey: "backgroundDefaultGradientStart"
                    label: I18n.trFor("quickCapture", "Gradient Start")
                    defaultValue: Defaults.values.backgroundDefaultGradientStart
                    config: root.config
                }
            }

            Item {
                visible: root.gradientMode
                width: parent.width
                height: gradEndSetting.implicitHeight + Theme.spacingM * 2

                BackgroundColorSetting {
                    id: gradEndSetting
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: Theme.spacingM
                    settingKey: "backgroundDefaultGradientEnd"
                    label: I18n.trFor("quickCapture", "Gradient End")
                    defaultValue: Defaults.values.backgroundDefaultGradientEnd
                    config: root.config
                }
            }

            SettingsSliderRow {
                text: I18n.trFor("quickCapture", "Padding")
                value: root.backgroundDefaultPadding
                minimum: 0
                maximum: 150
                step: 5
                unit: "px"
                modified: root.backgroundDefaultPadding !== Defaults.values.backgroundDefaultPadding
                resetByKeys: false
                onResetRequested: {
                    root.backgroundDefaultPadding = Defaults.values.backgroundDefaultPadding;
                    root.save("backgroundDefaultPadding", Defaults.values.backgroundDefaultPadding);
                }
                onSliderDragFinished: finalValue => {
                    root.backgroundDefaultPadding = finalValue;
                    root.save("backgroundDefaultPadding", finalValue);
                }
            }

            SettingsSliderRow {
                text: I18n.trFor("quickCapture", "Corner Radius")
                value: root.backgroundDefaultRadius
                minimum: 0
                maximum: 60
                step: 2
                unit: "px"
                modified: root.backgroundDefaultRadius !== Defaults.values.backgroundDefaultRadius
                resetByKeys: false
                onResetRequested: {
                    root.backgroundDefaultRadius = Defaults.values.backgroundDefaultRadius;
                    root.save("backgroundDefaultRadius", Defaults.values.backgroundDefaultRadius);
                }
                onSliderDragFinished: finalValue => {
                    root.backgroundDefaultRadius = finalValue;
                    root.save("backgroundDefaultRadius", finalValue);
                }
            }

            SettingsSliderRow {
                text: I18n.trFor("quickCapture", "Shadow Strength")
                value: root.backgroundDefaultShadow
                minimum: 0
                maximum: 100
                step: 5
                unit: "%"
                modified: root.backgroundDefaultShadow !== Defaults.values.backgroundDefaultShadow
                resetByKeys: false
                onResetRequested: {
                    root.backgroundDefaultShadow = Defaults.values.backgroundDefaultShadow;
                    root.save("backgroundDefaultShadow", Defaults.values.backgroundDefaultShadow);
                }
                onSliderDragFinished: finalValue => {
                    root.backgroundDefaultShadow = finalValue;
                    root.save("backgroundDefaultShadow", finalValue);
                }
            }

            SettingsSliderRow {
                text: I18n.trFor("quickCapture", "Gradient Angle")
                value: root.backgroundDefaultAngle
                minimum: 0
                maximum: 360
                step: 15
                unit: "°"
                modified: root.backgroundDefaultAngle !== Defaults.values.backgroundDefaultAngle
                resetByKeys: false
                onResetRequested: {
                    root.backgroundDefaultAngle = Defaults.values.backgroundDefaultAngle;
                    root.save("backgroundDefaultAngle", Defaults.values.backgroundDefaultAngle);
                }
                onSliderDragFinished: finalValue => {
                    root.backgroundDefaultAngle = finalValue;
                    root.save("backgroundDefaultAngle", finalValue);
                }
            }

            SettingsDropdownRow {
                text: I18n.trFor("quickCapture", "Aspect Ratio")
                options: [
                    I18n.trFor("quickCapture", "Auto"),
                    "1:1",
                    "16:9",
                    "9:16",
                    "4:3",
                    "3:2",
                    "21:9"
                ]
                optionValues: ["auto", "1:1", "16:9", "9:16", "4:3", "3:2", "21:9"]
                currentValue: root.backgroundDefaultAspectRatio
                modified: root.backgroundDefaultAspectRatio !== Defaults.values.backgroundDefaultAspectRatio
                resetByKeys: false
                onResetRequested: {
                    root.backgroundDefaultAspectRatio = Defaults.values.backgroundDefaultAspectRatio;
                    root.save("backgroundDefaultAspectRatio", Defaults.values.backgroundDefaultAspectRatio);
                }
                onValueChanged: val => {
                    root.backgroundDefaultAspectRatio = val;
                    root.save("backgroundDefaultAspectRatio", val);
                }
            }

            SettingsDropdownRow {
                text: I18n.trFor("quickCapture", "Alignment")
                options: [
                    I18n.trFor("quickCapture", "Top Left"),
                    I18n.trFor("quickCapture", "Top Center"),
                    I18n.trFor("quickCapture", "Top Right"),
                    I18n.trFor("quickCapture", "Left Center"),
                    I18n.trFor("quickCapture", "Center"),
                    I18n.trFor("quickCapture", "Right Center"),
                    I18n.trFor("quickCapture", "Bottom Left"),
                    I18n.trFor("quickCapture", "Bottom Center"),
                    I18n.trFor("quickCapture", "Bottom Right")
                ]
                optionValues: [
                    "top-left",
                    "top-center",
                    "top-right",
                    "center-left",
                    "center",
                    "center-right",
                    "bottom-left",
                    "bottom-center",
                    "bottom-right"
                ]
                currentValue: root.backgroundDefaultAlignment
                modified: root.backgroundDefaultAlignment !== Defaults.values.backgroundDefaultAlignment
                resetByKeys: false
                onResetRequested: {
                    root.backgroundDefaultAlignment = Defaults.values.backgroundDefaultAlignment;
                    root.save("backgroundDefaultAlignment", Defaults.values.backgroundDefaultAlignment);
                }
                onValueChanged: val => {
                    root.backgroundDefaultAlignment = val;
                    root.save("backgroundDefaultAlignment", val);
                }
            }
        }
    }

    FileBrowserSurfaceModal {
        id: bgFolderBrowser
        browserTitle: I18n.trFor("quickCapture", "Image Folder")
        browserType: "folder_picker"
        folderMode: true
        saveMode: false
        fileExtensions: []
        revealPath: root.backgroundImageFolder
        onAccepted: paths => {
            if (paths && paths.length > 0) {
                const cleaned = root.cleanPath(paths[0]);
                root.backgroundImageFolder = cleaned;
                bgImageFolderField.value = cleaned;
                root.save("backgroundImageFolder", cleaned);
            }
        }
    }

    FileBrowserSurfaceModal {
        id: bgImageBrowser
        browserTitle: I18n.trFor("quickCapture", "Background image")
        browserType: "file_picker"
        folderMode: false
        saveMode: false
        fileExtensions: ["Image files (*.png *.jpg *.jpeg *.webp *.bmp)", "All files (*)"]
        revealPath: root.backgroundDefaultImagePath
        onAccepted: paths => {
            if (paths && paths.length > 0) {
                const cleaned = root.cleanPath(paths[0]);
                root.backgroundDefaultImagePath = cleaned;
                bgDefaultImageField.value = cleaned;
                root.save("backgroundDefaultImagePath", cleaned);
            }
        }
    }
}
