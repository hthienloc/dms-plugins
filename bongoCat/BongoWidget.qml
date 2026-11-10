import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.X11
import qs.Common
import qs.DCommon.Widgets
import qs.Services
import qs.Modules.Plugins
import "./shared"
import "./services"


PluginComponent {
    id: root
    pluginId: "bongoCat"
    pluginService: PluginService

    readonly property bool showHints: pluginData.showHints ?? true

    readonly property bool isDock: root.surfaceContext?.kind === "dock"
    readonly property int effectiveIconSize: isDock ? Math.max(root.iconSize, Math.round(root.widgetThickness * 0.65)) : (root.iconSize > 0 ? Math.max(root.iconSize, 24) : 24)
    readonly property int effectiveTextSize: root.textSize > 0 ? root.textSize : Theme.fontSizeSmall

    pillRightClickAction: () => {
        root.forceSleep = !root.forceSleep;
        if (root.forceSleep) root.isWaiting = true;
    }


    property int catState: 0
    property bool leftWasLast: false
    property bool isBlinking: false
    property bool isWaiting: true
    property bool forceSleep: false
    onForceSleepChanged: {
        if (forceSleep) isWaiting = true;
    }

    property var deviceOptions: ["All Keyboards (Auto)"]
    property var deviceMap: ({ "All Keyboards (Auto)": "all" })
    readonly property string selectedDevicePath: (pluginData && pluginData.selectedDevicePath !== undefined ? pluginData.selectedDevicePath : "all")

    // Surface silent input-monitor failures (missing CLI tool / missing
    // input group) instead of leaving the cat motionless without a hint.
    readonly property bool inputToolMissing: inputListener.inputToolMissing
    readonly property bool notInInputGroup: inputListener.notInInputGroup
    readonly property bool inputBroken: inputListener.inputBroken
    readonly property string requiredTool: inputListener.requiredTool
    readonly property bool mouseBroken: mouseEnabled && selectedDevicePath !== "all" && mouseToolMissing
    readonly property bool mouseToolMissing: inputListener.mouseToolMissing

    onMouseEnabledChanged: {
        clearMouseState();
    }

    onSelectedDevicePathChanged: {
        console.log("[BongoCat] Device selection changed to:", selectedDevicePath);
        resetMetrics();
    }

    Timer {
        id: inputRestartTimer
        interval: 200
        onTriggered: inputProc.running = true
    }

    readonly property string selectedDeviceName: {
        for (let name in deviceMap) {
            if (deviceMap[name] === selectedDevicePath) return name;
        }
        return "All Keyboards (Auto)";
    }

    readonly property real catSize: ((pluginData && pluginData.catSizePercent !== undefined ? pluginData.catSizePercent : 100)) / 100.0
    readonly property int catYOffset: (pluginData && pluginData.catYOffset !== undefined ? pluginData.catYOffset : 0)
    readonly property bool enableBlinking: (pluginData && pluginData.enableBlinking !== undefined ? pluginData.enableBlinking : true)
    readonly property bool mouseEnabled: (pluginData && pluginData.mouseEnabled !== undefined ? pluginData.mouseEnabled : false)

    // --- Mouse interaction (roadmap item) ---
    // Keyboard, mouse buttons and scrolling each track their own paw state;
    // resolveCatState() merges them so no input source can clobber another
    // (e.g. releasing a key while a mouse button is still held).
    property int kbState: 0
    property int mouseState: 0
    property int scrollState: 0
    property bool scrollLeftWasLast: false
    property bool mouseLeftDown: false
    property bool mouseRightDown: false
    property bool mouseOtherDown: false

    function resolveCatState() {
        const states = [kbState, mouseState, scrollState].filter(s => s !== 0);
        if (states.length === 0) {
            catState = 0;
        } else if (states.indexOf(3) !== -1 || (states.indexOf(1) !== -1 && states.indexOf(2) !== -1)) {
            catState = 3;
        } else {
            catState = states[0];
        }
    }

    function updateMousePaws() {
        isWaiting = false;
        if ((mouseLeftDown && mouseRightDown) || mouseOtherDown) {
            mouseState = 3;
        } else if (mouseLeftDown) {
            mouseState = 1;
        } else if (mouseRightDown) {
            mouseState = 2;
        } else {
            mouseState = 0;
        }
        resolveCatState();
        waitingTimer.restart();
    }

    function clearMouseState() {
        mouseLeftDown = false;
        mouseRightDown = false;
        mouseOtherDown = false;
        mouseState = 0;
        scrollState = 0;
        scrollReleaseTimer.stop();
        resolveCatState();
    }

    function onMouseButton(buttonName, pressed) {
        if (pressed && soundOnMouse)
            playClick(false);
        if (buttonName === "BTN_LEFT") {
            mouseLeftDown = pressed;
        } else if (buttonName === "BTN_RIGHT") {
            mouseRightDown = pressed;
        } else {
            mouseOtherDown = pressed;
        }
        updateMousePaws();
    }

    function onScrollTick() {
        isWaiting = false;
        scrollReleaseTimer.restart();
        waitingTimer.restart();
        // Rate-limit the drumming so fast touchpad scrolling doesn't strobe
        if (scrollThrottle.running)
            return;
        scrollThrottle.restart();
        scrollLeftWasLast = !scrollLeftWasLast;
        scrollState = scrollLeftWasLast ? 1 : 2;
        resolveCatState();
    }

    Timer {
        id: scrollThrottle
        interval: 75
        repeat: false
    }

    Timer {
        id: scrollReleaseTimer
        interval: 150
        repeat: false
        onTriggered: {
            root.scrollState = 0;
            root.resolveCatState();
        }
    }

    function handlePointerLine(data) {
        if (data.includes("POINTER_BUTTON")) {
            const match = data.match(/(BTN_[A-Z0-9_]+)/);
            const name = match ? match[1] : "BTN_OTHER";
            if (data.includes("pressed")) {
                root.onMouseButton(name, true);
            } else if (data.includes("released")) {
                root.onMouseButton(name, false);
            }
        } else if (data.includes("POINTER_SCROLL")) {
            // Ignore scroll-stop events (zero on both axes)
            const vert = data.match(/vert\s+(-?\d+(?:\.\d+)?)/);
            const horiz = data.match(/horiz\s+(-?\d+(?:\.\d+)?)/);
            if (vert && horiz && parseFloat(vert[1]) === 0 && parseFloat(horiz[1]) === 0)
                return;
            root.onScrollTick();
        }
    }
    readonly property int waitingTimeout: ((pluginData && pluginData.waitingTimeout !== undefined ? pluginData.waitingTimeout : 5)) * 1000

    readonly property int pawHoldTime: (pluginData && pluginData.pawHoldTime !== undefined ? pluginData.pawHoldTime : 0)
    readonly property bool doubleSlam: (pluginData && pluginData.doubleSlam !== undefined ? pluginData.doubleSlam : true)
    readonly property bool classicIdle: (pluginData && pluginData.classicIdle !== undefined ? pluginData.classicIdle : false)
    // --- Cat color (roadmap: cat variants) ---
    // Permanent recolor of the cat. "classic" keeps the theme's default
    // black/white look, "primary" follows the system accent, "custom" uses a
    // user-picked hex. Migrated from the legacy boolean "activeColor".
    readonly property string catColorMode: {
        if (pluginData && pluginData.catColorMode !== undefined)
            return pluginData.catColorMode;
        // Legacy: the old on/off "Use Primary Color" toggle maps to primary.
        if (pluginData && pluginData.activeColor === true)
            return "primary";
        return "classic";
    }
    readonly property string catCustomColor: {
        const c = pluginData?.catCustomColor;
        if (!c) return "primary";
        if (typeof c === "string") return c;
        if (typeof c === "object" && c.hex) return String(c.hex);
        return "primary";
    }
    readonly property color resolvedCatColor: {
        if (root.classicIdle && root.isWaiting)
            return Theme.surfaceText;
        if (catColorMode === "primary")
            return Theme.primary;
        if (catColorMode === "custom")
            return catCustomColor === "primary" ? Theme.primary : Qt.color(catCustomColor);
        return Theme.surfaceText;
    }

    // Label/value mapping for the popout dropdown (DDropdown is label-based).
    // Both directions go through I18n.trFor("bongoCat", ) so they stay consistent per locale.
    readonly property var colorModeOptions: [I18n.trFor("bongoCat", "Classic B/W"), I18n.trFor("bongoCat", "Theme Primary"), I18n.trFor("bongoCat", "Custom")]
    function colorModeToLabel(m) {
        if (m === "primary") return I18n.trFor("bongoCat", "Theme Primary");
        if (m === "custom") return I18n.trFor("bongoCat", "Custom");
        return I18n.trFor("bongoCat", "Classic B/W");
    }
    function labelToColorMode(l) {
        if (l === I18n.trFor("bongoCat", "Theme Primary")) return "primary";
        if (l === I18n.trFor("bongoCat", "Custom")) return "custom";
        return "classic";
    }

    // --- Typing metrics (roadmap item) ---
    // Optional WPM + correction-rate overlay. Only keystroke *timing* is counted;
    // no key contents are ever stored or logged. Numbers are computed over a
    // sliding 60s window so they reflect recent typing, not the whole session.
    readonly property bool showMetrics: (pluginData && pluginData.showMetrics !== undefined ? pluginData.showMetrics : false)
    readonly property bool metricsInBar: (pluginData && pluginData.metricsInBar !== undefined ? pluginData.metricsInBar : false)
    readonly property int metricsWindowSec: (pluginData && pluginData.metricsWindowSec !== undefined ? pluginData.metricsWindowSec : 60)
    readonly property int metricsWindowMs: metricsWindowSec * 1000

    property int liveWpm: 0
    property int cleanPercent: 100
    // Plain timestamp buffers (ms). Read/written only in code, never in bindings.
    property var _charStamps: []
    property var _correctionStamps: []

    // Keys that produce no character and must not inflate WPM.
    readonly property var _nonCharKeys: ({
        "KEY_LEFTSHIFT": 1, "KEY_RIGHTSHIFT": 1, "KEY_LEFTCTRL": 1, "KEY_RIGHTCTRL": 1,
        "KEY_LEFTALT": 1, "KEY_RIGHTALT": 1, "KEY_LEFTMETA": 1, "KEY_RIGHTMETA": 1,
        "KEY_CAPSLOCK": 1, "KEY_NUMLOCK": 1, "KEY_SCROLLLOCK": 1,
        "KEY_ESC": 1, "KEY_ENTER": 1, "KEY_KPENTER": 1, "KEY_TAB": 1,
        "KEY_LEFT": 1, "KEY_RIGHT": 1, "KEY_UP": 1, "KEY_DOWN": 1,
        "KEY_HOME": 1, "KEY_END": 1, "KEY_PAGEUP": 1, "KEY_PAGEDOWN": 1, "KEY_INSERT": 1,
        "KEY_COMPOSE": 1, "KEY_MENU": 1, "KEY_SYSRQ": 1, "KEY_PAUSE": 1
    })

    // Returns "char" | "correction" | "ignore".
    function classifyKey(name) {
        if (name === "KEY_BACKSPACE" || name === "KEY_DELETE")
            return "correction";
        if (_nonCharKeys[name] || /^KEY_F\d+$/.test(name))
            return "ignore";
        return "char";
    }

    // Called on every key press. With --show-keycodes a real KEY_ name is
    // always present; an empty name means a non-key EV_KEY event (e.g. a mouse
    // BTN_ on a combo device), which must not count toward typing metrics.
    function recordKeystroke(keyName) {
        if (!showMetrics || !keyName)
            return;
        const kind = classifyKey(keyName);
        if (kind === "ignore")
            return;
        if (kind === "correction")
            _correctionStamps.push(Date.now());
        else
            _charStamps.push(Date.now());
    }

    function _pruneAndCompute() {
        const cutoff = Date.now() - metricsWindowMs;
        _charStamps = _charStamps.filter(t => t >= cutoff);
        _correctionStamps = _correctionStamps.filter(t => t >= cutoff);
        const chars = _charStamps.length;
        const corrections = _correctionStamps.length;
        // 5 chars = 1 word; scale the window count up to a per-minute rate.
        liveWpm = metricsWindowMs > 0 ? Math.round(chars / 5 * 60000 / metricsWindowMs) : 0;
        cleanPercent = (chars + corrections) > 0
            ? Math.round(100 * chars / (chars + corrections))
            : 100;
    }

    function resetMetrics() {
        _charStamps = [];
        _correctionStamps = [];
        liveWpm = 0;
        cleanPercent = 100;
    }

    onShowMetricsChanged: resetMetrics()
    // Widening the window would otherwise show a misleadingly low reading until
    // the (already-pruned) buffer refills; reset so it starts fresh.
    onMetricsWindowSecChanged: resetMetrics()

    Timer {
        id: metricsTicker
        interval: 1000
        repeat: true
        running: root.showMetrics && root.surfaceLive
        onTriggered: root._pruneAndCompute()
    }

    function saveSetting(key, value) {
        try {
            pluginService.savePluginData(pluginId, key, value);
            if (pluginData) pluginData[key] = value;
        } catch(e) {
            console.warn("[BongoCat] Failed to save setting:", key, e);
        }
    }

    FontLoader {
        id: bongoFont
        source: "./assets/bongocat-Regular.otf"
        onStatusChanged: {
            if (status === FontLoader.Error) {
                console.warn("[BongoCat] Failed to load font");
            }
        }
    }

    // --- Audio feedback (roadmap item): optional bongo-hit sounds ---
    // Playback lives in the BongoSoundService singleton so that on multi-monitor
    // setups (one widget instance per bar) a keypress plays a single click, not
    // one per monitor. Fired once per real key press — auto-repeat goes through
    // onKeyRepeat, so a held key clicks just once, like a real keyboard.
    readonly property bool soundEnabled: (pluginData && pluginData.soundEnabled !== undefined ? pluginData.soundEnabled : false)
    readonly property int soundVolume: (pluginData && pluginData.soundVolume !== undefined ? pluginData.soundVolume : 60)
    readonly property bool soundOnMouse: (pluginData && pluginData.soundOnMouse !== undefined ? pluginData.soundOnMouse : false)
    readonly property string soundProfile: (pluginData && pluginData.soundProfile !== undefined ? pluginData.soundProfile : "bongo")
    readonly property real _soundVol: Math.max(0, Math.min(1, soundVolume / 100))

    readonly property string catSkin: (pluginData && pluginData.catSkin !== undefined ? pluginData.catSkin : "classic")
    readonly property var skinOptions: [I18n.trFor("bongoCat", "Classic (Vector)"), I18n.trFor("bongoCat", "Pixel Doodle")]
    function skinToLabel(s) {
        if (s === "pixel") return I18n.trFor("bongoCat", "Pixel Doodle");
        return I18n.trFor("bongoCat", "Classic (Vector)");
    }
    function labelToSkin(l) {
        if (l === I18n.trFor("bongoCat", "Pixel Doodle")) return "pixel";
        return "classic";
    }

    readonly property string pixelSkinColor: (pluginData && pluginData.pixelSkinColor !== undefined ? pluginData.pixelSkinColor : "white")
    readonly property var pixelColorOptions: [
        I18n.trFor("bongoCat", "Classic White"),
        I18n.trFor("bongoCat", "Midnight Black"),
        I18n.trFor("bongoCat", "Ginger Orange"),
        I18n.trFor("bongoCat", "Calico"),
        I18n.trFor("bongoCat", "Siamese"),
        I18n.trFor("bongoCat", "Sakura Pink"),
        I18n.trFor("bongoCat", "Cyberpunk"),
        I18n.trFor("bongoCat", "Zombie")
    ]
    function pixelColorToLabel(c) {
        if (c === "black") return I18n.trFor("bongoCat", "Midnight Black");
        if (c === "orange") return I18n.trFor("bongoCat", "Ginger Orange");
        if (c === "calico") return I18n.trFor("bongoCat", "Calico");
        if (c === "siamese") return I18n.trFor("bongoCat", "Siamese");
        if (c === "pink") return I18n.trFor("bongoCat", "Sakura Pink");
        if (c === "cyberpunk") return I18n.trFor("bongoCat", "Cyberpunk");
        if (c === "zombie") return I18n.trFor("bongoCat", "Zombie");
        return I18n.trFor("bongoCat", "Classic White");
    }
    function labelToPixelColor(l) {
        if (l === I18n.trFor("bongoCat", "Midnight Black")) return "black";
        if (l === I18n.trFor("bongoCat", "Ginger Orange")) return "orange";
        if (l === I18n.trFor("bongoCat", "Calico")) return "calico";
        if (l === I18n.trFor("bongoCat", "Siamese")) return "siamese";
        if (l === I18n.trFor("bongoCat", "Sakura Pink")) return "pink";
        if (l === I18n.trFor("bongoCat", "Cyberpunk")) return "cyberpunk";
        if (l === I18n.trFor("bongoCat", "Zombie")) return "zombie";
        return "white";
    }

    readonly property string pixelSkinFolder: pixelSkinColor === "white" ? "pixel" : ("pixel_" + pixelSkinColor)

    readonly property var pixelSpriteMap: [
        "./assets/skins/" + pixelSkinFolder + "/idle@4x.png",
        "./assets/skins/" + pixelSkinFolder + "/left@4x.png",
        "./assets/skins/" + pixelSkinFolder + "/right@4x.png",
        "./assets/skins/" + pixelSkinFolder + "/both@4x.png"
    ]
    readonly property string pixelBlinkSprite: "./assets/skins/" + pixelSkinFolder + "/blink@4x.png"
    readonly property string pixelSleepSprite: "./assets/skins/" + pixelSkinFolder + "/sleep@4x.png"

    readonly property string activeSpriteSource: {
        if (root.forceSleep || root.isWaiting) return pixelSleepSprite;
        if (root.isBlinking && root.catState === 0) return pixelBlinkSprite;
        return pixelSpriteMap[root.catState] || pixelSpriteMap[0];
    }

    function playClick(isBigHit) {
        if (!soundEnabled || forceSleep)
            return;
        BongoSoundService.volume = _soundVol;
        BongoSoundService.soundProfile = soundProfile;
        BongoSoundService.play(isBigHit);
    }

    readonly property var glyphMap: ["bc", "dc", "ba", "da"]
    readonly property string currentCatGlyph: root.forceSleep ? root.sleepGlyph : (root.isWaiting ? root.sleepGlyph : (root.isBlinking && root.catState === 0 ? root.blinkGlyph : root.glyphMap[root.catState]))
    readonly property real catGlyphPixelSize: Math.round(root.effectiveIconSize * root.catSize)
    readonly property real vectorCatWidth: Math.round(root.catGlyphPixelSize * 2) - 1
    readonly property int iconSize: Theme.iconSizeSmall
    readonly property int padding: Theme.spacingS
    readonly property int spacing: Theme.spacingXS
    readonly property string blinkGlyph: "gh"
    readonly property string sleepGlyph: "ef"

    function onKeyPress(isBigHit) {
        isWaiting = false;
        playClick(isBigHit);
        let targetState;
        if (isBigHit) {
            targetState = 3;
        } else {
            if (kbState !== 0) {
                targetState = 3;
            } else {
                leftWasLast = !leftWasLast;
                targetState = leftWasLast ? 1 : 2;
            }
        }
        kbState = targetState;
        resolveCatState();
        waitingTimer.restart();
    }

    function onKeyRelease(isBigHit) {
        let targetState;
        if (isBigHit) {
            targetState = 0;
        } else {
            if (kbState === 3) {
                targetState = leftWasLast ? 1 : 2;
            } else {
                targetState = 0;
            }
        }
        if (root.pawHoldTime > 0) {
            pawHoldTimer.interval = root.pawHoldTime;
            pawHoldTimer.restart();
        } else {
            kbState = targetState;
            resolveCatState();
        }
    }

    function onKeyRepeat(isBigHit) {
        isWaiting = false;
        let targetState;
        if (kbState !== 0) {
            targetState = kbState;
        } else {
            if (isBigHit) {
                targetState = 3;
            } else {
                targetState = leftWasLast ? 1 : 2;
            }
        }
        kbState = targetState;
        resolveCatState();
        waitingTimer.restart();
    }

    Timer {
        id: waitingTimer
        interval: root.waitingTimeout
        onTriggered: {
            // Don't fall asleep while a mouse button is physically held
            if (root.mouseLeftDown || root.mouseRightDown || root.mouseOtherDown) {
                restart();
                return;
            }
            isWaiting = true;
        }
    }

    Timer {
        id: pawHoldTimer
        onTriggered: {
            if (kbState !== 0) {
                kbState = 0;
                resolveCatState();
            }
        }
    }

    Timer {
        id: blinkIntervalTimer
        interval: 6000 + Math.random() * 8000
        repeat: true
        running: root.enableBlinking && !root.isWaiting && !root.forceSleep && root.surfaceLive
        onTriggered: {
            interval = 6000 + Math.random() * 8000;
            isBlinking = true;
            blinkDurationTimer.start();
        }
    }

    Timer {
        id: blinkDurationTimer
        interval: 300
        onTriggered: isBlinking = false
    }

    function fetchDevices() {
        InputDeviceScanner.scanKeyboards("bongoCat.fetchDevices", (devices) => {
            let options = ["All Keyboards (Auto)"];
            let map = { "All Keyboards (Auto)": "all" };
            let seenPaths = new Set();
            seenPaths.add("all");

            for (let i = 0; i < devices.length; i++) {
                const name = devices[i].label;
                const path = devices[i].value;
                if (seenPaths.has(path)) continue;
                seenPaths.add(path);

                let uniqueName = name;
                let counter = 2;
                while (options.includes(uniqueName)) {
                    uniqueName = name + " (" + counter + ")";
                    counter++;
                }
                options.push(uniqueName);
                map[uniqueName] = path;
            }
            root.deviceOptions = options;
            root.deviceMap = map;
        });
    }

    // pluginData may still be empty when Component.onCompleted runs, so also
    // migrate whenever it (re)loads. migrateColorSetting() is idempotent.
    onPluginDataChanged: migrateColorSetting()
    Component.onCompleted: {
        fetchDevices();
        migrateColorSetting();
        // Instantiate the sound singleton up front so the WAVs are preloaded
        // and the first click isn't dropped while still loading.
        BongoSoundService.volume = _soundVol;
        BongoSoundService.soundProfile = soundProfile;
    }

    // One-time migration of the legacy boolean so the settings page and the
    // widget agree on the new tri-state color value.
    function migrateColorSetting() {
        if (pluginData && pluginData.catColorMode === undefined && pluginData.activeColor === true) {
            saveSetting("catColorMode", "primary");
        }
    }

    // Refresh devices when popout is triggered
    function triggerPopoutWithRefresh() {
        fetchDevices();
        root.triggerPopout();
    }

    InputEventListener {
        id: inputListener
        enabled: true
        selectedDevicePath: root.selectedDevicePath
        monitorMouse: root.mouseEnabled

        onKeyPressed: (keyName, keyCode) => {
            const isBigHit = root.doubleSlam && (keyName === "KEY_SPACE" || keyName === "KEY_ENTER" || keyName === "KEY_KPENTER");
            root.recordKeystroke(keyName);
            root.onKeyPress(isBigHit);
        }
        onKeyReleased: (keyName, keyCode) => {
            const isBigHit = root.doubleSlam && (keyName === "KEY_SPACE" || keyName === "KEY_ENTER" || keyName === "KEY_KPENTER");
            root.onKeyRelease(isBigHit);
        }
        onKeyRepeated: (keyName, keyCode) => {
            const isBigHit = root.doubleSlam && (keyName === "KEY_SPACE" || keyName === "KEY_ENTER" || keyName === "KEY_KPENTER");
            root.onKeyRepeat(isBigHit);
        }
        onRawLineReceived: line => {
            if (root.mouseEnabled && (line.includes("POINTER_BUTTON") || line.includes("POINTER_SCROLL"))) {
                root.handlePointerLine(line);
            }
        }
    }

    horizontalBarPill: Component {
        Item {
            implicitWidth: root.isDock && !(root.showMetrics && root.metricsInBar)
                ? root.effectiveIconSize
                : Math.max(root.effectiveIconSize, pillContent.implicitWidth + (root.isDock ? 0 : Theme.spacingS))
            implicitHeight: Math.max(root.effectiveIconSize, pillContent.implicitHeight)

            MouseArea {
                id: clickArea
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: mouse => {
                    if (mouse.button === Qt.RightButton) {
                        root.forceSleep = !root.forceSleep;
                        console.log("[BongoCat] Right click - forceSleep:", root.forceSleep);
                        if (root.forceSleep) root.isWaiting = true;
                    } else {
                        root.triggerPopoutWithRefresh();
                    }
                }
                onPressAndHold: mouse => {
                    if (mouse.button === Qt.RightButton) {
                        root.forceSleep = !root.forceSleep;
                        if (root.forceSleep) root.isWaiting = true;
                    }
                }
            }

            // Cat glyph plus an optional metrics readout. Grid switches between
            // side-by-side (horizontal bar) and stacked (vertical bar) so the
            // pill stays compact in either orientation.
            Grid {
                id: pillContent
                anchors.centerIn: parent
                columns: root.isVertical ? 1 : 2
                columnSpacing: Theme.spacingXS
                rowSpacing: 0
                horizontalItemAlignment: Grid.AlignHCenter
                verticalItemAlignment: Grid.AlignVCenter

                Item {
                    id: catContainer
                    width: root.catSkin === "pixel"
                        ? Math.round(root.effectiveIconSize * root.catSize * 1.25)
                        : root.vectorCatWidth
                    height: Math.round(root.effectiveIconSize * root.catSize)

                    Item {
                        id: catVectorItem
                        visible: root.catSkin !== "pixel"
                        anchors.centerIn: parent
                        width: parent.width
                        height: parent.height
                        opacity: root.forceSleep ? 0.5 : 1.0
                        transform: Translate { y: root.catYOffset }

                        Text {
                            id: leftCatHalf
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.right: parent.horizontalCenter
                            anchors.rightMargin: -1
                            font.family: bongoFont.name
                            font.pixelSize: root.catGlyphPixelSize
                            color: root.forceSleep ? Theme.surfaceVariantText : root.resolvedCatColor
                            text: root.currentCatGlyph.length > 0 ? root.currentCatGlyph.charAt(0) : ""
                        }

                        Text {
                            id: rightCatHalf
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.horizontalCenter
                            font.family: bongoFont.name
                            font.pixelSize: root.catGlyphPixelSize
                            color: root.forceSleep ? Theme.surfaceVariantText : root.resolvedCatColor
                            text: root.currentCatGlyph.length > 1 ? root.currentCatGlyph.charAt(1) : ""
                        }
                    }

                    Image {
                        id: catPixelSprite
                        visible: root.catSkin === "pixel"
                        anchors.centerIn: parent
                        width: parent.width
                        height: parent.height
                        fillMode: Image.PreserveAspectFit
                        smooth: false
                        mipmap: false
                        opacity: root.forceSleep ? 0.5 : 1.0
                        source: root.activeSpriteSource
                        transform: Translate { y: root.catYOffset }
                    }
                }

                StyledText {
                    visible: root.showMetrics && root.metricsInBar
                    text: root.liveWpm + " · " + root.cleanPercent + "%"
                    font.pixelSize: root.effectiveTextSize
                    color: root.forceSleep ? Theme.surfaceVariantText : Theme.surfaceText
                    opacity: root.forceSleep ? 0.5 : 1.0
                }
            }

            DIcon {
                visible: root.inputBroken
                name: "warning"
                size: Math.max(12, Math.round(root.effectiveIconSize * 0.6))
                color: Theme.error
                anchors.top: parent.top
                anchors.right: parent.right
            }
        }
    }

    verticalBarPill: horizontalBarPill

    popoutWidth: 320
    popoutHeight: 0 // auto from content

    popoutContent: Component {
        PopoutComponent {
            id: popout
            width: root.popoutWidth
            headerText: ""
            showCloseButton: false

            readonly property bool isActive: !root.isWaiting && !root.forceSleep

            Column {
                id: contentCol
                width: parent.width
                spacing: Theme.spacingM

                // Warning card (if input/tool broken)
                Rectangle {
                    width: parent.width
                    visible: root.inputBroken || root.mouseBroken
                    radius: M3E.outerR
                    color: Theme.errorContainer ?? Theme.errorHover
                    implicitHeight: warnCol.implicitHeight + Theme.spacingM * 2

                        Column {
                            id: warnCol
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.margins: Theme.spacingM
                            spacing: Theme.spacingXS

                            StyledText {
                                width: parent.width
                                visible: root.inputToolMissing
                                text: root.selectedDevicePath === "all"
                                    ? I18n.trFor("bongoCat", "The 'libinput' CLI was not found, so Auto mode can't see your keyboard. Install it (Arch: libinput-tools, Debian/Ubuntu: libinput-tools, Fedora: libinput-utils) or pick a specific keyboard below.")
                                    : I18n.trFor("bongoCat", "'evtest' was not found — install it to monitor a specific keyboard, or switch to Auto mode.")
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.onErrorContainer ?? Theme.error
                                wrapMode: Text.Wrap
                            }

                            StyledText {
                                width: parent.width
                                visible: root.notInInputGroup
                                text: I18n.trFor("bongoCat", "Your user is not in the 'input' group, so keyboard events can't be read. Run: sudo usermod -aG input $USER — then log out and back in.")
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.onErrorContainer ?? Theme.error
                                wrapMode: Text.Wrap
                            }

                            StyledText {
                                width: parent.width
                                visible: root.mouseBroken
                                text: I18n.trFor("bongoCat", "Mouse interaction needs the 'libinput' CLI — install it (Arch: libinput-tools, Debian/Ubuntu: libinput-tools, Fedora: libinput-utils) or switch the keyboard to Auto mode.")
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.onErrorContainer ?? Theme.error
                                wrapMode: Text.Wrap
                            }
                        }
                    }

                    // M3E Hero Card: Cat Display Stage
                    DCard {
                        id: catHeroStage
                        width: parent.width
                        height: 140
                        restRadius: Theme.cornerRadiusL
                        pad: 0
                        clipContent: true
                        color: (popout.isActive && root.catColorMode === "classic")
                            ? Theme.primaryContainer
                            : Theme.surfaceContainerHigh

                        Behavior on color {
                            ColorAnimation {
                                duration: M3E.effectsMs
                                easing.type: Easing.BezierSpline
                                easing.bezierCurve: M3E.curveEffects
                            }
                        }

                        // Gradient ambient depth
                        Rectangle {
                            anchors.fill: parent
                            gradient: Gradient {
                                GradientStop { position: 0.0; color: "transparent" }
                                GradientStop { position: 1.0; color: Theme.withAlpha(Theme.shadowColor ?? "#000000", 0.12) }
                            }
                        }

                        // The Big Cat
                        Item {
                            anchors.centerIn: parent
                            width: root.catSkin === "pixel" ? 140 : bigCatText.implicitWidth
                            height: root.catSkin === "pixel" ? 110 : bigCatText.implicitHeight
                            scale: popout.isActive ? 1.0 : 0.94

                            Behavior on scale {
                                NumberAnimation {
                                    duration: M3E.spatialFastMs
                                    easing.type: Easing.BezierSpline
                                    easing.bezierCurve: M3E.curveFastSpatial
                                }
                            }

                            Text {
                                id: bigCatText
                                visible: root.catSkin !== "pixel"
                                anchors.centerIn: parent
                                font.family: bongoFont.name
                                font.pixelSize: Theme.fontSizeXLarge * 4
                                font.letterSpacing: -2
                                color: root.catColorMode === "classic"
                                    ? (popout.isActive ? Theme.onPrimaryContainer : Theme.surfaceText)
                                    : root.resolvedCatColor
                                text: root.forceSleep
                                    ? root.sleepGlyph
                                    : (!popout.isActive ? root.sleepGlyph : (root.isBlinking && root.catState === 0 ? root.blinkGlyph : root.glyphMap[root.catState]))
                            }

                            Image {
                                id: bigCatPixel
                                visible: root.catSkin === "pixel"
                                anchors.centerIn: parent
                                width: parent.width
                                height: parent.height
                                fillMode: Image.PreserveAspectFit
                                smooth: false
                                mipmap: false
                                source: root.activeSpriteSource
                            }
                        }

                        // Interactive sleep toggle chip on hero top-right
                        Rectangle {
                            anchors.top: parent.top
                            anchors.right: parent.right
                            anchors.margins: Theme.spacingS
                            width: sleepChipRow.implicitWidth + Theme.spacingS * 2
                            height: 28
                            radius: height / 2
                            color: root.forceSleep ? Theme.primary : Theme.withAlpha(Theme.surface, 0.45)

                            Row {
                                id: sleepChipRow
                                anchors.centerIn: parent
                                spacing: 4
                                DIcon {
                                    name: root.forceSleep ? "bedtime" : "wb_sunny"
                                    size: 14
                                    color: root.forceSleep ? Theme.onPrimary : Theme.surfaceText
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                StyledText {
                                    text: root.forceSleep ? I18n.trFor("bongoCat", "Asleep") : I18n.trFor("bongoCat", "Awake")
                                    font.pixelSize: Theme.fontSizeExtraSmall
                                    font.weight: Font.Medium
                                    color: root.forceSleep ? Theme.onPrimary : Theme.surfaceText
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.forceSleep = !root.forceSleep
                            }
                        }
                    }

                    // M3E Metric Tiles (WPM & Cleanliness)
                    Row {
                        width: parent.width
                        visible: root.showMetrics
                        spacing: Theme.groupedListGap

                        DCard {
                            id: wpmTile
                            width: (parent.width - Theme.groupedListGap) / 2
                            height: 60
                            pad: 0
                            topLeftRadius: Theme.groupedListOuterRadius
                            bottomLeftRadius: Theme.groupedListOuterRadius
                            topRightRadius: Theme.groupedListInnerRadius
                            bottomRightRadius: Theme.groupedListInnerRadius
                            color: Theme.surfaceContainerHigh

                            Column {
                                anchors.centerIn: parent
                                spacing: 1
                                NumericText {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: String(root.liveWpm)
                                    font.features: ({ "tnum": 1 })
                                    font.pixelSize: Theme.fontSizeLarge
                                    font.weight: Font.Bold
                                    color: Theme.primary
                                }
                                StyledText {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: "WPM"
                                    font.pixelSize: Theme.fontSizeExtraSmall
                                    font.weight: Font.Medium
                                    color: Theme.surfaceVariantText
                                }
                            }
                        }

                        DCard {
                            id: cleanTile
                            width: (parent.width - Theme.groupedListGap) / 2
                            height: 60
                            pad: 0
                            topLeftRadius: Theme.groupedListInnerRadius
                            bottomLeftRadius: Theme.groupedListInnerRadius
                            topRightRadius: Theme.groupedListOuterRadius
                            bottomRightRadius: Theme.groupedListOuterRadius
                            color: Theme.surfaceContainerHigh

                            Column {
                                anchors.centerIn: parent
                                spacing: 1
                                NumericText {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: root.cleanPercent + "%"
                                    font.features: ({ "tnum": 1 })
                                    font.pixelSize: Theme.fontSizeLarge
                                    font.weight: Font.Bold
                                    color: Theme.primary
                                }
                                StyledText {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: "Clean"
                                    font.pixelSize: Theme.fontSizeExtraSmall
                                    font.weight: Font.Medium
                                    color: Theme.surfaceVariantText
                                }
                            }
                        }
                    }

                    // M3E Connected Settings Card Stack
                    Column {
                        width: parent.width
                        spacing: Theme.groupedListGap

                        // Row 1: Device Selector Card
                        DCard {
                            width: parent.width
                            height: 48
                            pad: 0
                            topLeftRadius: Theme.groupedListOuterRadius
                            topRightRadius: Theme.groupedListOuterRadius
                            bottomLeftRadius: Theme.groupedListInnerRadius
                            bottomRightRadius: Theme.groupedListInnerRadius
                            color: Theme.surfaceContainerHigh

                            Row {
                                anchors.fill: parent
                                anchors.leftMargin: Theme.spacingM
                                anchors.rightMargin: Theme.spacingM
                                spacing: Theme.spacingS

                                DIcon {
                                    name: "keyboard"
                                    size: Theme.iconSizeSmall
                                    color: Theme.primary
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                DDropdown {
                                    id: keyboardDropdown
                                    width: parent.width - Theme.iconSizeSmall - Theme.spacingS
                                    options: root.deviceOptions
                                    currentValue: root.selectedDeviceName
                                    maxPopupHeight: 200
                                    compactMode: true
                                    anchors.verticalCenter: parent.verticalCenter
                                    onValueChanged: v => root.saveSetting("selectedDevicePath", root.deviceMap[v])
                                }
                            }
                        }

                        // Row 2: Skin Selector Card
                        DCard {
                            width: parent.width
                            height: 48
                            pad: 0
                            topLeftRadius: Theme.groupedListInnerRadius
                            topRightRadius: Theme.groupedListInnerRadius
                            bottomLeftRadius: Theme.groupedListInnerRadius
                            bottomRightRadius: Theme.groupedListInnerRadius
                            color: Theme.surfaceContainerHigh

                            Row {
                                anchors.fill: parent
                                anchors.leftMargin: Theme.spacingM
                                anchors.rightMargin: Theme.spacingM
                                spacing: Theme.spacingS

                                DIcon {
                                    name: "pets"
                                    size: Theme.iconSizeSmall
                                    color: Theme.primary
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                DDropdown {
                                    id: skinDropdown
                                    width: parent.width - Theme.iconSizeSmall - Theme.spacingS
                                    options: root.skinOptions
                                    currentValue: root.skinToLabel(root.catSkin)
                                    maxPopupHeight: 200
                                    compactMode: true
                                    anchors.verticalCenter: parent.verticalCenter
                                    onValueChanged: v => root.saveSetting("catSkin", root.labelToSkin(v))
                                }
                            }
                        }

                        // Row 3: Cat Color Mode & Swatch (Vector skin only)
                        DCard {
                            width: parent.width
                            height: 48
                            pad: 0
                            visible: root.catSkin !== "pixel"
                            topLeftRadius: Theme.groupedListInnerRadius
                            topRightRadius: Theme.groupedListInnerRadius
                            bottomLeftRadius: Theme.groupedListInnerRadius
                            bottomRightRadius: Theme.groupedListInnerRadius
                            color: Theme.surfaceContainerHigh

                            Row {
                                anchors.fill: parent
                                anchors.leftMargin: Theme.spacingM
                                anchors.rightMargin: Theme.spacingM
                                spacing: Theme.spacingS

                                DIcon {
                                    name: "palette"
                                    size: Theme.iconSizeSmall
                                    color: Theme.primary
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                DDropdown {
                                    id: colorModeDropdown
                                    width: parent.width - Theme.iconSizeSmall - Theme.spacingS - (customSwatch.visible ? 36 + Theme.spacingS : 0)
                                    options: root.colorModeOptions
                                    currentValue: root.colorModeToLabel(root.catColorMode)
                                    maxPopupHeight: 200
                                    compactMode: true
                                    anchors.verticalCenter: parent.verticalCenter
                                    onValueChanged: v => root.saveSetting("catColorMode", root.labelToColorMode(v))
                                }

                                Rectangle {
                                    id: customSwatch
                                    visible: root.catColorMode === "custom"
                                    width: 36
                                    height: 28
                                    radius: Theme.cornerRadiusXS
                                    anchors.verticalCenter: parent.verticalCenter
                                    color: root.catCustomColor === "primary" ? Theme.primary : Qt.color(root.catCustomColor)
                                    border.color: Theme.outline
                                    border.width: 1

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (typeof PopoutService !== "undefined" && PopoutService && PopoutService.colorPickerModal) {
                                                const widget = root;
                                                PopoutService.colorPickerModal.selectedColor = root.catCustomColor === "primary" ? Theme.primary : Qt.color(root.catCustomColor);
                                                PopoutService.colorPickerModal.pickerTitle = I18n.trFor("bongoCat", "Cat Color");
                                                PopoutService.colorPickerModal.onColorSelectedCallback = function(selectedColor) {
                                                    widget.saveSetting("catCustomColor", selectedColor.toString());
                                                };
                                                PopoutService.colorPickerModal.show();
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // Row 3 (alt): Pixel Cat Color (Pixel Doodle skin only)
                        DCard {
                            width: parent.width
                            height: 48
                            pad: 0
                            visible: root.catSkin === "pixel"
                            topLeftRadius: Theme.groupedListInnerRadius
                            topRightRadius: Theme.groupedListInnerRadius
                            bottomLeftRadius: Theme.groupedListInnerRadius
                            bottomRightRadius: Theme.groupedListInnerRadius
                            color: Theme.surfaceContainerHigh

                            Row {
                                anchors.fill: parent
                                anchors.leftMargin: Theme.spacingM
                                anchors.rightMargin: Theme.spacingM
                                spacing: Theme.spacingS

                                DIcon {
                                    name: "palette"
                                    size: Theme.iconSizeSmall
                                    color: Theme.primary
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                DDropdown {
                                    id: pixelColorDropdown
                                    width: parent.width - Theme.iconSizeSmall - Theme.spacingS
                                    options: root.pixelColorOptions
                                    currentValue: root.pixelColorToLabel(root.pixelSkinColor)
                                    maxPopupHeight: 200
                                    compactMode: true
                                    anchors.verticalCenter: parent.verticalCenter
                                    onValueChanged: v => root.saveSetting("pixelSkinColor", root.labelToPixelColor(v))
                                }
                            }
                        }

                        // Row 3: Sliders Group Card (Cat Size, Sleep Timeout, Paw Hold)
                        DCard {
                            width: parent.width
                            implicitHeight: sliderRowsCol.implicitHeight + Theme.spacingM * 2
                            pad: 0
                            topLeftRadius: Theme.groupedListInnerRadius
                            topRightRadius: Theme.groupedListInnerRadius
                            bottomLeftRadius: Theme.groupedListOuterRadius
                            bottomRightRadius: Theme.groupedListOuterRadius
                            color: Theme.surfaceContainerHigh

                            Column {
                                id: sliderRowsCol
                                anchors.fill: parent
                                anchors.margins: Theme.spacingM
                                spacing: Theme.spacingM

                                // Size Slider
                                Row {
                                    width: parent.width
                                    height: 36
                                    spacing: Theme.spacingS

                                    DIcon {
                                        name: "aspect_ratio"
                                        size: Theme.iconSizeSmall
                                        color: Theme.primary
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                    StyledText {
                                        text: I18n.trFor("bongoCat", "Size")
                                        font.pixelSize: Theme.fontSizeSmall
                                        color: Theme.surfaceText
                                        width: 44
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                    DSlider {
                                        id: sizeSlider
                                        width: parent.width - 44 - Theme.iconSizeSmall - 24 - Theme.spacingS * 3
                                        value: root.catSize * 100
                                        minimum: 50
                                        maximum: 200
                                        centerMinimum: false
                                        unit: "%"
                                        showValue: true
                                        onSliderValueChanged: v => root.saveSetting("catSizePercent", v)
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                    Item {
                                        width: 24
                                        height: 24
                                        anchors.verticalCenter: parent.verticalCenter

                                        DIcon {
                                            anchors.centerIn: parent
                                            name: "restore"
                                            size: 16
                                            color: Theme.primary
                                            opacity: (root.catSize * 100) !== 100 ? 0.9 : 0.25
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            enabled: (root.catSize * 100) !== 100
                                            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                            onClicked: {
                                                root.saveSetting("catSizePercent", 100);
                                                sizeSlider.value = 100;
                                            }
                                        }
                                    }
                                }

                                // Sleep Timeout Slider
                                Row {
                                    width: parent.width
                                    height: 36
                                    spacing: Theme.spacingS

                                    DIcon {
                                        name: "bedtime"
                                        size: Theme.iconSizeSmall
                                        color: Theme.primary
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                    StyledText {
                                        text: I18n.trFor("bongoCat", "Sleep")
                                        font.pixelSize: Theme.fontSizeSmall
                                        color: Theme.surfaceText
                                        width: 44
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                    DSlider {
                                        id: sleepSlider
                                        width: parent.width - 44 - Theme.iconSizeSmall - 24 - Theme.spacingS * 3
                                        value: root.waitingTimeout / 1000
                                        minimum: 1
                                        maximum: 10
                                        centerMinimum: false
                                        unit: "s"
                                        showValue: true
                                        onSliderValueChanged: v => root.saveSetting("waitingTimeout", v)
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                    Item {
                                        width: 24
                                        height: 24
                                        anchors.verticalCenter: parent.verticalCenter

                                        DIcon {
                                            anchors.centerIn: parent
                                            name: "restore"
                                            size: 16
                                            color: Theme.primary
                                            opacity: (root.waitingTimeout / 1000) !== 5 ? 0.9 : 0.25
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            enabled: (root.waitingTimeout / 1000) !== 5
                                            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                            onClicked: {
                                                root.saveSetting("waitingTimeout", 5);
                                                sleepSlider.value = 5;
                                            }
                                        }
                                    }
                                }

                                // Paw Hold Slider
                                Row {
                                    width: parent.width
                                    height: 36
                                    spacing: Theme.spacingS

                                    DIcon {
                                        name: "timer"
                                        size: Theme.iconSizeSmall
                                        color: Theme.primary
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                    StyledText {
                                        text: I18n.trFor("bongoCat", "Paw")
                                        font.pixelSize: Theme.fontSizeSmall
                                        color: Theme.surfaceText
                                        width: 44
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                    DSlider {
                                        id: pawHoldSlider
                                        width: parent.width - 44 - Theme.iconSizeSmall - 24 - Theme.spacingS * 3
                                        value: root.pawHoldTime
                                        minimum: 0
                                        maximum: 100
                                        centerMinimum: false
                                        unit: "ms"
                                        showValue: true
                                        onSliderValueChanged: v => root.saveSetting("pawHoldTime", v)
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                    Item {
                                        width: 24
                                        height: 24
                                        anchors.verticalCenter: parent.verticalCenter

                                        DIcon {
                                            anchors.centerIn: parent
                                            name: "restore"
                                            size: 16
                                            color: Theme.primary
                                            opacity: root.pawHoldTime !== 0 ? 0.9 : 0.25
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            enabled: root.pawHoldTime !== 0
                                            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                            onClicked: {
                                                root.saveSetting("pawHoldTime", 0);
                                                pawHoldSlider.value = 0;
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // M3E Segmented Pill Action Strip for Quick Toggles
                    DCard {
                        width: parent.width
                        height: 38
                        pad: 0
                        color: "transparent"
                        border.width: 0

                        Row {
                            width: parent.width
                            spacing: Theme.groupedListGap

                            // Blink Toggle Pill
                            DCard {
                                id: blinkBtn
                                width: (parent.width - Theme.groupedListGap * 2) / 3
                                height: 38
                                pad: 0
                                topLeftRadius: Theme.groupedListOuterRadius
                                bottomLeftRadius: Theme.groupedListOuterRadius
                                topRightRadius: Theme.groupedListInnerRadius
                                bottomRightRadius: Theme.groupedListInnerRadius
                                color: root.enableBlinking ? Theme.primaryContainer : (blinkArea.containsMouse ? Theme.surfaceContainerHighest : Theme.surfaceContainerHigh)

                                Row {
                                    anchors.centerIn: parent
                                    spacing: 4
                                    DIcon {
                                        name: root.enableBlinking ? "visibility" : "visibility_off"
                                        size: 16
                                        color: root.enableBlinking ? Theme.onPrimaryContainer : Theme.surfaceVariantText
                                    }
                                    StyledText {
                                        text: I18n.trFor("bongoCat", "Blink")
                                        font.pixelSize: Theme.fontSizeSmall
                                        font.weight: root.enableBlinking ? Font.Bold : Font.Normal
                                        color: root.enableBlinking ? Theme.onPrimaryContainer : Theme.surfaceText
                                    }
                                }

                                MouseArea {
                                    id: blinkArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.saveSetting("enableBlinking", !root.enableBlinking)
                                }
                            }

                            // Sound Toggle Pill
                            DCard {
                                id: soundBtn
                                width: (parent.width - Theme.groupedListGap * 2) / 3
                                height: 38
                                pad: 0
                                topLeftRadius: Theme.groupedListInnerRadius
                                bottomLeftRadius: Theme.groupedListInnerRadius
                                topRightRadius: Theme.groupedListInnerRadius
                                bottomRightRadius: Theme.groupedListInnerRadius
                                color: root.soundEnabled ? Theme.primaryContainer : (soundArea.containsMouse ? Theme.surfaceContainerHighest : Theme.surfaceContainerHigh)

                                Row {
                                    anchors.centerIn: parent
                                    spacing: 4
                                    DIcon {
                                        name: root.soundEnabled ? "volume_up" : "volume_off"
                                        size: 16
                                        color: root.soundEnabled ? Theme.onPrimaryContainer : Theme.surfaceVariantText
                                    }
                                    StyledText {
                                        text: I18n.trFor("bongoCat", "Sound")
                                        font.pixelSize: Theme.fontSizeSmall
                                        font.weight: root.soundEnabled ? Font.Bold : Font.Normal
                                        color: root.soundEnabled ? Theme.onPrimaryContainer : Theme.surfaceText
                                    }
                                }

                                MouseArea {
                                    id: soundArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.saveSetting("soundEnabled", !root.soundEnabled)
                                }
                            }

                            // Metrics Toggle Pill
                            DCard {
                                id: metricsBtn
                                width: (parent.width - Theme.groupedListGap * 2) / 3
                                height: 38
                                pad: 0
                                topRightRadius: Theme.groupedListOuterRadius
                                bottomRightRadius: Theme.groupedListOuterRadius
                                topLeftRadius: Theme.groupedListInnerRadius
                                bottomLeftRadius: Theme.groupedListInnerRadius
                                color: root.showMetrics ? Theme.primaryContainer : (metricsArea.containsMouse ? Theme.surfaceContainerHighest : Theme.surfaceContainerHigh)

                                Row {
                                    anchors.centerIn: parent
                                    spacing: 4
                                    DIcon {
                                        name: "speed"
                                        size: 16
                                        color: root.showMetrics ? Theme.onPrimaryContainer : Theme.surfaceVariantText
                                    }
                                    StyledText {
                                        text: I18n.trFor("bongoCat", "Stats")
                                        font.pixelSize: Theme.fontSizeSmall
                                        font.weight: root.showMetrics ? Font.Bold : Font.Normal
                                        color: root.showMetrics ? Theme.onPrimaryContainer : Theme.surfaceText
                                    }
                                }

                                MouseArea {
                                    id: metricsArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.saveSetting("showMetrics", !root.showMetrics)
                                }
                            }
                        }
                    }

                    // Hint Item
                    HintSection {
                        width: parent.width
                        showHints: root.showHints

                        HintItem {
                            icon: "mouse"
                            text: I18n.trFor("bongoCat", "Right-click bar icon to toggle sleep mode.")
                        }
                    }
                }
        }
    }
}
