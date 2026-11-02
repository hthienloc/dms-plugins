import QtQuick
import Quickshell.Widgets
import qs.Common
import qs.Services
import qs.DCommon.Widgets
import qs.Modules.Plugins
import qs.Modules.DDash
import qs.Widgets
import "./shared"

DashTabComponent {
    id: root

    readonly property var bundledSounds: [
        { name: "rain", icon: "water_drop", mood: "rain" },
        { name: "storm", icon: "thunderstorm", mood: "rain" },
        { name: "wind", icon: "air", mood: "wind" },
        { name: "waves", icon: "waves", mood: "waves" },
        { name: "stream", icon: "water", mood: "waves" },
        { name: "birds", icon: "flutter_dash", mood: "forest" },
        { name: "forest", icon: "forest", mood: "forest" },
        { name: "summer-night", icon: "dark_mode", mood: "night" },
        { name: "fireplace", icon: "local_fire_department", mood: "fire" },
        { name: "coffee-shop", icon: "local_cafe", mood: "cafe" },
        { name: "city", icon: "location_city", mood: "city" },
        { name: "train", icon: "train", mood: "train" },
        { name: "boat", icon: "sailing", mood: "waves" },
        { name: "guitar", icon: "music_note", mood: "music" },
        { name: "warm-piano", icon: "piano", mood: "music" },
        { name: "ambient-music", icon: "library_music", mood: "music" },
        { name: "lofi-beats", icon: "headphones", mood: "music" },
        { name: "fan", icon: "mode_fan", mood: "wind" },
        { name: "airplane", icon: "flight", mood: "wind" },
        { name: "laundry-room", icon: "local_laundry_service", mood: "cafe" },
        { name: "white-noise", icon: "blur_on", mood: "noise" },
        { name: "pink-noise", icon: "blur_linear", mood: "noise" },
        { name: "brown-noise", icon: "blur_circular", mood: "noise" },
        { name: "green-noise", icon: "lens_blur", mood: "noise" }
    ]

    readonly property var customSounds: {
        const raw = root.pluginData?.customSounds || [];
        return raw.map(sound => ({
            id: "custom:" + sound.path,
            name: sound.name,
            icon: "audiotrack",
            mood: "music",
            path: sound.path,
            custom: true
        }));
    }

    readonly property var presets: root.pluginData?.presets || []
    readonly property var allSounds: bundledSounds.concat(customSounds)
    readonly property var visibleSounds: allSounds.filter(sound => sound.custom || (root.pluginData?.hiddenSounds || []).indexOf(sound.name) < 0)

    readonly property var playingSounds: root.pluginData?.playingSounds || []
    readonly property int playingCount: playingSounds.length
    readonly property bool isPlayingActive: playingCount > 0
    readonly property bool isMuted: root.pluginData?.isMuted ?? false
    readonly property int masterVolume: Number(root.pluginData?.masterVolume ?? 100)
    readonly property string selectedPresetName: root.pluginData?.selectedPreset || ""

    // Primary sound info
    readonly property var primarySoundData: {
        if (!root.isPlayingActive)
            return null;
        const currentName = root.playingSounds[0];
        return root.allSounds.find(s => s.name === currentName || s.id === currentName) || null;
    }

    // Interactive UI toggles
    property bool soundListOpen: false
    property bool timerOpen: false

    // Communication bus with widget
    PluginGlobalVar {
        id: dashAction
        varName: "ambientSoundDashAction"
        defaultValue: ""
    }

    PluginGlobalVar {
        id: timerRemainingVar
        varName: "ambientSoundTimerRemaining"
        defaultValue: 0
    }

    // Local optimistic sound volume cache for instantaneous, smooth wheel scrolling
    property var localSoundVolumes: ({})
    property var pendingVolumeTimers: ({})

    function getSoundVolume(soundId) {
        if (localSoundVolumes[soundId] !== undefined)
            return localSoundVolumes[soundId];
        return (root.pluginData?.soundVolumes || {})[soundId] !== undefined ? root.pluginData.soundVolumes[soundId] : 100;
    }

    function bumpSoundVolume(soundId, delta) {
        var current = getSoundVolume(soundId);
        var target = Math.max(0, Math.min(100, current + delta));
        
        // Instant local feedback
        var updated = Object.assign({}, localSoundVolumes);
        updated[soundId] = target;
        localSoundVolumes = updated;

        // Debounce / send IPC action immediately
        sendAction({ type: "adjustSoundVolume", sound: soundId, delta: target - current });
    }

    // Sleep timer properties
    readonly property int timerRemainingMs: Number(timerRemainingVar.value) || 0
    readonly property bool isTimerActive: timerRemainingMs > 0

    function formatTimer(ms) {
        const totalSec = Math.max(0, Math.floor(ms / 1000));
        const mins = Math.floor(totalSec / 60);
        const secs = totalSec % 60;
        return mins + ":" + (secs < 10 ? "0" : "") + secs;
    }

    function sendAction(actionObj) {
        actionObj._seq = Date.now() + Math.random();
        dashAction.set(JSON.stringify(actionObj));
    }

    function setPreset(presetName) {
        sendAction({ type: "loadPreset", name: presetName });
    }

    function saveNewPreset(name) {
        sendAction({ type: "saveNewPreset", name: name || "" });
    }

    function overwriteCurrentPreset(name) {
        sendAction({ type: "overwritePreset", name: name || root.selectedPresetName });
    }

    function deleteCurrentPreset(name) {
        sendAction({ type: "deletePreset", name: name || root.selectedPresetName });
    }

    function renamePreset(oldName, newName) {
        sendAction({ type: "renamePreset", oldName: oldName, newName: newName });
    }

    function isPlaying(soundId) {
        return root.playingSounds.indexOf(soundId) >= 0;
    }

    function toggleSound(soundId) {
        sendAction({ type: "toggleSound", sound: soundId });
    }

    Timer {
        id: masterVolumeDebounce
        interval: 100
        repeat: false
        property int pendingVolume: -1
        onTriggered: {
            if (pendingVolume >= 0) {
                sendAction({ type: "setMasterVolume", value: pendingVolume });
                pendingVolume = -1;
            }
        }
    }

    function setMasterVolume(value) {
        var val = Math.max(0, Math.min(100, Number(value) || 0));
        masterVolumeDebounce.pendingVolume = val;
        masterVolumeDebounce.restart();
    }

    function toggleMute() {
        sendAction({ type: "toggleMute" });
    }

    function togglePlayPause() {
        sendAction({ type: "togglePlayPause" });
    }

    function stopAllSounds() {
        sendAction({ type: "stopAll" });
    }

    function startSleepTimer(minutes) {
        sendAction({ type: "timerStart", minutes: minutes });
    }

    function cancelSleepTimer() {
        sendAction({ type: "timerCancel" });
    }

    function toggleWhenDone(value) {
        sendAction({ type: "toggleWhenDone", value: value });
    }

    focusTarget: playTransportBtn
    implicitWidth: DashMetrics.contentWidthFor(SettingsData.showWeekNumber)
    implicitHeight: DashMetrics.tabMinHeight
    height: DashMetrics.tabMinHeight

    readonly property real innerGap: Theme.spacingXL
    readonly property real artColumnWidth: Math.round((width - innerGap) * DashMetrics.mediaArtColumnRatio)
    readonly property real deckWidth: width - artColumnWidth - innerGap

    Item {
        id: mainLayout
        anchors.fill: parent

        // ==============================================================
        // LEFT COLUMN: Stage Art / Sound Mixer Surface
        // ==============================================================
        ClippingRectangle {
            id: leftColumn
            width: root.artColumnWidth
            height: parent.height
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            radius: Theme.cornerRadiusXL
            color: Theme.foregroundColor(Theme.cardSurface, true)
            border.width: Theme.layerOutlineWidth
            border.color: Theme.outlineMedium

                // State A: Dynamic Living Landscape Visualizer
                Item {
                    id: visualScene
                    anchors.fill: parent
                    visible: !root.soundListOpen

                    Canvas {
                        id: visualCanvas
                        anchors.fill: parent
                        antialiasing: true

                        property real animTime: 0
                        property var rainParticles: []
                        property var emberParticles: []
                        property var starParticles: []
                        property var birdParticles: []
                        property var noteParticles: []

                        Component.onCompleted: {
                            // Rain (Spawned across wider bounds so angled wind covers all corners)
                            const rains = [];
                            for (let i = 0; i < 52; i++) {
                                rains.push({
                                    x: -120 + Math.random() * 580,
                                    y: Math.random() * 500,
                                    len: 6 + Math.random() * 7, // sleeker, smaller drops
                                    speed: 2.4 + Math.random() * 2.2,
                                    drift: 0.6 + Math.random() * 0.4,
                                    alpha: 0.2 + Math.random() * 0.35
                                });
                            }
                            rainParticles = rains;

                            // Embers
                            const embers = [];
                            for (let i = 0; i < 24; i++) {
                                embers.push({
                                    x: 80 + Math.random() * 120,
                                    y: 260 + Math.random() * 80,
                                    r: 1.0 + Math.random() * 2.0,
                                    speed: 0.35 + Math.random() * 0.6,
                                    alpha: 0.2 + Math.random() * 0.5
                                });
                            }
                            emberParticles = embers;

                            // Stars
                            const stars = [];
                            for (let i = 0; i < 40; i++) {
                                stars.push({
                                    x: Math.random() * 400,
                                    y: Math.random() * 180,
                                    r: 0.8 + Math.random() * 1.6,
                                    phase: Math.random() * Math.PI * 2
                                });
                            }
                            starParticles = stars;

                            // Birds
                            const birds = [];
                            for (let i = 0; i < 3; i++) {
                                birds.push({
                                    x: i * 110 + Math.random() * 40,
                                    y: 45 + i * 20 + Math.random() * 15,
                                    speed: 0.35 + Math.random() * 0.2,
                                    size: 5 + Math.random() * 3
                                });
                            }
                            birdParticles = birds;

                            // Music Notes
                            const notes = [];
                            for (let i = 0; i < 8; i++) {
                                notes.push({
                                    x: 100 + Math.random() * 200,
                                    y: 100 + Math.random() * 200,
                                    speed: 0.25 + Math.random() * 0.35,
                                    phase: Math.random() * 6,
                                    char: ["♪", "♫", "♬"][Math.floor(Math.random() * 3)]
                                });
                            }
                            noteParticles = notes;
                        }

                        Timer {
                            interval: 40
                            repeat: true
                            running: root.live && !root.soundListOpen && root.isPlayingActive
                            onTriggered: {
                                visualCanvas.animTime += 0.016;
                                visualCanvas.requestPaint();
                            }
                        }

                        Connections {
                            target: root
                            function onPlayingSoundsChanged() {
                                visualCanvas.requestPaint();
                            }
                            function onIsPlayingActiveChanged() {
                                visualCanvas.requestPaint();
                            }
                        }

                        onPaint: {
                            const ctx = getContext("2d");
                            ctx.reset();
                            ctx.clearRect(0, 0, width, height);

                            const active = root.playingSounds;
                            const has = (name) => active.indexOf(name) >= 0;

                            // Sound category flags
                            const hasRain = has("rain") || has("storm");
                            const hasStorm = has("storm");
                            const hasWind = has("wind") || has("fan") || has("airplane");
                            const hasWater = has("waves") || has("stream") || has("boat");
                            const hasFire = has("fireplace");
                            const hasNight = has("summer-night");
                            const hasForest = has("forest") || has("birds");
                            const hasBirds = has("birds");
                            const hasCafe = has("coffee-shop") || has("laundry-room");
                            const hasCity = has("city") || has("train");
                            const hasMusic = has("guitar") || has("warm-piano") || has("ambient-music") || has("lofi-beats") || has("white-noise") || has("pink-noise") || has("brown-noise") || has("green-noise");

                            // 1. SKY GRADIENT (Atmospheric sky)
                            const sky = ctx.createLinearGradient(0, 0, 0, height);
                            if (hasStorm) {
                                sky.addColorStop(0, "#0c101c");
                                sky.addColorStop(0.65, "#171d2b");
                                sky.addColorStop(1, "#1e2638");
                            } else if (hasNight) {
                                sky.addColorStop(0, "#080b18");
                                sky.addColorStop(0.6, "#13192f");
                                sky.addColorStop(1, "#1c253f");
                            } else if (hasRain) {
                                sky.addColorStop(0, "#141a29");
                                sky.addColorStop(0.65, "#1f273b");
                                sky.addColorStop(1, "#28334a");
                            } else if (hasFire || hasCafe) {
                                sky.addColorStop(0, "#19141f");
                                sky.addColorStop(0.65, "#251b29");
                                sky.addColorStop(1, "#332231");
                            } else {
                                sky.addColorStop(0, "#101626");
                                sky.addColorStop(0.65, "#182035");
                                sky.addColorStop(1, "#222c44");
                            }
                            ctx.fillStyle = sky;
                            ctx.fillRect(0, 0, width, height);

                            // 2. CELESTIAL: Moon & Stars (Night / Idle / Clear sky)
                            if (hasNight || (!hasRain && !hasStorm)) {
                                // Stars
                                for (let i = 0; i < starParticles.length; i++) {
                                    const s = starParticles[i];
                                    const twinkle = 0.3 + 0.7 * Math.abs(Math.sin(animTime * 1.5 + s.phase));
                                    ctx.fillStyle = "rgba(255, 255, 255, " + (twinkle * 0.8) + ")";
                                    ctx.beginPath();
                                    ctx.arc(s.x % width, s.y, s.r, 0, 2 * Math.PI);
                                    ctx.fill();
                                }

                                // Crescent / Glowing Moon
                                const moonX = width * 0.8;
                                const moonY = height * 0.22;
                                const moonR = 26;

                                // Moon Halo
                                const moonHalo = ctx.createRadialGradient(moonX, moonY, moonR * 0.5, moonX, moonY, moonR * 2.4);
                                moonHalo.addColorStop(0, "rgba(255, 255, 230, 0.2)");
                                moonHalo.addColorStop(1, "rgba(255, 255, 255, 0)");
                                ctx.fillStyle = moonHalo;
                                ctx.beginPath();
                                ctx.arc(moonX, moonY, moonR * 2.4, 0, 2 * Math.PI);
                                ctx.fill();

                                // Moon Body
                                ctx.fillStyle = "#fff8db";
                                ctx.beginPath();
                                ctx.arc(moonX, moonY, moonR, 0, 2 * Math.PI);
                                ctx.fill();

                                // Moon shadow for crescent
                                ctx.fillStyle = hasNight ? "#13192f" : "#182035";
                                ctx.beginPath();
                                ctx.arc(moonX + 10, moonY - 4, moonR * 0.9, 0, 2 * Math.PI);
                                ctx.fill();
                            }

                            // 3. BACKGROUND MOUNTAINS
                            ctx.fillStyle = "rgba(20, 28, 48, 0.75)";
                            ctx.beginPath();
                            ctx.moveTo(0, height * 0.65);
                            ctx.lineTo(width * 0.22, height * 0.44);
                            ctx.lineTo(width * 0.48, height * 0.62);
                            ctx.lineTo(width * 0.76, height * 0.4);
                            ctx.lineTo(width, height * 0.58);
                            ctx.lineTo(width, height);
                            ctx.lineTo(0, height);
                            ctx.closePath();
                            ctx.fill();

                            // 4. MIDGROUND: Pine Trees Forest / Landscape Hill
                            const treeColor = hasFire ? "#1d1724" : "#111827";
                            ctx.fillStyle = treeColor;
                            ctx.beginPath();
                            ctx.moveTo(0, height * 0.72);
                            // Hill curve
                            ctx.bezierCurveTo(width * 0.35, height * 0.64, width * 0.65, height * 0.75, width, height * 0.68);
                            ctx.lineTo(width, height);
                            ctx.lineTo(0, height);
                            ctx.closePath();
                            ctx.fill();

                            // Pine tree silhouettes
                            ctx.fillStyle = treeColor;
                            const drawPine = (x, y, w, h) => {
                                ctx.beginPath();
                                ctx.moveTo(x, y - h);
                                ctx.lineTo(x - w/2, y);
                                ctx.lineTo(x + w/2, y);
                                ctx.closePath();
                                ctx.fill();
                            };

                            const treeCount = hasForest ? 16 : 8;
                            for (let i = 0; i < treeCount; i++) {
                                const tx = (i / treeCount) * width + Math.sin(i) * 12;
                                const ty = height * 0.68 + Math.cos(i) * 10;
                                drawPine(tx, ty, 18 + (i % 3) * 6, 36 + (i % 4) * 8);
                            }

                            // 5. COZY CABIN / COFFEE SHOP / CITY
                            if (hasCafe || hasCity) {
                                const cx = width * 0.68;
                                const cy = height * 0.64;

                                // Cabin Roof
                                ctx.fillStyle = "#2d2033";
                                ctx.beginPath();
                                ctx.moveTo(cx + 20, cy - 24);
                                ctx.lineTo(cx - 8, cy);
                                ctx.lineTo(cx + 48, cy);
                                ctx.closePath();
                                ctx.fill();

                                // Cabin Wall
                                ctx.fillStyle = "#1e1724";
                                ctx.fillRect(cx, cy, 40, 28);

                                // Warm Glowing Window
                                const glow = 0.7 + 0.3 * Math.sin(animTime * 3);
                                ctx.fillStyle = "rgba(255, 195, 77, " + glow + ")";
                                ctx.fillRect(cx + 10, cy + 6, 12, 12);
                                ctx.fillRect(cx + 24, cy + 6, 8, 12);

                                // Chimney smoke (continuous slow peaceful rising puffs with fade in/out)
                                for (let s = 0; s < 5; s++) {
                                    // Progress normalized from 0.0 (chimney mouth) to 1.0 (dissipated high up)
                                    const progress = ((animTime * 0.15 + s * 0.2) % 1.0);
                                    const sy = (cy - 24) - progress * 56;
                                    const sx = cx + 32 + Math.sin(animTime * 0.8 + s * 1.2) * (progress * 12);
                                    const sRadius = 2.5 + progress * 7.0;
                                    // Smooth envelope: fade in quickly, fade out gracefully near top
                                    const alpha = Math.sin(progress * Math.PI) * 0.3;

                                    ctx.fillStyle = "rgba(210, 215, 230, " + alpha + ")";
                                    ctx.beginPath();
                                    ctx.arc(sx, sy, sRadius, 0, 2 * Math.PI);
                                    ctx.fill();
                                }
                            }

                            // 6. CAMPFIRE / FIREPLACE EMBERS
                            if (hasFire) {
                                const fx = width * 0.28;
                                const fy = height * 0.76;

                                // Campfire Glow
                                const fireGlow = ctx.createRadialGradient(fx, fy, 4, fx, fy, 48);
                                fireGlow.addColorStop(0, "rgba(255, 130, 40, 0.45)");
                                fireGlow.addColorStop(0.5, "rgba(255, 80, 20, 0.18)");
                                fireGlow.addColorStop(1, "rgba(255, 40, 0, 0)");
                                ctx.fillStyle = fireGlow;
                                ctx.beginPath();
                                ctx.arc(fx, fy, 48, 0, 2 * Math.PI);
                                ctx.fill();

                                // Flickering Flame
                                const fH = 15 + Math.sin(animTime * 3.5) * 3;
                                ctx.fillStyle = "#ff6a1a";
                                ctx.beginPath();
                                ctx.moveTo(fx - 7, fy + 4);
                                ctx.lineTo(fx, fy - fH);
                                ctx.lineTo(fx + 7, fy + 4);
                                ctx.closePath();
                                ctx.fill();

                                ctx.fillStyle = "#ffdb4d";
                                ctx.beginPath();
                                ctx.moveTo(fx - 4, fy + 4);
                                ctx.lineTo(fx, fy - fH * 0.65);
                                ctx.lineTo(fx + 4, fy + 4);
                                ctx.closePath();
                                ctx.fill();

                                // Rising Embers
                                for (let i = 0; i < emberParticles.length; i++) {
                                    const e = emberParticles[i];
                                    e.y -= e.speed;
                                    e.x += Math.sin(animTime * 2.5 + i) * 1.1;
                                    if (e.y < height * 0.4) {
                                        e.y = fy - 2;
                                        e.x = fx - 10 + Math.random() * 20;
                                    }
                                    ctx.fillStyle = "rgba(255, 160, 40, " + e.alpha + ")";
                                    ctx.beginPath();
                                    ctx.arc(e.x, e.y, e.r, 0, 2 * Math.PI);
                                    ctx.fill();
                                }
                            }

                            // 7. WATER (Waves / Stream / Ocean at bottom 25%)
                            if (hasWater) {
                                const waterY = height * 0.77;
                                const waterGrad = ctx.createLinearGradient(0, waterY, 0, height);
                                waterGrad.addColorStop(0, "rgba(24, 46, 74, 0.85)");
                                waterGrad.addColorStop(1, "rgba(12, 25, 42, 0.98)");
                                ctx.fillStyle = waterGrad;
                                ctx.fillRect(0, waterY, width, height - waterY);

                                // Layered flowing animated wave strokes
                                ctx.lineWidth = 1.8;
                                for (let wave = 0; wave < 3; wave++) {
                                    ctx.beginPath();
                                    ctx.strokeStyle = "rgba(130, 200, 255, " + (0.2 + wave * 0.15) + ")";
                                    for (let x = -10; x <= width + 15; x += 10) {
                                        const y = waterY + wave * 16 + Math.sin((x / 45) + animTime * 2.2 + wave * 1.5) * 6;
                                        if (x === -10) ctx.moveTo(x, y);
                                        else ctx.lineTo(x, y);
                                    }
                                    ctx.stroke();
                                }

                                // Sailboat if "boat"
                                if (has("boat")) {
                                    const bx = width * 0.52 + Math.sin(animTime) * 6;
                                    const by = waterY + 12 + Math.cos(animTime * 1.5) * 3;

                                    // Boat hull
                                    ctx.fillStyle = "#e0e6ed";
                                    ctx.beginPath();
                                    ctx.moveTo(bx - 14, by);
                                    ctx.lineTo(bx + 16, by);
                                    ctx.lineTo(bx + 11, by + 6);
                                    ctx.lineTo(bx - 10, by + 6);
                                    ctx.closePath();
                                    ctx.fill();

                                    // Mast & Sail
                                    ctx.strokeStyle = "#4b5563";
                                    ctx.lineWidth = 1.5;
                                    ctx.beginPath();
                                    ctx.moveTo(bx, by);
                                    ctx.lineTo(bx, by - 20);
                                    ctx.stroke();

                                    ctx.fillStyle = "rgba(255, 255, 255, 0.85)";
                                    ctx.beginPath();
                                    ctx.moveTo(bx, by - 19);
                                    ctx.lineTo(bx + 12, by - 4);
                                    ctx.lineTo(bx, by - 4);
                                    ctx.closePath();
                                    ctx.fill();
                                }
                            }

                            // 8. FLYING BIRDS
                            if (hasBirds) {
                                ctx.strokeStyle = "rgba(220, 230, 250, 0.65)";
                                ctx.lineWidth = 1.6;
                                for (let i = 0; i < birdParticles.length; i++) {
                                    const b = birdParticles[i];
                                    b.x += b.speed;
                                    if (b.x > width + 20) b.x = -20;
                                    const flap = Math.sin(animTime * 6 + i) * 3;

                                    ctx.beginPath();
                                    ctx.moveTo(b.x - b.size, b.y + flap);
                                    ctx.quadraticCurveTo(b.x - b.size/2, b.y - flap, b.x, b.y);
                                    ctx.quadraticCurveTo(b.x + b.size/2, b.y - flap, b.x + b.size, b.y + flap);
                                    ctx.stroke();
                                }
                            }

                            // 9. WIND GUSTS
                            if (hasWind) {
                                ctx.strokeStyle = "rgba(200, 225, 255, 0.18)";
                                ctx.lineWidth = 1.6;
                                for (let i = 0; i < 3; i++) {
                                    const wy = height * (0.25 + i * 0.18);
                                    const offset = (animTime * 140 + i * 160) % (width + 120) - 60;
                                    ctx.beginPath();
                                    ctx.moveTo(offset, wy);
                                    ctx.bezierCurveTo(offset + 30, wy - 8, offset + 60, wy + 8, offset + 90, wy);
                                    ctx.stroke();
                                }
                            }

                            // 10. RAIN & STORM (Delicate, translucent teardrop raindrops)
                            if (hasRain) {
                                for (let i = 0; i < rainParticles.length; i++) {
                                    const p = rainParticles[i];
                                    p.y += p.speed;
                                    p.x += p.drift;
                                    if (p.y > height + 20 || p.x > width + 40) {
                                        p.y = -p.len - (Math.random() * 20);
                                        p.x = -80 + Math.random() * (width + 60);
                                    }

                                    // Delicate raindrop dimensions
                                    const angle = Math.atan2(p.speed, p.drift);
                                    const r = Math.max(0.8, p.len * 0.12); // smaller, subtle rounded bulb
                                    const dropAlpha = hasStorm ? p.alpha * 1.2 : p.alpha * 0.75; // subtle translucency

                                    ctx.fillStyle = "rgba(195, 225, 255, " + dropAlpha + ")";
                                    ctx.save();
                                    ctx.translate(p.x, p.y);
                                    ctx.rotate(angle - Math.PI / 2);

                                    ctx.beginPath();
                                    ctx.moveTo(0, -p.len / 2);
                                    ctx.quadraticCurveTo(r * 1.05, p.len * 0.15, r, p.len / 2 - r);
                                    ctx.arc(0, p.len / 2 - r, r, 0, Math.PI, false);
                                    ctx.quadraticCurveTo(-r * 1.05, p.len * 0.15, 0, -p.len / 2);
                                    ctx.closePath();
                                    ctx.fill();
                                    ctx.restore();
                                }

                                // Lightning flash during storm (rare, subtle localized sky glow)
                                if (hasStorm && Math.random() < 0.005) {
                                    const lx = width * (0.2 + Math.random() * 0.6);
                                    const stormGlow = ctx.createRadialGradient(lx, 40, 10, lx, 80, width * 0.45);
                                    stormGlow.addColorStop(0, "rgba(220, 235, 255, 0.16)");
                                    stormGlow.addColorStop(1, "rgba(220, 235, 255, 0)");
                                    ctx.fillStyle = stormGlow;
                                    ctx.fillRect(0, 0, width, height * 0.55);
                                }
                            }

                            // 11. FLOATING MUSICAL PARTICLES
                            if (hasMusic) {
                                ctx.font = "14px sans-serif";
                                for (let i = 0; i < noteParticles.length; i++) {
                                    const n = noteParticles[i];
                                    n.y -= n.speed;
                                    n.x += Math.sin(animTime * 1.8 + n.phase) * 0.6;
                                    if (n.y < 30) {
                                        n.y = height * 0.7 + Math.random() * 40;
                                        n.x = width * 0.2 + Math.random() * width * 0.6;
                                    }
                                    const alpha = Math.sin((n.y / height) * Math.PI) * 0.45;
                                    ctx.fillStyle = "rgba(215, 215, 255, " + alpha + ")";
                                    ctx.fillText(n.char, n.x, n.y);
                                }
                            }
                        }
                    }
                }

                // State B: Sound Customization Grid (Mixer with Pagination)
                Item {
                    id: soundCustomizer
                    anchors.fill: parent
                    anchors.margins: Theme.spacingM
                    visible: root.soundListOpen

                    property int currentPage: 0
                    property bool isRenaming: false
                    readonly property int pageSize: 9 // 3 columns x 3 rows
                    readonly property int totalPages: Math.max(1, Math.ceil(root.visibleSounds.length / pageSize))
                    readonly property var currentSounds: {
                        const start = currentPage * pageSize;
                        return root.visibleSounds.slice(start, start + pageSize);
                    }

                    // Header Row with Title and Page Navigation
                    Item {
                        id: mixerHeader
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.rightMargin: Theme.buttonHeightS + Theme.spacingS // leave exact space for toggle button
                        height: Theme.buttonHeightS

                        // Rename Inline Input Bar
                        Row {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: Theme.spacingXS
                            visible: soundCustomizer.isRenaming

                            DTextField {
                                id: renameInput
                                width: parent.width - 76
                                height: Theme.buttonHeightXS
                                font.pixelSize: Theme.fontSizeSmall
                                onAccepted: {
                                    if (text.trim() !== "") {
                                        root.renamePreset(root.selectedPresetName, text.trim());
                                    }
                                    soundCustomizer.isRenaming = false;
                                }
                                Keys.onEscapePressed: soundCustomizer.isRenaming = false
                            }

                            DIconButton {
                                size: "s"
                                iconName: "check"
                                tooltipText: I18n.trFor("ambientSound", "Confirm Rename")
                                onClicked: {
                                    if (renameInput.text.trim() !== "") {
                                        root.renamePreset(root.selectedPresetName, renameInput.text.trim());
                                    }
                                    soundCustomizer.isRenaming = false;
                                }
                            }

                            DIconButton {
                                size: "s"
                                iconName: "close"
                                tooltipText: I18n.trFor("ambientSound", "Cancel")
                                onClicked: soundCustomizer.isRenaming = false
                            }
                        }

                        // Normal Header View (Left-aligned container for presets & Right-aligned page navigation)
                        Item {
                            anchors.fill: parent
                            visible: !soundCustomizer.isRenaming

                            // Left-aligned interaction tools container (Preset actions)
                            Rectangle {
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                height: Theme.buttonHeightS
                                radius: Theme.cornerRadius
                                color: Theme.surfaceContainerHighest
                                border.width: Theme.layerOutlineWidth
                                border.color: Theme.outlineMedium
                                implicitWidth: presetActionsRow.implicitWidth + Theme.spacingXS * 2

                                Row {
                                    id: presetActionsRow
                                    anchors.centerIn: parent
                                    spacing: Theme.spacingXXS

                                    // Add as new preset
                                    DIconButton {
                                        size: "s"
                                        variant: "standard"
                                        iconName: "add"
                                        tooltipText: I18n.trFor("ambientSound", "Save as New Preset")
                                        enabled: root.isPlayingActive
                                        onClicked: root.saveNewPreset()
                                    }

                                    // Rename selected preset
                                    DIconButton {
                                        size: "s"
                                        variant: "standard"
                                        iconName: "edit"
                                        tooltipText: I18n.trFor("ambientSound", "Rename Selected Preset")
                                        enabled: root.selectedPresetName !== ""
                                        onClicked: {
                                            renameInput.text = root.selectedPresetName;
                                            soundCustomizer.isRenaming = true;
                                            renameInput.forceActiveFocus();
                                            renameInput.selectAll();
                                        }
                                    }

                                    // Overwrite currently selected preset
                                    DIconButton {
                                        size: "s"
                                        variant: "standard"
                                        iconName: "save"
                                        tooltipText: I18n.trFor("ambientSound", "Overwrite Selected Preset")
                                        enabled: root.selectedPresetName !== "" && root.isPlayingActive
                                        onClicked: root.overwriteCurrentPreset()
                                    }

                                    // Delete selected preset
                                    DIconButton {
                                        size: "s"
                                        variant: "standard"
                                        iconName: "delete"
                                        tooltipText: I18n.trFor("ambientSound", "Delete Selected Preset")
                                        enabled: root.selectedPresetName !== ""
                                        onClicked: root.deleteCurrentPreset()
                                    }
                                }
                            }

                            // Right-aligned page navigation: [ Page 1/3 ] [ < ] [ > ]
                            Row {
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: Theme.spacingS

                                StyledText {
                                    text: (soundCustomizer.currentPage + 1) + "/" + soundCustomizer.totalPages
                                    font.pixelSize: Theme.fontSizeSmall
                                    font.weight: Font.DemiBold
                                    color: Theme.surfaceVariantText
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Row {
                                    spacing: Theme.spacingXS
                                    anchors.verticalCenter: parent.verticalCenter

                                    DIconButton {
                                        size: "s"
                                        iconName: "chevron_left"
                                        enabled: soundCustomizer.currentPage > 0
                                        tooltipText: I18n.trFor("ambientSound", "Previous Page")
                                        onClicked: soundCustomizer.currentPage--
                                    }

                                    DIconButton {
                                        size: "s"
                                        iconName: "chevron_right"
                                        enabled: soundCustomizer.currentPage < soundCustomizer.totalPages - 1
                                        tooltipText: I18n.trFor("ambientSound", "Next Page")
                                        onClicked: soundCustomizer.currentPage++
                                    }
                                }
                            }
                        }
                    }

                    // Grid area (fixed 3 columns x 3 rows, perfectly filling stage card)
                    Grid {
                        id: mixerGrid
                        anchors.top: mixerHeader.bottom
                        anchors.topMargin: Theme.spacingS
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        columns: 3
                        spacing: Theme.spacingS

                        readonly property real tileWidth: Math.floor((width - spacing * 2) / 3)
                        readonly property real tileHeight: Math.floor((height - spacing * 2) / 3)

                        Repeater {
                            model: soundCustomizer.currentSounds
                            delegate: ActionTile {
                                required property var modelData
                                width: mixerGrid.tileWidth
                                height: mixerGrid.tileHeight
                                arcSize: 46
                                iconSize: 24
                                tileRadius: 14
                                title: modelData.name.replace(/-/g, " ")
                                iconName: modelData.icon
                                active: root.isPlaying(modelData.name || modelData.id)
                                activeColor: Theme.primary
                                activeContentColor: Theme.primaryText
                                volumeProgress: root.getSoundVolume(modelData.name || modelData.id) / 100.0

                                onClicked: root.toggleSound(modelData.name || modelData.id)
                                onScrollUp: root.bumpSoundVolume(modelData.name || modelData.id, 5)
                                onScrollDown: root.bumpSoundVolume(modelData.name || modelData.id, -5)
                            }
                        }
                    }
                }

                // Top-right Toggle Button (View Scene <-> Sound Mixer)
                DIconButton {
                    size: "s"
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.margins: Theme.spacingM
                    variant: root.soundListOpen ? "filled" : "filledTonal"
                    iconName: root.soundListOpen ? "image" : "tune"
                    tooltipText: root.soundListOpen ? I18n.trFor("ambientSound", "Show Visual Scene") : I18n.trFor("ambientSound", "Customize Sound Mix")
                    onClicked: root.soundListOpen = !root.soundListOpen
                }
            }

            // ==============================================================
            // RIGHT COLUMN: Deck / Controls & Presets
            // ==============================================================
            Item {
                id: rightColumn
                width: root.deckWidth
                height: parent.height
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom

                // TOP AREA: Header & Presets
                Item {
                    id: topPresetsArea
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: bottomControls.top
                    anchors.bottomMargin: Theme.spacingM
                    clip: true

                    Column {
                        anchors.fill: parent
                        spacing: Theme.spacingS

                        // Header / Status Deck
                        Column {
                            width: parent.width
                            spacing: Theme.spacingXXS

                            Item {
                                width: parent.width
                                height: Math.max(statusRow.height, timerBadge.height)

                                Row {
                                    id: statusRow
                                    spacing: Theme.spacingS
                                    anchors.left: parent.left
                                    anchors.verticalCenter: parent.verticalCenter

                                    Rectangle {
                                        width: 8
                                        height: 8
                                        radius: 4
                                        color: root.isPlayingActive ? Theme.primary : Theme.surfaceVariantText
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                    StyledText {
                                        text: root.isPlayingActive ? I18n.trFor("ambientSound", "PLAYING") : I18n.trFor("ambientSound", "PAUSED")
                                        font.pixelSize: Theme.fontSizeSmall
                                        font.weight: Font.Bold
                                        color: root.isPlayingActive ? Theme.primary : Theme.surfaceVariantText
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                }

                                // Active Sleep Timer Badge (Top Right)
                                Rectangle {
                                    id: timerBadge
                                    visible: root.isTimerActive
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    height: 24
                                    radius: 12
                                    color: Theme.withAlpha(Theme.primary, 0.18)
                                    border.width: Theme.layerOutlineWidth
                                    border.color: Theme.withAlpha(Theme.primary, 0.4)
                                    implicitWidth: timerBadgeRow.implicitWidth + Theme.spacingM * 2

                                    Row {
                                        id: timerBadgeRow
                                        anchors.centerIn: parent
                                        spacing: Theme.spacingXS

                                        DIcon {
                                            name: "timer"
                                            size: 14
                                            color: Theme.primary
                                            anchors.verticalCenter: parent.verticalCenter
                                        }

                                        NumericText {
                                            text: root.formatTimer(root.timerRemainingMs)
                                            reserveText: "00:00"
                                            font.pixelSize: Theme.fontSizeSmall
                                            font.weight: Font.Bold
                                            color: Theme.primary
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                    }
                                }
                            }

                            StyledText {
                                text: root.selectedPresetName || I18n.trFor("ambientSound", "Ambient Sounds")
                                font.pixelSize: Theme.fontSizeDisplay
                                font.weight: Font.Bold
                                color: Theme.surfaceText
                                elide: Text.ElideRight
                                width: parent.width
                            }

                            StyledText {
                                id: activeSoundsSubtitle
                                text: {
                                    if (root.isMuted)
                                        return I18n.trFor("ambientSound", "Master volume is muted");
                                    if (root.playingCount > 0)
                                        return I18n.trFor("ambientSound", "%1 active sounds: %2").arg(root.playingCount).arg(root.playingSounds.map(s => s.replace(/-/g, " ")).join(", "));
                                    return I18n.trFor("ambientSound", "Choose a preset or tap individual sounds to start");
                                }
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.surfaceVariantText
                                wrapMode: Text.WordWrap
                                maximumLineCount: 2
                                elide: Text.ElideRight
                                width: parent.width
                                height: fontMetrics.height * 2 + 4
                                verticalAlignment: Text.AlignTop

                                FontMetrics {
                                    id: fontMetrics
                                    font: activeSoundsSubtitle.font
                                }
                            }
                        }

                        // Presets Chips Block
                        Item {
                            width: parent.width
                            height: parent.height - y

                            Flickable {
                                anchors.fill: parent
                                contentHeight: presetFlow.implicitHeight
                                clip: true
                                boundsBehavior: Flickable.StopAtBounds

                                Flow {
                                    id: presetFlow
                                    width: parent.width
                                    spacing: Theme.spacingXS

                                    Repeater {
                                        model: root.presets
                                        delegate: DButton {
                                            required property var modelData
                                            height: Theme.buttonHeightXS
                                            text: modelData.name
                                            radius: Theme.fullRadius(Theme.buttonHeightXS, Theme.buttonHeightXS)
                                            buttonHeight: Theme.buttonHeightXS
                                            backgroundColor: root.selectedPresetName === modelData.name ? Theme.primary : Theme.surfaceContainerHighest
                                            textColor: root.selectedPresetName === modelData.name ? Theme.primaryText : Theme.surfaceText
                                            onClicked: root.setPreset(modelData.name)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // BOTTOM AREA: Media Player Transport Style
                Column {
                    id: bottomControls
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    spacing: Theme.spacingM

                    // Expandable Sleep Timer Drawer
                    Rectangle {
                        visible: root.timerOpen
                        width: parent.width
                        radius: Theme.cornerRadius
                        color: Theme.surfaceContainerHighest
                        border.width: Theme.layerOutlineWidth
                        border.color: Theme.outlineMedium
                        implicitHeight: timerBoxCol.implicitHeight + Theme.spacingS * 2

                        Column {
                            id: timerBoxCol
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: Theme.spacingS
                            spacing: Theme.spacingS

                            Row {
                                width: parent.width
                                spacing: Theme.spacingXS

                                Repeater {
                                    model: [15, 30, 45, 60, 90, 120]
                                    delegate: DButton {
                                        required property var modelData
                                        width: Math.floor((parent.width - parent.spacing * 5) / 6)
                                        height: Theme.buttonHeightXXS
                                        radius: Theme.fullRadius(Theme.buttonHeightXXS, Theme.buttonHeightXXS)
                                        buttonHeight: Theme.buttonHeightXXS
                                        text: modelData + "m"
                                        backgroundColor: (root.isTimerActive && Math.round(root.timerRemainingMs / 60000) === modelData) ? Theme.primary : Theme.surfaceContainerHigh
                                        textColor: (root.isTimerActive && Math.round(root.timerRemainingMs / 60000) === modelData) ? Theme.primaryText : Theme.surfaceText
                                        onClicked: root.startSleepTimer(modelData)
                                    }
                                }
                            }

                            Row {
                                width: parent.width
                                spacing: Theme.spacingS
                                visible: root.isTimerActive

                                StyledText {
                                    text: I18n.trFor("ambientSound", "Remaining:")
                                    font.pixelSize: Theme.fontSizeSmall
                                    color: Theme.surfaceVariantText
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                NumericText {
                                    text: root.formatTimer(root.timerRemainingMs)
                                    reserveText: "00:00"
                                    font.pixelSize: Theme.fontSizeSmall
                                    font.weight: Font.DemiBold
                                    color: Theme.primary
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                DButton {
                                    height: Theme.buttonHeightXXS
                                    radius: Theme.fullRadius(Theme.buttonHeightXXS, Theme.buttonHeightXXS)
                                    buttonHeight: Theme.buttonHeightXXS
                                    text: I18n.trFor("ambientSound", "Cancel")
                                    textColor: Theme.error
                                    backgroundColor: Theme.surfaceContainerHigh
                                    anchors.verticalCenter: parent.verticalCenter
                                    onClicked: root.cancelSleepTimer()
                                }
                            }
                        }
                    }

                    // Single Unified Controls Row: [ Play/Pause ] ── Slider Volume ── [ Timer ]
                    Row {
                        width: parent.width
                        height: Theme.buttonHeightS
                        spacing: Theme.spacingM

                        // Play / Pause Pill Button
                        DIconButton {
                            id: playTransportBtn
                            size: "s"
                            widthMode: "wide"
                            variant: "filled"
                            round: false
                            anchors.verticalCenter: parent.verticalCenter
                            iconName: root.isPlayingActive ? "pause" : "play_arrow"
                            containerColor: Theme.primary
                            contentColor: Theme.primaryText
                            tooltipText: root.isPlayingActive ? I18n.trFor("ambientSound", "Pause") : I18n.trFor("ambientSound", "Play")
                            onClicked: root.togglePlayPause()
                        }

                        // Master Volume Slider (in the center)
                        Item {
                            height: Theme.buttonHeightS
                            width: parent.width - playTransportBtn.width - sleepTimerBtn.width - parent.spacing * 2
                            anchors.verticalCenter: parent.verticalCenter

                            DSlider {
                                anchors.fill: parent
                                minimum: 0
                                maximum: 100
                                step: 5
                                size: "s"
                                value: root.masterVolume
                                showValue: true
                                unit: "%"
                                wheelEnabled: true
                                onSliderValueChanged: (v) => {
                                    if (v !== root.masterVolume)
                                        root.setMasterVolume(v);
                                }
                            }
                        }

                        // Sleep Timer Button
                        DIconButton {
                            id: sleepTimerBtn
                            size: "s"
                            variant: (root.timerOpen || root.isTimerActive) ? "filled" : "standard"
                            iconName: "timer"
                            containerColor: Theme.secondaryContainer
                            contentColor: Theme.onSecondaryContainer
                            anchors.verticalCenter: parent.verticalCenter
                            tooltipText: root.isTimerActive ? Math.ceil(root.timerRemainingMs / 60000) + "m left" : I18n.trFor("ambientSound", "Sleep Timer")
                            onClicked: root.timerOpen = !root.timerOpen
                        }
                    }
                }
            }
        }
    }
