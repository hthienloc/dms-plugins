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

    pluginId: "screenkey"
    pluginService: PluginService

    readonly property var daemon: PluginService.pluginInstances["screenkey"]
    property var deviceOptions: []
    property bool devicesScanning: true
    readonly property string autoDeviceLabel: I18n.trFor("screenkey", "All Keyboards (Auto)")

    readonly property string currentDeviceLabel: {
        if (root.devicesScanning)
            return I18n.trFor("screenkey", "Scanning devices…");
        const cur = root.daemon ? root.daemon.selectedDevicePath : "all";
        for (let i = 0; i < root.deviceOptions.length; i++) {
            if (root.deviceOptions[i].value === cur)
                return root.deviceOptions[i].label;
        }
        return root.autoDeviceLabel;
    }

    function scanDevices() {
        const defaultOptions = [{ label: root.autoDeviceLabel, value: "all" }];
        root.devicesScanning = true;

        InputDeviceScanner.scanKeyboards("screenkey.scanDevices", (devices) => {
            var options = defaultOptions.slice();
            for (var i = 0; i < devices.length; i++) {
                options.push(devices[i]);
            }
            root.deviceOptions = options;
            root.devicesScanning = false;
        });
    }

    Component.onCompleted: {
        scanDevices();
    }

    ccWidgetIcon: "keyboard"
    ccWidgetPrimaryText: I18n.trFor("screenkey", "Screenkey")
    ccWidgetSecondaryText: daemon && daemon.visualizerEnabled ? I18n.trFor("screenkey", "Active") : I18n.trFor("screenkey", "Disabled")
    ccWidgetIsActive: daemon ? daemon.visualizerEnabled : false
    ccDetailHeight: {
        const hasWarning = !!(root.daemon && (root.daemon.inputToolMissing || root.daemon.notInInputGroup));
        return hasWarning ? 400 : 340;
    }

    onCcWidgetToggled: {
        if (daemon) {
            daemon.saveSetting("visualizerEnabled", !daemon.visualizerEnabled);
        }
    }

    ccDetailContent: Component {
        Item {
            id: detailRoot
            implicitHeight: detailColumn.height

            readonly property string title: I18n.trFor("screenkey", "Screenkey")

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
                                    ? I18n.trFor("screenkey", "User not in 'input' group (run: sudo usermod -aG input $USER)")
                                    : I18n.trFor("screenkey", "Missing tool: %1").arg(root.daemon?.requiredTool ?? "libinput")
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.warning
                                wrapMode: Text.WordWrap
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                    }

                    CcGroup {
                        CcToggleRow {
                            iconName: "keyboard_command_key"
                            text: I18n.trFor("screenkey", "Shortcuts")
                            checked: root.daemon ? root.daemon.showShortcuts : true
                            onToggled: checked => root.daemon?.saveSetting("showShortcuts", checked)
                        }

                        CcToggleRow {
                            iconName: "keyboard"
                            text: I18n.trFor("screenkey", "All Keys")
                            checked: root.daemon ? root.daemon.showNormalKeys : false
                            onToggled: checked => root.daemon?.saveSetting("showNormalKeys", checked)
                        }

                        CcToggleRow {
                            iconName: "mouse"
                            text: I18n.trFor("screenkey", "Mouse")
                            checked: root.daemon ? root.daemon.showMouseClicks : false
                            onToggled: checked => root.daemon?.saveSetting("showMouseClicks", checked)
                        }

                        CcToggleRow {
                            iconName: "touch_app"
                            text: I18n.trFor("screenkey", "Modifiers")
                            checked: root.daemon ? root.daemon.showModifierStatus : false
                            onToggled: checked => root.daemon?.saveSetting("showModifierStatus", checked)
                        }
                    }

                    CcGroup {
                        SettingsDropdownRow {
                            text: I18n.trFor("screenkey", "Position")
                            options: [
                                I18n.trFor("screenkey", "Top Left"),
                                I18n.trFor("screenkey", "Top Center"),
                                I18n.trFor("screenkey", "Top Right"),
                                I18n.trFor("screenkey", "Bottom Left"),
                                I18n.trFor("screenkey", "Bottom Center"),
                                I18n.trFor("screenkey", "Bottom Right")
                            ]
                            optionValues: ["top_left", "top_center", "top_right", "bottom_left", "bottom_center", "bottom_right"]
                            currentValue: root.daemon?.position ?? "bottom_center"
                            onValueChanged: val => root.daemon?.saveSetting("position", val)
                        }

                        SettingsDropdownRow {
                            text: I18n.trFor("screenkey", "Keyboard Device")
                            enabled: !root.devicesScanning
                            options: root.deviceOptions.map(function(o) { return o.label; })
                            optionValues: root.deviceOptions.map(function(o) { return o.value; })
                            currentValue: root.daemon?.selectedDevicePath ?? "auto"
                            onValueChanged: val => root.daemon?.saveSetting("selectedDevicePath", val)
                        }
                    }
                }
            }
        }
    }
}
