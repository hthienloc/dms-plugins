import "./dms-common"
import QtQuick
import QtQuick.Controls
import Quickshell
import qs.Common
import qs.Modules.Plugins
import qs.Services
import qs.Widgets

PluginComponent {
    // Pure Neutral (Matches bar)

    id: root

    // --- Configuration Settings ---
    readonly property int dailyGoal: {
        let val = pluginData.dailyGoal ?? 2000;
        if (val < 50) return val * 250; // Auto-migrate cups target to ml
        return val;
    }
    readonly property int interval: pluginData.interval ?? 60
    readonly property string displayMode: pluginData.displayMode ?? "full"
    readonly property bool showHints: pluginData.showHints ?? true
    // --- Core State properties ---
    property int mlLogged: 0
    property string lastLogDate: ""
    property real lastDrinkTimestamp: 0
    property bool needsHydration: false
    // --- Helper properties for dynamic icon shape & color ---
    readonly property real progress: Math.min(1, root.mlLogged / root.dailyGoal)
    readonly property bool showProgressBar: root.displayMode === "progress" || root.displayMode === "text_progress"

    readonly property string pillText: {
        switch (root.displayMode) {
            case "logged":
            case "text_progress":
                return root.mlLogged + "ml";
            case "percentage":
                return Math.round(Math.min(100, root.progress * 100)) + "%";
            case "full":
                return root.mlLogged + "/" + root.dailyGoal + "ml";
            case "icon":
            case "progress":
            default:
                return "";
        }
    }
    readonly property string pillIconName: {
        if (root.mlLogged >= root.dailyGoal)
            return "check_circle";

        if (root.needsHydration)
            return "local_drink";

        return "water_drop";
    }
    readonly property color pillIconColor: {
        if (root.mlLogged >= root.dailyGoal)
            return Theme.primary;

        if (root.needsHydration)
            return Theme.warning;

        return Theme.surfaceText;
    }

    // --- State Persistence Helpers ---
    function saveState() {
        if (pluginService) {
            pluginService.savePluginState(pluginId, "mlLogged", root.mlLogged);
            pluginService.savePluginState(pluginId, "lastLogDate", root.lastLogDate);
            pluginService.savePluginState(pluginId, "lastDrinkTimestamp", root.lastDrinkTimestamp);
        }
    }

    function logWater(amount) {
        root.mlLogged += amount;
        root.needsHydration = false;
        root.lastDrinkTimestamp = Date.now();
        saveState();
    }

    function resetToday() {
        root.mlLogged = 0;
        root.needsHydration = false;
        root.lastDrinkTimestamp = Date.now();
        saveState();
    }

    // --- Initialization & Daily Auto-Reset ---
    Component.onCompleted: {
        const today = new Date().toDateString();
        const savedDate = pluginService ? pluginService.loadPluginState(pluginId, "lastLogDate", "") : "";
        if (savedDate !== today) {
            root.mlLogged = 0;
            root.lastLogDate = today;
            root.lastDrinkTimestamp = Date.now();
            root.needsHydration = false;
            saveState();
        } else {
            root.lastLogDate = savedDate;
            root.lastDrinkTimestamp = pluginService ? pluginService.loadPluginState(pluginId, "lastDrinkTimestamp", Date.now()) : Date.now();
            
            // Check for saved mlLogged
            let savedMl = pluginService ? pluginService.loadPluginState(pluginId, "mlLogged", -1) : -1;
            if (savedMl === -1) {
                // Migrate from old cupsLogged database
                let savedCups = pluginService ? pluginService.loadPluginState(pluginId, "cupsLogged", 0) : 0;
                root.mlLogged = savedCups * 250;
            } else {
                root.mlLogged = savedMl;
            }
            
            const elapsed = Date.now() - root.lastDrinkTimestamp;
            root.needsHydration = (elapsed >= root.interval * 60 * 1000) && (root.mlLogged < root.dailyGoal);
        }
    }
    // --- Minimalist Interaction Model ---
    // Left-click toggles popout dashboard, Right-click fast increments by 250ml.
    pillClickAction: null
    pillRightClickAction: () => {
        root.logWater(250);
    }
    // --- Popout Sizing ---
    popoutWidth: 320
    popoutHeight: root.showHints ? 335 : 295

    // --- Background Timer (Alarms & Midnight Reset) ---
    Timer {
        interval: 10000 // Check every 10 seconds
        repeat: true
        running: true
        triggeredOnStart: false
        onTriggered: {
            const today = new Date().toDateString();
            if (root.lastLogDate !== today) {
                root.mlLogged = 0;
                root.lastLogDate = today;
                root.lastDrinkTimestamp = Date.now();
                root.needsHydration = false;
                saveState();
                return ;
            }
            if (root.mlLogged < root.dailyGoal) {
                const elapsed = Date.now() - root.lastDrinkTimestamp;
                const limit = root.interval * 60 * 1000;
                root.needsHydration = (elapsed >= limit);
            } else {
                root.needsHydration = false;
            }
        }
    }

    // --- Horizontal Bar Pill Layout ---
    horizontalBarPill: Component {
        Row {
            spacing: (root.pillText !== "" || root.showProgressBar) ? Theme.spacingS : 0
            anchors.verticalCenter: parent ? parent.verticalCenter : undefined

            DankIcon {
                name: root.pillIconName
                size: Theme.iconSizeSmall
                color: root.pillIconColor
                anchors.verticalCenter: parent.verticalCenter
            }

            StyledText {
                visible: root.pillText !== ""
                text: root.pillText
                font.pixelSize: Theme.fontSizeMedium
                font.weight: Font.Medium
                color: Theme.surfaceText
                anchors.verticalCenter: parent.verticalCenter
            }

            // Progress Bar (Horizontal)
            StyledRect {
                visible: root.showProgressBar
                width: 60
                height: 6
                radius: 3
                color: Theme.surfaceContainerHighest
                anchors.verticalCenter: parent.verticalCenter

                Rectangle {
                    width: Math.max(height, parent.width * root.progress)
                    height: parent.height
                    radius: parent.radius
                    color: Theme.primary
                }
            }
        }
    }

    // --- Vertical Bar Pill Layout ---
    verticalBarPill: Component {
        Column {
            spacing: (root.pillText !== "" || root.showProgressBar) ? Theme.spacingS : 0
            anchors.horizontalCenter: parent ? parent.horizontalCenter : undefined

            DankIcon {
                name: root.pillIconName
                size: Theme.iconSizeSmall
                color: root.pillIconColor
                anchors.horizontalCenter: parent.horizontalCenter
            }

            StyledText {
                visible: root.pillText !== ""
                text: root.displayMode === "full" ? root.mlLogged + "ml" : root.pillText
                font.pixelSize: Theme.fontSizeSmall
                font.weight: Font.Medium
                color: Theme.surfaceText
                anchors.horizontalCenter: parent.horizontalCenter
            }

            // Progress Bar (Vertical)
            StyledRect {
                visible: root.showProgressBar
                width: 6
                height: 40
                radius: 3
                color: Theme.surfaceContainerHighest
                anchors.horizontalCenter: parent.horizontalCenter

                Rectangle {
                    width: parent.width
                    height: Math.max(width, parent.height * root.progress)
                    radius: parent.radius
                    color: Theme.primary
                    anchors.bottom: parent.bottom
                }
            }
        }
    }

    // --- Popout Content Panel ---
    popoutContent: Component {
        PopoutComponent {
            id: mainContent

            property var parentPopout: null

            onParentPopoutChanged: root.activePopoutReference = parentPopout
            width: parent ? parent.width : 0
            headerText: "Hydration Tracker"
            showCloseButton: true

            Column {
                width: parent.width
                spacing: Theme.spacingM

                // Simple progress cup visual
                Item {
                    width: parent.width
                    height: 130

                    // Clean Cup graphic
                    Rectangle {
                        id: cupFrame

                        width: 90
                        height: 120
                        anchors.centerIn: parent
                        color: "transparent"
                        border.color: Theme.surfaceVariantText
                        border.width: 4
                        radius: 10
                        clip: true

                        // Animated Wavy Water Level
                        Item {
                            id: waterLevelContainer

                            width: parent.width - 8
                            height: Math.max(0, (parent.height - 8) * Math.min(1, root.mlLogged / root.dailyGoal))
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 4
                            anchors.horizontalCenter: parent.horizontalCenter
                            clip: true

                            // Background wave (Parallax Back Layer)
                            Canvas {
                                id: backWave

                                property real phase: 0
                                property int mlLoggedRef: root.mlLogged

                                anchors.fill: parent
                                onPhaseChanged: requestPaint()
                                onMlLoggedRefChanged: requestPaint()
                                onPaint: {
                                    var ctx = getContext("2d");
                                    ctx.reset();
                                    var w = width;
                                    var h = height;
                                    ctx.fillStyle = Theme.primary;
                                    ctx.globalAlpha = 0.4;
                                    ctx.beginPath();
                                    ctx.moveTo(0, h);
                                    var isFilled = (root.mlLogged >= root.dailyGoal);
                                    for (var x = 0; x <= w; x += 2) {
                                        var y = isFilled ? 0 : (5 * Math.sin((x / w) * 2 * Math.PI + phase));
                                        ctx.lineTo(x, y + (isFilled ? 0 : 8));
                                    }
                                    ctx.lineTo(w, h);
                                    ctx.lineTo(0, h);
                                    ctx.closePath();
                                    ctx.fill();
                                }
                            }

                            // Foreground wave (Front Layer)
                            Canvas {
                                id: frontWave

                                property real phase: 0
                                property int mlLoggedRef: root.mlLogged

                                anchors.fill: parent
                                onPhaseChanged: requestPaint()
                                onMlLoggedRefChanged: requestPaint()
                                onPaint: {
                                    var ctx = getContext("2d");
                                    ctx.reset();
                                    var w = width;
                                    var h = height;
                                    ctx.fillStyle = Theme.primary;
                                    ctx.globalAlpha = 0.75;
                                    ctx.beginPath();
                                    ctx.moveTo(0, h);
                                    var isFilled = (root.mlLogged >= root.dailyGoal);
                                    for (var x = 0; x <= w; x += 2) {
                                        var y = isFilled ? 0 : (5 * Math.sin((x / w) * 2 * Math.PI - phase));
                                        ctx.lineTo(x, y + (isFilled ? 0 : 8));
                                    }
                                    ctx.lineTo(w, h);
                                    ctx.lineTo(0, h);
                                    ctx.closePath();
                                    ctx.fill();
                                }
                            }

                            // Infinite wave animations
                            NumberAnimation {
                                target: backWave
                                property: "phase"
                                from: 0
                                to: 2 * Math.PI
                                duration: 2400
                                loops: Animation.Infinite
                                running: root.mlLogged > 0 && root.mlLogged < root.dailyGoal
                            }

                            NumberAnimation {
                                target: frontWave
                                property: "phase"
                                from: 0
                                to: 2 * Math.PI
                                duration: 1400
                                loops: Animation.Infinite
                                running: root.mlLogged > 0 && root.mlLogged < root.dailyGoal
                            }

                            Behavior on height {
                                NumberAnimation {
                                    duration: 300
                                    easing.type: Easing.OutCubic
                                }
                            }
                        }

                        // Cup reflection overlay
                        Rectangle {
                            width: 3
                            height: parent.height - 16
                            anchors.left: parent.left
                            anchors.leftMargin: 6
                            anchors.verticalCenter: parent.verticalCenter
                            color: Theme.surfaceText
                            opacity: 0.12
                            radius: 1.5
                        }

                        // Percentage Label inside the cup
                        StyledText {
                            anchors.centerIn: parent
                            text: Math.round(Math.min(100, (root.mlLogged / root.dailyGoal) * 100)) + "%"
                            font.pixelSize: Theme.fontSizeMedium
                            font.weight: Font.Bold
                            color: Theme.surfaceText
                        }
                    }
                }

                // Presets Container Row
                Row {
                    width: parent.width
                    spacing: Theme.spacingS
                    anchors.horizontalCenter: parent.horizontalCenter

                    DankButton {
                        width: (parent.width - Theme.spacingS * 2) / 3
                        iconName: "local_bar"
                        text: "250ml"
                        backgroundColor: Theme.surfaceContainerHigh
                        textColor: Theme.primary
                        onClicked: logWater(250)
                    }

                    DankButton {
                        width: (parent.width - Theme.spacingS * 2) / 3
                        iconName: "local_cafe"
                        text: "350ml"
                        backgroundColor: Theme.surfaceContainerHigh
                        textColor: Theme.primary
                        onClicked: logWater(350)
                    }

                    DankButton {
                        width: (parent.width - Theme.spacingS * 2) / 3
                        iconName: "local_drink"
                        text: "500ml"
                        backgroundColor: Theme.surfaceContainerHigh
                        textColor: Theme.primary
                        onClicked: logWater(500)
                    }
                }

                // Reset progress button
                DankButton {
                    width: parent.width
                    text: I18n.tr("Reset Progress")
                    backgroundColor: Theme.surfaceContainerHighest
                    textColor: Theme.surfaceText
                    onClicked: resetToday()
                }

                // Hint Guide Section
                HintSection {
                    width: parent.width
                    showHints: root.showHints

                    HintItem {
                        icon: "info"
                        text: I18n.tr("Right-click the bar icon to quickly log +250ml.")
                    }
                }
            }
        }
    }
}
