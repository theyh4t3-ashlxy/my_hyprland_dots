import QtQuick
import ".."
import Quickshell.Hyprland

Rectangle {
    implicitWidth: Theme.isVertical ? Theme.barHeight - 8 : Math.min(titleText.implicitWidth + 24, 300)
    implicitHeight: Theme.barHeight - 8
    radius: Theme.radiusPill
    color: Theme.surface_container_high

    Text {
        id: titleText
        anchors.centerIn: parent
        // what are you even doing rn
        text: Hyprland.activeToplevel?.title ?? Theme.kaoEmpty
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeSm
        color: Theme.on_surface
        elide: Text.ElideRight
        maximumLineCount: 1
        width: Math.min(implicitWidth, 270)
        opacity: Hyprland.activeToplevel ? 1.0 : 0.5

        Behavior on opacity { NumberAnimation { duration: Theme.animFast; easing.type: Theme.animEasing } }
    }
}
