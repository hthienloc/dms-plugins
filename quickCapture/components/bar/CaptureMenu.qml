import QtQuick
import Quickshell
import qs.Common
import qs.Modules.Plugins
import qs.Services
import qs.Widgets
import "../core/Defaults.js" as Defaults
import "../../shared"

PopoutComponent {
    id: root

    required property var widget
    readonly property var daemon: widget.daemon
    readonly property var recorder: widget.recorder
    readonly property var config: widget.config
    readonly property bool isRecording: widget.isRecording
    readonly property bool videoMode: widget.widgetMode === "video"
    readonly property string menuRightClickAction: Defaults.get(widget.pluginData, "menuRightClickAction")
    readonly property bool recordingIsGif: (recorder?.videoFormat ?? "mp4") === "gif"
    readonly property bool recordingHasAudio: (recorder?.activeRecorderBin ?? "") !== "wf-recorder"
    property bool outputExpanded: false

    readonly property int spatialFastMs: M3E.spatialFastMs
    readonly property int effectsFastMs: M3E.effectsFastMs
    readonly property int effectsMs: M3E.effectsMs
    readonly property var curveFastSpatial: M3E.curveFastSpatial
    readonly property var curveEffects: M3E.curveEffects

    readonly property real outerR: M3E.outerR
    readonly property real innerR: M3E.innerR
    readonly property real groupGap: M3E.groupGap

    readonly property string recordingTargetIcon: {
        switch (recorder?.activeRecordingMode) {
        case "region":
            return "crop_square";
        case "portal":
            return "window";
        default:
            return "fullscreen";
        }
    }

    readonly property string recordingTargetText: {
        if (!recorder)
            return "";
        if (recorder.activeRecordingMode === "region")
            return recorder.regionW > 0 ? recorder.regionW + " × " + recorder.regionH : I18n.trFor("quickCapture", "Region");
        if (recorder.activeRecordingMode === "portal")
            return I18n.trFor("quickCapture", "Window");
        const target = Defaults.get(widget.pluginData, "recordingScreenTarget");
        let scr = Quickshell.screens.find(s => s.name === target) ?? null;
        if (!scr)
            scr = CompositorService.getFocusedScreen() ?? Quickshell.screens[0] ?? null;
        if (!scr)
            return I18n.trFor("quickCapture", "Fullscreen");
        return scr.name + " (" + scr.width + " × " + scr.height + ")";
    }

    readonly property string recordingFormatText: {
        if (!recorder)
            return "";
        const fmt = (recorder.videoFormat || "mp4").toUpperCase();
        const fps = fmt === "GIF" ? (recorder.gifFramerate || 15) : (recorder.framerate || 60);
        return fmt + " · " + fps + " FPS";
    }

    width: widget.popoutWidth
    headerText: ""
    showCloseButton: false
    spacing: Theme.spacingS
    closePopout: () => widget.closePopout()

    function refreshDevices() {
        if (root.videoMode && root.daemon)
            root.daemon.refreshAudioDevices();
    }

    Component.onCompleted: refreshDevices()
    onVideoModeChanged: refreshDevices()

    function run(mode, action, outputName) {
        if (!root.daemon)
            return;
        root.widget.runAfterPopoutClosed(() => root.daemon.capture(mode, action, outputName));
    }

    component ConnectedFooterButton: Rectangle {
        id: fBtn
        property string iconName: ""
        property string label: ""
        property bool isFirst: false
        property bool isLast: false
        signal clicked

        readonly property real pillR: height / 2
        readonly property real seamR: M3E.innerR
        readonly property real pressR: M3E.pressRadiusS

        width: (parent.width - parent.spacing) / 2
        height: 36
        clip: true
        color: btnMouse.containsMouse ? Theme.secondaryContainer : Theme.surfaceContainerHigh

        topLeftRadius: btnMouse.pressed ? pressR : (btnMouse.containsMouse || isFirst ? pillR : seamR)
        bottomLeftRadius: btnMouse.pressed ? pressR : (btnMouse.containsMouse || isFirst ? pillR : seamR)
        topRightRadius: btnMouse.pressed ? pressR : (btnMouse.containsMouse || isLast ? pillR : seamR)
        bottomRightRadius: btnMouse.pressed ? pressR : (btnMouse.containsMouse || isLast ? pillR : seamR)

        Behavior on topLeftRadius {
            NumberAnimation {
                duration: root.spatialFastMs
                easing.type: Easing.BezierSpline
                easing.bezierCurve: root.curveFastSpatial
            }
        }
        Behavior on bottomLeftRadius {
            NumberAnimation {
                duration: root.spatialFastMs
                easing.type: Easing.BezierSpline
                easing.bezierCurve: root.curveFastSpatial
            }
        }
        Behavior on topRightRadius {
            NumberAnimation {
                duration: root.spatialFastMs
                easing.type: Easing.BezierSpline
                easing.bezierCurve: root.curveFastSpatial
            }
        }
        Behavior on bottomRightRadius {
            NumberAnimation {
                duration: root.spatialFastMs
                easing.type: Easing.BezierSpline
                easing.bezierCurve: root.curveFastSpatial
            }
        }
        Behavior on color {
            ColorAnimation {
                duration: root.effectsFastMs
            }
        }

        Row {
            anchors.centerIn: parent
            spacing: 6

            DankIcon {
                name: fBtn.iconName
                size: Theme.iconSizeSmall
                color: btnMouse.containsMouse ? Theme.onSecondaryContainer : Theme.surfaceVariantText
                anchors.verticalCenter: parent.verticalCenter
            }

            StyledText {
                width: Math.min(implicitWidth, Math.max(0, fBtn.width - Theme.iconSizeSmall - 22))
                text: fBtn.label
                font.pixelSize: Theme.fontSizeSmall
                font.weight: btnMouse.containsMouse ? Font.Bold : Font.Medium
                color: btnMouse.containsMouse ? Theme.onSecondaryContainer : Theme.surfaceText
                elide: Text.ElideRight
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        MouseArea {
            id: btnMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: fBtn.clicked()
        }
    }

    component InfoRow: Item {
        id: infoRow
        property string icon: ""
        property string label: ""
        property string value: ""
        property bool accent: false

        width: parent.width
        implicitHeight: 20

        Row {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.spacingXS

            DankIcon {
                name: infoRow.icon
                size: 14
                color: infoRow.accent ? Theme.primary : Theme.surfaceVariantText
                anchors.verticalCenter: parent.verticalCenter
            }

            StyledText {
                text: infoRow.label
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceVariantText
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        StyledText {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(implicitWidth, parent.width - 100)
            text: infoRow.value
            font.pixelSize: Theme.fontSizeSmall
            font.weight: Font.Medium
            color: infoRow.accent ? Theme.surfaceText : Theme.surfaceVariantText
            horizontalAlignment: Text.AlignRight
            elide: Text.ElideRight
        }
    }

    // M3E Connected Segmented Switcher
    Row {
        id: modeSwitcher
        width: parent.width
        height: 36
        spacing: root.groupGap

        property real activeFrac: root.videoMode ? 1.0 : 0.0
        Behavior on activeFrac {
            NumberAnimation {
                duration: root.spatialFastMs
                easing.type: Easing.BezierSpline
                easing.bezierCurve: root.curveFastSpatial
            }
        }

        readonly property real availW: Math.max(0, width - spacing)
        readonly property real leftW: Math.round(availW * (0.68 - 0.36 * activeFrac))
        readonly property real rightW: Math.max(0, availW - leftW)

        Repeater {
            model: [
                {
                    mode: "photo",
                    icon: "photo_camera",
                    label: I18n.trFor("quickCapture", "Screenshot"),
                    isFirst: true
                },
                {
                    mode: "video",
                    icon: "videocam",
                    label: root.isRecording
                        ? I18n.trFor("quickCapture", "Recording...")
                        : I18n.trFor("quickCapture", "Screen Recording"),
                    isFirst: false
                }
            ]

            delegate: Rectangle {
                id: segment
                required property var modelData
                readonly property bool selected: root.widget.widgetMode === modelData.mode
                readonly property bool activeRec: modelData.mode === "video" && root.isRecording
                readonly property color activeBg: activeRec ? Theme.error : Theme.primary
                readonly property color activeFg: activeRec ? (Theme.onError ?? Theme.background) : Theme.onPrimary
                readonly property real pillR: height / 2
                readonly property real seamR: root.innerR
                readonly property real pressR: Theme.cornerRadiusS ?? 8

                width: modelData.isFirst ? modeSwitcher.leftW : modeSwitcher.rightW
                height: modeSwitcher.height
                clip: true
                color: selected
                    ? activeBg
                    : (segmentArea.containsMouse ? Theme.secondaryContainer : Theme.surfaceContainerHigh)

                topLeftRadius: segmentArea.pressed ? pressR : (selected || modelData.isFirst ? pillR : seamR)
                bottomLeftRadius: segmentArea.pressed ? pressR : (selected || modelData.isFirst ? pillR : seamR)
                topRightRadius: segmentArea.pressed ? pressR : (selected || !modelData.isFirst ? pillR : seamR)
                bottomRightRadius: segmentArea.pressed ? pressR : (selected || !modelData.isFirst ? pillR : seamR)

                Behavior on topLeftRadius {
                    NumberAnimation {
                        duration: root.spatialFastMs
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: root.curveFastSpatial
                    }
                }
                Behavior on bottomLeftRadius {
                    NumberAnimation {
                        duration: root.spatialFastMs
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: root.curveFastSpatial
                    }
                }
                Behavior on topRightRadius {
                    NumberAnimation {
                        duration: root.spatialFastMs
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: root.curveFastSpatial
                    }
                }
                Behavior on bottomRightRadius {
                    NumberAnimation {
                        duration: root.spatialFastMs
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: root.curveFastSpatial
                    }
                }
                Behavior on color {
                    ColorAnimation {
                        duration: root.effectsMs
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: root.curveEffects
                    }
                }

                Row {
                    anchors.centerIn: parent
                    spacing: 6

                    DankIcon {
                        name: segment.modelData.icon
                        size: Theme.iconSizeSmall
                        color: segment.selected ? segment.activeFg : (segmentArea.containsMouse ? Theme.onSecondaryContainer : Theme.surfaceVariantText)
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    StyledText {
                        visible: segment.selected
                        width: Math.min(implicitWidth, Math.max(0, segment.width - Theme.iconSizeSmall - 24))
                        text: segment.modelData.label
                        font.pixelSize: Theme.fontSizeSmall
                        font.weight: Font.Bold
                        color: segment.activeFg
                        elide: Text.ElideRight
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea {
                    id: segmentArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.widget.setWidgetMode(segment.modelData.mode)
                }
            }
        }
    }

    // PHOTO MODE — M3E Grouped List Stacks
    Column {
        width: parent.width
        spacing: Theme.spacingS
        visible: !root.videoMode

        // Group 1: Primary Capture Modes (Region, Fullscreen, Window)
        Column {
            width: parent.width
            spacing: root.groupGap

            readonly property var items: root.config.modesFor(["region", "full", "window"])

            Repeater {
                model: parent.items

                delegate: CaptureMenuItem {
                    required property var modelData
                    required property int index
                    icon: modelData.icon
                    text: modelData.label
                    highlighted: modelData.value === "region"
                    isFirst: index === 0
                    isLast: index === 2
                    rightClickAction: root.menuRightClickAction
                    onTriggered: action => root.run(modelData.value, action)
                }
            }
        }

        // Group 2: Advanced Capture Modes + Specific Output Accordion
        Column {
            width: parent.width
            spacing: root.groupGap

            readonly property var advItems: root.config.modesFor(["last", "scroll", "all"])

            Repeater {
                model: parent.advItems

                delegate: CaptureMenuItem {
                    required property var modelData
                    required property int index
                    icon: modelData.icon
                    text: modelData.label
                    isFirst: index === 0
                    isLast: false
                    rightClickAction: root.menuRightClickAction
                    onTriggered: action => root.run(modelData.value, action)
                }
            }

            // Specific Output Accordion Row
            Rectangle {
                id: outputHeader
                width: parent.width
                height: 40
                color: outputMouse.containsMouse ? Theme.secondaryContainer : Theme.surfaceContainerHigh

                readonly property bool isBottomItem: !root.outputExpanded
                topLeftRadius: outputMouse.pressed ? (Theme.cornerRadiusS ?? 8) : (outputMouse.containsMouse ? height / 2 : root.innerR)
                topRightRadius: outputMouse.pressed ? (Theme.cornerRadiusS ?? 8) : (outputMouse.containsMouse ? height / 2 : root.innerR)
                bottomLeftRadius: outputMouse.pressed ? (Theme.cornerRadiusS ?? 8) : (outputMouse.containsMouse ? height / 2 : (isBottomItem ? root.outerR : root.innerR))
                bottomRightRadius: outputMouse.pressed ? (Theme.cornerRadiusS ?? 8) : (outputMouse.containsMouse ? height / 2 : (isBottomItem ? root.outerR : root.innerR))

                Behavior on topLeftRadius {
                    NumberAnimation {
                        duration: root.spatialFastMs
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: root.curveFastSpatial
                    }
                }
                Behavior on topRightRadius {
                    NumberAnimation {
                        duration: root.spatialFastMs
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: root.curveFastSpatial
                    }
                }
                Behavior on bottomLeftRadius {
                    NumberAnimation {
                        duration: root.spatialFastMs
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: root.curveFastSpatial
                    }
                }
                Behavior on bottomRightRadius {
                    NumberAnimation {
                        duration: root.spatialFastMs
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: root.curveFastSpatial
                    }
                }
                Behavior on color {
                    ColorAnimation {
                        duration: root.effectsMs
                    }
                }

                Row {
                    anchors.left: parent.left
                    anchors.leftMargin: 8
                    anchors.right: parent.right
                    anchors.rightMargin: 36
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Theme.spacingS

                    Rectangle {
                        width: outputMouse.containsMouse || root.outputExpanded ? 34 : 28
                        height: 26
                        radius: outputMouse.pressed ? 6 : (outputMouse.containsMouse ? 10 : height / 2)
                        color: outputMouse.containsMouse || root.outputExpanded ? Theme.primary : Theme.surfaceContainerHighest
                        anchors.verticalCenter: parent.verticalCenter

                        Behavior on width {
                            NumberAnimation {
                                duration: root.spatialFastMs
                                easing.type: Easing.BezierSpline
                                easing.bezierCurve: root.curveFastSpatial
                            }
                        }

                        DankIcon {
                            anchors.centerIn: parent
                            name: "display_settings"
                            size: Theme.iconSizeSmall
                            color: outputMouse.containsMouse || root.outputExpanded ? Theme.onPrimary : Theme.surfaceText
                        }
                    }

                    StyledText {
                        text: I18n.trFor("quickCapture", "Specific Output")
                        font.pixelSize: Theme.fontSizeMedium
                        font.weight: outputMouse.containsMouse || root.outputExpanded ? Font.Bold : Font.Medium
                        color: outputMouse.containsMouse ? Theme.onSecondaryContainer : Theme.surfaceText
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                DankIcon {
                    anchors.right: parent.right
                    anchors.rightMargin: Theme.spacingM
                    anchors.verticalCenter: parent.verticalCenter
                    name: root.outputExpanded ? "expand_less" : "expand_more"
                    size: Theme.iconSizeSmall
                    color: outputMouse.containsMouse ? Theme.onSecondaryContainer : Theme.surfaceVariantText
                }

                MouseArea {
                    id: outputMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (!root.daemon)
                            return;
                        root.outputExpanded = !root.outputExpanded;
                        if (root.outputExpanded)
                            root.daemon.refreshOutputs();
                    }
                }
            }

            Repeater {
                model: root.outputExpanded ? (root.daemon?.outputs ?? []) : []

                delegate: CaptureMenuItem {
                    required property var modelData
                    required property int index
                    height: 36
                    icon: "monitor"
                    text: modelData.name + "  (" + modelData.width + "×" + modelData.height + ")"
                    isFirst: false
                    isLast: index === (root.daemon?.outputs ?? []).length - 1
                    rightClickAction: root.menuRightClickAction
                    onTriggered: action => {
                        root.outputExpanded = false;
                        root.run("output", action, modelData.name);
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 36
                visible: root.outputExpanded && (root.daemon?.outputs ?? []).length === 0
                color: Theme.surfaceContainerHigh
                topLeftRadius: root.innerR
                topRightRadius: root.innerR
                bottomLeftRadius: root.outerR
                bottomRightRadius: root.outerR

                StyledText {
                    anchors.centerIn: parent
                    text: I18n.trFor("quickCapture", "No output available")
                    font.pixelSize: Theme.fontSizeSmall
                    font.italic: true
                    color: Theme.surfaceVariantText
                }
            }
        }

        // Group 3: Import Sources (Clipboard, Select File)
        Column {
            width: parent.width
            spacing: root.groupGap

            Repeater {
                model: root.config.modesFor(["clipboard", "selectFile"])

                delegate: CaptureMenuItem {
                    required property var modelData
                    required property int index
                    icon: modelData.icon
                    text: modelData.label
                    isFirst: index === 0
                    isLast: index === 1
                    rightClickAction: root.menuRightClickAction
                    onTriggered: action => root.run(modelData.value, action)
                }
            }
        }
    }

    // VIDEO MODE — M3E Grouped Card Stacks
    Column {
        width: parent.width
        spacing: Theme.spacingS
        visible: root.videoMode

        // ACTIVE RECORDING STATE
        Column {
            width: parent.width
            spacing: root.groupGap
            visible: root.isRecording

            // Top Hero Card
            Rectangle {
                width: parent.width
                height: activeHeroColumn.implicitHeight + Theme.spacingM * 2
                color: root.widget.isPaused
                    ? Theme.withAlpha(Theme.warning, 0.14)
                    : Theme.errorContainer
                topLeftRadius: root.outerR
                topRightRadius: root.outerR
                bottomLeftRadius: root.innerR
                bottomRightRadius: root.innerR

                Column {
                    id: activeHeroColumn
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: Theme.spacingM
                    spacing: Theme.spacingS

                    Row {
                        spacing: Theme.spacingS
                        anchors.horizontalCenter: parent.horizontalCenter

                        RecordingDot {
                            dotSize: 10
                            paused: root.widget.isPaused
                            blink: root.isRecording && root.widget.blinkRecordDot
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        StyledText {
                            text: (root.widget.isPaused ? I18n.trFor("quickCapture", "Paused") : I18n.trFor("quickCapture", "Recording")).toUpperCase()
                            font.pixelSize: Theme.fontSizeSmall
                            font.weight: Font.Bold
                            color: root.widget.isPaused ? Theme.warning : Theme.error
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        StyledText {
                            text: root.widget.durationText
                            font.pixelSize: Theme.fontSizeLarge
                            font.weight: Font.Bold
                            font.features: {
                                "tnum": 1
                            }
                            color: Theme.surfaceText
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    RecordingTransport {
                        anchors.horizontalCenter: parent.horizontalCenter
                        recorder: root.recorder
                        filled: true
                        onActionTriggered: action => {
                            if (action !== "pause")
                                root.widget.closePopout();
                        }
                    }
                }
            }

            // Bottom Telemetry Card
            Rectangle {
                width: parent.width
                height: activeTelemetryColumn.implicitHeight + Theme.spacingM * 2
                color: Theme.surfaceContainerHigh
                topLeftRadius: root.innerR
                topRightRadius: root.innerR
                bottomLeftRadius: root.outerR
                bottomRightRadius: root.outerR

                Column {
                    id: activeTelemetryColumn
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: Theme.spacingM
                    spacing: Theme.spacingXS

                    InfoRow {
                        icon: root.recordingTargetIcon
                        label: I18n.trFor("quickCapture", "Display")
                        value: root.recordingTargetText
                        accent: true
                    }

                    InfoRow {
                        visible: root.recordingHasAudio
                        readonly property bool on: !root.recordingIsGif && (root.recorder?.recordMic ?? false)
                        icon: on ? "mic" : "mic_off"
                        label: I18n.trFor("quickCapture", "Microphone")
                        value: on ? micRow.currentLabel : I18n.trFor("quickCapture", "Off")
                        accent: on
                    }

                    InfoRow {
                        visible: root.recordingHasAudio
                        readonly property bool on: !root.recordingIsGif && (root.recorder?.recordAudio ?? false)
                        icon: on ? "volume_up" : "volume_off"
                        label: I18n.trFor("quickCapture", "Audio")
                        value: on ? audioRow.currentLabel : I18n.trFor("quickCapture", "Off")
                        accent: on
                    }

                    InfoRow {
                        icon: "movie"
                        label: I18n.trFor("quickCapture", "Output Format")
                        value: root.recordingFormatText
                        accent: true
                    }
                }
            }
        }

        // IDLE RECORDING STATE
        Column {
            width: parent.width
            spacing: Theme.spacingS
            visible: !root.isRecording

            // Record Mode Stack
            Column {
                width: parent.width
                spacing: root.groupGap

                Repeater {
                    model: root.config.recordModes

                    delegate: CaptureMenuItem {
                        required property var modelData
                        required property int index
                        icon: modelData.icon
                        text: modelData.label
                        highlighted: modelData.value === "region"
                        isFirst: index === 0
                        isLast: index === 2
                        showPin: false
                        onTriggered: root.widget.runAfterPopoutClosed(() => root.daemon?.record(modelData.value))
                    }
                }
            }

            // Audio & Format Stack
            Column {
                width: parent.width
                spacing: root.groupGap

                // Microphone Card
                Rectangle {
                    width: parent.width
                    height: 52
                    color: Theme.surfaceContainerHigh
                    topLeftRadius: root.outerR
                    topRightRadius: root.outerR
                    bottomLeftRadius: root.innerR
                    bottomRightRadius: root.innerR

                    Item {
                        anchors.fill: parent
                        anchors.leftMargin: 6
                        anchors.rightMargin: 6

                        AudioSourceRow {
                            id: micRow
                            anchors.verticalCenter: parent.verticalCenter
                            active: root.recorder?.recordMic ?? false
                            iconOn: "mic"
                            iconOff: "mic_off"
                            options: root.recorder?.audioInputsList ?? []
                            currentValue: root.recorder?.micDevice ?? ""
                            onToggled: root.daemon?.savePluginData("recordMic", !active)
                            onValueSelected: value => root.daemon?.savePluginData("micDevice", value)
                        }

                        Rectangle {
                            visible: !micRow.active
                            anchors.left: parent.left
                            anchors.leftMargin: 40 + Theme.spacingS
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            height: 40
                            radius: Theme.cornerRadiusM ?? 12
                            color: micOffArea.containsMouse ? Theme.surfaceContainerHighest : "transparent"

                            StyledText {
                                anchors.left: parent.left
                                anchors.leftMargin: Theme.spacingS
                                anchors.verticalCenter: parent.verticalCenter
                                text: I18n.trFor("quickCapture", "Microphone") + " · " + I18n.trFor("quickCapture", "Off")
                                font.pixelSize: Theme.fontSizeSmall
                                font.weight: Font.Medium
                                color: Theme.surfaceVariantText
                            }

                            MouseArea {
                                id: micOffArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.daemon?.savePluginData("recordMic", true)
                            }
                        }
                    }
                }

                // System Audio Card
                Rectangle {
                    width: parent.width
                    height: 52
                    color: Theme.surfaceContainerHigh
                    radius: root.innerR

                    Item {
                        anchors.fill: parent
                        anchors.leftMargin: 6
                        anchors.rightMargin: 6

                        AudioSourceRow {
                            id: audioRow
                            anchors.verticalCenter: parent.verticalCenter
                            active: root.recorder?.recordAudio ?? false
                            iconOn: "volume_up"
                            iconOff: "volume_off"
                            options: root.recorder?.audioOutputsList ?? []
                            currentValue: root.recorder?.systemAudioDevice ?? ""
                            onToggled: root.daemon?.savePluginData("recordSystemAudio", !active)
                            onValueSelected: value => root.daemon?.savePluginData("systemAudioDevice", value)
                        }

                        Rectangle {
                            visible: !audioRow.active
                            anchors.left: parent.left
                            anchors.leftMargin: 40 + Theme.spacingS
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            height: 40
                            radius: Theme.cornerRadiusM ?? 12
                            color: audioOffArea.containsMouse ? Theme.surfaceContainerHighest : "transparent"

                            StyledText {
                                anchors.left: parent.left
                                anchors.leftMargin: Theme.spacingS
                                anchors.verticalCenter: parent.verticalCenter
                                text: I18n.trFor("quickCapture", "Audio") + " · " + I18n.trFor("quickCapture", "Off")
                                font.pixelSize: Theme.fontSizeSmall
                                font.weight: Font.Medium
                                color: Theme.surfaceVariantText
                            }

                            MouseArea {
                                id: audioOffArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.daemon?.savePluginData("recordSystemAudio", true)
                            }
                        }
                    }
                }

                // Output Format Card
                Rectangle {
                    width: parent.width
                    height: 40
                    color: Theme.surfaceContainerHigh
                    topLeftRadius: root.innerR
                    topRightRadius: root.innerR
                    bottomLeftRadius: root.outerR
                    bottomRightRadius: root.outerR

                    Row {
                        anchors.left: parent.left
                        anchors.leftMargin: Theme.spacingM
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Theme.spacingXS

                        DankIcon {
                            name: "movie"
                            size: 15
                            color: Theme.primary
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        StyledText {
                            text: I18n.trFor("quickCapture", "Output Format")
                            font.pixelSize: Theme.fontSizeSmall
                            font.weight: Font.Medium
                            color: Theme.surfaceVariantText
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    Rectangle {
                        anchors.right: parent.right
                        anchors.rightMargin: 6
                        anchors.verticalCenter: parent.verticalCenter
                        width: fmtBadge.implicitWidth + Theme.spacingM * 2
                        height: 26
                        radius: height / 2
                        color: Theme.secondaryContainer

                        StyledText {
                            id: fmtBadge
                            anchors.centerIn: parent
                            text: root.recordingFormatText
                            font.pixelSize: Theme.fontSizeSmall
                            font.weight: Font.Bold
                            color: Theme.onSecondaryContainer
                        }
                    }
                }
            }
        }
    }

    // Bottom Connected Utility Footer (Folder & History)
    Row {
        width: parent.width
        height: 36
        spacing: root.groupGap

        ConnectedFooterButton {
            isFirst: true
            iconName: "folder"
            label: I18n.trFor("quickCapture", "Folder")
            onClicked: {
                root.widget.closePopout();
                root.daemon?.openFolder(root.videoMode ? "video" : "photo");
            }
        }

        ConnectedFooterButton {
            isLast: true
            iconName: "history"
            label: I18n.trFor("quickCapture", "History")
            onClicked: {
                root.widget.closePopout();
                root.daemon?.showHistoryCarousel();
            }
        }
    }
}
