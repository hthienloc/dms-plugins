pragma ComponentBehavior: Bound

import "./shared"
import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common
import qs.DCommon.Widgets
import qs.Modules.Plugins
import qs.Services

PluginSettings {
    id: rootSettings
    pluginId: "takeABreak"

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

    property var livePlugin: null

    Timer {
        interval: 1000
        running: livePlugin === null
        repeat: true
        onTriggered: {
            livePlugin = PluginService.getGlobalVar("takeABreak", "instance");
            if (livePlugin && livePlugin.getStats) livePlugin.getStats();
        }
    }

    Component.onCompleted: {
        livePlugin = PluginService.getGlobalVar("takeABreak", "instance");
        if (livePlugin && livePlugin.getStats) livePlugin.getStats();
        PluginService.globalVarChanged.connect((pid, vname) => {
            if (pid === "takeABreak" && vname === "instance") {
                livePlugin = PluginService.getGlobalVar("takeABreak", "instance");
                if (livePlugin && livePlugin.getStats) livePlugin.getStats();
            }
        });
    }

    SettingsCard {
        visible: livePlugin !== null
        
        StatusDisplay {
            large: true
            iconName: livePlugin ? (livePlugin.isPaused ? "pause_circle" : "timer") : ""
            title: {
                if (!livePlugin) return "";
                if (livePlugin.isPaused) return I18n.trFor("takeABreak", "Paused");
                if (livePlugin.isBreakActive) return livePlugin.nextBreakType === 1 ? I18n.trFor("takeABreak", "Short Break Active") : I18n.trFor("takeABreak", "Long Break Active");
                return livePlugin.nextBreakType === 1 ? I18n.trFor("takeABreak", "Next: Short Break") : I18n.trFor("takeABreak", "Next: Long Break");
            }
            subtitle: {
                if (!livePlugin) return "0:00";
                let total = livePlugin.isBreakActive ? livePlugin.breakTimeRemaining : livePlugin.timeToNextBreak;
                let m = Math.floor(total / 60);
                let s = total % 60;
                return `${m}:${s < 10 ? '0' : ''}${s}`;
            }
            active: livePlugin ? livePlugin.isBreakActive : false
            progress: {
                if (!livePlugin) return -1;
                if (livePlugin.isBreakActive) {
                    let duration = livePlugin.nextBreakType === 1 ? livePlugin.shortBreakDuration : livePlugin.longBreakDuration * 60;
                    return livePlugin.breakTimeRemaining / duration;
                } else {
                    let interval = livePlugin.nextBreakType === 1 ? livePlugin.shortBreakInterval * 60 : livePlugin.longBreakInterval * 60;
                    return 1 - (livePlugin.timeToNextBreak / interval);
                }
            }
        }

        Item { width: 1; height: Theme.spacingS }

        Row {
            width: parent.width - Theme.spacingM * 2
            x: Theme.spacingM
            spacing: Theme.spacingS

            DButton {
                text: livePlugin && livePlugin.isPaused ? I18n.trFor("takeABreak", "Resume") : I18n.trFor("takeABreak", "Pause")
                iconName: livePlugin && livePlugin.isPaused ? "play_arrow" : "pause"
                backgroundColor: Theme.surfaceContainerHigh
                textColor: Theme.surfaceText
                width: (parent.width - parent.spacing) / 2
                buttonHeight: 36
                onClicked: if (livePlugin) livePlugin.isPaused = !livePlugin.isPaused
            }

            DButton {
                text: I18n.trFor("takeABreak", "Reset Session")
                iconName: "refresh"
                backgroundColor: Theme.surfaceContainerHigh
                textColor: Theme.surfaceText
                width: (parent.width - parent.spacing) / 2
                buttonHeight: 36
                onClicked: if (livePlugin) livePlugin.resetSession()
            }
        }
    }

    SettingsCard {
        SectionTitle {
            text: I18n.trFor("takeABreak", "Break Schedule")
            icon: "timer"
        }

        SliderSettingPlus {
            id: shortBreakInterval
            settingKey: "shortBreakInterval"
            label: I18n.trFor("takeABreak", "Short Break Interval")
            defaultValue: 20
            minimum: 5
            maximum: 60
            unit: "m"
            leftLabel: "5m"
            rightLabel: "60m"
        }

        SliderSettingPlus {
            id: shortBreakDuration
            settingKey: "shortBreakDuration"
            label: I18n.trFor("takeABreak", "Short Break Duration")
            defaultValue: 20
            minimum: 5
            maximum: 120
            unit: "s"
            leftLabel: "5s"
            rightLabel: "2m"
        }

        SettingsDivider {}

        SliderSettingPlus {
            settingKey: "shortBreaksBeforeLong"
            label: I18n.trFor("takeABreak", "Short breaks before long break")
            defaultValue: 3
            minimum: 1
            maximum: 10
            unit: ""
            leftLabel: "1"
            rightLabel: "10"
        }

        SliderSettingPlus {
            id: longBreakDuration
            settingKey: "longBreakDuration"
            label: I18n.trFor("takeABreak", "Long Break Duration")
            defaultValue: 5
            minimum: 1
            maximum: 30
            unit: "m"
            leftLabel: "1m"
            rightLabel: "30m"
        }

        SettingsDivider {}

        SliderSettingPlus {
            settingKey: "preWarningTime"
            label: I18n.trFor("takeABreak", "Pre-break Warning Timing")
            description: I18n.trFor("takeABreak", "How many seconds before the break to show the warning notification.")
            defaultValue: 5
            minimum: 0
            maximum: 15
            unit: "s"
            leftLabel: "0s"
            rightLabel: "15s"
        }
    }

    SettingsCard {
        SectionTitle {
            text: I18n.trFor("takeABreak", "Smart Suppression")
            icon: "psychology"
        }

        ToggleSettingPlus {
            id: suppressFullscreen
            settingKey: "suppressFullscreen"
            label: I18n.trFor("takeABreak", "Suppress in Fullscreen")
            description: I18n.trFor("takeABreak", "Automatically snooze breaks if an application is running in fullscreen.")
            defaultValue: true
        }

        ToggleSettingPlus {
            id: suppressMeetings
            settingKey: "suppressMeetings"
            label: I18n.trFor("takeABreak", "Suppress during Meetings")
            description: I18n.trFor("takeABreak", "Automatically snooze breaks if your microphone is active.")
            defaultValue: true
        }
    }

    SettingsCard {
        SectionTitle {
            text: I18n.trFor("takeABreak", "Audio & Playback")
            icon: "volume_up"
        }

        ToggleSettingPlus {
            id: pauseMusic
            settingKey: "pauseMusic"
            label: I18n.trFor("takeABreak", "Pause Music during Break")
            description: I18n.trFor("takeABreak", "Automatically pause active music players when a break starts, and resume them when the break ends.")
            defaultValue: false
        }

        SettingsDivider {}

        ToggleSettingPlus {
            settingKey: "soundEnabled"
            label: I18n.trFor("takeABreak", "Enable Sound Alerts")
            description: I18n.trFor("takeABreak", "Play a gentle sound when a break starts and ends.")
            defaultValue: true
        }

        SettingsDivider {}

        SliderSettingPlus {
            settingKey: "soundVolume"
            label: I18n.trFor("takeABreak", "Alert Volume")
            defaultValue: 80
            minimum: 0
            maximum: 100
            unit: "%"
            leftLabel: "0%"
            rightLabel: "100%"
        }
    }

    SettingsCard {
        SectionTitle {
            text: I18n.trFor("takeABreak", "UI Appearance")
            icon: "palette"
        }

        SelectionSettingPlus {
            settingKey: "preWarningAlignment"
            label: I18n.trFor("takeABreak", "Pre-warning Position")
            description: I18n.trFor("takeABreak", "Where the pre-warning notification appears.")
            options: [
                { label: I18n.trFor("takeABreak", "Top Left"), value: "top-left" },
                { label: I18n.trFor("takeABreak", "Top Center"), value: "top-center" },
                { label: I18n.trFor("takeABreak", "Top Right"), value: "top-right" },
                { label: I18n.trFor("takeABreak", "Bottom Left"), value: "bottom-left" },
                { label: I18n.trFor("takeABreak", "Bottom Center"), value: "bottom-center" },
                { label: I18n.trFor("takeABreak", "Bottom Right"), value: "bottom-right" },
                { label: I18n.trFor("takeABreak", "Left Center"), value: "left-center" },
                { label: I18n.trFor("takeABreak", "Right Center"), value: "right-center" }
            ]
            defaultValue: "bottom-right"
        }

        SettingsDivider {}

        SliderSettingPlus {
            settingKey: "preWarningOpacity"
            label: I18n.trFor("takeABreak", "Pre-warning Opacity")
            description: I18n.trFor("takeABreak", "How transparent the pre-warning notification should be.")
            defaultValue: 100
            minimum: 20
            maximum: 100
            unit: "%"
            leftLabel: "20%"
            rightLabel: "100%"
        }

        SettingsDivider {}

        SliderSettingPlus {
            settingKey: "overlayOpacity"
            label: I18n.trFor("takeABreak", "Overlay Background Opacity")
            description: I18n.trFor("takeABreak", "How transparent the fullscreen break background should be.")
            defaultValue: 100
            minimum: 50
            maximum: 100
            unit: "%"
            leftLabel: "50%"
            rightLabel: "100%"
        }
    }

    Timer {
        id: statsRefreshTimer
        interval: 10000
        running: livePlugin !== null
        repeat: true
        onTriggered: {
            if (livePlugin && livePlugin.getStats) livePlugin.getStats();
        }
    }

    SettingsCard {
        SectionTitle {
            text: I18n.trFor("takeABreak", "Statistics")
            icon: "bar_chart"
        }

        Column {
            width: parent.width - Theme.spacingM * 2
            x: Theme.spacingM
            spacing: Theme.spacingS

            Row {
                width: parent.width
                spacing: Theme.spacingS

                InfoTile {
                    width: (parent.width - parent.spacing) / 2
                    label: I18n.trFor("takeABreak", "Today")
                    value: {
                        var s = livePlugin ? livePlugin._stats : null;
                        if (!s || s.todayRate < 0) return "—";
                        return s.todayCompleted + "/" + s.todayTotal + " (" + s.todayRate + "%)";
                    }
                    iconName: "today"
                    accentColor: {
                        var s = livePlugin ? livePlugin._stats : null;
                        if (!s || s.todayRate < 0) return Theme.primary;
                        return s.todayRate >= 80 ? Theme.success : (s.todayRate >= 50 ? Theme.warning : Theme.error);
                    }
                }

                InfoTile {
                    width: (parent.width - parent.spacing) / 2
                    label: I18n.trFor("takeABreak", "This Week")
                    value: {
                        var s = livePlugin ? livePlugin._stats : null;
                        if (!s || s.weekRate < 0) return "—";
                        return s.weekCompleted + "/" + s.weekTotal + " (" + s.weekRate + "%)";
                    }
                    iconName: "date_range"
                    accentColor: {
                        var s = livePlugin ? livePlugin._stats : null;
                        if (!s || s.weekRate < 0) return Theme.primary;
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
                        var s = livePlugin ? livePlugin._stats : null;
                        if (!s || s.todayRate < 0) return "0";
                        return s.todayCompleted + " / " + s.weekCompleted;
                    }
                    iconName: "check_circle"
                    accentColor: Theme.success
                }

                InfoTile {
                    width: (parent.width - parent.spacing) / 2
                    label: I18n.trFor("takeABreak", "Skipped")
                    value: {
                        var s = livePlugin ? livePlugin._stats : null;
                        if (!s || s.todayRate < 0) return "0";
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
                        var s = livePlugin ? livePlugin._stats : null;
                        if (!s || s.todayRate < 0) return "0";
                        return I18n.trFor("takeABreak", "Today: ") + s.todaySnoozed + " — " + I18n.trFor("takeABreak", "Week: ") + s.weekSnoozed;
                    }
                    iconName: "snooze"
                    accentColor: Theme.primary
                }

                InfoTile {
                    width: (parent.width - parent.spacing) / 2
                    label: I18n.trFor("takeABreak", "Total Breaks Logged")
                    value: {
                        var s = livePlugin ? livePlugin._stats : null;
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
                        if (livePlugin && livePlugin.getStats) livePlugin.getStats();
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
                        if (livePlugin && livePlugin.resetStats) {
                            livePlugin.resetStats();
                        } else if (root.pluginService) {
                            root.pluginService.savePluginState(root.pluginId, "events", []);
                        }
                    }
                }
            }
        }
    }

    SettingsCard {
        SectionTitle {
            text: I18n.trFor("takeABreak", "Testing & Preview")
            icon: "preview"
        }

        Column {
            width: parent.width - Theme.spacingM * 2
            x: Theme.spacingM
            spacing: Theme.spacingS

            Row {
                width: parent.width
                spacing: Theme.spacingS

                DButton {
                    text: (livePlugin && livePlugin.isPreWarning) ? I18n.trFor("takeABreak", "Hide Pre-Warning") : I18n.trFor("takeABreak", "Preview Pre-Warning")
                    iconName: (livePlugin && livePlugin.isPreWarning) ? "notifications_off" : "notifications"
                    backgroundColor: (livePlugin && livePlugin.isPreWarning) ? Theme.primaryContainer : Theme.surfaceContainerHigh
                    textColor: (livePlugin && livePlugin.isPreWarning) ? Theme.primary : Theme.surfaceText
                    width: (parent.width - parent.spacing) / 2
                    buttonHeight: 36
                    onClicked: previewPreWarningProc.running = true
                }

                DButton {
                    text: (livePlugin && livePlugin.isBreakActive) ? I18n.trFor("takeABreak", "Hide Overlay") : I18n.trFor("takeABreak", "Preview Fullscreen Break")
                    iconName: (livePlugin && livePlugin.isBreakActive) ? "fullscreen_exit" : "fullscreen"
                    backgroundColor: (livePlugin && livePlugin.isBreakActive) ? Theme.primaryContainer : Theme.surfaceContainerHigh
                    textColor: (livePlugin && livePlugin.isBreakActive) ? Theme.primary : Theme.surfaceText
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
