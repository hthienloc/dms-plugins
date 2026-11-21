import QtQuick
import qs.Common
import qs.DCommon.Widgets
import qs.Modules.Plugins
import qs.Modules.Settings.Widgets
import "./shared"

PluginSettings {
    id: root
    pluginId: "ocrScanner"

    readonly property string defaultOcrLanguage: "eng"
    readonly property bool defaultAutoCopy: true
    readonly property bool defaultKeepResults: true
    readonly property bool defaultShowPopoutOnRightClick: true

    property var availableLangs: []
    property var selectedLangs: []
    property bool autoCopy: defaultAutoCopy
    property bool keepResults: defaultKeepResults
    property bool showPopoutOnRightClick: defaultShowPopoutOnRightClick

    function loadSettings() {
        let val = root.defaultOcrLanguage;
        if (root.pluginService) {
            val = root.loadValue("ocrLanguage", root.defaultOcrLanguage);
            autoCopy = root.loadValue("autoCopy", defaultAutoCopy);
            keepResults = root.loadValue("keepResults", defaultKeepResults);
            showPopoutOnRightClick = root.loadValue("showPopoutOnRightClick", defaultShowPopoutOnRightClick);
            usageSection.expanded = root.loadValue("usageGuideExpanded", true);
        }
        if (val === undefined || val === null) {
            val = root.defaultOcrLanguage;
        }
        selectedLangs = String(val).split("+").filter(s => s !== "");
    }

    function toggleLang(lang) {
        let list = selectedLangs.slice();
        let index = list.indexOf(lang);
        if (index >= 0) {
            list.splice(index, 1);
        } else {
            list.push(lang);
        }

        let newVal = list.join("+");
        root.saveValue("ocrLanguage", newVal);

        // Update local state to trigger UI
        selectedLangs = list;
    }

    Connections {
        target: root.pluginService
        enabled: root.pluginService !== null

        function onPluginDataChanged(changedPluginId) {
            if (changedPluginId === root.pluginId) {
                root.loadSettings();
            }
        }
    }

    Component.onCompleted: {
        Qt.callLater(loadSettings);
        Proc.runCommand(
            "list-langs",
            ["tesseract", "--list-langs"],
            (stdout, exitCode) => {
                if (exitCode === 0) {
                    var lines = stdout.split("\n");
                    var langs = [];
                    for (var i = 1; i < lines.length; i++) {
                        var l = lines[i].trim();
                        if (l !== "" && l !== "osd")
                            langs.push(l);
                    }
                    availableLangs = langs.sort();
                }
            },
            0
        );
    }

    onPluginServiceChanged: loadSettings()

    Column {
        width: parent ? parent.width : 0
        spacing: 0

        SettingsSectionLabel {
            width: parent.width
            text: I18n.trFor("ocrScanner", "Recognition Languages")
        }

        SettingsGroup {
            width: parent.width
            slotColor: SettingsMetrics.controlColor

            Flow {
                id: langFlow
                width: parent.width
                spacing: Theme.spacingS

                Repeater {
                    model: root.availableLangs
                    delegate: Rectangle {
                        required property string modelData
                        width: (langFlow.width - (Theme.spacingS * 2)) / 3
                        height: 36
                        radius: Theme.cornerRadius
                        color: root.selectedLangs.indexOf(modelData) >= 0 ? Theme.primary : Theme.surfaceContainerHigh

                        Row {
                            anchors.centerIn: parent
                            spacing: Theme.spacingXS

                            DIcon {
                                name: root.selectedLangs.indexOf(modelData) >= 0 ? "check_circle" : "radio_button_unchecked"
                                size: 14
                                color: root.selectedLangs.indexOf(modelData) >= 0 ? Theme.onPrimary : Theme.surfaceVariantText
                            }

                            StyledText {
                                text: modelData.toUpperCase()
                                font.pixelSize: Theme.fontSizeSmall
                                font.weight: root.selectedLangs.indexOf(modelData) >= 0 ? Font.Bold : Font.Normal
                                color: root.selectedLangs.indexOf(modelData) >= 0 ? Theme.onPrimary : Theme.surfaceText
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.toggleLang(modelData)
                        }
                    }
                }
            }
        }
    }

    Column {
        width: parent ? parent.width : 0
        spacing: 0

        SettingsSectionLabel {
            width: parent.width
            text: I18n.trFor("ocrScanner", "Behavior")
        }

        SettingsGroup {
            width: parent.width
            slotColor: SettingsMetrics.controlColor

            SettingsToggleRow {
                text: I18n.trFor("ocrScanner", "Auto-copy to Clipboard")
                checked: root.autoCopy
                modified: root.autoCopy !== root.defaultAutoCopy
                resetByKeys: false
                onResetRequested: {
                    root.autoCopy = root.defaultAutoCopy;
                    root.saveValue("autoCopy", root.defaultAutoCopy);
                }
                onToggled: isChecked => {
                    root.autoCopy = isChecked;
                    root.saveValue("autoCopy", isChecked);
                }
            }

            SettingsToggleRow {
                text: I18n.trFor("ocrScanner", "Keep results when closed")
                checked: root.keepResults
                modified: root.keepResults !== root.defaultKeepResults
                resetByKeys: false
                onResetRequested: {
                    root.keepResults = root.defaultKeepResults;
                    root.saveValue("keepResults", root.defaultKeepResults);
                }
                onToggled: isChecked => {
                    root.keepResults = isChecked;
                    root.saveValue("keepResults", isChecked);
                }
            }

            SettingsToggleRow {
                text: I18n.trFor("ocrScanner", "Show popout on right-click")
                checked: root.showPopoutOnRightClick
                modified: root.showPopoutOnRightClick !== root.defaultShowPopoutOnRightClick
                resetByKeys: false
                onResetRequested: {
                    root.showPopoutOnRightClick = root.defaultShowPopoutOnRightClick;
                    root.saveValue("showPopoutOnRightClick", root.defaultShowPopoutOnRightClick);
                }
                onToggled: isChecked => {
                    root.showPopoutOnRightClick = isChecked;
                    root.saveValue("showPopoutOnRightClick", isChecked);
                }
            }
        }
    }

    Column {
        width: parent ? parent.width : 0
        spacing: 0

        SettingsSectionLabel {
            width: parent.width
            text: I18n.trFor("ocrScanner", "Installation")
        }

        SettingsGroup {
            width: parent.width
            slotColor: SettingsMetrics.controlColor

            SettingsNoteRow {
                noteIconName: "info"
                tint: Theme.primary
                tintBackground: Theme.withAlpha(Theme.primary, 0.08)
                text: I18n.trFor("ocrScanner", "Install the required packages:")
            }

            Column {
                width: parent.width
                spacing: Theme.spacingS

                Repeater {
                    model: [
                        { cmd: "sudo dnf install tesseract tesseract-langpack-eng tesseract-langpack-vie", label: "Fedora" },
                        { cmd: "sudo pacman -S tesseract tesseract-data-eng tesseract-data-vie", label: "Arch Linux" },
                        { cmd: "sudo apt install tesseract tesseract-ocr-eng tesseract-ocr-vie", label: "Debian/Ubuntu" },
                        { cmd: "sudo zypper install tesseract tesseract-langpack-en tesseract-langpack-vi", label: "openSUSE" }
                    ]

                    delegate: CopyBox {
                        required property var modelData
                        label: modelData.label
                        text: modelData.cmd
                    }
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
            text: I18n.trFor("ocrScanner", "How to Use")
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

            Repeater {
                model: [
                    {
                        icon: "crop_free",
                        title: I18n.trFor("ocrScanner", "Left-click"),
                        subtitle: I18n.trFor("ocrScanner", "Start a new screen scan from the pill.")
                    },
                    {
                        icon: "bolt",
                        title: I18n.trFor("ocrScanner", "Right-click"),
                        subtitle: I18n.trFor("ocrScanner", "Perform a quick scan or open recent results.")
                    },
                    {
                        icon: "image",
                        title: I18n.trFor("ocrScanner", "Drop Image"),
                        subtitle: I18n.trFor("ocrScanner", "Drag an image onto the pill to extract its text.")
                    }
                ]

                delegate: SettingsRow {
                    required property var modelData
                    iconName: modelData.icon
                    iconBox: true
                    title: modelData.title
                    subtitle: modelData.subtitle
                }
            }
        }
    }
}
