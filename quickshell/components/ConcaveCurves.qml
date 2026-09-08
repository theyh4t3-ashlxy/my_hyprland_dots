import QtQuick
import QtQuick.Shapes
import ".."

Shape {
    id: root

    property real radius: 16
    property real radiusX: radius
    property real radiusY: radius
    property color color: "#1e1e2d"
    property alias fillColor: root.color

    property bool isTop: true
    property bool mirrored: false
    property bool flipX: mirrored
    property bool flipY: !isTop
    property string cornerStyle: (typeof Settings !== "undefined" ? Settings?.cornerStyle : null) ?? "cubic"

    visible: width > 0 && height > 0
    implicitWidth: Math.max(0, radiusX)
    implicitHeight: Math.max(0, radiusY)
    width: implicitWidth
    height: implicitHeight

    preferredRendererType: Shape.CurveRenderer

    readonly property real w: width
    readonly property real h: height

    readonly property real tension: {
        if (cornerStyle === "squircle") return 0.65;
        if (cornerStyle === "flared") return 0.44;
        return (typeof Settings !== "undefined" ? Settings?.scoopTension : null) ?? 0.55228475;
    }

    Behavior on color {
        ColorAnimation {
            duration: (typeof Theme !== "undefined" ? Theme.animFast : null) ?? 150
        }
    }

    ShapePath {
        id: curvedPath
        fillColor: (root.cornerStyle !== "chamfer" && root.cornerStyle !== "stepped") ? root.color : "transparent"
        strokeColor: "transparent"
        strokeWidth: 0

        startX: root.flipX ? 0 : root.w
        startY: root.flipY ? root.h : 0

        PathLine {
            x: root.flipX ? root.w : 0
            y: root.flipY ? root.h : 0
        }

        PathLine {
            x: root.flipX ? root.w : 0
            y: root.flipY ? 0 : root.h
        }

        PathCubic {
            x: root.flipX ? 0 : root.w
            y: root.flipY ? root.h : 0
            control1X: root.flipX ? root.w : 0
            control1Y: root.flipY ? (root.h * root.tension) : (root.h * (1.0 - root.tension))
            control2X: root.flipX ? (root.w * root.tension) : (root.w * (1.0 - root.tension))
            control2Y: root.flipY ? root.h : 0
        }
    }

    ShapePath {
        id: chamferPath
        fillColor: (root.cornerStyle === "chamfer") ? root.color : "transparent"
        strokeColor: "transparent"
        strokeWidth: 0

        startX: root.flipX ? 0 : root.w
        startY: root.flipY ? root.h : 0

        PathLine {
            x: root.flipX ? root.w : 0
            y: root.flipY ? root.h : 0
        }

        PathLine {
            x: root.flipX ? root.w : 0
            y: root.flipY ? 0 : root.h
        }

        PathLine {
            x: root.flipX ? 0 : root.w
            y: root.flipY ? root.h : 0
        }
    }

    ShapePath {
        id: steppedPath
        fillColor: (root.cornerStyle === "stepped") ? root.color : "transparent"
        strokeColor: "transparent"
        strokeWidth: 0

        startX: root.flipX ? 0 : root.w
        startY: root.flipY ? root.h : 0

        PathLine {
            x: root.flipX ? root.w : 0
            y: root.flipY ? root.h : 0
        }

        PathLine {
            x: root.flipX ? root.w : 0
            y: root.flipY ? 0 : root.h
        }

        PathLine {
            x: root.w * 0.5
            y: root.flipY ? 0 : root.h
        }

        PathLine {
            x: root.w * 0.5
            y: root.h * 0.5
        }

        PathLine {
            x: root.flipX ? 0 : root.w
            y: root.h * 0.5
        }

        PathLine {
            x: root.flipX ? 0 : root.w
            y: root.flipY ? root.h : 0
        }
    }
}