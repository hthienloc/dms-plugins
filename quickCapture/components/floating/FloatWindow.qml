import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.Common
import qs.Services
import qs.DCommon.Widgets
import "../core/Helpers.js" as Helpers
import "../core/Defaults.js" as Defaults

PanelWindow {
    id: window
    color: "transparent"

    signal closing

    property string imageSource: ""
    property bool isPinned: true
    property var plugin: null
    property var annotationState: null
    property var tempPaths: []

    readonly property var pluginData: plugin?.pluginData ?? ({})
    readonly property int effectiveInitialWidth: Defaults.get(pluginData, "initialWidth")
    readonly property bool autoMinimize: Defaults.get(pluginData, "autoMinimize")
    readonly property int minimizeDelay: Defaults.get(pluginData, "minimizeDelay")
    readonly property int borderWidth: Defaults.get(pluginData, "borderWidth")
    readonly property string borderColor: Defaults.get(pluginData, "borderColor")
    readonly property bool transparentBg: Defaults.get(pluginData, "transparentBg")
    readonly property string spawnPosition: Defaults.get(pluginData, "spawnPosition")
    readonly property int maxHeight: Defaults.get(pluginData, "maxHeight")
    readonly property real edgeSpacing: Defaults.get(pluginData, "edgeSpacing")
    readonly property bool autoTiling: Defaults.get(pluginData, "autoTiling")
    readonly property int minimizedSize: Defaults.get(pluginData, "minimizedSize")
    readonly property int resizeMin: Defaults.get(pluginData, "resizeMin")
    readonly property int resizeMax: Defaults.get(pluginData, "resizeMax")

    onSpawnPositionChanged: updateSize()
    onMaxHeightChanged: updateSize()

    property bool isMinimized: false
    property real targetWidth: effectiveInitialWidth
    property real targetHeight: 1
    property bool imageLoaded: false
    property bool manuallyMoved: false
    property bool isTop: false
    property bool isScaling: false
    property bool temporarilyHidden: false
    property bool dndArmed: false
    property bool isExternalDragging: false
    property bool suppressClick: false
    property point pressPos: Qt.point(0, 0)
    property string portalKey: ""
    property string prevPortalKey: ""
    property bool portalReady: false
    property int dndGeneration: 0
    property int supersededPortalExits: 0
    readonly property int dragThreshold: 6
    readonly property int dragPreviewMaxSize: 256
    readonly property string fileUri: {
        if (!imageSource)
            return "";
        if (imageSource.startsWith("file://"))
            return imageSource;
        const encoded = imageSource.split("/").map(seg => encodeURIComponent(seg)).join("/");
        return "file://" + encoded;
    }
    readonly property string localFilePath: {
        if (!imageSource)
            return "";
        if (!imageSource.startsWith("file://"))
            return imageSource;
        const raw = imageSource.slice(7);
        try {
            return decodeURIComponent(raw);
        } catch (e) {
            return raw;
        }
    }
    visible: !temporarilyHidden

    onTargetWidthChanged: if (!manuallyMoved)
        updatePosition()
    onTargetHeightChanged: if (!manuallyMoved)
        updatePosition()

    property int xPos: 400
    property int yPos: 400

    anchors {
        top: true
        left: true
    }
    WlrLayershell.namespace: "dms-quick-capture-float"
    WlrLayershell.layer: {
        if (window.isPinned) {
            return isTop ? WlrLayershell.Overlay : WlrLayershell.Top;
        }
        return isTop ? WlrLayershell.Bottom : WlrLayershell.Background;
    }
    WlrLayershell.exclusiveZone: -1
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    WlrLayershell.margins {
        left: xPos
        top: yPos
    }

    Timer {
        id: scaleTimer
        interval: 200
        repeat: false
        onTriggered: window.isScaling = false
    }

    Behavior on targetWidth {
        enabled: window.isScaling
        NumberAnimation {
            duration: 150
            easing.type: Easing.OutCubic
        }
    }
    Behavior on targetHeight {
        enabled: window.isScaling
        NumberAnimation {
            duration: 150
            easing.type: Easing.OutCubic
        }
    }
    Behavior on xPos {
        enabled: window.isScaling
        NumberAnimation {
            duration: 150
            easing.type: Easing.OutCubic
        }
    }
    Behavior on yPos {
        enabled: window.isScaling
        NumberAnimation {
            duration: 150
            easing.type: Easing.OutCubic
        }
    }

    implicitWidth: isMinimized ? minimizedSize : targetWidth
    implicitHeight: isMinimized ? minimizedSize : targetHeight

    Timer {
        id: minimizeTimer
        interval: window.minimizeDelay
        repeat: false
        onTriggered: window.isMinimized = true
    }

    Component.onCompleted: {
        if (window.autoMinimize) {
            minimizeTimer.start();
        }
        updatePosition();
    }

    Connections {
        target: SettingsData
        function onBarConfigsChanged() {
            updatePosition();
        }
        function onDockEnabledChanged() {
            updatePosition();
        }
        function onDockPositionChanged() {
            updatePosition();
        }
    }

    function getWorkArea() {
        let area = {
            x: 0,
            y: 0,
            width: window.screen.width,
            height: window.screen.height
        };

        if (SettingsData.barConfigs) {
            SettingsData.barConfigs.forEach(cfg => {
                if (!cfg.enabled || !cfg.visible)
                    return;

                let onThisScreen = false;
                if (!cfg.screenPreferences || cfg.screenPreferences.includes("all")) {
                    onThisScreen = true;
                } else {
                    onThisScreen = cfg.screenPreferences.includes(window.screen.name);
                }

                if (!onThisScreen)
                    return;

                const innerPadding = cfg.innerPadding ?? 4;
                const spacing = cfg.spacing ?? 4;
                const bottomGap = Theme.isConnectedEffect ? 0 : (cfg.bottomGap ?? 0);

                let thickness = 0;
                if (SettingsData.frameEnabled) {
                    thickness = SettingsData.frameBarSize;
                } else {
                    const widgetThickness = Math.max(20, 26 + innerPadding * 0.6);
                    const barHeight = Theme.barHeight;
                    const effectiveBarThickness = Math.max(widgetThickness + innerPadding + 4, barHeight - 4 - (8 - innerPadding));
                    thickness = effectiveBarThickness + spacing + bottomGap;
                }

                switch (cfg.position) {
                case 0:
                    area.y += thickness;
                    area.height -= thickness;
                    break;
                case 1:
                    area.height -= thickness;
                    break;
                case 2:
                    area.x += thickness;
                    area.width -= thickness;
                    break;
                case 3:
                    area.width -= thickness;
                    break;
                }
            });
        }

        if (SettingsData.dockEnabled) {
            if (window.screen === Quickshell.screens[0]) {
                const iconSize = SettingsData.dockIconSize ?? 40;
                const spacing = SettingsData.dockSpacing ?? 4;
                const borderThickness = SettingsData.dockBorderEnabled ? (SettingsData.dockBorderThickness ?? 1) : 0;
                const bodyThickness = iconSize + spacing * 2 + borderThickness * 2;

                const reserveOffset = SettingsData.dockBottomGap ?? 0;
                const effectiveMargin = Theme.isConnectedEffect ? 0 : (SettingsData.dockMargin ?? 0);

                const dockThickness = bodyThickness + reserveOffset + effectiveMargin + 8;

                switch (SettingsData.dockPosition) {
                case 0:
                    area.y += dockThickness;
                    area.height -= dockThickness;
                    break;
                case 1:
                    area.height -= dockThickness;
                    break;
                case 2:
                    area.x += dockThickness;
                    area.width -= dockThickness;
                    break;
                case 3:
                    area.width -= dockThickness;
                    break;
                }
            }
        }

        return area;
    }

    function yPosForPosition(pos, winHeight, workArea) {
        switch (pos) {
        case "top":
        case "top-left":
        case "top-right":
            return workArea.y + edgeSpacing;
        case "bottom":
        case "bottom-left":
        case "bottom-right":
            return workArea.y + workArea.height - winHeight - edgeSpacing;
        default:
            return workArea.y + (workArea.height - winHeight) / 2;
        }
    }

    function xPosForPosition(pos, winWidth, workArea) {
        switch (pos) {
        case "left":
        case "top-left":
        case "bottom-left":
            return workArea.x + edgeSpacing;
        case "right":
        case "top-right":
        case "bottom-right":
            return workArea.x + workArea.width - winWidth - edgeSpacing;
        default:
            return workArea.x + (workArea.width - winWidth) / 2;
        }
    }

    function close() {
        opacityToClose.start();
    }

    function updatePosition() {
        let workArea = getWorkArea();
        let newX = xPosForPosition(spawnPosition, targetWidth, workArea);
        let newY = yPosForPosition(spawnPosition, targetHeight, workArea);

        if (autoTiling && !manuallyMoved && plugin && plugin.openWindows) {
            let currentWindows = plugin.openWindows;
            let attempts = 0;
            let maxAttempts = 50;

            let overlapping = true;
            while (overlapping && attempts < maxAttempts) {
                overlapping = false;
                for (let i = 0; i < currentWindows.length; i++) {
                    let other = currentWindows[i];
                    if (!other || other === window || other.isMinimized)
                        continue;

                    let ox = other.xPos;
                    let oy = other.yPos;
                    let ow = other.targetWidth;
                    let oh = other.targetHeight;

                    let isOverlapping = !(newX + targetWidth + edgeSpacing <= ox || newX >= ox + ow + edgeSpacing || newY + targetHeight + edgeSpacing <= oy || newY >= oy + oh + edgeSpacing);

                    if (isOverlapping) {
                        // Vertical stacking direction depends on whether we started at top or bottom
                        if (spawnPosition.includes("bottom")) {
                            newY = oy - targetHeight - edgeSpacing;

                            if (newY < workArea.y + edgeSpacing) {
                                newY = yPosForPosition(spawnPosition, targetHeight, workArea);
                                if (spawnPosition.includes("right"))
                                    newX = ox - targetWidth - edgeSpacing;
                                else
                                    newX = ox + ow + edgeSpacing;
                            }
                        } else {
                            newY = oy + oh + edgeSpacing;

                            if (newY + targetHeight > workArea.y + workArea.height - edgeSpacing) {
                                newY = yPosForPosition(spawnPosition, targetHeight, workArea);
                                if (spawnPosition.includes("right"))
                                    newX = ox - targetWidth - edgeSpacing;
                                else
                                    newX = ox + ow + edgeSpacing;
                            }
                        }
                        overlapping = true;
                        break;
                    }
                }
                attempts++;
            }
        }

        if (window.isMinimized) {
            let centerX = newX + targetWidth / 2;
            let centerY = newY + targetHeight / 2;
            if (centerX > window.screen.width / 2)
                newX += (targetWidth - minimizedSize);
            if (centerY > window.screen.height / 2)
                newY += (targetHeight - minimizedSize);
        }

        newX = Helpers.clamp(newX, workArea.x + edgeSpacing, workArea.x + workArea.width - targetWidth - edgeSpacing);
        newY = Helpers.clamp(newY, workArea.y + edgeSpacing, workArea.y + workArea.height - targetHeight - edgeSpacing);

        xPos = newX;
        yPos = newY;
    }

    function updateSize() {
        if (img.status !== Image.Ready)
            return;

        let iw = img.implicitWidth;
        let ih = img.implicitHeight;
        if (iw <= 0 || ih <= 0)
            return;

        let ratio = iw / ih;
        let b = window.borderWidth;

        let w = effectiveInitialWidth;
        let h = ((w - 2 * b) / ratio) + 2 * b;

        if (maxHeight > 0 && h > maxHeight) {
            h = maxHeight;
            w = (h - 2 * b) * ratio + 2 * b;
        }

        targetWidth = Math.round(w);
        targetHeight = Math.round(h);

        if (!manuallyMoved) {
            updatePosition();
        }
    }

    Item {
        id: dragTarget
        x: window.xPos
        y: window.yPos
        onXChanged: {
            if (dragArea.drag.active) {
                window.xPos = x;
                window.manuallyMoved = true;
            }
        }
        onYChanged: {
            if (dragArea.drag.active) {
                window.yPos = y;
                window.manuallyMoved = true;
            }
        }
    }

    StyledRect {
        id: container
        anchors.fill: parent
        radius: Theme.cornerRadius
        color: window.transparentBg ? "transparent" : Theme.surfaceContainer
        border.color: {
            if (window.dndArmed || window.isExternalDragging)
                return Theme.primary;
            switch (window.borderColor) {
            case "primary":
                return Theme.primary;
            case "surfaceContainerHighest":
                return Theme.surfaceContainerHighest;
            case "transparent":
                return "transparent";
            default:
                return Theme.outlineVariant;
            }
        }
        border.width: (window.dndArmed || window.isExternalDragging) ? Math.max(2, window.borderWidth) : window.borderWidth
        clip: true
        antialiasing: true

        SequentialAnimation {
            id: opacityToClose
            NumberAnimation {
                target: container
                property: "opacity"
                to: 0
                duration: 150
                easing.type: Easing.OutCubic
            }
            ScriptAction {
                script: {
                    window.closing();
                    window.destroy();
                }
            }
        }

        AnimatedImage {
            id: img
            source: window.imageSource
            anchors.fill: parent
            anchors.margins: window.borderWidth
            fillMode: Image.PreserveAspectFit
            paused: window.isMinimized
            antialiasing: true
            smooth: true
            opacity: window.imageLoaded ? 1 : 0
            visible: opacity > 0

            layer.enabled: true
            layer.effect: MultiEffect {
                maskEnabled: true
                maskSource: imgMask
            }

            onStatusChanged: {
                if (status === AnimatedImage.Ready) {
                    updateSize();
                    window.imageLoaded = true;
                } else if (status === AnimatedImage.Error) {
                    ToastService.showError(I18n.trFor("quickCapture", "Failed to load image: %1").arg(window.imageSource));
                    window.closing();
                    window.destroy();
                }
            }
        }

        Rectangle {
            id: imgMask
            anchors.fill: img
            radius: Math.max(0, Theme.cornerRadius - window.borderWidth)
            visible: false
            antialiasing: true
            layer.enabled: true
        }

        DIcon {
            id: cloudIcon
            name: "cloud"
            anchors.centerIn: parent
            size: Theme.iconSizeSmall
            color: Theme.onPrimary
            opacity: 0
            visible: opacity > 0
        }

        Item {
            id: dndDummy
            x: 0
            y: 0
            width: parent.width
            height: parent.height
            Drag.active: window.dndArmed && dragArea.drag.active && window.portalReady
            Drag.dragType: Drag.Automatic
            Drag.supportedActions: Qt.CopyAction
            Drag.keys: window.portalKey ? ["text/uri-list", "application/vnd.portal.filetransfer"] : ["text/uri-list"]
            Drag.mimeData: {
                if (!window.fileUri)
                    return ({});
                const data = {
                    "text/uri-list": window.fileUri + "\r\n",
                    "x-special/gnome-copied-files": "copy\n" + window.fileUri + "\n"
                };
                if (window.portalKey)
                    data["application/vnd.portal.filetransfer"] = window.portalKey;
                return data;
            }
            Drag.imageSource: window.imageSource
            Drag.imageSourceSize: Qt.size(Math.min(window.dragPreviewMaxSize, Math.max(64, Math.round(window.targetWidth))), Math.min(window.dragPreviewMaxSize, Math.max(64, Math.round(window.targetHeight))))
            Drag.hotSpot: Qt.point(Math.min(window.dragPreviewMaxSize / 2, window.pressPos.x), Math.min(window.dragPreviewMaxSize / 2, window.pressPos.y))
            Drag.onDragStarted: {
                window.isExternalDragging = true;
                if (window.portalKey)
                    window.prevPortalKey = window.portalKey;
            }
            Drag.onDragFinished: {
                window.isExternalDragging = false;
                window.dndArmed = false;
                dndDummy.x = 0;
                dndDummy.y = 0;
                portalCleanupTimer.restart();
                if (window.autoMinimize && !dragArea.containsMouse) {
                    minimizeTimer.restart();
                }
            }
        }

        Rectangle {
            id: dndBadge
            visible: !window.isMinimized && (window.dndArmed || window.isExternalDragging)
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.margins: window.borderWidth + Theme.spacingXS
            width: dndBadgeIcon.width + Theme.spacingS * 2
            height: dndBadgeIcon.height + Theme.spacingXS * 2
            radius: Theme.cornerRadius
            color: Theme.primary
            opacity: 0.92
            z: 2

            DIcon {
                id: dndBadgeIcon
                name: "drag_indicator"
                anchors.centerIn: parent
                size: Theme.iconSizeSmall
                color: Theme.onPrimary
            }
        }

        Process {
            id: portalProcess
            running: false
            stdout: SplitParser {
                onRead: line => {
                    const key = (line || "").trim();
                    if (key) {
                        window.portalKey = key;
                    }
                    window.portalReady = true;
                }
            }
            onExited: exitCode => {
                if (window.supersededPortalExits > 0) {
                    window.supersededPortalExits--;
                    return;
                }
                if (!window.portalReady) {
                    window.portalReady = true;
                }
            }
        }

        Timer {
            id: portalCleanupTimer
            interval: 5000
            repeat: false
            onTriggered: {
                if (!window.isExternalDragging && !window.dndArmed) {
                    container.stopPortalTransfer();
                }
            }
        }

        function stopPortalTransfer() {
            portalCleanupTimer.stop();
            if (portalProcess.running) {
                window.supersededPortalExits++;
                portalProcess.running = false;
            }
        }

        function startPortalTransfer() {
            stopPortalTransfer();
            window.portalKey = "";
            window.portalReady = false;
            ++window.dndGeneration;
            if (!window.localFilePath) {
                window.portalReady = true;
                return;
            }
            const scriptPath = Qt.resolvedUrl("../../scripts/portal_transfer.py").toString().replace(/^file:\/\//, "");
            const args = window.prevPortalKey ? ["python3", scriptPath, window.localFilePath, window.prevPortalKey] : ["python3", scriptPath, window.localFilePath];
            portalProcess.command = args;
            portalProcess.running = true;
        }

        Timer {
            id: holdDndTimer
            interval: 350
            repeat: false
            onTriggered: {
                if (dragArea.pressedButtons & Qt.LeftButton && !dragArea.drag.active && !window.isMinimized && window.fileUri) {
                    window.dndArmed = true;
                    window.suppressClick = true;
                    minimizeTimer.stop();
                }
            }
        }

        PinchHandler {
            id: pinchHandler
            target: null
            property real startWidth: 400
            onActiveChanged: {
                if (active)
                    startWidth = window.targetWidth;
            }
            onScaleChanged: {
                if (img.implicitWidth <= 0 || img.implicitHeight <= 0)
                    return;
                let b = window.borderWidth;
                let ratio = img.implicitWidth / img.implicitHeight;
                let newWidth = Helpers.clamp(startWidth * scale, window.resizeMin, window.resizeMax);
                let newHeight = ((newWidth - 2 * b) / ratio) + 2 * b;

                window.targetWidth = Math.round(newWidth);
                window.targetHeight = Math.round(newHeight);
            }
        }

        MouseArea {
            id: dragArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: (window.dndArmed || window.isExternalDragging) ? Qt.DragCopyCursor : Qt.SizeAllCursor
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

            drag.target: (window.dndArmed || window.isExternalDragging) ? dndDummy : dragTarget
            drag.axis: Drag.XAndYAxis
            drag.threshold: window.dragThreshold

            onEntered: {
                minimizeTimer.stop();
                window.isMinimized = false;
            }

            onExited: {
                if (window.autoMinimize && !drag.active && !window.dndArmed && !window.isExternalDragging) {
                    minimizeTimer.restart();
                }
            }

            onPressed: function (mouse) {
                if (window.plugin && typeof window.plugin.raiseWindow === "function") {
                    window.plugin.raiseWindow(window);
                }
                if (mouse.button === Qt.LeftButton) {
                    window.pressPos = Qt.point(mouse.x, mouse.y);
                    window.dndArmed = false;
                    window.suppressClick = false;
                    if (!window.isMinimized && window.fileUri) {
                        container.startPortalTransfer();
                        holdDndTimer.restart();
                    }
                } else if (mouse.button === Qt.RightButton) {
                    holdDndTimer.stop();
                    window.isMinimized = !window.isMinimized;
                } else if (mouse.button === Qt.MiddleButton) {
                    holdDndTimer.stop();
                    opacityToClose.start();
                }
            }

            onPositionChanged: function (mouse) {
                if (!(mouse.buttons & Qt.LeftButton))
                    return;

                const dist = Math.hypot(mouse.x - window.pressPos.x, mouse.y - window.pressPos.y);
                if (!window.dndArmed && !window.isExternalDragging && holdDndTimer.running && dist > window.dragThreshold) {
                    holdDndTimer.stop();
                }
            }

            onReleased: function (mouse) {
                if (mouse.button === Qt.LeftButton) {
                    const wasExternalDragging = window.isExternalDragging;
                    holdDndTimer.stop();
                    window.isExternalDragging = false;
                    window.dndArmed = false;
                    dndDummy.x = 0;
                    dndDummy.y = 0;
                    if (!wasExternalDragging) {
                        container.stopPortalTransfer();
                    }
                }
            }

            onCanceled: {
                const wasExternalDragging = window.isExternalDragging;
                holdDndTimer.stop();
                window.isExternalDragging = false;
                window.dndArmed = false;
                window.suppressClick = false;
                dndDummy.x = 0;
                dndDummy.y = 0;
                if (!wasExternalDragging) {
                    container.stopPortalTransfer();
                }
            }

            onClicked: function (mouse) {
                if (mouse.button === Qt.LeftButton) {
                    if (window.suppressClick) {
                        window.suppressClick = false;
                        return;
                    }
                    if (window.plugin && typeof window.plugin.requestRestore === "function") {
                        window.plugin.requestRestore(window.imageSource);
                    }
                    window.close();
                }
            }

            onWheel: wheel => {
                if (window.isMinimized || img.implicitWidth <= 0 || img.implicitHeight <= 0)
                    return;

                window.isScaling = true;
                scaleTimer.restart();

                let scaleFactor = Math.pow(1.1, wheel.angleDelta.y / 120.0);
                let oldWidth = window.targetWidth;
                let oldHeight = window.targetHeight;
                let b = window.borderWidth;
                let ratio = img.implicitWidth / img.implicitHeight;
                let newWidth = Math.round(Helpers.clamp(oldWidth * scaleFactor, window.resizeMin, window.resizeMax));
                let newHeight = Math.round(((newWidth - 2 * b) / ratio) + 2 * b);

                let centerX = window.xPos + oldWidth / 2;
                let centerY = window.yPos + oldHeight / 2;
                let screenWidth = window.screen.width;
                let screenHeight = window.screen.height;

                if (centerX > screenWidth / 2) {
                    window.xPos -= (newWidth - oldWidth);
                }

                if (centerY > screenHeight / 2) {
                    window.yPos -= (newHeight - oldHeight);
                }

                window.targetWidth = newWidth;
                window.targetHeight = newHeight;
                window.manuallyMoved = true;
            }
        }

        states: [
            State {
                name: "minimized"
                when: window.isMinimized
                PropertyChanges {
                    container.radius: minimizedSize / 2
                    container.color: Theme.primary
                    container.border.width: 0
                    container.opacity: 0.5
                    img.opacity: 0
                    cloudIcon.opacity: 1
                }
            }
        ]

        transitions: [
            Transition {
                from: ""
                to: "minimized"
                SequentialAnimation {
                    NumberAnimation {
                        target: container
                        property: "opacity"
                        to: 0
                        duration: 70
                        easing.type: Easing.OutQuad
                    }
                    ScriptAction {
                        script: {
                            let oldWidth = window.targetWidth;
                            let oldHeight = window.targetHeight;
                            let centerX = window.xPos + oldWidth / 2;
                            let centerY = window.yPos + oldHeight / 2;
                            let screenWidth = window.screen.width;
                            let screenHeight = window.screen.height;

                            if (centerX > screenWidth / 2)
                                window.xPos += (oldWidth - minimizedSize);
                            if (centerY > screenHeight / 2)
                                window.yPos += (oldHeight - minimizedSize);
                        }
                    }
                    PropertyAction {
                        target: container
                        properties: "radius,color,border.width"
                    }
                    PropertyAction {
                        targets: [img, cloudIcon]
                        properties: "opacity"
                    }
                    NumberAnimation {
                        target: container
                        property: "opacity"
                        from: 0
                        to: 0.5
                        duration: 80
                        easing.type: Easing.InQuad
                    }
                }
            },
            Transition {
                from: "minimized"
                to: ""
                SequentialAnimation {
                    NumberAnimation {
                        target: container
                        property: "opacity"
                        to: 0
                        duration: 70
                        easing.type: Easing.OutQuad
                    }
                    ScriptAction {
                        script: {
                            let oldWidth = window.targetWidth;
                            let oldHeight = window.targetHeight;
                            let centerX = window.xPos + minimizedSize / 2;
                            let centerY = window.yPos + minimizedSize / 2;
                            let screenWidth = window.screen.width;
                            let screenHeight = window.screen.height;

                            if (centerX > screenWidth / 2)
                                window.xPos -= (oldWidth - minimizedSize);
                            if (centerY > screenHeight / 2)
                                window.yPos -= (oldHeight - minimizedSize);
                        }
                    }
                    PropertyAction {
                        target: container
                        properties: "radius,color,border.width"
                    }
                    PropertyAction {
                        targets: [img, cloudIcon]
                        properties: "opacity"
                    }
                    NumberAnimation {
                        target: container
                        property: "opacity"
                        from: 0
                        to: 1
                        duration: 80
                        easing.type: Easing.InQuad
                    }
                }
            }
        ]
    }
}
