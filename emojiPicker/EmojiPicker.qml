pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Modals.Common
import qs.Modules.Plugins
import qs.Services
import qs.Widgets
import "emoji-data.js" as EmojiData

PluginComponent {
    id: root

    pluginId: "emojiPicker"
    pluginService: PluginService

    readonly property int pickerSize: {
        const configured = Number(root.pluginData?.pickerSize ?? 560);
        return [500, 560, 620].includes(configured) ? configured : 560;
    }
    readonly property int pickerWidth: pickerSize
    readonly property int pickerHeight: pickerSize
    readonly property int recentLimit: {
        const configured = Number(root.pluginData?.recentLimit ?? 30);
        return Number.isFinite(configured) ? Math.max(5, Math.min(100, configured)) : 30;
    }
    readonly property bool showCopyToast: root.pluginData?.showCopyToast ?? true

    property var allEntries: []
    property var recentEmojis: []
    property string query: ""
    property string selectedCategory: "recent"
    property int selectedIndex: 0
    property var queuedEmojis: []

    readonly property string queuedText: queuedEmojis.join("")

    readonly property var categoryNames: EmojiData.getCategories()
    readonly property var categoryOrder: [
        "recent", "smileys-people", "animals-nature", "food-drink",
        "activities", "travel-places", "objects", "symbols", "flags"
    ]
    readonly property var categoryIcons: ({
        "recent": "history",
        "smileys-people": "mood",
        "animals-nature": "pets",
        "food-drink": "restaurant",
        "activities": "sports_soccer",
        "travel-places": "travel_explore",
        "objects": "category",
        "symbols": "emoji_symbols",
        "flags": "flag"
    })
    readonly property var visibleEntries: {
        const q = root.query.trim().toLowerCase();
        let source = root.allEntries;
        if (!q && root.selectedCategory === "recent") {
            source = root.recentEmojis.map(emoji => root.allEntries.find(entry => entry.emoji === emoji)).filter(entry => entry);
        } else if (!q) {
            source = root.allEntries.filter(entry => entry.category === root.selectedCategory);
        }
        if (!q)
            return source;
        return root.allEntries.filter(entry => {
            if (root.selectedCategory !== "recent" && entry.category !== root.selectedCategory)
                return false;
            const haystack = [entry.name, entry.emoji].concat(entry.keywords || []).join(" ").toLowerCase();
            return haystack.includes(q);
        });
    }

    Timer {
        id: pasteTimer
        interval: 150
        repeat: false
        onTriggered: ClipboardService.sendPasteKeystroke()
    }

    function loadData() {
        root.allEntries = EmojiData.getEntries();
        const saved = PluginService.loadPluginState(root.pluginId, "recent", []);
        root.recentEmojis = Array.isArray(saved) ? saved.slice(0, root.recentLimit) : [];
    }

    function initialCategory() {
        const configured = root.pluginData?.defaultCategory ?? "auto";
        if (configured === "auto")
            return root.recentEmojis.length > 0 ? "recent" : "smileys-people";
        return root.categoryOrder.includes(configured) ? configured : "smileys-people";
    }

    function openPicker() {
        const screen = CompositorService.getFocusedScreen();
        if (!screen)
            return "No active screen";
        root.loadData();
        root.clearQueue();
        pickerModal.targetScreen = screen;
        root.query = "";
        root.selectedCategory = root.initialCategory();
        root.selectedIndex = 0;
        pickerModal.open();
        return "opened";
    }

    function closePicker() {
        root.clearQueue();
        pickerModal.close();
    }

    function saveRecentSequence(emojis) {
        let next = root.recentEmojis.slice();
        for (const emoji of emojis) {
            next = next.filter(item => item !== emoji);
            next.unshift(emoji);
        }
        next = next.slice(0, root.recentLimit);
        root.recentEmojis = next;
        PluginService.savePluginState(root.pluginId, "recent", next);
    }

    function clearRecentHistory() {
        root.recentEmojis = [];
        PluginService.savePluginState(root.pluginId, "recent", []);
        root.selectedIndex = 0;
    }

    function clearQueue() {
        root.queuedEmojis = [];
    }

    function appendEmoji(emoji) {
        if (!emoji)
            return false;
        root.queuedEmojis = root.queuedEmojis.concat([emoji]);
        return true;
    }

    function appendCurrent() {
        const entry = root.visibleEntries[root.selectedIndex];
        return entry ? root.appendEmoji(entry.emoji) : false;
    }

    function removeLastQueued() {
        if (root.queuedEmojis.length === 0)
            return false;
        root.queuedEmojis = root.queuedEmojis.slice(0, -1);
        return true;
    }

    function commitEmojis(emojis, paste) {
        const text = emojis.join("");
        if (!text)
            return;
        if (!DMSService.isConnected) {
            ToastService.showError(I18n.trFor("emojiPicker", "Failed to copy emoji"));
            return;
        }

        DMSService.sendRequest("clipboard.copy", { "text": text }, response => {
            if (response.error) {
                ToastService.showError(I18n.trFor("emojiPicker", "Failed to copy emoji"));
                return;
            }
            if (!paste && root.showCopyToast)
                ToastService.showInfo(I18n.trFor("emojiPicker", "Copied %1 to clipboard").arg(text));
            root.saveRecentSequence(emojis);
            root.closePicker();
            if (paste)
                pasteTimer.restart();
        });
    }

    function commitSingleEmoji(emoji, paste) {
        if (emoji)
            root.commitEmojis([emoji], paste);
    }

    function commitCurrent(paste) {
        if (root.queuedEmojis.length > 0) {
            root.commitEmojis(root.queuedEmojis.slice(), paste);
            return;
        }
        const entry = root.visibleEntries[root.selectedIndex];
        if (entry)
            root.commitSingleEmoji(entry.emoji, paste);
    }

    function handleEnter(event) {
        if (event.key !== Qt.Key_Return && event.key !== Qt.Key_Enter)
            return false;

        if (event.modifiers & Qt.ShiftModifier)
            root.appendCurrent();
        else
            root.commitCurrent((event.modifiers & Qt.ControlModifier) !== 0);
        event.accepted = true;
        return true;
    }

    function handleQueueBackspace(event, canRemove) {
        if (event.key !== Qt.Key_Backspace || !canRemove || root.queuedEmojis.length === 0)
            return false;
        root.removeLastQueued();
        event.accepted = true;
        return true;
    }

    function handleEscape(event) {
        if (root.queuedEmojis.length > 0)
            root.clearQueue();
        else
            root.closePicker();
        event.accepted = true;
    }

    Component.onCompleted: root.loadData()
    Component.onDestruction: root.clearQueue()

    IpcHandler {
        target: "emojiPicker"

        function open(): string { return root.openPicker(); }
        function close(): string { root.closePicker(); return "closed"; }
        function clearRecent(): string { root.clearRecentHistory(); return "cleared"; }
        function toggle(): string {
            if (pickerModal.shouldBeVisible) {
                root.closePicker();
                return "closed";
            }
            return root.openPicker();
        }
    }

    DankModal {
        id: pickerModal
        layerNamespace: "dms:plugins:emojiPicker"
        modalWidth: root.pickerWidth
        modalHeight: root.pickerHeight
        positioning: "center"
        showBackground: true
        useOverlayLayer: true
        enableShadow: true
        cornerRadius: Theme.cornerRadiusLarge
        shouldBeVisible: false
        content: pickerContent
        onBackgroundClicked: root.closePicker()
        onDialogClosed: root.clearQueue()
    }

    Component {
        id: pickerContent

        FocusScope {
            id: pickerView
            width: pickerModal.modalWidth
            implicitHeight: root.pickerHeight
            height: pickerModal.modalHeight
            focus: true

            function focusFirstEmoji() {
                if (root.visibleEntries.length === 0)
                    return;
                root.selectedIndex = 0;
                emojiGrid.currentIndex = 0;
                emojiGrid.forceActiveFocus();
                emojiGrid.positionViewAtIndex(0, GridView.Beginning);
            }

            function selectCategory(category) {
                const restoreGridFocus = emojiGrid.activeFocus;
                root.selectedCategory = category;
                root.query = "";
                searchField.text = "";
                root.selectedIndex = 0;
                Qt.callLater(() => {
                    emojiGrid.currentIndex = 0;
                    if (root.visibleEntries.length > 0)
                        emojiGrid.positionViewAtIndex(0, GridView.Beginning);
                    if (restoreGridFocus)
                        emojiGrid.forceActiveFocus();
                });
            }

            function categoryForShortcut(event) {
                if (!(event.modifiers & Qt.ControlModifier))
                    return "";
                switch (event.key) {
                case Qt.Key_QuoteLeft: return "recent";
                case Qt.Key_1: return "smileys-people";
                case Qt.Key_2: return "animals-nature";
                case Qt.Key_3: return "food-drink";
                case Qt.Key_4: return "activities";
                case Qt.Key_Q: return "travel-places";
                case Qt.Key_W: return "objects";
                case Qt.Key_E: return "symbols";
                case Qt.Key_R: return "flags";
                default: return "";
                }
            }

            Keys.onPressed: event => {
                const category = pickerView.categoryForShortcut(event);
                if (category) {
                    pickerView.selectCategory(category);
                    event.accepted = true;
                }
            }
            Keys.onEscapePressed: event => {
                root.handleEscape(event);
            }

            Connections {
                target: pickerModal
                function onOpened() {
                    Qt.callLater(() => {
                        searchField.forceActiveFocus();
                        searchField.selectAll();
                    });
                }
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Theme.spacingM
                spacing: Theme.spacingS

                RowLayout {
                    Layout.fillWidth: true

                    StyledText {
                        text: I18n.trFor("emojiPicker", "Emoji Picker")
                        color: Theme.surfaceText
                        font.pixelSize: Theme.fontSizeLarge
                        font.weight: Font.Medium
                        Layout.fillWidth: true
                    }

                    DankActionButton {
                        iconName: "close"
                        buttonSize: 30
                        iconSize: 18
                        iconColor: Theme.surfaceVariantText
                        tooltipText: I18n.trFor("emojiPicker", "Close")
                        onClicked: root.closePicker()
                    }
                }

                DankTextField {
                    id: searchField
                    Layout.fillWidth: true
                    placeholderText: I18n.trFor("emojiPicker", "Search emoji")
                    text: root.query
                    onTextChanged: {
                        root.query = text;
                        root.selectedIndex = 0;
                    }
                    Keys.onPressed: event => {
                        if (root.handleEnter(event))
                            return;
                        root.handleQueueBackspace(event, searchField.text.length === 0);
                    }
                    Keys.onDownPressed: {
                        pickerView.focusFirstEmoji();
                    }
                    Keys.onTabPressed: {
                        pickerView.focusFirstEmoji();
                    }
                }

                Flickable {
                    id: categoryScroller
                    Layout.fillWidth: true
                    Layout.preferredHeight: 56
                    contentWidth: categoryRow.width
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    Row {
                        id: categoryRow
                        width: categoryScroller.width
                        height: categoryScroller.height
                        spacing: Theme.spacingXS

                        Repeater {
                            model: root.categoryOrder

                            DankActionButton {
                                required property string modelData
                                iconName: root.categoryIcons[modelData] || "category"
                                iconSize: 22
                                tooltipText: I18n.tr(root.categoryNames[modelData] || "")
                                buttonSize: (categoryRow.width - (root.categoryOrder.length - 1) * categoryRow.spacing) / root.categoryOrder.length
                                backgroundColor: root.selectedCategory === modelData ? Theme.primary : Theme.surfaceContainerHigh
                                iconColor: root.selectedCategory === modelData ? Theme.onPrimary : Theme.surfaceText
                                onClicked: pickerView.selectCategory(modelData)
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 26
                    spacing: Theme.spacingS

                    StyledText {
                        Layout.fillWidth: true
                        text: root.visibleEntries.length > 0 ? (root.query ? I18n.trFor("emojiPicker", "Search results") : (I18n.tr(root.categoryNames[root.selectedCategory] || ""))) : I18n.trFor("emojiPicker", "No emoji found")
                        color: Theme.surfaceVariantText
                        font.pixelSize: Theme.fontSizeSmall
                        verticalAlignment: Text.AlignVCenter
                    }

                    DankButton {
                        visible: !root.query && root.selectedCategory === "recent" && root.recentEmojis.length > 0
                        text: I18n.trFor("emojiPicker", "Clear All")
                        iconName: "delete_sweep"
                        buttonHeight: 26
                        textColor: Theme.error
                        backgroundColor: Theme.withAlpha(Theme.error, 0.12)
                        onClicked: root.clearRecentHistory()
                    }
                }

                GridView {
                    id: emojiGrid
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    readonly property int columnCount: Math.max(1, Math.floor(width / 72))
                    cellWidth: width / columnCount
                    cellHeight: 68
                    clip: true
                    model: root.visibleEntries
                    currentIndex: root.selectedIndex
                    focus: false
                    keyNavigationEnabled: true
                    highlightFollowsCurrentItem: true
                    highlightMoveDuration: 0
                    highlight: null

                    onCurrentIndexChanged: root.selectedIndex = currentIndex

                    delegate: Item {
                        id: delegateItem
                        required property var modelData
                        readonly property bool isCurrent: GridView.isCurrentItem
                        width: emojiGrid.cellWidth
                        height: emojiGrid.cellHeight

                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 3
                            radius: Theme.cornerRadius
                            color: delegateItem.isCurrent && emojiGrid.activeFocus ? Theme.withAlpha(Theme.primary, 0.16) : (emojiMouse.containsMouse ? Theme.surfaceContainerHigh : "transparent")
                            border.width: delegateItem.isCurrent && emojiGrid.activeFocus ? 2 : 0
                            border.color: Theme.primary

                            StyledText {
                                anchors.centerIn: parent
                                text: modelData.emoji
                                font.pixelSize: 32
                                color: Theme.surfaceText
                            }

                            MouseArea {
                                id: emojiMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                onEntered: {
                                    emojiGrid.currentIndex = index;
                                }
                                onClicked: mouse => {
                                    if (mouse.button === Qt.LeftButton && (mouse.modifiers & Qt.ShiftModifier)) {
                                        root.appendEmoji(modelData.emoji);
                                        return;
                                    }
                                    root.commitSingleEmoji(modelData.emoji, mouse.button === Qt.RightButton);
                                }
                            }
                        }
                    }

                    Keys.onPressed: event => {
                        if (root.handleEnter(event))
                            return;
                        if (root.handleQueueBackspace(event, true))
                            return;
                        if (event.key === Qt.Key_Up) {
                            if (emojiGrid.currentIndex < emojiGrid.columnCount) {
                                searchField.forceActiveFocus();
                                event.accepted = true;
                            }
                        }
                    }
                }

                EmojiQueuePreview {
                    Layout.fillWidth: true
                    visible: root.queuedEmojis.length > 0
                    sequence: root.queuedText
                    onCopyRequested: root.commitCurrent(false)
                    onPasteRequested: root.commitCurrent(true)
                }
            }
        }
    }
}
