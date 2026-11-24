import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Common
import qs.Services
import qs.DCommon.Widgets
import "../core/Defaults.js" as Defaults
import "../../shared"

PanelWindow {
    id: root

    required property var daemon
    readonly property var recorder: daemon ? daemon.recordingController : null
    readonly property var pluginData: daemon ? daemon.pluginData : null
    readonly property bool isRecording: daemon ? daemon.isRecording : false
    readonly property bool isPaused: recorder ? recorder.isPaused : false
    readonly property bool blinkRecordDot: Defaults.get(pluginData, "blinkRecordDot")
    readonly property string durationText: recorder ? recorder.formatDuration(recorder.recordingSeconds) : "00:00"
    readonly property bool recordingIsGif: (recorder ? recorder.videoFormat : "mp4") === "gif"
    readonly property bool recordingHasAudio: (recorder ? recorder.activeRecorderBin : "") !== "wf-recorder"

    property bool shouldBeVisible: false
    property string expandedMode: ""
    property string selectedRecordMode: "region"
    property var targetScreen: null
    property var pendingAction: null

    readonly property real cardPad: Theme.spacingXS
    readonly property real tileHeight: Theme.iconSizeSmall + Theme.fontSizeSmall + Theme.spacingM * 1.5
    readonly property real outerRadius: M3E.tileHighlightedRadius
    readonly property real tileOuterRadius: Math.max(M3E.innerR, outerRadius - cardPad)
    readonly property real seamRadius: M3E.innerR

    readonly property var screenshotTargets: [
        {
            value: "region",
            icon: "screenshot_region",
            label: I18n.trFor("quickCapture", "Region")
        },
        {
            value: "full",
            icon: "fullscreen",
            label: I18n.trFor("quickCapture", "Full")
        },
        {
            value: "window",
            icon: "window",
            label: I18n.trFor("quickCapture", "Window")
        },
        {
            value: "scroll",
            icon: "unfold_more",
            label: I18n.trFor("quickCapture", "Scroll")
        }
    ]

    readonly property var recordTargets: [
        {
            value: "region",
            icon: "crop_square",
            label: I18n.trFor("quickCapture", "Region")
        },
        {
            value: "portal",
            icon: "window",
            label: I18n.trFor("quickCapture", "Window")
        },
        {
            value: "screen",
            icon: "fullscreen",
            label: I18n.trFor("quickCapture", "Full")
        }
    ]

    screen: targetScreen
    visible: shouldBeVisible
    color: "transparent"

    WlrLayershell.namespace: "dms:quick-capture-compact-toolbar"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusiveZone: -1
    WlrLayershell.keyboardFocus: shouldBeVisible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    anchors {
        left: true
        right: true
        top: true
        bottom: true
    }

    function open() {
        root.targetScreen = CompositorService.getFocusedScreen() ?? Quickshell.screens[0] ?? null;
        root.expandedMode = "";
        root.pendingAction = null;
        if (root.daemon && !root.isRecording)
            root.daemon.refreshAudioDevices();
        root.shouldBeVisible = true;
        focusScope.forceActiveFocus();
    }

    function dismiss(afterAction) {
        root.pendingAction = afterAction ?? null;
        if (!root.visible && !root.shouldBeVisible) {
            if (root.pendingAction) {
                const act = root.pendingAction;
                root.pendingAction = null;
                Qt.callLater(act);
            }
            return;
        }
        root.shouldBeVisible = false;
    }

    onVisibleChanged: {
        if (visible) {
            focusScope.forceActiveFocus();
        } else if (root.pendingAction) {
            const act = root.pendingAction;
            root.pendingAction = null;
            Qt.callLater(act);
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

    component ToolbarTile: Rectangle {
        id: tile
        property string iconName: ""
        property string label: ""
        property bool active: false
        property bool primaryCta: false
        property real minWidth: Theme.iconSizeLarge + Theme.spacingM * 2
        property real leftRadius: root.tileOuterRadius
        property real rightRadius: root.tileOuterRadius
        signal clicked

        readonly property bool hovered: tileArea.containsMouse
        readonly property bool pressed: tileArea.pressed

        width: Math.max(minWidth, tileCol.implicitWidth + Theme.spacingM * 1.5)
        height: root.tileHeight
        topLeftRadius: pressed ? M3E.pressRadiusXS : leftRadius
        bottomLeftRadius: pressed ? M3E.pressRadiusXS : leftRadius
        topRightRadius: pressed ? M3E.pressRadiusXS : rightRadius
        bottomRightRadius: pressed ? M3E.pressRadiusXS : rightRadius
        scale: pressed ? M3E.tilePressScale : 1.0

        color: {
            if (primaryCta)
                return hovered ? Theme.blend(Theme.error, Theme.surfaceText, 0.14) : Theme.error;
            if (active)
                return Theme.primaryContainer;
            if (hovered)
                return Theme.secondaryContainer;
            return Theme.surfaceContainerHigh;
        }

        readonly property color fgColor: {
            if (primaryCta)
                return Theme.onError ?? Theme.background;
            if (active)
                return Theme.onPrimaryContainer;
            if (hovered)
                return Theme.onSecondaryContainer;
            return Theme.surfaceText;
        }

        readonly property color iconColor: {
            if (primaryCta)
                return Theme.onError ?? Theme.background;
            if (active)
                return Theme.onPrimaryContainer;
            if (hovered)
                return Theme.onSecondaryContainer;
            return Theme.primary;
        }

        Behavior on topLeftRadius {
            NumberAnimation {
                duration: M3E.spatialFastMs
                easing.type: Easing.BezierSpline
                easing.bezierCurve: M3E.curveFastSpatial
            }
        }
        Behavior on bottomLeftRadius {
            NumberAnimation {
                duration: M3E.spatialFastMs
                easing.type: Easing.BezierSpline
                easing.bezierCurve: M3E.curveFastSpatial
            }
        }
        Behavior on topRightRadius {
            NumberAnimation {
                duration: M3E.spatialFastMs
                easing.type: Easing.BezierSpline
                easing.bezierCurve: M3E.curveFastSpatial
            }
        }
        Behavior on bottomRightRadius {
            NumberAnimation {
                duration: M3E.spatialFastMs
                easing.type: Easing.BezierSpline
                easing.bezierCurve: M3E.curveFastSpatial
            }
        }
        Behavior on scale {
            NumberAnimation {
                duration: M3E.spatialFastMs
                easing.type: Easing.BezierSpline
                easing.bezierCurve: M3E.curveFastSpatial
            }
        }
        Behavior on color {
            ColorAnimation {
                duration: M3E.effectsFastMs
                easing.type: Easing.BezierSpline
                easing.bezierCurve: M3E.curveEffects
            }
        }

        Column {
            id: tileCol
            anchors.centerIn: parent
            spacing: Math.max(2, Math.round(Theme.spacingXS * 0.5))

            DIcon {
                anchors.horizontalCenter: parent.horizontalCenter
                name: tile.iconName
                size: Theme.iconSizeSmall
                color: tile.iconColor
            }

            StyledText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: tile.label
                font.pixelSize: Theme.fontSizeSmall
                font.weight: (tile.active || tile.primaryCta) ? Font.Bold : Font.Medium
                color: tile.fgColor
            }
        }

        DRipple {
            id: tileRipple
            anchors.fill: parent
            rippleColor: tile.primaryCta ? (Theme.onError ?? Theme.background) : Theme.primary
            topLeftRadius: tile.topLeftRadius
            bottomLeftRadius: tile.bottomLeftRadius
            topRightRadius: tile.topRightRadius
            bottomRightRadius: tile.bottomRightRadius
            clip: true
        }

        MouseArea {
            id: tileArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onPressed: mouse => tileRipple.trigger(mouse.x, mouse.y)
            onClicked: tile.clicked()
        }
    }

    component ToolbarDivider: Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: 1
        height: Math.round(root.tileHeight * 0.55)
        color: Theme.withAlpha(Theme.outlineVariant, 0.45)
    }

    FocusScope {
        id: focusScope
        anchors.fill: parent
        focus: root.shouldBeVisible
        Keys.onEscapePressed: root.dismiss()

        MouseArea {
            anchors.fill: parent
            onClicked: root.dismiss()
        }

        Rectangle {
            id: toolbarCard

            readonly property real collapsedWidth: collapsedRow.implicitWidth + root.cardPad * 2
            readonly property real screenshotExpandedWidth: Math.max(collapsedWidth, screenshotExpandedRow.implicitWidth + root.cardPad * 2)
            readonly property real recordingExpandedWidth: Math.max(collapsedWidth, expandedRow.implicitWidth + root.cardPad * 2)
            readonly property real recordingWidth: Math.max(collapsedWidth, activeRecordingRow.implicitWidth + Theme.spacingL * 2)

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: root.edgeInset("bottom") + Theme.spacingM

            width: {
                if (root.isRecording)
                    return recordingWidth;
                if (root.expandedMode === "screenshot")
                    return screenshotExpandedWidth;
                if (root.expandedMode === "recording")
                    return recordingExpandedWidth;
                return collapsedWidth;
            }
            height: root.tileHeight + root.cardPad * 2
            radius: root.outerRadius
            clip: true
            color: Theme.withAlpha(Theme.surfaceContainer, Theme.popupTransparency)
            border.width: 1
            border.color: root.isRecording
                ? Theme.withAlpha(root.isPaused ? Theme.warning : Theme.error, 0.5)
                : Theme.withAlpha(Theme.outlineVariant, 0.6)

            Behavior on width {
                NumberAnimation {
                    duration: M3E.spatialDefaultMs
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: M3E.curveDefaultSpatial
                }
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.AllButtons
            }

            // Collapsed View: Connected Screenshot & Recording Tiles
            Row {
                id: collapsedRow
                anchors.centerIn: parent
                spacing: M3E.groupGap
                opacity: !root.isRecording && root.expandedMode === "" ? 1.0 : 0.0
                visible: opacity > 0.01
                enabled: !root.isRecording && root.expandedMode === ""

                Behavior on opacity {
                    NumberAnimation {
                        duration: M3E.effectsFastMs
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: M3E.curveEffects
                    }
                }

                ToolbarTile {
                    minWidth: Theme.iconSizeLarge * 4
                    iconName: "screenshot_region"
                    label: I18n.trFor("quickCapture", "Screenshot")
                    leftRadius: root.tileOuterRadius
                    rightRadius: root.seamRadius
                    onClicked: root.expandedMode = "screenshot"
                }

                ToolbarTile {
                    minWidth: Theme.iconSizeLarge * 4
                    iconName: "videocam"
                    label: I18n.trFor("quickCapture", "Recording")
                    leftRadius: root.seamRadius
                    rightRadius: root.tileOuterRadius
                    onClicked: root.expandedMode = "recording"
                }
            }

            // Expanded View: Screenshot Modes
            Row {
                id: screenshotExpandedRow
                anchors.centerIn: parent
                spacing: Theme.spacingXS
                opacity: !root.isRecording && root.expandedMode === "screenshot" ? 1.0 : 0.0
                visible: opacity > 0.01
                enabled: !root.isRecording && root.expandedMode === "screenshot"

                Behavior on opacity {
                    NumberAnimation {
                        duration: M3E.effectsFastMs
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: M3E.curveEffects
                    }
                }

                ToolbarTile {
                    iconName: "arrow_back"
                    label: I18n.trFor("quickCapture", "Back")
                    onClicked: root.expandedMode = ""
                }

                ToolbarDivider {}

                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: M3E.groupGap

                    Repeater {
                        model: root.screenshotTargets

                        delegate: ToolbarTile {
                            required property var modelData
                            required property int index

                            iconName: modelData.icon
                            label: modelData.label
                            leftRadius: index === 0 ? root.tileOuterRadius : root.seamRadius
                            rightRadius: index === root.screenshotTargets.length - 1 ? root.tileOuterRadius : root.seamRadius
                            onClicked: root.dismiss(() => {
                                if (root.daemon)
                                    root.daemon.capture(modelData.value, "edit", "", false);
                            })
                        }
                    }
                }
            }

            // Expanded View: Recording Controls (Unified Icon + Label Tiles)
            Row {
                id: expandedRow
                anchors.centerIn: parent
                spacing: Theme.spacingXS
                opacity: !root.isRecording && root.expandedMode === "recording" ? 1.0 : 0.0
                visible: opacity > 0.01
                enabled: !root.isRecording && root.expandedMode === "recording"

                Behavior on opacity {
                    NumberAnimation {
                        duration: M3E.effectsFastMs
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: M3E.curveEffects
                    }
                }

                ToolbarTile {
                    iconName: "arrow_back"
                    label: I18n.trFor("quickCapture", "Back")
                    onClicked: root.expandedMode = ""
                }

                ToolbarDivider {}

                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: M3E.groupGap

                    Repeater {
                        model: root.recordTargets

                        delegate: ToolbarTile {
                            required property var modelData
                            required property int index
                            readonly property bool isSelected: root.selectedRecordMode === modelData.value

                            iconName: modelData.icon
                            label: modelData.label
                            active: isSelected
                            leftRadius: (isSelected || index === 0) ? root.tileOuterRadius : root.seamRadius
                            rightRadius: (isSelected || index === root.recordTargets.length - 1) ? root.tileOuterRadius : root.seamRadius
                            onClicked: root.selectedRecordMode = modelData.value
                        }
                    }
                }

                ToolbarDivider {
                    visible: root.recordingHasAudio && !root.recordingIsGif
                }

                Row {
                    visible: root.recordingHasAudio && !root.recordingIsGif
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: M3E.groupGap

                    ToolbarTile {
                        iconName: (root.recorder && root.recorder.recordMic) ? "mic" : "mic_off"
                        label: I18n.trFor("quickCapture", "Mic")
                        active: root.recorder ? root.recorder.recordMic : false
                        leftRadius: root.tileOuterRadius
                        rightRadius: root.seamRadius
                        onClicked: {
                            if (root.daemon && root.recorder)
                                root.daemon.savePluginData("recordMic", !root.recorder.recordMic);
                        }
                    }

                    ToolbarTile {
                        iconName: (root.recorder && root.recorder.recordAudio) ? "volume_up" : "volume_off"
                        label: I18n.trFor("quickCapture", "Audio")
                        active: root.recorder ? root.recorder.recordAudio : false
                        leftRadius: root.seamRadius
                        rightRadius: root.tileOuterRadius
                        onClicked: {
                            if (root.daemon && root.recorder)
                                root.daemon.savePluginData("recordSystemAudio", !root.recorder.recordAudio);
                        }
                    }
                }

                ToolbarDivider {}

                ToolbarTile {
                    iconName: "fiber_manual_record"
                    label: I18n.trFor("quickCapture", "Record")
                    primaryCta: true
                    onClicked: root.dismiss(() => {
                        if (root.daemon)
                            root.daemon.record(root.selectedRecordMode, "", false);
                    })
                }
            }

            // Active Recording State
            Row {
                id: activeRecordingRow
                anchors.centerIn: parent
                spacing: Theme.spacingM
                opacity: root.isRecording ? 1.0 : 0.0
                visible: opacity > 0.01
                enabled: root.isRecording

                Behavior on opacity {
                    NumberAnimation {
                        duration: M3E.effectsFastMs
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: M3E.curveEffects
                    }
                }

                RecordingDot {
                    anchors.verticalCenter: parent.verticalCenter
                    dotSize: 10
                    paused: root.isPaused
                    blink: root.isRecording && root.blinkRecordDot
                }

                StyledText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.durationText
                    font.pixelSize: Theme.fontSizeLarge
                    font.weight: Font.Bold
                    font.features: {
                        "tnum": 1
                    }
                    color: root.isPaused ? Theme.warning : Theme.surfaceText
                }

                RecordingTransport {
                    anchors.verticalCenter: parent.verticalCenter
                    recorder: root.recorder
                    buttonSize: 34
                    iconSize: 18
                    filled: true
                    showCancel: true
                    onActionTriggered: action => {
                        if (action !== "pause")
                            root.dismiss();
                    }
                }
            }
        }
    }
}
