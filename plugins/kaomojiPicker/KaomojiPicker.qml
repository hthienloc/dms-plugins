import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Services
import "./dms-common"

QtObject {
    id: root

    property var pluginService: null
    property string trigger: "kj"

    // Database state
    property var database: ({})
    property bool dbLoaded: false
    property bool dbLoading: false
    
    // History state
    property var history: []
    
    // Pinned state
    property var pinned: []

    // Config state
    property int resultLimit: 50
    property bool enableHistory: true
    property int historyLimit: 15
    property bool pasteOnSelect: true

    signal itemsChanged

    readonly property string dbPath: Qt.resolvedUrl("database.json").toString().replace("file://", "")

    function updateConfigs() {
        if (!pluginService) return;
        trigger = pluginService.loadPluginData("kaomojiPicker", "trigger", "kj");
        resultLimit = pluginService.loadPluginData("kaomojiPicker", "resultLimit", 50);
        enableHistory = pluginService.loadPluginData("kaomojiPicker", "enableHistory", true);
        historyLimit = pluginService.loadPluginData("kaomojiPicker", "historyLimit", 15);
        pasteOnSelect = pluginService.loadPluginData("kaomojiPicker", "pasteOnSelect", true);
        console.log("KaomojiPicker: Configs updated (History: " + enableHistory + ", pasteOnSelect: " + pasteOnSelect + ")");
    }

    property Connections pluginServiceConnections: Connections {
        target: pluginService
        function onPluginDataChanged(id) {
            if (id === "kaomojiPicker") updateConfigs();
        }
        function onPluginStateChanged(id) {
            if (id === "kaomojiPicker") {
                loadHistory();
                loadPinned();
            }
        }
    }

    property FileView loader: FileView {
        path: ""
        watchChanges: false
        blockLoading: true
    }

    Component.onCompleted: {
        if (pluginService) {
            updateConfigs();
            loadHistory();
            loadPinned();
            init();
        }
    }

    onPluginServiceChanged: {
        if (pluginService) {
            updateConfigs();
            loadHistory();
            loadPinned();
            init();
        }
    }

    function init() {
        if (dbLoading || dbLoaded) return;
        dbLoading = true;

        console.log("KaomojiPicker: Loading from " + dbPath);
        loader.path = dbPath;

        const rawText = loader.text();
        if (!rawText || rawText.length < 2) {
            console.error("KaomojiPicker: File empty or not found at: " + dbPath);
            dbLoading = false;
            return;
        }

        try {
            database = JSON.parse(rawText);
            dbLoaded = true;
            dbLoading = false;
            console.log("KaomojiPicker: Loaded " + Object.keys(database).length + " entries.");
            itemsChanged();
        } catch (e) {
            console.error("KaomojiPicker: JSON parse failed: " + e);
            dbLoading = false;
        }
    }

    function loadHistory() {
        if (!pluginService) return;
        const loaded = pluginService.loadPluginState("kaomojiPicker", "history", []);
        history = Array.isArray(loaded) ? loaded : [];
        console.log("KaomojiPicker: History loaded, count: " + history.length);
        itemsChanged();
    }

    function loadPinned() {
        if (!pluginService) return;
        const loaded = pluginService.loadPluginState("kaomojiPicker", "pinned", []);
        pinned = Array.isArray(loaded) ? loaded : [];
        console.log("KaomojiPicker: Pinned loaded, count: " + pinned.length);
        itemsChanged();
    }

    function togglePin(kaomoji) {
        if (!pluginService) return;
        
        let list = pinned.slice();
        let idx = list.indexOf(kaomoji);
        if (idx >= 0) {
            list.splice(idx, 1);
            ToastService?.showInfo("Unpinned: " + kaomoji);
        } else {
            list.push(kaomoji);
            ToastService?.showInfo("Pinned: " + kaomoji);
        }
        pinned = list;
        pluginService.savePluginState("kaomojiPicker", "pinned", list);
        itemsChanged();
    }

    function removeFromHistory(kaomoji) {
        if (!pluginService) return;
        
        let list = history.slice();
        let idx = list.indexOf(kaomoji);
        if (idx >= 0) {
            list.splice(idx, 1);
            history = list;
            pluginService.savePluginState("kaomojiPicker", "history", list);
            ToastService?.showInfo("Removed from history: " + kaomoji);
            itemsChanged();
        }
    }

    function getContextMenuActions(item) {
        if (!item || !item._kaomoji) return [];
        const kaomoji = item._kaomoji;
        const isPinned = pinned.includes(kaomoji);
        const isInHistory = history.includes(kaomoji);
        
        const actions = [
            {
                icon: isPinned ? "keep_off" : "push_pin",
                text: isPinned ? I18n.tr("Unpin Kaomoji") : I18n.tr("Pin Kaomoji"),
                action: function() { togglePin(kaomoji); },
                closeLauncher: false
            }
        ];
        
        if (isInHistory) {
            actions.push({
                icon: "delete",
                text: I18n.tr("Remove from History"),
                action: function() { removeFromHistory(kaomoji); },
                closeLauncher: false
            });
        }
        
        return actions;
    }

    function saveToHistory(kaomoji) {
        if (!pluginService || !enableHistory) return;
        
        let list = history.slice();
        let idx = list.indexOf(kaomoji);
        if (idx >= 0) list.splice(idx, 1);
        list.unshift(kaomoji);
        if (list.length > historyLimit) list = list.slice(0, historyLimit);
        
        history = list;
        pluginService.savePluginState("kaomojiPicker", "history", list);
        console.log("KaomojiPicker: Saved to history: " + kaomoji);
        itemsChanged(); // Force immediate UI refresh
    }

    function getItems(query) {
        if (dbLoading) {
            return [{
                name: "Loading database...",
                comment: "Please wait, parsing ~10MB of kaomoji",
                icon: "material:sync",
                executable: false
            }];
        }

        if (!dbLoaded) {
            if (pluginService) init();
            return [{
                name: "Initializing...",
                comment: "Kaomoji database is starting up",
                icon: "material:hourglass_empty",
                executable: false
            }];
        }

        let items = [];
        const lowerQuery = query.toLowerCase().trim();

        // 1. Process Pinned Items (Highest Priority)
        let matchingPinned = [];
        if (pinned.length > 0) {
            pinned.forEach((k, index) => {
                let match = false;
                if (lowerQuery === "") {
                    match = true;
                } else {
                    if (k.toLowerCase().includes(lowerQuery)) {
                        match = true;
                    } else {
                        const entry = database[k];
                        if (entry) {
                            const tags = (Array.isArray(entry.new_tags) ? entry.new_tags : [])
                                         .concat(Array.isArray(entry.original_tags) ? entry.original_tags : [])
                                         .join(", ").toLowerCase();
                            if (tags.includes(lowerQuery)) match = true;
                        }
                    }
                }

                if (match) {
                    matchingPinned.push({
                        name: k,
                        icon: "material:push_pin",
                        executable: true,
                        _kaomoji: k,
                        _preScored: 3000 - index // Extremely high score
                    });
                }
            });
        }

        // 2. Process History (Prioritized below Pinned)
        let matchingHistory = [];
        if (enableHistory && history.length > 0) {
            history.forEach((k, index) => {
                // Skip if already in pinned matches list to avoid duplication
                if (matchingPinned.some(p => p._kaomoji === k)) return;

                let match = false;
                if (lowerQuery === "") {
                    match = true;
                } else {
                    if (k.toLowerCase().includes(lowerQuery)) {
                        match = true;
                    } else {
                        const entry = database[k];
                        if (entry) {
                            const tags = (Array.isArray(entry.new_tags) ? entry.new_tags : [])
                                         .concat(Array.isArray(entry.original_tags) ? entry.original_tags : [])
                                         .join(", ").toLowerCase();
                            if (tags.includes(lowerQuery)) match = true;
                        }
                    }
                }

                if (match) {
                    matchingHistory.push({
                        name: k,
                        icon: "material:history",
                        executable: true,
                        _kaomoji: k,
                        _preScored: 2000 - index // Preserves history order
                    });
                }
            });
        }

        if (lowerQuery === "") {
            return matchingPinned.concat(matchingHistory);
        }

        // Combine Pinned and History first
        items = matchingPinned.concat(matchingHistory);

        // 3. Search Database for remaining results
        const limit = root.resultLimit;
        let dbMatchCount = 0;
        
        for (const key in database) {
            if (items.length >= limit) break;
            
            // Skip if already in items (pinned or history) to avoid duplicates
            if (items.some(i => i._kaomoji === key)) continue;

            const entry = database[key];
            const tags = (Array.isArray(entry.new_tags) ? entry.new_tags : [])
                         .concat(Array.isArray(entry.original_tags) ? entry.original_tags : [])
                         .join(", ");

            if (tags.toLowerCase().includes(lowerQuery) || key.toLowerCase().includes(lowerQuery)) {
                items.push({
                    name: key,
                    comment: tags,
                    icon: "unicode:\u2800",
                    executable: true,
                    _kaomoji: key,
                    _preScored: 1000 - dbMatchCount
                });
                dbMatchCount++;
            }
        }

        return items;
    }

    function executeItem(item) {
        if (!item || !item._kaomoji) return;

        const kaomoji = item._kaomoji;
        
        // Save to history
        saveToHistory(kaomoji);
        
        // Copy to clipboard, and trigger direct paste if enabled
        let cmd = "printf '%s' \"$1\" | setsid dms cl copy";
        if (pasteOnSelect) {
            cmd += " && sleep 0.15 && (command -v wtype >/dev/null && wtype -M ctrl -P v -p v -m ctrl || command -v ydotool >/dev/null && ydotool key 29:1 47:1 47:0 29:0 || command -v xdotool >/dev/null && xdotool key --clearmodifiers ctrl+v)";
        }
        
        Quickshell.execDetached(["sh", "-c", cmd, "copy_paste", kaomoji]);
        
        // Feedback
        if (!pasteOnSelect) {
            ToastService?.showInfo("Copied to clipboard: " + kaomoji);
        }
    }

    function getPasteText(item) {
        return item?._kaomoji || null;
    }

    function getPasteArgs(item) {
        const kaomoji = getPasteText(item);
        if (!kaomoji) return null;

        if (pasteOnSelect) {
            // When pasteOnSelect is true, Shift+Enter means COPY only.
            // So we copy to clipboard here, close the launcher, and return null to prevent default pasting.
            saveToHistory(kaomoji);
            const cmd = "printf '%s' \"$1\" | setsid dms cl copy && dms ipc launcher close";
            Quickshell.execDetached(["sh", "-c", cmd, "copy", kaomoji]);
            ToastService?.showInfo("Copied to clipboard: " + kaomoji);
            return null;
        }

        // When pasteOnSelect is false, Shift+Enter means PASTE.
        // We return the command to copy, and let the launcher handle the pasting automatically.
        saveToHistory(kaomoji);
        const copyCmd = "printf '%s' \"$1\" | setsid dms cl copy";
        return ["sh", "-c", copyCmd, "copy", kaomoji];
    }
}
