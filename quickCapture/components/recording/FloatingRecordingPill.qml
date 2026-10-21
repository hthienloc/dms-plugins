import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Common
import qs.Services
import qs.Widgets
import "../bar"
import "../core/Defaults.js" as Defaults

PanelWindow {
    id: root

    required property var daemon
    readonly property var recorder: daemon?.recordingController ?? null
    readonly property bool isRecording: daemon?.isRecording ?? false
    readonly property bool isPaused: recorder?.isPaused ?? false
    readonly property bool blinkRecordDot: Defaults.get(daemon?.pluginData, "blinkRecordDot")
    readonly property string durationText: recorder ? recorder.formatDuration(recorder.recordingSeconds) : "00:00"
    readonly property string statusLocation: Defaults.get(daemon?.pluginData, "recordingStatusLocation")
    readonly property bool showPillBorder: Defaults.get(daemon?.pluginData, "showPillBorder")

    readonly property bool shouldBeVisible: {
        if (!root.isRecording)
            return false;
        switch (root.statusLocation) {
        case "floating":
        case "both":
            return true;
        case "bar":
            return false;
        case "auto":
        default:
            return !(root.daemon?.hasBarWidget ?? false);
        }
    }

    property var targetScreen: CompositorService.getFocusedScreen() ?? Quickshell.screens[0] ?? null
    property bool hasCustomPosition: false
    property real customX: 0
    property real customY: 0

    screen: targetScreen
    visible: shouldBeVisible
    color: "transparent"

    WlrLayershell.namespace: "dms:quick-capture-recording-pill"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusiveZone: -1
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    anchors {
        left: true
        right: true
        top: true
        bottom: true
    }

    mask: Region {
        item: pillCard
    }

    onIsRecordingChanged: {
        if (root.isRecording) {
            root.targetScreen = CompositorService.getFocusedScreen() ?? Quickshell.screens[0] ?? null;
            root.hasCustomPosition = false;
        }
    }

    function edgeInset(side) {
        const bars = SettingsData.barConfigs || [];
        let inset = 0;
        if (typeof ShellLayout !== "undefined" && ShellLayout && typeof ShellLayout.edge === "function") {
            void ShellLayout.layouts;
            const band = ShellLayout.edge(root.screen, side);
            if (band)
                inset = Math.max(band.reservation ?? 0, band.island ? (band.islandThickness ?? 0) : 0);
        } else {
            const posMap = {
                "top": 0,
                "bottom": 1,
                "left": 2,
                "right": 3
            };
            const pos = posMap[side];
            const hasBar = bars.some(b => (b.enabled ?? true) && (b.visible ?? true) && !b.autoHide && (b.position ?? 0) === pos);
            if (hasBar)
                inset = Theme.barHeight + Theme.spacingS;
        }
        if (typeof SettingsData.dockReservationForEdge === "function")
            inset = Math.max(inset, SettingsData.dockReservationForEdge(root.screen, side));
        return inset;
    }

    readonly property real topInset: edgeInset("top") + Theme.spacingM
    readonly property real bottomInset: edgeInset("bottom") + Theme.spacingM
    readonly property real leftInset: edgeInset("left") + Theme.spacingM
    readonly property real rightInset: edgeInset("right") + Theme.spacingM

    readonly property real minX: root.leftInset
    readonly property real maxX: Math.max(root.minX, root.width - pillCard.width - root.rightInset)
    readonly property real minY: root.topInset
    readonly property real maxY: Math.max(root.minY, root.height - pillCard.height - root.bottomInset)

    readonly property real defaultX: Math.round(root.maxX)
    readonly property real defaultY: Math.round(root.minY)

    Rectangle {
        id: pillCard

        width: pillRow.implicitWidth + Theme.spacingM * 2
        height: 36
        radius: height / 2
        color: Theme.withAlpha(Theme.surfaceContainer, Theme.popupTransparency)
        border.color: Theme.outlineVariant
        border.width: root.showPillBorder ? 1 : 0

        x: root.hasCustomPosition
            ? Math.max(root.minX, Math.min(root.maxX, root.customX))
            : root.defaultX
        y: root.hasCustomPosition
            ? Math.max(root.minY, Math.min(root.maxY, root.customY))
            : root.defaultY

        MouseArea {
            id: dragArea
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor

            property real startMouseX: 0
            property real startMouseY: 0
            property real startCardX: 0
            property real startCardY: 0

            onPressed: mouse => {
                if (mouse.button === Qt.RightButton) {
                    root.recorder?.cancelRecording();
                    return;
                }
                startMouseX = mouse.x;
                startMouseY = mouse.y;
                startCardX = pillCard.x;
                startCardY = pillCard.y;
            }

            onPositionChanged: mouse => {
                if (!(mouse.buttons & Qt.LeftButton))
                    return;
                const dx = mouse.x - startMouseX;
                const dy = mouse.y - startMouseY;
                if (!root.hasCustomPosition && Math.abs(dx) + Math.abs(dy) < 3)
                    return;
                root.customX = Math.max(root.minX, Math.min(root.maxX, startCardX + dx));
                root.customY = Math.max(root.minY, Math.min(root.maxY, startCardY + dy));
                root.hasCustomPosition = true;
                startCardX = root.customX;
                startCardY = root.customY;
            }
        }

        Row {
            id: pillRow
            anchors.centerIn: parent
            spacing: Theme.spacingS

            RecordingDot {
                dotSize: 9
                paused: root.isPaused
                blink: root.isRecording && root.blinkRecordDot
                visible: root.shouldBeVisible
                anchors.verticalCenter: parent.verticalCenter
            }

            StyledText {
                text: root.durationText
                color: root.isPaused ? Theme.warning : Theme.surfaceText
                font.pixelSize: Theme.fontSizeMedium
                font.weight: Font.Medium
                font.features: {
                    "tnum": 1
                }
                anchors.verticalCenter: parent.verticalCenter
            }

            RecordingTransport {
                recorder: root.recorder
                buttonSize: 24
                iconSize: 14
                filled: true
                showCancel: true
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }
}
