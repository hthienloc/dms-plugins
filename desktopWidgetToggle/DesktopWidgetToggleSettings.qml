import "./shared"
import QtQuick
import qs.Common
import qs.DCommon.Widgets
import qs.Modules.Plugins
import qs.Modules.Settings.Widgets
import qs.Services

PluginSettings {
    id: root
    pluginId: "desktopWidgetToggle"

    readonly property string defaultDisplayMode: "all"
    readonly property string defaultConflictMode: "single"
    readonly property int defaultAutoDismissDuration: 0

    property string displayMode: defaultDisplayMode
    property string conflictMode: defaultConflictMode
    property int currentAutoDismissDuration: defaultAutoDismissDuration

    property var groups: {
        settingChanged;
        return loadValue("groups", [
            { "id": "g1", "name": "Group 1", "icon": "widgets", "widgets": [] }
        ]);
    }

    property int selectedGroupIndex: 0
    property int selectedGroupSubTabIndex: 0

    property var tabModel: {
        let list = [];
        for (let i = 0; i < groups.length; i++) {
            list.push({
                "text": groups[i].name || "Group " + (i + 1),
                "icon": groups[i].icon || "widgets",
                "isAction": false
            });
        }
        list.push({
            "text": "",
            "icon": "add",
            "isAction": true
        });
        return list;
    }

    property var subTabModel: [
        { "text": I18n.trFor("desktopWidgetToggle", "Group"), "icon": "settings", "isAction": false },
        { "text": I18n.trFor("desktopWidgetToggle", "Widgets"), "icon": "widgets", "isAction": false }
    ]

    function loadSettings() {
        if (!pluginService)
            return;
        displayMode = loadValue("displayMode", defaultDisplayMode);
        conflictMode = loadValue("conflictMode", defaultConflictMode);
        usageSection.expanded = loadValue("usageGuideExpanded", true);
        loadCurrentGroupAutoDismiss();
    }

    function loadCurrentGroupAutoDismiss() {
        if (!pluginService || !activeGroupDetails.currentGroup)
            return;
        currentAutoDismissDuration = loadValue("autoDismissDuration_" + activeGroupDetails.currentGroup.id, defaultAutoDismissDuration);
    }

    Component.onCompleted: loadSettings()
    onPluginServiceChanged: loadSettings()

    function saveGroups(newGroups) {
        saveValue("groups", newGroups);
    }

    function renameGroup(index, newName) {
        let updated = JSON.parse(JSON.stringify(groups));
        updated[index].name = newName;
        saveGroups(updated);
    }

    function changeGroupIcon(index, newIcon) {
        let updated = JSON.parse(JSON.stringify(groups));
        updated[index].icon = newIcon;
        saveGroups(updated);
    }

    function updateGroupControl(index, key, value) {
        let updated = JSON.parse(JSON.stringify(groups));
        updated[index][key] = value;
        saveGroups(updated);
    }

    function addGroup() {
        let updated = JSON.parse(JSON.stringify(groups));
        const newId = "g_" + Date.now() + "_" + Math.random().toString(36).substr(2, 9);
        updated.push({
            "id": newId,
            "name": "New Group",
            "icon": "widgets",
            "widgets": [],
            "overrideIndividual": false,
            "widgetOverrides": {}
        });
        saveGroups(updated);
        selectedGroupIndex = updated.length - 1;
    }

    function deleteGroup(index) {
        if (groups.length <= 1)
            return;
        let updated = JSON.parse(JSON.stringify(groups));
        const deletedId = updated[index].id;

        let activeIds = loadValue("activeGroupIds", []);
        if (activeIds.includes(deletedId)) {
            activeIds = activeIds.filter(id => id !== deletedId);
            saveValue("activeGroupIds", activeIds);
            saveValue("activeGroupId", activeIds.length > 0 ? activeIds[0] : "");
        }

        updated.splice(index, 1);
        saveGroups(updated);

        if (selectedGroupIndex >= updated.length) {
            selectedGroupIndex = updated.length - 1;
        }
    }

    function toggleWidgetInGroup(groupIndex, widgetId, isChecked) {
        let updated = JSON.parse(JSON.stringify(groups));
        let widgetList = updated[groupIndex].widgets || [];
        if (isChecked) {
            if (!widgetList.includes(widgetId)) {
                widgetList.push(widgetId);
            }
        } else {
            widgetList = widgetList.filter(id => id !== widgetId);
        }
        updated[groupIndex].widgets = widgetList;
        saveGroups(updated);
    }

    function selectAllWidgetsInGroup(groupIndex, selectAll) {
        let updated = JSON.parse(JSON.stringify(groups));
        if (selectAll) {
            let allIds = (SettingsData.desktopWidgetInstances || []).map(w => w.id);
            updated[groupIndex].widgets = allIds;
        } else {
            updated[groupIndex].widgets = [];
        }
        saveGroups(updated);
    }

    function updateWidgetOverride(groupIndex, widgetId, key, value) {
        let updated = JSON.parse(JSON.stringify(groups));
        if (!updated[groupIndex].widgetOverrides)
            updated[groupIndex].widgetOverrides = {};
        if (!updated[groupIndex].widgetOverrides[widgetId])
            updated[groupIndex].widgetOverrides[widgetId] = {};
        updated[groupIndex].widgetOverrides[widgetId][key] = value;
        saveGroups(updated);
    }

    Column {
        width: parent ? parent.width : 0
        spacing: 0

        SettingsSectionLabel {
            width: parent.width
            text: I18n.trFor("desktopWidgetToggle", "Widget Groups")
        }

        SettingsGroup {
            width: parent.width
            slotColor: SettingsMetrics.controlColor

            Column {
                width: parent.width
                spacing: Theme.spacingM

                DTabBar {
                    id: groupTabBar
                    width: parent.width
                    tabHeight: 48
                    model: root.tabModel
                    currentIndex: root.selectedGroupIndex
                    equalWidthTabs: false
                    showIcons: true

                    onTabClicked: index => {
                        root.selectedGroupIndex = index;
                    }

                    onActionTriggered: index => {
                        root.addGroup();
                    }
                }

                Column {
                    id: activeGroupDetails
                    width: parent.width
                    spacing: Theme.spacingM

                    readonly property var currentGroup: (root.groups && root.selectedGroupIndex >= 0 && root.selectedGroupIndex < root.groups.length) ? root.groups[root.selectedGroupIndex] : null

                    visible: currentGroup !== null
                    onCurrentGroupChanged: root.loadCurrentGroupAutoDismiss()

                    Rectangle {
                        width: parent.width
                        height: Theme.buttonHeightXS
                        radius: height / 2
                        color: Theme.withAlpha(Theme.surfaceText, 0.05)
                        border.color: Theme.withAlpha(Theme.outline, 0.1)
                        border.width: 1

                        Row {
                            anchors.fill: parent
                            anchors.margins: 2

                            MouseArea {
                                id: tabGroupBtn
                                width: parent.width / 2
                                height: parent.height
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.selectedGroupSubTabIndex = 0

                                Rectangle {
                                    anchors.fill: parent
                                    radius: height / 2
                                    color: root.selectedGroupSubTabIndex === 0 ? Theme.primary : "transparent"

                                    Row {
                                        anchors.centerIn: parent
                                        spacing: Theme.spacingXS

                                        DIcon {
                                            name: "settings"
                                            size: Theme.iconSizeSmall
                                            color: root.selectedGroupSubTabIndex === 0 ? Theme.onPrimary : Theme.surfaceText
                                            opacity: tabGroupBtn.containsMouse ? 0.9 : 0.6
                                            anchors.verticalCenter: parent.verticalCenter
                                        }

                                        StyledText {
                                            text: I18n.trFor("desktopWidgetToggle", "Group")
                                            font.bold: true
                                            font.pixelSize: Theme.fontSizeSmall
                                            color: root.selectedGroupSubTabIndex === 0 ? Theme.onPrimary : Theme.surfaceText
                                            opacity: tabGroupBtn.containsMouse ? 0.9 : 0.6
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                    }
                                }
                            }

                            MouseArea {
                                id: tabWidgetsBtn
                                width: parent.width / 2
                                height: parent.height
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.selectedGroupSubTabIndex = 1

                                Rectangle {
                                    anchors.fill: parent
                                    radius: height / 2
                                    color: root.selectedGroupSubTabIndex === 1 ? Theme.primary : "transparent"

                                    Row {
                                        anchors.centerIn: parent
                                        spacing: Theme.spacingXS

                                        DIcon {
                                            name: "widgets"
                                            size: Theme.iconSizeSmall
                                            color: root.selectedGroupSubTabIndex === 1 ? Theme.onPrimary : Theme.surfaceText
                                            opacity: tabWidgetsBtn.containsMouse ? 0.9 : 0.6
                                            anchors.verticalCenter: parent.verticalCenter
                                        }

                                        StyledText {
                                            text: I18n.trFor("desktopWidgetToggle", "Widgets")
                                            font.bold: true
                                            font.pixelSize: Theme.fontSizeSmall
                                            color: root.selectedGroupSubTabIndex === 1 ? Theme.onPrimary : Theme.surfaceText
                                            opacity: tabWidgetsBtn.containsMouse ? 0.9 : 0.6
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // ── Sub-Tab 1: Group Settings ────────────────────────────────────
                    Column {
                        width: parent.width
                        spacing: Theme.spacingM
                        visible: root.selectedGroupSubTabIndex === 0

                        Row {
                            width: parent.width
                            spacing: Theme.spacingM

                            Column {
                                width: parent.width - deleteBtn.width - 88 - Theme.spacingM * 2
                                spacing: Theme.spacingXS
                                anchors.bottom: parent.bottom

                                StyledText {
                                    text: I18n.trFor("desktopWidgetToggle", "Group Name")
                                    font.pixelSize: Theme.fontSizeSmall
                                    color: Theme.surfaceVariantText
                                }

                                DTextField {
                                    width: parent.width
                                    height: 40
                                    text: activeGroupDetails.currentGroup ? (activeGroupDetails.currentGroup.name || "") : ""
                                    placeholderText: I18n.trFor("desktopWidgetToggle", "e.g. Work Widgets")
                                    onEditingFinished: {
                                        if (activeGroupDetails.currentGroup) {
                                            root.renameGroup(root.selectedGroupIndex, text.trim());
                                        }
                                    }
                                }
                            }

                            Column {
                                width: 88
                                spacing: Theme.spacingXS
                                anchors.bottom: parent.bottom

                                StyledText {
                                    text: I18n.trFor("desktopWidgetToggle", "Icon")
                                    font.pixelSize: Theme.fontSizeSmall
                                    color: Theme.surfaceVariantText
                                }

                                Row {
                                    width: parent.width
                                    spacing: Theme.spacingS

                                    DankIconPickerPlus {
                                        width: 40
                                        height: 40
                                        showText: false
                                        enabled: activeGroupDetails.currentGroup ? (activeGroupDetails.currentGroup.showIcon !== false) : true
                                        currentIcon: activeGroupDetails.currentGroup ? (activeGroupDetails.currentGroup.icon || "widgets") : "widgets"
                                        onIconSelected: (iconName, type) => {
                                            if (activeGroupDetails.currentGroup) {
                                                root.changeGroupIcon(root.selectedGroupIndex, iconName);
                                            }
                                        }
                                    }

                                    DButton {
                                        width: 40
                                        height: 40
                                        iconName: (activeGroupDetails.currentGroup && activeGroupDetails.currentGroup.showIcon !== false) ? "visibility" : "visibility_off"
                                        backgroundColor: (activeGroupDetails.currentGroup && activeGroupDetails.currentGroup.showIcon !== false) ? Theme.primaryContainer : Theme.surfaceContainerHigh
                                        textColor: (activeGroupDetails.currentGroup && activeGroupDetails.currentGroup.showIcon !== false) ? Theme.primary : Theme.surfaceVariantText
                                        onClicked: {
                                            if (activeGroupDetails.currentGroup) {
                                                const show = activeGroupDetails.currentGroup.showIcon !== false;
                                                root.updateGroupControl(root.selectedGroupIndex, "showIcon", !show);
                                            }
                                        }
                                    }
                                }
                            }

                            DButton {
                                id: deleteBtn
                                text: I18n.trFor("desktopWidgetToggle", "Delete")
                                iconName: "delete"
                                backgroundColor: Theme.error
                                textColor: Theme.onError
                                buttonHeight: 40
                                enabled: root.groups.length > 1
                                anchors.bottom: parent.bottom
                                onClicked: {
                                    root.deleteGroup(root.selectedGroupIndex);
                                }
                            }
                        }

                        Rectangle {
                            width: parent.width
                            height: 1
                            color: Theme.outline
                            opacity: 0.15
                        }

                        Column {
                            width: parent.width
                            spacing: Theme.spacingXS

                            StyledText {
                                text: I18n.trFor("desktopWidgetToggle", "Group Behavior")
                                font.pixelSize: Theme.fontSizeSmall
                                font.weight: Font.Medium
                                color: Theme.surfaceText
                            }

                            DToggle {
                                width: parent.width
                                text: I18n.trFor("desktopWidgetToggle", "Show on Overlay")
                                description: I18n.trFor("desktopWidgetToggle", "Show widgets in this group in the desktop overlay layer")
                                checked: activeGroupDetails.currentGroup ? (activeGroupDetails.currentGroup.toggleOverlay !== false) : true
                                onToggled: isChecked => {
                                    if (activeGroupDetails.currentGroup) {
                                        root.updateGroupControl(root.selectedGroupIndex, "toggleOverlay", isChecked);
                                    }
                                }
                            }

                            DToggle {
                                visible: CompositorService.isNiri
                                width: parent.width
                                text: I18n.trFor("desktopWidgetToggle", "Show on Overview")
                                description: I18n.trFor("desktopWidgetToggle", "Show widgets in this group during workspace overview")
                                checked: activeGroupDetails.currentGroup ? !!activeGroupDetails.currentGroup.toggleOverview : false
                                onToggled: isChecked => {
                                    if (activeGroupDetails.currentGroup) {
                                        root.updateGroupControl(root.selectedGroupIndex, "toggleOverview", isChecked);
                                    }
                                }
                            }

                            DToggle {
                                visible: CompositorService.isNiri
                                width: parent.width
                                text: I18n.trFor("desktopWidgetToggle", "Show on Overview Only")
                                description: I18n.trFor("desktopWidgetToggle", "Show widgets in this group only during workspace overview")
                                checked: activeGroupDetails.currentGroup ? !!activeGroupDetails.currentGroup.toggleOverviewOnly : false
                                onToggled: isChecked => {
                                    if (activeGroupDetails.currentGroup) {
                                        root.updateGroupControl(root.selectedGroupIndex, "toggleOverviewOnly", isChecked);
                                    }
                                }
                            }

                            DToggle {
                                width: parent.width
                                text: I18n.trFor("desktopWidgetToggle", "Click Through")
                                description: I18n.trFor("desktopWidgetToggle", "Allow clicks to pass through widgets in this group")
                                checked: activeGroupDetails.currentGroup ? !!activeGroupDetails.currentGroup.toggleClickThrough : false
                                onToggled: isChecked => {
                                    if (activeGroupDetails.currentGroup) {
                                        root.updateGroupControl(root.selectedGroupIndex, "toggleClickThrough", isChecked);
                                    }
                                }
                            }

                            DToggle {
                                width: parent.width
                                text: I18n.trFor("desktopWidgetToggle", "Hide when inactive")
                                description: I18n.trFor("desktopWidgetToggle", "Hide the widgets in this group entirely when the group is inactive.")
                                checked: activeGroupDetails.currentGroup ? !!activeGroupDetails.currentGroup.hideWhenInactive : false
                                onToggled: isChecked => {
                                    if (activeGroupDetails.currentGroup) {
                                        root.updateGroupControl(root.selectedGroupIndex, "hideWhenInactive", isChecked);
                                    }
                                }
                            }

                            SettingsSliderRow {
                                text: I18n.trFor("desktopWidgetToggle", "Auto-dismiss Overlay")
                                description: I18n.trFor("desktopWidgetToggle", "Automatically turn off the active overlay group after this duration. Set to 0 to keep active.")
                                minimum: 0
                                maximum: 15
                                step: 1
                                unit: "s"
                                value: root.currentAutoDismissDuration
                                modified: root.currentAutoDismissDuration !== root.defaultAutoDismissDuration
                                resetByKeys: false
                                onResetRequested: {
                                    root.currentAutoDismissDuration = root.defaultAutoDismissDuration;
                                    if (activeGroupDetails.currentGroup) {
                                        root.saveValue("autoDismissDuration_" + activeGroupDetails.currentGroup.id, root.defaultAutoDismissDuration);
                                    }
                                }
                                onSliderDragFinished: finalValue => {
                                    root.currentAutoDismissDuration = finalValue;
                                    if (activeGroupDetails.currentGroup) {
                                        root.saveValue("autoDismissDuration_" + activeGroupDetails.currentGroup.id, finalValue);
                                    }
                                }
                            }
                        }
                    }

                    // ── Sub-Tab 2: Widget Settings ───────────────────────────────────
                    Column {
                        width: parent.width
                        spacing: Theme.spacingM
                        visible: root.selectedGroupSubTabIndex === 1

                        DToggle {
                            width: parent.width
                            text: I18n.trFor("desktopWidgetToggle", "Individual Widget Behavior")
                            description: I18n.trFor("desktopWidgetToggle", "Configure behavior for each widget separately instead of using group-wide settings.")
                            checked: activeGroupDetails.currentGroup ? !!activeGroupDetails.currentGroup.overrideIndividual : false
                            onToggled: isChecked => {
                                if (activeGroupDetails.currentGroup) {
                                    root.updateGroupControl(root.selectedGroupIndex, "overrideIndividual", isChecked);
                                }
                            }
                        }

                        Rectangle {
                            width: parent.width
                            height: 1
                            color: Theme.outline
                            opacity: 0.15
                        }

                        Column {
                            width: parent.width
                            spacing: Theme.spacingS

                            Item {
                                width: parent.width
                                height: Math.max(selectWidgetsTitle.implicitHeight, selectAllRow.implicitHeight)

                                StyledText {
                                    id: selectWidgetsTitle
                                    text: I18n.trFor("desktopWidgetToggle", "Select Widgets")
                                    font.pixelSize: Theme.fontSizeSmall
                                    font.weight: Font.Medium
                                    color: Theme.surfaceText
                                    anchors.left: parent.left
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Row {
                                    id: selectAllRow
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: Theme.spacingS
                                    visible: (SettingsData.desktopWidgetInstances || []).length > 0

                                    DButton {
                                        text: I18n.trFor("desktopWidgetToggle", "Select All")
                                        buttonHeight: 32
                                        horizontalPadding: Theme.spacingM
                                        backgroundColor: Theme.primaryContainer
                                        textColor: Theme.primary
                                        onClicked: root.selectAllWidgetsInGroup(root.selectedGroupIndex, true)
                                    }

                                    DButton {
                                        text: I18n.trFor("desktopWidgetToggle", "Deselect All")
                                        buttonHeight: 32
                                        horizontalPadding: Theme.spacingM
                                        backgroundColor: Theme.surfaceContainerHigh
                                        textColor: Theme.surfaceText
                                        onClicked: root.selectAllWidgetsInGroup(root.selectedGroupIndex, false)
                                    }
                                }
                            }

                            Repeater {
                                model: SettingsData.desktopWidgetInstances || []

                                delegate: Column {
                                    id: widgetItem
                                    required property var modelData
                                    width: parent.width
                                    spacing: Theme.spacingS

                                    readonly property bool isSelected: {
                                        if (!activeGroupDetails.currentGroup)
                                            return false;
                                        return (activeGroupDetails.currentGroup.widgets || []).includes(modelData.id);
                                    }

                                    DToggle {
                                        width: parent.width
                                        text: widgetItem.modelData.name || widgetItem.modelData.widgetType
                                        description: "ID: " + widgetItem.modelData.id
                                        checked: widgetItem.isSelected
                                        onToggled: isChecked => {
                                            root.toggleWidgetInGroup(root.selectedGroupIndex, widgetItem.modelData.id, isChecked);
                                        }
                                    }

                                    // ── Individual Overrides Selection Bar ───────────
                                    Row {
                                        id: behaviorBar
                                        width: parent.width - Theme.spacingXL - Theme.spacingM
                                        x: Theme.spacingXL
                                        visible: widgetItem.isSelected && activeGroupDetails.currentGroup && !!activeGroupDetails.currentGroup.overrideIndividual
                                        spacing: Theme.spacingXS

                                        readonly property var activeModel: [
                                            { key: "toggleOverlay", label: I18n.trFor("desktopWidgetToggle", "Overlay") },
                                            { key: "toggleOverview", label: I18n.trFor("desktopWidgetToggle", "Overview"), visible: CompositorService.isNiri },
                                            { key: "toggleOverviewOnly", label: I18n.trFor("desktopWidgetToggle", "Overview Only"), visible: CompositorService.isNiri },
                                            { key: "toggleClickThrough", label: I18n.trFor("desktopWidgetToggle", "Click through") },
                                            { key: "hideWhenInactive", label: I18n.trFor("desktopWidgetToggle", "Hide inactive") }
                                        ].filter(m => m.visible !== false)

                                        property var overrides: (activeGroupDetails.currentGroup && activeGroupDetails.currentGroup.widgetOverrides && activeGroupDetails.currentGroup.widgetOverrides[widgetItem.modelData.id]) || {}

                                        Repeater {
                                            model: behaviorBar.activeModel

                                            delegate: StyledRect {
                                                id: overrideBtn
                                                required property var modelData
                                                visible: modelData.visible !== false
                                                width: (behaviorBar.width - (behaviorBar.spacing * (behaviorBar.activeModel.length - 1))) / behaviorBar.activeModel.length
                                                height: Theme.buttonHeightXS
                                                radius: Theme.cornerRadiusXS

                                                readonly property bool active: {
                                                    if (modelData.key === "toggleOverlay")
                                                        return behaviorBar.overrides.toggleOverlay !== false;
                                                    return !!behaviorBar.overrides[modelData.key];
                                                }

                                                color: active ? Theme.withAlpha(Theme.primary, 0.15) : Theme.surfaceContainerHigh
                                                border.color: active ? Theme.primary : "transparent"
                                                border.width: 1

                                                StyledText {
                                                    anchors.centerIn: parent
                                                    text: overrideBtn.modelData.label
                                                    font.pixelSize: Math.max(9, Math.round(Theme.fontSizeSmall * 0.8))
                                                    color: overrideBtn.active ? Theme.primary : Theme.surfaceVariantText
                                                }

                                                MouseArea {
                                                    anchors.fill: parent
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: {
                                                        const currentVal = (overrideBtn.modelData.key === "toggleOverlay") ? (behaviorBar.overrides.toggleOverlay !== false) : !!behaviorBar.overrides[overrideBtn.modelData.key];
                                                        root.updateWidgetOverride(root.selectedGroupIndex, widgetItem.modelData.id, overrideBtn.modelData.key, !currentVal);
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    Item {
                                        width: 1
                                        height: Theme.spacingXS
                                        visible: widgetItem.isSelected && activeGroupDetails.currentGroup && !!activeGroupDetails.currentGroup.overrideIndividual
                                    }
                                }
                            }

                            StyledText {
                                text: I18n.trFor("desktopWidgetToggle", "No desktop widgets found.")
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.surfaceVariantText
                                visible: (SettingsData.desktopWidgetInstances || []).length === 0
                            }
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: 1
                        color: Theme.outline
                        opacity: 0.15
                    }

                    Column {
                        width: parent.width
                        spacing: Theme.spacingXS

                        StyledText {
                            text: I18n.trFor("desktopWidgetToggle", "IPC Command")
                            font.pixelSize: Theme.fontSizeSmall
                            font.weight: Font.Medium
                            color: Theme.surfaceText
                        }

                        CopyBox {
                            width: parent.width
                            text: "dms ipc call desktopWidgetToggle toggle \"" + (activeGroupDetails.currentGroup ? activeGroupDetails.currentGroup.id : "") + "\""
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
            text: I18n.trFor("desktopWidgetToggle", "Behavior")
        }

        SettingsGroup {
            width: parent.width
            slotColor: SettingsMetrics.controlColor

            SettingsButtonGroupRow {
                text: I18n.trFor("desktopWidgetToggle", "Bar Display Mode")
                description: I18n.trFor("desktopWidgetToggle", "Choose how widget group toggles are displayed on the status bar.")
                model: [
                    I18n.trFor("desktopWidgetToggle", "Show All Groups"),
                    I18n.trFor("desktopWidgetToggle", "Minimal Popout")
                ]
                values: ["all", "minimal"]
                value: root.displayMode
                modified: root.displayMode !== root.defaultDisplayMode
                resetByKeys: false
                onResetRequested: {
                    root.displayMode = root.defaultDisplayMode;
                    root.saveValue("displayMode", root.defaultDisplayMode);
                }
                onValueSelected: val => {
                    root.displayMode = val;
                    root.saveValue("displayMode", val);
                }
            }

            SettingsDropdownRow {
                text: I18n.trFor("desktopWidgetToggle", "Toggle Mode")
                description: I18n.trFor("desktopWidgetToggle", "Choose how widget groups can be toggled simultaneously.")
                options: [
                    I18n.trFor("desktopWidgetToggle", "Single Active Group"),
                    I18n.trFor("desktopWidgetToggle", "Block Overlap"),
                    I18n.trFor("desktopWidgetToggle", "Allow All")
                ]
                optionValues: ["single", "overlap", "all"]
                currentValue: root.conflictMode
                modified: root.conflictMode !== root.defaultConflictMode
                resetByKeys: false
                onResetRequested: {
                    root.conflictMode = root.defaultConflictMode;
                    root.saveValue("conflictMode", root.defaultConflictMode);
                }
                onValueChanged: val => {
                    root.conflictMode = val;
                    root.saveValue("conflictMode", val);
                }
            }

            SettingsNoteRow {
                noteIconName: "info"
                tint: Theme.primary
                tintBackground: Theme.withAlpha(Theme.primary, 0.08)
                text: {
                    switch (root.conflictMode) {
                    case "single":
                        return I18n.trFor("desktopWidgetToggle", "Only one group can be active at a time.");
                    case "overlap":
                        return I18n.trFor("desktopWidgetToggle", "Allow multiple groups if they don't share widgets.");
                    case "all":
                        return I18n.trFor("desktopWidgetToggle", "No restrictions, multiple groups can be active.");
                    default:
                        return "";
                    }
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
            text: I18n.trFor("desktopWidgetToggle", "Usage Guide")
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
                        I18n.trFor("desktopWidgetToggle", "<b>Click</b> a group button on the status bar to show its widgets on top of all windows (overlay)."),
                        I18n.trFor("desktopWidgetToggle", "<b>Click it again</b> to return the widgets to the desktop background layer."),
                        I18n.trFor("desktopWidgetToggle", "Depending on the Toggle Mode setting, you can activate one or multiple groups concurrently.")
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
