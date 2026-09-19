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

    pluginId: "screenkey"
    pluginService: PluginService

    readonly property var daemon: PluginService.pluginInstances["screenkey"]
    property var deviceOptions: []
    property bool devicesScanning: true
    readonly property string autoDeviceLabel: I18n.tr("All Keyboards (Auto)")

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
                if m: name = m.group(1)
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
        const defaultOptions = [{ label: root.autoDeviceLabel, value: "all" }];
        root.devicesScanning = true;

        Proc.runCommand("screenkey.scanDevices", ["python3", "-c", script], (stdout, exitCode) => {
            if (exitCode !== 0) {
                console.warn("[Screenkey] scanDevices command failed with exit code:", exitCode, stdout);
                root.deviceOptions = defaultOptions;
                root.devicesScanning = false;
                return;
            }
            try {
                const data = JSON.parse(stdout.trim());
                var options = defaultOptions.slice();
                for (var i = 0; i < data.length; i++) {
                    options.push({ label: data[i][0], value: data[i][1] });
                }
                root.deviceOptions = options;
            } catch(e) {
                console.warn("[Screenkey] Failed to parse scanDevices output:", e, stdout);
                root.deviceOptions = defaultOptions;
            } finally {
                root.devicesScanning = false;
            }
        });
    }

    Component.onCompleted: {
        scanDevices();
    }

    ccWidgetIcon: "keyboard"
    ccWidgetPrimaryText: I18n.tr("Screenkey")
    ccWidgetSecondaryText: daemon && daemon.enabled ? I18n.tr("Active") : I18n.tr("Disabled")
    ccWidgetIsActive: daemon ? daemon.enabled : false
    ccDetailHeight: 360

    onCcWidgetToggled: {
        if (daemon) {
            daemon.saveSetting("enabled", !daemon.enabled);
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
                    text: I18n.tr("Screenkey")
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
                        iconName: root.daemon?.enabled ? "visibility" : "visibility_off"
                        iconColor: root.daemon?.enabled ? Theme.primary : Theme.surfaceVariantText
                        buttonSize: 28
                        iconSize: 16
                        tooltipText: root.daemon?.enabled ? I18n.tr("Disable") : I18n.tr("Enable")
                        tooltipSide: "bottom"
                        onClicked: {
                            if (root.daemon)
                                root.daemon.saveSetting("enabled", !root.daemon.enabled);
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

                Column {
                    width: parent.width
                    spacing: Theme.spacingXS

                    StyledText {
                        text: I18n.tr("Device")
                        font.pixelSize: Theme.fontSizeMedium
                        font.weight: Font.Medium
                        color: Theme.surfaceText
                    }

                    DankDropdown {
                        width: parent.width
                        compactMode: true
                        enabled: !root.devicesScanning
                        currentValue: {
                            if (root.devicesScanning)
                                return I18n.tr("Scanning devices…");
                            var cur = root.daemon ? root.daemon.selectedDevicePath : "all";
                            for (var i = 0; i < root.deviceOptions.length; i++) {
                                if (root.deviceOptions[i].value === cur)
                                    return root.deviceOptions[i].label;
                            }
                            return root.autoDeviceLabel;
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

                Grid {
                    width: parent.width
                    columns: 2
                    spacing: Theme.spacingS
                    rowSpacing: Theme.spacingXS

                    DankToggle {
                        text: I18n.tr("Normal Keys")
                        onToggled: {
                            if (root.daemon)
                                root.daemon.saveSetting("showNormalKeys", checked);
                        }
                        Binding on checked {
                            value: root.daemon ? root.daemon.showNormalKeys : false
                        }
                    }

                    DankToggle {
                        text: I18n.tr("Mouse Clicks")
                        onToggled: {
                            if (root.daemon)
                                root.daemon.saveSetting("showMouseClicks", checked);
                        }
                        Binding on checked {
                            value: root.daemon ? root.daemon.showMouseClicks : false
                        }
                    }

                    DankToggle {
                        text: I18n.tr("Shortcuts")
                        onToggled: {
                            if (root.daemon)
                                root.daemon.saveSetting("showShortcuts", checked);
                        }
                        Binding on checked {
                            value: root.daemon ? root.daemon.showShortcuts : true
                        }
                    }

                    DankToggle {
                        text: I18n.tr("macOS Symbols")
                        onToggled: {
                            if (root.daemon)
                                root.daemon.saveSetting("macSymbols", checked);
                        }
                        Binding on checked {
                            value: root.daemon ? root.daemon.macSymbols : false
                        }
                    }

                    DankToggle {
                        text: I18n.tr("Held Modifiers")
                        onToggled: {
                            if (root.daemon)
                                root.daemon.saveSetting("showModifierStatus", checked);
                        }
                        Binding on checked {
                            value: root.daemon ? root.daemon.showModifierStatus : false
                        }
                    }
                }

                // Input access warning
                StyledRect {
                    width: parent.width
                    height: errorText.implicitHeight + Theme.spacingS * 2
                    color: Theme.nestedSurface
                    border.color: Theme.error
                    border.width: Theme.layerOutlineWidth
                    radius: Theme.cornerRadius / 2
                    visible: root.daemon ? root.daemon.inputBroken : false

                    StyledText {
                        id: errorText
                        width: parent.width - Theme.spacingS * 2
                        anchors.centerIn: parent
                        text: root.daemon && root.daemon.inputToolMissing
                            ? I18n.tr("Missing input tools (%1)").arg(root.daemon.requiredTool)
                            : I18n.tr("User not in 'input' group.")
                        color: Theme.error
                        font.pixelSize: Theme.fontSizeSmall
                        wrapMode: Text.WordWrap
                    }
                }
            }
        }
    }
}
