import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.Plugins
import "./dms-common"

PluginComponent {
    id: root

    property var games: []
    property bool isLoading: false
    property string statusMessage: ""

    property int launchingId: -1
    readonly property bool isLaunching: launchingId !== -1
    property string currentSlug: ""
    property bool _internalUpdate: false

    Component.onCompleted: {
        console.log("Lutris Launcher: Plugin initialized")
        // Load cached list instantly, then fetch update in background
        const cached = pluginData.cachedGames
        if (cached && cached.length > 0) {
            gamesModel.clear()
            for (var i = 0; i < cached.length; i++) {
                gamesModel.append(cached[i])
            }
            updateFilteredModel()
            statusMessage = cached.length + " games (cached)"
        }
        fetchGames()
    }

    ListModel {
        id: gamesModel
    }

    ListModel {
        id: filteredGamesModel
    }

    property string searchQuery: ""
    property string filteredStatus: ""
    property bool favoriteOnly: false
    property bool blacklistOnly: false

    property int sortMode: pluginData.sortMode ?? 0
    property var favorites: pluginData.favorites ?? []
    property var playCounts: pluginData.playCounts ?? {}
    property var blacklist: pluginData.blacklist ?? []
    property string dateFormat: pluginData.dateFormat ?? "YYYY - MM - DD"
    readonly property bool showHints: pluginData.showHints ?? true

    function getFormattedDate(timestamp) {
        if (!timestamp) return "Never played"
        var d = new Date(timestamp)
        
        if (dateFormat === "relative") {
            var now = Date.now()
            var diff = now - timestamp
            var seconds = Math.floor(diff / 1000)
            var minutes = Math.floor(seconds / 60)
            var hours = Math.floor(minutes / 60)
            var days = Math.floor(hours / 24)
            
            if (days > 0) return days + "d ago"
            if (hours > 0) return hours + "h ago"
            if (minutes > 0) return minutes + "m ago"
            return "Just now"
        }

        var y = d.getFullYear()
        var m = (d.getMonth() + 1).toString().padStart(2, '0')
        var day = d.getDate().toString().padStart(2, '0')

        if (dateFormat === "DD / MM / YYYY") return day + " / " + m + " / " + y
        if (dateFormat === "MM / DD / YYYY") return m + " / " + day + " / " + y
        return y + " - " + m + " - " + day // Default YYYY - MM - DD
    }

    onPluginDataChanged: {
        if (pluginData.blacklist !== undefined) {
            var blacklistChanged = false;
            if (!root.blacklist || root.blacklist.length !== pluginData.blacklist.length) {
                blacklistChanged = true;
            } else {
                for (var i = 0; i < pluginData.blacklist.length; i++) {
                    if (root.blacklist[i] !== pluginData.blacklist[i]) {
                        blacklistChanged = true;
                        break;
                    }
                }
            }
            if (blacklistChanged) {
                blacklist = pluginData.blacklist
                updateFilteredModel()
            }
        }
        if (pluginData.dateFormat !== undefined) {
            dateFormat = pluginData.dateFormat
        }
    }

    readonly property var sortModes: [
        { label: "Name", icon: "sort_by_alpha" },
        { label: "Recently Played", icon: "history" },
        { label: "Most Played", icon: "trending_up" }
    ]

    function fetchGames() {
        console.log("Lutris Launcher: Fetching games from SQLite DB...")
        isLoading = true
        statusMessage = "Loading games..."
        
        const pyScript =
            "import sqlite3,json,os;" +
            "db=os.path.expanduser('~/.local/share/lutris/pga.db');" +
            "conn=sqlite3.connect('file:'+db+'?mode=ro',uri=True);" +
            "conn.row_factory=sqlite3.Row;" +
            "rows=conn.execute('SELECT id,name,slug,runner,platform,lastplayed,playtime FROM games WHERE installed=1 ORDER BY name COLLATE NOCASE').fetchall();" +
            "cover=os.path.expanduser('~/.local/share/lutris/coverart/');" +
            "out=[{" +
              "'id':r['id'],'name':r['name'],'slug':r['slug'],'runner':r['runner'],'platform':r['platform']," +
              "'lastplayed':r['lastplayed'] or 0,'playtimeSeconds':float(r['playtime'] or 0)," +
              "'coverPath':cover+r['slug']+'.jpg' if os.path.exists(cover+r['slug']+'.jpg') else ''" +
            "} for r in rows];" +
            "print(json.dumps(out))"

        Proc.runCommand(
            "lutris-launcher-fetch",
            ["python3", "-c", pyScript],
            function(output, exitCode) {
                isLoading = false
                if (exitCode !== 0 || !output || output.trim() === "") {
                    statusMessage = "Error reading Lutris database"
                    console.warn("Lutris Launcher: DB query failed:", output)
                    return
                }
                try {
                    var parsedGames = JSON.parse(output.trim())
                    console.log("Lutris Launcher: Loaded " + parsedGames.length + " games from DB")

                    sortGames(parsedGames)

                    gamesModel.clear()
                    var gamesListForSettings = []
                    for (var i = 0; i < parsedGames.length; i++) {
                        gamesModel.append(parsedGames[i])
                        gamesListForSettings.push({
                            "name": parsedGames[i].name,
                            "slug": parsedGames[i].slug
                        })
                    }
                    pluginService?.savePluginData(pluginId, "cachedGames", parsedGames)
                    pluginService?.savePluginData(pluginId, "allGames", gamesListForSettings)

                    updateFilteredModel()
                    statusMessage = parsedGames.length + " games found"
                } catch(e) {
                    console.error("Lutris Launcher: Error parsing DB output:", e)
                    statusMessage = "Error parsing game list"
                }
            },
            0
        )
    }

    function launchGame(gameId, slug) {
        if (isLaunching) return

        console.log("Lutris Launcher: Launching " + slug)
        launchingId = gameId

        var newCounts = Object.assign({}, playCounts)
        if (!newCounts[slug]) newCounts[slug] = { count: 0, lastPlayed: 0 }
        newCounts[slug].count++
        newCounts[slug].lastPlayed = Date.now()
        playCounts = newCounts
        saveStats()

        Quickshell.execDetached(["xdg-open", "lutris:rungameid/" + gameId])

        // Reset launching state after a delay
        launchResetTimer.restart()
    }

    Timer {
        id: launchResetTimer
        interval: 20000
        repeat: false
        onTriggered: root.launchingId = -1
    }

    function updateFilteredModel() {
        root._internalUpdate = true
        var previousSlug = root.currentSlug
        filteredGamesModel.clear()
        var query = searchQuery.toLowerCase().trim()
        
        var currentBlacklist = root.blacklist || []
        var blackSet = new Set()
        for (var b = 0; b < currentBlacklist.length; b++) {
            blackSet.add(currentBlacklist[b])
        }

        var foundIndex = -1
        var currentCount = 0

        for (var i = 0; i < gamesModel.count; i++) {
            var game = gamesModel.get(i)
            var isBlacklisted = blackSet.has(game.slug)

            if (blacklistOnly) {
                if (!isBlacklisted) continue;
            } else {
                if (isBlacklisted) continue;
            }

            var matchesSearch = query === "" || (game.name && game.name.toLowerCase().includes(query))
            var matchesFavorite = !favoriteOnly || root.isFavorite(game.slug)
            if (matchesSearch && matchesFavorite) {
                if (game.slug === previousSlug) foundIndex = currentCount

                filteredGamesModel.append({
                    "id": game.id,
                    "name": game.name,
                    "slug": game.slug,
                    "coverPath": game.coverPath,
                    "isVirtual": false,
                    "isBlacklisted": isBlacklisted
                })
                currentCount++
            }
        }
        
        console.log("Lutris Launcher: Filtered model updated. Count: " + filteredGamesModel.count)
        filteredStatus = query === "" ? "" : filteredGamesModel.count + " of " + gamesModel.count + " games"

        // Restore highlight
        if (foundIndex === -1 && filteredGamesModel.count > 0) {
            foundIndex = 0
        }

        if (foundIndex !== -1) {
            Qt.callLater(() => {
                if (typeof gamesGrid !== "undefined" && gamesGrid) {
                    gamesGrid.currentIndex = foundIndex
                    // Explicitly update currentSlug to ensure it's in sync even if currentIndex didn't "change"
                    if (gamesGrid.currentIndex >= 0 && gamesGrid.currentIndex < gamesGrid.model.count) {
                        root.currentSlug = gamesGrid.model.get(gamesGrid.currentIndex).slug
                    }
                }
                root._internalUpdate = false
            })
        } else {
            root._internalUpdate = false
            root.currentSlug = ""
        }
    }

    function onSearchTextChanged(text) {
        root.searchQuery = text
        updateFilteredModel()
    }

    function saveStats() {
        try {
            pluginService?.savePluginData(pluginId, "favorites", favorites)
            pluginService?.savePluginData(pluginId, "playCounts", playCounts)
            pluginService?.savePluginData(pluginId, "sortMode", sortMode)
            pluginService?.savePluginData(pluginId, "blacklist", blacklist)
        } catch(e) {
            console.log("Lutris Launcher: Failed to save stats", e)
        }
    }

    function sortGames(games) {
        var favSet = new Set(favorites)
        if (sortMode === 0) {
            games.sort((a, b) => {
                var aFav = favSet.has(a.slug) ? 0 : 1
                var bFav = favSet.has(b.slug) ? 0 : 1
                if (aFav !== bFav) return aFav - bFav
                return (a.name || "").localeCompare(b.name || "")
            })
        } else if (sortMode === 1) {
            games.sort((a, b) => {
                var aFav = favSet.has(a.slug) ? 0 : 1
                var bFav = favSet.has(b.slug) ? 0 : 1
                if (aFav !== bFav) return aFav - bFav
                var aTime = (playCounts[a.slug]?.lastPlayed || 0)
                var bTime = (playCounts[b.slug]?.lastPlayed || 0)
                return bTime - aTime
            })
        } else if (sortMode === 2) {
            games.sort((a, b) => {
                var aFav = favSet.has(a.slug) ? 0 : 1
                var bFav = favSet.has(b.slug) ? 0 : 1
                if (aFav !== bFav) return aFav - bFav
                var aCount = playCounts[a.slug]?.count || 0
                var bCount = playCounts[b.slug]?.count || 0
                return bCount - aCount
            })
        }
    }

    function toggleFavorite(slug) {
        var newFavs = favorites.slice()
        var idx = newFavs.indexOf(slug)
        if (idx >= 0) {
            newFavs.splice(idx, 1)
        } else {
            newFavs.push(slug)
            // If adding to favorites, remove from blacklist automatically
            var newBlacklist = (root.blacklist || []).slice()
            var bIdx = newBlacklist.indexOf(slug)
            if (bIdx >= 0) {
                newBlacklist.splice(bIdx, 1)
                root.blacklist = newBlacklist
            }
        }
        favorites = newFavs
        saveStats()
        updateFilteredModel()
    }

    function isFavorite(slug) {
        return favorites.indexOf(slug) >= 0
    }

    function toggleBlacklist(slug) {
        var currentBlacklist = (pluginData.blacklist || []).slice()
        var idx = currentBlacklist.indexOf(slug)
        if (idx >= 0) {
            currentBlacklist.splice(idx, 1)
        } else {
            currentBlacklist.push(slug)
        }
        pluginService.savePluginData(pluginId, "blacklist", currentBlacklist)
    }

    function sortGamesInternal() {
        var games = []
        for (var i = 0; i < gamesModel.count; i++) {
            var g = gamesModel.get(i)
            games.push({
                "id": g.id,
                "name": g.name,
                "slug": g.slug,
                "coverPath": g.coverPath
            })
        }
        sortGames(games)
        gamesModel.clear()
        for (var j = 0; j < games.length; j++) {
            gamesModel.append(games[j])
        }
        updateFilteredModel()
    }

    function cycleSortMode() {
        sortMode = (sortMode + 1) % sortModes.length
        saveStats()
        sortGamesInternal()
    }

    horizontalBarPill: Component {
        DankIcon {
            name: (root.isLaunching || root.isLoading) ? "refresh" : "sports_esports"
            size: Theme.iconSizeSmall
            color: (root.isLaunching || root.isLoading) ? Theme.warning : Theme.primary
            anchors.verticalCenter: parent.verticalCenter
            
            rotation: (root.isLaunching || root.isLoading) ? 0 : 0 // Placeholder to trigger binding if needed

            NumberAnimation on rotation {
                from: 0; to: 360; duration: 1000
                loops: Animation.Infinite
                running: root.isLaunching || root.isLoading
            }

            Behavior on rotation {
                enabled: !root.isLaunching && !root.isLoading
                NumberAnimation { duration: 300; easing.type: Easing.OutQuad }
            }
            
            onRotationChanged: {
                if (!root.isLaunching && !root.isLoading && rotation !== 0) {
                    rotation = 0
                }
            }
        }
    }

    verticalBarPill: Component {
        DankIcon {
            name: (root.isLaunching || root.isLoading) ? "refresh" : "sports_esports"
            size: Theme.iconSizeSmall
            color: (root.isLaunching || root.isLoading) ? Theme.warning : Theme.primary
            anchors.horizontalCenter: parent.horizontalCenter

            NumberAnimation on rotation {
                from: 0; to: 360; duration: 1000
                loops: Animation.Infinite
                running: root.isLaunching || root.isLoading
            }

            Behavior on rotation {
                enabled: !root.isLaunching && !root.isLoading
                NumberAnimation { duration: 300; easing.type: Easing.OutQuad }
            }
            
            onRotationChanged: {
                if (!root.isLaunching && !root.isLoading && rotation !== 0) {
                    rotation = 0
                }
            }
        }
    }

    popoutContent: Component {
        FocusScope {
            id: contentFocusScope
            width: parent ? parent.width : 0
            implicitHeight: mainContent.implicitHeight
            focus: true

            property var parentPopout: null
            Connections {
                target: parentPopout
                function onOpened() {
                    Qt.callLater(() => {
                        searchField.forceActiveFocus();
                    });
                }
            }

            PopoutComponent {
                id: mainContent
                width: parent.width
                headerText: "Lutris Launcher"
                detailsText: root.isLaunching ? "Launching game..." : root.statusMessage
                showCloseButton: false
                
                Component.onDestruction: {
                    root.searchQuery = "";
                    root.updateFilteredModel();
                }

                Column {
                    width: parent.width
                    spacing: Theme.spacingM

                    Row {
                        width: parent.width
                        height: 44
                        spacing: Theme.spacingS

                        DankTextField {
                            id: searchField
                            width: parent.width - (36 + Theme.spacingS) * 5 - Theme.spacingS
                            height: parent.height
                            leftIconName: "search"
                            placeholderText: "Search your library..."
                            backgroundColor: Theme.surfaceContainerLow
                            normalBorderColor: "transparent"
                            focusedBorderColor: Theme.primary
                            showClearButton: true
                            onTextEdited: root.onSearchTextChanged(text)
                            onTextChanged: {
                                if (text === "") {
                                    root.searchQuery = "";
                                    root.updateFilteredModel();
                                }
                            }
                            Keys.onDownPressed: {
                                if (root.isLaunching) return;
                                if (filteredGamesModel.count > 0) {
                                    gamesGrid.currentIndex = 0;
                                    gamesGrid.forceActiveFocus();
                                }
                            }
                            Keys.onTabPressed: {
                                if (root.isLaunching) return;
                                if (filteredGamesModel.count > 0) {
                                    gamesGrid.currentIndex = 0;
                                    gamesGrid.forceActiveFocus();
                                }
                            }
                        }

                        Row {
                            height: parent.height
                            spacing: Theme.spacingXS

                            DankButton {
                                width: 36; height: 36; iconName: sortModes[sortMode].icon
                                backgroundColor: Theme.surfaceContainerHigh
                                textColor: Theme.surfaceText
                                onClicked: root.cycleSortMode()
                            }

                            DankButton {
                                width: 36; height: 36; iconName: "star"
                                backgroundColor: root.favoriteOnly ? Theme.warning : Theme.surfaceContainerHigh
                                textColor: root.favoriteOnly ? Theme.onPrimary : Theme.surfaceText
                                onClicked: {
                                    root.favoriteOnly = !root.favoriteOnly
                                    if (root.favoriteOnly) root.blacklistOnly = false
                                    root.updateFilteredModel()
                                }
                            }

                            DankButton {
                                width: 36; height: 36; iconName: "visibility_off"
                                backgroundColor: root.blacklistOnly ? Theme.error : Theme.surfaceContainerHigh
                                textColor: root.blacklistOnly ? Theme.onPrimary : Theme.surfaceText
                                onClicked: {
                                    root.blacklistOnly = !root.blacklistOnly
                                    if (root.blacklistOnly) root.favoriteOnly = false
                                    root.updateFilteredModel()
                                }
                            }

                            DankButton {
                                width: 36; height: 36; iconName: "refresh"
                                backgroundColor: Theme.surfaceContainerHigh
                                textColor: root.isLoading ? Theme.surfaceVariantText : Theme.surfaceText
                                onClicked: root.fetchGames()
                            }

                            DankButton {
                                width: 36; height: 36; iconName: "settings"
                                backgroundColor: Theme.surfaceContainerHigh
                                textColor: Theme.surfaceText
                                onClicked: pluginService.showPluginSettings(root.pluginId)
                            }
                        }
                    }

                    Item {
                        width: parent.width
                        height: root.isLoading ? 300 : (filteredGamesModel.count > 0 ? Math.min(500, gamesGrid.contentHeight) : 300)
                        clip: true

                        GridView {
                            id: gamesGrid
                            anchors.fill: parent
                            visible: !root.isLoading && filteredGamesModel.count > 0
                            model: filteredGamesModel
                            cellWidth: Math.floor(parent.width / 4)
                            cellHeight: 220
                            boundsBehavior: Flickable.StopAtBounds
                            focus: false // Only gains focus via Tab or navigation
                            
                            highlightFollowsCurrentItem: true
                            highlightMoveDuration: 0
                            keyNavigationEnabled: !root.isLaunching

                            onCurrentIndexChanged: {
                                if (!root._internalUpdate && currentIndex >= 0 && currentIndex < model.count) {
                                    root.currentSlug = model.get(currentIndex).slug
                                }
                            }
                            
                            highlight: null
                            
                            Keys.onTabPressed: {
                                if (root.isLaunching) return;
                                if (currentIndex < count - 1) {
                                    currentIndex++;
                                } else {
                                    currentIndex = 0;
                                }
                            }

                            Keys.onUpPressed: {
                                if (root.isLaunching) return;
                                if (currentIndex < 4) {
                                    searchField.forceActiveFocus();
                                } else {
                                    currentIndex -= 4;
                                }
                            }

                            Keys.onBacktabPressed: {
                                if (root.isLaunching) return;
                                if (currentIndex > 0) {
                                    currentIndex--;
                                } else {
                                    searchField.forceActiveFocus();
                                }
                            }
                            
                            Keys.onReturnPressed: launchCurrent()
                            Keys.onEnterPressed: launchCurrent()
                            Keys.onSpacePressed: launchCurrent()
                            
                            function launchCurrent() {
                                var item = model.get(currentIndex);
                                if (item) {
                                    if (item.isVirtual) {
                                        Proc.runCommand("lutris-launcher-open", ["sh", "-c", "nohup /usr/bin/lutris > /dev/null 2>&1 &"], function() {}, 0);
                                    } else {
                                        root.launchGame(item.id, item.slug);
                                    }
                                }
                            }

                            delegate: Item {
                                id: delegateItem
                                width: gamesGrid.cellWidth
                                height: gamesGrid.cellHeight
                                
                                readonly property bool isCurrent: GridView.isCurrentItem

                                Column {
                                    anchors.centerIn: parent
                                    width: parent.width - Theme.spacingS
                                    spacing: Theme.spacingXS

                                    Rectangle {
                                        id: coverContainer
                                        width: parent.width
                                        height: 180
                                        color: Theme.surfaceContainer
                                        radius: Theme.roundness === "ROUND_FULL" ? 12 : (Theme.roundness === "ROUND_TWELVE" ? 12 : (Theme.roundness === "ROUND_EIGHT" ? 8 : 4))
                                        clip: true
                                        opacity: (root.isLaunching && model.id !== root.launchingId) ? 0.5 : 1.0
                                        scale: delegateItem.isCurrent ? 1.03 : 1.0
                                        z: delegateItem.isCurrent ? 5 : 1
                                        
                                        Behavior on scale { NumberAnimation { duration: 150 } }

                                        SequentialAnimation {
                                            id: clickAnimation
                                            NumberAnimation { target: coverContainer; property: "scale"; from: 1.03; to: 0.95; duration: 100; easing.type: Easing.OutQuad }
                                            NumberAnimation { target: coverContainer; property: "scale"; from: 0.95; to: 1.03; duration: 150; easing.type: Easing.OutBack }
                                        }

                                        Rectangle {
                                            anchors.fill: parent
                                            color: "transparent"
                                            border.width: model.id === root.launchingId ? 4 : 0
                                            border.color: Theme.warning
                                            radius: parent.radius
                                            visible: model.id === root.launchingId

                                            DankIcon {
                                                anchors.centerIn: parent
                                                name: "sync"
                                                size: 48
                                                color: Theme.warning
                                                
                                                RotationAnimator on rotation {
                                                    from: 0; to: 360; duration: 1000
                                                    loops: Animation.Infinite
                                                    running: model.id === root.launchingId
                                                }
                                            }
                                            
                                            SequentialAnimation on opacity {
                                                loops: Animation.Infinite
                                                running: model.id === root.launchingId
                                                NumberAnimation { from: 1.0; to: 0.6; duration: 800; easing.type: Easing.InOutQuad }
                                                NumberAnimation { from: 0.6; to: 1.0; duration: 800; easing.type: Easing.InOutQuad }
                                            }
                                        }

                                        Image {
                                            id: coverImage
                                            anchors.fill: parent
                                            source: (model.coverPath && !model.isVirtual) ? "file://" + model.coverPath : ""
                                            fillMode: Image.PreserveAspectCrop
                                            visible: model.coverPath && !model.isVirtual
                                        }

                                        // Focus Highlight Border (On top of image)
                                        Rectangle {
                                            anchors.fill: parent
                                            color: Theme.withAlpha(Theme.primary, 0.1)
                                            border.width: 3
                                            border.color: Theme.primary
                                            radius: parent.radius
                                            z: 2
                                            opacity: delegateItem.isCurrent ? 1.0 : 0.0
                                            Behavior on opacity { NumberAnimation { duration: 150 } }
                                        }

                                        DankIcon {
                                            anchors.centerIn: parent
                                            name: model.isVirtual ? "add" : "image"
                                            size: 32
                                            color: Theme.surfaceVariantText
                                            visible: !model.coverPath || model.isVirtual
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                                            hoverEnabled: true
                                            cursorShape: (root.isLaunching && !model.isVirtual) ? Qt.ArrowCursor : Qt.PointingHandCursor
                                            enabled: !root.isLaunching || (model.isVirtual && !root.isLaunching)

                                            onClicked: (mouse) => {
                                                if (root.isLaunching) return;
                                                
                                                gamesGrid.currentIndex = index
                                                
                                                if (model.isVirtual) {
                                                    if (mouse.button === Qt.LeftButton) {
                                                        clickAnimation.start()
                                                        Proc.runCommand("lutris-launcher-open", ["sh", "-c", "nohup /usr/bin/lutris > /dev/null 2>&1 &"], function() {}, 0)
                                                    }
                                                    return
                                                }

                                                if (mouse.button === Qt.LeftButton) {
                                                    clickAnimation.start()
                                                    root.launchGame(model.id, model.slug)
                                                } else if (mouse.button === Qt.RightButton) {
                                                    infoPanel.visible = true
                                                }
                                            }
                                        }

                                        // Hover Highlight
                                        Rectangle {
                                            anchors.fill: parent
                                            color: Theme.primary
                                            opacity: parent.containsMouse ? 0.1 : 0
                                            radius: parent.radius
                                            Behavior on opacity { NumberAnimation { duration: 200 } }
                                        }

                                        // Custom Info Panel (Glassmorphism)
                                        Rectangle {
                                            id: infoPanel
                                            anchors.fill: parent
                                            color: Qt.rgba(Theme.surfaceContainerHighest.r, Theme.surfaceContainerHighest.g, Theme.surfaceContainerHighest.b, 0.85)
                                            visible: false
                                            radius: parent.radius
                                            z: 10
                                            
                                            border.width: 1
                                            border.color: Qt.rgba(1, 1, 1, 0.1)

                                            MouseArea {
                                                anchors.fill: parent
                                                onClicked: infoPanel.visible = false
                                            }

                                            Column {
                                                anchors.centerIn: parent
                                                width: parent.width - Theme.spacingM
                                                spacing: Theme.spacingS

                                                StyledText {
                                                    width: parent.width
                                                    text: root.getFormattedDate(root.playCounts[model.slug]?.lastPlayed)
                                                    font.bold: true
                                                    font.pixelSize: Theme.fontSizeSmall
                                                    color: Theme.primary
                                                    horizontalAlignment: Text.AlignHCenter
                                                }

                                                StyledText {
                                                    width: parent.width
                                                    text: I18n.tr("Plays: ") + (root.playCounts[model.slug]?.count || 0)
                                                    font.pixelSize: 10
                                                    horizontalAlignment: Text.AlignHCenter
                                                }

                                                DankButton {
                                                    width: parent.width - Theme.spacingS
                                                    height: 32
                                                    anchors.horizontalCenter: parent.horizontalCenter
                                                    text: model.isBlacklisted ? I18n.tr("Unhide") : I18n.tr("Hide")
                                                    iconName: model.isBlacklisted ? "visibility" : "block"
                                                    backgroundColor: Theme.surfaceContainerHigh
                                                    textColor: model.isBlacklisted ? Theme.primary : Theme.error
                                                    enabled: model.isBlacklisted || !root.isFavorite(model.slug)
                                                    
                                                    // Explicitly handle clicks and prevent propagation
                                                    onClicked: {
                                                        root.toggleBlacklist(model.slug)
                                                        infoPanel.visible = false
                                                    }
                                                    
                                                    // Ensure the button is above the panel's close-MouseArea
                                                    z: 11
                                                }
                                                
                                                StyledText {
                                                    visible: !model.isBlacklisted && root.isFavorite(model.slug)
                                                    text: I18n.tr("Can't hide favorites")
                                                    font.pixelSize: 9
                                                    color: Theme.error
                                                    horizontalAlignment: Text.AlignHCenter
                                                    width: parent.width
                                                }

                                                DankButton {
                                                    width: 40
                                                    height: 24
                                                    anchors.horizontalCenter: parent.horizontalCenter
                                                    text: I18n.tr("Close")
                                                    backgroundColor: "transparent"
                                                    textColor: Theme.surfaceVariantText
                                                    onClicked: infoPanel.visible = false
                                                    z: 11
                                                }
                                            }
                                        }

                                        DankButton {
                                            width: 32
                                            height: 32
                                            anchors.left: parent.left
                                            anchors.top: parent.top
                                            anchors.margins: Theme.spacingS
                                            iconName: root.isFavorite(model.slug) ? "star" : "star_border"
                                            backgroundColor: root.isFavorite(model.slug) ? Theme.warning : Theme.surfaceContainerHigh
                                            textColor: root.isFavorite(model.slug) ? Theme.onPrimary : Theme.surfaceVariantText
                                            radius: width / 2
                                            visible: !model.isVirtual
                                            enabled: !root.isLaunching
                                            onClicked: root.toggleFavorite(model.slug)
                                        }
                                    }

                                    StyledText {
                                        width: parent.width
                                        text: model.name || model.slug
                                        font.pixelSize: Theme.fontSizeSmall
                                        font.weight: delegateItem.isCurrent ? Font.Bold : Font.Normal
                                        color: (root.isLaunching && model.id !== root.launchingId) ? Theme.surfaceVariantText : Theme.surfaceText
                                        horizontalAlignment: Text.AlignHCenter
                                        elide: Text.ElideRight
                                        maximumLineCount: 1
                                    }
                                }

                                opacity: 1.0
                            }

                            ScrollIndicator.vertical: ScrollIndicator { }
                        }

                        Column {
                            anchors.centerIn: parent
                            spacing: Theme.spacingM
                            visible: root.isLoading
                            
                            DankIcon {
                                name: "refresh"
                                size: 48
                                color: Theme.primary
                                anchors.horizontalCenter: parent.horizontalCenter
                                RotationAnimator on rotation {
                                    from: 0; to: 360; duration: 1000; loops: Animation.Infinite; running: root.isLoading
                                }
                            }
                            
                            StyledText {
                                text: I18n.tr("Synchronizing with Lutris...")
                                font.pixelSize: Theme.fontSizeMedium
                                color: Theme.surfaceVariantText
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                        }

                        Column {
                            anchors.centerIn: parent
                            width: parent.width - 64
                            spacing: Theme.spacingM
                            visible: !root.isLoading && filteredGamesModel.count === 0
                            
                            DankIcon {
                                name: root.searchQuery !== "" ? "search_off" : "sports_esports"
                                size: 48
                                color: Theme.surfaceContainerHighest
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                            
                            StyledText {
                                text: root.searchQuery !== "" ? I18n.tr("No matches for '") + root.searchQuery + "'" : I18n.tr("Your library is empty")
                                font.pixelSize: Theme.fontSizeMedium
                                color: Theme.surfaceVariantText
                                horizontalAlignment: Text.AlignHCenter
                                width: parent.width
                            }
                            
                            DankButton {
                                text: I18n.tr("Clear Filters")
                                visible: root.searchQuery !== "" || root.favoriteOnly || root.blacklistOnly
                                anchors.horizontalCenter: parent.horizontalCenter
                                onClicked: {
                                    root.searchQuery = ""
                                    root.favoriteOnly = false
                                    root.blacklistOnly = false
                                    root.updateFilteredModel()
                                }
                            }
                        }
                    }

                    HintSection {
                        showHints: root.showHints
                        width: parent.width

                        HintItem {
                            icon: "mouse"
                            text: I18n.tr("Left Click to launch a game, Right Click for more options")
                        }
                        HintItem {
                            icon: "star"
                            text: I18n.tr("Use the star icon to favorite games for quick access")
                        }
                        HintItem {
                            icon: "visibility_off"
                            text: I18n.tr("Hide games you don't play often to keep your list clean")
                        }
                    }
                }
            }
        }
    }

    popoutWidth: 600
}
