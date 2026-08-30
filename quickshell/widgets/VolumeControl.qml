import QtQuick
import QtQuick.Layouts
import ".."
import Quickshell
import Quickshell.Services.Pipewire

Rectangle {
    id: volRoot
    implicitWidth: Theme.isVertical ? Theme.barHeight - 8 : row.implicitWidth + 24
    implicitHeight: Theme.barHeight - 8
    radius: Theme.radiusPill
    color: popup.open ? Theme.primary_overlay : (volRoot.muted ? Theme.surface_container : (vMouse.containsMouse ? Theme.surface_container_highest : Theme.surface_container_high))

    Behavior on color { ColorAnimation { duration: Theme.animFast } }

    property var sink: Pipewire.defaultAudioSink
    property var source: Pipewire.defaultAudioSource
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
            color: popup.open ? Theme.primary : (volRoot.muted ? Theme.on_surface_disabled : Theme.on_surface)
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: vMouse.containsMouse || popup.open
            text: {
                if (volRoot.muted) return Settings.unhingedFlavor ? Theme.kaoAnger + " shh" : "muted";
                let pct = Math.round(volRoot.vol * 100);
                if (Settings.unhingedFlavor && pct > 100) return Theme.kaoPanic + " " + pct + "%";
                return pct + "%";
            }
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeXs
            color: popup.open ? Theme.primary : (volRoot.muted ? Theme.on_surface_disabled : Theme.on_surface)
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
                popup.targetRelativeX = volRoot.mapToItem(null, 0, 0).x + (volRoot.width / 2)
                popup.open = !popup.open
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

    PopupPanel {
        id: popup
        cardWidth: 420
        cardHeight: 460
        targetRelativeX: volRoot.mapToItem(null, 0, 0).x + (volRoot.width / 2)

        content: ColumnLayout {
            anchors.fill: parent
            spacing: Theme.widgetSpacing

            // Header
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: "audio & sound"
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeLg
                    font.weight: Font.Bold
                    color: Theme.on_surface
                    Layout.fillWidth: true
                }

                IconButton {
                    icon: Theme.iconSettings
                    iconSize: Theme.fontSizeMd
                    tooltip: "open pavucontrol mixer"
                    onClicked: Quickshell.execDetached(["pavucontrol"])
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Theme.widgetBorder
            }

            // Output Volume (Speaker / Headphones)
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Text {
                        text: "output"
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeSm
                        font.weight: Font.Bold
                        color: Theme.primary
                    }

                    Text {
                        text: (volRoot.sink?.description || volRoot.sink?.name || "default playback")
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeXs
                        color: Theme.on_surface_variant
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 52
                    radius: Theme.widgetRadius
                    color: Theme.surface_container_highest

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: Theme.widgetPaddingH
                        spacing: 10

                        IconButton {
                            icon: (volRoot.sink?.audio?.muted ?? false) ? Theme.iconVolMute : Theme.iconVolHigh
                            iconSize: Theme.fontSizeMd
                            tooltip: "toggle output mute"
                            onClicked: {
                                if (volRoot.sink?.audio) volRoot.sink.audio.muted = !volRoot.sink.audio.muted
                            }
                        }

                        // Output Volume Slider Track (up to 150%)
                        Rectangle {
                            id: volTrack
                            Layout.fillWidth: true
                            height: 8
                            radius: Theme.radiusPill
                            color: Theme.surface_variant

                            Rectangle {
                                width: parent.width * Math.min(1.0, Math.max(0.0, (volRoot.sink?.audio?.volume ?? 0) / 1.5))
                                height: parent.height
                                radius: Theme.radiusPill
                                color: (volRoot.sink?.audio?.muted ?? false) ? Theme.on_surface_disabled : Theme.primary
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                preventStealing: true

                                function applySinkVolume(posX) {
                                    if (!volRoot.sink?.audio || width <= 0) return
                                    const clamped = Math.max(0.0, Math.min(1.5, (posX / width) * 1.5))
                                    volRoot.sink.audio.volume = clamped
                                    if (volRoot.sink.audio.muted && clamped > 0) volRoot.sink.audio.muted = false
                                }

                                onPressed: (mouse) => applySinkVolume(mouse.x)
                                onPositionChanged: (mouse) => { if (pressed) applySinkVolume(mouse.x) }
                            }
                        }

                        Text {
                            text: Math.round((volRoot.sink?.audio?.volume ?? 0) * 100) + "%"
                            font.family: Theme.fontMono
                            font.pixelSize: Theme.fontSizeXs
                            font.weight: Font.Bold
                            color: (volRoot.sink?.audio?.muted ?? false) ? Theme.on_surface_disabled : Theme.primary
                            Layout.preferredWidth: 38
                            horizontalAlignment: Text.AlignRight
                        }
                    }
                }
            }

            // Quick Volume Presets
            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Repeater {
                    model: [
                        { label: "mute", val: 0.0, mute: true },
                        { label: "30%", val: 0.3, mute: false },
                        { label: "50%", val: 0.5, mute: false },
                        { label: "80%", val: 0.8, mute: false },
                        { label: "100%", val: 1.0, mute: false },
                        { label: "150%", val: 1.5, mute: false }
                    ]

                    delegate: Rectangle {
                        required property var modelData
                        Layout.fillWidth: true
                        height: 24
                        radius: Theme.radiusPill
                        color: presetMouse.containsMouse ? Theme.primary_overlay : Theme.surface_container_high

                        Behavior on color { ColorAnimation { duration: Theme.animFast } }

                        Text {
                            text: modelData.label
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                            font.weight: Font.Medium
                            color: Theme.on_surface
                            anchors.centerIn: parent
                        }

                        MouseArea {
                            id: presetMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (volRoot.sink?.audio) {
                                    if (modelData.mute) {
                                        volRoot.sink.audio.muted = true
                                    } else {
                                        volRoot.sink.audio.volume = modelData.val
                                        volRoot.sink.audio.muted = false
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Theme.widgetBorder
            }

            // Microphone Input
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Text {
                        text: "microphone"
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeSm
                        font.weight: Font.Bold
                        color: Theme.primary
                    }

                    Text {
                        text: (volRoot.source?.description || volRoot.source?.name || "default recording")
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeXs
                        color: Theme.on_surface_variant
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 52
                    radius: Theme.widgetRadius
                    color: Theme.surface_container_highest

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: Theme.widgetPaddingH
                        spacing: 10

                        IconButton {
                            icon: (volRoot.source?.audio?.muted ?? false) ? Theme.iconMicMute : Theme.iconMic
                            iconSize: Theme.fontSizeMd
                            tooltip: "toggle microphone mute"
                            onClicked: {
                                if (volRoot.source?.audio) volRoot.source.audio.muted = !volRoot.source.audio.muted
                            }
                        }

                        Rectangle {
                            id: micTrack
                            Layout.fillWidth: true
                            height: 8
                            radius: Theme.radiusPill
                            color: Theme.surface_variant

                            Rectangle {
                                width: parent.width * Math.min(1.0, Math.max(0.0, volRoot.source?.audio?.volume ?? 0))
                                height: parent.height
                                radius: Theme.radiusPill
                                color: (volRoot.source?.audio?.muted ?? false) ? Theme.on_surface_disabled : Theme.primary
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                preventStealing: true

                                function applyMicVolume(posX) {
                                    if (!volRoot.source?.audio || width <= 0) return
                                    const clamped = Math.max(0.0, Math.min(1.0, posX / width))
                                    volRoot.source.audio.volume = clamped
                                    if (volRoot.source.audio.muted && clamped > 0) volRoot.source.audio.muted = false
                                }

                                onPressed: (mouse) => applyMicVolume(mouse.x)
                                onPositionChanged: (mouse) => { if (pressed) applyMicVolume(mouse.x) }
                            }
                        }

                        Text {
                            text: Math.round((volRoot.source?.audio?.volume ?? 0) * 100) + "%"
                            font.family: Theme.fontMono
                            font.pixelSize: Theme.fontSizeXs
                            font.weight: Font.Bold
                            color: (volRoot.source?.audio?.muted ?? false) ? Theme.on_surface_disabled : Theme.primary
                            Layout.preferredWidth: 38
                            horizontalAlignment: Text.AlignRight
                        }
                    }
                }
            }
        }
    }
}
