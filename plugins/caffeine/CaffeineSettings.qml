import QtQuick
import qs.Common
import qs.Widgets
import qs.Modules.Plugins
import "./dms-common"

PluginSettings {
    id: root
    pluginId: "caffeine"

    SettingsCard {
        id: presetsSection
        SectionTitle { 
            text: I18n.tr("Presets & Default")
            icon: "tune" 
            showReset: presets.isDirty || defaultDuration.isDirty
            onResetClicked: {
                presets.resetToDefault();
                defaultDuration.resetToDefault();
            }
        }

        StringSettingPlus {
            id: presets
            settingKey: "presets"
            label: I18n.tr("Quick Presets")
            description: I18n.tr("Comma-separated list of durations (in minutes, or 'infinity').")
            placeholder: "5, 15, 30, 60, 120, infinity"
            defaultValue: "5, 15, 30, 60, 120, infinity"
        }

        Separator {}

        StringSettingPlus {
            id: defaultDuration
            settingKey: "defaultDuration"
            label: I18n.tr("Default Duration")
            description: I18n.tr("The default duration used on direct toggling.")
            placeholder: "infinity"
            defaultValue: "infinity"
        }
    }

    SettingsCard {
        id: notificationsSection
        SectionTitle { 
            text: I18n.tr("Notifications")
            icon: "notifications" 
            showReset: showToasts.isDirty
            onResetClicked: {
                showToasts.resetToDefault();
            }
        }

        ToggleSettingPlus {
            id: showToasts
            settingKey: "showToasts"
            label: I18n.tr("Show Status Toasts")
            description: I18n.tr("Show a quick pop-up toast when screen stay-awake is toggled.")
            defaultValue: true
        }
    }

    SettingsCard {
        id: appearanceSection
        SectionTitle { 
            text: I18n.tr("Appearance")
            icon: "palette" 
            showReset: showProgressRing.isDirty
            onResetClicked: {
                showProgressRing.resetToDefault();
            }
        }

        ToggleSettingPlus {
            id: showProgressRing
            settingKey: "showProgressRing"
            label: I18n.tr("Show Progress Ring")
            description: I18n.tr("Show a visual radial countdown progress ring around the caffeine icon.")
            defaultValue: true
        }
    }

    SettingsCard {
        id: automationSection
        SectionTitle { 
            text: I18n.tr("Automation")
            icon: "settings_suggest" 
            showReset: appAutomation.isDirty || autoApps.isDirty || fullscreenAwareness.isDirty
            onResetClicked: {
                appAutomation.resetToDefault();
                autoApps.resetToDefault();
                fullscreenAwareness.resetToDefault();
            }
        }

        ToggleSettingPlus {
            id: appAutomation
            settingKey: "appAutomationEnabled"
            label: I18n.tr("App Automation")
            description: I18n.tr("Automatically keep screen awake when specific apps (e.g. Media players, Meeting tools) are open.")
            defaultValue: false
        }

        Separator {
            visible: appAutomation.value
        }

        StringSettingPlus {
            id: autoApps
            settingKey: "autoAppsList"
            label: I18n.tr("Auto-Activate Apps")
            description: I18n.tr("Comma-separated list of app names/IDs (case-insensitive substring match).")
            placeholder: "mpv, vlc, zoom, Teams, discord, webcord, slack, spotify, obs"
            defaultValue: "mpv, vlc, zoom, Teams, discord, webcord, slack, spotify, obs"
            visible: appAutomation.value
        }

        Separator {}

        ToggleSettingPlus {
            id: fullscreenAwareness
            settingKey: "fullscreenAwarenessEnabled"
            label: I18n.tr("Full Screen Awareness")
            description: I18n.tr("Automatically keep screen awake when any window is full-screen.")
            defaultValue: false
        }
    }

    SettingsCard {
        id: systemIntegrationSection
        SectionTitle { 
            text: I18n.tr("System Integration")
            icon: "power" 
            showReset: batteryIntegration.isDirty || batteryThreshold.isDirty || deactivateOnLock.isDirty
            onResetClicked: {
                batteryIntegration.resetToDefault();
                batteryThreshold.resetToDefault();
                deactivateOnLock.resetToDefault();
            }
        }

        ToggleSettingPlus {
            id: batteryIntegration
            settingKey: "batteryIntegrationEnabled"
            label: I18n.tr("Battery Integration")
            description: I18n.tr("Automatically disable stay-awake when battery is low and not charging.")
            defaultValue: false
        }

        Separator {
            visible: batteryIntegration.value
        }

        SliderSetting {
            id: batteryThreshold
            settingKey: "batteryLowThreshold"
            label: I18n.tr("Battery Low Threshold")
            description: I18n.tr("Automatically disable stay-awake when battery drops to or below this percentage.")
            defaultValue: 15
            minimum: 5
            maximum: 50
            unit: "%"
            leftIcon: "battery_charging_full"
            visible: batteryIntegration.value

            readonly property bool isDirty: value !== defaultValue
            function resetToDefault() {
                value = defaultValue;
            }
        }

        Separator {}

        ToggleSettingPlus {
            id: deactivateOnLock
            settingKey: "deactivateOnManualLock"
            label: I18n.tr("Deactivate on Manual Lock")
            description: I18n.tr("Automatically disable stay-awake when the screen is locked manually.")
            defaultValue: true
        }
    }

    SettingsCard {
        SectionTitle { 
            id: usageTitle
            text: I18n.tr("Usage Guide")
            icon: "menu_book" 
            collapsible: true
            settingKey: "usageGuideExpanded"
        }

        UsageGuide {
            expanded: usageTitle.isExpanded
            items: [
                I18n.tr("<b>Left-click</b> the pill to open the duration picker popout."),
                I18n.tr("<b>Right-click</b> the pill to quick toggle stay-awake with default duration."),
                I18n.tr("The icon will glow when <b>Caffeine</b> is active.")
            ]
        }
    }

    PluginAbout {
        repoUrl: "https://github.com/hthienloc/dms-caffeine"
    }
}
