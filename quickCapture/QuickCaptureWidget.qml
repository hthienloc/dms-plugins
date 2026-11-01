import QtQuick
import qs.Common
import qs.Modules.Plugins
import qs.Services
import qs.Widgets
import "./components/bar"
import "./components/core/Defaults.js" as Defaults

PluginComponent {
    id: root

    pluginId: "quickCapture"
    pluginService: PluginService

    readonly property var daemon: PluginService.pluginDaemonInstances[pluginId] ?? null
    readonly property var recorder: daemon?.recordingController ?? null
    readonly property bool isRecording: daemon?.isRecording ?? false
    readonly property bool isPaused: recorder?.isPaused ?? false
    readonly property bool isActive: daemon ? (daemon.isCapturing || daemon.isAnnotating) : false
    readonly property bool isDownloading: daemon?.isDownloading ?? false
    readonly property string widgetMode: daemon?.widgetMode ?? "photo"
    readonly property bool blinkRecordDot: Defaults.get(pluginData, "blinkRecordDot")
    readonly property string durationText: recorder ? recorder.formatDuration(recorder.recordingSeconds) : "00:00"
    readonly property alias config: captureConfig

    property var pendingPopoutAction: null

    CaptureConfig {
        id: captureConfig
        pluginData: root.pluginData
    }

    Timer {
        id: popoutCloseTimer
        interval: Math.max(50, Theme.popoutAnimationDuration + 50)
        onTriggered: {
            const action = root.pendingPopoutAction;
            root.pendingPopoutAction = null;
            if (action)
                action();
        }
    }

    function runAfterPopoutClosed(action) {
        root.pendingPopoutAction = action;
        root.closePopout();
        popoutCloseTimer.restart();
    }

    function setWidgetMode(mode) {
        if (root.daemon)
            root.daemon.widgetMode = mode;
    }

    function runDefaultAction(settingKey, fromControlCenter) {
        if (!root.daemon)
            return;
        if (root.widgetMode === "video") {
            root.daemon.record("region", "", fromControlCenter);
            return;
        }
        root.daemon.capture(Defaults.get(pluginData, settingKey), "edit", "", fromControlCenter);
    }

    popoutWidth: 280
    popoutHeight: root.widgetMode === "video" ? (root.isRecording ? 320 : 310) : 465 + Math.min((root.daemon?.outputs ?? []).length, 5) * 38

    popoutContent: Component {
        CaptureMenu {
            widget: root
        }
    }

    horizontalBarPill: Component {
        CapturePill {
            widget: root
        }
    }

    verticalBarPill: Component {
        CapturePill {
            widget: root
            vertical: true
        }
    }

    function buildDockMenuItems() {
        const items = [
            {
                type: "item",
                icon: "screenshot_region",
                text: I18n.trFor("quickCapture", "Capture Region"),
                action: () => root.daemon?.capture("region", "edit", "", false)
            },
            {
                type: "item",
                icon: "fullscreen",
                text: I18n.trFor("quickCapture", "Capture Fullscreen"),
                action: () => root.daemon?.capture("full", "edit", "", false)
            },
            {
                type: "item",
                icon: "crop_square",
                text: I18n.trFor("quickCapture", "Capture Window"),
                action: () => root.daemon?.capture("window", "edit", "", false)
            },
            {
                type: "item",
                icon: "restart_alt",
                text: I18n.trFor("quickCapture", "Last Region"),
                action: () => root.daemon?.capture("last", "edit", "", false)
            },
            {
                type: "item",
                icon: "history_toggle_off",
                text: I18n.trFor("quickCapture", "Scrolling"),
                action: () => root.daemon?.capture("scroll", "edit", "", false)
            },
            {
                type: "separator"
            },
            {
                type: "item",
                icon: "content_paste",
                text: I18n.trFor("quickCapture", "From Clipboard"),
                action: () => root.daemon?.fromClipboard("edit")
            },
            {
                type: "item",
                icon: "folder_open",
                text: I18n.trFor("quickCapture", "Select Image File"),
                action: () => root.daemon?.selectFile("edit")
            },
            {
                type: "separator"
            },
            {
                type: "item",
                icon: root.isRecording ? "stop_circle" : "videocam",
                text: root.isRecording ? I18n.trFor("quickCapture", "Stop Recording") : I18n.trFor("quickCapture", "Record Region"),
                action: () => {
                    if (root.isRecording)
                        root.recorder?.stopRecording();
                    else
                        root.daemon?.record("region", "", false);
                }
            },
            {
                type: "item",
                icon: "video_settings",
                text: I18n.trFor("quickCapture", "Record Fullscreen"),
                action: () => root.daemon?.record("screen", "", false)
            },
            {
                type: "separator"
            },
            {
                type: "item",
                icon: "folder",
                text: I18n.trFor("quickCapture", "Open Captures Folder"),
                action: () => root.daemon?.openFolder(root.widgetMode === "video" ? "video" : "photo")
            },
            {
                type: "item",
                icon: "history",
                text: I18n.trFor("quickCapture", "Recent History"),
                action: () => root.daemon?.showHistoryCarousel()
            },
            {
                type: "separator"
            },
            {
                type: "item",
                icon: "tune",
                text: I18n.trFor("quickCapture", "More Options"),
                action: () => {
                    const oldClickAction = root.pillClickAction;
                    root.pillClickAction = null;
                    root.triggerPopout();
                    root.pillClickAction = oldClickAction;
                }
            }
        ];
        return items;
    }

    DContextMenu {
        id: dockContextMenu
        layerNamespace: "dms:quickcapture-context-menu"
        menuItems: []
    }

    readonly property bool isDockWidget: root.surfaceContext?.kind === "dock"
    pillClickAction: isDockWidget ? function () {
        if (!root.daemon)
            return;
        if (root.isRecording) {
            root.recorder?.stopRecording();
            return;
        }
        if (root.widgetMode === "video") {
            root.daemon.record("region", "", false);
            return;
        }
        root.daemon.capture("region", "edit", "", false);
    } : null

    pillRightClickAction: function (x, y, width, section, screen) {
        if (!root.daemon)
            return;
        if (root.surfaceContext?.kind === "dock") {
            if (root.isRecording) {
                root.recorder?.cancelRecording();
                return;
            }
            const anchor = root.pillAnchor();
            if (anchor) {
                const edge = root.axis?.edge ?? "bottom";
                const offset = Theme.spacingM;
                let targetX = anchor.trigger.x + (root.isVertical ? 0 : anchor.trigger.width / 2);
                let targetY = anchor.trigger.y + (root.isVertical ? anchor.trigger.width / 2 : 0);

                if (edge === "bottom")
                    targetY -= offset;
                else if (edge === "top")
                    targetY += offset;
                else if (edge === "right")
                    targetX -= offset;
                else if (edge === "left")
                    targetX += offset;

                dockContextMenu.menuItems = root.buildDockMenuItems();
                dockContextMenu.openFromBar({
                    screen: anchor.screen,
                    x: targetX,
                    y: targetY,
                    isVertical: root.isVertical,
                    edge: edge
                });
                return;
            }
        }
        if (root.isRecording) {
            root.recorder.cancelRecording();
            return;
        }
        root.runDefaultAction("rightClickAction", false);
    }

    ccWidgetIcon: root.isRecording ? "videocam" : "screenshot_region"
    ccWidgetPrimaryText: I18n.trFor("quickCapture", "Quick Capture")
    ccWidgetSecondaryText: {
        if (root.isRecording)
            return root.durationText;
        if (!root.isActive)
            return I18n.trFor("quickCapture", "Ready");
        return root.daemon.isCapturing ? I18n.trFor("quickCapture", "Capturing...") : I18n.trFor("quickCapture", "Annotating");
    }
    ccWidgetIsActive: root.isActive || root.isRecording
    onCcWidgetToggled: {
        if (root.isRecording) {
            root.recorder.stopRecording();
            return;
        }
        root.runDefaultAction("middleClickAction", true);
    }
    ccDetailHeight: 256

    ccDetailContent: Component {
        CaptureDetail {
            widget: root
        }
    }
}
