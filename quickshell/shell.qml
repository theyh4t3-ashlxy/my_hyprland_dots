//@ pragma UseQApplication
import Quickshell
import Quickshell.Io
import "widgets"

ShellRoot {
    Variants {
        model: Quickshell.screens
        StatusBar {}
    }

    Variants {
        model: Quickshell.screens
        ScreenCorners {}
    }

    Variants {
        model: Quickshell.screens
        NotificationToasts {}
    }

    Variants {
        model: Quickshell.screens
        BarStudio {}
    }

    Variants {
        model: Quickshell.screens
        MotionSandbox {
            open: Settings.showMotionSandbox
        }
    }

    Variants {
        model: Quickshell.screens
        OSD {}
    }

    LockScreen {
        id: globalLockScreen
    }

    // Notifications IPC
    IpcHandler {
        target: "notifs"
        function toggle(): void { NotificationService.toggle(); }
        function open(): void { NotificationService.open(); }
        function close(): void { NotificationService.close(); }
        function clear(): void { NotificationService.clearAll(); }
        function dnd(): void { Settings.dnd = !Settings.dnd; }
    }

    IpcHandler {
        target: "notifications"
        function toggle(): void { NotificationService.toggle(); }
        function open(): void { NotificationService.open(); }
        function close(): void { NotificationService.close(); }
        function clear(): void { NotificationService.clearAll(); }
        function dnd(): void { Settings.dnd = !Settings.dnd; }
    }

    // BarStudio IPC
    IpcHandler {
        target: "studio"
        function toggle(): void { Settings.showBarStudio = !Settings.showBarStudio; }
        function open(): void { Settings.showBarStudio = true; }
        function close(): void { Settings.showBarStudio = false; }
    }

    // Motion Sandbox IPC
    IpcHandler {
        target: "sandbox"
        function toggle(): void { Settings.showMotionSandbox = !Settings.showMotionSandbox; }
        function open(): void { Settings.showMotionSandbox = true; }
        function close(): void { Settings.showMotionSandbox = false; }
    }

    // Launcher IPC
    IpcHandler {
        target: "launcher"
        function toggle(): void { Settings.requestLauncherToggle(); }
        function open(): void { Settings.requestLauncherOpen(); }
        function close(): void { Settings.requestLauncherClose(); }
    }

    // Screenshot IPC
    Variants {
        model: Quickshell.screens
        ScreenshotOverlay {}
    }

    IpcHandler {
        target: "screenshot"
        function open(): void { ScreenshotService.open("region"); }
        function close(): void { ScreenshotService.close(); }
        function toggle(): void { ScreenshotService.toggle("region"); }
        function full(): void { ScreenshotService.captureFullscreen(Quickshell.screens[0], "both"); }
        function window(): void { ScreenshotService.open("window"); }
    }

    // Quick Settings IPC
    IpcHandler {
        target: "quicksettings"
        function toggle(): void { Settings.requestQuickSettingsToggle(); }
        function open(): void { Settings.requestQuickSettingsOpen(); }
        function close(): void { Settings.requestQuickSettingsClose(); }
    }

    IpcHandler {
        target: "settings"
        function toggle(): void { Settings.requestQuickSettingsToggle(); }
        function open(): void { Settings.requestQuickSettingsOpen(); }
        function close(): void { Settings.requestQuickSettingsClose(); }
    }

    // Battery IPC
    IpcHandler {
        target: "battery"
        function toggle(): void { Settings.requestBatteryToggle(); }
        function open(): void { Settings.requestBatteryOpen(); }
        function close(): void { Settings.requestBatteryClose(); }
    }

    // Window Title IPC
    IpcHandler {
        target: "window"
        function toggle(): void { Settings.requestWindowTitleToggle(); }
        function open(): void { Settings.requestWindowTitleOpen(); }
        function close(): void { Settings.requestWindowTitleClose(); }
    }

    // Volume & Audio Mixer IPC
    IpcHandler {
        target: "volume"
        function toggle(): void { Settings.requestVolumeToggle(); }
        function open(): void { Settings.requestVolumeOpen(); }
        function close(): void { Settings.requestVolumeClose(); }
        function mute(): void {
            let sink = Pipewire.defaultAudioSink;
            if (sink && sink.audio) sink.audio.muted = !sink.audio.muted;
        }
        function up(delta: real): void {
            let step = (delta > 0 ? delta : (Settings?.volumeStep ?? 5)) / 100.0;
            let sink = Pipewire.defaultAudioSink;
            if (sink && sink.audio) {
                sink.audio.volume = Math.min(1.5, sink.audio.volume + step);
                sink.audio.muted = false;
            }
        }
        function down(delta: real): void {
            let step = (delta > 0 ? delta : (Settings?.volumeStep ?? 5)) / 100.0;
            let sink = Pipewire.defaultAudioSink;
            if (sink && sink.audio) {
                sink.audio.volume = Math.max(0.0, sink.audio.volume - step);
            }
        }
    }

    IpcHandler {
        target: "audio"
        function toggle(): void { Settings.requestVolumeToggle(); }
        function open(): void { Settings.requestVolumeOpen(); }
        function close(): void { Settings.requestVolumeClose(); }
    }

    // Network & Wi-Fi IPC
    IpcHandler {
        target: "network"
        function toggle(): void { Settings.requestNetworkToggle(); }
        function open(): void { Settings.requestNetworkOpen(); }
        function close(): void { Settings.requestNetworkClose(); }
    }

    IpcHandler {
        target: "wifi"
        function toggle(): void { Settings.requestNetworkToggle(); }
        function open(): void { Settings.requestNetworkOpen(); }
        function close(): void { Settings.requestNetworkClose(); }
    }

    // Bluetooth IPC
    IpcHandler {
        target: "bluetooth"
        function toggle(): void { Settings.requestBluetoothToggle(); }
        function open(): void { Settings.requestBluetoothOpen(); }
        function close(): void { Settings.requestBluetoothClose(); }
    }

    IpcHandler {
        target: "bt"
        function toggle(): void { Settings.requestBluetoothToggle(); }
        function open(): void { Settings.requestBluetoothOpen(); }
        function close(): void { Settings.requestBluetoothClose(); }
    }

    // Media Player IPC
    IpcHandler {
        target: "media"
        function toggle(): void { Settings.requestMediaToggle(); }
        function open(): void { Settings.requestMediaOpen(); }
        function close(): void { Settings.requestMediaClose(); }
        function playPause(): void {
            let player = Mpris.players.values.find(p => p.canControl);
            if (player) player.playPause();
        }
        function next(): void {
            let player = Mpris.players.values.find(p => p.canGoNext);
            if (player) player.next();
        }
        function previous(): void {
            let player = Mpris.players.values.find(p => p.canGoPrevious);
            if (player) player.previous();
        }
    }

    IpcHandler {
        target: "nowplaying"
        function toggle(): void { Settings.requestMediaToggle(); }
        function open(): void { Settings.requestMediaOpen(); }
        function close(): void { Settings.requestMediaClose(); }
    }

    // Power Menu IPC
    IpcHandler {
        target: "power"
        function toggle(): void { Settings.requestPowerMenuToggle(); }
        function open(): void { Settings.requestPowerMenuOpen(); }
        function close(): void { Settings.requestPowerMenuClose(); }
    }

    IpcHandler {
        target: "powermenu"
        function toggle(): void { Settings.requestPowerMenuToggle(); }
        function open(): void { Settings.requestPowerMenuOpen(); }
        function close(): void { Settings.requestPowerMenuClose(); }
    }

    // Clock & Calendar IPC
    IpcHandler {
        target: "clock"
        function toggle(): void { Settings.requestClockToggle(); }
        function open(): void { Settings.requestClockOpen(); }
        function close(): void { Settings.requestClockClose(); }
    }

    IpcHandler {
        target: "calendar"
        function toggle(): void { Settings.requestClockToggle(); }
        function open(): void { Settings.requestClockOpen(); }
        function close(): void { Settings.requestClockClose(); }
    }

    // Clipboard Manager IPC
    IpcHandler {
        target: "clipboard"
        function toggle(): void { Settings.requestClipboardToggle(); }
        function open(): void { Settings.requestClipboardOpen(); }
        function close(): void { Settings.requestClipboardClose(); }
    }

    IpcHandler {
        target: "clip"
        function toggle(): void { Settings.requestClipboardToggle(); }
        function open(): void { Settings.requestClipboardOpen(); }
        function close(): void { Settings.requestClipboardClose(); }
    }

    // Wallpaper Browser IPC
    IpcHandler {
        target: "wallpaper"
        function toggle(): void { Settings.requestWallpaperToggle(); }
        function open(): void { Settings.requestWallpaperOpen(); }
        function close(): void { Settings.requestWallpaperClose(); }
    }

    // Quick Notes IPC
    IpcHandler {
        target: "notes"
        function toggle(): void { Settings.requestQuickNotesToggle(); }
        function open(): void { Settings.requestQuickNotesOpen(); }
        function close(): void { Settings.requestQuickNotesClose(); }
    }

    IpcHandler {
        target: "quicknotes"
        function toggle(): void { Settings.requestQuickNotesToggle(); }
        function open(): void { Settings.requestQuickNotesOpen(); }
        function close(): void { Settings.requestQuickNotesClose(); }
    }

    // Workspaces Overview IPC
    IpcHandler {
        target: "workspaces"
        function toggle(): void { Settings.requestWorkspacesToggle(); }
        function open(): void { Settings.requestWorkspacesOpen(); }
        function close(): void { Settings.requestWorkspacesClose(); }
    }

    IpcHandler {
        target: "overview"
        function toggle(): void { Settings.requestWorkspacesToggle(); }
        function open(): void { Settings.requestWorkspacesOpen(); }
        function close(): void { Settings.requestWorkspacesClose(); }
    }

    // Idle & Caffeine IPC
    IpcHandler {
        target: "caffeine"
        function toggle(): bool {
            IdleService.enabled = !IdleService.enabled;
            return !IdleService.enabled;
        }
        function open(): void { Settings.requestIdleOpen(); }
        function close(): void { Settings.requestIdleClose(); }
        function status(): bool { return !IdleService.enabled; }
    }

    IpcHandler {
        target: "idle"
        function toggle(): bool {
            IdleService.enabled = !IdleService.enabled;
            return IdleService.enabled;
        }
        function open(): void { Settings.requestIdleOpen(); }
        function close(): void { Settings.requestIdleClose(); }
        function status(): bool { return IdleService.enabled; }
        function set(state: bool): bool {
            IdleService.enabled = state;
            return IdleService.enabled;
        }
    }
}



