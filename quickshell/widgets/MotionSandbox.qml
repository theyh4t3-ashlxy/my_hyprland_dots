import QtQuick
import QtQuick.Layouts
import ".."
import "../corners"
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root

    property bool open: false
    property string dockPosition: "bottom" // "bottom" or "right"
    readonly property bool isBottom: dockPosition === "bottom"

    anchors {
        bottom: true
        right: !root.isBottom
        horizontalCenter: root.isBottom
    }

    margins {
        bottom: root.isBottom ? 0 : 32
        right: root.isBottom ? 0 : 0
    }

    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell:motionsandbox"

    visible: open
    implicitWidth: root.isBottom ? 520 : 320
    implicitHeight: root.isBottom ? 260 : 480

    // Dual Concave Joint Welds into Screen Edge
    Item {
        anchors.fill: parent

        // Left / Top scoop
        ConcaveCorner {
            x: root.isBottom ? 0 : 0
            y: root.isBottom ? (parent.height - Theme.scoopRadiusY) : 0
            radiusX: Theme.scoopRadiusX
            radiusY: Theme.scoopRadiusY
            fillColor: Theme.surface_container_low
            flipX: true
            flipY: !root.isBottom
            visible: Settings.scoopRadius > 0
        }

        // Right / Bottom scoop
        ConcaveCorner {
            x: root.isBottom ? (parent.width - Theme.scoopRadiusX) : 0
            y: root.isBottom ? (parent.height - Theme.scoopRadiusY) : (parent.height - Theme.scoopRadiusY)
            radiusX: Theme.scoopRadiusX
            radiusY: Theme.scoopRadiusY
            fillColor: Theme.surface_container_low
            flipX: false
            flipY: !root.isBottom
            visible: Settings.scoopRadius > 0
        }

        // Card body
        Rectangle {
            id: body
            anchors.fill: parent
            anchors.leftMargin: root.isBottom ? Theme.scoopRadiusX : 0
            anchors.rightMargin: root.isBottom ? Theme.scoopRadiusX : 0
            anchors.topMargin: root.isBottom ? 0 : Theme.scoopRadiusY
            anchors.bottomMargin: root.isBottom ? 0 : Theme.scoopRadiusY
            radius: Theme.radiusMd
            color: Theme.surface_container_low
            border.color: Theme.widgetBorder
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 10

                // Header
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

                    // Dock position switcher
                    Rectangle {
                        width: 72
                        height: 24
                        radius: Theme.radiusPill
                        color: Theme.surface_container_high

                        Text {
                            anchors.centerIn: parent
                            text: root.isBottom ? "bottom " : "right "
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                            font.weight: Font.Medium
                            color: Theme.on_surface
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.dockPosition = root.isBottom ? "right" : "bottom"
                        }
                    }

                    IconButton {
                        icon: Theme.iconClose
                        iconSize: Theme.fontSizeXs
                        tooltip: "close sandbox"
                        onClicked: root.open = false
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Theme.widgetBorder
                }

                // Interactive Physics Playground (Draggable Cards)
                Text {
                    text: "drag & flick cards to test hyprland inertia physics"
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

                        property real targetX: 0
                        property real targetY: 0

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

                    // Curve Profile Quick Switcher
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

                        // Live Tension & Radius info badge
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
