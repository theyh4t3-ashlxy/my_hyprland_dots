import QtQuick
import ".."
import Quickshell.Services.Mpris

Rectangle {
    id: root

    // grab whatever is currently making noise instead of whatever random browser tab booted first
    property var player: {
        const list = Mpris.players.values;
        return list.find(p => p.isPlaying) ?? list[0] ?? null;
    }

    visible: (player !== null) && Settings.showMedia
    implicitWidth: Theme.isVertical ? Theme.barHeight - 8 : row.implicitWidth + 24
    implicitHeight: Theme.barHeight - 8
    radius: Theme.radiusPill
    color: npMouse.containsMouse ? Theme.surface_container_highest : Theme.surface_container_high

    Behavior on color { ColorAnimation { duration: Theme.animFast } }

    Row {
        id: row
        spacing: 6
        anchors.centerIn: parent

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Theme.kaoMusic
            font.family: Theme.fontMono
            font.pixelSize: Theme.fontSizeSm
            color: root.player?.isPlaying ? Theme.primary : Theme.on_surface_variant

            Behavior on color { ColorAnimation { duration: Theme.animFast } }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: !Theme.isVertical
            text: root.player
                ? (root.player.trackArtist ? root.player.trackArtist + " - " : "") + (root.player.trackTitle || "nothing playing")
                : ""
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeSm
            color: Theme.on_surface
            elide: Text.ElideRight
            // stop spotify from bulldozing the rest of my status bar
            width: Math.min(implicitWidth, 180)
        }
    }

    MouseArea {
        id: npMouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor

        onClicked: (mouse) => {
            if (!root.player) return;
            if (mouse.button === Qt.LeftButton) {
                // native toggle so i don't have to write 6 branches of if-else
                if (root.player.canTogglePlaying) {
                    root.player.togglePlaying();
                }
            } else if (mouse.button === Qt.RightButton) {
                if (root.player.canGoNext) root.player.next();
            }
        }
    }
}