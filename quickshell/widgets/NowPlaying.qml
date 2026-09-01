import QtQuick
import QtQuick.Layouts
import ".."
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Mpris

Rectangle {
    id: root

    property var player: {
        const list = Mpris.players.values;
        return list.find(p => p.isPlaying) ?? list[0] ?? null;
    }

    readonly property bool hasTrack: player !== null && (player.trackTitle !== "" || player.trackArtist !== "")
    readonly property bool isPlaying: player?.isPlaying ?? false

    implicitWidth: Theme.isVertical ? Theme.barHeight - 8 : row.implicitWidth + 24
    implicitHeight: Theme.barHeight - 8
    radius: Theme.radiusPill
    color: popup.open ? Theme.primary_overlay : (npMouse.containsMouse ? Theme.surface_container_highest : Theme.surface_container_high)

    Behavior on color { ColorAnimation { duration: Theme.animFast } }
    Behavior on implicitWidth { NumberAnimation { duration: Theme.animFast; easing.type: Theme.animEasing } }

    Row {
        id: row
        spacing: 6
        anchors.centerIn: parent

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.isPlaying ? Theme.iconMusic : (root.hasTrack ? Theme.iconPause : Theme.kaoMusic)
            font.family: Theme.fontMono
            font.pixelSize: Theme.fontSizeSm
            color: root.isPlaying ? Theme.primary : Theme.on_surface_variant

            Behavior on color { ColorAnimation { duration: Theme.animFast } }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: !Theme.isVertical
            text: {
                if (root.hasTrack) {
                    let artist = root.player.trackArtist ? root.player.trackArtist + " - " : ""
                    let title = root.player.trackTitle || "unknown track"
                    return artist + title
                }
                return npMouse.containsMouse ? (Theme.kaoShrug + " nothing playing rn") : (Theme.kaoEmpty + " quiet")
            }
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeSm
            color: root.hasTrack ? Theme.on_surface : Theme.on_surface_variant
            elide: Text.ElideRight
            width: Math.min(implicitWidth, 200)
        }
    }

    MouseArea {
        id: npMouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        cursorShape: Qt.PointingHandCursor

        onClicked: (mouse) => {
            if (mouse.button === Qt.LeftButton) {
                popup.targetRelativeX = root.mapToItem(null, 0, 0).x + (root.width / 2)
                popup.open = !popup.open
            } else if (mouse.button === Qt.RightButton) {
                if (root.player?.canGoNext) root.player.next()
            } else if (mouse.button === Qt.MiddleButton) {
                if (root.player?.canTogglePlaying) root.player.togglePlaying()
            }
        }

        onWheel: (wheel) => {
            if (root.player && root.player.volume !== undefined) {
                let delta = wheel.angleDelta.y > 0 ? 0.05 : -0.05
                root.player.volume = Math.max(0.0, Math.min(1.0, root.player.volume + delta))
            }
        }
    }

    PopupPanel {
        id: popup
        cardWidth: 400
        cardHeight: 330
        targetRelativeX: root.mapToItem(null, 0, 0).x + (root.width / 2)

        content: ColumnLayout {
            anchors.fill: parent
            spacing: Theme.widgetSpacing

            // Top bar header
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: "media playback"
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeLg
                    font.weight: Font.Bold
                    color: Theme.on_surface
                    Layout.fillWidth: true
                }

                Text {
                    text: root.player?.identity || "no player"
                    font.family: Theme.fontMono
                    font.pixelSize: Theme.fontSizeXs
                    color: Theme.primary
                    visible: root.player !== null
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Theme.widgetBorder
            }

            // Media Active Card
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: root.player !== null && root.hasTrack

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 12

                    // Album Art + Info Row
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 14

                        // Album art thumbnail
                        Rectangle {
                            Layout.preferredWidth: 84
                            Layout.preferredHeight: 84
                            radius: Theme.radiusMd
                            color: Theme.surface_container_highest
                            clip: true

                            Image {
                                anchors.fill: parent
                                source: root.player?.trackArtUrl || ""
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                visible: status === Image.Ready
                            }

                            Text {
                                anchors.centerIn: parent
                                text: Theme.iconMusic
                                font.family: Theme.fontMono
                                font.pixelSize: 28
                                color: Theme.on_surface_variant
                                visible: !(root.player?.trackArtUrl)
                            }
                        }

                        // Track Title & Artist Info
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 4

                            Text {
                                text: root.player?.trackTitle || "unknown track"
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeMd
                                font.weight: Font.Bold
                                color: Theme.on_surface
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                                maximumLineCount: 2
                                wrapMode: Text.Wrap
                            }

                            Text {
                                text: root.player?.trackArtist || "unknown artist"
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeSm
                                color: Theme.primary
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }

                            Text {
                                text: root.player?.trackAlbum || ""
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeXs
                                color: Theme.on_surface_variant
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                                visible: text !== ""
                            }
                        }
                    }

                    // Progress Track Slider
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4

                        Rectangle {
                            id: progressTrack
                            Layout.fillWidth: true
                            height: 6
                            radius: Theme.radiusPill
                            color: Theme.surface_container_highest

                            Rectangle {
                                width: {
                                    if (!root.player || !root.player.length || root.player.length <= 0) return 0
                                    return parent.width * Math.min(1.0, Math.max(0.0, (root.player.position ?? 0) / root.player.length))
                                }
                                height: parent.height
                                radius: Theme.radiusPill
                                color: Theme.primary
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: (mouse) => {
                                    if (root.player && root.player.length > 0 && width > 0) {
                                        root.player.position = (mouse.x / width) * root.player.length
                                    }
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true

                            Text {
                                text: {
                                    if (!root.player || root.player.position === undefined) return "0:00"
                                    let sec = Math.floor(root.player.position)
                                    let m = Math.floor(sec / 60)
                                    let s = sec % 60
                                    return m + ":" + (s < 10 ? "0" : "") + s
                                }
                                font.family: Theme.fontMono
                                font.pixelSize: 10
                                color: Theme.on_surface_variant
                            }

                            Item { Layout.fillWidth: true }

                            Text {
                                text: {
                                    if (!root.player || !root.player.length) return "0:00"
                                    let sec = Math.floor(root.player.length)
                                    let m = Math.floor(sec / 60)
                                    let s = sec % 60
                                    return m + ":" + (s < 10 ? "0" : "") + s
                                }
                                font.family: Theme.fontMono
                                font.pixelSize: 10
                                color: Theme.on_surface_variant
                            }
                        }
                    }

                    // Playback Controls Row
                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 16

                        IconButton {
                            icon: Theme.iconPrev
                            iconSize: Theme.fontSizeMd
                            tooltip: "previous track"
                            enabled: root.player?.canGoPrevious ?? false
                            onClicked: root.player?.previous()
                        }

                        Rectangle {
                            width: 44
                            height: 44
                            radius: Theme.radiusPill
                            color: playMouse.containsMouse ? Theme.primary_overlay : Theme.surface_container_highest

                            Behavior on color { ColorAnimation { duration: Theme.animFast } }

                            Text {
                                anchors.centerIn: parent
                                text: root.isPlaying ? Theme.iconPause : Theme.iconPlay
                                font.family: Theme.fontMono
                                font.pixelSize: Theme.fontSizeLg
                                color: Theme.primary
                            }

                            MouseArea {
                                id: playMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (root.player?.canTogglePlaying) root.player.togglePlaying()
                                }
                            }
                        }

                        IconButton {
                            icon: Theme.iconNext
                            iconSize: Theme.fontSizeMd
                            tooltip: "next track"
                            enabled: root.player?.canGoNext ?? false
                            onClicked: root.player?.next()
                        }
                    }
                }
            }

            // Empty State (When nothing is playing)
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: root.player === null || !root.hasTrack

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 10

                    Text {
                        text: Theme.kaoMusic
                        font.family: Theme.fontMono
                        font.pixelSize: 32
                        color: Theme.primary
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Text {
                        text: "nothing playing rn " + Theme.kaoShrug
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeMd
                        font.weight: Font.Bold
                        color: Theme.on_surface
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Text {
                        text: "start playback on spotify, browser, or mpv " + Theme.kaoHappy
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeXs
                        color: Theme.on_surface_variant
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Rectangle {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.topMargin: 8
                        width: 140
                        height: 32
                        radius: Theme.radiusPill
                        color: spotifyMouse.containsMouse ? Theme.primary : Theme.surface_container_high

                        Behavior on color { ColorAnimation { duration: Theme.animFast } }

                        Text {
                            anchors.centerIn: parent
                            text: "launch player 󰓇"
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeXs
                            font.weight: Font.Bold
                            color: spotifyMouse.containsMouse ? Theme.on_primary : Theme.on_surface
                        }

                        MouseArea {
                            id: spotifyMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                Quickshell.execDetached(["spotify"]);
                            }
                        }
                    }
                }
            }
        }
    }
}
