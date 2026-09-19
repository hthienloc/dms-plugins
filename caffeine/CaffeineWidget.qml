import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland
import qs.Common
import qs.Widgets
import qs.Services
import qs.Modules.Plugins

PluginComponent {
    id: root
    pluginId: "caffeine"
    pluginService: PluginService

    // Reactive states
    readonly property bool caffeineActive: globalIsActive.value
    property string selectedDuration: {
        if (pluginData && pluginData.selectedDuration !== undefined && pluginData.selectedDuration !== null && pluginData.selectedDuration !== "undefined" && pluginData.selectedDuration !== "") {
            return pluginData.selectedDuration;
        }
        let def = pluginData?.defaultDuration ?? "infinity";
        def = def.trim().toLowerCase();
        if (def === "infinity" || def === "infinite" || def === "inf" || def === "") {
            return "infinity";
        }
        const mins = parseInt(def);
        if (!isNaN(mins) && mins > 0) {
            return (mins * 60).toString();
        }
        return "infinity";
    }
    readonly property int timeLeft: globalTimeLeft.value

    readonly property bool isAutoActive: globalIsAutoActive.value
    readonly property bool manualOverrideOff: globalManualOverrideOff.value

    PluginGlobalVar {
        id: globalIsActive
        varName: "isActive"
        defaultValue: false
    }

    PluginGlobalVar {
        id: globalTimeLeft
        varName: "timeLeft"
        defaultValue: 0
    }

    PluginGlobalVar {
        id: globalIsAutoActive
        varName: "isAutoActive"
        defaultValue: false
    }

    PluginGlobalVar {
        id: globalManualOverrideOff
        varName: "manualOverrideOff"
        defaultValue: false
    }

    // Sync settings
    property bool showToasts: (pluginData?.showToasts ?? true)
    property bool showProgressRing: (pluginData?.showProgressRing ?? true)
    property bool appAutomationEnabled: (pluginData?.appAutomationEnabled ?? false)
    property string autoAppsList: (pluginData?.autoAppsList ?? "mpv, vlc, zoom, Teams, discord, webcord, slack, spotify, obs")
    readonly property var parsedAutoApps: autoAppsList.split(",").map(a => a.trim().toLowerCase()).filter(Boolean)
    property bool fullscreenAwarenessEnabled: (pluginData?.fullscreenAwarenessEnabled ?? false)
    property bool batteryIntegrationEnabled: (pluginData?.batteryIntegrationEnabled ?? false)
    property int batteryLowThreshold: {
        const raw = pluginData?.batteryLowThreshold ?? "15";
        const val = parseInt(raw);
        return isNaN(val) ? 15 : val;
    }
    property bool deactivateOnManualLock: (pluginData?.deactivateOnManualLock ?? true)

    // Animated Coffee Cup component with steam and radial progress ring
    Component {
        id: animatedCoffeeCup
        Item {
            id: cupRoot
            width: 56
            height: 56
            
            // Radial progress ring
            RadialProgressRing {
                anchors.fill: parent
                radius: 25
                strokeWidth: 3
                color: Theme.primary
                active: root.caffeineActive
                ringVisible: root.showProgressRing
                backgroundOpacityActive: 0.25
                backgroundOpacityInactive: 0.08
                angle: {
                    if (root.selectedDuration === "infinity") return 360;
                    const total = parseInt(root.selectedDuration);
                    if (isNaN(total) || total <= 0) return 360;
                    return 360 * (root.timeLeft / total);
                }
            }

            // Coffee Cup Icon
            DankIcon {
                id: cupIcon
                name: "local_cafe"
                size: 28
                color: root.caffeineActive ? Theme.primary : Theme.surfaceText
                anchors.centerIn: parent
                anchors.verticalCenterOffset: 2
            }

            // Steaming lines (active only)
            Item {
                id: steamContainer
                width: 24
                height: 16
                anchors.bottom: cupIcon.top
                anchors.horizontalCenter: cupIcon.horizontalCenter
                anchors.bottomMargin: -2
                visible: root.caffeineActive

                Repeater {
                    model: 3
                    delegate: Shape {
                        id: steam
                        width: 6
                        height: 12
                        x: [3, 9, 15][index]
                        y: 4
                        opacity: 0
                        
                        ShapePath {
                            strokeColor: Theme.primary
                            strokeWidth: 1.5
                            fillColor: "transparent"
                            capStyle: ShapePath.RoundCap
                            startX: 3
                            startY: 12
                            PathQuad { x: 1; y: 6; controlX: 5; controlY: 9 }
                            PathQuad { x: 3; y: 0; controlX: -1; controlY: 3 }
                        }

                        SequentialAnimation {
                            running: steamContainer.visible
                            loops: Animation.Infinite
                            
                            PauseAnimation {
                                duration: index * 400
                            }
                            
                            ParallelAnimation {
                                NumberAnimation { target: steam; property: "y"; from: 4; to: -8; duration: 1200; easing.type: Easing.OutQuad }
                                SequentialAnimation {
                                    NumberAnimation { target: steam; property: "opacity"; from: 0; to: 0.7; duration: 400 }
                                    NumberAnimation { target: steam; property: "opacity"; from: 0.7; to: 0; duration: 800 }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    property var durationOptions: {
        const rawPresets = pluginData?.presets ?? "5, 15, 30, 60, 120, infinity";
        const items = rawPresets.split(",").map(item => item.trim()).filter(Boolean);
        const result = [];
        for (const item of items) {
            if (item.toLowerCase() === "infinity" || item.toLowerCase() === "infinite" || item.toLowerCase() === "inf") {
                result.push({ label: "Infinite", value: "infinity" });
            } else {
                const mins = parseInt(item);
                if (!isNaN(mins) && mins > 0) {
                    let label = mins + " Min";
                    if (mins >= 60) {
                        const hrs = mins / 60;
                        if (hrs === 1) {
                            label = "1 Hour";
                        } else if (hrs === Math.round(hrs)) {
                            label = hrs + " Hours";
                        } else {
                            label = hrs.toFixed(1).replace(".0", "") + " Hours";
                        }
                    }
                    result.push({ label: label, value: (mins * 60).toString() });
                }
            }
        }
        return result.length > 0 ? result : [
            { label: "5 Min", value: "300" },
            { label: "15 Min", value: "900" },
            { label: "30 Min", value: "1800" },
            { label: "1 Hour", value: "3600" },
            { label: "2 Hours", value: "7200" },
            { label: "Infinite", value: "infinity" }
        ];
    }

    // Control Center Integration
    ccWidgetIcon: "local_cafe"
    ccWidgetPrimaryText: I18n.tr("Caffeine")
    ccWidgetSecondaryText: {
        // Explicitly depend on caffeineActive, selectedDuration, and timeLeft
        const active = root.caffeineActive;
        const dur = root.selectedDuration;
        const remaining = root.timeLeft;

        if (!active) return I18n.tr("Inactive")
        if (dur === "infinity" || dur === "undefined" || !dur) return I18n.tr("Indefinite")
        if (remaining <= 0) return I18n.tr("Active")
        const mins = Math.ceil(remaining / 60)
        return mins + I18n.tr("m")
    }
    ccWidgetIsActive: caffeineActive
    ccDetailHeight: {
        const rows = Math.ceil(durationOptions.length / 3);
        const headerHeight = 64 + Theme.spacingS;
        const gridHeight = rows * 48 + Math.max(0, rows - 1) * Theme.spacingS;
        const customInputHeight = 36 + Theme.spacingS;
        return headerHeight + gridHeight + customInputHeight + Theme.spacingM * 2;
    }

    readonly property color pillColor: caffeineActive ? Theme.primary : Theme.surfaceText

    readonly property real barPillIconSize: Theme.barIconSize(barThickness, -4, barConfig?.maximizeWidgetIcons, barConfig?.iconScale)
    readonly property real barGlyphIconSize: barPillIconSize

    horizontalBarPill: Component {
        Item {
            implicitWidth: contentRow.implicitWidth
            implicitHeight: contentRow.implicitHeight

            Row {
                id: contentRow
                anchors.centerIn: parent
                spacing: (root.caffeineActive && root.selectedDuration !== "infinity") ? Theme.spacingXS : 0

                Item {
                    width: root.barGlyphIconSize + 8
                    height: root.barGlyphIconSize + 8
                    anchors.verticalCenter: parent.verticalCenter

                    RadialProgressRing {
                        anchors.fill: parent
                        radius: (root.barGlyphIconSize + 8) / 2 - strokeWidth
                        strokeWidth: 1.5
                        color: root.pillColor
                        active: root.caffeineActive
                        ringVisible: root.showProgressRing
                        backgroundOpacityActive: 0.2
                        backgroundOpacityInactive: 0.05
                        angle: {
                            if (root.selectedDuration === "infinity") return 360;
                            const total = parseInt(root.selectedDuration);
                            if (isNaN(total) || total <= 0) return 360;
                            return 360 * (root.timeLeft / total);
                        }
                    }

                    DankIcon {
                        name: "local_cafe"
                        size: root.barGlyphIconSize
                        color: root.pillColor
                        anchors.centerIn: parent
                    }
                }

                StyledText {
                    text: root.ccWidgetSecondaryText
                    color: root.pillColor
                    font.pixelSize: Theme.fontSizeMedium
                    anchors.verticalCenter: parent.verticalCenter
                    visible: root.caffeineActive && root.selectedDuration !== "infinity"
                }
            }
        }
    }

    verticalBarPill: Component {
        Item {
            implicitWidth: vColumn.implicitWidth
            implicitHeight: vColumn.implicitHeight

            Column {
                id: vColumn
                anchors.centerIn: parent
                spacing: (root.caffeineActive && root.selectedDuration !== "infinity") ? Theme.spacingXXS : 0

                Item {
                    width: root.barGlyphIconSize + 8
                    height: root.barGlyphIconSize + 8
                    anchors.horizontalCenter: parent.horizontalCenter

                    RadialProgressRing {
                        anchors.fill: parent
                        radius: (root.barGlyphIconSize + 8) / 2 - strokeWidth
                        strokeWidth: 1.5
                        color: root.pillColor
                        active: root.caffeineActive
                        ringVisible: root.showProgressRing
                        backgroundOpacityActive: 0.2
                        backgroundOpacityInactive: 0.05
                        angle: {
                            if (root.selectedDuration === "infinity") return 360;
                            const total = parseInt(root.selectedDuration);
                            if (isNaN(total) || total <= 0) return 360;
                            return 360 * (root.timeLeft / total);
                        }
                    }

                    DankIcon {
                        name: "local_cafe"
                        size: root.barGlyphIconSize
                        color: root.pillColor
                        anchors.centerIn: parent
                    }
                }

                StyledText {
                    text: root.ccWidgetSecondaryText
                    color: root.pillColor
                    font.pixelSize: Theme.fontSizeSmall
                    anchors.horizontalCenter: parent.horizontalCenter
                    visible: root.caffeineActive && root.selectedDuration !== "infinity"
                }
            }
        }
    }

    // Click action: always open duration picker popout (via null fallback)
    pillClickAction: null

    // Right click: quick toggle stay-awake with default duration
    pillRightClickAction: function() {
        toggleCaffeine()
    }

    // Popout dimensions
    popoutWidth: 360
    popoutHeight: 0 // auto from content

    // Popout content: duration selector grid
    popoutContent: Component {
        PopoutComponent {
            id: popoutScope
            headerText: I18n.tr("Caffeine")
            showCloseButton: true
            property int currentIndex: 0

            // Keyboard navigation
            Keys.onPressed: function(event) {
                const cols = 3
                const count = root.durationOptions.length
                let idx = popoutScope.currentIndex
                if (event.key === Qt.Key_Right) {
                    idx = (idx + 1) % count
                    event.accepted = true
                } else if (event.key === Qt.Key_Left) {
                    idx = (idx - 1 + count) % count
                    event.accepted = true
                } else if (event.key === Qt.Key_Down) {
                    idx = Math.min(idx + cols, count - 1)
                    event.accepted = true
                } else if (event.key === Qt.Key_Up) {
                    idx = Math.max(idx - cols, 0)
                    event.accepted = true
                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Space) {
                    if (idx >= 0 && idx < count) {
                        root.changeDuration(root.durationOptions[idx].value)
                    }
                    event.accepted = true
                } else if (event.key === Qt.Key_Escape) {
                    closePopout()
                    event.accepted = true
                }
                if (event.accepted) {
                    popoutScope.currentIndex = idx
                }
            }

            Column {
                width: parent.width
                spacing: Theme.spacingM
                leftPadding: Theme.spacingM
                rightPadding: Theme.spacingM

                Row {
                    width: parent.width - parent.leftPadding - parent.rightPadding
                    spacing: Theme.spacingM

                    Loader {
                        sourceComponent: animatedCoffeeCup
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Column {
                        width: parent.width - 56 - Theme.spacingM
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2

                        StyledText {
                            text: I18n.tr("Keep Awake")
                            font.pixelSize: Theme.fontSizeLarge
                            color: Theme.surfaceText
                            font.weight: Font.Medium
                        }

                        StyledText {
                            text: {
                                if (!root.caffeineActive) return I18n.tr("Inactive");
                                if (root.selectedDuration === "infinity") return I18n.tr("Active (Indefinite)");
                                const mins = Math.ceil(root.timeLeft / 60);
                                return I18n.tr("Active: %1m remaining").arg(mins);
                            }
                            font.pixelSize: Theme.fontSizeSmall
                            color: root.caffeineActive ? Theme.primary : Theme.surfaceVariantText
                        }
                    }
                }

                Grid {
                    id: durationGrid
                    width: parent.width - parent.leftPadding - parent.rightPadding
                    columns: 3
                    spacing: Theme.spacingS

                    Repeater {
                        model: root.durationOptions

                        delegate: Rectangle {
                            required property var modelData
                            required property int index

                            width: (parent.width - Theme.spacingS * 2) / 3
                            height: 48
                            radius: Theme.cornerRadius
                            color: {
                                if (popoutScope.currentIndex === index) return Theme.primaryPressed
                                if (optionMouseArea.containsMouse) return Theme.surfaceContainerHighest
                                return (root.selectedDuration === modelData.value ? Theme.withAlpha(Theme.primary, 0.12) : "transparent")
                            }
                            border.color: root.selectedDuration === modelData.value ? Theme.primary : Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.2)
                            border.width: root.selectedDuration === modelData.value ? 2 : 1

                            MouseArea {
                                id: optionMouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (typeof popoutScope !== 'undefined') popoutScope.currentIndex = index
                                    const isSelected = String(root.selectedDuration) === String(modelData.value)
                                    if (isSelected) {
                                        root.toggleCaffeine(modelData.value)
                                        if (typeof popoutScope !== 'undefined') closePopout()
                                    } else {
                                        root.changeDuration(modelData.value)
                                    }
                                }
                            }

                            StyledText {
                                text: modelData.label
                                color: root.selectedDuration === modelData.value ? Theme.primary : Theme.surfaceText
                                font.pixelSize: Theme.fontSizeMedium
                                font.weight: root.selectedDuration === modelData.value ? Font.Medium : Font.Normal
                                anchors.centerIn: parent
                            }

                            Keys.onReturnPressed: function(event) {
                                popoutScope.currentIndex = index
                                root.changeDuration(modelData.value)
                                event.accepted = true
                            }
                            Keys.onSpacePressed: function(event) {
                                popoutScope.currentIndex = index
                                root.changeDuration(modelData.value)
                                event.accepted = true
                            }
                        }
                    }
                }

                Row {
                    width: parent.width - parent.leftPadding - parent.rightPadding
                    spacing: Theme.spacingS

                    DankTextField {
                        id: customTimeInput
                        width: parent.width - btnSet.width - Theme.spacingS
                        height: 36
                        placeholderText: I18n.tr("Custom minutes...")
                        validator: IntValidator { bottom: 1; top: 1440 }
                        
                        onAccepted: btnSet.clicked()
                    }

                    DankButton {
                        id: btnSet
                        text: I18n.tr("Set")
                        height: 36
                        onClicked: {
                            const mins = parseInt(customTimeInput.text.trim());
                            if (!isNaN(mins) && mins > 0) {
                                const value = (mins * 60).toString();
                                root.changeDuration(value);
                                if (!root.caffeineActive) {
                                    root.toggleCaffeine(value);
                                }
                                customTimeInput.text = "";
                                closePopout();
                            }
                        }
                    }
                }
            }
        }
    }

    onCcWidgetToggled: {
        toggleCaffeine()
    }

    Timer {
        id: countdownTimer
        interval: 1000
        repeat: true
        running: false
        onTriggered: {
            globalTimeLeft.set(globalTimeLeft.value - 1);
            if (globalTimeLeft.value <= 0) {
                countdownTimer.stop();
                deactivateCaffeine("timeout"); // Turn off caffeine
            }
        }
    }

    // Sync with system state on startup
    Component.onCompleted: {
        Proc.runCommand("check-caffeine-active", ["pgrep", "-f", "DMS Caffeine"], function(output, exitCode) {
            const isActive = (exitCode === 0 && output.trim() !== "");
            if (isActive) {
                globalIsActive.set(true);
                const expiration = pluginService ? pluginService.loadPluginState(pluginId, "expiration", 0) : 0;
                if (expiration > Date.now()) {
                    globalTimeLeft.set(Math.round((expiration - Date.now()) / 1000));
                    countdownTimer.start();
                }
                if (typeof SessionService !== "undefined") {
                    SessionService.enableIdleInhibit();
                }
            } else {
                globalIsActive.set(false);
                if (pluginService) {
                    pluginService.savePluginState(pluginId, "expiration", 0);
                }
            }
            // Trigger auto-checks after we sync caffeine state!
            checkAutoActivation();
            checkBatteryStatus();
        })
    }

    function formatDurationLabel(dur) {
        if (dur === "infinity") return I18n.tr("indefinitely");
        const secs = parseInt(dur);
        if (isNaN(secs) || secs <= 0) return dur;
        const mins = secs / 60;
        if (mins < 60) {
            return mins + " " + I18n.tr("minutes");
        }
        const hrs = mins / 60;
        if (hrs === 1) return I18n.tr("1 hour");
        return hrs.toFixed(1).replace(".0", "") + " " + I18n.tr("hours");
    }

    function changeDuration(newDuration) {
        if (newDuration === undefined || newDuration === null || newDuration === "undefined" || newDuration === "") return;
        selectedDuration = newDuration;
        if (pluginService) {
            pluginService.savePluginData(pluginId, "selectedDuration", newDuration);
        }

        if (caffeineActive) {
            if (globalIsAutoActive.value) {
                globalIsAutoActive.set(false);
            }
            // Keep active, but update the duration!
            // 1. Kill the old process
            Proc.runCommand("deactivate-caffeine", ["pkill", "-f", "DMS Caffeine"], null, 0);

            // 2. Start the new process with new duration
            const args = [
                "systemd-inhibit", 
                "--what=idle", 
                "--who=DMS Caffeine", 
                "--why=Manual stay awake override"
            ];
            if (newDuration === "infinity") {
                args.push("sleep", "infinity");
            } else {
                args.push("sleep", newDuration);
            }
            Quickshell.execDetached(args);

            // 3. Update timer
            countdownTimer.stop();
            if (newDuration !== "infinity") {
                const durationSecs = parseInt(newDuration);
                globalTimeLeft.set(durationSecs);
                const expiration = Date.now() + durationSecs * 1000;
                if (pluginService) {
                    pluginService.savePluginState(pluginId, "expiration", expiration);
                }
                countdownTimer.restart();
            } else {
                if (pluginService) {
                    pluginService.savePluginState(pluginId, "expiration", 0);
                }
            }

            if (showToasts) {
                ToastService?.showSuccess(I18n.tr("Duration updated: stay awake for ") + formatDurationLabel(newDuration) + ".")
            }

            if (typeof SessionService !== "undefined") {
                SessionService.enableIdleInhibit();
            }
        }
    }

    function deactivateCaffeine(reason) {
        if (!globalIsActive.value) return;

        // Reset activation flags
        globalIsActive.set(false);
        globalIsAutoActive.set(false);

        // Determine if we need to set manual override off flag
        if (reason === "manual-toggle" && globalIsAutoActive.value) {
            globalManualOverrideOff.set(true);
        } else if (reason !== "preserve-override") {
            globalManualOverrideOff.set(false);
        }

        // Stop any running countdown
        countdownTimer.stop();

        // Clear stored expiration state
        if (pluginService) {
            pluginService.savePluginState(pluginId, "expiration", 0);
        }

        // Kill the inhibitor process
        Proc.runCommand("deactivate-caffeine", ["pkill", "-f", "DMS Caffeine"], function(output, exitCode) {
            if (showToasts) {
                if (reason === "battery") {
                    ToastService?.showWarning(
                        I18n.tr("Low Battery"),
                        I18n.tr("Stay awake disabled to save power.")
                    );
                } else if (reason !== "lock" && reason !== "silent") {
                    ToastService?.showInfo(I18n.tr("Screen sleep is now allowed."));
                }
            }
        });

        // Allow the session to sleep again
        if (typeof SessionService !== "undefined") {
            SessionService.disableIdleInhibit();
        }
    }

    function toggleCaffeine(duration) {
        if (batteryIntegrationEnabled && typeof BatteryService !== "undefined" && BatteryService.batteryAvailable && !BatteryService.isCharging && BatteryService.batteryLevel <= batteryLowThreshold) {
            if (!globalIsActive.value) {
                ToastService?.showWarning(
                    I18n.tr("Low Battery"),
                    I18n.tr("Cannot enable stay-awake when battery is low.")
                );
                return;
            }
        }

        let targetDuration = duration !== undefined ? duration : selectedDuration;
        if (targetDuration === undefined || targetDuration === null || targetDuration === "undefined" || targetDuration === "") {
            targetDuration = "infinity";
        }
        if (globalIsActive.value) {
            deactivateCaffeine("manual-toggle");
        } else {
            // Activate
            const args = [
                "systemd-inhibit", 
                "--what=idle", 
                "--who=DMS Caffeine", 
                "--why=Manual stay awake override"
            ];
            if (targetDuration === "infinity") {
                args.push("sleep", "infinity");
            } else {
                args.push("sleep", targetDuration);
            }
            Quickshell.execDetached(args);
            
            if (targetDuration !== "infinity") {
                const durationSecs = parseInt(targetDuration);
                globalTimeLeft.set(durationSecs);
                const expiration = Date.now() + durationSecs * 1000;
                if (pluginService) {
                    pluginService.savePluginState(pluginId, "expiration", expiration);
                }
                countdownTimer.restart();
            } else {
                if (pluginService) {
                    pluginService.savePluginState(pluginId, "expiration", 0);
                }
            }

            globalIsActive.set(true);
            
            if (showToasts) {
                ToastService?.showSuccess(targetDuration === "infinity" ? I18n.tr("Screen will stay awake.") : I18n.tr("Screen will stay awake for ") + formatDurationLabel(targetDuration) + ".")
            }

            if (typeof SessionService !== "undefined") {
                SessionService.enableIdleInhibit();
            }
        }
    }

    function activateCaffeineAuto(targetDuration) {
        if (batteryIntegrationEnabled && typeof BatteryService !== "undefined" && BatteryService.batteryAvailable && !BatteryService.isCharging && BatteryService.batteryLevel <= batteryLowThreshold) {
            return;
        }

        if (globalIsActive.value) return;

        const args = [
            "systemd-inhibit", 
            "--what=idle", 
            "--who=DMS Caffeine Auto", 
            "--why=Automated stay awake override"
        ];
        if (targetDuration === "infinity") {
            args.push("sleep", "infinity");
        } else {
            args.push("sleep", targetDuration);
        }
        Quickshell.execDetached(args);
        
        if (targetDuration !== "infinity") {
            const durationSecs = parseInt(targetDuration);
            globalTimeLeft.set(durationSecs);
            const expiration = Date.now() + durationSecs * 1000;
            if (pluginService) {
                pluginService.savePluginState(pluginId, "expiration", expiration);
            }
            countdownTimer.restart();
        } else {
            if (pluginService) {
                pluginService.savePluginState(pluginId, "expiration", 0);
            }
        }

        globalIsActive.set(true);
        globalIsAutoActive.set(true);
        
        if (showToasts) {
            ToastService?.showSuccess(I18n.tr("Screen will stay awake automatically."))
        }

        if (typeof SessionService !== "undefined") {
            SessionService.enableIdleInhibit();
        }
    }

    function deactivateCaffeineAuto() {
        deactivateCaffeine("auto");
    }

    function checkAutoActivation() {
        let shouldActivate = false;

        // 1. App Automation
        if (appAutomationEnabled) {
            const apps = parsedAutoApps;
            if (apps.length > 0 && typeof ToplevelManager !== "undefined" && ToplevelManager.toplevels?.values) {
                for (const toplevel of ToplevelManager.toplevels.values) {
                    const appId = (toplevel.appId || "").toLowerCase();
                    const title = (toplevel.title || "").toLowerCase();
                    
                    const matches = apps.some(app => {
                        return appId.includes(app) || title.includes(app);
                    });
                    
                    if (matches) {
                        shouldActivate = true;
                        break;
                    }
                }
            }
        }

        // 2. Full Screen Awareness
        if (!shouldActivate && fullscreenAwarenessEnabled) {
            if (typeof ToplevelManager !== "undefined" && ToplevelManager.toplevels?.values) {
                for (const toplevel of ToplevelManager.toplevels.values) {
                    if (toplevel.fullscreen && toplevel.activated) {
                        shouldActivate = true;
                        break;
                    }
                }
            }
        }

        if (shouldActivate) {
            if (!globalIsActive.value) {
                if (!globalManualOverrideOff.value) {
                    activateCaffeineAuto("infinity");
                }
            }
        } else {
            globalManualOverrideOff.set(false);
            if (globalIsAutoActive.value) {
                deactivateCaffeineAuto();
            }
        }
    }

    function checkBatteryStatus() {
        if (!batteryIntegrationEnabled) return;
        if (typeof BatteryService === "undefined" || !BatteryService.batteryAvailable) return;
        
        if (!BatteryService.isCharging && BatteryService.batteryLevel <= batteryLowThreshold) {
            deactivateCaffeine("battery");
        }
    }

    onAppAutomationEnabledChanged: checkAutoActivation()
    onAutoAppsListChanged: checkAutoActivation()
    onFullscreenAwarenessEnabledChanged: checkAutoActivation()
    onBatteryIntegrationEnabledChanged: {
        checkBatteryStatus();
        checkAutoActivation();
    }
    onBatteryLowThresholdChanged: checkBatteryStatus()

    Connections {
        target: (typeof ToplevelManager !== "undefined") ? ToplevelManager : null
        ignoreUnknownSignals: true
        function onActiveToplevelChanged() {
            checkAutoActivation();
        }
    }

    Connections {
        target: (typeof ToplevelManager !== "undefined" && ToplevelManager.toplevels) ? ToplevelManager.toplevels : null
        ignoreUnknownSignals: true
        function onValuesChanged() {
            checkAutoActivation();
        }
    }

    Connections {
        target: (typeof CompositorService !== "undefined") ? CompositorService : null
        ignoreUnknownSignals: true
        function onToplevelsChanged() {
            checkAutoActivation();
        }
    }

    Connections {
        target: (typeof BatteryService !== "undefined") ? BatteryService : null
        ignoreUnknownSignals: true
        function onBatteryLevelChanged() {
            checkBatteryStatus();
        }
        function onIsChargingChanged() {
            checkBatteryStatus();
        }
    }

    Connections {
        target: (typeof SessionService !== "undefined") ? SessionService : null
        ignoreUnknownSignals: true
        function onLockedChanged() {
            if (SessionService.locked && deactivateOnManualLock && globalIsActive.value) {
                deactivateCaffeine("lock");
            }
        }
    }

    Timer {
        id: autoCheckTimer
        interval: 2000
        repeat: true
        running: appAutomationEnabled || fullscreenAwarenessEnabled || batteryIntegrationEnabled
        onTriggered: {
            checkAutoActivation();
            checkBatteryStatus();
        }
    }

    ccDetailContent: Component {
        Rectangle {
            id: detailRoot
            implicitHeight: detailColumn.implicitHeight + Theme.spacingM * 2
            radius: Theme.cornerRadius
            color: Theme.surfaceContainerHigh
            border.width: 0

            Column {
                id: detailColumn
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: Theme.spacingM
                spacing: Theme.spacingS

                Row {
                    width: parent.width
                    spacing: Theme.spacingM
                    bottomPadding: Theme.spacingXS

                    Loader {
                        sourceComponent: animatedCoffeeCup
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Column {
                        width: parent.width - 56 - Theme.spacingM
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2

                        StyledText {
                            text: I18n.tr("Keep Awake Duration")
                            font.pixelSize: Theme.fontSizeLarge
                            color: Theme.surfaceText
                            font.weight: Font.Medium
                        }

                        StyledText {
                            text: {
                                if (!root.caffeineActive) return I18n.tr("Inactive");
                                if (root.selectedDuration === "infinity") return I18n.tr("Active (Indefinite)");
                                const mins = Math.ceil(root.timeLeft / 60);
                                return I18n.tr("Active: %1m remaining").arg(mins);
                            }
                            font.pixelSize: Theme.fontSizeSmall
                            color: root.caffeineActive ? Theme.primary : Theme.surfaceVariantText
                        }
                    }
                }

                Grid {
                    width: parent.width
                    columns: 3
                    spacing: Theme.spacingS

                    Repeater {
                        model: root.durationOptions

                        delegate: Rectangle {
                            required property var modelData
                            required property int index

                            width: (parent.width - Theme.spacingS * 2) / 3
                            height: 48
                            radius: Theme.cornerRadius
                            color: optionMouseArea.containsMouse 
                                ? Theme.surfaceContainerHighest 
                                : (root.selectedDuration === modelData.value ? Theme.withAlpha(Theme.primary, 0.12) : "transparent")
                            border.color: root.selectedDuration === modelData.value ? Theme.primary : Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.2)
                            border.width: root.selectedDuration === modelData.value ? 2 : 1

                            MouseArea {
                                id: optionMouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    const isSelected = String(root.selectedDuration) === String(modelData.value)
                                    if (isSelected) {
                                        root.toggleCaffeine(modelData.value)
                                    } else {
                                        root.changeDuration(modelData.value)
                                    }
                                }
                            }

                            StyledText {
                                text: modelData.label
                                color: root.selectedDuration === modelData.value ? Theme.primary : Theme.surfaceText
                                font.pixelSize: Theme.fontSizeMedium
                                font.weight: root.selectedDuration === modelData.value ? Font.Medium : Font.Normal
                                anchors.centerIn: parent
                            }
                        }
                    }
                }

                Row {
                    width: parent.width
                    spacing: Theme.spacingS
                    topPadding: Theme.spacingXS

                    DankTextField {
                        id: customTimeInputCC
                        width: parent.width - btnSetCC.width - Theme.spacingS
                        height: 36
                        placeholderText: I18n.tr("Custom minutes...")
                        validator: IntValidator { bottom: 1; top: 1440 }
                        
                        onAccepted: btnSetCC.clicked()
                    }

                    DankButton {
                        id: btnSetCC
                        text: I18n.tr("Set")
                        height: 36
                        onClicked: {
                            const mins = parseInt(customTimeInputCC.text.trim());
                            if (!isNaN(mins) && mins > 0) {
                                const value = (mins * 60).toString();
                                root.changeDuration(value);
                                if (!root.caffeineActive) {
                                    root.toggleCaffeine(value);
                                }
                                customTimeInputCC.text = "";
                            }
                        }
                    }
                }
            }
        }
    }
}
