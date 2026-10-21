import QtQuick
import Quickshell
import qs.Common
import qs.Services
import qs.Widgets
import "../core/Defaults.js" as Defaults
import "../../shared"

Item {
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

    readonly property real contentWidth: 432
    readonly property real contentHeight: 304
    implicitWidth: contentWidth + Theme.spacingM * 2
    implicitHeight: contentHeight + Theme.spacingM * 2

    readonly property int spatialFastMs: M3E.spatialFastMs
    readonly property int spatialDefaultMs: M3E.spatialDefaultMs
    readonly property int effectsFastMs: M3E.effectsFastMs
    readonly property int effectsMs: M3E.effectsMs
    readonly property var curveFastSpatial: M3E.curveFastSpatial
    readonly property var curveDefaultSpatial: M3E.curveDefaultSpatial
    readonly property var curveEffects: M3E.curveEffects

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

    function refreshState() {
        if (!root.daemon)
            return;
        root.daemon.refreshOutputs();
        if (root.videoMode)
            root.daemon.refreshAudioDevices();
    }

    Component.onCompleted: refreshState()
    onVideoModeChanged: {
        if (root.videoMode && root.daemon)
            root.daemon.refreshAudioDevices();
    }

    function run(mode, action, outputName) {
        if (!root.daemon)
            return;
        root.widget.runAfterPopoutClosed(() => root.daemon.capture(mode, action, outputName));
    }

    // M3E Expressive Tile with shape morphing & tonal icon pill
    component ExpressiveTile: Rectangle {
        id: tile
        required property var modelData
        property int columns: 4
        property real tileHeight: 90
        property bool highlighted: false
        property bool showPin: true
        property string rightClickAction: "copy"

        signal triggered(string action)

        readonly property bool canShowPin: showPin && rightClickAction !== "float"
        readonly property bool hovered: tileMouse.containsMouse || pinMouse.containsMouse
        readonly property bool pressed: tileMouse.pressed

        width: (parent.width - parent.spacing * (columns - 1)) / columns
        height: tileHeight

        // M3E shape morphing: squircle at rest -> rounder on hover -> sharp squircle on press
        radius: M3E.tileRadius(pressed, hovered, highlighted)

        color: highlighted
            ? (hovered ? Theme.blend(Theme.primaryContainer, Theme.primary, M3E.activeBlendFactor) : Theme.primaryContainer)
            : (hovered ? Theme.secondaryContainer : Theme.surfaceContainerHigh)

        border.width: highlighted || hovered ? 1 : 0
        border.color: highlighted
            ? Theme.withAlpha(Theme.primary, hovered ? 0.55 : 0.28)
            : Theme.withAlpha(Theme.primary, 0.35)

        scale: pressed ? M3E.tilePressScale : 1.0

        Behavior on radius {
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
                duration: M3E.effectsMs
                easing.type: Easing.BezierSpline
                easing.bezierCurve: M3E.curveEffects
            }
        }

        Column {
            anchors.centerIn: parent
            width: parent.width - Theme.spacingS * 2
            spacing: 6

            // M3E Morphing Icon Pill
            Rectangle {
                id: iconPill
                anchors.horizontalCenter: parent.horizontalCenter
                width: tile.hovered || tile.highlighted ? 46 : 38
                height: 32
                radius: M3E.iconPillRadius(tile.pressed, tile.hovered, height)
                color: tile.highlighted
                    ? Theme.primary
                    : (tile.hovered ? Theme.primary : Theme.surfaceContainerHighest)

                Behavior on width {
                    NumberAnimation {
                        duration: M3E.spatialFastMs
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: M3E.curveFastSpatial
                    }
                }
                Behavior on radius {
                    NumberAnimation {
                        duration: M3E.spatialFastMs
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: M3E.curveFastSpatial
                    }
                }
                Behavior on color {
                    ColorAnimation {
                        duration: M3E.effectsMs
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: M3E.curveEffects
                    }
                }

                DankIcon {
                    anchors.centerIn: parent
                    name: tile.modelData.icon
                    size: Theme.iconSize - 2
                    color: tile.highlighted || tile.hovered ? Theme.onPrimary : Theme.surfaceText
                    Behavior on color {
                        ColorAnimation {
                            duration: M3E.effectsFastMs
                        }
                    }
                }
            }

            StyledText {
                text: tile.modelData.label
                font.pixelSize: Theme.fontSizeSmall
                font.weight: tile.hovered || tile.highlighted ? Font.Bold : Font.Medium
                color: tile.highlighted
                    ? Theme.onPrimaryContainer
                    : (tile.hovered ? Theme.onSecondaryContainer : Theme.surfaceText)
                width: parent.width
                anchors.horizontalCenter: parent.horizontalCenter
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
            }
        }

        DankRipple {
            id: tileRipple
            anchors.fill: parent
            rippleColor: tile.highlighted ? Theme.onPrimaryContainer : Theme.primary
            cornerRadius: tile.radius
            clip: true
        }

        MouseArea {
            id: tileMouse
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            cursorShape: Qt.PointingHandCursor
            onPressed: mouse => tileRipple.trigger(mouse.x, mouse.y)
            onClicked: mouse => tile.triggered(mouse.button === Qt.RightButton ? tile.rightClickAction : "edit")
        }

        // Expressive Floating Pin Pill
        Rectangle {
            id: pinBtn
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.margins: 5
            width: 24
            height: 24
            radius: pinMouse.pressed ? M3E.pressRadiusXS : height / 2
            color: pinMouse.containsMouse ? Theme.tertiaryContainer : Theme.withAlpha(Theme.surfaceContainerHighest, 0.92)
            opacity: tile.canShowPin && tile.hovered ? 1 : 0
            scale: tile.canShowPin && tile.hovered ? (pinMouse.containsMouse ? M3E.pinHoverScale : 1.0) : M3E.pinHiddenScale
            visible: opacity > 0.01
            z: 2

            Behavior on opacity {
                NumberAnimation {
                    duration: M3E.effectsFastMs
                }
            }
            Behavior on scale {
                NumberAnimation {
                    duration: M3E.spatialFastMs
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: M3E.curveFastSpatial
                }
            }
            Behavior on radius {
                NumberAnimation {
                    duration: M3E.spatialFastMs
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: M3E.curveFastSpatial
                }
            }

            DankIcon {
                anchors.centerIn: parent
                name: "keep"
                size: 13
                color: pinMouse.containsMouse ? Theme.onTertiaryContainer : Theme.surfaceVariantText
            }

            MouseArea {
                id: pinMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: tile.triggered("float")
            }
        }
    }

    // M3E Connected Action Group Button
    component ConnectedIconButton: Rectangle {
        id: cBtn
        property string iconName: ""
        property string tooltipText: ""
        property bool isFirst: false
        property bool isLast: false
        signal clicked

        readonly property real outerR: height / 2
        readonly property real innerR: M3E.innerR
        readonly property real pressR: M3E.pressRadiusXXS

        width: 34
        height: 38
        scale: btnMouse.pressed ? M3E.iconBtnPressScale : 1.0
        color: btnMouse.containsMouse ? Theme.secondaryContainer : Theme.surfaceContainerHigh

        topLeftRadius: btnMouse.pressed ? pressR : (btnMouse.containsMouse || isFirst ? outerR : innerR)
        bottomLeftRadius: btnMouse.pressed ? pressR : (btnMouse.containsMouse || isFirst ? outerR : innerR)
        topRightRadius: btnMouse.pressed ? pressR : (btnMouse.containsMouse || isLast ? outerR : innerR)
        bottomRightRadius: btnMouse.pressed ? pressR : (btnMouse.containsMouse || isLast ? outerR : innerR)

        Behavior on scale {
            NumberAnimation {
                duration: root.spatialFastMs
                easing.type: Easing.BezierSpline
                easing.bezierCurve: root.curveFastSpatial
            }
        }
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

        DankIcon {
            anchors.centerIn: parent
            name: cBtn.iconName
            size: Theme.iconSizeSmall
            color: btnMouse.containsMouse ? Theme.onSecondaryContainer : Theme.surfaceVariantText
        }

        MouseArea {
            id: btnMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: cBtn.clicked()
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
            width: Math.min(implicitWidth, parent.width - 110)
            text: infoRow.value
            font.pixelSize: Theme.fontSizeSmall
            font.weight: Font.Medium
            color: infoRow.accent ? Theme.surfaceText : Theme.surfaceVariantText
            horizontalAlignment: Text.AlignRight
            elide: Text.ElideRight
        }
    }

    Column {
        x: Theme.spacingM
        y: Theme.spacingM
        width: root.contentWidth
        height: root.contentHeight
        spacing: Theme.spacingM

        // Top Bar (38px): M3E Connected Button Group Mode Switcher + Connected Utility Group
        Item {
            width: parent.width
            height: 38

            // M3E Connected Segmented Button Group (expands active segment & morphs pill <-> inner seam)
            Row {
                id: modeSwitcher
                anchors.left: parent.left
                anchors.right: actionButtonsRow.left
                anchors.rightMargin: Theme.spacingS
                anchors.verticalCenter: parent.verticalCenter
                height: 38
                spacing: Theme.groupedListGap ?? 2

                property real activeFrac: root.videoMode ? 1.0 : 0.0
                Behavior on activeFrac {
                    NumberAnimation {
                        duration: root.spatialFastMs
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: root.curveFastSpatial
                    }
                }

                readonly property real availW: Math.max(0, width - spacing)
                readonly property real leftW: Math.round(availW * (0.56 - 0.12 * activeFrac))
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
                        id: seg
                        required property var modelData
                        readonly property bool selected: root.widget.widgetMode === modelData.mode
                        readonly property bool activeRec: modelData.mode === "video" && root.isRecording
                        readonly property color activeBg: activeRec ? Theme.error : Theme.primary
                        readonly property color activeFg: activeRec ? (Theme.onError ?? Theme.background) : Theme.onPrimary
                        readonly property real pillR: height / 2
                        readonly property real innerR: Theme.groupedListInnerRadius ?? 6
                        readonly property real pressR: Theme.cornerRadiusS ?? 8

                        width: modelData.isFirst ? modeSwitcher.leftW : modeSwitcher.rightW
                        height: modeSwitcher.height
                        clip: true
                        color: selected
                            ? activeBg
                            : (segMouse.containsMouse ? Theme.secondaryContainer : Theme.surfaceContainerHigh)

                        topLeftRadius: segMouse.pressed ? pressR : (selected || modelData.isFirst ? pillR : innerR)
                        bottomLeftRadius: segMouse.pressed ? pressR : (selected || modelData.isFirst ? pillR : innerR)
                        topRightRadius: segMouse.pressed ? pressR : (selected || !modelData.isFirst ? pillR : innerR)
                        bottomRightRadius: segMouse.pressed ? pressR : (selected || !modelData.isFirst ? pillR : innerR)

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
                                name: seg.modelData.icon
                                size: Theme.iconSizeSmall
                                color: seg.selected ? seg.activeFg : (segMouse.containsMouse ? Theme.onSecondaryContainer : Theme.surfaceVariantText)
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            StyledText {
                                width: Math.min(implicitWidth, Math.max(0, seg.width - Theme.iconSizeSmall - 24))
                                text: seg.modelData.label
                                font.pixelSize: Theme.fontSizeSmall
                                font.weight: seg.selected ? Font.Bold : Font.Medium
                                color: seg.selected ? seg.activeFg : (segMouse.containsMouse ? Theme.onSecondaryContainer : Theme.surfaceVariantText)
                                elide: Text.ElideRight
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        MouseArea {
                            id: segMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.widget.setWidgetMode(seg.modelData.mode)
                        }
                    }
                }
            }

            // Connected Utility Action Buttons
            Row {
                id: actionButtonsRow
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: Theme.groupedListGap ?? 2

                ConnectedIconButton {
                    isFirst: true
                    iconName: "open_in_new"
                    tooltipText: root.videoMode ? I18n.trFor("quickCapture", "Recording Folder") : I18n.trFor("quickCapture", "Screenshot Folder")
                    onClicked: {
                        root.widget.closePopout();
                        root.daemon?.openFolder(root.videoMode ? "video" : "photo");
                    }
                }

                ConnectedIconButton {
                    isLast: true
                    iconName: "history"
                    tooltipText: I18n.trFor("quickCapture", "History")
                    onClicked: {
                        root.widget.closePopout();
                        root.daemon?.showHistoryCarousel();
                    }
                }
            }
        }

        // Fixed-Height Body Container (254px) with M3E Spatial Crossfade & Slide
        Item {
            width: parent.width
            height: 254

            // PHOTO VIEW
            Column {
                id: photoPage
                width: parent.width
                height: parent.height
                spacing: Theme.spacingS
                x: !root.videoMode ? 0 : -24
                opacity: !root.videoMode ? 1.0 : 0.0
                scale: !root.videoMode ? 1.0 : 0.96
                visible: opacity > 0.01
                enabled: !root.videoMode

                Behavior on x {
                    NumberAnimation {
                        duration: root.spatialFastMs
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: root.curveDefaultSpatial
                    }
                }
                Behavior on opacity {
                    NumberAnimation {
                        duration: root.effectsMs
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: root.curveEffects
                    }
                }
                Behavior on scale {
                    NumberAnimation {
                        duration: root.spatialFastMs
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: root.curveDefaultSpatial
                    }
                }

                Grid {
                    width: parent.width
                    columns: 4
                    spacing: Theme.spacingS

                    Repeater {
                        model: root.config.modesFor(["region", "window", "full", "last", "scroll", "all", "clipboard", "selectFile"])

                        delegate: ExpressiveTile {
                            columns: 4
                            tileHeight: 92
                            highlighted: modelData.value === "region"
                            rightClickAction: root.menuRightClickAction
                            onTriggered: action => root.run(modelData.value, action)
                        }
                    }
                }

                // Output Strip (54px) — M3E Pill Bar
                Rectangle {
                    width: parent.width
                    height: 54
                    radius: Theme.cornerRadiusXL ?? 24
                    color: Theme.surfaceContainerHigh

                    Row {
                        id: outputLabelRow
                        anchors.left: parent.left
                        anchors.leftMargin: Theme.spacingM
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Theme.spacingXS

                        Rectangle {
                            width: 28
                            height: 28
                            radius: height / 2
                            color: Theme.secondaryContainer
                            anchors.verticalCenter: parent.verticalCenter

                            DankIcon {
                                anchors.centerIn: parent
                                name: "display_settings"
                                size: 15
                                color: Theme.onSecondaryContainer
                            }
                        }

                        StyledText {
                            text: I18n.trFor("quickCapture", "Specific Output")
                            font.pixelSize: Theme.fontSizeSmall
                            font.weight: Font.Bold
                            color: Theme.surfaceText
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    Flickable {
                        anchors.left: outputLabelRow.right
                        anchors.leftMargin: Theme.spacingS
                        anchors.right: parent.right
                        anchors.rightMargin: Theme.spacingS
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        contentWidth: outputsChipRow.implicitWidth
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds

                        Row {
                            id: outputsChipRow
                            height: parent.height
                            spacing: 6

                            Repeater {
                                model: root.daemon?.outputs ?? []

                                delegate: Rectangle {
                                    id: outChip
                                    required property var modelData
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: chipRow.implicitWidth + Theme.spacingM * 2
                                    height: 36
                                    radius: chipMouse.pressed
                                        ? (Theme.cornerRadiusS ?? 8)
                                        : (chipMouse.containsMouse ? (Theme.cornerRadiusM ?? 12) : height / 2)
                                    color: chipMouse.containsMouse ? Theme.primaryContainer : Theme.surfaceContainerHighest

                                    Behavior on radius {
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
                                        id: chipRow
                                        anchors.centerIn: parent
                                        spacing: 6

                                        DankIcon {
                                            name: "monitor"
                                            size: 14
                                            color: chipMouse.containsMouse ? Theme.onPrimaryContainer : Theme.primary
                                            anchors.verticalCenter: parent.verticalCenter
                                        }

                                        StyledText {
                                            text: outChip.modelData.name + " · " + outChip.modelData.width + "×" + outChip.modelData.height
                                            font.pixelSize: Theme.fontSizeSmall
                                            font.weight: Font.Medium
                                            color: chipMouse.containsMouse ? Theme.onPrimaryContainer : Theme.surfaceText
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                    }

                                    MouseArea {
                                        id: chipMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: mouse => root.run("output", mouse.button === Qt.RightButton ? root.menuRightClickAction : "edit", outChip.modelData.name)
                                    }
                                }
                            }

                            StyledText {
                                visible: (root.daemon?.outputs ?? []).length === 0
                                anchors.verticalCenter: parent.verticalCenter
                                text: I18n.trFor("quickCapture", "No output available")
                                font.pixelSize: Theme.fontSizeSmall
                                font.italic: true
                                color: Theme.surfaceVariantText
                            }
                        }
                    }
                }
            }

            // VIDEO VIEW (Idle & Recording)
            Item {
                id: videoPage
                width: parent.width
                height: parent.height
                x: root.videoMode ? 0 : 24
                opacity: root.videoMode ? 1.0 : 0.0
                scale: root.videoMode ? 1.0 : 0.96
                visible: opacity > 0.01
                enabled: root.videoMode

                Behavior on x {
                    NumberAnimation {
                        duration: root.spatialFastMs
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: root.curveDefaultSpatial
                    }
                }
                Behavior on opacity {
                    NumberAnimation {
                        duration: root.effectsMs
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: root.curveEffects
                    }
                }
                Behavior on scale {
                    NumberAnimation {
                        duration: root.spatialFastMs
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: root.curveDefaultSpatial
                    }
                }

                // IDLE VIDEO STATE
                Column {
                    anchors.fill: parent
                    spacing: Theme.spacingS
                    visible: !root.isRecording

                    Grid {
                        width: parent.width
                        columns: 3
                        spacing: Theme.spacingS

                        Repeater {
                            model: root.config.recordModes

                            delegate: ExpressiveTile {
                                columns: 3
                                tileHeight: 96
                                highlighted: modelData.value === "region"
                                showPin: false
                                onTriggered: root.widget.runAfterPopoutClosed(() => root.daemon?.record(modelData.value))
                            }
                        }
                    }

                    // M3E Grouped Card Stack for Audio & Output Format (150px)
                    Column {
                        width: parent.width
                        spacing: Theme.groupedListGap ?? 2

                        readonly property real outerR: Theme.groupedListOuterRadius ?? (Theme.cornerRadiusL ?? 16)
                        readonly property real innerR: Theme.groupedListInnerRadius ?? (Theme.cornerRadiusXS ?? 6)

                        // Group Item 1: Microphone (52px)
                        Rectangle {
                            width: parent.width
                            height: 52
                            color: Theme.surfaceContainerHigh
                            topLeftRadius: parent.outerR
                            topRightRadius: parent.outerR
                            bottomLeftRadius: parent.innerR
                            bottomRightRadius: parent.innerR

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
                                    color: micOffMouse.containsMouse ? Theme.surfaceContainerHighest : "transparent"

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
                                        id: micOffMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.daemon?.savePluginData("recordMic", true)
                                    }
                                }
                            }
                        }

                        // Group Item 2: System Audio (52px)
                        Rectangle {
                            width: parent.width
                            height: 52
                            color: Theme.surfaceContainerHigh
                            radius: parent.innerR

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
                                    color: audioOffMouse.containsMouse ? Theme.surfaceContainerHighest : "transparent"

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
                                        id: audioOffMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.daemon?.savePluginData("recordSystemAudio", true)
                                    }
                                }
                            }
                        }

                        // Group Item 3: Output Format Footer (42px)
                        Rectangle {
                            width: parent.width
                            height: 42
                            color: Theme.surfaceContainerHigh
                            topLeftRadius: parent.innerR
                            topRightRadius: parent.innerR
                            bottomLeftRadius: parent.outerR
                            bottomRightRadius: parent.outerR

                            Row {
                                anchors.left: parent.left
                                anchors.leftMargin: Theme.spacingM
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: Theme.spacingS

                                DankIcon {
                                    name: "movie"
                                    size: 16
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
                                anchors.rightMargin: Theme.spacingS
                                anchors.verticalCenter: parent.verticalCenter
                                width: fmtLabel.implicitWidth + Theme.spacingM * 2
                                height: 26
                                radius: height / 2
                                color: Theme.secondaryContainer

                                StyledText {
                                    id: fmtLabel
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

                // ACTIVE RECORDING STATE (M3E Grouped Hero + Telemetry Card)
                Column {
                    anchors.fill: parent
                    spacing: Theme.groupedListGap ?? 2
                    visible: root.isRecording

                    readonly property real outerR: Theme.groupedListOuterRadius ?? (Theme.cornerRadiusXL ?? 24)
                    readonly property real innerR: Theme.groupedListInnerRadius ?? (Theme.cornerRadiusXS ?? 6)

                    // Top Hero Card: Timer & Transport (128px)
                    Rectangle {
                        width: parent.width
                        height: 128
                        color: root.widget.isPaused
                            ? Theme.withAlpha(Theme.warning, 0.14)
                            : Theme.errorContainer
                        topLeftRadius: parent.outerR
                        topRightRadius: parent.outerR
                        bottomLeftRadius: parent.innerR
                        bottomRightRadius: parent.innerR

                        Column {
                            anchors.centerIn: parent
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
                                    font.pixelSize: Theme.fontSizeXLarge
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
                                buttonSize: 36
                                iconSize: Theme.iconSize
                                filled: true
                                onActionTriggered: action => {
                                    if (action !== "pause")
                                        root.widget.closePopout();
                                }
                            }
                        }
                    }

                    // Bottom Telemetry Card (124px)
                    Rectangle {
                        width: parent.width
                        height: 124
                        color: Theme.surfaceContainerHigh
                        topLeftRadius: parent.innerR
                        topRightRadius: parent.innerR
                        bottomLeftRadius: parent.outerR
                        bottomRightRadius: parent.outerR

                        Column {
                            anchors.fill: parent
                            anchors.margins: Theme.spacingM
                            spacing: 6

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
            }
        }
    }
}
