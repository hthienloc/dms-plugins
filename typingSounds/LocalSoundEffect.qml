import QtQuick
import QtMultimedia

// In-process fallback, loaded only when the sound helper cannot run.
Item {
    property alias source: player.source
    property alias volume: player.volume

    function play() {
        player.play();
    }

    SoundEffect {
        id: player
    }

    Component.onDestruction: player.stop()
}
