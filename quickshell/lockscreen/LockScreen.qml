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
    property string sharedPassword: ""
    property bool revealPassword: false

    // standalone lockscreen sandbox state (~/.config/quickshell/lockscreen.json)
    readonly property string configDir: Quickshell.env("XDG_CONFIG_HOME") || ((Quickshell.env("HOME") || "") + "/.config")
    readonly property string lockSandboxPath: configDir + "/quickshell/lockscreen.json"

    property bool syncClockGlobal: false
    property bool sandboxClock24h: false
    property bool showSeconds: false
    property real clockScale: 1.0
    property string quoteMode: "hyprland"
    property real scrimDim: 0.58
    property bool showMediaCard: true
    property bool showUserPill: true
    property bool wallpaperSync: true
    property string localWallpaperOverride: ""

    property string hyprSplash: ""
    property string unhingedQuote: ""

    readonly property string currentUser: (Quickshell.env("USER") || "user").toLowerCase()
    readonly property string lockTokenPath: (Quickshell.env("XDG_RUNTIME_DIR") ?? "/tmp") + "/qs_session_locked.token"

    // effective clock settings depending on whether sandbox or global sync is active
    readonly property bool effectiveClock24h: syncClockGlobal
        ? Boolean(Settings?.clock24h ?? Settings?.clockMilitary ?? (/H/.test(Settings?.clockFormat ?? "")))
        : sandboxClock24h

    readonly property bool effectiveShowSeconds: syncClockGlobal
        ? Boolean(Settings?.clockShowSeconds ?? (/:ss/i.test(Settings?.clockFormat ?? "")))
        : showSeconds

    property FileView lockSandboxFile: FileView {
        path: lockRoot.lockSandboxPath
        blockLoading: true
        watchChanges: true
        printErrors: false
        onFileChanged: {
            reload();
            lockRoot.loadSandbox();
        }
        onLoaded: lockRoot.loadSandbox()
    }

    function loadSandbox() {
        let raw = lockSandboxFile.text();
        if (!raw || raw.trim() === "") return;
        try {
            let d = JSON.parse(raw);
            if (d.syncClockGlobal !== undefined) lockRoot.syncClockGlobal = Boolean(d.syncClockGlobal);
            if (d.clock24h !== undefined) lockRoot.sandboxClock24h = Boolean(d.clock24h);
            if (d.showSeconds !== undefined) lockRoot.showSeconds = Boolean(d.showSeconds);
            if (d.clockScale !== undefined) lockRoot.clockScale = Number(d.clockScale);
            if (d.quoteMode !== undefined) lockRoot.quoteMode = String(d.quoteMode);
            if (d.scrimDim !== undefined) lockRoot.scrimDim = Number(d.scrimDim);
            if (d.showMedia !== undefined) lockRoot.showMediaCard = Boolean(d.showMedia);
            if (d.showUser !== undefined) lockRoot.showUserPill = Boolean(d.showUser);
            if (d.wallpaperSync !== undefined) lockRoot.wallpaperSync = Boolean(d.wallpaperSync);
            if (d.customWallpaper !== undefined) lockRoot.localWallpaperOverride = String(d.customWallpaper);
        } catch (e) {}
    }

    function saveSandbox() {
        let payload = {
            syncClockGlobal: lockRoot.syncClockGlobal,
            clock24h: lockRoot.sandboxClock24h,
            showSeconds: lockRoot.showSeconds,
            clockScale: lockRoot.clockScale,
            quoteMode: lockRoot.quoteMode,
            scrimDim: lockRoot.scrimDim,
            showMedia: lockRoot.showMediaCard,
            showUser: lockRoot.showUserPill,
            wallpaperSync: lockRoot.wallpaperSync,
            customWallpaper: lockRoot.localWallpaperOverride
        };
        lockSandboxFile.setText(JSON.stringify(payload, null, 2));

        // mirror to global Settings when global clock sync is enabled
        if (lockRoot.syncClockGlobal && typeof Settings !== "undefined" && Settings) {
            let fmt = lockRoot.sandboxClock24h
                ? (lockRoot.showSeconds ? "HH:mm:ss" : "HH:mm")
                : (lockRoot.showSeconds ? "h:mm:ss ap" : "h:mm ap");
            Settings.clockFormat = fmt;
            Settings.clock24h = lockRoot.sandboxClock24h;
            Settings.clockMilitary = lockRoot.sandboxClock24h;
            Settings.clockShowSeconds = lockRoot.showSeconds;
            if (Settings.save) Settings.save();
        }
    }

    property FileView lockTokenFile: FileView {
        path: lockRoot.lockTokenPath
        blockLoading: true
        watchChanges: true
        printErrors: false
        onLoaded: {
            let t = text();
            if (t && t.trim() === "locked" && !lockRoot.locked) {
                lockRoot.locked = true;
            }
        }
    }

    // grab a fresh quote from hyprctl splash and force lowercase
    property Process splashProc: Process {
        command: ["hyprctl", "splash"]
        stdout: StdioCollector {
            onStreamFinished: {
                let raw = (text || "").trim().toLowerCase();
                if (raw !== "" && !raw.startsWith("error") && !raw.startsWith("unknown")) {
                    lockRoot.hyprSplash = raw;
                } else if (lockRoot.hyprSplash === "") {
                    lockRoot.hyprSplash = "hyprland: wayland compositor";
                }
            }
        }
    }

    function refreshQuotes() {
        splashProc.running = true;
        let pool = Theme.flavorQuotes?.system;
        if (pool && pool.length > 0) {
            let idx = Math.floor(Math.random() * pool.length);
            lockRoot.unhingedQuote = (pool[idx] || "").toLowerCase();
        } else if (Theme.getFlavor) {
            lockRoot.unhingedQuote = (Theme.getFlavor("system", "") || "").toLowerCase();
        }
    }

    readonly property string activeQuoteText: {
        if (lockRoot.quoteMode === "off") return "";
        if (lockRoot.quoteMode === "unhinged") {
            return lockRoot.unhingedQuote || (Theme.getFlavor ? Theme.getFlavor("system", "") : "");
        }
        return lockRoot.hyprSplash || (Theme.getFlavor ? Theme.getFlavor("system", "") : "");
    }

    Component.onCompleted: {
        loadSandbox();
        refreshQuotes();
        let t = lockTokenFile.text();
        if (t && t.trim() === "locked" && !lockRoot.locked) {
            lockRoot.locked = true;
        }
    }

    function pickRandomWallpaperInMemory(): string {
        if (typeof WallpaperService !== "undefined" && WallpaperService) {
            if (typeof WallpaperService.getRandomWallpaperPath === "function") {
                let wp = WallpaperService.getRandomWallpaperPath();
                if (wp && wp !== "") return wp;
            }
            if (WallpaperService.wallpaperList && WallpaperService.wallpaperList.length > 0) {
                let list = WallpaperService.wallpaperList;
                let item = list[Math.floor(Math.random() * list.length)];
                let p = item?.path ?? item?.url ?? "";
                if (p !== "") return p;
            }
            if (WallpaperService.localWpListFile) {
                try {
                    let raw = WallpaperService.localWpListFile.text();
                    let parsed = JSON.parse(raw) || [];
                    let staticList = parsed.filter(w => w && w.path && !/\.(mp4|webm|mkv|mov)$/i.test(w.path));
                    let pool = staticList.length > 0 ? staticList : parsed;
                    if (pool.length > 0) {
                        return pool[Math.floor(Math.random() * pool.length)].path || "";
                    }
                } catch (e) {}
            }
            if (WallpaperService.currentWallpaperPath) return WallpaperService.currentWallpaperPath;
            if (WallpaperService.currWallStatic) return WallpaperService.currWallStatic;
        }
        return "";
    }

    signal triggerShake()

    onLockedChanged: {
        if (locked) {
            currentTime = new Date();
            authFailed = false;
            isChecking = false;
            pendingPassword = "";
            sharedPassword = "";
            revealPassword = false;
            loadSandbox();
            refreshQuotes();
            lockTokenFile.setText("locked");
        } else {
            sharedPassword = "";
            revealPassword = false;
            lockTokenFile.setText("");
            Quickshell.execDetached(["rm", "-f", lockTokenPath]);
        }
    }

    Timer {
        interval: 1000
        running: lockRoot.locked
        repeat: true
        onTriggered: lockRoot.currentTime = new Date()
    }

    // 8s anti-hang pam watchdog
    Timer {
        id: pamSafetyTimeout
        interval: 8000
        onTriggered: {
            if (lockRoot.isChecking) {
                pam.abort();
                lockRoot.isChecking = false;
                lockRoot.pendingPassword = "";
                lockRoot.authFailed = true;
                lockRoot.triggerShake();
            }
        }
    }

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
        sharedPassword = "";
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
        interval: 1600
        onTriggered: lockRoot.authFailed = false
    }

    WlSessionLock {
        id: sessionLock
        locked: lockRoot.locked

        surface: Component {
            WlSessionLockSurface {
                id: surface

                property string pendingPowerAction: ""
                property bool optionsOpen: false

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

                component OptChip: Rectangle {
                    id: cRoot
                    property string label: ""
                    property bool selected: false
                    signal clicked()

                    Layout.fillWidth: true
                    Layout.preferredHeight: 26
                    radius: Theme.radiusPill
                    color: selected ? Theme.primary_overlay : (cMouse.containsMouse ? Theme.surface_container_high : "transparent")
                    border.color: selected ? Theme.primary : (Theme.outline_variant ?? Theme.cardBorder)
                    border.width: 1

                    Behavior on color { ColorAnimation { duration: Theme.animFast } }
                    Behavior on border.color { ColorAnimation { duration: Theme.animFast } }

                    Text {
                        anchors.centerIn: parent
                        text: cRoot.label
                        font.family: Theme.fontSans
                        font.pixelSize: Theme.fontSizeXs
                        font.weight: cRoot.selected ? Font.Bold : Font.Normal
                        color: cRoot.selected ? Theme.primary : Theme.on_surface_variant
                    }

                    MouseArea {
                        id: cMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: cRoot.clicked()
                    }
                }

                component PowerPill: Rectangle {
                    id: pRoot
                    property string actionId: ""
                    property string icon: ""
                    property string label: ""
                    property var command: []

                    readonly property bool isArmed: surface.pendingPowerAction === pRoot.actionId

                    height: 38
                    implicitWidth: isArmed ? (pRow.implicitWidth + 24) : 38
                    radius: Theme.radiusPill
                    color: isArmed
                        ? (Theme.error ?? "#ff5449")
                        : (pMouse.containsMouse ? Theme.surface_container_highest : Theme.alpha(Theme.surface_container_high, 0.78))
                    border.color: isArmed
                        ? (Theme.error ?? "#ff5449")
                        : (pMouse.containsMouse ? Theme.primary : Theme.cardBorder)
                    border.width: 1

                    Behavior on implicitWidth { NumberAnimation { duration: Theme.animFast; easing.type: Theme.animEasing } }
                    Behavior on color { ColorAnimation { duration: Theme.animFast } }
                    Behavior on border.color { ColorAnimation { duration: Theme.animFast } }

                    RowLayout {
                        id: pRow
                        anchors.centerIn: parent
                        spacing: 6

                        Text {
                            text: pRoot.isArmed ? Theme.iconFlame : pRoot.icon
                            font.family: Theme.fontIcon
                            font.pixelSize: Theme.fontSizeMd
                            color: pRoot.isArmed ? (Theme.on_error ?? "#ffffff") : (pMouse.containsMouse ? Theme.primary : Theme.on_surface)
                        }

                        Text {
                            visible: pRoot.isArmed
                            text: "confirm " + pRoot.label + "?"
                            font.family: Theme.fontSans
                            font.pixelSize: Theme.fontSizeXs
                            font.weight: Font.Bold
                            color: Theme.on_error ?? "#ffffff"
                        }
                    }

                    MouseArea {
                        id: pMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: surface.requestPowerAction(pRoot.actionId, pRoot.command)
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    color: Theme.background

                    focus: true
                    Keys.forwardTo: [pwInput]

                    MouseArea {
                        anchors.fill: parent
                        z: -1
                        onClicked: {
                            surface.optionsOpen = false;
                            surface.pendingPowerAction = "";
                            pwInput.forceActiveFocus();
                        }
                    }

                    // backdrop wallpaper
                    Image {
                        anchors.fill: parent
                        source: {
                            let wp = "";
                            if (!lockRoot.wallpaperSync && lockRoot.localWallpaperOverride !== "") {
                                wp = lockRoot.localWallpaperOverride;
                            } else {
                                wp = WallpaperService?.currentWallpaperPath ?? lockRoot.localWallpaperOverride ?? "";
                            }
                            if (!wp || wp === "" || /\.(mp4|webm|mkv|mov)$/i.test(wp)) {
                                wp = WallpaperService?.currWallStatic ?? ((Quickshell.env("HOME") || "") + "/.curr_wall_static.jpg");
                            }
                            if (!wp) return "";
                            return (wp.startsWith("file://") || wp.startsWith("http://") || wp.startsWith("https://")) ? wp : ("file://" + wp);
                        }
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                    }

                    // adjustable matugen scrim overlay
                    Rectangle {
                        anchors.fill: parent
                        color: Theme.scrim
                        opacity: lockRoot.scrimDim
                        Behavior on opacity { NumberAnimation { duration: Theme.animNormal } }
                    }

                    // top-left user session badge
                    Rectangle {
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.margins: 32
                        visible: lockRoot.showUserPill
                        height: 34
                        implicitWidth: userRow.implicitWidth + 20
                        radius: Theme.radiusPill
                        color: Theme.alpha(Theme.surface_container_high, 0.72)
                        border.color: Theme.cardBorder
                        border.width: 1

                        RowLayout {
                            id: userRow
                            anchors.centerIn: parent
                            spacing: 8

                            Text {
                                text: Theme.iconDistro ?? Theme.iconUser
                                font.family: Theme.fontIcon
                                font.pixelSize: Theme.fontSizeMd
                                color: Theme.primary
                            }

                            Text {
                                text: lockRoot.currentUser
                                font.family: Theme.fontMono
                                font.pixelSize: Theme.fontSizeSm
                                font.weight: Theme.fontWeightDemiBold
                                color: Theme.on_surface
                            }

                            Text {
                                text: lockRoot.syncClockGlobal ? "• global" : "• sandbox"
                                font.family: Theme.fontMono
                                font.pixelSize: Theme.fontSizeXs
                                color: Theme.on_surface_variant
                            }
                        }
                    }

                    // top-right status pill
                    Rectangle {
                        id: statusBar
                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.margins: 32
                        height: 36
                        implicitWidth: statusRow.implicitWidth + 20
                        radius: Theme.radiusPill
                        color: Theme.alpha(Theme.surface_container_high, 0.72)
                        border.color: surface.optionsOpen ? Theme.primary : Theme.cardBorder
                        border.width: 1

                        RowLayout {
                            id: statusRow
                            anchors.centerIn: parent
                            spacing: 14

                            RowLayout {
                                spacing: 6
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
                                    text: ((NetworkService?.isWiredConnected ?? false)
                                        ? "wired"
                                        : (NetworkService?.activeSsid || ((NetworkService?.isConnected ?? false) ? "connected" : "offline"))
                                    ).toLowerCase()
                                    font.family: Theme.fontSans
                                    font.pixelSize: Theme.fontSizeXs
                                    font.weight: Theme.fontWeightMedium
                                    color: Theme.on_surface
                                }
                            }

                            RowLayout {
                                spacing: 6
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
                                    font.pixelSize: Theme.fontSizeXs
                                    font.weight: Theme.fontWeightMedium
                                    color: Theme.on_surface
                                }
                            }

                            IconButton {
                                icon: Theme.iconSliders
                                iconSize: Theme.fontSizeSm
                                tooltip: "customize lock screen"
                                highlighted: surface.optionsOpen
                                onClicked: surface.optionsOpen = !surface.optionsOpen
                            }
                        }
                    }

                    // sandbox & global customization dropdown panel
                    Rectangle {
                        id: optionsCard
                        anchors.top: statusBar.bottom
                        anchors.right: statusBar.right
                        anchors.topMargin: 10
                        width: 320
                        implicitHeight: optionsLayout.implicitHeight + 28
                        radius: Theme.radiusLg
                        color: Theme.cardBg
                        border.color: Theme.cardBorder
                        border.width: 1
                        visible: opacity > 0
                        opacity: surface.optionsOpen ? 1.0 : 0.0
                        scale: surface.optionsOpen ? 1.0 : 0.96
                        z: 100

                        Behavior on opacity { NumberAnimation { duration: Theme.animNormal; easing.type: Theme.animEasing } }
                        Behavior on scale { NumberAnimation { duration: Theme.animNormal; easing.type: Theme.animEasing } }

                        MouseArea {
                            anchors.fill: parent
                            z: -1
                        }

                        ColumnLayout {
                            id: optionsLayout
                            anchors.fill: parent
                            anchors.margins: 14
                            spacing: 10

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                Text {
                                    text: Theme.iconSliders
                                    font.family: Theme.fontIcon
                                    font.pixelSize: Theme.fontSizeMd
                                    color: Theme.primary
                                }

                                Text {
                                    text: "lock screen sandbox"
                                    font.family: Theme.fontSans
                                    font.pixelSize: Theme.fontSizeSm
                                    font.weight: Theme.fontWeightDemiBold
                                    color: Theme.on_surface
                                    Layout.fillWidth: true
                                }

                                Rectangle {
                                    height: 20
                                    implicitWidth: scopeBadge.implicitWidth + 12
                                    radius: Theme.radiusPill
                                    color: lockRoot.syncClockGlobal ? Theme.primary_overlay : Theme.surface_container_high
                                    border.color: lockRoot.syncClockGlobal ? Theme.primary : Theme.outline_variant
                                    border.width: 1

                                    Text {
                                        id: scopeBadge
                                        anchors.centerIn: parent
                                        text: lockRoot.syncClockGlobal ? "global sync" : "sandboxed"
                                        font.family: Theme.fontMono
                                        font.pixelSize: 9
                                        font.weight: Font.Bold
                                        color: lockRoot.syncClockGlobal ? Theme.primary : Theme.on_surface_variant
                                    }
                                }

                                IconButton {
                                    icon: Theme.iconClose
                                    iconSize: Theme.fontSizeXs
                                    tooltip: "close"
                                    onClicked: {
                                        surface.optionsOpen = false;
                                        pwInput.forceActiveFocus();
                                    }
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                height: 1
                                color: Theme.outline_disabled
                            }

                            // quote source selector
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 6

                                Text {
                                    text: "quote source"
                                    font.family: Theme.fontSans
                                    font.pixelSize: Theme.fontSizeXs
                                    color: Theme.on_surface_variant
                                    Layout.fillWidth: true
                                }

                                IconButton {
                                    icon: Theme.iconRefresh
                                    iconSize: Theme.fontSizeXs
                                    tooltip: "roll new quote"
                                    visible: lockRoot.quoteMode !== "off"
                                    onClicked: lockRoot.refreshQuotes()
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 6

                                OptChip {
                                    label: "hyprctl splash"
                                    selected: lockRoot.quoteMode === "hyprland"
                                    onClicked: {
                                        lockRoot.quoteMode = "hyprland";
                                        lockRoot.refreshQuotes();
                                        lockRoot.saveSandbox();
                                    }
                                }

                                OptChip {
                                    label: "unhinged"
                                    selected: lockRoot.quoteMode === "unhinged"
                                    onClicked: {
                                        lockRoot.quoteMode = "unhinged";
                                        lockRoot.refreshQuotes();
                                        lockRoot.saveSandbox();
                                    }
                                }

                                OptChip {
                                    label: "off"
                                    selected: lockRoot.quoteMode === "off"
                                    onClicked: {
                                        lockRoot.quoteMode = "off";
                                        lockRoot.saveSandbox();
                                    }
                                }
                            }

                            // clock format & seconds
                            Text {
                                text: lockRoot.syncClockGlobal ? "clock format (global across rice)" : "clock format (lock sandbox only)"
                                font.family: Theme.fontSans
                                font.pixelSize: Theme.fontSizeXs
                                color: Theme.on_surface_variant
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 6

                                OptChip {
                                    label: "12-hour"
                                    selected: !lockRoot.effectiveClock24h
                                    onClicked: {
                                        lockRoot.sandboxClock24h = false;
                                        lockRoot.saveSandbox();
                                    }
                                }

                                OptChip {
                                    label: "24-hour"
                                    selected: lockRoot.effectiveClock24h
                                    onClicked: {
                                        lockRoot.sandboxClock24h = true;
                                        lockRoot.saveSandbox();
                                    }
                                }

                                OptChip {
                                    label: "seconds"
                                    selected: lockRoot.effectiveShowSeconds
                                    onClicked: {
                                        lockRoot.showSeconds = !lockRoot.effectiveShowSeconds;
                                        lockRoot.saveSandbox();
                                    }
                                }
                            }

                            // clock size scale
                            Text {
                                text: "clock size"
                                font.family: Theme.fontSans
                                font.pixelSize: Theme.fontSizeXs
                                color: Theme.on_surface_variant
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 6

                                Repeater {
                                    model: [
                                        { label: "compact", val: 0.82 },
                                        { label: "default", val: 1.0 },
                                        { label: "large", val: 1.18 },
                                        { label: "massive", val: 1.35 }
                                    ]

                                    delegate: OptChip {
                                        required property var modelData
                                        label: modelData.label
                                        selected: Math.abs(lockRoot.clockScale - modelData.val) < 0.05
                                        onClicked: {
                                            lockRoot.clockScale = modelData.val;
                                            lockRoot.saveSandbox();
                                        }
                                    }
                                }
                            }

                            // backdrop dim / scrim intensity
                            Text {
                                text: "backdrop dim"
                                font.family: Theme.fontSans
                                font.pixelSize: Theme.fontSizeXs
                                color: Theme.on_surface_variant
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 6

                                Repeater {
                                    model: [
                                        { label: "35%", val: 0.35 },
                                        { label: "58%", val: 0.58 },
                                        { label: "75%", val: 0.75 },
                                        { label: "90%", val: 0.90 }
                                    ]

                                    delegate: OptChip {
                                        required property var modelData
                                        label: modelData.label
                                        selected: Math.abs(lockRoot.scrimDim - modelData.val) < 0.05
                                        onClicked: {
                                            lockRoot.scrimDim = modelData.val;
                                            lockRoot.saveSandbox();
                                        }
                                    }
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                height: 1
                                color: Theme.outline_disabled
                            }

                            // shuffle wallpaper button
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 34
                                radius: Theme.radiusMd
                                color: shuffleMouse.pressed ? Theme.widgetActive : (shuffleMouse.containsMouse ? Theme.widgetHover : Theme.surface_container_high)
                                border.color: shuffleMouse.containsMouse ? Theme.primary : Theme.cardBorder
                                border.width: 1

                                Behavior on color { ColorAnimation { duration: Theme.animFast } }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 10
                                    spacing: 8

                                    Text {
                                        text: Theme.iconShuffle
                                        font.family: Theme.fontIcon
                                        font.pixelSize: Theme.fontSizeMd
                                        color: Theme.primary
                                    }

                                    Text {
                                        text: "shuffle lock wallpaper"
                                        font.family: Theme.fontSans
                                        font.pixelSize: Theme.fontSizeXs
                                        font.weight: Theme.fontWeightMedium
                                        color: Theme.on_surface
                                        Layout.fillWidth: true
                                    }
                                }

                                MouseArea {
                                    id: shuffleMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        let nextWp = lockRoot.pickRandomWallpaperInMemory();
                                        if (nextWp && nextWp !== "") {
                                            lockRoot.wallpaperSync = false;
                                            lockRoot.localWallpaperOverride = nextWp;
                                            lockRoot.saveSandbox();
                                        }
                                    }
                                }
                            }

                            // sync clock globally across the rice toggle
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 10

                                Text {
                                    text: Theme.iconClock
                                    font.family: Theme.fontIcon
                                    font.pixelSize: Theme.fontSizeMd
                                    color: lockRoot.syncClockGlobal ? Theme.primary : Theme.on_surface_variant
                                }

                                Text {
                                    text: "sync clock globally across rice"
                                    font.family: Theme.fontSans
                                    font.pixelSize: Theme.fontSizeXs
                                    color: Theme.on_surface
                                    Layout.fillWidth: true
                                }

                                ToggleSwitch {
                                    checked: lockRoot.syncClockGlobal
                                    onToggled: {
                                        lockRoot.syncClockGlobal = !lockRoot.syncClockGlobal;
                                        lockRoot.saveSandbox();
                                    }
                                }
                            }

                            // sync desktop wallpaper toggle
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 10

                                Text {
                                    text: Theme.iconWallpaper
                                    font.family: Theme.fontIcon
                                    font.pixelSize: Theme.fontSizeMd
                                    color: lockRoot.wallpaperSync ? Theme.primary : Theme.on_surface_variant
                                }

                                Text {
                                    text: "sync wallpaper with desktop"
                                    font.family: Theme.fontSans
                                    font.pixelSize: Theme.fontSizeXs
                                    color: Theme.on_surface
                                    Layout.fillWidth: true
                                }

                                ToggleSwitch {
                                    checked: lockRoot.wallpaperSync
                                    onToggled: {
                                        lockRoot.wallpaperSync = !lockRoot.wallpaperSync;
                                        if (lockRoot.wallpaperSync) {
                                            lockRoot.localWallpaperOverride = "";
                                        }
                                        lockRoot.saveSandbox();
                                    }
                                }
                            }

                            // show media player toggle
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 10

                                Text {
                                    text: lockRoot.showMediaCard ? Theme.iconMusic : Theme.iconEyeOff
                                    font.family: Theme.fontIcon
                                    font.pixelSize: Theme.fontSizeMd
                                    color: lockRoot.showMediaCard ? Theme.primary : Theme.on_surface_variant
                                }

                                Text {
                                    text: "show now playing card"
                                    font.family: Theme.fontSans
                                    font.pixelSize: Theme.fontSizeXs
                                    color: Theme.on_surface
                                    Layout.fillWidth: true
                                }

                                ToggleSwitch {
                                    checked: lockRoot.showMediaCard
                                    onToggled: {
                                        lockRoot.showMediaCard = !lockRoot.showMediaCard;
                                        lockRoot.saveSandbox();
                                    }
                                }
                            }

                            // show user session pill toggle
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 10

                                Text {
                                    text: lockRoot.showUserPill ? Theme.iconUser : Theme.iconEyeOff
                                    font.family: Theme.fontIcon
                                    font.pixelSize: Theme.fontSizeMd
                                    color: lockRoot.showUserPill ? Theme.primary : Theme.on_surface_variant
                                }

                                Text {
                                    text: "show user session badge"
                                    font.family: Theme.fontSans
                                    font.pixelSize: Theme.fontSizeXs
                                    color: Theme.on_surface
                                    Layout.fillWidth: true
                                }

                                ToggleSwitch {
                                    checked: lockRoot.showUserPill
                                    onToggled: {
                                        lockRoot.showUserPill = !lockRoot.showUserPill;
                                        lockRoot.saveSandbox();
                                    }
                                }
                            }
                        }
                    }

                    // center lock stack
                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 22
                        width: 440

                        // clock, lowercase date, and clickable lowercase quote
                        ColumnLayout {
                            Layout.alignment: Qt.AlignHCenter
                            spacing: 6

                            Text {
                                text: {
                                    let fmt = lockRoot.effectiveClock24h
                                        ? (lockRoot.effectiveShowSeconds ? "HH:mm:ss" : "HH:mm")
                                        : (lockRoot.effectiveShowSeconds ? "hh:mm:ss a" : "hh:mm a");
                                    return Qt.formatDateTime(lockRoot.currentTime, fmt).toLowerCase();
                                }
                                font.family: Theme.fontDisplay
                                font.pixelSize: Math.round(86 * Theme.fontScale * lockRoot.clockScale)
                                font.weight: Theme.fontWeightBold
                                color: Theme.on_surface
                                Layout.alignment: Qt.AlignHCenter

                                Behavior on font.pixelSize { NumberAnimation { duration: Theme.animFast; easing.type: Theme.animEasing } }
                            }

                            Text {
                                text: Qt.formatDateTime(lockRoot.currentTime, "dddd, MMMM d").toLowerCase()
                                font.family: Theme.fontSans
                                font.pixelSize: Theme.fontSizeMd
                                font.weight: Theme.fontWeightMedium
                                color: Theme.primary
                                Layout.alignment: Qt.AlignHCenter
                            }

                            // lowercase quote pill (click to cycle a new quote)
                            Rectangle {
                                visible: lockRoot.activeQuoteText !== ""
                                Layout.alignment: Qt.AlignHCenter
                                Layout.topMargin: 4
                                Layout.maximumWidth: 430
                                implicitWidth: Math.min(430, quoteTxt.implicitWidth + 24)
                                implicitHeight: quoteTxt.implicitHeight + 10
                                radius: Theme.radiusPill
                                color: quoteMouse.containsMouse
                                    ? Theme.alpha(Theme.surface_container_high, 0.55)
                                    : "transparent"

                                Behavior on color { ColorAnimation { duration: Theme.animFast } }

                                Text {
                                    id: quoteTxt
                                    anchors.centerIn: parent
                                    width: Math.min(406, implicitWidth)
                                    text: "\"" + lockRoot.activeQuoteText + "\""
                                    font.family: Theme.fontSans
                                    font.pixelSize: Theme.fontSizeXs
                                    font.italic: true
                                    color: quoteMouse.containsMouse ? Theme.on_surface : Theme.on_surface_variant
                                    horizontalAlignment: Text.AlignHCenter
                                    wrapMode: Text.WordWrap
                                }

                                MouseArea {
                                    id: quoteMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: lockRoot.refreshQuotes()
                                }
                            }
                        }

                        // mpris media player card
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 74
                            radius: Theme.radiusLg
                            color: Theme.cardBg
                            border.color: Theme.cardBorder
                            border.width: 1
                            visible: lockRoot.showMediaCard
                                && surface.activePlayer !== null
                                && ((surface.activePlayer?.trackTitle ?? "") !== "" || (surface.activePlayer?.isPlaying ?? false))

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 12

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

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2

                                    Text {
                                        text: (surface.activePlayer?.trackTitle || "no track playing").toLowerCase()
                                        font.family: Theme.fontSans
                                        font.pixelSize: Theme.fontSizeSm
                                        font.weight: Theme.fontWeightDemiBold
                                        color: Theme.on_surface
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        text: (surface.activePlayer?.trackArtist || "unknown artist").toLowerCase()
                                        font.family: Theme.fontSans
                                        font.pixelSize: Theme.fontSizeXs
                                        color: Theme.on_surface_variant
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                    }
                                }

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

                        // password entry pill
                        Rectangle {
                            id: pwContainer
                            Layout.fillWidth: true
                            Layout.preferredHeight: 48
                            radius: Theme.radiusPill
                            color: Theme.pillBg
                            border.color: lockRoot.authFailed
                                ? Theme.error
                                : (pwInput.activeFocus ? Theme.primary : Theme.pillBorder)
                            border.width: (pwInput.activeFocus || lockRoot.authFailed) ? 2 : 1

                            Behavior on border.color { ColorAnimation { duration: Theme.animFast } }

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
                                spacing: 8

                                Text {
                                    text: lockRoot.isChecking ? Theme.iconRefresh : Theme.iconLock
                                    font.family: Theme.fontIcon
                                    font.pixelSize: Theme.fontSizeMd
                                    color: lockRoot.authFailed
                                        ? Theme.error
                                        : (pwInput.activeFocus ? Theme.primary : Theme.on_surface_variant)

                                    RotationAnimator on rotation {
                                        running: lockRoot.isChecking
                                        loops: Animation.Infinite
                                        from: 0
                                        to: 360
                                        duration: 900
                                    }
                                }

                                TextInput {
                                    id: pwInput
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    verticalAlignment: TextInput.AlignVCenter
                                    text: lockRoot.sharedPassword
                                    echoMode: lockRoot.revealPassword ? TextInput.Normal : TextInput.Password
                                    font.family: Theme.fontMono
                                    font.pixelSize: Theme.fontSizeMd
                                    color: Theme.on_surface
                                    selectionColor: Theme.primary_container
                                    selectedTextColor: Theme.on_primary_container
                                    enabled: !lockRoot.isChecking
                                    passwordCharacter: "•"
                                    clip: true

                                    Text {
                                        anchors.fill: parent
                                        verticalAlignment: Text.AlignVCenter
                                        text: lockRoot.isChecking ? "verifying..." : "enter password to unlock..."
                                        font.family: Theme.fontSans
                                        font.pixelSize: Theme.fontSizeSm
                                        color: Theme.on_surface_disabled
                                        visible: pwInput.text.length === 0
                                    }

                                    onTextEdited: {
                                        lockRoot.sharedPassword = text;
                                        if (lockRoot.authFailed) lockRoot.authFailed = false;
                                    }

                                    Keys.onEscapePressed: {
                                        if (surface.optionsOpen) {
                                            surface.optionsOpen = false;
                                        } else {
                                            lockRoot.sharedPassword = "";
                                            lockRoot.authFailed = false;
                                        }
                                    }

                                    onAccepted: {
                                        const p = lockRoot.sharedPassword;
                                        lockRoot.sharedPassword = "";
                                        lockRoot.tryUnlock(p);
                                    }

                                    Component.onCompleted: forceActiveFocus()

                                    Connections {
                                        target: lockRoot
                                        function onLockedChanged() {
                                            if (lockRoot.locked) {
                                                pwInput.forceActiveFocus();
                                            }
                                        }
                                    }
                                }

                                IconButton {
                                    icon: lockRoot.revealPassword ? Theme.iconEyeOff : Theme.iconEye
                                    tooltip: lockRoot.revealPassword ? "hide password" : "show password"
                                    iconSize: Theme.fontSizeSm
                                    visible: pwInput.text.length > 0 && !lockRoot.isChecking
                                    onClicked: {
                                        lockRoot.revealPassword = !lockRoot.revealPassword;
                                        pwInput.forceActiveFocus();
                                    }
                                }

                                IconButton {
                                    icon: Theme.iconChevronRight
                                    tooltip: "unlock"
                                    iconSize: Theme.fontSizeSm
                                    visible: pwInput.text.length > 0 && !lockRoot.isChecking
                                    onClicked: {
                                        const p = lockRoot.sharedPassword;
                                        lockRoot.sharedPassword = "";
                                        lockRoot.tryUnlock(p);
                                    }
                                }
                            }
                        }

                        Text {
                            text: lockRoot.isChecking
                                ? "authenticating..."
                                : (lockRoot.authFailed ? "incorrect password, try again" : "")
                            font.family: Theme.fontSans
                            font.pixelSize: Theme.fontSizeXs
                            font.weight: Theme.fontWeightMedium
                            color: lockRoot.authFailed ? Theme.error : Theme.on_surface_disabled
                            Layout.alignment: Qt.AlignHCenter
                            visible: text !== ""
                        }
                    }

                    // bottom power dock with inline 2-step confirmation pills
                    RowLayout {
                        anchors.bottom: parent.bottom
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.margins: 36
                        spacing: 12

                        PowerPill {
                            actionId: "poweroff"
                            icon: Theme.iconPower
                            label: "shut down"
                            command: ["systemctl", "poweroff"]
                        }

                        PowerPill {
                            actionId: "reboot"
                            icon: Theme.iconReboot
                            label: "restart"
                            command: ["systemctl", "reboot"]
                        }

                        PowerPill {
                            actionId: "suspend"
                            icon: Theme.iconSuspend
                            label: "sleep"
                            command: ["systemctl", "suspend"]
                        }

                        PowerPill {
                            actionId: "logout"
                            icon: Theme.iconLogout
                            label: "log out"
                            command: ["hyprctl", "dispatch", "exit"]
                        }
                    }

                    // themed concave screen corners
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
