import QtQuick
import ".."
import Quickshell.Hyprland

Rectangle {
    id: root
    property real maxWidth: 220
    readonly property bool hasWindow: Boolean(Hyprland.activeToplevel && Hyprland.activeToplevel.title)

    visible: hasWindow && maxWidth > 20
    implicitWidth: {
        if (!hasWindow || maxWidth <= 20) return 0;
        if (Theme.isVertical) return Theme.barHeight - 8;
        return Math.min(titleText.implicitWidth + 24, root.maxWidth);
    }
    implicitHeight: Theme.barHeight - 8
    radius: Theme.radiusPill
    color: Theme.surface_container_high
    clip: true

    Behavior on implicitWidth { NumberAnimation { duration: Theme.animNormal; easing.type: Theme.animEasing } }
    Behavior on opacity { NumberAnimation { duration: Theme.animFast; easing.type: Theme.animEasing } }

    Text {
        id: titleText
        anchors.centerIn: parent
        text: Hyprland.activeToplevel?.title ?? ""
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeSm
        color: Theme.on_surface
        elide: Text.ElideRight
        maximumLineCount: 1
        width: Math.max(0, Math.min(implicitWidth - 16, root.maxWidth - 20))
    }
}
