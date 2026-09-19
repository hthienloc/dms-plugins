import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.X11
import Quickshell.Wayland
import qs.Common
import qs.Widgets
import qs.Services
import qs.Modules.Plugins
import "./dms-common"
import "./services"


PluginComponent {
    id: root
    pluginId: "bongoCat"
    pluginService: PluginService

    readonly property bool showHints: pluginData.showHints ?? true


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
    property bool inputToolMissing: false
    property bool notInInputGroup: false
    readonly property bool inputBroken: inputToolMissing || notInInputGroup
    readonly property string requiredTool: selectedDevicePath === "all" ? "libinput" : "evtest"

    onRequiredToolChanged: {
        toolCheck.running = false;
        toolCheck.running = true;
        clearMouseState();
        refreshMouseToolCheck();
    }

    Process {
        id: toolCheck
        command: ["sh", "-c", "command -v " + root.requiredTool + " >/dev/null 2>&1"]
        running: true
        onExited: (exitCode, exitStatus) => {
            root.inputToolMissing = (exitCode !== 0);
        }
    }

    // When a specific keyboard is selected, its evtest stream contains no
    // mouse events — those still come from libinput.
    readonly property bool mouseBroken: mouseEnabled && selectedDevicePath !== "all" && mouseToolMissing
    property bool mouseToolMissing: false

    onMouseEnabledChanged: {
        clearMouseState();
        refreshMouseToolCheck();
    }

    function refreshMouseToolCheck() {
        if (mouseEnabled && selectedDevicePath !== "all") {
            mouseToolCheck.running = false;
            mouseToolCheck.running = true;
        }
    }

    Process {
        id: mouseToolCheck
        command: ["sh", "-c", "command -v libinput >/dev/null 2>&1"]
        running: true
        onExited: (exitCode, exitStatus) => {
            root.mouseToolMissing = (exitCode !== 0);
        }
    }

    Process {
        id: mouseProc
        command: ["libinput", "debug-events"]
        running: root.mouseEnabled && root.selectedDevicePath !== "all" && !root.mouseToolMissing

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => {
                if (data.includes("POINTER_BUTTON") || data.includes("POINTER_SCROLL")) {
                    root.handlePointerLine(data);
                }
            }
        }

        stderr: StdioCollector {}
    }

    Process {
        id: groupCheck
        command: ["sh", "-c", "id -nG | tr ' ' '\n' | grep -qx input"]
        running: true
        onExited: (exitCode, exitStatus) => {
            root.notInInputGroup = (exitCode !== 0);
        }
    }
    onSelectedDevicePathChanged: {
        console.log("[BongoCat] Device selection changed to:", selectedDevicePath);
        inputProc.running = false;
        inputRestartTimer.restart();
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
    readonly property string catCustomColor: (pluginData && pluginData.catCustomColor)
        ? pluginData.catCustomColor : "primary"
    readonly property color resolvedCatColor: {
        if (root.classicIdle && root.isWaiting)
            return Theme.surfaceText;
        if (catColorMode === "primary")
            return Theme.primary;
        if (catColorMode === "custom")
            return catCustomColor === "primary" ? Theme.primary : Qt.color(catCustomColor);
        return Theme.surfaceText;
    }

    // Label/value mapping for the popout dropdown (DankDropdown is label-based).
    // Both directions go through I18n.tr() so they stay consistent per locale.
    readonly property var colorModeOptions: [I18n.tr("Classic B/W"), I18n.tr("Theme Primary"), I18n.tr("Custom")]
    function colorModeToLabel(m) {
        if (m === "primary") return I18n.tr("Theme Primary");
        if (m === "custom") return I18n.tr("Custom");
        return I18n.tr("Classic B/W");
    }
    function labelToColorMode(l) {
        if (l === I18n.tr("Theme Primary")) return "primary";
        if (l === I18n.tr("Custom")) return "custom";
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
        running: root.showMetrics
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

    function playClick(isBigHit) {
        if (!soundEnabled || forceSleep)
            return;
        BongoSoundService.volume = _soundVol;
        BongoSoundService.soundProfile = soundProfile;
        BongoSoundService.play(isBigHit);
    }

    readonly property var glyphMap: ["bc", "dc", "ba", "da"]
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
        running: root.enableBlinking && !root.isWaiting
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
        // Devices whose lowercase name matches this regex are always included,
        // even if they would otherwise be filtered by the exclude list.
        const includePattern = "kanata";

        const excludePattern = [
            "power button", "video bus", "speaker", "headphone",
            "lid switch", "touchpad", "extra buttons", "uinput",
            "server", "hitune", "inphic", "instant"
        ].join("|");

        const awkScript = `
            /^N: Name=/ {
                name = $0
                sub(/^N: Name="/, "", name)
                sub(/"$/, "", name)
            }
            /^H: Handlers=/ {
                lower = tolower(name)
                include = (lower ~ /${includePattern}/)
                exclude = (lower ~ /${excludePattern}/)
                if ($0 ~ /kbd/ && (include || ($0 !~ /mouse/ && !exclude))) {
                    for (i = 1; i <= NF; i++) {
                        if ($i ~ /^event[0-9]+$/) {
                            print name "|/dev/input/" $i
                            next
                        }
                    }
                }
            }
        `;
        const cmd = `awk '${awkScript}' /proc/bus/input/devices`;
        
        Proc.runCommand("bongoCat.fetchDevices", ["bash", "-c", cmd], (stdout, exitCode) => {
            if (exitCode !== 0) return;
            const output = stdout.trim();
            if (!output) return;

            let options = ["All Keyboards (Auto)"];
            let map = { "All Keyboards (Auto)": "all" };
            let seenPaths = new Set();
            seenPaths.add("all");

            output.split("\n").forEach(line => {
                const parts = line.split("|");
                if (parts.length === 2) {
                    const name = parts[0].trim();
                    const path = parts[1].trim();
                    if (seenPaths.has(path)) return;
                    seenPaths.add(path);

                    let uniqueName = name;
                    let i = 2;
                    while (options.includes(uniqueName)) {
                        uniqueName = name + " (" + i + ")";
                        i++;
                    }
                    options.push(uniqueName);
                    map[uniqueName] = path;
                }
            });
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

    Process {
        id: inputProc
        command: {
            // --show-keycodes makes libinput emit real key names (otherwise masked
            // as "***"), which lets us classify keystrokes for metrics and detect
            // big-hit keys in Auto mode.
            const cmd = selectedDevicePath === "all"
                ? ["libinput", "debug-events", "--show-keycodes"]
                : ["evtest", selectedDevicePath];
            console.log("[BongoCat] Starting input process with command:", JSON.stringify(cmd));
            return cmd;
        }
        running: true

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => {
                if (data.includes("EV_KEY")) {
                    const keyMatch = data.match(/(KEY_[A-Z0-9_]+)/);
                    const keyName = keyMatch ? keyMatch[1] : "";
                    const isBigHit = root.doubleSlam && (keyName === "KEY_SPACE" || keyName === "KEY_ENTER" || keyName === "KEY_KPENTER");
                    if (data.includes("value 1")) {
                        root.recordKeystroke(keyName);
                        root.onKeyPress(isBigHit);
                    } else if (data.includes("value 0")) {
                        root.onKeyRelease(isBigHit);
                    } else if (data.includes("value 2")) {
                        root.onKeyRepeat(isBigHit);
                    }
                } else if (root.mouseEnabled && (data.includes("POINTER_BUTTON") || data.includes("POINTER_SCROLL"))) {
                    root.handlePointerLine(data);
                } else if (data.includes("KEYBOARD_KEY")) {
                    const keyMatch = data.match(/(KEY_[A-Z0-9_]+)/);
                    const keyName = keyMatch ? keyMatch[1] : "";
                    const isBigHit = root.doubleSlam && (keyName === "KEY_SPACE" || keyName === "KEY_ENTER" || keyName === "KEY_KPENTER");
                    if (data.includes("pressed")) {
                        root.recordKeystroke(keyName);
                        root.onKeyPress(isBigHit);
                    } else if (data.includes("released")) {
                        root.onKeyRelease(isBigHit);
                    } else if (data.includes("repeat")) {
                        root.onKeyRepeat(isBigHit);
                    }
                }
            }
        }

        stderr: StdioCollector {}

        onExited: exitCode => {
            if (exitCode !== 0) {
                console.warn("[BongoCat] evtest failed. Error code:", exitCode);
            }
        }
    }

    horizontalBarPill: Component {
        Item {
            implicitWidth: pillContent.implicitWidth + Theme.spacingS
            implicitHeight: Math.max(Theme.iconSize, pillContent.implicitHeight)

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

                Text {
                    id: catLabel
                    font.family: bongoFont.name
                    font.pixelSize: 24 * root.catSize
                    color: root.forceSleep ? Theme.surfaceVariantText : root.resolvedCatColor
                    opacity: root.forceSleep ? 0.5 : 1.0
                    text: root.forceSleep ? root.sleepGlyph : (root.isWaiting ? root.sleepGlyph : (root.isBlinking && root.catState === 0 ? root.blinkGlyph : root.glyphMap[root.catState]))
                    transform: Translate { y: root.catYOffset }
                }

                StyledText {
                    visible: root.showMetrics && root.metricsInBar
                    text: root.liveWpm + " · " + root.cleanPercent + "%"
                    font.pixelSize: Theme.fontSizeSmall
                    color: root.forceSleep ? Theme.surfaceVariantText : Theme.surfaceText
                    opacity: root.forceSleep ? 0.5 : 1.0
                }
            }

            DankIcon {
                visible: root.inputBroken
                name: "warning"
                size: 11
                color: Theme.error
                anchors.top: parent.top
                anchors.right: parent.right
            }
        }
    }

    verticalBarPill: horizontalBarPill

    popoutWidth: 280
    popoutHeight: 450

    popoutContent: Component {
        PopoutComponent {
            id: popout
            width: root.popoutWidth
            headerText: "Bongo Cat"
            showCloseButton: true

            readonly property bool isActive: !root.isWaiting && !root.forceSleep

            Column {
                width: parent.width
                spacing: Theme.spacingL

                Rectangle {
                    width: parent.width
                    visible: root.inputBroken || root.mouseBroken
                    radius: Theme.cornerRadius
                    color: Theme.errorHover
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
                                ? I18n.tr("The 'libinput' CLI was not found, so Auto mode can't see your keyboard. Install it (Arch: libinput-tools, Debian/Ubuntu: libinput-tools, Fedora: libinput-utils) or pick a specific keyboard below.")
                                : I18n.tr("'evtest' was not found — install it to monitor a specific keyboard, or switch to Auto mode.")
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.error
                            wrapMode: Text.Wrap
                        }

                        StyledText {
                            width: parent.width
                            visible: root.notInInputGroup
                            text: I18n.tr("Your user is not in the 'input' group, so keyboard events can't be read. Run: sudo usermod -aG input $USER — then log out and back in.")
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.error
                            wrapMode: Text.Wrap
                        }

                        StyledText {
                            width: parent.width
                            visible: root.mouseBroken
                            text: I18n.tr("Mouse interaction needs the 'libinput' CLI — install it (Arch: libinput-tools, Debian/Ubuntu: libinput-tools, Fedora: libinput-utils) or switch the keyboard to Auto mode.")
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.error
                            wrapMode: Text.Wrap
                        }
                    }
                }

                StyledRect {
                    width: parent.width
                    height: 140
                    radius: Theme.cornerRadius
                    color: (popout.isActive && root.catColorMode === "classic") ? Theme.primaryContainer : Theme.surface
                    clip: true
                    
                    // Gradient overlay
                    Rectangle {
                        anchors.fill: parent
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: "transparent" }
                            GradientStop { position: 1.0; color: Qt.rgba(0,0,0, 0.1) }
                        }
                    }

                    // The Big Cat
                    Text {
                        anchors.centerIn: parent
                        font.family: bongoFont.name
                        font.pixelSize: 80
                        font.letterSpacing: -2
                        color: root.catColorMode === "classic"
                            ? (popout.isActive ? Theme.onPrimaryContainer : Theme.surfaceText)
                            : root.resolvedCatColor
                        text: root.forceSleep ? root.sleepGlyph : (!popout.isActive ? root.sleepGlyph : (root.isBlinking && root.catState === 0 ? root.blinkGlyph : root.glyphMap[root.catState]))
                    }
                }

                // Typing metrics overlay (optional)
                Row {
                    width: parent.width
                    visible: root.showMetrics
                    spacing: Theme.spacingM

                    StyledRect {
                        width: (parent.width - Theme.spacingM) / 2
                        height: 64
                        radius: Theme.cornerRadius
                        color: Theme.surfaceContainerHigh

                        Column {
                            anchors.centerIn: parent
                            spacing: 0
                            StyledText {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: root.liveWpm
                                font.pixelSize: Theme.fontSizeLarge
                                font.weight: Font.Bold
                                color: Theme.primary
                            }
                            StyledText {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "WPM"
                                font.pixelSize: Theme.fontSizeExtraSmall
                                color: Theme.surfaceVariantText
                            }
                        }
                    }

                    StyledRect {
                        width: (parent.width - Theme.spacingM) / 2
                        height: 64
                        radius: Theme.cornerRadius
                        color: Theme.surfaceContainerHigh

                        Column {
                            anchors.centerIn: parent
                            spacing: 0
                            StyledText {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: root.cleanPercent + "%"
                                font.pixelSize: Theme.fontSizeLarge
                                font.weight: Font.Bold
                                color: Theme.primary
                            }
                            StyledText {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "Clean"
                                font.pixelSize: Theme.fontSizeExtraSmall
                                color: Theme.surfaceVariantText
                            }
                        }
                    }
                }

                Column {
                    width: parent.width
                    spacing: Theme.spacingS

                    // Header for settings
                    StyledText {
                        text: "Appearance & Behavior"
                        font.pixelSize: Theme.fontSizeSmall
                        font.bold: true
                        color: Theme.primary
                        opacity: 0.8
                    }

                    // Keyboard Selection
                    Row {
                        width: parent.width
                        height: 36
                        spacing: Theme.spacingM
                        DankIcon { name: "keyboard"; size: 20; color: Theme.primary; anchors.verticalCenter: parent.verticalCenter }
                        DankDropdown {
                            id: keyboardDropdown
                            width: parent.width - 40
                            options: root.deviceOptions
                            currentValue: root.selectedDeviceName
                            maxPopupHeight: 200
                            compactMode: true
                            onValueChanged: v => root.saveSetting("selectedDevicePath", root.deviceMap[v])
                        }
                    }

                    // Size Setting
                    Column {
                        width: parent.width
                        spacing: 2

                        StyledText {
                            text: "Cat Size"
                            font.pixelSize: Theme.fontSizeExtraSmall
                            font.weight: Font.Medium
                            color: Theme.surfaceVariantText
                        }

                        Row {
                            width: parent.width
                            height: 32
                            spacing: Theme.spacingM
                            DankIcon { name: "aspect_ratio"; size: 18; color: Theme.primary; anchors.verticalCenter: parent.verticalCenter }
                            DankSlider {
                                id: sizeSlider
                                width: parent.width - 80
                                value: root.catSize * 100
                                minimum: 50; maximum: 200
                                centerMinimum: false; unit: "%"; showValue: true
                                onSliderValueChanged: v => root.saveSetting("catSizePercent", v)
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            DankIcon {
                                name: "restore"
                                size: 18
                                color: Theme.primary
                                opacity: (root.catSize * 100) !== 100 ? 1.0 : 0.3
                                anchors.verticalCenter: parent.verticalCenter
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
                    }

                    // Sleep Timeout
                    Column {
                        width: parent.width
                        spacing: 2

                        StyledText {
                            text: "Sleep Timeout"
                            font.pixelSize: Theme.fontSizeExtraSmall
                            font.weight: Font.Medium
                            color: Theme.surfaceVariantText
                        }

                        Row {
                            width: parent.width
                            height: 32
                            spacing: Theme.spacingM
                            DankIcon { name: "bedtime"; size: 18; color: Theme.primary; anchors.verticalCenter: parent.verticalCenter }
                            DankSlider {
                                id: sleepSlider
                                width: parent.width - 80
                                value: root.waitingTimeout / 1000
                                minimum: 1; maximum: 10
                                centerMinimum: false; unit: "s"; showValue: true
                                onSliderValueChanged: v => root.saveSetting("waitingTimeout", v)
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            DankIcon {
                                name: "restore"
                                size: 18
                                color: Theme.primary
                                opacity: (root.waitingTimeout / 1000) !== 5 ? 1.0 : 0.3
                                anchors.verticalCenter: parent.verticalCenter
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
                    }

                    // Vertical Offset
                    Column {
                        width: parent.width
                        spacing: 2

                        StyledText {
                            text: "Vertical Offset"
                            font.pixelSize: Theme.fontSizeExtraSmall
                            font.weight: Font.Medium
                            color: Theme.surfaceVariantText
                        }

                        Row {
                            width: parent.width
                            height: 32
                            spacing: Theme.spacingM
                            DankIcon { name: "swap_vert"; size: 18; color: Theme.primary; anchors.verticalCenter: parent.verticalCenter }
                            DankSlider {
                                id: offsetSlider
                                width: parent.width - 80
                                value: root.catYOffset
                                minimum: -10; maximum: 10
                                centerMinimum: false; unit: "px"; showValue: true
                                onSliderValueChanged: v => root.saveSetting("catYOffset", v)
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            DankIcon {
                                name: "restore"
                                size: 18
                                color: Theme.primary
                                opacity: root.catYOffset !== 0 ? 1.0 : 0.3
                                anchors.verticalCenter: parent.verticalCenter
                                MouseArea {
                                    anchors.fill: parent
                                    enabled: root.catYOffset !== 0
                                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                    onClicked: {
                                        root.saveSetting("catYOffset", 0);
                                        offsetSlider.value = 0;
                                    }
                                }
                            }
                        }
                    }

                    // Paw Hold Time
                    Column {
                        width: parent.width
                        spacing: 2

                        StyledText {
                            text: "Paw Hold Time"
                            font.pixelSize: Theme.fontSizeExtraSmall
                            font.weight: Font.Medium
                            color: Theme.surfaceVariantText
                        }

                        Row {
                            width: parent.width
                            height: 32
                            spacing: Theme.spacingM
                            DankIcon { name: "timer"; size: 18; color: Theme.primary; anchors.verticalCenter: parent.verticalCenter }
                            DankSlider {
                                id: pawHoldSlider
                                width: parent.width - 80
                                value: root.pawHoldTime
                                minimum: 0; maximum: 100
                                centerMinimum: false; unit: "ms"; showValue: true
                                onSliderValueChanged: v => root.saveSetting("pawHoldTime", v)
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            DankIcon {
                                name: "restore"
                                size: 18
                                color: Theme.primary
                                opacity: root.pawHoldTime !== 0 ? 1.0 : 0.3
                                anchors.verticalCenter: parent.verticalCenter
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

                    // Cat Color
                    Column {
                        width: parent.width
                        spacing: 2

                        StyledText {
                            text: I18n.tr("Cat Color")
                            font.pixelSize: Theme.fontSizeExtraSmall
                            font.weight: Font.Medium
                            color: Theme.surfaceVariantText
                        }

                        Row {
                            width: parent.width
                            height: 32
                            spacing: Theme.spacingM
                            DankIcon { name: "palette"; size: 18; color: Theme.primary; anchors.verticalCenter: parent.verticalCenter }
                            DankDropdown {
                                id: colorModeDropdown
                                width: parent.width - 40 - (customSwatch.visible ? 40 + Theme.spacingM : 0)
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
                                width: 40; height: 28; radius: Theme.cornerRadius
                                anchors.verticalCenter: parent.verticalCenter
                                color: root.catCustomColor === "primary" ? Theme.primary : Qt.color(root.catCustomColor)
                                border.color: Theme.outlineStrong
                                border.width: 2
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (typeof PopoutService !== "undefined" && PopoutService && PopoutService.colorPickerModal) {
                                            // Capture the widget root: the callback runs later in the
                                            // modal's scope, where the enclosing-file `root` id no longer
                                            // resolves (ReferenceError), so the save would never fire.
                                            const widget = root;
                                            PopoutService.colorPickerModal.selectedColor = root.catCustomColor === "primary" ? Theme.primary : Qt.color(root.catCustomColor);
                                            PopoutService.colorPickerModal.pickerTitle = I18n.tr("Cat Color");
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

                    // Quick Toggles
                    Flow {
                        width: parent.width
                        spacing: Theme.spacingL

                        // Blink Toggle
                        Row {
                            spacing: Theme.spacingS
                            DankIcon {
                                name: root.enableBlinking ? "visibility" : "visibility_off"
                                size: 22
                                color: root.enableBlinking ? Theme.primary : Theme.surfaceText
                                opacity: root.enableBlinking ? 1.0 : 0.4
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.saveSetting("enableBlinking", !root.enableBlinking)
                                }
                            }
                            StyledText {
                                text: "Blink"
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.surfaceText
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        // Sound Toggle
                        Row {
                            spacing: Theme.spacingS
                            DankIcon {
                                name: root.soundEnabled ? "volume_up" : "volume_off"
                                size: 22
                                color: root.soundEnabled ? Theme.primary : Theme.surfaceText
                                opacity: root.soundEnabled ? 1.0 : 0.4
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.saveSetting("soundEnabled", !root.soundEnabled)
                                }
                            }
                            StyledText {
                                text: "Sound"
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.surfaceText
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        // Metrics Toggle
                        Row {
                            spacing: Theme.spacingS
                            DankIcon {
                                name: "speed"
                                size: 22
                                color: root.showMetrics ? Theme.primary : Theme.surfaceText
                                opacity: root.showMetrics ? 1.0 : 0.4
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.saveSetting("showMetrics", !root.showMetrics)
                                }
                            }
                            StyledText {
                                text: "Metrics"
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.surfaceText
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                    }
                }

                HintSection {
                    width: parent.width
                    showHints: root.showHints

                    HintItem {
                        icon: "mouse"
                        text: "Right-click bar icon to toggle sleep mode."
                    }
                }
            }
        }
    }
}
