//@ pragma UseQApplication
import Quickshell
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
}
