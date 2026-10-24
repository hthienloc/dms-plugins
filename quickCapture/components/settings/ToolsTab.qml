import QtQuick
import qs.Common
import qs.DCommon.Widgets
import "../../shared"
import "../core/Constants.js" as Constants
import "../core/Defaults.js" as Defaults

SettingsGroup {
    id: root

    property QtObject config: null
    property var availableOcrLangs: []
    property var selectedOcrLangs: ["eng"]

    function findSettings() {
        let item = parent;
        while (item) {
            if (item.saveValue !== undefined && item.loadValue !== undefined)
                return item;
            item = item.parent;
        }
        return null;
    }

    function loadOcrLangs() {
        const settings = findSettings();
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
        const settings = findSettings();
        if (settings)
            settings.saveValue("ocrLanguage", list.join("+"));
    }

    Component.onCompleted: {
        Qt.callLater(loadOcrLangs);
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
                    availableOcrLangs = langs.sort();
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

    SettingsSection {
        title: I18n.trFor("quickCapture", "Tool Defaults")
        icon: "tune"

        ButtonGroupSettingPlus {
            id: defaultToolMode
            settingKey: "defaultToolMode"
            label: I18n.trFor("quickCapture", "Starting Tool Mode")
            options: [
                {
                    label: I18n.trFor("quickCapture", "Preset"),
                    value: "preset"
                },
                {
                    label: I18n.trFor("quickCapture", "Custom"),
                    value: "custom"
                }
            ]
            defaultValue: Defaults.values.defaultToolMode
        }

        InfoText {
            text: I18n.trFor("quickCapture", "Note: Starting tool mode overrides tool thickness and color defaults if the starting tool matches it.")
        }

        SettingsGroup {
            visible: defaultToolMode.value === "preset"

            Separator {}

            SelectionSettingPlus {
                settingKey: "defaultPresetIndex"
                label: I18n.trFor("quickCapture", "Starting Preset")
                options: [0, 1, 2, 3, 4, 5, 6, 7].map(i => ({
                            label: I18n.trFor("quickCapture", "Preset %1").arg(i + 1),
                            value: String(i)
                        }))
                defaultValue: Defaults.values.defaultPresetIndex
            }
        }

        SettingsGroup {
            visible: defaultToolMode.value === "custom"

            Separator {}

            SelectionSettingPlus {
                settingKey: "defaultTool"
                label: I18n.trFor("quickCapture", "Starting Tool")
                options: root.config.toolOptions(root.config.startingToolIds)
                defaultValue: Defaults.values.defaultTool
            }
        }

        Repeater {
            model: root.toolRows

            delegate: SettingsGroup {
                id: toolGroup
                required property var modelData
                readonly property var meta: Constants.getToolMeta(modelData.tool)
                title: root.config.getToolLabel(modelData.tool)
                divider: true

                SliderSettingPlus {
                    visible: toolGroup.modelData.thicknessKey !== ""
                    settingKey: toolGroup.modelData.thicknessKey
                    label: root.config.toolMetricLabel(toolGroup.modelData.tool)
                    defaultValue: toolGroup.meta.defaultValue
                    minimum: toolGroup.meta.min
                    maximum: toolGroup.meta.max
                    unit: toolGroup.meta.unit
                    leftLabel: String(toolGroup.meta.min)
                    rightLabel: String(toolGroup.meta.max)
                    previewType: toolGroup.meta.previewType
                }

                ColorSettingPlus {
                    visible: toolGroup.modelData.colorKey !== ""
                    settingKey: toolGroup.modelData.colorKey
                    label: I18n.trFor("quickCapture", "Color")
                    defaultValue: "primary"
                }
            }
        }
    }

    SettingsSection {
        title: I18n.trFor("quickCapture", "Text")
        icon: "format_size"

        SliderSettingPlus {
            settingKey: "textFontSize"
            label: I18n.trFor("quickCapture", "Font Size")
            defaultValue: Constants.getToolMeta("text").defaultValue
            minimum: Constants.getToolMeta("text").min
            maximum: Constants.getToolMeta("text").max
            leftLabel: String(Constants.getToolMeta("text").min)
            rightLabel: String(Constants.getToolMeta("text").max)
            previewType: "fontSize"
        }

        Separator {}

        FontSelectionSettingPlus {
            settingKey: "textFontFamily"
            label: I18n.trFor("quickCapture", "%1 Font").arg(I18n.trFor("quickCapture", "Text"))
            defaultValue: Defaults.values.textFontFamily
        }

        Separator {}

        FontSelectionSettingPlus {
            settingKey: "stampFontFamily"
            label: I18n.trFor("quickCapture", "%1 Font").arg(I18n.trFor("quickCapture", "Stamp"))
            description: I18n.trFor("quickCapture", "Font family used for number stamp labels")
            defaultValue: Defaults.values.stampFontFamily
        }

        Separator {}

        ToggleSettingPlus {
            settingKey: "textBold"
            label: I18n.trFor("quickCapture", "Bold")
            defaultValue: Defaults.values.textBold
        }

        Separator {}

        ToggleSettingPlus {
            settingKey: "textItalic"
            label: I18n.trFor("quickCapture", "Italic")
            defaultValue: Defaults.values.textItalic
        }

        Separator {}

        ToggleSettingPlus {
            settingKey: "textUnderline"
            label: I18n.trFor("quickCapture", "Underline")
            defaultValue: Defaults.values.textUnderline
        }

        Separator {}

        ToggleSettingPlus {
            settingKey: "textBackground"
            label: I18n.trFor("quickCapture", "Text Background")
            defaultValue: Defaults.values.textBackground
        }

        Separator {}

        ButtonGroupSettingPlus {
            settingKey: "textInputMode"
            label: I18n.trFor("quickCapture", "Input Mode")
            options: [
                {
                    label: I18n.trFor("quickCapture", "Inline"),
                    value: "inline"
                },
                {
                    label: I18n.trFor("quickCapture", "Popup"),
                    value: "popup"
                }
            ]
            defaultValue: Defaults.values.textInputMode
        }
    }

    SettingsSection {
        title: I18n.trFor("quickCapture", "Shapes")
        icon: "category"

        ToggleSettingPlus {
            settingKey: "roundRect"
            label: I18n.trFor("quickCapture", "Round Rectangle Corners")
            defaultValue: Defaults.values.roundRect
        }

        Separator {}

        SliderSettingPlus {
            settingKey: "textCornerRadius"
            label: I18n.trFor("quickCapture", "Text Background Roundness")
            defaultValue: Defaults.values.textCornerRadius
            minimum: 0
            maximum: 20
            unit: "px"
            leftLabel: "0"
            rightLabel: "20"
        }

        Separator {}

        ToggleSettingPlus {
            settingKey: "roundHighlighter"
            label: I18n.trFor("quickCapture", "Round Highlighter Tips")
            defaultValue: Defaults.values.roundHighlighter
        }

        Separator {}

        ToggleSettingPlus {
            settingKey: "stampOuterRing"
            label: I18n.trFor("quickCapture", "Stamp Contrast Ring")
            description: I18n.trFor("quickCapture", "Draw an outer ring using the stamp number color")
            defaultValue: Defaults.values.stampOuterRing
        }

        Separator {}

        ToggleSettingPlus {
            settingKey: "penAutoClose"
            label: I18n.trFor("quickCapture", "Pen Auto-Close")
            description: I18n.trFor("quickCapture", "Auto-close the loop when ending near the start point.")
            defaultValue: Defaults.values.penAutoClose
        }
    }

    SettingsSection {
        title: I18n.trFor("quickCapture", "OCR")
        icon: "document_scanner"

        InfoText {
            text: I18n.trFor("quickCapture", "Select one or more installed Tesseract language packs for OCR text recognition.")
        }

        Flow {
            id: ocrLangFlow
            width: parent.width
            spacing: Theme.spacingS
            visible: root.availableOcrLangs.length > 0

            Repeater {
                model: root.availableOcrLangs

                delegate: Rectangle {
                    id: langChip
                    required property string modelData
                    readonly property bool isSelected: root.selectedOcrLangs.indexOf(modelData) >= 0

                    width: (ocrLangFlow.width - (Theme.spacingS * 2)) / 3
                    height: 36
                    radius: Theme.cornerRadius
                    color: isSelected ? Theme.primary : Theme.surfaceContainerHigh

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
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.toggleOcrLang(langChip.modelData)
                    }
                }
            }
        }
    }
}
