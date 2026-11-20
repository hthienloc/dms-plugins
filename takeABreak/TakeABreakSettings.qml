import "./shared"
import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common
import qs.DCommon.Widgets
import qs.Modules.Plugins
import qs.Modules.Settings.Widgets
import qs.Services

PluginSettings {
    id: root
    pluginId: "takeABreak"

    readonly property int defaultShortBreakInterval: 20
    readonly property int defaultShortBreakDuration: 20
    readonly property int defaultShortBreaksBeforeLong: 3
    readonly property int defaultLongBreakDuration: 5
    readonly property int defaultPreWarningTime: 5
    readonly property bool defaultSuppressFullscreen: true
    readonly property bool defaultSuppressMeetings: true
    readonly property bool defaultPauseMusic: false
    readonly property bool defaultSoundEnabled: true
    readonly property int defaultSoundVolume: 80
    readonly property string defaultPreWarningAlignment: "bottom-right"
    readonly property int defaultPreWarningOpacity: 100
    readonly property int defaultOverlayOpacity: 100

    property int shortBreakInterval: defaultShortBreakInterval
    property int shortBreakDuration: defaultShortBreakDuration
    property int shortBreaksBeforeLong: defaultShortBreaksBeforeLong
    property int longBreakDuration: defaultLongBreakDuration
    property int preWarningTime: defaultPreWarningTime
    property bool suppressFullscreen: defaultSuppressFullscreen
    property bool suppressMeetings: defaultSuppressMeetings
    property bool pauseMusic: defaultPauseMusic
    property bool soundEnabled: defaultSoundEnabled
    property int soundVolume: defaultSoundVolume
    property string preWarningAlignment: defaultPreWarningAlignment
    property int preWarningOpacity: defaultPreWarningOpacity
    property int overlayOpacity: defaultOverlayOpacity

    property var livePlugin: null

    function loadSettings() {
        if (!pluginService)
            return;
        shortBreakInterval = loadValue("shortBreakInterval", defaultShortBreakInterval);
        shortBreakDuration = loadValue("shortBreakDuration", defaultShortBreakDuration);
        shortBreaksBeforeLong = loadValue("shortBreaksBeforeLong", defaultShortBreaksBeforeLong);
        longBreakDuration = loadValue("longBreakDuration", defaultLongBreakDuration);
        preWarningTime = loadValue("preWarningTime", defaultPreWarningTime);
        suppressFullscreen = loadValue("suppressFullscreen", defaultSuppressFullscreen);
        suppressMeetings = loadValue("suppressMeetings", defaultSuppressMeetings);
        pauseMusic = loadValue("pauseMusic", defaultPauseMusic);
        soundEnabled = loadValue("soundEnabled", defaultSoundEnabled);
        soundVolume = loadValue("soundVolume", defaultSoundVolume);
        preWarningAlignment = loadValue("preWarningAlignment", defaultPreWarningAlignment);
        preWarningOpacity = loadValue("preWarningOpacity", defaultPreWarningOpacity);
        overlayOpacity = loadValue("overlayOpacity", defaultOverlayOpacity);
    }

    Process {
        id: previewPreWarningProc
        command: ["dms", "ipc", "call", "takeABreak", "preview", "prewarning"]
    }

    Process {
        id: previewOverlayProc
        command: ["dms", "ipc", "call", "takeABreak", "preview", "overlay"]
    }

    Process {
        id: previewSoundProc
        command: ["dms", "ipc", "call", "takeABreak", "play_sound", "start"]
    }

    Timer {
        interval: 1000
        running: root.livePlugin === null
        repeat: true
        onTriggered: {
            root.livePlugin = PluginService.getGlobalVar("takeABreak", "instance");
            if (root.livePlugin && root.livePlugin.getStats)
                root.livePlugin.getStats();
        }
    }

    Timer {
        id: statsRefreshTimer
        interval: 10000
        running: root.livePlugin !== null
        repeat: true
        onTriggered: {
            if (root.livePlugin && root.livePlugin.getStats)
                root.livePlugin.getStats();
        }
    }

    Component.onCompleted: {
        loadSettings();
        livePlugin = PluginService.getGlobalVar("takeABreak", "instance");
        if (livePlugin && livePlugin.getStats)
            livePlugin.getStats();
        PluginService.globalVarChanged.connect((pid, vname) => {
            if (pid === "takeABreak" && vname === "instance") {
                root.livePlugin = PluginService.getGlobalVar("takeABreak", "instance");
                if (root.livePlugin && root.livePlugin.getStats)
                    root.livePlugin.getStats();
            }
        });
    }

    onPluginServiceChanged: loadSettings()

    Column {
        width: parent ? parent.width : 0
        spacing: 0
        visible: root.livePlugin !== null

        SettingsGroup {
            width: parent.width
            slotColor: SettingsMetrics.controlColor

            Column {
                width: parent.width
                spacing: Theme.spacingS

                StatusDisplay {
                    large: true
                    iconName: root.livePlugin ? (root.livePlugin.isPaused ? "pause_circle" : "timer") : ""
                    title: {
                        if (!root.livePlugin)
                            return "";
                        if (root.livePlugin.isPaused)
                            return I18n.trFor("takeABreak", "Paused");
                        if (root.livePlugin.isBreakActive)
                            return root.livePlugin.nextBreakType === 1 ? I18n.trFor("takeABreak", "Short Break Active") : I18n.trFor("takeABreak", "Long Break Active");
                        return root.livePlugin.nextBreakType === 1 ? I18n.trFor("takeABreak", "Next: Short Break") : I18n.trFor("takeABreak", "Next: Long Break");
                    }
                    subtitle: {
                        if (!root.livePlugin)
                            return "0:00";
                        let total = root.livePlugin.isBreakActive ? root.livePlugin.breakTimeRemaining : root.livePlugin.timeToNextBreak;
                        let m = Math.floor(total / 60);
                        let s = total % 60;
                        return `${m}:${s < 10 ? "0" : ""}${s}`;
                    }
                    active: root.livePlugin ? root.livePlugin.isBreakActive : false
                    progress: {
                        if (!root.livePlugin)
                            return -1;
                        if (root.livePlugin.isBreakActive) {
                            let duration = root.livePlugin.nextBreakType === 1 ? root.livePlugin.shortBreakDuration : root.livePlugin.longBreakDuration * 60;
                            return root.livePlugin.breakTimeRemaining / duration;
                        }
                        let interval = root.livePlugin.nextBreakType === 1 ? root.livePlugin.shortBreakInterval * 60 : root.livePlugin.longBreakInterval * 60;
                        return 1 - (root.livePlugin.timeToNextBreak / interval);
                    }
                }

                Row {
                    width: parent.width
                    spacing: Theme.spacingS

                    DButton {
                        text: root.livePlugin && root.livePlugin.isPaused ? I18n.trFor("takeABreak", "Resume") : I18n.trFor("takeABreak", "Pause")
                        iconName: root.livePlugin && root.livePlugin.isPaused ? "play_arrow" : "pause"
                        backgroundColor: Theme.surfaceContainerHigh
                        textColor: Theme.surfaceText
                        width: (parent.width - parent.spacing) / 2
                        buttonHeight: 36
                        onClicked: {
                            if (root.livePlugin)
                                root.livePlugin.isPaused = !root.livePlugin.isPaused;
                        }
                    }

                    DButton {
                        text: I18n.trFor("takeABreak", "Reset Session")
                        iconName: "refresh"
                        backgroundColor: Theme.surfaceContainerHigh
                        textColor: Theme.surfaceText
                        width: (parent.width - parent.spacing) / 2
                        buttonHeight: 36
                        onClicked: {
                            if (root.livePlugin)
                                root.livePlugin.resetSession();
                        }
                    }
                }
            }
        }
    }

    Column {
        width: parent ? parent.width : 0
        spacing: 0

        SettingsSectionLabel {
            width: parent.width
            text: I18n.trFor("takeABreak", "Break Schedule")
        }

        SettingsGroup {
            width: parent.width
            slotColor: SettingsMetrics.controlColor

            SettingsSliderRow {
                text: I18n.trFor("takeABreak", "Short Break Interval")
                minimum: 5
                maximum: 60
                step: 1
                unit: "m"
                value: root.shortBreakInterval
                modified: root.shortBreakInterval !== root.defaultShortBreakInterval
                resetByKeys: false
                onResetRequested: {
                    root.shortBreakInterval = root.defaultShortBreakInterval;
                    root.saveValue("shortBreakInterval", root.defaultShortBreakInterval);
                }
                onSliderDragFinished: finalValue => {
                    root.shortBreakInterval = finalValue;
                    root.saveValue("shortBreakInterval", finalValue);
                }
            }

            SettingsSliderRow {
                text: I18n.trFor("takeABreak", "Short Break Duration")
                minimum: 5
                maximum: 120
                step: 5
                unit: "s"
                value: root.shortBreakDuration
                modified: root.shortBreakDuration !== root.defaultShortBreakDuration
                resetByKeys: false
                onResetRequested: {
                    root.shortBreakDuration = root.defaultShortBreakDuration;
                    root.saveValue("shortBreakDuration", root.defaultShortBreakDuration);
                }
                onSliderDragFinished: finalValue => {
                    root.shortBreakDuration = finalValue;
                    root.saveValue("shortBreakDuration", finalValue);
                }
            }

            SettingsSliderRow {
                text: I18n.trFor("takeABreak", "Short breaks before long break")
                minimum: 1
                maximum: 10
                step: 1
                unit: ""
                value: root.shortBreaksBeforeLong
                modified: root.shortBreaksBeforeLong !== root.defaultShortBreaksBeforeLong
                resetByKeys: false
                onResetRequested: {
                    root.shortBreaksBeforeLong = root.defaultShortBreaksBeforeLong;
                    root.saveValue("shortBreaksBeforeLong", root.defaultShortBreaksBeforeLong);
                }
                onSliderDragFinished: finalValue => {
                    root.shortBreaksBeforeLong = finalValue;
                    root.saveValue("shortBreaksBeforeLong", finalValue);
                }
            }

            SettingsSliderRow {
                text: I18n.trFor("takeABreak", "Long Break Duration")
                minimum: 1
                maximum: 30
                step: 1
                unit: "m"
                value: root.longBreakDuration
                modified: root.longBreakDuration !== root.defaultLongBreakDuration
                resetByKeys: false
                onResetRequested: {
                    root.longBreakDuration = root.defaultLongBreakDuration;
                    root.saveValue("longBreakDuration", root.defaultLongBreakDuration);
                }
                onSliderDragFinished: finalValue => {
                    root.longBreakDuration = finalValue;
                    root.saveValue("longBreakDuration", finalValue);
                }
            }

            SettingsSliderRow {
                text: I18n.trFor("takeABreak", "Pre-break Warning Timing")
                description: I18n.trFor("takeABreak", "How many seconds before the break to show the warning notification.")
                minimum: 0
                maximum: 15
                step: 1
                unit: "s"
                value: root.preWarningTime
                modified: root.preWarningTime !== root.defaultPreWarningTime
                resetByKeys: false
                onResetRequested: {
                    root.preWarningTime = root.defaultPreWarningTime;
                    root.saveValue("preWarningTime", root.defaultPreWarningTime);
                }
                onSliderDragFinished: finalValue => {
                    root.preWarningTime = finalValue;
                    root.saveValue("preWarningTime", finalValue);
                }
            }
        }
    }

    Column {
        width: parent ? parent.width : 0
        spacing: 0

        SettingsSectionLabel {
            width: parent.width
            text: I18n.trFor("takeABreak", "Smart Suppression")
        }

        SettingsGroup {
            width: parent.width
            slotColor: SettingsMetrics.controlColor

            SettingsToggleRow {
                text: I18n.trFor("takeABreak", "Suppress in Fullscreen")
                description: I18n.trFor("takeABreak", "Automatically snooze breaks if an application is running in fullscreen.")
                checked: root.suppressFullscreen
                modified: root.suppressFullscreen !== root.defaultSuppressFullscreen
                resetByKeys: false
                onResetRequested: {
                    root.suppressFullscreen = root.defaultSuppressFullscreen;
                    root.saveValue("suppressFullscreen", root.defaultSuppressFullscreen);
                }
                onToggled: isChecked => {
                    root.suppressFullscreen = isChecked;
                    root.saveValue("suppressFullscreen", isChecked);
                }
            }

            SettingsToggleRow {
                text: I18n.trFor("takeABreak", "Suppress during Meetings")
                description: I18n.trFor("takeABreak", "Automatically snooze breaks if your microphone is active.")
                checked: root.suppressMeetings
                modified: root.suppressMeetings !== root.defaultSuppressMeetings
                resetByKeys: false
                onResetRequested: {
                    root.suppressMeetings = root.defaultSuppressMeetings;
                    root.saveValue("suppressMeetings", root.defaultSuppressMeetings);
                }
                onToggled: isChecked => {
                    root.suppressMeetings = isChecked;
                    root.saveValue("suppressMeetings", isChecked);
                }
            }
        }
    }

    Column {
        width: parent ? parent.width : 0
        spacing: 0

        SettingsSectionLabel {
            width: parent.width
            text: I18n.trFor("takeABreak", "Audio & Playback")
        }

        SettingsGroup {
            width: parent.width
            slotColor: SettingsMetrics.controlColor

            SettingsToggleRow {
                text: I18n.trFor("takeABreak", "Pause Music during Break")
                description: I18n.trFor("takeABreak", "Automatically pause active music players when a break starts, and resume them when the break ends.")
                checked: root.pauseMusic
                modified: root.pauseMusic !== root.defaultPauseMusic
                resetByKeys: false
                onResetRequested: {
                    root.pauseMusic = root.defaultPauseMusic;
                    root.saveValue("pauseMusic", root.defaultPauseMusic);
                }
                onToggled: isChecked => {
                    root.pauseMusic = isChecked;
                    root.saveValue("pauseMusic", isChecked);
                }
            }

            SettingsToggleRow {
                text: I18n.trFor("takeABreak", "Enable Sound Alerts")
                description: I18n.trFor("takeABreak", "Play a gentle sound when a break starts and ends.")
                checked: root.soundEnabled
                modified: root.soundEnabled !== root.defaultSoundEnabled
                resetByKeys: false
                onResetRequested: {
                    root.soundEnabled = root.defaultSoundEnabled;
                    root.saveValue("soundEnabled", root.defaultSoundEnabled);
                }
                onToggled: isChecked => {
                    root.soundEnabled = isChecked;
                    root.saveValue("soundEnabled", isChecked);
                }
            }

            SettingsSliderRow {
                text: I18n.trFor("takeABreak", "Alert Volume")
                minimum: 0
                maximum: 100
                step: 5
                unit: "%"
                value: root.soundVolume
                modified: root.soundVolume !== root.defaultSoundVolume
                resetByKeys: false
                onResetRequested: {
                    root.soundVolume = root.defaultSoundVolume;
                    root.saveValue("soundVolume", root.defaultSoundVolume);
                }
                onSliderDragFinished: finalValue => {
                    root.soundVolume = finalValue;
                    root.saveValue("soundVolume", finalValue);
                }
            }
        }
    }

    Column {
        width: parent ? parent.width : 0
        spacing: 0

        SettingsSectionLabel {
            width: parent.width
            text: I18n.trFor("takeABreak", "UI Appearance")
        }

        SettingsGroup {
            width: parent.width
            slotColor: SettingsMetrics.controlColor

            SettingsDropdownRow {
                text: I18n.trFor("takeABreak", "Pre-warning Position")
                description: I18n.trFor("takeABreak", "Where the pre-warning notification appears.")
                options: [
                    I18n.trFor("takeABreak", "Top Left"),
                    I18n.trFor("takeABreak", "Top Center"),
                    I18n.trFor("takeABreak", "Top Right"),
                    I18n.trFor("takeABreak", "Bottom Left"),
                    I18n.trFor("takeABreak", "Bottom Center"),
                    I18n.trFor("takeABreak", "Bottom Right"),
                    I18n.trFor("takeABreak", "Left Center"),
                    I18n.trFor("takeABreak", "Right Center")
                ]
                optionValues: ["top-left", "top-center", "top-right", "bottom-left", "bottom-center", "bottom-right", "left-center", "right-center"]
                currentValue: root.preWarningAlignment
                modified: root.preWarningAlignment !== root.defaultPreWarningAlignment
                resetByKeys: false
                onResetRequested: {
                    root.preWarningAlignment = root.defaultPreWarningAlignment;
                    root.saveValue("preWarningAlignment", root.defaultPreWarningAlignment);
                }
                onValueChanged: val => {
                    root.preWarningAlignment = val;
                    root.saveValue("preWarningAlignment", val);
                }
            }

            SettingsSliderRow {
                text: I18n.trFor("takeABreak", "Pre-warning Opacity")
                description: I18n.trFor("takeABreak", "How transparent the pre-warning notification should be.")
                minimum: 20
                maximum: 100
                step: 5
                unit: "%"
                value: root.preWarningOpacity
                modified: root.preWarningOpacity !== root.defaultPreWarningOpacity
                resetByKeys: false
                onResetRequested: {
                    root.preWarningOpacity = root.defaultPreWarningOpacity;
                    root.saveValue("preWarningOpacity", root.defaultPreWarningOpacity);
                }
                onSliderDragFinished: finalValue => {
                    root.preWarningOpacity = finalValue;
                    root.saveValue("preWarningOpacity", finalValue);
                }
            }

            SettingsSliderRow {
                text: I18n.trFor("takeABreak", "Overlay Background Opacity")
                description: I18n.trFor("takeABreak", "How transparent the fullscreen break background should be.")
                minimum: 50
                maximum: 100
                step: 5
                unit: "%"
                value: root.overlayOpacity
                modified: root.overlayOpacity !== root.defaultOverlayOpacity
                resetByKeys: false
                onResetRequested: {
                    root.overlayOpacity = root.defaultOverlayOpacity;
                    root.saveValue("overlayOpacity", root.defaultOverlayOpacity);
                }
                onSliderDragFinished: finalValue => {
                    root.overlayOpacity = finalValue;
                    root.saveValue("overlayOpacity", finalValue);
                }
            }
        }
    }

    Column {
        width: parent ? parent.width : 0
        spacing: 0

        SettingsSectionLabel {
            width: parent.width
            text: I18n.trFor("takeABreak", "Statistics")
        }

        SettingsGroup {
            width: parent.width
            slotColor: SettingsMetrics.controlColor

            Column {
                width: parent.width
                spacing: Theme.spacingS

                Row {
                    width: parent.width
                    spacing: Theme.spacingS

                    InfoTile {
                        width: (parent.width - parent.spacing) / 2
                        label: I18n.trFor("takeABreak", "Today")
                        value: {
                            var s = root.livePlugin ? root.livePlugin._stats : null;
                            if (!s || s.todayRate < 0)
                                return "—";
                            return s.todayCompleted + "/" + s.todayTotal + " (" + s.todayRate + "%)";
                        }
                        iconName: "today"
                        accentColor: {
                            var s = root.livePlugin ? root.livePlugin._stats : null;
                            if (!s || s.todayRate < 0)
                                return Theme.primary;
                            return s.todayRate >= 80 ? Theme.success : (s.todayRate >= 50 ? Theme.warning : Theme.error);
                        }
                    }

                    InfoTile {
                        width: (parent.width - parent.spacing) / 2
                        label: I18n.trFor("takeABreak", "This Week")
                        value: {
                            var s = root.livePlugin ? root.livePlugin._stats : null;
                            if (!s || s.weekRate < 0)
                                return "—";
                            return s.weekCompleted + "/" + s.weekTotal + " (" + s.weekRate + "%)";
                        }
                        iconName: "date_range"
                        accentColor: {
                            var s = root.livePlugin ? root.livePlugin._stats : null;
                            if (!s || s.weekRate < 0)
                                return Theme.primary;
                            return s.weekRate >= 80 ? Theme.success : (s.weekRate >= 50 ? Theme.warning : Theme.error);
                        }
                    }
                }

                Row {
                    width: parent.width
                    spacing: Theme.spacingS

                    InfoTile {
                        width: (parent.width - parent.spacing) / 2
                        label: I18n.trFor("takeABreak", "Completed")
                        value: {
                            var s = root.livePlugin ? root.livePlugin._stats : null;
                            if (!s || s.todayRate < 0)
                                return "0";
                            return s.todayCompleted + " / " + s.weekCompleted;
                        }
                        iconName: "check_circle"
                        accentColor: Theme.success
                    }

                    InfoTile {
                        width: (parent.width - parent.spacing) / 2
                        label: I18n.trFor("takeABreak", "Skipped")
                        value: {
                            var s = root.livePlugin ? root.livePlugin._stats : null;
                            if (!s || s.todayRate < 0)
                                return "0";
                            return s.todaySkipped + " / " + s.weekSkipped;
                        }
                        iconName: "skip_next"
                        accentColor: Theme.warning
                    }
                }

                Row {
                    width: parent.width
                    spacing: Theme.spacingS

                    InfoTile {
                        width: (parent.width - parent.spacing) / 2
                        label: I18n.trFor("takeABreak", "Snoozed")
                        value: {
                            var s = root.livePlugin ? root.livePlugin._stats : null;
                            if (!s || s.todayRate < 0)
                                return "0";
                            return I18n.trFor("takeABreak", "Today: ") + s.todaySnoozed + " — " + I18n.trFor("takeABreak", "Week: ") + s.weekSnoozed;
                        }
                        iconName: "snooze"
                        accentColor: Theme.primary
                    }

                    InfoTile {
                        width: (parent.width - parent.spacing) / 2
                        label: I18n.trFor("takeABreak", "Total Breaks Logged")
                        value: {
                            var s = root.livePlugin ? root.livePlugin._stats : null;
                            return s ? String(s.totalAll) : "0";
                        }
                        iconName: "analytics"
                        accentColor: Theme.primary
                    }
                }

                Row {
                    width: parent.width
                    spacing: Theme.spacingS

                    DButton {
                        text: I18n.trFor("takeABreak", "Refresh")
                        iconName: "refresh"
                        backgroundColor: Theme.surfaceContainerHigh
                        textColor: Theme.surfaceText
                        width: (parent.width - parent.spacing) / 2
                        buttonHeight: 32
                        onClicked: {
                            if (root.livePlugin && root.livePlugin.getStats)
                                root.livePlugin.getStats();
                        }
                    }

                    DButton {
                        text: I18n.trFor("takeABreak", "Reset Stats")
                        iconName: "delete_sweep"
                        backgroundColor: Theme.errorContainer
                        textColor: Theme.error
                        width: (parent.width - parent.spacing) / 2
                        buttonHeight: 32
                        onClicked: {
                            if (root.livePlugin && root.livePlugin.resetStats) {
                                root.livePlugin.resetStats();
                            } else if (root.pluginService) {
                                root.pluginService.savePluginState(root.pluginId, "events", []);
                            }
                        }
                    }
                }
            }
        }
    }

    Column {
        width: parent ? parent.width : 0
        spacing: 0

        SettingsSectionLabel {
            width: parent.width
            text: I18n.trFor("takeABreak", "Testing & Preview")
        }

        SettingsGroup {
            width: parent.width
            slotColor: SettingsMetrics.controlColor

            Column {
                width: parent.width
                spacing: Theme.spacingS

                Row {
                    width: parent.width
                    spacing: Theme.spacingS

                    DButton {
                        text: (root.livePlugin && root.livePlugin.isPreWarning) ? I18n.trFor("takeABreak", "Hide Pre-Warning") : I18n.trFor("takeABreak", "Preview Pre-Warning")
                        iconName: (root.livePlugin && root.livePlugin.isPreWarning) ? "notifications_off" : "notifications"
                        backgroundColor: (root.livePlugin && root.livePlugin.isPreWarning) ? Theme.primaryContainer : Theme.surfaceContainerHigh
                        textColor: (root.livePlugin && root.livePlugin.isPreWarning) ? Theme.primary : Theme.surfaceText
                        width: (parent.width - parent.spacing) / 2
                        buttonHeight: 36
                        onClicked: previewPreWarningProc.running = true
                    }

                    DButton {
                        text: (root.livePlugin && root.livePlugin.isBreakActive) ? I18n.trFor("takeABreak", "Hide Overlay") : I18n.trFor("takeABreak", "Preview Fullscreen Break")
                        iconName: (root.livePlugin && root.livePlugin.isBreakActive) ? "fullscreen_exit" : "fullscreen"
                        backgroundColor: (root.livePlugin && root.livePlugin.isBreakActive) ? Theme.primaryContainer : Theme.surfaceContainerHigh
                        textColor: (root.livePlugin && root.livePlugin.isBreakActive) ? Theme.primary : Theme.surfaceText
                        width: (parent.width - parent.spacing) / 2
                        buttonHeight: 36
                        onClicked: previewOverlayProc.running = true
                    }
                }

                DButton {
                    text: I18n.trFor("takeABreak", "Test Alert Sound")
                    iconName: "volume_up"
                    backgroundColor: Theme.surfaceContainerHigh
                    textColor: Theme.surfaceText
                    width: parent.width
                    buttonHeight: 36
                    onClicked: previewSoundProc.running = true
                }
            }
        }
    }
}
