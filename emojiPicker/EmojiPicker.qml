pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Modals.Common
import qs.Modules.Plugins
import qs.Services
import qs.DCommon.Widgets
import "./shared"
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
    readonly property int emojisPerRow: {
        const configured = Number(root.pluginData?.emojisPerRow ?? 8);
        return Math.max(4, Math.min(16, configured));
    }
    readonly property bool pasteByDefault: (root.pluginData?.defaultAction ?? "copy") === "paste"
    readonly property bool showCopyToast: root.pluginData?.showCopyToast ?? true
    readonly property bool showHints: root.pluginData?.showHints ?? true

    function getStoredSkinTone() {
        const stored = String(root.pluginData?.defaultSkinTone ?? "default");
        return stored === "0" ? "default" : stored;
    }

    property string activeSkinTone: root.getStoredSkinTone()

    property var allEntries: []
    property var entriesByCategory: ({})
    property var entryByEmoji: ({})
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

    readonly property var skinToneOptions: ["✋", "✋🏻", "✋🏼", "✋🏽", "✋🏾", "✋🏿"]
    readonly property var skinToneValues: ["default", "1", "2", "3", "4", "5"]

    function skinToneIcon(tone) {
        const idx = root.skinToneValues.indexOf(tone);
        return idx >= 0 ? root.skinToneOptions[idx] : "✋";
    }

    function skinToneToOption(tone) {
        return root.skinToneIcon(tone);
    }

    function optionToSkinTone(option) {
        const idx = root.skinToneOptions.indexOf(option);
        return idx >= 0 ? root.skinToneValues[idx] : "default";
    }

    function stripSkinTone(emoji) {
        if (!emoji)
            return "";
        return emoji.replace(/[\u{1F3FB}-\u{1F3FF}]/gu, "");
    }

    function findEntry(emoji) {
        if (!emoji)
            return null;
        const stripped = root.stripSkinTone(emoji);
        return root.entryByEmoji[emoji] || root.entryByEmoji[stripped] || null;
    }

    function setSkinTone(tone) {
        root.activeSkinTone = String(tone);
    }

    function effectiveEmoji(entry) {
        if (!entry)
            return "";
        if (root.activeSkinTone === "default" || !entry.variants)
            return entry.emoji;
        const toneIdx = Number(root.activeSkinTone) - 1;
        return (toneIdx >= 0 && toneIdx < entry.variants.length) ? (entry.variants[toneIdx] || entry.emoji) : entry.emoji;
    }

    readonly property var visibleEntries: {
        const q = root.query.trim().toLowerCase();
        let source = root.allEntries;
        if (!q && root.selectedCategory === "recent") {
            source = root.recentEmojis.map(emoji => root.findEntry(emoji)).filter(Boolean);
        } else if (!q) {
            source = root.entriesByCategory[root.selectedCategory] || [];
        }
        if (!q)
            return source;
        const searchSource = root.selectedCategory === "recent"
            ? root.allEntries
            : (root.entriesByCategory[root.selectedCategory] || []);
        return searchSource.filter(entry => {
            return entry.searchText.includes(q) || root.effectiveEmoji(entry).toLowerCase().includes(q);
        });
    }

    Timer {
        id: pasteTimer
        interval: 150
        repeat: false
        onTriggered: ClipboardService.sendPasteKeystroke()
    }

    // Noto Color Emoji ligates ZWJ sequences without U+FE0F, but Qt's shaper doesn't
    // skip the selector, so they render split. Display-only; the copied value is unchanged.
    function displayEmoji(emoji) {
        return emoji.indexOf("\u200D") >= 0 ? emoji.replace(/\uFE0F/g, "") : emoji;
    }

    function loadData() {
        if (root.allEntries.length === 0) {
            const entries = EmojiData.getEntries();
            const byCategory = {};
            const byEmoji = {};

            for (const entry of entries) {
                entry.searchText = [entry.name, entry.emoji].concat(entry.keywords || []).join(" ").toLowerCase();
                if (!byCategory[entry.category])
                    byCategory[entry.category] = [];
                byCategory[entry.category].push(entry);

                byEmoji[entry.emoji] = entry;
                byEmoji[root.stripSkinTone(entry.emoji)] = entry;
                for (const variant of entry.variants || []) {
                    byEmoji[variant] = entry;
                    byEmoji[root.stripSkinTone(variant)] = entry;
                }
            }

            root.allEntries = entries;
            root.entriesByCategory = byCategory;
            root.entryByEmoji = byEmoji;
        }
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
        root.activeSkinTone = root.getStoredSkinTone();
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
            const base = root.stripSkinTone(emoji);
            next = next.filter(item => item !== base && item !== emoji);
            next.unshift(base);
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
        return entry ? root.appendEmoji(root.effectiveEmoji(entry)) : false;
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
            root.commitSingleEmoji(root.effectiveEmoji(entry), paste);
    }

    function handleEnter(event) {
        if (event.key !== Qt.Key_Return && event.key !== Qt.Key_Enter)
            return false;

        if (event.modifiers & Qt.ShiftModifier)
            root.appendCurrent();
        else
            root.commitCurrent(((event.modifiers & Qt.ControlModifier) !== 0) !== root.pasteByDefault);
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
        if (root.queuedEmojis.length > 0) {
            root.clearQueue();
        } else {
            root.closePicker();
        }
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

    DModal {
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

            property bool variantPopupVisible: false
            property var variantEntry: null
            property var variantPopupOptions: []
            property Item variantAnchorItem: null
            property real variantPopupX: 0
            property real variantPopupY: 0
            property string variantPopupPlacement: "below"
            property real variantArrowOffsetX: 0

            function updateVariantPopupPosition() {
                if (!variantPopupVisible || !variantAnchorItem)
                    return;
                const mapped = variantAnchorItem.mapToItem(pickerView, 0, 0);
                const gridMapped = emojiGrid.mapToItem(pickerView, 0, 0);
                const itemTop = mapped.y;
                const itemBottom = mapped.y + variantAnchorItem.height;
                const gridTop = gridMapped.y;
                const gridBottom = gridMapped.y + emojiGrid.height;

                // If the anchored emoji item is scrolled out of the visible grid viewport, hide popup
                if (itemBottom <= gridTop || itemTop >= gridBottom) {
                    hideVariantPopup();
                    return;
                }

                const popupWidth = variantPopup.width > 0 ? variantPopup.width : (variantPopupOptions.length * 40 + 16);
                const popupHeight = variantPopup.height > 0 ? variantPopup.height : 44;
                const arrowOffset = 10;

                let px = mapped.x + (variantAnchorItem.width - popupWidth) / 2;
                px = Math.max(Theme.spacingM, Math.min(px, pickerView.width - popupWidth - Theme.spacingM));

                // Always prefer orienting toward the vertical center of the emoji area (emojiGrid)
                const gridCenterY = gridTop + emojiGrid.height / 2;
                const itemCenterY = mapped.y + variantAnchorItem.height / 2;

                let placement = itemCenterY < gridCenterY ? "below" : "above";
                let py = placement === "below"
                    ? mapped.y + variantAnchorItem.height + arrowOffset
                    : mapped.y - popupHeight - arrowOffset;

                // Boundary guard checks
                if (py < Theme.spacingM) {
                    placement = "below";
                    py = mapped.y + variantAnchorItem.height + arrowOffset;
                } else if (py + popupHeight > pickerView.height - Theme.spacingM) {
                    placement = "above";
                    py = mapped.y - popupHeight - arrowOffset;
                }

                const anchorCenterX = mapped.x + variantAnchorItem.width / 2;
                const safeMargin = Math.min(popupWidth / 2, (Theme.cornerRadius ?? 8) + 9);

                variantPopupX = px;
                variantPopupY = py;
                variantPopupPlacement = placement;
                variantArrowOffsetX = Math.max(safeMargin, Math.min(anchorCenterX - px, popupWidth - safeMargin));
            }

            function showVariantPopup(entry, item) {
                if (!entry || !entry.variants || entry.variants.length === 0 || !item)
                    return;
                variantEntry = entry;
                const variants = (entry.variants || []).filter(Boolean);
                variantPopupOptions = [entry.emoji].concat(variants);
                variantAnchorItem = item;
                variantPopupVisible = true;
                updateVariantPopupPosition();
            }

            function hideVariantPopup() {
                variantPopupVisible = false;
                variantEntry = null;
                variantAnchorItem = null;
                variantPopupOptions = [];
            }

            function focusCategory(index) {
                const button = categoryRepeater.itemAt(index);
                if (button)
                    button.forceActiveFocus(Qt.TabFocusReason);
            }

            function focusSelectedCategory() {
                pickerView.focusCategory(root.categoryOrder.indexOf(root.selectedCategory));
            }

            function focusFirstEmoji() {
                if (root.visibleEntries.length === 0)
                    return;
                root.selectedIndex = 0;
                emojiGrid.currentIndex = 0;
                emojiGrid.forceActiveFocus();
                emojiGrid.positionViewAtIndex(0, GridView.Beginning);
            }

            function focusedCategoryIndex() {
                for (let index = 0; index < categoryRepeater.count; index++) {
                    const button = categoryRepeater.itemAt(index);
                    if (button && button.activeFocus)
                        return index;
                }
                return -1;
            }

            function handleVimNavigation(event) {
                if (!(event.modifiers & Qt.ControlModifier)
                        || (event.modifiers & (Qt.ShiftModifier | Qt.AltModifier | Qt.MetaModifier)))
                    return false;

                if (emojiGrid.activeFocus) {
                    let targetIndex = emojiGrid.currentIndex;
                    let movedToSearch = false;
                    switch (event.key) {
                    case Qt.Key_H:
                        if (targetIndex % emojiGrid.columnCount > 0)
                            targetIndex--;
                        break;
                    case Qt.Key_J:
                        if (targetIndex + emojiGrid.columnCount < root.visibleEntries.length)
                            targetIndex += emojiGrid.columnCount;
                        break;
                    case Qt.Key_K:
                        if (targetIndex >= emojiGrid.columnCount) {
                            targetIndex -= emojiGrid.columnCount;
                        } else {
                            searchField.forceActiveFocus();
                            movedToSearch = true;
                        }
                        break;
                    case Qt.Key_L:
                        if (targetIndex % emojiGrid.columnCount < emojiGrid.columnCount - 1
                                && targetIndex + 1 < root.visibleEntries.length)
                            targetIndex++;
                        break;
                    default:
                        return false;
                    }

                    if (!movedToSearch) {
                        emojiGrid.currentIndex = targetIndex;
                        emojiGrid.forceActiveFocus();
                    }
                    event.accepted = true;
                    return true;
                }

                const categoryIndex = pickerView.focusedCategoryIndex();
                if (categoryIndex >= 0) {
                    switch (event.key) {
                    case Qt.Key_H:
                        pickerView.focusCategory(Math.max(0, categoryIndex - 1));
                        break;
                    case Qt.Key_J:
                        pickerView.focusFirstEmoji();
                        break;
                    case Qt.Key_K:
                        searchField.forceActiveFocus();
                        break;
                    case Qt.Key_L:
                        pickerView.focusCategory(Math.min(root.categoryOrder.length - 1, categoryIndex + 1));
                        break;
                    default:
                        return false;
                    }
                    event.accepted = true;
                    return true;
                }

                if (searchField.getActiveFocus() && event.key === Qt.Key_J) {
                    pickerView.focusFirstEmoji();
                    event.accepted = true;
                    return true;
                }

                if (searchField.getActiveFocus() && event.key === Qt.Key_K) {
                    event.accepted = true;
                    return true;
                }

                return false;
            }

            function handleSearchTyping(event) {
                if (searchField.getActiveFocus() || event.text.length === 0 || event.text.trim().length === 0
                        || (event.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier)))
                    return false;

                searchField.forceActiveFocus();
                searchField.cursorPosition = searchField.text.length;
                searchField.insertText(event.text);
                event.accepted = true;
                return true;
            }

            function handleGridSearchReset(event) {
                if (root.queuedEmojis.length > 0
                        || (event.key !== Qt.Key_Backspace && event.key !== Qt.Key_Delete))
                    return false;

                root.query = "";
                searchField.clear();
                root.selectedIndex = 0;
                searchField.forceActiveFocus();
                event.accepted = true;
                return true;
            }

            function selectCategory(category) {
                pickerView.hideVariantPopup();
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

            function cycleCategory(direction) {
                const currentIndex = root.categoryOrder.indexOf(root.selectedCategory);
                const categoryCount = root.categoryOrder.length;
                const nextIndex = (currentIndex + direction + categoryCount) % categoryCount;
                pickerView.selectCategory(root.categoryOrder[nextIndex]);
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

            function handleCommonShortcuts(event) {
                if (!(event.modifiers & Qt.ControlModifier) || (event.modifiers & (Qt.AltModifier | Qt.MetaModifier)))
                    return false;

                if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) {
                    const reverse = event.key === Qt.Key_Backtab || (event.modifiers & Qt.ShiftModifier);
                    pickerView.cycleCategory(reverse ? -1 : 1);
                    event.accepted = true;
                    return true;
                }

                if (event.modifiers & Qt.ShiftModifier)
                    return false;

                if (event.key === Qt.Key_F) {
                    searchField.forceActiveFocus();
                    searchField.selectAll();
                    event.accepted = true;
                    return true;
                }
                if (event.key === Qt.Key_C) {
                    root.commitCurrent(false);
                    event.accepted = true;
                    return true;
                }
                if (event.key === Qt.Key_V) {
                    root.commitCurrent(true);
                    event.accepted = true;
                    return true;
                }
                return false;
            }

            Keys.onPressed: event => {
                if (pickerView.handleCommonShortcuts(event))
                    return;
                if (pickerView.handleVimNavigation(event))
                    return;
                const category = pickerView.categoryForShortcut(event);
                if (category) {
                    pickerView.selectCategory(category);
                    event.accepted = true;
                    return;
                }
                if (event.key === Qt.Key_Down && searchField.getActiveFocus()) {
                    pickerView.focusFirstEmoji();
                    event.accepted = true;
                    return;
                }
                // Down from the header (close button) goes to the search field; the other rows handle their own arrows.
                if (event.key === Qt.Key_Down && !emojiGrid.activeFocus) {
                    searchField.forceActiveFocus();
                    event.accepted = true;
                    return;
                }
                pickerView.handleSearchTyping(event);
            }
            Keys.onEscapePressed: event => {
                if (pickerView.variantPopupVisible) {
                    pickerView.hideVariantPopup();
                    event.accepted = true;
                    return;
                }
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
                function onClosed() {
                    pickerView.hideVariantPopup();
                    skinToneDropdown.closeDropdownMenu();
                }
            }

            DDropdown {
                id: skinToneDropdown
                showTrigger: false
                popupAnchorItem: skinToneBtn
                popupWidth: 68
                alignPopupRight: true
                options: root.skinToneOptions
                currentValue: root.skinToneToOption(root.activeSkinTone)
                onValueChanged: value => {
                    root.setSkinTone(root.optionToSkinTone(value));
                    searchField.forceActiveFocus();
                }
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Theme.spacingM
                anchors.bottomMargin: root.showHints ? (footerBar.height + Theme.spacingXS) : 0
                spacing: Theme.spacingS

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.spacingS

                    DankSearchField {
                        id: searchField
                        Layout.fillWidth: true
                        placeholderText: root.selectedCategory === "recent" || !root.categoryNames[root.selectedCategory]
                            ? I18n.trFor("emojiPicker", "Search emoji")
                            : I18n.trFor("emojiPicker", "Search in %1").arg(I18n.trFor("emojiPicker", root.categoryNames[root.selectedCategory]))
                        text: root.query
                        onTextChanged: {
                            pickerView.hideVariantPopup();
                            root.query = text;
                            root.selectedIndex = 0;
                        }
                        ignoreUpDownKeys: true
                        keyForwardTargets: [pickerView]
                        Keys.onPressed: event => {
                            if (pickerView.handleCommonShortcuts(event))
                                return;
                            if (pickerView.handleVimNavigation(event))
                                return;
                            if (event.key === Qt.Key_Down) {
                                pickerView.focusFirstEmoji();
                                event.accepted = true;
                                return;
                            }
                            if (root.handleEnter(event))
                                return;
                            root.handleQueueBackspace(event, searchField.text.length === 0);
                        }
                        Keys.onTabPressed: {
                            pickerView.focusFirstEmoji();
                        }
                    }

                    Rectangle {
                        id: skinToneBtn
                        Layout.preferredWidth: Math.max(searchField.implicitHeight, searchField.height)
                        Layout.preferredHeight: Math.max(searchField.implicitHeight, searchField.height)
                        radius: height / 2
                        color: skinToneBtnMouse.containsMouse || skinToneDropdown.menuVisible
                            ? (typeof Theme.foregroundColor === "function" ? Theme.foregroundColor(Theme.surfaceContainerHigh) : Theme.surfaceContainerHigh)
                            : (typeof Theme.foregroundColor === "function" ? Theme.foregroundColor(Theme.chipSurface) : Theme.chipSurface)
                        border.width: 1
                        border.color: skinToneDropdown.menuVisible ? Theme.primary : Theme.outlineVariant

                        Behavior on color {
                            ColorAnimation {
                                duration: Theme.shortDuration ?? 150
                            }
                        }

                        StyledText {
                            anchors.centerIn: parent
                            text: root.skinToneIcon(root.activeSkinTone)
                            font.family: "Noto Color Emoji"
                            font.pixelSize: 20
                            color: Theme.surfaceText
                        }

                        MouseArea {
                            id: skinToneBtnMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: skinToneDropdown.openDropdownMenu()
                        }
                    }
                }

                Flickable {
                    id: categoryScroller
                    Layout.fillWidth: true
                    readonly property int ringInset: 4
                    Layout.preferredHeight: 56 + ringInset * 2
                    contentWidth: categoryRow.width + ringInset * 2
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    Row {
                        id: categoryRow
                        x: categoryScroller.ringInset
                        y: categoryScroller.ringInset
                        width: categoryScroller.width - categoryScroller.ringInset * 2
                        height: categoryScroller.height - categoryScroller.ringInset * 2
                        spacing: Theme.spacingXS

                        Repeater {
                            id: categoryRepeater
                            model: root.categoryOrder

                            DActionButton {
                                required property string modelData
                                required property int index
                                iconName: root.categoryIcons[modelData] || "category"
                                iconSize: 22
                                tooltipText: I18n.trFor("emojiPicker", root.categoryNames[modelData] || "")
                                buttonSize: (categoryRow.width - (root.categoryOrder.length - 1) * categoryRow.spacing) / root.categoryOrder.length
                                backgroundColor: root.selectedCategory === modelData ? Theme.primary : Theme.surfaceContainerHigh
                                iconColor: root.selectedCategory === modelData ? Theme.onPrimary : Theme.surfaceText
                                onClicked: pickerView.selectCategory(modelData)
                                Keys.onLeftPressed: pickerView.focusCategory(Math.max(0, index - 1))
                                Keys.onRightPressed: pickerView.focusCategory(Math.min(root.categoryOrder.length - 1, index + 1))
                                Keys.onUpPressed: searchField.forceActiveFocus()
                                Keys.onDownPressed: pickerView.focusFirstEmoji()
                                Keys.onPressed: event => {
                                    if (pickerView.handleCommonShortcuts(event))
                                        return;
                                    if (pickerView.handleVimNavigation(event))
                                        return;
                                }
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 26
                    spacing: Theme.spacingS

                    StyledText {
                        text: root.visibleEntries.length > 0 ? (root.query ? I18n.trFor("emojiPicker", "Search results") : (I18n.trFor("emojiPicker", root.categoryNames[root.selectedCategory] || ""))) : I18n.trFor("emojiPicker", "No emoji found")
                        color: Theme.surfaceVariantText
                        font.pixelSize: Theme.fontSizeSmall
                        verticalAlignment: Text.AlignVCenter
                    }

                    StyledText {
                        readonly property var highlightedEntry: pickerView.variantPopupVisible ? pickerView.variantEntry : (emojiGrid.hoveredIndex >= 0 ? root.visibleEntries[emojiGrid.hoveredIndex] : (emojiGrid.activeFocus ? root.visibleEntries[root.selectedIndex] : null))
                        Layout.fillWidth: true
                        text: highlightedEntry ? "·  " + highlightedEntry.name : ""
                        color: Theme.surfaceText
                        font.pixelSize: Theme.fontSizeSmall
                        font.weight: Font.Medium
                        elide: Text.ElideRight
                        verticalAlignment: Text.AlignVCenter
                    }

                    DButton {
                        visible: !root.query && root.selectedCategory === "recent" && root.recentEmojis.length > 0
                        text: I18n.trFor("emojiPicker", "Clear All")
                        iconName: "delete_sweep"
                        buttonHeight: 26
                        textColor: Theme.error
                        backgroundColor: Theme.withAlpha(Theme.error, 0.12)
                        onClicked: root.clearRecentHistory()
                    }
                }

                DGridView {
                    id: emojiGrid
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    readonly property int columnCount: root.emojisPerRow
                    readonly property real cellSize: width / root.emojisPerRow
                    cellWidth: cellSize
                    cellHeight: cellSize
                    clip: true
                    model: root.visibleEntries
                    currentIndex: root.selectedIndex
                    focus: false
                    keyNavigationEnabled: true
                    highlightFollowsCurrentItem: true
                    highlightMoveDuration: 0
                    highlight: null

                    property int hoveredIndex: -1

                    onCurrentIndexChanged: root.selectedIndex = currentIndex
                    onModelChanged: {
                        hoveredIndex = -1;
                        pickerView.hideVariantPopup();
                    }
                    onContentYChanged: pickerView.updateVariantPopupPosition()
                    onContentXChanged: pickerView.updateVariantPopupPosition()

                    delegate: Item {
                        id: delegateItem
                        required property var modelData
                        required property int index
                        readonly property bool isCurrent: GridView.isCurrentItem
                        width: emojiGrid.cellWidth
                        height: emojiGrid.cellHeight

                        Rectangle {
                            id: emojiBox
                            anchors.fill: parent
                            anchors.margins: 4
                            radius: Theme.cornerRadius
                            clip: true
                            color: delegateItem.isCurrent && emojiGrid.activeFocus ? Theme.withAlpha(Theme.primary, 0.16) : (emojiMouse.containsMouse ? Theme.surfaceContainerHigh : "transparent")
                            border.width: delegateItem.isCurrent && emojiGrid.activeFocus ? 2 : 0
                            border.color: Theme.primary

                            readonly property bool hasVariants: Boolean(delegateItem.modelData?.variants && delegateItem.modelData.variants.length > 0)

                            // Hold threshold: initial delay before progress bar starts, ensuring regular clicks never trigger hold animation
                            Timer {
                                id: holdThresholdTimer
                                interval: 220
                                repeat: false
                                onTriggered: {
                                    if (emojiMouse.pressed && emojiBox.hasVariants) {
                                        emojiMouse.holdThresholdPassed = true;
                                        holdProgressFill.startProgress();
                                        holdTimer.restart();
                                    }
                                }
                            }

                            // Visual hold fill animation from left to right
                            Rectangle {
                                id: holdProgressFill
                                anchors.left: parent.left
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                width: 0
                                radius: parent.radius
                                color: Theme.withAlpha(Theme.primary, 0.35)
                                visible: width > 0

                                PropertyAnimation {
                                    id: fillAnim
                                    target: holdProgressFill
                                    property: "width"
                                    from: 0
                                    to: emojiBox.width
                                    duration: 300
                                    easing.type: Easing.Linear
                                }

                                function startProgress() {
                                    fillAnim.stop();
                                    holdProgressFill.width = 0;
                                    fillAnim.start();
                                }

                                function resetProgress() {
                                    fillAnim.stop();
                                    holdProgressFill.width = 0;
                                }
                            }

                            Timer {
                                id: holdTimer
                                interval: 300
                                repeat: false
                                onTriggered: {
                                    emojiMouse.heldTriggered = true;
                                    holdProgressFill.resetProgress();
                                    pickerView.showVariantPopup(delegateItem.modelData, delegateItem);
                                }
                            }

                            StyledText {
                                anchors.centerIn: parent
                                text: root.displayEmoji(root.effectiveEmoji(delegateItem.modelData))
                                font.family: "Noto Color Emoji"
                                font.pixelSize: 32
                                color: Theme.surfaceText
                            }

                            MouseArea {
                                id: emojiMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                property bool heldTriggered: false
                                property bool holdThresholdPassed: false

                                function cancelHold() {
                                    holdThresholdTimer.stop();
                                    holdTimer.stop();
                                    holdProgressFill.resetProgress();
                                }

                                onPressed: mouse => {
                                    heldTriggered = false;
                                    holdThresholdPassed = false;
                                    const hasModifiers = Boolean(mouse.modifiers & (Qt.ShiftModifier | Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier));
                                    if (mouse.button === Qt.LeftButton && !hasModifiers && emojiBox.hasVariants) {
                                        holdThresholdTimer.restart();
                                    }
                                }

                                onReleased: cancelHold()
                                onCanceled: cancelHold()

                                onContainsMouseChanged: {
                                    if (containsMouse) {
                                        emojiGrid.hoveredIndex = delegateItem.index;
                                    } else {
                                        if (emojiGrid.hoveredIndex === delegateItem.index)
                                            emojiGrid.hoveredIndex = -1;
                                        cancelHold();
                                    }
                                }

                                onClicked: mouse => {
                                    cancelHold();
                                    if (heldTriggered || holdThresholdPassed) {
                                        heldTriggered = false;
                                        holdThresholdPassed = false;
                                        return;
                                    }
                                    pickerView.hideVariantPopup();
                                    const emojiToCommit = root.effectiveEmoji(delegateItem.modelData);
                                    if (mouse.button === Qt.LeftButton && (mouse.modifiers & Qt.ShiftModifier)) {
                                        root.appendEmoji(emojiToCommit);
                                        return;
                                    }
                                    const togglePaste = (mouse.button === Qt.RightButton) || Boolean(mouse.modifiers & Qt.ControlModifier);
                                    root.commitSingleEmoji(emojiToCommit, togglePaste !== root.pasteByDefault);
                                }
                            }
                        }
                    }

                    Keys.priority: Keys.BeforeItem
                    Keys.onPressed: event => {
                        if (pickerView.handleCommonShortcuts(event))
                            return;
                        if (pickerView.handleVimNavigation(event))
                            return;
                        if (root.handleEnter(event))
                            return;
                        if (root.handleQueueBackspace(event, true))
                            return;
                        if (pickerView.handleGridSearchReset(event))
                            return;
                        if (pickerView.handleSearchTyping(event))
                            return;
                        if (event.key === Qt.Key_Up) {
                            if (emojiGrid.currentIndex < emojiGrid.columnCount) {
                                searchField.forceActiveFocus();
                                event.accepted = true;
                            }
                        }
                    }
                    Keys.onEscapePressed: event => {
                        if (pickerView.variantPopupVisible) {
                            pickerView.hideVariantPopup();
                            event.accepted = true;
                            return;
                        }
                        root.handleEscape(event);
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

            // Keyboard hints strip, styled after the DMS launcher footer.
            Item {
                id: footerBar
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: 40
                visible: root.showHints
                clip: true

                Rectangle {
                    anchors.fill: parent
                    anchors.topMargin: -Theme.cornerRadius
                    visible: !Theme.blurLayersActive
                    color: Theme.withAlpha(Theme.surfaceContainerHigh, Theme.popupTransparency)
                    radius: Theme.cornerRadius
                }

                Row {
                    anchors.right: parent.right
                    anchors.rightMargin: Theme.spacingM
                    anchors.verticalCenter: parent.verticalCenter
                    layoutDirection: I18n.isRtl ? Qt.RightToLeft : Qt.LeftToRight
                    spacing: Theme.spacingM

                    Repeater {
                        model: [
                            { keys: "↑ ↓", label: I18n.trFor("emojiPicker", "nav"), shown: true },
                            { keys: "↵", label: root.pasteByDefault ? I18n.trFor("emojiPicker", "Paste") : I18n.trFor("emojiPicker", "Copy"), shown: true },
                            { keys: "Ctrl ↵", label: root.pasteByDefault ? I18n.trFor("emojiPicker", "Copy") : I18n.trFor("emojiPicker", "Paste"), shown: true },
                            { keys: "Shift ↵", label: I18n.trFor("emojiPicker", "Queue"), shown: true },
                            { keys: "⌫", label: I18n.trFor("emojiPicker", "Remove"), shown: root.queuedEmojis.length > 0 },
                            { keys: "Esc", label: root.queuedEmojis.length > 0 ? I18n.trFor("emojiPicker", "Clear") : I18n.trFor("emojiPicker", "Close"), shown: true }
                        ]

                        Row {
                            required property var modelData
                            visible: modelData.shown
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: Theme.spacingXS

                            DKeycap {
                                anchors.verticalCenter: parent.verticalCenter
                                text: parent.modelData.keys
                            }

                            StyledText {
                                anchors.verticalCenter: parent.verticalCenter
                                text: parent.modelData.label.toLocaleLowerCase()
                                font.pixelSize: Theme.fontSizeSmall
                                color: Theme.surfaceVariantText
                            }
                        }
                    }
                }
            }

            // Scrim overlay: catches all clicks and hover events outside the popup to dismiss it cleanly without propagating to items beneath
            MouseArea {
                anchors.fill: parent
                visible: pickerView.variantPopupVisible
                z: 99
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: mouse => {
                    pickerView.hideVariantPopup();
                    mouse.accepted = true;
                }
            }

            // Skin tone variant selector popup
            Rectangle {
                id: variantPopup
                visible: pickerView.variantPopupVisible
                z: 100
                x: pickerView.variantPopupX
                y: pickerView.variantPopupY
                width: variantRow.width + Theme.spacingS * 2
                height: 44
                onWidthChanged: pickerView.updateVariantPopupPosition()
                radius: Theme.cornerRadius
                color: Theme.surfaceContainerHigh
                border.width: 1
                border.color: Theme.outlineVariant

                Canvas {
                    id: variantArrowCanvas
                    width: 16
                    height: 8
                    x: Math.round(pickerView.variantArrowOffsetX - width / 2)
                    y: pickerView.variantPopupPlacement === "below" ? -height + 1 : parent.height - 1

                    readonly property color fillColor: Theme.surfaceContainerHigh
                    readonly property color strokeColor: Theme.outlineVariant
                    readonly property string placement: pickerView.variantPopupPlacement

                    onFillColorChanged: requestPaint()
                    onStrokeColorChanged: requestPaint()
                    onPlacementChanged: requestPaint()
                    onVisibleChanged: {
                        if (visible)
                            requestPaint();
                    }

                    onPaint: {
                        const ctx = getContext("2d");
                        ctx.clearRect(0, 0, width, height);

                        const pointingUp = placement === "below";
                        const baseY = pointingUp ? height : 0;
                        const strokeBaseY = pointingUp ? height - 0.5 : 0.5;
                        const tipY = pointingUp ? 1 : height - 1;

                        ctx.beginPath();
                        ctx.moveTo(1, baseY);
                        ctx.lineTo(width / 2, tipY);
                        ctx.lineTo(width - 1, baseY);
                        ctx.closePath();
                        ctx.fillStyle = fillColor;
                        ctx.fill();

                        ctx.beginPath();
                        ctx.moveTo(1, strokeBaseY);
                        ctx.lineTo(width / 2, tipY);
                        ctx.lineTo(width - 1, strokeBaseY);
                        ctx.strokeStyle = strokeColor;
                        ctx.lineWidth = 1;
                        ctx.lineJoin = "round";
                        ctx.stroke();
                    }
                }

                Row {
                    id: variantRow
                    anchors.centerIn: parent
                    spacing: 4

                    Repeater {
                        model: pickerView.variantPopupOptions

                        Rectangle {
                            id: variantItem
                            required property string modelData
                            required property int index
                            width: 36
                            height: 36
                            radius: Theme.cornerRadiusSmall
                            color: variantMouse.containsMouse ? Theme.surfaceContainerHighest : (Theme.transparent ?? "transparent")

                            StyledText {
                                anchors.centerIn: parent
                                text: root.displayEmoji(variantItem.modelData)
                                font.family: "Noto Color Emoji"
                                font.pixelSize: 22
                                color: Theme.surfaceText
                            }

                            MouseArea {
                                id: variantMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                onClicked: mouse => {
                                    const emojiToCommit = variantItem.modelData;
                                    pickerView.hideVariantPopup();
                                    if (mouse.button === Qt.LeftButton && (mouse.modifiers & Qt.ShiftModifier)) {
                                        root.appendEmoji(emojiToCommit);
                                        return;
                                    }
                                    const togglePaste = (mouse.button === Qt.RightButton) || Boolean(mouse.modifiers & Qt.ControlModifier);
                                    root.commitSingleEmoji(emojiToCommit, togglePaste !== root.pasteByDefault);
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
