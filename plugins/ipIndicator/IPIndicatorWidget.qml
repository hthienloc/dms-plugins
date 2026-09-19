import "./dms-common"
import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Modules.Plugins
import qs.Services
import qs.Widgets

PluginComponent {
    id: root

    // Public IP state
    property string publicIP: ""
    property string publicIPv4: ""
    property string publicIPv6: ""
    property string ispName: ""
    property string countryCode: ""
    property string countryName: ""
    property string regionName: ""
    property string cityName: ""
    property string statusMessage: "..."
    // Settings
    property bool privacyMode: (pluginData.privacyDefault || false)
    property bool pillShowLocal: (pluginData.pillShowLocal || false)
    property bool autoRefresh: (pluginData.autoRefresh ?? true)
    readonly property bool showHints: (pluginData.showHints ?? true)
    readonly property bool showIPv4: (pluginData.showIPv4 ?? true)
    readonly property bool showIPv6: (pluginData.showIPv6 ?? true)
    readonly property bool showISP: (pluginData.showISP ?? true)
    readonly property bool showLocation: (pluginData.showLocation ?? true)
    readonly property bool showLocalIP: (pluginData.showLocalIP ?? true)
    readonly property bool showLocalGateway: (pluginData.showLocalGateway ?? true)
    readonly property bool showLocalInterface: (pluginData.showLocalInterface ?? true)
    readonly property bool showLatency: (pluginData.showLatency ?? true)
    readonly property bool useFlagIcon: (pluginData.useFlagIcon ?? true)
    readonly property string displayMode: (pluginData.displayMode || "country")
    readonly property bool notifyOnIPChange: (pluginData.notifyOnIPChange ?? false)
    readonly property int refreshIntervalMin: (pluginData.refreshInterval ?? 30)
    // Fetching state
    property bool isFetching: false
    // VPN Detection
    property bool vpnActive: false
    property string vpnInterfaceName: ""
    // Latency
    property string latencyMs: ""
    property string latencyError: ""
    // Local Network
    property string localIP: ""
    property string localGateway: ""
    property string localInterface: ""
    // Shell script to fetch local IP address with multiple robust fallback layers
    readonly property string _localIPScript: ["ip route get 1.1.1.1 2>/dev/null | awk '/src/ {for(i=1;i<=NF;i++) if($i==\"src\") {print $(i+1); exit}}'", "hostname -I 2>/dev/null | awk '{print $1}'", "ip address | awk '/inet / && !/127.0.0.1/ {split($2, a, \"/\"); print a[1]; exit}'"].join(" || ")
    // IP change tracking
    property string lastKnownIP: ""
    property string lastKnownCountryCode: ""
    // Provider list for redundancy (primary uses HTTPS for privacy/security)
    property var ipProviders: [{
        "name": "freeipapi.com",
        "url": "https://freeipapi.com/api/json",
        "parser": function(data) {
            return {
                "ip": data.ipAddress || "",
                "isp": data.asnOrganization || "",
                "countryCode": (data.countryCode || "").toLowerCase(),
                "country": data.countryName || "",
                "region": data.regionName || "",
                "city": data.cityName || ""
            };
        }
    }, {
        "name": "ipinfo.io",
        "url": "https://ipinfo.io/json",
        "parser": function(data) {
            return {
                "ip": data.ip || "",
                "isp": data.org || "",
                "countryCode": (data.country || "").toLowerCase(),
                "country": data.country || "",
                "region": data.region || "",
                "city": data.city || ""
            };
        }
    }, {
        "name": "ip-api.com",
        "url": "http://ip-api.com/json",
        "parser": function(data) {
            return {
                "ip": data.query || "",
                "isp": data.isp || data.org || "",
                "countryCode": (data.countryCode || "").toLowerCase(),
                "country": data.country || "",
                "region": data.regionName || data.region || "",
                "city": data.city || ""
            };
        }
    }]
    readonly property color pillColor: {
        if (isFetching)
            return Theme.surfaceText;

        if (privacyMode)
            return Theme.warning;

        if (vpnActive)
            return Theme.success;

        if (pillShowLocal)
            return (localIP && localIP !== "N/A") ? Theme.primary : Theme.surfaceText;

        if (root.publicIP)
            return Theme.primary;

        return Theme.surfaceText;
    }

    // Shell command helpers — thin wrappers around Proc.runCommand
    // for commonly used shell pipelines. Keeps the main logic readable
    // and avoids dense sh -c invocations scattered through the code.
    function _runSh(taskId, script, callback) {
        Proc.runCommand(taskId, ["sh", "-c", script], callback, 50, 3000);
    }

    function _findVpnInterface() {
        _runSh("check-vpn", "ls /sys/class/net | grep -E '^(tun|tap|wg|ppp|proton|tailscale|zero|vpn|cscotun)' | head -1", function(output, exitCode) {
            if (exitCode === 0 && output.trim() !== "") {
                vpnActive = true;
                vpnInterfaceName = output.trim();
            } else {
                vpnActive = false;
                vpnInterfaceName = "";
            }
        });
    }

    function _fetchLocalInterface() {
        _runSh("local-iface", "ip route get 1.1.1.1 | awk '/dev/ {for(i=1;i<=NF;i++) if($i==\"dev\") print $(i+1); exit}'", function(output, exitCode) {
            localInterface = (exitCode === 0 && output.trim() !== "") ? output.trim() : "N/A";
        });
    }

    function _fetchLocalGateway() {
        _runSh("local-gw", "ip route | awk '/default/ {print $3; exit}'", function(output, exitCode) {
            localGateway = (exitCode === 0 && output.trim() !== "") ? output.trim() : "N/A";
        });
    }

    function _fetchLocalIP() {
        _runSh("local-ip-addr", root._localIPScript, function(output, exitCode) {
            localIP = (exitCode === 0 && output.trim() !== "") ? output.trim() : "N/A";
        });
    }

    function checkVPN() {
        _findVpnInterface();
    }

    function measureLatency(target) {
        if (!target)
            target = "8.8.8.8";

        latencyMs = "";
        latencyError = "";
        Proc.runCommand("ping-" + target, ["ping", "-c", "1", "-W", "2", target], function(output, exitCode) {
            if (exitCode !== 0) {
                latencyError = "Fail";
                return ;
            }
            var match = output.match(/time=([\d\.]+)\s*ms/);
            if (match)
                latencyMs = match[1] + " ms";
            else
                latencyError = "N/A";
        }, 50, 5000);
    }

    function fetchLocalDetails() {
        _fetchLocalInterface();
        _fetchLocalGateway();
        _fetchLocalIP();
    }

    function fetchIPInfo() {
        lastKnownIP = publicIP;
        lastKnownCountryCode = countryCode;
        isFetching = true;
        statusMessage = "...";
        tryProvider(0);
    }

    function tryProvider(index) {
        var ipv4Done = false;
        var ipv6Done = false;
        var ipv4Data = null;
        var ipv6Data = null;

        function checkComplete() {
            if (ipv4Done && ipv6Done) {
                if (!ipv4Data && !ipv6Data) {
                    tryProvider(index + 1);
                    return ;
                }
                var bestData = ipv4Data || ipv6Data;
                publicIPv4 = ipv4Data ? ipv4Data.ip : "";
                publicIPv6 = ipv6Data ? ipv6Data.ip : "";
                publicIP = publicIPv4 || publicIPv6 || "";
                ispName = bestData.isp || "";
                countryCode = bestData.countryCode || "";
                countryName = bestData.country || "";
                regionName = bestData.region || "";
                cityName = bestData.city || "";
                var ipChanged = lastKnownIP !== "" && publicIP !== lastKnownIP;
                if (notifyOnIPChange && ipChanged) {
                    var reason = "";
                    if (privacyMode) {
                        reason = "Network connection changed (IP details hidden in Privacy Mode)";
                    } else {
                        var lines = [];
                        if (publicIPv4)
                            lines.push("IPv4: " + publicIPv4 + (countryCode ? " " + root.getFlagEmoji(countryCode) : ""));

                        if (publicIPv6)
                            lines.push("IPv6: " + publicIPv6 + (countryCode ? " " + root.getFlagEmoji(countryCode) : ""));

                        if (ispName)
                            lines.push("ISP: " + ispName);

                        var locs = [];
                        if (cityName)
                            locs.push(cityName);

                        if (regionName)
                            locs.push(regionName);

                        if (countryName)
                            locs.push(countryName);

                        if (locs.length > 0)
                            lines.push("Location: " + locs.join(", "));

                        reason = lines.join("\n");
                    }
                    Proc.runCommand("notify-ip-change", ["notify-send", "IP Indicator", reason], function() {
                    }, 50, 5000);
                }
                lastKnownIP = publicIP;
                lastKnownCountryCode = countryCode;
                isFetching = false;
                statusMessage = "OK";
            }
        }

        if (index >= ipProviders.length) {
            isFetching = false;
            statusMessage = "Error";
            return ;
        }
        var provider = ipProviders[index];
        // Fetch IPv4
        Proc.runCommand("fetch-ip-v4-" + index, ["curl", "-4", "-sL", "--connect-timeout", "3", provider.url], function(output, exitCode) {
            ipv4Done = true;
            if (exitCode === 0 && output) {
                try {
                    var data = JSON.parse(output);
                    var parsed = provider.parser(data);
                    if (parsed && parsed.ip)
                        ipv4Data = parsed;

                } catch (e) {
                }
            }
            checkComplete();
        }, 50, 4000);
        // Fetch IPv6
        Proc.runCommand("fetch-ip-v6-" + index, ["curl", "-6", "-sL", "--connect-timeout", "3", provider.url], function(output, exitCode) {
            ipv6Done = true;
            if (exitCode === 0 && output) {
                try {
                    var data = JSON.parse(output);
                    var parsed = provider.parser(data);
                    if (parsed && parsed.ip)
                        ipv6Data = parsed;

                } catch (e) {
                }
            }
            checkComplete();
        }, 50, 4000);
    }

    function togglePrivacy() {
        privacyMode = !privacyMode;
    }

    function setPillSource(showLocal) {
        if (pillShowLocal === showLocal)
            return;

        pillShowLocal = showLocal;
        pluginService.savePluginData("ipIndicator", "pillShowLocal", showLocal);
    }

    function getDisplayText() {
        if (root.displayMode === "icon")
            return "";

        if (privacyMode)
            return "";

        if (pillShowLocal)
            return localIP || "N/A";

        if (isFetching)
            return "...";

        if (root.publicIP) {
            switch (root.displayMode) {
            case "ip":
                return root.publicIP;
            case "country_ip":
                return (countryCode ? countryCode.toUpperCase() + " " : "") + root.publicIP;
            case "city":
                return (cityName || regionName || countryCode.toUpperCase());
            case "isp":
                return ispName || "N/A";
            case "country_city":
                return (countryCode ? countryCode.toUpperCase() : "") + (cityName || regionName ? " - " + (cityName || regionName) : "");
            case "city_ip":
                return (cityName || regionName ? (cityName || regionName) + " " : "") + root.publicIP;
            case "country":
            default:
                return countryCode ? countryCode.toUpperCase() : root.publicIP;
            }
        }
        return root.statusMessage;
    }

    function getFlagEmoji(code) {
        if (!code || code.length !== 2)
            return "";

        let codePoints = [];
        let upper = code.toUpperCase();
        for (let i = 0; i < upper.length; i++) {
            codePoints.push(127397 + upper.charCodeAt(i));
        }
        return String.fromCodePoint.apply(null, codePoints);
    }

    onRefreshIntervalMinChanged: {
        if (bgRefreshTimer.running)
            bgRefreshTimer.restart();

    }
    Component.onCompleted: {
        checkVPN();
        fetchLocalDetails();
        if (autoRefresh) {
            statusMessage = "...";
            fetchIPInfo();
        } else {
            statusMessage = "Click to fetch";
        }
    }
    pillRightClickAction: () => {
        checkVPN();
        fetchLocalDetails();
        fetchIPInfo();
    }
    popoutWidth: {
        let baseWidth = 330;
        let longestIP = 15;
        if (!privacyMode) {
            if (publicIPv4 && publicIPv4.length > longestIP)
                longestIP = publicIPv4.length;

            if (publicIPv6 && publicIPv6.length > longestIP)
                longestIP = publicIPv6.length;

        }
        if (localIP && localIP.length > longestIP)
            longestIP = localIP.length;

        if (localGateway && localGateway.length > longestIP)
            longestIP = localGateway.length;

        if (longestIP > 15)
            return baseWidth + (longestIP - 15) * 8;

        return baseWidth;
    }
    popoutHeight: {
        let h = 80; // Header + spacing
        // Group 1: Public Connection Card
        if (root.showIPv4 || root.showIPv6 || root.showISP || root.showLocation) {
            h += 44; // Card Margins + Title
            if (root.showIPv4)
                h += 28;

            if (root.showIPv6)
                h += 28;

            if (root.showISP)
                h += 28;

            if (root.showLocation)
                h += 28;

            let rows = 0;
            if (root.showIPv4)
                rows++;

            if (root.showIPv6)
                rows++;

            if (root.showISP)
                rows++;

            if (root.showLocation)
                rows++;

            if (rows > 1)
                h += 12 * (rows - 1);

        }
        // Group 2: Local Network Card
        if (root.showLocalIP || root.showLocalGateway || root.showLocalInterface || root.showLatency) {
            h += 44; // Card Margins + Title
            if (root.showLocalIP)
                h += 28;

            if (root.showLocalGateway)
                h += 28;

            if (root.showLocalInterface)
                h += 28;

            if (root.showLatency)
                h += 28;

            let rows = 0;
            if (root.showLocalIP)
                rows++;

            if (root.showLocalGateway)
                rows++;

            if (root.showLocalInterface)
                rows++;

            if (root.showLatency)
                rows++;

            if (rows > 1)
                h += 12 * (rows - 1);

        }
        if (root.showHints)
            h += 60;

        return h + 40; // margins
    }

    Timer {
        id: bgRefreshTimer

        interval: refreshIntervalMin * 60 * 1000 // Convert minutes to milliseconds
        running: autoRefresh
        repeat: true
        triggeredOnStart: false
        onTriggered: {
            checkVPN();
            fetchLocalDetails();
            fetchIPInfo();
        }
    }

    // Automatically detect network or VPN changes and trigger a fast, responsive refetch
    Connections {
        function onConnectionChanged() {
            vpnRefreshTimer.restart();
        }

        target: NetworkService
    }

    Timer {
        id: vpnRefreshTimer

        interval: 1500 // 1.5s delay to allow routing tables to settle
        running: false
        repeat: false
        onTriggered: {
            checkVPN();
            fetchLocalDetails();
            fetchIPInfo();
        }
    }

    horizontalBarPill: Component {
        Item {
            implicitWidth: pillRow.implicitWidth
            implicitHeight: pillRow.implicitHeight
            width: implicitWidth
            height: implicitHeight

            Row {
                id: pillRow
                spacing: Theme.spacingS

                Image {
                    source: root.countryCode ? "./flags/" + root.countryCode.toLowerCase() + ".png" : ""
                    width: 20
                    height: 14
                    fillMode: Image.PreserveAspectFit
                    anchors.verticalCenter: parent.verticalCenter
                    visible: root.useFlagIcon && !privacyMode && !pillShowLocal && root.countryCode !== ""
                    smooth: true
                    asynchronous: true
                    cache: true
                }

                DankIcon {
                    name: privacyMode ? "visibility_off" : (pillShowLocal ? "lan" : (vpnActive ? "vpn_key" : "public"))
                    size: Theme.iconSizeSmall
                    color: root.pillColor
                    anchors.verticalCenter: parent.verticalCenter
                    visible: !root.useFlagIcon || privacyMode || pillShowLocal || root.countryCode === ""
                }

                StyledText {
                    text: root.getDisplayText()
                    color: root.pillColor
                    font.pixelSize: Theme.barTextSize(root.barThickness, root.barConfig?.fontScale, root.barConfig?.maximizeWidgetText)
                    anchors.verticalCenter: parent.verticalCenter
                    visible: root.displayMode !== "icon" && root.getDisplayText() !== ""
                }
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.MiddleButton
                cursorShape: Qt.PointingHandCursor
                onClicked: (mouse) => {
                    if (mouse.button === Qt.MiddleButton) {
                        root.togglePrivacy();
                    }
                }
            }
        }

    }

    verticalBarPill: Component {
        Item {
            implicitWidth: pillColumn.implicitWidth
            implicitHeight: pillColumn.implicitHeight
            width: implicitWidth
            height: implicitHeight

            Column {
                id: pillColumn
                spacing: Theme.spacingXS

                Image {
                    source: root.countryCode ? "./flags/" + root.countryCode.toLowerCase() + ".png" : ""
                    width: 20
                    height: 14
                    fillMode: Image.PreserveAspectFit
                    anchors.horizontalCenter: parent.horizontalCenter
                    visible: root.useFlagIcon && !privacyMode && !pillShowLocal && root.countryCode !== ""
                    smooth: true
                    asynchronous: true
                    cache: true
                }

                DankIcon {
                    name: privacyMode ? "visibility_off" : (pillShowLocal ? "lan" : (vpnActive ? "vpn_key" : "public"))
                    size: Theme.iconSizeSmall
                    color: root.pillColor
                    anchors.horizontalCenter: parent.horizontalCenter
                    visible: !root.useFlagIcon || privacyMode || pillShowLocal || root.countryCode === ""
                }

                StyledText {
                    text: root.getDisplayText()
                    color: root.pillColor
                    font.pixelSize: Theme.barTextSize(root.barThickness, root.barConfig?.fontScale, root.barConfig?.maximizeWidgetText)
                    anchors.horizontalCenter: parent.horizontalCenter
                    visible: root.displayMode !== "icon" && root.getDisplayText() !== ""
                }
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.MiddleButton
                cursorShape: Qt.PointingHandCursor
                onClicked: (mouse) => {
                    if (mouse.button === Qt.MiddleButton) {
                        root.togglePrivacy();
                    }
                }
            }
        }

    }

    popoutContent: Component {
        FocusScope {
            width: parent ? parent.width : 0
            implicitHeight: mainContent.implicitHeight
            Component.onCompleted: {
                measureLatency("8.8.8.8");
            }

            PopoutComponent {
                id: mainContent

                width: parent.width
                headerText: "IP Indicator" + (vpnActive ? " (VPN)" : "")
                detailsText: privacyMode ? "Hidden" : root.statusMessage
                showCloseButton: false

                Column {
                    width: parent.width
                    spacing: Theme.spacingM

                    // VPN badge
                    Row {
                        spacing: Theme.spacingS
                        visible: vpnActive
                        anchors.horizontalCenter: parent.horizontalCenter

                        StyledText {
                            text: I18n.tr("VPN: ") + vpnInterfaceName
                            color: Theme.success
                            font.pixelSize: Theme.fontSizeMedium
                        }

                    }

                    // Group 1: Public Connection Card
                    StyledRect {
                        width: parent.width
                        height: visible ? (group1Column.implicitHeight + Theme.spacingM * 2) : 0
                        color: Theme.surfaceContainerHigh
                        radius: Theme.cornerRadius
                        border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.1)
                        border.width: 1
                        visible: root.showIPv4 || root.showIPv6 || root.showISP || root.showLocation

                        Column {
                            id: group1Column

                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: Theme.spacingM
                            spacing: Theme.spacingM

                            StyledText {
                                text: I18n.tr("Public Connection")
                                font.pixelSize: Theme.fontSizeSmall
                                font.bold: true
                                color: Theme.primary
                            }

                            // IPv4 Row
                            Row {
                                width: parent.width
                                visible: root.showIPv4

                                StyledText {
                                    text: I18n.tr("IPv4")
                                    font.pixelSize: Theme.fontSizeMedium
                                    color: Theme.surfaceVariantText
                                    width: 100
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Row {
                                    spacing: Theme.spacingS
                                    anchors.verticalCenter: parent.verticalCenter
                                    visible: !privacyMode && publicIPv4 !== ""

                                    StyledText {
                                        text: publicIPv4
                                        font.pixelSize: Theme.fontSizeMedium
                                        color: Theme.surfaceText
                                        font.bold: true
                                        width: Math.min(implicitWidth, parent.parent.width - 100 - 24 - Theme.spacingS)
                                        elide: Text.ElideRight
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                    Rectangle {
                                        width: 24
                                        height: 24
                                        radius: 12
                                        color: copyAreaV4.containsMouse ? Theme.surfaceContainerHigh : "transparent"
                                        anchors.verticalCenter: parent.verticalCenter

                                        DankIcon {
                                            anchors.centerIn: parent
                                            name: "content_copy"
                                            size: Theme.iconSizeSmall - 2
                                            color: Theme.primary
                                        }

                                        MouseArea {
                                            id: copyAreaV4

                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                Proc.runCommand("copy-ipv4", ["wl-copy", "--", publicIPv4], function() {
                                                    if (typeof ToastService !== "undefined" && ToastService)
                                                        ToastService.showInfo("Copied to clipboard");

                                                });
                                            }
                                        }

                                    }

                                }

                                StyledText {
                                    text: "----"
                                    font.pixelSize: Theme.fontSizeMedium
                                    color: Theme.surfaceText
                                    visible: privacyMode || !publicIPv4
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                            }

                            // IPv6 Row
                            Row {
                                width: parent.width
                                visible: root.showIPv6

                                StyledText {
                                    text: I18n.tr("IPv6")
                                    font.pixelSize: Theme.fontSizeMedium
                                    color: Theme.surfaceVariantText
                                    width: 100
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Row {
                                    spacing: Theme.spacingS
                                    anchors.verticalCenter: parent.verticalCenter
                                    visible: !privacyMode && publicIPv6 !== ""

                                    StyledText {
                                        text: publicIPv6
                                        font.pixelSize: Theme.fontSizeMedium
                                        color: Theme.surfaceText
                                        font.bold: true
                                        width: Math.min(implicitWidth, parent.parent.width - 100 - 24 - Theme.spacingS)
                                        elide: Text.ElideRight
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                    Rectangle {
                                        width: 24
                                        height: 24
                                        radius: 12
                                        color: copyAreaV6.containsMouse ? Theme.surfaceContainerHigh : "transparent"
                                        anchors.verticalCenter: parent.verticalCenter

                                        DankIcon {
                                            anchors.centerIn: parent
                                            name: "content_copy"
                                            size: Theme.iconSizeSmall - 2
                                            color: Theme.primary
                                        }

                                        MouseArea {
                                            id: copyAreaV6

                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                Proc.runCommand("copy-ipv6", ["wl-copy", "--", publicIPv6], function() {
                                                    if (typeof ToastService !== "undefined" && ToastService)
                                                        ToastService.showInfo("Copied to clipboard");

                                                });
                                            }
                                        }

                                    }

                                }

                                StyledText {
                                    text: privacyMode ? "----" : ""
                                    font.pixelSize: Theme.fontSizeMedium
                                    color: Theme.surfaceText
                                    visible: privacyMode || !publicIPv6
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                            }

                            // ISP Row
                            Row {
                                width: parent.width
                                visible: root.showISP

                                StyledText {
                                    text: I18n.tr("ISP")
                                    font.pixelSize: Theme.fontSizeMedium
                                    color: Theme.surfaceVariantText
                                    width: 100
                                }

                                StyledText {
                                    text: privacyMode ? "----" : (ispName || "N/A")
                                    font.pixelSize: Theme.fontSizeMedium
                                    color: Theme.surfaceText
                                    width: parent.width - 100
                                    elide: Text.ElideRight
                                }

                            }

                            // Location Row
                            Row {
                                width: parent.width
                                visible: root.showLocation

                                StyledText {
                                    text: I18n.tr("Location")
                                    font.pixelSize: Theme.fontSizeMedium
                                    color: Theme.surfaceVariantText
                                    width: 100
                                }

                                StyledText {
                                    text: privacyMode ? "----" : (countryName ? countryName + (cityName || regionName ? " - " + (cityName || regionName) : "") : "N/A")
                                    font.pixelSize: Theme.fontSizeMedium
                                    color: Theme.surfaceText
                                    width: parent.width - 100
                                    elide: Text.ElideRight
                                }

                            }

                        }

                    }

                    // Group 2: Local Network Card
                    StyledRect {
                        width: parent.width
                        visible: root.showLocalIP || root.showLocalGateway || root.showLocalInterface || root.showLatency
                        height: visible ? (group2Column.implicitHeight + Theme.spacingM * 2) : 0
                        color: Theme.surfaceContainerHigh
                        radius: Theme.cornerRadius
                        border.color: Qt.rgba(Theme.outline.r, Theme.outline.g, Theme.outline.b, 0.1)
                        border.width: 1

                        Column {
                            id: group2Column

                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.margins: Theme.spacingM
                            spacing: Theme.spacingM

                            StyledText {
                                text: I18n.tr("Local Network")
                                font.pixelSize: Theme.fontSizeSmall
                                font.bold: true
                                color: Theme.primary
                            }

                            // Local IP Row
                            Row {
                                width: parent.width
                                visible: root.showLocalIP

                                StyledText {
                                    text: I18n.tr("Local IP")
                                    font.pixelSize: Theme.fontSizeMedium
                                    color: Theme.surfaceVariantText
                                    width: 100
                                }

                                StyledText {
                                    text: localIP || "N/A"
                                    font.pixelSize: Theme.fontSizeMedium
                                    color: Theme.surfaceText
                                    width: parent.width - 100
                                    elide: Text.ElideRight
                                }

                            }

                            // Gateway Row
                            Row {
                                width: parent.width
                                visible: root.showLocalGateway

                                StyledText {
                                    text: I18n.tr("Gateway")
                                    font.pixelSize: Theme.fontSizeMedium
                                    color: Theme.surfaceVariantText
                                    width: 100
                                }

                                StyledText {
                                    text: localGateway || "N/A"
                                    font.pixelSize: Theme.fontSizeMedium
                                    color: Theme.surfaceText
                                    width: parent.width - 100
                                    elide: Text.ElideRight
                                }

                            }

                            // Interface Row
                            Row {
                                width: parent.width
                                visible: root.showLocalInterface

                                StyledText {
                                    text: I18n.tr("Interface")
                                    font.pixelSize: Theme.fontSizeMedium
                                    color: Theme.surfaceVariantText
                                    width: 100
                                }

                                StyledText {
                                    text: localInterface || "N/A"
                                    font.pixelSize: Theme.fontSizeMedium
                                    color: Theme.surfaceText
                                    width: parent.width - 100
                                    elide: Text.ElideRight
                                }

                            }

                            // Latency Row
                            Row {
                                width: parent.width
                                visible: root.showLatency

                                StyledText {
                                    text: I18n.tr("Latency")
                                    font.pixelSize: Theme.fontSizeMedium
                                    color: Theme.surfaceVariantText
                                    width: 100
                                }

                                StyledText {
                                    text: latencyMs ? latencyMs : (latencyError ? latencyError : "")
                                    color: (latencyError ? Theme.error : Theme.surfaceText)
                                    font.pixelSize: Theme.fontSizeMedium
                                }

                            }

                        }

                    }

                    HintSection {
                        showHints: root.showHints
                        width: parent.width

                        HintItem {
                            icon: "mouse"
                            text: I18n.tr("Right-click the bar icon to quickly refresh network status")
                        }

                        HintItem {
                            icon: "visibility_off"
                            text: I18n.tr("Middle-click the bar icon or use the eye button to toggle Privacy Mode")
                        }

                    }

                }

                headerActions: Component {
                    Row {
                        spacing: Theme.spacingS
                        anchors.verticalCenter: parent.verticalCenter

                        // Privacy Button
                        Rectangle {
                            width: 32
                            height: 32
                            radius: 16
                            color: privacyArea.containsMouse ? Theme.surfaceContainerHigh : "transparent"
                            anchors.verticalCenter: parent.verticalCenter

                            DankIcon {
                                anchors.centerIn: parent
                                name: privacyMode ? "visibility_off" : "visibility"
                                size: Theme.iconSizeSmall
                                color: Theme.surfaceText
                            }

                            MouseArea {
                                id: privacyArea

                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: togglePrivacy()
                            }

                        }

                        // Bar Display Source Button
                        Rectangle {
                            width: 32
                            height: 32
                            radius: 16
                            color: sourceArea.containsMouse ? Theme.surfaceContainerHigh : "transparent"
                            anchors.verticalCenter: parent.verticalCenter

                            DankIcon {
                                anchors.centerIn: parent
                                name: pillShowLocal ? "lan" : "public"
                                size: Theme.iconSizeSmall
                                color: Theme.surfaceText
                            }

                            MouseArea {
                                id: sourceArea

                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.setPillSource(!pillShowLocal)
                            }

                        }

                        // Refresh Button
                        Rectangle {
                            width: 32
                            height: 32
                            radius: 16
                            color: refreshArea.containsMouse ? Theme.surfaceContainerHigh : "transparent"
                            anchors.verticalCenter: parent.verticalCenter

                            DankIcon {
                                anchors.centerIn: parent
                                name: "refresh"
                                size: Theme.iconSizeSmall
                                color: Theme.surfaceText
                            }

                            MouseArea {
                                id: refreshArea

                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    checkVPN();
                                    fetchLocalDetails();
                                    fetchIPInfo();
                                }
                            }

                        }

                    }

                }

            }

        }

    }

}
