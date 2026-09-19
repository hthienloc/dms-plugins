import "./dms-common"
import QtQuick
import QtQuick.Controls
import qs.Common
import qs.Modules.Plugins
import qs.Widgets

PluginSettings {
    id: root

    pluginId: "hydrate"

    SettingsCard {
        id: goalSection
        SectionTitle {
            text: I18n.tr("Hydration Goals")
            icon: "water_drop"
            showReset: dailyGoal.isDirty || interval.isDirty
            onResetClicked: {
                dailyGoal.resetToDefault();
                interval.resetToDefault();
            }
        }

        SliderSettingPlus {
            id: dailyGoal
            label: I18n.tr("Daily Target")
            description: I18n.tr("Target water intake per day.")
            settingKey: "dailyGoal"
            defaultValue: 2000
            minimum: 500
            maximum: 5000
            unit: I18n.tr(" ml")
            leftLabel: "500"
            rightLabel: "5000"
        }

        Separator {}

        SliderSettingPlus {
            id: interval
            label: I18n.tr("Reminder Interval")
            description: I18n.tr("How often the icon shifts to remind you to drink.")
            settingKey: "interval"
            defaultValue: 60
            minimum: 15
            maximum: 180
            unit: I18n.tr(" min")
            leftLabel: "15"
            rightLabel: "180"
        }
    }

    SettingsCard {
        id: behaviorSection
        SectionTitle {
            text: I18n.tr("Behavior")
            icon: "settings"
            showReset: showHints.isDirty || displayMode.isDirty
            onResetClicked: {
                showHints.resetToDefault();
                displayMode.resetToDefault();
            }
        }

        SelectionSettingPlus {
            id: displayMode
            label: I18n.tr("Display Mode")
            description: I18n.tr("How progress is shown on the bar.")
            settingKey: "displayMode"
            defaultValue: "full"
            options: [
                { label: I18n.tr("Full (Logged / Goal)"), value: "full" },
                { label: I18n.tr("Logged Only"), value: "logged" },
                { label: I18n.tr("Percentage"), value: "percentage" },
                { label: I18n.tr("Icon Only"), value: "icon" },
                { label: I18n.tr("Progress Bar"), value: "progress" },
                { label: I18n.tr("Text + Bar"), value: "text_progress" }
            ]
        }

        Separator {}

        ToggleSettingPlus {
            id: showHints
            label: I18n.tr("Show Hints")
            settingKey: "showHints"
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
                I18n.tr("<b>Left-click</b> the pill to open the hydration dashboard."),
                I18n.tr("<b>Right-click</b> the pill to instantly log <b>+1 cup</b>."),
                I18n.tr("The icon will <b>pulse or shift shape</b> when it's time to drink.")
            ]
        }
    }

    PluginAbout {
        repoUrl: "https://github.com/hthienloc/dms-hydrate"
    }

}
