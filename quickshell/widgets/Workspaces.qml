import QtQuick
import ".."
import Quickshell.Hyprland

Rectangle {
    id: wsContainer
    implicitWidth: Theme.isVertical ? Theme.barHeight - 8 : wsFlow.implicitWidth + 24
    implicitHeight: Theme.isVertical ? wsFlow.implicitHeight + 24 : Theme.barHeight - 8
    radius: Theme.radiusPill
    color: wsMouse.containsMouse ? Theme.surface_container_highest : Theme.surface_container_high

    Behavior on color { ColorAnimation { duration: Theme.animFast } }

    Flow {
        id: wsFlow
        anchors.centerIn: parent
        spacing: 4
        // dots go sideways or stack depending on bar orientation
        flow: Theme.isVertical ? Flow.TopToBottom : Flow.LeftToRight

        Repeater {
            model: Hyprland.workspaces

            Rectangle {
                // lil pill guys
                required property var modelData

                property bool isFocused: Hyprland.focusedWorkspace?.id === modelData.id
                property bool isActive: modelData.windows > 0

                // swap dimensions when vertical so dots stack naturally
                width: Theme.isVertical ? 6 : (isFocused ? 18 : isActive ? 8 : 6)
                height: Theme.isVertical ? (isFocused ? 18 : isActive ? 8 : 6) : 6
                radius: Math.min(width, height) / 2
                color: isFocused ? Theme.primary
                     : isActive  ? Theme.on_surface_variant
                                 : Theme.outline_variant

                Behavior on width  { NumberAnimation { duration: Theme.animFast; easing.type: Theme.animEasing } }
                Behavior on height { NumberAnimation { duration: Theme.animFast; easing.type: Theme.animEasing } }
                Behavior on color  { ColorAnimation  { duration: Theme.animFast; easing.type: Theme.animEasing } }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: modelData.activate()
                }
            }
        }
    }

    MouseArea {
        id: wsMouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton

        onWheel: (wheel) => {
            if (wheel.angleDelta.y < 0) {
                Hyprland.dispatch("workspace m+1")
            } else if (wheel.angleDelta.y > 0) {
                Hyprland.dispatch("workspace m-1")
            }
        }
    }
}
