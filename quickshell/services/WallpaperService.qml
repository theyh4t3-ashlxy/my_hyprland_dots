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
    readonly property string scriptPath: "/home/ashley/.config/quickshell/scripts/wallpaper.sh"

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

    function scanLocalWallpapers() {
        Quickshell.execDetached([scriptPath, "scan"])
    }

    function applyLocalWallpaper(filePath, monitor) {
        currentWallpaperPath = filePath
        Settings.currentWallpaper = filePath
        let tType = Settings.awwwTransitionType ?? "wipe"
        let tAngle = "" + (Settings.awwwTransitionAngle ?? 30)
        let tStep = "" + (Settings.awwwTransitionStep ?? 90)
        let tDur = "" + (Settings.awwwTransitionDuration ?? 3)
        let tFps = "" + (Settings.awwwTransitionFps ?? 60)
        let tFilter = Settings.awwwFilter ?? "Lanczos3"
        let mode = currentMode ?? "dark"
        let scheme = currentSchemeType ?? "scheme-tonal-spot"
        let mon = monitor || targetMonitor || "all"
        let panscan = "" + (Settings.mpvPanscan ?? 1.0)
        let audio = Settings.mpvAudio ? "true" : "false"

        Quickshell.execDetached([scriptPath, "set", filePath, tType, tAngle, tStep, tDur, tFps, tFilter, mode, scheme, mon, panscan, audio])
    }

    function applyRandomWallpaper(category, monitor) {
        let cat = category ?? "all"
        let tType = Settings.awwwTransitionType ?? "wipe"
        let tAngle = "" + (Settings.awwwTransitionAngle ?? 30)
        let tStep = "" + (Settings.awwwTransitionStep ?? 90)
        let tDur = "" + (Settings.awwwTransitionDuration ?? 3)
        let tFps = "" + (Settings.awwwTransitionFps ?? 60)
        let tFilter = Settings.awwwFilter ?? "Lanczos3"
        let mode = currentMode ?? "dark"
        let scheme = currentSchemeType ?? "scheme-tonal-spot"
        let mon = monitor || targetMonitor || "all"
        let panscan = "" + (Settings.mpvPanscan ?? 1.0)
        let audio = Settings.mpvAudio ? "true" : "false"

        Quickshell.execDetached([scriptPath, "random", cat, tType, tAngle, tStep, tDur, tFps, tFilter, mode, scheme, mon, panscan, audio])
    }

    function setWallpaper(url, monitor) {
        let tType = Settings.awwwTransitionType ?? "wipe"
        let tAngle = "" + (Settings.awwwTransitionAngle ?? 30)
        let tStep = "" + (Settings.awwwTransitionStep ?? 90)
        let tDur = "" + (Settings.awwwTransitionDuration ?? 3)
        let tFps = "" + (Settings.awwwTransitionFps ?? 60)
        let tFilter = Settings.awwwFilter ?? "Lanczos3"
        let mode = currentMode ?? "dark"
        let scheme = currentSchemeType ?? "scheme-tonal-spot"
        let mon = monitor || targetMonitor || "all"
        let panscan = "" + (Settings.mpvPanscan ?? 1.0)
        let audio = Settings.mpvAudio ? "true" : "false"

        Quickshell.execDetached([scriptPath, "download", url, tType, tAngle, tStep, tDur, tFps, tFilter, mode, scheme, mon, panscan, audio])
    }

    function applyColor(hex) {
        let mode = currentMode ?? "dark"
        let scheme = currentSchemeType ?? "scheme-tonal-spot"
        Quickshell.execDetached([scriptPath, "color", hex, mode, scheme])
    }

    function reapplyTheme() {
        let mode = currentMode ?? "dark"
        let scheme = currentSchemeType ?? "scheme-tonal-spot"
        Quickshell.execDetached([scriptPath, "reapply", mode, scheme])
    }

    Component.onCompleted: {
        scanLocalWallpapers()
    }
}
