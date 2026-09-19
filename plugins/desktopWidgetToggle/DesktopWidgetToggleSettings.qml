pragma ComponentBehavior: Bound

import "./dms-common"
import QtQuick
import qs.Common
import qs.Widgets
import qs.Modules.Plugins
import qs.Services

PluginSettings {
    id: rootSettings
    pluginId: "desktopWidgetToggle"

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
        { "text": I18n.tr("Group"), "icon": "settings", "isAction": false },
        { "text": I18n.tr("Widgets"), "icon": "widgets", "isAction": false }
    ]

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
        if (!updated[groupIndex].widgetOverrides) updated[groupIndex].widgetOverrides = {};
        if (!updated[groupIndex].widgetOverrides[widgetId]) updated[groupIndex].widgetOverrides[widgetId] = {};
        updated[groupIndex].widgetOverrides[widgetId][key] = value;
        saveGroups(updated);
    }

    SettingsCard {
        id: groupsSection

        SectionTitle {
            text: I18n.tr("Widget Groups")
            icon: "widgets"
        }

        DankTabBar {
            id: groupTabBar
            width: parent.width
            tabHeight: 48
            model: rootSettings.tabModel
            currentIndex: rootSettings.selectedGroupIndex
            equalWidthTabs: false
            showIcons: true

            onTabClicked: index => {
                rootSettings.selectedGroupIndex = index;
            }

            onActionTriggered: index => {
                rootSettings.addGroup();
            }
        }

        Column {
            id: activeGroupDetails
            width: parent.width
            spacing: Theme.spacingM

            readonly property var currentGroup: (rootSettings.groups && rootSettings.selectedGroupIndex >= 0 && rootSettings.selectedGroupIndex < rootSettings.groups.length) ? rootSettings.groups[rootSettings.selectedGroupIndex] : null

            visible: currentGroup !== null

            Rectangle {
                width: parent.width; height: 32; radius: 16; color: Theme.withAlpha(Theme.surfaceText, 0.05)
                border.color: Theme.withAlpha(Theme.outline, 0.1); border.width: 1

                Row {
                    anchors.fill: parent; anchors.margins: 2

                    MouseArea {
                        id: tabGroupBtn
                        width: parent.width / 2; height: parent.height
                        hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: rootSettings.selectedGroupSubTabIndex = 0

                        Rectangle {
                            anchors.fill: parent; radius: 14
                            color: rootSettings.selectedGroupSubTabIndex === 0 ? Theme.primary : "transparent"

                            Row {
                                anchors.centerIn: parent
                                spacing: Theme.spacingXS

                                DankIcon {
                                    name: "settings"
                                    size: 14
                                    color: rootSettings.selectedGroupSubTabIndex === 0 ? Theme.onPrimary : Theme.surfaceText
                                    opacity: tabGroupBtn.containsMouse ? 0.9 : 0.6
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                StyledText {
                                    text: I18n.tr("Group")
                                    font.bold: true
                                    font.pixelSize: Theme.fontSizeSmall
                                    color: rootSettings.selectedGroupSubTabIndex === 0 ? Theme.onPrimary : Theme.surfaceText
                                    opacity: tabGroupBtn.containsMouse ? 0.9 : 0.6
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }
                        }
                    }

                    MouseArea {
                        id: tabWidgetsBtn
                        width: parent.width / 2; height: parent.height
                        hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: rootSettings.selectedGroupSubTabIndex = 1

                        Rectangle {
                            anchors.fill: parent; radius: 14
                            color: rootSettings.selectedGroupSubTabIndex === 1 ? Theme.primary : "transparent"

                            Row {
                                anchors.centerIn: parent
                                spacing: Theme.spacingXS

                                DankIcon {
                                    name: "widgets"
                                    size: 14
                                    color: rootSettings.selectedGroupSubTabIndex === 1 ? Theme.onPrimary : Theme.surfaceText
                                    opacity: tabWidgetsBtn.containsMouse ? 0.9 : 0.6
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                StyledText {
                                    text: I18n.tr("Widgets")
                                    font.bold: true
                                    font.pixelSize: Theme.fontSizeSmall
                                    color: rootSettings.selectedGroupSubTabIndex === 1 ? Theme.onPrimary : Theme.surfaceText
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
                visible: rootSettings.selectedGroupSubTabIndex === 0

                Row {
                    width: parent.width
                    spacing: Theme.spacingM

                    Column {
                        width: parent.width - deleteBtn.width - 88 - Theme.spacingM * 2
                        spacing: Theme.spacingXS
                        anchors.bottom: parent.bottom

                        StyledText {
                            text: I18n.tr("Group Name")
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceVariantText
                        }

                        DankTextField {
                            width: parent.width
                            height: 40
                            text: activeGroupDetails.currentGroup ? (activeGroupDetails.currentGroup.name || "") : ""
                            placeholderText: I18n.tr("e.g. Work Widgets")
                            onEditingFinished: {
                                if (activeGroupDetails.currentGroup) {
                                    rootSettings.renameGroup(rootSettings.selectedGroupIndex, text.trim());
                                }
                            }
                        }
                    }

                    Column {
                        width: 88
                        spacing: Theme.spacingXS
                        anchors.bottom: parent.bottom

                        StyledText {
                            text: I18n.tr("Icon")
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
                                        rootSettings.changeGroupIcon(rootSettings.selectedGroupIndex, iconName);
                                    }
                                }
                            }

                            DankButton {
                                width: 40
                                height: 40
                                iconName: (activeGroupDetails.currentGroup && activeGroupDetails.currentGroup.showIcon !== false) ? "visibility" : "visibility_off"
                                backgroundColor: (activeGroupDetails.currentGroup && activeGroupDetails.currentGroup.showIcon !== false) ? Theme.primaryContainer : Theme.surfaceContainerHigh
                                textColor: (activeGroupDetails.currentGroup && activeGroupDetails.currentGroup.showIcon !== false) ? Theme.primary : Theme.surfaceVariantText
                                onClicked: {
                                    if (activeGroupDetails.currentGroup) {
                                        const show = activeGroupDetails.currentGroup.showIcon !== false;
                                        rootSettings.updateGroupControl(rootSettings.selectedGroupIndex, "showIcon", !show);
                                    }
                                }
                            }
                        }
                    }

                    DankButton {
                        id: deleteBtn
                        text: I18n.tr("Delete")
                        iconName: "delete"
                        backgroundColor: Theme.error
                        textColor: Theme.onError
                        buttonHeight: 40
                        enabled: rootSettings.groups.length > 1
                        anchors.bottom: parent.bottom
                        onClicked: {
                            rootSettings.deleteGroup(rootSettings.selectedGroupIndex);
                        }
                    }
                }

                Separator {}

                Column {
                    width: parent.width
                    spacing: Theme.spacingXS
                    leftPadding: Theme.spacingM

                    StyledText {
                        text: I18n.tr("Group Behavior")
                        font.pixelSize: Theme.fontSizeSmall
                        font.weight: Font.Medium
                        color: Theme.surfaceText
                    }

                    DankToggle {
                        width: parent.width
                        text: I18n.tr("Show on Overlay")
                        description: I18n.tr("Show widgets in this group in the desktop overlay layer")
                        checked: activeGroupDetails.currentGroup ? (activeGroupDetails.currentGroup.toggleOverlay !== false) : true
                        onToggled: isChecked => {
                            if (activeGroupDetails.currentGroup) {
                                rootSettings.updateGroupControl(rootSettings.selectedGroupIndex, "toggleOverlay", isChecked);
                            }
                        }
                    }

                    DankToggle {
                        visible: CompositorService.isNiri
                        width: parent.width
                        text: I18n.tr("Show on Overview")
                        description: I18n.tr("Show widgets in this group during workspace overview")
                        checked: activeGroupDetails.currentGroup ? !!activeGroupDetails.currentGroup.toggleOverview : false
                        onToggled: isChecked => {
                            if (activeGroupDetails.currentGroup) {
                                rootSettings.updateGroupControl(rootSettings.selectedGroupIndex, "toggleOverview", isChecked);
                            }
                        }
                    }

                    DankToggle {
                        visible: CompositorService.isNiri
                        width: parent.width
                        text: I18n.tr("Show on Overview Only")
                        description: I18n.tr("Show widgets in this group only during workspace overview")
                        checked: activeGroupDetails.currentGroup ? !!activeGroupDetails.currentGroup.toggleOverviewOnly : false
                        onToggled: isChecked => {
                            if (activeGroupDetails.currentGroup) {
                                rootSettings.updateGroupControl(rootSettings.selectedGroupIndex, "toggleOverviewOnly", isChecked);
                            }
                        }
                    }

                    DankToggle {
                        width: parent.width
                        text: I18n.tr("Click Through")
                        description: I18n.tr("Allow clicks to pass through widgets in this group")
                        checked: activeGroupDetails.currentGroup ? !!activeGroupDetails.currentGroup.toggleClickThrough : false
                        onToggled: isChecked => {
                            if (activeGroupDetails.currentGroup) {
                                rootSettings.updateGroupControl(rootSettings.selectedGroupIndex, "toggleClickThrough", isChecked);
                            }
                        }
                    }

                    DankToggle {
                        width: parent.width
                        text: I18n.tr("Hide when inactive")
                        description: I18n.tr("Hide the widgets in this group entirely when the group is inactive.")
                        checked: activeGroupDetails.currentGroup ? !!activeGroupDetails.currentGroup.hideWhenInactive : false
                        onToggled: isChecked => {
                            if (activeGroupDetails.currentGroup) {
                                rootSettings.updateGroupControl(rootSettings.selectedGroupIndex, "hideWhenInactive", isChecked);
                            }
                        }
                    }

                    Item { width: 1; height: Theme.spacingS }

                    SliderSettingPlus {
                        id: autoDismissDuration
                        settingKey: "autoDismissDuration_" + (activeGroupDetails.currentGroup ? activeGroupDetails.currentGroup.id : "none")
                        label: I18n.tr("Auto-dismiss Overlay")
                        description: I18n.tr("Automatically turn off the active overlay group after this duration. Set to 0 to keep active.")
                        defaultValue: 0
                        minimum: 0
                        maximum: 15
                        unit: "s"
                        leftLabel: I18n.tr("Off")
                        rightLabel: "15s"

                        Connections {
                            target: activeGroupDetails
                            function onCurrentGroupChanged() {
                                autoDismissDuration.loadValue();
                            }
                        }
                    }
                }
            }

            // ── Sub-Tab 2: Widget Settings ───────────────────────────────────
            Column {
                width: parent.width
                spacing: Theme.spacingM
                visible: rootSettings.selectedGroupSubTabIndex === 1

                DankToggle {
                    width: parent.width
                    text: I18n.tr("Individual Widget Behavior")
                    description: I18n.tr("Configure behavior for each widget separately instead of using group-wide settings.")
                    checked: activeGroupDetails.currentGroup ? !!activeGroupDetails.currentGroup.overrideIndividual : false
                    onToggled: isChecked => {
                        if (activeGroupDetails.currentGroup) {
                            rootSettings.updateGroupControl(rootSettings.selectedGroupIndex, "overrideIndividual", isChecked);
                        }
                    }
                }

                Separator {}

                Column {
                    width: parent.width
                    spacing: Theme.spacingS
                    leftPadding: Theme.spacingM

                    Item {
                        width: parent.width - Theme.spacingM
                        height: Math.max(selectWidgetsTitle.implicitHeight, selectAllRow.implicitHeight)

                        StyledText {
                            id: selectWidgetsTitle
                            text: I18n.tr("Select Widgets")
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

                            DankButton {
                                text: I18n.tr("Select All")
                                buttonHeight: 32
                                horizontalPadding: Theme.spacingM
                                backgroundColor: Theme.primaryContainer
                                textColor: Theme.primary
                                onClicked: rootSettings.selectAllWidgetsInGroup(rootSettings.selectedGroupIndex, true)
                            }

                            DankButton {
                                text: I18n.tr("Deselect All")
                                buttonHeight: 32
                                horizontalPadding: Theme.spacingM
                                backgroundColor: Theme.surfaceContainerHigh
                                textColor: Theme.surfaceText
                                onClicked: rootSettings.selectAllWidgetsInGroup(rootSettings.selectedGroupIndex, false)
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
                                if (!activeGroupDetails.currentGroup) return false;
                                return (activeGroupDetails.currentGroup.widgets || []).includes(modelData.id);
                            }

                            DankToggle {
                                width: parent.width
                                text: modelData.name || modelData.widgetType
                                description: "ID: " + modelData.id
                                checked: widgetItem.isSelected
                                onToggled: isChecked => {
                                    rootSettings.toggleWidgetInGroup(rootSettings.selectedGroupIndex, modelData.id, isChecked);
                                }
                            }

                            // ── Individual Overrides Selection Bar ───────────
                            Row {
                                id: behaviorBar
                                width: parent.width - Theme.spacingXL - Theme.spacingM
                                x: Theme.spacingXL
                                visible: widgetItem.isSelected && activeGroupDetails.currentGroup.overrideIndividual
                                spacing: Theme.spacingXS

                                readonly property var activeModel: [
                                    { key: "toggleOverlay", label: I18n.tr("Overlay") },
                                    { key: "toggleOverview", label: I18n.tr("Overview"), visible: CompositorService.isNiri },
                                    { key: "toggleOverviewOnly", label: I18n.tr("Overview Only"), visible: CompositorService.isNiri },
                                    { key: "toggleClickThrough", label: I18n.tr("Click through") },
                                    { key: "hideWhenInactive", label: I18n.tr("Hide inactive") }
                                ].filter(m => m.visible !== false)

                                property var overrides: (activeGroupDetails.currentGroup.widgetOverrides && activeGroupDetails.currentGroup.widgetOverrides[widgetItem.modelData.id]) || {}

                                Repeater {
                                    model: behaviorBar.activeModel

                                    delegate: StyledRect {
                                        required property var modelData
                                        visible: modelData.visible !== false
                                        width: (behaviorBar.width - (behaviorBar.spacing * (behaviorBar.activeModel.length - 1))) / behaviorBar.activeModel.length
                                        height: 32
                                        radius: 4
                                        
                                        readonly property bool active: {
                                            if (modelData.key === "toggleOverlay") return behaviorBar.overrides.toggleOverlay !== false;
                                            return !!behaviorBar.overrides[modelData.key];
                                        }

                                        color: active ? Theme.withAlpha(Theme.primary, 0.15) : Theme.surfaceContainerHigh
                                        border.color: active ? Theme.primary : "transparent"
                                        border.width: 1

                                        StyledText {
                                            anchors.centerIn: parent
                                            text: modelData.label
                                            font.pixelSize: 10
                                            color: parent.active ? Theme.primary : Theme.surfaceVariantText
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                const currentVal = (modelData.key === "toggleOverlay") ? (behaviorBar.overrides.toggleOverlay !== false) : !!behaviorBar.overrides[modelData.key];
                                                rootSettings.updateWidgetOverride(rootSettings.selectedGroupIndex, widgetItem.modelData.id, modelData.key, !currentVal);
                                            }
                                        }
                                    }
                                }
                            }
                            
                            Item { width: 1; height: Theme.spacingXS; visible: widgetItem.isSelected && activeGroupDetails.currentGroup.overrideIndividual }
                        }
                    }

                    StyledText {
                        text: I18n.tr("No desktop widgets found.")
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.surfaceVariantText
                        visible: (SettingsData.desktopWidgetInstances || []).length === 0
                    }
                }
            }

            Separator {}

            Column {
                width: parent.width
                spacing: Theme.spacingXS
                leftPadding: Theme.spacingM

                StyledText {
                    text: I18n.tr("IPC Command")
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

    SettingsCard {
        id: behaviorSection
        SectionTitle {
            id: behaviorTitle
            text: I18n.tr("Behavior")
            icon: "settings"
            showReset: conflictModeSetting.isDirty || displayModeSetting.isDirty
            onResetClicked: {
                conflictModeSetting.resetToDefault();
                displayModeSetting.resetToDefault();
            }
        }

        ButtonGroupSettingPlus {
            id: displayModeSetting
            settingKey: "displayMode"
            label: I18n.tr("Bar Display Mode")
            description: I18n.tr("Choose how widget group toggles are displayed on the status bar.")
            defaultValue: "all"
            options: [
                { "value": "all", "label": I18n.tr("Show All Groups") },
                { "value": "minimal", "label": I18n.tr("Minimal Popout") }
            ]
        }

        Separator {}

        SelectionSettingPlus {
            id: conflictModeSetting
            settingKey: "conflictMode"
            label: I18n.tr("Toggle Mode")
            description: I18n.tr("Choose how widget groups can be toggled simultaneously.")
            defaultValue: "single"
            options: [
                { "value": "single", "label": I18n.tr("Single Active Group") },
                { "value": "overlap", "label": I18n.tr("Block Overlap") },
                { "value": "all", "label": I18n.tr("Allow All") }
            ]
        }

        StyledText {
            width: parent.width
            text: {
                switch (conflictModeSetting.value) {
                    case "single": return I18n.tr("Only one group can be active at a time.");
                    case "overlap": return I18n.tr("Allow multiple groups if they don't share widgets.");
                    case "all": return I18n.tr("No restrictions, multiple groups can be active.");
                    default: return "";
                }
            }
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.surfaceVariantText
            wrapMode: Text.Wrap
            leftPadding: Theme.spacingM
            rightPadding: Theme.spacingM
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
                I18n.tr("<b>Click</b> a group button on the status bar to show its widgets on top of all windows (overlay)."),
                I18n.tr("<b>Click it again</b> to return the widgets to the desktop background layer."),
                I18n.tr("Depending on the Toggle Mode setting, you can activate one or multiple groups concurrently.")
            ]
        }
    }

    PluginAbout {
        repoUrl: "https://github.com/hthienloc/dms-desktop-widget-toggle"
    }
}
