pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import ".."

Singleton {
    id: root

    property bool isOpen: false
    property string activeMode: "region"
    property var clients: []

    // coordination signals for the per-screen ScreencopyView overlay
    signal performCapture(var targetScreen, string action, real x, real y, real w, real h)
    signal performFullscreen(var targetScreen, string action)

    // find the Quickshell ShellScreen matching the currently focused Hyprland monitor
    function getFocusedScreen() {
        let screens = Quickshell.screens || [];
        if (screens.length === 0) return null;
        let focusedMon = Hyprland.focusedMonitor;
        if (focusedMon) {
            for (let i = 0; i < screens.length; i++) {
                let mon = Hyprland.monitorFor(screens[i]);
                if ((mon && mon.id === focusedMon.id) || screens[i].name === focusedMon.name) {
                    return screens[i];
                }
            }
        }
        return screens[0];
    }

    // collect the set of workspace IDs currently visible across all monitors
    function getVisibleWorkspaceIds() {
        let visibleIds = {};
        let monitors = Hyprland.monitors?.values || [];
        for (let i = 0; i < monitors.length; i++) {
            let m = monitors[i];
            if (!m) continue;
            if (m.activeWorkspace?.id !== undefined) {
                visibleIds[m.activeWorkspace.id] = true;
            }
            if (m.lastIpcObject?.specialWorkspace?.id) {
                visibleIds[m.lastIpcObject.specialWorkspace.id] = true;
            }
        }
        if (Hyprland.focusedWorkspace?.id !== undefined) {
            visibleIds[Hyprland.focusedWorkspace.id] = true;
        }
        return visibleIds;
    }

    function filterAndSortClients(rawList) {
        if (!Array.isArray(rawList)) return [];
        let visibleWs = root.getVisibleWorkspaceIds();
        let hasWsInfo = Object.keys(visibleWs).length > 0;

        let filtered = rawList.filter(c => {
            if (!c || c.hidden || c.mapped === false) return false;
            if (!c.size || c.size[0] <= 0 || c.size[1] <= 0) return false;
            if (hasWsInfo && c.workspace?.id !== undefined) {
                return Boolean(visibleWs[c.workspace.id]);
            }
            return true;
        });

        // sort topmost windows first: pinned -> floating -> most recently focused
        filtered.sort((a, b) => {
            if (Boolean(a.pinned) !== Boolean(b.pinned)) return a.pinned ? -1 : 1;
            if (Boolean(a.floating) !== Boolean(b.floating)) return a.floating ? -1 : 1;
            return (a.focusHistoryID ?? 9999) - (b.focusHistoryID ?? 9999);
        });

        return filtered;
    }

    // instant seed from Quickshell's native Hyprland.toplevels while hyprctl refreshes exact geometry
    function seedClientsFromToplevels() {
        Hyprland.refreshMonitors();
        Hyprland.refreshWorkspaces();
        Hyprland.refreshToplevels();

        let toplevels = Hyprland.toplevels?.values || [];
        let seeded = [];
        for (let i = 0; i < toplevels.length; i++) {
            let ipc = toplevels[i]?.lastIpcObject;
            if (ipc) seeded.push(ipc);
        }
        if (seeded.length > 0) {
            root.clients = root.filterAndSortClients(seeded);
        }
    }

    property Process clientsProcess: Process {
        command: ["hyprctl", "clients", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let parsed = JSON.parse(text);
                    root.clients = root.filterAndSortClients(parsed);
                } catch (e) {
                    if (!root.clients || root.clients.length === 0) {
                        root.clients = [];
                    }
                }
            }
        }
    }

    property Timer fullscreenTimer: Timer {
        interval: 120
        repeat: false
        property var targetScreen: null
        property string action: "both"
        onTriggered: {
            root.performFullscreen(targetScreen, action);
        }
    }

    function open(mode: string): void {
        activeMode = mode || "region";
        if (activeMode !== "fullscreen") {
            seedClientsFromToplevels();
            clientsProcess.running = true;
        }
        isOpen = true;
    }

    function close(): void {
        isOpen = false;
        fullscreenTimer.stop();
    }

    function toggle(mode: string): void {
        if (isOpen) {
            close();
        } else {
            open(mode);
        }
    }

    function captureRegion(screen: var, x: real, y: real, w: real, h: real, action: string): void {
        let act = action || Settings?.screenshotDefaultAction || "both";
        let target = screen || root.getFocusedScreen();
        if (!target || w <= 1 || h <= 1) return;
        root.performCapture(target, act, x, y, w, h);
    }

    function captureFullscreen(screen: var, action: string): void {
        let act = action || Settings?.screenshotDefaultAction || "both";
        let target = screen || root.getFocusedScreen();
        if (!target) return;

        if (!isOpen) {
            open("fullscreen");
            fullscreenTimer.targetScreen = target;
            fullscreenTimer.action = act;
            fullscreenTimer.restart();
        } else {
            root.performFullscreen(target, act);
        }
    }

    function captureWindow(client: var, action: string): void {
        if (!client || !client.at || !client.size) return;
        let act = action || Settings?.screenshotDefaultAction || "both";
        let cx = Number(client.at[0]);
        let cy = Number(client.at[1]);
        let cw = Number(client.size[0]);
        let ch = Number(client.size[1]);
        if (cw <= 1 || ch <= 1) return;

        let screens = Quickshell.screens || [];
        if (screens.length === 0) return;

        // match screen by window center point or monitor ID so edge-overlapping windows don't pick the wrong monitor
        let centerX = cx + (cw / 2);
        let centerY = cy + (ch / 2);
        let matchedScreen = root.getFocusedScreen() || screens[0];

        for (let i = 0; i < screens.length; i++) {
            let s = screens[i];
            let mon = Hyprland.monitorFor(s);
            if (client.monitor !== undefined && mon && mon.id === client.monitor) {
                matchedScreen = s;
                break;
            }
            if (centerX >= s.x && centerY >= s.y && centerX < s.x + s.width && centerY < s.y + s.height) {
                matchedScreen = s;
                break;
            }
        }

        // clamp window crop rectangle to the matched monitor's bounds
        let rawX = cx - matchedScreen.x;
        let rawY = cy - matchedScreen.y;
        let clampedX = Math.max(0, rawX);
        let clampedY = Math.max(0, rawY);
        let clampedW = Math.min(matchedScreen.width - clampedX, cw - (clampedX - rawX));
        let clampedH = Math.min(matchedScreen.height - clampedY, ch - (clampedY - rawY));

        if (clampedW <= 1 || clampedH <= 1) return;
        root.performCapture(matchedScreen, act, clampedX, clampedY, clampedW, clampedH);
    }
}
