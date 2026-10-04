import QtQuick
import ".."

Rectangle {
    id: root

    property bool hovered: false
    property bool focused: false
    property bool pressed: false
    property bool dragged: false
    property bool disabled: false

    property color stateColor: Theme.on_surface
    property real hoverOpacity: 0.08
    property real focusOpacity: 0.10
    property real pressOpacity: 0.12
    property real dragOpacity: 0.16
    property real customOpacity: 0.0

    anchors.fill: parent
    radius: parent?.radius ?? 0
    color: stateColor

    opacity: {
        if (disabled) return 0.0;
        if (dragged) return dragOpacity;
        if (pressed) return pressOpacity;
        if (focused) return focusOpacity;
        if (hovered) return hoverOpacity;
        return customOpacity;
    }

    visible: opacity > 0.001

    Behavior on opacity {
        NumberAnimation {
            duration: Theme.animFast
            easing.type: Theme.animEasing
        }
    }

    Behavior on color {
        ColorAnimation {
            duration: Theme.animFast
        }
    }
}
