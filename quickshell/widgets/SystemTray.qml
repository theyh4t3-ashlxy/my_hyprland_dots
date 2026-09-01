import QtQuick
import Quickshell
import ".."
import Quickshell.Widgets
import Quickshell.Services.SystemTray

Rectangle {
    id: trayRoot
    readonly property int itemCount: SystemTray.items.values ? SystemTray.items.values.length : 0
    visible: Settings.showSystemTray && itemCount > 0

    implicitWidth: Theme.isVertical ? Theme.barHeight - 8 : trayFlow.implicitWidth + 16
    implicitHeight: Theme.isVertical ? trayFlow.implicitHeight + 16 : Theme.barHeight - 8
    radius: Theme.radiusPill
    color: Theme.pillBg
    border.color: Theme.pillBorder
    border.width: Theme.pillBorder === "transparent" ? 0 : 1

    Behavior on color { ColorAnimation { duration: Theme.animFast } }
    Behavior on border.color { ColorAnimation { duration: Theme.animFast } }

    Flow {
        id: trayFlow
        anchors.centerIn: parent
        spacing: Theme.widgetSpacing
        flow: Theme.isVertical ? Flow.TopToBottom : Flow.LeftToRight

        Repeater {
            model: SystemTray.items

            Item {
                required property var modelData
                width: 20
                height: 20

                IconImage {
                    id: trayIcon
                    source: modelData.icon || ""
                    anchors.centerIn: parent
                    width: 16
                    height: 16
                }

                QsMenuAnchor {
                    id: menuAnchor
                    menu: modelData.menu
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor

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
