// NowPlaying.qml
import QtQuick
import QtQuick.Layouts
import ".."
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import "../controls"

Rectangle {
    id: root

    // Native PipeWire audio peak monitor
    PwNodePeakMonitor {
        id: peakMonitor
        node: (typeof Pipewire !== "undefined") ? Pipewire?.defaultAudioSink : null
        enabled: root.isPlaying && (popup.open || (Settings?.mediaWaveVisualizer ?? true))
    }

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
    property int manualPlayerIndex: -1
    readonly property var activeList: Mpris.players.values ?? []

    // Prefer an actively playing stream unless the user manually cycled to a specific player
    readonly property var player: {
        if (!activeList || activeList.length === 0) return null;
        if (manualPlayerIndex >= 0 && manualPlayerIndex < activeList.length) {
            let manual = activeList[manualPlayerIndex];
            if (manual && manual.isPlaying) return manual;
            let otherPlaying = activeList.find(p => p.isPlaying);
            if (!otherPlaying) return manual;
        }
        return activeList.find(p => p.isPlaying) ?? activeList.find(p => p.trackTitle) ?? activeList[0] ?? null;
    }

    readonly property int currentPlayerIdx: {
        if (!player || !activeList) return 0;
        let idx = activeList.indexOf(player);
        return idx >= 0 ? idx : 0;
    }

    property bool compactMode: false
    readonly property bool hasTrack: player !== null && Boolean(player.trackTitle || player.trackArtist)
    readonly property bool isPlaying: player?.isPlaying ?? false
    readonly property string coverArtUrl: fixCoverUrl(player?.trackArtUrl)

    // Extract accent color from album art so the player card adapts to the cover
    ColorQuantizer {
        id: artQuantizer
        depth: 2
        source: root.coverArtUrl
    }

    readonly property color artAccent: {
        if (root.coverArtUrl !== "" && artQuantizer.colors && artQuantizer.colors.length > 0) {
            for (let i = 0; i < artQuantizer.colors.length; i++) {
                let c = artQuantizer.colors[i];
                if (!c) continue;
                let mx = Math.max(c.r, c.g, c.b);
                let mn = Math.min(c.r, c.g, c.b);
                if (mx > 0.25 && (mx - mn) > 0.15) {
                    return Theme.blend(c, Theme.primary, 0.35);
                }
            }
        }
        return Theme.primary;
    }

    readonly property bool isCollapsed: (!root.hasTrack || root.compactMode) && !npMouse.containsMouse && !popup.open
    readonly property bool isWideIcon: Theme.iconSet === "kaomoji" || Theme.iconSet === "text"

    implicitWidth: {
        if (Theme.isVertical) return Theme.barHeight - 8;
        if (root.isCollapsed) {
            return root.isWideIcon ? Math.max(Theme.barHeight - 8, barIcon.implicitWidth + 14) : (Theme.barHeight - 8);
        }
        return row.implicitWidth + (Theme.widgetPaddingH * 2) + 8;
    }
    implicitHeight: Theme.barHeight - 8
    radius: Theme.radiusPill
    color: popup.open ? Theme.primary_overlay : (npMouse.containsMouse ? Theme.pillHover : Theme.pillBg)
    border.color: popup.open ? Theme.alpha(Theme.primary, 0.5) : Theme.pillBorder
    border.width: (popup.open || Theme.pillBorder !== "transparent") ? 1 : 0
    clip: true

    Behavior on color { ColorAnimation { duration: Theme.animFast; easing.type: Theme.animColorEasing } }
    Behavior on border.color { ColorAnimation { duration: Theme.animFast; easing.type: Theme.animColorEasing } }
    Behavior on implicitWidth { NumberAnimation { duration: Theme.animNormal; easing.type: Theme.animEasing } }

    property real trackPosition: root.player?.position ?? 0
    property real wavePhase: 0.0

    Connections {
        target: root.player
        function onPositionChanged() {
            root.trackPosition = root.player?.position ?? 0;
        }
    }

    // Smooth timer for seekbar + animated spectrum phase
    Timer {
        id: tracker
        interval: popup.open ? 60 : 400
        running: root.isPlaying && (popup.open || (Settings?.mediaWaveVisualizer ?? true))
        repeat: true
        onTriggered: {
            if (root.player && popup.open) root.trackPosition = root.player.position ?? 0;
            root.wavePhase = (root.wavePhase + 0.32) % (Math.PI * 20);
        }
    }

    function fixCoverUrl(url) {
        if (!url || typeof url !== "string") return "";
        let cleaned = url.trim();
        if (cleaned.startsWith("/")) return "file://" + cleaned;
        return cleaned;
    }

    function formatTime(seconds) {
        if (seconds === undefined || seconds === null || isNaN(seconds) || seconds < 0) return "0:00";
        let sec = Math.floor(seconds);
        let m = Math.floor(sec / 60);
        let s = sec % 60;
        return m + ":" + (s < 10 ? "0" : "") + s;
    }

    function runPlayer(appId) {
        let target = appId || root.preferredAppId;
        if (!target) return;
        if (target.includes(".")) {
            Quickshell.execDetached(["flatpak", "run", target]);
        } else {
            Quickshell.execDetached([target]);
        }
    }

    function togglePlayback() {
        if (!root.player) return;
        if (root.player.canTogglePlaying) {
            root.player.togglePlaying();
        } else if (root.isPlaying && root.player.canPause) {
            root.player.pause();
        } else if (!root.isPlaying && root.player.canPlay) {
            root.player.play();
        }
    }

    function cycleLoopState() {
        if (!root.player || !root.player.loopSupported) return;
        let cur = root.player.loopState;
        if (cur === MprisLoopState.None) {
            root.player.loopState = MprisLoopState.Playlist;
        } else if (cur === MprisLoopState.Playlist) {
            root.player.loopState = MprisLoopState.Track;
        } else {
            root.player.loopState = MprisLoopState.None;
        }
    }

    function syncAnchor() {
        const coords = root.mapToItem(null, 0, 0);
        if (Theme.isVertical) {
            popup.targetRelativeY = coords.y + (root.height / 2);
        } else {
            popup.targetRelativeX = coords.x + (root.width / 2);
        }
    }

    Row {
        id: row
        spacing: Theme.widgetSpacing + 2
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: (!Theme.isVertical && !root.isCollapsed) ? parent.left : undefined
        anchors.leftMargin: Theme.widgetPaddingH + 4
        anchors.horizontalCenter: (Theme.isVertical || root.isCollapsed) ? parent.horizontalCenter : undefined

        Text {
            id: barIcon
            anchors.verticalCenter: parent.verticalCenter
            text: root.isPlaying
                ? (Theme.iconSet === "kaomoji" ? Theme.kaoJam : Theme.iconMusic)
                : (root.hasTrack ? Theme.iconPause : Theme.iconMusic)
            font.family: Theme.fontIcon
            font.pixelSize: root.isWideIcon ? Theme.fontSizeXs : Theme.fontSizeSm
            font.weight: root.isWideIcon ? Theme.fontWeightBold : Theme.fontWeightRegular
            color: root.isPlaying ? Theme.primary : Theme.on_surface_variant

            Behavior on color { ColorAnimation { duration: Theme.animFast; easing.type: Theme.animColorEasing } }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: !Theme.isVertical && !root.isCollapsed
            text: {
                if (root.hasTrack) {
                    let artist = root.player.trackArtist ? root.player.trackArtist + " - " : "";
                    let title = root.player.trackTitle || "unknown track";
                    return (artist + title).toLowerCase();
                }
                return npMouse.containsMouse
                    ? Theme.getFlavor("media_quiet", Theme.getVibe(Theme.kaoShrug + " nothing playing rn", "nothing playing rn", "nothing playing"))
                    : Theme.getFlavor("media_quiet", Theme.getVibe(Theme.kaoEmpty + " quiet", "quiet", "quiet"));
            }
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeSm
            color: root.hasTrack ? Theme.on_surface : Theme.on_surface_variant
            elide: Text.ElideRight
            width: Math.min(implicitWidth, root.compactMode ? 100 : 170)
        }

        // Bar mini equalizer
        Row {
            visible: root.isPlaying && (Settings?.mediaWaveVisualizer ?? true) && !Theme.isVertical
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2
            height: 12

            Repeater {
                model: 4
                Rectangle {
                    required property int index
                    width: 2
                    radius: 1
                    color: Theme.primary
                    anchors.verticalCenter: parent.verticalCenter

                    height: {
                        if (!root.isPlaying) return 2;
                        let p = (typeof peakMonitor !== "undefined" && peakMonitor.peak !== undefined) ? peakMonitor.peak : 0;
                        let wave = Math.abs(Math.sin(root.wavePhase + index * 1.1));
                        if (p > 0.01) {
                            return Math.max(3, Math.min(12, Math.round((p * 9) + (wave * 5))));
                        }
                        return Math.max(3, Math.round(3 + wave * 5));
                    }

                    Behavior on height {
                        NumberAnimation {
                            duration: 90
                            easing.type: Easing.OutQuad
                        }
                    }
                }
            }
        }
    }

    HoverFlyoutHandler {
        popup: popup
        mouseArea: npMouse
        updatePos: () => root.syncAnchor()
    }

    MouseArea {
        id: npMouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        cursorShape: Qt.PointingHandCursor

        onClicked: (mouse) => {
            if (mouse.button === Qt.LeftButton) {
                root.syncAnchor();
                if (!popup.open) {
                    popup.pinned = true;
                    popup.open = true;
                } else if (!popup.pinned) {
                    popup.pinned = true;
                } else {
                    popup.pinned = false;
                    popup.open = false;
                }
            } else if (mouse.button === Qt.RightButton) {
                if (root.player?.canGoNext) root.player.next();
            } else if (mouse.button === Qt.MiddleButton) {
                root.togglePlayback();
            }
        }

        onWheel: (wheel) => {
            if (root.player && (root.player.volumeSupported ?? true)) {
                let delta = wheel.angleDelta.y > 0 ? 0.05 : -0.05;
                let cur = (root.player.volume !== undefined && !isNaN(root.player.volume)) ? root.player.volume : 1.0;
                root.player.volume = Math.max(0.0, Math.min(1.0, cur + delta));
            }
        }
    }

    Connections {
        target: Settings
        function onRequestMediaToggle() {
            root.syncAnchor();
            popup.open = !popup.open;
        }
        function onRequestMediaOpen() {
            root.syncAnchor();
            popup.open = true;
        }
        function onRequestMediaClose() {
            popup.open = false;
        }
    }

    PopupPanel {
        id: popup
        cardWidth: 420
        cardHeight: Math.max(Theme.popupMinHeight, Math.min(Theme.popupMaxHeight, mediaContentLayout.implicitHeight + (Theme.popupPadding * 2)))
        onOpenChanged: {
            if (!open) root.dropdownOpen = false;
        }

        content: ColumnLayout {
            id: mediaContentLayout
            anchors.fill: parent
            spacing: 10

            // Header + player switcher pill
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: root.isPlaying && Theme.iconSet === "kaomoji"
                        ? "media playback " + Theme.kaoDJ
                        : "media playback"
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeLg
                    font.weight: Theme.fontWeightBold
                    color: Theme.on_surface
                    Layout.fillWidth: true
                }

                Rectangle {
                    visible: root.activeList.length > 0
                    radius: Theme.radiusPill
                    color: switchHover.containsMouse
                        ? Theme.stateHover(Theme.surface_container_highest, root.artAccent)
                        : Theme.surface_container_highest
                    border.color: switchHover.containsMouse ? Theme.alpha(root.artAccent, 0.5) : Theme.widgetBorder
                    border.width: 1
                    implicitWidth: switchRow.implicitWidth + 16
                    implicitHeight: 26

                    Behavior on color { ColorAnimation { duration: Theme.animFast } }
                    Behavior on border.color { ColorAnimation { duration: Theme.animFast } }

                    RowLayout {
                        id: switchRow
                        anchors.centerIn: parent
                        spacing: 5

                        Text {
                            text: (root.player?.identity || "player").toLowerCase()
                            font.family: Theme.fontMono
                            font.pixelSize: Theme.fontSizeXs
                            font.weight: Theme.fontWeightBold
                            color: root.artAccent
                        }

                        Text {
                            visible: root.activeList.length > 1
                            text: "(" + (root.currentPlayerIdx + 1) + "/" + root.activeList.length + ")"
                            font.family: Theme.fontMono
                            font.pixelSize: Theme.fontSizeXs
                            color: Theme.on_surface_variant
                        }

                        Text {
                            visible: root.activeList.length > 1
                            text: Theme.iconChevronRight
                            font.family: Theme.fontIcon
                            font.pixelSize: Theme.fontSizeXs
                            color: Theme.on_surface_variant
                        }
                    }

                    MouseArea {
                        id: switchHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: root.activeList.length > 1 ? Qt.PointingHandCursor : Qt.ArrowCursor
                        enabled: root.activeList.length > 1
                        onClicked: {
                            root.manualPlayerIndex = (root.currentPlayerIdx + 1) % root.activeList.length;
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Theme.widgetBorder
            }

            // Active playback card
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 12
                visible: root.player !== null && root.hasTrack

                // Hero track banner with tinted backdrop
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: heroRow.implicitHeight + 20
                    radius: Theme.radiusLg
                    color: Theme.blend(Theme.cardBg, root.artAccent, root.isPlaying ? 0.14 : 0.05)
                    border.color: Theme.alpha(root.artAccent, root.isPlaying ? 0.35 : 0.15)
                    border.width: 1

                    Behavior on color { ColorAnimation { duration: Theme.animSlow } }
                    Behavior on border.color { ColorAnimation { duration: Theme.animSlow } }

                    RowLayout {
                        id: heroRow
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 14

                        // True rounded-corner album cover via ClippingRectangle
                        Item {
                            Layout.preferredWidth: 88
                            Layout.preferredHeight: 88

                            Rectangle {
                                anchors.fill: parent
                                anchors.margins: -3
                                radius: Theme.radiusMd + 3
                                color: Theme.alpha(root.artAccent, root.isPlaying ? 0.32 : 0.10)
                                Behavior on color { ColorAnimation { duration: Theme.animNormal } }
                            }

                            ClippingRectangle {
                                anchors.fill: parent
                                radius: Theme.radiusMd
                                color: Theme.surface_container_highest

                                Image {
                                    anchors.fill: parent
                                    source: root.coverArtUrl
                                    fillMode: Image.PreserveAspectCrop
                                    asynchronous: true
                                    visible: status === Image.Ready && source != ""
                                    scale: coverMouse.containsMouse ? 1.05 : 1.0
                                    Behavior on scale { NumberAnimation { duration: Theme.animNormal; easing.type: Easing.OutQuad } }
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: Theme.iconSet === "kaomoji" ? Theme.kaoMusic : Theme.iconMusic
                                    font.family: Theme.fontIcon
                                    font.pixelSize: root.isWideIcon ? Theme.fontSizeMd : 28
                                    color: root.artAccent
                                    visible: root.coverArtUrl === ""
                                }

                                // Hover play/pause overlay on the album art
                                Rectangle {
                                    anchors.fill: parent
                                    color: Qt.rgba(0, 0, 0, coverMouse.containsMouse ? 0.38 : 0.0)
                                    Behavior on color { ColorAnimation { duration: Theme.animFast } }

                                    Text {
                                        anchors.centerIn: parent
                                        opacity: coverMouse.containsMouse ? 1.0 : 0.0
                                        scale: coverMouse.containsMouse ? 1.0 : 0.8
                                        text: root.isPlaying ? Theme.iconPause : Theme.iconPlay
                                        font.family: Theme.fontIcon
                                        font.pixelSize: Theme.fontSizeLg
                                        color: "#ffffff"
                                        Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
                                        Behavior on scale { NumberAnimation { duration: Theme.animFast; easing.type: Easing.OutBack } }
                                    }
                                }

                                MouseArea {
                                    id: coverMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.togglePlayback()
                                    onWheel: (wheel) => {
                                        if (root.player && root.player.volume !== undefined) {
                                            root.player.volume = Math.max(0.0, Math.min(1.0, root.player.volume + (wheel.angleDelta.y > 0 ? 0.05 : -0.05)));
                                        }
                                    }
                                }
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 4

                            Text {
                                text: (root.player?.trackTitle || "unknown track").toLowerCase()
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeMd
                                font.weight: Theme.fontWeightBold
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
                                font.weight: Theme.fontWeightDemiBold
                                color: root.artAccent
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                                Behavior on color { ColorAnimation { duration: Theme.animNormal } }
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

                            // Flavor subtitle or kaomoji vibe badge
                            Text {
                                visible: root.isPlaying && ((Settings?.unhingedFlavor ?? false) || Theme.iconSet === "kaomoji")
                                text: Theme.getFlavor("media_playing", Theme.getVibe(Theme.kaoVibe + " vibing", "", ""))
                                font.family: Theme.fontVibe
                                font.pixelSize: Theme.fontSizeXs
                                color: Theme.alpha(Theme.on_surface_variant, 0.8)
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }
                        }
                    }
                }

                // Seekbar + timestamps
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    WavyProgress {
                        id: progressTrack
                        Layout.fillWidth: true
                        Layout.preferredHeight: 22
                        from: 0
                        to: (root.player && root.player.length > 0) ? root.player.length : 1
                        value: root.trackPosition
                        playing: root.isPlaying
                        audioPeak: (typeof peakMonitor !== "undefined" && peakMonitor.peak !== undefined) ? peakMonitor.peak : 0.0
                        interactive: root.player && (root.player.canSeek ?? true) && root.player.length > 0
                        onSeekRequested: (pos) => {
                            if (root.player && (root.player.canSeek ?? true) && root.player.length > 0) {
                                root.player.position = pos;
                                root.trackPosition = pos;
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true

                        Text {
                            text: root.formatTime(root.trackPosition)
                            font.family: Theme.fontMono
                            font.pixelSize: Theme.fontSizeXs
                            color: Theme.on_surface_variant
                        }

                        Item { Layout.fillWidth: true }

                        Text {
                            text: root.formatTime(root.player?.length ?? 0)
                            font.family: Theme.fontMono
                            font.pixelSize: Theme.fontSizeXs
                            color: Theme.on_surface_variant
                        }
                    }
                }

                // 24-band reactive spectrum visualizer
                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 26
                    spacing: 3
                    visible: Settings?.mediaWaveVisualizer ?? true

                    Repeater {
                        model: 24
                        Rectangle {
                            required property int index
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignBottom
                            radius: 2

                            readonly property real env: {
                                let norm = index / 23.0;
                                return Math.sin(norm * Math.PI) * 0.72 + 0.28;
                            }

                            readonly property real chPeak: {
                                let pList = (typeof peakMonitor !== "undefined" && peakMonitor.peaks && peakMonitor.peaks.length > 0)
                                    ? peakMonitor.peaks
                                    : [];
                                if (pList.length >= 2) {
                                    let mix = index / 23.0;
                                    return (pList[0] * (1.0 - mix)) + (pList[1] * mix);
                                }
                                return (typeof peakMonitor !== "undefined" && peakMonitor.peak !== undefined) ? peakMonitor.peak : 0;
                            }

                            height: {
                                if (!root.isPlaying) return 3;
                                let p = chPeak;
                                let ripple = Math.sin((index * 0.65) + root.wavePhase) * 0.3 + Math.cos((index * 1.2) - root.wavePhase * 0.7) * 0.2;
                                if (p > 0.008) {
                                    let target = (p * env * 24) + (Math.abs(ripple) * 10 * Math.min(1.0, p * 3.5));
                                    return Math.max(3, Math.min(26, Math.round(target)));
                                }
                                return Math.max(3, Math.round(3 + Math.abs(ripple) * 4));
                            }

                            color: {
                                if (!root.isPlaying) return Theme.surface_container_highest;
                                if (chPeak > 0.55) return Theme.tertiary;
                                if (chPeak > 0.18) return root.artAccent;
                                return Theme.alpha(root.artAccent, 0.45);
                            }

                            Behavior on height {
                                NumberAnimation {
                                    duration: 75
                                    easing.type: Easing.OutQuad
                                }
                            }

                            Behavior on color { ColorAnimation { duration: Theme.animFast } }
                        }
                    }
                }

                // Transport controls: Shuffle | Prev | Play/Pause | Next | Repeat + Player Volume
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    // Shuffle button
                    Rectangle {
                        visible: root.player?.shuffleSupported ?? false
                        width: 32
                        height: 32
                        radius: Theme.radiusPill
                        color: (root.player?.shuffle ?? false)
                            ? Theme.alpha(root.artAccent, 0.22)
                            : (shufMouse.containsMouse ? Theme.surface_container_highest : "transparent")

                        Text {
                            anchors.centerIn: parent
                            text: Theme.iconShuffle
                            font.family: Theme.fontIcon
                            font.pixelSize: Theme.fontSizeSm
                            color: (root.player?.shuffle ?? false) ? root.artAccent : Theme.on_surface_variant
                        }

                        MouseArea {
                            id: shufMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (root.player) root.player.shuffle = !root.player.shuffle;
                            }
                        }
                    }

                    Item { Layout.fillWidth: true }

                    IconButton {
                        icon: Theme.iconPrev
                        iconSize: Theme.fontSizeMd
                        tooltip: "previous track"
                        enabled: root.player?.canGoPrevious ?? false
                        onClicked: root.player?.previous()
                    }

                    // Squishy primary Play/Pause pill
                    Rectangle {
                        width: root.isPlaying ? 54 : 44
                        height: 42
                        radius: root.isPlaying ? Theme.radiusMd : Theme.radiusPill
                        color: playMouse.pressed
                            ? Theme.statePress(root.artAccent, Theme.on_primary)
                            : (playMouse.containsMouse
                                ? Theme.stateHover(root.artAccent, Theme.on_primary)
                                : root.artAccent)

                        Behavior on width { NumberAnimation { duration: Theme.expressiveFast; easing.type: Theme.animExpressiveEasing } }
                        Behavior on radius { NumberAnimation { duration: Theme.animNormal; easing.type: Theme.animEasing } }
                        Behavior on color { ColorAnimation { duration: Theme.animFast } }

                        Text {
                            anchors.centerIn: parent
                            text: root.isPlaying ? Theme.iconPause : Theme.iconPlay
                            font.family: Theme.fontIcon
                            font.pixelSize: root.isWideIcon ? Theme.fontSizeSm : Theme.fontSizeLg
                            font.weight: Theme.fontWeightBold
                            color: Theme.on_primary
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

                    Item { Layout.fillWidth: true }

                    // Loop / Repeat button
                    Rectangle {
                        visible: root.player?.loopSupported ?? false
                        width: 32
                        height: 32
                        radius: Theme.radiusPill
                        readonly property bool loopActive: (root.player?.loopState ?? MprisLoopState.None) !== MprisLoopState.None
                        color: loopActive
                            ? Theme.alpha(root.artAccent, 0.22)
                            : (loopMouse.containsMouse ? Theme.surface_container_highest : "transparent")

                        Text {
                            anchors.centerIn: parent
                            text: (root.player?.loopState === MprisLoopState.Track) ? Theme.iconRepeatOne : Theme.iconRepeat
                            font.family: Theme.fontIcon
                            font.pixelSize: Theme.fontSizeSm
                            color: parent.loopActive ? root.artAccent : Theme.on_surface_variant
                        }

                        MouseArea {
                            id: loopMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.cycleLoopState()
                        }
                    }
                }
            }

            // Empty state with smooth dropdown drawer
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: emptyCol.implicitHeight + 16
                visible: root.player === null || !root.hasTrack

                ColumnLayout {
                    id: emptyCol
                    anchors.centerIn: parent
                    spacing: 8
                    width: parent.width - 12

                    Text {
                        text: Theme.getVibe(Theme.kaoSilent, Theme.iconHeadphones, Theme.iconHeadphones)
                        font.family: Theme.fontIcon
                        font.pixelSize: root.isWideIcon ? Theme.fontSizeXl : 28
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

                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.fillWidth: true
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
                                    font.weight: Theme.fontWeightDemiBold
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
                            Layout.preferredWidth: 88
                            height: 34
                            radius: Theme.radiusMd
                            color: launchHover.containsMouse ? Theme.primary : Theme.surface_container_high
                            border.color: Theme.primary
                            border.width: 1

                            Behavior on color { ColorAnimation { duration: Theme.animFast } }

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 5

                                Text {
                                    text: "launch"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSizeXs
                                    font.weight: Theme.fontWeightBold
                                    color: launchHover.containsMouse ? Theme.on_primary : Theme.on_surface
                                }

                                Text {
                                    text: Theme.iconPlay
                                    font.family: Theme.fontIcon
                                    font.pixelSize: Theme.fontSizeXs
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

                    Rectangle {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.fillWidth: true
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
                                                root.preferredAppId = modelData.id;
                                                root.dropdownOpen = false;
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
