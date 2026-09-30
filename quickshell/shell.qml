//@ pragma UseQApplication
// ==============================================================================
// quickshell root orchestrator: the asylum command deck
// spawns bars, liquid corners, overlays, and registers IPC endpoints.
// engineered to make electron devs cry and waybar users question their life choices.
// do not touch unless you crave a completely black screen and existential dread.
// ==============================================================================
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Services.Mpris
import "widgets"

ShellRoot {
    // the bar: dynamic edges, liquid fillets, and zero electron baggage
    Variants {
        model: Quickshell.screens
        StatusBar {}
    }

    // liquid concave screen corners: sharp 90-degree corners are an illegal felony
    Variants {
        model: Quickshell.screens
        ScreenCorners {}
    }

    // toast alerts that actually respect physics and dismiss on drag
    Variants {
        model: Quickshell.screens
        NotificationToasts {}
    }

    // the mad scientist bar studio for dragging pills around at 3am
    Variants {
        model: Quickshell.screens
        BarStudio {}
    }

    // bezier curves and spring physics calibration playground
    Variants {
        model: Quickshell.screens
        MotionSandbox {}
    }

    // on-screen volume & brightness pills so you know your keys aren't broken
    Variants {
        model: Quickshell.screens
        OSD {}
    }

    // first-run onboarding & vibe calibration monolith (who the fuck is 'we'?):
    // instantiates per-screen via Variants and dynamically presents on whichever monitor is focused
    Variants {
        model: Quickshell.screens
        WelcomeWizard {}
    }

    // pam-authenticated layer-shell vault to keep out the uninitiated
    LockScreen {
        id: globalLockScreen
    }

    // notifications IPC: route alerts to dbus or nuke them into the void
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

    // bar studio IPC: drag status bar pills around at 3am
    IpcHandler {
        target: "studio"
        function toggle(): void { Settings.showBarStudio = !Settings.showBarStudio; }
        function open(): void { Settings.showBarStudio = true; }
        function close(): void { Settings.showBarStudio = false; }
    }

    // motion sandbox IPC: torture test bezier curves and spring physics
    IpcHandler {
        target: "sandbox"
        function toggle(): void { Settings.showMotionSandbox = !Settings.showMotionSandbox; }
        function open(): void { Settings.showMotionSandbox = true; }
        function close(): void { Settings.showMotionSandbox = false; }
    }

    // app launcher IPC: fuzzy search apps at lightspeed
    IpcHandler {
        target: "launcher"
        function toggle(): void { Settings.requestLauncherToggle(); }
        function open(): void { Settings.requestLauncherOpen(); }
        function close(): void { Settings.requestLauncherClose(); }
    }

    // screenshot IPC: digital kleptomania and receipts for the group chat
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

    // screen recording IPC: hardware-accelerated video capture with native multi-source audio
    IpcHandler {
        target: "record"
        function toggle(): void { ScreenRecService.toggle(); }
        function start(): void { ScreenRecService.startRecording(); }
        function stop(): void { ScreenRecService.stopRecording(); }
        function screen(): void { ScreenRecService.startRecording("screen"); }
        function region(): void { ScreenRecService.startRecording("region"); }
        function window(): void { ScreenRecService.startRecording("window"); }
        function discard(): void { ScreenRecService.discardRecording(); }
    }

    // quick settings IPC: control center, sliders, and unhinged vibe toggles
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

    // battery IPC: monitor laptop power depletion panic
    IpcHandler {
        target: "battery"
        function toggle(): void { Settings.requestBatteryToggle(); }
        function open(): void { Settings.requestBatteryOpen(); }
        function close(): void { Settings.requestBatteryClose(); }
    }

    // window title IPC: active client telemetry
    IpcHandler {
        target: "window"
        function toggle(): void { Settings.requestWindowTitleToggle(); }
        function open(): void { Settings.requestWindowTitleOpen(); }
        function close(): void { Settings.requestWindowTitleClose(); }
    }

    // volume & pipewire mixer IPC: decibels exceeding osha recommendations
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

    // network & wifi IPC: wifi, ethernet, and disconnecting from reality
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

    // bluetooth IPC: rf packets screaming into the void
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

    // media player IPC: skip bad tracks with extreme prejudice
    IpcHandler {
        target: "media"
        function toggle(): void { Settings.requestMediaToggle(); }
        function open(): void { Settings.requestMediaOpen(); }
        function close(): void { Settings.requestMediaClose(); }
        function playPause(): void {
            let player = Mpris.players.values.find(p => p.canTogglePlaying) ?? Mpris.players.values.find(p => p.canPlay || p.canPause);
            if (player) {
                if (player.canTogglePlaying) {
                    player.togglePlaying();
                } else if (player.isPlaying && player.canPause) {
                    player.pause();
                } else if (player.canPlay) {
                    player.play();
                }
            }
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

    // power menu IPC: shutdown, reboot, or cowards way out
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

    // clock & calendar IPC: watch your mortal lifespan tick away in real time
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

    // clipboard manager IPC: saving your accidental ctrl+c disasters
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

    // wallpaper browser IPC: live matugen color extraction roulette
    IpcHandler {
        target: "wallpaper"
        function toggle(): void { Settings.requestWallpaperToggle(); }
        function open(): void { Settings.requestWallpaperOpen(); }
        function close(): void { Settings.requestWallpaperClose(); }
    }

    // quick notes IPC: unhinged midnight thoughts storage
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

    // tasks & to-do list IPC: flex on brain_shell kanban without bash subshells
    IpcHandler {
        target: "tasks"
        function toggle(): void { Settings.requestQuickNotesToggle(); }
        function open(): void { Settings.requestQuickNotesOpen(); }
        function close(): void { Settings.requestQuickNotesClose(); }
    }

    IpcHandler {
        target: "todo"
        function toggle(): void { Settings.requestQuickNotesToggle(); }
        function open(): void { Settings.requestQuickNotesOpen(); }
        function close(): void { Settings.requestQuickNotesClose(); }
    }

    // screen capture & recorder hub IPC
    IpcHandler {
        target: "capture"
        function toggle(): void { Settings.requestCaptureToggle(); }
        function open(): void { Settings.requestCaptureOpen(); }
        function close(): void { Settings.requestCaptureClose(); }
    }

    // workspaces overview IPC: hyprland workspace hyperjump
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

    // idle & caffeine IPC: pumping intravenous espresso straight into wayland
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

    // keybinds preview IPC: muscle memory or bust
    IpcHandler {
        target: "keybinds"
        function toggle(): void { Settings.requestKeybindsToggle(); }
        function open(): void { Settings.requestKeybindsOpen(); }
        function close(): void { Settings.requestKeybindsClose(); }
    }

    // welcome wizard IPC: onboarding the newly initiated into the asylum
    IpcHandler {
        target: "welcome"
        function toggle(): void { Settings.requestWelcomeToggle(); }
        function open(): void { Settings.requestWelcomeOpen(); }
        function close(): void { Settings.requestWelcomeClose(); }
    }
}



