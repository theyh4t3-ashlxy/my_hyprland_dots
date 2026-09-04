import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import ".."
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Mpris
import Quickshell.Services.UPower
import Quickshell.Services.Pam

Scope {
    id: lockRoot

    property bool locked: false
    property bool authFailed: false
    property bool isChecking: false
    property date currentTime: new Date()

    // time loop so our clock doesn't freeze in time
    Timer {
        interval: 1000
        running: lockRoot.locked
        repeat: true
        onTriggered: lockRoot.currentTime = new Date()
    }

    IpcHandler {
        target: "lock"

        function lock(): void {
            lockRoot.locked = true;
        }

        function unlock(): void {
            lockRoot.locked = false;
        }
    }

    property string pendingPassword: ""

    PamContext {
        id: pam
        config: "login"
        user: Quickshell.env("USER")

        onPamMessage: {
            if (responseRequired && lockRoot.pendingPassword) {
                pam.respond(lockRoot.pendingPassword);
            }
        }

        onCompleted: (result) => {
            lockRoot.isChecking = false;
            lockRoot.pendingPassword = "";
            let success = (result === 0 || PamResult.toString(result) === "Success");
            if (success) {
                lockRoot.locked = false;
                lockRoot.authFailed = false;
            } else {
                lockRoot.authFailed = true;
                shakeAnim.restart();
                shakeTimer.restart();
            }
        }

        onError: (err) => {
            lockRoot.isChecking = false;
            lockRoot.pendingPassword = "";
            lockRoot.authFailed = true;
            shakeAnim.restart();
            shakeTimer.restart();
        }
    }

    function tryUnlock(pw) {
        if (isChecking || !pw || pw.length === 0) return;

        isChecking = true;
        authFailed = false;
        pendingPassword = pw;
        pam.start();
    }

    Timer {
        id: shakeTimer
        interval: 1200
        onTriggered: lockRoot.authFailed = false
    }

    WlSessionLock {
        id: sessionLock
        locked: lockRoot.locked

        surface: Component {
            WlSessionLockSurface {
                id: surface

                readonly property var activePlayer: Mpris.players.values[0] ?? null
                readonly property int cornerRadius: Theme?.screenCornerRadius ?? 16
                readonly property color cornerColor: Theme?.cornerFill ?? Theme?.surface_container_low ?? Theme?.background ?? "#14140c"

                Rectangle {
                    anchors.fill: parent
                    color: "#050505"

                    // wallpaper backdrop
                    Image {
                        anchors.fill: parent
                        source: WallpaperService.currentWallpaperPath ? ("file://" + WallpaperService.currentWallpaperPath) : ""
                        fillMode: Image.PreserveAspectCrop
                        opacity: 0.35
                        asynchronous: true
                    }

                    // vignette overlay
                    Rectangle {
                        anchors.fill: parent
                        color: "black"
                        opacity: 0.50
                    }

                    // top status row
                    RowLayout {
                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.margins: 32
                        spacing: 16

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

                    // center lock card
                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 24
                        width: 440

                        // large clock
                        ColumnLayout {
                            Layout.alignment: Qt.AlignHCenter
                            spacing: 4

                            Text {
                                text: Qt.formatDateTime(lockRoot.currentTime, Settings?.clock24h ? "HH:mm" : "hh:mm A")
                                font.family: Theme.fontFamily
                                font.pixelSize: 84
                                font.weight: Font.Bold
                                color: Theme.on_surface
                                Layout.alignment: Qt.AlignHCenter
                            }

                            Text {
                                text: Qt.formatDateTime(lockRoot.currentTime, "dddd, MMMM d")
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeMd
                                font.weight: Font.Medium
                                color: Theme.primary
                                Layout.alignment: Qt.AlignHCenter
                            }
                        }

                        // media player card
                        Rectangle {
                            Layout.fillWidth: true
                            height: 72
                            radius: Theme.radiusMd
                            color: Theme.cardBg
                            border.color: Theme.cardBorder
                            border.width: 1
                            visible: surface.activePlayer !== null && (surface.activePlayer.trackTitle !== "" || surface.activePlayer.isPlaying)

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
                                        source: surface.activePlayer?.trackArtUrl ?? ""
                                        fillMode: Image.PreserveAspectCrop
                                    }

                                    Text {
                                        anchors.centerIn: parent
                                        text: Theme.iconMusic
                                        font.family: Theme.fontIcon
                                        font.pixelSize: Theme.fontSizeMd
                                        color: Theme.primary
                                        visible: !surface.activePlayer?.trackArtUrl
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2

                                    Text {
                                        text: surface.activePlayer?.trackTitle || "no track playing"
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.fontSizeSm
                                        font.weight: Font.Bold
                                        color: Theme.on_surface
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        text: surface.activePlayer?.trackArtist || "unknown artist"
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
                                    onClicked: surface.activePlayer?.previous()
                                }

                                IconButton {
                                    icon: surface.activePlayer?.isPlaying ? Theme.iconPause : Theme.iconPlay
                                    iconSize: Theme.fontSizeSm
                                    tooltip: "toggle play"
                                    onClicked: surface.activePlayer?.togglePlaying()
                                }

                                IconButton {
                                    icon: Theme.iconNext
                                    iconSize: Theme.fontSizeXs
                                    tooltip: "next"
                                    onClicked: surface.activePlayer?.next()
                                }
                            }
                        }

                        // password entry container
                        Rectangle {
                            id: pwContainer
                            Layout.fillWidth: true
                            height: 48
                            radius: Theme.radiusPill
                            color: Theme.cardBg
                            border.color: lockRoot.authFailed ? Theme.error : (pwInput.activeFocus ? Theme.primary : Theme.cardBorder)
                            border.width: 2

                            // transform translate so columnlayout doesn't fight our animation
                            transform: Translate { id: pwShake }

                            SequentialAnimation {
                                id: shakeAnim
                                NumberAnimation { target: pwShake; property: "x"; from: 0; to: -14; duration: 45; easing.type: Easing.OutQuad }
                                NumberAnimation { target: pwShake; property: "x"; from: -14; to: 14; duration: 45; easing.type: Easing.InOutQuad }
                                NumberAnimation { target: pwShake; property: "x"; from: 14; to: -8; duration: 45; easing.type: Easing.InOutQuad }
                                NumberAnimation { target: pwShake; property: "x"; from: -8; to: 8; duration: 45; easing.type: Easing.InOutQuad }
                                NumberAnimation { target: pwShake; property: "x"; from: 8; to: 0; duration: 45; easing.type: Easing.OutQuad }
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 16
                                anchors.rightMargin: 12
                                spacing: 10

                                Text {
                                    text: Theme.iconLock
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

                                    Component.onCompleted: forceActiveFocus()
                                    Connections {
                                        target: lockRoot
                                        function onLockedChanged() {
                                            if (lockRoot.locked) {
                                                pwInput.text = "";
                                                pwInput.forceActiveFocus();
                                            }
                                        }
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

                        // feedback status
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

                    // bottom power management row
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

                    // matching screen corners so our curved monitor bezels don't disappear
                    ConcaveCorner {
                        anchors.top: parent.top
                        anchors.left: parent.left
                        radiusX: surface.cornerRadius
                        radiusY: surface.cornerRadius
                        fillColor: surface.cornerColor
                        flipX: false
                        flipY: false
                        visible: surface.cornerRadius > 0
                    }

                    ConcaveCorner {
                        anchors.top: parent.top
                        anchors.right: parent.right
                        radiusX: surface.cornerRadius
                        radiusY: surface.cornerRadius
                        fillColor: surface.cornerColor
                        flipX: true
                        flipY: false
                        visible: surface.cornerRadius > 0
                    }

                    ConcaveCorner {
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        radiusX: surface.cornerRadius
                        radiusY: surface.cornerRadius
                        fillColor: surface.cornerColor
                        flipX: false
                        flipY: true
                        visible: surface.cornerRadius > 0
                    }

                    ConcaveCorner {
                        anchors.bottom: parent.bottom
                        anchors.right: parent.right
                        radiusX: surface.cornerRadius
                        radiusY: surface.cornerRadius
                        fillColor: surface.cornerColor
                        flipX: true
                        flipY: true
                        visible: surface.cornerRadius > 0
                    }
                }
            }
        }
    }
}