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
    implicitHeight: 60

    WlrLayershell.namespace: "quickshell:osd"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore

    // ensuring user clicks through the transparent backdrop
    mask: Region {
        item: revealed ? osdCard : null
    }

    property bool _ready: false
    property bool revealed: false
    property string osdType: "volume"
    property string osdIcon: Theme.iconVolHigh
    property int osdValue: 50
    property string osdLabel: "50%"

    property var sink: Pipewire.defaultAudioSink
    property var source: Pipewire.defaultAudioSource
    PwObjectTracker { objects: [osdRoot.sink, osdRoot.source].filter(Boolean) }

    Timer {
        id: initTimer
        interval: 1000
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
            let icon = Theme.getVolumeIcon(vRatio, osdRoot.sink.audio.muted);
            osdRoot.show("volume", icon, vol, osdRoot.sink.audio.muted ? "muted" : (vol + "%"));
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
        function onMutedChanged() {
            if (!osdRoot._ready || !osdRoot.source?.audio) return;
            let m = osdRoot.source.audio.muted;
            osdRoot.show("mic", m ? Theme.iconMicMute : Theme.iconMic, m ? 0 : 100, m ? "mic muted" : "mic unmuted");
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
        width: 250
        height: 52
        radius: Theme.radiusPill
        color: Theme.barBg
        border.color: Theme.widgetBorder
        border.width: 1
        opacity: osdRoot.revealed ? 1.0 : 0.0
        scale: osdRoot.revealed ? 1.0 : 0.88

        Behavior on opacity { NumberAnimation { duration: Theme.animNormal; easing.type: Theme.animEasing } }
        Behavior on scale   { NumberAnimation { duration: Theme.animNormal; easing.type: Easing.OutBack } }

        RowLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 12

            Rectangle {
                width: 32
                height: 32
                radius: 16
                color: (osdRoot.osdType === "mic" && osdRoot.osdValue === 0) || (osdRoot.osdType === "volume" && osdRoot.sink?.audio?.muted)
                     ? Theme.error_overlay : Theme.primary_overlay

                Text {
                    anchors.centerIn: parent
                    text: osdRoot.osdIcon
                    font.family: Theme.fontIcon
                    font.pixelSize: Theme.fontSizeMd
                    color: (osdRoot.osdType === "mic" && osdRoot.osdValue === 0) || (osdRoot.osdType === "volume" && osdRoot.sink?.audio?.muted)
                         ? Theme.error : Theme.primary
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
                        color: Theme.on_surface_variant
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        text: osdRoot.osdLabel
                        font.family: Theme.fontMono
                        font.pixelSize: Theme.fontSizeXs
                        font.weight: Font.Bold
                        color: Theme.primary
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 6
                    radius: 3
                    color: Theme.surface_container_highest

                    Rectangle {
                        height: parent.height
                        width: Math.round(parent.width * Math.min(1.0, Math.max(0.0, osdRoot.osdValue / 100.0)))
                        radius: 3
                        color: (osdRoot.osdType === "mic" && osdRoot.osdValue === 0) || (osdRoot.osdType === "volume" && osdRoot.sink?.audio?.muted)
                             ? Theme.error : Theme.primary

                        Behavior on width { NumberAnimation { duration: Theme.animFast; easing.type: Theme.animEasing } }
                    }
                }
            }
        }
    }
}
