import QtQuick
import QtQuick.Layouts
import ".."
import Quickshell.Hyprland

Rectangle {
    id: wsContainer
    implicitWidth: Theme.isVertical ? Theme.barHeight - 8 : wsFlow.implicitWidth + 24
    implicitHeight: Theme.isVertical ? wsFlow.implicitHeight + 24 : Theme.barHeight - 8
    radius: Theme.radiusPill
    color: popup.open ? Theme.primary_overlay : (wsMouse.containsMouse ? Theme.pillHover : Theme.pillBg)
    border.color: Theme.pillBorder
    border.width: Theme.pillBorder === "transparent" ? 0 : 1

    Behavior on color { ColorAnimation { duration: Theme.animFast } }
    Behavior on border.color { ColorAnimation { duration: Theme.animFast } }

    Flow {
        id: wsFlow
        anchors.centerIn: parent
        spacing: 4
        flow: Theme.isVertical ? Flow.TopToBottom : Flow.LeftToRight

        Repeater {
            model: Hyprland.workspaces

            Rectangle {
                required property var modelData

                property bool isFocused: Hyprland.focusedWorkspace?.id === modelData.id
                property bool isActive: modelData.windows > 0

                width: Theme.isVertical ? 6 : (isFocused ? 18 : isActive ? 8 : 6)
                height: Theme.isVertical ? (isFocused ? 18 : isActive ? 8 : 6) : 6
                radius: Math.min(width, height) / 2
                color: isFocused ? Theme.primary
                     : isActive  ? Theme.on_surface_variant
                                 : Theme.outline_variant

                Behavior on width  { NumberAnimation { duration: Theme.animFast; easing.type: Theme.animEasing } }
                Behavior on height { NumberAnimation { duration: Theme.animFast; easing.type: Theme.animEasing } }
                Behavior on color  { ColorAnimation  { duration: Theme.animFast; easing.type: Theme.animEasing } }
            }
        }
    }

    MouseArea {
        id: wsMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        onClicked: (mouse) => {
            popup.targetRelativeX = wsContainer.mapToItem(null, 0, 0).x + (wsContainer.width / 2)
            popup.open = !popup.open
        }

        onWheel: (wheel) => {
            if (wheel.angleDelta.y < 0) {
                Hyprland.dispatch('hl.dsp.focus({ workspace = "m+1" })')
            } else if (wheel.angleDelta.y > 0) {
                Hyprland.dispatch('hl.dsp.focus({ workspace = "m-1" })')
            }
        }
    }

    PopupPanel {
        id: popup
        cardWidth: 440
        cardHeight: 420
        targetRelativeX: wsContainer.mapToItem(null, 0, 0).x + (wsContainer.width / 2)

        content: ColumnLayout {
            anchors.fill: parent
            spacing: Theme.widgetSpacing

            // Header with the question
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        text: "which workspace would you like to go?"
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeMd
                        font.weight: Font.Bold
                        color: Theme.primary
                        Layout.fillWidth: true
                    }

                    Text {
                        text: "active workspace: " + (Hyprland.focusedWorkspace?.id ?? 1)
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeXs
                        color: Theme.on_surface_variant
                    }
                }

                Text {
                    text: Theme.iconWorkspaces
                    font.family: Theme.fontIcon
                    font.pixelSize: Theme.fontSizeMd
                    color: Theme.primary
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Theme.widgetBorder
            }

            // Grid of 10 workspaces (2 columns x 5 rows)
            GridLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                columns: 2
                columnSpacing: 8
                rowSpacing: 6

                Repeater {
                    model: 10

                    delegate: Rectangle {
                        required property int index
                        readonly property int wsId: index + 1
                        readonly property var wsObj: {
                            let list = Hyprland.workspaces.values || [];
                            for (let i = 0; i < list.length; i++) {
                                if (list[i].id === wsId) return list[i];
                            }
                            return null;
                        }
                        readonly property bool isCurrent: (Hyprland.focusedWorkspace?.id ?? 1) === wsId
                        readonly property bool hasWindows: (wsObj?.windows ?? 0) > 0
                        readonly property int winCount: wsObj?.windows ?? 0

                        Layout.fillWidth: true
                        Layout.preferredHeight: 44
                        radius: Theme.radiusMd
                        color: isCurrent ? Theme.primary_overlay : (cardMouse.containsMouse ? Theme.surface_container_highest : Theme.surface_container_high)
                        border.color: isCurrent ? Theme.primary : "transparent"
                        border.width: 1

                        Behavior on color { ColorAnimation { duration: Theme.animFast } }
                        Behavior on border.color { ColorAnimation { duration: Theme.animFast } }

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 10

                            Rectangle {
                                Layout.preferredWidth: 26
                                Layout.preferredHeight: 26
                                radius: Theme.radiusSm
                                color: isCurrent ? Theme.primary : (hasWindows ? Theme.surface_variant : Theme.surface_container)

                                Text {
                                    text: wsId
                                    font.family: Theme.fontMono
                                    font.pixelSize: Theme.fontSizeSm
                                    font.weight: Font.Bold
                                    color: isCurrent ? Theme.on_primary : Theme.on_surface
                                    anchors.centerIn: parent
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 1

                                Text {
                                    text: "workspace " + wsId
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSizeSm
                                    font.weight: Font.Medium
                                    color: isCurrent ? Theme.primary : Theme.on_surface
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }

                                Text {
                                    text: isCurrent ? "currently active" : (hasWindows ? (winCount + (winCount === 1 ? " window" : " windows")) : "empty")
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSizeXs
                                    color: isCurrent ? Theme.primary : Theme.on_surface_variant
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                            }

                            Rectangle {
                                Layout.preferredWidth: 22
                                Layout.preferredHeight: 20
                                radius: Theme.radiusSm
                                color: isCurrent ? Theme.primary : "transparent"

                                Text {
                                    text: isCurrent ? Theme.iconCheck : "↵"
                                    font.family: Theme.fontMono
                                    font.pixelSize: 10
                                    font.weight: Font.Bold
                                    color: isCurrent ? Theme.on_primary : Theme.on_surface_variant
                                    anchors.centerIn: parent
                                }
                            }
                        }

                        MouseArea {
                            id: cardMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                Hyprland.dispatch('hl.dsp.focus({ workspace = "' + wsId + '" })');
                                popup.open = false;
                            }
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Theme.widgetBorder
            }

            // Footer shortcuts & actions
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Rectangle {
                    Layout.preferredHeight: 28
                    Layout.fillWidth: true
                    radius: Theme.radiusSm
                    color: specialMouse.containsMouse ? Theme.primary_overlay : Theme.surface_container_high

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 4
                        Text {
                            text: "󰒝"
                            font.family: Theme.fontMono
                            font.pixelSize: Theme.fontSizeXs
                            color: Theme.primary
                        }
                        Text {
                            text: "toggle scratchpad"
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeXs
                            font.weight: Font.Medium
                            color: Theme.on_surface
                        }
                    }

                    MouseArea {
                        id: specialMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            Hyprland.dispatch('hl.dsp.workspace.toggle_special("scratchpad")');
                            popup.open = false;
                        }
                    }
                }

                Text {
                    text: "scroll to switch"
                    font.family: Theme.fontMono
                    font.pixelSize: 9
                    color: Theme.on_surface_variant
                    opacity: 0.8
                }
            }
        }
    }
}
