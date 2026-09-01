import QtQuick
import ".."
import Quickshell
import Quickshell.Io

Rectangle {
    id: root
    implicitWidth: Theme.isVertical ? Theme.barHeight - 8 : cafRow.implicitWidth + 24
    implicitHeight: Theme.barHeight - 8
    radius: Theme.radiusPill
    color: root.active ? Theme.primary_overlay : (cafMouse.containsMouse ? Theme.pillHover : Theme.pillBg)
    border.color: Theme.pillBorder
    border.width: Theme.pillBorder === "transparent" ? 0 : 1

    Behavior on color { ColorAnimation { duration: Theme.animFast } }
    Behavior on border.color { ColorAnimation { duration: Theme.animFast } }

    readonly property string scriptPath: "/home/ashley/.config/quickshell/scripts/caffeine.sh"
    property bool active: !IdleService.enabled

    function toggleInhibit() {
        IdleService.enabled = !IdleService.enabled;
        active = !IdleService.enabled;
        Quickshell.execDetached([scriptPath, active ? "start" : "stop"]);
    }

    Row {
        id: cafRow
        anchors.centerIn: parent
        spacing: 4

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Theme.iconCoffee
            font.family: Theme.fontIcon
            font.pixelSize: Theme.fontSizeMd
            color: root.active ? Theme.primary : Theme.on_surface
        }
    }

    MouseArea {
        id: cafMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggleInhibit()
    }
}
