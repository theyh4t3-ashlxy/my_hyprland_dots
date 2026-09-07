import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import ".."
import "../controls"
import "../corners"
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

    signal triggerShake()

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
        user: Quickshell.env("USER") ?? ""

        onPamMessage: {
            if (responseRequired && lockRoot.pendingPassword) {
                let pw = lockRoot.pendingPassword;
                lockRoot.pendingPassword = "";
                pam.respond(pw);
            }
        }

        onResponseRequiredChanged: {
            if (responseRequired && lockRoot.pendingPassword) {
                let pw = lockRoot.pendingPassword;
                lockRoot.pendingPassword = "";
                pam.respond(pw);
            }
        }

        onCompleted: (result) => {
            lockRoot.isChecking = false;
            lockRoot.pendingPassword = "";
            let success = (result === PamResult.Success || result === 0 || PamResult.toString(result) === "Success");
            if (success) {
                lockRoot.locked = false;
                lockRoot.authFailed = false;
            } else {
                lockRoot.authFailed = true;
                lockRoot.triggerShake();
                shakeTimer.restart();
            }
        }

        onError: (err) => {
            lockRoot.isChecking = false;
            lockRoot.pendingPassword = "";
            lockRoot.authFailed = true;
            lockRoot.triggerShake();
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

                // calculates background luminance so light mode doesnt paint black text on black voids
                readonly property bool isDark: {
                    if (WallpaperService?.currentMode) return WallpaperService.currentMode === "dark";
                    let bg = Theme?.background ?? Theme?.surface;
                    if (bg) {
                        let lum = (0.299 * bg.r + 0.587 * bg.g + 0.114 * bg.b);
                        return lum < 0.5;
                    }
                    return true;
                }

                readonly property var activePlayer: Mpris?.players?.values?.[0] ?? null
                readonly property int cornerRadius: Settings?.screenCornerRadius ?? 16
                readonly property color cornerColor: {
                    let cm = Settings?.cornerColorMode ?? "bar";
                    if (cm === "accent") return Theme?.primary ?? "#ffffff";
                    if (cm === "pure-black") return "#000000";
                    if (cm === "theme") return Theme?.surface_container_high ?? (surface.isDark ? "#14140c" : "#f5f5f5");
                    return Theme?.barBg ?? (surface.isDark ? (Theme?.background ?? "#050505") : (Theme?.background ?? "#ffffff"));
                }

                Rectangle {
                    anchors.fill: parent
                    color: surface.isDark ? (Theme?.background ?? "#050505") : (Theme?.background ?? "#fbf8ff")

                    MouseArea {
                        anchors.fill: parent
                        z: -1
                        onClicked: pwInput.forceActiveFocus()
                    }

                    // wallpaper backdrop
                    Image {
                        anchors.fill: parent
                        source: {
                            let wp = WallpaperService?.currentWallpaperPath ?? "";
                            if (!wp) return "";
                            return (wp.startsWith("file://") || wp.startsWith("http://") || wp.startsWith("https://")) ? wp : ("file://" + wp);
                        }
                        fillMode: Image.PreserveAspectCrop
                        opacity: surface.isDark ? 0.35 : 0.40
                        asynchronous: true
                    }

                    // adapt wash tint to mode instead of crushing everything in black ink
                    Rectangle {
                        anchors.fill: parent
                        color: surface.isDark ? "#000000" : (Theme?.background ?? "#ffffff")
                        opacity: surface.isDark ? 0.50 : 0.65
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
                                text: (NetworkService?.isWiredConnected ?? false)
                                    ? (Theme?.iconEthernet ?? "󰈀")
                                    : ((NetworkService?.isWifiConnected ?? false) ? (Theme?.iconWifiHigh ?? "󰤨") : (Theme?.iconWifiOff ?? "󰤭"))
                                font.family: Theme?.fontIcon ?? "sans-serif"
                                font.pixelSize: Theme?.fontSizeMd ?? 14
                                color: (NetworkService?.isConnected ?? false) ? Theme.primary : Theme.on_surface_variant
                            }
                            Text {
                                text: (NetworkService?.isWiredConnected ?? false)
                                    ? "wired"
                                    : (NetworkService?.activeSsid || ((NetworkService?.isConnected ?? false) ? "connected" : "offline"))
                                font.family: Theme?.fontFamily ?? "sans-serif"
                                font.pixelSize: Theme?.fontSizeSm ?? 12
                                font.weight: Font.Medium
                                color: Theme.on_surface
                            }
                        }

                        RowLayout {
                            spacing: 6
                            visible: UPower.displayDevice?.isPresent ?? false

                            readonly property int batPct: {
                                let p = UPower.displayDevice?.percentage ?? 1.0;
                                return Math.min(100, Math.max(0, Math.round(p <= 1.0 ? p * 100 : p)));
                            }

                            Text {
                                text: Theme?.getBatteryIcon
                                    ? Theme.getBatteryIcon(parent.batPct, UPower.displayDevice?.state === UPowerDeviceState.Charging, !(UPower?.onBattery ?? true), false)
                                    : (Theme?.iconBatFull ?? "󰁹")
                                font.family: Theme?.fontIcon ?? "sans-serif"
                                font.pixelSize: Theme?.fontSizeMd ?? 14
                                color: Theme.primary
                            }
                            Text {
                                text: parent.batPct + "%"
                                font.family: Theme?.fontFamily ?? "sans-serif"
                                font.pixelSize: Theme?.fontSizeSm ?? 12
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
                                text: Qt.formatDateTime(lockRoot.currentTime, Settings?.clockFormat ?? (Settings?.clock24h ? "HH:mm" : "hh:mm A"))
                                font.family: Theme?.fontFamily ?? "sans-serif"
                                font.pixelSize: 84
                                font.weight: Font.Bold
                                color: Theme.on_surface
                                Layout.alignment: Qt.AlignHCenter
                            }

                            Text {
                                text: Qt.formatDateTime(lockRoot.currentTime, "dddd, MMMM d")
                                font.family: Theme?.fontFamily ?? "sans-serif"
                                font.pixelSize: Theme?.fontSizeMd ?? 14
                                font.weight: Font.Medium
                                color: Theme.primary
                                Layout.alignment: Qt.AlignHCenter
                            }
                        }

                        // media player card
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 72
                            radius: Theme?.radiusMd ?? 8
                            color: Theme?.cardBg ?? Theme.surface_container_high
                            border.color: Theme?.cardBorder ?? Theme.widgetBorder
                            border.width: 1
                            visible: surface.activePlayer !== null && ((surface.activePlayer?.trackTitle ?? "") !== "" || (surface.activePlayer?.isPlaying ?? false))

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 12

                                Rectangle {
                                    Layout.preferredWidth: 48
                                    Layout.preferredHeight: 48
                                    radius: Theme?.radiusSm ?? 6
                                    color: Theme.surface_container_highest
                                    clip: true

                                    Image {
                                        anchors.fill: parent
                                        source: surface.activePlayer?.trackArtUrl ?? ""
                                        fillMode: Image.PreserveAspectCrop
                                    }

                                    Text {
                                        anchors.centerIn: parent
                                        text: Theme?.iconMusic ?? "󰝚"
                                        font.family: Theme?.fontIcon ?? "sans-serif"
                                        font.pixelSize: Theme?.fontSizeMd ?? 14
                                        color: Theme.primary
                                        visible: !surface.activePlayer?.trackArtUrl
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2

                                    Text {
                                        text: surface.activePlayer?.trackTitle || "no track playing"
                                        font.family: Theme?.fontFamily ?? "sans-serif"
                                        font.pixelSize: Theme?.fontSizeSm ?? 12
                                        font.weight: Font.Bold
                                        color: Theme.on_surface
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        text: surface.activePlayer?.trackArtist || "unknown artist"
                                        font.family: Theme?.fontFamily ?? "sans-serif"
                                        font.pixelSize: Theme?.fontSizeXs ?? 10
                                        color: Theme.on_surface_variant
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                    }
                                }

                                IconButton {
                                    icon: Theme?.iconPrev ?? "⏮"
                                    iconSize: Theme?.fontSizeXs ?? 10
                                    tooltip: "previous"
                                    onClicked: surface.activePlayer?.previous()
                                }

                                IconButton {
                                    icon: (surface.activePlayer?.isPlaying ?? false) ? (Theme?.iconPause ?? "⏸") : (Theme?.iconPlay ?? "▶")
                                    iconSize: Theme?.fontSizeSm ?? 12
                                    tooltip: "toggle play"
                                    onClicked: surface.activePlayer?.togglePlaying()
                                }

                                IconButton {
                                    icon: Theme?.iconNext ?? "⏭"
                                    iconSize: Theme?.fontSizeXs ?? 10
                                    tooltip: "next"
                                    onClicked: surface.activePlayer?.next()
                                }
                            }
                        }

                        // password entry container
                        Rectangle {
                            id: pwContainer
                            Layout.fillWidth: true
                            Layout.preferredHeight: 48
                            radius: Theme?.radiusPill ?? 999
                            color: Theme?.cardBg ?? Theme.surface_container_high
                            border.color: lockRoot.authFailed ? Theme.error : (pwInput.activeFocus ? Theme.primary : (Theme?.cardBorder ?? Theme.widgetBorder))
                            border.width: 2

                            transform: Translate { id: pwShake }

                            SequentialAnimation {
                                id: shakeAnim
                                NumberAnimation { target: pwShake; property: "x"; from: 0; to: -14; duration: 45; easing.type: Easing.OutQuad }
                                NumberAnimation { target: pwShake; property: "x"; from: -14; to: 14; duration: 45; easing.type: Easing.InOutQuad }
                                NumberAnimation { target: pwShake; property: "x"; from: 14; to: -8; duration: 45; easing.type: Easing.InOutQuad }
                                NumberAnimation { target: pwShake; property: "x"; from: -8; to: 8; duration: 45; easing.type: Easing.InOutQuad }
                                NumberAnimation { target: pwShake; property: "x"; from: 8; to: 0; duration: 45; easing.type: Easing.OutQuad }
                            }

                            Connections {
                                target: lockRoot
                                function onTriggerShake() {
                                    shakeAnim.restart();
                                }
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 16
                                anchors.rightMargin: 12
                                spacing: 10

                                Text {
                                    text: Theme?.iconLock ?? "\uE899"
                                    font.family: Theme?.fontIcon ?? "sans-serif"
                                    font.pixelSize: Theme?.fontSizeMd ?? 14
                                    color: lockRoot.authFailed ? Theme.error : Theme.primary
                                }

                                TextInput {
                                    id: pwInput
                                    Layout.fillWidth: true
                                    echoMode: TextInput.Password
                                    font.family: Theme?.fontFamily ?? "sans-serif"
                                    font.pixelSize: Theme?.fontSizeMd ?? 14
                                    color: Theme.on_surface
                                    enabled: !lockRoot.isChecking
                                    passwordCharacter: "•"

                                    Text {
                                        anchors.fill: parent
                                        verticalAlignment: Text.AlignVCenter
                                        text: "enter password to unlock..."
                                        font.family: Theme?.fontFamily ?? "sans-serif"
                                        font.pixelSize: Theme?.fontSizeSm ?? 12
                                        color: Theme?.on_surface_disabled ?? Theme?.on_surface_variant ?? "#888888"
                                        visible: pwInput.text === "" && !pwInput.activeFocus
                                    }

                                    onTextChanged: {
                                        if (lockRoot.authFailed) lockRoot.authFailed = false;
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
                                    icon: Theme?.iconChevronRight ?? "➜"
                                    tooltip: "unlock"
                                    iconSize: Theme?.fontSizeSm ?? 12
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
                            font.family: Theme?.fontFamily ?? "sans-serif"
                            font.pixelSize: Theme?.fontSizeXs ?? 10
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
                            icon: Theme?.iconPower ?? "\uF8C7"
                            tooltip: "shut down"
                            iconSize: Theme?.fontSizeMd ?? 14
                            onClicked: Quickshell.execDetached(["systemctl", "poweroff"])
                        }

                        IconButton {
                            icon: Theme?.iconRefresh ?? "\uF053"
                            tooltip: "restart"
                            iconSize: Theme?.fontSizeMd ?? 14
                            onClicked: Quickshell.execDetached(["systemctl", "reboot"])
                        }

                        IconButton {
                            icon: Theme?.iconMoon ?? "\uF159"
                            tooltip: "sleep"
                            iconSize: Theme?.fontSizeMd ?? 14
                            onClicked: Quickshell.execDetached(["systemctl", "suspend"])
                        }
                    }

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