pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Effects
import QtMultimedia
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import qs.Common
import qs.Widgets
import qs.Modules.Plugins
import qs.Services
import "./dms-common"

PluginComponent {
    id: root

    property var popoutService: null
    property bool popoutOpen: false
    
    // Snapshot preview states
    property string previewPath: ""
    property bool isPreviewing: false

    // ── Config properties (reactive: update when settings change) ──
    readonly property int    cfg_popoutScale:   root.pluginData.popoutScale    ?? 100
    readonly property int    cfg_windowScale:   root.pluginData.windowScale    ?? 100
    readonly property string cfg_aspectRatio:   root.pluginData.aspectRatio    ?? "auto"
    readonly property int    cfg_cameraIndex:   parseInt(root.pluginData.cameraIndex ?? "0")
    readonly property real   cfg_zoomFactor:    root.pluginData.zoomFactor     ?? 1.0
    readonly property int    cfg_borderRadius:  root.pluginData.borderRadius   ?? 16
    readonly property bool   cfg_mirror:        root.pluginData.mirror         ?? true
    readonly property bool   cfg_screenFlash:   root.pluginData.screenFlash    ?? true
    readonly property string cfg_filterMode:    root.pluginData.filterMode     ?? "none"
    readonly property real   cfg_filterStrength: (root.pluginData.filterStrength ?? 100) / 100.0
    readonly property real   cfg_smoothing:      (root.pluginData.smoothingAmount ?? 0) / 100.0

    // Aspect ratio calculation
    property real cameraRatio: 4.0 / 3.0
    readonly property real activeRatio: {
        if (root.cfg_aspectRatio === "16:9") return 16.0 / 9.0;
        if (root.cfg_aspectRatio === "4:3") return 4.0 / 3.0;
        if (root.cfg_aspectRatio === "1:1") return 1.0;
        return root.cameraRatio;
    }

    popoutWidth:  Math.round(360 * (root.cfg_popoutScale / 100.0))
    popoutHeight: Math.round(popoutWidth / root.activeRatio) + (root.isPreviewing ? 48 : 0)

    onCfg_popoutScaleChanged: {
        root.popoutWidth = Math.round(360 * (root.cfg_popoutScale / 100.0));
        root.popoutHeight = Math.round(root.popoutWidth / root.activeRatio) + (root.isPreviewing ? 48 : 0);
    }
    
    onActiveRatioChanged: {
        root.popoutHeight = Math.round(root.popoutWidth / root.activeRatio) + (root.isPreviewing ? 48 : 0);
    }

    onIsPreviewingChanged: {
        root.popoutHeight = Math.round(root.popoutWidth / root.activeRatio) + (root.isPreviewing ? 48 : 0);
    }

    // Config path resolution for snapshots directory
    readonly property string cfg_saveDirectory: {
        const dir = root.pluginData.saveDirectory ?? "~/Pictures/Snaps";
        if (dir.startsWith("~/")) {
            return Quickshell.env("HOME") + dir.slice(1);
        }
        return dir;
    }

    // Countdown snapshot timer logic
    property int countdownValue: 0
    property bool isCountingDown: false
    property var onCountdownFinished: null

    Timer {
        id: countdownTimer
        interval: 1000
        repeat: true
        running: false
        onTriggered: {
            root.countdownValue--;
            if (root.countdownValue <= 0) {
                countdownTimer.stop();
                root.isCountingDown = false;
                if (root.onCountdownFinished) {
                    root.onCountdownFinished();
                }
            }
        }
    }

    function startCapture(finishedCallback, delaySec) {
        const delay = delaySec !== undefined ? delaySec : parseInt(root.pluginData.captureDelay ?? "0");
        if (delay > 0) {
            root.countdownValue = delay;
            root.isCountingDown = true;
            root.onCountdownFinished = finishedCallback;
            countdownTimer.start();
        } else {
            finishedCallback();
        }
    }

    IpcHandler {
        target: "handMirror"

        function toggle() : string {
            if (standaloneWindow.visible) {
                standaloneWindow.visible = false;
                return "CLOSED_PINNED";
            }
            root.triggerPopout();
            return "TOGGLED_POPOUT";
        }

        function togglePin() : string {
            if (standaloneWindow.visible) {
                standaloneWindow.visible = false;
                return "UNPINNED";
            } else {
                root.closePopout();
                standaloneWindow.visible = true;
                return "PINNED";
            }
        }
    }

    function toggleFlash() {
        if (root.pluginService) {
            root.pluginService.savePluginData(root.pluginId, "screenFlash", !root.cfg_screenFlash);
        }
    }

    function discardPreview() {
        root.isPreviewing = false;
        // Optional: delete temp file
        if (root.previewPath.startsWith("/tmp/")) {
            Proc.runCommand("cleanup-preview", ["rm", "-f", root.previewPath]);
        }
        root.previewPath = "";
    }

    function copyPreview() {
        if (!root.previewPath) return;
        DMSService.sendRequest("clipboard.copyFile", { "filePath": root.previewPath }, function(response) {
            if (response.error) {
                if (typeof ToastService !== "undefined" && ToastService)
                    ToastService.showError(I18n.tr("Copy Failed"));
            } else {
                if (typeof ToastService !== "undefined" && ToastService)
                    ToastService.showInfo(I18n.tr("Snapshot copied to clipboard."));
                root.isPreviewing = false;
            }
        });
    }

    function savePreview() {
        if (!root.previewPath) return;
        const filename = "Snap_" + new Date().getTime() + ".png";
        const saveDir = root.cfg_saveDirectory;
        const destPath = saveDir + "/" + filename;

        Proc.runCommand("save-snap", ["cp", root.previewPath, destPath], function(stdout, exitCode) {
            if (exitCode === 0) {
                if (typeof ToastService !== "undefined" && ToastService)
                    ToastService.showInfo(I18n.tr("Snapshot saved"));
                root.isPreviewing = false;
            } else {
                if (typeof ToastService !== "undefined" && ToastService)
                    ToastService.showError(I18n.tr("Failed to save snapshot."));
            }
        });
    }

    function performCapture(vOut, instant) {
        if (!vOut) return;
        var doCapture = function() {
            if (root.cfg_screenFlash) {
                screenFlashWindow.startFlash();
            }
            
            const tempPath = "/tmp/hand_mirror_snap_" + Date.now() + ".png";
            const saveDir = root.cfg_saveDirectory;
            
            // Ensure directory exists even for preview (so we can save later)
            Proc.runCommand("mkdir-snaps", ["mkdir", "-p", saveDir], function(stdout, exitCode) {
                vOut.grabToImage(function(result) {
                    result.saveToFile(tempPath);
                    root.previewPath = tempPath;
                    root.isPreviewing = true;
                });
            });
        };
        if (instant) {
            doCapture();
        } else {
            root.startCapture(doCapture);
        }
    }

    // Shared camera components to prevent conflict between popout and standalone window
    MediaDevices {
        id: mediaDevices
    }

    Camera {
        id: camera
        active: root.popoutOpen || standaloneWindow.visible
        cameraDevice: {
            const index = root.cfg_cameraIndex;
            const devices = mediaDevices.videoInputs;
            if (devices && devices.length > index) {
                return devices[index];
            }
            return mediaDevices.defaultVideoInput;
        }
    }

    CaptureSession {
        id: captureSession
        camera: camera
    }

    horizontalBarPill: Component {
        Item {
            implicitWidth: Theme.iconSizeSmall
            implicitHeight: Theme.iconSize
            anchors.verticalCenter: parent.verticalCenter

            DankIcon {
                anchors.centerIn: parent
                name: "photo_camera"
                size: Theme.iconSizeSmall
                color: (root.pluginPopout && root.pluginPopout.shouldBeVisible) ? Theme.primary : Theme.surfaceText
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                cursorShape: Qt.PointingHandCursor
                onClicked: (mouse) => {
                    if (mouse.button === Qt.LeftButton) {
                        root.triggerPopout();
                    } else if (mouse.button === Qt.RightButton) {
                        standaloneWindow.visible = !standaloneWindow.visible;
                    }
                }
            }
        }
    }

    verticalBarPill: Component {
        Item {
            implicitWidth: Theme.iconSize
            implicitHeight: Theme.iconSizeSmall
            anchors.horizontalCenter: parent.horizontalCenter

            DankIcon {
                anchors.centerIn: parent
                name: "photo_camera"
                size: Theme.iconSizeSmall
                color: (root.pluginPopout && root.pluginPopout.shouldBeVisible) ? Theme.primary : Theme.surfaceText
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                cursorShape: Qt.PointingHandCursor
                onClicked: (mouse) => {
                    if (mouse.button === Qt.LeftButton) {
                        root.triggerPopout();
                    } else if (mouse.button === Qt.RightButton) {
                        standaloneWindow.visible = !standaloneWindow.visible;
                    }
                }
            }
        }
    }

    // Shared Camera content component
    Component {
        id: mirrorContentComponent

        Item {
            id: contentItem
            width: parent.width
            height: parent.height

            property bool isStandalone: false
            property alias videoOutput: videoOutput
            signal startMoveRequested()

            // 1. Camera View panel
            StyledRect {
                id: cameraViewPanel
                anchors.fill: parent
                radius: root.cfg_borderRadius
                color: Theme.surfaceContainer
                clip: true

                HoverHandler {
                    id: cameraHoverHandler
                }



                VideoOutput {
                    id: videoOutput
                    width: parent.width * root.cfg_zoomFactor
                    height: parent.height * root.cfg_zoomFactor
                    fillMode: VideoOutput.PreserveAspectCrop
                    
                    Component.onCompleted: {
                        captureSession.videoOutput = videoOutput
                    }
                    Component.onDestruction: {
                        if (captureSession.videoOutput === videoOutput) {
                            captureSession.videoOutput = null
                        }
                    }
                    
                    property real zoomXOffset: 0
                    property real zoomYOffset: 0
                    
                    x: (parent.width - width) / 2 + zoomXOffset
                    y: (parent.height - height) / 2 + zoomYOffset

                    onWidthChanged: clampOffsets()
                    onHeightChanged: clampOffsets()
                    
                    function clampOffsets() {
                        const maxXOffset = Math.max(0, (width - parent.width) / 2);
                        zoomXOffset = Math.max(-maxXOffset, Math.min(maxXOffset, zoomXOffset));
                        
                        const maxYOffset = Math.max(0, (height - parent.height) / 2);
                        zoomYOffset = Math.max(-maxYOffset, Math.min(maxYOffset, zoomYOffset));
                    }
                    
                    onSourceRectChanged: {
                        if (sourceRect.width > 0 && sourceRect.height > 0) {
                            root.cameraRatio = sourceRect.width / sourceRect.height;
                        }
                    }
                    
                    transform: Scale {
                        origin.x: videoOutput.width / 2
                        origin.y: videoOutput.height / 2
                        xScale: root.cfg_mirror ? -1 : 1
                    }

                    layer.enabled: true
                    layer.effect: MultiEffect {
                        maskEnabled: true
                        maskSource: ShaderEffectSource {
                            sourceItem: Rectangle {
                                width: cameraViewPanel.width
                                height: cameraViewPanel.height
                                radius: cameraViewPanel.radius
                            }
                        }
                        
                        saturation: {
                            if (root.cfg_filterMode === "grayscale") return -1.0 * root.cfg_filterStrength;
                            if (root.cfg_filterMode === "sepia") return -0.2 * root.cfg_filterStrength;
                            return 0.0;
                        }
                        contrast: root.cfg_filterMode === "contrast" ? (0.4 * root.cfg_filterStrength) : 0.0
                        brightness: root.cfg_filterMode === "contrast" ? (0.1 * root.cfg_filterStrength) : 0.0
                        colorization: root.cfg_filterMode === "sepia" ? root.cfg_filterStrength : 0.0
                        colorizationColor: "#704214"

                        // Simple denoising via smoothing
                        blurEnabled: root.cfg_smoothing > 0
                        blur: root.cfg_smoothing * 0.5 // Subtle blur to soften noise
                        blurMax: 32
                    }
                }

                // Background MouseArea handling zoom scroll and drag move
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton

                    property real dragStartX: 0
                    property real dragStartY: 0
                    property real initialXOffset: 0
                    property real initialYOffset: 0

                    onWheel: (wheel) => {
                        const delta = wheel.angleDelta.y > 0 ? 0.1 : -0.1;
                        let targetZoom = Math.max(1.0, Math.min(3.0, root.cfg_zoomFactor + delta));
                        targetZoom = Math.round(targetZoom * 10) / 10;
                        if (root.pluginService) {
                            root.pluginService.savePluginData(root.pluginId, "zoomFactor", targetZoom);
                        }
                    }

                    onPressed: (mouse) => {
                        if (contentItem.isStandalone) {
                            if (mouse.button === Qt.RightButton) {
                                dragStartX = mouse.x;
                                dragStartY = mouse.y;
                                initialXOffset = videoOutput.zoomXOffset;
                                initialYOffset = videoOutput.zoomYOffset;
                            } else {
                                // Don't capture drag if near bottom-right resize grip
                                if (mouse.x > parent.width - 24 && mouse.y > parent.height - 24) {
                                    mouse.accepted = false;
                                    return;
                                }
                                contentItem.startMoveRequested();
                            }
                        } else {
                            dragStartX = mouse.x;
                            dragStartY = mouse.y;
                            initialXOffset = videoOutput.zoomXOffset;
                            initialYOffset = videoOutput.zoomYOffset;
                        }
                    }

                    onPositionChanged: (mouse) => {
                        if (pressed && (!contentItem.isStandalone || (contentItem.isStandalone && mouse.buttons & Qt.RightButton))) {
                            const deltaX = mouse.x - dragStartX;
                            const deltaY = mouse.y - dragStartY;
                            
                            const maxXOffset = Math.max(0, (videoOutput.width - parent.width) / 2);
                            const newXOffset = initialXOffset + deltaX;
                            videoOutput.zoomXOffset = Math.max(-maxXOffset, Math.min(maxXOffset, newXOffset));

                            const maxYOffset = Math.max(0, (videoOutput.height - parent.height) / 2);
                            const newYOffset = initialYOffset + deltaY;
                            videoOutput.zoomYOffset = Math.max(-maxYOffset, Math.min(maxYOffset, newYOffset));
                        }
                    }
                }

                // Pin button overlay (top right) - only visible in popout mode
                StyledRect {
                    width: 28
                    height: 28
                    radius: 14
                    color: pinArea.containsMouse ? Qt.rgba(0, 0, 0, 0.8) : Qt.rgba(0, 0, 0, 0.6)
                    border.color: "white"
                    border.width: 1
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.rightMargin: 12
                    anchors.topMargin: 12
                    visible: !contentItem.isStandalone && opacity > 0.0
                    opacity: (!contentItem.isStandalone && cameraHoverHandler.hovered) ? 1.0 : 0.0
                    Behavior on opacity {
                        NumberAnimation { duration: 200 }
                    }

                    DankIcon {
                        anchors.centerIn: parent
                        name: "push_pin"
                        size: 14
                        color: "white"
                    }

                    MouseArea {
                        id: pinArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: parent.color = Qt.rgba(0, 0, 0, 0.8)
                        onExited: parent.color = Qt.rgba(0, 0, 0, 0.6)
                        onClicked: {
                            root.closePopout();
                            standaloneWindow.visible = true;
                        }
                    }
                }

                // Flash toggle button overlay (top right) - only visible in popout mode
                StyledRect {
                    width: 28
                    height: 28
                    radius: 14
                    color: flashArea.containsMouse ? Qt.rgba(0, 0, 0, 0.8) : Qt.rgba(0, 0, 0, 0.6)
                    border.color: "white"
                    border.width: 1
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.rightMargin: 114
                    anchors.topMargin: 12
                    visible: !contentItem.isStandalone && opacity > 0.0
                    opacity: (!contentItem.isStandalone && cameraHoverHandler.hovered) ? 1.0 : 0.0
                    Behavior on opacity {
                        NumberAnimation { duration: 200 }
                    }

                    DankIcon {
                        anchors.centerIn: parent
                        name: root.cfg_screenFlash ? "flash_on" : "offline_bolt"
                        size: 14
                        color: root.cfg_screenFlash ? Theme.primary : "white"
                    }

                    MouseArea {
                        id: flashArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            root.toggleFlash();
                        }
                    }
                }

                // Snapshot button — captures photo with current delay setting
                StyledRect {
                    width: 28
                    height: 28
                    radius: 14
                    color: snapArea.containsMouse ? Qt.rgba(0, 0, 0, 0.8) : Qt.rgba(0, 0, 0, 0.6)
                    border.color: "white"
                    border.width: 1
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.rightMargin: 80
                    anchors.topMargin: 12
                    visible: !contentItem.isStandalone && opacity > 0.0
                    opacity: (!contentItem.isStandalone && cameraHoverHandler.hovered) ? 1.0 : 0.0
                    Behavior on opacity {
                        NumberAnimation { duration: 200 }
                    }

                    DankIcon {
                        anchors.centerIn: parent
                        name: "photo_camera"
                        size: 14
                        color: "white"
                    }

                    MouseArea {
                        id: snapArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: parent.color = Qt.rgba(0, 0, 0, 0.8)
                        onExited: parent.color = Qt.rgba(0, 0, 0, 0.6)
                        onClicked: {
                            root.performCapture(videoOutput);
                        }
                    }
                }

                // Timer button — cycles capture delay on each click
                StyledRect {
                    id: timerBtn
                    width: 32
                    height: 28
                    radius: 14
                    color: timerArea.containsMouse ? Qt.rgba(0, 0, 0, 0.8) : Qt.rgba(0, 0, 0, 0.6)
                    border.color: "white"
                    border.width: 1
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.rightMargin: 46
                    anchors.topMargin: 12
                    visible: !contentItem.isStandalone && opacity > 0.0
                    opacity: (!contentItem.isStandalone && cameraHoverHandler.hovered) ? 1.0 : 0.0
                    Behavior on opacity {
                        NumberAnimation { duration: 200 }
                    }

                    readonly property var delays: ["0s", "3s", "5s", "10s"]
                    property int delayIndex: 0

                    StyledText {
                        text: timerBtn.delays[timerBtn.delayIndex]
                        font.pixelSize: 9
                        font.bold: true
                        color: "white"
                        anchors.centerIn: parent
                    }

                    MouseArea {
                        id: timerArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: parent.color = Qt.rgba(0, 0, 0, 0.8)
                        onExited: parent.color = Qt.rgba(0, 0, 0, 0.6)
                        onClicked: {
                            timerBtn.delayIndex = (timerBtn.delayIndex + 1) % timerBtn.delays.length;
                            root.pluginService.savePluginData(root.pluginId, "captureDelay", timerBtn.delays[timerBtn.delayIndex].replace("s", ""));
                        }
                    }
                }

                // Premium Canvas Resize Grip (bottom right)
                Canvas {
                    id: resizeCanvas
                    width: 12
                    height: 12
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.rightMargin: 6
                    anchors.bottomMargin: 6
                    opacity: cameraHoverHandler.hovered ? 1.0 : 0.0
                    visible: opacity > 0.0
                    Behavior on opacity {
                        NumberAnimation { duration: 200 }
                    }

                    onPaint: {
                        const ctx = getContext("2d");
                        ctx.clearRect(0, 0, width, height);
                        ctx.strokeStyle = Qt.rgba(1, 1, 1, 0.6);
                        ctx.lineWidth = 1.5;
                        ctx.beginPath();
                        ctx.moveTo(12, 0); ctx.lineTo(0, 12);
                        ctx.moveTo(12, 4); ctx.lineTo(4, 12);
                        ctx.moveTo(12, 8); ctx.lineTo(8, 12);
                        ctx.stroke();
                    }

                    MouseArea {
                        id: resizeGrip
                        anchors.fill: parent
                        cursorShape: Qt.SizeFDiagCursor
                        
                        property real startX
                        property real startY
                        property real startWidth

                        onPressed: (mouse) => {
                            startX = mouse.x;
                            startY = mouse.y;
                            startWidth = root.popoutWidth;
                        }

                        onPositionChanged: (mouse) => {
                            if (!pressed) return;
                            const deltaX = mouse.x - startX;
                            const targetWidth = Math.max(180, Math.min(1080, startWidth + deltaX));
                            root.popoutWidth = targetWidth;
                            root.popoutHeight = Math.round(targetWidth / root.activeRatio) + (root.isPreviewing ? 48 : 0);
                        }

                        onReleased: {
                            const targetScale = Math.round((root.popoutWidth / 360.0) * 100);
                            if (root.pluginService) {
                                root.pluginService.savePluginData(root.pluginId, "popoutScale", targetScale);
                            }
                        }
                    }
                }

                // Resize Grip (bottom left)
                Canvas {
                    id: resizeCanvasLeft
                    width: 12
                    height: 12
                    anchors.left: parent.left
                    anchors.bottom: parent.bottom
                    anchors.leftMargin: 6
                    anchors.bottomMargin: 6
                    opacity: cameraHoverHandler.hovered ? 1.0 : 0.0
                    visible: opacity > 0.0
                    Behavior on opacity {
                        NumberAnimation { duration: 200 }
                    }

                    onPaint: {
                        const ctx = getContext("2d");
                        ctx.clearRect(0, 0, width, height);
                        ctx.strokeStyle = Qt.rgba(1, 1, 1, 0.6);
                        ctx.lineWidth = 1.5;
                        ctx.beginPath();
                        ctx.moveTo(0, 0); ctx.lineTo(12, 12);
                        ctx.moveTo(0, 4); ctx.lineTo(8, 12);
                        ctx.moveTo(0, 8); ctx.lineTo(4, 12);
                        ctx.stroke();
                    }

                    MouseArea {
                        id: resizeGripLeft
                        anchors.fill: parent
                        cursorShape: Qt.SizeBDiagCursor
                        
                        property real startX
                        property real startWidth

                        onPressed: (mouse) => {
                            startX = mouse.x;
                            startWidth = root.popoutWidth;
                        }

                        onPositionChanged: (mouse) => {
                            if (!pressed) return;
                            const deltaX = startX - mouse.x; // Left side drag: moving left increases width
                            const targetWidth = Math.max(180, Math.min(1080, startWidth + deltaX));
                            root.popoutWidth = targetWidth;
                            root.popoutHeight = Math.round(targetWidth / root.activeRatio) + (root.isPreviewing ? 48 : 0);
                        }

                        onReleased: {
                            const targetScale = Math.round((root.popoutWidth / 360.0) * 100);
                            if (root.pluginService) {
                                root.pluginService.savePluginData(root.pluginId, "popoutScale", targetScale);
                            }
                        }
                    }
                }

                // Countdown Visual Overlay
                StyledRect {
                    anchors.fill: parent
                    color: Qt.rgba(0, 0, 0, 0.4)
                    visible: root.isCountingDown
                    radius: cameraViewPanel.radius

                    StyledText {
                        anchors.centerIn: parent
                        text: root.countdownValue
                        font.pixelSize: 72
                        font.bold: true
                        color: "white"
                    }
                }

                // 2. Snapshot Preview Overlay
                Rectangle {
                    id: previewOverlay
                    anchors.fill: parent
                    visible: root.isPreviewing
                    radius: cameraViewPanel.radius
                    color: Theme.surfaceContainerHighest
                    z: 500

                    Column {
                        anchors.fill: parent
                        spacing: 0

                        Item {
                            width: parent.width
                            height: parent.height - (root.isPreviewing ? 48 : 0)
                            clip: true

                            Image {
                                id: previewImg
                                anchors.fill: parent
                                source: root.previewPath ? "file://" + root.previewPath : ""
                                fillMode: Image.PreserveAspectFit
                                asynchronous: true
                                
                                // Ensure preview respects mirror setting
                                transform: Scale {
                                    origin.x: previewImg.width / 2
                                    origin.y: previewImg.height / 2
                                    xScale: root.cfg_mirror ? -1 : 1
                                }

                                // Drag & Drop support
                                MouseArea {
                                    id: dragArea
                                    anchors.fill: parent
                                    drag.target: dragDummy
                                }

                                Item {
                                    id: dragDummy
                                    Drag.active: dragArea.drag.active
                                    Drag.keys: ["text/uri-list"]
                                    Drag.mimeData: { "text/uri-list": "file://" + root.previewPath }
                                }
                            }
                        }

                        // Bottom Action Bar
                        Rectangle {
                            width: parent.width
                            height: 48
                            color: Qt.rgba(0, 0, 0, 0.6)
                            
                            Separator { anchors.top: parent.top }

                            Row {
                                anchors.centerIn: parent
                                spacing: Theme.spacingM

                                DankActionButton {
                                    iconName: "close"
                                    iconColor: Theme.error
                                    tooltipText: I18n.tr("Discard")
                                    onClicked: root.discardPreview()
                                }

                                DankActionButton {
                                    iconName: "content_copy"
                                    iconColor: "white"
                                    tooltipText: I18n.tr("Copy to Clipboard")
                                    onClicked: root.copyPreview()
                                }

                                DankActionButton {
                                    iconName: "save"
                                    iconColor: Theme.primary
                                    tooltipText: I18n.tr("Save Image")
                                    onClicked: root.savePreview()
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    popoutContent: Component {
        PopoutComponent {
            id: popoutComp
            headerText: ""
            showCloseButton: false

            Component.onCompleted: {
                root.popoutOpen = true;
            }
            Component.onDestruction: {
                root.popoutOpen = false;
            }

            Item {
                width: parent.width
                height: root.popoutHeight

                Loader {
                    id: popoutLoader
                    anchors.fill: parent
                    sourceComponent: mirrorContentComponent
                    onLoaded: {
                        if (item) item.isStandalone = false;
                    }
                }
            }
        }
    }

    // Pinned Standalone Window
    FloatingWindow {
        id: standaloneWindow
        title: I18n.tr("Hand Mirror")
        implicitWidth: Math.round(360 * (root.cfg_windowScale / 100.0))
        implicitHeight: Math.round(implicitWidth / root.activeRatio)
        color: "transparent"
        visible: false


        // Custom window body
        Item {
            anchors.fill: parent

            HoverHandler {
                id: windowHoverHandler
            }

            Loader {
                id: standaloneLoader
                anchors.fill: parent
                active: standaloneWindow.visible
                sourceComponent: mirrorContentComponent
                onLoaded: {
                    if (item) {
                        item.isStandalone = true;
                        item.startMoveRequested.connect(windowControls.tryStartMove);
                    }
                }
            }

            // Close button (top right of standalone window)
            StyledRect {
                width: 28
                height: 28
                radius: 14
                color: closeArea.containsMouse ? Theme.errorHover : Qt.rgba(0, 0, 0, 0.6)
                border.color: "white"
                border.width: 1
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.rightMargin: 12
                anchors.topMargin: 12
                opacity: windowHoverHandler.hovered ? 1.0 : 0.0
                visible: opacity > 0.0
                Behavior on opacity {
                    NumberAnimation { duration: 200 }
                }

                DankIcon {
                    anchors.centerIn: parent
                    name: "close"
                    size: 14
                    color: "white"
                }

                MouseArea {
                    id: closeArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        standaloneWindow.visible = false;
                    }
                }
            }

            // Unpin button (top right of standalone window, next to close)
            StyledRect {
                width: 28
                height: 28
                radius: 14
                color: unpinArea.containsMouse ? Qt.rgba(0, 0, 0, 0.8) : Qt.rgba(0, 0, 0, 0.6)
                border.color: "white"
                border.width: 1
                anchors.right: parent.right
                anchors.rightMargin: 46
                anchors.top: parent.top
                anchors.topMargin: 12
                opacity: windowHoverHandler.hovered ? 1.0 : 0.0
                visible: opacity > 0.0
                Behavior on opacity {
                    NumberAnimation { duration: 200 }
                }

                DankIcon {
                    anchors.centerIn: parent
                    name: "push_pin"
                    size: 14
                    color: Theme.primary
                }

                MouseArea {
                    id: unpinArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        standaloneWindow.visible = false;
                        root.triggerPopout();
                    }
                }
            }

            // Flash toggle button (standalone window)
            StyledRect {
                width: 28
                height: 28
                radius: 14
                color: flashAreaStandalone.containsMouse ? Qt.rgba(0, 0, 0, 0.8) : Qt.rgba(0, 0, 0, 0.6)
                border.color: "white"
                border.width: 1
                anchors.right: parent.right
                anchors.rightMargin: 80
                anchors.top: parent.top
                anchors.topMargin: 12
                opacity: windowHoverHandler.hovered ? 1.0 : 0.0
                visible: opacity > 0.0
                Behavior on opacity {
                    NumberAnimation { duration: 200 }
                }

                DankIcon {
                    anchors.centerIn: parent
                    name: root.cfg_screenFlash ? "flash_on" : "offline_bolt"
                    size: 14
                    color: root.cfg_screenFlash ? Theme.primary : "white"
                }

                MouseArea {
                    id: flashAreaStandalone
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        root.toggleFlash();
                    }
                }
            }

            // Snapshot button (top right of standalone window, next to flash)
            StyledRect {
                width: 28
                height: 28
                radius: 14
                color: snapAreaStandalone.containsMouse ? Qt.rgba(0, 0, 0, 0.8) : Qt.rgba(0, 0, 0, 0.6)
                border.color: "white"
                border.width: 1
                anchors.right: parent.right
                anchors.rightMargin: 114
                anchors.top: parent.top
                anchors.topMargin: 12
                opacity: windowHoverHandler.hovered ? 1.0 : 0.0
                visible: opacity > 0.0
                Behavior on opacity {
                    NumberAnimation { duration: 200 }
                }

                DankIcon {
                    anchors.centerIn: parent
                    name: "photo_camera"
                    size: 14
                    color: "white"
                }

                MouseArea {
                    id: snapAreaStandalone
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: parent.color = Qt.rgba(0, 0, 0, 0.8)
                    onExited: parent.color = Qt.rgba(0, 0, 0, 0.6)
                    onClicked: {
                        if (standaloneLoader.item) {
                            root.performCapture(standaloneLoader.item.videoOutput);
                        }
                    }
                }
            }
        }

        FloatingWindowControls {
            id: windowControls
            targetWindow: standaloneWindow
        }
    }

    // Fullscreen Screen Border Flash Window
    PanelWindow {
        id: screenFlashWindow
        screen: standaloneWindow.visible ? standaloneWindow.screen : (root.parentScreen || Screen)
        visible: false
        color: "transparent"
        
        WlrLayershell.namespace: "dms:handmirror:flash"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.exclusiveZone: -1
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        
        anchors {
            top: true
            left: true
            right: true
            bottom: true
        }

        function startFlash() {
            borderFlashAnim.start();
        }
        
        Rectangle {
            anchors.fill: parent
            color: "transparent"
            border.color: "white"
            border.width: borderFlashAnim.borderVal
            opacity: borderFlashAnim.opacityVal
        }
        
        SequentialAnimation {
            id: borderFlashAnim
            running: false
            
            property real opacityVal: 0.0
            property real borderVal: 0
            
            ScriptAction {
                script: {
                    screenFlashWindow.visible = true;
                }
            }
            
            ParallelAnimation {
                NumberAnimation { target: borderFlashAnim; property: "opacityVal"; to: 0.95; duration: 50; easing.type: Easing.OutQuad }
                NumberAnimation { target: borderFlashAnim; property: "borderVal"; to: 28; duration: 50; easing.type: Easing.OutQuad }
            }
            
            ParallelAnimation {
                NumberAnimation { target: borderFlashAnim; property: "opacityVal"; to: 0.0; duration: 320; easing.type: Easing.InQuad }
                NumberAnimation { target: borderFlashAnim; property: "borderVal"; to: 0; duration: 320; easing.type: Easing.InQuad }
            }
            
            ScriptAction {
                script: {
                    screenFlashWindow.visible = false;
                }
            }
        }
    }
}
