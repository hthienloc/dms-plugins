import "./dms-common"
import QtQuick
import QtQuick.Controls
import qs.Common
import qs.Modules.Plugins
import qs.Services
import qs.Widgets

PluginSettings {
    id: root

    pluginId: "ipIndicator"

    SettingsCard {
        id: barDisplaySection
        SectionTitle { 
            text: I18n.tr("Bar Display")
            icon: "view_day" 
            showReset: displayMode.isDirty || useFlagIcon.isDirty
            onResetClicked: {
                displayMode.resetToDefault();
                useFlagIcon.resetToDefault();
            }
        }

        SelectionSettingPlus {
            id: displayMode
            settingKey: "displayMode"
            label: I18n.tr("Display Content")
            options: [{
                "label": I18n.tr("Country"),
                "value": "country"
            }, {
                "label": I18n.tr("City"),
                "value": "city"
            }, {
                "label": I18n.tr("ISP"),
                "value": "isp"
            }, {
                "label": I18n.tr("IP Address"),
                "value": "ip"
            }, {
                "label": I18n.tr("Country + IP"),
                "value": "country_ip"
            }, {
                "label": I18n.tr("Country + City"),
                "value": "country_city"
            }, {
                "label": I18n.tr("City + IP"),
                "value": "city_ip"
            }, {
                "label": I18n.tr("Icon Only"),
                "value": "icon"
            }]
            defaultValue: "country"
        }

        Separator {}

        ToggleSettingPlus {
            id: useFlagIcon
            settingKey: "useFlagIcon"
            label: I18n.tr("Use Country Flag as Icon")
            description: I18n.tr("Show the country's flag on the bar pill instead of the default globe icon.")
            defaultValue: true
        }
    }

    SettingsCard {
        id: popoutSection
        SectionTitle { 
            text: I18n.tr("Popout Content")
            icon: "call_made" 
            showReset: showIPv4.isDirty || showIPv6.isDirty || showISP.isDirty || showLocation.isDirty || showLocalIP.isDirty || showLocalGateway.isDirty || showLocalInterface.isDirty || showLatency.isDirty || showHints.isDirty
            onResetClicked: {
                showIPv4.resetToDefault();
                showIPv6.resetToDefault();
                showISP.resetToDefault();
                showLocation.resetToDefault();
                showLocalIP.resetToDefault();
                showLocalGateway.resetToDefault();
                showLocalInterface.resetToDefault();
                showLatency.resetToDefault();
                showHints.resetToDefault();
            }
        }

        ToggleSettingPlus {
            id: showIPv4
            settingKey: "showIPv4"
            label: I18n.tr("Show IPv4")
            defaultValue: true
        }

        Separator {}

        ToggleSettingPlus {
            id: showIPv6
            settingKey: "showIPv6"
            label: I18n.tr("Show IPv6")
            defaultValue: true
        }

        Separator {}

        ToggleSettingPlus {
            id: showISP
            settingKey: "showISP"
            label: I18n.tr("Show ISP")
            defaultValue: true
        }

        Separator {}

        ToggleSettingPlus {
            id: showLocation
            settingKey: "showLocation"
            label: I18n.tr("Show Location")
            defaultValue: true
        }

        Separator {}

        ToggleSettingPlus {
            id: showLocalIP
            settingKey: "showLocalIP"
            label: I18n.tr("Show Local IP")
            defaultValue: true
        }

        Separator {}

        ToggleSettingPlus {
            id: showLocalGateway
            settingKey: "showLocalGateway"
            label: I18n.tr("Show Local Gateway")
            defaultValue: true
        }

        Separator {}

        ToggleSettingPlus {
            id: showLocalInterface
            settingKey: "showLocalInterface"
            label: I18n.tr("Show Local Interface")
            defaultValue: true
        }

        Separator {}

        ToggleSettingPlus {
            id: showLatency
            settingKey: "showLatency"
            label: I18n.tr("Show Latency")
            defaultValue: true
        }

        Separator {}

        ToggleSettingPlus {
            id: showHints
            settingKey: "showHints"
            label: I18n.tr("Show Hints")
            defaultValue: true
        }
    }

    SettingsCard {
        id: behaviorSection
        SectionTitle { 
            text: I18n.tr("Behavior")
            icon: "settings" 
            showReset: refreshInterval.isDirty || notifyOnIPChange.isDirty || privacyDefault.isDirty
            onResetClicked: {
                refreshInterval.resetToDefault();
                notifyOnIPChange.resetToDefault();
                privacyDefault.resetToDefault();
            }
        }

        SliderSettingPlus {
            id: refreshInterval
            settingKey: "refreshInterval"
            label: I18n.tr("Refresh Interval")
            description: I18n.tr("How often to check for IP changes.")
            minimum: 1
            maximum: 60
            unit: I18n.tr("min")
            defaultValue: 30
            leftLabel: "1"
            rightLabel: "60"
        }

        Separator {}

        ToggleSettingPlus {
            id: notifyOnIPChange
            settingKey: "notifyOnIPChange"
            label: I18n.tr("IP Change Notifications")
            description: I18n.tr("Show a desktop notification when your public IP address or ISP changes.")
            defaultValue: false
        }

        Separator {}

        ToggleSettingPlus {
            id: privacyDefault
            settingKey: "privacyDefault"
            label: I18n.tr("Default to Privacy Mode")
            description: I18n.tr("Start the plugin with public IP details hidden by default.")
            defaultValue: false
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
                I18n.tr("<b>Left-click</b> the pill to open the IP details popout."),
                I18n.tr("<b>Right-click</b> the pill to manually force a refresh."),
                I18n.tr("<b>Middle-click</b> the pill to toggle privacy mode."),
                I18n.tr("Click any <b>IP address</b> in the popout to copy it to the clipboard."),
                I18n.tr("Click the <b>eye icon</b> in the popout to toggle privacy mode.")
            ]
        }
    }

    PluginAbout {
        repoUrl: "https://github.com/hthienloc/dms-ipIndicator"
    }

}
