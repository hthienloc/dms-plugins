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
    readonly property bool defaultShowHints: true

    property var availableLangs: []
    property var selectedLangs: []
    property bool autoCopy: defaultAutoCopy
    property bool keepResults: defaultKeepResults
    property bool showPopoutOnRightClick: defaultShowPopoutOnRightClick
    property bool showHints: defaultShowHints

    function loadSettings() {
        let val = root.defaultOcrLanguage;
        if (root.pluginService) {
            val = root.loadValue("ocrLanguage", root.defaultOcrLanguage);
            autoCopy = root.loadValue("autoCopy", defaultAutoCopy);
            keepResults = root.loadValue("keepResults", defaultKeepResults);
            showPopoutOnRightClick = root.loadValue("showPopoutOnRightClick", defaultShowPopoutOnRightClick);
            showHints = root.loadValue("showHints", defaultShowHints);
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

            SettingsToggleRow {
                text: I18n.trFor("ocrScanner", "Show Hints")
                checked: root.showHints
                modified: root.showHints !== root.defaultShowHints
                resetByKeys: false
                onResetRequested: {
                    root.showHints = root.defaultShowHints;
                    root.saveValue("showHints", root.defaultShowHints);
                }
                onToggled: isChecked => {
                    root.showHints = isChecked;
                    root.saveValue("showHints", isChecked);
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
                        { cmd: "sudo dnf install tesseract tesseract-langpack-eng tesseract-langpack-vie wl-clipboard", label: "Fedora" },
                        { cmd: "sudo pacman -S tesseract tesseract-data-eng tesseract-data-vie wl-clipboard", label: "Arch Linux" },
                        { cmd: "sudo apt install tesseract tesseract-ocr-eng tesseract-ocr-vie wl-clipboard", label: "Debian/Ubuntu" },
                        { cmd: "sudo zypper install tesseract tesseract-langpack-en tesseract-langpack-vi wl-clipboard", label: "openSUSE" }
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

            Column {
                width: parent.width
                spacing: Theme.spacingS

                Repeater {
                    model: [
                        I18n.trFor("ocrScanner", "<b>Left-click</b> the pill to start a new screen scan."),
                        I18n.trFor("ocrScanner", "<b>Right-click</b> the pill to perform a quick scan or open results."),
                        I18n.trFor("ocrScanner", "Dropping an <b>image</b> onto the pill will scan it for text."),
                        I18n.trFor("ocrScanner", "Scanned text is automatically copied to the <b>clipboard</b>.")
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
