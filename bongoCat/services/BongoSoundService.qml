pragma Singleton

import QtQuick

// Owns the bongo-hit playback. Living in a singleton means there is exactly one
// player per Quickshell process, no matter how many bar widget instances exist.
// On a multi-monitor setup each instance reads input independently and calls
// play() for the same keypress within the same event loop tick, so play()
// de-duplicates those near-simultaneous calls — otherwise the click would sound
// once per monitor (a doubled / flanged hit).
//
// Sounds play in a helper process (SfxClient + ../sfx/shell.qml) so QtMultimedia
// stays out of the shell: its PipeWire backend can crash the process when the
// output device disappears during playback. The in-process SoundEffects below
// are only created if the helper cannot run; QtMultimedia is loaded dynamically
// there, so the plugin still loads on systems without it.
QtObject {
    id: svc

    // Set by the widget before each play; identical across monitors (shared pluginData).
    property real volume: 0.6
    // Which sound profile to use — "bongo" or "pop".
    property string soundProfile: "bongo"

    property double _lastPlayMs: 0
    // Calls within this window are treated as the same keypress arriving from
    // another monitor's widget instance and ignored. Well below the gap between
    // distinct keystrokes in real typing, well above same-tick scheduling jitter.
    readonly property int _dedupMs: 25
    property bool _alt: false

    readonly property var _files: ({
            "bongo": {
                "key1": "key.wav",
                "key2": "key_alt.wav",
                "big": "space.wav"
            },
            "pop": {
                "key1": "pop_key.wav",
                "key2": "pop_key_alt.wav",
                "big": "pop_space.wav"
            }
        })

    property SfxClient _sfx: SfxClient {
        name: "bongoCat"
        helperDir: Qt.resolvedUrl("../sfx")
    }

    // Fallback players, created on first use only if the helper is unavailable.
    property var _local: null

    function _url(file) {
        return Qt.resolvedUrl("../assets/sounds/" + file);
    }

    function _makeSfx(file) {
        return Qt.createQmlObject(
            'import QtMultimedia; SoundEffect {'
            + ' source: "' + _url(file) + '";'
            + ' onStatusChanged: if (status === SoundEffect.Error)'
            + ' console.warn("[BongoCat] failed to load ' + file + '") }',
            svc);
    }

    function _localSfx(profile, slot) {
        if (_local === null) {
            _local = {};
            try {
                for (const p of Object.keys(_files)) {
                    _local[p] = {
                        "key1": _makeSfx(_files[p].key1),
                        "key2": _makeSfx(_files[p].key2),
                        "big": _makeSfx(_files[p].big)
                    };
                }
            } catch (e) {
                console.warn("[BongoCat] QtMultimedia unavailable — key sounds disabled:", e);
                _local = {};
            }
        }
        return _local[profile] ? _local[profile][slot] : null;
    }

    // Starts the helper and preloads every sample so the first click isn't
    // dropped. Called by the widget once sounds are enabled; until then no
    // helper process runs.
    function warmUp() {
        for (const p of Object.keys(_files)) {
            for (const slot of ["key1", "key2", "big"])
                _sfx.load(_url(_files[p][slot]));
        }
    }

    function play(isBigHit) {
        const now = Date.now();
        if (now - _lastPlayMs < _dedupMs)
            return;
        _lastPlayMs = now;
        _alt = !_alt;
        const profile = _files[soundProfile] ? soundProfile : "bongo";
        const slot = isBigHit ? "big" : (_alt ? "key1" : "key2");
        if (!_sfx.unavailable) {
            _sfx.play(_url(_files[profile][slot]), volume);
            return;
        }
        const sfx = _localSfx(profile, slot);
        if (!sfx)
            return;
        sfx.volume = volume;
        sfx.play();
    }
}
