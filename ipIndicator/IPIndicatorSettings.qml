import QtQuick
import qs.Common
import qs.DCommon.Widgets
import qs.Modules.Plugins
import qs.Modules.Settings.Widgets

PluginSettings {
    id: root

    pluginId: "ipIndicator"

    readonly property string defaultDisplayMode: "country"
    readonly property bool defaultUseFlagIcon: true
    readonly property bool defaultShowIPv4: true
    readonly property bool defaultShowIPv6: true
    readonly property bool defaultShowISP: true
    readonly property bool defaultShowLocation: true
    readonly property bool defaultShowLocalIP: true
    readonly property bool defaultShowLocalGateway: true
    readonly property bool defaultShowLocalInterface: true
    readonly property bool defaultShowLatency: true
    readonly property bool defaultShowHints: true
    readonly property int defaultRefreshInterval: 30
    readonly property bool defaultNotifyOnIPChange: false
    readonly property bool defaultPrivacyDefault: false

    property string displayMode: defaultDisplayMode
    property bool useFlagIcon: defaultUseFlagIcon
    property bool showIPv4: defaultShowIPv4
    property bool showIPv6: defaultShowIPv6
    property bool showISP: defaultShowISP
    property bool showLocation: defaultShowLocation
    property bool showLocalIP: defaultShowLocalIP
    property bool showLocalGateway: defaultShowLocalGateway
    property bool showLocalInterface: defaultShowLocalInterface
    property bool showLatency: defaultShowLatency
    property bool showHints: defaultShowHints
    property int refreshInterval: defaultRefreshInterval
    property bool notifyOnIPChange: defaultNotifyOnIPChange
    property bool privacyDefault: defaultPrivacyDefault

    function loadSettings() {
        if (!pluginService)
            return;
        displayMode = loadValue("displayMode", defaultDisplayMode);
        useFlagIcon = loadValue("useFlagIcon", defaultUseFlagIcon);
        showIPv4 = loadValue("showIPv4", defaultShowIPv4);
        showIPv6 = loadValue("showIPv6", defaultShowIPv6);
        showISP = loadValue("showISP", defaultShowISP);
        showLocation = loadValue("showLocation", defaultShowLocation);
        showLocalIP = loadValue("showLocalIP", defaultShowLocalIP);
        showLocalGateway = loadValue("showLocalGateway", defaultShowLocalGateway);
        showLocalInterface = loadValue("showLocalInterface", defaultShowLocalInterface);
        showLatency = loadValue("showLatency", defaultShowLatency);
        showHints = loadValue("showHints", defaultShowHints);
        refreshInterval = loadValue("refreshInterval", defaultRefreshInterval);
        notifyOnIPChange = loadValue("notifyOnIPChange", defaultNotifyOnIPChange);
        privacyDefault = loadValue("privacyDefault", defaultPrivacyDefault);
        usageSection.expanded = loadValue("usageGuideExpanded", true);
    }

    Component.onCompleted: loadSettings()
    onPluginServiceChanged: loadSettings()

    Column {
        width: parent ? parent.width : 0
        spacing: 0

        SettingsSectionLabel {
            width: parent.width
            text: I18n.trFor("ipIndicator", "Bar Display")
        }

        SettingsGroup {
            width: parent.width
            slotColor: SettingsMetrics.controlColor

            SettingsDropdownRow {
                text: I18n.trFor("ipIndicator", "Display Content")
                options: [
                    I18n.trFor("ipIndicator", "Country"),
                    I18n.trFor("ipIndicator", "City"),
                    I18n.trFor("ipIndicator", "ISP"),
                    I18n.trFor("ipIndicator", "IP Address"),
                    I18n.trFor("ipIndicator", "Country + IP"),
                    I18n.trFor("ipIndicator", "Country + City"),
                    I18n.trFor("ipIndicator", "City + IP"),
                    I18n.trFor("ipIndicator", "Icon Only")
                ]
                optionValues: ["country", "city", "isp", "ip", "country_ip", "country_city", "city_ip", "icon"]
                currentValue: root.displayMode
                modified: root.displayMode !== root.defaultDisplayMode
                resetByKeys: false
                onResetRequested: {
                    root.displayMode = root.defaultDisplayMode;
                    root.saveValue("displayMode", root.defaultDisplayMode);
                }
                onValueChanged: val => {
                    root.displayMode = val;
                    root.saveValue("displayMode", val);
                }
            }

            SettingsToggleRow {
                text: I18n.trFor("ipIndicator", "Use Country Flag as Icon")
                description: I18n.trFor("ipIndicator", "Show the country's flag on the bar pill instead of the default globe icon.")
                checked: root.useFlagIcon
                modified: root.useFlagIcon !== root.defaultUseFlagIcon
                resetByKeys: false
                onResetRequested: {
                    root.useFlagIcon = root.defaultUseFlagIcon;
                    root.saveValue("useFlagIcon", root.defaultUseFlagIcon);
                }
                onToggled: isChecked => {
                    root.useFlagIcon = isChecked;
                    root.saveValue("useFlagIcon", isChecked);
                }
            }
        }
    }

    Column {
        width: parent ? parent.width : 0
        spacing: 0

        SettingsSectionLabel {
            width: parent.width
            text: I18n.trFor("ipIndicator", "Popout Content")
        }

        SettingsGroup {
            width: parent.width
            slotColor: SettingsMetrics.controlColor

            SettingsToggleRow {
                text: I18n.trFor("ipIndicator", "Show IPv4")
                checked: root.showIPv4
                modified: root.showIPv4 !== root.defaultShowIPv4
                resetByKeys: false
                onResetRequested: {
                    root.showIPv4 = root.defaultShowIPv4;
                    root.saveValue("showIPv4", root.defaultShowIPv4);
                }
                onToggled: isChecked => {
                    root.showIPv4 = isChecked;
                    root.saveValue("showIPv4", isChecked);
                }
            }

            SettingsToggleRow {
                text: I18n.trFor("ipIndicator", "Show IPv6")
                checked: root.showIPv6
                modified: root.showIPv6 !== root.defaultShowIPv6
                resetByKeys: false
                onResetRequested: {
                    root.showIPv6 = root.defaultShowIPv6;
                    root.saveValue("showIPv6", root.defaultShowIPv6);
                }
                onToggled: isChecked => {
                    root.showIPv6 = isChecked;
                    root.saveValue("showIPv6", isChecked);
                }
            }

            SettingsToggleRow {
                text: I18n.trFor("ipIndicator", "Show ISP")
                checked: root.showISP
                modified: root.showISP !== root.defaultShowISP
                resetByKeys: false
                onResetRequested: {
                    root.showISP = root.defaultShowISP;
                    root.saveValue("showISP", root.defaultShowISP);
                }
                onToggled: isChecked => {
                    root.showISP = isChecked;
                    root.saveValue("showISP", isChecked);
                }
            }

            SettingsToggleRow {
                text: I18n.trFor("ipIndicator", "Show Location")
                checked: root.showLocation
                modified: root.showLocation !== root.defaultShowLocation
                resetByKeys: false
                onResetRequested: {
                    root.showLocation = root.defaultShowLocation;
                    root.saveValue("showLocation", root.defaultShowLocation);
                }
                onToggled: isChecked => {
                    root.showLocation = isChecked;
                    root.saveValue("showLocation", isChecked);
                }
            }

            SettingsToggleRow {
                text: I18n.trFor("ipIndicator", "Show Local IP")
                checked: root.showLocalIP
                modified: root.showLocalIP !== root.defaultShowLocalIP
                resetByKeys: false
                onResetRequested: {
                    root.showLocalIP = root.defaultShowLocalIP;
                    root.saveValue("showLocalIP", root.defaultShowLocalIP);
                }
                onToggled: isChecked => {
                    root.showLocalIP = isChecked;
                    root.saveValue("showLocalIP", isChecked);
                }
            }

            SettingsToggleRow {
                text: I18n.trFor("ipIndicator", "Show Local Gateway")
                checked: root.showLocalGateway
                modified: root.showLocalGateway !== root.defaultShowLocalGateway
                resetByKeys: false
                onResetRequested: {
                    root.showLocalGateway = root.defaultShowLocalGateway;
                    root.saveValue("showLocalGateway", root.defaultShowLocalGateway);
                }
                onToggled: isChecked => {
                    root.showLocalGateway = isChecked;
                    root.saveValue("showLocalGateway", isChecked);
                }
            }

            SettingsToggleRow {
                text: I18n.trFor("ipIndicator", "Show Local Interface")
                checked: root.showLocalInterface
                modified: root.showLocalInterface !== root.defaultShowLocalInterface
                resetByKeys: false
                onResetRequested: {
                    root.showLocalInterface = root.defaultShowLocalInterface;
                    root.saveValue("showLocalInterface", root.defaultShowLocalInterface);
                }
                onToggled: isChecked => {
                    root.showLocalInterface = isChecked;
                    root.saveValue("showLocalInterface", isChecked);
                }
            }

            SettingsToggleRow {
                text: I18n.trFor("ipIndicator", "Show Latency")
                checked: root.showLatency
                modified: root.showLatency !== root.defaultShowLatency
                resetByKeys: false
                onResetRequested: {
                    root.showLatency = root.defaultShowLatency;
                    root.saveValue("showLatency", root.defaultShowLatency);
                }
                onToggled: isChecked => {
                    root.showLatency = isChecked;
                    root.saveValue("showLatency", isChecked);
                }
            }

            SettingsToggleRow {
                text: I18n.trFor("ipIndicator", "Show Hints")
                checked: root.showHints
                modified: root.showHints !== root.defaultShowHints
                resetByKeys: false
                onResetRequested: {
                    root.showHints = root.defaultShowHints;
                    root.saveValue("showHints", root.defaultShowHints);
                }
                onToggled: isChecked => {
                    root.showHints = isChecked;
                    root.saveValue("showHints", isChecked);
                }
            }
        }
    }

    Column {
        width: parent ? parent.width : 0
        spacing: 0

        SettingsSectionLabel {
            width: parent.width
            text: I18n.trFor("ipIndicator", "Behavior")
        }

        SettingsGroup {
            width: parent.width
            slotColor: SettingsMetrics.controlColor

            SettingsSliderRow {
                text: I18n.trFor("ipIndicator", "Refresh Interval")
                description: I18n.trFor("ipIndicator", "How often to check for IP changes.")
                minimum: 1
                maximum: 60
                step: 1
                unit: I18n.trFor("ipIndicator", "min")
                value: root.refreshInterval
                modified: root.refreshInterval !== root.defaultRefreshInterval
                resetByKeys: false
                onResetRequested: {
                    root.refreshInterval = root.defaultRefreshInterval;
                    root.saveValue("refreshInterval", root.defaultRefreshInterval);
                }
                onSliderDragFinished: finalValue => {
                    root.refreshInterval = finalValue;
                    root.saveValue("refreshInterval", finalValue);
                }
            }

            SettingsToggleRow {
                text: I18n.trFor("ipIndicator", "IP Change Notifications")
                description: I18n.trFor("ipIndicator", "Show a desktop notification when your public IP address or ISP changes.")
                checked: root.notifyOnIPChange
                modified: root.notifyOnIPChange !== root.defaultNotifyOnIPChange
                resetByKeys: false
                onResetRequested: {
                    root.notifyOnIPChange = root.defaultNotifyOnIPChange;
                    root.saveValue("notifyOnIPChange", root.defaultNotifyOnIPChange);
                }
                onToggled: isChecked => {
                    root.notifyOnIPChange = isChecked;
                    root.saveValue("notifyOnIPChange", isChecked);
                }
            }

            SettingsToggleRow {
                text: I18n.trFor("ipIndicator", "Default to Privacy Mode")
                description: I18n.trFor("ipIndicator", "Start the plugin with public IP details hidden by default.")
                checked: root.privacyDefault
                modified: root.privacyDefault !== root.defaultPrivacyDefault
                resetByKeys: false
                onResetRequested: {
                    root.privacyDefault = root.defaultPrivacyDefault;
                    root.saveValue("privacyDefault", root.defaultPrivacyDefault);
                }
                onToggled: isChecked => {
                    root.privacyDefault = isChecked;
                    root.saveValue("privacyDefault", isChecked);
                }
            }
        }
    }

    Column {
        id: usageSection
        width: parent ? parent.width : 0
        spacing: 0

        property bool expanded: true

        SettingsSectionLabel {
            width: parent.width
            text: I18n.trFor("ipIndicator", "How to Use")
            collapsible: true
            expanded: usageSection.expanded
            onToggleRequested: {
                usageSection.expanded = !usageSection.expanded;
                if (root.pluginService)
                    root.saveValue("usageGuideExpanded", usageSection.expanded);
            }
        }

        SettingsGroup {
            width: parent.width
            slotColor: SettingsMetrics.controlColor
            visible: usageSection.expanded

            Column {
                width: parent.width
                spacing: Theme.spacingS

                Repeater {
                    model: [
                        I18n.trFor("ipIndicator", "<b>Left-click</b> the pill to open the IP details popout."),
                        I18n.trFor("ipIndicator", "<b>Right-click</b> the pill to manually force a refresh."),
                        I18n.trFor("ipIndicator", "<b>Middle-click</b> the pill to toggle privacy mode."),
                        I18n.trFor("ipIndicator", "Click any <b>IP address</b> in the popout to copy it to the clipboard."),
                        I18n.trFor("ipIndicator", "Click the <b>eye icon</b> in the popout to toggle privacy mode.")
                    ]

                    delegate: Row {
                        required property string modelData
                        width: parent.width
                        spacing: Theme.spacingS

                        StyledText {
                            id: bullet
                            text: "•"
                            color: Theme.primary
                            font.pixelSize: Theme.fontSizeSmall
                            font.weight: Font.Bold
                        }

                        StyledText {
                            width: parent.width - bullet.width - parent.spacing
                            text: modelData
                            color: Theme.surfaceVariantText
                            font.pixelSize: Theme.fontSizeSmall
                            wrapMode: Text.WordWrap
                            textFormat: Text.StyledText
                        }
                    }
                }
            }
        }
    }
}
