pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Widgets
import qs.Services
import qs.Modules.Plugins
import "./dms-common"

PluginComponent {
    id: root

    pluginId: "typingSounds"
    pluginService: PluginService

    readonly property var daemon: PluginService.pluginInstances["typingSounds"]

    property var packOptions: []
    property var deviceOptions: []
    property bool _packInit: false
    property bool _devInit: false

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
        const localPath = Paths.expandTilde("~/.config/DankMaterialShell/plugins/typingSounds/soundpacks");
        const userPath = Paths.expandTilde("~/.config/dms-typing-sounds/soundpacks");
        Proc.runCommand("typingSounds.scanPacks", ["python3", "-c", script, userPath, localPath], (stdout, exitCode) => {
            if (exitCode !== 0) return;
            try {
                const data = JSON.parse(stdout.trim());
                var options = [];
                for (var i = 0; i < data.length; i++) {
                    options.push({ label: data[i][0], value: data[i][1] });
                    if (root.daemon)
                        root.daemon.preSlicePack(data[i][1]);
                }
                root.packOptions = options;
                root._packInit = true;
            } catch(e) {}
        });
    }

    function scanDevices() {
        const script = `
import os, json, re
include_pattern = "kanata"
exclude_pattern = ["power button", "video bus", "speaker", "headphone", "lid switch", "touchpad", "extra buttons", "uinput", "server", "hitune", "inphic", "instant", "webcam", "video"]
devs = []
if os.path.exists('/proc/bus/input/devices'):
    with open('/proc/bus/input/devices', encoding='utf-8', errors='replace') as f:
        content = f.read()
    sections = content.strip().split('\\n\\n')
    for section in sections:
        name = ""
        handlers = ""
        for line in section.split('\\n'):
            if line.startswith('N: Name='):
                m = re.search(r'Name="([^"]+)"', line)
                if m:
                    name = m.group(1)
            elif line.startswith('H: Handlers='):
                handlers = line.split('=')[1]
        if name and handlers:
            lower_name = name.lower()
            is_included = include_pattern in lower_name
            is_excluded = any(x in lower_name for x in exclude_pattern)
            if 'kbd' in handlers and (is_included or ('mouse' not in handlers and not is_excluded)):
                event_match = re.search(r'event(\\d+)', handlers)
                if event_match:
                    event_path = "/dev/input/event" + event_match.group(1)
                    devs.append((name + " (" + event_path.split('/')[-1] + ")", event_path))
print(json.dumps(devs))
`;
        Proc.runCommand("typingSounds.scanDevices", ["python3", "-c", script], (stdout, exitCode) => {
            if (exitCode !== 0) return;
            try {
                const data = JSON.parse(stdout.trim());
                var options = [{ label: "All Keyboards (Auto)", value: "all" }];
                for (var i = 0; i < data.length; i++) {
                    options.push({ label: data[i][0], value: data[i][1] });
                }
                root.deviceOptions = options;
                root._devInit = true;
            } catch(e) {}
        });
    }

    Component.onCompleted: {
        scanSoundpacks();
        scanDevices();
    }

    ccWidgetIcon: "keyboard"
    ccWidgetPrimaryText: I18n.tr("Typing Sounds")
    ccWidgetSecondaryText: daemon && daemon.soundEnabled ? I18n.tr("Enabled") : I18n.tr("Disabled")
    ccWidgetIsActive: daemon ? daemon.soundEnabled : false
    ccDetailHeight: 360

    onCcWidgetToggled: {
        if (daemon) {
            var newState = !daemon.soundEnabled;
            daemon.saveSetting("soundEnabled", newState);
        }
    }

    ccDetailContent: Component {
        Rectangle {
            id: detailRoot
            radius: Theme.cornerRadius
            color: Theme.nestedSurface
            border.color: Theme.outlineMedium
            border.width: Theme.layerOutlineWidth

            implicitHeight: childrenRect.height

            Item {
                id: headerRow
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                height: Math.max(headerLabel.implicitHeight, headerControls.implicitHeight) + Theme.spacingS * 2

                StyledText {
                    id: headerLabel
                    text: I18n.tr("Typing Sounds")
                    font.pixelSize: Theme.fontSizeLarge
                    font.weight: Font.Medium
                    color: Theme.surfaceText
                    anchors.left: parent.left
                    anchors.leftMargin: Theme.spacingM
                    anchors.verticalCenter: parent.verticalCenter
                }

                Row {
                    id: headerControls
                    anchors.right: parent.right
                    anchors.rightMargin: Theme.spacingM
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Theme.spacingS

                    DankActionButton {
                        iconName: "settings"
                        buttonSize: 28
                        iconSize: 16
                        iconColor: Theme.surfaceVariantText
                        tooltipText: I18n.tr("Settings")
                        tooltipSide: "bottom"
                        onClicked: PopoutService.openSettingsWithTab("plugins")
                    }

                    DankActionButton {
                        iconName: root.daemon?.soundEnabled ? "volume_up" : "volume_off"
                        iconColor: root.daemon?.soundEnabled ? Theme.primary : Theme.surfaceVariantText
                        buttonSize: 28
                        iconSize: 16
                        tooltipText: root.daemon?.soundEnabled ? I18n.tr("Disable") : I18n.tr("Enable")
                        tooltipSide: "bottom"
                        onClicked: {
                            if (root.daemon)
                                root.daemon.saveSetting("soundEnabled", !root.daemon.soundEnabled);
                        }
                    }
                }
            }

            Column {
                id: detailColumn
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: headerRow.bottom
                anchors.margins: Theme.spacingM
                anchors.topMargin: Theme.spacingS
                spacing: Theme.spacingS

                DankSliderPlus {
                    width: parent.width
                    value: root.daemon ? root.daemon.volume : 100
                    minimum: 0
                    maximum: 200
                    unit: "%"
                    showValue: true
                    wheelEnabled: false
                    onSliderValueChanged: (newValue) => {
                        if (root.daemon)
                            root.daemon.saveSetting("volume", newValue);
                    }
                }

                Column {
                    width: parent.width
                    spacing: Theme.spacingXS

                    StyledText {
                        text: I18n.tr("Sound Pack")
                        font.pixelSize: Theme.fontSizeLarge
                        font.weight: Font.Medium
                        color: Theme.surfaceText
                    }

                    DankDropdown {
                        width: parent.width
                        compactMode: true
                        currentValue: {
                            var cur = root.daemon ? root.daemon.selectedPackPath : "";
                            for (var i = 0; i < root.packOptions.length; i++) {
                                if (root.packOptions[i].value === cur)
                                    return root.packOptions[i].label;
                            }
                            return root._packInit && root.packOptions.length > 0 ? root.packOptions[0].label : "";
                        }
                        options: root.packOptions.map(function(o) { return o.label; })
                        onValueChanged: (newValue) => {
                            for (var i = 0; i < root.packOptions.length; i++) {
                                if (root.packOptions[i].label === newValue) {
                                    if (root.daemon)
                                        root.daemon.saveSetting("selectedPackPath", root.packOptions[i].value);
                                    break;
                                }
                            }
                        }
                    }
                }

                Column {
                    width: parent.width
                    spacing: Theme.spacingXS

                    StyledText {
                        text: I18n.tr("Device")
                        font.pixelSize: Theme.fontSizeLarge
                        font.weight: Font.Medium
                        color: Theme.surfaceText
                    }

                    DankDropdown {
                        width: parent.width
                        compactMode: true
                        currentValue: {
                            var cur = root.daemon ? root.daemon.selectedDevicePath : "all";
                            for (var i = 0; i < root.deviceOptions.length; i++) {
                                if (root.deviceOptions[i].value === cur)
                                    return root.deviceOptions[i].label;
                            }
                            return "All Keyboards (Auto)";
                        }
                        options: root.deviceOptions.map(function(o) { return o.label; })
                        onValueChanged: (newValue) => {
                            for (var i = 0; i < root.deviceOptions.length; i++) {
                                if (root.deviceOptions[i].label === newValue) {
                                    if (root.daemon)
                                        root.daemon.saveSetting("selectedDevicePath", root.deviceOptions[i].value);
                                    break;
                                }
                            }
                        }
                    }
                }

                DankToggle {
                    width: parent.width
                    text: I18n.tr("Mouse Clicks")
                    checked: root.daemon ? root.daemon.mouseEnabled : false
                    onToggled: (checked) => {
                        if (root.daemon)
                            root.daemon.saveSetting("mouseEnabled", checked);
                    }
                }
            }
        }
    }
}
