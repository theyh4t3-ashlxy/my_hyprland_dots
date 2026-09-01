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
    color: popup.open ? Theme.error_overlay : (pwrMouse.containsMouse ? Theme.pillHover : Theme.pillBg)
    border.color: Theme.pillBorder
    border.width: Theme.pillBorder === "transparent" ? 0 : 1

    Behavior on color { ColorAnimation { duration: Theme.animFast } }
    Behavior on border.color { ColorAnimation { duration: Theme.animFast } }

    Row {
        id: pwrRow
        anchors.centerIn: parent
        spacing: 4

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Theme.iconPower
            font.family: Theme.fontIcon
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
        cardWidth: 440
        cardHeight: 330
        targetRelativeX: root.mapToItem(null, 0, 0).x + (root.width / 2)

        property string pendingAction: ""
        property int confirmCountdown: 0

        Timer {
            id: confirmTimer
            interval: 1000
            repeat: true
            onTriggered: {
                if (popup.confirmCountdown > 1) {
                    popup.confirmCountdown -= 1;
                } else {
                    popup.pendingAction = "";
                    popup.confirmCountdown = 0;
                    confirmTimer.stop();
                }
            }
        }

        function triggerAction(actionKey, needsConfirm) {
            if (needsConfirm) {
                if (popup.pendingAction === actionKey) {
                    // confirmed! execute now
                    confirmTimer.stop();
                    popup.pendingAction = "";
                    popup.confirmCountdown = 0;
                    popup.open = false;
                    Quickshell.execDetached(["/home/ashley/.config/quickshell/scripts/session.sh", actionKey]);
                } else {
                    popup.pendingAction = actionKey;
                    popup.confirmCountdown = 3;
                    confirmTimer.restart();
                }
            } else {
                popup.open = false;
                Quickshell.execDetached(["/home/ashley/.config/quickshell/scripts/session.sh", actionKey]);
            }
        }

        content: ColumnLayout {
            anchors.fill: parent
            spacing: Theme.widgetSpacing

            // User Profile & System Header
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Rectangle {
                    Layout.preferredWidth: 38
                    Layout.preferredHeight: 38
                    radius: Theme.radiusPill
                    color: Theme.surface_container_highest

                    Text {
                        anchors.centerIn: parent
                        text: Theme.kaoCool
                        font.family: Theme.fontMono
                        font.pixelSize: Theme.fontSizeSm
                        color: Theme.primary
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        text: "session & power"
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeLg
                        font.weight: Font.Bold
                        color: Theme.on_surface
                    }

                    Text {
                        text: Settings.unhingedFlavor ? (Theme.kaoChaos + " choose your destiny") : "manage current desktop session"
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeXs
                        color: Theme.on_surface_variant
                    }
                }

                IconButton {
                    icon: Theme.iconClose
                    iconSize: Theme.fontSizeSm
                    tooltip: "close menu"
                    onClicked: popup.open = false
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Theme.widgetBorder
            }

            // Power Actions Grid (Lock, Suspend, Logout, Reboot, Shutdown)
            GridLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                columns: 3
                rowSpacing: 10
                columnSpacing: 10

                // Lock Screen Card
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: Theme.radiusMd
                    color: lockMouse.containsMouse ? Theme.surface_container_highest : Theme.surface_container_high
                    border.color: lockMouse.containsMouse ? Theme.primary : "transparent"
                    border.width: 1

                    Behavior on color { ColorAnimation { duration: Theme.animFast } }

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 4

                        Text {
                            text: Theme.iconLock
                            font.family: Theme.fontIcon
                            font.pixelSize: 22
                            color: Theme.primary
                            Layout.alignment: Qt.AlignHCenter
                        }

                        Text {
                            text: "lock"
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeXs
                            font.weight: Font.Bold
                            color: Theme.on_surface
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }

                    MouseArea {
                        id: lockMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: popup.triggerAction("lock", false)
                    }
                }

                // Suspend / Sleep Card
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: Theme.radiusMd
                    color: sleepMouse.containsMouse ? Theme.surface_container_highest : Theme.surface_container_high
                    border.color: sleepMouse.containsMouse ? Theme.primary : "transparent"
                    border.width: 1

                    Behavior on color { ColorAnimation { duration: Theme.animFast } }

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 4

                        Text {
                            text: Theme.iconSuspend
                            font.family: Theme.fontIcon
                            font.pixelSize: 22
                            color: Theme.primary
                            Layout.alignment: Qt.AlignHCenter
                        }

                        Text {
                            text: "sleep"
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeXs
                            font.weight: Font.Bold
                            color: Theme.on_surface
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }

                    MouseArea {
                        id: sleepMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: popup.triggerAction("suspend", false)
                    }
                }

                // Log Out Card
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: Theme.radiusMd
                    color: logoutMouse.containsMouse ? Theme.surface_container_highest : Theme.surface_container_high
                    border.color: logoutMouse.containsMouse ? Theme.warn : "transparent"
                    border.width: 1

                    Behavior on color { ColorAnimation { duration: Theme.animFast } }

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 4

                        Text {
                            text: Theme.iconLogout
                            font.family: Theme.fontIcon
                            font.pixelSize: 22
                            color: Theme.warn
                            Layout.alignment: Qt.AlignHCenter
                        }

                        Text {
                            text: "log out"
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeXs
                            font.weight: Font.Bold
                            color: Theme.on_surface
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }

                    MouseArea {
                        id: logoutMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: popup.triggerAction("logout", false)
                    }
                }

                // Reboot Card with Confirmation
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: Theme.radiusMd
                    readonly property bool isConfirming: popup.pendingAction === "reboot"
                    color: isConfirming ? Theme.warn_container : (rebootMouse.containsMouse ? Theme.surface_container_highest : Theme.surface_container_high)
                    border.color: isConfirming ? Theme.warn : (rebootMouse.containsMouse ? Theme.primary : "transparent")
                    border.width: 1

                    Behavior on color { ColorAnimation { duration: Theme.animFast } }

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 4

                        Text {
                            text: Theme.iconReboot
                            font.family: Theme.fontIcon
                            font.pixelSize: 22
                            color: parent.parent.isConfirming ? Theme.on_warn_container : Theme.primary
                            Layout.alignment: Qt.AlignHCenter
                        }

                        Text {
                            text: parent.parent.isConfirming ? ("confirm (" + popup.confirmCountdown + "s)") : "restart"
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeXs
                            font.weight: Font.Bold
                            color: parent.parent.isConfirming ? Theme.on_warn_container : Theme.on_surface
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }

                    MouseArea {
                        id: rebootMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: popup.triggerAction("reboot", true)
                    }
                }

                // Power Off Card with Confirmation
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.columnSpan: 2
                    radius: Theme.radiusMd
                    readonly property bool isConfirming: popup.pendingAction === "poweroff"
                    color: isConfirming ? Theme.error_container : (powerMouse.containsMouse ? Theme.error_overlay : Theme.surface_container_high)
                    border.color: isConfirming ? Theme.error : (powerMouse.containsMouse ? Theme.error : "transparent")
                    border.width: 1

                    Behavior on color { ColorAnimation { duration: Theme.animFast } }

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 10

                        Text {
                            text: Theme.iconPower
                            font.family: Theme.fontIcon
                            font.pixelSize: 24
                            color: Theme.error
                        }

                        ColumnLayout {
                            spacing: 2
                            Text {
                                text: parent.parent.parent.isConfirming ? ("click to confirm (" + popup.confirmCountdown + "s)") : "shut down"
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeSm
                                font.weight: Font.Bold
                                color: parent.parent.parent.isConfirming ? Theme.on_error_container : Theme.on_surface
                            }
                            Text {
                                text: Settings.unhingedFlavor ? (Theme.kaoSleepy + " goodnight") : "power off device"
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                                color: parent.parent.parent.isConfirming ? Theme.on_error_container : Theme.on_surface_variant
                            }
                        }
                    }

                    MouseArea {
                        id: powerMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: popup.triggerAction("poweroff", true)
                    }
                }
            }
        }
    }
}
