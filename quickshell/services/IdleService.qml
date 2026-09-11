pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

QtObject {
    id: root

    property bool enabled: true

    // Must be assigned to a property inside QtObject!
    property IpcHandler ipc: IpcHandler {
        target: "idle"

        function toggle(): bool {
            root.enabled = !root.enabled;
            return root.enabled;
        }

        function status(): bool {
            return root.enabled;
        }

        function set(state: bool): bool {
            root.enabled = state;
            return root.enabled;
        }
    }

    // 150s: dim screen
    property IdleMonitor dimMonitor: IdleMonitor {
        timeout: 150
        respectInhibitors: true
        onIsIdleChanged: {
            if (!root.enabled) return;
            Quickshell.execDetached(isIdle ? ["brightnessctl", "-s", "set", "10%"] : ["brightnessctl", "-r"]);
        }
    }

    // 300s: lock screen natively via Quickshell
    property IdleMonitor lockMonitor: IdleMonitor {
        timeout: 300
        respectInhibitors: true
        onIsIdleChanged: {
            if (!root.enabled || !isIdle) return;
            Quickshell.execDetached(["qs", "ipc", "call", "lock", "lock"]);
        }
    }

    // 330s: turn off monitors via native Hyprland IPC
    property IdleMonitor dpmsMonitor: IdleMonitor {
        timeout: 330
        respectInhibitors: true
        onIsIdleChanged: {
            if (!root.enabled) return;

            let action = isIdle ? "disable" : "enable";
            Settings.dispatchDpms(action);
        }
    }

    // 600s: suspend system
    property IdleMonitor suspendMonitor: IdleMonitor {
        timeout: 600
        respectInhibitors: true
        onIsIdleChanged: {
            if (!root.enabled || !isIdle) return;
            Quickshell.execDetached(["systemctl", "suspend"]);
        }
    }
}
