import QtQuick
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
    readonly property bool videoMode: widget.widgetMode === "video"
    readonly property bool isRecording: widget.isRecording
    readonly property string menuRightClickAction: Defaults.get(widget.pluginData, "menuRightClickAction")

    readonly property int spatialFastMs: M3E.spatialFastMs
    readonly property int effectsFastMs: M3E.effectsFastMs
    readonly property int effectsMs: M3E.effectsMs
    readonly property var curveFastSpatial: M3E.curveFastSpatial
    readonly property var curveDefaultSpatial: M3E.curveDefaultSpatial
    readonly property var curveEffects: M3E.curveEffects

    readonly property real outerR: M3E.outerR
    readonly property real innerR: M3E.innerR
    readonly property real groupGap: M3E.groupGap

    readonly property string recordingFormatText: {
        if (!recorder)
            return "";
        const fmt = (recorder.videoFormat || "mp4").toUpperCase();
        const fps = fmt === "GIF" ? (recorder.gifFramerate || 15) : (recorder.framerate || 60);
        return fmt + " · " + fps + " FPS";
    }

    implicitHeight: contentColumn.implicitHeight

    Component.onCompleted: {
        if (root.daemon) {
            root.daemon.refreshOutputs();
            if (root.videoMode)
                root.daemon.refreshAudioDevices();
        }
    }

    onVideoModeChanged: {
        if (root.videoMode && root.daemon)
            root.daemon.refreshAudioDevices();
    }

    component ExpressiveTile: Rectangle {
        id: tile
        required property var modelData
        property int columns: 4
        property real tileHeight: 74
        property bool highlighted: false
        property bool showPin: true
        property string rightClickAction: "copy"

        signal triggered(string action)

        readonly property bool canShowPin: showPin && rightClickAction !== "float"
        readonly property bool hovered: tileArea.containsMouse || pinMouse.containsMouse
        readonly property bool pressed: tileArea.pressed

        width: (parent.width - parent.spacing * (columns - 1)) / columns
        height: tileHeight

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
            spacing: 4

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: tile.hovered || tile.highlighted ? M3E.tileIconPillActiveWidth : M3E.tileIconPillWidth
                height: M3E.tileIconPillHeight
                radius: M3E.iconPillRadius(tile.pressed, tile.hovered, height)
                color: tile.highlighted || tile.hovered ? Theme.primary : Theme.surfaceContainerHighest

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
                        duration: M3E.effectsFastMs
                    }
                }

                DankIcon {
                    anchors.centerIn: parent
                    name: tile.modelData.icon
                    size: Theme.iconSize - 4
                    color: tile.highlighted || tile.hovered ? Theme.onPrimary : Theme.surfaceText
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
            id: tileArea
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            cursorShape: Qt.PointingHandCursor
            onPressed: mouse => tileRipple.trigger(mouse.x, mouse.y)
            onClicked: mouse => tile.triggered(mouse.button === Qt.RightButton ? tile.rightClickAction : "edit")
        }

        Rectangle {
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.margins: 4
            width: 22
            height: 22
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

            DankIcon {
                anchors.centerIn: parent
                name: "keep"
                size: 12
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

    component ConnectedIconButton: Rectangle {
        id: cBtn
        property string iconName: ""
        property bool active: false
        property bool isFirst: false
        property bool isLast: false
        signal clicked

        readonly property real pillR: height / 2
        readonly property real seamR: M3E.innerR
        readonly property real pressR: M3E.pressRadiusXXS

        width: 34
        height: 36
        scale: btnMouse.pressed ? M3E.iconBtnPressScale : 1.0
        color: active
            ? Theme.primaryContainer
            : (btnMouse.containsMouse ? Theme.secondaryContainer : Theme.surfaceContainerHigh)

        topLeftRadius: btnMouse.pressed ? pressR : (btnMouse.containsMouse || active || isFirst ? pillR : seamR)
        bottomLeftRadius: btnMouse.pressed ? pressR : (btnMouse.containsMouse || active || isFirst ? pillR : seamR)
        topRightRadius: btnMouse.pressed ? pressR : (btnMouse.containsMouse || active || isLast ? pillR : seamR)
        bottomRightRadius: btnMouse.pressed ? pressR : (btnMouse.containsMouse || active || isLast ? pillR : seamR)

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
            color: cBtn.active
                ? Theme.onPrimaryContainer
                : (btnMouse.containsMouse ? Theme.onSecondaryContainer : Theme.surfaceVariantText)
        }

        MouseArea {
            id: btnMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: cBtn.clicked()
        }
    }

    Column {
        id: contentColumn
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: Theme.spacingXS
        anchors.rightMargin: Theme.spacingXS
        spacing: Theme.spacingS

        // Top Bar (36px): Connected Segmented Switcher + Connected Utility Group
        Item {
            width: parent.width
            height: 36

            Row {
                id: modeSwitcher
                anchors.left: parent.left
                anchors.right: utilityGroup.left
                anchors.rightMargin: Theme.spacingS
                anchors.verticalCenter: parent.verticalCenter
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
                        id: seg
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
                            : (segArea.containsMouse ? Theme.secondaryContainer : Theme.surfaceContainerHigh)

                        topLeftRadius: segArea.pressed ? pressR : (selected || modelData.isFirst ? pillR : seamR)
                        bottomLeftRadius: segArea.pressed ? pressR : (selected || modelData.isFirst ? pillR : seamR)
                        topRightRadius: segArea.pressed ? pressR : (selected || !modelData.isFirst ? pillR : seamR)
                        bottomRightRadius: segArea.pressed ? pressR : (selected || !modelData.isFirst ? pillR : seamR)

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
                                color: seg.selected ? seg.activeFg : (segArea.containsMouse ? Theme.onSecondaryContainer : Theme.surfaceVariantText)
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            StyledText {
                                visible: seg.selected
                                width: Math.min(implicitWidth, Math.max(0, seg.width - Theme.iconSizeSmall - 24))
                                text: seg.modelData.label
                                font.pixelSize: Theme.fontSizeSmall
                                font.weight: Font.Bold
                                color: seg.activeFg
                                elide: Text.ElideRight
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        MouseArea {
                            id: segArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.widget.setWidgetMode(seg.modelData.mode)
                        }
                    }
                }
            }

            Row {
                id: utilityGroup
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: root.groupGap

                ConnectedIconButton {
                    isFirst: true
                    iconName: "open_in_new"
                    onClicked: {
                        root.daemon?.closeControlCenter();
                        root.daemon?.openFolder(root.videoMode ? "video" : "photo");
                    }
                }

                ConnectedIconButton {
                    iconName: "history"
                    onClicked: root.daemon?.showHistoryCarousel()
                }

                ConnectedIconButton {
                    readonly property bool hiding: root.daemon ? root.daemon.hideControlCenter : true
                    iconName: hiding ? "visibility_off" : "visibility"
                    active: !hiding
                    onClicked: root.daemon?.toggleHideControlCenter()
                }

                ConnectedIconButton {
                    isLast: true
                    iconName: "settings"
                    onClicked: PopoutService.openSettingsWithTab("plugins")
                }
            }
        }

        // Fixed-Height Body Container (204px) with M3E Spatial Crossfade & Slide
        Item {
            width: parent.width
            height: 204

            // PHOTO VIEW
            Column {
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
                            tileHeight: 72
                            highlighted: modelData.value === "region"
                            rightClickAction: root.menuRightClickAction
                            onTriggered: action => {
                                if (root.daemon)
                                    root.daemon.capture(modelData.value, action, "", true);
                            }
                        }
                    }
                }

                // Output Pill Strip (44px)
                Rectangle {
                    width: parent.width
                    height: 44
                    radius: height / 2
                    color: Theme.surfaceContainerHigh

                    Row {
                        id: ccOutputLabel
                        anchors.left: parent.left
                        anchors.leftMargin: Theme.spacingM
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Theme.spacingXS

                        DankIcon {
                            name: "display_settings"
                            size: 15
                            color: Theme.primary
                            anchors.verticalCenter: parent.verticalCenter
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
                        anchors.left: ccOutputLabel.right
                        anchors.leftMargin: Theme.spacingS
                        anchors.right: parent.right
                        anchors.rightMargin: Theme.spacingS
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        contentWidth: ccOutputsRow.implicitWidth
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds

                        Row {
                            id: ccOutputsRow
                            height: parent.height
                            spacing: 6

                            Repeater {
                                model: root.daemon?.outputs ?? []

                                delegate: Rectangle {
                                    id: ccChip
                                    required property var modelData
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: ccChipRow.implicitWidth + Theme.spacingM * 2
                                    height: 30
                                    radius: ccChipMouse.pressed
                                        ? (Theme.cornerRadiusXS ?? 6)
                                        : (ccChipMouse.containsMouse ? (Theme.cornerRadiusM ?? 10) : height / 2)
                                    color: ccChipMouse.containsMouse ? Theme.primaryContainer : Theme.surfaceContainerHighest

                                    Behavior on radius {
                                        NumberAnimation {
                                            duration: root.spatialFastMs
                                            easing.type: Easing.BezierSpline
                                            easing.bezierCurve: root.curveFastSpatial
                                        }
                                    }

                                    Row {
                                        id: ccChipRow
                                        anchors.centerIn: parent
                                        spacing: 5

                                        DankIcon {
                                            name: "monitor"
                                            size: 13
                                            color: ccChipMouse.containsMouse ? Theme.onPrimaryContainer : Theme.primary
                                            anchors.verticalCenter: parent.verticalCenter
                                        }

                                        StyledText {
                                            text: ccChip.modelData.name + " · " + ccChip.modelData.width + "×" + ccChip.modelData.height
                                            font.pixelSize: Theme.fontSizeSmall
                                            font.weight: Font.Medium
                                            color: ccChipMouse.containsMouse ? Theme.onPrimaryContainer : Theme.surfaceText
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                    }

                                    MouseArea {
                                        id: ccChipMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: mouse => {
                                            if (root.daemon)
                                                root.daemon.capture("output", mouse.button === Qt.RightButton ? root.menuRightClickAction : "edit", ccChip.modelData.name, true);
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // VIDEO VIEW
            Item {
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
                                tileHeight: 80
                                highlighted: modelData.value === "region"
                                showPin: false
                                onTriggered: {
                                    if (root.daemon)
                                        root.daemon.record(modelData.value, "", true);
                                }
                            }
                        }
                    }

                    // M3E Grouped Stack: Side-by-Side Audio Row + Format Footer
                    Column {
                        width: parent.width
                        spacing: root.groupGap

                        // Top Connected Row: Mic + System Audio (68px)
                        Row {
                            width: parent.width
                            height: 68
                            spacing: root.groupGap

                            readonly property real halfW: (width - spacing) / 2

                            // Mic Toggle Card
                            Rectangle {
                                id: ccMicCard
                                readonly property bool on: root.recorder?.recordMic ?? false
                                width: parent.halfW
                                height: parent.height
                                color: on ? Theme.primaryContainer : (ccMicArea.containsMouse ? Theme.secondaryContainer : Theme.surfaceContainerHigh)
                                topLeftRadius: root.outerR
                                topRightRadius: root.innerR
                                bottomLeftRadius: root.innerR
                                bottomRightRadius: root.innerR

                                Row {
                                    anchors.left: parent.left
                                    anchors.leftMargin: Theme.spacingM
                                    anchors.right: parent.right
                                    anchors.rightMargin: Theme.spacingS
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: Theme.spacingS

                                    Rectangle {
                                        width: 34
                                        height: 34
                                        radius: ccMicCard.on ? (Theme.cornerRadiusM ?? 10) : height / 2
                                        color: ccMicCard.on ? Theme.primary : Theme.surfaceContainerHighest
                                        anchors.verticalCenter: parent.verticalCenter

                                        DankIcon {
                                            anchors.centerIn: parent
                                            name: ccMicCard.on ? "mic" : "mic_off"
                                            size: Theme.iconSizeSmall
                                            color: ccMicCard.on ? Theme.onPrimary : Theme.surfaceVariantText
                                        }
                                    }

                                    Column {
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 2

                                        StyledText {
                                            text: I18n.trFor("quickCapture", "Microphone")
                                            font.pixelSize: Theme.fontSizeSmall
                                            font.weight: Font.Bold
                                            color: ccMicCard.on ? Theme.onPrimaryContainer : Theme.surfaceText
                                        }

                                        StyledText {
                                            text: ccMicCard.on ? I18n.trFor("quickCapture", "On") : I18n.trFor("quickCapture", "Off")
                                            font.pixelSize: Theme.fontSizeSmall
                                            color: ccMicCard.on ? Theme.onPrimaryContainer : Theme.surfaceVariantText
                                        }
                                    }
                                }

                                MouseArea {
                                    id: ccMicArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.daemon?.savePluginData("recordMic", !ccMicCard.on)
                                }
                            }

                            // System Audio Toggle Card
                            Rectangle {
                                id: ccAudioCard
                                readonly property bool on: root.recorder?.recordAudio ?? false
                                width: parent.halfW
                                height: parent.height
                                color: on ? Theme.primaryContainer : (ccAudioArea.containsMouse ? Theme.secondaryContainer : Theme.surfaceContainerHigh)
                                topLeftRadius: root.innerR
                                topRightRadius: root.outerR
                                bottomLeftRadius: root.innerR
                                bottomRightRadius: root.innerR

                                Row {
                                    anchors.left: parent.left
                                    anchors.leftMargin: Theme.spacingM
                                    anchors.right: parent.right
                                    anchors.rightMargin: Theme.spacingS
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: Theme.spacingS

                                    Rectangle {
                                        width: 34
                                        height: 34
                                        radius: ccAudioCard.on ? (Theme.cornerRadiusM ?? 10) : height / 2
                                        color: ccAudioCard.on ? Theme.primary : Theme.surfaceContainerHighest
                                        anchors.verticalCenter: parent.verticalCenter

                                        DankIcon {
                                            anchors.centerIn: parent
                                            name: ccAudioCard.on ? "volume_up" : "volume_off"
                                            size: Theme.iconSizeSmall
                                            color: ccAudioCard.on ? Theme.onPrimary : Theme.surfaceVariantText
                                        }
                                    }

                                    Column {
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 2

                                        StyledText {
                                            text: I18n.trFor("quickCapture", "Audio")
                                            font.pixelSize: Theme.fontSizeSmall
                                            font.weight: Font.Bold
                                            color: ccAudioCard.on ? Theme.onPrimaryContainer : Theme.surfaceText
                                        }

                                        StyledText {
                                            text: ccAudioCard.on ? I18n.trFor("quickCapture", "On") : I18n.trFor("quickCapture", "Off")
                                            font.pixelSize: Theme.fontSizeSmall
                                            color: ccAudioCard.on ? Theme.onPrimaryContainer : Theme.surfaceVariantText
                                        }
                                    }
                                }

                                MouseArea {
                                    id: ccAudioArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.daemon?.savePluginData("recordSystemAudio", !ccAudioCard.on)
                                }
                            }
                        }

                        // Bottom Format Strip (44px)
                        Rectangle {
                            width: parent.width
                            height: 44
                            color: Theme.surfaceContainerHigh
                            topLeftRadius: root.innerR
                            topRightRadius: root.innerR
                            bottomLeftRadius: root.outerR
                            bottomRightRadius: root.outerR

                            Row {
                                anchors.left: parent.left
                                anchors.leftMargin: Theme.spacingM
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: Theme.spacingS

                                DankIcon {
                                    name: "movie"
                                    size: Theme.iconSizeSmall
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
                                width: ccFmtText.implicitWidth + Theme.spacingM * 2
                                height: 26
                                radius: height / 2
                                color: Theme.secondaryContainer

                                StyledText {
                                    id: ccFmtText
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

                // ACTIVE RECORDING STATE (204px M3E Hero Card)
                Rectangle {
                    anchors.fill: parent
                    radius: root.outerR
                    color: root.widget.isPaused
                        ? Theme.withAlpha(Theme.warning, 0.14)
                        : Theme.errorContainer
                    visible: root.isRecording

                    Column {
                        anchors.centerIn: parent
                        spacing: Theme.spacingM

                        Row {
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: Theme.spacingS

                            RecordingDot {
                                dotSize: 10
                                paused: root.widget.isPaused
                                blink: root.isRecording && root.widget.blinkRecordDot
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            StyledText {
                                text: root.widget.isPaused
                                    ? I18n.trFor("quickCapture", "Recording Paused")
                                    : I18n.trFor("quickCapture", "Recording...")
                                font.pixelSize: Theme.fontSizeSmall
                                font.weight: Font.Bold
                                color: root.widget.isPaused ? Theme.warning : Theme.error
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Rectangle {
                                height: 22
                                width: activeFmtBadge.implicitWidth + Theme.spacingM * 2
                                radius: height / 2
                                color: Theme.surfaceContainerHighest
                                anchors.verticalCenter: parent.verticalCenter

                                StyledText {
                                    id: activeFmtBadge
                                    anchors.centerIn: parent
                                    text: root.recordingFormatText
                                    font.pixelSize: Theme.fontSizeSmall
                                    font.weight: Font.Bold
                                    color: Theme.surfaceText
                                }
                            }
                        }

                        StyledText {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: root.widget.durationText
                            font.pixelSize: 36
                            font.weight: Font.Bold
                            font.features: {
                                "tnum": 1
                            }
                            color: root.widget.isPaused ? Theme.warning : Theme.error
                        }

                        RecordingTransport {
                            anchors.horizontalCenter: parent.horizontalCenter
                            recorder: root.widget.recorder
                            buttonSize: 38
                            iconSize: Theme.iconSize
                            filled: true
                        }
                    }
                }
            }
        }
    }
}
