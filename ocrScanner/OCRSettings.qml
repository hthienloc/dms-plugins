import QtQuick
import QtQuick.Controls
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.Plugins
import "./dms-common"

PluginSettings {
    id: root
    pluginId: "ocrScanner"

    readonly property string defaultOcrLanguage: "eng"
    property var availableLangs: []
    property var selectedLangs: []

    function loadSettings() {
        let val = root.defaultOcrLanguage;
        if (root.pluginService) {
            val = root.loadValue("ocrLanguage", root.defaultOcrLanguage);
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
                        if (l !== "" && l !== "osd") langs.push(l);
                    }
                    availableLangs = langs.sort();
                }
            },
            0
        );
    }

    onPluginServiceChanged: loadSettings()

    SettingsCard {
        SectionTitle { text: I18n.tr("Recognition Languages"); icon: "language" }

        Flow {
            id: langFlow
            width: parent.width
            spacing: Theme.spacingS

            Repeater {
                model: root.availableLangs
                delegate: Rectangle {
                    width: (langFlow.width - (Theme.spacingS * 2)) / 3
                    height: 36
                    radius: Theme.cornerRadius
                    color: root.selectedLangs.indexOf(modelData) >= 0 ? Theme.primary : Theme.surfaceContainerHigh
                    
                    Row {
                        anchors.centerIn: parent
                        spacing: Theme.spacingXS
                        DankIcon {
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

    SettingsCard {
        SectionTitle { 
            text: I18n.tr("Behavior")
            icon: "settings" 
            showReset: autoCopy.isDirty || keepResults.isDirty || showPopout.isDirty || showHints.isDirty
            onResetClicked: {
                autoCopy.resetToDefault();
                keepResults.resetToDefault();
                showPopout.resetToDefault();
                showHints.resetToDefault();
            }
        }

        ToggleSettingPlus {
            id: autoCopy
            settingKey: "autoCopy"
            label: I18n.tr("Auto-copy to Clipboard")
            defaultValue: true
        }

        Separator { leftMargin: Theme.spacingM; rightMargin: Theme.spacingM }

        ToggleSettingPlus {
            id: keepResults
            settingKey: "keepResults"
            label: I18n.tr("Keep results when closed")
            defaultValue: true
        }

        Separator { leftMargin: Theme.spacingM; rightMargin: Theme.spacingM }

        ToggleSettingPlus {
            id: showPopout
            settingKey: "showPopoutOnRightClick"
            label: I18n.tr("Show popout on right-click")
            defaultValue: true
        }

        Separator { leftMargin: Theme.spacingM; rightMargin: Theme.spacingM }

        ToggleSettingPlus {
            id: showHints
            settingKey: "showHints"
            label: I18n.tr("Show Hints")
            defaultValue: true
        }
    }

    SettingsCard {
        SectionTitle { text: I18n.tr("Installation"); icon: "download" }

        InfoText {
            text: I18n.tr("Install the required packages:")
        }

        Column {
            width: parent.width
            spacing: Theme.spacingS

            Repeater {
                model: [
                    { cmd: "sudo dnf install tesseract tesseract-langpack-eng tesseract-langpack-vie wl-clipboard curl", label: "Fedora" },
                    { cmd: "sudo pacman -S tesseract tesseract-data-eng tesseract-data-vie wl-clipboard curl", label: "Arch Linux" },
                    { cmd: "sudo apt install tesseract tesseract-ocr-eng tesseract-ocr-vie wl-clipboard curl", label: "Debian/Ubuntu" },
                    { cmd: "sudo zypper install tesseract tesseract-langpack-en tesseract-langpack-vi wl-clipboard curl", label: "openSUSE" }
                ]

                delegate: CopyBox {
                    label: modelData.label
                    text: modelData.cmd
                }
            }
        }
    }

    SettingsCard {
        SectionTitle { 
            id: usageTitle
            text: I18n.tr("Usage Guide")
            icon: "menu_book" 
            collapsible: true
            settingKey: "usageGuideExpanded"
        }

        UsageGuide {
            expanded: usageTitle.isExpanded
            items: [
                I18n.tr("<b>Left-click</b> the pill to start a new screen scan."),
                I18n.tr("<b>Right-click</b> the pill to perform a quick scan or open results."),
                I18n.tr("Dropping an <b>image</b> onto the pill will scan it for text."),
                I18n.tr("Scanned text is automatically copied to the <b>clipboard</b>.")
            ]
        }
    }

    PluginAbout {
        repoUrl: "https://github.com/hthienloc/dms-ocr-scanner"
    }
}
