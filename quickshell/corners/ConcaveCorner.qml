// ConcaveCorner.qml (Canvas version with initial paint & hidpi fix)
import QtQuick
import ".."

Item {
    id: root

    property real radius: 16
    property real radiusX: Theme?.scoopRadiusX ?? radius
    property real radiusY: Theme?.scoopRadiusY ?? radius
    property color fillColor: Theme?.cornerFill ?? Theme?.barBg ?? "#14140c"
    property bool flipX: false
    property bool flipY: false
    property string cornerStyle: (typeof Settings !== "undefined" ? Settings?.cornerStyle : null) ?? "cubic"

    property alias color: root.fillColor
    property alias mirrored: root.flipX
    readonly property bool isTop: !flipY

    implicitWidth: Math.max(1, radiusX)
    implicitHeight: Math.max(1, radiusY)
    width: implicitWidth
    height: implicitHeight

    readonly property real w: width
    readonly property real h: height
    readonly property real tension: {
        if (cornerStyle === "squircle") return 0.68;
        if (cornerStyle === "flared") return 0.42;
        return (typeof Settings !== "undefined" ? Settings?.scoopTension : null) ?? 0.55228475;
    }

    Behavior on fillColor { ColorAnimation { duration: (typeof Theme !== "undefined" ? Theme?.animFast : null) ?? 150 } }

    Canvas {
        id: canvas
        anchors.fill: parent
        antialiasing: true
        smooth: true
        renderTarget: Canvas.FramebufferObject
        renderStrategy: Canvas.Immediate

        onPaint: {
            var ctx = getContext("2d");
            ctx.reset();
            ctx.clearRect(0, 0, width, height);
            ctx.fillStyle = root.fillColor;
            ctx.beginPath();

            var fx = root.flipX;
            var fy = root.flipY;
            var w = root.w;
            var h = root.h;
            var t = root.tension;

            var sx = fx ? 0 : w;
            var sy = fy ? h : 0;
            ctx.moveTo(sx, sy);

            var p1x = fx ? w : 0;
            var p1y = fy ? h : 0;
            ctx.lineTo(p1x, p1y);

            var p2x = fx ? w : 0;
            var p2y = fy ? 0 : h;
            ctx.lineTo(p2x, p2y);

            if (root.cornerStyle === "chamfer") {
                ctx.lineTo(sx, sy);
            } else if (root.cornerStyle === "stepped") {
                var midX = w * 0.5;
                var midY = h * 0.5;
                ctx.lineTo(p2x, midY);
                ctx.lineTo(midX, midY);
                ctx.lineTo(midX, sy);
                ctx.lineTo(sx, sy);
            } else {
                var c1x = fx ? w : 0;
                var c1y = fy ? (h * t) : (h * (1.0 - t));
                var c2x = fx ? (w * t) : (w * (1.0 - t));
                var c2y = fy ? h : 0;
                ctx.bezierCurveTo(c1x, c1y, c2x, c2y, sx, sy);
            }

            ctx.closePath();
            ctx.fill();
        }

        // wake up canvas on initial load so it doesnt sit there transparent
        Component.onCompleted: requestPaint()
        onAvailableChanged: if (available) requestPaint()

        Connections {
            target: root
            function onFillColorChanged() { canvas.requestPaint(); }
            function onRadiusXChanged() { canvas.requestPaint(); }
            function onRadiusYChanged() { canvas.requestPaint(); }
            function onWidthChanged() { canvas.requestPaint(); }
            function onHeightChanged() { canvas.requestPaint(); }
            function onFlipXChanged() { canvas.requestPaint(); }
            function onFlipYChanged() { canvas.requestPaint(); }
            function onCornerStyleChanged() { canvas.requestPaint(); }
            function onTensionChanged() { canvas.requestPaint(); }
        }
    }
}