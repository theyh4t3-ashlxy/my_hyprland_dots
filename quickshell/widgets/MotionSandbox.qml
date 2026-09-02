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

    property bool open: false
    property string dockPosition: "bottom" // "top", "bottom", "left", "right"
    readonly property bool isBottom: dockPosition === "bottom"
    readonly property bool isTop: dockPosition === "top"
    readonly property bool isLeft: dockPosition === "left"
    readonly property bool isRight: dockPosition === "right"
    readonly property bool isVertical: isLeft || isRight

    property bool springMode: false
    property string activeSandboxMode: "toy" // "toy" or "cards"
    property int bounceScore: 0
    property string gravityMode: "normal" // "normal", "zero", "reverse", "chaos"

    anchors {
        top: root.isTop || root.isVertical
        bottom: root.isBottom || root.isVertical
        left: root.isLeft || !root.isVertical
        right: root.isRight || !root.isVertical
    }

    margins {
        top: root.isTop ? 0 : (root.isVertical ? 40 : 0)
        bottom: root.isBottom ? 0 : (root.isVertical ? 40 : 0)
        left: root.isLeft ? 0 : (root.isBottom || root.isTop ? 40 : 0)
        right: root.isRight ? 0 : (root.isBottom || root.isTop ? 40 : 0)
    }

    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell:motionsandbox"

    visible: open
    implicitWidth: root.isVertical ? 360 : 580
    implicitHeight: root.isVertical ? 500 : 280

    // Dual Concave Joint Welds into Screen Edge
    Item {
        anchors.fill: parent

        // Top edge weld scoops
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

        // Bottom edge weld scoops
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

        // Left edge weld scoops
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

        // Right edge weld scoops
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

        // Card body
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

                // Header & Controls
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

                    
                    // Sandbox mode toggle
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
                                color: root.activeSandboxMode === modelData.id ? Theme.primary : Theme.cardBg
                                border.color: Theme.cardBorder
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

                    // Mode Toggle (Flick Momentum vs Spring Return)
                    Rectangle {
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

                    // Reset Positions Button
                    IconButton {
                        icon: Theme.iconRefresh
                        iconSize: Theme.fontSizeXs
                        tooltip: "reset card positions"
                        onClicked: {
                            dragCard1.animateTo(10, 10);
                            dragCard2.animateTo(145, 10);
                            dragCard3.animateTo(280, 10);
                        }
                    }

                    // 4-Way Dock Position Selector
                    RowLayout {
                        spacing: 2

                        Repeater {
                            model: [
                                { pos: "bottom", icon: "" },
                                { pos: "top", icon: "" },
                                { pos: "left", icon: "" },
                                { pos: "right", icon: "" }
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
                                    onClicked: root.dockPosition = modelData.pos
                                }
                            }
                        }
                    }

                    IconButton {
                        icon: Theme.iconClose
                        iconSize: Theme.fontSizeXs
                        tooltip: "close sandbox"
                        onClicked: {
                            root.open = false
                            Settings.showMotionSandbox = false
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Theme.widgetBorder
                }

                // Free Canvas Playground Area
                Item {
                    id: canvasArea
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true

                    // Momentum Draggable Card 1 (Vibe)
                    Rectangle {
                        id: dragCard1
                        x: 10
                        y: 10
                        width: 120
                        height: 90
                        radius: Theme.radiusMd
                        color: Theme.surface_container_highest
                        border.color: dragArea1.drag.active ? Theme.primary : Theme.widgetBorder
                        border.width: 1
                        z: dragArea1.drag.active ? 10 : 1

                        property real lastX: 0
                        property real lastY: 0
                        property real lastTime: 0
                        property real velX: 0
                        property real velY: 0

                        function animateTo(targetX, targetY) {
                            animX1.to = Math.max(0, Math.min(canvasArea.width - width, targetX));
                            animY1.to = Math.max(0, Math.min(canvasArea.height - height, targetY));
                            momentumAnim1.restart();
                        }

                        ParallelAnimation {
                            id: momentumAnim1
                            NumberAnimation { id: animX1; target: dragCard1; property: "x"; duration: Theme.animNormal; easing.type: Easing.OutQuad }
                            NumberAnimation { id: animY1; target: dragCard1; property: "y"; duration: Theme.animNormal; easing.type: Easing.OutQuad }
                        }

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 4

                            Text {
                                text: "󰁕"
                                font.family: Theme.fontIcon
                                font.pixelSize: 18
                                color: Theme.primary
                                Layout.alignment: Qt.AlignHCenter
                            }
                            Text {
                                text: "flick momentum"
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                                font.weight: Font.Bold
                                color: Theme.on_surface
                                Layout.alignment: Qt.AlignHCenter
                            }
                            Text {
                                text: "(" + Math.round(dragCard1.x) + ", " + Math.round(dragCard1.y) + ")"
                                font.family: Theme.fontMono
                                font.pixelSize: 9
                                color: Theme.on_surface_variant
                                Layout.alignment: Qt.AlignHCenter
                            }
                        }

                        MouseArea {
                            id: dragArea1
                            anchors.fill: parent
                            drag.target: dragCard1
                            drag.axis: Drag.XAndYAxis
                            drag.minimumX: 0
                            drag.maximumX: canvasArea.width - dragCard1.width
                            drag.minimumY: 0
                            drag.maximumY: canvasArea.height - dragCard1.height
                            cursorShape: drag.active ? Qt.ClosedHandCursor : Qt.OpenHandCursor

                            onPressed: (mouse) => {
                                momentumAnim1.stop();
                                dragCard1.lastX = mouse.x;
                                dragCard1.lastY = mouse.y;
                                dragCard1.lastTime = Date.now();
                                dragCard1.velX = 0;
                                dragCard1.velY = 0;
                            }

                            onPositionChanged: (mouse) => {
                                let now = Date.now();
                                let dt = Math.max(1, now - dragCard1.lastTime);
                                dragCard1.velX = (mouse.x - dragCard1.lastX) / dt * 60;
                                dragCard1.velY = (mouse.y - dragCard1.lastY) / dt * 60;
                                dragCard1.lastX = mouse.x;
                                dragCard1.lastY = mouse.y;
                                dragCard1.lastTime = now;
                            }

                            onReleased: {
                                if (root.springMode) {
                                    dragCard1.animateTo(10, 10);
                                } else {
                                    // Glide with calculated velocity momentum
                                    dragCard1.animateTo(dragCard1.x + dragCard1.velX * 4, dragCard1.y + dragCard1.velY * 4);
                                }
                            }
                        }
                    }

                    // Momentum Draggable Card 2 (DJ)
                    Rectangle {
                        id: dragCard2
                        x: 145
                        y: 10
                        width: 120
                        height: 90
                        radius: Theme.radiusMd
                        color: Theme.surface_container_highest
                        border.color: dragArea2.drag.active ? Theme.warn : Theme.widgetBorder
                        border.width: 1
                        z: dragArea2.drag.active ? 10 : 1

                        property real lastX: 0
                        property real lastY: 0
                        property real lastTime: 0
                        property real velX: 0
                        property real velY: 0

                        function animateTo(targetX, targetY) {
                            animX2.to = Math.max(0, Math.min(canvasArea.width - width, targetX));
                            animY2.to = Math.max(0, Math.min(canvasArea.height - height, targetY));
                            momentumAnim2.restart();
                        }

                        ParallelAnimation {
                            id: momentumAnim2
                            NumberAnimation { id: animX2; target: dragCard2; property: "x"; duration: Theme.animSlow; easing.type: Easing.OutQuad }
                            NumberAnimation { id: animY2; target: dragCard2; property: "y"; duration: Theme.animSlow; easing.type: Easing.OutQuad }
                        }

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 4

                            Text {
                                text: "󰈈"
                                font.family: Theme.fontIcon
                                font.pixelSize: 18
                                color: Theme.warn
                                Layout.alignment: Qt.AlignHCenter
                            }
                            Text {
                                text: "freedom card"
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                                font.weight: Font.Bold
                                color: Theme.on_surface
                                Layout.alignment: Qt.AlignHCenter
                            }
                            Text {
                                text: "(" + Math.round(dragCard2.x) + ", " + Math.round(dragCard2.y) + ")"
                                font.family: Theme.fontMono
                                font.pixelSize: 9
                                color: Theme.on_surface_variant
                                Layout.alignment: Qt.AlignHCenter
                            }
                        }

                        MouseArea {
                            id: dragArea2
                            anchors.fill: parent
                            drag.target: dragCard2
                            drag.axis: Drag.XAndYAxis
                            drag.minimumX: 0
                            drag.maximumX: canvasArea.width - dragCard2.width
                            drag.minimumY: 0
                            drag.maximumY: canvasArea.height - dragCard2.height
                            cursorShape: drag.active ? Qt.ClosedHandCursor : Qt.OpenHandCursor

                            onPressed: (mouse) => {
                                momentumAnim2.stop();
                                dragCard2.lastX = mouse.x;
                                dragCard2.lastY = mouse.y;
                                dragCard2.lastTime = Date.now();
                                dragCard2.velX = 0;
                                dragCard2.velY = 0;
                            }

                            onPositionChanged: (mouse) => {
                                let now = Date.now();
                                let dt = Math.max(1, now - dragCard2.lastTime);
                                dragCard2.velX = (mouse.x - dragCard2.lastX) / dt * 60;
                                dragCard2.velY = (mouse.y - dragCard2.lastY) / dt * 60;
                                dragCard2.lastX = mouse.x;
                                dragCard2.lastY = mouse.y;
                                dragCard2.lastTime = now;
                            }

                            onReleased: {
                                if (root.springMode) {
                                    dragCard2.animateTo(145, 10);
                                } else {
                                    dragCard2.animateTo(dragCard2.x + dragCard2.velX * 5, dragCard2.y + dragCard2.velY * 5);
                                }
                            }
                        }
                    }

                    // Momentum Draggable Card 3 (Media Pill)
                    Rectangle {
                        id: dragCard3
                        x: 280
                        y: 10
                        width: 120
                        height: 90
                        radius: Theme.radiusMd
                        color: Theme.surface_container_highest
                        border.color: dragArea3.drag.active ? Theme.secondary : Theme.widgetBorder
                        border.width: 1
                        z: dragArea3.drag.active ? 10 : 1

                        property real lastX: 0
                        property real lastY: 0
                        property real lastTime: 0
                        property real velX: 0
                        property real velY: 0

                        function animateTo(targetX, targetY) {
                            animX3.to = Math.max(0, Math.min(canvasArea.width - width, targetX));
                            animY3.to = Math.max(0, Math.min(canvasArea.height - height, targetY));
                            momentumAnim3.restart();
                        }

                        ParallelAnimation {
                            id: momentumAnim3
                            NumberAnimation { id: animX3; target: dragCard3; property: "x"; duration: Theme.animNormal; easing.type: Easing.OutQuad }
                            NumberAnimation { id: animY3; target: dragCard3; property: "y"; duration: Theme.animNormal; easing.type: Easing.OutQuad }
                        }

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 4

                            Text {
                                text: Theme.iconMusic
                                font.family: Theme.fontIcon
                                font.pixelSize: 18
                                color: Theme.secondary
                                Layout.alignment: Qt.AlignHCenter
                            }
                            Text {
                                text: "media pill"
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                                font.weight: Font.Bold
                                color: Theme.on_surface
                                Layout.alignment: Qt.AlignHCenter
                            }
                            Text {
                                text: "(" + Math.round(dragCard3.x) + ", " + Math.round(dragCard3.y) + ")"
                                font.family: Theme.fontMono
                                font.pixelSize: 9
                                color: Theme.on_surface_variant
                                Layout.alignment: Qt.AlignHCenter
                            }
                        }

                        MouseArea {
                            id: dragArea3
                            anchors.fill: parent
                            drag.target: dragCard3
                            drag.axis: Drag.XAndYAxis
                            drag.minimumX: 0
                            drag.maximumX: canvasArea.width - dragCard3.width
                            drag.minimumY: 0
                            drag.maximumY: canvasArea.height - dragCard3.height
                            cursorShape: drag.active ? Qt.ClosedHandCursor : Qt.OpenHandCursor

                            onPressed: (mouse) => {
                                momentumAnim3.stop();
                                dragCard3.lastX = mouse.x;
                                dragCard3.lastY = mouse.y;
                                dragCard3.lastTime = Date.now();
                                dragCard3.velX = 0;
                                dragCard3.velY = 0;
                            }

                            onPositionChanged: (mouse) => {
                                let now = Date.now();
                                let dt = Math.max(1, now - dragCard3.lastTime);
                                dragCard3.velX = (mouse.x - dragCard3.lastX) / dt * 60;
                                dragCard3.velY = (mouse.y - dragCard3.lastY) / dt * 60;
                                dragCard3.lastX = mouse.x;
                                dragCard3.lastY = mouse.y;
                                dragCard3.lastTime = now;
                            }

                            onReleased: {
                                if (root.springMode) {
                                    dragCard3.animateTo(280, 10);
                                } else {
                                    dragCard3.animateTo(dragCard3.x + dragCard3.velX * 4, dragCard3.y + dragCard3.velY * 4);
                                }
                            }
                        }
                    }
                }

                // Active Curve & Tension Controls Footer
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
                                { id: "superSnappy", label: "snappy" },
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
                        text: "scoop: " + Settings.scoopRadius + "px • κ: " + Settings.scoopTension.toFixed(3)
                        font.family: Theme.fontMono
                        font.pixelSize: 10
                        color: Theme.on_surface_variant
                    }
                }
            }
        }
    }
}
