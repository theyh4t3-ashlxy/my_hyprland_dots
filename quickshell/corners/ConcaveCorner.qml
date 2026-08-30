import QtQuick
import QtQuick.Shapes
import ".."

Shape {
    id: root

    property real radiusX: Theme.scoopRadiusX
    property real radiusY: Theme.scoopRadiusY
    property real tension: Theme.scoopTension ?? 0.55228475
    property string style: Theme.scoopStyle
    property color fillColor: "#000"
    property bool flipX: false
    property bool flipY: false

    width: radiusX
    height: radiusY

    // please stop blurring my edges
    layer.enabled: false
    preferredRendererType: Shape.CurveRenderer

    // if this flips weirdly again im deleting hyprland
    transform: Scale {
        xScale: root.flipX ? -1 : 1
        yScale: root.flipY ? -1 : 1
        origin.x: Math.floor(root.width / 2)
        origin.y: Math.floor(root.height / 2)
    }

    readonly property real c1X: style === "chamfer" ? (root.radiusX * 0.5)
                              : style === "flared"  ? (root.radiusX * 0.08)
                              : style === "stepped" ? 0
                              : (root.radiusX * (1.0 - root.tension))
    readonly property real c1Y: style === "chamfer" ? (root.radiusY * 0.5) : 0

    readonly property real c2X: style === "chamfer" ? (root.radiusX * 0.5) : 0
    readonly property real c2Y: style === "chamfer" ? (root.radiusY * 0.5)
                              : style === "flared"  ? (root.radiusY * 0.08)
                              : style === "stepped" ? 0
                              : (root.radiusY * (1.0 - root.tension))

    ShapePath {
        fillColor: root.fillColor
        strokeColor: "transparent"
        strokeWidth: 0

        // back to the origin before it blows up
        startX: 0
        startY: 0

        PathLine { x: root.radiusX; y: 0 }

        // actual concave scoop math instead of convex garbage
        PathCubic {
            x: 0
            y: root.radiusY
            control1X: root.c1X
            control1Y: root.c1Y
            control2X: root.c2X
            control2Y: root.c2Y
        }

        PathLine { x: 0; y: 0 }
    }
}