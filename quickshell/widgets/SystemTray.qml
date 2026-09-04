import QtQuick
import Quickshell
import ".."
import Quickshell.Widgets
import Quickshell.Services.SystemTray

Rectangle {
    id: trayRoot
    readonly property int itemCount: SystemTray.items.values ? SystemTray.items.values.length : 0
    visible: Settings.showSystemTray && itemCount > 0

    implicitWidth: Theme.isVertical ? Theme.barHeight - 8 : (trayRow.implicitWidth + 16)
    implicitHeight: Theme.isVertical ? (trayCol.implicitHeight + 16) : Theme.barHeight - 8
    radius: Theme.radiusPill
    color: Theme.pillBg
    border.color: Theme.pillBorder
    border.width: Theme.pillBorder === "transparent" ? 0 : 1

    Behavior on color { ColorAnimation { duration: Theme.animFast } }
    Behavior on border.color { ColorAnimation { duration: Theme.animFast } }

    Column {
        id: trayCol
        visible: Theme.isVertical
        anchors.centerIn: parent
        spacing: Theme.widgetSpacing

        Repeater {
            model: SystemTray.items

            Item {
                required property var modelData
                width: 20
                height: 20

                IconImage {
                    id: trayIconV
                    source: {
                        let ic = modelData.icon || "";
                        if (!ic) return "";
                        if (ic.startsWith("/") || ic.startsWith("file://") || ic.startsWith("image://")) return ic;
                        return Quickshell.iconPath(ic);
                    }
                    anchors.centerIn: parent
                    width: 16
                    height: 16
                }

                QsMenuAnchor {
                    id: menuAnchorV
                    menu: modelData.menu
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor

                    onClicked: (mouse) => {
                        if (mouse.button === Qt.RightButton || modelData.onlyMenu)
                            menuAnchorV.open();
                        else
                            modelData.activate();
                    }
                }
            }
        }
    }

    Row {
        id: trayRow
        visible: !Theme.isVertical
        anchors.centerIn: parent
        spacing: Theme.widgetSpacing

        Repeater {
            model: SystemTray.items

            Item {
                required property var modelData
                width: 20
                height: 20

                IconImage {
                    id: trayIconH
                    source: {
                        let ic = modelData.icon || "";
                        if (!ic) return "";
                        if (ic.startsWith("/") || ic.startsWith("file://") || ic.startsWith("image://")) return ic;
                        return Quickshell.iconPath(ic);
                    }
                    anchors.centerIn: parent
                    width: 16
                    height: 16
                }

                QsMenuAnchor {
                    id: menuAnchorH
                    menu: modelData.menu
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor

                    onClicked: (mouse) => {
                        if (mouse.button === Qt.RightButton || modelData.onlyMenu)
                            menuAnchorH.open();
                        else
                            modelData.activate();
                    }
                }
            }
        }
    }
}
