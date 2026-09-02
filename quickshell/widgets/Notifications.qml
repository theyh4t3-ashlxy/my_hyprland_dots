import QtQuick
import QtQuick.Layouts
import ".."
import Quickshell
import Quickshell.Services.Notifications

Rectangle {
    id: root
    implicitWidth: Theme.isVertical ? Theme.barHeight - 8 : notifRow.implicitWidth + 24
    implicitHeight: Theme.barHeight - 8
    radius: Theme.radiusPill
    color: popup.open ? Theme.primary_overlay : (notifMouse.containsMouse ? Theme.pillHover : Theme.pillBg)
    border.color: Settings.dnd ? Theme.tertiary : Theme.pillBorder
    border.width: (Settings.dnd || Theme.pillBorder !== "transparent") ? 1 : 0

    Behavior on color { ColorAnimation { duration: Theme.animFast } }
    Behavior on border.color { ColorAnimation { duration: Theme.animFast } }

    readonly property int notifCount: NotificationService.trackedNotifications.values?.length ?? 0

    Row {
        id: notifRow
        anchors.centerIn: parent
        spacing: 4

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Settings.dnd ? Theme.iconBellOff : (root.notifCount > 0 ? Theme.iconBell : Theme.iconBellOutline)
            font.family: Theme.fontIcon
            font.pixelSize: Theme.fontSizeMd
            color: Settings.dnd ? Theme.tertiary : (root.notifCount > 0 ? Theme.primary : Theme.on_surface)
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.notifCount > 0
            text: root.notifCount
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeXs
            font.weight: Font.Bold
            color: Settings.dnd ? Theme.tertiary : Theme.primary
        }
    }

    MouseArea {
        id: notifMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (Theme.isVertical) {
                popup.targetRelativeY = root.mapToItem(null, 0, 0).y + (root.height / 2);
            } else {
                popup.targetRelativeX = root.mapToItem(null, 0, 0).x + (root.width / 2);
            }
            popup.open = !popup.open
        }
    }

    PopupPanel {
        id: popup
        cardWidth: 380
        cardHeight: 460

        content: ColumnLayout {
            anchors.fill: parent
            spacing: Theme.widgetSpacing

            // header with DND toggle and clear all
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: "notifications"
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeLg
                    font.weight: Font.Bold
                    color: Theme.on_surface
                    Layout.fillWidth: true
                }

                // DND Toggle chip
                Rectangle {
                    height: 26
                    implicitWidth: dndChipRow.implicitWidth + 14
                    radius: Theme.radiusPill
                    color: Settings.dnd ? Theme.tertiary_container : Theme.surface_container_highest
                    border.color: Settings.dnd ? Theme.tertiary : "transparent"
                    border.width: 1

                    Behavior on color { ColorAnimation { duration: Theme.animFast } }

                    RowLayout {
                        id: dndChipRow
                        anchors.centerIn: parent
                        spacing: 4

                        Text {
                            text: Settings.dnd ? Theme.iconBellOff : Theme.iconBell
                            font.family: Theme.fontIcon
                            font.pixelSize: 11
                            color: Settings.dnd ? Theme.on_tertiary_container : Theme.on_surface_variant
                        }

                        Text {
                            text: Settings.dnd ? "dnd on" : "dnd off"
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                            font.weight: Font.Bold
                            color: Settings.dnd ? Theme.on_tertiary_container : Theme.on_surface_variant
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Settings.dnd = !Settings.dnd
                    }
                }

                IconButton {
                    icon: Theme.iconTrash
                    iconSize: Theme.fontSizeMd
                    tooltip: "clear all"
                    onClicked: {
                        NotificationService.clearAll()
                        popup.open = false
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Theme.widgetBorder
            }

            FlickList {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                Repeater {
                    model: NotificationService.trackedNotifications

                    delegate: Rectangle {
                        required property var modelData
                        width: parent.width
                        implicitHeight: col.implicitHeight + Theme.widgetPaddingH * 2
                        color: Theme.surface_container_highest
                        radius: Theme.widgetRadius

                        ColumnLayout {
                            id: col
                            anchors.fill: parent
                            anchors.margins: Theme.widgetPaddingH
                            spacing: 4

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                // App name
                                Text {
                                    text: modelData.appName
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSizeXs
                                    font.weight: Font.Bold
                                    color: Theme.primary
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                }
                                
                                IconButton {
                                    icon: Theme.iconClose
                                    iconSize: Theme.fontSizeSm
                                    Layout.preferredWidth: 20
                                    Layout.preferredHeight: 20
                                    onClicked: modelData.dismiss()
                                }
                            }

                            // Summary
                            Text {
                                text: modelData.summary
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeMd
                                font.weight: Font.Medium
                                color: Theme.on_surface
                                Layout.fillWidth: true
                                wrapMode: Text.Wrap
                            }

                            // Body
                            Text {
                                text: modelData.body
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeSm
                                color: Theme.on_surface_variant
                                Layout.fillWidth: true
                                wrapMode: Text.Wrap
                                visible: text !== ""
                            }
                            
                            // Actions
                            RowLayout {
                                Layout.fillWidth: true
                                visible: modelData.actions.length > 0
                                spacing: 4
                                
                                Repeater {
                                    model: modelData.actions
                                    
                                    delegate: Rectangle {
                                        required property var modelData
                                        Layout.fillWidth: true
                                        height: 28
                                        radius: Theme.radiusSm
                                        color: actMouse.containsMouse ? Theme.primary_overlay : Theme.surface_variant
                                        
                                        Behavior on color { ColorAnimation { duration: Theme.animFast } }
                                        
                                        Text {
                                            text: modelData.text
                                            font.family: Theme.fontFamily
                                            font.pixelSize: Theme.fontSizeSm
                                            color: Theme.on_surface
                                            anchors.centerIn: parent
                                        }
                                        
                                        MouseArea {
                                            id: actMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: modelData.invoke()
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: root.notifCount === 0
                
                Text {
                    text: (Settings.dnd ? (Theme.iconBellOff + "\ndo not disturb active\n") : (Theme.getVibe(Theme.kaoSleepy + "\n", Theme.iconBellOutline + "\n", ""))) + "all caught up"
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeMd
                    color: Theme.on_surface_variant
                    horizontalAlignment: Text.AlignHCenter
                    anchors.centerIn: parent
                    lineHeight: 1.5
                }
            }
        }
    }
}
