import QtQuick
import QtQuick.Layouts
import ".."
import Quickshell
import Quickshell.Wayland

Rectangle {
    id: root
    implicitWidth: Theme.isVertical ? Theme.barHeight - 8 : pwrRow.implicitWidth + 24
    implicitHeight: Theme.barHeight - 8
    radius: Theme.radiusPill
    color: popup.open ? Theme.error_overlay : (pwrMouse.containsMouse ? Theme.surface_container_highest : Theme.surface_container_high)

    Behavior on color { ColorAnimation { duration: Theme.animFast } }

    Row {
        id: pwrRow
        anchors.centerIn: parent
        spacing: 4

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Theme.iconPower
            font.family: Theme.fontMono
            font.pixelSize: Theme.fontSizeMd
            color: popup.open ? Theme.error : Theme.on_surface
        }
    }

    MouseArea {
        id: pwrMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            popup.targetRelativeX = root.mapToItem(null, 0, 0).x + (root.width / 2)
            popup.open = !popup.open
        }
    }

    PopupPanel {
        id: popup
        panelHeight: 180
        panelWidth: 360
        
        content: ColumnLayout {
            anchors.fill: parent
            spacing: Theme.widgetSpacing

            Text {
                text: Settings.unhingedFlavor ? Theme.kaoChaos + " session control" : "power menu"
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeLg
                font.weight: Font.Bold
                color: Theme.on_surface
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: 8
                Layout.bottomMargin: 8
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 12
                Layout.alignment: Qt.AlignHCenter
                
                // shutdown
                IconButton {
                    icon: Theme.iconPower
                    iconSize: 28
                    tooltip: "Power Off (goodnight)"
                    Layout.preferredWidth: 68
                    Layout.preferredHeight: 64
                    onClicked: {
                        Quickshell.execDetached(["/home/ashley/.config/quickshell/scripts/session.sh", "poweroff"])
                    }
                }
                
                // reboot
                IconButton {
                    icon: Theme.iconReboot
                    iconSize: 28
                    tooltip: "Reboot (turning it off and on again)"
                    Layout.preferredWidth: 68
                    Layout.preferredHeight: 64
                    onClicked: {
                        Quickshell.execDetached(["/home/ashley/.config/quickshell/scripts/session.sh", "reboot"])
                    }
                }
                
                // suspend
                IconButton {
                    icon: Theme.iconSuspend
                    iconSize: 28
                    tooltip: "Suspend (" + Theme.kaoSleepy + ")"
                    Layout.preferredWidth: 68
                    Layout.preferredHeight: 64
                    onClicked: {
                        Quickshell.execDetached(["/home/ashley/.config/quickshell/scripts/session.sh", "suspend"])
                        popup.open = false
                    }
                }
                
                // logout
                IconButton {
                    icon: Theme.iconLogout
                    iconSize: 28
                    tooltip: "Log Out (abandon ship)"
                    Layout.preferredWidth: 68
                    Layout.preferredHeight: 64
                    onClicked: {
                        Quickshell.execDetached(["/home/ashley/.config/quickshell/scripts/session.sh", "logout"])
                    }
                }
            }
        }
    }
}
