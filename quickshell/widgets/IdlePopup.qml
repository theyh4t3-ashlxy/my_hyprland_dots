import QtQuick
import QtQuick.Layouts
import ".."
import "../controls"
import Quickshell
import Quickshell.Io
import "../services"

PopupPanel {
    id: root

    cardWidth: 360
    cardHeight: 310

    property int remainingSecs: 0
    readonly property bool hasTimer: remainingSecs > 0

    Timer {
        id: countdownTimer
        interval: 1000
        repeat: true
        running: root.hasTimer && !IdleService.enabled
        onTriggered: {
            if (root.remainingSecs > 1) {
                root.remainingSecs--;
            } else {
                root.remainingSecs = 0;
                IdleService.enabled = true; // resume normal idle
            }
        }
    }

    function setCaffeineTimer(minutes) {
        if (minutes <= 0) {
            root.remainingSecs = 0;
            IdleService.enabled = false; // keep awake indefinitely
        } else {
            root.remainingSecs = minutes * 60;
            IdleService.enabled = false;
        }
    }

    function formatTime(totalSec) {
        let m = Math.floor(totalSec / 60);
        let s = totalSec % 60;
        return (m < 10 ? "0" + m : m) + ":" + (s < 10 ? "0" + s : s);
    }

    content: ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.widgetPaddingH + 4
        spacing: 12

        // Header
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                text: Theme.iconCoffee
                font.family: Theme.fontIcon
                font.pixelSize: Theme.fontSizeLg
                color: !IdleService.enabled ? Theme.primary : Theme.on_surface_variant
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Text {
                    text: "caffeine & sleep inhibitor"
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeMd
                    font.weight: Font.Bold
                    color: Theme.on_surface
                }

                Text {
                    text: !IdleService.enabled
                        ? (root.hasTimer ? ("active • " + root.formatTime(root.remainingSecs) + " left") : "active indefinitely")
                        : "system idle sleep enabled"
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeXs
                    color: !IdleService.enabled ? Theme.primary : Theme.on_surface_variant
                }
            }

            Rectangle {
                height: 22
                implicitWidth: statusBadge.implicitWidth + 14
                radius: Theme.radiusPill
                color: !IdleService.enabled ? Theme.primary_container : Theme.surface_container_highest

                Text {
                    id: statusBadge
                    anchors.centerIn: parent
                    text: !IdleService.enabled ? "awake" : "sleepable"
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                    font.weight: Font.Bold
                    color: !IdleService.enabled ? Theme.on_primary_container : Theme.on_surface_variant
                }
            }
        }

        // Timer Presets Card
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 96
            radius: Theme.radiusMd
            color: Theme.surface_container
            border.color: Theme.glassBorder
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 8

                Text {
                    text: "keep system awake for:"
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeXs
                    color: Theme.on_surface_variant
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Repeater {
                        model: [
                            { label: "15m", val: 15 },
                            { label: "30m", val: 30 },
                            { label: "1h", val: 60 },
                            { label: "2h", val: 120 },
                            { label: "always", val: 0 }
                        ]

                        delegate: Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredWidth: 1
                            height: 32
                            radius: Theme.radiusSm
                            color: (!IdleService.enabled && ((modelData.val === 0 && !root.hasTimer) || (root.hasTimer && Math.round(root.remainingSecs/60) === modelData.val)))
                                ? Theme.primary : Theme.surface_container_high
                            border.color: Theme.glassBorder
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: modelData.label
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeXs
                                font.weight: Font.Medium
                                color: (!IdleService.enabled && ((modelData.val === 0 && !root.hasTimer) || (root.hasTimer && Math.round(root.remainingSecs/60) === modelData.val)))
                                    ? Theme.on_primary : Theme.on_surface
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.setCaffeineTimer(modelData.val)
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 24
                    radius: Theme.radiusSm
                    color: IdleService.enabled ? Theme.primary_container : Theme.surface_container_highest

                    Text {
                        anchors.centerIn: parent
                        text: IdleService.enabled ? "sleep active (click to inhibit)" : "turn off inhibitor (allow sleep)"
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                        font.weight: Font.Medium
                        color: IdleService.enabled ? Theme.on_primary_container : Theme.on_surface
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.remainingSecs = 0;
                            IdleService.enabled = !IdleService.enabled;
                        }
                    }
                }
            }
        }

        // Quick Display Actions
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Rectangle {
                Layout.fillWidth: true
                height: 36
                radius: Theme.radiusSm
                color: Theme.surface_container_high
                border.color: Theme.glassBorder
                border.width: 1

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 4

                    Text {
                        text: Theme.iconEyeOff
                        font.family: Theme.fontIcon
                        font.pixelSize: Theme.fontSizeSm
                        color: Theme.on_surface
                    }

                    Text {
                        text: "blank screen"
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeXs
                        color: Theme.on_surface
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        Settings.dispatchDpms("disable");
                        root.open = false;
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 36
                radius: Theme.radiusSm
                color: Theme.surface_container_high
                border.color: Theme.glassBorder
                border.width: 1

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 4

                    Text {
                        text: Theme.iconLock
                        font.family: Theme.fontIcon
                        font.pixelSize: Theme.fontSizeSm
                        color: Theme.on_surface
                    }

                    Text {
                        text: "lock now"
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeXs
                        color: Theme.on_surface
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        Quickshell.execDetached(["qs", "ipc", "call", "lock", "lock"]);
                        root.open = false;
                    }
                }
            }
        }
    }
}
