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
    property string barStyle: "regular" // "regular", "glass", "pure-black", "translucent", "accent-glow", "monochrome"
    property int scoopRadius: 16
    property real scoopTension: 0.55228475
    // screen corners & concave styles
    property int screenCornerRadius: 16
    property int screenBorderWidth: 2
    property bool screenFrameDocked: true
    property string screenCornerMode: "all"
    property string cornerStyle: "cubic"
    property string cornerColorMode: "theme"

    // dynamic bar module ordering
    property var barModulesLeft: ["launcher", "wallpaper", "workspaces", "windowTitle"]
    property var barModulesCenter: ["clock"]
    property var barModulesRight: ["media", "quickNotes", "clipboard", "idleInhibitor", "notifications", "systemTray", "bluetooth", "network", "volume", "battery", "quickSettings", "powerMenu"]
    property bool showBarStudio: false

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
    onScreenBorderWidthChanged: queueSave()
    onScreenFrameDockedChanged: queueSave()
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
    onShowBarStudioChanged: queueSave()
    onBarModulesLeftChanged: queueSave()
    onBarModulesCenterChanged: queueSave()
    onBarModulesRightChanged: queueSave()
    onClockFormatChanged: queueSave()
    onDateFormatChanged: queueSave()
    onShowBarDateChanged: queueSave()
    onWorkspaceCountChanged: queueSave()
    onIconSetChanged: queueSave()
    onFontFamilyChanged: queueSave()
    onFontMonoChanged: queueSave()
    onFontWindowsChanged: queueSave()
    onFontAwesomeChanged: queueSave()
    onFontScaleChanged: queueSave()
    onFontWeightChanged: queueSave()
    onMpvPanscanChanged: queueSave()
    onMpvAudioChanged: queueSave()
    onDndChanged: queueSave()
    onVibeStyleChanged: queueSave()
    onNetworkAliasesChanged: queueSave()

    readonly property var _schema: [
        { key: "barPosition", type: "string", def: "top" },
        { key: "barMargin", type: "int", def: 0 },
        { key: "barFloating", type: "bool", def: false },
        { key: "barHeight", type: "int", def: 32 },
        { key: "barStyle", type: "string", def: "regular" },
        { key: "scoopRadius", type: "int", def: 16 },
        { key: "scoopTension", type: "float", def: 0.55228475 },
        { key: "screenCornerRadius", type: "int", def: 16 },
        { key: "screenBorderWidth", type: "int", def: 2 },
        { key: "screenFrameDocked", type: "bool", def: true },
        { key: "screenCornerMode", type: "string", def: "all" },
        { key: "cornerStyle", type: "string", def: "cubic" },
        { key: "cornerColorMode", type: "string", def: "bar" },
        { key: "currentWallpaper", type: "string", def: "/home/ashley/.wallpapers/hyprland/hypr.png" },
        { key: "matugenMode", type: "string", def: "dark" },
        { key: "matugenScheme", type: "string", def: "scheme-tonal-spot" },
        { key: "awwwTransitionType", type: "string", def: "wipe" },
        { key: "awwwTransitionAngle", type: "int", def: 30 },
        { key: "awwwTransitionStep", type: "int", def: 90 },
        { key: "awwwTransitionDuration", type: "int", def: 3 },
        { key: "awwwTransitionFps", type: "int", def: 60 },
        { key: "awwwFilter", type: "string", def: "Lanczos3" },
        { key: "mpvPanscan", type: "float", def: 1.0 },
        { key: "mpvAudio", type: "bool", def: false },
        { key: "dnd", type: "bool", def: false },
        { key: "vibeStyle", type: "string", def: "nerd" },
        { key: "animSpeed", type: "string", def: "snappy" },
        { key: "unhingedFlavor", type: "bool", def: true },
        { key: "showWorkspaces", type: "bool", def: true },
        { key: "showWindowTitle", type: "bool", def: true },
        { key: "showClock", type: "bool", def: true },
        { key: "showBattery", type: "bool", def: true },
        { key: "showSystemTray", type: "bool", def: true },
        { key: "showVolume", type: "bool", def: true },
        { key: "showMedia", type: "bool", def: true },
        { key: "showNotifications", type: "bool", def: true },
        { key: "showLauncher", type: "bool", def: true },
        { key: "showPowerMenu", type: "bool", def: true },
        { key: "showNetwork", type: "bool", def: true },
        { key: "showBluetooth", type: "bool", def: true },
        { key: "showClipboard", type: "bool", def: true },
        { key: "showIdleInhibitor", type: "bool", def: true },
        { key: "showQuickSettings", type: "bool", def: true },
        { key: "showWallpaper", type: "bool", def: true },
        { key: "showQuickNotes", type: "bool", def: true },
        { key: "showMotionSandbox", type: "bool", def: false },
        { key: "showBarStudio", type: "bool", def: false },
        { key: "barModulesLeft", type: "json", def: ["launcher", "wallpaper", "workspaces", "windowTitle"] },
        { key: "barModulesCenter", type: "json", def: ["clock"] },
        { key: "barModulesRight", type: "json", def: ["media", "quickNotes", "clipboard", "idleInhibitor", "notifications", "systemTray", "bluetooth", "network", "volume", "battery", "quickSettings", "powerMenu"] },
        { key: "iconSet", type: "string", def: "material" },
        { key: "clockFormat", type: "string", def: "HH:mm" },
        { key: "dateFormat", type: "string", def: "ddd, MMM d" },
        { key: "showBarDate", type: "bool", def: false },
        { key: "workspaceCount", type: "int", def: 10 },
        { key: "fontFamily", type: "string", def: "Noto Sans" },
        { key: "fontMono", type: "string", def: "JetBrainsMono Nerd Font" },
        { key: "fontWindows", type: "string", def: "Segoe Fluent Icons" },
        { key: "fontAwesome", type: "string", def: "Font Awesome 6 Free" },
        { key: "fontScale", type: "float", def: 1.0 },
        { key: "fontWeight", type: "string", def: "regular" },
        { key: "networkAliases", type: "json", def: ({}) }
    ]

    function loadObject(data) {
        if (!data) return;
        for (let i = 0; i < _schema.length; i++) {
            let item = _schema[i];
            let v = data[item.key];
            if (v === undefined) continue;

            if (item.key === "awwwTransitionType") {
                let valid = ["wipe", "wave", "grow", "fade", "center", "outer", "simple", "left", "right", "top", "bottom", "random", "none"];
                if (valid.indexOf(v) === -1) v = "wipe";
            }

            if (item.type === "string") {
                if (root[item.key] !== v) root[item.key] = v;
            } else if (item.type === "int") {
                let n = parseInt(v);
                if (!isNaN(n) && root[item.key] !== n) root[item.key] = n;
            } else if (item.type === "float") {
                let f = parseFloat(v);
                if (!isNaN(f) && root[item.key] !== f) root[item.key] = f;
            } else if (item.type === "bool") {
                let b = (v === true || v === "true");
                if (root[item.key] !== b) root[item.key] = b;
            } else if (item.type === "json") {
                try {
                    let obj = typeof v === "string" ? JSON.parse(v) : v;
                    if (obj && (typeof obj === "object" || Array.isArray(obj))) root[item.key] = obj;
                } catch(e) {}
            }
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

    readonly property string confPath: Qt.resolvedUrl("../settings.conf").toString().replace(/^file:\/\//, "")

    property FileView confFile: FileView {
        path: root.confPath
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
        let lines = [];
        for (let i = 0; i < _schema.length; i++) {
            let item = _schema[i];
            let val = root[item.key];
            if (item.type === "string") {
                lines.push(item.key + '="' + val + '"');
            } else if (item.type === "json") {
                lines.push(item.key + "='" + JSON.stringify(val ?? item.def) + "'");
            } else {
                lines.push(item.key + "=" + val);
            }
        }
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
        Quickshell.execDetached(["rm", "-f", "/home/ashley/.config/quickshell/settings.conf", "/home/ashley/my-hyprland-dots/quickshell/settings.conf"]);
        for (let i = 0; i < _schema.length; i++) {
            let item = _schema[i];
            root[item.key] = (item.type === "json") ? (Array.isArray(item.def) ? item.def.slice() : Object.assign({}, item.def)) : item.def;
        }
        root._loading = false;
        root.save();
    }

    function moveModule(zone, fromIdx, toIdx) {
        let list = (zone === "left") ? barModulesLeft.slice() : (zone === "center") ? barModulesCenter.slice() : barModulesRight.slice();
        if (fromIdx < 0 || fromIdx >= list.length || toIdx < 0 || toIdx >= list.length) return;
        let item = list.splice(fromIdx, 1)[0];
        list.splice(toIdx, 0, item);
        if (zone === "left") barModulesLeft = list;
        else if (zone === "center") barModulesCenter = list;
        else barModulesRight = list;
        queueSave();
    }

    function transferModule(fromZone, toZone, fromIdx) {
        if (fromZone === toZone) return;
        let fromList = (fromZone === "left") ? barModulesLeft.slice() : (fromZone === "center") ? barModulesCenter.slice() : barModulesRight.slice();
        let toList = (toZone === "left") ? barModulesLeft.slice() : (toZone === "center") ? barModulesCenter.slice() : barModulesRight.slice();
        if (fromIdx < 0 || fromIdx >= fromList.length) return;
        let item = fromList.splice(fromIdx, 1)[0];
        toList.push(item);

        if (fromZone === "left") barModulesLeft = fromList;
        else if (fromZone === "center") barModulesCenter = fromList;
        else barModulesRight = fromList;

        if (toZone === "left") barModulesLeft = toList;
        else if (toZone === "center") barModulesCenter = toList;
        else barModulesRight = toList;
        queueSave();
    }

    function resetBarLayout() {
        barModulesLeft = ["launcher", "wallpaper", "workspaces", "windowTitle"];
        barModulesCenter = ["clock"];
        barModulesRight = ["media", "quickNotes", "clipboard", "idleInhibitor", "notifications", "systemTray", "bluetooth", "network", "volume", "battery", "quickSettings", "powerMenu"];
        queueSave();
    }
}
