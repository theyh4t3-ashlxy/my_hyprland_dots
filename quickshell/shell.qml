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

    IpcHandler {
        target: "notifs"

        function toggle(): void {
            NotificationService.toggle();
        }

        function open(): void {
            NotificationService.open();
        }

        function close(): void {
            NotificationService.close();
        }

        function clear(): void {
            NotificationService.clearAll();
        }

        function dnd(): void {
            Settings.dnd = !Settings.dnd;
        }
    }

    IpcHandler {
        target: "notifications"

        function toggle(): void {
            NotificationService.toggle();
        }

        function open(): void {
            NotificationService.open();
        }

        function close(): void {
            NotificationService.close();
        }

        function clear(): void {
            NotificationService.clearAll();
        }

        function dnd(): void {
            Settings.dnd = !Settings.dnd;
        }
    }

    IpcHandler {
        target: "studio"

        function toggle(): void {
            Settings.showBarStudio = !Settings.showBarStudio;
        }

        function open(): void {
            Settings.showBarStudio = true;
        }

        function close(): void {
            Settings.showBarStudio = false;
        }
    }

    IpcHandler {
        target: "launcher"

        function toggle(): void {
            Settings.requestLauncherToggle();
        }

        function open(): void {
            Settings.requestLauncherToggle();
        }
    }

    Variants {
        model: Quickshell.screens
        ScreenshotOverlay {}
    }

    IpcHandler {
        target: "screenshot"

        function open(): void {
            ScreenshotService.open("region");
        }

        function close(): void {
            ScreenshotService.close();
        }

        function toggle(): void {
            ScreenshotService.toggle("region");
        }

        function full(): void {
            ScreenshotService.captureFullscreen(Quickshell.screens[0], "both");
        }

        function window(): void {
            ScreenshotService.open("window");
        }
    }

    IpcHandler {
        target: "quicksettings"

        function toggle(): void {
            Settings.requestQuickSettingsToggle();
        }

        function open(): void {
            Settings.requestQuickSettingsToggle();
        }
    }

    IpcHandler {
        target: "battery"

        function toggle(): void {
            Settings.requestBatteryToggle();
        }

        function open(): void {
            Settings.requestBatteryToggle();
        }
    }

    IpcHandler {
        target: "window"

        function toggle(): void {
            Settings.requestWindowTitleToggle();
        }

        function open(): void {
            Settings.requestWindowTitleToggle();
        }
    }

    IpcHandler {
        target: "caffeine"

        function toggle(): void {
            Settings.requestIdleToggle();
        }

        function open(): void {
            Settings.requestIdleToggle();
        }
    }
}
