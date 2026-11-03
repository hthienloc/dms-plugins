import QtQuick
import QtMultimedia
import Quickshell
import Quickshell.Io
import qs.Common
import qs.DCommon.Widgets
import qs.Modules.Plugins
import qs.Services

PluginComponent {
    id: pluginRoot

    property int shortBreakInterval: pluginData.shortBreakInterval ?? 20 // minutes
    property int shortBreakDuration: pluginData.shortBreakDuration ?? 20 // seconds
    property int shortBreaksBeforeLong: pluginData.shortBreaksBeforeLong ?? 3 // count
    property int longBreakDuration: pluginData.longBreakDuration ?? 5 // minutes

    property int preWarningTime: pluginData.preWarningTime ?? 5 // seconds
    property real preWarningOpacity: (pluginData.preWarningOpacity ?? 100) / 100

    property bool soundEnabled: pluginData.soundEnabled ?? true
    property real soundVolume: (pluginData.soundVolume ?? 80) / 100

    property int completedShortBreaks: 0
    property bool suppressFullscreen: pluginData.suppressFullscreen ?? true
    property bool suppressMeetings: pluginData.suppressMeetings ?? true

    // Only the elected instance drives the shared timer state.
    property bool isActiveInstance: false

    property int nextBreakType: 0 // 0 for none, 1 for short, 2 for long
    property int timeToNextBreak: 0 // seconds
    property int breakTimeRemaining: 0 // seconds

    property bool isPreWarning: false
    property bool isBreakActive: false
    property bool isPaused: pluginData.isPaused ?? false
    property bool pauseMusic: pluginData.pauseMusic ?? false
    property var pausedPlayers: []

    pluginId: "takeABreak"
    pluginService: PluginService

    // ── Statistics ──────────────────────────────────────────────────────────
    function logEvent(status) {
        try {
            var raw = pluginService ? pluginService.loadPluginState(pluginId, "events", []) : [];
            var events = Array.isArray(raw) ? raw.slice() : [];
            var type = pluginRoot.nextBreakType === 1 ? "short" : "long";
            var ts = Math.floor(Date.now() / 1000);
            events.push({ ts: ts, type: type, status: status });
            if (events.length > 1000) {
                events = events.slice(events.length - 1000);
            }
            if (pluginService) {
                pluginService.savePluginState(pluginId, "events", events);
            }
            pluginRoot.getStats();
        } catch (e) {
            console.warn("[TakeABreak] Failed to log event:", e);
        }
    }

    function resetStats() {
        try {
            if (pluginService) {
                pluginService.savePluginState(pluginId, "events", []);
            }
            pluginRoot.getStats();
        } catch (e) {
            console.warn("[TakeABreak] Failed to reset stats:", e);
        }
    }

    function getStats() {
        try {
            var raw = pluginService ? pluginService.loadPluginState(pluginId, "events", []) : [];
            var events = Array.isArray(raw) ? raw : [];
            var now = new Date();
            var todayStart = new Date(now.getFullYear(), now.getMonth(), now.getDate()).getTime() / 1000;
            var weekStart = todayStart - 6 * 86400;
            var todayTotal = 0, todayCompleted = 0, todaySkipped = 0, todaySnoozed = 0;
            var weekTotal = 0, weekCompleted = 0, weekSkipped = 0, weekSnoozed = 0;
            for (var i = 0; i < events.length; i++) {
                var e = events[i];
                if (e.ts >= todayStart) {
                    todayTotal++;
                    if (e.status === "completed") todayCompleted++;
                    else if (e.status === "skipped") todaySkipped++;
                    else if (e.status === "snoozed") todaySnoozed++;
                }
                if (e.ts >= weekStart) {
                    weekTotal++;
                    if (e.status === "completed") weekCompleted++;
                    else if (e.status === "skipped") weekSkipped++;
                    else if (e.status === "snoozed") weekSnoozed++;
                }
            }
            var todayResponded = todayCompleted + todaySkipped + todaySnoozed;
            var weekResponded = weekCompleted + weekSkipped + weekSnoozed;
            pluginRoot._stats = {
                todayRate: todayResponded > 0 ? Math.round(todayCompleted / todayResponded * 100) : -1,
                todayCompleted: todayCompleted,
                todaySkipped: todaySkipped,
                todaySnoozed: todaySnoozed,
                todayTotal: todayTotal,
                weekRate: weekResponded > 0 ? Math.round(weekCompleted / weekResponded * 100) : -1,
                weekCompleted: weekCompleted,
                weekSkipped: weekSkipped,
                weekSnoozed: weekSnoozed,
                weekTotal: weekTotal,
                totalAll: events.length
            };
            if (typeof _onStatsReady === "function") _onStatsReady();
        } catch (e) {
            console.warn("[TakeABreak] Failed to parse stats:", e);
        }
    }
    property var _stats: null
    property var _onStatsReady: null

    readonly property var masterInstance: (isActiveInstance) ? pluginRoot : PluginService.getGlobalVar(pluginId, "instance")

    // Control Center Integration
    ccWidgetIcon: {
        const master = pluginRoot.masterInstance;
        if (master && master.isPaused) return "pause";
        return "self_improvement";
    }
    ccWidgetPrimaryText: I18n.trFor("takeABreak", "Take a Break")
    ccWidgetSecondaryText: {
        const master = pluginRoot.masterInstance;
        if (!master) return "";
        if (master.isPaused) return I18n.trFor("takeABreak", "Paused");
        
        let total = master.isBreakActive ? master.breakTimeRemaining : master.timeToNextBreak;
        let m = Math.floor(total / 60);
        let s = total % 60;
        let timeStr = `${m}:${s < 10 ? '0' : ''}${s}`;
        
        return master.isBreakActive ? I18n.trFor("takeABreak", "Break: %1").arg(timeStr) : timeStr;
    }
    ccWidgetIsActive: masterInstance ? !masterInstance.isPaused : true
    ccDetailHeight: 310

    function setPaused(paused) {
        const master = pluginRoot.masterInstance;
        if (!master)
            return;
        master.isPaused = paused;
        pluginService?.savePluginData(pluginId, "isPaused", paused);
    }

    function togglePaused() {
        const master = pluginRoot.masterInstance;
        if (master)
            setPaused(!master.isPaused);
    }

    onCcWidgetToggled: {
        pluginRoot.togglePaused();
    }

    ccDetailContent: Component {
        Item {
            id: detailRoot

            readonly property var master: pluginRoot.masterInstance
            readonly property var statsData: detailRoot.master?._stats ?? pluginRoot._stats
            readonly property bool isBreak: !!(detailRoot.master && (detailRoot.master.isBreakActive || detailRoot.master.isPreWarning))
            readonly property bool isPaused: !!(detailRoot.master && detailRoot.master.isPaused)

            implicitHeight: contentColumn.implicitHeight

            function refreshStats() {
                if (detailRoot.master && typeof detailRoot.master.getStats === "function") {
                    detailRoot.master.getStats();
                } else {
                    pluginRoot.getStats();
                }
            }

            Component.onCompleted: {
                detailRoot.refreshStats();
            }

            Column {
                id: contentColumn
                anchors.left: parent.left
                anchors.right: parent.right
                spacing: Theme.spacingM

                // Hero Status & Timer Card
                Rectangle {
                    width: parent.width
                    height: 116
                    radius: Theme.cornerRadius
                    color: detailRoot.isBreak
                        ? Theme.withAlpha(Theme.primary, 0.12)
                        : Theme.surfaceContainerHigh
                    border.color: detailRoot.isBreak
                        ? Theme.withAlpha(Theme.primary, 0.4)
                        : Theme.withAlpha(Theme.outline, 0.12)
                    border.width: 1

                    Behavior on color { ColorAnimation { duration: Theme.shortDuration } }
                    Behavior on border.color { ColorAnimation { duration: Theme.shortDuration } }

                    Column {
                        id: heroColumn
                        anchors.fill: parent
                        anchors.margins: Theme.spacingM
                        spacing: Theme.spacingXS

                        // Top row: Status info & Cycle indicator
                        Item {
                            width: parent.width
                            height: 20

                            Row {
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: Theme.spacingXS

                                DIcon {
                                    name: {
                                        if (detailRoot.isPaused) return "pause_circle";
                                        if (detailRoot.isBreak) return "self_improvement";
                                        if (detailRoot.master?.isPreWarning) return "notifications_active";
                                        return "timer";
                                    }
                                    size: Theme.iconSizeSmall
                                    color: detailRoot.isBreak ? Theme.primary : (detailRoot.master?.isPreWarning ? Theme.warning : Theme.surfaceVariantText)
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                StyledText {
                                    text: {
                                        if (!detailRoot.master) return "";
                                        if (detailRoot.isPaused) return I18n.trFor("takeABreak", "Paused");
                                        if (detailRoot.master.isBreakActive) {
                                            return detailRoot.master.nextBreakType === 1
                                                ? I18n.trFor("takeABreak", "Short Break Active")
                                                : I18n.trFor("takeABreak", "Long Break Active");
                                        }
                                        if (detailRoot.master.isPreWarning) {
                                            return I18n.trFor("takeABreak", "Break Incoming");
                                        }
                                        return detailRoot.master.nextBreakType === 1
                                            ? I18n.trFor("takeABreak", "Next: Short Break")
                                            : I18n.trFor("takeABreak", "Next: Long Break");
                                    }
                                    font.pixelSize: Theme.fontSizeSmall
                                    font.weight: Font.Medium
                                    color: detailRoot.isBreak ? Theme.primary : (detailRoot.master?.isPreWarning ? Theme.warning : Theme.surfaceVariantText)
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            // Cycle indicators
                            Row {
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 5

                                Repeater {
                                    model: (detailRoot.master?.shortBreaksBeforeLong ?? 3)

                                    Rectangle {
                                        required property int index
                                        readonly property bool isCompleted: (detailRoot.master?.completedShortBreaks ?? 0) > index
                                        readonly property bool isCurrent: (detailRoot.master?.completedShortBreaks ?? 0) === index && !(detailRoot.master?.isBreakActive && detailRoot.master?.nextBreakType === 2)

                                        width: isCurrent ? 16 : 6
                                        height: 6
                                        radius: 3
                                        color: (isCompleted || isCurrent) ? Theme.primary : Theme.withAlpha(Theme.surfaceVariantText, 0.3)
                                        opacity: (isCompleted || isCurrent) ? 1.0 : 0.6

                                        Behavior on width { NumberAnimation { duration: Theme.shortDuration } }
                                        Behavior on color { ColorAnimation { duration: Theme.shortDuration } }
                                    }
                                }

                                Rectangle {
                                    readonly property bool isLongBreak: (detailRoot.master?.nextBreakType === 2)
                                    width: 16
                                    height: 6
                                    radius: 3
                                    color: isLongBreak ? Theme.primary : Theme.withAlpha(Theme.surfaceVariantText, 0.3)
                                    opacity: isLongBreak ? 1.0 : 0.6

                                    Behavior on color { ColorAnimation { duration: Theme.shortDuration } }
                                }
                            }
                        }

                        // Big Countdown Text
                        Item {
                            width: parent.width
                            height: 48

                            StyledText {
                                anchors.centerIn: parent
                                text: {
                                    if (!detailRoot.master) return "0:00";
                                    const total = detailRoot.master.isBreakActive
                                        ? detailRoot.master.breakTimeRemaining
                                        : detailRoot.master.timeToNextBreak;
                                    const m = Math.floor(total / 60);
                                    const s = total % 60;
                                    return `${m}:${s < 10 ? "0" : ""}${s}`;
                                }
                                font.pixelSize: Theme.fontSizeDisplay
                                font.weight: Font.Bold
                                isMonospace: true
                                color: {
                                    if (detailRoot.isPaused) return Theme.surfaceVariantText;
                                    if (detailRoot.isBreak) return Theme.primary;
                                    return Theme.surfaceText;
                                }
                            }
                        }

                        // Progress Bar Track & Fill
                        Rectangle {
                            width: parent.width
                            height: Theme.spacingXS
                            radius: height / 2
                            color: Theme.surfaceContainerHighest
                            clip: true

                            Rectangle {
                                anchors.left: parent.left
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                radius: 2
                                color: detailRoot.isBreak
                                    ? Theme.primary
                                    : (detailRoot.isPaused ? Theme.surfaceVariantText : Theme.primary)

                                width: {
                                    if (!detailRoot.master || detailRoot.isPaused) return 0;
                                    let pct = 0;
                                    if (detailRoot.master.isBreakActive) {
                                        const duration = detailRoot.master.nextBreakType === 1
                                            ? detailRoot.master.shortBreakDuration
                                            : detailRoot.master.longBreakDuration * 60;
                                        pct = duration > 0 ? (detailRoot.master.breakTimeRemaining / duration) : 0;
                                    } else {
                                        const interval = detailRoot.master.shortBreakInterval * 60;
                                        pct = interval > 0 ? 1 - (detailRoot.master.timeToNextBreak / interval) : 0;
                                    }
                                    return parent.width * Math.max(0, Math.min(1, pct));
                                }

                                Behavior on width {
                                    NumberAnimation { duration: 250; easing.type: Easing.OutQuad }
                                }
                            }
                        }
                    }
                }

                // Primary Actions Row
                Row {
                    width: parent.width
                    spacing: Theme.spacingM

                    DButton {
                        width: (parent.width - parent.spacing) / 2
                        buttonHeight: 38
                        iconName: detailRoot.isBreak ? "snooze" : (detailRoot.isPaused ? "play_arrow" : "pause")
                        text: detailRoot.isBreak ? I18n.trFor("takeABreak", "Snooze 5m") : (detailRoot.isPaused ? I18n.trFor("takeABreak", "Resume") : I18n.trFor("takeABreak", "Pause"))
                        backgroundColor: (!detailRoot.isBreak && detailRoot.isPaused) ? Theme.primary : Theme.surfaceContainerHigh
                        textColor: (!detailRoot.isBreak && detailRoot.isPaused) ? Theme.onPrimary : Theme.surfaceText
                        onClicked: {
                            if (detailRoot.isBreak) {
                                if (detailRoot.master) detailRoot.master.snoozeBreak();
                            } else {
                                pluginRoot.togglePaused();
                            }
                        }
                    }

                    DButton {
                        width: (parent.width - parent.spacing) / 2
                        buttonHeight: 38
                        iconName: detailRoot.isBreak ? "skip_next" : "self_improvement"
                        text: detailRoot.isBreak ? I18n.trFor("takeABreak", "Skip") : I18n.trFor("takeABreak", "Take Break")
                        backgroundColor: detailRoot.isBreak ? Theme.primary : Theme.surfaceContainerHigh
                        textColor: detailRoot.isBreak ? Theme.onPrimary : Theme.surfaceText
                        enabled: detailRoot.isBreak || !detailRoot.isPaused
                        onClicked: {
                            if (detailRoot.isBreak) {
                                if (detailRoot.master) detailRoot.master.skipBreak();
                            } else {
                                if (detailRoot.master) detailRoot.master.startBreak();
                            }
                        }
                    }
                }

                // Statistics & Health Metrics Card
                Rectangle {
                    width: parent.width
                    height: 64
                    radius: Theme.cornerRadius
                    color: Theme.surfaceContainer
                    border.color: Theme.withAlpha(Theme.outline, 0.12)
                    border.width: 1

                    Row {
                        anchors.fill: parent
                        anchors.margins: Theme.spacingS

                        // Tile 1: Adherence Rate
                        Item {
                            width: (parent.width - 2) / 3
                            height: parent.height

                            Column {
                                anchors.centerIn: parent
                                spacing: 2

                                StyledText {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: {
                                        const s = detailRoot.statsData;
                                        if (!s || s.todayRate < 0) return "—";
                                        return s.todayRate + "%";
                                    }
                                    font.pixelSize: Theme.fontSizeMedium
                                    font.weight: Font.Bold
                                    color: {
                                        const s = detailRoot.statsData;
                                        if (!s || s.todayRate < 0) return Theme.surfaceVariantText;
                                        return s.todayRate >= 80 ? Theme.success : (s.todayRate >= 50 ? Theme.warning : Theme.error);
                                    }
                                }

                                StyledText {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: I18n.trFor("takeABreak", "Adherence")
                                    font.pixelSize: Theme.fontSizeSmall
                                    color: Theme.surfaceVariantText
                                }
                            }
                        }

                        // Divider 1
                        Rectangle {
                            width: 1
                            height: parent.height - Theme.spacingS
                            anchors.verticalCenter: parent.verticalCenter
                            color: Theme.withAlpha(Theme.outline, 0.12)
                        }

                        // Tile 2: Today Breaks
                        Item {
                            width: (parent.width - 2) / 3
                            height: parent.height

                            Column {
                                anchors.centerIn: parent
                                spacing: 2

                                StyledText {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: {
                                        const s = detailRoot.statsData;
                                        if (!s || s.todayRate < 0) return "0 / 0";
                                        return s.todayCompleted + " / " + s.todayTotal;
                                    }
                                    font.pixelSize: Theme.fontSizeMedium
                                    font.weight: Font.Bold
                                    color: Theme.surfaceText
                                }

                                StyledText {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: I18n.trFor("takeABreak", "Today Done")
                                    font.pixelSize: Theme.fontSizeSmall
                                    color: Theme.surfaceVariantText
                                }
                            }
                        }

                        // Divider 2
                        Rectangle {
                            width: 1
                            height: parent.height - Theme.spacingS
                            anchors.verticalCenter: parent.verticalCenter
                            color: Theme.withAlpha(Theme.outline, 0.12)
                        }

                        // Tile 3: This Week
                        Item {
                            width: (parent.width - 2) / 3
                            height: parent.height

                            Column {
                                anchors.centerIn: parent
                                spacing: 2

                                StyledText {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: {
                                        const s = detailRoot.statsData;
                                        if (!s || s.weekRate < 0) return "0";
                                        return String(s.weekCompleted);
                                    }
                                    font.pixelSize: Theme.fontSizeMedium
                                    font.weight: Font.Bold
                                    color: Theme.primary
                                }

                                StyledText {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: I18n.trFor("takeABreak", "This Week")
                                    font.pixelSize: Theme.fontSizeSmall
                                    color: Theme.surfaceVariantText
                                }
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: detailRoot.refreshStats()
                    }
                }

                // Secondary Utility Row
                Row {
                    width: parent.width
                    spacing: Theme.spacingM

                    DButton {
                        width: (parent.width - parent.spacing * 2) / 3
                        buttonHeight: 32
                        iconName: "more_time"
                        text: I18n.trFor("takeABreak", "+5m")
                        backgroundColor: Theme.surfaceContainerHigh
                        textColor: Theme.surfaceText
                        enabled: !detailRoot.isBreak && !detailRoot.isPaused
                        onClicked: {
                            if (detailRoot.master)
                                detailRoot.master.timeToNextBreak += 300;
                        }
                    }

                    DButton {
                        width: (parent.width - parent.spacing * 2) / 3
                        buttonHeight: 32
                        iconName: "refresh"
                        text: I18n.trFor("takeABreak", "Reset")
                        backgroundColor: Theme.surfaceContainerHigh
                        textColor: Theme.surfaceText
                        onClicked: {
                            if (detailRoot.master)
                                detailRoot.master.resetSession();
                        }
                    }

                    DButton {
                        width: (parent.width - parent.spacing * 2) / 3
                        buttonHeight: 32
                        iconName: "settings"
                        text: I18n.trFor("takeABreak", "Settings")
                        backgroundColor: Theme.surfaceContainerHigh
                        textColor: Theme.surfaceText
                        onClicked: PopoutService.openSettingsWithTab("plugins")
                    }
                }
            }
        }
    }

    IpcHandler {
        target: "takeABreak"
        
        function preview(type: string): string {
            if (type === "prewarning") {
                if (pluginRoot.isPreWarning && preWarningWindow && preWarningWindow.visible) {
                    pluginRoot.isPreWarning = false;
                    preWarningWindow.visible = false;
                    return "Hiding pre-warning preview";
                }
                pluginRoot.isPreWarning = true;
                pluginRoot.showPreWarning();
                return "Showing pre-warning preview";
            } else if (type === "overlay") {
                if (pluginRoot.isBreakActive && overlayWindow && overlayWindow.visible) {
                    pluginRoot.isBreakActive = false;
                    pluginRoot.closeBreakOverlay();
                    return "Hiding overlay preview";
                }
                pluginRoot.isBreakActive = true;
                pluginRoot.showBreakOverlay();
                return "Showing overlay preview";
            }
            return "Usage: preview prewarning|overlay";
        }

        function play_sound(type: string): string {
            pluginRoot.playSound(type || "start");
            return "Playing sound: " + (type || "start");
        }
    }

    // Audio
    MediaPlayer {
        id: alertPlayer
        audioOutput: AudioOutput {
            volume: pluginRoot.soundVolume
        }
    }

    function playSound(type) {
        if (!pluginRoot.soundEnabled) return;
        if (typeof AudioService === "undefined" || !AudioService || !AudioService.soundsAvailable) return;
        
        alertPlayer.stop();
        if (type === "start") {
            alertPlayer.source = AudioService.getSoundPath("message");
        } else {
            alertPlayer.source = AudioService.getSoundPath("audio-volume-change");
        }
        alertPlayer.play();
    }

    // Timers
    Timer {
        id: sessionTimer
        interval: 1000
        repeat: true
        running: isActiveInstance && !pluginRoot.isBreakActive && !pluginRoot.isPaused
        onTriggered: {
            pluginRoot.timeToNextBreak -= 1;

            if (pluginRoot.timeToNextBreak <= pluginRoot.preWarningTime) {
                if (shouldSuppress()) {
                    pluginRoot.snoozeBreak();
                    return;
                }
                if (pluginRoot.preWarningTime > 0 && !pluginRoot.isPreWarning && pluginRoot.timeToNextBreak > 0) {
                    pluginRoot.isPreWarning = true;
                    showPreWarning();
                }
            }

            if (pluginRoot.timeToNextBreak <= 0) {
                if (shouldSuppress()) {
                    pluginRoot.snoozeBreak();
                    return;
                }
                pluginRoot.isPreWarning = false;
                startBreak();
            }
        }
    }

    Timer {
        id: breakTimer
        interval: 1000
        repeat: true
        running: pluginRoot.isBreakActive
        onTriggered: {
            pluginRoot.breakTimeRemaining -= 1;
            if (pluginRoot.breakTimeRemaining <= 0) {
                endBreak();
            }
        }
    }

    function shouldSuppress() {
        if (pluginRoot.suppressFullscreen) {
            if (typeof CompositorService !== "undefined" && CompositorService && typeof CompositorService.fullscreenToplevelOnScreen === "function") {
                const screens = Quickshell.screens || [];
                for (let i = 0; i < screens.length; i++) {
                    const scr = screens[i];
                    const scrName = scr ? (scr.name || scr) : "";
                    if (scrName && CompositorService.fullscreenToplevelOnScreen(scrName)) {
                        return true;
                    }
                }
            }

            if (typeof ToplevelManager !== "undefined" && ToplevelManager && ToplevelManager.toplevels && ToplevelManager.toplevels.values) {
                const toplevels = ToplevelManager.toplevels.values;
                for (let i = 0; i < toplevels.length; i++) {
                    const tl = toplevels[i];
                    if (tl && tl.fullscreen && tl.activated) {
                        return true;
                    }
                }
            }
        }

        if (pluginRoot.suppressMeetings && typeof PrivacyService !== "undefined" && PrivacyService && PrivacyService.microphoneActive) {
            return true;
        }

        return false;
    }

    Connections {
        target: (typeof CompositorService !== "undefined") ? CompositorService : null
        function onToplevelsChanged() {
            if (pluginRoot.suppressFullscreen && shouldSuppress()) {
                if (pluginRoot.isPreWarning || pluginRoot.isBreakActive) {
                    pluginRoot.snoozeBreak();
                }
            }
        }
    }

    Connections {
        target: (typeof PrivacyService !== "undefined") ? PrivacyService : null
        function onMicrophoneActiveChanged() {
            if (PrivacyService && PrivacyService.microphoneActive && pluginRoot.suppressMeetings) {
                if (pluginRoot.isPreWarning || pluginRoot.isBreakActive) {
                    pluginRoot.snoozeBreak();
                }
            }
        }
    }

    function pauseMusicPlayers() {
        if (!pluginRoot.pauseMusic) return;
        var playersToResume = [];
        var available = MprisController.availablePlayers || [];
        for (var i = 0; i < available.length; i++) {
            var player = available[i];
            if (player && player.isPlaying && player.canPause) {
                playersToResume.push(player.identity);
                player.pause();
            }
        }
        pluginRoot.pausedPlayers = playersToResume;
    }

    function resumeMusicPlayers() {
        if (!pluginRoot.pauseMusic || !pluginRoot.pausedPlayers || pluginRoot.pausedPlayers.length === 0) return;
        var available = MprisController.availablePlayers || [];
        for (var i = 0; i < available.length; i++) {
            var player = available[i];
            if (player && pluginRoot.pausedPlayers.indexOf(player.identity) !== -1 && player.canPlay) {
                player.play();
            }
        }
        pluginRoot.pausedPlayers = [];
    }

    function resetSession() {
        pluginRoot.completedShortBreaks = 0;
        pluginRoot.nextBreakType = 1; // Start with short break
        pluginRoot.timeToNextBreak = pluginRoot.shortBreakInterval * 60;
    }

    function startBreak() {
        if (shouldSuppress()) {
            snoozeBreak();
            return;
        }
        pluginRoot.isBreakActive = true;
        if (pluginRoot.nextBreakType === 1) {
            pluginRoot.breakTimeRemaining = pluginRoot.shortBreakDuration;
        } else {
            pluginRoot.breakTimeRemaining = pluginRoot.longBreakDuration * 60;
        }
        showBreakOverlay();
        playSound("start");
        pauseMusicPlayers();
    }

    function endBreak() {
        pluginRoot.isBreakActive = false;
        closeBreakOverlay();
        playSound("end");
        pluginRoot.logEvent("completed");
        resumeMusicPlayers();
        
        if (pluginRoot.nextBreakType === 1) {
            pluginRoot.completedShortBreaks++;
        } else {
            pluginRoot.completedShortBreaks = 0;
        }

        if (pluginRoot.completedShortBreaks >= pluginRoot.shortBreaksBeforeLong) {
            pluginRoot.nextBreakType = 2;
        } else {
            pluginRoot.nextBreakType = 1;
        }
        
        pluginRoot.timeToNextBreak = pluginRoot.shortBreakInterval * 60;
    }

    function skipBreak() {
        if (pluginRoot.isPreWarning || (preWarningWindow && preWarningWindow.visible)) {
            pluginRoot.logEvent("skipped");
            pluginRoot.isPreWarning = false;
            if (preWarningWindow) preWarningWindow.visible = false;
            pluginRoot.timeToNextBreak = pluginRoot.shortBreakInterval * 60;
        } else if (pluginRoot.isBreakActive || (overlayWindow && overlayWindow.visible)) {
            pluginRoot.logEvent("skipped");
            pluginRoot.isBreakActive = false;
            closeBreakOverlay();
            resumeMusicPlayers();
            pluginRoot.completedShortBreaks = pluginRoot.nextBreakType === 1 ? pluginRoot.completedShortBreaks + 1 : 0;
            if (pluginRoot.completedShortBreaks >= pluginRoot.shortBreaksBeforeLong) {
                pluginRoot.nextBreakType = 2;
            } else {
                pluginRoot.nextBreakType = 1;
            }
            pluginRoot.timeToNextBreak = pluginRoot.shortBreakInterval * 60;
        }
    }

    function snoozeBreak() {
        pluginRoot.logEvent("snoozed");
        if (pluginRoot.isPreWarning || (preWarningWindow && preWarningWindow.visible)) {
            pluginRoot.isPreWarning = false;
            if (preWarningWindow) preWarningWindow.visible = false;
        } else if (pluginRoot.isBreakActive || (overlayWindow && overlayWindow.visible)) {
            pluginRoot.isBreakActive = false;
            closeBreakOverlay();
            resumeMusicPlayers();
        }
        pluginRoot.timeToNextBreak = 300; // 5 minutes snooze
    }

    // Dynamic component creation for Modals/Windows to keep widget small
    property var preWarningWindow: null
    property var overlayWindow: null

    function showPreWarning() {
        if (!preWarningWindow) {
            var comp = Qt.createComponent("PreWarningToast.qml");
            if (comp.status === Component.Ready) {
                preWarningWindow = comp.createObject(pluginRoot, { "pluginRoot": pluginRoot });
            }
        }
        if (preWarningWindow) preWarningWindow.visible = true;
    }

    function showBreakOverlay() {
        if (preWarningWindow) preWarningWindow.visible = false;
        
        if (!overlayWindow) {
            var comp = Qt.createComponent("TakeABreakOverlay.qml");
            if (comp.status === Component.Ready) {
                overlayWindow = comp.createObject(pluginRoot, { "pluginRoot": pluginRoot });
            }
        }
        if (overlayWindow) overlayWindow.visible = true;
    }

    function closeBreakOverlay() {
        if (overlayWindow) overlayWindow.visible = false;
    }

    onPluginIdChanged: {
        if (isActiveInstance && pluginId !== "") {
            PluginService.setGlobalVar(pluginId, "instance", pluginRoot);
        }
    }

    Component.onCompleted: {
        // Elect one owner for the shared timer state.
        if (pluginId !== "" && !PluginService.getGlobalVar(pluginId, "instance")) {
            PluginService.setGlobalVar(pluginId, "instance", pluginRoot);
            pluginRoot.isActiveInstance = true;
        }
        if (pluginRoot.isActiveInstance) {
            resetSession();
        }
    }

    Component.onDestruction: {
        if (pluginRoot.isActiveInstance && pluginRoot.pluginId !== "" &&
            PluginService.getGlobalVar(pluginRoot.pluginId, "instance") === pluginRoot) {
            PluginService.setGlobalVar(pluginRoot.pluginId, "instance", null);
        }
    }

    popoutContent: Component {
        Column {
            width: 300
            spacing: Theme.spacingM
            padding: Theme.spacingM

            Row {
                width: parent.width
                spacing: Theme.spacingM

                DIcon {
                    name: "self_improvement"
                    size: 32
                    color: Theme.primary
                    anchors.verticalCenter: parent.verticalCenter
                }

                Column {
                    width: parent.width - 32 - Theme.spacingM
                    spacing: 4

                    StyledText {
                        text: pluginRoot.isBreakActive ? I18n.trFor("takeABreak", "Currently on a break") : (pluginRoot.nextBreakType === 1 ? I18n.trFor("takeABreak", "Next: Short Break") : I18n.trFor("takeABreak", "Next: Long Break"))
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.surfaceVariantText
                    }

                    StyledText {
                        text: {
                            if (pluginRoot.isBreakActive) {
                                let m = Math.floor(pluginRoot.breakTimeRemaining / 60);
                                let s = pluginRoot.breakTimeRemaining % 60;
                                return (m > 0 ? m + ":" : "") + (s < 10 && m > 0 ? "0" : "") + s;
                            } else {
                                let m = Math.floor(pluginRoot.timeToNextBreak / 60);
                                let s = pluginRoot.timeToNextBreak % 60;
                                return `${m}:${s < 10 ? '0' : ''}${s}`;
                            }
                        }
                        font.pixelSize: Theme.fontSizeExtraLarge
                        font.weight: Font.Bold
                        color: pluginRoot.isPaused ? Theme.surfaceVariantText : Theme.surfaceText
                    }
                }
            }

            Item { width: 1; height: Theme.spacingS }

            Row {
                width: parent.width
                spacing: Theme.spacingS

                DButton {
                    text: pluginRoot.isPaused ? I18n.trFor("takeABreak", "Resume") : I18n.trFor("takeABreak", "Pause")
                    iconName: pluginRoot.isPaused ? "play_arrow" : "pause"
                    backgroundColor: Theme.surfaceContainerHigh
                    textColor: Theme.surfaceText
                    width: (parent.width - parent.spacing) / 2
                    buttonHeight: 36
                    onClicked: pluginRoot.togglePaused()
                }

                DButton {
                    text: I18n.trFor("takeABreak", "Reset")
                    iconName: "refresh"
                    backgroundColor: Theme.surfaceContainerHigh
                    textColor: Theme.surfaceText
                    width: (parent.width - parent.spacing) / 2
                    buttonHeight: 36
                    onClicked: pluginRoot.resetSession()
                }
            }
        }
    }
}
