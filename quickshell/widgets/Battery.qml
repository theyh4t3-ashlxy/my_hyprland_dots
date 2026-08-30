import QtQuick
import ".."
import Quickshell.Services.UPower

Rectangle {
    id: container

    property var device: UPower.displayDevice

    implicitWidth: Theme.isVertical ? Theme.barHeight - 8 : contentRow.implicitWidth + 24
    implicitHeight: Theme.barHeight - 8
    radius: Theme.radiusPill
    color: (contentRow.pct < 20 && !contentRow.isCharging) ? Theme.error_overlay : Theme.surface_container_high
    visible: (device?.ready ?? false) && (device?.isLaptopBattery ?? false)

    Behavior on color { ColorAnimation { duration: Theme.animFast } }

    Row {
        id: contentRow
        anchors.centerIn: parent
        spacing: 4

        // don't delete this multiplier or my battery dies at 100% (float 0-1)
        property real pct: Math.round((container.device?.percentage ?? 0) * 100)
        
        property bool isCharging: container.device?.state === UPowerDeviceState.Charging
                               || container.device?.state === UPowerDeviceState.PendingCharge

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: contentRow.isCharging ? Theme.iconBatCharge
                : contentRow.pct >= 90  ? Theme.iconBatFull
                : contentRow.pct >= 50  ? Theme.iconBatHalf
                : contentRow.pct >= 20  ? Theme.iconBatQuarter
                                        : Theme.iconBatEmpty
            font.family: Theme.fontMono
            font.pixelSize: Theme.fontSizeSm
            color: contentRow.pct < 20 && !contentRow.isCharging ? Theme.error : Theme.on_surface
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: {
                if (Settings.unhingedFlavor && bMouse.containsMouse) {
                    if (contentRow.isCharging) return Theme.kaoBolt + " chuggin watts";
                    if (contentRow.pct < 15) return Theme.kaoSad + " feed me";
                    if (contentRow.pct >= 95) return Theme.kaoHappy + " full";
                    return contentRow.pct + "%";
                }
                return contentRow.pct + "%";
            }
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeSm
            color: contentRow.pct < 20 && !contentRow.isCharging ? Theme.error : Theme.on_surface
        }
    }

    MouseArea {
        id: bMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
    }
}