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
        return hasWarning ? 320 : 260;
    }

    onCcWidgetToggled: {
        if (daemon) {
            daemon.saveSetting("visualizerEnabled", !daemon.visualizerEnabled);
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
                                ? I18n.trFor("screenkey", "User not in 'input' group (run: sudo usermod -aG input $USER)")
                                : I18n.trFor("screenkey", "Missing tool: %1").arg(root.daemon?.requiredTool ?? "libinput")
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.warning
                            wrapMode: Text.WordWrap
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }

                // ── M3E Segmented Display Modes Strip (DCard + DToggle) ─────
                Row {
                    id: optionsRow
                    width: parent.width
                    spacing: Theme.groupedListGap

                    readonly property var optionsList: [
                        { id: "showShortcuts", label: I18n.trFor("screenkey", "Shortcuts"), icon: "keyboard_command_key", val: root.daemon ? root.daemon.showShortcuts : true },
                        { id: "showNormalKeys", label: I18n.trFor("screenkey", "All Keys"), icon: "keyboard", val: root.daemon ? root.daemon.showNormalKeys : false },
                        { id: "showMouseClicks", label: I18n.trFor("screenkey", "Mouse"), icon: "mouse", val: root.daemon ? root.daemon.showMouseClicks : false },
                        { id: "showModifierStatus", label: I18n.trFor("screenkey", "Modifiers"), icon: "touch_app", val: root.daemon ? root.daemon.showModifierStatus : false }
                    ]

                    Repeater {
                        model: optionsRow.optionsList

                        delegate: DCard {
                            id: optCard
                            required property var modelData
                            required property int index

                            width: (optionsRow.width - Theme.groupedListGap * (optionsRow.optionsList.length - 1)) / optionsRow.optionsList.length
                            height: 60
                            pad: 0

                            topLeftRadius: index === 0 ? Theme.groupedListOuterRadius : Theme.groupedListInnerRadius
                            bottomLeftRadius: index === 0 ? Theme.groupedListOuterRadius : Theme.groupedListInnerRadius
                            topRightRadius: index === optionsRow.optionsList.length - 1 ? Theme.groupedListOuterRadius : Theme.groupedListInnerRadius
                            bottomRightRadius: index === optionsRow.optionsList.length - 1 ? Theme.groupedListOuterRadius : Theme.groupedListInnerRadius

                            readonly property bool isSelected: modelData.val
                            readonly property bool hovered: mouseArea.containsMouse

                            color: isSelected ? Theme.primaryContainer : (hovered ? Theme.surfaceContainerHighest : Theme.surfaceContainerHigh)

                            Behavior on color {
                                ColorAnimation {
                                    duration: M3E.effectsFastMs
                                }
                            }

                            Column {
                                anchors.centerIn: parent
                                spacing: 4

                                DIcon {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    name: optCard.modelData.icon
                                    size: 18
                                    color: optCard.isSelected ? Theme.onPrimaryContainer : Theme.surfaceVariantText
                                }

                                StyledText {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: optCard.modelData.label
                                    font.pixelSize: Theme.fontSizeSmall
                                    font.weight: optCard.isSelected ? Font.SemiBold : Font.Normal
                                    color: optCard.isSelected ? Theme.onPrimaryContainer : Theme.surfaceText
                                }
                            }

                            MouseArea {
                                id: mouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (root.daemon)
                                        root.daemon.saveSetting(optCard.modelData.id, !optCard.isSelected);
                                }
                            }
                        }
                    }
                }

                // ── M3E Position Card (Mock Screen Picker theo phong cách OSD DMS) ──
                DCard {
                    id: positionCard
                    width: parent.width
                    height: 106
                    pad: 0
                    restRadius: Theme.cornerRadiusL
                    color: Theme.surfaceContainerHigh

                    readonly property string curPos: root.daemon?.position ?? "bottom_center"
                    readonly property var positionsList: [
                        { id: "top_left", col: 0, row: 0, label: I18n.trFor("screenkey", "Top Left") },
                        { id: "top_center", col: 1, row: 0, label: I18n.trFor("screenkey", "Top Center") },
                        { id: "top_right", col: 2, row: 0, label: I18n.trFor("screenkey", "Top Right") },
                        { id: "bottom_left", col: 0, row: 1, label: I18n.trFor("screenkey", "Bottom Left") },
                        { id: "bottom_center", col: 1, row: 1, label: I18n.trFor("screenkey", "Bottom Center") },
                        { id: "bottom_right", col: 2, row: 1, label: I18n.trFor("screenkey", "Bottom Right") }
                    ]

                    function positionLabel(pos) {
                        for (let i = 0; i < positionsList.length; i++) {
                            if (positionsList[i].id === pos) return positionsList[i].label;
                        }
                        return I18n.trFor("screenkey", "Bottom Center");
                    }

                    Row {
                        anchors.fill: parent
                        anchors.margins: Theme.spacingM
                        spacing: Theme.spacingM

                        // Left label & current active info
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - mockScreen.width - Theme.spacingM
                            spacing: 4

                            StyledText {
                                text: I18n.trFor("screenkey", "Position")
                                font.pixelSize: Theme.fontSizeMedium
                                font.weight: Font.Medium
                                color: Theme.surfaceText
                            }

                            StyledText {
                                text: positionCard.positionLabel(positionCard.curPos)
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.primary
                                font.weight: Font.Medium
                            }
                        }

                        // Right: Interactive Mini Screen Canvas
                        Rectangle {
                            id: mockScreen
                            anchors.verticalCenter: parent.verticalCenter
                            width: 124
                            height: 74
                            radius: Theme.cornerRadiusS
                            color: Theme.surfaceContainerHighest
                            border.width: 1
                            border.color: Theme.withAlpha(Theme.outline, 0.2)

                            readonly property real slotW: 32
                            readonly property real slotH: 14
                            readonly property real inset: 6

                            function slotX(col) {
                                if (col === 0) return inset;
                                if (col === 2) return mockScreen.width - slotW - inset;
                                return (mockScreen.width - slotW) / 2;
                            }

                            function slotY(row) {
                                if (row === 0) return inset;
                                return mockScreen.height - slotH - inset;
                            }

                            // Active indicator with smooth motion animation
                            Rectangle {
                                readonly property var activeItem: {
                                    for (let i = 0; i < positionCard.positionsList.length; i++) {
                                        if (positionCard.positionsList[i].id === positionCard.curPos)
                                            return positionCard.positionsList[i];
                                    }
                                    return { col: 1, row: 1 };
                                }
                                width: mockScreen.slotW
                                height: mockScreen.slotH
                                radius: Theme.cornerRadiusXXS
                                color: Theme.primary

                                x: mockScreen.slotX(activeItem.col)
                                y: mockScreen.slotY(activeItem.row)

                                Behavior on x {
                                    NumberAnimation {
                                        duration: M3E.spatialFastMs
                                        easing.type: Easing.BezierSpline
                                        easing.bezierCurve: M3E.curveFastSpatial
                                    }
                                }
                                Behavior on y {
                                    NumberAnimation {
                                        duration: M3E.spatialFastMs
                                        easing.type: Easing.BezierSpline
                                        easing.bezierCurve: M3E.curveFastSpatial
                                    }
                                }
                            }

                            // Slots for all 6 positions
                            Repeater {
                                model: positionCard.positionsList

                                delegate: Rectangle {
                                    id: slotRect
                                    required property var modelData
                                    x: mockScreen.slotX(modelData.col)
                                    y: mockScreen.slotY(modelData.row)
                                    width: mockScreen.slotW
                                    height: mockScreen.slotH
                                    radius: Theme.cornerRadiusXXS

                                    readonly property bool isSelected: positionCard.curPos === modelData.id
                                    readonly property bool hovered: slotMouse.containsMouse

                                    color: isSelected ? "transparent" : (hovered ? Theme.withAlpha(Theme.outline, 0.25) : Theme.withAlpha(Theme.outline, 0.12))

                                    Behavior on color { ColorAnimation { duration: M3E.effectsFastMs } }

                                    MouseArea {
                                        id: slotMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (root.daemon)
                                                root.daemon.saveSetting("position", slotRect.modelData.id);
                                        }
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
                            text: I18n.trFor("screenkey", "Keyboard Device")
                            font.pixelSize: Theme.fontSizeMedium
                            font.weight: Font.Medium
                            color: Theme.surfaceText
                        }

                        DDropdown {
                            width: parent.width
                            height: 38
                            compactMode: true
                            enabled: !root.devicesScanning
                            currentValue: root.currentDeviceLabel
                            options: root.deviceOptions.map(function(o) { return o.label; })
                            onValueChanged: (newValue) => {
                                for (let i = 0; i < root.deviceOptions.length; i++) {
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
            }
        }
    }
}
