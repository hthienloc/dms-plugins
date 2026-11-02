import QtQuick
import Quickshell
import qs.Common
import qs.Services
import qs.DCommon.Widgets
import qs.Modules.Plugins
import qs.Modules.DDash
import qs.Widgets
import "./shared"

DashCardComponent {
    id: root

    readonly property var playingSounds: root.pluginData?.playingSounds || []
    readonly property int playingCount: playingSounds.length
    readonly property bool isPlayingActive: playingCount > 0
    readonly property bool isMuted: root.pluginData?.isMuted ?? false
    readonly property int masterVolume: Number(root.pluginData?.masterVolume ?? 100)
    readonly property string selectedPresetName: root.pluginData?.selectedPreset || ""
    readonly property var presets: root.pluginData?.presets || []

    readonly property var ambientVars: PluginService.globalVars[root.pluginId || "ambientSound"]
    readonly property int timerRemainingMs: Number(ambientVars?.ambientSoundTimerRemaining) || 0
    readonly property bool isTimerActive: timerRemainingMs > 0

    function sendAction(actionObj) {
        actionObj._seq = Date.now() + Math.random();
        PluginService.setGlobalVar(root.pluginId || "ambientSound", "ambientSoundDashAction", JSON.stringify(actionObj));
    }

    function togglePlayPause() {
        sendAction({ type: "togglePlayPause" });
    }

    function setPreset(name) {
        sendAction({ type: "loadPreset", name: name });
    }

    function adjustMasterVolume(delta) {
        var current = root.masterVolume;
        var next = Math.max(0, Math.min(100, current + delta));
        if (next !== current) {
            sendAction({ type: "setMasterVolume", value: next });
        }
    }

    function cycleSleepTimer() {
        // Toggle through 15m -> 30m -> 60m -> cancel
        if (!root.isTimerActive) {
            sendAction({ type: "timerStart", minutes: 30 });
        } else {
            var currentMins = Math.round(root.timerRemainingMs / 60000);
            if (currentMins <= 15) {
                sendAction({ type: "timerStart", minutes: 30 });
            } else if (currentMins <= 30) {
                sendAction({ type: "timerStart", minutes: 60 });
            } else {
                sendAction({ type: "timerCancel" });
            }
        }
    }

    opensTab: true
    clickable: false
    focusTarget: playArcBtn
    pad: Theme.spacingM
    title: ""

    // Centered single row minimal layout
    Row {
        anchors.centerIn: parent
        width: parent.width
        height: Math.min(parent.height, 56)
        spacing: Theme.spacingM

        // 1. Play / Pause Button wrapped with Arc Volume Ring (Scroll to adjust volume)
        Item {
            id: playArcBtn
            width: 48
            height: 48
            anchors.verticalCenter: parent.verticalCenter

            Canvas {
                id: arcCanvas
                anchors.fill: parent
                antialiasing: true

                Connections {
                    target: root
                    function onMasterVolumeChanged() { arcCanvas.requestPaint(); }
                    function onIsPlayingActiveChanged() { arcCanvas.requestPaint(); }
                    function onIsMutedChanged() { arcCanvas.requestPaint(); }
                }

                onPaint: {
                    var ctx = getContext("2d");
                    ctx.reset();
                    ctx.clearRect(0, 0, width, height);

                    var cx = width / 2;
                    var cy = height / 2;
                    var radius = (Math.min(width, height) - 6) / 2;
                    var lw = 3.2;

                    var startAngle = Math.PI * 0.75; // 135 deg
                    var endAngle = Math.PI * 2.25;   // 405 deg
                    var span = Math.PI * 1.5;        // 270 deg

                    ctx.lineWidth = lw;
                    ctx.lineCap = "round";

                    // Track
                    ctx.beginPath();
                    ctx.strokeStyle = Theme.withAlpha(Theme.surfaceVariantText, 0.22);
                    ctx.arc(cx, cy, radius, startAngle, endAngle, false);
                    ctx.stroke();

                    // Progress
                    var progress = root.isMuted ? 0 : Math.max(0.0, Math.min(1.0, root.masterVolume / 100.0));
                    if (progress > 0) {
                        ctx.beginPath();
                        ctx.strokeStyle = root.isPlayingActive ? Theme.primary : Theme.withAlpha(Theme.surfaceVariantText, 0.75);
                        var progEnd = startAngle + (progress * span);
                        ctx.arc(cx, cy, radius, startAngle, progEnd, false);
                        ctx.stroke();
                    }
                }
            }

            // Central Play / Pause Button
            Rectangle {
                width: 32
                height: 32
                radius: 16
                anchors.centerIn: parent
                color: root.isPlayingActive ? Theme.primary : (playMouse.containsMouse ? Theme.surfaceContainerHighest : Theme.surfaceContainerHigh)

                Behavior on color { ColorAnimation { duration: 120 } }

                DIcon {
                    anchors.centerIn: parent
                    name: root.isPlayingActive ? "pause" : "play_arrow"
                    size: 18
                    color: root.isPlayingActive ? Theme.primaryText : Theme.surfaceText
                }
            }

            // Mouse interaction: Click = Play/Pause, Wheel = Volume
            MouseArea {
                id: playMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.togglePlayPause()
                onWheel: (wheel) => {
                    var delta = wheel.angleDelta.y > 0 ? 5 : -5;
                    root.adjustMasterVolume(delta);
                }
            }
        }

        // 2. Preset Selector Dropdown (Fills available space)
        Item {
            height: Theme.buttonHeightS
            width: parent.width - playArcBtn.width - timerBtnContainer.width - parent.spacing * 2
            anchors.verticalCenter: parent.verticalCenter

            DDropdown {
                id: presetDropdown
                anchors.fill: parent
                compactMode: true
                dropdownWidth: Math.max(width, 180)
                emptyText: I18n.trFor("ambientSound", "Select preset…")
                options: root.presets.map(function(p) { return p.name; })
                currentValue: root.selectedPresetName

                Connections {
                    target: root
                    function onSelectedPresetNameChanged() {
                        presetDropdown.currentValue = root.selectedPresetName;
                    }
                }

                onValueChanged: (newValue) => {
                    if (newValue && newValue !== root.selectedPresetName) {
                        root.setPreset(newValue);
                    }
                }
            }
        }

        // 3. Sleep Timer Button with Countdown badge
        Item {
            id: timerBtnContainer
            width: root.isTimerActive ? timerBadgePill.implicitWidth : Theme.buttonHeightS
            height: Theme.buttonHeightS
            anchors.verticalCenter: parent.verticalCenter

            Behavior on width {
                NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
            }

            // Inactive Timer Icon Button
            DIconButton {
                anchors.fill: parent
                visible: !root.isTimerActive
                size: "s"
                variant: "filledTonal"
                iconName: "timer"
                tooltipText: I18n.trFor("ambientSound", "Set Sleep Timer (30m)")
                onClicked: root.cycleSleepTimer()
            }

            // Active Timer Pill (Shows MM:SS countdown, click to cycle/cancel)
            Rectangle {
                id: timerBadgePill
                visible: root.isTimerActive
                anchors.fill: parent
                radius: height / 2
                color: Theme.withAlpha(Theme.primary, 0.18)
                border.width: Theme.layerOutlineWidth
                border.color: Theme.withAlpha(Theme.primary, 0.4)
                implicitWidth: timerBadgeRow.implicitWidth + Theme.spacingM * 2

                Row {
                    id: timerBadgeRow
                    anchors.centerIn: parent
                    spacing: 4

                    DIcon {
                        name: "timer"
                        size: 13
                        color: Theme.primary
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    NumericText {
                        text: {
                            const totalSec = Math.max(0, Math.floor(root.timerRemainingMs / 1000));
                            const mins = Math.floor(totalSec / 60);
                            const secs = totalSec % 60;
                            return mins + ":" + (secs < 10 ? "0" : "") + secs;
                        }
                        reserveText: "00:00"
                        font.pixelSize: Theme.fontSizeSmall
                        font.weight: Font.Bold
                        color: Theme.primary
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: root.cycleSleepTimer()
                }
            }
        }
    }
}
