import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import ".."
import "../controls"
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Mpris
import Quickshell.Services.UPower

Scope {
    id: lockRoot

    property bool locked: false
    property string password: ""
    property bool authFailed: false
    property bool isChecking: false

    IpcHandler {
        target: "lock"

        function lock(): void {
            lockRoot.locked = true;
        }

        function unlock(): void {
            lockRoot.locked = false;
        }
    }

    function tryUnlock(pw) {
        if (isChecking) return;
        if (!pw || pw.length === 0) return;

        isChecking = true;
        authFailed = false;

        authProc.command = [
            "python3",
            Quickshell.env("HOME") + "/.config/quickshell/scripts/auth.py",
            pw
        ];
        authProc.running = true;
    }

    Process {
        id: authProc
        running: false
        onExited: (code) => {
            lockRoot.isChecking = false;
            if (code === 0) {
                lockRoot.locked = false;
                lockRoot.authFailed = false;
            } else {
                lockRoot.authFailed = true;
                shakeTimer.restart();
            }
        }
    }

    Timer {
        id: shakeTimer
        interval: 1000
        onTriggered: lockRoot.authFailed = false
    }

    WlSessionLock {
        id: sessionLock
        locked: lockRoot.locked

        surface: Component {
            WlSessionLockSurface {
                id: surface

                Rectangle {
                    anchors.fill: parent
                    color: "#050505"

                    // wallpaper background image with ambient overlay
                    Image {
                        anchors.fill: parent
                        source: WallpaperService.currentWallpaperPath ? ("file://" + WallpaperService.currentWallpaperPath) : ""
                        fillMode: Image.PreserveAspectCrop
                        opacity: 0.35
                        asynchronous: true
                    }

                    // dark vignette gradient
                    Rectangle {
                        anchors.fill: parent
                        color: "black"
                        opacity: 0.50
                    }

                    // top status row (battery, network)
                    RowLayout {
                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.margins: 32
                        spacing: 16

                        // network pill
                        RowLayout {
                            spacing: 6
                            Text {
                                text: NetworkService.isWiredConnected ? Theme.iconEthernet : (NetworkService.isWifiConnected ? Theme.iconWifiHigh : Theme.iconWifiOff)
                                font.family: Theme.fontIcon
                                font.pixelSize: Theme.fontSizeMd
                                color: NetworkService.isConnected ? Theme.primary : Theme.on_surface_variant
                            }
                            Text {
                                text: NetworkService.activeSsid
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeSm
                                font.weight: Font.Medium
                                color: Theme.on_surface
                            }
                        }

                        // battery pill
                        RowLayout {
                            spacing: 6
                            visible: UPower.displayDevice?.isPresent ?? false
                            Text {
                                text: (UPower.displayDevice?.state === UPowerDeviceState.Charging) ? Theme.iconBatCharging : Theme.iconBatFull
                                font.family: Theme.fontIcon
                                font.pixelSize: Theme.fontSizeMd
                                color: Theme.primary
                            }
                            Text {
                                text: Math.round((UPower.displayDevice?.percentage ?? 1.0) * 100) + "%"
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeSm
                                font.weight: Font.Medium
                                color: Theme.on_surface
                            }
                        }
                    }

                    // center main lock card
                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 24
                        width: 440

                        // large aesthetic digital clock
                        ColumnLayout {
                            Layout.alignment: Qt.AlignHCenter
                            spacing: 4

                            Text {
                                text: Qt.formatDateTime(new Date(), Settings.clock24h ? "HH:mm" : "hh:mm A")
                                font.family: Theme.fontFamily
                                font.pixelSize: 84
                                font.weight: Font.Bold
                                color: Theme.on_surface
                                Layout.alignment: Qt.AlignHCenter

                                Timer {
                                    interval: 1000
                                    running: lockRoot.locked
                                    repeat: true
                                    onTriggered: parent.text = Qt.formatDateTime(new Date(), Settings.clock24h ? "HH:mm" : "hh:mm A")
                                }
                            }

                            Text {
                                text: Qt.formatDateTime(new Date(), "dddd, MMMM d")
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeMd
                                font.weight: Font.Medium
                                color: Theme.primary
                                Layout.alignment: Qt.AlignHCenter
                            }
                        }

                        // media playback card on lockscreen
                        Rectangle {
                            Layout.fillWidth: true
                            height: 72
                            radius: Theme.radiusMd
                            color: Theme.cardBg
                            border.color: Theme.cardBorder
                            border.width: 1
                            visible: Mpris.players.values.length > 0 && Mpris.players.values[0]?.trackTitle !== ""

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 12

                                Rectangle {
                                    width: 48
                                    height: 48
                                    radius: Theme.radiusSm
                                    color: Theme.surface_container_highest
                                    clip: true

                                    Image {
                                        anchors.fill: parent
                                        source: Mpris.players.values[0]?.trackArtUrl || ""
                                        fillMode: Image.PreserveAspectCrop
                                    }

                                    Text {
                                        anchors.centerIn: parent
                                        text: Theme.iconMusic
                                        font.family: Theme.fontIcon
                                        font.pixelSize: Theme.fontSizeMd
                                        color: Theme.primary
                                        visible: !Mpris.players.values[0]?.trackArtUrl
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2

                                    Text {
                                        text: Mpris.players.values[0]?.trackTitle || "no track playing"
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.fontSizeSm
                                        font.weight: Font.Bold
                                        color: Theme.on_surface
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        text: Mpris.players.values[0]?.trackArtist || "unknown artist"
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.fontSizeXs
                                        color: Theme.on_surface_variant
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                    }
                                }

                                IconButton {
                                    icon: Theme.iconPrev
                                    iconSize: Theme.fontSizeXs
                                    tooltip: "previous"
                                    onClicked: Mpris.players.values[0]?.previous()
                                }

                                IconButton {
                                    icon: Mpris.players.values[0]?.isPlaying ? Theme.iconPause : Theme.iconPlay
                                    iconSize: Theme.fontSizeSm
                                    tooltip: "toggle play"
                                    onClicked: Mpris.players.values[0]?.togglePlaying()
                                }

                                IconButton {
                                    icon: Theme.iconNext
                                    iconSize: Theme.fontSizeXs
                                    tooltip: "next"
                                    onClicked: Mpris.players.values[0]?.next()
                                }
                            }
                        }

                        // password input container
                        Rectangle {
                            id: pwContainer
                            Layout.fillWidth: true
                            height: 48
                            radius: Theme.radiusPill
                            color: Theme.cardBg
                            border.color: lockRoot.authFailed ? Theme.error : (pwInput.activeFocus ? Theme.primary : Theme.cardBorder)
                            border.width: 2

                            // shake animation on auth failure
                            SequentialAnimation on x {
                                running: lockRoot.authFailed
                                NumberAnimation { from: 0; to: -12; duration: 50 }
                                NumberAnimation { from: -12; to: 12; duration: 50 }
                                NumberAnimation { from: 12; to: -8; duration: 50 }
                                NumberAnimation { from: -8; to: 8; duration: 50 }
                                NumberAnimation { from: 8; to: 0; duration: 50 }
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 16
                                anchors.rightMargin: 12
                                spacing: 10

                                Text {
                                    text: lockRoot.authFailed ? Theme.iconLock : (pwInput.text.length > 0 ? Theme.iconLock : Theme.iconLock)
                                    font.family: Theme.fontIcon
                                    font.pixelSize: Theme.fontSizeMd
                                    color: lockRoot.authFailed ? Theme.error : Theme.primary
                                }

                                TextInput {
                                    id: pwInput
                                    Layout.fillWidth: true
                                    echoMode: TextInput.Password
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSizeMd
                                    color: Theme.on_surface
                                    focus: lockRoot.locked
                                    enabled: !lockRoot.isChecking
                                    passwordCharacter: "•"

                                    Text {
                                        anchors.fill: parent
                                        verticalAlignment: Text.AlignVCenter
                                        text: "enter password to unlock..."
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.fontSizeSm
                                        color: Theme.on_surface_disabled
                                        visible: pwInput.text === "" && !pwInput.activeFocus
                                    }

                                    onAccepted: {
                                        const p = text;
                                        text = "";
                                        lockRoot.tryUnlock(p);
                                    }
                                }

                                IconButton {
                                    icon: Theme.iconChevronRight
                                    tooltip: "unlock"
                                    iconSize: Theme.fontSizeSm
                                    visible: pwInput.text.length > 0
                                    onClicked: {
                                        const p = pwInput.text;
                                        pwInput.text = "";
                                        lockRoot.tryUnlock(p);
                                    }
                                }
                            }
                        }

                        // feedback status text
                        Text {
                            text: lockRoot.isChecking ? "authenticating..." : (lockRoot.authFailed ? "incorrect password, try again" : "")
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeXs
                            font.weight: Font.Medium
                            color: lockRoot.authFailed ? Theme.error : Theme.on_surface_disabled
                            Layout.alignment: Qt.AlignHCenter
                            visible: text !== ""
                        }
                    }

                    // bottom power actions row
                    RowLayout {
                        anchors.bottom: parent.bottom
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.margins: 40
                        spacing: 24

                        IconButton {
                            icon: Theme.iconPower
                            tooltip: "shut down"
                            iconSize: Theme.fontSizeMd
                            onClicked: Quickshell.execDetached(["systemctl", "poweroff"])
                        }

                        IconButton {
                            icon: Theme.iconRefresh
                            tooltip: "restart"
                            iconSize: Theme.fontSizeMd
                            onClicked: Quickshell.execDetached(["systemctl", "reboot"])
                        }

                        IconButton {
                            icon: Theme.iconMoon
                            tooltip: "sleep"
                            iconSize: Theme.fontSizeMd
                            onClicked: Quickshell.execDetached(["systemctl", "suspend"])
                        }
                    }
                }
            }
        }
    }
}
