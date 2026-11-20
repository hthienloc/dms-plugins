import QtQuick
import qs.Common
import qs.DCommon.Widgets
import qs.Modules.Settings.Widgets
import "../../shared"
import "../core/Constants.js" as Constants
import "../core/Defaults.js" as Defaults

Column {
    id: root

    property QtObject config: null
    property var settings: null

    width: parent ? parent.width : 0
    spacing: Theme.spacingM

    property string defaultToolMode: Defaults.values.defaultToolMode
    property string defaultPresetIndex: String(Defaults.values.defaultPresetIndex)
    property string defaultTool: Defaults.values.defaultTool

    property int textFontSize: Constants.getToolMeta("text").defaultValue
    property string textFontFamily: Defaults.values.textFontFamily
    property string stampFontFamily: Defaults.values.stampFontFamily
    property bool textBold: Defaults.values.textBold
    property bool textItalic: Defaults.values.textItalic
    property bool textUnderline: Defaults.values.textUnderline
    property bool textBackground: Defaults.values.textBackground
    property string textInputMode: Defaults.values.textInputMode

    property bool roundRect: Defaults.values.roundRect
    property int textCornerRadius: Defaults.values.textCornerRadius
    property bool roundHighlighter: Defaults.values.roundHighlighter
    property bool stampOuterRing: Defaults.values.stampOuterRing
    property bool penAutoClose: Defaults.values.penAutoClose

    property var availableOcrLangs: []
    property var selectedOcrLangs: ["eng"]

    readonly property var startingToolOptions: root.config ? root.config.toolOptions(root.config.startingToolIds) : []
    readonly property var presetOptions: [0, 1, 2, 3, 4, 5, 6, 7].map(i => ({
                label: I18n.trFor("quickCapture", "Preset %1").arg(i + 1),
                value: String(i)
            }))

    function loadValue() {
        if (!settings)
            return;
        defaultToolMode = settings.loadValue("defaultToolMode", Defaults.values.defaultToolMode);
        defaultPresetIndex = String(settings.loadValue("defaultPresetIndex", Defaults.values.defaultPresetIndex));
        defaultTool = settings.loadValue("defaultTool", Defaults.values.defaultTool);

        textFontSize = settings.loadValue("textFontSize", Constants.getToolMeta("text").defaultValue);
        textFontFamily = settings.loadValue("textFontFamily", Defaults.values.textFontFamily);
        stampFontFamily = settings.loadValue("stampFontFamily", Defaults.values.stampFontFamily);
        textBold = settings.loadValue("textBold", Defaults.values.textBold);
        textItalic = settings.loadValue("textItalic", Defaults.values.textItalic);
        textUnderline = settings.loadValue("textUnderline", Defaults.values.textUnderline);
        textBackground = settings.loadValue("textBackground", Defaults.values.textBackground);
        textInputMode = settings.loadValue("textInputMode", Defaults.values.textInputMode);

        roundRect = settings.loadValue("roundRect", Defaults.values.roundRect);
        textCornerRadius = settings.loadValue("textCornerRadius", Defaults.values.textCornerRadius);
        roundHighlighter = settings.loadValue("roundHighlighter", Defaults.values.roundHighlighter);
        stampOuterRing = settings.loadValue("stampOuterRing", Defaults.values.stampOuterRing);
        penAutoClose = settings.loadValue("penAutoClose", Defaults.values.penAutoClose);

        loadOcrLangs();
    }

    function save(key, val) {
        if (settings)
            settings.saveValue(key, val);
    }

    function loadOcrLangs() {
        let val = Defaults.values.ocrLanguage;
        if (settings) {
            const loaded = settings.loadValue("ocrLanguage", Defaults.values.ocrLanguage);
            if (loaded !== undefined && loaded !== null && String(loaded).trim() !== "")
                val = String(loaded);
        }
        const parsed = String(val).split("+").map(s => s.trim()).filter(s => s !== "");
        selectedOcrLangs = parsed.length > 0 ? parsed : ["eng"];
    }

    function toggleOcrLang(lang) {
        loadOcrLangs();
        const list = selectedOcrLangs.slice();
        const index = list.indexOf(lang);
        if (index >= 0) {
            if (list.length <= 1)
                return;
            list.splice(index, 1);
        } else {
            list.push(lang);
        }
        selectedOcrLangs = list;
        save("ocrLanguage", list.join("+"));
    }

    onSettingsChanged: loadValue()

    Component.onCompleted: {
        loadValue();
        Proc.runCommand(
            "quickcapture-list-langs",
            ["tesseract", "--list-langs"],
            (stdout, exitCode) => {
                if (exitCode === 0) {
                    const lines = stdout.split("\n");
                    const langs = [];
                    for (let i = 1; i < lines.length; i++) {
                        const l = lines[i].trim();
                        if (l !== "" && l !== "osd")
                            langs.push(l);
                    }
                    const available = langs.sort();
                    availableOcrLangs = available;
                    if (available.length > 0) {
                        const reconciled = selectedOcrLangs.filter(lang => available.indexOf(lang) >= 0);
                        if (reconciled.length === 0)
                            reconciled.push(available.indexOf("eng") >= 0 ? "eng" : available[0]);
                        if (reconciled.join("+") !== selectedOcrLangs.join("+")) {
                            selectedOcrLangs = reconciled;
                            root.save("ocrLanguage", reconciled.join("+"));
                        }
                    }
                }
            },
            0
        );
    }

    readonly property var toolRows: [
        {
            tool: "pen",
            thicknessKey: "defaultPenThickness",
            colorKey: "defaultPenColor"
        },
        {
            tool: "line",
            thicknessKey: "defaultLineThickness",
            colorKey: "defaultLineColor"
        },
        {
            tool: "arrow",
            thicknessKey: "defaultArrowThickness",
            colorKey: "defaultArrowColor"
        },
        {
            tool: "rect",
            thicknessKey: "defaultRectThickness",
            colorKey: "defaultRectColor"
        },
        {
            tool: "ellipse",
            thicknessKey: "defaultEllipseThickness",
            colorKey: "defaultEllipseColor"
        },
        {
            tool: "highlighter",
            thicknessKey: "defaultHighlighterThickness",
            colorKey: "defaultHighlighterColor"
        },
        {
            tool: "text",
            thicknessKey: "",
            colorKey: "defaultTextColor"
        },
        {
            tool: "stamp",
            thicknessKey: "defaultStampSize",
            colorKey: "defaultStampColor"
        },
        {
            tool: "redact",
            thicknessKey: "defaultRedactThickness",
            colorKey: ""
        },
        {
            tool: "pixelate",
            thicknessKey: "defaultPixelateIntensity",
            colorKey: ""
        },
        {
            tool: "spotlight",
            thicknessKey: "defaultSpotlightIntensity",
            colorKey: ""
        },
        {
            tool: "callout",
            thicknessKey: "defaultCalloutZoom",
            colorKey: ""
        }
    ]

    Column {
        width: parent.width
        spacing: 0

        SettingsSectionLabel {
            width: parent.width
            text: I18n.trFor("quickCapture", "Tool Defaults")
        }

        SettingsGroup {
            width: parent.width
            slotColor: SettingsMetrics.controlColor

            SettingsButtonGroupRow {
                text: I18n.trFor("quickCapture", "Starting Tool Mode")
                model: [
                    I18n.trFor("quickCapture", "Preset"),
                    I18n.trFor("quickCapture", "Custom")
                ]
                values: ["preset", "custom"]
                value: root.defaultToolMode
                modified: root.defaultToolMode !== Defaults.values.defaultToolMode
                resetByKeys: false
                onResetRequested: {
                    root.defaultToolMode = Defaults.values.defaultToolMode;
                    root.save("defaultToolMode", Defaults.values.defaultToolMode);
                }
                onValueSelected: val => {
                    root.defaultToolMode = val;
                    root.save("defaultToolMode", val);
                }
            }

            SettingsNoteRow {
                noteIconName: "info"
                tint: Theme.primary
                tintBackground: Theme.withAlpha(Theme.primary, 0.08)
                text: I18n.trFor("quickCapture", "Note: Starting tool mode overrides tool thickness and color defaults if the starting tool matches it.")
            }

            SettingsDropdownRow {
                visible: root.defaultToolMode === "preset"
                text: I18n.trFor("quickCapture", "Starting Preset")
                options: root.presetOptions.map(o => o.label)
                optionValues: root.presetOptions.map(o => o.value)
                currentValue: root.defaultPresetIndex
                modified: root.defaultPresetIndex !== String(Defaults.values.defaultPresetIndex)
                resetByKeys: false
                onResetRequested: {
                    root.defaultPresetIndex = String(Defaults.values.defaultPresetIndex);
                    root.save("defaultPresetIndex", Defaults.values.defaultPresetIndex);
                }
                onValueChanged: val => {
                    root.defaultPresetIndex = val;
                    root.save("defaultPresetIndex", val);
                }
            }

            SettingsDropdownRow {
                visible: root.defaultToolMode === "custom"
                text: I18n.trFor("quickCapture", "Starting Tool")
                options: root.startingToolOptions.map(o => o.label)
                optionValues: root.startingToolOptions.map(o => o.value)
                currentValue: root.defaultTool
                modified: root.defaultTool !== Defaults.values.defaultTool
                resetByKeys: false
                onResetRequested: {
                    root.defaultTool = Defaults.values.defaultTool;
                    root.save("defaultTool", Defaults.values.defaultTool);
                }
                onValueChanged: val => {
                    root.defaultTool = val;
                    root.save("defaultTool", val);
                }
            }
        }
    }

    Repeater {
        model: root.toolRows

        delegate: Column {
            id: toolSection
            required property var modelData
            readonly property var meta: Constants.getToolMeta(modelData.tool)
            property real thicknessVal: meta.defaultValue

            width: root.width
            spacing: 0

            function loadToolVal() {
                if (!root.settings || modelData.thicknessKey === "")
                    return;
                thicknessVal = root.settings.loadValue(modelData.thicknessKey, meta.defaultValue);
            }

            Connections {
                target: root
                function onSettingsChanged() {
                    toolSection.loadToolVal();
                }
            }

            Component.onCompleted: loadToolVal()

            SettingsSectionLabel {
                width: parent.width
                text: root.config ? root.config.getToolLabel(toolSection.modelData.tool) : toolSection.modelData.tool
            }

            SettingsGroup {
                width: parent.width
                slotColor: SettingsMetrics.controlColor

                SettingsSliderRow {
                    visible: toolSection.modelData.thicknessKey !== ""
                    text: root.config ? root.config.toolMetricLabel(toolSection.modelData.tool) : I18n.trFor("quickCapture", "Size")
                    value: toolSection.thicknessVal
                    minimum: toolSection.meta.min
                    maximum: toolSection.meta.max
                    step: toolSection.meta.step !== undefined ? toolSection.meta.step : 1
                    unit: toolSection.meta.unit
                    modified: toolSection.thicknessVal !== toolSection.meta.defaultValue
                    resetByKeys: false
                    onResetRequested: {
                        toolSection.thicknessVal = toolSection.meta.defaultValue;
                        root.save(toolSection.modelData.thicknessKey, toolSection.meta.defaultValue);
                    }
                    onSliderDragFinished: finalValue => {
                        toolSection.thicknessVal = finalValue;
                        root.save(toolSection.modelData.thicknessKey, finalValue);
                    }
                }

                Item {
                    visible: toolSection.modelData.colorKey !== ""
                    width: parent.width
                    height: colorSetting.implicitHeight + Theme.spacingM * 2

                    ColorSettingPlus {
                        id: colorSetting
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.margins: Theme.spacingM
                        settingKey: toolSection.modelData.colorKey
                        label: I18n.trFor("quickCapture", "Color")
                        defaultValue: "primary"
                    }
                }
            }
        }
    }

    Column {
        width: parent.width
        spacing: 0

        SettingsSectionLabel {
            width: parent.width
            text: I18n.trFor("quickCapture", "Text")
        }

        SettingsGroup {
            width: parent.width
            slotColor: SettingsMetrics.controlColor

            SettingsSliderRow {
                text: I18n.trFor("quickCapture", "Font Size")
                value: root.textFontSize
                minimum: Constants.getToolMeta("text").min
                maximum: Constants.getToolMeta("text").max
                step: Constants.getToolMeta("text").step
                unit: Constants.getToolMeta("text").unit
                modified: root.textFontSize !== Constants.getToolMeta("text").defaultValue
                resetByKeys: false
                onResetRequested: {
                    const def = Constants.getToolMeta("text").defaultValue;
                    root.textFontSize = def;
                    root.save("textFontSize", def);
                }
                onSliderDragFinished: finalValue => {
                    root.textFontSize = finalValue;
                    root.save("textFontSize", finalValue);
                }
            }

            SettingsFontDropdownRow {
                text: I18n.trFor("quickCapture", "%1 Font").arg(I18n.trFor("quickCapture", "Text"))
                currentFont: root.textFontFamily
                modified: root.textFontFamily !== Defaults.values.textFontFamily
                resetByKeys: false
                onResetRequested: {
                    root.textFontFamily = Defaults.values.textFontFamily;
                    root.save("textFontFamily", Defaults.values.textFontFamily);
                }
                onFontSelected: family => {
                    root.textFontFamily = family;
                    root.save("textFontFamily", family);
                }
            }

            SettingsFontDropdownRow {
                text: I18n.trFor("quickCapture", "%1 Font").arg(I18n.trFor("quickCapture", "Stamp"))
                description: I18n.trFor("quickCapture", "Font family used for number stamp labels")
                currentFont: root.stampFontFamily
                modified: root.stampFontFamily !== Defaults.values.stampFontFamily
                resetByKeys: false
                onResetRequested: {
                    root.stampFontFamily = Defaults.values.stampFontFamily;
                    root.save("stampFontFamily", Defaults.values.stampFontFamily);
                }
                onFontSelected: family => {
                    root.stampFontFamily = family;
                    root.save("stampFontFamily", family);
                }
            }

            SettingsToggleRow {
                text: I18n.trFor("quickCapture", "Bold")
                checked: root.textBold
                modified: root.textBold !== Defaults.values.textBold
                resetByKeys: false
                onResetRequested: {
                    root.textBold = Defaults.values.textBold;
                    root.save("textBold", Defaults.values.textBold);
                }
                onToggled: isChecked => {
                    root.textBold = isChecked;
                    root.save("textBold", isChecked);
                }
            }

            SettingsToggleRow {
                text: I18n.trFor("quickCapture", "Italic")
                checked: root.textItalic
                modified: root.textItalic !== Defaults.values.textItalic
                resetByKeys: false
                onResetRequested: {
                    root.textItalic = Defaults.values.textItalic;
                    root.save("textItalic", Defaults.values.textItalic);
                }
                onToggled: isChecked => {
                    root.textItalic = isChecked;
                    root.save("textItalic", isChecked);
                }
            }

            SettingsToggleRow {
                text: I18n.trFor("quickCapture", "Underline")
                checked: root.textUnderline
                modified: root.textUnderline !== Defaults.values.textUnderline
                resetByKeys: false
                onResetRequested: {
                    root.textUnderline = Defaults.values.textUnderline;
                    root.save("textUnderline", Defaults.values.textUnderline);
                }
                onToggled: isChecked => {
                    root.textUnderline = isChecked;
                    root.save("textUnderline", isChecked);
                }
            }

            SettingsToggleRow {
                text: I18n.trFor("quickCapture", "Text Background")
                checked: root.textBackground
                modified: root.textBackground !== Defaults.values.textBackground
                resetByKeys: false
                onResetRequested: {
                    root.textBackground = Defaults.values.textBackground;
                    root.save("textBackground", Defaults.values.textBackground);
                }
                onToggled: isChecked => {
                    root.textBackground = isChecked;
                    root.save("textBackground", isChecked);
                }
            }

            SettingsButtonGroupRow {
                text: I18n.trFor("quickCapture", "Input Mode")
                model: [
                    I18n.trFor("quickCapture", "Inline"),
                    I18n.trFor("quickCapture", "Popup")
                ]
                values: ["inline", "popup"]
                value: root.textInputMode
                modified: root.textInputMode !== Defaults.values.textInputMode
                resetByKeys: false
                onResetRequested: {
                    root.textInputMode = Defaults.values.textInputMode;
                    root.save("textInputMode", Defaults.values.textInputMode);
                }
                onValueSelected: val => {
                    root.textInputMode = val;
                    root.save("textInputMode", val);
                }
            }
        }
    }

    Column {
        width: parent.width
        spacing: 0

        SettingsSectionLabel {
            width: parent.width
            text: I18n.trFor("quickCapture", "Shapes")
        }

        SettingsGroup {
            width: parent.width
            slotColor: SettingsMetrics.controlColor

            SettingsToggleRow {
                text: I18n.trFor("quickCapture", "Round Rectangle Corners")
                checked: root.roundRect
                modified: root.roundRect !== Defaults.values.roundRect
                resetByKeys: false
                onResetRequested: {
                    root.roundRect = Defaults.values.roundRect;
                    root.save("roundRect", Defaults.values.roundRect);
                }
                onToggled: isChecked => {
                    root.roundRect = isChecked;
                    root.save("roundRect", isChecked);
                }
            }

            SettingsSliderRow {
                text: I18n.trFor("quickCapture", "Text Background Roundness")
                value: root.textCornerRadius
                minimum: 0
                maximum: 20
                step: 1
                unit: "px"
                modified: root.textCornerRadius !== Defaults.values.textCornerRadius
                resetByKeys: false
                onResetRequested: {
                    root.textCornerRadius = Defaults.values.textCornerRadius;
                    root.save("textCornerRadius", Defaults.values.textCornerRadius);
                }
                onSliderDragFinished: finalValue => {
                    root.textCornerRadius = finalValue;
                    root.save("textCornerRadius", finalValue);
                }
            }

            SettingsToggleRow {
                text: I18n.trFor("quickCapture", "Round Highlighter Tips")
                checked: root.roundHighlighter
                modified: root.roundHighlighter !== Defaults.values.roundHighlighter
                resetByKeys: false
                onResetRequested: {
                    root.roundHighlighter = Defaults.values.roundHighlighter;
                    root.save("roundHighlighter", Defaults.values.roundHighlighter);
                }
                onToggled: isChecked => {
                    root.roundHighlighter = isChecked;
                    root.save("roundHighlighter", isChecked);
                }
            }

            SettingsToggleRow {
                text: I18n.trFor("quickCapture", "Stamp Contrast Ring")
                description: I18n.trFor("quickCapture", "Draw an outer ring using the stamp number color")
                checked: root.stampOuterRing
                modified: root.stampOuterRing !== Defaults.values.stampOuterRing
                resetByKeys: false
                onResetRequested: {
                    root.stampOuterRing = Defaults.values.stampOuterRing;
                    root.save("stampOuterRing", Defaults.values.stampOuterRing);
                }
                onToggled: isChecked => {
                    root.stampOuterRing = isChecked;
                    root.save("stampOuterRing", isChecked);
                }
            }

            SettingsToggleRow {
                text: I18n.trFor("quickCapture", "Pen Auto-Close")
                description: I18n.trFor("quickCapture", "Auto-close the loop when ending near the start point.")
                checked: root.penAutoClose
                modified: root.penAutoClose !== Defaults.values.penAutoClose
                resetByKeys: false
                onResetRequested: {
                    root.penAutoClose = Defaults.values.penAutoClose;
                    root.save("penAutoClose", Defaults.values.penAutoClose);
                }
                onToggled: isChecked => {
                    root.penAutoClose = isChecked;
                    root.save("penAutoClose", isChecked);
                }
            }
        }
    }

    Column {
        width: parent.width
        spacing: 0

        SettingsSectionLabel {
            width: parent.width
            text: I18n.trFor("quickCapture", "OCR")
        }

        SettingsGroup {
            width: parent.width
            slotColor: SettingsMetrics.controlColor

            SettingsNoteRow {
                noteIconName: "info"
                tint: Theme.primary
                tintBackground: Theme.withAlpha(Theme.primary, 0.08)
                text: root.availableOcrLangs.length > 0
                    ? I18n.trFor("quickCapture", "Select one or more installed Tesseract language packs for OCR text recognition.")
                    : I18n.trFor("quickCapture", "No Tesseract language packs found. Ensure tesseract is installed and has language data packages.")
            }

            Item {
                visible: root.availableOcrLangs.length > 0
                width: parent.width
                height: ocrLangFlow.implicitHeight + Theme.spacingM * 2

                Flow {
                    id: ocrLangFlow
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: Theme.spacingM
                    spacing: Theme.spacingS

                    Repeater {
                        model: root.availableOcrLangs

                        delegate: Rectangle {
                            id: langChip
                            required property string modelData
                            readonly property bool isSelected: root.selectedOcrLangs.indexOf(modelData) >= 0

                            width: (ocrLangFlow.width - (Theme.spacingS * 2)) / 3
                            height: 36
                            radius: Theme.cornerRadius
                            color: isSelected ? Theme.primary : (chipMouseArea.containsMouse ? Theme.surfaceContainerHighest : Theme.surfaceContainerHigh)
                            border.color: activeFocus ? Theme.primary : "transparent"
                            border.width: 2

                            focus: true
                            activeFocusOnTab: true
                            Keys.onReturnPressed: root.toggleOcrLang(langChip.modelData)
                            Keys.onEnterPressed: root.toggleOcrLang(langChip.modelData)
                            Keys.onSpacePressed: root.toggleOcrLang(langChip.modelData)

                            Row {
                                anchors.centerIn: parent
                                spacing: Theme.spacingXS

                                DIcon {
                                    name: langChip.isSelected ? "check_circle" : "radio_button_unchecked"
                                    size: 14
                                    color: langChip.isSelected ? Theme.onPrimary : Theme.surfaceVariantText
                                }

                                StyledText {
                                    text: langChip.modelData.toUpperCase()
                                    font.pixelSize: Theme.fontSizeSmall
                                    font.weight: langChip.isSelected ? Font.Bold : Font.Normal
                                    color: langChip.isSelected ? Theme.onPrimary : Theme.surfaceText
                                }
                            }

                            MouseArea {
                                id: chipMouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    langChip.forceActiveFocus();
                                    root.toggleOcrLang(langChip.modelData);
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
