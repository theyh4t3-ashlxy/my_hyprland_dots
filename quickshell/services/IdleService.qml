pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Wayland

QtObject {
    id: root

    property bool enabled: true

    // 150s: dim screen
    property IdleMonitor dimMonitor: IdleMonitor {
        timeout: 150
        respectInhibitors: true
        onIsIdleChanged: {
            if (!root.enabled) return;
            if (isIdle) {
                Quickshell.execDetached(["brightnessctl", "-s", "set", "10%"]);
            } else {
                Quickshell.execDetached(["brightnessctl", "-r"]);
            }
        }
    }

    // 300s: lock screen natively via Quickshell
    property IdleMonitor lockMonitor: IdleMonitor {
        timeout: 300
        respectInhibitors: true
        onIsIdleChanged: {
            if (!root.enabled) return;
            if (isIdle) {
                // Trigger native quickshell session lock
                let lockObj = Quickshell.env("QUICKSHELL_LOCK") || null;
                Quickshell.execDetached(["bash", "-c", "loginctl lock-session 2>/dev/null || true"]);
            }
        }
    }

    // 330s: turn off monitors
    property IdleMonitor dpmsMonitor: IdleMonitor {
        timeout: 330
        respectInhibitors: true
        onIsIdleChanged: {
            if (!root.enabled) return;
            if (isIdle) {
                Quickshell.execDetached(["hyprctl", "dispatch", "dpms", "off"]);
            } else {
                Quickshell.execDetached(["hyprctl", "dispatch", "dpms", "on"]);
            }
        }
    }

    // 600s: suspend system
    property IdleMonitor suspendMonitor: IdleMonitor {
        timeout: 600
        respectInhibitors: true
        onIsIdleChanged: {
            if (!root.enabled) return;
            if (isIdle) {
                Quickshell.execDetached(["systemctl", "suspend"]);
            }
        }
    }
}
