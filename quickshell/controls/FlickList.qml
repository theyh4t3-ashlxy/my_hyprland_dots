import QtQuick
import QtQuick.Layouts
import ".."

Flickable {
    id: root

    property int orientation: Qt.Vertical
    property int spacing: Theme.popupSpacing
    property bool showEdgeFades: true

    default property alias content: contentLayout.data

    flickableDirection: orientation === Qt.Horizontal ? Flickable.HorizontalFlick : Flickable.VerticalFlick
    boundsBehavior: Flickable.StopAtBounds
    clip: true

    contentWidth: orientation === Qt.Horizontal ? contentLayout.implicitWidth : width
    contentHeight: orientation === Qt.Vertical ? contentLayout.implicitHeight : height

    // Smooth horizontal mouse wheel scroll translation
    WheelHandler {
        target: root
        orientation: Qt.Vertical
        onWheel: (event) => {
            if (root.orientation === Qt.Horizontal) {
                const delta = event.angleDelta.y !== 0 ? event.angleDelta.y : event.angleDelta.x;
                const targetX = root.contentX - (delta * 0.8);
                const maxX = Math.max(0, root.contentWidth - root.width);
                root.contentX = Math.max(0, Math.min(maxX, targetX));
                event.accepted = true;
            }
        }
    }

    Item {
        id: contentLayout
        width: root.orientation === Qt.Horizontal ? implicitWidth : root.width
        height: root.orientation === Qt.Vertical ? implicitHeight : root.height

        implicitWidth: root.orientation === Qt.Horizontal ? (horizRow ? horizRow.implicitWidth : 0) : root.width
        implicitHeight: root.orientation === Qt.Vertical ? (vertCol ? vertCol.implicitHeight : 0) : root.height

        Column {
            id: vertCol
            visible: root.orientation === Qt.Vertical
            width: parent.width
            spacing: root.spacing
        }

        Row {
            id: horizRow
            visible: root.orientation === Qt.Horizontal
            height: parent.height
            spacing: root.spacing
        }
    }

    // Edge fade indicators for horizontal mode
    Rectangle {
        id: leftFade
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 16
        z: 10
        visible: root.showEdgeFades && root.orientation === Qt.Horizontal && root.contentX > 4
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: Theme.surface_container_lowest }
            GradientStop { position: 1.0; color: "transparent" }
        }
    }

    Rectangle {
        id: rightFade
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 16
        z: 10
        visible: root.showEdgeFades && root.orientation === Qt.Horizontal && (root.contentX + root.width < root.contentWidth - 4)
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 1.0; color: Theme.surface_container_lowest }
        }
    }
}
