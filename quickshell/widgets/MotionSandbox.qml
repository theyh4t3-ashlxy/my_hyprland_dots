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
    implicitWidth: root.isVertical ? 340 : 540
    implicitHeight: root.isVertical ? 480 : 270

    // Dual Concave Joint Welds into Screen Edge
    Item {
        anchors.fill: parent

        // Top edge weld scoops
        ConcaveCorner {
            x: 0
            y: 0
            radiusX: Theme.scoopRadiusX
            radiusY: Theme.scoopRadiusY
            fillColor: Theme.surface_container_low
            flipX: true
            flipY: false
            visible: root.isTop && Settings.scoopRadius > 0
        }
        ConcaveCorner {
            x: parent.width - Theme.scoopRadiusX
            y: 0
            radiusX: Theme.scoopRadiusX
            radiusY: Theme.scoopRadiusY
            fillColor: Theme.surface_container_low
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
            fillColor: Theme.surface_container_low
            flipX: true
            flipY: true
            visible: root.isBottom && Settings.scoopRadius > 0
        }
        ConcaveCorner {
            x: parent.width - Theme.scoopRadiusX
            y: parent.height - Theme.scoopRadiusY
            radiusX: Theme.scoopRadiusX
            radiusY: Theme.scoopRadiusY
            fillColor: Theme.surface_container_low
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
            fillColor: Theme.surface_container_low
            flipX: false
            flipY: true
            visible: root.isLeft && Settings.scoopRadius > 0
        }
        ConcaveCorner {
            x: 0
            y: parent.height - Theme.scoopRadiusY
            radiusX: Theme.scoopRadiusX
            radiusY: Theme.scoopRadiusY
            fillColor: Theme.surface_container_low
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
            fillColor: Theme.surface_container_low
            flipX: true
            flipY: true
            visible: root.isRight && Settings.scoopRadius > 0
        }
        ConcaveCorner {
            x: parent.width - Theme.scoopRadiusX
            y: parent.height - Theme.scoopRadiusY
            radiusX: Theme.scoopRadiusX
            radiusY: Theme.scoopRadiusY
            fillColor: Theme.surface_container_low
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
            color: Theme.surface_container_low
            border.color: Theme.widgetBorder
            border.width: 1

            topLeftRadius: (root.isTop || root.isLeft) ? 0 : Theme.radiusMd
            topRightRadius: (root.isTop || root.isRight) ? 0 : Theme.radiusMd
            bottomLeftRadius: (root.isBottom || root.isLeft) ? 0 : Theme.radiusMd
            bottomRightRadius: (root.isBottom || root.isRight) ? 0 : Theme.radiusMd

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 10

                // Header & 4-Way Dock Switcher
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Text {
                        text: Theme.kaoVibe + " motion & corner sandbox"
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeSm
                        font.weight: Font.Bold
                        color: Theme.primary
                        Layout.fillWidth: true
                    }

                    // 4-Way Dock Position Selector
                    RowLayout {
                        spacing: 3

                        Repeater {
                            model: [
                                { pos: "bottom", icon: "" },
                                { pos: "top", icon: "" },
                                { pos: "left", icon: "" },
                                { pos: "right", icon: "" }
                            ]

                            delegate: Rectangle {
                                required property var modelData
                                width: 28
                                height: 24
                                radius: Theme.radiusSm
                                color: root.dockPosition === modelData.pos ? Theme.primary : Theme.surface_container_high

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.icon
                                    font.family: Theme.fontMono
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

                // Interactive Physics Playground (Draggable Cards)
                Text {
                    text: "drag & fling cards with live hyprland inertia physics"
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                    color: Theme.on_surface_variant
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 12

                    // Draggable Card 1
                    Rectangle {
                        id: dragCard1
                        Layout.preferredWidth: 120
                        Layout.fillHeight: true
                        radius: Theme.radiusMd
                        color: Theme.surface_container_highest
                        border.color: dragArea1.drag.active ? Theme.primary : Theme.widgetBorder
                        border.width: 1

                        Behavior on x {
                            enabled: !dragArea1.drag.active
                            NumberAnimation { duration: Theme.animNormal; easing.type: Theme.animEasing }
                        }
                        Behavior on y {
                            enabled: !dragArea1.drag.active
                            NumberAnimation { duration: Theme.animNormal; easing.type: Theme.animEasing }
                        }

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 4

                            Text {
                                text: Theme.kaoJam
                                font.family: Theme.fontMono
                                font.pixelSize: 18
                                color: Theme.primary
                                Layout.alignment: Qt.AlignHCenter
                            }
                            Text {
                                text: "drag me!"
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                                font.weight: Font.Bold
                                color: Theme.on_surface
                                Layout.alignment: Qt.AlignHCenter
                            }
                        }

                        MouseArea {
                            id: dragArea1
                            anchors.fill: parent
                            drag.target: dragCard1
                            drag.axis: Drag.XAndYAxis
                            cursorShape: drag.active ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                            onReleased: {
                                dragCard1.x = 0;
                                dragCard1.y = 0;
                            }
                        }
                    }

                    // Draggable Card 2
                    Rectangle {
                        id: dragCard2
                        Layout.preferredWidth: 120
                        Layout.fillHeight: true
                        radius: Theme.radiusMd
                        color: Theme.surface_container_highest
                        border.color: dragArea2.drag.active ? Theme.warn : Theme.widgetBorder
                        border.width: 1

                        Behavior on x {
                            enabled: !dragArea2.drag.active
                            NumberAnimation { duration: Theme.animSlow; easing.type: Theme.animEasing }
                        }
                        Behavior on y {
                            enabled: !dragArea2.drag.active
                            NumberAnimation { duration: Theme.animSlow; easing.type: Theme.animEasing }
                        }

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 4

                            Text {
                                text: Theme.kaoDJ
                                font.family: Theme.fontMono
                                font.pixelSize: 18
                                color: Theme.warn
                                Layout.alignment: Qt.AlignHCenter
                            }
                            Text {
                                text: "spring toss"
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                                font.weight: Font.Bold
                                color: Theme.on_surface
                                Layout.alignment: Qt.AlignHCenter
                            }
                        }

                        MouseArea {
                            id: dragArea2
                            anchors.fill: parent
                            drag.target: dragCard2
                            drag.axis: Drag.XAndYAxis
                            cursorShape: drag.active ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                            onReleased: {
                                dragCard2.x = 0;
                                dragCard2.y = 0;
                            }
                        }
                    }

                    // Active Motion Curve Switcher & Scoop Metric Badge
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 6

                        Text {
                            text: "active curve: " + Settings.animSpeed
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                            font.weight: Font.Bold
                            color: Theme.primary
                        }

                        RowLayout {
                            Layout.fillWidth: true
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
                                    Layout.fillWidth: true
                                    height: 26
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

                        Rectangle {
                            Layout.fillWidth: true
                            height: 28
                            radius: Theme.radiusSm
                            color: Theme.surface_container_high

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 8

                                Text {
                                    text: "scoop: " + Settings.scoopRadius + "px • κ: " + Settings.scoopTension.toFixed(3)
                                    font.family: Theme.fontMono
                                    font.pixelSize: 10
                                    color: Theme.on_surface
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
