pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import ".."

QtObject {
    id: root

    property bool isOpen: false
    property string activeMode: "region" // "region", "window", "fullscreen"
    property var clients: []

    // Coordination signals for per-screen overlay
    signal performCapture(var targetScreen, string action, real x, real y, real w, real h)
    signal performFullscreen(var targetScreen, string action)

    property Process clientsProcess: Process {
        command: ["hyprctl", "clients", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let parsed = JSON.parse(text);
                    if (Array.isArray(parsed)) {
                        root.clients = parsed.filter(c => !c.hidden && c.mapped !== false);
                    }
                } catch (e) {
                    root.clients = [];
                }
            }
        }
    }

    property Timer fullscreenTimer: Timer {
        interval: 100
        repeat: false
        property var targetScreen
        property string action: "both"
        onTriggered: {
            root.performFullscreen(targetScreen, action);
        }
    }

    function open(mode: string): void {
        activeMode = mode || "region";
        isOpen = true;
        clientsProcess.running = true;
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
        let act = action || Settings.screenshotDefaultAction || "both";
        root.performCapture(screen, act, x, y, w, h);
    }

    function captureFullscreen(screen: var, action: string): void {
        let act = action || Settings.screenshotDefaultAction || "both";
        let target = screen || Quickshell.screens[0];
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
        let act = action || Settings.screenshotDefaultAction || "both";
        let cx = client.at[0];
        let cy = client.at[1];
        let cw = client.size[0];
        let ch = client.size[1];

        let matchedScreen = Quickshell.screens[0];
        for (let i = 0; i < Quickshell.screens.length; i++) {
            let s = Quickshell.screens[i];
            if (cx >= s.x && cy >= s.y && cx < s.x + s.width && cy < s.y + s.height) {
                matchedScreen = s;
                break;
            }
        }

        let relX = cx - matchedScreen.x;
        let relY = cy - matchedScreen.y;
        root.performCapture(matchedScreen, act, relX, relY, cw, ch);
    }
}
