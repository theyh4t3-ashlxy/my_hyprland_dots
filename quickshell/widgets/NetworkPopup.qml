import QtQuick
import QtQuick.Layouts
import ".."
import Quickshell
import Quickshell.Networking

PopupPanel {
    id: root

    content: ColumnLayout {
        anchors.fill: parent
        spacing: Theme.widgetSpacing

        // header
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                text: "Wi-Fi"
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeLg
                font.weight: Font.Bold
                color: Theme.on_surface
                Layout.fillWidth: true
            }

            IconButton {
                icon: Theme.iconRefresh
                iconSize: Theme.fontSizeMd
                tooltip: "Scan Networks"
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

        // network status banner
        Rectangle {
            Layout.fillWidth: true
            height: 40
            color: NetworkService.isConnected ? Theme.primary_overlay : Theme.surface_container_highest
            radius: Theme.widgetRadius

            RowLayout {
                anchors.fill: parent
                anchors.margins: Theme.widgetPaddingH
                spacing: 8

                Text {
                    text: NetworkService.isWiredConnected ? Theme.iconEthernet : (NetworkService.isWifiConnected ? Theme.iconWifiHigh : Theme.iconWifiOff)
                    font.family: Theme.fontMono
                    font.pixelSize: Theme.fontSizeMd
                    color: NetworkService.isConnected ? Theme.primary : Theme.on_surface_variant
                }

                Text {
                    text: NetworkService.activeSsid
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSm
                    font.weight: Font.Medium
                    color: Theme.on_surface
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }

                Text {
                    text: NetworkService.isConnected ? (NetworkService.signalStrength + "%") : "offline"
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeXs
                    color: Theme.on_surface_variant
                }
            }
        }

        readonly property var wifiNetworks: (NetworkService.wifiDevice?.networks?.values ?? NetworkService.wifiDevice?.networks) ?? []
        readonly property int wifiNetworkCount: wifiNetworks ? (wifiNetworks.length ?? 0) : 0

        // list of available networks
        FlickList {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            visible: NetworkService.wifiEnabled && root.wifiNetworkCount > 0

            Repeater {
                model: NetworkService.wifiEnabled ? root.wifiNetworks : []

                delegate: NetworkEntry {
                    required property var modelData
                    modelData: modelData
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

        // empty state if wifi off or no networks
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: !NetworkService.wifiEnabled || root.wifiNetworkCount === 0

            Text {
                text: !NetworkService.wifiEnabled ? (Theme.kaoSleepy + "\nwi-fi is turned off") : (Theme.kaoSearch + "\nsearching for networks...")
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
