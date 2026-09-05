pragma Singleton
import QtQuick
import ".."
import Quickshell
import Quickshell.Io

QtObject {
    id: service

    property string currentSchemeType: Settings.matugenScheme ?? "scheme-tonal-spot"
    property string currentMode: Settings.matugenMode ?? "dark"
    property string currentWallpaperPath: Settings.currentWallpaper || "/home/ashley/.wallpapers/hyprland/hypr.png"
    readonly property string scriptPath: Qt.resolvedUrl("../scripts/wallpaper.py").toString().replace(/^file:\/\//, "")

    property FileView currentWpFile: FileView {
        path: "/tmp/qs_current_wallpaper.txt"
        watchChanges: true
        printErrors: false
        onFileChanged: {
            reload();
            let p = text().trim();
            if (p !== "" && p !== service.currentWallpaperPath) {
                service.currentWallpaperPath = p;
                Settings.currentWallpaper = p;
            }
        }
    }

    function setMode(mode) {
        currentMode = mode
        Settings.matugenMode = mode
        Settings.save()
        reapplyTheme()
    }

    function setScheme(scheme) {
        currentSchemeType = scheme
        Settings.matugenScheme = scheme
        Settings.save()
        reapplyTheme()
    }

    property string targetMonitor: "all"

    signal wallpapersUpdated()

    property FileView localWpListFile: FileView {
        path: "/tmp/qs_wallpapers.json"
        watchChanges: true
        printErrors: false
        onFileChanged: {
            reload();
            service.wallpapersUpdated();
        }
    }

    function getTransitionArgs(monitor) {
        let tType = Settings.awwwTransitionType ?? "wipe";
        let tAngle = "" + (Settings.awwwTransitionAngle ?? 30);
        let tStep = "" + (Settings.awwwTransitionStep ?? 90);
        let tDur = "" + (Settings.awwwTransitionDuration ?? 3);
        let tFps = "" + (Settings.awwwTransitionFps ?? 60);
        let tFilter = Settings.awwwFilter ?? "Lanczos3";
        let mode = currentMode ?? "dark";
        let scheme = currentSchemeType ?? "scheme-tonal-spot";
        let mon = monitor || targetMonitor || "all";
        let panscan = "" + (Settings.mpvPanscan ?? 1.0);
        let audio = Settings.mpvAudio ? "true" : "false";
        return [tType, tAngle, tStep, tDur, tFps, tFilter, mode, scheme, mon, panscan, audio];
    }

    function scanLocalWallpapers() {
        Quickshell.execDetached(["python3", scriptPath, "scan"])
    }

    function applyLocalWallpaper(filePath, monitor) {
        currentWallpaperPath = filePath
        Settings.currentWallpaper = filePath
        Quickshell.execDetached(["python3", scriptPath, "set", filePath, ...getTransitionArgs(monitor)])
    }

    function applyRandomWallpaper(category, monitor) {
        let cat = category ?? "all"
        Quickshell.execDetached(["python3", scriptPath, "random", cat, ...getTransitionArgs(monitor)])
    }

    function setWallpaper(url, monitor) {
        Quickshell.execDetached(["python3", scriptPath, "download", url, ...getTransitionArgs(monitor)])
    }

    function batchDownload(urls) {
        if (!urls || urls.length === 0) return
        Quickshell.execDetached(["python3", scriptPath, "batch-download", JSON.stringify(urls)])
    }

    function applyColor(hex) {
        let mode = currentMode ?? "dark"
        let scheme = currentSchemeType ?? "scheme-tonal-spot"
        Quickshell.execDetached(["python3", scriptPath, "color", hex, mode, scheme])
    }

    function reapplyTheme() {
        let mode = currentMode ?? "dark"
        let scheme = currentSchemeType ?? "scheme-tonal-spot"
        Quickshell.execDetached(["python3", scriptPath, "reapply", mode, scheme])
    }

    Component.onCompleted: {
        scanLocalWallpapers()
    }
}
