import QtQuick
import qs.Common

Item {
    id: root

    property string skin: "classic" // "classic" | "pixel"
    property string glyphText: "bc"
    property real targetPixelSize: 24
    property color catColor: Theme.surfaceText
    property real catOpacity: 1.0
    property string spriteSource: ""
    property real yOffset: 0

    // Font layout metrics
    readonly property real letterSpacingValue: -Math.max(1, Math.round(root.targetPixelSize * 0.05))
    readonly property real leftInset: (166 / 1024) * root.targetPixelSize
    readonly property real visualWidth: Math.round(root.targetPixelSize * (1707 / 1024) + root.letterSpacingValue)

    width: implicitWidth
    height: implicitHeight

    implicitWidth: root.skin === "pixel"
        ? Math.round(root.targetPixelSize * 1.25)
        : Math.max(1, root.visualWidth)
    implicitHeight: Math.round(root.targetPixelSize)

    // Vector Cat View
    Item {
        id: vectorViewport
        visible: root.skin !== "pixel"
        anchors.fill: parent
        clip: false

        Text {
            id: catText
            font.family: bongoFont.name
            font.pixelSize: root.targetPixelSize
            font.letterSpacing: root.letterSpacingValue
            color: root.catColor
            opacity: root.catOpacity
            text: root.glyphText

            // Anchor by fixed baseline offsets (both X and Y) so the cat body stays rock-solid
            x: -root.leftInset
            y: Math.round((root.height - (960 / 1024) * root.targetPixelSize) / 2) + root.yOffset
        }
    }

    // Pixel Sprite Cat View
    Image {
        id: pixelSprite
        visible: root.skin === "pixel"
        anchors.centerIn: parent
        width: root.width
        height: root.height
        fillMode: Image.PreserveAspectFit
        smooth: false
        mipmap: false
        opacity: root.catOpacity
        source: root.spriteSource
        transform: Translate { y: root.yOffset }
    }
}
