import QtQuick
import qs.Common

Rectangle {
    id: root

    property bool paused: false
    property bool blink: true
    property real dotSize: 8

    width: dotSize
    height: dotSize
    radius: dotSize / 2
    color: paused ? Theme.warning : Theme.error

    SequentialAnimation on opacity {
        // Item.visible stays true inside a hidden window; an endless animation there keeps every shell window repainting
        running: root.visible && (root.Window.window ? root.Window.window.visible : false) && !root.paused && root.blink
        loops: Animation.Infinite
        NumberAnimation {
            to: 0.35
            duration: 800
            easing.type: Easing.InOutSine
        }
        NumberAnimation {
            to: 1.0
            duration: 800
            easing.type: Easing.InOutSine
        }
        onRunningChanged: if (!running)
            root.opacity = 1.0
    }
}
