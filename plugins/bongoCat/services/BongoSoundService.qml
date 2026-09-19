pragma Singleton

import QtQuick

// Owns the bongo-hit playback. Living in a singleton means there is exactly one
// set of SoundEffect objects per Quickshell process, no matter how many bar
// widget instances exist. On a multi-monitor setup each instance reads input
// independently and calls play() for the same keypress within the same event
// loop tick, so play() de-duplicates those near-simultaneous calls — otherwise
// the click would sound once per monitor (a doubled / flanged hit).
//
// QtMultimedia is loaded dynamically (not a static import) so the plugin still
// loads on systems without it — DMS treats QtMultimedia the same way in
// AudioService. If it's missing, _available stays false and play() is a no-op.
QtObject {
    id: svc

    // Set by the widget before each play; identical across monitors (shared pluginData).
    property real volume: 0.6
    // Which sound profile to use — "bongo" or "pop".  Profiles are loaded once
    // during startup and switched by pointer so there's no runtime I/O.
    property string soundProfile: "bongo"
    onSoundProfileChanged: _currentSfx = _profiles[soundProfile] || _profiles["bongo"]

    property double _lastPlayMs: 0
    // Calls within this window are treated as the same keypress arriving from
    // another monitor's widget instance and ignored. Well below the gap between
    // distinct keystrokes in real typing, well above same-tick scheduling jitter.
    readonly property int _dedupMs: 25
    property bool _alt: false

    property var _profiles: ({})
    property var _currentSfx: null
    property bool _available: false

    function _makeSfx(file) {
        return Qt.createQmlObject(
            'import QtMultimedia; SoundEffect {'
            + ' source: "' + Qt.resolvedUrl("../assets/sounds/" + file) + '";'
            + ' onStatusChanged: if (status === SoundEffect.Error)'
            + ' console.warn("[BongoCat] failed to load ' + file + '") }',
            svc);
    }

    function _loadProfile(prefix) {
        return {
            key1: _makeSfx(prefix + "key.wav"),
            key2: _makeSfx(prefix + "key_alt.wav"),
            big: _makeSfx(prefix + "space.wav")
        };
    }

    Component.onCompleted: {
        try {
            _profiles["bongo"] = _loadProfile("");
            _profiles["pop"] = _loadProfile("pop_");
            _currentSfx = _profiles["bongo"];
            _available = true;
        } catch (e) {
            console.warn("[BongoCat] QtMultimedia unavailable — key sounds disabled:", e);
        }
    }

    function play(isBigHit) {
        if (!_available || !_currentSfx)
            return;
        const now = Date.now();
        if (now - _lastPlayMs < _dedupMs)
            return;
        _lastPlayMs = now;
        _alt = !_alt;
        const sfx = isBigHit ? _currentSfx.big : (_alt ? _currentSfx.key1 : _currentSfx.key2);
        sfx.volume = volume;
        sfx.play();
    }
}
