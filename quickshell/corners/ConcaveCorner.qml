import QtQuick
import QtQuick.Shapes
import ".."

Shape {
    id: root

    property real radiusX: Theme.scoopRadiusX ?? 16
    property real radiusY: Theme.scoopRadiusY ?? 16
    property real tension: Theme.scoopTension ?? 0.55228475
    property string style: Theme.scoopStyle ?? "cubic"
    property color fillColor: Theme.surface ?? "#000"
    property bool flipX: false
    property bool flipY: false

    width: Math.max(1, radiusX)
    height: Math.max(1, radiusY)

    // so it doesn't look like a jagged ps1 mesh
    asynchronous: false
    preferredRendererType: Shape.CurveRenderer
    antialiasing: true

    readonly property real w: width
    readonly property real h: height

    // actual geometric presets instead of made-up numbers
    readonly property real effTension: style === "chamfer"  ? 0.0
                                     : style === "squircle" ? 0.75
                                     : style === "flared"   ? 0.85
                                     : style === "stepped"  ? 1.0
                                     : tension
    readonly property real k: 1.0 - effTension

    // outer anchor corner
    readonly property real startPtX: flipX ? w : 0
    readonly property real startPtY: flipY ? h : 0

    // first straight point
    readonly property real linePtX: flipX ? 0 : w
    readonly property real linePtY: flipY ? h : 0

    // second straight point
    readonly property real endPtX: flipX ? w : 0
    readonly property real endPtY: flipY ? 0 : h

    // fixing the control points so it doesn't look like a squished egg
    readonly property real ctrl1X: flipX ? (w * effTension) : (w * k)
    readonly property real ctrl1Y: linePtY

    readonly property real ctrl2X: endPtX
    readonly property real ctrl2Y: flipY ? (h * effTension) : (h * k)

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

        // closing the loop before memory leaks into the void
        PathLine { x: root.startPtX; y: root.startPtY }
    }
}