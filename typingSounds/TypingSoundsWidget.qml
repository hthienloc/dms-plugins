pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.Common
import qs.DCommon.Widgets
import qs.Services
import qs.Modules.ControlCenter
import qs.Modules.ControlCenter.Widgets
import qs.Modules.Plugins
import qs.Modules.Settings.Widgets
import "./shared"

PluginComponent {
    id: root

    pluginId: "typingSounds"
    pluginService: PluginService

    readonly property var daemon: PluginService.pluginInstances["typingSounds"]

    readonly property string pluginDir: {
        if (root.pluginService && typeof root.pluginService.getPluginPath === "function") {
            const p = root.pluginService.getPluginPath(root.pluginId);
            if (p)
                return p;
        }
        return Paths.strip(Paths.config) + "/plugins/" + root.pluginId;
    }

    property var packOptions: []
    property var deviceOptions: []
    property bool _packInit: false
    property bool _devInit: false

    readonly property string currentPackLabel: {
        var cur = root.daemon ? root.daemon.selectedPackPath : "";
        for (var i = 0; i < root.packOptions.length; i++) {
            if (root.packOptions[i].value === cur)
                return root.packOptions[i].label;
        }
        return root._packInit && root.packOptions.length > 0 ? root.packOptions[0].label : I18n.trFor("typingSounds", "Default Pack");
    }

    readonly property string currentDeviceLabel: {
        var cur = root.daemon ? root.daemon.selectedDevicePath : "all";
        for (var i = 0; i < root.deviceOptions.length; i++) {
            if (root.deviceOptions[i].value === cur)
                return root.deviceOptions[i].label;
        }
        return I18n.trFor("typingSounds", "All Keyboards (Auto)");
    }

    readonly property string volumeIcon: {
        const vol = root.daemon ? root.daemon.volume : 100;
        if (!root.daemon || !root.daemon.soundEnabled || vol === 0) return "volume_off";
        if (vol < 50) return "volume_down";
        return "volume_up";
    }

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
        InputDeviceScanner.scanKeyboards("typingSounds.scanDevices", (devices) => {
            var options = [{ label: I18n.trFor("typingSounds", "All Keyboards (Auto)"), value: "all" }];
            for (var i = 0; i < devices.length; i++) {
                options.push(devices[i]);
            }
            root.deviceOptions = options;
            root._devInit = true;
        });
    }

    Component.onCompleted: {
        scanSoundpacks();
        scanDevices();
    }

    ccWidgetIcon: "volume_up"
    ccWidgetPrimaryText: I18n.trFor("typingSounds", "Typing Sounds")
    ccWidgetSecondaryText: daemon && daemon.soundEnabled ? I18n.trFor("typingSounds", "Active") : I18n.trFor("typingSounds", "Disabled")
    ccWidgetIsActive: daemon ? daemon.soundEnabled : false
    ccDetailHeight: {
        const hasWarning = !!(root.daemon && (root.daemon.inputToolMissing || root.daemon.notInInputGroup));
        return hasWarning ? 390 : 330;
    }

    onCcWidgetToggled: {
        if (daemon) {
            var newState = !daemon.soundEnabled;
            daemon.saveSetting("soundEnabled", newState);
        }
    }

    ccDetailContent: Component {
        Item {
            id: detailRoot
            implicitHeight: detailColumn.height

            readonly property string title: I18n.trFor("typingSounds", "Typing Sounds")

            DFlickable {
                anchors.fill: parent
                contentHeight: detailColumn.height
                clip: true

                Column {
                    id: detailColumn
                    width: parent.width
                    spacing: CcMetrics.detailContentGap

                    // ── Warning Banner ───────────────────────────────────────
                    Rectangle {
                        width: parent.width
                        height: warningRow.implicitHeight + Theme.spacingM * 2
                        radius: Theme.cornerRadius
                        color: Theme.withAlpha(Theme.warning, 0.12)
                        border.color: Theme.withAlpha(Theme.warning, 0.3)
                        border.width: 1
                        visible: !!(root.daemon && (root.daemon.inputToolMissing || root.daemon.notInInputGroup))

                        Row {
                            id: warningRow
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.margins: Theme.spacingM
                            spacing: Theme.spacingM

                            DIcon {
                                name: "warning"
                                size: Theme.iconSizeSmall
                                color: Theme.warning
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            StyledText {
                                width: parent.width - Theme.iconSizeSmall - Theme.spacingM
                                text: root.daemon?.notInInputGroup
                                    ? I18n.trFor("typingSounds", "User not in 'input' group (run: sudo usermod -aG input $USER)")
                                    : I18n.trFor("typingSounds", "Missing tool: %1").arg(root.daemon?.requiredTool ?? "libinput")
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.warning
                                wrapMode: Text.WordWrap
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                    }

                    CcGroup {
                        SettingsSliderRow {
                            text: I18n.trFor("typingSounds", "Volume")
                            value: root.daemon ? root.daemon.volume : 100
                            minimum: 0
                            maximum: 200
                            step: 1
                            unit: "%"
                            onSliderValueChanged: newValue => {
                                if (root.daemon && newValue !== root.daemon.volume)
                                    root.daemon.saveSetting("volume", newValue);
                            }
                        }

                        CcToggleRow {
                            iconName: "mouse"
                            text: I18n.trFor("typingSounds", "Mouse Click Sounds")
                            checked: root.daemon ? root.daemon.mouseEnabled : false
                            onToggled: checked => root.daemon?.saveSetting("mouseEnabled", checked)
                        }
                    }

                    CcGroup {
                        SettingsDropdownRow {
                            text: I18n.trFor("typingSounds", "Sound Pack")
                            options: root.packOptions.map(function(o) { return o.label; })
                            optionValues: root.packOptions.map(function(o) { return o.value; })
                            currentValue: root.daemon?.selectedPackPath ?? ""
                            onValueChanged: val => root.daemon?.saveSetting("selectedPackPath", val)
                        }

                        SettingsDropdownRow {
                            text: I18n.trFor("typingSounds", "Keyboard Device")
                            options: root.deviceOptions.map(function(o) { return o.label; })
                            optionValues: root.deviceOptions.map(function(o) { return o.value; })
                            currentValue: root.daemon?.selectedDevicePath ?? "auto"
                            onValueChanged: val => root.daemon?.saveSetting("selectedDevicePath", val)
                        }

                        CcListRow {
                            iconName: "play_arrow"
                            title: I18n.trFor("typingSounds", "Test Sound")
                            clickable: true
                            onClicked: root.daemon?.triggerKeySound(57)
                        }
                    }
                }
            }
        }
    }
}
