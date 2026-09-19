import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Widgets
import qs.Modules.Plugins
import qs.Services
import "./dms-common"

PluginComponent {
    id: root

    pluginId: "mediaDownloader"

    pillRightClickAction: function() {
        Proc.runCommand(
            "mediaDownloader.rightClickPaste",
            ["sh", "-c", "wl-paste --no-newline || xclip -selection clipboard -o"],
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
        Proc.runCommand("mediaDownloader.checkUpdate", ["yt-dlp", "--update"], (stdout, exitCode) => {
            var currentVersion = "";
            var latestVersion = "";
            var isPkgManaged = false;
            var lines = stdout.split("\n");
            for (var i = 0; i < lines.length; i++) {
                var line = lines[i].trim();
                if (line.indexOf("Current version:") === 0) {
                    currentVersion = line.substring("Current version:".length).trim();
                } else if (line.indexOf("Latest version:") === 0) {
                    latestVersion = line.substring("Latest version:".length).trim();
                } else if (line.indexOf("package manager") !== -1 || line.indexOf("pip ") !== -1 || line.indexOf("PyPI") !== -1) {
                    isPkgManaged = true;
                }
            }
            
            root.ytdlpPkgManaged = isPkgManaged;
            
            if (isPkgManaged) {
                root.detectPkgManager();
            }
            
            if (currentVersion !== "") {
                var cur = currentVersion.indexOf("@") !== -1 ? currentVersion.split("@")[1] : currentVersion;
                cur = cur.split(" ")[0].trim();
                root.ytdlpVersion = cur;
                
                if (latestVersion !== "") {
                    var lat = latestVersion.indexOf("@") !== -1 ? latestVersion.split("@")[1] : latestVersion;
                    lat = lat.split(" ")[0].trim();
                    root.ytdlpLatestVersion = lat;
                    root.ytdlpOutdated = isPkgManaged ? false : (cur !== lat);
                }
            } else {
                Proc.runCommand("mediaDownloader.getVersion", ["yt-dlp", "--version"], (versionStdout, versionExitCode) => {
                    if (versionExitCode === 0 && versionStdout.trim() !== "") {
                        root.ytdlpVersion = versionStdout.trim().split(" ")[0];
                    }
                });
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
        
        Proc.runCommand("mediaDownloader.doUpdate", ["sh", "-c", "yt-dlp -U 2>&1"], (stdout, exitCode) => {
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
                    var thumbDir = "/tmp/dms-media-downloader/";
                    var thumbPath = thumbDir + "thumb_" + idx + ".jpg";
                    Proc.runCommand("mediaDownloader.extractThumb" + idx,
                        ["sh", "-c", "mkdir -p '" + thumbDir + "' && ffmpeg -y -i \"" + fp + "\" -an -vcodec copy -f image2 \"" + thumbPath + "\" 2>/dev/null"],
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

                DankIcon {
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

                DankIcon {
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
            headerText: "Media Downloader"
            detailsText: ""

            Column {
                width: parent.width
                spacing: Theme.spacingM

                // URL Input Field
                DankTextField {
                    id: urlInput
                    width: parent.width
                    placeholderText: "Paste video or audio link here..."
                    text: root.activeUrl
                    onTextChanged: {
                        root.activeUrl = text;
                        if (text.length === 0) {
                            root.customMode = "";
                        }
                    }
                }

                // Grid of 4 download options (when URL is loaded)
                Grid {
                    width: parent.width
                    columns: 2
                    spacing: Theme.spacingM
                    visible: root.activeUrl.length > 0

                    // Option 1: Quick Video
                    ActionTile {
                        width: (parent.width - Theme.spacingM) / 2
                        height: 64
                        iconName: "videocam"
                        title: "Quick Video"
                        titleFontSize: Theme.fontSizeSmall
                        subtitle: root.quickVideoRes + " (" + root.quickVideoFormat.toUpperCase() + ")"
                        onClicked: {
                            root.startDownload(root.activeUrl, "video", root.quickVideoFormat, root.quickVideoRes, root.previewThumbnail);
                            root.activeUrl = "";
                            urlInput.text = "";
                        }
                    }

                    // Option 2: Quick Audio
                    ActionTile {
                        width: (parent.width - Theme.spacingM) / 2
                        height: 64
                        iconName: "audiotrack"
                        title: "Quick Audio"
                        titleFontSize: Theme.fontSizeSmall
                        subtitle: root.quickAudioFormat.toUpperCase() + " (" + root.quickAudioQuality + ")"
                        onClicked: {
                            root.startDownload(root.activeUrl, "audio", root.quickAudioFormat, root.quickAudioQuality, root.previewThumbnail);
                            root.activeUrl = "";
                            urlInput.text = "";
                        }
                    }

                    // Option 3: Custom Video Options
                    ActionTile {
                        width: (parent.width - Theme.spacingM) / 2
                        height: 64
                        iconName: "settings"
                        title: "Custom Video"
                        titleFontSize: Theme.fontSizeSmall
                        subtitle: "Select quality & format"
                        active: root.customMode === "video"
                        onClicked: {
                            root.customMode = "video";
                            root.customFormat = "mp4";
                            root.customQuality = "1080p";
                        }
                    }

                    // Option 4: Custom Audio Options
                    ActionTile {
                        width: (parent.width - Theme.spacingM) / 2
                        height: 64
                        iconName: "settings"
                        title: "Custom Audio"
                        titleFontSize: Theme.fontSizeSmall
                        subtitle: "Select format & bitrate"
                        active: root.customMode === "audio"
                        onClicked: {
                            root.customMode = "audio";
                            root.customFormat = "mp3";
                            root.customQuality = "best";
                        }
                    }
                }



                // Custom Configuration Subpanels
                Column {
                    width: parent.width
                    spacing: Theme.spacingS
                    visible: root.customMode !== ""

                    Row {
                        width: parent.width
                        spacing: Theme.spacingM

                        // Format Dropdown
                        Column {
                            width: (parent.width - Theme.spacingM) / 2
                            spacing: 4
                            StyledText { text: "Format"; font.pixelSize: Theme.fontSizeSmall - 1; color: Theme.surfaceVariantText }
                            DankDropdown {
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
                            StyledText { text: "Quality"; font.pixelSize: Theme.fontSizeSmall - 1; color: Theme.surfaceVariantText }
                            DankDropdown {
                                width: parent.width
                                compactMode: true
                                options: root.customMode === "video" ? ["best", "1080p", "720p", "480p"] : ["best", "320k", "192k", "128k"]
                                currentValue: root.customQuality || (options.length > 0 ? options[0] : "")
                                onValueChanged: (value) => root.customQuality = value
                                Component.onCompleted: if (!root.customQuality && options.length > 0) root.customQuality = options[0]
                            }
                        }
                    }

                    DankButton {
                        width: parent.width
                        buttonHeight: 36
                        text: "Start Custom Download"
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

                Separator {}

                // Active / Past Downloads List
                Item {
                    width: parent.width
                    height: Theme.fontSizeSmall + 8

                    StyledText {
                        text: "Downloads Queue"
                        font.weight: Font.Bold
                        font.pixelSize: Theme.fontSizeSmall
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    DankButton {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        buttonHeight: 24
                        horizontalPadding: Theme.spacingS
                        enabled: root.hasHistoryItems
                        backgroundColor: "transparent"
                        textColor: root.hasHistoryItems ? Theme.error : Theme.surfaceVariantText
                        iconName: "delete_sweep"
                        iconSize: 14
                        text: "Clear History"
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

                ScrollView {
                    width: parent.width
                    height: {
                        var h = 300;
                        if (root.activeUrl !== "") {
                            h -= 130; // 2 rows of ActionTile (64px) + spacing
                            if (root.customMode !== "") {
                                h -= 90;
                            }
                        }
                        return Math.max(100, h);
                    }
                    clip: true

                    Column {
                        width: parent.width
                        spacing: Theme.spacingM

                        Repeater {
                            model: downloadsModel
                            delegate: Rectangle {
                                width: parent.width
                                readonly property bool isCompleted: model.status === "completed"
                                readonly property bool hasThumb: model.thumbnailUrl && model.thumbnailUrl !== ""
                                height: isCompleted ? 88 : 72
                                color: Theme.surfaceContainerHigh
                                radius: Theme.cornerRadius
                                border.color: Theme.withAlpha(Theme.outline, 0.1)
                                clip: true

                                Row {
                                    anchors.fill: parent
                                    anchors.topMargin: 10
                                    anchors.bottomMargin: 14
                                    anchors.leftMargin: Theme.spacingM
                                    anchors.rightMargin: Theme.spacingM
                                    spacing: Theme.spacingM

                                    // Thumbnail for completed downloads
                                    Rectangle {
                                        width: 52
                                        height: 52
                                        radius: Theme.cornerRadius / 2
                                        color: Theme.surfaceContainerLowest
                                        clip: true
                                        visible: isCompleted && hasThumb
                                        anchors.verticalCenter: parent.verticalCenter

                                        Image {
                                            anchors.fill: parent
                                            source: model.thumbnailUrl
                                            fillMode: Image.PreserveAspectCrop
                                        }
                                    }

                                    Column {
                                        width: {
                                            if (isCompleted && hasThumb) parent.width - 52 - Theme.spacingM
                                            else parent.width
                                        }
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 4

                                        Item {
                                            width: parent.width
                                            height: Math.max(titleText.implicitHeight, progressText.implicitHeight)

                                            StyledText {
                                                id: titleText
                                                text: model.title
                                                anchors.left: parent.left
                                                anchors.right: progressText.left
                                                anchors.rightMargin: Theme.spacingM
                                                anchors.verticalCenter: parent.verticalCenter
                                                elide: Text.ElideRight
                                                font.pixelSize: Theme.fontSizeSmall
                                                font.weight: Font.Medium
                                            }
                                            StyledText {
                                                id: progressText
                                                text: model.status === "completed" ? "Done" : (model.status === "error" ? "Error" : (model.status === "cancelled" ? "Cancelled" : (model.status === "embedding" ? "Embedding..." : model.progress + "%")))
                                                anchors.right: parent.right
                                                anchors.verticalCenter: parent.verticalCenter
                                                font.pixelSize: Theme.fontSizeSmall - 1
                                                color: model.status === "error" ? Theme.error : (model.status === "completed" ? Theme.success : (model.status === "embedding" ? Theme.success : Theme.primary))
                                            }
                                        }

                                        Item {
                                            width: parent.width
                                            height: 28

                                            StyledText {
                                                text: model.status === "downloading" ? model.speed + " - ETA " + model.eta : (model.status === "fetching" ? "Initializing..." : "")
                                                font.pixelSize: Theme.fontSizeSmall - 2
                                                color: Theme.surfaceVariantText
                                                anchors.left: parent.left
                                                anchors.right: actionButtonsRow.left
                                                anchors.rightMargin: Theme.spacingS
                                                elide: Text.ElideRight
                                                anchors.verticalCenter: parent.verticalCenter
                                            }

                                            Row {
                                                id: actionButtonsRow
                                                anchors.right: parent.right
                                                anchors.verticalCenter: parent.verticalCenter
                                                spacing: 4

                                                // Cancel Button
                                                DankActionButton {
                                                    visible: model.status === "downloading" || model.status === "fetching"
                                                    iconName: "close"
                                                    iconColor: Theme.error
                                                    tooltipText: I18n.tr("Cancel")
                                                    onClicked: {
                                                        downloadsModel.setProperty(index, "status", "cancelled");
                                                    }
                                                }

                                                // Retry Button
                                                DankActionButton {
                                                    visible: model.status === "error" || model.status === "cancelled"
                                                    iconName: "refresh"
                                                    iconColor: Theme.primary
                                                    tooltipText: I18n.tr("Retry")
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

                                                // Play Music/Video Button
                                                DankActionButton {
                                                    visible: isCompleted
                                                    iconName: "play_arrow"
                                                    iconColor: Theme.primary
                                                    tooltipText: I18n.tr("Play")
                                                    onClicked: {
                                                        let p = model.fullPath || (model.downloadPath + "/" + model.title);
                                                        Quickshell.execDetached(["xdg-open", p]);
                                                    }
                                                }

                                                // Open File Button
                                                DankActionButton {
                                                    visible: isCompleted
                                                    iconName: "open_in_new"
                                                    iconColor: Theme.primary
                                                    tooltipText: I18n.tr("Open File")
                                                    onClicked: {
                                                        let p = model.fullPath || (model.downloadPath + "/" + model.title);
                                                        Quickshell.execDetached(["xdg-open", p]);
                                                    }
                                                }

                                                // Open Folder Button
                                                DankActionButton {
                                                    visible: isCompleted
                                                    iconName: "folder"
                                                    iconColor: Theme.primary
                                                    tooltipText: I18n.tr("Open Folder")
                                                    onClicked: {
                                                        let p = model.fullPath || (model.downloadPath + "/" + model.title);
                                                        let dir = p.substring(0, p.lastIndexOf("/"));
                                                        Quickshell.execDetached(["xdg-open", dir]);
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }

                                // Dynamic Progress Bar — anchored with gap
                                Rectangle {
                                    anchors.bottom: parent.bottom
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    height: 4
                                    color: Theme.withAlpha(Theme.surfaceText, 0.1)

                                    Rectangle {
                                        width: parent.width * (model.progress / 100)
                                        height: parent.height
                                        color: model.status === "error" ? Theme.error : (model.status === "completed" ? Theme.success : Theme.primary)
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    acceptedButtons: Qt.RightButton
                                    onClicked: (mouse) => {
                                        if (mouse.button === Qt.RightButton && isCompleted) {
                                            root.activeHistoryIndex = index;
                                            historyMenu.open(mouse.x, mouse.y);
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // yt-dlp Version Info
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: Theme.spacingS
                    opacity: root.ytdlpVersion !== "" ? 0.7 : 0.0
                    Behavior on opacity { NumberAnimation { duration: 200 } }

                    DankIcon {
                        name: root.ytdlpOutdated ? "warning" : "info"
                        size: 12
                        color: root.ytdlpOutdated ? Theme.error : (root.ytdlpPkgManaged ? Theme.surfaceVariantText : Theme.surfaceVariantText)
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    StyledText {
                        text: {
                            if (root.ytdlpPkgManaged)
                                return "yt-dlp v" + root.ytdlpVersion + " (via " + (root.ytdlpPkgCmd || "package manager") + ")";
                            if (root.ytdlpOutdated)
                                return "yt-dlp v" + root.ytdlpVersion + " (Update available: v" + root.ytdlpLatestVersion + ")";
                            return "yt-dlp v" + root.ytdlpVersion;
                        }
                        font.pixelSize: Theme.fontSizeSmall - 2
                        color: root.ytdlpOutdated ? Theme.error : Theme.surfaceVariantText
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    DankButton {
                        text: "Update"
                        visible: root.ytdlpOutdated && !root.updatingYtdlp && !root.ytdlpPkgManaged
                        buttonHeight: 20
                        horizontalPadding: Theme.spacingS
                        backgroundColor: Theme.withAlpha(Theme.primary, 0.1)
                        textColor: Theme.primary
                        anchors.verticalCenter: parent.verticalCenter
                        onClicked: {
                            root.updateYtdlp();
                        }
                    }

                    StyledText {
                        text: "Updating..."
                        visible: root.updatingYtdlp
                        font.pixelSize: Theme.fontSizeSmall - 2
                        font.italic: true
                        color: Theme.primary
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }
        }
    }

    property int activeHistoryIndex: -1
    Popup {
        id: historyMenu
        width: 180
        height: menuColumn.implicitHeight + Theme.spacingS * 2
        padding: 0
        background: Rectangle {
            color: "transparent"
        }

        contentItem: StyledRect {
            color: Theme.surfaceContainer
            radius: Theme.cornerRadius
            border.color: Theme.withAlpha(Theme.outline, 0.15)
            border.width: 1

            Column {
                id: menuColumn
                anchors.fill: parent
                anchors.margins: Theme.spacingS
                spacing: 2

                Repeater {
                    model: [
                        {
                            text: I18n.tr("Play Now"),
                            icon: "play_arrow",
                            action: function() {
                                let item = downloadsModel.get(root.activeHistoryIndex);
                                let p = item.fullPath || (item.downloadPath + "/" + item.title);
                                Quickshell.execDetached(["xdg-open", p]);
                            }
                        },
                        {
                            text: I18n.tr("Open File"),
                            icon: "open_in_new",
                            action: function() {
                                let item = downloadsModel.get(root.activeHistoryIndex);
                                let p = item.fullPath || (item.downloadPath + "/" + item.title);
                                Quickshell.execDetached(["xdg-open", p]);
                            }
                        },
                        {
                            text: I18n.tr("Open Folder"),
                            icon: "folder",
                            action: function() {
                                let item = downloadsModel.get(root.activeHistoryIndex);
                                let p = item.fullPath || (item.downloadPath + "/" + item.title);
                                let dir = p.substring(0, p.lastIndexOf("/"));
                                Quickshell.execDetached(["xdg-open", dir]);
                            }
                        },
                        {
                            text: I18n.tr("Remove from History"),
                            icon: "delete",
                            action: function() {
                                downloadsModel.remove(root.activeHistoryIndex);
                                root.updateActiveCount();
                            }
                        }
                    ]

                    delegate: MouseArea {
                        width: parent.width
                        height: 32
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor

                        Rectangle {
                            anchors.fill: parent
                            color: parent.containsMouse ? Theme.withAlpha(Theme.primary, 0.1) : "transparent"
                            radius: Theme.cornerRadius / 2
                        }

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: Theme.spacingS
                            anchors.rightMargin: Theme.spacingS
                            spacing: Theme.spacingS

                            DankIcon {
                                name: modelData.icon
                                size: 16
                                color: Theme.surfaceText
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            StyledText {
                                text: modelData.text
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.surfaceText
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        onClicked: {
                            modelData.action();
                            historyMenu.close();
                        }
                    }
                }
            }
        }
    }
}
