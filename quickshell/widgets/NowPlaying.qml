import QtQuick
import QtQuick.Layouts
import ".."
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Mpris

Rectangle {
    id: root

    property var musicApps: [
        { name: "mixtapes", id: "com.pocoguy.Muse", icon: Theme.iconRadio },
        { name: "amberol", id: "io.bassi.Amberol", icon: Theme.iconMusic },
        { name: "spotube", id: "com.github.KRTirtho.Spotube", icon: Theme.iconMusic },
        { name: "tauon", id: "com.github.taiko2k.tauonmb", icon: Theme.iconMusic },
        { name: "g4music", id: "com.github.neithern.g4music", icon: Theme.iconMusic },
        { name: "feishin", id: "org.feishin.feishin", icon: Theme.iconRadio },
        { name: "spotify", id: "com.spotify.Client", icon: Theme.iconMusic }
    ]
    property string preferredAppId: "com.pocoguy.Muse"
    readonly property var selectedApp: musicApps.find(a => a.id === preferredAppId) ?? musicApps[0]

    property bool dropdownOpen: false
    property int playerIndex: 0
    readonly property var activeList: Mpris.players.values

    // grabbing whatever is actively making sound before we lose our minds
    readonly property var player: {
        if (!activeList || activeList.length === 0) return null
        if (playerIndex >= 0 && playerIndex < activeList.length) {
            return activeList[playerIndex]
        }
        return activeList.find(p => p.isPlaying) ?? activeList[0] ?? null
    }

    property bool compactMode: false
    readonly property bool hasTrack: player !== null && Boolean(player.trackTitle || player.trackArtist)
    readonly property bool isPlaying: player?.isPlaying ?? false

    implicitWidth: {
        if (Theme.isVertical) return Theme.barHeight - 8;
        if ((!root.hasTrack || root.compactMode) && !npMouse.containsMouse && !popup.open) {
            return Theme.barHeight - 8;
        }
        return row.implicitWidth + (Theme.widgetPaddingH * 2) + 8;
    }
    implicitHeight: Theme.barHeight - 8
    radius: Theme.radiusPill
    color: popup.open ? Theme.primary_overlay : (npMouse.containsMouse ? Theme.pillHover : Theme.pillBg)
    border.color: Theme.pillBorder
    border.width: Theme.pillBorder === "transparent" ? 0 : 1
    clip: true

    Behavior on color { ColorAnimation { duration: Theme.animFast } }
    Behavior on border.color { ColorAnimation { duration: Theme.animFast } }
    Behavior on implicitWidth { NumberAnimation { duration: Theme.animNormal; easing.type: Theme.animEasing } }

    property real trackPosition: root.player?.position ?? 0

    Connections {
        target: root.player
        function onPositionChanged() {
            root.trackPosition = root.player?.position ?? 0;
        }
    }

    // poll position during playback so the seekbar glides
    Timer {
        id: tracker
        interval: 500
        running: popup.open && root.isPlaying
        repeat: true
        onTriggered: {
            if (root.player) root.trackPosition = root.player.position ?? 0;
        }
    }

    // local flatpaks spit raw paths without file:// that murder the image loader
    function fixCoverUrl(url) {
        if (!url || typeof url !== "string") return ""
        let cleaned = url.trim()
        if (cleaned.startsWith("/")) return "file://" + cleaned
        return cleaned
    }

    function runPlayer(appId) {
        let target = appId || root.preferredAppId
        if (!target) return
        if (target.includes(".")) {
            Quickshell.execDetached(["flatpak", "run", target])
        } else {
            Quickshell.execDetached([target])
        }
    }

    function togglePlayback() {
        if (!root.player) return
        if (root.player.canTogglePlaying) {
            root.player.togglePlaying()
        } else if (root.isPlaying && root.player.canPause) {
            root.player.pause()
        } else if (!root.isPlaying && root.player.canPlay) {
            root.player.play()
        }
    }

    function syncAnchor() {
        const coords = root.mapToItem(null, 0, 0)
        if (Theme.isVertical) {
            popup.targetRelativeY = coords.y + (root.height / 2)
        } else {
            popup.targetRelativeX = coords.x + (root.width / 2)
        }
    }

    Row {
        id: row
        spacing: Theme.widgetSpacing + 2
        anchors.centerIn: parent

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.isPlaying ? Theme.iconMusic : (root.hasTrack ? Theme.iconPause : Theme.iconMusic)
            font.family: Theme.fontIcon
            font.pixelSize: Theme.fontSizeSm
            color: root.isPlaying ? Theme.primary : Theme.on_surface_variant

            Behavior on color { ColorAnimation { duration: Theme.animFast } }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: !Theme.isVertical && (!root.compactMode || npMouse.containsMouse || popup.open) && (root.hasTrack || npMouse.containsMouse || popup.open)
            text: {
                if (root.hasTrack) {
                    let artist = root.player.trackArtist ? root.player.trackArtist + " - " : ""
                    let title = root.player.trackTitle || "unknown track"
                    return (artist + title).toLowerCase()
                }
                return npMouse.containsMouse 
                    ? Theme.getFlavor("media_quiet", Theme.getVibe(Theme.kaoShrug + " nothing playing rn", "nothing playing rn", "nothing playing"))
                    : Theme.getFlavor("media_quiet", Theme.getVibe(Theme.kaoEmpty + " quiet", "quiet", "quiet"))
            }
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeSm
            color: root.hasTrack ? Theme.on_surface : Theme.on_surface_variant
            elide: Text.ElideRight
            width: Math.min(implicitWidth, root.compactMode ? 100 : 160)
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
                root.syncAnchor()
                popup.open = !popup.open
            } else if (mouse.button === Qt.RightButton) {
                if (root.player?.canGoNext) root.player.next()
            } else if (mouse.button === Qt.MiddleButton) {
                root.togglePlayback()
            }
        }

        onWheel: (wheel) => {
            if (root.player && (root.player.volumeSupported ?? true)) {
                let delta = wheel.angleDelta.y > 0 ? 0.05 : -0.05
                let cur = (root.player.volume !== undefined && !isNaN(root.player.volume)) ? root.player.volume : 1.0
                root.player.volume = Math.max(0.0, Math.min(1.0, cur + delta))
            }
        }
    }

    PopupPanel {
        id: popup
        cardWidth: 420
        cardHeight: 340
        onOpenChanged: {
            if (!open) root.dropdownOpen = false
        }

        content: ColumnLayout {
            anchors.fill: parent
            spacing: Theme.widgetSpacing * 2

            // player pill so we can boot random browser audio out of focus
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

                Rectangle {
                    visible: root.activeList.length > 0
                    radius: Theme.radiusPill
                    color: switchHover.containsMouse ? Theme.primary_overlay : Theme.surface_container_highest
                    border.color: Theme.widgetBorder
                    border.width: 1
                    implicitWidth: switchRow.implicitWidth + 14
                    implicitHeight: 24

                    Behavior on color { ColorAnimation { duration: Theme.animFast } }

                    RowLayout {
                        id: switchRow
                        anchors.centerIn: parent
                        spacing: 4

                        Text {
                            text: (root.player?.identity || "player").toLowerCase()
                            font.family: Theme.fontMono
                            font.pixelSize: Theme.fontSizeXs
                            color: Theme.primary
                        }

                        Text {
                            text: root.activeList.length > 1 ? `(${root.playerIndex + 1}/${root.activeList.length}) 󰒭` : ""
                            font.family: Theme.fontMono
                            font.pixelSize: 10
                            color: Theme.on_surface_variant
                            visible: root.activeList.length > 1
                        }
                    }

                    MouseArea {
                        id: switchHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        enabled: root.activeList.length > 1
                        onClicked: {
                            root.playerIndex = (root.playerIndex + 1) % root.activeList.length
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Theme.widgetBorder
            }

            // active playback view
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: root.player !== null && root.hasTrack

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 12

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 14

                        Rectangle {
                            Layout.preferredWidth: 84
                            Layout.preferredHeight: 84
                            radius: Theme.radiusMd
                            color: Theme.surface_container_highest
                            clip: true

                            Image {
                                anchors.fill: parent
                                source: root.fixCoverUrl(root.player?.trackArtUrl)
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                visible: status === Image.Ready && source != ""
                            }

                            Text {
                                anchors.centerIn: parent
                                text: Theme.iconMusic
                                font.family: Theme.fontIcon
                                font.pixelSize: 28
                                color: Theme.on_surface_variant
                                visible: !(root.player?.trackArtUrl)
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 4

                            Text {
                                text: (root.player?.trackTitle || "unknown track").toLowerCase()
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
                                text: (root.player?.trackArtist || "unknown artist").toLowerCase()
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeSm
                                color: Theme.primary
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }

                            Text {
                                text: (root.player?.trackAlbum || "").toLowerCase()
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeXs
                                color: Theme.on_surface_variant
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                                visible: text !== ""
                            }
                        }
                    }

                    // seekbar that doesnt feel like dialup
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
                                    return parent.width * Math.min(1.0, Math.max(0.0, root.trackPosition / root.player.length))
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
                                    if (root.player && (root.player.canSeek ?? true) && root.player.length > 0 && width > 0) {
                                        let posFrac = Math.max(0.0, Math.min(1.0, mouse.x / width))
                                        root.player.position = posFrac * root.player.length
                                        root.trackPosition = root.player.position
                                    }
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true

                            Text {
                                text: {
                                    if (!root.player || root.trackPosition === undefined) return "0:00"
                                    let sec = Math.floor(root.trackPosition)
                                    let m = Math.floor(sec / 60)
                                    let s = sec % 60
                                    return m + ":" + (s < 10 ? "0" : "") + s
                                }
                                font.family: Theme.fontMono
                                font.pixelSize: Theme.fontSizeXs
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
                                font.pixelSize: Theme.fontSizeXs
                                color: Theme.on_surface_variant
                            }
                        }
                    }

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
                                font.family: Theme.fontIcon
                                font.pixelSize: Theme.fontSizeLg
                                color: Theme.primary
                            }

                            MouseArea {
                                id: playMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.togglePlayback()
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

            // empty state with smooth dropdown drawer
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: root.player === null || !root.hasTrack

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 8
                    width: parent.width - 24

                    Text {
                        text: Theme.getVibe(Theme.kaoSilent, Theme.iconHeadphones, "󰋋")
                        font.family: Theme.fontIcon
                        font.pixelSize: 28
                        color: Theme.on_surface_variant
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Text {
                        text: Theme.getFlavor("media_quiet", Theme.getVibe("quiet right now", "no players active", "nothing playing"))
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeSm
                        color: Theme.on_surface_variant
                        Layout.alignment: Qt.AlignHCenter
                    }

                    // dropdown trigger + launch action
                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredWidth: parent.width
                        Layout.topMargin: 4
                        spacing: 8

                        Rectangle {
                            Layout.fillWidth: true
                            height: 34
                            radius: Theme.radiusMd
                            color: dropHover.containsMouse ? Theme.surface_container_highest : Theme.surface_container_high
                            border.color: root.dropdownOpen ? Theme.primary : Theme.widgetBorder
                            border.width: 1

                            Behavior on color { ColorAnimation { duration: Theme.animFast } }
                            Behavior on border.color { ColorAnimation { duration: Theme.animFast } }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 10
                                spacing: 8

                                Text {
                                    text: root.selectedApp?.icon || Theme.iconMusic
                                    font.family: Theme.fontIcon
                                    font.pixelSize: Theme.fontSizeSm
                                    color: Theme.primary
                                }

                                Text {
                                    text: (root.selectedApp?.name || "choose app").toLowerCase()
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSizeXs
                                    font.weight: Font.DemiBold
                                    color: Theme.on_surface
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                }

                                Text {
                                    text: root.dropdownOpen ? Theme.iconChevronUp : Theme.iconChevronDown
                                    font.family: Theme.fontIcon
                                    font.pixelSize: Theme.fontSizeXs
                                    color: Theme.on_surface_variant
                                }
                            }

                            MouseArea {
                                id: dropHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.dropdownOpen = !root.dropdownOpen
                            }
                        }

                        Rectangle {
                            Layout.preferredWidth: 84
                            height: 34
                            radius: Theme.radiusMd
                            color: launchHover.containsMouse ? Theme.primary : Theme.surface_container_high
                            border.color: Theme.primary
                            border.width: 1

                            Behavior on color { ColorAnimation { duration: Theme.animFast } }

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 4

                                Text {
                                    text: "launch"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSizeXs
                                    font.weight: Font.Bold
                                    color: launchHover.containsMouse ? Theme.on_primary : Theme.on_surface
                                }

                                Text {
                                    text: Theme.iconPlay
                                    font.family: Theme.fontIcon
                                    font.pixelSize: 10
                                    color: launchHover.containsMouse ? Theme.on_primary : Theme.primary
                                }
                            }

                            MouseArea {
                                id: launchHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.runPlayer(root.preferredAppId)
                            }
                        }
                    }

                    // expandable drawer without clip bugs
                    Rectangle {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredWidth: parent.width
                        height: root.dropdownOpen ? Math.min(drawerCol.implicitHeight + 8, 136) : 0
                        visible: height > 0
                        clip: true
                        radius: Theme.radiusMd
                        color: Theme.surface_container_low
                        border.color: Theme.widgetBorder
                        border.width: 1

                        Behavior on height { NumberAnimation { duration: Theme.animFast; easing.type: Theme.animEasing } }

                        Flickable {
                            anchors.fill: parent
                            anchors.margins: 4
                            contentHeight: drawerCol.implicitHeight
                            clip: true
                            boundsBehavior: Flickable.StopAtBounds

                            ColumnLayout {
                                id: drawerCol
                                width: parent.width
                                spacing: 2

                                Repeater {
                                    model: root.musicApps

                                    Rectangle {
                                        required property var modelData
                                        Layout.fillWidth: true
                                        height: 28
                                        radius: Theme.radiusSm
                                        color: itemHover.containsMouse 
                                            ? Theme.primary_overlay 
                                            : (root.preferredAppId === modelData.id ? Theme.surface_container_highest : "transparent")

                                        Behavior on color { ColorAnimation { duration: Theme.animFast } }

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: 8
                                            anchors.rightMargin: 8
                                            spacing: 6

                                            Text {
                                                text: modelData.icon
                                                font.family: Theme.fontIcon
                                                font.pixelSize: Theme.fontSizeXs
                                                color: root.preferredAppId === modelData.id ? Theme.primary : Theme.on_surface_variant
                                            }

                                            Text {
                                                text: modelData.name.toLowerCase()
                                                font.family: Theme.fontFamily
                                                font.pixelSize: Theme.fontSizeXs
                                                color: root.preferredAppId === modelData.id ? Theme.on_surface : Theme.on_surface_variant
                                                Layout.fillWidth: true
                                                elide: Text.ElideRight
                                            }

                                            Text {
                                                text: Theme.iconCheck
                                                font.family: Theme.fontIcon
                                                font.pixelSize: Theme.fontSizeXs
                                                color: Theme.primary
                                                visible: root.preferredAppId === modelData.id
                                            }
                                        }

                                        MouseArea {
                                            id: itemHover
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                root.preferredAppId = modelData.id
                                                root.dropdownOpen = false
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
