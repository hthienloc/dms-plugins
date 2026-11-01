import QtQuick
import qs.Common
import qs.DCommon.Widgets
import "../core/Defaults.js" as Defaults

Item {
    id: root

    required property var widget
    property bool vertical: false
    readonly property bool isRecording: widget.isRecording
    readonly property bool isPaused: widget.isPaused
    readonly property string statusLocation: Defaults.get(widget.pluginData, "recordingStatusLocation")
    readonly property bool showRecordingStatus: root.isRecording && (root.statusLocation !== "floating")
    readonly property int effectiveIconSize: root.widget.iconSize > 0 ? root.widget.iconSize : Theme.iconSizeSmall
    property bool draggingOver: false

    width: implicitWidth
    height: implicitHeight
    implicitWidth: vertical ? Math.max(effectiveIconSize, layout.implicitWidth) : (showRecordingStatus ? layout.implicitWidth : effectiveIconSize)
    implicitHeight: vertical ? layout.implicitHeight : (root.widget.surfaceContext?.kind === "dock" ? root.effectiveIconSize : Theme.iconSize)
    anchors.verticalCenter: vertical ? undefined : parent.verticalCenter
    anchors.horizontalCenter: vertical ? parent.horizontalCenter : undefined

    Behavior on implicitWidth {
        enabled: !root.vertical
        NumberAnimation {
            duration: Theme.shortDuration
            easing.type: Theme.standardEasing
        }
    }

    Grid {
        id: layout
        anchors.centerIn: parent
        columns: root.vertical ? 1 : (root.showRecordingStatus ? 3 : 1)
        spacing: root.showRecordingStatus ? (root.vertical ? Theme.spacingXS : Theme.spacingS) : 0
        horizontalItemAlignment: Grid.AlignHCenter
        verticalItemAlignment: Grid.AlignVCenter
        scale: root.draggingOver ? 1.2 : 1.0
        Behavior on scale {
            NumberAnimation {
                duration: Theme.shortDuration
                easing.type: Easing.OutBack
            }
        }

        DIcon {
            visible: !root.showRecordingStatus
            width: visible ? root.effectiveIconSize : 0
            implicitWidth: visible ? root.effectiveIconSize : 0
            name: root.widget.isDownloading ? "download" : (root.widget.widgetMode === "video" || root.isRecording ? "videocam" : "screenshot_region")
            size: root.effectiveIconSize
            color: root.isRecording ? (root.isPaused ? Theme.warning : Theme.error) : (root.draggingOver || root.widget.isActive || root.widget.isDownloading ? Theme.primary : Theme.surfaceText)
        }

        RecordingDot {
            visible: root.showRecordingStatus
            paused: root.isPaused
            blink: root.widget.blinkRecordDot
        }

        StyledText {
            visible: root.showRecordingStatus
            text: root.vertical ? root.widget.durationText.split(":").join("\n") : root.widget.durationText
            color: root.isPaused ? Theme.warning : Theme.widgetTextColor
            font.pixelSize: Theme.barTextSize(root.widget.barThickness, root.widget.barConfig?.fontScale, root.widget.barConfig?.maximizeWidgetText)
            font.weight: Font.Medium
            font.features: {
                "tnum": 1
            }
            horizontalAlignment: Text.AlignHCenter
        }

        RecordingTransport {
            visible: root.showRecordingStatus
            recorder: root.widget.recorder
            vertical: root.vertical
            buttonSize: 24
            iconSize: 14
            filled: true
            showCancel: false
        }
    }

    DropArea {
        anchors.fill: parent
        onEntered: root.draggingOver = true
        onExited: root.draggingOver = false
        onDropped: drop => {
            root.draggingOver = false;
            root.widget.daemon?.handleDrop(drop);
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.MiddleButton
        cursorShape: Qt.PointingHandCursor
        visible: !root.isRecording
        onClicked: root.widget.runDefaultAction("middleClickAction")
    }
}
