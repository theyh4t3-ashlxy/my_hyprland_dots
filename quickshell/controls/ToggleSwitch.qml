import QtQuick
import ".."

Rectangle {
    id: track

    property bool checked: false
    signal toggled()

    width: 36
    height: 20
    radius: height / 2
    color: checked ? Theme.primary : Theme.surface_variant

    Behavior on color { ColorAnimation { duration: Theme.animNormal } }

    Rectangle {
        id: knob
        // subtle grow on check so it feels alive
        width: track.checked ? 16 : 14
        height: track.checked ? 16 : 14
        radius: width / 2
        color: track.checked ? Theme.on_primary : Theme.outline
        anchors.verticalCenter: parent.verticalCenter
        x: track.checked ? (track.width - knob.width - 3) : 3

        Behavior on x {
            NumberAnimation {
                duration: Theme.animNormal
                easing.type: Theme.animEasing
            }
        }
        Behavior on width { NumberAnimation { duration: Theme.animNormal; easing.type: Theme.animEasing } }
        Behavior on height { NumberAnimation { duration: Theme.animNormal; easing.type: Theme.animEasing } }
        Behavior on color { ColorAnimation { duration: Theme.animNormal } }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            track.toggled()
        }
    }
}
