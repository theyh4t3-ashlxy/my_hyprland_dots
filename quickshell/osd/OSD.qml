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

    anchors {
        bottom: true
    }
    margins {
        bottom: 80
    }

    implicitWidth: 260
    implicitHeight: 64

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
    property string osdIcon: Theme.iconVolHigh
    property int osdValue: 50
    property string osdLabel: "50%"
    readonly property bool isOverAmp: osdType.startsWith("volume") && osdValue > 100
    readonly property bool isMuted: (osdType === "mic" && (source?.audio?.muted ?? false)) ||
                                    (osdType.startsWith("volume") && (sink?.audio?.muted ?? false))

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

    function show(type, icon, value, label) {
        if (!_ready) return;
        osdType = type;
        osdIcon = icon;
        osdValue = Math.max(0, value);
        osdLabel = label;
        revealed = true;
        dismissTimer.restart();
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
            osdRoot.show(type, icon, vol, m ? "muted" : (vol + "%"));
        }
        function onMutedChanged() {
            if (!osdRoot._ready || !osdRoot.sink?.audio) return;
            let m = osdRoot.sink.audio.muted;
            let vRatio = osdRoot.sink.audio.volume;
            let vol = Math.round(vRatio * 100);
            let icon = Theme.getVolumeIcon(vRatio, m);
            osdRoot.show("volume", icon, m ? 0 : vol, m ? "speaker muted" : (vol + "%"));
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
            osdRoot.show("mic", icon, vol, m ? "mic muted" : (vol + "%"));
        }
        function onMutedChanged() {
            if (!osdRoot._ready || !osdRoot.source?.audio) return;
            let m = osdRoot.source.audio.muted;
            let vRatio = osdRoot.source.audio.volume ?? 1.0;
            let vol = Math.round(vRatio * 100);
            osdRoot.show("mic", m ? Theme.iconMicMute : Theme.iconMic, m ? 0 : vol, m ? "mic muted" : "mic active");
        }
    }

    Connections {
        target: BrightnessService
        function onBrightnessChanged(pct) {
            if (!osdRoot._ready) return;
            osdRoot.show("brightness", Theme.iconBrightness, pct, pct + "%");
        }
    }

    Rectangle {
        id: osdCard
        anchors.centerIn: parent
        // verticalCenterOffset preserves anchors while letting us slide
        anchors.verticalCenterOffset: osdRoot.revealed ? 0 : 14
        width: 250
        height: 52
        radius: Theme.radiusPill
        color: Theme.barBg
        border.color: osdRoot.isOverAmp ? Theme.warn : Theme.widgetBorder
        border.width: 1

        opacity: osdRoot.revealed ? 1.0 : 0.0
        scale: osdRoot.revealed ? 1.0 : 0.92

        Behavior on opacity { NumberAnimation { duration: Theme.animNormal; easing.type: Theme.animEasing } }
        Behavior on scale   { NumberAnimation { duration: Theme.animNormal; easing.type: osdRoot.revealed ? Easing.OutBack : Easing.InCubic } }
        Behavior on anchors.verticalCenterOffset {
            NumberAnimation {
                duration: Theme.animNormal
                easing.type: osdRoot.revealed ? Easing.OutCubic : Easing.InCubic
            }
        }

        MouseArea {
            id: cardMouseArea
            anchors.fill: parent
            hoverEnabled: true
            onEntered: dismissTimer.stop()
            onExited: if (osdRoot.revealed) dismissTimer.restart()
            onWheel: (wheel) => {
                if (wheel.angleDelta.y === 0) return;
                // keep timer paused while cursor lingers
                if (!cardMouseArea.containsMouse) dismissTimer.restart();

                let delta = wheel.angleDelta.y > 0 ? 0.02 : -0.02;

                if (osdRoot.osdType.startsWith("volume") && osdRoot.sink?.audio) {
                    // clamp so you dont nuke your hardware
                    osdRoot.sink.audio.volume = Math.min(1.5, Math.max(0, osdRoot.sink.audio.volume + delta));
                } else if (osdRoot.osdType === "mic" && osdRoot.source?.audio) {
                    osdRoot.source.audio.volume = Math.min(1.0, Math.max(0, osdRoot.source.audio.volume + delta));
                }
            }
        }

        RowLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 12

            Rectangle {
                width: 32
                height: 32
                radius: 16
                color: osdRoot.isMuted
                    ? Theme.error_overlay
                    : (osdRoot.isOverAmp ? Theme.warn_overlay : Theme.primary_overlay)

                Text {
                    anchors.centerIn: parent
                    text: osdRoot.osdIcon
                    font.family: Theme.fontIcon
                    font.pixelSize: Theme.fontSizeMd
                    color: osdRoot.isMuted
                        ? Theme.error
                        : (osdRoot.isOverAmp ? Theme.warn : Theme.primary)
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        text: osdRoot.osdType
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                        font.weight: Font.Bold
                        color: osdRoot.isOverAmp ? Theme.warn : Theme.on_surface_variant
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        text: osdRoot.osdLabel
                        font.family: Theme.fontMono
                        font.pixelSize: Theme.fontSizeXs
                        font.weight: Font.Bold
                        color: osdRoot.isMuted
                            ? Theme.error
                            : (osdRoot.isOverAmp ? Theme.warn : Theme.primary)
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 6
                    radius: 3
                    color: Theme.surface_container_highest
                    clip: true

                    Rectangle {
                        height: parent.height
                        // static 150 cap for volume mode prevents the 100->101 shrink snap
                        width: Math.round(parent.width * Math.min(1.0, Math.max(0.0, osdRoot.osdValue / (osdRoot.osdType.startsWith("volume") ? 150.0 : 100.0))))
                        radius: 3
                        color: osdRoot.isMuted
                            ? Theme.error
                            : (osdRoot.isOverAmp ? Theme.warn : Theme.primary)

                        Behavior on width {
                            NumberAnimation {
                                duration: Theme.animFast
                                easing.type: Theme.animEasing
                            }
                        }
                    }
                }
            }
        }
    }
}