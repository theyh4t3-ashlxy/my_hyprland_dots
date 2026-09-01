import QtQuick
import ".."
import Quickshell.Services.UPower

Rectangle {
    id: container

    property var device: UPower.displayDevice

    readonly property bool isVertical: Theme?.isVertical ?? false
    readonly property real pct: Math.round((container.device?.percentage ?? 0) * 100)
    readonly property bool isCharging: container.device?.state === UPowerDeviceState.Charging
                                    || container.device?.state === UPowerDeviceState.PendingCharge
    readonly property bool isLow: pct < 20 && !isCharging

    implicitWidth: isVertical ? Theme.barHeight - 8 : (contentRow.implicitWidth + 16)
    implicitHeight: Theme.barHeight - 8
    radius: Theme.radiusPill
    color: isLow ? Theme.error_overlay : (bMouse.containsMouse ? Theme.surface_container_highest : Theme.surface_container_high)
    visible: (device?.ready ?? false) && (device?.isLaptopBattery ?? false)

    Behavior on color { ColorAnimation { duration: Theme.animFast } }
    Behavior on implicitWidth { NumberAnimation { duration: Theme.animFast; easing.type: Theme.animEasing } }

    Row {
        id: contentRow
        anchors.centerIn: parent
        spacing: 4

        Text {
            id: batIcon
            anchors.verticalCenter: parent.verticalCenter
            text: container.isCharging ? Theme.iconBatCharge
                : container.pct >= 90  ? Theme.iconBatFull
                : container.pct >= 50  ? Theme.iconBatHalf
                : container.pct >= 20  ? Theme.iconBatQuarter
                                       : Theme.iconBatEmpty
            font.family: Theme.fontMono
            font.pixelSize: Theme.fontSizeMd
            color: container.isLow ? Theme.error : Theme.on_surface
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: !container.isVertical
            text: {
                if (Settings.unhingedFlavor && bMouse.containsMouse) {
                    if (container.isCharging) return Theme.kaoBolt + " chuggin watts";
                    if (container.pct < 15) return Theme.kaoSad + " feed me";
                    if (container.pct >= 95) return Theme.kaoHappy + " full";
                    return container.pct + "%";
                }
                return container.pct + "%";
            }
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeXs
            font.weight: Font.Medium
            color: container.isLow ? Theme.error : Theme.on_surface
        }
    }

    MouseArea {
        id: bMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
    }
}