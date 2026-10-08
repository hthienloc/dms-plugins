import QtQuick
import Quickshell
import Quickshell.Io

// Plays sound effects in a separate Quickshell process (sfx/shell.qml).
// QtMultimedia's PipeWire backend can crash its process when the output
// device disappears during playback (e.g. unplugging a USB headset). In a
// helper that only costs a helper restart instead of taking the shell down.
// The helper starts on the first load()/play(). If it cannot run, `unavailable`
// turns true and callers fall back to in-process playback.
Item {
    id: root

    required property string name
    property url helperDir: Qt.resolvedUrl("sfx")
    readonly property string socketPath: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/dms-sfx-" + root.name + ".sock"
    readonly property bool connected: socketLoader.item ? socketLoader.item.connected : false
    property bool unavailable: false

    property bool _started: false
    property int _failures: 0
    property bool _socketOn: true
    property var _loaded: []

    function _path(p) {
        return p.toString().replace(/^file:\/\//, "");
    }

    function _send(line) {
        if (!root.connected)
            return;
        socketLoader.item.write(line + "\n");
        socketLoader.item.flush();
    }

    function _ensureStarted() {
        if (root._started || root.unavailable)
            return;
        root._started = true;
        helper.running = true;
    }

    function load(p) {
        root._ensureStarted();
        const path = root._path(p);
        if (root._loaded.indexOf(path) === -1)
            root._loaded.push(path);
        root._send("load\t" + path);
    }

    function play(p, volume) {
        root._ensureStarted();
        root._send("play\t" + volume + "\t" + root._path(p));
    }

    Process {
        id: helper

        command: ["quickshell", "-p", root._path(root.helperDir)]
        environment: ({
                "DMS_SFX_SOCKET": root.socketPath,
                "QT_QPA_PLATFORM": "offscreen",
                "PIPEWIRE_LATENCY": "1024/48000",
                "PIPEWIRE_PROPS": "{ node.latency = 1024/48000 }"
            })
        onExited: (exitCode, exitStatus) => {
            root._failures += 1;
            if (root._failures >= 3) {
                console.warn("[SfxClient] sound helper keeps exiting, falling back to in-process playback");
                root.unavailable = true;
            } else {
                restartTimer.restart();
            }
        }
    }

    Timer {
        id: restartTimer

        interval: 1000
        onTriggered: helper.running = true
    }

    Loader {
        id: socketLoader

        active: root._started && !root.unavailable && root._socketOn
        sourceComponent: Socket {
            path: root.socketPath
            connected: true
            onConnectedChanged: {
                if (connected) {
                    root._failures = 0;
                    for (const p of root._loaded)
                        write("load\t" + p + "\n");
                    flush();
                } else if (root._socketOn) {
                    retryTimer.restart();
                }
            }
            onError: retryTimer.restart()
        }
    }

    Timer {
        id: retryTimer

        interval: 500
        onTriggered: {
            if (root.unavailable || root.connected)
                return;
            root._socketOn = false;
            Qt.callLater(() => root._socketOn = true);
        }
    }
}
