import QtQuick
import ".."

Item {
    id: root

    property real value: 0.0
    property real from: 0.0
    property real to: 1.0

    property bool playing: false
    property bool wavy: true
    property bool interactive: true

    property color primaryColor: Theme.primary
    property color trackColor: Theme.surface_container_highest
    property real lineWidth: 5
    property real waveAmplitude: 4.5
    property real waveFrequency: 5.5
    property real audioPeak: 0.0

    signal seekRequested(real position)
    signal moved(real position)

    implicitWidth: 200
    implicitHeight: Math.max(24, Math.round(lineWidth + (waveAmplitude * 2) + 10))

    readonly property real progress: {
        if (to <= from) return 0.0;
        return Math.max(0.0, Math.min(1.0, (value - from) / (to - from)));
    }

    // Material 3 Expressive spring relaxation: when paused, sine wave straightens out to flat line
    property real currentAmplitude: (playing && wavy) ? (waveAmplitude * (1.0 + (audioPeak * 0.35))) : 0.0
    Behavior on currentAmplitude {
        NumberAnimation {
            duration: Theme.expressiveDefault
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Theme.motionExpressiveDefault
        }
    }

    property real phase: 0.0
    NumberAnimation {
        id: waveAnim
        target: root
        property: "phase"
        from: 0.0
        to: Math.PI * 2
        duration: 2200
        loops: Animation.Infinite
        running: root.playing && root.wavy && root.visible && root.currentAmplitude > 0.05
    }

    onPhaseChanged: canvas.requestPaint()
    onCurrentAmplitudeChanged: canvas.requestPaint()
    onProgressChanged: canvas.requestPaint()
    onWidthChanged: canvas.requestPaint()
    onPrimaryColorChanged: canvas.requestPaint()
    onTrackColorChanged: canvas.requestPaint()

    readonly property real playedX: {
        let startX = lineWidth / 2;
        let endX = width - (lineWidth / 2);
        return startX + (Math.max(0, endX - startX) * progress);
    }

    readonly property real playedY: {
        let centerY = height / 2;
        let startX = lineWidth / 2;
        let endX = width - (lineWidth / 2);
        let effectiveTrackWidth = Math.max(1, endX - startX);
        let normX = (playedX - startX) / effectiveTrackWidth;
        if (currentAmplitude > 0.1) {
            return centerY + currentAmplitude * Math.sin((waveFrequency * 2 * Math.PI * normX) + phase);
        }
        return centerY;
    }

    Canvas {
        id: canvas
        anchors.fill: parent
        antialiasing: true

        onPaint: {
            let ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);

            if (root.width <= 0 || root.height <= 0) return;

            let centerY = Math.round(height / 2);
            let startX = root.lineWidth / 2;
            let endX = root.width - (root.lineWidth / 2);
            let effectiveTrackWidth = Math.max(1, endX - startX);
            let curPlayedX = startX + (effectiveTrackWidth * root.progress);

            // 1. Draw played section (Wavy or straight depending on currentAmplitude)
            ctx.strokeStyle = root.primaryColor;
            ctx.lineWidth = root.lineWidth;
            ctx.lineCap = "round";
            ctx.lineJoin = "round";

            if (root.currentAmplitude > 0.1 && curPlayedX > startX) {
                ctx.beginPath();
                let step = 2;
                for (let x = startX; x <= curPlayedX; x += step) {
                    let normX = (x - startX) / effectiveTrackWidth;
                    let waveY = centerY + root.currentAmplitude * Math.sin((root.waveFrequency * 2 * Math.PI * normX) + root.phase);
                    if (x === startX) {
                        ctx.moveTo(x, waveY);
                    } else {
                        ctx.lineTo(x, waveY);
                    }
                }
                let finalNorm = (curPlayedX - startX) / effectiveTrackWidth;
                let finalY = centerY + root.currentAmplitude * Math.sin((root.waveFrequency * 2 * Math.PI * finalNorm) + root.phase);
                ctx.lineTo(curPlayedX, finalY);
                ctx.stroke();
            } else if (curPlayedX > startX) {
                // Straight line when amplitude is ~0
                ctx.beginPath();
                ctx.moveTo(startX, centerY);
                ctx.lineTo(curPlayedX, centerY);
                ctx.stroke();
            }

            // 2. Draw unplayed remainder section (flat track line)
            let gap = root.interactive ? 6 : 4;
            let unplayedStart = Math.min(endX, curPlayedX + gap);
            if (unplayedStart < endX) {
                ctx.strokeStyle = root.trackColor;
                ctx.lineWidth = Math.max(2, root.lineWidth - 2);
                ctx.lineCap = "round";
                ctx.beginPath();
                ctx.moveTo(unplayedStart, centerY);
                ctx.lineTo(endX, centerY);
                ctx.stroke();
            }
        }
    }

    // Material 3 Scrubber Thumb riding the wave
    Item {
        id: thumb
        x: Math.round(root.playedX - width / 2)
        y: Math.round(root.playedY - height / 2)
        width: 24
        height: 24
        z: 2
        visible: root.interactive && root.to > root.from

        Rectangle {
            id: thumbGlow
            anchors.centerIn: parent
            width: mouseArea.pressed ? 22 : (mouseArea.containsMouse ? 18 : 0)
            height: width
            radius: Theme.radiusPill
            color: Theme.alpha(root.primaryColor, 0.22)
            visible: width > 0

            Behavior on width {
                NumberAnimation {
                    duration: Theme.animFast
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Theme.motionExpressiveDefault
                }
            }
        }

        Rectangle {
            id: thumbDot
            anchors.centerIn: parent
            width: mouseArea.pressed ? 14 : (mouseArea.containsMouse ? 12 : 9)
            height: width
            radius: Theme.radiusPill
            color: root.primaryColor

            Behavior on width {
                NumberAnimation {
                    duration: Theme.animFast
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Theme.motionExpressiveDefault
                }
            }

            Rectangle {
                anchors.centerIn: parent
                width: parent.width * 0.4
                height: width
                radius: Theme.radiusPill
                color: Theme.surface
                visible: mouseArea.containsMouse || mouseArea.pressed
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: root.interactive
        enabled: root.interactive
        cursorShape: Qt.PointingHandCursor

        function updateSeek(mouse) {
            let startX = root.lineWidth / 2;
            let endX = root.width - (root.lineWidth / 2);
            let effectiveTrackWidth = Math.max(1, endX - startX);
            let frac = Math.max(0.0, Math.min(1.0, (mouse.x - startX) / effectiveTrackWidth));
            let targetVal = root.from + frac * (root.to - root.from);
            root.seekRequested(targetVal);
            root.moved(targetVal);
        }

        onClicked: (mouse) => updateSeek(mouse)
        onPositionChanged: (mouse) => {
            if (pressed) updateSeek(mouse);
        }
    }
}
