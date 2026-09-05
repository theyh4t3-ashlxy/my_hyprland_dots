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
    readonly property string scriptsDir: "/home/ashley/.config/quickshell/scripts"
    readonly property string scriptPath: scriptsDir + "/wallpaper.sh"

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

    function _buildCommonArgs(monitor) {
        return [
            Settings.awwwTransitionType ?? "wipe",
            "" + (Settings.awwwTransitionAngle ?? 30),
            "" + (Settings.awwwTransitionStep ?? 90),
            "" + (Settings.awwwTransitionDuration ?? 3),
            "" + (Settings.awwwTransitionFps ?? 60),
            Settings.awwwFilter ?? "Lanczos3",
            currentMode ?? "dark",
            currentSchemeType ?? "scheme-tonal-spot",
            monitor || targetMonitor || "all",
            "" + (Settings.mpvPanscan ?? 1.0),
            Settings.mpvAudio ? "true" : "false"
        ]
    }

    function applyLocalWallpaper(filePath, monitor) {
        currentWallpaperPath = filePath
        Settings.currentWallpaper = filePath
        Quickshell.execDetached([scriptPath, "set", filePath].concat(_buildCommonArgs(monitor)))
    }

    function applyRandomWallpaper(category, monitor) {
        let cat = category ?? "all"
        Quickshell.execDetached([scriptPath, "random", cat].concat(_buildCommonArgs(monitor)))
    }

    function setWallpaper(url, monitor) {
        Quickshell.execDetached([scriptPath, "download", url].concat(_buildCommonArgs(monitor)))
    }

    function applyColor(hex) {
        let mode = currentMode ?? "dark"
        let scheme = currentSchemeType ?? "scheme-tonal-spot"
        Quickshell.execDetached([scriptPath, "color", hex, mode, scheme])
    }

    function reapplyTheme() {
        let wp = currentWallpaperPath || Settings.currentWallpaper || "/home/ashley/.wallpapers/hyprland/hypr.png"
        applyLocalWallpaper(wp)
    }

    Component.onCompleted: {
        scanLocalWallpapers()
    }
}
