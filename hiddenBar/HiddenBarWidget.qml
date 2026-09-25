import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Modules.Plugins
import qs.Services
import qs.Widgets

PluginComponent {
    id: pluginRoot

    property bool isExpanded: pluginData.startExpanded ?? false
    readonly property bool autoExpand: pluginData.autoExpand ?? true
    readonly property int hoverDelay: pluginData.hoverDelay ?? 0
    readonly property bool excludeTray: pluginData.excludeTray ?? true
    readonly property bool excludeClock: pluginData.excludeClock ?? true
    readonly property bool autoCollapse: pluginData.autoCollapse ?? true
    readonly property bool hideIconPillWhenCollapsed: pluginData.hideIconPillWhenCollapsed ?? false
    readonly property bool hideIconPillWhenExpanded: pluginData.hideIconPillWhenExpanded ?? false
    readonly property int collapseDelay: {
        const val = pluginData.collapseDelay ?? 1;
        return val <= 100 ? val * 1000 : val;
    }
    property bool isPinned: false
    readonly property int expandedHeight: Theme.iconSizeLarge + Theme.spacingM
    readonly property int collapsedHeight: 4
    readonly property int spacing: Theme.spacingS
    readonly property bool extendedTrigger: pluginData.extendedTrigger ?? true
    readonly property int hideCount: pluginData.hideCount ?? 0
    // Granular widget control: "auto" hides everything eligible (respecting the
    // tray/clock toggles and hideCount), "blacklist" hides everything except the
    // listed widgets, "whitelist" hides only the listed widgets. IDs match the
    // BarWidgetService registry (== bar config / plugin fullId).
    readonly property string widgetSelectionMode: pluginData.widgetSelectionMode ?? "auto"
    readonly property var widgetBlacklist: pluginData.widgetBlacklist ?? []
    readonly property var widgetWhitelist: pluginData.widgetWhitelist ?? []
    readonly property bool showRegionPreview: pluginData.showRegionPreview ?? false
    readonly property int triggerAdjustment: pluginData.triggerAdjustment ?? 0
    readonly property int triggerOffset: pluginData.triggerOffset ?? 0
    readonly property int triggerHeightAdjustment: pluginData.triggerHeightAdjustment ?? 0
    readonly property int triggerYOffset: pluginData.triggerYOffset ?? 0
    readonly property bool usePopout: pluginData.usePopout ?? false
    readonly property string popoutLayout: pluginData.popoutLayout ?? "row"
    readonly property int popoutWidthAdjustment: pluginData.popoutWidthAdjustment ?? 48
    readonly property int popoutHeightAdjustment: pluginData.popoutHeightAdjustment ?? 6
    onUsePopoutChanged: updateWidgets()
    onWidgetSelectionModeChanged: updateWidgets()
    onWidgetBlacklistChanged: updateWidgets()
    onWidgetWhitelistChanged: updateWidgets()
    property var hiddenPluginIds: []
    property bool _popoutVisible: false
    property bool _popoutHovered: false
    property real hiddenAreaSize: 0

    // Collapse/expand animation. collapseProgress drives the managed widgets'
    // layout slot size: 0 = fully collapsed (space reclaimed), 1 = fully shown.
    // It tracks the expand state so toggling animates via the Behavior below.
    readonly property bool animateCollapse: pluginData.animateCollapse ?? true
    readonly property int animDuration: pluginData.animDuration ?? 220
    property real collapseProgress: pluginRoot.usePopout ? 0 : (pluginRoot.isExpanded ? 1 : 0)
    // Slots we currently override, as {slot, item} pairs, so they can be restored.
    property var _managedSlots: []
    // Last known reliable position per widget id, so selection stays stable while
    // managed slots are collapsed (their live x/y is unreliable when reclaimed).
    property var _posCache: ({})

    readonly property int _popoutInternalMargin: Theme.spacingS // From PluginPopout.qml
    readonly property real _totalManagedWidth: {
        let w = 0;
        for (let i = 0; i < hiddenPluginIds.length; i++) {
            let id = hiddenPluginIds[i];
            w += (pluginRoot._sizeCache[id] || Theme.iconSizeSmall);
        }
        if (hiddenPluginIds.length > 1) {
            w += (hiddenPluginIds.length - 1) * Theme.spacingM;
        }
        return w;
    }
    property var _sizeCache: ({
    }) // Cache for widget sizes
    property bool anyHovered: false
    property bool isMouseInGlobalZone: false

    function updateAnyHovered() {
        if (isMouseInGlobalZone || _popoutHovered) {
            hoverGraceTimer.stop();
            anyHovered = true;
        } else {
            if (pluginRoot.isExpanded) {
                if (!hoverGraceTimer.running)
                    hoverGraceTimer.restart();

            } else {
                anyHovered = false;
            }
        }
    }

    // Helper to get screen coordinates of the main bar pill.
    // This MUST be called from the bar window context to get correct global coordinates.
    function getMainPillScreenPos() {
        const pill = isVertical ? verticalPill : horizontalPill;
        if (!pill || !pill.visualContent) return { x: 0, y: 0, width: 0 };
        
        const globalPos = pill.visualContent.mapToItem(null, 0, 0);
        const currentScreen = parentScreen || Screen;
        const barPosition = (axis ? axis.edge : "") === "left" ? 2 : ((axis ? axis.edge : "") === "right" ? 3 : ((axis ? axis.edge : "") === "top" ? 0 : 1));
        return SettingsData.getPopupTriggerPosition(globalPos, currentScreen, barThickness, pill.visualWidth, barSpacing, barPosition, barConfig);
    }

    function handleHover(hovered) {
        if (hovered) {
            const isOpened = pluginRoot.usePopout ? pluginRoot._popoutVisible : pluginRoot.isExpanded;
            if (pluginRoot.autoExpand && !isOpened) {
                hoverTimer.interval = pluginRoot.hoverDelay;
                hoverTimer.restart();
            }
            collapseTimer.stop();
        } else {
            hoverTimer.stop();
            const isOpened = pluginRoot.usePopout ? pluginRoot._popoutVisible : pluginRoot.isExpanded;
            if (isOpened && pluginRoot.autoCollapse && !pluginRoot.isPinned)
                collapseTimer.restart();

        }
    }

    // Whether a widget id may be hidden under the current selection mode.
    // "auto" allows everything; the tray/clock quick-toggles are handled
    // separately (auto mode only) so they don't fight the explicit lists.
    function _isHideAllowed(id) {
        if (pluginRoot.widgetSelectionMode === "blacklist")
            return pluginRoot.widgetBlacklist.indexOf(id) === -1;
        if (pluginRoot.widgetSelectionMode === "whitelist")
            return pluginRoot.widgetWhitelist.indexOf(id) !== -1;
        return true;
    }

    // Position of a widget's layout slot, cached while reliable. A managed slot
    // collapses to ~0 and turns invisible, so its live x/y can't be trusted then;
    // we fall back to the last position captured while it was at full size.
    function _resolvePos(id, slot) {
        let live = pluginRoot.isVertical ? slot.y : slot.x;
        let sz = pluginRoot.isVertical ? slot.height : slot.width;
        if (slot.visible && sz > 1) {
            pluginRoot._posCache[id] = live;
            return live;
        }
        return (id in pluginRoot._posCache) ? pluginRoot._posCache[id] : live;
    }

    // Override a widget's layout slot so its size follows collapseProgress and it
    // reveals from the pill side. clip hides the overflow while the slot shrinks.
    // All size bindings read the WidgetHost Loader's LIVE item (loader.item),
    // mirroring DMS' own `widgetLoader.item ? widgetLoader.item.width : 0` — so a
    // widget whose Loader reactivates (music player on/off, dgop toggle) tracks the
    // fresh item instead of clinging to a captured, now-destroyed reference.
    function _applyManaged(slot, item) {
        if (!slot || !item)
            return ;
        let loader = item.parent; // the WidgetHost Loader hosting this widget
        if (!loader)
            return ;
        slot.clip = true;
        loader.visible = true;
        if (pluginRoot.isVertical) {
            slot.height = Qt.binding(function() {
                return loader.item ? Math.round((loader.item.implicitHeight || loader.item.height || 0) * pluginRoot.collapseProgress) : 0;
            });
            // Vertical right section: widgets sit above the pill, so reveal from the
            // bottom (pill) edge. Left/center reveal from the top edge.
            if (pluginRoot.section === "right")
                loader.y = Qt.binding(function() {
                    return slot.height - (loader.implicitHeight || loader.height || 0);
                });
            else
                loader.y = 0;
        } else {
            slot.width = Qt.binding(function() {
                return loader.item ? Math.round((loader.item.implicitWidth || loader.item.width || 0) * pluginRoot.collapseProgress) : 0;
            });
            // Right section: widgets sit left of the pill, so reveal from the right
            // (pill) edge. Left/center reveal from the left edge.
            if (pluginRoot.section === "right")
                loader.x = Qt.binding(function() {
                    return slot.width - (loader.implicitWidth || loader.width || 0);
                });
            else
                loader.x = 0;
        }
        slot.visible = Qt.binding(function() {
            return pluginRoot.collapseProgress > 0.001;
        });
    }

    // Hand a slot back to its default DMS layout (full size, visible, no clip).
    // Re-bind to the live loader.item, matching DMS' own delegate binding, so the
    // slot keeps tracking the widget across Loader reloads after we let go of it.
    function _restoreSlot(slot, item) {
        if (!slot)
            return ;
        slot.clip = false;
        slot.visible = true;
        let loader = item ? item.parent : null;
        if (loader) {
            loader.visible = true;
            loader.x = 0;
            loader.y = 0;
        }
        if (pluginRoot.isVertical)
            slot.height = Qt.binding(function() {
                return (loader && loader.item) ? (loader.item.implicitHeight || loader.item.height || 0) : 0;
            });
        else
            slot.width = Qt.binding(function() {
                return (loader && loader.item) ? (loader.item.implicitWidth || loader.item.width || 0) : 0;
            });
    }

    function updateWidgets() {
        if (!pluginRoot.parentScreen)
            return ;

        let myScreen = pluginRoot.parentScreen.name;
        let mySection = pluginRoot.section;
        if (!pluginRoot.parent || !pluginRoot.parent.parent)
            return ;

        let myPos = pluginRoot.isVertical ? pluginRoot.parent.parent.y : pluginRoot.parent.parent.x;
        let allIds = BarWidgetService.getRegisteredWidgetIds();
        let candidates = [];
        for (let i = 0; i < allIds.length; i++) {
            let id = allIds[i];
            if (id === pluginRoot.pluginId)
                continue;

            // Tray/clock quick-toggles only apply in auto mode; in
            // blacklist/whitelist the explicit lists are the source of truth.
            if (pluginRoot.widgetSelectionMode === "auto") {
                if (pluginRoot.excludeTray && (id === "systray" || id.includes("tray")))
                    continue;

                if (pluginRoot.excludeClock && (id === "clock" || id === "time"))
                    continue;

            }

            let widget = BarWidgetService.getWidget(id, myScreen);
            if (widget && widget.section === mySection && widget.parent && widget.parent.parent) {
                let widgetPos = pluginRoot._resolvePos(id, widget.parent.parent);
                let shouldManage = false;
                if (mySection === "right")
                    shouldManage = (widgetPos < myPos);
                else if (mySection === "left")
                    shouldManage = (widgetPos > myPos);
                else if (mySection === "center")
                    shouldManage = true;
                if (shouldManage)
                    candidates.push({
                    "id": id,
                    "widget": widget,
                    "dist": Math.abs(widgetPos - myPos),
                    "pos": widgetPos
                });

            }
        }
        candidates.sort((a, b) => {
            return a.dist - b.dist;
        });
        // Only widgets allowed by the current selection mode can be hidden.
        // Non-eligible candidates stay in `candidates` so the visibility loop
        // below restores them to visible (handles toggling a widget back on).
        let eligible = candidates.filter(c => pluginRoot._isHideAllowed(c.id));
        let limit = (pluginRoot.hideCount > 0) ? pluginRoot.hideCount : eligible.length;
        let hiddenCandidates = eligible.slice(0, limit);
        hiddenCandidates.sort((a, b) => {
            return a.pos - b.pos;
        });
        let newHiddenIds = [];
        for (let k = 0; k < hiddenCandidates.length; k++) {
            newHiddenIds.push(hiddenCandidates[k].id);
        }
        let totalSize = 0;
        let newManaged = [];
        for (let j = 0; j < candidates.length; j++) {
            let c = candidates[j];
            let slot = c.widget.parent ? c.widget.parent.parent : null;
            let shouldBeHidden = newHiddenIds.indexOf(c.id) !== -1;
            if (shouldBeHidden) {
                let currentSize = pluginRoot.isVertical ? (c.widget.implicitHeight || c.widget.height || 0) : (c.widget.implicitWidth || c.widget.width || 0);
                if (currentSize > 0)
                    pluginRoot._sizeCache[c.id] = currentSize;

                let size = currentSize > 0 ? currentSize : (pluginRoot._sizeCache[c.id] || 0);
                if (size > 0)
                    totalSize += size;

                if (slot) {
                    pluginRoot._applyManaged(slot, c.widget);
                    newManaged.push({
                        "slot": slot,
                        "item": c.widget
                    });
                }
            } else if (slot) {
                pluginRoot._restoreSlot(slot, c.widget);
            }
        }

        // Restore slots that were managed last time but no longer are.
        let oldManaged = pluginRoot._managedSlots;
        for (let m = 0; m < oldManaged.length; m++) {
            let pair = oldManaged[m];
            let stillManaged = false;
            for (let n = 0; n < newManaged.length; n++) {
                if (newManaged[n].slot === pair.slot) {
                    stillManaged = true;
                    break;
                }
            }
            if (!stillManaged)
                pluginRoot._restoreSlot(pair.slot, pair.item);
        }
        pluginRoot._managedSlots = newManaged;
        pluginRoot.hiddenPluginIds = newHiddenIds;

        // Cleanup cache for unregistered widgets
        let cacheKeys = Object.keys(pluginRoot._sizeCache);
        for (let k = 0; k < cacheKeys.length; k++) {
            if (allIds.indexOf(cacheKeys[k]) === -1)
                delete pluginRoot._sizeCache[cacheKeys[k]];

        }
        if (totalSize > 0 && !pluginRoot.usePopout) {
            let newSize = totalSize + Theme.spacingM;
            if (Math.abs(pluginRoot.hiddenAreaSize - newSize) > 1)
                pluginRoot.hiddenAreaSize = newSize;

        } else if (pluginRoot.hiddenAreaSize !== 0) {
            pluginRoot.hiddenAreaSize = 0;
        }
    }

    Component.onCompleted: {
        reEvalTimer.restart();
        for (let i = 0; i < pluginRoot.children.length; i++) {
            let child = pluginRoot.children[i];
            if (child && "_primeContent" in child) {
                child.primeContent();
                child.popoutClosed.connect(child.primeContent);
            }
        }
    }
    Component.onDestruction: {
        // Hand every overridden slot back to its default DMS layout so we never
        // leave a foreign widget bound to this (now destroyed) component.
        for (let i = 0; i < pluginRoot._managedSlots.length; i++) {
            pluginRoot._restoreSlot(pluginRoot._managedSlots[i].slot, pluginRoot._managedSlots[i].item);
        }
        pluginRoot._managedSlots = [];
    }
    onIsMouseInGlobalZoneChanged: {
        updateAnyHovered();
    }
    onAnyHoveredChanged: handleHover(anyHovered)
    pillClickAction: pluginRoot.usePopout ? null : function() {
        pluginRoot.isExpanded = !pluginRoot.isExpanded;
        pluginRoot.isPinned = false;
        updateWidgets();
        // Only start collapse timer if expanded AND mouse is NOT in zone AND not pinned
        if (pluginRoot.isExpanded && pluginRoot.autoCollapse && !pluginRoot.anyHovered && !pluginRoot.isPinned)
            collapseTimer.restart();
        else
            collapseTimer.stop();
    }
    verticalBarPill: horizontalBarPill

    popoutWidth: {
        if (pluginRoot.popoutLayout === "row") {
            if (hiddenPluginIds.length === 0) return 60;
            return Math.max(60, _totalManagedWidth + Theme.spacingM * 2 + _popoutInternalMargin * 2 + pluginRoot.popoutWidthAdjustment);
        }
        return 240;
    }
    popoutHeight: pluginRoot.popoutLayout === "row" ? (pluginRoot.barThickness + Theme.spacingS * 2) : Math.ceil(hiddenPluginIds.length / 4) * (Theme.iconSizeSmall + Theme.spacingM) + Theme.spacingM * 2

    popoutContent: pluginRoot.usePopout ? popoutComponentDef : null

    function triggerHoverPopout(widgetHostId) {
        if (!pluginRoot.usePopout || !pluginRoot.autoExpand)
            return;
        if (!hasPopout || !positionPopout())
            return;
        const pill = isVertical ? verticalPill : horizontalPill;
        const target = pill ? pill.popoutTarget : null;
        if (target)
            PopoutManager.requestHoverPopout(target, undefined, widgetHostId || pluginId);
    }

    Component {
        id: popoutComponentDef
        PopoutComponent {
            headerText: ""
            showCloseButton: false
            
            Component.onCompleted: pluginRoot._popoutVisible = true
            Component.onDestruction: {
                pluginRoot._popoutVisible = false;
                pluginRoot._popoutHovered = false;
            }

            Connections {
                target: parentPopout
                function onShouldBeVisibleChanged() {
                    pluginRoot._popoutVisible = parentPopout.shouldBeVisible;
                    if (!parentPopout.shouldBeVisible)
                        pluginRoot._popoutHovered = false;
                }
            }

            MouseArea {
                width: parent.width
                height: {
                    let baseH = pluginRoot.popoutLayout === "row" ? pluginRoot.barThickness : Math.ceil(hiddenPluginIds.length / 4) * (Theme.iconSizeSmall + Theme.spacingM) + Theme.spacingM * 2;
                    return Math.max(40, baseH + pluginRoot.popoutHeightAdjustment);
                }
                hoverEnabled: true
                onContainsMouseChanged: pluginRoot._popoutHovered = containsMouse
                propagateComposedEvents: true

                Rectangle {
                    anchors.fill: parent
                    color: Theme.surfaceVariant
                    opacity: 0.5
                    radius: Theme.cornerRadius
                    z: -1
                }

                Loader {
                    anchors.fill: parent
                    sourceComponent: pluginRoot.popoutLayout === "grid" ? gridLayout : rowLayout
                }
            }

            Component {
                id: rowLayout
                Row {
                    width: parent.width
                    height: parent.height
                    spacing: Theme.spacingM
                    leftPadding: Theme.spacingM
                    rightPadding: Theme.spacingM
                    
                    Repeater {
                        model: pluginRoot.hiddenPluginIds
                        delegate: widgetDelegate
                    }
                }
            }

            Component {
                id: gridLayout
                Flow {
                    width: parent.width
                    spacing: Theme.spacingM
                    padding: Theme.spacingM
                    Repeater {
                        model: pluginRoot.hiddenPluginIds
                        delegate: widgetDelegate
                    }
                }
            }

            Component {
                id: widgetDelegate
                Item {
                    id: delegateRoot
                    implicitWidth: (widgetLoader.item && widgetLoader.item.width > 0) ? widgetLoader.item.width : (pluginRoot._sizeCache[modelData] || Theme.iconSizeSmall)
                    height: parent.height
                    anchors.verticalCenter: parent.verticalCenter

                    readonly property var originalWidget: {
                        if (!pluginRoot.parentScreen) return null;
                        return BarWidgetService.getWidget(modelData, pluginRoot.parentScreen.name);
                    }

                    Loader {
                        id: widgetLoader
                        readonly property string targetPluginId: modelData
                        anchors.fill: parent

                        sourceComponent: PluginService.pluginWidgetComponents[targetPluginId] || null

                        onLoaded: {
                            if (item) {
                                if (item.pluginId !== undefined) item.pluginId = targetPluginId;
                                if (item.pluginService !== undefined) item.pluginService = PluginService;
                                if (item.popoutService !== undefined) item.popoutService = PopoutService;
                                if (item.isVertical !== undefined) { try { item.isVertical = false; } catch (e) {} }
                            }
                        }
                    }

                    DropArea {
                        anchors.fill: parent
                        z: 11
                        onEntered: drag => { drag.accepted = true; }
                        onDropped: {
                            const w = delegateRoot.originalWidget;
                            if (w) {
                                if (typeof w.triggerPopout === "function")
                                    w.triggerPopout();
                                else
                                    BarWidgetService.triggerWidgetPopout(modelData);
                                pluginRoot.closePopout();
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        z: 10
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        onContainsMouseChanged: pluginRoot._popoutHovered = containsMouse
                        onClicked: mouse => {
                            const w = delegateRoot.originalWidget;
                            if (mouse.button === Qt.RightButton) {
                                if (w && typeof w.pillRightClickAction === "function")
                                    w.pillRightClickAction();
                                else
                                    BarWidgetService.triggerWidgetPopout(modelData);
                                return;
                            }
                            if (w && typeof w.triggerPopout === "function")
                                w.triggerPopout();
                            else
                                BarWidgetService.triggerWidgetPopout(modelData);
                        }
                    }
                }
            }
        }
    }

    Behavior on collapseProgress {
        enabled: pluginRoot.animateCollapse && !pluginRoot.usePopout
        NumberAnimation {
            duration: pluginRoot.animDuration
            easing.type: Easing.OutCubic
        }
    }

    Timer {
        id: hoverGraceTimer

        interval: 500
        repeat: false
        onTriggered: {
            if (!pluginRoot.isMouseInGlobalZone)
                pluginRoot.anyHovered = false;

        }
    }

    Timer {
        id: hoverTimer

        repeat: false
        onTriggered: {
            if (pluginRoot.usePopout) {
                if (!pluginRoot._popoutVisible) {
                    pluginRoot.triggerPopout();
                }
            } else if (!pluginRoot.isExpanded) {
                pluginRoot.isExpanded = true;
                updateWidgets();
            }
        }
    }

    Timer {
        id: collapseTimer

        interval: pluginRoot.collapseDelay
        repeat: false
        onTriggered: {
            // Safety check: don't collapse if mouse returned to zone
            if (pluginRoot.anyHovered) return;

            if (pluginRoot.usePopout) {
                if (pluginRoot._popoutVisible) {
                    pluginRoot.closePopout();
                }
            } else if (pluginRoot.isExpanded) {
                pluginRoot.isExpanded = false;
                updateWidgets();
            }
        }
    }

    Connections {
        function onWidgetRegistered(id, screen) {
            if (pluginRoot.parentScreen && screen === pluginRoot.parentScreen.name)
                reEvalTimer.restart();

        }

        target: BarWidgetService
    }

    Timer {
        id: reEvalTimer

        interval: 100
        repeat: false
        onTriggered: updateWidgets()
    }



    IpcHandler {
        function toggle() : string {
            pluginRoot.isExpanded = !pluginRoot.isExpanded;
            pluginRoot.isPinned = false;
            updateWidgets();
            if (pluginRoot.isExpanded && pluginRoot.autoCollapse && !pluginRoot.anyHovered && !pluginRoot.isPinned)
                collapseTimer.restart();
            else
                collapseTimer.stop();
            return pluginRoot.isExpanded ? "EXPANDED" : "COLLAPSED";
        }

        function togglePin() : string {
            if (!pluginRoot.isExpanded) {
                pluginRoot.isExpanded = true;
                pluginRoot.isPinned = true;
                updateWidgets();
                collapseTimer.stop();
            } else {
                pluginRoot.isPinned = !pluginRoot.isPinned;
                if (!pluginRoot.isPinned && pluginRoot.autoCollapse && !pluginRoot.anyHovered)
                    collapseTimer.restart();
                else
                    collapseTimer.stop();
            }
            return pluginRoot.isPinned ? "PINNED" : "UNPINNED";
        }

        target: "hiddenBar"
    }

    MouseArea {
        id: triggerZone

        readonly property real baseExpansion: pluginRoot.extendedTrigger ? Math.max(pluginRoot.hiddenAreaSize, 260) : 0
        readonly property real expansion: Math.max(0, baseExpansion + pluginRoot.triggerAdjustment)

        hoverEnabled: true
        acceptedButtons: Qt.NoButton
        propagateComposedEvents: true
        cursorShape: Qt.PointingHandCursor
        width: {
            if (pluginRoot.isVertical)
                return pluginRoot.width + pluginRoot.triggerHeightAdjustment;

            return pluginRoot.width + expansion;
        }
        height: {
            if (!pluginRoot.isVertical)
                return pluginRoot.height + pluginRoot.triggerHeightAdjustment;

            return pluginRoot.height + expansion;
        }
        x: {
            if (pluginRoot.isVertical)
                return pluginRoot.triggerYOffset;

            let base_x = 0;
            if (pluginRoot.section === "right")
                base_x = -expansion;
            else if (pluginRoot.section === "center")
                base_x = -expansion / 2;

            return base_x + pluginRoot.triggerOffset;
        }
        y: {
            if (!pluginRoot.isVertical)
                return pluginRoot.triggerYOffset;

            let base_y = 0;
            if (pluginRoot.section === "right")
                base_y = -expansion;
            else if (pluginRoot.section === "center")
                base_y = -expansion / 2;

            return base_y + pluginRoot.triggerOffset;
        }
        onContainsMouseChanged: {
            pluginRoot.isMouseInGlobalZone = containsMouse;
        }

        DropArea {
            anchors.fill: parent
            enabled: !pluginRoot.isExpanded
            onEntered: {
                pluginRoot.isMouseInGlobalZone = true;
            }
            onExited: {
                pluginRoot.isMouseInGlobalZone = false;
            }
        }
    }

    Rectangle {
        id: regionPreview

        visible: pluginRoot.showRegionPreview
        x: triggerZone.x
        y: triggerZone.y
        width: triggerZone.width
        height: triggerZone.height
        color: Theme.primary
        opacity: 0.2
        border.color: Theme.primary
        border.width: 1
        z: 999 // Ensure it's visible over other widgets
    }

    horizontalBarPill: Component {
        Item {
            id: pillRootItem

            readonly property bool isActuallyExpanded: pluginRoot.isExpanded || (pluginRoot.usePopout && pluginRoot._popoutVisible)
            readonly property bool shouldBeHidden: (pluginRoot.hideIconPillWhenCollapsed && !isActuallyExpanded) || (pluginRoot.hideIconPillWhenExpanded && isActuallyExpanded)

            implicitWidth: shouldBeHidden ? 0 : Theme.iconSizeSmall
            implicitHeight: shouldBeHidden ? 0 : Theme.iconSizeSmall
            visible: opacity > 0
            opacity: shouldBeHidden ? 0 : (isActuallyExpanded ? 1 : 0.6)
            clip: true

            DankIcon {
                id: pillIcon

                anchors.centerIn: parent
                size: Theme.iconSizeSmall
                name: {
                    if (pluginRoot.isPinned)
                        return "push_pin";

                    if (pluginRoot.usePopout) {
                        if (pluginRoot.isVertical) {
                            const edge = axis?.edge ?? "";
                            if (edge === "left")
                                return pluginRoot._popoutVisible ? "chevron_right" : "chevron_left";
                            if (edge === "right")
                                return pluginRoot._popoutVisible ? "chevron_left" : "chevron_right";
                        }
                        return "expand_less";
                    }

                    if (pluginRoot.section === "right")
                        return pluginRoot.isExpanded ? "chevron_left" : "chevron_right";
                    else if (pluginRoot.section === "left")
                        return pluginRoot.isExpanded ? "chevron_right" : "chevron_left";
                    return pluginRoot.isExpanded ? "view-conceal-symbolic" : "view-visible-symbolic";
                }
                rotation: (pluginRoot.usePopout && pluginRoot._popoutVisible && !pluginRoot.isVertical) ? 180 : 0
                color: Theme.surfaceText
            }

            Rectangle {
                id: pinIndicator

                width: Theme.spacingXS
                height: Theme.spacingXS
                radius: width / 2
                color: Theme.primary
                visible: pluginRoot.isPinned

                anchors {
                    right: parent.right
                    rightMargin: -Theme.spacingXS / 2
                    top: parent.top
                    topMargin: Theme.spacingXS / 2
                }

            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.RightButton
                onClicked: {
                    if (mouse.button === Qt.RightButton) {
                        if (pluginRoot.isExpanded)
                            pluginRoot.isPinned = !pluginRoot.isPinned;
                        else
                            pluginRoot.isPinned = false;
                    }
                }
            }

        }

    }

}
