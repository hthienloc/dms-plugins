import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Modules.Plugins
import qs.Services
import qs.Modals.Common
import qs.Modals.FileBrowser
import "./components/bar"
import "./components/core"
import "./components/floating"
import "./components/history"
import "./components/recording"
import "./components/core/Defaults.js" as Defaults

PluginComponent {
    id: root

    pluginId: "quickCapture"
    pluginService: PluginService

    readonly property alias recordingController: recorder
    readonly property alias actions: captureActions
    readonly property bool isRecording: recorder.isRecording
    readonly property bool isAnnotating: modal.shouldBeVisible
    readonly property bool isMenuOpen: menuModal.shouldBeVisible
    readonly property var allowedModes: ["region", "window", "full", "output", "all", "last", "scroll"]
    readonly property int captureTimeoutMs: 60000
    readonly property int scrollCaptureTimeoutMs: 120000

    readonly property bool hasBarWidget: {
        const bars = SettingsData.barConfigs || [];
        const sections = ["leftWidgets", "centerWidgets", "rightWidgets"];
        return bars.some(bar => (bar.enabled ?? true) && sections.some(sec => (bar[sec] || []).some(w => typeof w === "string" ? w === "quickCapture" : (w && w.id === "quickCapture" && w.enabled !== false))));
    }
    readonly property bool hasCcWidget: {
        const ccWidgets = SettingsData.controlCenterWidgets || [];
        return ccWidgets.some(w => w && w.id === "quickCapture" && w.enabled !== false);
    }
    readonly property bool hasSurfaceWidget: hasBarWidget || hasCcWidget

    property string widgetMode: "photo"
    property bool isCapturing: false
    property bool isDownloading: false
    property bool hideControlCenter: Defaults.get(pluginData, "defaultHideControlCenter")
    property var outputs: []
    property string currentCapturePath: ""

    property string pendingCaptureAction: "edit"
    property string pendingCaptureMode: ""
    property string pendingOutputName: ""
    property bool pendingFromControlCenter: false

    function savePluginData(key, value) {
        pluginService.savePluginData(pluginId, key, value);
    }

    function refreshAudioDevices() {
        recorder.refreshAudioDevices();
    }

    function refreshOutputs(callback) {
        Proc.runCommand("quickCapture.listOutputs", [Proc.dmsBin, "screenshot", "list"], (stdout, exitCode) => {
            const list = [];
            for (const line of (stdout || "").trim().split("\n")) {
                const m = line.match(/^([^:]+):\s+(\d+)x(\d+)/);
                if (!m)
                    continue;
                list.push({
                    name: m[1].trim(),
                    width: parseInt(m[2], 10),
                    height: parseInt(m[3], 10)
                });
            }
            root.outputs = list;
            if (callback)
                callback(list);
        });
    }

    function capture(mode, action, outputName, fromControlCenter) {
        switch (mode) {
        case "clipboard":
            fromClipboard(action, fromControlCenter);
            return;
        case "selectFile":
            selectImage(action, fromControlCenter);
            return;
        default:
            triggerCapture(mode, action, outputName, fromControlCenter);
        }
    }

    function record(mode, geometry, fromControlCenter) {
        if (fromControlCenter && root.hideControlCenter) {
            closeControlCenter();
            Qt.callLater(() => recorder.startRecording(mode || "screen", geometry || ""));
            return;
        }
        recorder.startRecording(mode || "screen", geometry || "");
    }

    function openFolder(kind) {
        const key = kind === "video" ? "recordingDirectory" : "saveDirectory";
        Proc.runCommand("quickCapture.openFolder", ["xdg-open", Paths.expandTilde(String(Defaults.get(pluginData, key)))]);
    }

    function toggleHideControlCenter() {
        root.hideControlCenter = !root.hideControlCenter;
    }

    function closeControlCenter() {
        PopoutService.closeIslandActivity("controlcenter");
        const cc = PopoutService.controlCenterPopout;
        if (cc && typeof cc.instantClose === "function") {
            cc.instantClose();
        } else {
            PopoutService.closeControlCenter();
        }
    }

    function capturePath() {
        return "/tmp/dms_capture_" + Date.now() + ".png";
    }

    function modeFlags(mode) {
        const flags = [];
        if (mode === "region" && Defaults.get(pluginData, "skipConfirm"))
            flags.push("--no-confirm");
        if (mode === "scroll")
            flags.push("--interval", String(parseInt(Defaults.get(pluginData, "scrollInterval"), 10) || Defaults.values.scrollInterval));
        if (mode === "output")
            flags.push("--output", root.pendingOutputName || Defaults.get(pluginData, "outputTargetName") || "DP-1");
        if (Defaults.get(pluginData, "resetLastRegion"))
            flags.push("--reset");
        const hudScale = Defaults.get(pluginData, "regionHudScale");
        if (hudScale && hudScale !== "auto")
            flags.push("--hud", hudScale);
        return flags;
    }

    function screenshotArgs(mode, filename) {
        const cursor = Defaults.get(pluginData, "includeCursor") ? "on" : "off";
        return [Proc.dmsBin, "screenshot", mode, "--no-clipboard", "--dir", "/tmp", "--filename", filename, "--format", "png", "--cursor", cursor, "--no-notify", "--json"].concat(modeFlags(mode));
    }

    function triggerCapture(mode, action, outputName, fromControlCenter) {
        const finalMode = mode || Defaults.get(pluginData, "middleClickAction");
        if (!root.allowedModes.includes(finalMode)) {
            console.warn("quickCapture: rejected screenshot mode", finalMode);
            return;
        }
        if (root.isCapturing || modal.shouldBeVisible)
            return;

        root.isCapturing = true;
        root.pendingCaptureAction = action || "edit";
        root.pendingCaptureMode = finalMode;
        root.pendingOutputName = outputName || "";
        root.pendingFromControlCenter = !!fromControlCenter;

        if (fromControlCenter && root.hideControlCenter) {
            closeControlCenter();
            Qt.callLater(startActualCapture);
            return;
        }
        startActualCapture();
    }

    function startActualCapture() {
        const mode = root.pendingCaptureMode;
        const action = root.pendingCaptureAction;
        const timeout = mode === "scroll" ? root.scrollCaptureTimeoutMs : root.captureTimeoutMs;

        root.currentCapturePath = capturePath();
        const filename = root.currentCapturePath.split("/").pop();
        Proc.runCommand("quickCapture.screenshot", screenshotArgs(mode, filename), (stdout, exitCode) => {
            root.isCapturing = false;
            root.pendingCaptureMode = "";
            root.pendingCaptureAction = "edit";
            root.pendingOutputName = "";
            const fallback = I18n.trFor("quickCapture", "Screenshot failed (mode: %1).").arg(mode);
            let meta = null;
            try {
                meta = JSON.parse((stdout || "").trim());
            } catch (e) {
                root.pendingFromControlCenter = false;
                captureActions.notifyError((stdout && stdout.trim()) || fallback);
                return;
            }
            if (meta.status === "success") {
                root.currentCapturePath = meta.path;
                openCaptured(meta.path, action, meta.width, meta.height);
                return;
            }
            root.pendingFromControlCenter = false;
            if (meta.status !== "aborted")
                captureActions.notifyError(meta.message || meta.error || fallback);
        }, 0, timeout);
    }

    function selectImage(action, fromControlCenter) {
        if (fromControlCenter && root.hideControlCenter)
            closeControlCenter();
        fileBrowserModal.captureAction = action || "edit";
        fileBrowserModal.open();
    }

    function fromClipboard(action, fromControlCenter) {
        if (fromControlCenter && root.hideControlCenter)
            closeControlCenter();
        const destPath = capturePath();
        root.currentCapturePath = destPath;
        Proc.runCommand("quickCapture.clipboardPasteFile", ["sh", "-c", '"$1" cl paste > "$2" 2>/dev/null', "_", Proc.dmsBin, destPath], (stdout, exitCode) => {
            if (exitCode !== 0) {
                tryClipboardAsText(action);
                return;
            }
            Proc.runCommand("quickCapture.clipboardCheckImage", ["file", "-b", destPath], (fileOut, fileExit) => {
                if (fileExit === 0 && fileOut.toLowerCase().includes("image")) {
                    validateAndOpen(destPath, action);
                    return;
                }
                tryClipboardAsText(action);
            });
        });
    }

    function tryClipboardAsText(action) {
        Proc.runCommand("quickCapture.clipboardPasteText", [Proc.dmsBin, "cl", "paste"], (stdout, exitCode) => {
            const text = (stdout || "").trim();
            if (exitCode !== 0 || text === "") {
                captureActions.notifyWarning(I18n.trFor("quickCapture", "No valid image, URL, or path in clipboard."));
                return;
            }
            loadImageFromUri(text, action);
        });
    }

    function openCaptured(path, action, width, height) {
        const minSize = Defaults.get(pluginData, "minImageSize");
        if (width < minSize || height < minSize) {
            root.pendingFromControlCenter = false;
            captureActions.notifyWarning(I18n.trFor("quickCapture", "Image is too small (%1×%2). Minimum: %3px").arg(width).arg(height).arg(minSize));
            return;
        }
        openAction(path, action);
    }

    function validateAndOpen(path, action) {
        Proc.runCommand("quickCapture.validateImage", ["file", "-b", path], (stdout, exitCode) => {
            const output = (stdout || "").toLowerCase();
            if (exitCode !== 0 || output.includes("empty") || !output.includes("image")) {
                captureActions.notifyError(I18n.trFor("quickCapture", "Invalid or corrupted image file."));
                return;
            }
            openAction(path, action);
        });
    }

    function openAction(path, action) {
        const fromCC = root.pendingFromControlCenter;
        root.pendingFromControlCenter = false;
        switch (action) {
        case "float":
            floatServiceItem.spawnWindow("file://" + path, null, [path]);
            return;
        case "copy":
            captureActions.copyImage(path, () => captureActions.cleanupTemp(path));
            return;
        case "save":
            captureActions.saveImage(path, () => captureActions.cleanupTemp(path));
            return;
        case "copyAndSave":
            captureActions.copyAndSaveImage(path, () => captureActions.cleanupTemp(path));
            return;
        default:
            if (fromCC && root.hideControlCenter)
                closeControlCenter();
            modal.currentCapturePath = path;
            modal.shouldBeVisible = true;
            modal.open();
        }
    }

    function loadImageFromUri(uri, action) {
        if (uri.startsWith("file://"))
            uri = uri.substring(7);
        root.currentCapturePath = capturePath();

        if (uri.startsWith("http://") || uri.startsWith("https://")) {
            root.isDownloading = true;
            Proc.runCommand("quickCapture.download", [Proc.dmsBin, "dl", uri, "-o", root.currentCapturePath], (stdout, exitCode) => {
                root.isDownloading = false;
                if (exitCode !== 0) {
                    captureActions.notifyError(I18n.trFor("quickCapture", "Failed to download image."));
                    return;
                }
                validateAndOpen(root.currentCapturePath, action);
            });
            return;
        }

        Proc.runCommand("quickCapture.copyImage", ["cp", "-f", "--", uri, root.currentCapturePath], (stdout, exitCode) => {
            if (exitCode !== 0) {
                captureActions.notifyError(I18n.trFor("quickCapture", "Failed to load image: %1").arg(uri));
                return;
            }
            validateAndOpen(root.currentCapturePath, action);
        });
    }

    function handleDrop(drop) {
        let url = "";
        if (drop.hasUrls && drop.urls.length > 0)
            url = drop.urls[0].toString();
        else if (drop.hasText && /^https?:\/\//.test(drop.text.trim()))
            url = drop.text.trim();

        if (url === "") {
            captureActions.notifyWarning(I18n.trFor("quickCapture", "No valid image file or URL found in drop."));
            return;
        }
        loadImageFromUri(url, "edit");
    }

    function showHistoryCarousel() {
        historyModal.shouldBeVisible = true;
        historyModal.open();
    }

    function openMenu() {
        if (root.isRecording && root.widgetMode !== "video")
            root.widgetMode = "video";
        menuModal.targetScreen = CompositorService.getFocusedScreen() ?? Quickshell.screens[0] ?? null;
        menuModal.shouldBeVisible = true;
        menuModal.open();
    }

    function closeMenu() {
        if (menuModal && typeof menuModal.instantClose === "function") {
            menuModal.instantClose();
        } else {
            menuModal.close();
        }
    }

    function toggleMenu() {
        if (menuModal.shouldBeVisible) {
            closeMenu();
            return "CLOSED";
        }
        openMenu();
        return "OPENED";
    }

    IpcHandler {
        target: "quickCapture"

        function open(): string {
            root.openMenu();
            return "SUCCESS";
        }

        function toggle(): string {
            return root.toggleMenu();
        }

        function menu(): string {
            return root.toggleMenu();
        }

        function screenshot(mode: string, action: string): string {
            root.triggerCapture(mode, action, "", false);
            return "SUCCESS";
        }

        function selectFile(action: string): string {
            root.selectImage(action, false);
            return "SUCCESS";
        }

        function fromClipboard(action: string): string {
            root.fromClipboard(action, false);
            return "SUCCESS";
        }

        function openImage(path: string, action: string): string {
            root.loadImageFromUri(path, action);
            return "SUCCESS";
        }

        function close(): string {
            modal.close();
            menuModal.close();
            return "SUCCESS";
        }

        function showHistory(): string {
            root.showHistoryCarousel();
            return "SUCCESS";
        }

        function recordStart(mode: string, geometry: string): string {
            root.record(mode, geometry, false);
            return "SUCCESS";
        }

        function recordStop(): string {
            recorder.stopRecording();
            return "SUCCESS";
        }

        function recordPause(): string {
            recorder.pauseRecording();
            return "SUCCESS";
        }

        function recordCancel(): string {
            recorder.cancelRecording();
            return "SUCCESS";
        }

        function recordToggle(mode: string): string {
            if (recorder.isRecording) {
                recorder.stopRecording();
                return "STOPPED";
            }
            root.record(mode, "", false);
            return "STARTED";
        }

        function recordStatus(): string {
            return JSON.stringify({
                "recordingState": recorder.recordingState,
                "isRecording": recorder.isRecording,
                "isPaused": recorder.isPaused,
                "duration": recorder.recordingSeconds,
                "outputPath": recorder.outputPath
            });
        }
    }

    CaptureConfig {
        id: daemonConfig
        pluginData: root.pluginData
    }

    QtObject {
        id: menuWidgetAdapter

        readonly property var daemon: root
        readonly property var recorder: root.recordingController
        readonly property var config: daemonConfig
        readonly property bool isRecording: root.isRecording
        readonly property bool isPaused: recorder.isPaused
        readonly property string widgetMode: root.widgetMode
        readonly property var pluginData: root.pluginData
        readonly property bool blinkRecordDot: Defaults.get(root.pluginData, "blinkRecordDot")
        readonly property string durationText: recorder.formatDuration(recorder.recordingSeconds)
        readonly property real popoutWidth: 260

        function closePopout() {
            root.closeMenu();
        }

        function runAfterPopoutClosed(action) {
            root.closeMenu();
            Qt.callLater(action);
        }

        function setWidgetMode(mode) {
            root.widgetMode = mode;
        }
    }

    FloatService {
        id: floatServiceItem
        pluginData: root.pluginData
    }

    QuickCaptureActions {
        id: captureActions
        daemon: root
        modal: modal
        floatService: floatServiceItem
        exportAndExecute: callback => modal.exportAndExecute(callback)
        onCloseRequested: modal.discardAndClose()
    }

    QuickCaptureModal {
        id: modal
        parentWidget: root
        floatService: floatServiceItem
        actions: captureActions
    }

    FileBrowserModal {
        id: fileBrowserModal
        property string captureAction: "edit"
        browserTitle: I18n.trFor("quickCapture", "Select Image to Annotate")
        browserIcon: "image"
        fileExtensions: ["*.png", "*.jpg", "*.jpeg", "*.webp", "*.bmp"]
        onFileSelected: path => {
            root.loadImageFromUri(path, fileBrowserModal.captureAction);
            close();
        }
    }

    DModal {
        id: historyModal
        shouldBeVisible: false
        positioning: "center"
        enableShadow: true
        useOverlayLayer: true
        closeOnEscapeKey: true
        closeOnBackgroundClick: true
        onBackgroundClicked: close()

        readonly property real screenW: targetScreen ? targetScreen.width : (Quickshell.screens[0]?.width ?? 1920)
        readonly property real screenH: targetScreen ? targetScreen.height : (Quickshell.screens[0]?.height ?? 1080)
        readonly property real heightFraction: contentLoader?.item?.heightFraction ?? 0.45
        modalWidth: Math.round(screenW * 0.9)
        modalHeight: Math.round(screenH * heightFraction)

        content: Component {
            RecentEditsCarousel {
                daemon: root
                onCloseRequested: historyModal.close()
            }
        }
    }

    DModal {
        id: menuModal
        shouldBeVisible: false
        positioning: "center"
        enableShadow: true
        useOverlayLayer: true
        closeOnEscapeKey: true
        closeOnBackgroundClick: true
        onBackgroundClicked: close()

        modalWidth: 432 + Theme.spacingM * 2
        modalHeight: 304 + Theme.spacingM * 2

        content: Component {
            CaptureLauncherModal {
                widget: menuWidgetAdapter
            }
        }
    }

    RecordingController {
        id: recorder
        daemon: root
    }

    RecordingRegionBorder {
        recordingController: recorder
    }

    FloatingRecordingPill {
        daemon: root
    }
}
