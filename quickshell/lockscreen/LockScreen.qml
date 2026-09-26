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
    property string pendingPassword: ""

    signal triggerShake()

    // 1. Snapshot time & clear auth state on lock
    onLockedChanged: {
        if (locked) {
            currentTime = new Date();
            authFailed = false;
            isChecking = false;
            pendingPassword = "";
        }
    }

    Timer {
        interval: 1000
        running: lockRoot.locked
        repeat: true
        onTriggered: lockRoot.currentTime = new Date()
    }

    // 2. Anti-hang PAM watchdog (8s safety timeout)
    Timer {
        id: pamSafetyTimeout
        interval: 8000
        onTriggered: {
            if (lockRoot.isChecking) {
                console.warn("[LockScreen] PAM conversation timed out. Aborting.");
                pam.abort();
                lockRoot.isChecking = false;
                lockRoot.pendingPassword = "";
                lockRoot.authFailed = true;
                lockRoot.triggerShake();
            }
        }
    }

    // 3. IPC (Lock only, backdoor removed)
    IpcHandler {
        target: "lock"
        function lock(): void {
            lockRoot.locked = true;
        }
    }

    PamContext {
        id: pam
        config: "login"
        user: Quickshell.env("USER") ?? ""

        function handleResponse(): void {
            if (responseRequired && lockRoot.pendingPassword) {
                let pw = lockRoot.pendingPassword;
                lockRoot.pendingPassword = "";
                pam.respond(pw);
            }
        }

        onPamMessage: handleResponse()
        onResponseRequiredChanged: handleResponse()

        onCompleted: (result) => {
            pamSafetyTimeout.stop();
            lockRoot.isChecking = false;
            lockRoot.pendingPassword = "";

            if (result === PamResult.Success) {
                lockRoot.locked = false;
                lockRoot.authFailed = false;
            } else {
                lockRoot.authFailed = true;
                lockRoot.triggerShake();
                shakeTimer.restart();
            }
        }

        onError: (err) => {
            console.warn("[LockScreen PAM Error]:", err);
        }
    }

    function tryUnlock(pw: string) {
        if (isChecking || !pw || pw.length === 0) return;

        isChecking = true;
        authFailed = false;
        pendingPassword = pw;
        pamSafetyTimeout.restart();

        if (!pam.start()) {
            pamSafetyTimeout.stop();
            isChecking = false;
            pendingPassword = "";
            authFailed = true;
            triggerShake();
        }
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

                // Power confirmation state (prevents accidental shutdowns)
                property string pendingPowerAction: ""

                Timer {
                    id: powerActionResetTimer
                    interval: 3500
                    onTriggered: surface.pendingPowerAction = ""
                }

                function requestPowerAction(action: string, cmd: var) {
                    if (surface.pendingPowerAction === action) {
                        surface.pendingPowerAction = "";
                        powerActionResetTimer.stop();
                        Quickshell.execDetached(cmd);
                    } else {
                        surface.pendingPowerAction = action;
                        powerActionResetTimer.restart();
                    }
                }

                readonly property var activePlayer: Mpris?.players?.values?.[0] ?? null

                Rectangle {
                    anchors.fill: parent
                    color: Theme.background
                    
                    // Keystroke capture: redirects any typed key directly to pwInput
                    focus: true
                    Keys.forwardTo: [pwInput]

                    MouseArea {
                        anchors.fill: parent
                        z: -1
                        onClicked: pwInput.forceActiveFocus()
                    }

                    // Backdrop Wallpaper
                    Image {
                        anchors.fill: parent
                        source: {
                            let wp = WallpaperService?.currentWallpaperPath ?? "";
                            if (!wp) return "";
                            return (wp.startsWith("file://") || wp.startsWith("http://") || wp.startsWith("https://")) ? wp : ("file://" + wp);
                        }
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                    }

                    // Theme Scrim / Tint Overlay (Matugen Scrim Token)
                    Rectangle {
                        anchors.fill: parent
                        color: Theme.scrim
                        opacity: 0.58
                    }

                    // Top Status Row (Wired/Wi-Fi + Battery via Theme resolvers)
                    RowLayout {
                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.margins: 32
                        spacing: 20

                        // Network Pill
                        RowLayout {
                            spacing: 8
                            Text {
                                text: Theme.getWifiIcon(
                                    NetworkService?.signalStrength ?? 100,
                                    NetworkService?.isConnected ?? false,
                                    NetworkService?.isWiredConnected ?? false
                                )
                                font.family: Theme.fontIcon
                                font.pixelSize: Theme.fontSizeMd
                                color: (NetworkService?.isConnected ?? false) ? Theme.primary : Theme.on_surface_variant
                            }
                            Text {
                                text: (NetworkService?.isWiredConnected ?? false)
                                    ? "wired"
                                    : (NetworkService?.activeSsid || ((NetworkService?.isConnected ?? false) ? "connected" : "offline"))
                                font.family: Theme.fontSans
                                font.pixelSize: Theme.fontSizeSm
                                font.weight: Theme.fontWeightMedium
                                color: Theme.on_surface
                            }
                        }

                        // Battery Pill
                        RowLayout {
                            spacing: 8
                            visible: UPower.displayDevice?.isPresent ?? false

                            readonly property int batPct: {
                                let p = UPower.displayDevice?.percentage ?? 1.0;
                                return Math.min(100, Math.max(0, Math.round(p * 100)));
                            }
                            readonly property bool isCharging: UPower.displayDevice?.state === UPowerDeviceState.Charging

                            Text {
                                text: Theme.getBatteryIcon(parent.batPct, parent.isCharging, !(UPower?.onBattery ?? true), false)
                                font.family: Theme.fontIcon
                                font.pixelSize: Theme.fontSizeMd
                                color: Theme.getBatteryColor(parent.batPct, parent.isCharging)
                            }
                            Text {
                                text: parent.batPct + "%"
                                font.family: Theme.fontMono
                                font.pixelSize: Theme.fontSizeSm
                                font.weight: Theme.fontWeightMedium
                                color: Theme.on_surface
                            }
                        }
                    }

                    // Center Lock Card
                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 24
                        width: 440

                        // Clock & Flavor Header
                        ColumnLayout {
                            Layout.alignment: Qt.AlignHCenter
                            spacing: 6

                            // Big Display Clock
                            Text {
                                text: Qt.formatDateTime(lockRoot.currentTime, Settings?.clockFormat ?? (Settings?.clock24h ? "HH:mm" : "hh:mm A"))
                                font.family: Theme.fontDisplay
                                font.pixelSize: Math.round(86 * Theme.fontScale)
                                font.weight: Theme.fontWeightBold
                                color: Theme.on_surface
                                Layout.alignment: Qt.AlignHCenter
                            }

                            // Formatted Date
                            Text {
                                text: Qt.formatDateTime(lockRoot.currentTime, "dddd, MMMM d")
                                font.family: Theme.fontSans
                                font.pixelSize: Theme.fontSizeMd
                                font.weight: Theme.fontWeightMedium
                                color: Theme.primary
                                Layout.alignment: Qt.AlignHCenter
                            }

                            // Dynamic Unhinged Flavor Subtext
                            Text {
                                text: Theme.getFlavor("system", "")
                                font.family: Theme.fontSans
                                font.pixelSize: Theme.fontSizeXs
                                color: Theme.on_surface_disabled
                                Layout.alignment: Qt.AlignHCenter
                                Layout.maximumWidth: 420
                                horizontalAlignment: Text.AlignHCenter
                                elide: Text.ElideRight
                                visible: text !== ""
                            }
                        }

                        // MPRIS Media Card
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 74
                            radius: Theme.radiusLg
                            color: Theme.cardBg
                            border.color: Theme.cardBorder
                            border.width: 1
                            visible: surface.activePlayer !== null && ((surface.activePlayer?.trackTitle ?? "") !== "" || (surface.activePlayer?.isPlaying ?? false))

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 12

                                // Album Thumbnail / Fallback Icon
                                Rectangle {
                                    Layout.preferredWidth: 50
                                    Layout.preferredHeight: 50
                                    radius: Theme.radiusMd
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
                                        font.pixelSize: Theme.fontSizeLg
                                        color: Theme.primary
                                        visible: !surface.activePlayer?.trackArtUrl
                                    }
                                }

                                // Track & Artist Meta
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2

                                    Text {
                                        text: surface.activePlayer?.trackTitle || "no track playing"
                                        font.family: Theme.fontSans
                                        font.pixelSize: Theme.fontSizeSm
                                        font.weight: Theme.fontWeightDemiBold
                                        color: Theme.on_surface
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        text: surface.activePlayer?.trackArtist || "unknown artist"
                                        font.family: Theme.fontSans
                                        font.pixelSize: Theme.fontSizeXs
                                        color: Theme.on_surface_variant
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                    }
                                }

                                // Media Controls
                                IconButton {
                                    icon: Theme.iconPrev
                                    iconSize: Theme.fontSizeSm
                                    tooltip: "previous"
                                    onClicked: surface.activePlayer?.previous()
                                }

                                IconButton {
                                    icon: (surface.activePlayer?.isPlaying ?? false) ? Theme.iconPause : Theme.iconPlay
                                    iconSize: Theme.fontSizeMd
                                    tooltip: "toggle play"
                                    onClicked: surface.activePlayer?.togglePlaying()
                                }

                                IconButton {
                                    icon: Theme.iconNext
                                    iconSize: Theme.fontSizeSm
                                    tooltip: "next"
                                    onClicked: surface.activePlayer?.next()
                                }
                            }
                        }

                        // Password Entry Pill
                        Rectangle {
                            id: pwContainer
                            Layout.fillWidth: true
                            Layout.preferredHeight: 48
                            radius: Theme.radiusPill
                            color: Theme.pillBg
                            border.color: lockRoot.authFailed 
                                ? Theme.error 
                                : (pwInput.activeFocus ? Theme.primary : Theme.pillBorder)
                            border.width: pwInput.activeFocus || lockRoot.authFailed ? 2 : 1

                            transform: Translate { id: pwShake }

                            SequentialAnimation {
                                id: shakeAnim
                                NumberAnimation { target: pwShake; property: "x"; from: 0; to: -14; duration: Math.max(30, Math.round(Theme.animFast / 3)); easing.type: Easing.OutQuad }
                                NumberAnimation { target: pwShake; property: "x"; from: -14; to: 14; duration: Math.max(30, Math.round(Theme.animFast / 3)); easing.type: Easing.InOutQuad }
                                NumberAnimation { target: pwShake; property: "x"; from: 14; to: -8; duration: Math.max(30, Math.round(Theme.animFast / 3)); easing.type: Easing.InOutQuad }
                                NumberAnimation { target: pwShake; property: "x"; from: -8; to: 8; duration: Math.max(30, Math.round(Theme.animFast / 3)); easing.type: Easing.InOutQuad }
                                NumberAnimation { target: pwShake; property: "x"; from: 8; to: 0; duration: Math.max(30, Math.round(Theme.animFast / 3)); easing.type: Easing.OutQuad }
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
                                anchors.rightMargin: 10
                                spacing: 10

                                Text {
                                    text: Theme.iconLock
                                    font.family: Theme.fontIcon
                                    font.pixelSize: Theme.fontSizeMd
                                    color: lockRoot.authFailed 
                                        ? Theme.error 
                                        : (pwInput.activeFocus ? Theme.primary : Theme.on_surface_variant)
                                }

                                TextInput {
                                    id: pwInput
                                    Layout.fillWidth: true
                                    echoMode: TextInput.Password
                                    font.family: Theme.fontMono
                                    font.pixelSize: Theme.fontSizeMd
                                    color: Theme.on_surface
                                    selectionColor: Theme.primary_container
                                    selectedTextColor: Theme.on_primary_container
                                    enabled: !lockRoot.isChecking
                                    passwordCharacter: "•"

                                    Text {
                                        anchors.fill: parent
                                        verticalAlignment: Text.AlignVCenter
                                        text: "enter password to unlock..."
                                        font.family: Theme.fontSans
                                        font.pixelSize: Theme.fontSizeSm
                                        color: Theme.on_surface_disabled
                                        visible: pwInput.text.length === 0
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

                        // Feedback Status Label
                        Text {
                            text: lockRoot.isChecking ? "authenticating..." : (lockRoot.authFailed ? "incorrect password, try again" : "")
                            font.family: Theme.fontSans
                            font.pixelSize: Theme.fontSizeXs
                            font.weight: Theme.fontWeightMedium
                            color: lockRoot.authFailed ? Theme.error : Theme.on_surface_disabled
                            Layout.alignment: Qt.AlignHCenter
                            visible: text !== ""
                        }
                    }

                    // Bottom Power Management Row with 2-Step Confirmation
                    RowLayout {
                        anchors.bottom: parent.bottom
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.margins: 40
                        spacing: 20

                        IconButton {
                            icon: surface.pendingPowerAction === "poweroff" ? (Theme.iconFlame) : Theme.iconPower
                            tooltip: surface.pendingPowerAction === "poweroff" ? "press again to shut down" : "shut down"
                            iconSize: Theme.fontSizeLg
                            onClicked: surface.requestPowerAction("poweroff", ["systemctl", "poweroff"])
                        }

                        IconButton {
                            icon: surface.pendingPowerAction === "reboot" ? (Theme.iconFlame) : Theme.iconReboot
                            tooltip: surface.pendingPowerAction === "reboot" ? "press again to restart" : "restart"
                            iconSize: Theme.fontSizeLg
                            onClicked: surface.requestPowerAction("reboot", ["systemctl", "reboot"])
                        }

                        IconButton {
                            icon: surface.pendingPowerAction === "suspend" ? (Theme.iconFlame) : Theme.iconSuspend
                            tooltip: surface.pendingPowerAction === "suspend" ? "press again to sleep" : "sleep"
                            iconSize: Theme.fontSizeLg
                            onClicked: surface.requestPowerAction("suspend", ["systemctl", "suspend"])
                        }
                    }

                    // Themed Concave Screen Corners
                    ConcaveCorner {
                        anchors.top: parent.top
                        anchors.left: parent.left
                        radiusX: Theme.screenCornerRadius
                        radiusY: Theme.screenCornerRadius
                        fillColor: Theme.cornerFill
                        flipX: false
                        flipY: false
                        visible: Theme.screenCornerRadius > 0
                    }

                    ConcaveCorner {
                        anchors.top: parent.top
                        anchors.right: parent.right
                        radiusX: Theme.screenCornerRadius
                        radiusY: Theme.screenCornerRadius
                        fillColor: Theme.cornerFill
                        flipX: true
                        flipY: false
                        visible: Theme.screenCornerRadius > 0
                    }

                    ConcaveCorner {
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        radiusX: Theme.screenCornerRadius
                        radiusY: Theme.screenCornerRadius
                        fillColor: Theme.cornerFill
                        flipX: false
                        flipY: true
                        visible: Theme.screenCornerRadius > 0
                    }

                    ConcaveCorner {
                        anchors.bottom: parent.bottom
                        anchors.right: parent.right
                        radiusX: Theme.screenCornerRadius
                        radiusY: Theme.screenCornerRadius
                        fillColor: Theme.cornerFill
                        flipX: true
                        flipY: true
                        visible: Theme.screenCornerRadius > 0
                    }
                }
            }
        }
    }
}
