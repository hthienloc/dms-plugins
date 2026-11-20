import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.Common
import qs.DCommon.Widgets
import qs.Modules.Plugins
import qs.Services
import "./shared"

PluginComponent {
    id: root

    pluginId: "mediaDownloader"

    pillRightClickAction: function() {
        Proc.runCommand(
            "mediaDownloader.rightClickPaste",
            ["dms", "cl", "paste"],
            (stdout, exitCode) => {
                if (exitCode === 0 && stdout !== "") {
                    var trimmed = stdout.trim();
                    if (trimmed.indexOf("http://") === 0 || trimmed.indexOf("https://") === 0 || trimmed.indexOf("www.") === 0) {
                        root.activeUrl = trimmed;
                    }
                }
                root.triggerPopout();
            },
            0
        );
    }

    // Read settings
    readonly property string downloadPathAudio: (pluginData.downloadPathAudio && pluginData.downloadPathAudio.trim() !== "") ? pluginData.downloadPathAudio : (Quickshell.env("HOME") + "/Music")
    readonly property string downloadPathVideo: (pluginData.downloadPathVideo && pluginData.downloadPathVideo.trim() !== "") ? pluginData.downloadPathVideo : (Quickshell.env("HOME") + "/Videos")
    readonly property string quickVideoFormat: pluginData.quickVideoFormat ?? "mp4"
    readonly property string quickVideoRes: pluginData.quickVideoRes ?? "1080p"
    readonly property string quickAudioFormat: pluginData.quickAudioFormat ?? "mp3"
    readonly property string quickAudioQuality: pluginData.quickAudioQuality ?? "best"
    readonly property bool sponsorBlock: pluginData.sponsorBlock ?? true
    readonly property bool limitRate: pluginData.limitRate ?? false
    readonly property int maxRate: pluginData.maxRate ?? 5000
    readonly property bool embedThumbnail: pluginData.embedThumbnail ?? true
    readonly property bool cropThumbnail: pluginData.cropThumbnail ?? false
    readonly property bool embedMetadata: pluginData.embedMetadata ?? true
    readonly property bool embedSubs: pluginData.embedSubs ?? false

    readonly property real tileHeight: Theme.listItemHeight + Theme.spacingS
    readonly property real thumbSize: Theme.listItemHeight - Theme.spacingXS

    // State variables
    property string activeUrl: ""
    property int activeDownloadsCount: 0
    property bool hasHistoryItems: false
    property string customMode: "" // "", "video", "audio"

    // Version check variables
    property string ytdlpVersion: ""
    property string ytdlpLatestVersion: ""
    property bool ytdlpOutdated: false
    property bool updatingYtdlp: false
    property bool ytdlpPkgManaged: false
    property string ytdlpPkgCmd: ""

    // Custom configuration states
    property string customFormat: ""
    property string customQuality: ""

    // Preview state variables
    property string previewTitle: ""
    property string previewAuthor: ""
    property string previewThumbnail: ""
    property bool fetchingPreview: false
    property string previewUrl: ""

    // ListModel for tracking downloads
    ListModel {
        id: downloadsModel
    }

    // Update active count whenever model changes
    function updateActiveCount() {
        var activeCount = 0;
        var historyCount = 0;
        for (var i = 0; i < downloadsModel.count; i++) {
            var s = downloadsModel.get(i).status;
            if (s === "fetching" || s === "downloading") {
                activeCount++;
            } else if (s === "completed" || s === "cancelled" || s === "error") {
                historyCount++;
            }
        }
        root.activeDownloadsCount = activeCount;
        root.hasHistoryItems = historyCount > 0;
    }

    // Helper functions for formatting bytes and speed
    function formatSpeed(speedBytes) {
        var bytes = parseFloat(speedBytes);
        if (isNaN(bytes) || bytes <= 0) return "0 B/s";
        var k = 1024;
        var sizes = ["B/s", "KB/s", "MB/s", "GB/s"];
        var i = Math.floor(Math.log(bytes) / Math.log(k));
        return parseFloat((bytes / Math.pow(k, i)).toFixed(1)) + " " + sizes[i];
    }

    function formatEta(seconds) {
        var sec = parseInt(seconds);
        if (isNaN(sec) || sec <= 0) return "00:00";
        var h = Math.floor(sec / 3600);
        var m = Math.floor((sec % 3600) / 60);
        var s = sec % 60;
        var pad = (n) => n < 10 ? "0" + n : n;
        if (h > 0) return pad(h) + ":" + pad(m) + ":" + pad(s);
        return pad(m) + ":" + pad(s);
    }

    function checkYtdlpVersion() {
        Proc.runCommand("mediaDownloader.getVersion", ["yt-dlp", "--version"], (stdout, exitCode) => {
            if (exitCode === 0 && stdout.trim() !== "") {
                root.ytdlpVersion = stdout.trim().split(" ")[0];
            }
        });
    }

    function detectPkgManager() {
        Proc.runCommand("mediaDownloader.detectPkg", ["sh", "-c", "\
            if command -v pacman >/dev/null 2>&1; then \
                echo 'sudo pacman -Syu yt-dlp'; \
            elif command -v apt-get >/dev/null 2>&1; then \
                echo 'sudo apt update && sudo apt install yt-dlp'; \
            elif command -v dnf >/dev/null 2>&1; then \
                echo 'sudo dnf update yt-dlp'; \
            elif command -v pip3 >/dev/null 2>&1 && pip3 show yt-dlp >/dev/null 2>&1; then \
                echo 'pip3 install -U yt-dlp'; \
            elif command -v pip >/dev/null 2>&1 && pip show yt-dlp >/dev/null 2>&1; then \
                echo 'pip install -U yt-dlp'; \
            else \
                echo 'your package manager'; \
            fi"], (stdout) => {
            root.ytdlpPkgCmd = stdout.trim();
        });
    }

    function updateYtdlp() {
        root.updatingYtdlp = true;
        if (typeof ToastService !== "undefined" && ToastService) {
            ToastService.showInfo("Updating yt-dlp...");
        }
        
        Proc.runCommand("mediaDownloader.doUpdate", ["yt-dlp", "-U"], (stdout, exitCode) => {
            root.updatingYtdlp = false;
            var output = stdout.trim();
            if (exitCode === 0) {
                if (typeof ToastService !== "undefined" && ToastService) {
                    ToastService.showSuccess("yt-dlp updated successfully");
                }
                root.checkYtdlpVersion();
            } else {
                var isPkgManager = output.indexOf("package manager") !== -1 || output.indexOf("manual build") !== -1;
                if (isPkgManager) {
                    root.ytdlpPkgManaged = true;
                    root.ytdlpOutdated = false;
                }
                var errorMsg = isPkgManager 
                    ? "Cannot update: yt-dlp was installed via package manager." 
                    : "Failed to update: " + (output.substring(0, 100) || "Unknown error");
                
                if (typeof ToastService !== "undefined" && ToastService) {
                    ToastService.showError(errorMsg);
                }
            }
        });
    }

    Component.onCompleted: {
        root.checkYtdlpVersion();
    }

    // Function to add and start a download process
    function startDownload(url, type, format, quality, thumbnailUrl) {
        var path = (type === "audio") ? root.downloadPathAudio : root.downloadPathVideo;
        downloadsModel.append({
            url: url,
            title: "Fetching title...",
            progress: 0,
            speed: "0 B/s",
            eta: "--:--",
            status: "fetching",
            type: type,
            format: format,
            quality: quality,
            fullPath: "",
            downloadPath: path,
            thumbnailUrl: thumbnailUrl || ""
        });
        
        var idx = downloadsModel.count - 1;
        updateActiveCount();

        // Get the title first via a quick shell query
        Proc.runCommand("mediaDownloader.getTitle_" + idx, ["yt-dlp", "--ignore-config", "--get-title", url], (stdout, exitCode) => {
            if (exitCode === 0 && stdout.trim().length > 0) {
                downloadsModel.setProperty(idx, "title", stdout.trim());
            } else {
                downloadsModel.setProperty(idx, "title", url);
            }
            downloadsModel.setProperty(idx, "status", "downloading");
            updateActiveCount();
        });
    }

    onActiveUrlChanged: {
        previewDebounceTimer.restart();
        if (activeUrl === "") {
            previewDebounceTimer.stop();
            root.previewTitle = "";
            root.previewAuthor = "";
            root.previewThumbnail = "";
            root.previewUrl = "";
            root.fetchingPreview = false;
        }
    }

    Timer {
        id: previewDebounceTimer
        interval: 800
        running: false
        repeat: false
        onTriggered: {
            root.fetchPreview(root.activeUrl);
        }
    }

    function fetchPreview(url) {
        if (url === "") {
            root.previewTitle = "";
            root.previewAuthor = "";
            root.previewThumbnail = "";
            root.previewUrl = "";
            root.fetchingPreview = false;
            return;
        }
        
        var trimmed = url.trim();
        if (!(trimmed.indexOf("http://") === 0 || trimmed.indexOf("https://") === 0 || trimmed.indexOf("www.") === 0)) {
            root.previewTitle = "";
            root.previewAuthor = "";
            root.previewThumbnail = "";
            root.previewUrl = "";
            root.fetchingPreview = false;
            return;
        }

        if (trimmed === root.previewUrl) {
            return;
        }

        root.previewUrl = trimmed;
        root.fetchingPreview = true;
        root.previewTitle = "Loading preview...";
        root.previewAuthor = "";
        root.previewThumbnail = "";

        var cmd = ["yt-dlp", "--ignore-config", "--print", "%(title)s|%(uploader)s|%(thumbnail)s", "--skip-download", trimmed];
        Proc.runCommand("mediaDownloader.getPreview_" + Date.now(), cmd, (stdout, exitCode) => {
            // Check if activeUrl hasn't changed since we started fetching
            if (root.activeUrl.trim() !== trimmed) {
                return;
            }
            root.fetchingPreview = false;
            if (exitCode === 0 && stdout.trim().length > 0) {
                var lines = stdout.trim().split("\n");
                var lastLine = lines[lines.length - 1]; // in case of warnings/other output
                var parts = lastLine.split("|");
                if (parts.length >= 2) {
                    root.previewTitle = parts[0].trim();
                    root.previewAuthor = parts[1].trim();
                    root.previewThumbnail = parts.length >= 3 ? parts[2].trim() : "";
                    return;
                }
            }
            root.previewTitle = "";
            root.previewAuthor = "";
            root.previewThumbnail = "";
        });
    }

    // Instantiator for active download processes
    Instantiator {
        model: downloadsModel
        delegate: Item {
            property bool isDownloading: model.status === "downloading"
            
            property Process downloadProc: Process {
                running: isDownloading
                command: {
                    var args = [
                        "yt-dlp",
                        "--ignore-config",
                        "--newline",
                        "--progress",
                        "--progress-template", "[Progress];%(progress.status)s;%(progress.downloaded_bytes)s;%(progress.total_bytes)s;%(progress.total_bytes_estimate)s;%(progress.speed)s;%(progress.eta)s",
                        "--paths", model.downloadPath,
                        "--output", "%(title)s.%(ext)s"
                    ];

                    if (model.type === "audio") {
                        args.push("-x");
                        args.push("--audio-format");
                        args.push(model.format);
                        if (model.quality !== "best") {
                            args.push("--audio-quality");
                            args.push(model.quality);
                        }
                    } else {
                        args.push("-f");
                        if (model.quality === "best") {
                            args.push("bestvideo+bestaudio/best");
                        } else {
                            var res = model.quality.replace("p", "");
                            args.push("bestvideo[height<=" + res + "]+bestaudio/best[height<=" + res + "]");
                        }
                        args.push("--merge-output-format");
                        args.push(model.format);
                    }

                    if (root.embedThumbnail) {
                        args.push("--embed-thumbnail");
                        if (root.cropThumbnail) {
                            args.push("--convert-thumbnails");
                            args.push("jpg");
                            args.push("--ppa");
                            args.push("EmbedThumbnail+ffmpeg_o:-c:v mjpeg -vf crop=\"'if(gt(ih,iw),iw,ih)':'if(gt(iw,ih),ih,iw)'\"");
                        }
                    }
                    if (root.embedMetadata) {
                        args.push("--embed-metadata");
                    }
                    if (root.embedSubs && model.type === "video") {
                        args.push("--embed-subs");
                        args.push("--write-subs");
                    }

                    if (root.sponsorBlock) {
                        args.push("--sponsorblock-remove");
                        args.push("default");
                    }
                    if (root.limitRate) {
                        args.push("--limit-rate");
                        args.push(root.maxRate + "K");
                    }

                    args.push(model.url);
                    return args;
                }

                stdout: SplitParser {
                    onRead: (data) => {
                        var line = String(data).trim();
                        if (line.indexOf("[Progress];") === 0) {
                            var parts = line.split(";");
                            var status = parts[1];
                            var downloadedBytes = parseInt(parts[2]) || 0;
                            var totalBytes = parseInt(parts[3]) || parseInt(parts[4]) || 0;
                            var speed = parts[5];
                            var eta = parts[6];
                            
                            var percent = totalBytes > 0 ? Math.round((downloadedBytes / totalBytes) * 100) : 0;
                            
                            downloadsModel.setProperty(index, "progress", percent);
                            downloadsModel.setProperty(index, "speed", root.formatSpeed(speed));
                            downloadsModel.setProperty(index, "eta", root.formatEta(eta));
                        } else if (line.indexOf("[download] Destination:") === 0) {
                            var dest = line.substring(23).replace(/"/g, "").trim();
                            var fullP = dest;
                            if (dest.indexOf("/") !== -1) {
                                dest = dest.substring(dest.lastIndexOf("/") + 1);
                            }
                            downloadsModel.setProperty(index, "title", dest);
                            downloadsModel.setProperty(index, "fullPath", fullP);
                        } else if (line.indexOf("[ExtractAudio] Destination:") === 0) {
                            var dest = line.substring(27).replace(/"/g, "").trim();
                            var fullP = dest;
                            if (dest.indexOf("/") !== -1) {
                                dest = dest.substring(dest.lastIndexOf("/") + 1);
                            }
                            downloadsModel.setProperty(index, "title", dest);
                            downloadsModel.setProperty(index, "fullPath", fullP);
                        } else if (line.indexOf("[ffmpeg] Destination:") === 0) {
                            var dest = line.substring(21).replace(/"/g, "").trim();
                            var fullP = dest;
                            if (dest.indexOf("/") !== -1) {
                                dest = dest.substring(dest.lastIndexOf("/") + 1);
                            }
                            downloadsModel.setProperty(index, "title", dest);
                            downloadsModel.setProperty(index, "fullPath", fullP);
                        } else if (line.indexOf("[Metadata] Adding metadata to") === 0) {
                            var dest = line.substring(29).replace(/"/g, "").trim();
                            var fullP = dest;
                            if (dest.indexOf("/") !== -1) {
                                dest = dest.substring(dest.lastIndexOf("/") + 1);
                            }
                            downloadsModel.setProperty(index, "title", dest);
                            downloadsModel.setProperty(index, "fullPath", fullP);
                        } else if (line.indexOf("[Merger] Merging formats into") === 0) {
                            var merger = line.substring(30).replace(/"/g, "").trim();
                            var fullM = merger;
                            if (merger.indexOf("/") !== -1) {
                                merger = merger.substring(merger.lastIndexOf("/") + 1);
                            }
                            downloadsModel.setProperty(index, "title", merger);
                            downloadsModel.setProperty(index, "fullPath", fullM);
                        }
                    }
                }

                function _extractThumbnail(fp, idx) {
                    if (!fp) return;
                    var cacheBase = Quickshell.env("XDG_CACHE_HOME") || (Quickshell.env("HOME") + "/.cache");
                    var thumbDir = cacheBase + "/dms-media-downloader/";
                    var thumbPath = thumbDir + "thumb_" + idx + ".jpg";
                    Proc.runCommand("mediaDownloader.extractThumb" + idx,
                        ["sh", "-c", "mkdir -p \"$1\" && ffmpeg -y -i \"$2\" -an -vcodec copy -f image2 \"$3\" 2>/dev/null", "sh", thumbDir, fp, thumbPath],
                        function(stdout, exitCode2) {
                            if (exitCode2 === 0)
                                downloadsModel.setProperty(idx, "thumbnailUrl", "file://" + thumbPath);
                        }
                    );
                }

                onExited: (exitCode) => {
                    running = false;
                    if (exitCode === 0) {
                        downloadsModel.setProperty(index, "status", "completed");
                        downloadsModel.setProperty(index, "progress", 100);
                        var fp = downloadsModel.get(index).fullPath || (downloadsModel.get(index).downloadPath + "/" + downloadsModel.get(index).title);
                        _extractThumbnail(fp, index);
                        if (typeof ToastService !== "undefined" && ToastService) {
                            ToastService.showSuccess("Download Completed", downloadsModel.get(index).title || "File downloaded successfully");
                        }
                    } else {
                        if (downloadsModel.get(index).status !== "cancelled") {
                            downloadsModel.setProperty(index, "status", "error");
                            if (typeof ToastService !== "undefined" && ToastService) {
                                ToastService.showError("Download Failed", "Failed to download: " + downloadsModel.get(index).url);
                            }
                        }
                    }
                    root.updateActiveCount();
                }
            }

            // Watcher to handle cancellation
            Connections {
                target: downloadsModel
                function onDataChanged(topLeft, bottomRight, roles) {
                    if (topLeft.row <= index && index <= bottomRight.row) {
                        var item = downloadsModel.get(index);
                        if (item.status === "cancelled" && downloadProc.running) {
                            downloadProc.running = false;
                            root.updateActiveCount();
                        }
                    }
                }
            }
        }
    }



    horizontalBarPill: Component {
        Item {
            implicitWidth: horizontalRow.implicitWidth
            implicitHeight: Theme.iconSize
            anchors.verticalCenter: parent.verticalCenter
            
            property bool draggingOver: false

            Row {
                id: horizontalRow
                spacing: Theme.spacingXS
                anchors.verticalCenter: parent.verticalCenter
                scale: draggingOver ? 1.2 : 1.0
                Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }

                DIcon {
                    name: "download"
                    size: Theme.iconSizeSmall
                    color: draggingOver ? Theme.primary : (root.activeDownloadsCount > 0 ? Theme.primary : Theme.surfaceText)
                    anchors.verticalCenter: parent.verticalCenter
                }

                StyledText {
                    text: root.activeDownloadsCount
                    visible: root.activeDownloadsCount > 0
                    color: Theme.primary
                    font.pixelSize: Theme.fontSizeSmall
                    font.bold: true
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            DropArea {
                anchors.fill: parent
                onEntered: draggingOver = true
                onExited: draggingOver = false
                onDropped: (drop) => {
                    draggingOver = false;
                    var urlStr = "";
                    if (drop.hasUrls && drop.urls.length > 0) {
                        urlStr = drop.urls[0].toString();
                    } else if (drop.hasText) {
                        urlStr = drop.text;
                    }
                    urlStr = urlStr.trim();
                    
                    if (urlStr.indexOf("http://") === 0 || urlStr.indexOf("https://") === 0 || urlStr.indexOf("www.") === 0) {
                        root.activeUrl = urlStr;
                        root.triggerPopout();
                    }
                }
            }
        }
    }

    verticalBarPill: Component {
        Item {
            implicitWidth: Theme.iconSize
            implicitHeight: verticalCol.implicitHeight
            anchors.horizontalCenter: parent.horizontalCenter
            
            property bool draggingOver: false

            Column {
                id: verticalCol
                spacing: 2
                anchors.horizontalCenter: parent.horizontalCenter
                scale: draggingOver ? 1.2 : 1.0
                Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }

                DIcon {
                    name: "download"
                    size: Theme.iconSizeSmall
                    color: draggingOver ? Theme.primary : (root.activeDownloadsCount > 0 ? Theme.primary : Theme.surfaceText)
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                StyledText {
                    text: root.activeDownloadsCount
                    visible: root.activeDownloadsCount > 0
                    color: Theme.primary
                    font.pixelSize: Theme.fontSizeSmall - 2
                    font.bold: true
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }

            DropArea {
                anchors.fill: parent
                onEntered: draggingOver = true
                onExited: draggingOver = false
                onDropped: (drop) => {
                    draggingOver = false;
                    var urlStr = "";
                    if (drop.hasUrls && drop.urls.length > 0) {
                        urlStr = drop.urls[0].toString();
                    } else if (drop.hasText) {
                        urlStr = drop.text;
                    }
                    urlStr = urlStr.trim();
                    
                    if (urlStr.indexOf("http://") === 0 || urlStr.indexOf("https://") === 0 || urlStr.indexOf("www.") === 0) {
                        root.activeUrl = urlStr;
                        root.triggerPopout();
                    }
                }
            }
        }
    }

    // Popout Dialog Layout
    popoutWidth: 440
    popoutHeight: 600

    popoutContent: Component {
        PopoutComponent {
            id: popoutComp
            headerText: ""
            detailsText: ""
            spacing: Theme.spacingM

            component ConnectedFooterButton: Rectangle {
                id: fBtn
                property string iconName: ""
                property string label: ""
                property bool isFirst: false
                property bool isLast: false
                property bool hasAccent: false
                property color accentColor: Theme.primary
                signal clicked

                readonly property real pillR: height / 2
                readonly property real seamR: M3E.innerR
                readonly property real pressR: M3E.pressRadiusS

                height: 36
                clip: true
                color: btnMouse.containsMouse ? Theme.secondaryContainer : Theme.surfaceContainerHigh
                scale: btnMouse.pressed ? M3E.iconBtnPressScale : 1.0

                topLeftRadius: btnMouse.pressed ? pressR : (btnMouse.containsMouse || isFirst ? pillR : seamR)
                bottomLeftRadius: btnMouse.pressed ? pressR : (btnMouse.containsMouse || isFirst ? pillR : seamR)
                topRightRadius: btnMouse.pressed ? pressR : (btnMouse.containsMouse || isLast ? pillR : seamR)
                bottomRightRadius: btnMouse.pressed ? pressR : (btnMouse.containsMouse || isLast ? pillR : seamR)

                Behavior on topLeftRadius {
                    NumberAnimation {
                        duration: M3E.spatialFastMs
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: M3E.curveFastSpatial
                    }
                }
                Behavior on bottomLeftRadius {
                    NumberAnimation {
                        duration: M3E.spatialFastMs
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: M3E.curveFastSpatial
                    }
                }
                Behavior on topRightRadius {
                    NumberAnimation {
                        duration: M3E.spatialFastMs
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: M3E.curveFastSpatial
                    }
                }
                Behavior on bottomRightRadius {
                    NumberAnimation {
                        duration: M3E.spatialFastMs
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: M3E.curveFastSpatial
                    }
                }
                Behavior on color {
                    ColorAnimation {
                        duration: M3E.effectsFastMs
                    }
                }
                Behavior on scale {
                    NumberAnimation {
                        duration: M3E.spatialFastMs
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: M3E.curveFastSpatial
                    }
                }

                Row {
                    anchors.centerIn: parent
                    spacing: 6

                    DIcon {
                        name: fBtn.iconName
                        size: Theme.iconSizeSmall
                        color: fBtn.hasAccent ? fBtn.accentColor : (btnMouse.containsMouse ? Theme.onSecondaryContainer : Theme.surfaceVariantText)
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    StyledText {
                        text: fBtn.label
                        font.pixelSize: Theme.fontSizeSmall
                        font.weight: btnMouse.containsMouse ? Font.Bold : Font.Medium
                        color: fBtn.hasAccent ? fBtn.accentColor : (btnMouse.containsMouse ? Theme.onSecondaryContainer : Theme.surfaceText)
                        elide: Text.ElideRight
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea {
                    id: btnMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: fBtn.clicked()
                }
            }

            component ExpressiveTile: Rectangle {
                id: tile
                property string iconName: ""
                property string title: ""
                property string subtitle: ""
                property bool active: false
                signal clicked

                readonly property bool hovered: tileMouse.containsMouse
                readonly property bool pressed: tileMouse.pressed

                radius: M3E.tileRadius(pressed, hovered, active)
                color: active
                    ? (hovered ? Theme.blend(Theme.primaryContainer, Theme.primary, M3E.activeBlendFactor) : Theme.primaryContainer)
                    : (hovered ? Theme.secondaryContainer : Theme.surfaceContainerHigh)

                border.width: active || hovered ? 1 : 0
                border.color: active
                    ? Theme.withAlpha(Theme.primary, hovered ? 0.55 : 0.28)
                    : Theme.withAlpha(Theme.primary, 0.35)

                scale: pressed ? M3E.tilePressScale : 1.0

                Behavior on radius {
                    NumberAnimation {
                        duration: M3E.spatialFastMs
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: M3E.curveFastSpatial
                    }
                }
                Behavior on scale {
                    NumberAnimation {
                        duration: M3E.spatialFastMs
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: M3E.curveFastSpatial
                    }
                }
                Behavior on color {
                    ColorAnimation {
                        duration: M3E.effectsMs
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: M3E.curveEffects
                    }
                }

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: Theme.spacingM
                    anchors.rightMargin: Theme.spacingM
                    spacing: Theme.spacingS

                    Rectangle {
                        width: tile.hovered || tile.active ? M3E.tileIconPillActiveWidth : M3E.tileIconPillWidth
                        height: M3E.tileIconPillHeight
                        radius: M3E.iconPillRadius(tile.pressed, tile.hovered, height)
                        color: tile.active || tile.hovered ? Theme.primary : Theme.surfaceContainerHighest
                        anchors.verticalCenter: parent.verticalCenter

                        Behavior on width {
                            NumberAnimation {
                                duration: M3E.spatialFastMs
                                easing.type: Easing.BezierSpline
                                easing.bezierCurve: M3E.curveFastSpatial
                            }
                        }
                        Behavior on radius {
                            NumberAnimation {
                                duration: M3E.spatialFastMs
                                easing.type: Easing.BezierSpline
                                easing.bezierCurve: M3E.curveFastSpatial
                            }
                        }
                        Behavior on color {
                            ColorAnimation {
                                duration: M3E.effectsFastMs
                            }
                        }

                        DIcon {
                            anchors.centerIn: parent
                            name: tile.iconName
                            size: Theme.iconSizeMedium
                            color: tile.active || tile.hovered ? Theme.onPrimary : Theme.surfaceText
                        }
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - (tile.hovered || tile.active ? M3E.tileIconPillActiveWidth : M3E.tileIconPillWidth) - parent.spacing
                        spacing: 2

                        StyledText {
                            width: parent.width
                            text: tile.title
                            font.pixelSize: Theme.fontSizeSmall
                            font.weight: tile.hovered || tile.active ? Font.Bold : Font.Medium
                            color: tile.active ? Theme.onPrimaryContainer : (tile.hovered ? Theme.onSecondaryContainer : Theme.surfaceText)
                            elide: Text.ElideRight
                        }

                        StyledText {
                            width: parent.width
                            text: tile.subtitle
                            font.pixelSize: Theme.fontSizeSmall - 1
                            color: tile.active ? Theme.withAlpha(Theme.onPrimaryContainer, 0.75) : Theme.surfaceVariantText
                            elide: Text.ElideRight
                        }
                    }
                }

                MouseArea {
                    id: tileMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: tile.clicked()
                }
            }

            Column {
                width: parent.width
                spacing: Theme.spacingM

                // URL Input Field
                DTextField {
                    id: urlInput
                    width: parent.width
                    height: Theme.buttonHeightS
                    leftIconName: "link"
                    placeholderText: I18n.trFor("mediaDownloader", "Paste video or audio link here...")
                    text: root.activeUrl
                    showClearButton: true
                    onTextChanged: {
                        root.activeUrl = text;
                        if (text.length === 0) {
                            root.customMode = "";
                        }
                    }
                }

                // Media Preview Card (when URL is entered)
                Rectangle {
                    id: previewCard
                    width: parent.width
                    height: 64
                    radius: M3E.innerR
                    color: Theme.surfaceContainerHigh
                    border.width: 1
                    border.color: Theme.withAlpha(Theme.outline, 0.1)
                    clip: true
                    visible: root.activeUrl.length > 0

                    Row {
                        anchors.fill: parent
                        anchors.margins: Theme.spacingS
                        spacing: Theme.spacingM

                        Rectangle {
                            width: 72
                            height: 48
                            radius: M3E.pressRadiusXS
                            color: Theme.surfaceContainerLowest
                            clip: true
                            anchors.verticalCenter: parent.verticalCenter

                            Image {
                                anchors.fill: parent
                                source: root.previewThumbnail
                                fillMode: Image.PreserveAspectCrop
                                visible: root.previewThumbnail !== ""
                            }

                            DIcon {
                                anchors.centerIn: parent
                                visible: root.previewThumbnail === ""
                                name: root.fetchingPreview ? "sync" : "smart_display"
                                size: Theme.iconSizeMedium
                                color: Theme.surfaceVariantText

                                RotationAnimation on rotation {
                                    running: root.fetchingPreview && previewCard.visible
                                    loops: Animation.Infinite
                                    from: 0
                                    to: 360
                                    duration: 1200
                                }
                            }
                        }

                        Column {
                            width: parent.width - 72 - Theme.spacingM
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2

                            StyledText {
                                width: parent.width
                                text: root.previewTitle || (root.fetchingPreview ? I18n.trFor("mediaDownloader", "Fetching video details...") : I18n.trFor("mediaDownloader", "Ready to download"))
                                font.pixelSize: Theme.fontSizeSmall
                                font.weight: Font.Bold
                                color: Theme.surfaceText
                                wrapMode: Text.Wrap
                                maximumLineCount: 2
                                elide: Text.ElideRight
                            }

                            StyledText {
                                width: parent.width
                                text: root.previewAuthor || (root.fetchingPreview ? I18n.trFor("mediaDownloader", "Loading metadata...") : root.activeUrl)
                                font.pixelSize: Theme.fontSizeSmall - 1
                                color: Theme.surfaceVariantText
                                elide: Text.ElideRight
                            }
                        }
                    }
                }

                // 2x2 Grid of Download Options (when URL is entered)
                Grid {
                    id: tilesGrid
                    width: parent.width
                    columns: 2
                    spacing: Theme.spacingM
                    visible: root.activeUrl.length > 0

                    readonly property real tileWidth: (width - spacing) / 2
                    readonly property real tileH: 64

                    // Option 1: Quick Video
                    ExpressiveTile {
                        width: tilesGrid.tileWidth
                        height: tilesGrid.tileH
                        iconName: "videocam"
                        title: I18n.trFor("mediaDownloader", "Quick Video")
                        subtitle: root.quickVideoRes + " · " + root.quickVideoFormat.toUpperCase()
                        onClicked: {
                            root.startDownload(root.activeUrl, "video", root.quickVideoFormat, root.quickVideoRes, root.previewThumbnail);
                            root.activeUrl = "";
                            urlInput.text = "";
                        }
                    }

                    // Option 2: Quick Audio
                    ExpressiveTile {
                        width: tilesGrid.tileWidth
                        height: tilesGrid.tileH
                        iconName: "audiotrack"
                        title: I18n.trFor("mediaDownloader", "Quick Audio")
                        subtitle: root.quickAudioFormat.toUpperCase() + " · " + root.quickAudioQuality
                        onClicked: {
                            root.startDownload(root.activeUrl, "audio", root.quickAudioFormat, root.quickAudioQuality, root.previewThumbnail);
                            root.activeUrl = "";
                            urlInput.text = "";
                        }
                    }

                    // Option 3: Custom Video
                    ExpressiveTile {
                        width: tilesGrid.tileWidth
                        height: tilesGrid.tileH
                        iconName: "tune"
                        title: I18n.trFor("mediaDownloader", "Custom Video")
                        subtitle: I18n.trFor("mediaDownloader", "Quality & format")
                        active: root.customMode === "video"
                        onClicked: {
                            root.customMode = (root.customMode === "video" ? "" : "video");
                            root.customFormat = "mp4";
                            root.customQuality = "1080p";
                        }
                    }

                    // Option 4: Custom Audio
                    ExpressiveTile {
                        width: tilesGrid.tileWidth
                        height: tilesGrid.tileH
                        iconName: "tune"
                        title: I18n.trFor("mediaDownloader", "Custom Audio")
                        subtitle: I18n.trFor("mediaDownloader", "Format & bitrate")
                        active: root.customMode === "audio"
                        onClicked: {
                            root.customMode = (root.customMode === "audio" ? "" : "audio");
                            root.customFormat = "mp3";
                            root.customQuality = "best";
                        }
                    }
                }

                // Custom Configuration Panel
                Rectangle {
                    id: customConfigCard
                    width: parent.width
                    radius: M3E.outerR
                    color: Theme.surfaceContainerHigh
                    border.width: 1
                    border.color: Theme.withAlpha(Theme.outline, 0.12)
                    visible: root.customMode !== ""
                    implicitHeight: customCol.implicitHeight + Theme.spacingM * 2

                    Column {
                        id: customCol
                        anchors.fill: parent
                        anchors.margins: Theme.spacingM
                        spacing: Theme.spacingS

                        Row {
                            width: parent.width
                            spacing: Theme.spacingM

                            // Format Dropdown
                            Column {
                                width: (parent.width - Theme.spacingM) / 2
                                spacing: 4

                                StyledText {
                                    text: I18n.trFor("mediaDownloader", "Format")
                                    font.pixelSize: Theme.fontSizeSmall
                                    font.weight: Font.Medium
                                    color: Theme.surfaceVariantText
                                }

                                DDropdown {
                                    width: parent.width
                                    compactMode: true
                                    options: root.customMode === "video" ? ["mp4", "webm"] : ["mp3", "opus", "flac", "wav"]
                                    currentValue: root.customFormat || (options.length > 0 ? options[0] : "")
                                    onValueChanged: (value) => root.customFormat = value
                                    Component.onCompleted: if (!root.customFormat && options.length > 0) root.customFormat = options[0]
                                }
                            }

                            // Quality Dropdown
                            Column {
                                width: (parent.width - Theme.spacingM) / 2
                                spacing: 4

                                StyledText {
                                    text: I18n.trFor("mediaDownloader", "Quality")
                                    font.pixelSize: Theme.fontSizeSmall
                                    font.weight: Font.Medium
                                    color: Theme.surfaceVariantText
                                }

                                DDropdown {
                                    width: parent.width
                                    compactMode: true
                                    options: root.customMode === "video" ? ["best", "1080p", "720p", "480p"] : ["best", "320k", "192k", "128k"]
                                    currentValue: root.customQuality || (options.length > 0 ? options[0] : "")
                                    onValueChanged: (value) => root.customQuality = value
                                    Component.onCompleted: if (!root.customQuality && options.length > 0) root.customQuality = options[0]
                                }
                            }
                        }

                        DButton {
                            width: parent.width
                            buttonHeight: Theme.buttonHeightS
                            iconName: "download"
                            text: root.customMode === "video" ? I18n.trFor("mediaDownloader", "Download Video") : I18n.trFor("mediaDownloader", "Download Audio")
                            backgroundColor: Theme.primary
                            textColor: Theme.onPrimary
                            onClicked: {
                                root.startDownload(root.activeUrl, root.customMode, root.customFormat, root.customQuality, root.previewThumbnail);
                                root.activeUrl = "";
                                root.customMode = "";
                                urlInput.text = "";
                            }
                        }
                    }
                }

                // Downloads Queue Section Header
                Item {
                    width: parent.width
                    height: 26

                    Row {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Theme.spacingS

                        DIcon {
                            name: "downloading"
                            size: Theme.iconSizeSmall
                            color: Theme.primary
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        StyledText {
                            text: I18n.trFor("mediaDownloader", "Downloads Queue")
                            font.weight: Font.Bold
                            font.pixelSize: Theme.fontSizeSmall
                            color: Theme.surfaceText
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Rectangle {
                            visible: downloadsModel.count > 0
                            width: countBadgeText.implicitWidth + 10
                            height: 16
                            radius: 8
                            color: Theme.surfaceContainerHighest
                            anchors.verticalCenter: parent.verticalCenter

                            StyledText {
                                id: countBadgeText
                                anchors.centerIn: parent
                                text: downloadsModel.count
                                font.pixelSize: Theme.fontSizeSmall - 2
                                font.weight: Font.Bold
                                color: Theme.surfaceVariantText
                            }
                        }
                    }

                    DButton {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        buttonHeight: Theme.buttonHeightXXS
                        horizontalPadding: Theme.spacingS
                        visible: root.hasHistoryItems
                        backgroundColor: "transparent"
                        textColor: Theme.error
                        iconName: "delete_sweep"
                        iconSize: Theme.iconSizeSmall
                        text: I18n.trFor("mediaDownloader", "Clear History")
                        onClicked: {
                            for (var i = downloadsModel.count - 1; i >= 0; i--) {
                                var s = downloadsModel.get(i).status;
                                if (s === "completed" || s === "cancelled" || s === "error") {
                                    downloadsModel.remove(i);
                                }
                            }
                            root.updateActiveCount();
                        }
                    }
                }

                // Downloads Flickable Queue List
                DFlickable {
                    id: queueFlickable
                    width: parent.width
                    contentWidth: width
                    contentHeight: downloadsColumn.implicitHeight
                    height: {
                        var fixedH = Theme.buttonHeightS + 26 + 36 + Theme.spacingM * 5;
                        var dynamicH = 0;
                        if (root.activeUrl.length > 0) {
                            dynamicH += 64 + 140 + Theme.spacingM * 2;
                            if (root.customMode !== "") {
                                dynamicH += 88 + Theme.spacingM;
                            }
                        }
                        return Math.max(120, root.popoutHeight - fixedH - dynamicH);
                    }
                    clip: true

                    Column {
                        id: downloadsColumn
                        width: parent.width
                        spacing: Theme.spacingS

                        // Empty State Card
                        Rectangle {
                            width: parent.width
                            height: 140
                            radius: M3E.outerR
                            color: Theme.surfaceContainerHigh
                            border.width: 1
                            border.color: Theme.withAlpha(Theme.outline, 0.08)
                            visible: downloadsModel.count === 0

                            Column {
                                anchors.centerIn: parent
                                spacing: Theme.spacingS

                                Rectangle {
                                    width: 44
                                    height: 44
                                    radius: 22
                                    color: Theme.surfaceContainerHighest
                                    anchors.horizontalCenter: parent.horizontalCenter

                                    DIcon {
                                        anchors.centerIn: parent
                                        name: "download"
                                        size: Theme.iconSizeMedium
                                        color: Theme.surfaceVariantText
                                    }
                                }

                                StyledText {
                                    text: I18n.trFor("mediaDownloader", "No active downloads")
                                    font.pixelSize: Theme.fontSizeSmall
                                    font.weight: Font.Bold
                                    color: Theme.surfaceText
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }

                                StyledText {
                                    text: I18n.trFor("mediaDownloader", "Paste a video or audio link above to download")
                                    font.pixelSize: Theme.fontSizeSmall - 1
                                    color: Theme.surfaceVariantText
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }
                            }
                        }

                        // Downloads Items Repeater
                        Repeater {
                            model: downloadsModel

                            delegate: Rectangle {
                                id: downloadCard
                                width: parent.width
                                readonly property bool isCompleted: model.status === "completed"
                                readonly property bool isDownloading: model.status === "downloading"
                                readonly property bool isFetching: model.status === "fetching"
                                readonly property bool isError: model.status === "error"
                                readonly property bool isCancelled: model.status === "cancelled"
                                readonly property bool hasThumb: model.thumbnailUrl && model.thumbnailUrl !== ""

                                height: 68
                                radius: M3E.outerR
                                clip: true

                                color: isDownloading
                                    ? Theme.withAlpha(Theme.primary, 0.08)
                                    : (isError ? Theme.withAlpha(Theme.error, 0.08) : Theme.surfaceContainerHigh)

                                border.width: 1
                                border.color: isDownloading
                                    ? Theme.withAlpha(Theme.primary, 0.28)
                                    : (isError ? Theme.withAlpha(Theme.error, 0.3) : Theme.withAlpha(Theme.outline, 0.1))

                                scale: cardMouse.pressed ? M3E.rowPressScale : 1.0

                                Behavior on scale {
                                    NumberAnimation {
                                        duration: M3E.spatialFastMs
                                        easing.type: Easing.BezierSpline
                                        easing.bezierCurve: M3E.curveFastSpatial
                                    }
                                }
                                Behavior on color {
                                    ColorAnimation {
                                        duration: M3E.effectsMs
                                    }
                                }

                                MouseArea {
                                    id: cardMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                }

                                Row {
                                    anchors.fill: parent
                                    anchors.leftMargin: Theme.spacingM
                                    anchors.rightMargin: Theme.spacingM
                                    anchors.topMargin: Theme.spacingS
                                    anchors.bottomMargin: Theme.spacingS
                                    spacing: Theme.spacingM

                                    // Thumbnail / Icon Pill
                                    Rectangle {
                                        width: 44
                                        height: 44
                                        radius: M3E.innerR
                                        color: isCompleted && hasThumb ? "transparent" : (isDownloading ? Theme.primaryContainer : (isError ? Theme.errorContainer : Theme.surfaceContainerHighest))
                                        clip: true
                                        anchors.verticalCenter: parent.verticalCenter

                                        Image {
                                            anchors.fill: parent
                                            source: model.thumbnailUrl || ""
                                            fillMode: Image.PreserveAspectCrop
                                            visible: isCompleted && hasThumb
                                        }

                                        DIcon {
                                            anchors.centerIn: parent
                                            visible: !(isCompleted && hasThumb)
                                            name: {
                                                if (isCompleted) return (model.type === "audio" ? "audiotrack" : "videocam");
                                                if (isError) return "error";
                                                if (isCancelled) return "block";
                                                if (isFetching) return "sync";
                                                return model.type === "audio" ? "audiotrack" : "videocam";
                                            }
                                            size: Theme.iconSizeMedium
                                            color: {
                                                if (isCompleted) return Theme.success;
                                                if (isError) return Theme.error;
                                                if (isDownloading || isFetching) return Theme.primary;
                                                return Theme.surfaceVariantText;
                                            }
                                        }
                                    }

                                    // Title & Status Column
                                    Column {
                                        width: parent.width - 44 - Theme.spacingM - actionButtonsRow.implicitWidth - Theme.spacingS
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 2

                                        StyledText {
                                            width: parent.width
                                            text: model.title
                                            font.pixelSize: Theme.fontSizeSmall
                                            font.weight: Font.Medium
                                            color: Theme.surfaceText
                                            wrapMode: Text.Wrap
                                            maximumLineCount: 2
                                            elide: Text.ElideRight
                                        }

                                        Row {
                                            spacing: Theme.spacingXS
                                            width: parent.width

                                            StyledText {
                                                text: {
                                                    if (isDownloading) return model.speed + " · ETA " + model.eta;
                                                    if (isFetching) return I18n.trFor("mediaDownloader", "Fetching info...");
                                                    if (isCompleted) return (model.format ? model.format.toUpperCase() : "MEDIA") + " · " + I18n.trFor("mediaDownloader", "Completed");
                                                    if (isError) return I18n.trFor("mediaDownloader", "Download failed");
                                                    if (isCancelled) return I18n.trFor("mediaDownloader", "Cancelled");
                                                    return "";
                                                }
                                                font.pixelSize: Theme.fontSizeSmall - 1
                                                color: {
                                                    if (isDownloading) return Theme.surfaceVariantText;
                                                    if (isFetching) return Theme.primary;
                                                    if (isCompleted) return Theme.success;
                                                    if (isError) return Theme.error;
                                                    return Theme.surfaceVariantText;
                                                }
                                                elide: Text.ElideRight
                                            }
                                        }
                                    }

                                    // Action Buttons Row
                                    Row {
                                        id: actionButtonsRow
                                        spacing: Theme.spacingXS
                                        anchors.verticalCenter: parent.verticalCenter

                                        // Progress percentage text
                                        StyledText {
                                            visible: isDownloading
                                            text: model.progress + "%"
                                            font.pixelSize: Theme.fontSizeSmall
                                            font.weight: Font.Bold
                                            color: Theme.primary
                                            anchors.verticalCenter: parent.verticalCenter
                                        }

                                        // Cancel Button
                                        DActionButton {
                                            visible: isDownloading || isFetching
                                            iconName: "close"
                                            iconColor: Theme.error
                                            buttonSize: Theme.buttonHeightXXS
                                            iconSize: Theme.iconSizeSmall
                                            tooltipText: I18n.trFor("mediaDownloader", "Cancel")
                                            onClicked: {
                                                downloadsModel.setProperty(index, "status", "cancelled");
                                            }
                                        }

                                        // Retry Button
                                        DActionButton {
                                            visible: isError || isCancelled
                                            iconName: "refresh"
                                            iconColor: Theme.primary
                                            buttonSize: Theme.buttonHeightXXS
                                            iconSize: Theme.iconSizeSmall
                                            tooltipText: I18n.trFor("mediaDownloader", "Retry")
                                            onClicked: {
                                                downloadsModel.setProperty(index, "status", "fetching");
                                                downloadsModel.setProperty(index, "progress", 0);
                                                downloadsModel.setProperty(index, "speed", "0 B/s");
                                                downloadsModel.setProperty(index, "eta", "--:--");
                                                downloadsModel.setProperty(index, "title", "Fetching title...");
                                                root.startDownload(model.url, model.type, model.format, model.quality, model.thumbnailUrl);
                                                downloadsModel.remove(index);
                                            }
                                        }

                                        // Dismiss Failed/Cancelled Button
                                        DActionButton {
                                            visible: isError || isCancelled
                                            iconName: "delete"
                                            iconColor: Theme.surfaceVariantText
                                            buttonSize: Theme.buttonHeightXXS
                                            iconSize: Theme.iconSizeSmall
                                            tooltipText: I18n.trFor("mediaDownloader", "Remove")
                                            onClicked: {
                                                downloadsModel.remove(index);
                                                root.updateActiveCount();
                                            }
                                        }

                                        // Play Completed Button
                                        DActionButton {
                                            visible: isCompleted
                                            iconName: "play_arrow"
                                            iconColor: Theme.primary
                                            buttonSize: Theme.buttonHeightXXS
                                            iconSize: Theme.iconSizeSmall
                                            tooltipText: I18n.trFor("mediaDownloader", "Play")
                                            onClicked: {
                                                let p = model.fullPath || (model.downloadPath + "/" + model.title);
                                                Quickshell.execDetached(["xdg-open", p]);
                                            }
                                        }

                                        // Open Folder Button
                                        DActionButton {
                                            visible: isCompleted
                                            iconName: "folder"
                                            iconColor: Theme.surfaceVariantText
                                            buttonSize: Theme.buttonHeightXXS
                                            iconSize: Theme.iconSizeSmall
                                            tooltipText: I18n.trFor("mediaDownloader", "Open Folder")
                                            onClicked: {
                                                let p = model.fullPath || (model.downloadPath + "/" + model.title);
                                                let dir = p.substring(0, p.lastIndexOf("/"));
                                                Quickshell.execDetached(["xdg-open", dir]);
                                            }
                                        }

                                        // Remove from History Button
                                        DActionButton {
                                            visible: isCompleted
                                            iconName: "delete"
                                            iconColor: Theme.surfaceVariantText
                                            buttonSize: Theme.buttonHeightXXS
                                            iconSize: Theme.iconSizeSmall
                                            tooltipText: I18n.trFor("mediaDownloader", "Remove from History")
                                            onClicked: {
                                                downloadsModel.remove(index);
                                                root.updateActiveCount();
                                            }
                                        }
                                    }
                                }

                                // Bottom Animated Progress Bar
                                Rectangle {
                                    anchors.bottom: parent.bottom
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    height: 3
                                    color: Theme.withAlpha(Theme.surfaceText, 0.08)
                                    visible: isDownloading || isFetching

                                    Rectangle {
                                        anchors.left: parent.left
                                        anchors.top: parent.top
                                        anchors.bottom: parent.bottom
                                        width: isFetching ? parent.width * 0.35 : parent.width * (Math.max(0, Math.min(100, model.progress)) / 100)
                                        color: isError ? Theme.error : Theme.primary
                                        radius: 1.5

                                        Behavior on width {
                                            NumberAnimation {
                                                duration: 180
                                                easing.type: Easing.OutQuad
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // M3E Connected Footer Row
                Row {
                    id: footerRow
                    width: parent.width
                    height: 36
                    spacing: M3E.groupGap

                    readonly property real availW: Math.max(0, width - spacing * 2)
                    readonly property real colW: Math.floor(availW / 3)

                    ConnectedFooterButton {
                        width: footerRow.colW
                        isFirst: true
                        iconName: "library_music"
                        label: I18n.trFor("mediaDownloader", "Music")
                        onClicked: {
                            Quickshell.execDetached(["xdg-open", root.downloadPathAudio]);
                        }
                    }

                    ConnectedFooterButton {
                        width: footerRow.colW
                        iconName: "video_library"
                        label: I18n.trFor("mediaDownloader", "Videos")
                        onClicked: {
                            Quickshell.execDetached(["xdg-open", root.downloadPathVideo]);
                        }
                    }

                    ConnectedFooterButton {
                        width: footerRow.availW - footerRow.colW * 2
                        isLast: true
                        hasAccent: root.ytdlpOutdated
                        accentColor: Theme.error
                        iconName: root.updatingYtdlp ? "sync" : (root.ytdlpOutdated ? "system_update" : "info")
                        label: {
                            if (root.updatingYtdlp) return I18n.trFor("mediaDownloader", "Updating...");
                            if (root.ytdlpOutdated) return I18n.trFor("mediaDownloader", "Update Engine");
                            return "v" + (root.ytdlpVersion || "---");
                        }
                        onClicked: {
                            if (root.ytdlpOutdated && !root.updatingYtdlp && !root.ytdlpPkgManaged) {
                                root.updateYtdlp();
                            } else {
                                root.checkYtdlpVersion();
                            }
                        }
                    }
                }
            }
        }
    }

}
