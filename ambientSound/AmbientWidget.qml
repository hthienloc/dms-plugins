import QtQuick
import QtQuick.Controls
import Quickshell.Io
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.Plugins
import "./shared"


PluginComponent {
    id: root
    readonly property bool showHints: pluginData.showHints ?? true


    // Layout constants
    readonly property real cellWidth: Math.floor((root.popoutWidth - (Theme.spacingM * 2) - (root.gridSpacing * 3)) / 4)
    readonly property real cellHeight: 96
    readonly property real iconSize: Theme.iconSize
    readonly property real fontSize: Theme.fontSizeSmall
    readonly property real gridSpacing: 8
    readonly property real actionButtonSize: Theme.buttonHeightS

    // Plugin directory (for sound files)
    readonly property string pluginDir: {
        var url = Qt.resolvedUrl(".").toString();
        if (url.startsWith("file://")) url = url.replace("file://", "");
        return url.endsWith("/") ? url.substring(0, url.length - 1) : url;
    }

    function hashString(value) {
        return Qt.md5(String(value));
    }

    function soundId(sound) {
        return sound.id || sound.name;
    }

    function getIpcSocket(soundId) {
        var safeId = String(soundId).replace(/[^A-Za-z0-9_.-]/g, "_").substring(0, 24);
        return "/tmp/dms-ambient-" + safeId + "-" + hashString(soundId) + ".sock";
    }

    function getSound(soundId) {
        if (soundId === "acoustic-guitar") soundId = "guitar";
        for (var i = 0; i < sounds.length; i++) {
            if (root.soundId(sounds[i]) === soundId || sounds[i].name === soundId) return sounds[i];
        }
        return null;
    }

    function commandId(prefix, sound) {
        return prefix + "-" + hashString(sound);
    }

    // Sound definitions
    readonly property var bundledSounds: [
        { name: "rain", icon: "water_drop" },
        { name: "storm", icon: "thunderstorm" },
        { name: "wind", icon: "air" },
        { name: "waves", icon: "waves" },
        { name: "stream", icon: "water" },
        { name: "birds", icon: "flutter_dash" },
        { name: "forest", icon: "forest" },
        { name: "summer-night", icon: "dark_mode" },
        { name: "fireplace", icon: "local_fire_department" },
        { name: "coffee-shop", icon: "local_cafe" },
        { name: "city", icon: "location_city" },
        { name: "train", icon: "train" },
        { name: "boat", icon: "sailing" },
        { name: "guitar", icon: "music_note" },
        { name: "warm-piano", icon: "piano" },
        { name: "ambient-music", icon: "library_music" },
        { name: "lofi-beats", icon: "headphones" },
        { name: "fan", icon: "mode_fan" },
        { name: "airplane", icon: "flight" },
        { name: "laundry-room", icon: "local_laundry_service" },
        { name: "white-noise", icon: "blur_on" },
        { name: "pink-noise", icon: "blur_linear" },
        { name: "brown-noise", icon: "blur_circular" },
        { name: "green-noise", icon: "lens_blur" }
    ]

    readonly property var customSounds: (pluginData.customSounds || []).map(sound => ({
        id: "custom:" + sound.path,
        name: sound.name,
        icon: "audiotrack",
        path: sound.path,
        custom: true
    }))
    readonly property var sounds: bundledSounds.concat(customSounds)
    readonly property var visibleSounds: sounds.filter(s => s.custom || (pluginData.hiddenSounds || []).indexOf(s.name) < 0)

    // Sleep timer presets
    readonly property var sleepPresets: [
        { label: "15m",  minutes: 15 },
        { label: "30m",  minutes: 30 },
        { label: "45m",  minutes: 45 },
        { label: "1h",   minutes: 60 },
        { label: "1.5h", minutes: 90 },
        { label: "2h",   minutes: 120 }
    ]

    // When Done options
    readonly property var whenDoneAudioOptions: [
        { label: I18n.tr("Stop"), icon: "stop", value: "stopAll" },
        { label: I18n.tr("Mute"), icon: "volume_off", value: "mute" }
    ]
    readonly property var whenDoneSystemOptions: [
        { label: I18n.tr("Lock"), icon: "lock", value: "lock" },
        { label: I18n.tr("Suspend"), icon: "bedtime", value: "suspend" },
        { label: I18n.tr("Power"), icon: "power_settings_new", value: "powerOff" }
    ]
    readonly property var whenDoneOptions: whenDoneAudioOptions.concat(whenDoneSystemOptions)
    property var whenDoneActions: (pluginData.whenDoneActions && pluginData.whenDoneActions.length > 0) ? pluginData.whenDoneActions : ["stopAll"]
    property bool timerDropdownOpen: false

    function isWhenDoneSelected(value) {
        return whenDoneActions.indexOf(value) >= 0;
    }

    function toggleWhenDoneAction(value) {
        var idx = whenDoneActions.indexOf(value);
        var newActions = whenDoneActions.slice();

        if (value === "stopAll" || value === "mute") {
            newActions = newActions.filter(a => a !== "stopAll" && a !== "mute");
            if (idx < 0) newActions.push(value);
        } else if (value === "lock" || value === "suspend" || value === "powerOff") {
            newActions = newActions.filter(a => a !== "lock" && a !== "suspend" && a !== "powerOff");
            if (idx < 0) newActions.push(value);
        } else {
            if (idx >= 0) {
                if (whenDoneActions.length > 1) {
                    newActions.splice(idx, 1);
                }
            } else {
                newActions.push(value);
            }
        }

        whenDoneActions = newActions;
        pluginService.savePluginData(root.pluginId, "whenDoneActions", newActions);
    }

    // Audio state
    property var playingSounds: []
    // Sessions retain their resolved paths even if a custom sound is removed from settings.
    property var activeSessions: ({})
    property var stopCallbacks: []
    property string playerBackend: ""
    property bool playerProbeComplete: false
    property var soundVolumes: pluginData.soundVolumes || ({})
    property int masterVolume: pluginData.defaultVolume !== undefined ? parseInt(pluginData.defaultVolume) : 100
    property bool isMuted: false
    property bool showVolumeIndicator: false

    Timer {
        id: volumeIndicatorTimer
        interval: 1200
        repeat: false
        onTriggered: root.showVolumeIndicator = false
    }

    function getEffectiveVolume(sound) {
        var individual = soundVolumes[sound] !== undefined ? soundVolumes[sound] : 100;
        return (individual / 100) * (root.isMuted ? 0 : root.masterVolume);
    }

    function setSoundVolume(sound, vol) {
        var volumes = Object.assign({}, soundVolumes);
        volumes[sound] = vol;
        soundVolumes = volumes;
        pluginService.savePluginData(root.pluginId, "soundVolumes", soundVolumes);
        var session = activeSessions[sound];
        if (session) session.applyVolume(getEffectiveVolume(sound));
    }

    // Preset state
    property var presets: pluginData.presets || []
    property int editingIndex: -1
    property int selectedPresetIndex: -1
    property string activePresetName: (selectedPresetIndex >= 0 && selectedPresetIndex < presets.length) ? presets[selectedPresetIndex].name : ""
    property bool renamingPreset: false
    property var lastPlayingSounds: []

    function togglePlayPause() {
        if (root.playingSounds.length > 0) {
            root.lastPlayingSounds = root.playingSounds.slice();
            root.stopAll();
        } else {
            if (root.lastPlayingSounds.length > 0) {
                var toPlay = root.lastPlayingSounds.slice();
                for (var i = 0; i < toPlay.length; i++) {
                    root.startSound(toPlay[i]);
                }
                root.playingSounds = toPlay;
            } else if (root.selectedPresetIndex >= 0 && root.selectedPresetIndex < root.presets.length) {
                root.loadPreset(root.presets[root.selectedPresetIndex]);
            } else if (root.presets.length > 0) {
                root.loadPreset(root.presets[0]);
                root.selectedPresetIndex = 0;
            } else if (root.visibleSounds.length > 0) {
                var firstSoundId = root.soundId(root.visibleSounds[0]);
                root.toggleSound(firstSoundId);
            }
        }
    }

    function savePreset() {
        if (playingSounds.length === 0) {
            ToastService.showError(I18n.tr("Play some sounds first to save as preset!"));
            return;
        }
        var newPresets = presets.slice();
        var presetName = "Preset " + (newPresets.length + 1);
        newPresets.push({
            name: presetName,
            sounds: playingSounds.slice(),
            volume: root.masterVolume
        });
        presets = newPresets;
        pluginService.savePluginData(root.pluginId, "presets", newPresets);
        selectedPresetIndex = newPresets.length - 1;
        activePresetName = presetName;
        ToastService.showInfo(I18n.tr("Saved ") + presetName);
    }

    function loadPreset(preset) {
        activePresetName = preset.name;
        stopAll(() => {
            root.isMuted = false;
            root.masterVolume = preset.volume;
            var startedSounds = [];
            for (var i = 0; i < preset.sounds.length; i++) {
                if (root.startSound(preset.sounds[i])) startedSounds.push(preset.sounds[i]);
            }
            root.playingSounds = startedSounds;
        });
    }

    function togglePresetByName(presetName) {
        var foundPreset = null;
        for (var i = 0; i < presets.length; i++) {
            if (presets[i].name === presetName) {
                foundPreset = presets[i];
                break;
            }
        }
        if (!foundPreset) return;

        var active = true;
        if (root.playingSounds.length !== foundPreset.sounds.length) {
            active = false;
        } else {
            for (var j = 0; j < foundPreset.sounds.length; j++) {
                if (root.playingSounds.indexOf(foundPreset.sounds[j]) < 0) {
                    active = false;
                    break;
                }
            }
        }

        if (active) {
            root.stopAll();
        } else {
            root.loadPreset(foundPreset);
        }
    }

    function deletePreset(index) {
        if (index < 0 || index >= presets.length) return;
        var newPresets = presets.slice();
        newPresets.splice(index, 1);
        presets = newPresets;
        pluginService.savePluginData(root.pluginId, "presets", newPresets);
        selectedPresetIndex = -1;
        activePresetName = "";
    }

    function cancelRename() {
        if (root.selectedPresetIndex >= 0 && root.selectedPresetIndex < root.presets.length) {
            activePresetName = root.presets[root.selectedPresetIndex].name;
        } else {
            activePresetName = "";
        }
        editingIndex = -1;
        renamingPreset = false;
    }

    function renamePreset(index, newName) {
        if (index >= 0 && index < presets.length && newName && newName.trim() !== "") {
            var trimmed = newName.trim();
            var newPresets = presets.slice();
            var existingIdx = -1;
            for (var i = 0; i < newPresets.length; i++) {
                if (i !== index && newPresets[i].name.toLowerCase() === trimmed.toLowerCase()) {
                    existingIdx = i;
                    break;
                }
            }

            if (existingIdx >= 0) {
                newPresets[existingIdx] = {
                    name: trimmed,
                    sounds: (root.playingSounds.length > 0) ? root.playingSounds.slice() : newPresets[index].sounds.slice(),
                    volume: root.masterVolume
                };
                newPresets.splice(index, 1);
                selectedPresetIndex = existingIdx > index ? existingIdx - 1 : existingIdx;
                presets = newPresets;
                pluginService.savePluginData(root.pluginId, "presets", newPresets);
                activePresetName = trimmed;
                ToastService.showInfo(I18n.tr("Preset overwritten: ") + trimmed);
            } else {
                var isSameName = (newPresets[index].name.toLowerCase() === trimmed.toLowerCase());
                newPresets[index] = {
                    name: trimmed,
                    sounds: (root.playingSounds.length > 0) ? root.playingSounds.slice() : newPresets[index].sounds.slice(),
                    volume: root.masterVolume
                };
                presets = newPresets;
                pluginService.savePluginData(root.pluginId, "presets", newPresets);
                activePresetName = trimmed;
                if (isSameName) {
                    ToastService.showInfo(I18n.tr("Preset overwritten: ") + trimmed);
                } else {
                    ToastService.showInfo(I18n.tr("Preset renamed to ") + trimmed);
                }
            }
        }
        editingIndex = -1;
        renamingPreset = false;
    }

    function soundPath(soundData) {
        return soundData.path || (pluginDir + "/sounds/" + soundData.name + ".ogg");
    }

    function startSound(sound) {
        if (!playerProbeComplete) {
            ToastService.showWarning("Audio player check is still running.");
            return false;
        }
        if (!playerBackend) {
            ToastService.showError("Install mpv or ffplay for playback.");
            return false;
        }
        if (activeSessions[sound]) return true;

        var soundData = getSound(sound);
        if (!soundData) {
            ToastService.showWarning("A sound in this preset is no longer available.");
            return false;
        }

        var session = audioSessionComponent.createObject(root, {
            sessionId: sound,
            backend: playerBackend,
            sourcePath: soundPath(soundData),
            socketPath: getIpcSocket(sound),
            effectiveVolume: getEffectiveVolume(sound)
        });
        if (!session) return false;

        activeSessions[sound] = session;
        session.start();
        return true;
    }

    function stopSound(sound) {
        var session = activeSessions[sound];
        if (session) session.stop();
    }

    function sendIpcVolume(sound, socket, volume) {
        var command = JSON.stringify({ "command": ["set_property", "volume", volume] });
        Proc.runCommand(commandId("ipc", sound), [
            "sh", "-c",
            "printf '%s\\n' \"$1\" | socat - \"UNIX-CONNECT:$2\"",
            "sh", command, socket
        ], null, 0);
    }

    function handleSessionFinished(sound, session, exitCode) {
        if (activeSessions[sound] !== session) return;

        delete activeSessions[sound];
        Proc.runCommand(commandId("cleanup", sound), ["rm", "-f", session.socketPath], null, 0);

        var idx = playingSounds.indexOf(sound);
        if (idx >= 0) {
            var list = playingSounds.slice();
            list.splice(idx, 1);
            playingSounds = list;
        }

        if (!session.stopping && exitCode !== 0) {
            var snd = getSound(sound);
            ToastService.showError("Failed to play " + (snd ? snd.name : "sound") + ".");
        }
        Qt.callLater(() => session.destroy());
        finishStopCallbacks();
    }

    function finishStopCallbacks() {
        if (Object.keys(activeSessions).length > 0 || stopCallbacks.length === 0) return;
        var callbacks = stopCallbacks.slice();
        stopCallbacks = [];
        for (var i = 0; i < callbacks.length; i++) callbacks[i]();
    }

    function updateAllVolumes() {
        for (var i = 0; i < playingSounds.length; i++) {
            var sound = playingSounds[i];
            var session = activeSessions[sound];
            if (session) session.applyVolume(getEffectiveVolume(sound));
        }
    }

    // Audio logic
    function toggleMute() {
        isMuted = !isMuted;
        updateAllVolumes();
    }
    
    function toggleSound(sound) {
        var idx = playingSounds.indexOf(sound);
        var list = playingSounds.slice();

        if (idx >= 0) {
            list.splice(idx, 1);
            playingSounds = list;
            stopSound(sound);
            if (list.length === 0) {
                root.isMuted = false;
            }
        } else {
            if (startSound(sound)) {
                list.push(sound);
                playingSounds = list;
            }
        }
    }

    function stopAll(callback) {
        playingSounds = [];
        isMuted = false;
        if (callback) stopCallbacks = stopCallbacks.concat([callback]);

        var sessionIds = Object.keys(activeSessions);
        for (var i = 0; i < sessionIds.length; i++) activeSessions[sessionIds[i]].stop();
        finishStopCallbacks();
    }

    function destroyAllSessions() {
        var sessionIds = Object.keys(activeSessions);
        for (var i = 0; i < sessionIds.length; i++) activeSessions[sessionIds[i]].destroy();
        activeSessions = {};
    }

    Process {
        id: playerProbe
        running: true
        command: ["sh", "-c", "if command -v mpv >/dev/null 2>&1; then printf mpv; elif command -v ffplay >/dev/null 2>&1; then printf ffplay; fi"]
        stdout: StdioCollector { id: playerProbeOutput }
        stderr: StdioCollector {}
        onExited: exitCode => {
            root.playerBackend = exitCode === 0 ? playerProbeOutput.text.trim() : "";
            root.playerProbeComplete = true;
        }
    }

    Component {
        id: audioSessionComponent
        AudioSession {
            id: audioSession
            onVolumeCommandRequested: (socketPath, volume) => root.sendIpcVolume(sessionId, socketPath, volume)
            onFinished: exitCode => root.handleSessionFinished(sessionId, audioSession, exitCode)
        }
    }

    function adjustVolume(delta) {
        root.showVolumeIndicator = true;
        volumeIndicatorTimer.restart();
        var newVol = Math.min(100, Math.max(0, root.masterVolume + delta));
        if (newVol !== root.masterVolume) {
            root.masterVolume = newVol;
            if (newVol > 0 && root.isMuted) root.isMuted = false;
            updateAllVolumes();
        }
    }

    // Auto‑start key generator
    function autoStartKey(soundName) {
        return "autoStart" + soundName.charAt(0).toUpperCase() + soundName.slice(1).replace("-", "");
    }

    // Timers
    Timer {
        id: autoStartTimer
        interval: 2000
        onTriggered: {
            var mode = pluginData.autoStartMode || "preset";
            if (mode === "preset") {
                var presetName = pluginData.autoStartPreset || "";
                if (presetName !== "") {
                    root.togglePresetByName(presetName);
                }
            } else {
                for (var i = 0; i < root.sounds.length; i++) {
                    var key = autoStartKey(root.sounds[i].name);
                    if (pluginData[key]) root.toggleSound(root.sounds[i].name);
                }
            }
            if (pluginData.enableSleepTimer ?? true) {
                var minutes = parseInt(pluginData.defaultTimer ?? "30") || 30;
                if (minutes > 0) {
                    sleepTimer.interval = minutes * 60 * 1000;
                    sleepTimer.remainingTime = minutes * 60 * 1000;
                    sleepTimer.start();
                }
            }
        }
    }

    Timer {
        id: sleepTimer
        property int remainingTime: 0
        onTriggered: {
            executeWhenDone();
            remainingTime = 0;
        }
    }

    function executeWhenDone() {
        for (var i = 0; i < whenDoneActions.length; i++) {
            var action = whenDoneActions[i];
            if (action === "stopAll") {
                root.stopAll();
            } else if (action === "mute") {
                root.isMuted = true;
                root.updateAllVolumes();
            } else if (action === "lock") {
                Proc.runCommand("lock-screen", ["loginctl", "lock-session"], null, 0);
            } else if (action === "suspend") {
                Proc.runCommand("suspend", ["systemctl", "suspend"], null, 0);
            } else if (action === "powerOff") {
                Proc.runCommand("power-off", ["systemctl", "poweroff"], null, 0);
            }
        }
    }

    Timer {
        id: sleepCountdown
        interval: 1000
        repeat: true                     // tick every second
        running: sleepTimer.running
        onTriggered: sleepTimer.remainingTime = Math.max(0, sleepTimer.remainingTime - 1000);
    }

    Component.onCompleted: {
        autoStartTimer.start();
        // Initialize default preset only once
        if (pluginData.hasInitializedPresets === undefined) {
            var defaultPresets = [
                {
                    name: "Relaxing Rain",
                    sounds: ["rain", "birds", "wind"],
                    volume: 75
                }
            ];
            if (pluginService) {
                pluginService.savePluginData(root.pluginId, "presets", defaultPresets);
                pluginService.savePluginData(root.pluginId, "hasInitializedPresets", true);
            }
        }
    }

    Component.onDestruction: destroyAllSessions()

    pillRightClickAction: () => root.toggleMute()

    // ── Pill (horizontal & vertical) ──
    horizontalBarPill: Component {
        Item {
            implicitWidth: pillRow.implicitWidth
            implicitHeight: pillRow.implicitHeight

            // Mouse area for left click, middle click, right click, and wheel
            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                cursorShape: Qt.PointingHandCursor
                onClicked: (mouse) => {
                    if (mouse.button === Qt.RightButton) {
                        root.toggleMute();
                    } else if (mouse.button === Qt.MiddleButton) {
                        var preset = pluginData.middleClickAction || "";
                        if (preset !== "") {
                            root.togglePresetByName(preset);
                        }
                    } else {
                        root.triggerPopout();
                    }
                }
                onWheel: (wheel) => {
                    var delta = wheel.angleDelta.y > 0 ? 5 : -5;
                    root.adjustVolume(delta);
                }
            }

            // Centered content row
            Row {
                id: pillRow
                anchors.centerIn: parent
                spacing: Theme.spacingXS

                Item {
                    id: iconOrVolumeContainer
                    implicitWidth: root.showVolumeIndicator ? volumeText.reservedWidth : dankIcon.implicitWidth
                    implicitHeight: Math.max(dankIcon.implicitHeight, volumeText.implicitHeight)
                    anchors.verticalCenter: parent.verticalCenter
                    clip: true

                    Behavior on implicitWidth {
                        NumberAnimation { duration: Theme.shortDuration; easing.type: Easing.OutCubic }
                    }

                    DankIcon {
                        id: dankIcon
                        anchors.centerIn: parent
                        opacity: root.showVolumeIndicator ? 0.0 : 1.0
                        scale: root.showVolumeIndicator ? 0.8 : 1.0
                        name: root.isMuted ? "volume_off" : (root.playingSounds.length > 0 ? "equalizer" : "music_note")
                        size: Theme.chipIconSize
                        color: root.isMuted ? Theme.error : (root.playingSounds.length > 0 ? Theme.primary : Theme.surfaceVariantText)

                        Behavior on opacity {
                            NumberAnimation { duration: Theme.shortDuration; easing.type: Easing.OutCubic }
                        }
                        Behavior on scale {
                            NumberAnimation { duration: Theme.shortDuration; easing.type: Easing.OutCubic }
                        }
                    }

                    NumericText {
                        id: volumeText
                        anchors.centerIn: parent
                        opacity: root.showVolumeIndicator ? 1.0 : 0.0
                        scale: root.showVolumeIndicator ? 1.0 : 0.8
                        text: root.masterVolume + "%"
                        reserveText: "100%"
                        font.pixelSize: Theme.fontSizeSmall
                        font.weight: Font.DemiBold
                        color: root.isMuted ? Theme.error : Theme.primary

                        Behavior on opacity {
                            NumberAnimation { duration: Theme.shortDuration; easing.type: Easing.OutCubic }
                        }
                        Behavior on scale {
                            NumberAnimation { duration: Theme.shortDuration; easing.type: Easing.OutCubic }
                        }
                    }
                }
            }
        }
    }

    verticalBarPill: horizontalBarPill

    // Popout dimensions
    popoutWidth: 480
    popoutHeight: {
        let gridRows = Math.ceil(root.visibleSounds.length / 4);
        let gridHeight = gridRows * root.cellHeight + Math.max(0, gridRows - 1) * root.gridSpacing;
        let baseH = root.actionButtonSize + Theme.buttonHeightM + (Theme.spacingM * 3);
        return Math.min(760, baseH + gridHeight);
    }

    component WhenDoneChip: Rectangle {
        id: chipRoot
        property string label: ""
        property string iconName: ""
        property string value: ""
        readonly property bool selected: root.isWhenDoneSelected(value)

        height: Theme.buttonHeightXS
        radius: Theme.cornerRadius
        color: selected
            ? Theme.withAlpha(Theme.primary, 0.18)
            : (chipMouseArea.containsMouse ? Theme.surfaceContainerHighest : Theme.surfaceContainerHigh)
        border.width: 1
        border.color: selected ? Theme.primary : Theme.surfaceVariant

        Behavior on color { ColorAnimation { duration: 120 } }
        Behavior on border.color { ColorAnimation { duration: 120 } }

        Row {
            anchors.centerIn: parent
            spacing: Theme.spacingXXS

            DankIcon {
                name: chipRoot.iconName
                size: Theme.iconSizeSmall
                color: chipRoot.selected ? Theme.primary : Theme.surfaceVariantText
                anchors.verticalCenter: parent.verticalCenter
            }

            StyledText {
                text: chipRoot.label
                font.pixelSize: Theme.fontSizeSmall - 1
                font.weight: chipRoot.selected ? Font.DemiBold : Font.Normal
                color: chipRoot.selected ? Theme.primary : Theme.surfaceVariantText
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        MouseArea {
            id: chipMouseArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.toggleWhenDoneAction(chipRoot.value)
        }
    }

    // Popout content
    popoutContent: Component {
        PopoutComponent {
            width: root.popoutWidth
            headerText: ""
            detailsText: ""
            showCloseButton: false

            Item {
                width: parent.width
                implicitHeight: mainContentColumn.implicitHeight + (Theme.spacingM * 2)

                Column {
                    id: mainContentColumn
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: Theme.spacingM
                    spacing: Theme.spacingM

                    // Top Preset Row
                    Row {
                        id: presetRow
                        width: parent.width
                        height: root.actionButtonSize
                        spacing: Theme.spacingS

                        // Preset Selector (DankDropdown)
                        Item {
                            id: presetSelectorContainer
                            readonly property int visibleButtonCount: root.renamingPreset ? 3 : 2
                            width: parent.width - (root.actionButtonSize + Theme.spacingS) * visibleButtonCount
                            height: root.actionButtonSize

                            DankDropdown {
                                id: presetDropdown
                                anchors.fill: parent
                                visible: !root.renamingPreset
                                compactMode: true
                                dropdownWidth: width
                                emptyText: I18n.tr("Select preset…")
                                options: root.presets.map(function(p) { return p.name; })
                                currentValue: root.activePresetName

                                Connections {
                                    target: root
                                    function onActivePresetNameChanged() {
                                        presetDropdown.currentValue = root.activePresetName;
                                    }
                                }
                                onValueChanged: (newValue) => {
                                    for (var i = 0; i < root.presets.length; i++) {
                                        if (root.presets[i].name === newValue) {
                                            root.selectedPresetIndex = i;
                                            root.loadPreset(root.presets[i]);
                                            break;
                                        }
                                    }
                                }
                            }

                            // Inline rename field
                            DankTextField {
                                id: renameField
                                anchors.fill: parent
                                anchors.margins: 2
                                visible: root.renamingPreset
                                text: root.activePresetName
                                onAccepted: root.renamePreset(root.selectedPresetIndex, text)
                                Keys.onEscapePressed: root.cancelRename()
                                Component.onCompleted: {
                                    if (visible) forceActiveFocus();
                                }
                            }
                        }

                        // Add preset button (+) / Confirm rename button (check)
                        DankActionButton {
                            buttonSize: root.actionButtonSize
                            circular: true
                            iconName: root.renamingPreset ? "check" : "add"
                            iconSize: Theme.iconSizeSmall + 2
                            iconColor: root.renamingPreset ? Theme.primary : Theme.surfaceText
                            backgroundColor: root.renamingPreset ? Theme.withAlpha(Theme.primary, 0.18) : Theme.surfaceContainerHigh
                            tooltipText: root.renamingPreset ? I18n.tr("Confirm") : I18n.tr("Save Preset")
                            onClicked: {
                                if (root.renamingPreset) {
                                    root.renamePreset(root.selectedPresetIndex, renameField.text);
                                } else {
                                    root.savePreset();
                                }
                            }
                        }

                        // Delete preset button (trash), only shown in edit mode
                        DankActionButton {
                            readonly property bool canDelete: root.selectedPresetIndex >= 0 && root.selectedPresetIndex < root.presets.length
                            visible: root.renamingPreset
                            buttonSize: root.actionButtonSize
                            circular: true
                            enabled: canDelete
                            opacity: canDelete ? 1.0 : 0.35
                            iconName: "delete"
                            iconSize: Theme.iconSizeSmall
                            iconColor: Theme.error
                            backgroundColor: Theme.surfaceContainerHigh
                            tooltipText: I18n.tr("Delete Preset")
                            onClicked: {
                                root.deletePreset(root.selectedPresetIndex);
                                root.editingIndex = -1;
                                root.renamingPreset = false;
                            }
                        }

                        // Edit preset button (pencil) / Cancel rename button (close / x)
                        DankActionButton {
                            readonly property bool canEdit: root.selectedPresetIndex >= 0 && root.selectedPresetIndex < root.presets.length
                            buttonSize: root.actionButtonSize
                            circular: true
                            enabled: root.renamingPreset || canEdit
                            opacity: (root.renamingPreset || canEdit) ? 1.0 : 0.35
                            iconName: root.renamingPreset ? "close" : "edit"
                            iconSize: Theme.iconSizeSmall
                            iconColor: root.renamingPreset ? Theme.error : Theme.surfaceText
                            backgroundColor: root.renamingPreset ? Theme.withAlpha(Theme.error, 0.15) : Theme.surfaceContainerHigh
                            tooltipText: root.renamingPreset ? I18n.tr("Cancel") : I18n.tr("Rename Preset")
                            onClicked: {
                                if (root.renamingPreset) {
                                    root.cancelRename();
                                } else {
                                    root.renamingPreset = true;
                                    renameField.text = root.activePresetName;
                                    renameField.forceActiveFocus();
                                    renameField.selectAll();
                                }
                            }
                        }
                    }

                    // Sound Grid
                    Flickable {
                        id: gridFlickable
                        width: parent.width
                        height: Math.min(soundGrid.implicitHeight, root.popoutHeight - (root.actionButtonSize + Theme.buttonHeightM + (Theme.spacingM * 3)))
                        contentWidth: width
                        contentHeight: soundGrid.implicitHeight
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds

                        Grid {
                            id: soundGrid
                            width: parent.width
                            columns: 4
                            spacing: root.gridSpacing

                            Repeater {
                                model: root.visibleSounds
                                delegate: ActionTile {
                                    readonly property string itemId: root.soundId(modelData)
                                    width: Math.floor((soundGrid.width - (root.gridSpacing * 3)) / 4)
                                    height: root.cellHeight
                                    iconName: modelData.icon
                                    title: modelData.name.replace("-", " ")
                                    titleFontSize: Theme.fontSizeSmall
                                    volumeProgress: {
                                        var vol = root.soundVolumes[itemId] !== undefined ? root.soundVolumes[itemId] : 100;
                                        return vol / 100.0;
                                    }
                                    active: root.playingSounds.indexOf(itemId) >= 0

                                    onClicked: root.toggleSound(itemId)
                                    onScrollUp: {
                                        var current = root.soundVolumes[itemId] !== undefined ? root.soundVolumes[itemId] : 100;
                                        root.setSoundVolume(itemId, Math.min(100, current + 5));
                                    }
                                    onScrollDown: {
                                        var current = root.soundVolumes[itemId] !== undefined ? root.soundVolumes[itemId] : 100;
                                        root.setSoundVolume(itemId, Math.max(0, current - 5));
                                    }
                                }
                            }
                        }
                    }

                    // Bottom Control Bar
                    Item {
                        id: bottomBar
                        width: parent.width
                        height: Theme.buttonHeightM

                        Row {
                            anchors.fill: parent
                            spacing: Theme.spacingS

                            // Mute button
                            DankActionButton {
                                id: muteBtn
                                buttonSize: root.actionButtonSize
                                circular: true
                                anchors.verticalCenter: parent.verticalCenter
                                backgroundColor: Theme.surfaceContainerHigh
                                iconName: root.isMuted ? "volume_off" : (root.masterVolume > 50 ? "volume_up" : (root.masterVolume > 0 ? "volume_down" : "volume_mute"))
                                iconSize: Theme.iconSizeMedium
                                iconColor: root.isMuted ? Theme.error : Theme.surfaceText
                                tooltipText: root.isMuted ? I18n.tr("Unmute") : I18n.tr("Mute")
                                onClicked: root.toggleMute()
                            }

                            // Master Volume Slider
                            DankSlider {
                                id: masterSlider
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width - (root.actionButtonSize * 3) - (Theme.spacingS * 3)
                                minimum: 0
                                maximum: 100
                                step: 5
                                value: root.masterVolume
                                showValue: true
                                unit: "%"
                                wheelEnabled: true
                                onSliderValueChanged: (v) => {
                                    if (v !== root.masterVolume) {
                                        root.masterVolume = v;
                                        if (v > 0 && root.isMuted) root.isMuted = false;
                                        root.updateAllVolumes();
                                    }
                                }

                                Connections {
                                    target: root
                                    function onMasterVolumeChanged() {
                                        if (masterSlider.value !== root.masterVolume) {
                                            masterSlider.value = root.masterVolume;
                                        }
                                    }
                                }
                            }

                            // Timer button
                            DankActionButton {
                                id: timerBtn
                                buttonSize: root.actionButtonSize
                                circular: true
                                anchors.verticalCenter: parent.verticalCenter
                                backgroundColor: sleepTimer.running
                                    ? Theme.primary
                                    : (root.timerDropdownOpen ? Theme.withAlpha(Theme.primary, 0.18) : Theme.surfaceContainerHigh)
                                iconName: "timer"
                                iconSize: Theme.iconSizeMedium
                                iconColor: sleepTimer.running ? Theme.onPrimary : (root.timerDropdownOpen ? Theme.primary : Theme.surfaceText)
                                tooltipText: I18n.tr("Sleep Timer")
                                onClicked: {
                                    root.timerDropdownOpen = !root.timerDropdownOpen;
                                }

                                // Small badge if running
                                Rectangle {
                                    anchors.top: parent.top
                                    anchors.right: parent.right
                                    anchors.margins: -2
                                    height: 16
                                    implicitWidth: timerBadgeText.implicitWidth + 8
                                    radius: 8
                                    color: Theme.primary
                                    visible: sleepTimer.running && !root.timerDropdownOpen

                                    StyledText {
                                        id: timerBadgeText
                                        anchors.centerIn: parent
                                        text: Math.ceil(sleepTimer.remainingTime / 60000) + "m"
                                        font.pixelSize: 9
                                        font.weight: Font.Bold
                                        color: Theme.onPrimary
                                    }
                                }
                            }

                            // Play / Pause / Resume button
                            DankActionButton {
                                id: playPauseBtn
                                buttonSize: root.actionButtonSize
                                circular: true
                                anchors.verticalCenter: parent.verticalCenter
                                backgroundColor: Theme.primary
                                iconName: root.playingSounds.length > 0 ? "pause" : "play_arrow"
                                iconSize: Theme.iconSize
                                iconColor: Theme.onPrimary
                                tooltipText: root.playingSounds.length > 0 ? I18n.tr("Pause") : I18n.tr("Resume")
                                onClicked: root.togglePlayPause()
                            }
                        }
                    }
                }

                // Backdrop for popups
                MouseArea {
                    anchors.fill: parent
                    z: 99
                    visible: root.timerDropdownOpen
                    onClicked: {
                        root.timerDropdownOpen = false;
                        root.renamingPreset = false;
                    }
                }

                // Timer / When Done Dropdown
                Rectangle {
                    id: timerDropdownCard
                    z: 100
                    visible: opacity > 0
                    opacity: root.timerDropdownOpen ? 1.0 : 0.0
                    scale: root.timerDropdownOpen ? 1.0 : 0.95
                    transformOrigin: Item.BottomRight

                    anchors.bottom: mainContentColumn.bottom
                    anchors.bottomMargin: 64
                    anchors.right: mainContentColumn.right
                    width: Math.min(parent.width - (Theme.spacingM * 2), 380)

                    height: timerDropdownContent.implicitHeight + (Theme.spacingS * 2)
                    radius: Theme.cornerRadius
                    color: Theme.surfaceContainer
                    border.width: 1
                    border.color: Theme.outlineVariant

                    Behavior on opacity { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }
                    Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutQuad } }

                    Column {
                        id: timerDropdownContent
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: Theme.spacingS
                        spacing: Theme.spacingS

                        // Duration presets (timer not running)
                        Row {
                            width: parent.width
                            spacing: Theme.spacingXS
                            visible: !sleepTimer.running

                            Repeater {
                                model: root.sleepPresets
                                delegate: DankButton {
                                    text: modelData.label
                                    width: (parent.width - (parent.spacing * (root.sleepPresets.length - 1))) / root.sleepPresets.length
                                    height: Theme.buttonHeightXS
                                    onClicked: {
                                        var ms = modelData.minutes * 60 * 1000;
                                        sleepTimer.interval = ms;
                                        sleepTimer.remainingTime = ms;
                                        sleepTimer.start();
                                        root.timerDropdownOpen = false;
                                    }
                                }
                            }
                        }

                        // Active countdown (timer running)
                        Row {
                            width: parent.width
                            spacing: Theme.spacingS
                            visible: sleepTimer.running

                            DankIcon {
                                name: "hourglass_top"
                                size: Theme.iconSizeMedium
                                color: Theme.primary
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            StyledText {
                                text: I18n.tr("Sleep timer: ") + Math.ceil(sleepTimer.remainingTime / 60000) + I18n.tr(" minutes left")
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.primary
                                font.weight: Font.Medium
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width - 80 - parent.spacing * 2 - Theme.iconSizeMedium
                            }

                            DankButton {
                                text: I18n.tr("Cancel")
                                width: 80
                                height: Theme.buttonHeightXS
                                backgroundColor: Theme.surfaceContainerHighest
                                textColor: Theme.surfaceText
                                onClicked: sleepTimer.stop()
                            }
                        }

                        // When Done section
                        Column {
                            width: parent.width
                            spacing: Theme.spacingXS

                            StyledText {
                                text: I18n.tr("When done:")
                                font.pixelSize: Theme.fontSizeSmall
                                font.weight: Font.Bold
                                color: Theme.surfaceVariantText
                            }

                            Row {
                                width: parent.width
                                spacing: Theme.spacingXS

                                Repeater {
                                    model: root.whenDoneAudioOptions
                                    delegate: WhenDoneChip {
                                        width: Math.floor((parent.width - 1 - (parent.spacing * 5)) / 5)
                                        label: modelData.label
                                        iconName: modelData.icon
                                        value: modelData.value
                                    }
                                }

                                Rectangle {
                                    width: 1
                                    height: 18
                                    color: Theme.outlineVariant
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Repeater {
                                    model: root.whenDoneSystemOptions
                                    delegate: WhenDoneChip {
                                        width: Math.floor((parent.width - 1 - (parent.spacing * 5)) / 5)
                                        label: modelData.label
                                        iconName: modelData.icon
                                        value: modelData.value
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
