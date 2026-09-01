import QtQuick
import QtQuick.Layouts
import ".."
import Quickshell
import Quickshell.Networking

PopupPanel {
    id: root
    cardWidth: 420
    cardHeight: 480

    content: ColumnLayout {
        anchors.fill: parent
        spacing: Theme.widgetSpacing

        // Header
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                text: "network & wi-fi"
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeLg
                font.weight: Font.Bold
                color: Theme.on_surface
                Layout.fillWidth: true
            }

            IconButton {
                icon: Theme.iconRefresh
                iconSize: Theme.fontSizeMd
                tooltip: "rescan networks"
                onClicked: NetworkService.rescan()
            }

            ToggleSwitch {
                checked: NetworkService.wifiEnabled
                onToggled: NetworkService.toggleWifi()
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Theme.widgetBorder
        }

        // Active Connection Status Card
        Rectangle {
            Layout.fillWidth: true
            height: 52
            color: NetworkService.isConnected ? Theme.primary_overlay : Theme.surface_container_highest
            radius: Theme.widgetRadius

            RowLayout {
                anchors.fill: parent
                anchors.margins: Theme.widgetPaddingH
                spacing: 10

                Text {
                    text: NetworkService.isWiredConnected ? Theme.iconEthernet : (NetworkService.isWifiConnected ? Theme.iconWifiHigh : Theme.iconWifiOff)
                    font.family: Theme.fontMono
                    font.pixelSize: 22
                    color: NetworkService.isConnected ? Theme.primary : Theme.on_surface_variant
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        text: NetworkService.activeSsid
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeSm
                        font.weight: Font.Bold
                        color: NetworkService.isConnected ? Theme.primary : Theme.on_surface
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }

                    Text {
                        text: NetworkService.isConnected ? ("online • " + NetworkService.signalStrength + "% signal") : "no connection"
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                        color: Theme.on_surface_variant
                    }
                }

                IconButton {
                    icon: Theme.iconTerminal
                    iconSize: Theme.fontSizeXs
                    tooltip: "open nmtui terminal manager"
                    onClicked: Quickshell.execDetached(["kitty", "-e", "nmtui"])
                }
            }
        }

        readonly property var wifiNetworks: (NetworkService.wifiDevice?.networks?.values ?? NetworkService.wifiDevice?.networks) ?? []
        readonly property int wifiNetworkCount: wifiNetworks ? (wifiNetworks.length ?? 0) : 0

        // Discovered Networks List
        Text {
            text: "available networks (" + root.wifiNetworkCount + ")"
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeXs
            font.weight: Font.Bold
            color: Theme.primary
            visible: NetworkService.wifiEnabled && root.wifiNetworkCount > 0
        }

        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            contentWidth: width
            contentHeight: netCol.implicitHeight
            boundsBehavior: Flickable.StopAtBounds
            visible: NetworkService.wifiEnabled && root.wifiNetworkCount > 0

            ColumnLayout {
                id: netCol
                width: parent.width - 4
                spacing: 6

                Repeater {
                    model: NetworkService.wifiEnabled ? root.wifiNetworks : []

                    delegate: NetworkEntry {
                        required property var modelData
                        modelData: modelData
                    }
                }
            }
        }

        // Empty state when Wi-Fi disabled or no networks found
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: !NetworkService.wifiEnabled || root.wifiNetworkCount === 0

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 8

                Text {
                    text: !NetworkService.wifiEnabled ? Theme.kaoSleepy : Theme.kaoSearch
                    font.family: Theme.fontMono
                    font.pixelSize: 32
                    color: Theme.primary
                    Layout.alignment: Qt.AlignHCenter
                }

                Text {
                    text: !NetworkService.wifiEnabled ? "wi-fi is turned off" : "scanning for networks..."
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSm
                    font.weight: Font.Bold
                    color: Theme.on_surface
                    Layout.alignment: Qt.AlignHCenter
                }

                Text {
                    text: !NetworkService.wifiEnabled ? "toggle the switch above to connect" : (Theme.kaoHappy + " hang tight while we discover ssids")
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                    color: Theme.on_surface_variant
                    Layout.alignment: Qt.AlignHCenter
                }
            }
        }
    }
}
