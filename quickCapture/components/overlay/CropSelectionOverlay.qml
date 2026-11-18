import QtQuick
import qs.Common
import qs.Widgets

Item {
    id: root

    required property var window
    required property Item boardContainer

    readonly property real fitScale: window ? window.effectiveFitScale : 1
    readonly property real visualW: window ? (window.canvasWidth * fitScale) : 0
    readonly property real visualH: window ? (window.canvasHeight * fitScale) : 0

    readonly property bool isCropMode: window ? (window.currentTool === "crop") : false
    readonly property bool isOcrMode: window ? (window.currentTool === "ocr" || window.currentTool === "qr") : false
    readonly property rect activeRect: isOcrMode ? (window ? window.ocrRect : Qt.rect(0, 0, 0, 0)) : (window ? window.cropRect : Qt.rect(0, 0, 0, 0))
    readonly property bool hasRect: activeRect.width > 0 && activeRect.height > 0

    readonly property real rx: activeRect.x * fitScale
    readonly property real ry: activeRect.y * fitScale
    readonly property real rw: activeRect.width * fitScale
    readonly property real rh: activeRect.height * fitScale
    readonly property real cx: rx + rw / 2
    readonly property real cy: ry + rh / 2

    readonly property color overlayColor: isOcrMode ? Qt.rgba(76 / 255, 175 / 255, 80 / 255, 0.15) : Qt.rgba(0, 0, 0, 0.4)
    readonly property real armLen: Math.max(12, Math.min(20, Math.min(rw, rh) * 0.25))
    readonly property real strokeW: 2.5

    x: boardContainer ? (boardContainer.width / 2 + window.userPanX - visualW / 2) : 0
    y: boardContainer ? (boardContainer.height / 2 + window.userPanY - visualH / 2) : 0
    width: visualW
    height: visualH
    z: 5
    enabled: false
    visible: isCropMode || isOcrMode

    // Full-canvas dim before a selection is drawn
    Rectangle {
        anchors.fill: parent
        color: root.overlayColor
        visible: !root.hasRect
    }

    // 4-sided dim around active selection
    Rectangle {
        x: 0
        y: 0
        width: Math.max(0, root.rx)
        height: root.height
        color: root.overlayColor
        visible: root.hasRect
    }

    Rectangle {
        x: root.rx + root.rw
        y: 0
        width: Math.max(0, root.width - (root.rx + root.rw))
        height: root.height
        color: root.overlayColor
        visible: root.hasRect
    }

    Rectangle {
        x: root.rx
        y: 0
        width: Math.max(0, root.rw)
        height: Math.max(0, root.ry)
        color: root.overlayColor
        visible: root.hasRect
    }

    Rectangle {
        x: root.rx
        y: root.ry + root.rh
        width: Math.max(0, root.rw)
        height: Math.max(0, root.height - (root.ry + root.rh))
        color: root.overlayColor
        visible: root.hasRect
    }

    // Solid crop border
    Rectangle {
        x: root.rx
        y: root.ry
        width: root.rw
        height: root.rh
        color: "transparent"
        border.color: Theme.primary
        border.width: 1.5
        visible: root.hasRect && root.isCropMode
    }

    // Dashed OCR/QR border rendered at 1:1 screen pixels
    Canvas {
        id: ocrBorderCanvas
        x: root.rx - 2
        y: root.ry - 2
        width: root.rw + 4
        height: root.rh + 4
        visible: root.hasRect && root.isOcrMode

        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onVisibleChanged: {
            if (visible)
                requestPaint();
        }

        onPaint: {
            var ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            if (width <= 4 || height <= 4)
                return;
            ctx.strokeStyle = "#4CAF50";
            ctx.lineWidth = 2;
            ctx.setLineDash([6, 4]);
            ctx.strokeRect(2, 2, width - 4, height - 4);
        }
    }

    // 4 Corner L-bracket handles (white outline + primary fill)
    Repeater {
        model: root.hasRect && root.isCropMode ? [
            { x: root.rx, y: root.ry, sx: 1, sy: 1 },
            { x: root.rx + root.rw, y: root.ry, sx: -1, sy: 1 },
            { x: root.rx, y: root.ry + root.rh, sx: 1, sy: -1 },
            { x: root.rx + root.rw, y: root.ry + root.rh, sx: -1, sy: -1 }
        ] : []

        delegate: Item {
            required property var modelData
            readonly property real cxPos: modelData.x
            readonly property real cyPos: modelData.y
            readonly property int sx: modelData.sx
            readonly property int sy: modelData.sy
            readonly property real sw: root.strokeW
            readonly property real arm: root.armLen

            Rectangle {
                x: sx > 0 ? cxPos - sw / 2 - 1 : cxPos - arm + sw / 2 - 1
                y: cyPos - sw / 2 - 1
                width: arm + 2
                height: sw + 2
                color: "#ffffff"
            }

            Rectangle {
                x: cxPos - sw / 2 - 1
                y: sy > 0 ? cyPos - sw / 2 - 1 : cyPos - arm + sw / 2 - 1
                width: sw + 2
                height: arm + 2
                color: "#ffffff"
            }

            Rectangle {
                x: sx > 0 ? cxPos - sw / 2 : cxPos - arm + sw / 2
                y: cyPos - sw / 2
                width: arm
                height: sw
                color: Theme.primary
            }

            Rectangle {
                x: cxPos - sw / 2
                y: sy > 0 ? cyPos - sw / 2 : cyPos - arm + sw / 2
                width: sw
                height: arm
                color: Theme.primary
            }
        }
    }

    // 4 Edge pill handles (N, S, E, W)
    Repeater {
        model: root.hasRect && root.isCropMode ? [
            { px: root.cx - 12, py: root.ry - 3, pw: 24, ph: 6 },
            { px: root.cx - 12, py: root.ry + root.rh - 3, pw: 24, ph: 6 },
            { px: root.rx - 3, py: root.cy - 12, pw: 6, ph: 24 },
            { px: root.rx + root.rw - 3, py: root.cy - 12, pw: 6, ph: 24 }
        ] : []

        delegate: Rectangle {
            required property var modelData
            x: modelData.px
            y: modelData.py
            width: modelData.pw
            height: modelData.ph
            radius: Math.min(width, height) / 2
            color: "#ffffff"
            border.color: Qt.rgba(0, 0, 0, 0.45)
            border.width: 1
        }
    }

    // Live dimension badge in screen-space
    Rectangle {
        id: dimensionBadge
        visible: root.hasRect && root.isCropMode
        width: badgeLabel.implicitWidth + 24
        height: 30
        radius: height / 2
        color: Qt.rgba(0, 0, 0, 0.75)
        border.color: Qt.rgba(1, 1, 1, 0.25)
        border.width: 1

        x: Math.max(8, Math.min(root.width - width - 8, root.cx - width / 2))
        y: (root.ry - height - 8 >= 8) ? (root.ry - height - 8) : (root.ry + root.rh + 8)

        StyledText {
            id: badgeLabel
            anchors.centerIn: parent
            text: Math.round(root.activeRect.width) + " × " + Math.round(root.activeRect.height) + " px"
            color: "#ffffff"
            font.family: Theme.monoFontFamily || "monospace"
            font.pixelSize: 15
            font.weight: Font.Bold
        }
    }
}
