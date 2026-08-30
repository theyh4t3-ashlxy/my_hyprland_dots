import QtQuick
import QtQuick.Layouts
import ".."
import Quickshell
import Quickshell.Bluetooth

Rectangle {
    id: root
    implicitWidth: Theme.isVertical ? Theme.barHeight - 8 : btRow.implicitWidth + 24
    implicitHeight: Theme.barHeight - 8
    radius: Theme.radiusPill
    color: popup.open ? Theme.primary_overlay : (btMouse.containsMouse ? Theme.surface_container_highest : Theme.surface_container_high)

    Behavior on color { ColorAnimation { duration: Theme.animFast } }

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool isPowered: adapter ? adapter.enabled : false
    readonly property bool hasConnectedDevice: root.adapter?.devices?.values?.some(d => d.connected) ?? false

    Row {
        id: btRow
        anchors.centerIn: parent
        spacing: 4

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.isPowered ? (root.hasConnectedDevice ? Theme.iconBluetoothConnected : Theme.iconBluetooth) : Theme.iconBluetoothOff
            font.family: Theme.fontMono
            font.pixelSize: Theme.fontSizeMd
            color: root.hasConnectedDevice ? Theme.primary : Theme.on_surface
        }
    }

    MouseArea {
        id: btMouse
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
        cardWidth: 420
        cardHeight: 440

        content: ColumnLayout {
            anchors.fill: parent
            spacing: Theme.widgetSpacing

            // header
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: "Bluetooth"
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeLg
                    font.weight: Font.Bold
                    color: Theme.on_surface
                    Layout.fillWidth: true
                }

                IconButton {
                    icon: Theme.iconRefresh
                    iconSize: Theme.fontSizeMd
                    tooltip: "Scan Devices"
                    visible: root.isPowered && root.adapter
                    onClicked: {
                        if (root.adapter) {
                            root.adapter.discovering = !root.adapter.discovering;
                        }
                    }
                }

                ToggleSwitch {
                    checked: root.isPowered
                    onToggled: {
                        if (root.adapter) {
                            root.adapter.enabled = !root.adapter.enabled;
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Theme.widgetBorder
            }

            // device list
            FlickList {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                visible: root.isPowered && root.adapter && root.adapter.devices && root.adapter.devices.values && root.adapter.devices.values.length > 0

                Repeater {
                    model: (root.isPowered && root.adapter?.devices) ? root.adapter.devices.values : []

                    delegate: Rectangle {
                        id: btDeviceDelegate
                        required property var modelData
                        width: parent.width
                        height: 48
                        color: modelData.connected ? Theme.primary_overlay : (dMouse.containsMouse ? Theme.surface_container_highest : Theme.surface_container_low)
                        radius: Theme.radiusMd
                        border.color: modelData.connected ? Theme.primary : "transparent"
                        border.width: 1

                        Behavior on color { ColorAnimation { duration: Theme.animFast } }
                        Behavior on border.color { ColorAnimation { duration: Theme.animFast } }

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: Theme.widgetPaddingH
                            spacing: 10

                            Text {
                                text: modelData.connected ? Theme.iconBluetoothConnected : Theme.iconBluetooth
                                font.family: Theme.fontMono
                                font.pixelSize: Theme.fontSizeMd
                                color: modelData.connected ? Theme.primary : Theme.on_surface_variant
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 1

                                Text {
                                    text: modelData.name || modelData.address || "Unknown Device"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSizeSm
                                    font.weight: modelData.connected ? Font.Bold : Font.Normal
                                    color: modelData.connected ? Theme.primary : Theme.on_surface
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }

                                Text {
                                    text: modelData.connected ? (modelData.battery !== undefined ? (modelData.battery + "% battery") : "Connected") : (modelData.paired ? "Paired" : "Available")
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSizeXs
                                    color: Theme.on_surface_variant
                                    Layout.fillWidth: true
                                }
                            }

                            IconButton {
                                icon: modelData.connected ? Theme.iconClose : Theme.iconCheckCircle
                                iconSize: Theme.fontSizeSm
                                tooltip: modelData.connected ? "Disconnect" : "Connect"
                                onClicked: {
                                    if (modelData.connected) {
                                        if (modelData.disconnect) modelData.disconnect();
                                    } else {
                                        if (modelData.connect) modelData.connect();
                                    }
                                }
                            }
                        }

                        MouseArea {
                            id: dMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (modelData.connected) {
                                    if (modelData.disconnect) modelData.disconnect();
                                } else {
                                    if (modelData.connect) modelData.connect();
                                }
                            }
                        }
                    }
                }
            }

            // empty state
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: !root.isPowered || !root.adapter || !root.adapter.devices || !root.adapter.devices.values || root.adapter.devices.values.length === 0

                Text {
                    text: !root.isPowered ? (Theme.kaoSleepy + "\nbluetooth is disabled") : (Theme.kaoSearch + "\nno devices found")
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
