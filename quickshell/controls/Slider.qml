import QtQuick
import QtQuick.Layouts
import ".."

Item {
    id: root

    property real from: 0.0
    property real to: 100.0
    property real stepSize: 1.0
    property real value: 0.0
    property string label: ""
    property string unit: ""
    property string icon: ""
    property bool showValue: true
    property color accentColor: Theme.primary
    property bool liveUpdate: true

    signal moved(real val)

    implicitWidth: 240
    implicitHeight: (root.label !== "" || root.showValue) ? 44 : 26

    // Internal clamped fraction
    readonly property real span: Math.max(0.0001, root.to - root.from)
    readonly property real clampedValue: Math.max(root.from, Math.min(root.to, root.value))
    readonly property real fraction: Math.max(0.0, Math.min(1.0, (clampedValue - root.from) / span))

    function setValueFromX(mouseX) {
        const trackW = Math.max(1, trackArea.width - handle.width);
        const relX = Math.max(0, Math.min(trackW, mouseX - (handle.width / 2)));
        let rawVal = root.from + (relX / trackW) * root.span;

        if (root.stepSize > 0) {
            rawVal = Math.round((rawVal - root.from) / root.stepSize) * root.stepSize + root.from;
        }
        rawVal = Math.max(root.from, Math.min(root.to, rawVal));
        if (Math.abs(root.value - rawVal) > 0.0001) {
            root.value = rawVal;
            root.moved(rawVal);
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 4

        // Top Row: Icon + Label + Value Badge
        RowLayout {
            Layout.fillWidth: true
            visible: root.label !== "" || root.showValue
            spacing: 6

            Text {
                visible: root.icon !== ""
                text: root.icon
                font.family: Theme.fontIcon
                font.pixelSize: Theme.fontSizeSm
                color: Theme.on_surface_variant
            }

            Text {
                Layout.fillWidth: true
                visible: root.label !== ""
                text: root.label
                font.family: Theme.fontSans
                font.pixelSize: Theme.fontSizeSm
                font.weight: Font.Medium
                color: Theme.on_surface
                elide: Text.ElideRight
            }

            Rectangle {
                visible: root.showValue
                implicitWidth: valText.implicitWidth + 12
                implicitHeight: 20
                radius: Theme.radiusPill
                color: mouseArea.pressed ? Theme.primary_container : Theme.surface_container_high

                Behavior on color { ColorAnimation { duration: Theme.animFast } }

                Text {
                    id: valText
                    anchors.centerIn: parent
                    text: {
                        let v = root.value;
                        if (root.stepSize >= 1) {
                            return Math.round(v) + root.unit;
                        }
                        return v.toFixed(1) + root.unit;
                    }
                    font.family: Theme.fontMono
                    font.pixelSize: Theme.fontSizeXs
                    font.weight: Font.DemiBold
                    color: mouseArea.pressed ? Theme.on_primary_container : Theme.on_surface
                }
            }
        }

        // Bottom Row: Slider Track & Handle
        Item {
            id: trackArea
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredHeight: 22

            Rectangle {
                id: bgTrack
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                height: 6
                radius: 3
                color: Theme.surface_container_highest

                Rectangle {
                    id: fillTrack
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: Math.max(0, handle.x + (handle.width / 2))
                    radius: 3
                    color: root.accentColor

                    Behavior on width {
                        enabled: !mouseArea.pressed
                        NumberAnimation { duration: Theme.animFast; easing.type: Theme.animEasing }
                    }
                }
            }

            Rectangle {
                id: handle
                width: mouseArea.pressed ? 18 : (mouseArea.containsMouse ? 16 : 14)
                height: width
                radius: width / 2
                x: Math.max(0, Math.min(trackArea.width - width, root.fraction * (trackArea.width - width)))
                anchors.verticalCenter: parent.verticalCenter
                color: mouseArea.pressed ? root.accentColor : Theme.on_surface
                border.width: 2
                border.color: Theme.surface

                Behavior on width { NumberAnimation { duration: Theme.animFast; easing.type: Theme.animEasing } }
                Behavior on color { ColorAnimation { duration: Theme.animFast } }
                Behavior on x {
                    enabled: !mouseArea.pressed
                    NumberAnimation { duration: Theme.animFast; easing.type: Theme.animEasing }
                }
            }

            MouseArea {
                id: mouseArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                preventStealing: true

                onPressed: (mouse) => root.setValueFromX(mouse.x)
                onPositionChanged: (mouse) => {
                    if (pressed) root.setValueFromX(mouse.x);
                }
                onWheel: (wheel) => {
                    const step = root.stepSize > 0 ? root.stepSize : 1.0;
                    const delta = wheel.angleDelta.y > 0 ? step : -step;
                    const nextVal = Math.max(root.from, Math.min(root.to, root.value + delta));
                    if (Math.abs(root.value - nextVal) > 0.0001) {
                        root.value = nextVal;
                        root.moved(nextVal);
                    }
                }
            }
        }
    }
}
