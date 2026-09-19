import QtQuick
import Quickshell
import qs.Common
import qs.Widgets
import qs.Modules.Plugins
import qs.Services

PluginComponent {
    id: rootWidget

    pluginId: "desktopWidgetToggle"
    pluginService: PluginService

    // Local reactive views of the settings
    property var groups: pluginData.groups ?? [
        { "id": "g1", "name": "Group 1", "icon": "widgets", "widgets": [], "autoDismissDuration": 0 }
    ]
    property string conflictMode: pluginData.conflictMode ?? "single"
    property var activeGroupIds: pluginData.activeGroupIds ?? []
    readonly property string displayMode: rootWidget.pluginData?.displayMode ?? "all"

    // Popout settings
    popoutWidth: 320
    popoutHeight: 0 // auto from content

    popoutContent: Component {
        PopoutComponent {
            headerText: I18n.tr("Desktop Widgets")
            detailsText: {
                const activeCount = rootWidget.activeGroupIds.length;
                if (activeCount === 0) return I18n.tr("No active groups");
                if (activeCount === 1) return I18n.tr("1 active group");
                return I18n.tr("%1 active groups").arg(activeCount);
            }
            showCloseButton: true

            Column {
                width: parent.width
                spacing: Theme.spacingS

                Repeater {
                    model: rootWidget.groups

                    delegate: StyledRect {
                        id: popoutItem
                        required property var modelData

                        width: parent.width
                        height: 48
                        radius: Theme.cornerRadius

                        readonly property bool isActive: rootWidget.activeGroupIds.includes(modelData.id)
                        readonly property bool isDisabled: {
                            if (isActive) return false;
                            if (rootWidget.conflictMode === "single") {
                                return rootWidget.activeGroupIds.length > 0;
                            }
                            if (rootWidget.conflictMode === "overlap") {
                                const daemon = pluginService.pluginInstances[rootWidget.pluginId];
                                return daemon ? daemon.hasOverlapWithActive(modelData.id, rootWidget.activeGroupIds) : false;
                            }
                            return false;
                        }

                        color: isActive 
                            ? Theme.withAlpha(Theme.primary, 0.15) 
                            : (popoutItemArea.containsMouse ? Theme.surfaceContainerHigh : Theme.surfaceContainer)
                        border.color: isActive ? Theme.primary : Theme.withAlpha(Theme.outline, 0.1)
                        border.width: 1
                        opacity: isDisabled ? 0.4 : 1.0

                        DankIcon {
                            id: popoutItemIcon
                            name: modelData.icon || "widgets"
                            size: 24
                            color: popoutItem.isActive ? Theme.primary : Theme.surfaceText
                            anchors.left: parent.left
                            anchors.leftMargin: Theme.spacingM
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        StyledText {
                            id: popoutItemText
                            text: modelData.name || ""
                            font.pixelSize: Theme.fontSizeMedium
                            font.weight: popoutItem.isActive ? Font.Medium : Font.Normal
                            color: popoutItem.isActive ? Theme.primary : Theme.surfaceText
                            anchors.left: popoutItemIcon.right
                            anchors.leftMargin: Theme.spacingM
                            anchors.right: popoutItemToggle.left
                            anchors.rightMargin: Theme.spacingM
                            anchors.verticalCenter: parent.verticalCenter
                            elide: Text.ElideRight
                        }

                        DankToggle {
                            id: popoutItemToggle
                            checked: popoutItem.isActive
                            enabled: !popoutItem.isDisabled
                            anchors.right: parent.right
                            anchors.rightMargin: Theme.spacingM
                            anchors.verticalCenter: parent.verticalCenter
                            onToggled: isChecked => {
                                const daemon = pluginService.pluginInstances[rootWidget.pluginId];
                                if (daemon) {
                                    daemon.toggleGroup(modelData.id);
                                }
                            }
                        }

                        MouseArea {
                            id: popoutItemArea
                            anchors.fill: parent
                            enabled: !popoutItem.isDisabled
                            hoverEnabled: true
                            cursorShape: popoutItem.isDisabled ? Qt.ArrowCursor : Qt.PointingHandCursor
                            onClicked: {
                                const daemon = pluginService.pluginInstances[rootWidget.pluginId];
                                if (daemon) {
                                    daemon.toggleGroup(modelData.id);
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    horizontalBarPill: Component {
        Item {
            implicitWidth: rootWidget.displayMode === "minimal" ? minimalPill.implicitWidth : horizontalRow.implicitWidth
            implicitHeight: rootWidget.displayMode === "minimal" ? minimalPill.implicitHeight : horizontalRow.implicitHeight

            Row {
                id: horizontalRow
                spacing: Theme.spacingS
                height: rootWidget.widgetThickness
                visible: rootWidget.displayMode === "all"

                Repeater {
                    model: rootWidget.groups

                    delegate: StyledRect {
                        id: btn
                        required property var modelData

                        width: contentRow.width + Theme.spacingM * 2
                        height: parent.height
                        radius: Theme.cornerRadius

                        readonly property bool isActive: rootWidget.activeGroupIds.includes(modelData.id)
                        readonly property bool isDisabled: {
                            if (isActive) return false;
                            if (rootWidget.conflictMode === "single") {
                                return rootWidget.activeGroupIds.length > 0;
                            }
                            if (rootWidget.conflictMode === "overlap") {
                                const daemon = pluginService.pluginInstances[rootWidget.pluginId];
                                return daemon ? daemon.hasOverlapWithActive(modelData.id, rootWidget.activeGroupIds) : false;
                            }
                            return false;
                        }

                        color: isActive ? Theme.primary : (isDisabled ? Theme.surfaceContainerLow : Theme.surfaceContainerHigh)
                        opacity: isDisabled ? 0.4 : 1.0

                        Row {
                            id: contentRow
                            anchors.centerIn: parent
                            spacing: Theme.spacingXS

                            DankIcon {
                                name: modelData.icon || "widgets"
                                size: Theme.barIconSize(rootWidget.barThickness, -4, rootWidget.barConfig?.maximizeWidgetIcons, rootWidget.barConfig?.iconScale)
                                color: btn.isActive ? Theme.onPrimary : Theme.surfaceText
                                anchors.verticalCenter: parent.verticalCenter
                                Behavior on color { enabled: false }
                                visible: modelData.showIcon !== false && name !== ""
                            }

                            StyledText {
                                text: modelData.name || ""
                                font.pixelSize: Theme.fontSizeSmall
                                color: btn.isActive ? Theme.onPrimary : Theme.surfaceText
                                visible: modelData.name !== ""
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            enabled: !btn.isDisabled
                            cursorShape: btn.isDisabled ? Qt.ArrowCursor : Qt.PointingHandCursor
                            onClicked: {
                                const daemon = pluginService.pluginInstances[rootWidget.pluginId];
                                if (daemon) {
                                    daemon.toggleGroup(modelData.id);
                                } else {
                                    console.warn("[desktopWidgetToggle] Daemon not found; fallback to settings change");
                                }
                            }
                        }
                    }
                }
            }

            Row {
                id: minimalPill
                visible: rootWidget.displayMode === "minimal"
                spacing: Theme.spacingXS
                anchors.verticalCenter: parent.verticalCenter

                readonly property bool hasActive: rootWidget.activeGroupIds.length > 0

                DankIcon {
                    name: "widgets"
                    size: Theme.iconSizeSmall
                    color: minimalPill.hasActive ? Theme.primary : Theme.surfaceVariantText
                    anchors.verticalCenter: parent.verticalCenter
                }

                StyledText {
                    text: rootWidget.activeGroupIds.length
                    font.pixelSize: Theme.fontSizeSmall
                    font.bold: true
                    color: Theme.primary
                    visible: rootWidget.activeGroupIds.length > 0
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }
    }

    verticalBarPill: Component {
        Item {
            implicitWidth: rootWidget.displayMode === "minimal" ? minimalVerticalPill.implicitWidth : verticalColumn.implicitWidth
            implicitHeight: rootWidget.displayMode === "minimal" ? minimalVerticalPill.implicitHeight : verticalColumn.implicitHeight

            Column {
                id: verticalColumn
                spacing: Theme.spacingS
                width: rootWidget.widgetThickness

                Repeater {
                    model: rootWidget.groups

                    delegate: StyledRect {
                        id: btn
                        required property var modelData

                        width: parent.width
                        height: width
                        radius: Theme.cornerRadius

                        readonly property bool isActive: rootWidget.activeGroupIds.includes(modelData.id)
                        readonly property bool isDisabled: {
                            if (isActive) return false;
                            if (rootWidget.conflictMode === "single") {
                                return rootWidget.activeGroupIds.length > 0;
                            }
                            if (rootWidget.conflictMode === "overlap") {
                                const daemon = pluginService.pluginInstances[rootWidget.pluginId];
                                return daemon ? daemon.hasOverlapWithActive(modelData.id, rootWidget.activeGroupIds) : false;
                            }
                            return false;
                        }

                        color: isActive ? Theme.primary : (isDisabled ? Theme.surfaceContainerLow : Theme.surfaceContainerHigh)
                        opacity: isDisabled ? 0.4 : 1.0

                        DankIcon {
                            name: modelData.icon || "widgets"
                            size: Theme.barIconSize(rootWidget.barThickness, -4, rootWidget.barConfig?.maximizeWidgetIcons, rootWidget.barConfig?.iconScale)
                            color: btn.isActive ? Theme.onPrimary : Theme.surfaceText
                            anchors.centerIn: parent
                            Behavior on color { enabled: false }
                            visible: modelData.showIcon !== false
                        }

                        StyledText {
                            text: (modelData.name || "").substring(0, 2)
                            font.pixelSize: Theme.fontSizeMedium
                            font.weight: Font.Bold
                            color: btn.isActive ? Theme.onPrimary : Theme.surfaceText
                            anchors.centerIn: parent
                            visible: modelData.showIcon === false
                        }

                        MouseArea {
                            anchors.fill: parent
                            enabled: !btn.isDisabled
                            cursorShape: btn.isDisabled ? Qt.ArrowCursor : Qt.PointingHandCursor
                            onClicked: {
                                const daemon = pluginService.pluginInstances[rootWidget.pluginId];
                                if (daemon) {
                                    daemon.toggleGroup(modelData.id);
                                } else {
                                    console.warn("[desktopWidgetToggle] Daemon not found; fallback to settings change");
                                }
                            }
                        }
                    }
                }
            }

            Column {
                id: minimalVerticalPill
                visible: rootWidget.displayMode === "minimal"
                spacing: 2
                anchors.horizontalCenter: parent.horizontalCenter

                readonly property bool hasActive: rootWidget.activeGroupIds.length > 0

                DankIcon {
                    name: "widgets"
                    size: Theme.iconSizeSmall
                    color: minimalVerticalPill.hasActive ? Theme.primary : Theme.surfaceVariantText
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                StyledText {
                    text: rootWidget.activeGroupIds.length
                    font.pixelSize: 10
                    font.bold: true
                    color: Theme.primary
                    visible: rootWidget.activeGroupIds.length > 0
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }
        }
    }
}
