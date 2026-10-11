import QtQuick
import QtQuick.Shapes
import "KeyIcons.js" as KeyIcons

Item {
    id: root
    property string name: ""
    property color color: "#000000"
    property real size: 24
    readonly property var paths: KeyIcons.iconPaths(name)
    width: size
    height: size

    Shape {
        width: 24
        height: 24
        scale: root.size / 24
        transformOrigin: Item.TopLeft
        antialiasing: true
        preferredRendererType: Shape.CurveRenderer
        fillMode: Shape.PreserveAspectFit
        ShapePath {
            strokeColor: root.color
            strokeWidth: 2
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            PathSvg { path: "M0 0 " + root.paths.join(" M0 0 ") }
        }
    }
}
