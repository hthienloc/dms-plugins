pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.Common
import qs.DCommon.Widgets
import qs.Services
import qs.Modules.Plugins
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
        return hasWarning ? 380 : 320;
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
            implicitHeight: detailColumn.implicitHeight

            Column {
                id: detailColumn
                anchors.left: parent.left
                anchors.right: parent.right
                spacing: Theme.spacingM

                // ── Warning Banner ───────────────────────────────────────────
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

                // ── M3E Volume Slider Card ───────────────────────────────────
                DCard {
                    width: parent.width
                    implicitHeight: volumeCol.implicitHeight + Theme.spacingM * 2
                    pad: 0
                    restRadius: Theme.cornerRadiusL
                    color: Theme.surfaceContainerHigh

                    Column {
                        id: volumeCol
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.margins: Theme.spacingM
                        spacing: Theme.spacingS

                        Item {
                            width: parent.width
                            height: Math.max(volTitleRow.implicitHeight, volValueText.implicitHeight)

                            Row {
                                id: volTitleRow
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: Theme.spacingS

                                DIcon {
                                    name: root.volumeIcon
                                    size: Theme.iconSizeSmall
                                    color: (root.daemon?.soundEnabled ?? false) ? Theme.primary : Theme.surfaceVariantText
                                    anchors.verticalCenter: parent.verticalCenter
                                    Behavior on color { ColorAnimation { duration: M3E.effectsFastMs } }
                                }

                                StyledText {
                                    text: I18n.trFor("typingSounds", "Volume")
                                    font.pixelSize: Theme.fontSizeMedium
                                    font.weight: Font.Medium
                                    color: Theme.surfaceText
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            NumericText {
                                id: volValueText
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                text: (root.daemon ? root.daemon.volume : 100) + "%"
                                font.pixelSize: Theme.fontSizeMedium
                                font.weight: Font.SemiBold
                                color: (root.daemon?.soundEnabled ?? false) ? Theme.primary : Theme.surfaceVariantText
                            }
                        }

                        DSlider {
                            width: parent.width
                            value: root.daemon ? root.daemon.volume : 100
                            minimum: 0
                            maximum: 200
                            step: 1
                            wheelEnabled: true
                            showValue: false
                            onValueChanged: {
                                if (root.daemon && Math.round(value) !== root.daemon.volume)
                                    root.daemon.saveSetting("volume", Math.round(value));
                            }
                        }
                    }
                }

                // ── M3E Soundpack Selector Card (with Test Sound Button) ─────
                DCard {
                    width: parent.width
                    implicitHeight: packCol.implicitHeight + Theme.spacingM * 2
                    pad: 0
                    restRadius: Theme.cornerRadiusL
                    color: Theme.surfaceContainerHigh

                    Column {
                        id: packCol
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.margins: Theme.spacingM
                        spacing: Theme.spacingS

                        Item {
                            width: parent.width
                            height: 28

                            StyledText {
                                text: I18n.trFor("typingSounds", "Sound Pack")
                                font.pixelSize: Theme.fontSizeMedium
                                font.weight: Font.Medium
                                color: Theme.surfaceText
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Rectangle {
                                id: testPlayBtn
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                height: 26
                                width: testBtnRow.implicitWidth + 16
                                radius: Theme.cornerRadiusXXS

                                readonly property bool hovered: testMouse.containsMouse
                                readonly property bool pressed: testMouse.pressed

                                color: (root.daemon?.soundEnabled ?? false)
                                    ? (hovered ? Theme.primary : Theme.withAlpha(Theme.primary, 0.15))
                                    : (hovered ? Theme.surfaceContainerHighest : Theme.surfaceContainer)

                                scale: pressed ? M3E.rowPressScale : 1.0

                                Behavior on scale {
                                    NumberAnimation {
                                        duration: M3E.spatialFastMs
                                        easing.type: Easing.BezierSpline
                                        easing.bezierCurve: M3E.curveFastSpatial
                                    }
                                }
                                Behavior on color { ColorAnimation { duration: M3E.effectsFastMs } }

                                Row {
                                    id: testBtnRow
                                    anchors.centerIn: parent
                                    spacing: 4

                                    DIcon {
                                        name: "play_arrow"
                                        size: 14
                                        color: (root.daemon?.soundEnabled ?? false)
                                            ? (testPlayBtn.hovered ? Theme.onPrimary : Theme.primary)
                                            : Theme.surfaceText
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                    StyledText {
                                        text: I18n.trFor("typingSounds", "Test")
                                        font.pixelSize: Theme.fontSizeSmall
                                        font.weight: Font.SemiBold
                                        color: (root.daemon?.soundEnabled ?? false)
                                            ? (testPlayBtn.hovered ? Theme.onPrimary : Theme.primary)
                                            : Theme.surfaceText
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                }

                                MouseArea {
                                    id: testMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (root.daemon) {
                                            root.daemon.triggerKeySound(57); // Spacebar sound test
                                        }
                                    }
                                }
                            }
                        }

                        DDropdown {
                            width: parent.width
                            height: 38
                            compactMode: true
                            currentValue: root.currentPackLabel
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
                }

                // ── M3E Keyboard Device Card ─────────────────────────────────
                DCard {
                    width: parent.width
                    implicitHeight: deviceCol.implicitHeight + Theme.spacingM * 2
                    pad: 0
                    restRadius: Theme.cornerRadiusL
                    color: Theme.surfaceContainerHigh

                    Column {
                        id: deviceCol
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.margins: Theme.spacingM
                        spacing: Theme.spacingS

                        StyledText {
                            text: I18n.trFor("typingSounds", "Keyboard Device")
                            font.pixelSize: Theme.fontSizeMedium
                            font.weight: Font.Medium
                            color: Theme.surfaceText
                        }

                        DDropdown {
                            width: parent.width
                            height: 38
                            compactMode: true
                            currentValue: root.currentDeviceLabel
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
                }

                // ── M3E Mouse Click Audio Toggle Card ────────────────────────
                DCard {
                    width: parent.width
                    height: 48
                    pad: 0
                    restRadius: Theme.cornerRadiusL
                    color: Theme.surfaceContainerHigh

                    StyledText {
                        anchors.left: parent.left
                        anchors.leftMargin: Theme.spacingM
                        anchors.verticalCenter: parent.verticalCenter
                        text: I18n.trFor("typingSounds", "Mouse Click Sounds")
                        font.pixelSize: Theme.fontSizeMedium
                        font.weight: Font.Medium
                        color: Theme.surfaceText
                    }

                    DToggle {
                        id: mouseToggle
                        hideText: true
                        anchors.right: parent.right
                        anchors.rightMargin: Theme.spacingM
                        anchors.verticalCenter: parent.verticalCenter
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
}
