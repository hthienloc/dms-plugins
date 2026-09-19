import "./dms-common"
import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Modules.Plugins
import qs.Services
import qs.Widgets

PluginComponent {
    id: root

    readonly property var presets: {
        const raw = pluginData.presets || "1, 2, 5, 10, 15, 20, 25, 30, 45, 60, 90, 120";
        return raw.split(',').map((s) => {
            return parseInt(s.trim());
        }).filter((n) => {
            return !isNaN(n);
        });
    }
    readonly property string soundPath: pluginData.soundPath || ""
    readonly property bool useSystemNotificationSound: pluginData.useSystemNotificationSound ?? true
    readonly property bool showNotification: pluginData.showNotification ?? true
    readonly property string notificationTitle: pluginData.notificationTitle || "Timer"
    readonly property int buttonHeight: Theme.iconSizeLarge + Theme.spacingS
    readonly property int padding: Theme.spacingS
    readonly property int spacing: Theme.spacingS
    readonly property int fontSize: Theme.fontSizeMedium
    readonly property string notificationBody: pluginData.notificationBody || "Timeout!"
    readonly property string timeoutBehavior: pluginData.timeoutBehavior || "stay"
    readonly property string displayFormat: pluginData.displayFormat || "full"
    readonly property bool showPillIcon: pluginData.showPillIcon ?? true
    readonly property bool showReadyPlaceholder: pluginData.showReadyPlaceholder ?? true
    property string systemActionOnTimeout: pluginData.systemActionOnTimeout || "none"
    property string customCommandOnTimeout: pluginData.customCommandOnTimeout || ""
    // Derived helpers — icon/pulse modes are fixed layouts; others respect showPillIcon
    readonly property bool _pillHasIcon: displayFormat === "icon" || (showPillIcon && displayFormat !== "pulse")
    readonly property bool _pillIsIconOnly: displayFormat === "icon"
    readonly property bool _pillIsProgress: displayFormat === "progress"
    readonly property bool _pillIsPulse: displayFormat === "pulse"
    readonly property bool showHints: pluginData.showHints ?? true
    readonly property bool autoDND: pluginData.autoDND ?? false
    readonly property bool showTimeoutActions: pluginData.showTimeoutActions ?? true
    readonly property bool isFinished: globalRemainingMilliseconds.value === 0 && globalTotalSeconds.value > 0
    readonly property bool isPaused: !globalIsRunning.value && globalRemainingMilliseconds.value > 0 && globalRemainingSeconds.value < globalTotalSeconds.value
    readonly property bool isReady: globalRemainingMilliseconds.value === 0 && globalTotalSeconds.value === 0
    readonly property color pillColor: {
        if (globalIsRunning.value)
            return Theme.primary;

        if (isPaused || isFinished)
            return Theme.warning;

        return Theme.surfaceText;
    }
    readonly property int quickStartMinutes: {
        const val = parseInt(pluginData.quickStartMinutes);
        return (!isNaN(val) && val > 0) ? val : 25;
    }
    property var activePopoutReference: null
    property var manualInputInput: null

    function formatTime(totalSeconds) {
        const hours = Math.floor(totalSeconds / 3600);
        const minutes = Math.floor((totalSeconds % 3600) / 60);
        const seconds = totalSeconds % 60;
        if (root.displayFormat === "minimal") {
            if (hours > 0)
                return hours + "h " + minutes + "m";

            if (minutes > 0)
                return minutes + "m " + seconds + "s";

            return seconds + "s";
        }
        if (root.displayFormat === "compact") {
            let res = "";
            if (hours > 0)
                res += hours + "h ";

            if (minutes > 0 || hours > 0)
                res += minutes + "m ";

            res += seconds + "s";
            return res.trim();
        }
        // Full format (00:00:00)
        let result = "";
        if (hours > 0)
            result += hours.toString().padStart(2, '0') + ":";

        result += minutes.toString().padStart(2, '0') + ":" + seconds.toString().padStart(2, '0');
        return result;
    }

    function setTimer(minutes) {
        const durationMs = minutes * 60 * 1000;
        const seconds = Math.ceil(durationMs / 1000);
        globalTotalSeconds.set(seconds);
        globalRemainingMilliseconds.set(durationMs);
        globalRemainingSeconds.set(seconds);
        globalEndTimeMs.set(Date.now() + durationMs);
        globalIsRunning.set(true);
        root.closePopout();
    }

    function updateRemaining() {
        if (!globalIsRunning.value || globalEndTimeMs.value <= 0)
            return;

        const remainingMs = Math.max(0, globalEndTimeMs.value - Date.now());
        globalRemainingMilliseconds.set(remainingMs);
        globalRemainingSeconds.set(Math.ceil(remainingMs / 1000));

        if (remainingMs === 0) {
            globalIsRunning.set(false);
            globalEndTimeMs.set(0);
            handleTimeout();
        }
    }

    function handleTimeout() {
        if (root.showNotification)
            Proc.runCommand("timer-notify", ["notify-send", "-i", "appointment-soon", "-u", "normal", root.notificationTitle, root.notificationBody], null, 0);

        if (root.soundPath !== "")
            Proc.runCommand("timer-sound", ["paplay", "--property=media.role=event", root.soundPath], null, 0);
        else if (root.useSystemNotificationSound && AudioService.soundsAvailable)
            AudioService.playCriticalNotificationSound();
        else
            Proc.runCommand("timer-sound", ["paplay", "--property=media.role=event", "/usr/share/sounds/freedesktop/stereo/complete.oga"], null, 0);

        if (root.systemActionOnTimeout === "lock")
            Proc.runCommand("timer-lock", ["loginctl", "lock-session"], null, 0);
        else if (root.systemActionOnTimeout === "suspend")
            Proc.runCommand("timer-suspend", ["systemctl", "suspend"], null, 0);
        else if (root.systemActionOnTimeout === "hibernate")
            Proc.runCommand("timer-hibernate", ["systemctl", "hibernate"], null, 0);
        else if (root.systemActionOnTimeout === "poweroff")
            Proc.runCommand("timer-poweroff", ["systemctl", "poweroff"], null, 0);
        else if (root.systemActionOnTimeout === "custom" && root.customCommandOnTimeout !== "")
            Proc.runCommand("timer-custom-command", ["bash", "-c", root.customCommandOnTimeout], null, 0);

        if (root.timeoutBehavior === "reset")
            root.resetTimer();
    }

    function toggleTimer() {
        if (globalTotalSeconds.value === 0)
            return;

        if (isFinished) {
            resetTimer();
            return;
        }
        if (globalIsRunning.value) {
            updateRemaining();
            if (globalRemainingMilliseconds.value === 0)
                return;

            globalIsRunning.set(false);
            globalEndTimeMs.set(0);
        } else if (globalRemainingMilliseconds.value > 0) {
            globalEndTimeMs.set(Date.now() + globalRemainingMilliseconds.value);
            globalIsRunning.set(true);
        }
    }

    function resetTimer() {
        globalIsRunning.set(false);
        globalEndTimeMs.set(0);
        globalRemainingMilliseconds.set(0);
        globalRemainingSeconds.set(0);
        globalTotalSeconds.set(0);
    }

    pillClickAction: root.isReady ? null : () => {
        root.toggleTimer();
    }
    
    pillRightClickAction: () => {
        if (root.isReady)
            root.setTimer(root.quickStartMinutes);
        else
            root.resetTimer();
    }

    // Global variable to keep track of the timer's state across instances
    PluginGlobalVar {
        id: globalRemainingSeconds
        varName: "timerRemainingSeconds"
        defaultValue: 0
    }

    PluginGlobalVar {
        id: globalRemainingMilliseconds
        varName: "timerRemainingMilliseconds"
        defaultValue: 0
    }

    PluginGlobalVar {
        id: globalTotalSeconds
        varName: "timerTotalSeconds"
        defaultValue: 0
    }

    PluginGlobalVar {
        id: globalIsRunning
        varName: "timerIsRunning"
        defaultValue: false
    }

    PluginGlobalVar {
        id: globalEndTimeMs
        varName: "timerEndTimeMs"
        defaultValue: 0
    }

    Connections {
        target: root.autoDND ? SessionData : null
        function onIsDNDChanged() {
            // No-op, just here to make the binding reactive
        }
    }

    onAutoDNDChanged: {
        if (autoDND && globalIsRunning.value) {
            SessionData.isDND = true;
        } else if (!autoDND) {
            // Don't force DND off, just let it be
        }
    }

    // Ensure DND follows timer state if autoDND is enabled
    Connections {
        target: globalIsRunning
        function onValueChanged() {
            if (root.autoDND) {
                if (globalIsRunning.value) {
                    SessionData.isDND = true;
                } else if (globalRemainingSeconds.value === 0) {
                    SessionData.isDND = false;
                }
            }
        }
    }

    Timer {
        id: timer

        interval: 100
        repeat: true
        running: globalIsRunning.value && globalRemainingMilliseconds.value > 0
        onTriggered: {
            root.updateRemaining();
        }
    }

    IpcHandler {
        function toggle() : string {
            root.updateRemaining();
            if (root.isReady) {
                root.setTimer(root.quickStartMinutes);
                return "STARTED (" + root.quickStartMinutes + "m)";
            } else if (root.isFinished) {
                root.resetTimer();
                return "RESET";
            } else {
                const nextState = !globalIsRunning.value;
                root.toggleTimer();
                return nextState ? "RUNNING" : "PAUSED";
            }
        }

        function pause() : string {
            root.updateRemaining();
            if (globalIsRunning.value) {
                root.toggleTimer();
                return "PAUSED";
            }
            return "ALREADY_PAUSED";
        }

        function resume() : string {
            root.updateRemaining();
            if (root.isReady) {
                root.setTimer(root.quickStartMinutes);
                return "STARTED (" + root.quickStartMinutes + "m)";
            }
            if (root.isFinished) {
                return "ERROR: timer is finished";
            }
            if (!globalIsRunning.value) {
                root.toggleTimer();
                return "RUNNING";
            }
            return "ALREADY_RUNNING";
        }

        function reset() : string {
            root.resetTimer();
            return "RESET";
        }

        function start(minutes: string) : string {
            const m = parseInt(minutes);
            if (isNaN(m) || m <= 0) return "ERROR: invalid minutes";
            root.setTimer(m);
            return "STARTED (" + m + "m)";
        }

        function status() : string {
            root.updateRemaining();
            if (root.isReady) return "ready";
            if (root.isFinished) return "finished";
            if (!globalIsRunning.value) return "paused";
            return "running";
        }

        function getStatus() : string {
            root.updateRemaining();
            const data = {
                "state": status(),
                "remaining": globalRemainingSeconds.value,
                "total": globalTotalSeconds.value,
                "formatted": root.formatTime(globalRemainingSeconds.value)
            };
            return JSON.stringify(data);
        }

        target: "timer"
        enabled: true
    }

    horizontalBarPill: Component {
        Item {
            implicitWidth: root._pillIsPulse ? (Theme.iconSizeSmall) : pillRow.implicitWidth
            implicitHeight: root._pillIsPulse ? (Theme.iconSizeSmall) : pillRow.implicitHeight

            Row {
                id: pillRow
                spacing: (root._pillHasIcon && !root._pillIsIconOnly && !root._pillIsPulse) ? Theme.spacingS : 0
                visible: !root._pillIsPulse

                DankIcon {
                    name: globalIsRunning.value ? "pause" : (root.isReady ? "timer" : "play_arrow")
                    size: Theme.iconSizeSmall
                    color: root.pillColor
                    anchors.verticalCenter: parent.verticalCenter
                    visible: root._pillHasIcon
                }

                StyledText {
                    text: formatTime(globalRemainingSeconds.value)
                    color: root.pillColor
                    font.pixelSize: Theme.fontSizeMedium
                    isMonospace: true
                    anchors.verticalCenter: parent.verticalCenter
                    visible: !root._pillIsIconOnly && !root._pillIsProgress && (!root.isReady || root.showReadyPlaceholder)
                }

                Item {
                    width: 56
                    height: 6
                    anchors.verticalCenter: parent.verticalCenter
                    visible: root._pillIsProgress && !root.isReady

                    Rectangle {
                        anchors.fill: parent
                        radius: 3
                        color: root.pillColor
                        opacity: 0.2
                    }

                    Rectangle {
                        width: parent.width * (1 - (globalRemainingMilliseconds.value / Math.max(1, globalTotalSeconds.value * 1000)))
                        height: parent.height
                        radius: 3
                        color: root.pillColor
                    }
                }
            }

            Item {
                property real progress: globalRemainingMilliseconds.value / Math.max(1, globalTotalSeconds.value * 1000)
                property int beatMs: root.isReady || root.isFinished ? 2000 : Math.max(400, Math.min(2000, Math.round(400 + progress * 1600)))

                anchors.centerIn: parent
                width: Theme.iconSizeSmall
                height: Theme.iconSizeSmall
                visible: root._pillIsPulse

                Rectangle {
                    id: pulseDot
                    property real scale: 1
                    anchors.centerIn: parent
                    width: Theme.iconSizeSmall * scale
                    height: width
                    radius: width / 2
                    color: root.pillColor

                    SequentialAnimation on scale {
                        loops: Animation.Infinite
                        running: globalIsRunning.value && !root.isReady
                        NumberAnimation { to: 1.4; duration: parent.parent.beatMs / 2; easing.type: Easing.InOutSine }
                        NumberAnimation { to: 1; duration: parent.parent.beatMs / 2; easing.type: Easing.InOutSine }
                    }
                }
            }
        }
    }

    popoutWidth: 400
    popoutHeight: {
        let baseHeight = root.showHints ? 385 : 335;
        if (!root.showTimeoutActions) {
            baseHeight -= 120;
        }
        const presetRows = Math.ceil(root.presets.length / 4);
        const extraRows = Math.max(0, presetRows - 3);
        return baseHeight + (extraRows * 42);
    }

    popoutContent: Component {
        PopoutComponent {
            id: popout
            headerText: I18n.tr("Timer")
            showCloseButton: true

            Column {
                width: parent.width
                spacing: Theme.spacingM

                StyledText {
                    text: I18n.tr("Select a preset or enter minutes")
                    font.pixelSize: Theme.fontSizeMedium
                    color: Theme.surfaceVariantText
                    horizontalAlignment: Text.AlignHCenter
                    width: parent.width
                }

                // Presets Grid
                Flow {
                    width: parent.width
                    spacing: Theme.spacingS
                    layoutDirection: Qt.LeftToRight

                    Repeater {
                        model: root.presets
                        delegate: DankButton {
                            text: modelData + "m"
                            width: (parent.width - (Theme.spacingS * 3)) / 4
                            backgroundColor: Theme.primary
                            textColor: Theme.onPrimary
                            onClicked: {
                                root.setTimer(modelData);
                                globalIsRunning.set(true);
                                root.closePopout();
                            }
                        }
                    }
                }

                // Custom Input
                Row {
                    width: parent.width
                    spacing: Theme.spacingS

                    DankTextField {
                        id: customInput
                        placeholderText: "Minutes..."
                        width: parent.width - setBtn.width - parent.spacing
                        validator: IntValidator { bottom: 1; top: 1440 }
                        Component.onCompleted: {
                            root.manualInputInput = customInput;
                            customInput.forceActiveFocus();
                        }
                        onAccepted: setBtn.clicked()
                    }

                    DankButton {
                        id: setBtn
                        text: I18n.tr("Set")
                        iconName: "play_arrow"
                        onClicked: {
                            const mins = parseInt(customInput.text);
                            if (!isNaN(mins) && mins > 0) {
                                root.setTimer(mins);
                                globalIsRunning.set(true);
                                root.closePopout();
                            }
                        }
                    }
                }

                // Quick Actions Section
                Column {
                    width: parent.width
                    spacing: Theme.spacingS
                    visible: root.showTimeoutActions

                    Separator { opacity: 0.1 }

                    StyledText {
                        text: I18n.tr("When Done")
                        font.pixelSize: Theme.fontSizeSmall
                        font.weight: Font.Bold
                        color: Theme.primary
                    }

                    Row {
                        spacing: 4
                        anchors.horizontalCenter: parent.horizontalCenter

                        Repeater {
                            model: [{
                                "label": I18n.tr("None"),
                                "value": "none",
                                "icon": "block"
                            }, {
                                "label": I18n.tr("Lock"),
                                "value": "lock",
                                "icon": "lock"
                            }, {
                                "label": I18n.tr("Sleep"),
                                "value": "suspend",
                                "icon": "snooze"
                            }, {
                                "label": I18n.tr("Hibernate"),
                                "value": "hibernate",
                                "icon": "nights_stay"
                            }, {
                                "label": I18n.tr("Shutdown"),
                                "value": "poweroff",
                                "icon": "power_settings_new"
                            }, {
                                "label": I18n.tr("Custom"),
                                "value": "custom",
                                "icon": "code"
                            }]

                            delegate: Rectangle {
                                width: 58
                                height: 42
                                radius: Theme.cornerRadius
                                color: root.systemActionOnTimeout === modelData.value ? Theme.primary : Theme.surfaceContainerHigh

                                Column {
                                    anchors.centerIn: parent
                                    spacing: 2

                                    DankIcon {
                                        name: modelData.icon
                                        size: 16
                                        color: root.systemActionOnTimeout === modelData.value ? Theme.onPrimary : Theme.surfaceText
                                        anchors.horizontalCenter: parent.horizontalCenter
                                    }

                                    StyledText {
                                        text: modelData.label
                                        font.pixelSize: 9
                                        font.weight: Font.Medium
                                        color: root.systemActionOnTimeout === modelData.value ? Theme.onPrimary : Theme.surfaceText
                                        anchors.horizontalCenter: parent.horizontalCenter
                                    }

                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        root.systemActionOnTimeout = modelData.value;
                                        pluginService.savePluginData(root.pluginId, "systemActionOnTimeout", modelData.value);
                                    }
                                }

                            }

                        }

                    }

                    DankTextField {
                        id: cmdInput

                        width: parent.width - 24
                        anchors.horizontalCenter: parent.horizontalCenter
                        placeholderText: I18n.tr("Custom shell command...")
                        showClearButton: true
                        text: root.customCommandOnTimeout
                        visible: root.systemActionOnTimeout === "custom"
                        onTextChanged: {
                            root.customCommandOnTimeout = text;
                            pluginService.savePluginData(root.pluginId, "customCommandOnTimeout", text);
                        }
                    }

                }

                HintSection {
                    width: parent.width
                    showHints: root.showHints

                    HintItem {
                        icon: "mouse"
                        text: I18n.tr("Left-click to Pause/Resume, Right-click to Reset (Quick Start when ready).")
                    }
                }
            }
        }
    }

}
