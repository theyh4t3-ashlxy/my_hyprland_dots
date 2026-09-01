import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import ".."
import "../controls"
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Mpris

Scope {
    id: lockRoot

    property bool locked: false
    property string password: ""
    property bool authFailed: false
    property bool isChecking: false

    function tryUnlock() {
        if (isChecking) return;
        isChecking = true;
        authFailed = false;

        // Verify password with PAM / su / unix_chkpwd helper
        let pw = password;
        password = "";
        
        let checkProc = Qt.createQmlObject("import Quickshell.Io; Process { id: proc; command: [\"bash\", \"-c\", \"echo -n \\\"$1\\\" | su -c true ashley 2>/dev/null\", \"--\", \"" + pw.replace(/"/g, "\\\"") + "\"]; }", lockRoot, "checkProc");
        checkProc.exited.connect(function(code) {
            isChecking = false;
            if (code === 0) {
                // Success! Unlock session
                lockRoot.locked = false;
            } else {
                // Failed! Shake animation
                authFailed = true;
                shakeTimer.restart();
            }
            checkProc.destroy();
        });
        checkProc.running = true;
    }

    Timer {
        id: shakeTimer
        interval: 1000
        onTriggered: lockRoot.authFailed = false
    }

    WlSessionLock {
        id: sessionLock
        locked: lockRoot.locked

        WlSessionLockSurface {
            id: surface

            Rectangle {
                anchors.fill: parent
                color: "#050505"

                // Wallpaper background image
                Image {
                    anchors.fill: parent
                    source: WallpaperService.currentWallpaperPath ? ("file://" + WallpaperService.currentWallpaperPath) : ""
                    fillMode: Image.PreserveAspectCrop
                    opacity: 0.35
                    asynchronous: true
                }

                // Vignette & dark gradient overlay
                Rectangle {
                    anchors.fill: parent
                    color: "black"
                    opacity: 0.45
                }

                // Top right status row (Battery, Wifi)
                RowLayout {
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.margins: 32
                    spacing: 16

                    RowLayout {
                        spacing: 6
                        Text {
                            text: Theme.iconBatteryFull
                            font.family: Theme.fontIcon
                            font.pixelSize: Theme.fontSizeMd
                            color: Theme.primary
                        }
                        Text {
                            text: "100%"
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeSm
                            font.weight: Font.Medium
                            color: Theme.on_surface
                        }
                    }
                }

                // Center main lock card
                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 24
                    width: 440

                    // Large aesthetic digital clock
                    ColumnLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 4

                        Text {
                            text: Qt.formatDateTime(new Date(), "HH:mm")
                            font.family: Theme.fontFamily
                            font.pixelSize: 84
                            font.weight: Font.Bold
                            color: Theme.on_surface
                            Layout.alignment: Qt.AlignHCenter

                            Timer {
                                interval: 1000
                                running: lockRoot.locked
                                repeat: true
                                onTriggered: parent.text = Qt.formatDateTime(new Date(), "HH:mm")
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

                    // Media playback card on lockscreen
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
                                icon: Mpris.players.values[0]?.isPlaying ? Theme.iconPause : Theme.iconPlay
                                iconSize: Theme.fontSizeSm
                                onClicked: Mpris.players.values[0]?.togglePlaying()
                            }
                        }
                    }

                    // Password Input Container
                    Rectangle {
                        id: pwContainer
                        Layout.fillWidth: true
                        height: 48
                        radius: Theme.radiusPill
                        color: Theme.cardBg
                        border.color: lockRoot.authFailed ? Theme.error : (pwInput.activeFocus ? Theme.primary : Theme.cardBorder)
                        border.width: 2

                        // Shake animation
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
                                text: lockRoot.authFailed ? Theme.iconLock : (pwInput.text.length > 0 ? Theme.iconLockOpen : Theme.iconLock)
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
                                onAccepted: {
                                    lockRoot.password = text;
                                    text = "";
                                    lockRoot.tryUnlock();
                                }
                            }

                            IconButton {
                                icon: Theme.iconArrowRight
                                tooltip: "unlock"
                                iconSize: Theme.fontSizeSm
                                visible: pwInput.text.length > 0
                                onClicked: {
                                    lockRoot.password = pwInput.text;
                                    pwInput.text = "";
                                    lockRoot.tryUnlock();
                                }
                            }
                        }
                    }

                    // Feedback status text
                    Text {
                        text: lockRoot.isChecking ? "authenticating..." : (lockRoot.authFailed ? "incorrect password, try again" : "enter password to unlock")
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeXs
                        font.weight: Font.Medium
                        color: lockRoot.authFailed ? Theme.error : Theme.on_surface_disabled
                        Layout.alignment: Qt.AlignHCenter
                    }
                }

                // Bottom power actions row
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
