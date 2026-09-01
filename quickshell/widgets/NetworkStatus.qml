import QtQuick
import ".."

Rectangle {
    id: root
    implicitWidth: Theme.isVertical ? Theme.barHeight - 8 : netRow.implicitWidth + 24
    implicitHeight: Theme.barHeight - 8
    radius: Theme.radiusPill
    color: popup.open ? Theme.primary_overlay : (netMouse.containsMouse ? Theme.pillHover : Theme.pillBg)
    border.color: Theme.pillBorder
    border.width: Theme.pillBorder === "transparent" ? 0 : 1

    Behavior on color { ColorAnimation { duration: Theme.animFast } }
    Behavior on border.color { ColorAnimation { duration: Theme.animFast } }

    readonly property string netIcon: {
        if (NetworkService.isWiredConnected) return Theme.iconEthernet;
        if (!NetworkService.wifiEnabled) return Theme.iconWifiOff;
        if (!NetworkService.isWifiConnected) return Theme.iconWifiOff;
        let sig = NetworkService.signalStrength;
        if (sig >= 75) return Theme.iconWifiHigh;
        if (sig >= 40) return Theme.iconWifiMed;
        return Theme.iconWifiLow;
    }

    Row {
        id: netRow
        anchors.centerIn: parent
        spacing: 4

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.netIcon
            font.family: Theme.fontIcon
            font.pixelSize: Theme.fontSizeMd
            color: NetworkService.isConnected ? Theme.primary : Theme.on_surface
        }
    }

    MouseArea {
        id: netMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            popup.targetRelativeX = root.mapToItem(null, 0, 0).x + (root.width / 2)
            popup.open = !popup.open
        }
    }

    NetworkPopup {
        id: popup
    }
}
