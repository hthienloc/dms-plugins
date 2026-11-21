import QtQuick
import qs.Common
import qs.DCommon.Widgets
import qs.Modules.Plugins
import qs.Modules.Settings.Widgets

PluginSettings {
    id: root
    pluginId: "persona5Calendar"

    readonly property string defaultThemeVersion: "dynamic"
    readonly property int defaultWidgetOpacity: 100
    readonly property string defaultTodMode: "game"
    readonly property bool defaultShowWeather: true
    readonly property bool defaultAnimateWeather: false
    readonly property int defaultAnimInterval: 300
    readonly property string defaultClickAction: "refresh"

    property string themeVersion: defaultThemeVersion
    property int widgetOpacity: defaultWidgetOpacity
    property string todMode: defaultTodMode
    property bool showWeather: defaultShowWeather
    property bool animateWeather: defaultAnimateWeather
    property int animInterval: defaultAnimInterval
    property string clickAction: defaultClickAction

    function loadSettings() {
        if (!pluginService)
            return;
        themeVersion = loadValue("themeVersion", defaultThemeVersion);
        widgetOpacity = loadValue("widgetOpacity", defaultWidgetOpacity);
        todMode = loadValue("todMode", defaultTodMode);
        showWeather = loadValue("showWeather", defaultShowWeather);
        animateWeather = loadValue("animateWeather", defaultAnimateWeather);
        animInterval = loadValue("animInterval", defaultAnimInterval);
        clickAction = loadValue("clickAction", defaultClickAction);
        creditsSection.expanded = loadValue("creditsExpanded", true);
    }

    Component.onCompleted: loadSettings()
    onPluginServiceChanged: loadSettings()

    Column {
        width: parent ? parent.width : 0
        spacing: 0

        SettingsSectionLabel {
            width: parent.width
            text: I18n.trFor("persona5Calendar", "Appearance")
        }

        SettingsGroup {
            width: parent.width
            slotColor: SettingsMetrics.controlColor

            SettingsDropdownRow {
                text: I18n.trFor("persona5Calendar", "Theme Palette")
                description: I18n.trFor("persona5Calendar", "Vanilla, Royal, or Dynamic (Royal in Jan–Feb).")
                options: [
                    I18n.trFor("persona5Calendar", "Dynamic (Vanilla, Royal in Jan/Feb)"),
                    I18n.trFor("persona5Calendar", "Vanilla (Persona 5)"),
                    I18n.trFor("persona5Calendar", "Royal (Persona 5 Royal)")
                ]
                optionValues: ["dynamic", "vanilla", "royal"]
                currentValue: root.themeVersion
                modified: root.themeVersion !== root.defaultThemeVersion
                resetByKeys: false
                onResetRequested: {
                    root.themeVersion = root.defaultThemeVersion;
                    root.saveValue("themeVersion", root.defaultThemeVersion);
                }
                onValueChanged: val => {
                    root.themeVersion = val;
                    root.saveValue("themeVersion", val);
                }
            }

            SettingsSliderRow {
                text: I18n.trFor("persona5Calendar", "Widget Opacity")
                description: I18n.trFor("persona5Calendar", "Adjust transparency of the calendar HUD.")
                minimum: 20
                maximum: 100
                step: 5
                unit: "%"
                value: root.widgetOpacity
                modified: root.widgetOpacity !== root.defaultWidgetOpacity
                resetByKeys: false
                onResetRequested: {
                    root.widgetOpacity = root.defaultWidgetOpacity;
                    root.saveValue("widgetOpacity", root.defaultWidgetOpacity);
                }
                onSliderDragFinished: finalValue => {
                    root.widgetOpacity = finalValue;
                    root.saveValue("widgetOpacity", finalValue);
                }
            }
        }
    }

    Column {
        width: parent ? parent.width : 0
        spacing: 0

        SettingsSectionLabel {
            width: parent.width
            text: I18n.trFor("persona5Calendar", "Schedule")
        }

        SettingsGroup {
            width: parent.width
            slotColor: SettingsMetrics.controlColor

            SettingsDropdownRow {
                text: I18n.trFor("persona5Calendar", "Time of Day Logic")
                description: I18n.trFor("persona5Calendar", "Use Persona 5 game schedule or local solar time.")
                options: [
                    I18n.trFor("persona5Calendar", "Persona 5 Game Schedule"),
                    I18n.trFor("persona5Calendar", "Solar Schedule (Sun Times)")
                ]
                optionValues: ["game", "solar"]
                currentValue: root.todMode
                modified: root.todMode !== root.defaultTodMode
                resetByKeys: false
                onResetRequested: {
                    root.todMode = root.defaultTodMode;
                    root.saveValue("todMode", root.defaultTodMode);
                }
                onValueChanged: val => {
                    root.todMode = val;
                    root.saveValue("todMode", val);
                }
            }

            SettingsToggleRow {
                text: I18n.trFor("persona5Calendar", "Display Weather Icon")
                description: I18n.trFor("persona5Calendar", "Show current weather condition integrated with DMS WeatherService.")
                checked: root.showWeather
                modified: root.showWeather !== root.defaultShowWeather
                resetByKeys: false
                onResetRequested: {
                    root.showWeather = root.defaultShowWeather;
                    root.saveValue("showWeather", root.defaultShowWeather);
                }
                onToggled: isChecked => {
                    root.showWeather = isChecked;
                    root.saveValue("showWeather", isChecked);
                }
            }

            SettingsToggleRow {
                text: I18n.trFor("persona5Calendar", "Animate Weather")
                description: I18n.trFor("persona5Calendar", "Cycle weather icon frames for game-authentic animation.")
                checked: root.animateWeather
                enabled: root.showWeather
                modified: root.animateWeather !== root.defaultAnimateWeather
                resetByKeys: false
                onResetRequested: {
                    root.animateWeather = root.defaultAnimateWeather;
                    root.saveValue("animateWeather", root.defaultAnimateWeather);
                }
                onToggled: isChecked => {
                    root.animateWeather = isChecked;
                    root.saveValue("animateWeather", isChecked);
                }
            }

            SettingsSliderRow {
                text: I18n.trFor("persona5Calendar", "Animation Speed")
                description: I18n.trFor("persona5Calendar", "Interval between weather animation frames (lower is faster).")
                minimum: 150
                maximum: 800
                step: 10
                unit: "ms"
                value: root.animInterval
                enabled: root.showWeather && root.animateWeather
                modified: root.animInterval !== root.defaultAnimInterval
                resetByKeys: false
                onResetRequested: {
                    root.animInterval = root.defaultAnimInterval;
                    root.saveValue("animInterval", root.defaultAnimInterval);
                }
                onSliderDragFinished: finalValue => {
                    root.animInterval = finalValue;
                    root.saveValue("animInterval", finalValue);
                }
            }
        }
    }

    Column {
        width: parent ? parent.width : 0
        spacing: 0

        SettingsSectionLabel {
            width: parent.width
            text: I18n.trFor("persona5Calendar", "Interactions")
        }

        SettingsGroup {
            width: parent.width
            slotColor: SettingsMetrics.controlColor

            SettingsDropdownRow {
                text: I18n.trFor("persona5Calendar", "Click Action")
                description: I18n.trFor("persona5Calendar", "Action triggered when clicking anywhere on the calendar.")
                options: [
                    I18n.trFor("persona5Calendar", "Force Refresh Weather"),
                    I18n.trFor("persona5Calendar", "Show Date & Weather Toast"),
                    I18n.trFor("persona5Calendar", "None")
                ]
                optionValues: ["refresh", "dateInfo", "none"]
                currentValue: root.clickAction
                modified: root.clickAction !== root.defaultClickAction
                resetByKeys: false
                onResetRequested: {
                    root.clickAction = root.defaultClickAction;
                    root.saveValue("clickAction", root.defaultClickAction);
                }
                onValueChanged: val => {
                    root.clickAction = val;
                    root.saveValue("clickAction", val);
                }
            }
        }
    }

    Column {
        id: creditsSection
        width: parent ? parent.width : 0
        spacing: 0

        property bool expanded: true

        SettingsSectionLabel {
            width: parent.width
            text: I18n.trFor("persona5Calendar", "Credits")
            collapsible: true
            expanded: creditsSection.expanded
            onToggleRequested: {
                creditsSection.expanded = !creditsSection.expanded;
                if (root.pluginService)
                    root.saveValue("creditsExpanded", creditsSection.expanded);
            }
        }

        SettingsGroup {
            width: parent.width
            slotColor: SettingsMetrics.controlColor
            visible: creditsSection.expanded

            Repeater {
                model: [
                    {
                        author: "ATLUS / SEGA",
                        url: "https://atlus.com",
                        role: I18n.trFor("persona5Calendar", "Persona 5 & Persona 5 Royal IP, UI design, and visual assets (©ATLUS. ©SEGA.)"),
                        icon: "info"
                    },
                    {
                        author: "Mive82",
                        url: "https://github.com/Mive82/Persona-5-Calendar",
                        role: I18n.trFor("persona5Calendar", "Creator of the original Persona 5 Rainmeter skin"),
                        icon: "code"
                    },
                    {
                        author: "BHDown",
                        url: "https://www.reddit.com/r/Persona5/comments/bjldpg/high_resolution_calendar_assets_and_rainmeter/",
                        role: I18n.trFor("persona5Calendar", "High-resolution calendar vector graphics and assets"),
                        icon: "brush"
                    },
                    {
                        author: "Dartemil",
                        url: "https://www.deviantart.com/dartemil",
                        role: I18n.trFor("persona5Calendar", "Original Persona 5 Calendar skin concept"),
                        icon: "palette"
                    }
                ]

                delegate: SettingsRow {
                    required property var modelData
                    title: modelData.author
                    subtitle: modelData.role
                    iconName: modelData.icon
                    iconBox: true
                    clickable: true
                    showChevron: true
                    onClicked: Qt.openUrlExternally(modelData.url)
                }
            }
        }
    }
}
