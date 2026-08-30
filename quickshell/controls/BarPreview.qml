import QtQuick
import QtQuick.Layouts
import ".."

Rectangle {
    id: root

    property string barPos: Settings.barPosition
    readonly property bool isTop: barPos === "top"
    readonly property bool isBottom: barPos === "bottom"
    readonly property bool isLeft: barPos === "left"
    readonly property bool isRight: barPos === "right"
    readonly property bool isVertical: isLeft || isRight

    width: parent.width
    height: 120
    color: Theme.surface_container_lowest
    radius: Theme.radiusMd
    border.color: Theme.widgetBorder
    border.width: 1

    // monitor screen outline
    Rectangle {
        id: screenMock
        anchors.fill: parent
        anchors.margins: 10
        color: Theme.background
        radius: Theme.radiusSm
        clip: true

        // mock bar
        Rectangle {
            id: mockBar
            anchors.left: !root.isRight ? parent.left : undefined
            anchors.right: !root.isLeft ? parent.right : undefined
            anchors.top: !root.isBottom ? parent.top : undefined
            anchors.bottom: !root.isTop ? parent.bottom : undefined
            width: root.isVertical ? 16 : parent.width
            height: root.isVertical ? parent.height : 16
            color: Theme.surface_container_low

            // horizontal layout mock
            RowLayout {
                anchors.fill: parent
                anchors.margins: 3
                spacing: 3
                visible: !root.isVertical

                Rectangle { width: 12; height: 4; radius: 2; color: Theme.primary }
                Rectangle { width: 6; height: 4; radius: 2; color: Theme.on_surface_variant }
                Item { Layout.fillWidth: true }
                Rectangle { width: 16; height: 4; radius: 2; color: Theme.on_surface }
                Item { Layout.fillWidth: true }
                Rectangle { width: 4; height: 4; radius: 2; color: Theme.on_surface_variant }
                Rectangle { width: 4; height: 4; radius: 2; color: Theme.on_surface_variant }
                Rectangle { width: 8; height: 4; radius: 2; color: Theme.primary }
            }

            // vertical layout mock
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 3
                spacing: 3
                visible: root.isVertical

                Rectangle { width: 4; height: 12; radius: 2; color: Theme.primary; Layout.alignment: Qt.AlignHCenter }
                Rectangle { width: 4; height: 6; radius: 2; color: Theme.on_surface_variant; Layout.alignment: Qt.AlignHCenter }
                Item { Layout.fillHeight: true }
                Rectangle { width: 4; height: 16; radius: 2; color: Theme.on_surface; Layout.alignment: Qt.AlignHCenter }
                Item { Layout.fillHeight: true }
                Rectangle { width: 4; height: 4; radius: 2; color: Theme.on_surface_variant; Layout.alignment: Qt.AlignHCenter }
                Rectangle { width: 4; height: 4; radius: 2; color: Theme.on_surface_variant; Layout.alignment: Qt.AlignHCenter }
                Rectangle { width: 4; height: 8; radius: 2; color: Theme.primary; Layout.alignment: Qt.AlignHCenter }
            }
        }

        // mock window in hyprland
        Rectangle {
            anchors.left: root.isLeft ? mockBar.right : parent.left
            anchors.right: root.isRight ? mockBar.left : parent.right
            anchors.top: root.isTop ? mockBar.bottom : parent.top
            anchors.bottom: root.isBottom ? mockBar.top : parent.bottom
            anchors.margins: 6
            color: Theme.surface_container_high
            radius: Theme.radiusSm
            border.color: Theme.primary_overlay
            border.width: 1

            Text {
                text: Theme.kaoCool + " " + root.barPos + " dock"
                font.family: Theme.fontMono
                font.pixelSize: Theme.fontSizeXs
                color: Theme.on_surface_variant
                anchors.centerIn: parent
            }
        }
    }
}
