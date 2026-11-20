import "./shared"
import QtQuick
import QtQuick.Controls
import qs.Common
import qs.DCommon.Widgets
import qs.Modules.Plugins
import qs.Modules.Settings.Widgets
import qs.Services

PluginSettings {
    id: root
    pluginId: "hiddenBar"

    readonly property bool defaultUsePopout: false
    readonly property string defaultPopoutLayout: "row"
    readonly property int defaultPopoutWidthAdjustment: 48
    readonly property int defaultPopoutHeightAdjustment: 6
    readonly property bool defaultStartExpanded: false
    readonly property bool defaultAutoExpand: true
    readonly property int defaultHoverDelay: 0
    readonly property bool defaultAutoCollapse: true
    readonly property int defaultCollapseDelay: 1
    readonly property bool defaultAnimateCollapse: true
    readonly property int defaultAnimDuration: 220
    readonly property bool defaultHideIconPillWhenCollapsed: false
    readonly property bool defaultHideIconPillWhenExpanded: false

    readonly property bool defaultExtendedTrigger: true
    readonly property bool defaultShowRegionPreview: false
    readonly property int defaultTriggerAdjustment: 0
    readonly property int defaultTriggerOffset: 0
    readonly property int defaultTriggerHeightAdjustment: 0
    readonly property int defaultTriggerYOffset: 0

    readonly property string defaultWidgetSelectionMode: "auto"
    readonly property bool defaultExcludeTray: true
    readonly property bool defaultExcludeClock: true
    readonly property int defaultHideCount: 0

    property bool usePopout: defaultUsePopout
    property string popoutLayout: defaultPopoutLayout
    property int popoutWidthAdjustment: defaultPopoutWidthAdjustment
    property int popoutHeightAdjustment: defaultPopoutHeightAdjustment
    property bool startExpanded: defaultStartExpanded
    property bool autoExpand: defaultAutoExpand
    property int hoverDelay: defaultHoverDelay
    property bool autoCollapse: defaultAutoCollapse
    property int collapseDelay: defaultCollapseDelay
    property bool animateCollapse: defaultAnimateCollapse
    property int animDuration: defaultAnimDuration
    property bool hideIconPillWhenCollapsed: defaultHideIconPillWhenCollapsed
    property bool hideIconPillWhenExpanded: defaultHideIconPillWhenExpanded

    property bool extendedTrigger: defaultExtendedTrigger
    property bool showRegionPreview: defaultShowRegionPreview
    property int triggerAdjustment: defaultTriggerAdjustment
    property int triggerOffset: defaultTriggerOffset
    property int triggerHeightAdjustment: defaultTriggerHeightAdjustment
    property int triggerYOffset: defaultTriggerYOffset

    property string widgetSelectionMode: defaultWidgetSelectionMode
    property bool excludeTray: defaultExcludeTray
    property bool excludeClock: defaultExcludeClock
    property int hideCount: defaultHideCount

    function loadSettings() {
        if (!pluginService)
            return;
        usePopout = loadValue("usePopout", defaultUsePopout);
        popoutLayout = loadValue("popoutLayout", defaultPopoutLayout);
        popoutWidthAdjustment = loadValue("popoutWidthAdjustment", defaultPopoutWidthAdjustment);
        popoutHeightAdjustment = loadValue("popoutHeightAdjustment", defaultPopoutHeightAdjustment);
        startExpanded = loadValue("startExpanded", defaultStartExpanded);
        autoExpand = loadValue("autoExpand", defaultAutoExpand);
        hoverDelay = loadValue("hoverDelay", defaultHoverDelay);
        autoCollapse = loadValue("autoCollapse", defaultAutoCollapse);
        collapseDelay = loadValue("collapseDelay", defaultCollapseDelay);
        animateCollapse = loadValue("animateCollapse", defaultAnimateCollapse);
        animDuration = loadValue("animDuration", defaultAnimDuration);
        hideIconPillWhenCollapsed = loadValue("hideIconPillWhenCollapsed", defaultHideIconPillWhenCollapsed);
        hideIconPillWhenExpanded = loadValue("hideIconPillWhenExpanded", defaultHideIconPillWhenExpanded);

        extendedTrigger = loadValue("extendedTrigger", defaultExtendedTrigger);
        showRegionPreview = loadValue("showRegionPreview", defaultShowRegionPreview);
        triggerAdjustment = loadValue("triggerAdjustment", defaultTriggerAdjustment);
        triggerOffset = loadValue("triggerOffset", defaultTriggerOffset);
        triggerHeightAdjustment = loadValue("triggerHeightAdjustment", defaultTriggerHeightAdjustment);
        triggerYOffset = loadValue("triggerYOffset", defaultTriggerYOffset);

        widgetSelectionMode = loadValue("widgetSelectionMode", defaultWidgetSelectionMode);
        excludeTray = loadValue("excludeTray", defaultExcludeTray);
        excludeClock = loadValue("excludeClock", defaultExcludeClock);
        hideCount = loadValue("hideCount", defaultHideCount);
        widgetList.loadValue();

        ipcSection.expanded = loadValue("ipcCommandsExpanded", false);
        usageSection.expanded = loadValue("usageGuideExpanded", true);
    }

    Component.onCompleted: loadSettings()
    onPluginServiceChanged: loadSettings()

    Column {
        width: parent ? parent.width : 0
        spacing: 0

        SettingsGroup {
            width: parent.width
            slotColor: SettingsMetrics.controlColor

            SettingsNoteRow {
                noteIconName: "warning"
                tint: Theme.warning
                tintBackground: Theme.withAlpha(Theme.warning, 0.08)
                text: I18n.trFor("hiddenBar", "Inline mode detects newly added status bar widgets automatically. Popout Overflow changes require restarting DankMaterialShell ('dms restart').")
            }
        }
    }

    Column {
        width: parent ? parent.width : 0
        spacing: 0

        SettingsSectionLabel {
            width: parent.width
            text: I18n.trFor("hiddenBar", "Expansion")
        }

        SettingsGroup {
            width: parent.width
            slotColor: SettingsMetrics.controlColor

            SettingsToggleRow {
                text: I18n.trFor("hiddenBar", "Use Popout Overflow")
                description: I18n.trFor("hiddenBar", "Show hidden plugins in a separate popout menu instead of expanding the status bar.")
                checked: root.usePopout
                modified: root.usePopout !== root.defaultUsePopout
                resetByKeys: false
                onResetRequested: {
                    root.usePopout = root.defaultUsePopout;
                    root.saveValue("usePopout", root.defaultUsePopout);
                }
                onToggled: isChecked => {
                    root.usePopout = isChecked;
                    root.saveValue("usePopout", isChecked);
                }
            }

            SettingsDropdownRow {
                visible: root.usePopout
                text: I18n.trFor("hiddenBar", "Popout Layout")
                description: I18n.trFor("hiddenBar", "How icons are arranged inside the popout.")
                options: [
                    I18n.trFor("hiddenBar", "Horizontal Row"),
                    I18n.trFor("hiddenBar", "Grid")
                ]
                optionValues: ["row", "grid"]
                currentValue: root.popoutLayout
                modified: root.popoutLayout !== root.defaultPopoutLayout
                resetByKeys: false
                onResetRequested: {
                    root.popoutLayout = root.defaultPopoutLayout;
                    root.saveValue("popoutLayout", root.defaultPopoutLayout);
                }
                onValueChanged: val => {
                    root.popoutLayout = val;
                    root.saveValue("popoutLayout", val);
                }
            }

            SettingsSliderRow {
                visible: root.usePopout && root.popoutLayout === "row"
                text: I18n.trFor("hiddenBar", "Popout width adjustment")
                description: I18n.trFor("hiddenBar", "Fine-tune the horizontal popout width.")
                minimum: -150
                maximum: 150
                step: 5
                unit: "px"
                value: root.popoutWidthAdjustment
                modified: root.popoutWidthAdjustment !== root.defaultPopoutWidthAdjustment
                resetByKeys: false
                onResetRequested: {
                    root.popoutWidthAdjustment = root.defaultPopoutWidthAdjustment;
                    root.saveValue("popoutWidthAdjustment", root.defaultPopoutWidthAdjustment);
                }
                onSliderDragFinished: finalValue => {
                    root.popoutWidthAdjustment = finalValue;
                    root.saveValue("popoutWidthAdjustment", finalValue);
                }
            }

            SettingsSliderRow {
                visible: root.usePopout
                text: I18n.trFor("hiddenBar", "Popout height adjustment")
                description: I18n.trFor("hiddenBar", "Fine-tune the popout height.")
                minimum: -150
                maximum: 150
                step: 5
                unit: "px"
                value: root.popoutHeightAdjustment
                modified: root.popoutHeightAdjustment !== root.defaultPopoutHeightAdjustment
                resetByKeys: false
                onResetRequested: {
                    root.popoutHeightAdjustment = root.defaultPopoutHeightAdjustment;
                    root.saveValue("popoutHeightAdjustment", root.defaultPopoutHeightAdjustment);
                }
                onSliderDragFinished: finalValue => {
                    root.popoutHeightAdjustment = finalValue;
                    root.saveValue("popoutHeightAdjustment", finalValue);
                }
            }

            SettingsToggleRow {
                visible: !root.usePopout
                text: I18n.trFor("hiddenBar", "Start expanded")
                checked: root.startExpanded
                modified: root.startExpanded !== root.defaultStartExpanded
                resetByKeys: false
                onResetRequested: {
                    root.startExpanded = root.defaultStartExpanded;
                    root.saveValue("startExpanded", root.defaultStartExpanded);
                }
                onToggled: isChecked => {
                    root.startExpanded = isChecked;
                    root.saveValue("startExpanded", isChecked);
                }
            }

            SettingsToggleRow {
                text: I18n.trFor("hiddenBar", "Auto-expand on hover")
                checked: root.autoExpand
                modified: root.autoExpand !== root.defaultAutoExpand
                resetByKeys: false
                onResetRequested: {
                    root.autoExpand = root.defaultAutoExpand;
                    root.saveValue("autoExpand", root.defaultAutoExpand);
                }
                onToggled: isChecked => {
                    root.autoExpand = isChecked;
                    root.saveValue("autoExpand", isChecked);
                }
            }

            SettingsSliderRow {
                visible: root.autoExpand
                text: I18n.trFor("hiddenBar", "Hover delay")
                description: I18n.trFor("hiddenBar", "Wait time before expanding on hover.")
                minimum: 0
                maximum: 1000
                step: 25
                unit: "ms"
                value: root.hoverDelay
                modified: root.hoverDelay !== root.defaultHoverDelay
                resetByKeys: false
                onResetRequested: {
                    root.hoverDelay = root.defaultHoverDelay;
                    root.saveValue("hoverDelay", root.defaultHoverDelay);
                }
                onSliderDragFinished: finalValue => {
                    root.hoverDelay = finalValue;
                    root.saveValue("hoverDelay", finalValue);
                }
            }

            SettingsToggleRow {
                text: I18n.trFor("hiddenBar", "Auto-collapse")
                checked: root.autoCollapse
                modified: root.autoCollapse !== root.defaultAutoCollapse
                resetByKeys: false
                onResetRequested: {
                    root.autoCollapse = root.defaultAutoCollapse;
                    root.saveValue("autoCollapse", root.defaultAutoCollapse);
                }
                onToggled: isChecked => {
                    root.autoCollapse = isChecked;
                    root.saveValue("autoCollapse", isChecked);
                }
            }

            SettingsSliderRow {
                visible: root.autoCollapse
                text: I18n.trFor("hiddenBar", "Collapse delay")
                description: I18n.trFor("hiddenBar", "Wait time before collapsing automatically.")
                minimum: 0
                maximum: 10
                step: 1
                unit: "s"
                value: root.collapseDelay
                modified: root.collapseDelay !== root.defaultCollapseDelay
                resetByKeys: false
                onResetRequested: {
                    root.collapseDelay = root.defaultCollapseDelay;
                    root.saveValue("collapseDelay", root.defaultCollapseDelay);
                }
                onSliderDragFinished: finalValue => {
                    root.collapseDelay = finalValue;
                    root.saveValue("collapseDelay", finalValue);
                }
            }

            SettingsToggleRow {
                text: I18n.trFor("hiddenBar", "Animate collapse")
                description: I18n.trFor("hiddenBar", "Slide widgets in and out instead of switching instantly. When off, the space is reclaimed immediately.")
                checked: root.animateCollapse
                modified: root.animateCollapse !== root.defaultAnimateCollapse
                resetByKeys: false
                onResetRequested: {
                    root.animateCollapse = root.defaultAnimateCollapse;
                    root.saveValue("animateCollapse", root.defaultAnimateCollapse);
                }
                onToggled: isChecked => {
                    root.animateCollapse = isChecked;
                    root.saveValue("animateCollapse", isChecked);
                }
            }

            SettingsSliderRow {
                visible: root.animateCollapse
                text: I18n.trFor("hiddenBar", "Animation duration")
                description: I18n.trFor("hiddenBar", "How long the slide animation takes.")
                minimum: 80
                maximum: 600
                step: 10
                unit: "ms"
                value: root.animDuration
                modified: root.animDuration !== root.defaultAnimDuration
                resetByKeys: false
                onResetRequested: {
                    root.animDuration = root.defaultAnimDuration;
                    root.saveValue("animDuration", root.defaultAnimDuration);
                }
                onSliderDragFinished: finalValue => {
                    root.animDuration = finalValue;
                    root.saveValue("animDuration", finalValue);
                }
            }

            SettingsToggleRow {
                text: I18n.trFor("hiddenBar", "Hide icon pill when collapsed")
                description: I18n.trFor("hiddenBar", "Completely hide the trigger icon pill when the bar is collapsed.")
                checked: root.hideIconPillWhenCollapsed
                modified: root.hideIconPillWhenCollapsed !== root.defaultHideIconPillWhenCollapsed
                resetByKeys: false
                onResetRequested: {
                    root.hideIconPillWhenCollapsed = root.defaultHideIconPillWhenCollapsed;
                    root.saveValue("hideIconPillWhenCollapsed", root.defaultHideIconPillWhenCollapsed);
                }
                onToggled: isChecked => {
                    root.hideIconPillWhenCollapsed = isChecked;
                    root.saveValue("hideIconPillWhenCollapsed", isChecked);
                }
            }

            SettingsToggleRow {
                text: I18n.trFor("hiddenBar", "Hide icon pill when expanded")
                description: I18n.trFor("hiddenBar", "Completely hide the trigger icon pill when the bar is expanded.")
                checked: root.hideIconPillWhenExpanded
                modified: root.hideIconPillWhenExpanded !== root.defaultHideIconPillWhenExpanded
                resetByKeys: false
                onResetRequested: {
                    root.hideIconPillWhenExpanded = root.defaultHideIconPillWhenExpanded;
                    root.saveValue("hideIconPillWhenExpanded", root.defaultHideIconPillWhenExpanded);
                }
                onToggled: isChecked => {
                    root.hideIconPillWhenExpanded = isChecked;
                    root.saveValue("hideIconPillWhenExpanded", isChecked);
                }
            }
        }
    }

    Column {
        width: parent ? parent.width : 0
        spacing: 0

        SettingsSectionLabel {
            width: parent.width
            text: I18n.trFor("hiddenBar", "Trigger Zone")
        }

        SettingsGroup {
            width: parent.width
            slotColor: SettingsMetrics.controlColor

            SettingsToggleRow {
                text: I18n.trFor("hiddenBar", "Extended trigger area")
                description: I18n.trFor("hiddenBar", "Allow triggering expansion by hovering over the area where icons are hidden.")
                checked: root.extendedTrigger
                modified: root.extendedTrigger !== root.defaultExtendedTrigger
                resetByKeys: false
                onResetRequested: {
                    root.extendedTrigger = root.defaultExtendedTrigger;
                    root.saveValue("extendedTrigger", root.defaultExtendedTrigger);
                }
                onToggled: isChecked => {
                    root.extendedTrigger = isChecked;
                    root.saveValue("extendedTrigger", isChecked);
                }
            }

            SettingsToggleRow {
                text: I18n.trFor("hiddenBar", "Show region preview")
                description: I18n.trFor("hiddenBar", "Highlight the expansion trigger zone.")
                checked: root.showRegionPreview
                modified: root.showRegionPreview !== root.defaultShowRegionPreview
                resetByKeys: false
                onResetRequested: {
                    root.showRegionPreview = root.defaultShowRegionPreview;
                    root.saveValue("showRegionPreview", root.defaultShowRegionPreview);
                }
                onToggled: isChecked => {
                    root.showRegionPreview = isChecked;
                    root.saveValue("showRegionPreview", isChecked);
                }
            }

            SettingsSliderRow {
                text: I18n.trFor("hiddenBar", "Trigger area width adjustment")
                description: I18n.trFor("hiddenBar", "Fine-tune the trigger zone width along the bar axis. Positive values expand it, negative values shrink it.")
                minimum: -150
                maximum: 150
                step: 5
                unit: "px"
                value: root.triggerAdjustment
                modified: root.triggerAdjustment !== root.defaultTriggerAdjustment
                resetByKeys: false
                onResetRequested: {
                    root.triggerAdjustment = root.defaultTriggerAdjustment;
                    root.saveValue("triggerAdjustment", root.defaultTriggerAdjustment);
                }
                onSliderDragFinished: finalValue => {
                    root.triggerAdjustment = finalValue;
                    root.saveValue("triggerAdjustment", finalValue);
                }
            }

            SettingsSliderRow {
                text: I18n.trFor("hiddenBar", "Trigger area X offset")
                description: I18n.trFor("hiddenBar", "Shift the trigger zone position along the bar axis. Positive values shift right/down, negative values shift left/up.")
                minimum: -100
                maximum: 100
                step: 5
                unit: "px"
                value: root.triggerOffset
                modified: root.triggerOffset !== root.defaultTriggerOffset
                resetByKeys: false
                onResetRequested: {
                    root.triggerOffset = root.defaultTriggerOffset;
                    root.saveValue("triggerOffset", root.defaultTriggerOffset);
                }
                onSliderDragFinished: finalValue => {
                    root.triggerOffset = finalValue;
                    root.saveValue("triggerOffset", finalValue);
                }
            }

            SettingsSliderRow {
                text: I18n.trFor("hiddenBar", "Trigger area height adjustment")
                description: I18n.trFor("hiddenBar", "Adjust the height (thickness) of the trigger area perpendicular to the bar.")
                minimum: -30
                maximum: 30
                step: 1
                unit: "px"
                value: root.triggerHeightAdjustment
                modified: root.triggerHeightAdjustment !== root.defaultTriggerHeightAdjustment
                resetByKeys: false
                onResetRequested: {
                    root.triggerHeightAdjustment = root.defaultTriggerHeightAdjustment;
                    root.saveValue("triggerHeightAdjustment", root.defaultTriggerHeightAdjustment);
                }
                onSliderDragFinished: finalValue => {
                    root.triggerHeightAdjustment = finalValue;
                    root.saveValue("triggerHeightAdjustment", finalValue);
                }
            }

            SettingsSliderRow {
                text: I18n.trFor("hiddenBar", "Trigger area Y offset")
                description: I18n.trFor("hiddenBar", "Shift the trigger zone position perpendicular to the bar axis. Positive values shift down/right, negative values shift up/left.")
                minimum: -40
                maximum: 40
                step: 1
                unit: "px"
                value: root.triggerYOffset
                modified: root.triggerYOffset !== root.defaultTriggerYOffset
                resetByKeys: false
                onResetRequested: {
                    root.triggerYOffset = root.defaultTriggerYOffset;
                    root.saveValue("triggerYOffset", root.defaultTriggerYOffset);
                }
                onSliderDragFinished: finalValue => {
                    root.triggerYOffset = finalValue;
                    root.saveValue("triggerYOffset", finalValue);
                }
            }
        }
    }

    Column {
        width: parent ? parent.width : 0
        spacing: 0

        SettingsSectionLabel {
            width: parent.width
            text: I18n.trFor("hiddenBar", "Widget Control")
        }

        SettingsGroup {
            width: parent.width
            slotColor: SettingsMetrics.controlColor

            SettingsDropdownRow {
                text: I18n.trFor("hiddenBar", "Widget selection")
                description: I18n.trFor("hiddenBar", "Auto hides every eligible widget. Blacklist hides all except the widgets you pick. Whitelist hides only the widgets you pick.")
                options: [
                    I18n.trFor("hiddenBar", "Auto"),
                    I18n.trFor("hiddenBar", "Blacklist"),
                    I18n.trFor("hiddenBar", "Whitelist")
                ]
                optionValues: ["auto", "blacklist", "whitelist"]
                currentValue: root.widgetSelectionMode
                modified: root.widgetSelectionMode !== root.defaultWidgetSelectionMode
                resetByKeys: false
                onResetRequested: {
                    root.widgetSelectionMode = root.defaultWidgetSelectionMode;
                    root.saveValue("widgetSelectionMode", root.defaultWidgetSelectionMode);
                }
                onValueChanged: val => {
                    root.widgetSelectionMode = val;
                    root.saveValue("widgetSelectionMode", val);
                }
            }

            SettingsToggleRow {
                visible: root.widgetSelectionMode === "auto"
                text: I18n.trFor("hiddenBar", "Keep System Tray")
                description: I18n.trFor("hiddenBar", "Never hide the system tray widgets.")
                checked: root.excludeTray
                modified: root.excludeTray !== root.defaultExcludeTray
                resetByKeys: false
                onResetRequested: {
                    root.excludeTray = root.defaultExcludeTray;
                    root.saveValue("excludeTray", root.defaultExcludeTray);
                }
                onToggled: isChecked => {
                    root.excludeTray = isChecked;
                    root.saveValue("excludeTray", isChecked);
                }
            }

            SettingsToggleRow {
                visible: root.widgetSelectionMode === "auto"
                text: I18n.trFor("hiddenBar", "Keep Clock")
                description: I18n.trFor("hiddenBar", "Never hide the clock widget.")
                checked: root.excludeClock
                modified: root.excludeClock !== root.defaultExcludeClock
                resetByKeys: false
                onResetRequested: {
                    root.excludeClock = root.defaultExcludeClock;
                    root.saveValue("excludeClock", root.defaultExcludeClock);
                }
                onToggled: isChecked => {
                    root.excludeClock = isChecked;
                    root.saveValue("excludeClock", isChecked);
                }
            }

            // Granular widget control: an explicit blacklist/whitelist of bar
            // widgets. The list is sourced from BarWidgetService so the IDs match
            // exactly what the widget filters on at runtime. Persists an array of
            // widget IDs per mode via the PluginSettings root (saveValue/loadValue).
            Column {
                id: widgetList

                width: parent.width
                visible: root.widgetSelectionMode !== "auto"
                spacing: Theme.spacingS
                topPadding: visible ? Theme.spacingS : 0

                readonly property string settingKey: root.widgetSelectionMode === "whitelist" ? "widgetWhitelist" : "widgetBlacklist"
                property var selectedIds: []
                property var widgetModel: []

                // Mirrors DMS' baseWidgetDefinitions.coreWidgets in
                // Modules/Settings/WidgetsTab.qml so built-in widgets show the same
                // name/icon as the bar settings. Keep in sync on DMS updates: new or
                // renamed built-ins missing here fall back to prettify(id) + the
                // generic "widgets" icon (see buildModel's else branch). There is no
                // upstream catalog singleton — BarWidgetService exposes IDs only.
                readonly property var builtinCatalog: ({
                    "layout": { text: I18n.trFor("hiddenBar", "Layout"), icon: "view_quilt" },
                    "launcherButton": { text: I18n.trFor("hiddenBar", "App Launcher"), icon: "apps" },
                    "workspaceSwitcher": { text: I18n.trFor("hiddenBar", "Workspace Switcher"), icon: "view_module" },
                    "focusedWindow": { text: I18n.trFor("hiddenBar", "Focused Window"), icon: "window" },
                    "runningApps": { text: I18n.trFor("hiddenBar", "Running Apps"), icon: "apps" },
                    "appsDock": { text: I18n.trFor("hiddenBar", "Apps Dock"), icon: "dock_to_bottom" },
                    "clock": { text: I18n.trFor("hiddenBar", "Clock"), icon: "schedule" },
                    "weather": { text: I18n.trFor("hiddenBar", "Weather Widget"), icon: "wb_sunny" },
                    "music": { text: I18n.trFor("hiddenBar", "Media Controls"), icon: "music_note" },
                    "clipboard": { text: I18n.trFor("hiddenBar", "Clipboard Manager"), icon: "content_paste" },
                    "cpuUsage": { text: I18n.trFor("hiddenBar", "CPU Usage"), icon: "memory" },
                    "memUsage": { text: I18n.trFor("hiddenBar", "Memory Usage"), icon: "developer_board" },
                    "diskUsage": { text: I18n.trFor("hiddenBar", "Disk Usage"), icon: "storage" },
                    "cpuTemp": { text: I18n.trFor("hiddenBar", "CPU Temperature"), icon: "device_thermostat" },
                    "gpuTemp": { text: I18n.trFor("hiddenBar", "GPU Temperature"), icon: "auto_awesome_mosaic" },
                    "systemTray": { text: I18n.trFor("hiddenBar", "System Tray"), icon: "notifications" },
                    "privacyIndicator": { text: I18n.trFor("hiddenBar", "Privacy Indicator"), icon: "privacy_tip" },
                    "controlCenterButton": { text: I18n.trFor("hiddenBar", "Control Center"), icon: "settings" },
                    "notificationButton": { text: I18n.trFor("hiddenBar", "Notification Center"), icon: "notifications" },
                    "battery": { text: I18n.trFor("hiddenBar", "Battery"), icon: "battery_std" },
                    "vpn": { text: I18n.trFor("hiddenBar", "VPN"), icon: "vpn_lock" },
                    "idleInhibitor": { text: I18n.trFor("hiddenBar", "Idle Inhibitor"), icon: "motion_sensor_active" },
                    "capsLockIndicator": { text: I18n.trFor("hiddenBar", "Caps Lock Indicator"), icon: "shift_lock" },
                    "spacer": { text: I18n.trFor("hiddenBar", "Spacer"), icon: "more_horiz" },
                    "separator": { text: I18n.trFor("hiddenBar", "Separator"), icon: "remove" },
                    "network_speed_monitor": { text: I18n.trFor("hiddenBar", "Network Speed Monitor"), icon: "network_check" },
                    "keyboard_layout_name": { text: I18n.trFor("hiddenBar", "Keyboard Layout Name"), icon: "keyboard" },
                    "notepadButton": { text: I18n.trFor("hiddenBar", "Notepad"), icon: "assignment" },
                    "colorPicker": { text: I18n.trFor("hiddenBar", "Color Picker"), icon: "palette" },
                    "systemUpdate": { text: I18n.trFor("hiddenBar", "System Update"), icon: "update" },
                    "powerMenuButton": { text: I18n.trFor("hiddenBar", "Power"), icon: "power_settings_new" }
                })

                // Turn an unknown widget id into a readable label, e.g.
                // "network_speed_monitor" -> "Network Speed Monitor".
                function prettify(id) {
                    let s = String(id).replace(/[:_]/g, " ").replace(/([a-z0-9])([A-Z])/g, "$1 $2");
                    return s.charAt(0).toUpperCase() + s.slice(1);
                }

                function loadValue() {
                    if (!root.pluginService)
                        return;
                    selectedIds = (root.loadValue(settingKey, []) || []).slice();
                }

                function persist() {
                    root.saveValue(settingKey, selectedIds);
                }

                function isSelected(id) {
                    return selectedIds.indexOf(id) !== -1;
                }

                function setSelected(id, on) {
                    let arr = selectedIds.slice();
                    let i = arr.indexOf(id);
                    if (on && i === -1)
                        arr.push(id);
                    else if (!on && i !== -1)
                        arr.splice(i, 1);
                    selectedIds = arr;
                    persist();
                }

                function buildModel() {
                    const ids = BarWidgetService.getRegisteredWidgetIds ? BarWidgetService.getRegisteredWidgetIds() : [];
                    const variants = (PluginService && PluginService.getAllPluginVariants) ? PluginService.getAllPluginVariants() : [];
                    let variantMap = ({});
                    for (let v = 0; v < variants.length; v++) {
                        if (variants[v] && variants[v].fullId)
                            variantMap[variants[v].fullId] = variants[v];
                    }
                    let out = [];
                    for (let i = 0; i < ids.length; i++) {
                        let id = ids[i];
                        if (id === root.pluginId || id.indexOf(root.pluginId + ":") === 0)
                            continue;
                        let def = builtinCatalog[id];
                        let name, icon;
                        if (def) {
                            name = def.text;
                            icon = def.icon;
                        } else if (variantMap[id]) {
                            name = variantMap[id].name || prettify(id);
                            icon = variantMap[id].icon || "extension";
                        } else {
                            name = prettify(id);
                            icon = "widgets";
                        }
                        out.push({ "id": id, "name": name, "icon": icon });
                    }
                    out.sort((a, b) => a.name.localeCompare(b.name));
                    widgetModel = out;
                }

                onSettingKeyChanged: loadValue()
                Component.onCompleted: {
                    buildModel();
                    Qt.callLater(loadValue);
                }

                Connections {
                    target: BarWidgetService
                    function onWidgetRegistered(id, screen) { widgetList.buildModel(); }
                    function onWidgetUnregistered(id, screen) { widgetList.buildModel(); }
                }

                StyledText {
                    width: parent.width
                    text: root.widgetSelectionMode === "whitelist" ? I18n.trFor("hiddenBar", "Only hide these widgets:") : I18n.trFor("hiddenBar", "Never hide these widgets:")
                    font.pixelSize: Theme.fontSizeMedium
                    font.weight: Font.Medium
                    color: Theme.surfaceText
                    wrapMode: Text.WordWrap
                }

                Repeater {
                    model: widgetList.widgetModel
                    delegate: Item {
                        width: widgetList.width
                        height: 40

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: widgetList.setSelected(modelData.id, !widgetList.isSelected(modelData.id))
                        }

                        DIcon {
                            id: rowIcon
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            name: modelData.icon
                            size: Theme.iconSizeSmall
                            color: Theme.surfaceText
                        }

                        DToggle {
                            id: rowToggle
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            checked: widgetList.isSelected(modelData.id)
                            onToggled: isChecked => widgetList.setSelected(modelData.id, isChecked)
                        }

                        StyledText {
                            anchors.left: rowIcon.right
                            anchors.leftMargin: Theme.spacingM
                            anchors.right: rowToggle.left
                            anchors.rightMargin: Theme.spacingM
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData.name
                            font.pixelSize: Theme.fontSizeMedium
                            color: Theme.surfaceText
                            elide: Text.ElideRight
                        }
                    }
                }

                StyledText {
                    width: parent.width
                    visible: widgetList.widgetModel.length === 0
                    text: I18n.trFor("hiddenBar", "No manageable widgets detected yet. Add widgets to the bar, then run 'dms restart'.")
                    color: Theme.surfaceVariantText
                    font.pixelSize: Theme.fontSizeSmall
                    wrapMode: Text.WordWrap
                }
            }

            SettingsSliderRow {
                text: I18n.trFor("hiddenBar", "Max hidden widgets")
                description: I18n.trFor("hiddenBar", "Limit the number of widgets to hide. Set to 0 to hide all.")
                minimum: 0
                maximum: 20
                step: 1
                unit: ""
                value: root.hideCount
                modified: root.hideCount !== root.defaultHideCount
                resetByKeys: false
                onResetRequested: {
                    root.hideCount = root.defaultHideCount;
                    root.saveValue("hideCount", root.defaultHideCount);
                }
                onSliderDragFinished: finalValue => {
                    root.hideCount = finalValue;
                    root.saveValue("hideCount", finalValue);
                }
            }
        }
    }

    Column {
        id: ipcSection
        width: parent ? parent.width : 0
        spacing: 0

        property bool expanded: false

        SettingsSectionLabel {
            width: parent.width
            text: I18n.trFor("hiddenBar", "IPC Commands")
            collapsible: true
            expanded: ipcSection.expanded
            onToggleRequested: {
                ipcSection.expanded = !ipcSection.expanded;
                if (root.pluginService)
                    root.saveValue("ipcCommandsExpanded", ipcSection.expanded);
            }
        }

        SettingsGroup {
            width: parent.width
            slotColor: SettingsMetrics.controlColor
            visible: ipcSection.expanded

            Column {
                width: parent.width
                spacing: Theme.spacingM

                CopyBox {
                    label: I18n.trFor("hiddenBar", "Toggle Expansion")
                    text: "dms ipc call hiddenBar toggle"
                }

                CopyBox {
                    label: I18n.trFor("hiddenBar", "Expand Area")
                    text: "dms ipc call hiddenBar expand"
                }

                CopyBox {
                    label: I18n.trFor("hiddenBar", "Collapse Area")
                    text: "dms ipc call hiddenBar collapse"
                }

                CopyBox {
                    label: I18n.trFor("hiddenBar", "Pin Expansion")
                    text: "dms ipc call hiddenBar pin"
                }

                CopyBox {
                    label: I18n.trFor("hiddenBar", "Unpin Expansion")
                    text: "dms ipc call hiddenBar unpin"
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
            text: I18n.trFor("hiddenBar", "How to Use")
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
                        I18n.trFor("hiddenBar", "<b>Hover</b> the icon (or trigger zone) to temporarily expand the hidden area."),
                        I18n.trFor("hiddenBar", "<b>Left-click</b> the icon to manually toggle the expanded state."),
                        I18n.trFor("hiddenBar", "<b>Right-click</b> the icon while expanded to <b>PIN</b> (prevent auto-collapse).")
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
