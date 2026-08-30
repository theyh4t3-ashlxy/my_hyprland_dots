import QtQuick
import Quickshell
import ".."
import Quickshell.Widgets
import Quickshell.Services.SystemTray

Rectangle {
    implicitWidth: Theme.isVertical ? Theme.barHeight - 8 : trayRow.implicitWidth + 16
    implicitHeight: Theme.barHeight - 8
    radius: Theme.radiusPill
    color: Theme.surface_container_high

    Row {
        id: trayRow
        anchors.centerIn: parent
        spacing: Theme.widgetSpacing

    Repeater {
        model: SystemTray.items

        Item {
            // stowaways in the tray
            required property var modelData
            width: Theme.fontSizeMd + 6
            height: Theme.fontSizeMd + 6

            Image {
                source: modelData.icon
                sourceSize: Qt.size(24, 24)
                anchors.fill: parent
                anchors.margins: 2
                fillMode: Image.PreserveAspectFit
                asynchronous: true
            }

            QsMenuAnchor {
                id: menuAnchor
                menu: modelData.menu
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: (mouse) => {
                    if (mouse.button === Qt.RightButton || modelData.onlyMenu)
                        menuAnchor.open();
                    else
                        modelData.activate();
                }
            }
        }
    }
}
}
