import QtQuick
import QtQuick.Controls
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.Plugins
import "./dms-common"

PluginSettings {
    id: root
    pluginId: "hiddenBar"

    NoteCard {
        title: I18n.tr("Note")
        icon: "warning"
        text: I18n.tr("Please run 'dms restart' after adding widgets to the status bar for changes to take effect.\n\nPopout Overflow: changes to expansion & collapse settings while Popout mode is active may require a DMS restart (dms restart) to fully apply.")
    }

    SettingsCard {
        id: expansionSection
        SectionTitle { 
            text: I18n.tr("Expansion & Collapse")
            icon: "unfold_more" 
            showReset: usePopout.isDirty || popoutLayout.isDirty || startExpanded.isDirty || autoExpand.isDirty || hoverDelay.isDirty || autoCollapse.isDirty || collapseDelay.isDirty || animateCollapse.isDirty || animDuration.isDirty
            onResetClicked: {
                usePopout.resetToDefault();
                popoutLayout.resetToDefault();
                startExpanded.resetToDefault();
                autoExpand.resetToDefault();
                hoverDelay.resetToDefault();
                autoCollapse.resetToDefault();
                collapseDelay.resetToDefault();
                animateCollapse.resetToDefault();
                animDuration.resetToDefault();
            }
        }

        ToggleSettingPlus {
            id: usePopout
            label: I18n.tr("Use Popout Overflow")
            description: I18n.tr("Show hidden plugins in a separate popout menu instead of expanding the status bar.")
            settingKey: "usePopout"
            defaultValue: false
        }

        Separator {
            visible: popoutLayout.visible || startExpanded.visible
            height: visible ? 1 : 0
        }

        SelectionSettingPlus {
            id: popoutLayout
            label: I18n.tr("Popout Layout")
            description: I18n.tr("How icons are arranged inside the popout.")
            settingKey: "popoutLayout"
            defaultValue: "row"
            options: [
                { label: I18n.tr("Horizontal Row"), value: "row" },
                { label: I18n.tr("Grid"), value: "grid" }
            ]
            visible: usePopout.value
            height: visible ? implicitHeight : 0
        }

        Separator {
            visible: popoutWidthAdjustment.visible
            height: visible ? 1 : 0
        }

        SliderSettingPlus {
            id: popoutWidthAdjustment
            label: I18n.tr("Popout width adjustment")
            description: I18n.tr("Fine-tune the horizontal popout width.")
            settingKey: "popoutWidthAdjustment"
            defaultValue: 48
            minimum: -150
            maximum: 150
            unit: "px"
            leftLabel: "-150"
            rightLabel: "150"
            visible: usePopout.value && popoutLayout.value === "row"
            height: visible ? implicitHeight : 0
        }

        Separator {
            visible: popoutHeightAdjustment.visible
            height: visible ? 1 : 0
        }

        SliderSettingPlus {
            id: popoutHeightAdjustment
            label: I18n.tr("Popout height adjustment")
            description: I18n.tr("Fine-tune the popout height.")
            settingKey: "popoutHeightAdjustment"
            defaultValue: 6
            minimum: -150
            maximum: 150
            unit: "px"
            leftLabel: "-150"
            rightLabel: "150"
            visible: usePopout.value
            height: visible ? implicitHeight : 0
        }

        ToggleSettingPlus {
            id: startExpanded
            label: I18n.tr("Start expanded")
            settingKey: "startExpanded"
            defaultValue: false
            visible: !usePopout.value
            height: visible ? implicitHeight : 0
        }

        Separator {
            visible: true
        }

        ToggleSettingPlus {
            id: autoExpand
            label: I18n.tr("Auto-expand on hover")
            settingKey: "autoExpand"
            defaultValue: true
        }

        Separator {
            visible: autoExpand.value
            height: visible ? 1 : 0
        }

        SliderSettingPlus {
            id: hoverDelay
            label: I18n.tr("Hover delay")
            description: I18n.tr("Wait time before expanding on hover.")
            settingKey: "hoverDelay"
            defaultValue: 0
            minimum: 0
            maximum: 1000
            unit: "ms"
            leftLabel: "0"
            rightLabel: "1000"
            visible: autoExpand.value
            height: visible ? implicitHeight : 0
        }

        Separator {}

        ToggleSettingPlus {
            id: autoCollapse
            label: I18n.tr("Auto-collapse")
            settingKey: "autoCollapse"
            defaultValue: true
        }

        SliderSettingPlus {
            id: collapseDelay
            label: I18n.tr("Collapse delay")
            description: I18n.tr("Wait time before collapsing automatically.")
            settingKey: "collapseDelay"
            defaultValue: 1
            minimum: 0
            maximum: 10
            unit: "s"
            leftLabel: "0"
            rightLabel: "10"
            visible: autoCollapse.value
            height: visible ? implicitHeight : 0
        }

        Separator {}

        ToggleSettingPlus {
            id: animateCollapse
            label: I18n.tr("Animate collapse")
            description: I18n.tr("Slide widgets in and out instead of switching instantly. When off, the space is reclaimed immediately.")
            settingKey: "animateCollapse"
            defaultValue: true
        }

        SliderSettingPlus {
            id: animDuration
            label: I18n.tr("Animation duration")
            description: I18n.tr("How long the slide animation takes.")
            settingKey: "animDuration"
            defaultValue: 220
            minimum: 80
            maximum: 600
            unit: "ms"
            leftLabel: "80"
            rightLabel: "600"
            visible: animateCollapse.value
            height: visible ? implicitHeight : 0
        }

        Separator {
            visible: autoCollapse.value
            height: visible ? 1 : 0
        }

        ToggleSettingPlus {
            id: hideIconPillWhenCollapsed
            label: I18n.tr("Hide icon pill when collapsed")
            description: I18n.tr("Completely hide the trigger icon pill when the bar is collapsed.")
            settingKey: "hideIconPillWhenCollapsed"
            defaultValue: false
        }

        Separator {}

        ToggleSettingPlus {
            id: hideIconPillWhenExpanded
            label: I18n.tr("Hide icon pill when expanded")
            description: I18n.tr("Completely hide the trigger icon pill when the bar is expanded.")
            settingKey: "hideIconPillWhenExpanded"
            defaultValue: false
        }
    }

    SettingsCard {
        id: triggerSection
        SectionTitle { 
            text: I18n.tr("Trigger Zone")
            icon: "ads_click" 
            showReset: extendedTrigger.isDirty || showRegionPreview.isDirty || triggerAdjustment.isDirty || triggerOffset.isDirty || triggerHeightAdjustment.isDirty || triggerYOffset.isDirty
            onResetClicked: {
                extendedTrigger.resetToDefault();
                showRegionPreview.resetToDefault();
                triggerAdjustment.resetToDefault();
                triggerOffset.resetToDefault();
                triggerHeightAdjustment.resetToDefault();
                triggerYOffset.resetToDefault();
            }
        }

        ToggleSettingPlus {
            id: extendedTrigger
            label: I18n.tr("Extended trigger area")
            description: I18n.tr("Allow triggering expansion by hovering over the area where icons are hidden.")
            settingKey: "extendedTrigger"
            defaultValue: true
        }

        Separator {}

        ToggleSettingPlus {
            id: showRegionPreview
            label: I18n.tr("Show region preview")
            description: I18n.tr("Highlight the expansion trigger zone.")
            settingKey: "showRegionPreview"
            defaultValue: false
        }

        Separator {}

        SliderSettingPlus {
            id: triggerAdjustment
            label: I18n.tr("Trigger area width adjustment")
            description: I18n.tr("Fine-tune the trigger zone width along the bar axis. Positive values expand it, negative values shrink it.")
            settingKey: "triggerAdjustment"
            defaultValue: 0
            minimum: -150
            maximum: 150
            unit: "px"
            leftLabel: "-150"
            rightLabel: "150"
        }

        Separator {}

        SliderSettingPlus {
            id: triggerOffset
            label: I18n.tr("Trigger area X offset")
            description: I18n.tr("Shift the trigger zone position along the bar axis. Positive values shift right/down, negative values shift left/up.")
            settingKey: "triggerOffset"
            defaultValue: 0
            minimum: -100
            maximum: 100
            unit: "px"
            leftLabel: "-100"
            rightLabel: "100"
        }

        Separator {}

        SliderSettingPlus {
            id: triggerHeightAdjustment
            label: I18n.tr("Trigger area height adjustment")
            description: I18n.tr("Adjust the height (thickness) of the trigger area perpendicular to the bar.")
            settingKey: "triggerHeightAdjustment"
            defaultValue: 0
            minimum: -30
            maximum: 30
            unit: "px"
            leftLabel: "-30"
            rightLabel: "30"
        }

        Separator {}

        SliderSettingPlus {
            id: triggerYOffset
            label: I18n.tr("Trigger area Y offset")
            description: I18n.tr("Shift the trigger zone position perpendicular to the bar axis. Positive values shift down/right, negative values shift up/left.")
            settingKey: "triggerYOffset"
            defaultValue: 0
            minimum: -40
            maximum: 40
            unit: "px"
            leftLabel: "-40"
            rightLabel: "40"
        }
    }

    SettingsCard {
        id: exclusionsSection
        SectionTitle {
            text: I18n.tr("Widget Control")
            icon: "tune"
            showReset: widgetSelectionMode.isDirty || excludeTray.isDirty || excludeClock.isDirty || hideCount.isDirty || (widgetList.hasSelection && widgetList.visible)
            onResetClicked: {
                widgetSelectionMode.resetToDefault();
                excludeTray.resetToDefault();
                excludeClock.resetToDefault();
                hideCount.resetToDefault();
                widgetList.clearAll();
            }
        }

        SelectionSettingPlus {
            id: widgetSelectionMode
            label: I18n.tr("Widget selection")
            description: I18n.tr("Auto hides every eligible widget. Blacklist hides all except the widgets you pick. Whitelist hides only the widgets you pick.")
            settingKey: "widgetSelectionMode"
            defaultValue: "auto"
            options: [
                { label: I18n.tr("Auto"), value: "auto" },
                { label: I18n.tr("Blacklist"), value: "blacklist" },
                { label: I18n.tr("Whitelist"), value: "whitelist" }
            ]
        }

        Separator {
            visible: excludeTray.visible || widgetList.visible
            height: visible ? 1 : 0
        }

        ToggleSettingPlus {
            id: excludeTray
            label: I18n.tr("Keep System Tray")
            description: I18n.tr("Never hide the system tray widgets.")
            settingKey: "excludeTray"
            defaultValue: true
            visible: widgetSelectionMode.value === "auto"
            height: visible ? implicitHeight : 0
        }

        Separator {
            visible: excludeTray.visible
            height: visible ? 1 : 0
        }

        ToggleSettingPlus {
            id: excludeClock
            label: I18n.tr("Keep Clock")
            description: I18n.tr("Never hide the clock widget.")
            settingKey: "excludeClock"
            defaultValue: true
            visible: widgetSelectionMode.value === "auto"
            height: visible ? implicitHeight : 0
        }

        // Granular widget control: an explicit blacklist/whitelist of bar
        // widgets. The list is sourced from BarWidgetService so the IDs match
        // exactly what the widget filters on at runtime. Persists an array of
        // widget IDs per mode via the PluginSettings root (saveValue/loadValue).
        Column {
            id: widgetList

            width: parent.width
            visible: widgetSelectionMode.value !== "auto"
            height: visible ? implicitHeight : 0
            spacing: Theme.spacingS
            topPadding: visible ? Theme.spacingS : 0

            readonly property string settingKey: widgetSelectionMode.value === "whitelist" ? "widgetWhitelist" : "widgetBlacklist"
            property var selectedIds: []
            property var widgetModel: []
            readonly property bool hasSelection: selectedIds.length > 0

            // Mirrors DMS' baseWidgetDefinitions.coreWidgets in
            // Modules/Settings/WidgetsTab.qml so built-in widgets show the same
            // name/icon as the bar settings. Keep in sync on DMS updates: new or
            // renamed built-ins missing here fall back to prettify(id) + the
            // generic "widgets" icon (see buildModel's else branch). There is no
            // upstream catalog singleton — BarWidgetService exposes IDs only.
            readonly property var builtinCatalog: ({
                "layout": { text: I18n.tr("Layout"), icon: "view_quilt" },
                "launcherButton": { text: I18n.tr("App Launcher"), icon: "apps" },
                "workspaceSwitcher": { text: I18n.tr("Workspace Switcher"), icon: "view_module" },
                "focusedWindow": { text: I18n.tr("Focused Window"), icon: "window" },
                "runningApps": { text: I18n.tr("Running Apps"), icon: "apps" },
                "appsDock": { text: I18n.tr("Apps Dock"), icon: "dock_to_bottom" },
                "clock": { text: I18n.tr("Clock"), icon: "schedule" },
                "weather": { text: I18n.tr("Weather Widget"), icon: "wb_sunny" },
                "music": { text: I18n.tr("Media Controls"), icon: "music_note" },
                "clipboard": { text: I18n.tr("Clipboard Manager"), icon: "content_paste" },
                "cpuUsage": { text: I18n.tr("CPU Usage"), icon: "memory" },
                "memUsage": { text: I18n.tr("Memory Usage"), icon: "developer_board" },
                "diskUsage": { text: I18n.tr("Disk Usage"), icon: "storage" },
                "cpuTemp": { text: I18n.tr("CPU Temperature"), icon: "device_thermostat" },
                "gpuTemp": { text: I18n.tr("GPU Temperature"), icon: "auto_awesome_mosaic" },
                "systemTray": { text: I18n.tr("System Tray"), icon: "notifications" },
                "privacyIndicator": { text: I18n.tr("Privacy Indicator"), icon: "privacy_tip" },
                "controlCenterButton": { text: I18n.tr("Control Center"), icon: "settings" },
                "notificationButton": { text: I18n.tr("Notification Center"), icon: "notifications" },
                "battery": { text: I18n.tr("Battery"), icon: "battery_std" },
                "vpn": { text: I18n.tr("VPN"), icon: "vpn_lock" },
                "idleInhibitor": { text: I18n.tr("Idle Inhibitor"), icon: "motion_sensor_active" },
                "capsLockIndicator": { text: I18n.tr("Caps Lock Indicator"), icon: "shift_lock" },
                "spacer": { text: I18n.tr("Spacer"), icon: "more_horiz" },
                "separator": { text: I18n.tr("Separator"), icon: "remove" },
                "network_speed_monitor": { text: I18n.tr("Network Speed Monitor"), icon: "network_check" },
                "keyboard_layout_name": { text: I18n.tr("Keyboard Layout Name"), icon: "keyboard" },
                "notepadButton": { text: I18n.tr("Notepad"), icon: "assignment" },
                "colorPicker": { text: I18n.tr("Color Picker"), icon: "palette" },
                "systemUpdate": { text: I18n.tr("System Update"), icon: "update" },
                "powerMenuButton": { text: I18n.tr("Power"), icon: "power_settings_new" }
            })

            // Turn an unknown widget id into a readable label, e.g.
            // "network_speed_monitor" -> "Network Speed Monitor".
            function prettify(id) {
                let s = String(id).replace(/[:_]/g, " ").replace(/([a-z0-9])([A-Z])/g, "$1 $2");
                return s.charAt(0).toUpperCase() + s.slice(1);
            }

            // Named loadValue() so SettingsCard.loadValue() picks it up on reload.
            // root is the PluginSettings (id: root) and exposes saveValue/loadValue.
            function loadValue() {
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

            function clearAll() {
                selectedIds = [];
                root.saveValue("widgetBlacklist", []);
                root.saveValue("widgetWhitelist", []);
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
                text: widgetSelectionMode.value === "whitelist" ? I18n.tr("Only hide these widgets:") : I18n.tr("Never hide these widgets:")
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

                    DankIcon {
                        id: rowIcon
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        name: modelData.icon
                        size: Theme.iconSizeSmall
                        color: Theme.surfaceText
                    }

                    DankToggle {
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
                text: I18n.tr("No manageable widgets detected yet. Add widgets to the bar, then run 'dms restart'.")
                color: Theme.surfaceVariantText
                font.pixelSize: Theme.fontSizeSmall
                wrapMode: Text.WordWrap
            }
        }

        Separator {
            height: 1
        }

        SliderSettingPlus {
            id: hideCount
            label: I18n.tr("Max hidden widgets")
            description: I18n.tr("Limit the number of widgets to hide. Set to 0 to hide all.")
            settingKey: "hideCount"
            defaultValue: 0
            minimum: 0
            maximum: 20
            leftLabel: "0"
            rightLabel: "20"
        }
    }

    SettingsCard {
        SectionTitle { 
            id: ipcTitle
            text: I18n.tr("IPC Commands")
            icon: "terminal" 
            collapsible: true
            isExpanded: false
            settingKey: "ipcCommandsExpanded"
        }

        Column {
            width: parent.width
            spacing: Theme.spacingM
            visible: ipcTitle.isExpanded

            CopyBox {
                label: I18n.tr("Toggle Expansion")
                text: "dms ipc call hiddenBar toggle"
            }

            CopyBox {
                label: I18n.tr("Expand Area")
                text: "dms ipc call hiddenBar expand"
            }

            CopyBox {
                label: I18n.tr("Collapse Area")
                text: "dms ipc call hiddenBar collapse"
            }

            CopyBox {
                label: I18n.tr("Pin Expansion")
                text: "dms ipc call hiddenBar pin"
            }

            CopyBox {
                label: I18n.tr("Unpin Expansion")
                text: "dms ipc call hiddenBar unpin"
            }
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
                I18n.tr("<b>Hover</b> the icon (or trigger zone) to temporarily expand the hidden area."),
                I18n.tr("<b>Left-click</b> the icon to manually toggle the expanded state."),
                I18n.tr("<b>Right-click</b> the icon while expanded to <b>PIN</b> (prevent auto-collapse).")
            ]
        }
    }

    PluginAbout {
        repoUrl: "https://github.com/hthienloc/dms-hidden-bar"
    }
}
