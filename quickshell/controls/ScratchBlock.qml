// ScratchBlock.qml - Tactile Scratch-like interlocking widget block
import QtQuick
import QtQuick.Layouts
import ".."
import "../services"

Item {
    id: root

    required property string blockId
    property string zoneId: "left"
    property int index: 0
    property bool isDragged: false
    property bool isVisibleInBar: true

    signal dragStarted(real mouseX, real mouseY)
    signal dragUpdated(real globalX, real globalY)
    signal dragFinished()
    signal dragCanceled()
    signal shiftZoneRequested(string targetZone)
    signal moveStepRequested(int delta)
    signal visibilityToggled()
    signal removeRequested()

    readonly property var blockInfo: PresetService.getBlockInfo(root.blockId)
    readonly property color blockColor: root.blockInfo?.color ?? "#4c97ff"
    readonly property string blockName: root.blockInfo?.name ?? root.blockId
    readonly property string blockIcon: root.blockInfo?.icon ?? "\uE9B0"
    readonly property string blockCategory: root.blockInfo?.category ?? "tools"

    implicitWidth: 320
    implicitHeight: 44
    height: 44

    // Puzzle notch Canvas
    Canvas {
        id: bgCanvas
        anchors.fill: parent
        antialiasing: true
        smooth: true

        readonly property color baseColor: root.blockColor
        readonly property bool isHovered: blockMouse.containsMouse && !root.isDragged
        readonly property real dpr: Math.max(1.0, Screen.devicePixelRatio || 1.0)

        Connections {
            target: root
            function onBlockColorChanged() { bgCanvas.requestPaint(); }
            function onIsDraggedChanged() { bgCanvas.requestPaint(); }
        }

        onPaint: {
            let ctx = getContext("2d");
            ctx.reset();
            ctx.clearRect(0, 0, width, height);

            let w = width;
            let h = height;
            let r = 7; // corner radius
            let notchX = 20;
            let notchW = 16;
            let notchD = 4; // notch depth

            ctx.fillStyle = root.isDragged ? Qt.rgba(baseColor.r, baseColor.g, baseColor.b, 0.45) : (isHovered ? Qt.lighter(baseColor, 1.08) : baseColor);

            // Interlocking Scratch puzzle shape:
            // Top has indent (notch going down into block)
            // Bottom has tab (notch sticking down out of block)
            ctx.beginPath();
            ctx.moveTo(r, 0);

            // Top edge with indent
            ctx.lineTo(notchX, 0);
            ctx.lineTo(notchX + 3, notchD);
            ctx.lineTo(notchX + notchW - 3, notchD);
            ctx.lineTo(notchX + notchW, 0);
            ctx.lineTo(w - r, 0);

            // Top right corner
            ctx.arcTo(w, 0, w, r, r);

            // Right edge
            ctx.lineTo(w, h - r);
            ctx.arcTo(w, h, w - r, h, r);

            // Bottom edge with tab (sticking down by notchD)
            ctx.lineTo(notchX + notchW, h);
            ctx.lineTo(notchX + notchW - 3, h + notchD);
            ctx.lineTo(notchX + 3, h + notchD);
            ctx.lineTo(notchX, h);
            ctx.lineTo(r, h);

            // Bottom left corner
            ctx.arcTo(0, h, 0, h - r, r);

            // Left edge
            ctx.lineTo(0, r);
            ctx.arcTo(0, 0, r, 0, r);

            ctx.closePath();
            ctx.fill();

            // Darker perimeter border
            ctx.lineWidth = 1.5;
            ctx.strokeStyle = Qt.darker(baseColor, 1.35);
            ctx.stroke();

            // Highlight bevel along top edge
            ctx.beginPath();
            ctx.moveTo(r, 1);
            ctx.lineTo(notchX, 1);
            ctx.moveTo(notchX + notchW, 1);
            ctx.lineTo(w - r, 1);
            ctx.lineWidth = 1.0;
            ctx.strokeStyle = Qt.rgba(1, 1, 1, 0.35);
            ctx.stroke();
        }
    }

    MouseArea {
        id: blockMouse
        anchors.fill: parent
        hoverEnabled: true
        preventStealing: pressedLocal || root.isDragged
        cursorShape: root.isDragged ? Qt.ClosedHandCursor : Qt.OpenHandCursor

        property real pressX: 0
        property real pressY: 0
        property bool pressedLocal: false

        onPressed: (mouse) => {
            if (mouse.button !== Qt.LeftButton) return;
            pressX = mouse.x;
            pressY = mouse.y;
            pressedLocal = true;
        }

        onPositionChanged: (mouse) => {
            if (!pressedLocal) return;
            if (!root.isDragged) {
                if (Math.hypot(mouse.x - pressX, mouse.y - pressY) > 5) {
                    root.dragStarted(mouse.x, mouse.y);
                }
            } else {
                let p = root.mapToItem(null, mouse.x, mouse.y);
                root.dragUpdated(p.x, p.y);
            }
        }

        onReleased: {
            if (root.isDragged) root.dragFinished();
            pressedLocal = false;
        }

        onCanceled: {
            if (root.isDragged) root.dragCanceled();
            pressedLocal = false;
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        spacing: 8

        // Drag grip
        Text {
            text: "\u283F"
            font.pixelSize: 13
            color: Qt.rgba(1, 1, 1, 0.75)
        }

        // Category icon badge
        Rectangle {
            Layout.preferredWidth: 24
            Layout.preferredHeight: 24
            radius: 5
            color: Qt.darker(root.blockColor, 1.25)

            Text {
                anchors.centerIn: parent
                text: root.blockIcon
                font.family: Theme?.fontIcon
                font.pixelSize: 11
                color: "#ffffff"
            }
        }

        // Title and category badge
        ColumnLayout {
            spacing: 0
            Layout.fillWidth: true

            Text {
                text: root.blockName
                font.family: Theme?.fontFamily
                font.pixelSize: 11
                font.weight: Font.Bold
                color: "#ffffff"
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            Text {
                text: root.blockCategory
                font.family: Theme?.fontFamily
                font.pixelSize: 8
                font.weight: Font.DemiBold
                color: Qt.rgba(1, 1, 1, 0.7)
            }
        }

        // Right side action buttons
        RowLayout {
            spacing: 3
            opacity: blockMouse.containsMouse ? 1.0 : 0.65

            // Shift Left
            Rectangle {
                visible: root.zoneId === "center" || root.zoneId === "right"
                Layout.preferredWidth: 20
                Layout.preferredHeight: 20
                radius: 4
                color: shiftLMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.25) : Qt.rgba(0, 0, 0, 0.2)

                Text {
                    anchors.centerIn: parent
                    text: "\u25C0"
                    font.pixelSize: 8
                    color: "#ffffff"
                }

                MouseArea {
                    id: shiftLMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.shiftZoneRequested(root.zoneId === "right" ? "center" : "left")
                }
            }

            // Move Up
            Rectangle {
                visible: root.index > 0
                Layout.preferredWidth: 20
                Layout.preferredHeight: 20
                radius: 4
                color: upMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.25) : Qt.rgba(0, 0, 0, 0.2)

                Text {
                    anchors.centerIn: parent
                    text: "\u25B2"
                    font.pixelSize: 8
                    color: "#ffffff"
                }

                MouseArea {
                    id: upMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.moveStepRequested(-1)
                }
            }

            // Move Down
            Rectangle {
                Layout.preferredWidth: 20
                Layout.preferredHeight: 20
                radius: 4
                color: downMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.25) : Qt.rgba(0, 0, 0, 0.2)

                Text {
                    anchors.centerIn: parent
                    text: "\u25BC"
                    font.pixelSize: 8
                    color: "#ffffff"
                }

                MouseArea {
                    id: downMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.moveStepRequested(1)
                }
            }

            // Shift Right
            Rectangle {
                visible: root.zoneId === "left" || root.zoneId === "center"
                Layout.preferredWidth: 20
                Layout.preferredHeight: 20
                radius: 4
                color: shiftRMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.25) : Qt.rgba(0, 0, 0, 0.2)

                Text {
                    anchors.centerIn: parent
                    text: "\u25B6"
                    font.pixelSize: 8
                    color: "#ffffff"
                }

                MouseArea {
                    id: shiftRMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.shiftZoneRequested(root.zoneId === "left" ? "center" : "right")
                }
            }

            // Eye visibility toggle
            Rectangle {
                Layout.preferredWidth: 22
                Layout.preferredHeight: 22
                radius: 4
                color: eyeMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.25) : (root.isVisibleInBar ? Qt.rgba(0, 0, 0, 0.2) : Qt.rgba(1, 0, 0, 0.35))

                Text {
                    anchors.centerIn: parent
                    text: root.isVisibleInBar ? (Theme?.iconEye ?? "\uE8F4") : (Theme?.iconEyeOff ?? "\uE8F5")
                    font.family: Theme?.fontIcon
                    font.pixelSize: 11
                    color: root.isVisibleInBar ? "#ffffff" : "#ff8888"
                }

                MouseArea {
                    id: eyeMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.visibilityToggled()
                }
            }

            // Remove / detach
            Rectangle {
                Layout.preferredWidth: 20
                Layout.preferredHeight: 20
                radius: 4
                color: rmMouse.containsMouse ? Qt.rgba(1, 0, 0, 0.45) : Qt.rgba(0, 0, 0, 0.2)

                Text {
                    anchors.centerIn: parent
                    text: "\u2715"
                    font.pixelSize: 9
                    color: rmMouse.containsMouse ? "#ffffff" : Qt.rgba(1, 1, 1, 0.8)
                }

                MouseArea {
                    id: rmMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.removeRequested()
                }
            }
        }
    }
}
