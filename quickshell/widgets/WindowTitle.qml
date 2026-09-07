import QtQuick
import ".."
import Quickshell.Hyprland

Rectangle {
    id: windowTitleRoot

    readonly property var activeTop: Hyprland?.activeToplevel
    readonly property string rawTitle: (activeTop?.title ?? "").trim()
    readonly property string fallbackText: Theme?.getFlavor
        ? Theme.getFlavor("system", (Theme?.getVibe ? Theme.getVibe(Theme?.kaoEmpty, "󰄛", "desktop") : "desktop"))
        : "desktop"
    readonly property string displayTitle: rawTitle.length > 0 ? rawTitle : fallbackText

    visible: !(Theme?.isVertical ?? false) && (Settings?.showWindowTitle ?? true)
    implicitWidth: (Theme?.isVertical ?? false) ? 0 : Math.min(titleText.implicitWidth + 24, 300)
    implicitHeight: (Theme?.isVertical ?? false) ? 0 : ((Theme?.barHeight ?? 48) - 8)
    radius: Theme?.radiusPill ?? 999
    clip: true
    color: wtMouse.containsMouse ? (Theme?.pillHover ?? "#33ffffff") : (Theme?.pillBg ?? "#1a000000")
    border.color: Theme?.pillBorder ?? "transparent"
    border.width: (Theme?.pillBorder ?? "transparent") === "transparent" ? 0 : 1

    Behavior on color { ColorAnimation { duration: Theme?.animFast ?? 150 } }
    Behavior on border.color { ColorAnimation { duration: Theme?.animFast ?? 150 } }
    Behavior on implicitWidth { NumberAnimation { duration: Theme?.animFast ?? 150; easing.type: Theme?.animEasing ?? Easing.OutQuad } }

    MouseArea {
        id: wtMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.ArrowCursor
        acceptedButtons: Qt.NoButton
    }

    Text {
        id: titleText
        // anchoring to edges prevents centerIn from slicing off the start of long titles
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        horizontalAlignment: Text.AlignHCenter
        text: windowTitleRoot.displayTitle
        font.family: Theme?.fontFamily ?? "sans-serif"
        font.pixelSize: Theme?.fontSizeSm ?? 12
        color: Theme?.on_surface ?? "#ffffff"
        elide: Text.ElideRight
        maximumLineCount: 1
        opacity: (windowTitleRoot.activeTop && windowTitleRoot.rawTitle.length > 0) ? 1.0 : 0.5

        Behavior on opacity { NumberAnimation { duration: Theme?.animFast ?? 150; easing.type: Theme?.animEasing ?? Easing.OutQuad } }
    }
}