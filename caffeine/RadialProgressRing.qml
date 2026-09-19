import QtQuick
import QtQuick.Shapes
import qs.Common

Item {
    id: radialRingRoot

    property bool active: false
    property double angle: 360
    property color color: Theme.primary
    property real strokeWidth: 2
    property real radius: 10
    property real centerX: width / 2
    property real centerY: height / 2
    property real backgroundOpacityActive: 0.2
    property real backgroundOpacityInactive: 0.05
    property bool ringVisible: true

    Shape {
        anchors.fill: parent
        antialiasing: true
        preferredRendererType: Shape.CurveRenderer
        visible: radialRingRoot.ringVisible
        opacity: active ? backgroundOpacityActive : backgroundOpacityInactive
        ShapePath {
            strokeColor: color
            strokeWidth: strokeWidth
            fillColor: "transparent"
            PathAngleArc {
                centerX: radialRingRoot.centerX
                centerY: radialRingRoot.centerY
                radiusX: radius
                radiusY: radius
                startAngle: 0
                sweepAngle: 360
            }
        }
    }

    Shape {
        anchors.fill: parent
        antialiasing: true
        preferredRendererType: Shape.CurveRenderer
        visible: radialRingRoot.ringVisible && active && angle > 0
        ShapePath {
            strokeColor: color
            strokeWidth: radialRingRoot.strokeWidth + 0.5
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            PathAngleArc {
                centerX: radialRingRoot.centerX
                centerY: radialRingRoot.centerY
                radiusX: radius
                radiusY: radius
                startAngle: -90
                sweepAngle: Math.max(0, Math.min(360, angle))
            }
        }
    }
}
