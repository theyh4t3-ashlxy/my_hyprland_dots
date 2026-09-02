import QtQuick
import QtQuick.Shapes
import ".."

Shape {
    id: root

    property real radiusX: Theme.scoopRadiusX
    property real radiusY: Theme.scoopRadiusY
    property real tension: Theme.scoopTension ?? 0.55228475
    property string style: Theme.scoopStyle ?? "cubic"
    property color fillColor: "#000"
    property bool flipX: false
    property bool flipY: false

    width: Math.max(1, radiusX)
    height: Math.max(1, radiusY)

    // no subpixel blurring or weird transform scaling
    layer.enabled: false
    preferredRendererType: Shape.GeometryRenderer
    asynchronous: false

    readonly property real w: width
    readonly property real h: height
    readonly property real effTension: style === "chamfer" ? 0.5
                                     : style === "flared"  ? 0.92
                                     : style === "stepped" ? 1.0
                                     : tension
    readonly property real k: 1.0 - effTension

    // mathematically exact closed-loop 4-quadrant bezier coordinates
    readonly property real startPtX: flipX ? w : 0
    readonly property real startPtY: flipY ? h : 0

    readonly property real linePtX: flipX ? 0 : w
    readonly property real linePtY: flipY ? h : 0

    readonly property real endPtX: flipX ? w : 0
    readonly property real endPtY: flipY ? 0 : h

    readonly property real ctrl1X: flipX ? (w * k) : (w * effTension)
    readonly property real ctrl1Y: flipY ? h : 0

    readonly property real ctrl2X: flipX ? w : 0
    readonly property real ctrl2Y: flipY ? (h * k) : (h * effTension)

    ShapePath {
        fillColor: root.fillColor
        strokeColor: "transparent"
        strokeWidth: 0
        joinStyle: ShapePath.MiterJoin
        capStyle: ShapePath.FlatCap

        startX: root.startPtX
        startY: root.startPtY

        PathLine { x: root.linePtX; y: root.linePtY }

        PathCubic {
            x: root.endPtX
            y: root.endPtY
            control1X: root.ctrl1X
            control1Y: root.ctrl1Y
            control2X: root.ctrl2X
            control2Y: root.ctrl2Y
        }

        PathLine { x: root.startPtX; y: root.startPtY }
    }
}
