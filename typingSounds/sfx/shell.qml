// Out-of-process sound player, started by SfxClient as `quickshell -p <this dir>`.
// Reads "load\t<path>" and "play\t<volume>\t<path>" lines from the Unix socket
// in $DMS_SFX_SOCKET. Keeping QtMultimedia here instead of in the shell means a
// crash in its PipeWire backend (e.g. when the output device is unplugged
// during playback) only restarts this helper.
import QtQuick
import QtMultimedia
import Quickshell
import Quickshell.Io

ShellRoot {
    id: root

    property var effects: ({})

    function effect(path) {
        let sfx = root.effects[path];
        if (!sfx) {
            sfx = sfxComponent.createObject(root, {
                "source": "file://" + path
            });
            root.effects[path] = sfx;
        }
        return sfx;
    }

    function handle(line) {
        const fields = line.split("\t");
        if (fields[0] === "load" && fields.length >= 2) {
            root.effect(fields.slice(1).join("\t"));
        } else if (fields[0] === "play" && fields.length >= 3) {
            const sfx = root.effect(fields.slice(2).join("\t"));
            sfx.volume = Math.max(0, Math.min(1, parseFloat(fields[1]) || 0));
            if (sfx.status === SoundEffect.Ready)
                sfx.play();
            else
                sfx.pending = true;
        }
    }

    Component {
        id: sfxComponent

        SoundEffect {
            property bool pending: false

            onStatusChanged: {
                if (status === SoundEffect.Ready && pending) {
                    pending = false;
                    play();
                }
            }
        }
    }

    SocketServer {
        active: true
        path: Quickshell.env("DMS_SFX_SOCKET") || ""
        handler: Socket {
            parser: SplitParser {
                onRead: line => root.handle(line)
            }
        }
    }
}
