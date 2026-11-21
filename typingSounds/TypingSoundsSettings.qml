import QtQuick
import qs.Common
import qs.DCommon.Widgets
import qs.Modules.Plugins
import qs.Modules.Settings.Widgets
import "./shared"

PluginSettings {
    id: root

    pluginId: "typingSounds"

    readonly property bool defaultSoundEnabled: true
    readonly property int defaultVolume: 100
    readonly property bool defaultMouseEnabled: false
    readonly property string defaultSelectedPackPath: ""
    readonly property string defaultSelectedDevicePath: "all"

    property bool soundEnabled: defaultSoundEnabled
    property int volume: defaultVolume
    property bool mouseEnabled: defaultMouseEnabled
    property string selectedPackPath: defaultSelectedPackPath
    property string selectedDevicePath: defaultSelectedDevicePath

    readonly property string pluginDir: {
        if (root.pluginService && typeof root.pluginService.getPluginPath === "function") {
            const p = root.pluginService.getPluginPath(root.pluginId);
            if (p)
                return p;
        }
        return Paths.strip(Paths.config) + "/plugins/" + root.pluginId;
    }

    // Soundpack discovery lists
    property var packLabels: []
    property var packValues: []
    // Keyboard devices
    property var deviceLabels: ["All Keyboards (Auto)"]
    property var deviceValues: ["all"]

    function loadSettings() {
        if (!pluginService)
            return;
        soundEnabled = loadValue("soundEnabled", defaultSoundEnabled);
        volume = loadValue("volume", defaultVolume);
        mouseEnabled = loadValue("mouseEnabled", defaultMouseEnabled);
        selectedPackPath = loadValue("selectedPackPath", defaultSelectedPackPath);
        selectedDevicePath = loadValue("selectedDevicePath", defaultSelectedDevicePath);
        ipcSection.expanded = loadValue("ipcCommandsExpanded", true);
        usageSection.expanded = loadValue("usageGuideExpanded", true);
        creditsSection.expanded = loadValue("creditsExpanded", true);
    }

    Component.onCompleted: {
        loadSettings();
        scanSoundpacks();
        scanDevices();
    }

    onPluginServiceChanged: loadSettings()

    function scanSoundpacks() {
        const script = `
import os, json, sys
res = []
for p in sys.argv[1:]:
    if not os.path.exists(p): continue
    for d in os.listdir(p):
        dp = os.path.join(p, d)
        cfg = os.path.join(dp, 'config.json')
        if os.path.exists(cfg):
            try:
                with open(cfg) as f:
                    name = json.load(f).get('name', d)
                    res.append((name, dp))
            except:
                res.append((d, dp))
print(json.dumps(res))
`;
        const localPath = root.pluginDir + "/soundpacks";
        const userPath = Paths.expandTilde("~/.config/dms-typing-sounds/soundpacks");

        Proc.runCommand("typingSounds.scanSoundpacks", ["python3", "-c", script, userPath, localPath], (stdout, exitCode) => {
            if (exitCode !== 0)
                return;
            try {
                const data = JSON.parse(stdout.trim());
                var labels = [];
                var values = [];
                for (var i = 0; i < data.length; i++) {
                    labels.push(data[i][0]);
                    values.push(data[i][1]);
                }
                root.packLabels = labels;
                root.packValues = values;
            } catch (e) {
                console.warn("[TypingSounds] Failed to parse pack scanner output:", e);
            }
        });
    }

    function scanDevices() {
        InputDeviceScanner.scanKeyboards("typingSounds.scanDevices", devices => {
            const labels = ["All Keyboards (Auto)"];
            const values = ["all"];
            for (let i = 0; i < devices.length; i++) {
                labels.push(devices[i].label);
                values.push(devices[i].value);
            }
            root.deviceLabels = labels;
            root.deviceValues = values;
        });
    }

    Column {
        width: parent ? parent.width : 0
        spacing: 0

        SettingsSectionLabel {
            width: parent.width
            text: I18n.trFor("typingSounds", "Playback")
        }

        SettingsGroup {
            width: parent.width
            slotColor: SettingsMetrics.controlColor

            SettingsToggleRow {
                text: I18n.trFor("typingSounds", "Enable Typing Sounds")
                checked: root.soundEnabled
                modified: root.soundEnabled !== root.defaultSoundEnabled
                resetByKeys: false
                onResetRequested: {
                    root.soundEnabled = root.defaultSoundEnabled;
                    root.saveValue("soundEnabled", root.defaultSoundEnabled);
                }
                onToggled: isChecked => {
                    root.soundEnabled = isChecked;
                    root.saveValue("soundEnabled", isChecked);
                }
            }

            SettingsSliderRow {
                text: I18n.trFor("typingSounds", "Sound Volume")
                minimum: 0
                maximum: 200
                step: 5
                unit: "%"
                value: root.volume
                modified: root.volume !== root.defaultVolume
                resetByKeys: false
                onResetRequested: {
                    root.volume = root.defaultVolume;
                    root.saveValue("volume", root.defaultVolume);
                }
                onSliderDragFinished: finalValue => {
                    root.volume = finalValue;
                    root.saveValue("volume", finalValue);
                }
            }

            SettingsToggleRow {
                text: I18n.trFor("typingSounds", "Mouse Interaction")
                description: I18n.trFor("typingSounds", "Play sounds for mouse clicks")
                checked: root.mouseEnabled
                modified: root.mouseEnabled !== root.defaultMouseEnabled
                resetByKeys: false
                onResetRequested: {
                    root.mouseEnabled = root.defaultMouseEnabled;
                    root.saveValue("mouseEnabled", root.defaultMouseEnabled);
                }
                onToggled: isChecked => {
                    root.mouseEnabled = isChecked;
                    root.saveValue("mouseEnabled", isChecked);
                }
            }
        }
    }

    Column {
        width: parent ? parent.width : 0
        spacing: 0

        SettingsSectionLabel {
            width: parent.width
            text: I18n.trFor("typingSounds", "Device & Sounds")
        }

        SettingsGroup {
            width: parent.width
            slotColor: SettingsMetrics.controlColor

            SettingsDropdownRow {
                text: I18n.trFor("typingSounds", "Sound Pack")
                options: root.packLabels
                optionValues: root.packValues
                currentValue: root.selectedPackPath
                modified: root.selectedPackPath !== root.defaultSelectedPackPath
                resetByKeys: false
                onResetRequested: {
                    root.selectedPackPath = root.defaultSelectedPackPath;
                    root.saveValue("selectedPackPath", root.defaultSelectedPackPath);
                }
                onValueChanged: val => {
                    root.selectedPackPath = val;
                    root.saveValue("selectedPackPath", val);
                }
            }

            SettingsDropdownRow {
                text: I18n.trFor("typingSounds", "Keyboard Device")
                options: root.deviceLabels
                optionValues: root.deviceValues
                currentValue: root.selectedDevicePath
                modified: root.selectedDevicePath !== root.defaultSelectedDevicePath
                resetByKeys: false
                onResetRequested: {
                    root.selectedDevicePath = root.defaultSelectedDevicePath;
                    root.saveValue("selectedDevicePath", root.defaultSelectedDevicePath);
                }
                onValueChanged: val => {
                    root.selectedDevicePath = val;
                    root.saveValue("selectedDevicePath", val);
                }
            }
        }
    }

    Column {
        id: ipcSection
        width: parent ? parent.width : 0
        spacing: 0

        property bool expanded: true

        SettingsSectionLabel {
            width: parent.width
            text: I18n.trFor("typingSounds", "IPC Commands")
            collapsible: true
            expanded: ipcSection.expanded
            onToggleRequested: {
                ipcSection.expanded = !ipcSection.expanded;
                if (root.pluginService)
                    root.saveValue("ipcCommandsExpanded", ipcSection.expanded);
            }
        }

        SettingsGroup {
            width: parent.width
            slotColor: SettingsMetrics.controlColor
            visible: ipcSection.expanded

            Column {
                width: parent.width
                spacing: Theme.spacingS

                Repeater {
                    model: [
                        { text: "dms ipc typingSounds toggle", label: I18n.trFor("typingSounds", "Toggle typing sounds") },
                        { text: "dms ipc typingSounds enable", label: I18n.trFor("typingSounds", "Enable typing sounds") },
                        { text: "dms ipc typingSounds disable", label: I18n.trFor("typingSounds", "Disable typing sounds") }
                    ]

                    delegate: CopyBox {
                        required property var modelData
                        label: modelData.label
                        text: modelData.text
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
            text: I18n.trFor("typingSounds", "How to Use")
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
                        icon: "volume_up",
                        title: I18n.trFor("typingSounds", "Global Sounds"),
                        subtitle: I18n.trFor("typingSounds", "Plays mechanical keyboard sounds globally as you type.")
                    },
                    {
                        icon: "admin_panel_settings",
                        title: I18n.trFor("typingSounds", "Input Group"),
                        subtitle: I18n.trFor("typingSounds", "Your user must belong to the input group to read keyboard events without root.")
                    },
                    {
                        icon: "library_music",
                        title: I18n.trFor("typingSounds", "Sound Packs"),
                        subtitle: I18n.trFor("typingSounds", "Choose a bundled or custom sound pack above to change key sounds.")
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

    Column {
        id: creditsSection
        width: parent ? parent.width : 0
        spacing: 0

        property bool expanded: true

        SettingsSectionLabel {
            width: parent.width
            text: I18n.trFor("typingSounds", "Credits")
            collapsible: true
            expanded: creditsSection.expanded
            onToggleRequested: {
                creditsSection.expanded = !creditsSection.expanded;
                if (root.pluginService)
                    root.saveValue("creditsExpanded", creditsSection.expanded);
            }
        }

        SettingsGroup {
            width: parent.width
            slotColor: SettingsMetrics.controlColor
            visible: creditsSection.expanded

            Repeater {
                model: [
                    {
                        author: "Mechvibes",
                        url: "https://github.com/hainguyents13/mechvibes",
                        role: I18n.trFor("typingSounds", "Bundled mechanical keyboard sound packs."),
                        icon: "keyboard"
                    }
                ]

                delegate: SettingsRow {
                    required property var modelData
                    title: modelData.author
                    subtitle: modelData.role
                    iconName: modelData.icon
                    iconBox: true
                    clickable: true
                    showChevron: true
                    onClicked: Qt.openUrlExternally(modelData.url)
                }
            }
        }
    }
}
