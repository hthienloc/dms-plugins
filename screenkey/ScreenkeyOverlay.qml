import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Common
import qs.Widgets
import "./dms-common"

PanelWindow {
    id: overlayWindow

    property var daemon: null
    readonly property bool isCentered: daemon ? (daemon.position === "bottom_center" || daemon.position === "top_center") : false
    readonly property bool isMouseClick: daemon ? (daemon.displayText === "LMB Click" || daemon.displayText === "RMB Click" || daemon.displayText === "MMB Click") : false
    readonly property bool isOverlayVisible: daemon && (daemon.displayText !== "" || (daemon.showModifierStatus && (daemon.ctrlActive || daemon.altActive || daemon.shiftActive || daemon.superActive)))

    // Dynamic positioning based on settings (e.g. "bottom_center", "top_left", etc.)
    anchors.bottom: daemon ? daemon.position.includes("bottom") : false
    anchors.top: daemon ? daemon.position.includes("top") : false
    anchors.left: isCentered || (daemon ? daemon.position.includes("left") : false)
    anchors.right: isCentered || (daemon ? daemon.position.includes("right") : false)

    // Wayland specific window properties
    WlrLayershell.layer: WlrLayershell.Overlay
    WlrLayershell.keyboardFocus: WlrLayershell.None // Absolutely critical: do not steal focus
    WlrLayershell.exclusiveZone: -1
    exclusionMode: ExclusionMode.Ignore

    WlrLayershell.margins {
        left: daemon ? daemon.marginSize : 24
        right: daemon ? daemon.marginSize : 24
        top: daemon ? daemon.marginSize : 24
        bottom: daemon ? daemon.marginSize : 24
    }

    // Dummy text to calculate a unified height based on current font size
    StyledText {
        id: dummyText
        visible: false
        font.pixelSize: daemon ? daemon.fontSize : 24
        font.bold: true
        text: "A"
    }

    readonly property real unifiedHeight: dummyText.implicitHeight + Theme.spacingXS * 2
    function resolveColor(mode, custom) {
        if (mode === "custom") return custom ? Qt.color(custom) : Theme.primary;
        if (mode === "default") return Theme.primary;
        return Theme.roleColor(mode);
    }

    function getOverlayKeyText(keyText) {
        if (!daemon || !daemon.macSymbols) return keyText;
        const macMap = {
            "Ctrl": "⌃",
            "Alt": "⌥",
            "Shift": "⇧",
            "Super": "⌘",
            "Enter": "⏎",
            "Backspace": "⌫",
            "Tab": "⇥",
            "Esc": "⎋",
            "Space": "␣"
        };
        return macMap[keyText] || keyText;
    }

    readonly property color resolvedTextColor: daemon ? overlayWindow.resolveColor(daemon.textColorMode, daemon.textColorCustom) : Theme.primary
    readonly property color resolvedKeycapTextColor: daemon ? overlayWindow.resolveColor(daemon.keycapTextColorMode, daemon.keycapTextColorCustom) : Theme.primary
    readonly property bool roundedKeycaps: daemon ? daemon.roundedKeycaps : true
    readonly property color resolvedBgColor: {
        if (!daemon) return Theme.withAlpha(Theme.surface, 0.85);
        if (daemon.bgColorMode === "default") return Theme.withAlpha(Theme.surface, 0.85);
        if (daemon.bgColorMode === "custom") return Qt.color(daemon.bgColorCustom);
        return Theme.roleColor(daemon.bgColorMode);
    }

    // Match window size to container size
    implicitWidth: isCentered ? (screen ? screen.width : 1920) : cardContainer.width
    implicitHeight: cardContainer.height
    color: "transparent"

    StyledRect {
        id: cardContainer
        
        // Match contents with padding
        width: contentColumn.implicitWidth + Theme.spacingXL * 2
        height: contentColumn.implicitHeight + Theme.spacingL * 2
        
        anchors.top: (daemon && daemon.position.includes("top")) ? parent.top : undefined
        anchors.bottom: (daemon && daemon.position.includes("bottom")) ? parent.bottom : undefined
        anchors.left: (daemon && daemon.position.includes("left")) ? parent.left : undefined
        anchors.right: (daemon && daemon.position.includes("right")) ? parent.right : undefined
        anchors.horizontalCenter: isCentered ? parent.horizontalCenter : undefined

        // Smooth scaling when content changes
        Behavior on width { NumberAnimation { duration: 100 } }
        Behavior on height { NumberAnimation { duration: 100 } }

        radius: Theme.cornerRadius
        color: overlayWindow.resolvedBgColor
        border.color: Theme.withAlpha(Theme.outline, 0.15)
        border.width: 1

        // Display with dynamic animations based on settings
        opacity: overlayWindow.isOverlayVisible ? (daemon ? daemon.overlayOpacity / 100.0 : 0.9) : 0.0
        scale: overlayWindow.isOverlayVisible ? 1.0 : (daemon && daemon.animationType === "zoom" ? 0.9 : 1.0)

        property real yOffset: {
            if (!daemon || daemon.animationType !== "slide") return 0;
            const isVisible = overlayWindow.isOverlayVisible;
            if (isVisible) return 0;
            const isTop = daemon.position.includes("top");
            return isTop ? -20 : 20;
        }

        transform: Translate {
            y: cardContainer.yOffset
        }

        Behavior on opacity {
            enabled: daemon && daemon.animationType !== "none"
            OpacityAnimator { duration: 150 }
        }

        Behavior on scale {
            enabled: daemon && daemon.animationType === "zoom"
            NumberAnimation { duration: 150; easing.type: Easing.OutBack }
        }

        Behavior on yOffset {
            enabled: daemon && daemon.animationType === "slide"
            NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
        }

        Column {
            id: contentColumn
            anchors.centerIn: parent
            spacing: Theme.spacingS

            Repeater {
                model: daemon ? daemon.historyList : []
                delegate: Row {
                    spacing: (daemon && daemon.macSymbols) ? Theme.spacingXS : Theme.spacingS
                    anchors.horizontalCenter: isCentered ? parent.horizontalCenter : undefined

                    readonly property string lineText: modelData.text
                    readonly property bool isCombo: modelData.isCombo
                    readonly property bool isMouseClick: lineText === "LMB Click" || lineText === "RMB Click" || lineText === "MMB Click"
                    readonly property var keysList: isCombo ? lineText.split(" + ") : []

                    // Render keycaps for combinations
                    Repeater {
                        model: isCombo ? keysList : 0
                        delegate: Row {
                            spacing: (daemon && daemon.macSymbols) ? Theme.spacingXS : Theme.spacingS
                            anchors.verticalCenter: parent.verticalCenter

                            StyledRect {
                                anchors.verticalCenter: parent.verticalCenter
                                width: keycapText.implicitWidth + Theme.spacingM * 2
                                height: overlayWindow.unifiedHeight
                                radius: overlayWindow.roundedKeycaps ? Theme.cornerRadius / 2 : 0
                                color: Theme.surfaceContainerHighest
                                border.color: Theme.withAlpha(Theme.outline, 0.25)
                                border.width: 1

                                StyledText {
                                    id: keycapText
                                    anchors.centerIn: parent
                                    font.pixelSize: daemon ? daemon.fontSize : 24
                                    font.bold: true
                                    color: overlayWindow.resolvedKeycapTextColor
                                    text: overlayWindow.getOverlayKeyText(modelData)
                                }
                            }

                            // Render separator unless it is the last item
                            StyledText {
                                visible: index < keysList.length - 1
                                anchors.verticalCenter: parent.verticalCenter
                                font.pixelSize: daemon ? daemon.fontSize : 24
                                font.bold: true
                                color: Theme.outline
                                text: daemon ? daemon.customSeparator : "+"
                            }
                        }
                    }

                    // Render mouse click indicator
                    Row {
                        id: mouseIcon
                        visible: isMouseClick
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Theme.spacingS
                        height: overlayWindow.unifiedHeight

                        readonly property bool isLeft: lineText === "LMB Click"
                        readonly property bool isRight: lineText === "RMB Click"
                        readonly property bool isMiddle: lineText === "MMB Click"

                        Rectangle {
                            width: 14
                            height: 22
                            radius: 7
                            color: "transparent"
                            border.color: Theme.outline
                            border.width: 1.5
                            anchors.verticalCenter: parent.verticalCenter

                            Rectangle {
                                width: 7
                                height: 11
                                radius: 3
                                color: mouseIcon.isLeft ? Theme.primary : "transparent"
                                border.color: Theme.outline
                                border.width: 1
                                anchors.left: parent.left
                                anchors.top: parent.top
                            }

                            Rectangle {
                                width: 7
                                height: 11
                                radius: 3
                                color: mouseIcon.isRight ? Theme.primary : "transparent"
                                border.color: Theme.outline
                                border.width: 1
                                anchors.right: parent.right
                                anchors.top: parent.top
                            }

                            Rectangle {
                                width: 2
                                height: 5
                                radius: 1
                                color: mouseIcon.isMiddle ? Theme.primary : Theme.outline
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.top: parent.top
                                anchors.topMargin: 3
                            }
                        }

                        StyledText {
                            anchors.verticalCenter: parent.verticalCenter
                            font.pixelSize: daemon ? daemon.fontSize : 24
                            font.bold: true
                            color: overlayWindow.resolvedKeycapTextColor
                            text: mouseIcon.isLeft ? "L" : (mouseIcon.isRight ? "R" : "M")
                        }
                    }

                    // Render standard text for normal typing
                    StyledText {
                        visible: !isCombo && !isMouseClick
                        anchors.verticalCenter: parent.verticalCenter
                        font.pixelSize: daemon ? daemon.fontSize : 24
                        font.bold: true
                        color: overlayWindow.resolvedTextColor
                        text: overlayWindow.getOverlayKeyText(lineText)
                        
                        height: overlayWindow.unifiedHeight
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }

            // Divider between history and active modifiers
            Separator {
                id: modifierDivider
                visible: daemon && daemon.showModifierStatus && (daemon.ctrlActive || daemon.altActive || daemon.shiftActive || daemon.superActive) && daemon.historyList.length > 0
            }

            // Real-time held modifiers status bar
            Row {
                id: modifierStatusRow
                visible: daemon && daemon.showModifierStatus && (daemon.ctrlActive || daemon.altActive || daemon.shiftActive || daemon.superActive)
                spacing: Theme.spacingS
                anchors.horizontalCenter: isCentered ? parent.horizontalCenter : undefined

                // Ctrl Pill
                StyledRect {
                    visible: daemon && daemon.ctrlActive
                    height: overlayWindow.unifiedHeight
                    width: ctrlText.implicitWidth + Theme.spacingM * 2
                    radius: overlayWindow.roundedKeycaps ? height / 2 : 0
                    color: Theme.primaryContainer
                    border.color: Theme.withAlpha(Theme.outline, 0.15)
                    border.width: 1

                    StyledText {
                        id: ctrlText
                        anchors.centerIn: parent
                        font.pixelSize: daemon ? daemon.fontSize - 4 : 20
                        font.bold: true
                        color: Theme.onPrimary
                        text: overlayWindow.getOverlayKeyText("Ctrl")
                    }
                }

                // Alt Pill
                StyledRect {
                    visible: daemon && daemon.altActive
                    height: overlayWindow.unifiedHeight
                    width: altText.implicitWidth + Theme.spacingM * 2
                    radius: overlayWindow.roundedKeycaps ? height / 2 : 0
                    color: Theme.primaryContainer
                    border.color: Theme.withAlpha(Theme.outline, 0.15)
                    border.width: 1

                    StyledText {
                        id: altText
                        anchors.centerIn: parent
                        font.pixelSize: daemon ? daemon.fontSize - 4 : 20
                        font.bold: true
                        color: Theme.onPrimary
                        text: overlayWindow.getOverlayKeyText("Alt")
                    }
                }

                // Shift Pill
                StyledRect {
                    visible: daemon && daemon.shiftActive
                    height: overlayWindow.unifiedHeight
                    width: shiftText.implicitWidth + Theme.spacingM * 2
                    radius: overlayWindow.roundedKeycaps ? height / 2 : 0
                    color: Theme.primaryContainer
                    border.color: Theme.withAlpha(Theme.outline, 0.15)
                    border.width: 1

                    StyledText {
                        id: shiftText
                        anchors.centerIn: parent
                        font.pixelSize: daemon ? daemon.fontSize - 4 : 20
                        font.bold: true
                        color: Theme.onPrimary
                        text: overlayWindow.getOverlayKeyText("Shift")
                    }
                }

                // Super Pill
                StyledRect {
                    visible: daemon && daemon.superActive
                    height: overlayWindow.unifiedHeight
                    width: superText.implicitWidth + Theme.spacingM * 2
                    radius: overlayWindow.roundedKeycaps ? height / 2 : 0
                    color: Theme.primaryContainer
                    border.color: Theme.withAlpha(Theme.outline, 0.15)
                    border.width: 1

                    StyledText {
                        id: superText
                        anchors.centerIn: parent
                        font.pixelSize: daemon ? daemon.fontSize - 4 : 20
                        font.bold: true
                        color: Theme.onPrimary
                        text: overlayWindow.getOverlayKeyText("Super")
                    }
                }
            }
        }
    }
}
