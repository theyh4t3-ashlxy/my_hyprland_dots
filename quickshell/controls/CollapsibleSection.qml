import QtQuick
import QtQuick.Layouts
import ".."

Rectangle {
    id: root

    property string title: ""
    property string subtitle: ""
    property string icon: ""
    property string badge: ""
    property bool collapsed: false
    property color accentColor: Theme.primary

    default property alias content: contentCol.data

    implicitWidth: 320
    implicitHeight: headerRow.height + (root.collapsed ? 0 : (bodyContainer.implicitHeight + 8))

    radius: Theme.widgetRadius
    color: Theme.surface_container_lowest
    border.width: 1
    border.color: Theme.outline_variant

    Behavior on implicitHeight {
        NumberAnimation { duration: Theme.animNormal; easing.type: Theme.animEasing }
    }

    Column {
        anchors.fill: parent
        anchors.margins: 1

        // Clickable Section Header
        Rectangle {
            id: headerRow
            width: parent.width
            height: 38
            radius: root.collapsed ? Theme.widgetRadius : (Theme.widgetRadius > 0 ? Theme.widgetRadius - 1 : 0)
            color: headerMouse.pressed
                ? Theme.surface_container_highest
                : (headerMouse.containsMouse ? Theme.surface_container_high : Theme.surface_container_low)

            Behavior on color { ColorAnimation { duration: Theme.animFast } }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 8

                Text {
                    visible: root.icon !== ""
                    text: root.icon
                    font.family: Theme.fontIcon
                    font.pixelSize: Theme.fontSizeMd
                    color: root.collapsed ? Theme.on_surface_variant : root.accentColor

                    Behavior on color { ColorAnimation { duration: Theme.animFast } }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1

                    Text {
                        Layout.fillWidth: true
                        text: root.title
                        font.family: Theme.fontSans
                        font.pixelSize: Theme.fontSizeSm
                        font.weight: Font.DemiBold
                        color: Theme.on_surface
                        elide: Text.ElideRight
                    }

                    Text {
                        Layout.fillWidth: true
                        visible: root.subtitle !== ""
                        text: root.subtitle
                        font.family: Theme.fontSans
                        font.pixelSize: Theme.fontSizeXs
                        color: Theme.on_surface_variant
                        elide: Text.ElideRight
                    }
                }

                Rectangle {
                    visible: root.badge !== ""
                    implicitWidth: badgeText.implicitWidth + 10
                    implicitHeight: 18
                    radius: Theme.radiusPill
                    color: Theme.primary_container

                    Text {
                        id: badgeText
                        anchors.centerIn: parent
                        text: root.badge
                        font.family: Theme.fontSans
                        font.pixelSize: Theme.fontSizeXs
                        font.weight: Font.Medium
                        color: Theme.on_primary_container
                    }
                }

                Text {
                    text: Theme.iconChevronDown
                    font.family: Theme.fontIcon
                    font.pixelSize: Theme.fontSizeSm
                    color: headerMouse.containsMouse ? Theme.primary : Theme.on_surface_variant
                    rotation: root.collapsed ? -90 : 0

                    Behavior on rotation {
                        NumberAnimation { duration: Theme.animNormal; easing.type: Theme.animEasing }
                    }
                    Behavior on color { ColorAnimation { duration: Theme.animFast } }
                }
            }

            MouseArea {
                id: headerMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.collapsed = !root.collapsed
            }
        }

        // Expandable Body Container
        Item {
            id: bodyContainer
            width: parent.width
            implicitHeight: contentCol.implicitHeight + 8
            height: root.collapsed ? 0 : implicitHeight
            clip: true
            opacity: root.collapsed ? 0 : 1
            visible: height > 0

            Behavior on height {
                NumberAnimation { duration: Theme.animNormal; easing.type: Theme.animEasing }
            }
            Behavior on opacity {
                NumberAnimation { duration: Theme.animNormal; easing.type: Theme.animEasing }
            }

            Column {
                id: contentCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 8
                spacing: 8
            }
        }
    }
}
