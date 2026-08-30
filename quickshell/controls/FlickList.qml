import QtQuick
import ".."

Flickable {
    id: root

    default property alias content: contentCol.data

    flickableDirection: Flickable.VerticalFlick
    boundsBehavior: Flickable.StopAtBounds
    clip: true
    contentHeight: contentCol.implicitHeight

    Column {
        id: contentCol
        width: parent.width
        spacing: Theme.popupSpacing
    }
}
