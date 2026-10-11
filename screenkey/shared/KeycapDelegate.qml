import QtQuick
import qs.Common
import qs.Widgets
import "./KeyIcons.js" as KeyIcons
import "./keycapColors.js" as KeycapColors

Item {
    id: keycap

    property string label: ""
    property string skin: "pbt" // "minimal" | "laptop" | "lowprofile" | "pbt"
    property real fontSize: 24
    property bool roundedCorners: true
    property color customTextColor: Theme.primary

    readonly property bool isMinimal: skin === "minimal"
    readonly property bool isLaptop: skin === "laptop"
    readonly property bool isLowProfile: skin === "lowprofile"
    readonly property bool isPbt: skin === "pbt"

    readonly property real fs: fontSize
    readonly property real radiusF: roundedCorners ? 0.5 : 0.0
    readonly property real capRadius: radiusF * fs * 1.25
    readonly property real padInline: fs * (radiusF < 0.75 ? 0.5 : (0.5 + radiusF - 0.75))
    readonly property real padBlock: fs * 0.4
    readonly property real contentBorder: isLowProfile ? 1 : 0
    readonly property real bottomEdge: isPbt ? fs * 0.06 : 0
    readonly property real borderW: 1

    readonly property color faceColor: Theme.surfaceContainerHighest
    readonly property color wallColor: Theme.surfaceContainerHigh
    readonly property color labelColor: customTextColor
    readonly property color ringColor: Theme.withAlpha(Theme.outline, 0.25)
    readonly property bool useGradient: true

    function darken(c, f) { return KeycapColors.shiftLightness(c, -f); }
    function lighten(c, f) { return KeycapColors.shiftLightness(c, f); }

    readonly property var kd: KeyIcons.display(label)
    readonly property bool hasIcon: kd.icon !== undefined
    readonly property bool isModifier: kd.category === "modifier"

    readonly property bool iconOnly: hasIcon && (kd.category === "arrow" || label === "Space")
    readonly property bool iconLayout: hasIcon && !iconOnly

    // Geometry matching keyviz/keystrokes:
    // Box height: 1.2em (minimal) / 2.25em (laptop) / 2.5em (lowprofile) / 2.75em (pbt)
    readonly property real bodyH: isMinimal
        ? fs * 1.2
        : (isLaptop ? fs * 2.25 : (isLowProfile ? fs * 2.5 : fs * 2.75))

    // Face height: 2.25em (laptop/lowprofile), 2.2em (pbt)
    readonly property real faceH: isMinimal
        ? bodyH
        : (isPbt ? fs * 2.2 : fs * 2.25)

    readonly property real faceInset: isPbt ? fs * 0.3 : 0
    readonly property real minW: isMinimal
        ? 0
        : (isPbt ? fs * (isModifier ? 3.0 : 2.75) : fs * (isModifier ? 2.5 : 2.25))

    readonly property real contentW: {
        if (iconOnly) return fs * 0.8;
        if (iconLayout) return Math.max(fs * 0.5, measureSmall.implicitWidth);
        return measurePlain.implicitWidth;
    }

    readonly property real capW: isMinimal
        ? minRow.implicitWidth
        : Math.max(minW, faceInset * 2 + Math.max(isPbt ? fs * 2 : 0, contentW + padInline * 2 + contentBorder * 2))

    width: isMinimal ? minRow.implicitWidth : capW
    height: isMinimal ? Math.max(fs, minRow.implicitHeight) : bodyH

    Text {
        id: measureSmall
        visible: false
        font.pixelSize: fs * 0.5
        text: kd.shortLabel || kd.label
    }

    Text {
        id: measurePlain
        visible: false
        font.pixelSize: fs
        font.bold: true
        text: kd.label
    }

    // ── lowprofile base wall ──
    Rectangle {
        id: lpWall
        visible: keycap.isLowProfile
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: keycap.faceH
        radius: keycap.capRadius
        color: keycap.wallColor
        border.width: keycap.borderW
        border.color: keycap.ringColor
    }

    // ── PBT shell with diagonal gradient ──
    KeycapSurface {
        visible: keycap.isPbt
        anchors.fill: parent
        radius: keycap.capRadius
        baseColor: keycap.wallColor
        endColor: keycap.darken(keycap.wallColor, 0.15)
        gradientEnabled: true
        diagonal: true
        ringWidth: keycap.borderW
        ringColor: keycap.ringColor
    }

    // ── Cap Face (Laptop / Low Profile / PBT) ──
    Item {
        id: capFace
        visible: !keycap.isMinimal
        x: keycap.faceInset
        y: 0
        width: parent.width - keycap.faceInset * 2
        height: keycap.faceH

        KeycapSurface {
            anchors.fill: parent
            radius: keycap.capRadius
            baseColor: keycap.isPbt ? keycap.darken(keycap.faceColor, 0.05)
                : (keycap.isLaptop ? keycap.lighten(keycap.faceColor, 0.08) : keycap.faceColor)
            endColor: keycap.faceColor
            gradientEnabled: keycap.isLaptop || keycap.isPbt
            horizontal: keycap.isPbt
            solidColor: keycap.faceColor
            ringWidth: keycap.isLowProfile ? 0 : keycap.borderW
            ringColor: keycap.ringColor
            innerBorderWidth: keycap.contentBorder
            bottomBorderWidth: keycap.bottomEdge
            bottomBorderColor: keycap.faceColor
            dropShadow: keycap.isLaptop
            shadowSize: keycap.fs * 0.1
            insetHighlight: keycap.isLaptop
            highlightColor: keycap.lighten(keycap.faceColor, 0.2)
            highlightDepth: keycap.fs * 0.12
        }

        Item {
            id: contentBox
            anchors.fill: parent
            anchors.leftMargin: keycap.padInline + keycap.contentBorder
            anchors.rightMargin: keycap.padInline + keycap.contentBorder
            anchors.topMargin: keycap.padBlock + keycap.contentBorder
            anchors.bottomMargin: keycap.padBlock + keycap.contentBorder + keycap.bottomEdge

            // Icon-only (arrow keys, etc.)
            KeyIcon {
                visible: keycap.iconOnly
                name: keycap.kd.icon || ""
                color: keycap.labelColor
                size: keycap.fs * 0.8
                anchors.centerIn: parent
            }

            // Icon + label stacked (modifiers, Esc, Tab, etc.)
            KeyIcon {
                visible: keycap.iconLayout
                name: keycap.kd.icon || ""
                color: keycap.labelColor
                size: keycap.fs * 0.5
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Text {
                visible: keycap.iconLayout
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                font.pixelSize: Math.round(keycap.fs * 0.5)
                font.weight: Font.Medium
                color: keycap.labelColor
                text: keycap.kd.shortLabel || keycap.kd.label
            }

            // Plain text (letters, numbers)
            Text {
                visible: !keycap.iconOnly && !keycap.iconLayout
                anchors.centerIn: parent
                font.pixelSize: keycap.fs
                font.bold: true
                color: keycap.labelColor
                text: keycap.kd.label
            }
        }
    }

    // ── Minimal Mode: Inline icon & label without cap body ──
    Row {
        id: minRow
        visible: keycap.isMinimal
        spacing: keycap.fs * 0.15
        anchors.centerIn: parent

        KeyIcon {
            visible: keycap.hasIcon
            name: keycap.kd.icon || ""
            color: keycap.labelColor
            size: keycap.fs * 0.8
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            visible: !keycap.iconOnly
            anchors.verticalCenter: parent.verticalCenter
            font.pixelSize: keycap.fs
            font.bold: true
            color: keycap.labelColor
            text: keycap.kd.label
        }
    }
}
