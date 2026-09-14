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

    property bool open: Settings.showMotionSandbox
    onOpenChanged: {
        if (Settings.showMotionSandbox !== open) Settings.showMotionSandbox = open;
    }

    property string dockPosition: "bottom"
    readonly property bool isBottom: dockPosition === "bottom"
    readonly property bool isTop: dockPosition === "top"
    readonly property bool isLeft: dockPosition === "left"
    readonly property bool isRight: dockPosition === "right"
    readonly property bool isVertical: isLeft || isRight

    property bool springMode: false
    property string activeSandboxMode: "toy"
    property int bounceScore: 0
    property string gravityMode: "normal"

    anchors {
        top: root.isTop
        bottom: root.isBottom
        left: root.isLeft
        right: root.isRight
    }

    margins {
        top: 0
        bottom: 0
        left: 0
        right: 0
    }

    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell:motionsandbox"

    visible: open
    implicitWidth: root.isVertical ? 380 : 620
    implicitHeight: root.isVertical ? 520 : 320

    Item {
        anchors.fill: parent

        ConcaveCorner {
            x: 0
            y: 0
            radiusX: Theme.scoopRadiusX
            radiusY: Theme.scoopRadiusY
            fillColor: Theme.popupBg
            flipX: true
            flipY: false
            visible: root.isTop && Settings.scoopRadius > 0
        }
        ConcaveCorner {
            x: parent.width - Theme.scoopRadiusX
            y: 0
            radiusX: Theme.scoopRadiusX
            radiusY: Theme.scoopRadiusY
            fillColor: Theme.popupBg
            flipX: false
            flipY: false
            visible: root.isTop && Settings.scoopRadius > 0
        }

        ConcaveCorner {
            x: 0
            y: parent.height - Theme.scoopRadiusY
            radiusX: Theme.scoopRadiusX
            radiusY: Theme.scoopRadiusY
            fillColor: Theme.popupBg
            flipX: true
            flipY: true
            visible: root.isBottom && Settings.scoopRadius > 0
        }
        ConcaveCorner {
            x: parent.width - Theme.scoopRadiusX
            y: parent.height - Theme.scoopRadiusY
            radiusX: Theme.scoopRadiusX
            radiusY: Theme.scoopRadiusY
            fillColor: Theme.popupBg
            flipX: false
            flipY: true
            visible: root.isBottom && Settings.scoopRadius > 0
        }

        ConcaveCorner {
            x: 0
            y: 0
            radiusX: Theme.scoopRadiusX
            radiusY: Theme.scoopRadiusY
            fillColor: Theme.popupBg
            flipX: false
            flipY: true
            visible: root.isLeft && Settings.scoopRadius > 0
        }
        ConcaveCorner {
            x: 0
            y: parent.height - Theme.scoopRadiusY
            radiusX: Theme.scoopRadiusX
            radiusY: Theme.scoopRadiusY
            fillColor: Theme.popupBg
            flipX: false
            flipY: false
            visible: root.isLeft && Settings.scoopRadius > 0
        }

        ConcaveCorner {
            x: parent.width - Theme.scoopRadiusX
            y: 0
            radiusX: Theme.scoopRadiusX
            radiusY: Theme.scoopRadiusY
            fillColor: Theme.popupBg
            flipX: true
            flipY: true
            visible: root.isRight && Settings.scoopRadius > 0
        }
        ConcaveCorner {
            x: parent.width - Theme.scoopRadiusX
            y: parent.height - Theme.scoopRadiusY
            radiusX: Theme.scoopRadiusX
            radiusY: Theme.scoopRadiusY
            fillColor: Theme.popupBg
            flipX: true
            flipY: false
            visible: root.isRight && Settings.scoopRadius > 0
        }

        Rectangle {
            id: body
            anchors.fill: parent
            anchors.leftMargin: root.isBottom || root.isTop ? Theme.scoopRadiusX : 0
            anchors.rightMargin: root.isBottom || root.isTop ? Theme.scoopRadiusX : 0
            anchors.topMargin: root.isVertical ? Theme.scoopRadiusY : 0
            anchors.bottomMargin: root.isVertical ? Theme.scoopRadiusY : 0
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

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Text {
                        text: "󰑮 physics & momentum playground"
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeSm
                        font.weight: Font.Bold
                        color: Theme.primary
                        Layout.fillWidth: true
                    }

                    RowLayout {
                        spacing: 4
                        Repeater {
                            model: [
                                { id: "toy", label: "pinball toy" },
                                { id: "cards", label: "cards" }
                            ]
                            delegate: Rectangle {
                                required property var modelData
                                height: 24
                                width: modeText.implicitWidth + 14
                                radius: Theme.radiusPill
                                color: root.activeSandboxMode === modelData.id ? Theme.primary : Theme.surface_container_highest
                                border.color: Theme.widgetBorder
                                border.width: 1

                                Text {
                                    id: modeText
                                    text: modelData.label
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 10
                                    font.weight: Font.Bold
                                    color: root.activeSandboxMode === modelData.id ? Theme.on_primary : Theme.on_surface
                                    anchors.centerIn: parent
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.activeSandboxMode = modelData.id
                                }
                            }
                        }
                    }

                    RowLayout {
                        visible: root.activeSandboxMode === "toy"
                        spacing: 4

                        Repeater {
                            model: [
                                { id: "normal", label: "grav" },
                                { id: "zero", label: "zero-g" },
                                { id: "reverse", label: "anti-g" },
                                { id: "chaos", label: "chaos" }
                            ]

                            delegate: Rectangle {
                                required property var modelData
                                height: 22
                                width: gText.implicitWidth + 10
                                radius: Theme.radiusPill
                                color: root.gravityMode === modelData.id ? Theme.secondary : Theme.surface_container_high

                                Text {
                                    id: gText
                                    text: modelData.label
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 9
                                    font.weight: Font.Bold
                                    color: root.gravityMode === modelData.id ? Theme.on_secondary : Theme.on_surface_variant
                                    anchors.centerIn: parent
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.gravityMode = modelData.id
                                }
                            }
                        }
                    }

                    Rectangle {
                        visible: root.activeSandboxMode === "cards"
                        height: 24
                        implicitWidth: modeRow.implicitWidth + 14
                        radius: Theme.radiusPill
                        color: root.springMode ? Theme.warn_container : Theme.primary_overlay

                        RowLayout {
                            id: modeRow
                            anchors.centerIn: parent
                            spacing: 4
                            Text {
                                text: root.springMode ? "spring snapback" : "momentum flick"
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                                font.weight: Font.Bold
                                color: root.springMode ? Theme.on_warn_container : Theme.primary
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.springMode = !root.springMode
                        }
                    }

                    IconButton {
                        icon: Theme.iconRefresh
                        iconSize: Theme.fontSizeXs
                        tooltip: "reset playground"
                        onClicked: {
                            root.bounceScore = 0;
                            toyBall.resetBall();
                            dragCard1.snapHome();
                            dragCard2.snapHome();
                            dragCard3.snapHome();
                        }
                    }

                    RowLayout {
                        spacing: 2
                        Repeater {
                            model: [
                                { pos: "bottom", icon: Theme?.iconChevronDown ?? "↓" },
                                { pos: "top", icon: Theme?.iconChevronUp ?? "↑" },
                                { pos: "left", icon: Theme?.iconChevronLeft ?? "←" },
                                { pos: "right", icon: Theme?.iconChevronRight ?? "→" }
                            ]
                            delegate: Rectangle {
                                required property var modelData
                                width: 24
                                height: 24
                                radius: Theme.radiusSm
                                color: root.dockPosition === modelData.pos ? Theme.primary : Theme.surface_container_high

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.icon
                                    font.family: Theme.fontIcon
                                    font.pixelSize: 10
                                    color: root.dockPosition === modelData.pos ? Theme.on_primary : Theme.on_surface
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        root.dockPosition = modelData.pos;
                                        dragCard1.snapHome();
                                        dragCard2.snapHome();
                                        dragCard3.snapHome();
                                        toyBall.resetBall();
                                    }
                                }
                            }
                        }
                    }

                    IconButton {
                        icon: Theme.iconClose
                        iconSize: Theme.fontSizeXs
                        tooltip: "close sandbox"
                        onClicked: {
                            root.open = false;
                            Settings.showMotionSandbox = false;
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Theme.widgetBorder
                }

                Item {
                    id: canvasArea
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true

                    Item {
                        id: toyLayer
                        anchors.fill: parent
                        visible: root.activeSandboxMode === "toy"

                        component Bumper: Rectangle {
                            id: bmpRoot
                            property int points: 50
                            property alias icon: bmpIcon.text
                            width: 52
                            height: 52
                            radius: 26
                            color: Theme.surface_container_high
                            border.color: Theme.widgetBorder
                            border.width: 2

                            function pulse() {
                                bumpAnim.restart();
                            }

                            SequentialAnimation {
                                id: bumpAnim
                                ParallelAnimation {
                                    ColorAnimation { target: bmpRoot; property: "color"; to: Theme.primary; duration: 60 }
                                    NumberAnimation { target: bmpRoot; property: "scale"; to: 1.22; duration: 60; easing.type: Easing.OutBack }
                                }
                                ParallelAnimation {
                                    ColorAnimation { target: bmpRoot; property: "color"; to: Theme.surface_container_high; duration: 240 }
                                    NumberAnimation { target: bmpRoot; property: "scale"; to: 1.0; duration: 240; easing.type: Easing.OutQuad }
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
                                    text: "+" + bmpRoot.points
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 8
                                    font.weight: Font.Bold
                                    color: Theme.on_surface_variant
                                }
                            }
                        }

                        Bumper {
                            id: bump1
                            x: Math.round(canvasArea.width * 0.24 - width / 2)
                            y: Math.round(canvasArea.height * 0.42 - height / 2)
                            points: 25
                            icon: "󰓠"
                        }

                        Bumper {
                            id: bump2
                            x: Math.round(canvasArea.width * 0.50 - width / 2)
                            y: Math.round(canvasArea.height * 0.28 - height / 2)
                            points: 100
                            icon: "󰓦"
                        }

                        Bumper {
                            id: bump3
                            x: Math.round(canvasArea.width * 0.76 - width / 2)
                            y: Math.round(canvasArea.height * 0.42 - height / 2)
                            points: 50
                            icon: "󰓡"
                        }

                        RowLayout {
                            anchors.top: parent.top
                            anchors.left: parent.left
                            anchors.margins: 6
                            spacing: 6

                            Rectangle {
                                height: 20
                                implicitWidth: scText.implicitWidth + 12
                                radius: Theme.radiusPill
                                color: Theme.primary_overlay

                                Text {
                                    id: scText
                                    anchors.centerIn: parent
                                    text: "score: " + root.bounceScore
                                    font.family: Theme.fontMono
                                    font.pixelSize: 9
                                    font.weight: Font.Bold
                                    color: Theme.primary
                                }
                            }

                            Text {
                                text: "click canvas to shockwave • drag ball to fling"
                                font.family: Theme.fontFamily
                                font.pixelSize: 9
                                color: Theme.on_surface_variant
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: (mouse) => {
                                const dx = toyBall.x + toyBall.width / 2 - mouse.x;
                                const dy = toyBall.y + toyBall.height / 2 - mouse.y;
                                const dist = Math.max(16, Math.hypot(dx, dy));
                                const force = Math.min(1800, 35000 / dist);
                                toyBall.vx += (dx / dist) * force;
                                toyBall.vy += (dy / dist) * force;
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

                            property real vx: 180
                            property real vy: -240
                            property real chaosAngle: 0
                            property bool dragging: false
                            property real dragStartX: 0
                            property real dragStartY: 0
                            property real lastDragTime: 0

                            function resetBall() {
                                x = Math.round(canvasArea.width / 2 - width / 2);
                                y = Math.round(canvasArea.height * 0.75);
                                vx = (Math.random() - 0.5) * 360;
                                vy = -420;
                            }

                            Component.onCompleted: resetBall()

                            Text {
                                anchors.centerIn: parent
                                text: "󰮯"
                                font.family: Theme.fontIcon
                                font.pixelSize: 12
                                color: Theme.on_primary
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor

                                onPressed: (mouse) => {
                                    toyBall.dragging = true;
                                    toyBall.vx = 0;
                                    toyBall.vy = 0;
                                    toyBall.dragStartX = toyBall.x;
                                    toyBall.dragStartY = toyBall.y;
                                    toyBall.lastDragTime = Date.now();
                                }

                                onPositionChanged: (mouse) => {
                                    if (!toyBall.dragging) return;
                                    const p = mapToItem(canvasArea, mouse.x, mouse.y);
                                    toyBall.x = Math.max(0, Math.min(canvasArea.width - toyBall.width, p.x - toyBall.width / 2));
                                    toyBall.y = Math.max(0, Math.min(canvasArea.height - toyBall.height, p.y - toyBall.height / 2));
                                }

                                onReleased: (mouse) => {
                                    if (!toyBall.dragging) return;
                                    toyBall.dragging = false;
                                    const dt = Math.max(16, Date.now() - toyBall.lastDragTime);
                                    toyBall.vx = Math.max(-1400, Math.min(1400, ((toyBall.x - toyBall.dragStartX) / dt) * 1000));
                                    toyBall.vy = Math.max(-1400, Math.min(1400, ((toyBall.y - toyBall.dragStartY) / dt) * 1000));
                                    if (Math.hypot(toyBall.vx, toyBall.vy) < 60) {
                                        toyBall.vy = -380;
                                    }
                                }
                            }
                        }

                        Timer {
                            interval: 16
                            running: root.visible && root.activeSandboxMode === "toy" && !toyBall.dragging
                            repeat: true
                            onTriggered: {
                                const dt = 0.016;
                                let gx = 0, gy = 0;
                                const gMag = 920;

                                if (root.gravityMode === "normal") {
                                    if (root.isBottom) gy = gMag;
                                    else if (root.isTop) gy = -gMag;
                                    else if (root.isLeft) gx = -gMag;
                                    else if (root.isRight) gx = gMag;
                                } else if (root.gravityMode === "reverse") {
                                    if (root.isBottom) gy = -gMag;
                                    else if (root.isTop) gy = gMag;
                                    else if (root.isLeft) gx = gMag;
                                    else if (root.isRight) gx = -gMag;
                                } else if (root.gravityMode === "chaos") {
                                    toyBall.chaosAngle += 0.08;
                                    gx = Math.sin(toyBall.chaosAngle) * gMag;
                                    gy = Math.cos(toyBall.chaosAngle * 1.3) * gMag;
                                }

                                toyBall.vx += gx * dt;
                                toyBall.vy += gy * dt;

                                toyBall.vx *= 0.994;
                                toyBall.vy *= 0.994;

                                toyBall.x += toyBall.vx * dt;
                                toyBall.y += toyBall.vy * dt;

                                const maxX = canvasArea.width - toyBall.width;
                                const maxY = canvasArea.height - toyBall.height;
                                const bounceLoss = 0.78;

                                if (toyBall.x < 0) {
                                    toyBall.x = 0;
                                    toyBall.vx = -toyBall.vx * bounceLoss;
                                    if (Math.abs(toyBall.vx) > 40) root.bounceScore += 1;
                                } else if (toyBall.x > maxX) {
                                    toyBall.x = maxX;
                                    toyBall.vx = -toyBall.vx * bounceLoss;
                                    if (Math.abs(toyBall.vx) > 40) root.bounceScore += 1;
                                }

                                if (toyBall.y < 0) {
                                    toyBall.y = 0;
                                    toyBall.vy = -toyBall.vy * bounceLoss;
                                    if (Math.abs(toyBall.vy) > 40) root.bounceScore += 1;
                                } else if (toyBall.y > maxY) {
                                    toyBall.y = maxY;
                                    toyBall.vy = -toyBall.vy * bounceLoss;
                                    if (Math.abs(toyBall.vy) > 40) root.bounceScore += 1;
                                }

                                const bx = toyBall.x + toyBall.width / 2;
                                const by = toyBall.y + toyBall.height / 2;
                                const ballRadius = toyBall.width / 2;

                                const bumpers = [bump1, bump2, bump3];
                                for (let i = 0; i < bumpers.length; ++i) {
                                    const b = bumpers[i];
                                    const cx = b.x + b.width / 2;
                                    const cy = b.y + b.height / 2;
                                    const bRadius = b.width / 2;
                                    const dist = Math.hypot(bx - cx, by - cy);
                                    const minDist = ballRadius + bRadius;

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
                            }
                        }
                    }

                    component PhysicsCard: Rectangle {
                        id: pcRoot
                        property int homeX: 10
                        property int homeY: 10
                        property alias icon: pcIcon.text
                        property alias title: pcTitle.text
                        property color accentColor: Theme.primary

                        width: 120
                        height: 88
                        radius: Theme.radiusMd
                        color: Theme.surface_container_highest
                        border.color: pcMouse.drag.active ? accentColor : Theme.widgetBorder
                        border.width: 1
                        z: pcMouse.drag.active ? 20 : 1

                        property real lastCanvasX: 0
                        property real lastCanvasY: 0
                        property real lastTime: 0
                        property real velX: 0
                        property real velY: 0

                        function snapHome() {
                            momentumAnim.stop();
                            animX.to = Math.max(0, Math.min(canvasArea.width - width, homeX));
                            animY.to = Math.max(0, Math.min(canvasArea.height - height, homeY));
                            animX.easing.type = Easing.OutBack;
                            animY.easing.type = Easing.OutBack;
                            animX.duration = Theme.animSlow;
                            animY.duration = Theme.animSlow;
                            momentumAnim.restart();
                        }

                        function animateTo(targetX, targetY) {
                            momentumAnim.stop();
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
                                font.pixelSize: 10
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

                        MouseArea {
                            id: pcMouse
                            anchors.fill: parent
                            drag.target: pcRoot
                            drag.axis: Drag.XAndYAxis
                            drag.minimumX: 0
                            drag.maximumX: canvasArea.width - pcRoot.width
                            drag.minimumY: 0
                            drag.maximumY: canvasArea.height - pcRoot.height
                            cursorShape: drag.active ? Qt.ClosedHandCursor : Qt.OpenHandCursor

                            onPressed: {
                                momentumAnim.stop();
                                pcRoot.lastCanvasX = pcRoot.x;
                                pcRoot.lastCanvasY = pcRoot.y;
                                pcRoot.lastTime = Date.now();
                                pcRoot.velX = 0;
                                pcRoot.velY = 0;
                            }

                            // calculate delta on parent canvas coordinate space, not self-canceling local mouse
                            onPositionChanged: {
                                const now = Date.now();
                                const dt = Math.max(8, now - pcRoot.lastTime);
                                const vx = ((pcRoot.x - pcRoot.lastCanvasX) / dt) * 1000;
                                const vy = ((pcRoot.y - pcRoot.lastCanvasY) / dt) * 1000;
                                pcRoot.velX = pcRoot.velX * 0.25 + vx * 0.75;
                                pcRoot.velY = pcRoot.velY * 0.25 + vy * 0.75;
                                pcRoot.lastCanvasX = pcRoot.x;
                                pcRoot.lastCanvasY = pcRoot.y;
                                pcRoot.lastTime = now;
                            }

                            onReleased: {
                                if (Date.now() - pcRoot.lastTime > 80) {
                                    pcRoot.velX = 0;
                                    pcRoot.velY = 0;
                                }

                                if (root.springMode) {
                                    pcRoot.snapHome();
                                } else {
                                    pcRoot.animateTo(pcRoot.x + pcRoot.velX * 0.22, pcRoot.y + pcRoot.velY * 0.22);
                                }
                            }
                        }
                    }

                    Item {
                        id: cardsLayer
                        anchors.fill: parent
                        visible: root.activeSandboxMode === "cards"

                        PhysicsCard {
                            id: dragCard1
                            homeX: 10
                            homeY: 10
                            x: homeX
                            y: homeY
                            icon: "󰁕"
                            title: "flick momentum"
                            accentColor: Theme.primary
                        }

                        PhysicsCard {
                            id: dragCard2
                            homeX: root.isVertical ? 10 : 145
                            homeY: root.isVertical ? 106 : 10
                            x: homeX
                            y: homeY
                            icon: "󰈈"
                            title: "freedom card"
                            accentColor: Theme.warn
                        }

                        PhysicsCard {
                            id: dragCard3
                            homeX: root.isVertical ? 10 : 280
                            homeY: root.isVertical ? 202 : 10
                            x: homeX
                            y: homeY
                            icon: Theme.iconMusic
                            title: "media pill"
                            accentColor: Theme.secondary
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Text {
                        text: "timing: " + Settings.animSpeed
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                        font.weight: Font.Bold
                        color: Theme.primary
                    }

                    RowLayout {
                        spacing: 4
                        Repeater {
                            model: [
                                { id: "hyprland", label: "hypr" },
                                { id: "snappy", label: "snappy" },
                                { id: "chill", label: "chill" },
                                { id: "instant", label: "zero" }
                            ]
                            delegate: Rectangle {
                                required property var modelData
                                width: 48
                                height: 22
                                radius: Theme.radiusSm
                                color: Settings.animSpeed === modelData.id ? Theme.primary : Theme.surface_container_high

                                Text {
                                    text: modelData.label
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 10
                                    color: Settings.animSpeed === modelData.id ? Theme.on_primary : Theme.on_surface
                                    anchors.centerIn: parent
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Settings.animSpeed = modelData.id
                                }
                            }
                        }
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        text: "scoop: " + Settings.scoopRadius + "px • native arc"
                        font.family: Theme.fontMono
                        font.pixelSize: 10
                        color: Theme.on_surface_variant
                    }
                }
            }
        }
    }
}