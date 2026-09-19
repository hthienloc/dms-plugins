import QtQuick
import qs.Common

Rectangle {
    id: root

    property bool opened: false
    property bool allowOpen: true
    property int closeInterval: 200
    property real closedScale: 0.9

    signal closed()
    default property alias contentData: content.data

    color: Theme.surfaceContainer
    border.color: Theme.withAlpha(Theme.outline, 0.15)
    border.width: 1
    radius: Theme.cornerRadius
    z: 10001
    visible: opacity > 0
    opacity: 0
    scale: root.closedScale

    onAllowOpenChanged: {
        if (!allowOpen) root.close();
    }

    states: [
        State {
            name: "visible"
            when: root.opened
            PropertyChanges { target: root; opacity: 1.0; scale: 1.0 }
        }
    ]

    transitions: [
        Transition {
            NumberAnimation { properties: "opacity,scale"; duration: 120; easing.type: Easing.OutQuad }
        }
    ]

    function open() {
        if (!root.allowOpen) return;
        closeTimer.stop();
        root.opened = true;
    }

    function close() {
        root.opened = false;
        root.closed();
    }

    function startCloseTimer() {
        closeTimer.start();
    }

    function stopCloseTimer() {
        closeTimer.stop();
    }

    Timer {
        id: closeTimer
        interval: root.closeInterval
        onTriggered: root.close()
    }

    Item {
        id: content
        anchors.fill: parent
    }
}
