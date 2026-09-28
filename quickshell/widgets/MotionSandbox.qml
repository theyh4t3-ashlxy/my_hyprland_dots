import QtQuick
import QtQuick.Layouts
import ".."
import "../corners"
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root

    required property var modelData
    screen: modelData

    // ── state ──────────────────────────────────────────────────────────
    property bool springMode: false
    property string activeSandboxMode: "toy"
    property string gravityMode: "normal"
    property int bounceScore: 0
    property int bestScore: 0
    onBounceScoreChanged: if (bounceScore > bestScore) bestScore = bounceScore

    // ── docking ────────────────────────────────────────────────────────
    // Follows the bar by default. manualDockPosition is kept as a debug override;
    // when it differs from the bar's edge we no longer add the bar offset.
    property string manualDockPosition: ""
    // Where along the bar the popup sits: "center" | "start" | "end"
    property string barAlign: "center"
    property int crossMargin: 12

    function normalizeDock(p) {
        switch (p) {
        case "up":
        case "top":
            return "top";
        case "down":
        case "bottom":
            return "bottom";
        case "left":
            return "left";
        case "right":
            return "right";
        default:
            return "top";
        }
    }

    readonly property string barDock: normalizeDock(Settings?.barPosition ?? "top")
    readonly property string resolvedDock: manualDockPosition !== "" ? normalizeDock(manualDockPosition) : barDock
    readonly property bool followsBar: resolvedDock === barDock

    readonly property bool isTop: resolvedDock === "top"
    readonly property bool isBottom: resolvedDock === "bottom"
    readonly property bool isLeft: resolvedDock === "left"
    readonly property bool isRight: resolvedDock === "right"
    readonly property bool isVertical: isLeft || isRight

    // unit vector pointing from the popup toward the bar
    readonly property int barDx: isLeft ? -1 : (isRight ? 1 : 0)
    readonly property int barDy: isTop ? -1 : (isBottom ? 1 : 0)

    readonly property int scoopRadius: Math.round(Settings?.scoopRadius ?? Settings?.screenCornerRadius ?? 16)
    readonly property int barOffset: (Theme?.barHeight ?? 40) + ((Settings?.barFloating ?? false) ? (Settings?.barMargin ?? 8) : 0)
    readonly property int edgeOffset: followsBar ? barOffset : 0

    readonly property bool alignStart: barAlign === "start"
    readonly property bool alignEnd: barAlign === "end"

    anchors {
        top: root.isTop || (root.isVertical && root.alignStart)
        bottom: root.isBottom || (root.isVertical && root.alignEnd)
        left: root.isLeft || (!root.isVertical && root.alignStart)
        right: root.isRight || (!root.isVertical && root.alignEnd)
    }

    margins {
        top: root.isTop ? root.edgeOffset : ((root.isVertical && root.alignStart) ? root.crossMargin : 0)
        bottom: root.isBottom ? root.edgeOffset : ((root.isVertical && root.alignEnd) ? root.crossMargin : 0)
        left: root.isLeft ? root.edgeOffset : ((!root.isVertical && root.alignStart) ? root.crossMargin : 0)
        right: root.isRight ? root.edgeOffset : ((!root.isVertical && root.alignEnd) ? root.crossMargin : 0)
    }

    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell:motionsandbox"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    // ── open / close animation (slides out of the bar) ─────────────────
    readonly property bool isOpen: Settings.showMotionSandbox
    property real reveal: isOpen ? 1 : 0
    Behavior on reveal {
        NumberAnimation {
            duration: Theme.animNormal
            easing.type: Easing.OutCubic
        }
    }

    visible: isOpen || reveal > 0.001
    implicitWidth: root.isVertical ? 380 : 620
    implicitHeight: root.isVertical ? 520 : 320

    onIsOpenChanged: if (isOpen) toyBall.wake()
    onGravityModeChanged: toyBall.wake()
    onResolvedDockChanged: layoutSettle.restart()

    // Sizes only settle after the compositor answers the resize, so anything that
    // depends on canvas size is (re)placed after a short debounce instead of instantly.
    Timer {
        id: layoutSettle
        interval: 150
        onTriggered: root.resetPlayground()
    }

    function resetPlayground() {
        toyBall.resetBall();
        dragCard1.snapHome();
        dragCard2.snapHome();
        dragCard3.snapHome();
    }

    // ── reusable pieces ────────────────────────────────────────────────
    component Chip: Rectangle {
        id: chip
        property string label: ""
        property bool active: false
        property color activeColor: Theme.primary
        property color activeTextColor: Theme.on_primary
        signal clicked

        implicitWidth: chipText.implicitWidth + 16
        implicitHeight: 24
        radius: Theme.radiusPill
        color: active ? activeColor : Theme.surface_container_high
        border.color: Theme.widgetBorder
        border.width: 1

        Behavior on color {
            ColorAnimation {
                duration: Theme.animNormal
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: chip.radius
            color: Theme.on_surface
            opacity: chipMouse.pressed ? 0.14 : (chipMouse.containsMouse ? 0.07 : 0)
            Behavior on opacity {
                NumberAnimation {
                    duration: Theme.animNormal
                }
            }
        }

        Text {
            id: chipText
            anchors.centerIn: parent
            text: chip.label
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeXs
            font.weight: Font.Bold
            color: chip.active ? chip.activeTextColor : Theme.on_surface
        }

        MouseArea {
            id: chipMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: chip.clicked()
        }
    }

    component ChipGroup: Row {
        id: group
        property var options: []
        property string current: ""
        property color activeColor: Theme.primary
        property color activeTextColor: Theme.on_primary
        signal picked(string key)

        spacing: 4

        Repeater {
            model: group.options
            delegate: Chip {
                required property var modelData
                label: modelData.label
                active: group.current === modelData.id
                activeColor: group.activeColor
                activeTextColor: group.activeTextColor
                onClicked: group.picked(modelData.id)
            }
        }
    }

    component Bumper: Rectangle {
        id: bmp
        property int points: 50
        property real flash: 0
        property alias icon: bmpIcon.text

        width: 52
        height: 52
        radius: 26
        // flash is blended in instead of animating `color` directly, so the
        // binding survives and the bumper keeps following theme changes
        color: Qt.tint(Theme.surface_container_high, Qt.alpha(Theme.primary, flash))
        border.color: Theme.widgetBorder
        border.width: 2

        function pulse() {
            pulseAnim.restart();
        }

        SequentialAnimation {
            id: pulseAnim
            ParallelAnimation {
                NumberAnimation { target: bmp; property: "flash"; to: 1; duration: 60 }
                NumberAnimation { target: bmp; property: "scale"; to: 1.22; duration: 60; easing.type: Easing.OutBack }
            }
            ParallelAnimation {
                NumberAnimation { target: bmp; property: "flash"; to: 0; duration: 240 }
                NumberAnimation { target: bmp; property: "scale"; to: 1.0; duration: 240; easing.type: Easing.OutQuad }
            }
        }

        Column {
            anchors.centerIn: parent
            spacing: 1
            Text {
                id: bmpIcon
                anchors.horizontalCenter: parent.horizontalCenter
                font.family: Theme.fontIcon
                font.pixelSize: 14
                color: Theme.primary
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "+" + bmp.points
                font.family: Theme.fontFamily
                font.pixelSize: 8
                font.weight: Font.Bold
                color: Theme.on_surface_variant
            }
        }
    }

    component PhysicsCard: Rectangle {
        id: pcRoot
        property int slot: 0
        readonly property int homeX: root.isVertical ? 10 : 10 + slot * 135
        readonly property int homeY: root.isVertical ? 10 + slot * 96 : 10
        property alias icon: pcIcon.text
        property alias title: pcTitle.text
        property color accentColor: Theme.primary

        x: homeX
        y: homeY
        width: 120
        height: 88
        radius: Theme.radiusMd
        color: Theme.surface_container_highest
        border.color: cardDrag.active ? accentColor : Theme.widgetBorder
        border.width: 1
        z: cardDrag.active ? 20 : 1

        function snapHome() {
            if (cardDrag.active)
                return;
            animX.to = Math.max(0, Math.min(canvasArea.width - width, homeX));
            animY.to = Math.max(0, Math.min(canvasArea.height - height, homeY));
            animX.easing.type = root.springMode ? Easing.OutBack : Easing.OutCubic;
            animY.easing.type = root.springMode ? Easing.OutBack : Easing.OutCubic;
            animX.duration = Theme.animSlow;
            animY.duration = Theme.animSlow;
            momentumAnim.restart();
        }

        function animateTo(targetX, targetY) {
            if (cardDrag.active)
                return;
            animX.to = Math.max(0, Math.min(canvasArea.width - width, targetX));
            animY.to = Math.max(0, Math.min(canvasArea.height - height, targetY));
            animX.easing.type = Easing.OutCubic;
            animY.easing.type = Easing.OutCubic;
            animX.duration = Theme.animNormal;
            animY.duration = Theme.animNormal;
            momentumAnim.restart();
        }

        ParallelAnimation {
            id: momentumAnim
            NumberAnimation { id: animX; target: pcRoot; property: "x" }
            NumberAnimation { id: animY; target: pcRoot; property: "y" }
        }

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 3

            Text {
                id: pcIcon
                font.family: Theme.fontIcon
                font.pixelSize: 18
                color: pcRoot.accentColor
                Layout.alignment: Qt.AlignHCenter
            }
            Text {
                id: pcTitle
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeXs
                font.weight: Font.Bold
                color: Theme.on_surface
                Layout.alignment: Qt.AlignHCenter
            }
            Text {
                text: "(" + Math.round(pcRoot.x) + ", " + Math.round(pcRoot.y) + ")"
                font.family: Theme.fontMono
                font.pixelSize: 9
                color: Theme.on_surface_variant
                Layout.alignment: Qt.AlignHCenter
            }
        }

        DragHandler {
            id: cardDrag
            target: pcRoot
            xAxis.minimum: 0
            xAxis.maximum: canvasArea.width - pcRoot.width
            yAxis.minimum: 0
            yAxis.maximum: canvasArea.height - pcRoot.height
            cursorShape: active ? Qt.ClosedHandCursor : Qt.OpenHandCursor

            onActiveChanged: {
                if (active) {
                    momentumAnim.stop();
                } else if (root.springMode) {
                    pcRoot.snapHome();
                } else {
                    pcRoot.animateTo(pcRoot.x + centroid.velocity.x * 0.22, pcRoot.y + centroid.velocity.y * 0.22);
                }
            }
        }
    }

    // ── frame: concave scoops + body ───────────────────────────────────
    Item {
        id: frame
        anchors.fill: parent
        focus: true
        opacity: root.reveal
        Keys.onEscapePressed: Settings.showMotionSandbox = false

        transform: Translate {
            x: root.barDx * frame.width * 0.3 * (1 - root.reveal)
            y: root.barDy * frame.height * 0.3 * (1 - root.reveal)
        }

        // Two scoops flank the edge that touches the bar.
        Repeater {
            model: 2
            delegate: ConcaveCorner {
                required property int index
                readonly property bool isStart: index === 0

                x: root.isVertical ? (root.isLeft ? 0 : frame.width - root.scoopRadius) : (isStart ? 0 : frame.width - root.scoopRadius)
                y: root.isVertical ? (isStart ? 0 : frame.height - root.scoopRadius) : (root.isTop ? 0 : frame.height - root.scoopRadius)
                radiusX: root.scoopRadius
                radiusY: root.scoopRadius
                fillColor: Theme.popupBg
                showBorder: true
                borderWidth: 1
                borderColor: Theme.popupBorderColor
                flipX: root.isVertical ? root.isRight : isStart
                flipY: root.isVertical ? isStart : root.isBottom
                visible: root.scoopRadius > 0
            }
        }

        Rectangle {
            id: body
            anchors.fill: parent
            // -1 on the attached side pushes the border under the bar so there's no seam line
            anchors.leftMargin: root.isVertical ? (root.isLeft ? -1 : 0) : root.scoopRadius
            anchors.rightMargin: root.isVertical ? (root.isRight ? -1 : 0) : root.scoopRadius
            anchors.topMargin: root.isVertical ? root.scoopRadius : (root.isTop ? -1 : 0)
            anchors.bottomMargin: root.isVertical ? root.scoopRadius : (root.isBottom ? -1 : 0)

            radius: Theme.radiusMd
            color: Theme.popupBg
            border.color: Theme.popupBorderColor
            border.width: 1

            topLeftRadius: (root.isTop || root.isLeft) ? 0 : Theme.radiusMd
            topRightRadius: (root.isTop || root.isRight) ? 0 : Theme.radiusMd
            bottomLeftRadius: (root.isBottom || root.isLeft) ? 0 : Theme.radiusMd
            bottomRightRadius: (root.isBottom || root.isRight) ? 0 : Theme.radiusMd

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 8

                // header
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Text {
                        text: "󰑮 physics & momentum playground"
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeSm
                        font.weight: Font.Bold
                        color: Theme.primary
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    IconButton {
                        icon: Theme.iconRefresh
                        iconSize: Theme.fontSizeXs
                        tooltip: "reset playground"
                        onClicked: {
                            root.bounceScore = 0;
                            root.resetPlayground();
                        }
                    }

                    IconButton {
                        icon: Theme.iconClose
                        iconSize: Theme.fontSizeXs
                        tooltip: "close (esc)"
                        onClicked: Settings.showMotionSandbox = false
                    }
                }

                // toolbar (wraps instead of overflowing on vertical docks)
                Flow {
                    Layout.fillWidth: true
                    spacing: 8

                    ChipGroup {
                        options: [
                            { id: "toy", label: "pinball toy" },
                            { id: "cards", label: "cards" }
                        ]
                        current: root.activeSandboxMode
                        onPicked: key => root.activeSandboxMode = key
                    }

                    ChipGroup {
                        visible: root.activeSandboxMode === "toy"
                        options: [
                            { id: "normal", label: "grav" },
                            { id: "zero", label: "zero-g" },
                            { id: "reverse", label: "anti-g" },
                            { id: "chaos", label: "chaos" }
                        ]
                        current: root.gravityMode
                        activeColor: Theme.secondary
                        activeTextColor: Theme.on_secondary
                        onPicked: key => root.gravityMode = key
                    }

                    Chip {
                        visible: root.activeSandboxMode === "cards"
                        label: root.springMode ? "spring snapback" : "momentum flick"
                        active: true
                        activeColor: root.springMode ? Theme.warn_container : Theme.primary_overlay
                        activeTextColor: root.springMode ? Theme.on_warn_container : Theme.primary
                        onClicked: root.springMode = !root.springMode
                    }
                }

                // play area
                Rectangle {
                    id: canvasArea
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.minimumHeight: 120
                    radius: Theme.radiusSm
                    color: Qt.alpha(Theme.surface_container_high, 0.35)
                    border.color: Theme.widgetBorder
                    border.width: 1
                    clip: true

                    onWidthChanged: layoutSettle.restart()
                    onHeightChanged: layoutSettle.restart()

                    // ─ pinball toy ─
                    Item {
                        id: toyLayer
                        anchors.fill: parent
                        visible: root.activeSandboxMode === "toy"

                        // (u, d) = position along the bar, depth away from the bar (0..1),
                        // so the layout mirrors correctly for every dock edge
                        function mapX(u, d) {
                            const w = canvasArea.width;
                            return root.isVertical ? (root.isLeft ? d * w : (1 - d) * w) : u * w;
                        }
                        function mapY(u, d) {
                            const h = canvasArea.height;
                            return root.isVertical ? u * h : (root.isTop ? d * h : (1 - d) * h);
                        }

                        Repeater {
                            id: bumperRepeater
                            model: [
                                { u: 0.24, d: 0.42, points: 25, icon: "󰓠" },
                                { u: 0.50, d: 0.28, points: 100, icon: "󰓦" },
                                { u: 0.76, d: 0.42, points: 50, icon: "󰓡" }
                            ]
                            delegate: Bumper {
                                required property var modelData
                                points: modelData.points
                                icon: modelData.icon
                                x: Math.round(toyLayer.mapX(modelData.u, modelData.d) - width / 2)
                                y: Math.round(toyLayer.mapY(modelData.u, modelData.d) - height / 2)
                            }
                        }

                        RowLayout {
                            anchors.top: parent.top
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.margins: 6
                            spacing: 6

                            Rectangle {
                                implicitHeight: 20
                                implicitWidth: scText.implicitWidth + 12
                                radius: Theme.radiusPill
                                color: Theme.primary_overlay

                                Text {
                                    id: scText
                                    anchors.centerIn: parent
                                    text: "score " + root.bounceScore + " · best " + root.bestScore
                                    font.family: Theme.fontMono
                                    font.pixelSize: 9
                                    font.weight: Font.Bold
                                    color: Theme.primary
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                text: "click = shockwave · drag ball to fling"
                                elide: Text.ElideRight
                                font.family: Theme.fontFamily
                                font.pixelSize: 9
                                color: Theme.on_surface_variant
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: mouse => {
                                const dx = toyBall.x + toyBall.width / 2 - mouse.x;
                                const dy = toyBall.y + toyBall.height / 2 - mouse.y;
                                const dist = Math.max(16, Math.hypot(dx, dy));
                                const force = Math.min(1800, 35000 / dist);
                                toyBall.vx += (dx / dist) * force;
                                toyBall.vy += (dy / dist) * force;
                                toyBall.wake();
                                root.bounceScore += 5;
                            }
                        }

                        Rectangle {
                            id: toyBall
                            width: 28
                            height: 28
                            radius: 14
                            color: Theme.primary
                            border.color: Theme.on_primary
                            border.width: 2
                            z: 10

                            property real vx: 0
                            property real vy: 0
                            property real chaosAngle: 0
                            property real restTime: 0
                            property bool placed: false
                            property bool asleep: true   // physics loop stops when the ball settles
                            property bool dragging: ballDrag.active

                            function wake() {
                                if (!placed)
                                    return;
                                asleep = false;
                                restTime = 0;
                            }

                            // spawn on the far side from the bar; gravity pulls it back through the bumpers
                            function resetBall() {
                                const cx = toyLayer.mapX(0.5, 0.8);
                                const cy = toyLayer.mapY(0.5, 0.8);
                                x = Math.round(cx - width / 2);
                                y = Math.round(cy - height / 2);
                                const lateral = (Math.random() - 0.5) * 360;
                                const away = 240;
                                vx = root.isVertical ? -root.barDx * away : lateral;
                                vy = root.isVertical ? lateral : -root.barDy * away;
                                placed = true;
                                wake();
                            }

                            Text {
                                anchors.centerIn: parent
                                text: "󰮯"
                                font.family: Theme.fontIcon
                                font.pixelSize: 12
                                color: Theme.on_primary
                            }

                            DragHandler {
                                id: ballDrag
                                target: toyBall
                                xAxis.minimum: 0
                                xAxis.maximum: canvasArea.width - toyBall.width
                                yAxis.minimum: 0
                                yAxis.maximum: canvasArea.height - toyBall.height
                                cursorShape: active ? Qt.ClosedHandCursor : Qt.OpenHandCursor

                                onActiveChanged: {
                                    if (active) {
                                        toyBall.vx = 0;
                                        toyBall.vy = 0;
                                    } else {
                                        const cap = 1400;
                                        toyBall.vx = Math.max(-cap, Math.min(cap, centroid.velocity.x));
                                        toyBall.vy = Math.max(-cap, Math.min(cap, centroid.velocity.y));
                                        if (Math.hypot(toyBall.vx, toyBall.vy) < 60) {
                                            // a plain drop gets tossed away from the bar
                                            toyBall.vx = -root.barDx * 380;
                                            toyBall.vy = -root.barDy * 380;
                                        }
                                        toyBall.wake();
                                    }
                                }
                            }
                        }

                        FrameAnimation {
                            running: root.isOpen && root.activeSandboxMode === "toy" && !toyBall.dragging && !toyBall.asleep

                            onTriggered: {
                                const dt = Math.min(0.05, frameTime);
                                if (dt <= 0)
                                    return;

                                // "normal" gravity pulls toward the bar, "reverse" away from it
                                const gMag = 920;
                                let gx = 0, gy = 0;
                                if (root.gravityMode === "normal") {
                                    gx = root.barDx * gMag;
                                    gy = root.barDy * gMag;
                                } else if (root.gravityMode === "reverse") {
                                    gx = -root.barDx * gMag;
                                    gy = -root.barDy * gMag;
                                } else if (root.gravityMode === "chaos") {
                                    toyBall.chaosAngle += 0.08 * (dt / 0.016);
                                    gx = Math.sin(toyBall.chaosAngle) * gMag;
                                    gy = Math.cos(toyBall.chaosAngle * 1.3) * gMag;
                                }

                                toyBall.vx += gx * dt;
                                toyBall.vy += gy * dt;

                                const friction = Math.pow(0.994, dt / 0.016);
                                toyBall.vx *= friction;
                                toyBall.vy *= friction;

                                toyBall.x += toyBall.vx * dt;
                                toyBall.y += toyBall.vy * dt;

                                // walls
                                const maxX = canvasArea.width - toyBall.width;
                                const maxY = canvasArea.height - toyBall.height;
                                const bounceLoss = 0.78;

                                if (toyBall.x < 0 || toyBall.x > maxX) {
                                    toyBall.x = Math.max(0, Math.min(maxX, toyBall.x));
                                    if (Math.abs(toyBall.vx) > 50)
                                        root.bounceScore += 1;
                                    toyBall.vx = -toyBall.vx * bounceLoss;
                                }
                                if (toyBall.y < 0 || toyBall.y > maxY) {
                                    toyBall.y = Math.max(0, Math.min(maxY, toyBall.y));
                                    if (Math.abs(toyBall.vy) > 50)
                                        root.bounceScore += 1;
                                    toyBall.vy = -toyBall.vy * bounceLoss;
                                }

                                // bumpers
                                const bx = toyBall.x + toyBall.width / 2;
                                const by = toyBall.y + toyBall.height / 2;
                                const ballRadius = toyBall.width / 2;

                                for (let i = 0; i < bumperRepeater.count; ++i) {
                                    const b = bumperRepeater.itemAt(i);
                                    if (!b)
                                        continue;
                                    const cx = b.x + b.width / 2;
                                    const cy = b.y + b.height / 2;
                                    const dist = Math.hypot(bx - cx, by - cy);
                                    const minDist = ballRadius + b.width / 2;

                                    if (dist < minDist && dist > 0.001) {
                                        const nx = (bx - cx) / dist;
                                        const ny = (by - cy) / dist;

                                        toyBall.x = cx + nx * (minDist + 1) - ballRadius;
                                        toyBall.y = cy + ny * (minDist + 1) - ballRadius;

                                        const dot = toyBall.vx * nx + toyBall.vy * ny;
                                        if (dot < 0) {
                                            toyBall.vx -= 1.88 * dot * nx;
                                            toyBall.vy -= 1.88 * dot * ny;
                                        }
                                        toyBall.vx += nx * 140;
                                        toyBall.vy += ny * 140;

                                        b.pulse();
                                        root.bounceScore += b.points;
                                    }
                                }

                                // fall asleep once settled so an idle popup doesn't redraw every frame
                                if (Math.hypot(toyBall.vx, toyBall.vy) < 20 && root.gravityMode !== "chaos") {
                                    toyBall.restTime += dt;
                                    if (toyBall.restTime > 0.4) {
                                        toyBall.vx = 0;
                                        toyBall.vy = 0;
                                        toyBall.asleep = true;
                                    }
                                } else {
                                    toyBall.restTime = 0;
                                }
                            }
                        }
                    }

                    // ─ cards ─
                    Item {
                        id: cardsLayer
                        anchors.fill: parent
                        visible: root.activeSandboxMode === "cards"

                        Text {
                            anchors.left: parent.left
                            anchors.bottom: parent.bottom
                            anchors.margins: 6
                            text: root.springMode ? "release to snap back" : "drag and release to flick"
                            font.family: Theme.fontFamily
                            font.pixelSize: 9
                            color: Theme.on_surface_variant
                        }

                        PhysicsCard {
                            id: dragCard1
                            slot: 0
                            icon: "󰁕"
                            title: "flick momentum"
                            accentColor: Theme.primary
                        }

                        PhysicsCard {
                            id: dragCard2
                            slot: 1
                            icon: "󰈈"
                            title: "freedom card"
                            accentColor: Theme.warn
                        }

                        PhysicsCard {
                            id: dragCard3
                            slot: 2
                            icon: Theme.iconMusic
                            title: "media pill"
                            accentColor: Theme.secondary
                        }
                    }
                }

                // footer
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Text {
                        text: "timing"
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeXs
                        font.weight: Font.Bold
                        color: Theme.primary
                    }

                    ChipGroup {
                        options: [
                            { id: "hyprland", label: "hypr" },
                            { id: "snappy", label: "snappy" },
                            { id: "chill", label: "chill" },
                            { id: "instant", label: "zero" }
                        ]
                        current: Settings.animSpeed
                        onPicked: key => Settings.animSpeed = key
                    }

                    Text {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignRight
                        elide: Text.ElideLeft
                        text: root.resolvedDock + " · scoop " + root.scoopRadius + "px" + (root.followsBar ? "" : " · detached")
                        font.family: Theme.fontMono
                        font.pixelSize: 10
                        color: Theme.on_surface_variant
                    }
                }
            }
        }
    }
}
