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
    property string barStyle: "glass" // "glass", "pure-black", "translucent", "accent-glow", "monochrome"
    property int scoopRadius: 16
    property real scoopTension: 0.55228475
    // screen corners & concave styles
    property int screenCornerRadius: 16
    property string screenCornerMode: "all"
    property string cornerStyle: "cubic"
    property string cornerColorMode: "bar"

    // matugen & awww engine
    property string currentWallpaper: "/home/ashley/.wallpapers/hyprland/hypr.png"
    property string matugenMode: "dark"
    property string matugenScheme: "scheme-tonal-spot"
    property string awwwTransitionType: "wipe"
    property int awwwTransitionAngle: 30
    property int awwwTransitionStep: 90
    property int awwwTransitionDuration: 3
    property int awwwTransitionFps: 60
    property string awwwFilter: "Lanczos3"
    property real mpvPanscan: 1.0
    property bool mpvAudio: false

    // anim & chaos vibe
    property string animSpeed: "snappy"
    property bool unhingedFlavor: true
    property string vibeStyle: "nerd" // "kaomoji", "nerd", "text"
    property bool dnd: false // do not disturb: silence toast popups

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
    property bool showQuickNotes: true
    property bool showMotionSandbox: false

    // formatting & typography
    property string clockFormat: "HH:mm"
    property string dateFormat: "ddd, MMM d"
    property bool showBarDate: false
    property int workspaceCount: 10
    property string iconSet: "material" // "material", "windows", "awesome"
    property string fontFamily: "Noto Sans"
    property string fontMono: "JetBrainsMono Nerd Font"
    property string fontWindows: "Segoe Fluent Icons"
    property string fontAwesome: "Font Awesome 6 Free"
    property real fontScale: 1.0
    property string fontWeight: "regular"
    property var networkAliases: ({})

    property bool _initialized: false
    property bool _loading: false

    property Timer autoSaveTimer: Timer {
        interval: 80
        repeat: false
        onTriggered: {
            if (root._initialized && !root._loading) {
                root.save();
            }
        }
    }

    function queueSave() {
        if (root._initialized && !root._loading) {
            autoSaveTimer.restart();
        }
    }

    onBarPositionChanged: queueSave()
    onBarMarginChanged: queueSave()
    onBarFloatingChanged: queueSave()
    onBarHeightChanged: queueSave()
    onBarStyleChanged: queueSave()
    onScoopRadiusChanged: queueSave()
    onScoopTensionChanged: queueSave()
    onScreenCornerRadiusChanged: queueSave()
    onScreenCornerModeChanged: queueSave()
    onCornerStyleChanged: queueSave()
    onCornerColorModeChanged: queueSave()
    onMatugenModeChanged: queueSave()
    onMatugenSchemeChanged: queueSave()
    onAwwwTransitionTypeChanged: queueSave()
    onAwwwTransitionAngleChanged: queueSave()
    onAwwwTransitionStepChanged: queueSave()
    onAwwwTransitionDurationChanged: queueSave()
    onAwwwTransitionFpsChanged: queueSave()
    onAwwwFilterChanged: queueSave()
    onAnimSpeedChanged: queueSave()
    onUnhingedFlavorChanged: queueSave()
    onCurrentWallpaperChanged: queueSave()
    onShowWorkspacesChanged: queueSave()
    onShowWindowTitleChanged: queueSave()
    onShowClockChanged: queueSave()
    onShowBatteryChanged: queueSave()
    onShowSystemTrayChanged: queueSave()
    onShowVolumeChanged: queueSave()
    onShowMediaChanged: queueSave()
    onShowNotificationsChanged: queueSave()
    onShowLauncherChanged: queueSave()
    onShowPowerMenuChanged: queueSave()
    onShowNetworkChanged: queueSave()
    onShowBluetoothChanged: queueSave()
    onShowClipboardChanged: queueSave()
    onShowIdleInhibitorChanged: queueSave()
    onShowQuickSettingsChanged: queueSave()
    onShowWallpaperChanged: queueSave()
    onShowQuickNotesChanged: queueSave()
    onShowMotionSandboxChanged: queueSave()
    onClockFormatChanged: queueSave()
    onDateFormatChanged: queueSave()
    onShowBarDateChanged: queueSave()
    onWorkspaceCountChanged: queueSave()
    onIconSetChanged: queueSave()
    onFontFamilyChanged: queueSave()
    onFontMonoChanged: queueSave()
    onFontScaleChanged: queueSave()
    onFontWeightChanged: queueSave()
    onMpvPanscanChanged: queueSave()
    onMpvAudioChanged: queueSave()
    onDndChanged: queueSave()
    onVibeStyleChanged: queueSave()
    onNetworkAliasesChanged: queueSave()

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
        if (data.currentWallpaper !== undefined && root.currentWallpaper !== data.currentWallpaper) root.currentWallpaper = data.currentWallpaper;
        if (data.matugenMode !== undefined && root.matugenMode !== data.matugenMode) root.matugenMode = data.matugenMode;
        if (data.matugenScheme !== undefined && root.matugenScheme !== data.matugenScheme) root.matugenScheme = data.matugenScheme;
        if (data.awwwTransitionType !== undefined) {
            let valid = ["wipe", "wave", "grow", "fade", "center", "outer", "simple", "left", "right", "top", "bottom", "random", "none"];
            let t = (valid.indexOf(data.awwwTransitionType) !== -1) ? data.awwwTransitionType : "wipe";
            if (root.awwwTransitionType !== t) root.awwwTransitionType = t;
        }
        if (data.awwwTransitionAngle !== undefined && root.awwwTransitionAngle !== parseInt(data.awwwTransitionAngle)) root.awwwTransitionAngle = parseInt(data.awwwTransitionAngle);
        if (data.awwwTransitionStep !== undefined && root.awwwTransitionStep !== parseInt(data.awwwTransitionStep)) root.awwwTransitionStep = parseInt(data.awwwTransitionStep);
        if (data.awwwTransitionDuration !== undefined && root.awwwTransitionDuration !== parseInt(data.awwwTransitionDuration)) root.awwwTransitionDuration = parseInt(data.awwwTransitionDuration);
        if (data.awwwTransitionFps !== undefined && root.awwwTransitionFps !== parseInt(data.awwwTransitionFps)) root.awwwTransitionFps = parseInt(data.awwwTransitionFps);
        if (data.awwwFilter !== undefined && root.awwwFilter !== data.awwwFilter) root.awwwFilter = data.awwwFilter;
        if (data.mpvPanscan !== undefined && root.mpvPanscan !== parseFloat(data.mpvPanscan)) root.mpvPanscan = parseFloat(data.mpvPanscan);
        if (data.mpvAudio !== undefined) root.mpvAudio = (data.mpvAudio === true || data.mpvAudio === "true");
        if (data.dnd !== undefined) root.dnd = (data.dnd === true || data.dnd === "true");
        if (data.vibeStyle !== undefined && root.vibeStyle !== data.vibeStyle) root.vibeStyle = data.vibeStyle;
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
        if (data.showQuickNotes !== undefined) root.showQuickNotes = (data.showQuickNotes === true || data.showQuickNotes === "true");
        if (data.barStyle !== undefined && root.barStyle !== data.barStyle) root.barStyle = data.barStyle;
        if (data.showMotionSandbox !== undefined) root.showMotionSandbox = (data.showMotionSandbox === true || data.showMotionSandbox === "true");
        if (data.iconSet !== undefined && root.iconSet !== data.iconSet) root.iconSet = data.iconSet;
        if (data.clockFormat !== undefined && root.clockFormat !== data.clockFormat) root.clockFormat = data.clockFormat;
        if (data.dateFormat !== undefined && root.dateFormat !== data.dateFormat) root.dateFormat = data.dateFormat;
        if (data.showBarDate !== undefined) root.showBarDate = (data.showBarDate === true || data.showBarDate === "true");
        if (data.workspaceCount !== undefined && root.workspaceCount !== parseInt(data.workspaceCount)) root.workspaceCount = parseInt(data.workspaceCount);
        if (data.fontFamily !== undefined && root.fontFamily !== data.fontFamily) root.fontFamily = data.fontFamily;
        if (data.fontMono !== undefined && root.fontMono !== data.fontMono) root.fontMono = data.fontMono;
        if (data.fontWindows !== undefined && root.fontWindows !== data.fontWindows) root.fontWindows = data.fontWindows;
        if (data.fontAwesome !== undefined && root.fontAwesome !== data.fontAwesome) root.fontAwesome = data.fontAwesome;
        if (data.fontScale !== undefined && root.fontScale !== parseFloat(data.fontScale)) root.fontScale = parseFloat(data.fontScale);
        if (data.fontWeight !== undefined && root.fontWeight !== data.fontWeight) root.fontWeight = data.fontWeight;
        if (data.networkAliases !== undefined) {
            try {
                let parsed = typeof data.networkAliases === "string" ? JSON.parse(data.networkAliases) : data.networkAliases;
                if (parsed && typeof parsed === "object") {
                    root.networkAliases = parsed;
                }
            } catch(e) {}
        }
    }

    function getNetworkAlias(ssid) {
        if (!ssid) return "";
        if (root.networkAliases && root.networkAliases[ssid]) {
            return root.networkAliases[ssid];
        }
        return ssid;
    }

    function setNetworkAlias(ssid, alias) {
        if (!ssid) return;
        let next = Object.assign({}, root.networkAliases);
        let trimmed = alias ? alias.trim() : "";
        if (!trimmed || trimmed === ssid) {
            delete next[ssid];
        } else {
            next[ssid] = trimmed;
        }
        root.networkAliases = next;
        queueSave();
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
                if ((val.startsWith('"') && val.endsWith('"')) || (val.startsWith("'") && val.endsWith("'"))) {
                    val = val.substring(1, val.length - 1);
                }
                data[key] = val;
            }
        }
        root._loading = true;
        loadObject(data);
        root._loading = false;
        root._initialized = true;
    }


    property bool _isSaving: false

    property Timer resetSavingTimer: Timer {
        interval: 400
        repeat: false
        onTriggered: {
            root._isSaving = false;
        }
    }

    property FileView confFile: FileView {
        path: "/home/ashley/.config/quickshell/settings.conf"
        watchChanges: true
        printErrors: false
        onLoaded: root.loadFromFile()
        onFileChanged: {
            if (!root._isSaving) {
                confFile.reload();
            }
        }
    }

    Component.onCompleted: {
        root.loadFromFile();
    }

    function loadFromFile() {
        let str = confFile.text();
        if (str && str.trim() !== "") {
            root.loadConf(str);
        }
    }

    function toConf() {
        let lines = [
            'barPosition="' + barPosition + '"',
            "barMargin=" + barMargin,
            "barFloating=" + barFloating,
            "barHeight=" + barHeight,
            'barStyle="' + barStyle + '"',
            "scoopRadius=" + scoopRadius,
            "scoopTension=" + scoopTension,
            "screenCornerRadius=" + screenCornerRadius,
            'screenCornerMode="' + screenCornerMode + '"',
            'cornerStyle="' + cornerStyle + '"',
            'cornerColorMode="' + cornerColorMode + '"',
            'currentWallpaper="' + currentWallpaper + '"',
            'matugenMode="' + matugenMode + '"',
            'matugenScheme="' + matugenScheme + '"',
            'awwwTransitionType="' + awwwTransitionType + '"',
            "awwwTransitionAngle=" + awwwTransitionAngle,
            "awwwTransitionStep=" + awwwTransitionStep,
            "awwwTransitionDuration=" + awwwTransitionDuration,
            "awwwTransitionFps=" + awwwTransitionFps,
            'awwwFilter="' + awwwFilter + '"',
            "mpvPanscan=" + mpvPanscan,
            "mpvAudio=" + mpvAudio,
            "dnd=" + dnd,
            'vibeStyle="' + vibeStyle + '"',
            'animSpeed="' + animSpeed + '"',
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
            "showQuickNotes=" + showQuickNotes,
            "showMotionSandbox=" + showMotionSandbox,
            'iconSet="' + iconSet + '"',
            'clockFormat="' + clockFormat + '"',
            'dateFormat="' + dateFormat + '"',
            "showBarDate=" + showBarDate,
            "workspaceCount=" + workspaceCount,
            'fontFamily="' + fontFamily + '"',
            'fontMono="' + fontMono + '"',
            'fontWindows="' + fontWindows + '"',
            'fontAwesome="' + fontAwesome + '"',
            "fontScale=" + fontScale,
            'fontWeight="' + fontWeight + '"',
            'networkAliases=\'' + JSON.stringify(root.networkAliases || {}) + '\''
        ];
        return lines.join("\n");
    }

    function save() {
        root._isSaving = true;
        let confStr = toConf();
        confFile.setText(confStr);
        resetSavingTimer.restart();
    }

    // nuke everything and go back to factory stock
    function resetToDefaults() {
        root._loading = true;
        root.barPosition = "top";
        root.barMargin = 0;
        root.barFloating = false;
        root.barHeight = 32;
        root.barStyle = "glass";
        root.scoopRadius = 16;
        root.scoopTension = 0.55228475;
        root.screenCornerRadius = 16;
        root.screenCornerMode = "all";
        root.cornerStyle = "cubic";
        root.cornerColorMode = "bar";
        root.currentWallpaper = "/home/ashley/.wallpapers/hyprland/hypr.png";
        root.matugenMode = "dark";
        root.matugenScheme = "scheme-tonal-spot";
        root.awwwTransitionType = "wipe";
        root.awwwTransitionAngle = 30;
        root.awwwTransitionStep = 90;
        root.awwwTransitionDuration = 3;
        root.awwwTransitionFps = 60;
        root.awwwFilter = "Lanczos3";
        root.mpvPanscan = 1.0;
        root.mpvAudio = false;
        root.dnd = false;
        root.animSpeed = "snappy";
        root.unhingedFlavor = true;
        root.vibeStyle = "nerd";
        root.showWorkspaces = true;
        root.showWindowTitle = true;
        root.showClock = true;
        root.showBattery = true;
        root.showSystemTray = true;
        root.showVolume = true;
        root.showMedia = true;
        root.showNotifications = true;
        root.showLauncher = true;
        root.showPowerMenu = true;
        root.showNetwork = true;
        root.showBluetooth = true;
        root.showClipboard = true;
        root.showIdleInhibitor = true;
        root.showQuickSettings = true;
        root.showWallpaper = true;
        root.showQuickNotes = true;
        root.showMotionSandbox = false;
        root.clockFormat = "HH:mm";
        root.dateFormat = "ddd, MMM d";
        root.showBarDate = false;
        root.workspaceCount = 10;
        root.iconSet = "material";
        root.fontFamily = "Noto Sans";
        root.fontMono = "JetBrainsMono Nerd Font";
        root.fontWindows = "Segoe Fluent Icons";
        root.fontAwesome = "Font Awesome 6 Free";
        root.fontScale = 1.0;
        root.fontWeight = "regular";
        root.networkAliases = ({});
        root._loading = false;
        root.save();
    }
}
