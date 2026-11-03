import "./shared"
import QtQuick
import QtQuick.Controls
import qs.Common
import qs.Modules.Plugins

PluginSettings {
    id: root

    pluginId: "timer"

    SettingsCard {
        id: presetsSection
        SectionTitle {
            text: I18n.trFor("timer", "Presets"); icon: "timer"
            showReset: presets.isDirty || quickStartMinutes.isDirty
            onResetClicked: {
                presets.resetToDefault();
                quickStartMinutes.resetToDefault();
            }
        }

        StringSettingPlus {
            id: presets
            settingKey: "presets"
            label: I18n.trFor("timer", "Quick Presets")
            description: I18n.trFor("timer", "Comma-separated list of minutes for quick start buttons.")
            placeholder: "1, 2, 5, 10, 15, 20, 25, 30, 45, 60, 90, 120"
            defaultValue: "1, 2, 5, 10, 15, 20, 25, 30, 45, 60, 90, 120"
        }

        Separator {}

        StringSettingPlus {
            id: quickStartMinutes
            settingKey: "quickStartMinutes"
            label: I18n.trFor("timer", "Right-Click Quick Start")
            description: I18n.trFor("timer", "The duration in minutes to start when right-clicking the icon in Ready state.")
            placeholder: "25"
            defaultValue: "25"
        }
    }

    SettingsCard {
        id: displaySection
        SectionTitle {
            text: I18n.trFor("timer", "Display"); icon: "display_settings"
            showReset: showPillIcon.isDirty || showReadyPlaceholder.isDirty || displayFormat.isDirty
            onResetClicked: {
                showPillIcon.resetToDefault();
                showReadyPlaceholder.resetToDefault();
                displayFormat.resetToDefault();
            }
        }

        ToggleSettingPlus {
            id: showPillIcon
            settingKey: "showPillIcon"
            label: I18n.trFor("timer", "Show Icon")
            defaultValue: true
        }

        Separator {}

        ToggleSettingPlus {
            id: showReadyPlaceholder
            settingKey: "showReadyPlaceholder"
            label: I18n.trFor("timer", "Show Ready Placeholder")
            description: I18n.trFor("timer", "Show placeholder digits/text when the timer is in the ready state.")
            defaultValue: true
        }

        Separator {}

        SelectionSettingPlus {
            id: displayFormat
            settingKey: "displayFormat"
            label: I18n.trFor("timer", "Display Content")
            options: [{
                "label": "00:00:00",
                "value": "full"
            }, {
                "label": I18n.trFor("timer", "1h 5m 10s"),
                "value": "compact"
            }, {
                "label": I18n.trFor("timer", "5m 10s"),
                "value": "minimal"
            }, {
                "label": I18n.trFor("timer", "Progress Bar"),
                "value": "progress"
            }, {
                "label": I18n.trFor("timer", "Icon Only"),
                "value": "icon"
            }, {
                "label": I18n.trFor("timer", "Pulse Dot ✦"),
                "value": "pulse"
            }]
            defaultValue: "full"
        }
    }

    SettingsCard {
        id: notificationsSection
        SectionTitle {
            text: I18n.trFor("timer", "Notifications"); icon: "notifications"
            showReset: timeoutBehavior.isDirty || showNotification.isDirty || notificationTitle.isDirty || notificationBody.isDirty || autoDND.isDirty
            onResetClicked: {
                timeoutBehavior.resetToDefault();
                showNotification.resetToDefault();
                notificationTitle.resetToDefault();
                notificationBody.resetToDefault();
                autoDND.resetToDefault();
            }
        }

        ButtonGroupSettingPlus {
            id: timeoutBehavior
            settingKey: "timeoutBehavior"
            label: I18n.trFor("timer", "When Finished")
            options: [{
                "label": I18n.trFor("timer", "Stay at Finished"),
                "value": "stay"
            }, {
                "label": I18n.trFor("timer", "Reset to Ready"),
                "value": "reset"
            }]
            defaultValue: "reset"
        }

        Separator {}

        ToggleSettingPlus {
            id: showNotification
            settingKey: "showNotification"
            label: I18n.trFor("timer", "Show Desktop Notification")
            defaultValue: true
        }

        Separator { visible: showNotification.value }

        StringSettingPlus {
            id: notificationTitle
            settingKey: "notificationTitle"
            label: I18n.trFor("timer", "Notification Title")
            placeholder: I18n.trFor("timer", "Timer")
            defaultValue: I18n.trFor("timer", "Timer")
            visible: showNotification.value
        }

        Separator { visible: showNotification.value }

        StringSettingPlus {
            id: notificationBody
            settingKey: "notificationBody"
            label: I18n.trFor("timer", "Notification Body")
            placeholder: I18n.trFor("timer", "Timeout!")
            defaultValue: I18n.trFor("timer", "Timeout!")
            visible: showNotification.value
        }

        Separator {}

        ToggleSettingPlus {
            id: autoDND
            settingKey: "autoDND"
            label: I18n.trFor("timer", "Automatically Do Not Disturb")
            description: I18n.trFor("timer", "Toggle Do Not Disturb mode when the timer is active.")
            defaultValue: false
        }
    }

    SettingsCard {
        id: customActionsSection
        SectionTitle {
            text: I18n.trFor("timer", "Custom Actions"); icon: "bolt"
            showReset: systemActionOnTimeout.isDirty || customCommandOnTimeout.isDirty
            onResetClicked: {
                systemActionOnTimeout.resetToDefault();
                customCommandOnTimeout.resetToDefault();
            }
        }

        SelectionSettingPlus {
            id: systemActionOnTimeout
            settingKey: "systemActionOnTimeout"
            label: I18n.trFor("timer", "Trigger System Action")
            description: I18n.trFor("timer", "Automatically perform a system action when the timer finishes.")
            options: [{
                "label": I18n.trFor("timer", "None"),
                "value": "none"
            }, {
                "label": I18n.trFor("timer", "Lock Screen"),
                "value": "lock"
            }, {
                "label": I18n.trFor("timer", "Suspend"),
                "value": "suspend"
            }, {
                "label": I18n.trFor("timer", "Hibernate"),
                "value": "hibernate"
            }, {
                "label": I18n.trFor("timer", "Power Off"),
                "value": "poweroff"
            }, {
                "label": I18n.trFor("timer", "Custom Command"),
                "value": "custom"
            }]
            defaultValue: "none"
        }

        Separator { visible: systemActionOnTimeout.value === "custom" }

        StringSettingPlus {
            id: customCommandOnTimeout
            settingKey: "customCommandOnTimeout"
            label: I18n.trFor("timer", "Run Custom Shell Command")
            description: I18n.trFor("timer", "Execute a shell command when the timer finishes.")
            placeholder: "e.g., systemctl suspend"
            defaultValue: ""
            visible: systemActionOnTimeout.value === "custom"
        }
    }

    SettingsCard {
        id: soundSection
        SectionTitle {
            text: I18n.trFor("timer", "Sound"); icon: "volume_up"
            showReset: soundPath.isDirty || useSystemNotificationSound.isDirty
            onResetClicked: {
                soundPath.resetToDefault();
                useSystemNotificationSound.resetToDefault();
            }
        }

        StringSettingPlus {
            id: soundPath
            settingKey: "soundPath"
            label: I18n.trFor("timer", "Custom Sound Path")
            description: I18n.trFor("timer", "Full path to sound file. Leave empty for default.")
            placeholder: "/usr/share/sounds/freedesktop/stereo/complete.oga"
            defaultValue: ""
            isFile: true
            fileExtensions: [I18n.trFor("timer", "Audio files") + " (*.mp3 *.wav *.ogg *.oga *.flac)", I18n.trFor("timer", "All files") + " (*)"]
        }

        Separator {}

        ToggleSettingPlus {
            id: useSystemNotificationSound
            settingKey: "useSystemNotificationSound"
            label: I18n.trFor("timer", "Use System Notification Sound")
            description: I18n.trFor("timer", "Use system's critical notification sound if no path is set.")
            defaultValue: true
        }
    }

    SettingsCard {
        id: behaviorSection
        SectionTitle {
            text: I18n.trFor("timer", "Behavior"); icon: "settings"
            showReset: showTimeoutActions.isDirty || showHints.isDirty
            onResetClicked: {
                showTimeoutActions.resetToDefault();
                showHints.resetToDefault();
            }
        }

        ToggleSettingPlus {
            id: showTimeoutActions
            settingKey: "showTimeoutActions"
            label: I18n.trFor("timer", "Show 'When Done' Section")
            defaultValue: true
        }

        Separator {}

        ToggleSettingPlus {
            id: showHints
            settingKey: "showHints"
            label: I18n.trFor("timer", "Show Hints")
            defaultValue: true
        }
    }

    SettingsCard {
        SectionTitle { 
            id: usageTitle
            text: I18n.trFor("timer", "Usage Guide")
            icon: "menu_book" 
            collapsible: true
            settingKey: "usageGuideExpanded"
        }

        UsageGuide {
            expanded: usageTitle.isExpanded
            items: [
                I18n.trFor("timer", "<b>Left-click</b> the pill to <b>Pause</b> or <b>Resume</b> the timer."),
                I18n.trFor("timer", "<b>Right-click</b> the pill to <b>Reset</b> (or <b>Quick Start</b> if ready)."),
                I18n.trFor("timer", "Open the <b>Popout</b> to select presets or enter custom minutes.")
            ]
        }
    }
}
