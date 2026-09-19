import QtQuick
import QtQuick.Controls
import Quickshell
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.Plugins
import "./dms-common"


PluginComponent {
    id: root
    readonly property string pluginDir: {
        var url = Qt.resolvedUrl(".").toString();
        if (url.startsWith("file://")) url = url.replace("file://", "");
        return url.endsWith("/") ? url.substring(0, url.length - 1) : url;
    }
    readonly property bool showHints: pluginData.showHints ?? true


    pillRightClickAction: () => root.togglePause()

    readonly property real cellWidth: (root.popoutWidth - (root.gridSpacing * 2) - 16) / 2
    readonly property real cellHeight: 100
    readonly property int labelFontSize: Theme.fontSizeSmall
    readonly property int timerFontSize: Theme.fontSizeLarge
    readonly property int spacing: Theme.spacingM
    readonly property int gridSpacing: 8

    readonly property var exercises: [
        {
            id: "deep",
            name: "Deep Breathing",
            description: "Slow deep breaths for relaxation",
            inhaleDuration: 4,
            holdDuration: 4,
            exhaleDuration: 4,
            cycles: 4,
            iconName: "air"
        },
        {
            id: "478",
            name: "4-7-8 Breathing",
            description: "Calming technique for sleep",
            inhaleDuration: 4,
            holdDuration: 7,
            exhaleDuration: 8,
            cycles: 4,
            iconName: "bedtime"
        },
        {
            id: "box",
            name: "Box Breathing",
            description: "Navy SEAL technique",
            inhaleDuration: 4,
            holdDuration: 4,
            exhaleDuration: 4,
            holdAfterExhale: 4,
            cycles: 4,
            iconName: "crop_square"
        },
        {
            id: "equal",
            name: "Equal Breathing",
            description: "Equal inhale and exhale",
            inhaleDuration: 4,
            holdDuration: 0,
            exhaleDuration: 4,
            cycles: 6,
            iconName: "sync_alt"
        },
        {
            id: "resonance",
            name: "Resonance",
            description: "5.5-5.5 breathing rhythm",
            inhaleDuration: 5.5,
            holdDuration: 0,
            exhaleDuration: 5.5,
            cycles: 6,
            iconName: "waves"
        },
        {
            id: "alternate",
            name: "Alternate Nostril",
            description: "Balance left and right",
            inhaleDuration: 4,
            holdDuration: 0,
            exhaleDuration: 4,
            holdAfterExhale: 2,
            cycles: 6,
            iconName: "swap_horiz"
        }
    ]

    property real breathProgress: 0.0
    readonly property string animationStyle: pluginData.animationStyle ?? "pulse"

    readonly property color phaseColor: {
        if (breathPhase === "inhale") return Theme.primary; // Focus
        if (breathPhase === "hold") return Theme.warning;   // Hold
        if (breathPhase === "exhale") return Theme.success;  // Release
        return Theme.surfaceVariantText; // Silent / Rest
    }

    onBreathPhaseChanged: {
        root.playSound(breathPhase);

        if (!isRunning || currentExerciseIndex < 0) {
            progressAnimation.stop();
            breathProgress = 0.0;
            return;
        }

        var ex = exercises[currentExerciseIndex];
        var duration = 0;
        var targetVal = 0.0;

        if (breathPhase === "inhale") {
            duration = ex.inhaleDuration * 1000;
            targetVal = 1.0;
        } else if (breathPhase === "hold") {
            duration = ex.holdDuration * 1000;
            targetVal = 1.0;
        } else if (breathPhase === "exhale") {
            duration = ex.exhaleDuration * 1000;
            targetVal = 0.0;
        } else if (breathPhase === "holdAfterExhale") {
            duration = (ex.holdAfterExhale || 0) * 1000;
            targetVal = 0.0;
        }

        if (duration > 0) {
            progressAnimation.stop();
            progressAnimation.duration = duration;
            progressAnimation.from = breathProgress;
            progressAnimation.to = targetVal;
            progressAnimation.start();
        } else {
            breathProgress = targetVal;
        }
    }

    onIsRunningChanged: {
        if (!isRunning) {
            progressAnimation.stop();
            breathProgress = 0.0;
            root.stopSound();
        }
    }

    onIsPausedChanged: {
        if (isRunning) {
            if (isPaused) {
                progressAnimation.pause();
                root.pauseSound();
            } else {
                progressAnimation.resume();
                root.resumeSound();
            }
        }
    }

    NumberAnimation {
        id: progressAnimation
        target: root
        property: "breathProgress"
        easing.type: Easing.InOutQuad
    }

    property bool isRunning: false
    property bool isPaused: false
    property int currentExerciseIndex: -1
    property int currentCycle: 0
    onCurrentCycleChanged: {
        if (isPlayerRunning && currentCycle > 1) {
            var cmd = "echo '{\"command\":[\"seek\",0,\"absolute\"]}' | socat - UNIX-CONNECT:/tmp/dms-breathing-mpv.sock 2>/dev/null";
            Proc.runCommand("restart-breathing-sound", ["bash", "-c", cmd], null, 0, -1);
        }
    }
    property string breathPhase: ""
    property int phaseTimeRemaining: 0
    property int totalTimeRemaining: 0
    property bool enableHaptic: pluginData.enableHaptic !== undefined ? pluginData.enableHaptic : true
    property int selectedDuration: 5
    property int calculatedCycles: 0

    property bool enableSound: pluginData.enableSound !== undefined ? pluginData.enableSound : true
    property bool enableTwoTone: pluginData.enableTwoTone !== undefined ? pluginData.enableTwoTone : false
    property string soundType: pluginData.soundType !== undefined ? pluginData.soundType : "chime"

    property bool isPlayerRunning: false
    property bool isTestingSound: false
    property int soundVolume: pluginData.defaultSoundVolume !== undefined ? pluginData.defaultSoundVolume : 80

    onSoundVolumeChanged: {
        pluginData.defaultSoundVolume = soundVolume;
        if (isPlayerRunning || isTestingSound) {
            var cmd = "echo '{\"command\":[\"set_property\",\"volume\"," + soundVolume + "]}' | socat - UNIX-CONNECT:/tmp/dms-breathing-mpv.sock 2>/dev/null";
            Proc.runCommand("update-volume", ["bash", "-c", cmd], null, 0, -1);
        }
    }

    // Volume fade state
    property real fadeStartVol: 100
    property real fadeEndVol: 100
    property int fadeDurationMs: 1000
    property int fadeElapsedMs: 0
    readonly property int fadeTickMs: 120

    Timer {
        id: volumeFadeTimer
        interval: root.fadeTickMs
        repeat: true
        running: false
        onTriggered: {
            root.fadeElapsedMs += root.fadeTickMs;
            var progress = Math.min(root.fadeElapsedMs / root.fadeDurationMs, 1.0);
            var vol = Math.round(root.fadeStartVol + (root.fadeEndVol - root.fadeStartVol) * progress);
            var cmd = "echo '{\"command\":[\"set_property\",\"volume\"," + vol + "]}' | socat - UNIX-CONNECT:/tmp/dms-breathing-mpv.sock 2>/dev/null";
            Proc.runCommand("fade-breathing-volume", ["bash", "-c", cmd], null, 0, -1);
            if (progress >= 1.0) volumeFadeTimer.stop();
        }
    }

    function startVolumeFade(fromVol, toVol, durationMs) {
        volumeFadeTimer.stop();
        root.fadeStartVol = fromVol;
        root.fadeEndVol = toVol;
        root.fadeDurationMs = Math.max(durationMs, 1);
        root.fadeElapsedMs = 0;
        // Set initial volume immediately
        var cmd = "echo '{\"command\":[\"set_property\",\"volume\"," + Math.round(fromVol) + "]}' | socat - UNIX-CONNECT:/tmp/dms-breathing-mpv.sock 2>/dev/null";
        Proc.runCommand("fade-breathing-volume", ["bash", "-c", cmd], null, 0, -1);
        if (fromVol !== toVol) volumeFadeTimer.start();
    }

    function toggleTestSound() {
        if (isTestingSound) {
            stopTestSound();
        } else {
            startTestSound();
        }
    }

    function startTestSound() {
        if (isRunning) {
            stopExercise();
        }
        isTestingSound = true;
        var SOCK = "/tmp/dms-breathing-mpv.sock";
        var soundFile = pluginDir + "/sounds/chime.ogg";
        if (root.soundType === "meditation") {
            soundFile = pluginDir + "/sounds/meditation.mp3";
        } else if (root.soundType === "custom") {
            var customPath = pluginData.customSoundPath !== undefined ? pluginData.customSoundPath.trim() : "";
            if (customPath.length > 0) {
                soundFile = customPath;
            }
        }
        var initCmd = "rm -f '" + SOCK + "'; mpv --no-video --no-config --loop=inf --audio-pitch-correction=no --volume=" + root.soundVolume + " --audio-samplerate=48000 --speed=1.0 --input-ipc-server='" + SOCK + "' '" + soundFile + "' 2>&1";
        console.log("[BreathingWidget] startTestSound cmd:", initCmd);
        Proc.runCommand("start-breathing-test-sound", ["bash", "-c", initCmd], function(output, exitCode) {
            console.log("[BreathingWidget] MPV exited! code:", exitCode, "output:", output);
            isTestingSound = false;
            var debugCmd = "printf '%s' 'MPV exited with code " + exitCode + ". Output: " + output.replace(/'/g, "") + "' > /tmp/breathing-mpv-error.txt";
            Proc.runCommand("write-debug", ["bash", "-c", debugCmd], null, 0);
        }, 0, -1);
    }

    function stopTestSound() {
        isTestingSound = false;
        stopSound();
    }

    function playSoundCmd() {
        var SOCK = "/tmp/dms-breathing-mpv.sock";
        var soundFile = pluginDir + "/sounds/chime.ogg";
        if (root.soundType === "meditation") {
            soundFile = pluginDir + "/sounds/meditation.mp3";
        } else if (root.soundType === "custom") {
            var customPath = pluginData.customSoundPath !== undefined ? pluginData.customSoundPath.trim() : "";
            if (customPath.length > 0) {
                soundFile = customPath;
            }
        }
        return "mpv --no-video --no-config --loop=inf --audio-pitch-correction=no --volume=" + root.soundVolume + " --audio-samplerate=48000 --input-ipc-server='" + SOCK + "' '" + soundFile + "' > /dev/null 2>&1";
    }

    function stopSound() {
        isPlayerRunning = false;
        volumeFadeTimer.stop();
        var cmd = "echo '{\"command\":[\"quit\"]}' | socat - UNIX-CONNECT:/tmp/dms-breathing-mpv.sock 2>/dev/null; rm -f /tmp/dms-breathing-mpv.sock";
        Proc.runCommand("stop-breathing-sound", ["bash", "-c", cmd], null, 0, -1);
    }

    function pauseSound() {
        if (!enableSound || !isPlayerRunning) return;
        var cmd = "echo '{\"command\":[\"set_property\",\"pause\",true]}' | socat - UNIX-CONNECT:/tmp/dms-breathing-mpv.sock";
        Proc.runCommand("pause-breathing-sound", ["bash", "-c", cmd], null, 0, -1);
    }

    function resumeSound() {
        if (!enableSound || !isRunning || isPaused) return;
        if (!isPlayerRunning) {
            playSound(breathPhase);
            return;
        }
        var cmd = "echo '{\"command\":[\"set_property\",\"pause\",false]}' | socat - UNIX-CONNECT:/tmp/dms-breathing-mpv.sock";
        Proc.runCommand("resume-breathing-sound", ["bash", "-c", cmd], null, 0, -1);
    }

    function playSound(phase) {
        if (!enableSound || !isRunning || isPaused) return;

        var shouldStrike = (phase === "inhale") || (root.enableTwoTone && phase === "exhale");
        var speed = "1.0";
        if (phase === "inhale") {
            speed = "1.1";
        } else if (phase === "exhale" || phase === "holdAfterExhale") {
            speed = "0.9";
        }

        if (isPlayerRunning) {
            var cmd = "echo '{\"command\":[\"set_property\",\"speed\"," + speed + "]}' | socat - UNIX-CONNECT:/tmp/dms-breathing-mpv.sock && " +
                      "echo '{\"command\":[\"set_property\",\"volume\"," + root.soundVolume + "]}' | socat - UNIX-CONNECT:/tmp/dms-breathing-mpv.sock && " +
                      "echo '{\"command\":[\"set_property\",\"pause\",false]}' | socat - UNIX-CONNECT:/tmp/dms-breathing-mpv.sock";
            if (shouldStrike) {
                cmd += " && echo '{\"command\":[\"seek\",0,\"absolute\"]}' | socat - UNIX-CONNECT:/tmp/dms-breathing-mpv.sock";
            }
            Proc.runCommand("play-breathing-sound", ["bash", "-c", cmd], null, 0, -1);
        } else {
            isPlayerRunning = true;
            var SOCK = "/tmp/dms-breathing-mpv.sock";
            var initCmd = "rm -f '" + SOCK + "'; " + playSoundCmd();
            Proc.runCommand("start-breathing-sound", ["bash", "-c", initCmd], null, 0, -1);
            var capturedSpeed = speed;
            var strikePart = shouldStrike ? "echo '{\"command\":[\"seek\",0,\"absolute\"]}' | socat - UNIX-CONNECT:" + SOCK + " 2>/dev/null && " : "";
            var setCmd = "for i in {1..30}; do if [ -S " + SOCK + " ]; then " +
                         "echo '{\"command\":[\"set_property\",\"speed\"," + capturedSpeed + "]}' | socat - UNIX-CONNECT:" + SOCK + " 2>/dev/null && " +
                         strikePart +
                         "echo '{\"command\":[\"set_property\",\"pause\",false]}' | socat - UNIX-CONNECT:" + SOCK + " 2>/dev/null && break; " +
                         "fi; sleep 0.05; done";
            Proc.runCommand("play-breathing-sound", ["bash", "-c", setCmd], null, 0, -1);
        }
    }


    Component.onDestruction: {
        stopSound();
    }

    readonly property var timePresets: [
        { label: "1m", minutes: 1 },
        { label: "2m", minutes: 2 },
        { label: "3m", minutes: 3 },
        { label: "5m", minutes: 5 },
        { label: "10m", minutes: 10 },
        { label: "15m", minutes: 15 },
        { label: "20m", minutes: 20 },
        { label: "30m", minutes: 30 }
    ]

    function selectExercise(index) {
        currentExerciseIndex = index;
        currentCycle = 0;
        breathPhase = "";
    }

    function startExercise() {
        if (isTestingSound) {
            isTestingSound = false;
            isPlayerRunning = true;
        } else {
            isPlayerRunning = false;
        }
        if (currentExerciseIndex < 0) {
            currentExerciseIndex = 0;
        }
        var ex = exercises[currentExerciseIndex];
        var cycleTime = ex.inhaleDuration + ex.holdDuration + ex.exhaleDuration + (ex.holdAfterExhale || 0);
        root.calculatedCycles = Math.floor((root.selectedDuration * 60) / cycleTime);
        
        isRunning = true;
        isPaused = false;
        currentCycle = 1;
        breathPhase = "inhale";
        phaseTimeRemaining = ex.inhaleDuration * 1000;
        totalTimeRemaining = root.selectedDuration * 60 * 1000;
        exerciseTimer.start();
    }

    function togglePause() {
        if (!isRunning && currentExerciseIndex >= 0) {
            startExercise();
            return;
        }
        isPaused = !isPaused;
        if (isPaused) {
            exerciseTimer.stop();
        } else {
            exerciseTimer.start();
        }
    }

    function stopExercise() {
        isRunning = false;
        isPaused = false;
        currentCycle = 0;
        breathPhase = "";
        phaseTimeRemaining = 0;
        totalTimeRemaining = 0;
        exerciseTimer.stop();
    }

    function calculateTotalTime() {
        if (currentExerciseIndex < 0) return 0;
        var ex = exercises[currentExerciseIndex];
        var cycleTime = (ex.inhaleDuration + ex.holdDuration + ex.exhaleDuration + (ex.holdAfterExhale || 0)) * 1000;
        return cycleTime * ex.cycles;
    }

    Timer {
        id: exerciseTimer
        interval: 1000
        repeat: true
        running: isRunning && !isPaused
        onTriggered: {
            phaseTimeRemaining -= 1000;
            totalTimeRemaining -= 1000;
            
            if (phaseTimeRemaining === 1000) {
                var ex = exercises[currentExerciseIndex];
                var nextIsInhale = false;
                if (breathPhase === "exhale" && !(ex.holdAfterExhale > 0)) {
                    nextIsInhale = (currentCycle < root.calculatedCycles);
                } else if (breathPhase === "holdAfterExhale") {
                    nextIsInhale = (currentCycle < root.calculatedCycles);
                }

                if (nextIsInhale && enableSound) {
                    root.startVolumeFade(root.soundVolume, Math.round(root.soundVolume * 0.45), 500);
                }
            }
            
            if (phaseTimeRemaining <= 0) {
                var ex = exercises[currentExerciseIndex];
                
                if (breathPhase === "inhale") {
                    if (ex.holdDuration > 0) {
                        breathPhase = "hold";
                        phaseTimeRemaining = ex.holdDuration * 1000;
                    } else {
                        breathPhase = "exhale";
                        phaseTimeRemaining = ex.exhaleDuration * 1000;
                    }
                } else if (breathPhase === "hold") {
                    breathPhase = "exhale";
                    phaseTimeRemaining = ex.exhaleDuration * 1000;
                } else if (breathPhase === "exhale") {
                    if (ex.holdAfterExhale > 0) {
                        breathPhase = "holdAfterExhale";
                        phaseTimeRemaining = ex.holdAfterExhale * 1000;
                    } else {
                        if (currentCycle < root.calculatedCycles) {
                            currentCycle++;
                            breathPhase = "inhale";
                            phaseTimeRemaining = ex.inhaleDuration * 1000;
                        } else {
                            stopExercise();
                            ToastService.showInfo("Exercise complete!");
                        }
                    }
                } else if (breathPhase === "holdAfterExhale") {
                    if (currentCycle < root.calculatedCycles) {
                        currentCycle++;
                        breathPhase = "inhale";
                        phaseTimeRemaining = ex.inhaleDuration * 1000;
                    } else {
                        stopExercise();
                        ToastService.showInfo("Exercise complete!");
                    }
                }
            }
        }
    }

    Timer {
        id: autoStartTimer
        interval: 2000
        onTriggered: {
            if (pluginData.enableAutoStart && pluginData.autoStartExercise !== undefined) {
                var idx = parseInt(pluginData.autoStartExercise);
                var dur = parseInt(pluginData.defaultDuration ?? 5);
                if (idx >= 0 && idx < root.exercises.length) {
                    root.selectedDuration = dur;
                    selectExercise(idx);
                    startExercise();
                }
            }
        }
    }

    Component.onCompleted: {
        console.log("[BreathingWidget] Component completed successfully! enableSound is:", enableSound);
        root.selectedDuration = pluginData.defaultDuration !== undefined ? pluginData.defaultDuration : 5;
        autoStartTimer.start();
    }

    horizontalBarPill: Component {
        Item {
            implicitWidth: pillRow.implicitWidth
            implicitHeight: pillRow.implicitHeight

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton
                cursorShape: Qt.PointingHandCursor
                onClicked: root.triggerPopout()
            }

            Row {
                id: pillRow
                anchors.centerIn: parent
                spacing: 4

                DankIcon {
                    name: root.isPaused ? "pause" : 
                          (breathPhase === "inhale" ? "trending_up" : 
                           breathPhase === "hold" || breathPhase === "holdAfterExhale" ? "horizontal_rule" :
                           breathPhase === "exhale" ? "trending_down" : "air")
                    size: 18
                    color: (root.isRunning || root.breathPhase !== "") ? Theme.primary : Theme.surfaceVariantText
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }
    }

    verticalBarPill: horizontalBarPill

    popoutWidth: 380
    popoutHeight: 500

    popoutContent: Component {
        PopoutComponent {
            id: mainPopout
            width: root.popoutWidth
            headerText: "Breathing Exercises"
            detailsText: isRunning ? (exercises[currentExerciseIndex].name + " • Cycle " + currentCycle + "/" + root.calculatedCycles) : ""
            showCloseButton: false
            focus: true

            property var parentPopout: null
            PluginShortcut {
                parentPopout: mainPopout.parentPopout
                onSpacePressed: () => root.togglePause()
                onRPressed: () => root.stopExercise()
            }

            Column {
                id: mainColumn
                width: parent.width
                spacing: 8

                // Active display when running
                StyledRect {
                    width: parent.width
                    height: root.isRunning ? (root.animationStyle === "classic" ? 96 : 220) : 0
                    visible: root.isRunning
                    radius: Theme.cornerRadius
                    color: Theme.surfaceContainerHigh
                    clip: true

                    Behavior on height {
                        NumberAnimation { duration: 250; easing.type: Easing.InOutQuad }
                    }

                    // 1. Expanding Circle Visualizer
                    Item {
                        anchors.fill: parent
                        visible: root.animationStyle === "circle"

                        // Outer thin ring
                        Rectangle {
                            anchors.centerIn: parent
                            width: (100 + root.breathProgress * 80) * 1.3
                            height: width
                            radius: width / 2
                            color: "transparent"
                            border.color: Qt.rgba(root.phaseColor.r, root.phaseColor.g, root.phaseColor.b, 0.15)
                            border.width: 1
                        }

                        // Middle glowing ring
                        Rectangle {
                            anchors.centerIn: parent
                            width: (100 + root.breathProgress * 80) * 1.15
                            height: width
                            radius: width / 2
                            color: "transparent"
                            border.color: Qt.rgba(root.phaseColor.r, root.phaseColor.g, root.phaseColor.b, 0.3)
                            border.width: 1
                        }

                        // Core expanding circle
                        Rectangle {
                            id: coreCircle
                            anchors.centerIn: parent
                            width: 100 + root.breathProgress * 80
                            height: width
                            radius: width / 2
                            color: Qt.rgba(root.phaseColor.r, root.phaseColor.g, root.phaseColor.b, 0.12)
                            border.color: root.phaseColor
                            border.width: 3

                            Behavior on color { ColorAnimation { duration: 500 } }
                            Behavior on border.color { ColorAnimation { duration: 500 } }

                            Column {
                                anchors.centerIn: parent
                                spacing: 4

                                StyledText {
                                    text: root.isPaused ? I18n.tr("Paused") : (
                                        breathPhase === "inhale" ? I18n.tr("Breathe In") : 
                                        breathPhase === "hold" ? I18n.tr("Hold") : 
                                        breathPhase === "exhale" ? I18n.tr("Breathe Out") :
                                        breathPhase === "holdAfterExhale" ? I18n.tr("Hold") : "---"
                                    )
                                    font.pixelSize: Theme.fontSizeMedium
                                    font.bold: true
                                    color: Theme.surfaceText
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }

                                StyledText {
                                    text: Math.ceil(phaseTimeRemaining / 1000) + "s"
                                    font.pixelSize: Theme.fontSizeLarge
                                    font.bold: true
                                    color: root.phaseColor
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }
                            }
                        }
                    }

                    // 2. Flowing Wave Visualizer
                    Item {
                        anchors.fill: parent
                        visible: root.animationStyle === "wave"

                        Canvas {
                            id: waveCanvas
                            anchors.fill: parent
                            property real waveOffset: 0.0

                            onPaint: {
                                var ctx = getContext("2d");
                                ctx.clearRect(0, 0, width, height);

                                var baseHeight = height * 0.75;
                                var waveHeight = height * 0.35 * root.breathProgress;

                                // Wave 1 (Back wave, lower opacity)
                                drawWave(ctx, baseHeight + 5, waveHeight, waveOffset, 0.015, Qt.rgba(root.phaseColor.r, root.phaseColor.g, root.phaseColor.b, 0.15));
                                // Wave 2 (Front wave, higher opacity)
                                drawWave(ctx, baseHeight, waveHeight * 0.8, waveOffset + 2.5, 0.025, Qt.rgba(root.phaseColor.r, root.phaseColor.g, root.phaseColor.b, 0.3));
                            }

                            function drawWave(ctx, base, amp, offset, freq, fillColor) {
                                ctx.fillStyle = fillColor;
                                ctx.beginPath();
                                ctx.moveTo(0, height);
                                for (var x = 0; x <= width; x += 5) {
                                    var y = base - Math.sin(x * freq + offset) * amp;
                                    ctx.lineTo(x, y);
                                }
                                ctx.lineTo(width, height);
                                ctx.closePath();
                                ctx.fill();
                            }

                            Timer {
                                running: root.isRunning && !root.isPaused && root.animationStyle === "wave"
                                interval: 16
                                repeat: true
                                onTriggered: {
                                    waveCanvas.waveOffset += 0.05;
                                    waveCanvas.requestPaint();
                                }
                            }
                        }

                        // Info text in center (wave overlay)
                        Column {
                            anchors.centerIn: parent
                            spacing: 4

                            StyledText {
                                text: root.isPaused ? I18n.tr("Paused") : (
                                    breathPhase === "inhale" ? I18n.tr("Breathe In") : 
                                    breathPhase === "hold" ? I18n.tr("Hold") : 
                                    breathPhase === "exhale" ? I18n.tr("Breathe Out") :
                                    breathPhase === "holdAfterExhale" ? I18n.tr("Hold") : "---"
                                )
                                font.pixelSize: Theme.fontSizeXLarge
                                font.bold: true
                                color: Theme.surfaceText
                                anchors.horizontalCenter: parent.horizontalCenter
                            }

                            StyledText {
                                text: Math.ceil(phaseTimeRemaining / 1000) + "s"
                                font.pixelSize: Theme.fontSizeLarge
                                font.bold: true
                                color: root.phaseColor
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                        }
                    }

                    // 3. Pulsating Glow Visualizer
                    Item {
                        anchors.fill: parent
                        visible: root.animationStyle === "pulse"

                        // Ambient glow background
                        Rectangle {
                            anchors.centerIn: parent
                            width: 240
                            height: 240
                            radius: 120
                            color: root.phaseColor
                            opacity: 0.05 + root.breathProgress * 0.15
                            scale: 0.8 + root.breathProgress * 0.4

                            Behavior on color { ColorAnimation { duration: 500 } }
                        }

                        // Pulsating core circle
                        Rectangle {
                            anchors.centerIn: parent
                            width: 140
                            height: 140
                            radius: 70
                            color: root.phaseColor
                            opacity: 0.15 + root.breathProgress * 0.45
                            scale: 0.95 + Math.sin(Date.now() / 400) * 0.03

                            Behavior on color { ColorAnimation { duration: 500 } }

                            Column {
                                anchors.centerIn: parent
                                spacing: 2

                                DankIcon {
                                    name: root.isPaused ? "pause" : (
                                        breathPhase === "inhale" ? "trending_up" : 
                                        breathPhase === "hold" || breathPhase === "holdAfterExhale" ? "horizontal_rule" :
                                        breathPhase === "exhale" ? "trending_down" : "air"
                                    )
                                    size: Theme.iconSize
                                    color: Theme.surfaceText
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }

                                StyledText {
                                    text: root.isPaused ? I18n.tr("Paused") : (
                                        breathPhase === "inhale" ? I18n.tr("Breathe In") : 
                                        breathPhase === "hold" ? I18n.tr("Hold") : 
                                        breathPhase === "exhale" ? I18n.tr("Breathe Out") :
                                        breathPhase === "holdAfterExhale" ? I18n.tr("Hold") : "---"
                                    )
                                    font.pixelSize: Theme.fontSizeMedium
                                    font.bold: true
                                    color: Theme.surfaceText
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }

                                StyledText {
                                    text: Math.ceil(phaseTimeRemaining / 1000) + "s"
                                    font.pixelSize: Theme.fontSizeMedium
                                    font.bold: true
                                    color: Theme.surfaceText
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    opacity: 0.8
                                }
                            }
                        }
                    }

                    // 4. Classic Card Visualizer
                    Item {
                        anchors.fill: parent
                        visible: root.animationStyle === "classic"

                        StatusDisplay {
                            id: statusDisplay
                            width: parent.width
                            large: true
                            active: root.isRunning || root.breathPhase !== ""
                            iconName: root.isPaused ? "pause" : 
                                     (breathPhase === "inhale" ? "trending_up" : 
                                      breathPhase === "hold" || breathPhase === "holdAfterExhale" ? "horizontal_rule" :
                                      breathPhase === "exhale" ? "trending_down" : "air")
                            title: root.isPaused ? "Paused" : (breathPhase === "inhale" ? "Breathe In" : 
                                       breathPhase === "hold" ? "Hold" : 
                                       breathPhase === "exhale" ? "Breathe Out" :
                                       breathPhase === "holdAfterExhale" ? "Hold" : "---")
                            subtitle: (Math.ceil(phaseTimeRemaining / 1000)) + "s"
                            infoText: "/ " + Math.floor(totalTimeRemaining / 60000) + ":" + ((Math.floor((totalTimeRemaining % 60000) / 1000) + "").padStart(2, "0"))
                        }
                    }

                    // Total session timer in top-right
                    StyledText {
                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.margins: Theme.spacingM
                        text: Math.floor(totalTimeRemaining / 60000) + ":" + ((Math.floor((totalTimeRemaining % 60000) / 1000) + "").padStart(2, "0"))
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.surfaceVariantText
                        visible: root.animationStyle !== "classic"
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.togglePause()
                    }
                }

                // Exercises grid
                Flow {
                    width: parent.width
                    spacing: root.gridSpacing
                    visible: !root.isRunning

                    Repeater {
                        model: root.exercises
                        delegate: ActionTile {
                            width: root.cellWidth
                            height: root.cellHeight
                            title: modelData.name
                            subtitle: (modelData.inhaleDuration || 0) + "-" + (modelData.holdDuration || 0) + "-" + (modelData.exhaleDuration || 0) + "-" + (modelData.holdAfterExhale || 0)
                            iconName: modelData.iconName
                            active: root.currentExerciseIndex === index
                            onClicked: {
                                if (root.currentExerciseIndex === index && !root.isRunning) {
                                    root.startExercise();
                                } else {
                                    root.selectExercise(index);
                                    if (root.isRunning) root.startExercise();
                                }
                            }
                        }
                    }
                }

                // Start/Stop buttons
                Column {
                    width: parent.width
                    spacing: 8

                    // Duration presets
                    Row {
                        width: parent.width
                        spacing: 4
                        visible: !root.isRunning

                        Repeater {
                            model: root.timePresets
                            delegate: Rectangle {
                                width: (parent.width - 28) / 8
                                height: 28
                                radius: Theme.cornerRadius
                                color: root.selectedDuration === modelData.minutes ? Theme.primary : Theme.surfaceContainerHigh

                                StyledText {
                                    text: modelData.label
                                    font.pixelSize: 12
                                    font.weight: root.selectedDuration === modelData.minutes ? Font.Bold : Font.Normal
                                    color: root.selectedDuration === modelData.minutes ? Theme.onPrimary : Theme.surfaceText
                                    anchors.centerIn: parent
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.selectedDuration = modelData.minutes;
                                }
                            }
                        }
                    }

                    Row {
                        width: parent.width
                        spacing: 8

                        DankButton {
                            text: root.isRunning ? (root.isPaused ? I18n.tr("Resume") : I18n.tr("Pause")) : I18n.tr("Start")
                            width: parent.width / 2 - 4
                            height: 40
                            iconName: root.isPaused ? "play_arrow" : (root.isRunning ? "pause" : "play_arrow")
                            onClicked: {
                                if (root.isRunning) {
                                    root.togglePause();
                                } else {
                                    root.startExercise();
                                }
                            }
                        }

                        DankButton {
                            text: I18n.tr("Stop")
                            width: parent.width / 2 - 4
                            height: 40
                            backgroundColor: (root.isRunning || root.breathPhase !== "") ? Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.15) : Theme.surfaceContainerHigh
                            textColor: (root.isRunning || root.breathPhase !== "") ? Theme.error : Theme.surfaceVariantText
                            iconName: "stop"
                            enabled: root.isRunning || root.breathPhase !== ""
                            onClicked: root.stopExercise()
                        }
                    }

                    DankButton {
                        visible: !root.isRunning
                        text: root.isTestingSound ? I18n.tr("Stop Test") : I18n.tr("Test Sound")
                        width: parent.width
                        height: 40
                        backgroundColor: root.isTestingSound ? Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.15) : Theme.surfaceContainerHigh
                        textColor: root.isTestingSound ? Theme.error : Theme.surfaceVariantText
                        iconName: root.isTestingSound ? "volume_off" : "volume_up"
                        onClicked: root.toggleTestSound()
                    }

                    // Volume slider
                    DankSlider {
                        visible: !root.isRunning
                        width: parent.width
                        leftIcon: "volume_down"
                        rightIcon: "volume_up"
                        minimum: 0
                        maximum: 100
                        value: root.soundVolume
                        unit: "%"
                        onSliderValueChanged: root.soundVolume = newValue
                    }
                }
                HintSection {
                    width: parent.width
                    showHints: root.showHints

                    HintItem {
                        icon: "mouse"
                        text: I18n.tr("Right-click bar icon to quickly toggle Start/Pause.")
                    }
                    HintItem {
                        icon: "mouse"
                        text: I18n.tr("Double-click an exercise tile to start it immediately.")
                    }
                    HintItem {
                        icon: "keyboard"
                        text: I18n.tr("Press 'Space' to Pause/Resume, 'R' to Reset.")
                    }
                }
            }
        }
    }
}