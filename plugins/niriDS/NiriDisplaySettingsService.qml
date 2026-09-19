pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import qs.Common
import qs.Services
import qs.Modules.Plugins

Singleton {
    id: root

    property var displays: []
    property var rawOutputs: ({})
    property bool modalVisible: false
    property var modal: null
    property string _displaysJsonCache: ""

    readonly property bool hasExternal: {
        const raw = root.rawOutputs || {};
        return Object.keys(raw).some(n => n && !isInternalName(n));
    }

    // Tracks the running wl-mirror process so it can be killed on mode switch
    Process {
        id: wlMirrorProc
        running: false
    }

    function stopMirror() {
        if (wlMirrorProc.running) wlMirrorProc.running = false;
    }

    readonly property var internalPrefixes: ["edp", "lvds"]

    function isInternalName(name) {
        if (!name) return false;
        const lower = name.toLowerCase();
        return internalPrefixes.some(prefix => lower.startsWith(prefix));
    }

    function isInternal(display) {
        if (!display || !display.name) return false;

        let preferred = "";
        try {
            preferred = PluginService.loadPluginData("niriDS", "fallbackDisplay", "");
        } catch (e) {}

        if (preferred && display.name === preferred) return true;

        return isInternalName(display.name);
    }

    function setDisplays() {
        Proc.runCommand("niriDS:getOutputs", ["niri", "msg", "--json", "outputs"], (output, exitCode) => {
            if (exitCode !== 0) return;
            try {
                const parsed = JSON.parse(output);
                root.rawOutputs = parsed;
                const arr = [];
                for (const name in parsed) {
                    const raw = parsed[name];
                    const internal = isInternal({ name: name });
                    const hasLogical = raw.logical && typeof raw.logical === 'object';
                    let friendly = internal ? "Laptop Screen" : ((raw.make && raw.model) ? (raw.make + " " + raw.model) : name);

                    arr.push({
                        name: name,
                        friendlyName: friendly,
                        disabled: !hasLogical,
                        logical: hasLogical ? raw.logical : null,
                        isInternal: internal
                    });
                }
                arr.sort((a, b) => {
                    if (a.isInternal !== b.isInternal) return a.isInternal ? -1 : 1;
                    return a.name.localeCompare(b.name);
                });
                arr.forEach(d => delete d.isInternal);
                
                const newJson = JSON.stringify(arr);
                if (root._displaysJsonCache !== newJson) {
                    root._displaysJsonCache = newJson;
                    root.displays = arr;
                }
            } catch (e) {
                console.warn("niriDS: setDisplays failed:", e);
            }
        });
    }

    function toggleDisable(display) {
        if (!display || !display.name) return;
        stopMirror();
        const action = display.disabled ? "on" : "off";
        Proc.runCommand("niriDS:toggle", ["niri", "msg", "output", display.name, action], (out, code) => {
            if (code === 0) setDisplays();
        });
    }

    function apply(profile) {
        stopMirror();
        const toProcess = [...displays];
        if (toProcess.length === 0) return;

        const internal = toProcess.filter(d => isInternal(d));
        const external = toProcess.filter(d => !isInternal(d));

        function enableAll(callback) {
            function enableNext(i) {
                if (i >= toProcess.length) {
                    callback();
                    return;
                }
                Proc.runCommand("niriDS:enable", ["niri", "msg", "output", toProcess[i].name, "on"], () => enableNext(i + 1));
            }
            enableNext(0);
        }

        function disableExternal(callback) {
            function disableNext(i) {
                if (i >= external.length) {
                    callback();
                    return;
                }
                Proc.runCommand("niriDS:disable", ["niri", "msg", "output", external[i].name, "off"], () => disableNext(i + 1));
            }
            disableNext(0);
        }

        function disableInternal(callback) {
            function disableNext(i) {
                if (i >= internal.length) {
                    callback();
                    return;
                }
                Proc.runCommand("niriDS:disable", ["niri", "msg", "output", internal[i].name, "off"], () => disableNext(i + 1));
            }
            disableNext(0);
        }

        function finish() {
            Qt.callLater(() => setDisplays());
        }

        if (profile === "internal_only") {
            enableAll(() => {
                disableExternal(() => finish());
            });
        } else if (profile === "external_only") {
            enableAll(() => {
                disableInternal(() => finish());
            });
        } else if (profile === "extend") {
            enableAll(() => finish());
        } else if (profile === "mirror") {
            enableAll(() => {
                mirrorDisplay();
                finish();
            });
        } else {
            finish();
        }
    }

    function enableInternalDisplay() {
        Proc.runCommand("niriDS:fallbackCheck", ["niri", "msg", "--json", "outputs"], (output, exitCode) => {
            if (exitCode !== 0) {
                const pref = PluginService ? PluginService.loadPluginData("niriDS", "fallbackDisplay", "") : "";
                if (pref) {
                    Proc.runCommand("niriDS:recover", ["niri", "msg", "output", pref, "on"], () => setDisplays());
                }
                return;
            }

            try {
                const parsed = JSON.parse(output);
                for (const name in parsed) {
                    if (isInternalName(name)) {
                        Proc.runCommand("niriDS:recover", ["niri", "msg", "output", name, "on"], () => setDisplays());
                        return;
                    }
                }
                const pref = PluginService ? PluginService.loadPluginData("niriDS", "fallbackDisplay", "") : "";
                if (pref) {
                    Proc.runCommand("niriDS:recover", ["niri", "msg", "output", pref, "on"], () => setDisplays());
                }
            } catch (e) {
                console.warn("niriDS: enableInternalDisplay failed:", e);
            }
        });
    }

    function mirrorDisplay() {
        // Find internal + any external (regardless of disabled state).
        // Callers (apply("mirror") and the button) must enable outputs first.
        const internal = displays.find(d => isInternal(d));
        const external = displays.find(d => !isInternal(d));
        if (!internal || !external) return;
        wlMirrorProc.command = ["wl-mirror", "--fullscreen-output", external.name, internal.name];
        wlMirrorProc.running = true;
    }

    Component.onCompleted: Qt.callLater(() => setDisplays())
}
