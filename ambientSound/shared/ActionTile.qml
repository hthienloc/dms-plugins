import QtQuick
import qs.Common
import qs.DCommon.Widgets

Rectangle {
    id: root

    property string iconName: ""
    property string title: ""
    property string subtitle: ""
    property bool active: false
    property color activeColor: Theme.primary
    property color activeContentColor: Theme.primaryText
    property color borderColor: "transparent"
    property real borderWidth: 0
    property color textColor: Theme.surfaceText
    property real titleFontSize: Theme.fontSizeSmall
    property real volumeProgress: 0.0 // from 0.0 to 1.0
    property real arcSize: 44
    property real iconSize: 22
    property real tileRadius: 16

    signal clicked()
    signal pressAndHold()
    signal scrollUp()
    signal scrollDown()

    radius: root.tileRadius
    color: root.active
        ? root.activeColor
        : (tileMouse.containsMouse ? Theme.surfaceContainerHighest : Theme.surfaceContainerHigh)
    border.color: borderColor
    border.width: borderWidth

    Behavior on color { ColorAnimation { duration: 150 } }

    onVolumeProgressChanged: arcCanvas.requestPaint()
    onActiveChanged: arcCanvas.requestPaint()
    onActiveColorChanged: arcCanvas.requestPaint()
    onActiveContentColorChanged: arcCanvas.requestPaint()

    Column {
        anchors.centerIn: parent
        spacing: Theme.spacingXS

        Item {
            id: arcContainer
            width: root.arcSize
            height: root.arcSize
            anchors.horizontalCenter: parent.horizontalCenter

            Canvas {
                id: arcCanvas
                anchors.fill: parent
                antialiasing: true

                onPaint: {
                    var ctx = getContext("2d");
                    ctx.reset();
                    ctx.clearRect(0, 0, width, height);

                    var cx = width / 2;
                    var cy = height / 2;
                    var radius = (Math.min(width, height) - 6) / 2;
                    var lw = Math.max(2.5, root.arcSize * 0.075);

                    var startAngle = Math.PI * 0.75; // 135 deg (bottom-left)
                    var endAngle = Math.PI * 2.25;   // 405 deg (bottom-right)
                    var span = Math.PI * 1.5;        // 270 deg

                    ctx.lineWidth = lw;
                    ctx.lineCap = "round";

                    // Background track
                    ctx.beginPath();
                    ctx.strokeStyle = root.active
                        ? Theme.withAlpha(root.activeContentColor, 0.25)
                        : Theme.withAlpha(Theme.surfaceVariantText, 0.22);
                    ctx.arc(cx, cy, radius, startAngle, endAngle, false);
                    ctx.stroke();

                    // Foreground progress arc
                    var progress = Math.max(0.0, Math.min(1.0, root.volumeProgress));
                    if (progress > 0) {
                        ctx.beginPath();
                        ctx.strokeStyle = root.active
                            ? root.activeContentColor
                            : Theme.withAlpha(Theme.surfaceVariantText, 0.75);
                        var progEnd = startAngle + (progress * span);
                        ctx.arc(cx, cy, radius, startAngle, progEnd, false);
                        ctx.stroke();
                    }
                }

                onWidthChanged: requestPaint()
                onHeightChanged: requestPaint()
            }

            DIcon {
                name: root.iconName
                size: root.iconSize
                anchors.centerIn: parent
                color: root.active ? root.activeContentColor : Theme.surfaceVariantText
            }
        }

        StyledText {
            text: root.title
            font.pixelSize: root.titleFontSize
            font.weight: Font.Medium
            color: root.active ? root.activeContentColor : Theme.surfaceVariantText
            anchors.horizontalCenter: parent.horizontalCenter
            elide: Text.ElideRight
            width: root.width - Theme.spacingS
            horizontalAlignment: Text.AlignHCenter
        }
    }

    MouseArea {
        id: tileMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
        onPressAndHold: root.pressAndHold()
        onWheel: (wheel) => {
            if (wheel.angleDelta.y > 0) root.scrollUp();
            else root.scrollDown();
        }
    }
}
