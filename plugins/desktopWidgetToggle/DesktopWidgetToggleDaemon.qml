import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Widgets
import qs.Modules.Plugins
import qs.Services

PluginComponent {
    id: rootDaemon

    pluginId: "desktopWidgetToggle"
    pluginService: PluginService

    // Core properties
    property var groups: pluginData.groups ?? [
        { "id": "g1", "name": "Group 1", "icon": "widgets", "widgets": [], "autoDismissDuration": 0 }
    ]
    property string conflictMode: pluginData.conflictMode ?? "single"
    property var activeGroupIds: pluginData.activeGroupIds ?? []

    property var _groupTimers: ({})

    IpcHandler {
        target: "desktopWidgetToggle"

        function toggleGroup(groupId: string): string {
            if (!groupId) return "ERROR: No group ID provided";
            const group = rootDaemon.groups.find(g => g.id === groupId || (g.name && g.name.toLowerCase() === groupId.toLowerCase()));
            if (!group) return `ERROR: Group not found: ${groupId}`;
            rootDaemon.toggleGroup(group.id);
            const isActive = rootDaemon.activeGroupIds.includes(group.id);
            return isActive ? `GROUP_ACTIVATED: ${group.name}` : `GROUP_DEACTIVATED: ${group.name}`;
        }

        function toggle(groupId: string): string {
            return toggleGroup(groupId);
        }

        function activate(groupId: string): string {
            if (!groupId) return "ERROR: No group ID provided";
            const group = rootDaemon.groups.find(g => g.id === groupId || (g.name && g.name.toLowerCase() === groupId.toLowerCase()));
            if (!group) return `ERROR: Group not found: ${groupId}`;
            if (!rootDaemon.activeGroupIds.includes(group.id)) {
                rootDaemon.toggleGroup(group.id);
            }
            return `GROUP_ACTIVATED: ${group.name}`;
        }

        function deactivate(groupId: string): string {
            if (!groupId) return "ERROR: No group ID provided";
            const group = rootDaemon.groups.find(g => g.id === groupId || (g.name && g.name.toLowerCase() === groupId.toLowerCase()));
            if (!group) return `ERROR: Group not found: ${groupId}`;
            if (rootDaemon.activeGroupIds.includes(group.id)) {
                rootDaemon.toggleGroup(group.id);
            }
            return `GROUP_DEACTIVATED: ${group.name}`;
        }

        function list(): string {
            return rootDaemon.groups.map(g => `${g.id} : ${g.name} (${rootDaemon.activeGroupIds.includes(g.id) ? "active" : "inactive"})`).join("\n");
        }
    }

    onGroupsChanged: updateAllWidgetsState(activeGroupIds)
    onActiveGroupIdsChanged: updateAllWidgetsState(activeGroupIds)

    Component.onCompleted: {
        updateAllWidgetsState(activeGroupIds)

        // Re-sync timers for already active groups if they have durations
        for (let id of activeGroupIds) {
            let duration = pluginData["autoDismissDuration_" + id] || 0;
            if (duration > 0) {
                startGroupTimer(id, duration);
            }
        }

        if (pluginService && pluginId) {
            const newInstances = Object.assign({}, pluginService.pluginInstances);
            newInstances[pluginId] = rootDaemon;
            pluginService.pluginInstances = newInstances;
        }
    }

    Component.onDestruction: {
        // Stop all timers
        const keys = Object.keys(_groupTimers);
        for (let k of keys) {
            if (_groupTimers[k]) _groupTimers[k].stop();
        }

        if (pluginService && pluginId) {
            if (pluginService.pluginInstances[pluginId] === rootDaemon) {
                const newInstances = Object.assign({}, pluginService.pluginInstances);
                delete newInstances[pluginId];
                pluginService.pluginInstances = newInstances;
            }
        }
    }

    function startGroupTimer(groupId, seconds) {
        if (_groupTimers[groupId]) {
            _groupTimers[groupId].stop();
            _groupTimers[groupId].destroy();
        }

        const timer = Qt.createQmlObject("import QtQuick; Timer { interval: " + (seconds * 1000) + "; repeat: false; running: true }", rootDaemon, "dismissTimer_" + groupId);
        timer.triggered.connect(function() {
            deactivateGroup(groupId);
            timer.destroy();
            delete _groupTimers[groupId];
        });
        _groupTimers[groupId] = timer;
    }

    function stopGroupTimer(groupId) {
        if (_groupTimers[groupId]) {
            _groupTimers[groupId].stop();
            _groupTimers[groupId].destroy();
            delete _groupTimers[groupId];
        }
    }

    function deactivateGroup(groupId) {
        if (activeGroupIds.includes(groupId)) {
            toggleGroup(groupId);
        }
    }

    function toggleGroup(groupId) {
        let currentActive = Array.isArray(activeGroupIds) ? [...activeGroupIds] : [];
        const isCurrentlyActive = currentActive.includes(groupId);
        const group = groups.find(g => g.id === groupId);

        if (conflictMode === "single") {
            // Stop all existing timers when switching in single mode
            for (let id of currentActive) stopGroupTimer(id);

            if (isCurrentlyActive) {
                currentActive = [];
            } else {
                currentActive = [groupId];
                let duration = pluginData["autoDismissDuration_" + groupId] || 0;
                if (duration > 0) {
                    startGroupTimer(groupId, duration);
                }
            }
        } else if (conflictMode === "overlap") {
            if (isCurrentlyActive) {
                currentActive = currentActive.filter(id => id !== groupId);
                stopGroupTimer(groupId);
            } else {
                if (!hasOverlapWithActive(groupId, currentActive)) {
                    currentActive.push(groupId);
                    let duration = pluginData["autoDismissDuration_" + groupId] || 0;
                    if (duration > 0) {
                        startGroupTimer(groupId, duration);
                    }
                }
            }
        } else {
            if (isCurrentlyActive) {
                currentActive = currentActive.filter(id => id !== groupId);
                stopGroupTimer(groupId);
            } else {
                currentActive.push(groupId);
                let duration = pluginData["autoDismissDuration_" + groupId] || 0;
                if (duration > 0) {
                    startGroupTimer(groupId, duration);
                }
            }
        }

        updateAllWidgetsState(currentActive);
        activeGroupIds = currentActive;

        if (pluginService) {
            pluginService.savePluginData(pluginId, "activeGroupIds", currentActive);
            pluginService.savePluginData(pluginId, "activeGroupId", currentActive.length > 0 ? currentActive[0] : "");
        }
    }

    function groupsOverlap(g1, g2) {
        if (!g1 || !g1.widgets || !g2 || !g2.widgets) return false;
        return g1.widgets.some(wId => g2.widgets.includes(wId));
    }

    function hasOverlapWithActive(groupId, activeIds) {
        const targetGroup = groups.find(g => g.id === groupId);
        if (!targetGroup) return false;
        for (let i = 0; i < activeIds.length; i++) {
            const activeGroup = groups.find(g => g.id === activeIds[i]);
            if (activeGroup && groupsOverlap(targetGroup, activeGroup)) {
                return true;
            }
        }
        return false;
    }

    function getAllGroupWidgetIds() {
        let ids = [];
        groups.forEach(g => {
            if (g.widgets) {
                g.widgets.forEach(wId => {
                    if (!ids.includes(wId)) {
                        ids.push(wId);
                    }
                });
            }
        });
        return ids;
    }

    function updateAllWidgetsState(activeIds) {
        const allWidgetIds = getAllGroupWidgetIds();
        allWidgetIds.forEach(wId => {
            const activeGroupsWithWidget = rootDaemon.groups.filter(g => activeIds.includes(g.id) && g.widgets && g.widgets.includes(wId));
            if (activeGroupsWithWidget.length > 0) {
                SettingsData.updateDesktopWidgetInstance(wId, {
                    enabled: true
                });

                let showOnOverlayVal = false;
                let showOnOverviewVal = false;
                let showOnOverviewOnlyVal = false;
                let clickThroughVal = false;

                activeGroupsWithWidget.forEach(g => {
                    const hasOverride = !!g.overrideIndividual && g.widgetOverrides && g.widgetOverrides[wId];
                    const overrides = hasOverride ? g.widgetOverrides[wId] : {};

                    if (hasOverride) {
                        if (overrides.toggleOverlay !== false) showOnOverlayVal = true;
                        if (!!overrides.toggleOverview) showOnOverviewVal = true;
                        if (!!overrides.toggleOverviewOnly) showOnOverviewOnlyVal = true;
                        if (!!overrides.toggleClickThrough) clickThroughVal = true;
                    } else {
                        if (g.toggleOverlay !== false) showOnOverlayVal = true;
                        if (!!g.toggleOverview) showOnOverviewVal = true;
                        if (!!g.toggleOverviewOnly) showOnOverviewOnlyVal = true;
                        if (!!g.toggleClickThrough) clickThroughVal = true;
                    }
                });

                SettingsData.updateDesktopWidgetInstanceConfig(wId, {
                    showOnOverlay: showOnOverlayVal,
                    showOnOverview: showOnOverviewVal,
                    showOnOverviewOnly: showOnOverviewOnlyVal,
                    clickThrough: clickThroughVal
                });
            } else {
                SettingsData.updateDesktopWidgetInstanceConfig(wId, {
                    showOnOverlay: false,
                    showOnOverview: false,
                    showOnOverviewOnly: false,
                    clickThrough: false
                });

                const groupsWithWidget = rootDaemon.groups.filter(g => g.widgets && g.widgets.includes(wId));
                const shouldHide = groupsWithWidget.some(g => {
                    const hasOverride = !!g.overrideIndividual && g.widgetOverrides && g.widgetOverrides[wId];
                    if (hasOverride) {
                        return !!g.widgetOverrides[wId].hideWhenInactive;
                    } else {
                        return !!g.hideWhenInactive;
                    }
                });

                if (shouldHide) {
                    SettingsData.updateDesktopWidgetInstance(wId, {
                        enabled: false
                    });
                } else {
                    SettingsData.updateDesktopWidgetInstance(wId, {
                        enabled: true
                    });
                }
            }
        });
    }
}
