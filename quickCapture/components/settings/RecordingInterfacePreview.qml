import QtQuick
import qs.Common
import qs.DCommon.Widgets
import qs.Widgets
import "../bar"

StyledRect {
    id: root

    property string recordingStatusLocation: "auto"
    property bool showPillBorder: true
    property bool dimUnfocusedRecordingPill: false
    property bool showRecordingDot: true
    property bool blinkRecordDot: true
    property bool showRecordingTimer: true
    property bool showRecordingControls: true
    property bool showRegionBorder: true

    readonly property bool barStatusActive: recordingStatusLocation !== "floating"
    readonly property bool floatingActive: recordingStatusLocation === "floating" || recordingStatusLocation === "both"
    readonly property bool floatingFallback: recordingStatusLocation === "auto"
    readonly property bool barHasExpandedParts: showRecordingDot || showRecordingTimer || showRecordingControls
    readonly property bool barShowsExpanded: barStatusActive && barHasExpandedParts
    readonly property bool effectiveFloatingDot: showRecordingDot || (!showRecordingTimer && !showRecordingControls)

    width: parent ? parent.width : 0
    implicitHeight: previewCol.implicitHeight + Theme.spacingM * 2
    height: implicitHeight
    radius: Theme.cornerRadius / 2
    color: Theme.surfaceContainer
    clip: true

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop {
                position: 0.0
                color: Theme.surfaceContainerHighest
            }
            GradientStop {
                position: 1.0
                color: Theme.surfaceContainerLowest
            }
        }
    }

    // Region recording border indicator (matches RecordingRegionBorder.qml)
    Item {
        id: regionBorderPreview
        anchors.fill: parent
        anchors.margins: 4
        visible: root.showRegionBorder

        property real pulseValue: 0.15
        opacity: pulseValue

        SequentialAnimation on pulseValue {
            running: regionBorderPreview.visible && (regionBorderPreview.Window.window ? regionBorderPreview.Window.window.visible : false)
            loops: Animation.Infinite
            NumberAnimation {
                from: 0.15
                to: 0.6
                duration: 1500
                easing.type: Easing.InOutQuad
            }
            NumberAnimation {
                from: 0.6
                to: 0.15
                duration: 1500
                easing.type: Easing.InOutQuad
            }
        }

        Canvas {
            id: regionBorderCanvas
            anchors.fill: parent

            onPaint: {
                var ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);
                ctx.strokeStyle = Theme.primary;
                ctx.lineWidth = 2.5;
                ctx.setLineDash([6, 5]);

                var strokeOffset = 1.25;
                var bx = strokeOffset;
                var by = strokeOffset;
                var bw = width - (strokeOffset * 2);
                var bh = height - (strokeOffset * 2);
                var r = 8;

                if (bw < r * 2 || bh < r * 2) {
                    r = Math.max(0, Math.min(bw, bh) / 2);
                }

                ctx.beginPath();
                ctx.moveTo(bx + r, by);
                ctx.lineTo(bx + bw - r, by);
                ctx.quadraticCurveTo(bx + bw, by, bx + bw, by + r);
                ctx.lineTo(bx + bw, by + bh - r);
                ctx.quadraticCurveTo(bx + bw, by + bh, bx + bw - r, by + bh);
                ctx.lineTo(bx + r, by + bh);
                ctx.quadraticCurveTo(bx, by + bh, bx, by + bh - r);
                ctx.lineTo(bx, by + r);
                ctx.quadraticCurveTo(bx, by, bx + r, by);
                ctx.closePath();
                ctx.stroke();
            }

            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()
            onVisibleChanged: {
                if (visible)
                    requestPaint();
            }

            Connections {
                target: Theme
                function onPrimaryChanged() {
                    regionBorderCanvas.requestPaint();
                }
            }
        }
    }

    Column {
        id: previewCol
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Theme.spacingM
        spacing: Theme.spacingM

        // 1. DankBar Preview
        Column {
            width: parent.width
            spacing: Theme.spacingXS

            Row {
                width: parent.width
                spacing: Theme.spacingS

                StyledText {
                    text: I18n.trFor("quickCapture", "DankBar")
                    font.pixelSize: Theme.fontSizeSmall
                    font.weight: Font.Bold
                    color: Theme.surfaceVariantText
                }

                StyledText {
                    text: root.barStatusActive
                        ? I18n.trFor("quickCapture", "Active")
                        : I18n.trFor("quickCapture", "Icon only")
                    font.pixelSize: Theme.fontSizeSmall - 1
                    color: root.barStatusActive ? Theme.primary : Theme.surfaceVariantText
                }
            }

            Rectangle {
                width: parent.width
                height: 36
                radius: Theme.cornerRadius
                color: Theme.surfaceContainerHigh
                border.color: Theme.outlineVariant
                border.width: 1

                // Simulated left bar items
                Row {
                    anchors.left: parent.left
                    anchors.leftMargin: Theme.spacingM
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Theme.spacingS
                    opacity: 0.35

                    Rectangle {
                        width: 16
                        height: 8
                        radius: 4
                        color: Theme.surfaceVariantText
                    }
                    Rectangle {
                        width: 28
                        height: 8
                        radius: 4
                        color: Theme.surfaceVariantText
                    }
                }

                // Simulated QuickCapture DankBar pill
                Rectangle {
                    anchors.right: parent.right
                    anchors.rightMargin: Theme.spacingS
                    anchors.verticalCenter: parent.verticalCenter
                    height: 28
                    width: barPillRow.implicitWidth + Theme.spacingS * 2
                    radius: height / 2
                    color: Theme.withAlpha(Theme.surfaceContainerHighest, 0.85)
                    opacity: root.barStatusActive ? 1.0 : 0.7

                    Row {
                        id: barPillRow
                        anchors.centerIn: parent
                        spacing: Theme.spacingS

                        DIcon {
                            visible: !root.barShowsExpanded
                            name: "videocam"
                            size: Theme.iconSizeSmall
                            color: Theme.error
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        RecordingDot {
                            visible: root.barShowsExpanded && root.showRecordingDot
                            blink: root.blinkRecordDot
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        StyledText {
                            visible: root.barShowsExpanded && root.showRecordingTimer
                            text: "00:42"
                            color: Theme.surfaceText
                            font.pixelSize: Theme.fontSizeSmall
                            font.weight: Font.Medium
                            font.features: {
                                "tnum": 1
                            }
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        RecordingTransport {
                            visible: root.barShowsExpanded && root.showRecordingControls
                            recorder: null
                            buttonSize: 22
                            iconSize: 13
                            filled: true
                            showCancel: false
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }
            }
        }

        // 2. Floating Pill Preview
        Column {
            width: parent.width
            spacing: Theme.spacingXS

            Row {
                width: parent.width
                spacing: Theme.spacingS

                StyledText {
                    text: I18n.trFor("quickCapture", "Floating Pill")
                    font.pixelSize: Theme.fontSizeSmall
                    font.weight: Font.Bold
                    color: Theme.surfaceVariantText
                }

                StyledText {
                    text: root.floatingActive
                        ? I18n.trFor("quickCapture", "Active")
                        : (root.floatingFallback
                            ? I18n.trFor("quickCapture", "Fallback if no DankBar")
                            : I18n.trFor("quickCapture", "Hidden"))
                    font.pixelSize: Theme.fontSizeSmall - 1
                    color: root.floatingActive ? Theme.primary : Theme.surfaceVariantText
                }
            }

            Item {
                width: parent.width
                height: 44

                Rectangle {
                    id: floatingPillCard
                    anchors.centerIn: parent
                    width: floatingPillRow.implicitWidth + Theme.spacingM * 2
                    height: 36
                    radius: height / 2
                    color: Theme.withAlpha(Theme.surfaceContainer, Theme.popupTransparency)
                    border.color: Theme.outlineVariant
                    border.width: root.showPillBorder ? 1 : 0
                    opacity: root.floatingActive
                        ? ((!root.dimUnfocusedRecordingPill || floatingHover.hovered) ? 1.0 : 0.35)
                        : (root.floatingFallback ? ((!root.dimUnfocusedRecordingPill || floatingHover.hovered) ? 0.75 : 0.35) : 0.45)

                    Behavior on opacity {
                        NumberAnimation {
                            duration: Theme.shortDuration
                        }
                    }

                    HoverHandler {
                        id: floatingHover
                    }

                    Row {
                        id: floatingPillRow
                        anchors.centerIn: parent
                        spacing: Theme.spacingS

                        RecordingDot {
                            dotSize: 9
                            blink: root.blinkRecordDot
                            visible: root.effectiveFloatingDot
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        StyledText {
                            text: "00:42"
                            color: Theme.surfaceText
                            font.pixelSize: Theme.fontSizeMedium
                            font.weight: Font.Medium
                            font.features: {
                                "tnum": 1
                            }
                            visible: root.showRecordingTimer
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        RecordingTransport {
                            recorder: null
                            buttonSize: 24
                            iconSize: 14
                            filled: true
                            showCancel: true
                            visible: root.showRecordingControls
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }
            }
        }
    }
}
