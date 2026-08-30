import QtQuick
import ".."
import Quickshell
import Quickshell.Io

Rectangle {
    id: root
    implicitWidth: Theme.isVertical ? Theme.barHeight - 8 : cafRow.implicitWidth + 24
    implicitHeight: Theme.barHeight - 8
    radius: Theme.radiusPill
    color: root.active ? Theme.primary_overlay : (cafMouse.containsMouse ? Theme.surface_container_highest : Theme.surface_container_high)

    Behavior on color { ColorAnimation { duration: Theme.animFast } }

    readonly property string scriptPath: "/home/ashley/.config/quickshell/scripts/caffeine.sh"
    property bool active: false

    property FileView pidFile: FileView {
        path: "/tmp/qs_caffeine.pid"
        watchChanges: true
        printErrors: false
        onFileChanged: {
            reload();
            let pid = text().trim();
            root.active = pid.length > 0;
        }
    }

    Component.onCompleted: {
        pidFile.reload();
        let pid = pidFile.text().trim();
        root.active = pid.length > 0;
    }

    function toggleInhibit() {
        active = !active
        Quickshell.execDetached([scriptPath, active ? "start" : "stop"])
    }

    Row {
        id: cafRow
        anchors.centerIn: parent
        spacing: 4

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Theme.iconCoffee
            font.family: Theme.fontMono
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
