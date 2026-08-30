import QtQuick
import ".."

Rectangle {
    id: root

    property string icon: ""
    property int iconSize: Theme.fontSizeMd
    property string tooltip: ""
    property bool highlighted: false

    signal clicked()

    implicitWidth: iconSize + Theme.widgetPaddingH * 2
    implicitHeight: Theme.barHeight - 8

    radius: Theme.widgetRadius
    color: mouseArea.pressed
        ? Theme.widgetActive
        : mouseArea.containsMouse
            ? Theme.widgetHover
            : highlighted
                ? Theme.primary_overlay
                : "transparent"

    Behavior on color { ColorAnimation { duration: Theme.animFast } }

    Text {
        text: root.icon
        font.family: Theme.fontMono
        font.pixelSize: root.iconSize
        color: Theme.on_surface
        anchors.centerIn: parent
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
