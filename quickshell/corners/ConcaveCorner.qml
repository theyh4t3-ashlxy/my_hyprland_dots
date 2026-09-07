import QtQuick
import ".."

Item {
    id: root

    property real radiusX: Theme.scoopRadiusX ?? 16
    property real radiusY: Theme.scoopRadiusY ?? 16
    property color fillColor: Theme.cornerFill ?? Theme.barBg ?? Theme.surface_container_low ?? "#14140c"
    property bool flipX: false
    property bool flipY: false
    property string cornerStyle: Settings?.cornerStyle ?? "cubic"

    property alias radius: root.radiusX
    property alias color: root.fillColor
    property alias mirrored: root.flipX
    readonly property bool isTop: !flipY

    width: Math.max(1, radiusX)
    height: Math.max(1, radiusY)
    implicitWidth: width
    implicitHeight: height

    readonly property real w: width
    readonly property real h: height
    readonly property real tension: {
        if (cornerStyle === "squircle") return 0.58;
        if (cornerStyle === "flared") return 0.38;
        return Settings?.scoopTension ?? 0.55228475;
    }

    Behavior on fillColor { ColorAnimation { duration: Theme.animFast } }

    Canvas {
        id: canvas
        anchors.fill: parent
        antialiasing: true
        smooth: true
        renderTarget: Canvas.Image
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
                ctx.lineTo(midX, p2y);
                ctx.lineTo(midX, midY);
                ctx.lineTo(sx, midY);
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