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
}
