import QtQuick
import Quickshell
import qs.Common
import qs.Services
import qs.DCommon.Widgets
import qs.Modules.Plugins
import qs.Modules.DDash

DashCardComponent {
    id: root

    readonly property var daemon: PluginService.pluginDaemonInstances[root.pluginId] ?? null
    readonly property var recorder: daemon?.recordingController ?? null
    readonly property bool isRecording: daemon?.isRecording ?? false
    readonly property bool isPaused: recorder?.isPaused ?? false
    readonly property string durationText: recorder ? recorder.formatDuration(recorder.recordingSeconds) : "00:00"

    readonly property bool wide: width >= DashMetrics.gridRowUnit * 2
    readonly property bool extraWide: width >= DashMetrics.gridRowUnit * 3
    readonly property bool tall: height >= DashMetrics.gridRowUnit * 2

    // Responsive button count based on available content width
    readonly property int buttonCount: {
        const avail = width - pad * 2;
        if (avail < 160)
            return 2;
        if (avail < 260)
            return 4;
        if (avail < 340)
            return 5;
        return 6;
    }

    opensTab: false
    clickable: false
    focusTarget: regionButton
    tone: options.tone ?? (root.isRecording ? "error" : "")
    title: ""

    function runAfterDashClosed(action) {
        const dash = PopoutService.dankDashPopout;
        if (!dash || (!dash.dashVisible && !dash.shouldBeVisible && !dash.isClosing)) {
            action();
            return;
        }
        dash.dashVisible = false;
        if (typeof dash.instantClose === "function") {
            dash.instantClose();
        } else {
            PopoutService.closeDankDash();
        }
        Qt.callLater(action);
    }

    // Active Recording View
    Item {
        anchors.fill: parent
        visible: root.isRecording

        Row {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.spacingS

            Rectangle {
                width: 14
                height: 14
                radius: 7
                color: Theme.error
                anchors.verticalCenter: parent.verticalCenter

                SequentialAnimation on opacity {
                    running: root.isRecording && root.live
                    loops: Animation.Infinite
                    NumberAnimation {
                        from: 1.0
                        to: 0.2
                        duration: 600
                        easing.type: Easing.InOutQuad
                    }
                    NumberAnimation {
                        from: 0.2
                        to: 1.0
                        duration: 600
                        easing.type: Easing.InOutQuad
                    }
                }
            }

            StyledText {
                text: root.durationText
                font.pixelSize: Theme.fontSizeXLarge
                font.weight: Theme.fontWeightBold
                font.family: Theme.monoFontFamily
                color: root.contentColor
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.spacingS

            readonly property real btnHeight: Math.min(parent.height, 52)
            readonly property real btnWidth: Math.max(44, Math.min(56, (parent.width - 120 - spacing * 2) / 3))

            DIconButton {
                iconName: root.isPaused ? "play_arrow" : "pause"
                size: "m"
                variant: "tonal"
                width: parent.btnWidth
                height: parent.btnHeight
                buttonSize: parent.btnHeight
                iconSize: 24
                tooltipText: root.isPaused ? I18n.trFor("quickCapture", "Resume") : I18n.trFor("quickCapture", "Pause")
                onClicked: {
                    if (root.isPaused)
                        root.recorder?.resumeRecording();
                    else
                        root.recorder?.pauseRecording();
                }
            }

            DIconButton {
                iconName: "stop"
                size: "m"
                variant: "filled"
                containerColor: Theme.error
                contentColor: Theme.onError
                width: parent.btnWidth
                height: parent.btnHeight
                buttonSize: parent.btnHeight
                iconSize: 24
                tooltipText: I18n.trFor("quickCapture", "Stop Recording")
                onClicked: root.recorder?.stopRecording()
            }

            DIconButton {
                iconName: "close"
                size: "m"
                variant: "standard"
                width: parent.btnWidth
                height: parent.btnHeight
                buttonSize: parent.btnHeight
                iconSize: 24
                tooltipText: I18n.trFor("quickCapture", "Cancel")
                onClicked: root.recorder?.cancelRecording()
            }
        }
    }

    // Idle Mode: Standard 1-Row View (Auto-scales to fill available card space)
    Item {
        anchors.fill: parent
        visible: !root.isRecording && !root.tall

        Row {
            id: buttonRow
            anchors.fill: parent
            spacing: Theme.spacingS

            readonly property int count: root.buttonCount
            readonly property real btnWidth: Math.floor((width - spacing * (count - 1)) / count)
            readonly property real btnHeight: Math.min(height, 56)

            DIconButton {
                id: regionButton
                iconName: "crop_free"
                size: "m"
                variant: "filled"
                containerColor: root.accentColor
                contentColor: root.onAccentColor
                width: buttonRow.btnWidth
                height: buttonRow.btnHeight
                buttonSize: buttonRow.btnHeight
                iconSize: 24
                anchors.verticalCenter: parent.verticalCenter
                tooltipText: I18n.trFor("quickCapture", "Capture Region")
                onClicked: root.runAfterDashClosed(() => root.daemon?.capture("region", "edit", "", false))
            }

            DIconButton {
                id: windowButton
                visible: buttonRow.count >= 3
                iconName: "crop_square"
                size: "m"
                variant: "tonal"
                width: buttonRow.btnWidth
                height: buttonRow.btnHeight
                buttonSize: buttonRow.btnHeight
                iconSize: 24
                anchors.verticalCenter: parent.verticalCenter
                tooltipText: I18n.trFor("quickCapture", "Capture Window")
                onClicked: root.runAfterDashClosed(() => root.daemon?.capture("window", "edit", "", false))
            }

            DIconButton {
                id: fullButton
                visible: buttonRow.count >= 4
                iconName: "fullscreen"
                size: "m"
                variant: "tonal"
                width: buttonRow.btnWidth
                height: buttonRow.btnHeight
                buttonSize: buttonRow.btnHeight
                iconSize: 24
                anchors.verticalCenter: parent.verticalCenter
                tooltipText: I18n.trFor("quickCapture", "Capture Fullscreen")
                onClicked: root.runAfterDashClosed(() => root.daemon?.capture("full", "edit", "", false))
            }

            DIconButton {
                id: lastButton
                visible: buttonRow.count >= 5
                iconName: "restart_alt"
                size: "m"
                variant: "tonal"
                width: buttonRow.btnWidth
                height: buttonRow.btnHeight
                buttonSize: buttonRow.btnHeight
                iconSize: 24
                anchors.verticalCenter: parent.verticalCenter
                tooltipText: I18n.trFor("quickCapture", "Last Region")
                onClicked: root.runAfterDashClosed(() => root.daemon?.capture("last", "edit", "", false))
            }

            DIconButton {
                id: recordButton
                iconName: "videocam"
                size: "m"
                variant: "tonal"
                width: buttonRow.btnWidth
                height: buttonRow.btnHeight
                buttonSize: buttonRow.btnHeight
                iconSize: 24
                anchors.verticalCenter: parent.verticalCenter
                tooltipText: I18n.trFor("quickCapture", "Record Region")
                onClicked: root.runAfterDashClosed(() => root.daemon?.record("region", "", false))
            }

            DIconButton {
                id: moreButton
                visible: buttonRow.count >= 6
                iconName: "more_horiz"
                size: "m"
                variant: "standard"
                width: buttonRow.btnWidth
                height: buttonRow.btnHeight
                buttonSize: buttonRow.btnHeight
                iconSize: 24
                anchors.verticalCenter: parent.verticalCenter
                tooltipText: I18n.trFor("quickCapture", "More Options")
                onClicked: root.runAfterDashClosed(() => root.daemon?.openMenu())
            }
        }
    }

    // Idle Mode: Multi-Row View (Tall mode: h >= 2)
    Column {
        anchors.fill: parent
        visible: !root.isRecording && root.tall
        spacing: Theme.spacingS

        readonly property real rowHeight: Math.floor((height - spacing) / 2)
        readonly property real btnHeight: Math.min(rowHeight, 64)

        Row {
            id: tallRow1
            width: parent.width
            height: parent.rowHeight
            spacing: Theme.spacingS

            readonly property real btnWidth: Math.floor((width - spacing * 3) / 4)

            DIconButton {
                iconName: "crop_free"
                size: "m"
                variant: "filled"
                containerColor: root.accentColor
                contentColor: root.onAccentColor
                width: tallRow1.btnWidth
                height: parent.parent.btnHeight
                buttonSize: parent.parent.btnHeight
                iconSize: 26
                anchors.verticalCenter: parent.verticalCenter
                tooltipText: I18n.trFor("quickCapture", "Capture Region")
                onClicked: root.runAfterDashClosed(() => root.daemon?.capture("region", "edit", "", false))
            }

            DIconButton {
                iconName: "crop_square"
                size: "m"
                variant: "tonal"
                width: tallRow1.btnWidth
                height: parent.parent.btnHeight
                buttonSize: parent.parent.btnHeight
                iconSize: 26
                anchors.verticalCenter: parent.verticalCenter
                tooltipText: I18n.trFor("quickCapture", "Capture Window")
                onClicked: root.runAfterDashClosed(() => root.daemon?.capture("window", "edit", "", false))
            }

            DIconButton {
                iconName: "fullscreen"
                size: "m"
                variant: "tonal"
                width: tallRow1.btnWidth
                height: parent.parent.btnHeight
                buttonSize: parent.parent.btnHeight
                iconSize: 26
                anchors.verticalCenter: parent.verticalCenter
                tooltipText: I18n.trFor("quickCapture", "Capture Fullscreen")
                onClicked: root.runAfterDashClosed(() => root.daemon?.capture("full", "edit", "", false))
            }

            DIconButton {
                iconName: "restart_alt"
                size: "m"
                variant: "tonal"
                width: tallRow1.btnWidth
                height: parent.parent.btnHeight
                buttonSize: parent.parent.btnHeight
                iconSize: 26
                anchors.verticalCenter: parent.verticalCenter
                tooltipText: I18n.trFor("quickCapture", "Last Region")
                onClicked: root.runAfterDashClosed(() => root.daemon?.capture("last", "edit", "", false))
            }
        }

        Row {
            id: tallRow2
            width: parent.width
            height: parent.rowHeight
            spacing: Theme.spacingS

            readonly property real btnWidth: Math.floor((width - spacing * 3) / 4)

            DIconButton {
                iconName: "videocam"
                size: "m"
                variant: "tonal"
                width: tallRow2.btnWidth
                height: parent.parent.btnHeight
                buttonSize: parent.parent.btnHeight
                iconSize: 26
                anchors.verticalCenter: parent.verticalCenter
                tooltipText: I18n.trFor("quickCapture", "Record Region")
                onClicked: root.runAfterDashClosed(() => root.daemon?.record("region", "", false))
            }

            DIconButton {
                iconName: "desktop_windows"
                size: "m"
                variant: "tonal"
                width: tallRow2.btnWidth
                height: parent.parent.btnHeight
                buttonSize: parent.parent.btnHeight
                iconSize: 26
                anchors.verticalCenter: parent.verticalCenter
                tooltipText: I18n.trFor("quickCapture", "Record Screen")
                onClicked: root.runAfterDashClosed(() => root.daemon?.record("screen", "", false))
            }

            DIconButton {
                iconName: "content_paste"
                size: "m"
                variant: "tonal"
                width: tallRow2.btnWidth
                height: parent.parent.btnHeight
                buttonSize: parent.parent.btnHeight
                iconSize: 26
                anchors.verticalCenter: parent.verticalCenter
                tooltipText: I18n.trFor("quickCapture", "From Clipboard")
                onClicked: root.runAfterDashClosed(() => root.daemon?.fromClipboard("edit"))
            }

            DIconButton {
                iconName: "more_horiz"
                size: "m"
                variant: "standard"
                width: tallRow2.btnWidth
                height: parent.parent.btnHeight
                buttonSize: parent.parent.btnHeight
                iconSize: 26
                anchors.verticalCenter: parent.verticalCenter
                tooltipText: I18n.trFor("quickCapture", "More Options")
                onClicked: root.runAfterDashClosed(() => root.daemon?.openMenu())
            }
        }
    }
}
