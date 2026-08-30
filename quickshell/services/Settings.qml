pragma Singleton
import QtQuick
import ".."
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    // bar vibes
    property string barPosition: "top"
    property int barMargin: 0
    property bool barFloating: false
    property int barHeight: 32
    property int scoopRadius: 16
    property real scoopTension: 0.55228475
    // screen corners & concave styles
    property int screenCornerRadius: 16
    property string screenCornerMode: "all"
    property string cornerStyle: "cubic"
    property string cornerColorMode: "theme"

    // matugen & awww engine
    property string matugenMode: "dark"
    property string matugenScheme: "scheme-tonal-spot"
    property string awwwTransitionType: "wipe"
    property int awwwTransitionAngle: 30
    property int awwwTransitionStep: 90
    property int awwwTransitionDuration: 3
    property int awwwTransitionFps: 60
    property string awwwFilter: "Lanczos3"

    // anim & chaos vibe
    property string animSpeed: "snappy"
    property bool unhingedFlavor: true

    // visibility toggles
    property bool showWorkspaces: true
    property bool showWindowTitle: true
    property bool showClock: true
    property bool showBattery: true
    property bool showSystemTray: true
    property bool showVolume: true
    property bool showMedia: true
    property bool showNotifications: true
    property bool showLauncher: true
    property bool showPowerMenu: true
    property bool showNetwork: true
    property bool showBluetooth: true
    property bool showClipboard: true
    property bool showIdleInhibitor: true
    property bool showQuickSettings: true
    property bool showWallpaper: true

    // formatting & typography
    property string clockFormat: "HH:mm"
    property string dateFormat: "ddd, MMM d"
    property int workspaceCount: 10
    property string fontFamily: "Noto Sans"
    property string fontMono: "JetBrainsMono Nerd Font"
    property real fontScale: 1.0
    property string fontWeight: "regular"

    readonly property string saveScriptPath: "/home/ashley/.config/quickshell/scripts/save_settings.py"

    function loadObject(data) {
        if (!data) return;
        if (data.barPosition !== undefined && root.barPosition !== data.barPosition) root.barPosition = data.barPosition;
        if (data.barMargin !== undefined && root.barMargin !== parseInt(data.barMargin)) root.barMargin = parseInt(data.barMargin);
        if (data.barFloating !== undefined) root.barFloating = (data.barFloating === true || data.barFloating === "true");
        if (data.barHeight !== undefined && root.barHeight !== parseInt(data.barHeight)) root.barHeight = parseInt(data.barHeight);
        if (data.scoopRadius !== undefined && root.scoopRadius !== parseInt(data.scoopRadius)) root.scoopRadius = parseInt(data.scoopRadius);
        if (data.scoopTension !== undefined && root.scoopTension !== parseFloat(data.scoopTension)) root.scoopTension = parseFloat(data.scoopTension);
        if (data.screenCornerRadius !== undefined && root.screenCornerRadius !== parseInt(data.screenCornerRadius)) root.screenCornerRadius = parseInt(data.screenCornerRadius);
        if (data.screenCornerMode !== undefined && root.screenCornerMode !== data.screenCornerMode) root.screenCornerMode = data.screenCornerMode;
        if (data.cornerStyle !== undefined && root.cornerStyle !== data.cornerStyle) root.cornerStyle = data.cornerStyle;
        if (data.cornerColorMode !== undefined && root.cornerColorMode !== data.cornerColorMode) root.cornerColorMode = data.cornerColorMode;
        if (data.matugenMode !== undefined && root.matugenMode !== data.matugenMode) root.matugenMode = data.matugenMode;
        if (data.matugenScheme !== undefined && root.matugenScheme !== data.matugenScheme) root.matugenScheme = data.matugenScheme;
        if (data.awwwTransitionType !== undefined && root.awwwTransitionType !== data.awwwTransitionType) root.awwwTransitionType = data.awwwTransitionType;
        if (data.awwwTransitionAngle !== undefined && root.awwwTransitionAngle !== parseInt(data.awwwTransitionAngle)) root.awwwTransitionAngle = parseInt(data.awwwTransitionAngle);
        if (data.awwwTransitionStep !== undefined && root.awwwTransitionStep !== parseInt(data.awwwTransitionStep)) root.awwwTransitionStep = parseInt(data.awwwTransitionStep);
        if (data.awwwTransitionDuration !== undefined && root.awwwTransitionDuration !== parseInt(data.awwwTransitionDuration)) root.awwwTransitionDuration = parseInt(data.awwwTransitionDuration);
        if (data.awwwTransitionFps !== undefined && root.awwwTransitionFps !== parseInt(data.awwwTransitionFps)) root.awwwTransitionFps = parseInt(data.awwwTransitionFps);
        if (data.awwwFilter !== undefined && root.awwwFilter !== data.awwwFilter) root.awwwFilter = data.awwwFilter;
        if (data.animSpeed !== undefined && root.animSpeed !== data.animSpeed) root.animSpeed = data.animSpeed;
        if (data.unhingedFlavor !== undefined) root.unhingedFlavor = (data.unhingedFlavor === true || data.unhingedFlavor === "true");
        if (data.showWorkspaces !== undefined) root.showWorkspaces = (data.showWorkspaces === true || data.showWorkspaces === "true");
        if (data.showWindowTitle !== undefined) root.showWindowTitle = (data.showWindowTitle === true || data.showWindowTitle === "true");
        if (data.showClock !== undefined) root.showClock = (data.showClock === true || data.showClock === "true");
        if (data.showBattery !== undefined) root.showBattery = (data.showBattery === true || data.showBattery === "true");
        if (data.showSystemTray !== undefined) root.showSystemTray = (data.showSystemTray === true || data.showSystemTray === "true");
        if (data.showVolume !== undefined) root.showVolume = (data.showVolume === true || data.showVolume === "true");
        if (data.showMedia !== undefined) root.showMedia = (data.showMedia === true || data.showMedia === "true");
        if (data.showNotifications !== undefined) root.showNotifications = (data.showNotifications === true || data.showNotifications === "true");
        if (data.showLauncher !== undefined) root.showLauncher = (data.showLauncher === true || data.showLauncher === "true");
        if (data.showPowerMenu !== undefined) root.showPowerMenu = (data.showPowerMenu === true || data.showPowerMenu === "true");
        if (data.showNetwork !== undefined) root.showNetwork = (data.showNetwork === true || data.showNetwork === "true");
        if (data.showBluetooth !== undefined) root.showBluetooth = (data.showBluetooth === true || data.showBluetooth === "true");
        if (data.showClipboard !== undefined) root.showClipboard = (data.showClipboard === true || data.showClipboard === "true");
        if (data.showIdleInhibitor !== undefined) root.showIdleInhibitor = (data.showIdleInhibitor === true || data.showIdleInhibitor === "true");
        if (data.showQuickSettings !== undefined) root.showQuickSettings = (data.showQuickSettings === true || data.showQuickSettings === "true");
        if (data.showWallpaper !== undefined) root.showWallpaper = (data.showWallpaper === true || data.showWallpaper === "true");
        if (data.clockFormat !== undefined && root.clockFormat !== data.clockFormat) root.clockFormat = data.clockFormat;
        if (data.dateFormat !== undefined && root.dateFormat !== data.dateFormat) root.dateFormat = data.dateFormat;
        if (data.workspaceCount !== undefined && root.workspaceCount !== parseInt(data.workspaceCount)) root.workspaceCount = parseInt(data.workspaceCount);
        if (data.fontFamily !== undefined && root.fontFamily !== data.fontFamily) root.fontFamily = data.fontFamily;
        if (data.fontMono !== undefined && root.fontMono !== data.fontMono) root.fontMono = data.fontMono;
        if (data.fontScale !== undefined && root.fontScale !== parseFloat(data.fontScale)) root.fontScale = parseFloat(data.fontScale);
        if (data.fontWeight !== undefined && root.fontWeight !== data.fontWeight) root.fontWeight = data.fontWeight;
    }

    function loadConf(str) {
        let lines = str.split("\n");
        let data = {};
        for (let i = 0; i < lines.length; i++) {
            let line = lines[i].trim();
            if (line === "" || line.startsWith("#")) continue;
            let eqIdx = line.indexOf("=");
            if (eqIdx !== -1) {
                let key = line.substring(0, eqIdx).trim();
                let val = line.substring(eqIdx + 1).trim();
                data[key] = val;
            }
        }
        loadObject(data);
    }

    // nuke the stale cache or every save reverts itself
    property FileView confFile: FileView {
        path: "/home/ashley/.config/quickshell/settings.conf"
        watchChanges: true
        printErrors: false
        onFileChanged: {
            reload();
            let str = text();
            if (!str || str.trim() === "") return;
            root.loadConf(str);
        }
    }

    Component.onCompleted: {
        confFile.reload();
        let str = confFile.text();
        if (str && str.trim() !== "") loadConf(str);
    }

    function toConf() {
        let lines = [
            "barPosition=" + barPosition,
            "barMargin=" + barMargin,
            "barFloating=" + barFloating,
            "barHeight=" + barHeight,
            "scoopRadius=" + scoopRadius,
            "scoopTension=" + scoopTension,
            "screenCornerRadius=" + screenCornerRadius,
            "screenCornerMode=" + screenCornerMode,
            "cornerStyle=" + cornerStyle,
            "cornerColorMode=" + cornerColorMode,
            "matugenMode=" + matugenMode,
            "matugenScheme=" + matugenScheme,
            "awwwTransitionType=" + awwwTransitionType,
            "awwwTransitionAngle=" + awwwTransitionAngle,
            "awwwTransitionStep=" + awwwTransitionStep,
            "awwwTransitionDuration=" + awwwTransitionDuration,
            "awwwTransitionFps=" + awwwTransitionFps,
            "awwwFilter=" + awwwFilter,
            "animSpeed=" + animSpeed,
            "unhingedFlavor=" + unhingedFlavor,
            "showWorkspaces=" + showWorkspaces,
            "showWindowTitle=" + showWindowTitle,
            "showClock=" + showClock,
            "showBattery=" + showBattery,
            "showSystemTray=" + showSystemTray,
            "showVolume=" + showVolume,
            "showMedia=" + showMedia,
            "showNotifications=" + showNotifications,
            "showLauncher=" + showLauncher,
            "showPowerMenu=" + showPowerMenu,
            "showNetwork=" + showNetwork,
            "showBluetooth=" + showBluetooth,
            "showClipboard=" + showClipboard,
            "showIdleInhibitor=" + showIdleInhibitor,
            "showQuickSettings=" + showQuickSettings,
            "showWallpaper=" + showWallpaper,
            "clockFormat=" + clockFormat,
            "dateFormat=" + dateFormat,
            "workspaceCount=" + workspaceCount,
            "fontFamily=" + fontFamily,
            "fontMono=" + fontMono,
            "fontScale=" + fontScale,
            "fontWeight=" + fontWeight
        ];
        return lines.join("\n");
    }

    function save() {
        let confStr = toConf();
        Quickshell.execDetached([saveScriptPath, confStr]);
    }
}
