import QtQuick
import QtQuick.Layouts
import ".."

Rectangle {
    id: root

    required property var modelData
    property bool isConnected: modelData.connected || false
    property string networkName: modelData.name || "Hidden Network"
    property real signal: modelData.signalStrength || 0

    signal clicked()

    width: parent.width
    height: 44
    color: mouseArea.pressed ? Theme.widgetActive : mouseArea.containsMouse ? Theme.widgetHover : Theme.surface_container_highest
    radius: Theme.widgetRadius

    Behavior on color { ColorAnimation { duration: Theme.animFast } }

    RowLayout {
        anchors.fill: parent
        anchors.margins: Theme.widgetPaddingH
        spacing: 10

        Text {
            text: root.isConnected ? Theme.iconWifiHigh : (root.signal > 0.6 ? Theme.iconWifiHigh : root.signal > 0.3 ? Theme.iconWifiMed : Theme.iconWifiLow)
            font.family: Theme.fontMono
            font.pixelSize: Theme.fontSizeMd
            color: root.isConnected ? Theme.primary : Theme.on_surface
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 1

            Text {
                text: root.networkName
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSm
                font.weight: root.isConnected ? Font.Bold : Font.Normal
                color: root.isConnected ? Theme.primary : Theme.on_surface
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            Text {
                text: root.isConnected ? "Connected" : (Math.round(root.signal * 100) + "% signal")
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeXs
                color: Theme.on_surface_variant
                Layout.fillWidth: true
            }
        }

        IconButton {
            icon: root.isConnected ? Theme.iconClose : Theme.iconCheckCircle
            iconSize: Theme.fontSizeSm
            tooltip: root.isConnected ? "Disconnect" : "Connect"
            onClicked: root.clicked()
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
