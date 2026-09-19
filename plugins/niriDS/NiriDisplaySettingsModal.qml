import QtQuick
import Quickshell
import qs.Common
import qs.Modals.Common
import qs.Services
import qs.Widgets
import "./dms-common"

DankModal {
    id: root

    layerNamespace: "dms:plugins:niriDS"
    keepPopoutsOpen: true
    useOverlayLayer: true
    property int selectedIndex: 0
    property int optionCount: NiriDS.displays ? NiriDS.displays.length : 0
    property rect parentBounds: Qt.rect(0, 0, 0, 0)
    readonly property bool hasExternal: NiriDS.hasExternal

    function openCentered() {
        parentBounds = Qt.rect(0, 0, 0, 0);
        const bgOpacity = PluginService ? PluginService.loadPluginData("niriDS", "bgOpacity", 50) : 50;
        backgroundOpacity = bgOpacity / 100.0;
        open();
        NiriDS.setDisplays();
    }

    shouldBeVisible: false
    modalWidth: 400
    modalHeight: (typeof contentLoader !== 'undefined' && contentLoader && contentLoader.item) ? contentLoader.item.implicitHeight : 450
    enableShadow: true
    positioning: parentBounds.width > 0 ? "custom" : "center"

    customPosition: {
        if (parentBounds.width > 0) {
            const centerX = parentBounds.x + (parentBounds.width - modalWidth) / 2;
            const centerY = parentBounds.y + (parentBounds.height - modalHeight) / 2;
            return Qt.point(centerX, centerY);
        }
        return Qt.point(0, 0);
    }

    onBackgroundClicked: () => close()
    onOpened: () => {
        const displays = NiriDS ? NiriDS.displays : [];
        const enabledCount = displays.filter(d => !d.disabled).length;
        
        let firstSelectable = 0;
        for (let i = 0; i < displays.length; i++) {
            const isLast = enabledCount === 1 && !displays[i].disabled;
            if (!isLast) {
                firstSelectable = i;
                break;
            }
        }
        selectedIndex = firstSelectable;
        Qt.callLater(() => {
            if (modalFocusScope) modalFocusScope.forceActiveFocus();
        });
    }

    modalFocusScope.Keys.onPressed: event => {
        function getNextEnabledIndex(current, direction) {
            const displays = NiriDS ? NiriDS.displays : [];
            let count = 0;
            let index = current;
            
            while (count < optionCount) {
                index = (index + direction + optionCount) % optionCount;
                const item = displays[index];
                const isLast = displays.filter(d => !d.disabled).length === 1 && !item.disabled;
                if (!isLast) return index;
                count++;
            }
            return current;
        }

        switch (event.key) {
            case Qt.Key_Up:
            case Qt.Key_Backtab:
                selectedIndex = getNextEnabledIndex(selectedIndex, -1);
                event.accepted = true;
                break;
            case Qt.Key_Down:
            case Qt.Key_Tab:
                selectedIndex = getNextEnabledIndex(selectedIndex, 1);
                event.accepted = true;
                break;
            case Qt.Key_Return:
            case Qt.Key_Enter:
                if (optionCount > 0) {
                    const item = (NiriDS && NiriDS.displays) ? NiriDS.displays[selectedIndex] : null;
                    const enabledCount = (NiriDS ? NiriDS.displays : []).filter(d => !d.disabled).length;
                    const isLast = enabledCount === 1 && item && !item.disabled;
                    if (!isLast) NiriDS.toggleDisable(item);
                }
                event.accepted = true;
                break;
            case Qt.Key_1: 
                if (hasExternal) { NiriDS.apply("external_only"); root.close(); }
                event.accepted = true; 
                break;
            case Qt.Key_2: 
                if (hasExternal) { NiriDS.apply("extend"); root.close(); }
                event.accepted = true; 
                break;
            case Qt.Key_3:
                if (hasExternal) { NiriDS.apply("mirror"); root.close(); }
                event.accepted = true; break;
            case Qt.Key_4: NiriDS.apply("internal_only"); root.close(); event.accepted = true; break;
        }
    }

    content: Component {
        Item {
            implicitHeight: mainColumn.implicitHeight + Theme.spacingL * 2
            width: root.modalWidth

            Column {
                id: mainColumn
                anchors.fill: parent
                anchors.margins: Theme.spacingL
                spacing: Theme.spacingL

                HeaderRow {
                    title: I18n.tr("Display Settings")
                    onCloseClicked: () => close()
                }

                // Section 1: Display Profiles
                Column {
                    id: profileSection
                    width: parent.width
                    spacing: Theme.spacingS

                    StyledText {
                        text: I18n.tr("Project")
                        font.pixelSize: Theme.fontSizeMedium
                        color: Theme.surfaceText
                        font.weight: Font.Medium
                        opacity: 0.6
                        bottomPadding: Theme.spacingS
                    }
                    ShortcutCard {
                        iconName: "tv"
                        label: I18n.tr("External Only")
                        shortcut: "1"
                        disabled: !root.hasExternal
                        onClicked: { NiriDS.apply("external_only"); root.close(); }
                    }
                    ShortcutCard {
                        iconName: "grid_view"
                        label: I18n.tr("Extended")
                        shortcut: "2"
                        disabled: !root.hasExternal
                        onClicked: { NiriDS.apply("extend"); root.close(); }
                    }
                    ShortcutCard {
                        iconName: "screen_share"
                        label: I18n.tr("Mirror")
                        shortcut: "3"
                        disabled: !root.hasExternal
                        onClicked: { NiriDS.apply("mirror"); root.close(); }
                    }
                    ShortcutCard {
                        iconName: "computer"
                        label: I18n.tr("Internal Only")
                        shortcut: "4"
                        onClicked: { NiriDS.apply("internal_only"); root.close(); }
                    }
                }

                // Section 2: Manual Output Toggles
                Column {
                    width: parent.width
                    spacing: Theme.spacingS

                    StyledText {
                        text: I18n.tr("Manual Control")
                        font.pixelSize: Theme.fontSizeMedium
                        color: Theme.surfaceText
                        font.weight: Font.Medium
                        opacity: 0.6
                        topPadding: Theme.spacingM
                        bottomPadding: Theme.spacingS
                    }

                    DankListView {
                        width: parent.width
                        spacing: Theme.spacingS
                        height: (60 * root.optionCount) + Theme.spacingS
                        
                        // Using ScriptModel which worked before
                        model: ScriptModel { 
                            id: dispModel
                            values: NiriDS.displays 
                        }

                        Connections {
                            target: NiriDS
                            function onDisplaysChanged() {
                                dispModel.values = [...NiriDS.displays];
                            }
                        }

                        delegate: Rectangle {
                            width: parent.width
                            implicitHeight: 60
                            radius: Theme.cornerRadius
                            color: isOnlyEnabled && modelData && !modelData.disabled ?
                                Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g, Theme.surfaceVariant.b, 0.04) :
                                (selectedIndex === index ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12) : (itemHover.containsMouse ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.08) : Qt.rgba(Theme.surfaceVariant.r, Theme.surfaceVariant.g, Theme.surfaceVariant.b, 0.08)))
                            opacity: isOnlyEnabled && modelData && !modelData.disabled ? 0.5 : 1.0
                            border.color: selectedIndex === index ? Theme.primary : "transparent"
                            border.width: selectedIndex === index ? 1 : 0

                            property bool isOnlyEnabled: {
                                const enabledCount = (NiriDS ? NiriDS.displays : []).filter(d => !d.disabled).length;
                                return enabledCount === 1 && !(modelData && modelData.disabled);
                            }

                            DankIcon {
                                id: iIcon
                                name: (modelData && modelData.name && NiriDS.isInternalName(modelData.name)) ? "computer" : "tv"
                                size: Theme.iconSize
                                color: Theme.surfaceText
                                anchors.left: parent.left
                                anchors.leftMargin: Theme.spacingL
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            StyledText {
                                text: modelData ? (modelData.friendlyName || "Unknown") : "Unknown"
                                font.pixelSize: Theme.fontSizeMedium
                                color: Theme.surfaceText
                                font.weight: Font.Medium
                                anchors.left: iIcon.right
                                anchors.leftMargin: Theme.spacingL
                                anchors.right: statusDot.left
                                anchors.rightMargin: Theme.spacingM
                                anchors.verticalCenter: parent.verticalCenter
                                elide: Text.ElideRight
                            }

                            StatusDot {
                                id: statusDot
                                active: !(modelData && modelData.disabled)
                                anchors.right: parent.right
                                anchors.rightMargin: Theme.spacingL
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            MouseArea {
                                id: itemHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: isOnlyEnabled ? Qt.ArrowCursor : Qt.PointingHandCursor
                                onClicked: {
                                    if (!isOnlyEnabled) NiriDS.toggleDisable(modelData)
                                }
                            }
                        }
                    }

                    StyledText {
                        text: I18n.tr("No displays detected...")
                        font.pixelSize: Theme.fontSizeSmall
                        color: Theme.surfaceText
                        opacity: 0.4
                        visible: root.optionCount === 0
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }
            }
        }
    }
}
