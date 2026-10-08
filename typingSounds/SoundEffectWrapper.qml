import QtQuick

// One key sound. Played through the out-of-process helper (SfxClient);
// LocalSoundEffect (QtMultimedia inside the shell) is only loaded as fallback.
Item {
    id: root

    property string keycode: ""
    property var client: null
    property string sourcePath: ""
    property real volumeValue: 1.0

    readonly property bool _useHelper: root.client !== null && !root.client.unavailable

    function _preload() {
        if (root._useHelper && root.sourcePath !== "")
            root.client.load(root.sourcePath);
    }

    function play() {
        if (root._useHelper)
            root.client.play(root.sourcePath, root.volumeValue);
        else if (local.item)
            local.item.play();
    }

    onSourcePathChanged: root._preload()
    Component.onCompleted: root._preload()

    Loader {
        id: local

        active: !root._useHelper && root.sourcePath !== ""
        source: "LocalSoundEffect.qml"
        onLoaded: {
            item.source = Qt.binding(() => root.sourcePath);
            item.volume = Qt.binding(() => root.volumeValue);
        }
    }
}
