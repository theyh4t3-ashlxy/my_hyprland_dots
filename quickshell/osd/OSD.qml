// OSD.qml
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import ".."
import "../services"

PanelWindow {
    id: osdRoot
    required property var modelData
    screen: modelData
    color: "transparent"

    readonly property var root: osdRoot
    readonly property bool showing: revealed || osdCard.opacity > 0
    visible: root.showing

    anchors {
        bottom: true
    }
    margins {
        bottom: 72
    }

    // Extra room around the card so OutBack scaling and glow dont get clipped
    implicitWidth: Math.max(340, osdCard.width + 40)
    implicitHeight: 96

    WlrLayershell.namespace: "quickshell:osd"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore

    mask: Region {
        item: (revealed || osdCard.opacity > 0) ? osdCard : null
    }

    property bool _ready: false
    property bool revealed: false
    property string osdType: "volume"
    property string osdSubtitle: ""
    property string osdIcon: Theme.iconVolHigh
    property int osdValue: 50
    property string osdLabel: "50%"

    readonly property bool isVolume: osdType.startsWith("volume")
    readonly property bool isMic: osdType === "mic"
    readonly property bool isBrightness: osdType === "brightness"
    readonly property bool isOverAmp: isVolume && osdValue > 100
    readonly property bool isMuted: (isMic && (source?.audio?.muted ?? false)) ||
                                    (isVolume && (sink?.audio?.muted ?? false))

    readonly property bool isKaomoji: (Theme.iconSet === "kaomoji" || Theme.iconSet === "text" || osdIcon.length > 2)
    readonly property color activeColor: isMuted
        ? (Theme.error ?? "#ff5449")
        : (isOverAmp ? (Theme.warn ?? "#ffb4ab") : Theme.primary)
    readonly property color activeOverlay: isMuted
        ? Theme.error_overlay
        : (isOverAmp ? Theme.warn_overlay : Theme.primary_overlay)

    property var sink: Pipewire.defaultAudioSink
    property var source: Pipewire.defaultAudioSource
    PwObjectTracker { objects: [osdRoot.sink, osdRoot.source] }

    Timer {
        id: initTimer
        interval: 1200
        running: true
        repeat: false
        onTriggered: osdRoot._ready = true
    }

    Timer {
        id: dismissTimer
        interval: 1800
        repeat: false
        onTriggered: osdRoot.revealed = false
    }

    function show(type, icon, value, label, subtitle) {
        if (!_ready) return;
        osdType = type;
        osdIcon = icon;
        osdValue = Math.max(0, value);
        osdLabel = label;
        osdSubtitle = subtitle ?? "";
        revealed = true;
        if (!cardMouseArea.containsMouse && !sliderDragArea.pressed) {
            dismissTimer.restart();
        }
    }

    function setLevelFromRatio(ratio) {
        let clamped = Math.min(1.0, Math.max(0.0, ratio));
        if (osdRoot.isVolume && osdRoot.sink?.audio) {
            if (osdRoot.sink.audio.muted) osdRoot.sink.audio.muted = false;
            osdRoot.sink.audio.volume = clamped * 1.5;
        } else if (osdRoot.isMic && osdRoot.source?.audio) {
            if (osdRoot.source.audio.muted) osdRoot.source.audio.muted = false;
            osdRoot.source.audio.volume = clamped;
        } else if (osdRoot.isBrightness && typeof BrightnessService !== "undefined") {
            let pct = Math.round(clamped * 100);
            if (BrightnessService.setBrightness) {
                BrightnessService.setBrightness(pct);
            }
        }
    }

    function stepLevel(direction) {
        let delta = direction > 0 ? 0.02 : -0.02;
        if (osdRoot.isVolume && osdRoot.sink?.audio) {
            osdRoot.sink.audio.volume = Math.min(1.5, Math.max(0, osdRoot.sink.audio.volume + delta));
        } else if (osdRoot.isMic && osdRoot.source?.audio) {
            osdRoot.source.audio.volume = Math.min(1.0, Math.max(0, osdRoot.source.audio.volume + delta));
        } else if (osdRoot.isBrightness && typeof BrightnessService !== "undefined") {
            let step = direction > 0 ? 2 : -2;
            let nextPct = Math.min(100, Math.max(1, osdRoot.osdValue + step));
            if (BrightnessService.setBrightness) {
                BrightnessService.setBrightness(nextPct);
            }
        }
    }

    // Pop the icon slightly when it changes
    onOsdIconChanged: {
        iconPopAnim.restart();
    }

    // Show OSD when switching headphones/speakers
    onSinkChanged: {
        if (!osdRoot._ready || !osdRoot.sink?.audio) return;
        let vRatio = osdRoot.sink.audio.volume;
        let vol = Math.round(vRatio * 100);
        let m = osdRoot.sink.audio.muted;
        let icon = Theme.getVolumeIcon(vRatio, m);
        let devName = osdRoot.sink.description || osdRoot.sink.name || "";
        osdRoot.show(vol > 100 ? "volume boost" : "volume", icon, m ? 0 : vol, m ? "muted" : (vol + "%"), devName);
    }

    Connections {
        target: osdRoot.sink?.audio ?? null
        function onVolumeChanged() {
            if (!osdRoot._ready || !osdRoot.sink?.audio) return;
            let vRatio = osdRoot.sink.audio.volume;
            let vol = Math.round(vRatio * 100);
            let m = osdRoot.sink.audio.muted;
            let icon = Theme.getVolumeIcon(vRatio, m);
            let type = vol > 100 ? "volume boost" : "volume";
            let devName = osdRoot.sink?.description || osdRoot.sink?.name || "";
            osdRoot.show(type, icon, vol, m ? "muted" : (vol + "%"), devName);
        }
        function onMutedChanged() {
            if (!osdRoot._ready || !osdRoot.sink?.audio) return;
            let m = osdRoot.sink.audio.muted;
            let vRatio = osdRoot.sink.audio.volume;
            let vol = Math.round(vRatio * 100);
            let icon = Theme.getVolumeIcon(vRatio, m);
            let devName = osdRoot.sink?.description || osdRoot.sink?.name || "";
            osdRoot.show("volume", icon, m ? 0 : vol, m ? "speaker muted" : (vol + "%"), devName);
        }
    }

    Connections {
        target: osdRoot.source?.audio ?? null
        function onVolumeChanged() {
            if (!osdRoot._ready || !osdRoot.source?.audio) return;
            let vRatio = osdRoot.source.audio.volume;
            let vol = Math.round(vRatio * 100);
            let m = osdRoot.source.audio.muted;
            let icon = m ? Theme.iconMicMute : Theme.iconMic;
            let devName = osdRoot.source?.description || osdRoot.source?.name || "";
            osdRoot.show("mic", icon, vol, m ? "mic muted" : (vol + "%"), devName);
        }
        function onMutedChanged() {
            if (!osdRoot._ready || !osdRoot.source?.audio) return;
            let m = osdRoot.source.audio.muted;
            let vRatio = osdRoot.source.audio.volume ?? 1.0;
            let vol = Math.round(vRatio * 100);
            let devName = osdRoot.source?.description || osdRoot.source?.name || "";
            osdRoot.show("mic", m ? Theme.iconMicMute : Theme.iconMic, m ? 0 : vol, m ? "mic muted" : "mic active", devName);
        }
    }

    Connections {
        target: BrightnessService
        function onBrightnessChanged(pct) {
            if (!osdRoot._ready) return;
            osdRoot.show("brightness", Theme.iconBrightness, pct, pct + "%", "display");
        }
    }

    Rectangle {
        id: osdCard
        anchors.centerIn: parent
        anchors.verticalCenterOffset: osdRoot.revealed ? 0 : 16
        width: Math.max(268, Math.min(340, 220 + iconBadge.width))
        height: 58
        radius: Theme.radiusPill
        color: Theme.barBg
        border.color: osdRoot.isMuted
            ? (Theme.error ?? "#ff5449")
            : (osdRoot.isOverAmp
                ? (Theme.warn ?? "#ffb4ab")
                : ((Theme?.isCyberNeon ?? false)
                    ? Theme.alpha(Theme.primary, 0.65)
                    : ((Theme?.isPureBlack ?? false) ? "#222222" : Theme.widgetBorder)))
        border.width: 1

        opacity: osdRoot.revealed ? 1.0 : 0.0
        scale: osdRoot.revealed ? (cardMouseArea.containsMouse ? 1.02 : 1.0) : 0.90

        Behavior on width { NumberAnimation { duration: Theme.animFast; easing.type: Theme.animEasing } }
        Behavior on border.color { ColorAnimation { duration: Theme.animFast } }
        Behavior on opacity {
            NumberAnimation {
                duration: Theme.animNormal
                easing.type: osdRoot.revealed ? Theme.animEasing : Easing.InQuad
            }
        }
        Behavior on scale {
            NumberAnimation {
                duration: Theme.animNormal
                easing.type: osdRoot.revealed ? Easing.OutBack : Easing.InCubic
            }
        }
        Behavior on anchors.verticalCenterOffset {
            NumberAnimation {
                duration: Theme.animNormal
                easing.type: osdRoot.revealed ? Easing.OutCubic : Easing.InCubic
            }
        }

        // Ambient underglow to match StatusBar
        Rectangle {
            visible: (Theme?.isAccentGlow ?? false) || (Theme?.isCyberNeon ?? false) || osdRoot.isOverAmp
            anchors.fill: parent
            anchors.margins: -4
            radius: parent.radius + 4
            color: Theme.alpha(osdRoot.activeColor, 0.22)
            z: -2
            Behavior on color { ColorAnimation { duration: Theme.animFast } }
        }

        // Top specular highlight for glass theme
        Rectangle {
            visible: Theme?.isGlass ?? false
            anchors.top: parent.top
            anchors.topMargin: 1
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width - (parent.radius * 1.4)
            height: 1
            color: Theme.glassHighlight ?? Qt.rgba(1, 1, 1, 0.22)
        }

        MouseArea {
            id: cardMouseArea
            anchors.fill: parent
            hoverEnabled: true
            onEntered: dismissTimer.stop()
            onExited: if (osdRoot.revealed && !sliderDragArea.pressed) dismissTimer.restart()
            onWheel: (wheel) => {
                if (wheel.angleDelta.y === 0) return;
                if (!cardMouseArea.containsMouse) dismissTimer.restart();
                osdRoot.stepLevel(wheel.angleDelta.y);
            }
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 11
            anchors.rightMargin: 14
            anchors.topMargin: 9
            anchors.bottomMargin: 9
            spacing: 12

            // Dynamic icon / kaomoji badge (click to toggle mute)
            Rectangle {
                id: iconBadge
                Layout.preferredWidth: osdRoot.isKaomoji ? Math.max(38, iconText.implicitWidth + 18) : 38
                Layout.preferredHeight: 38
                width: Layout.preferredWidth
                height: 38
                radius: 19
                color: iconMouse.pressed
                    ? Theme.alpha(osdRoot.activeColor, 0.35)
                    : (iconMouse.containsMouse ? Theme.alpha(osdRoot.activeColor, 0.25) : osdRoot.activeOverlay)
                border.color: Theme.alpha(osdRoot.activeColor, iconMouse.containsMouse ? 0.5 : 0.2)
                border.width: 1

                Behavior on Layout.preferredWidth { NumberAnimation { duration: Theme.animFast; easing.type: Theme.animEasing } }
                Behavior on color { ColorAnimation { duration: Theme.animFast } }

                SequentialAnimation {
                    id: iconPopAnim
                    NumberAnimation { target: iconText; property: "scale"; to: 1.18; duration: 90; easing.type: Easing.OutQuad }
                    NumberAnimation { target: iconText; property: "scale"; to: 1.0; duration: 140; easing.type: Easing.OutBack }
                }

                Text {
                    id: iconText
                    anchors.centerIn: parent
                    text: osdRoot.osdIcon
                    font.family: osdRoot.isKaomoji ? Theme.fontFamily : Theme.fontIcon
                    font.pixelSize: osdRoot.isKaomoji ? Theme.fontSizeSm : Theme.fontSizeLg
                    font.weight: osdRoot.isKaomoji ? Font.Bold : Font.Normal
                    color: osdRoot.activeColor
                    Behavior on color { ColorAnimation { duration: Theme.animFast } }
                }

                MouseArea {
                    id: iconMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: (osdRoot.isVolume || osdRoot.isMic) ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: {
                        if (osdRoot.isVolume && osdRoot.sink?.audio) {
                            osdRoot.sink.audio.muted = !osdRoot.sink.audio.muted;
                        } else if (osdRoot.isMic && osdRoot.source?.audio) {
                            osdRoot.source.audio.muted = !osdRoot.source.audio.muted;
                        }
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 5

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Text {
                        text: osdRoot.osdType
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        font.weight: Font.Bold
                        color: osdRoot.isOverAmp ? (Theme.warn ?? "#ffb4ab") : Theme.on_surface
                    }

                    Text {
                        visible: osdRoot.osdSubtitle !== ""
                        Layout.fillWidth: true
                        text: "· " + osdRoot.osdSubtitle
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                        color: Theme.on_surface_variant
                        elide: Text.ElideRight
                    }

                    Item {
                        visible: osdRoot.osdSubtitle === ""
                        Layout.fillWidth: true
                    }

                    Text {
                        text: osdRoot.osdLabel
                        font.family: Theme.fontMono
                        font.pixelSize: Theme.fontSizeXs
                        font.weight: Font.Bold
                        color: osdRoot.activeColor
                        Behavior on color { ColorAnimation { duration: Theme.animFast } }
                    }
                }

                // Interactive progress track (click or drag to adjust)
                Item {
                    id: trackContainer
                    Layout.fillWidth: true
                    height: 12

                    Rectangle {
                        id: trackBg
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width
                        height: sliderDragArea.containsMouse || sliderDragArea.pressed ? 8 : 6
                        radius: height / 2
                        color: Theme.surface_container_highest
                        clip: true

                        Behavior on height { NumberAnimation { duration: Theme.animFast } }

                        // Fill bar
                        Rectangle {
                            id: fillRect
                            height: parent.height
                            readonly property real maxScale: osdRoot.isVolume ? 150.0 : 100.0
                            width: Math.round(parent.width * Math.min(1.0, Math.max(0.0, osdRoot.osdValue / maxScale)))
                            radius: parent.radius
                            color: osdRoot.activeColor

                            Behavior on width {
                                enabled: !sliderDragArea.pressed
                                NumberAnimation {
                                    duration: Theme.animFast
                                    easing.type: Theme.animEasing
                                }
                            }
                            Behavior on color { ColorAnimation { duration: Theme.animFast } }
                        }

                        // 100% notch marker so the 150% volume scale makes visual sense
                        Rectangle {
                            visible: osdRoot.isVolume
                            x: Math.round(parent.width * (100.0 / 150.0)) - 1
                            width: 2
                            height: parent.height
                            color: osdRoot.osdValue >= 100
                                ? Qt.rgba(0, 0, 0, 0.45)
                                : Theme.alpha(Theme.on_surface_variant, 0.45)
                        }
                    }

                    MouseArea {
                        id: sliderDragArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onPressed: (mouse) => {
                            dismissTimer.stop();
                            osdRoot.setLevelFromRatio(mouse.x / width);
                        }
                        onPositionChanged: (mouse) => {
                            if (pressed) {
                                osdRoot.setLevelFromRatio(mouse.x / width);
                            }
                        }
                        onReleased: {
                            if (!cardMouseArea.containsMouse) {
                                dismissTimer.restart();
                            }
                        }
                    }
                }
            }
        }
    }
}
