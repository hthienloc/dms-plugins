import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Common
import qs.DCommon.Widgets
import qs.Services
import qs.Modules.Plugins
import "./shared"
import "./services"

DesktopPluginComponent {
    id: root
    pluginId: "bongoCat"
    pluginService: PluginService

    minWidth: 100
    minHeight: 80

    // Settings: use getData() so when a new desktop widget is created,
    // it seamlessly inherits the current global settings from the bar widget / popout
    // until explicitly overridden in the widget editor.
    readonly property real backgroundOpacity: (getData("desktopBackgroundOpacity", 0)) / 100.0
    readonly property bool showMetrics: getData("desktopShowMetrics", false)
    readonly property int metricsWindowSec: getData("metricsWindowSec", 15)
    readonly property int metricsWindowMs: metricsWindowSec * 1000

    readonly property string catSkin: getData("catSkin", "classic")
    readonly property string pixelSkinColor: getData("pixelSkinColor", "white")
    readonly property string pixelSkinFolder: pixelSkinColor === "white" ? "pixel" : ("pixel_" + pixelSkinColor)
    readonly property string catColorMode: getData("catColorMode", getData("activeColor", false) === true ? "primary" : "classic")
    readonly property string catCustomColor: getData("catCustomColor", "#ffffff")
    readonly property bool enableBlinking: getData("enableBlinking", true)
    readonly property bool mouseEnabled: getData("mouseEnabled", false)
    readonly property bool soundEnabled: getData("soundEnabled", false)
    readonly property bool soundOnMouse: getData("soundOnMouse", false)
    readonly property int soundVolume: getData("soundVolume", 70)
    readonly property string soundProfile: getData("soundProfile", "bongo")
    readonly property real _soundVol: Math.max(0, Math.min(1, soundVolume / 100))
    readonly property string selectedDevicePath: getData("selectedDevicePath", "all")
    readonly property int waitingTimeout: (getData("waitingTimeout", 5)) * 1000
    readonly property int pawHoldTime: getData("pawHoldTime", 0)
    readonly property bool doubleSlam: getData("doubleSlam", true)
    readonly property bool classicIdle: getData("classicIdle", false)

    // State
    property int catState: 0
    property bool leftWasLast: false
    property bool isBlinking: false
    property bool isWaiting: true
    property bool forceSleep: false

    property int kbState: 0
    property int mouseState: 0
    property int scrollState: 0
    property bool scrollLeftWasLast: false
    property bool mouseLeftDown: false
    property bool mouseRightDown: false
    property bool mouseOtherDown: false

    // WPM Metrics
    property int liveWpm: 0
    property int cleanPercent: 100
    property var _charStamps: []
    property var _correctionStamps: []

    readonly property var _nonCharKeys: [
        "KEY_LEFTSHIFT", "KEY_RIGHTSHIFT",
        "KEY_LEFTCTRL", "KEY_RIGHTCTRL",
        "KEY_LEFTALT", "KEY_RIGHTALT",
        "KEY_LEFTMETA", "KEY_RIGHTMETA",
        "KEY_CAPSLOCK", "KEY_NUMLOCK", "KEY_SCROLLLOCK",
        "KEY_UP", "KEY_DOWN", "KEY_LEFT", "KEY_RIGHT",
        "KEY_PAGEUP", "KEY_PAGEDOWN", "KEY_HOME", "KEY_END",
        "KEY_ESC", "KEY_PAUSE", "KEY_PRINT", "KEY_INSERT",
        "KEY_TAB"
    ]

    function classifyKey(keyName) {
        if (!keyName) return "ignore";
        if (keyName.indexOf("KEY_F") === 0) {
            const numPart = keyName.substring(5);
            if (!isNaN(parseInt(numPart, 10))) return "ignore";
        }
        if (_nonCharKeys.indexOf(keyName) !== -1) return "ignore";
        if (keyName === "KEY_BACKSPACE" || keyName === "KEY_DELETE") return "correction";
        return "char";
    }

    function recordKeystroke(keyName) {
        if (!showMetrics) return;
        const now = Date.now();
        const kind = classifyKey(keyName);
        if (kind === "ignore") return;
        if (kind === "char") {
            _charStamps.push(now);
        } else if (kind === "correction") {
            _correctionStamps.push(now);
        }
        _pruneAndCompute(now);
    }

    function _pruneAndCompute(now) {
        const cutoff = now - metricsWindowMs;
        while (_charStamps.length > 0 && _charStamps[0] < cutoff)
            _charStamps.shift();
        while (_correctionStamps.length > 0 && _correctionStamps[0] < cutoff)
            _correctionStamps.shift();

        const chars = _charStamps.length;
        const corrections = _correctionStamps.length;
        const minutes = metricsWindowSec / 60.0;
        liveWpm = Math.round((chars / 5.0) / minutes);

        const total = chars + corrections;
        if (total === 0) {
            cleanPercent = 100;
        } else {
            cleanPercent = Math.max(0, Math.min(100, Math.round((chars / total) * 100)));
        }
    }

    Timer {
        id: metricsPruneTimer
        interval: 1000
        repeat: true
        running: root.showMetrics && (root._charStamps.length > 0 || root._correctionStamps.length > 0)
        onTriggered: root._pruneAndCompute(Date.now())
    }

    readonly property color resolvedCatColor: {
        if (catColorMode === "primary") return Theme.primary;
        if (catColorMode === "custom") return Qt.color(catCustomColor);
        return Theme.surfaceText;
    }

    FontLoader {
        id: bongoFont
        source: "./assets/bongocat-Regular.otf"
    }

    readonly property var glyphMap: ["bc", "dc", "ba", "da"]
    readonly property string blinkGlyph: "gh"
    readonly property string sleepGlyph: "ef"
    readonly property string currentCatGlyph: root.forceSleep ? root.sleepGlyph : (root.isWaiting ? root.sleepGlyph : (root.isBlinking && root.catState === 0 ? root.blinkGlyph : root.glyphMap[root.catState]))
    readonly property real catGlyphPixelSize: Math.max(24, Math.min(desktopCatContainer.width * 0.75, desktopCatContainer.height * (root.showMetrics ? 0.7 : 0.85)))

    readonly property var pixelSpriteMap: [
        Qt.resolvedUrl("./assets/skins/" + pixelSkinFolder + "/idle@4x.png"),
        Qt.resolvedUrl("./assets/skins/" + pixelSkinFolder + "/left@4x.png"),
        Qt.resolvedUrl("./assets/skins/" + pixelSkinFolder + "/right@4x.png"),
        Qt.resolvedUrl("./assets/skins/" + pixelSkinFolder + "/both@4x.png")
    ]
    readonly property string pixelBlinkSprite: Qt.resolvedUrl("./assets/skins/" + pixelSkinFolder + "/blink@4x.png")
    readonly property string pixelSleepSprite: Qt.resolvedUrl("./assets/skins/" + pixelSkinFolder + "/sleep@4x.png")

    readonly property string activeSpriteSource: {
        if (root.forceSleep || root.isWaiting) return pixelSleepSprite;
        if (root.isBlinking && root.catState === 0) return pixelBlinkSprite;
        return pixelSpriteMap[root.catState] || pixelSpriteMap[0];
    }

    function playClick(isBigHit) {
        if (!soundEnabled || forceSleep) return;
        BongoSoundService.volume = _soundVol;
        BongoSoundService.soundProfile = soundProfile;
        BongoSoundService.play(isBigHit);
    }

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

    function onMouseButton(buttonName, pressed) {
        if (pressed && soundOnMouse) playClick(false);
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
        if (scrollThrottle.running) return;
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
        running: root.enableBlinking && !root.isWaiting && !root.forceSleep
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
                if (line.includes("POINTER_BUTTON")) {
                    const match = line.match(/(BTN_[A-Z0-9_]+)/);
                    const name = match ? match[1] : "BTN_OTHER";
                    if (line.includes("pressed")) {
                        root.onMouseButton(name, true);
                    } else if (line.includes("released")) {
                        root.onMouseButton(name, false);
                    }
                } else if (line.includes("POINTER_SCROLL")) {
                    const vert = line.match(/vert\s+(-?\d+(?:\.\d+)?)/);
                    const horiz = line.match(/horiz\s+(-?\d+(?:\.\d+)?)/);
                    if (vert && horiz && parseFloat(vert[1]) === 0 && parseFloat(horiz[1]) === 0)
                        return;
                    root.onScrollTick();
                }
            }
        }
    }

    // UI Content
    Rectangle {
        id: backgroundRect
        anchors.fill: parent
        radius: Theme.cornerRadius
        color: Theme.withAlpha(Theme.surface, root.backgroundOpacity)
        border.color: Theme.withAlpha(Theme.outline, root.backgroundOpacity > 0 ? 0.2 : 0)
        border.width: 1
    }

    Item {
        anchors.fill: parent
        anchors.margins: root.backgroundOpacity > 0 ? Theme.spacingS : 0

        ColumnLayout {
            anchors.fill: parent
            spacing: Theme.spacingXS

            Item {
                id: desktopCatContainer
                Layout.fillWidth: true
                Layout.fillHeight: true

                BongoCatView {
                    anchors.centerIn: parent
                    skin: root.catSkin
                    glyphText: root.currentCatGlyph
                    targetPixelSize: root.catGlyphPixelSize
                    catColor: root.resolvedCatColor
                    catOpacity: root.forceSleep ? 0.5 : 1.0
                    spriteSource: root.activeSpriteSource
                }
            }

            // Optional metrics readout
            StyledText {
                visible: root.showMetrics
                Layout.alignment: Qt.AlignHCenter
                text: root.liveWpm + " WPM · " + root.cleanPercent + "%"
                font.pixelSize: Theme.fontSizeSmall
                font.weight: Font.DemiBold
                color: Theme.surfaceText
                opacity: root.forceSleep ? 0.5 : 0.9
            }
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.RightButton
            cursorShape: Qt.PointingHandCursor
            onClicked: mouse => {
                if (mouse.button === Qt.RightButton) {
                    root.forceSleep = !root.forceSleep;
                    if (root.forceSleep) root.isWaiting = true;
                }
            }
        }
    }
}
