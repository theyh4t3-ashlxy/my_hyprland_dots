import QtQuick
import ".."
import Quickshell.Services.Pipewire

Rectangle {
    id: volRoot
    implicitWidth: Theme.isVertical ? Theme.barHeight - 8 : row.implicitWidth + 24
    implicitHeight: Theme.barHeight - 8
    radius: Theme.radiusPill
    color: volRoot.muted ? Theme.surface_container : (vMouse.containsMouse ? Theme.surface_container_highest : Theme.surface_container_high)

    Behavior on color { ColorAnimation { duration: Theme.animFast } }

    property var sink: Pipewire.defaultAudioSink
    property var source: Pipewire.defaultAudioSource
    // if you skip this your audio properties are ghosts
    PwObjectTracker { objects: [volRoot.sink, volRoot.source].filter(Boolean) }

    property bool ready: sink?.ready ?? false
    property real vol: (ready && sink?.audio) ? sink.audio.volume : 0
    property bool muted: (ready && sink?.audio) ? sink.audio.muted : true

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 4

        Text {
            id: volIcon
            anchors.verticalCenter: parent.verticalCenter
            text: volRoot.muted || volRoot.vol === 0 ? Theme.iconVolMute
                : volRoot.vol < 0.33                 ? Theme.iconVolLow
                : volRoot.vol < 0.66                 ? Theme.iconVolMid
                                                     : Theme.iconVolHigh
            font.family: Theme.fontMono
            font.pixelSize: Theme.fontSizeMd
            color: volRoot.muted ? Theme.on_surface_disabled : Theme.on_surface
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: vMouse.containsMouse
            text: {
                if (volRoot.muted) return Settings.unhingedFlavor ? Theme.kaoAnger + " shh" : "muted";
                let pct = Math.round(volRoot.vol * 100);
                if (Settings.unhingedFlavor && pct > 100) return Theme.kaoPanic + " " + pct + "%";
                return pct + "%";
            }
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeXs
            color: volRoot.muted ? Theme.on_surface_disabled : Theme.on_surface
        }
    }

    MouseArea {
        id: vMouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        cursorShape: Qt.PointingHandCursor

        onClicked: (mouse) => {
            if (mouse.button === Qt.LeftButton) {
                if (ready && sink.audio)
                    sink.audio.muted = !sink.audio.muted;
            } else if (mouse.button === Qt.RightButton) {
                Quickshell.execDetached(["pavucontrol"]);
            } else if (mouse.button === Qt.MiddleButton) {
                if (source && source.audio) {
                    source.audio.muted = !source.audio.muted;
                }
            }
        }

        onWheel: (wheel) => {
            if (ready && sink.audio) {
                sink.audio.volume = Math.max(0, Math.min(1.5,
                    sink.audio.volume + (wheel.angleDelta.y > 0 ? 0.05 : -0.05)));
                sink.audio.muted = false;
            }
        }
    }
}
