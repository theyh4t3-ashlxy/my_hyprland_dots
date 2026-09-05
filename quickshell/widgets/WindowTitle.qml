import QtQuick
import ".."
import Quickshell.Hyprland

Rectangle {
    id: windowTitleRoot
    visible: !Theme.isVertical && (Settings?.showWindowTitle ?? true)
    implicitWidth: Theme.isVertical ? 0 : Math.min(titleText.implicitWidth + 24, 300)
    implicitHeight: Theme.isVertical ? 0 : Theme.barHeight - 8
    radius: Theme.radiusPill
    clip: true
    color: wtMouse.containsMouse ? Theme.pillHover : Theme.pillBg
    border.color: Theme.pillBorder
    border.width: Theme.pillBorder === "transparent" ? 0 : 1

    Behavior on color { ColorAnimation { duration: Theme.animFast } }
    Behavior on border.color { ColorAnimation { duration: Theme.animFast } }
    Behavior on implicitWidth { NumberAnimation { duration: Theme.animFast; easing.type: Theme.animEasing } }

    MouseArea {
        id: wtMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.ArrowCursor
    }

    Text {
        id: titleText
        anchors.centerIn: parent
        text: Hyprland.activeToplevel?.title ?? Theme.getFlavor("system", Theme.getVibe(Theme.kaoEmpty, "󰄛", "desktop"))
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
