pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: root

    property string device: "intel_backlight"
    property int current: 0
    property int max: 19393
    readonly property int percent: max > 0 ? Math.round((current / max) * 100) : 0

    property bool _ready: false
    signal brightnessChanged(int newPercent)

    // detects amdgpu, intel, etc automatically
    Process {
        id: detectProc
        command: ["sh", "-c", "ls -1 /sys/class/backlight 2>/dev/null | head -n 1"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                let d = data.trim();
                if (d.length > 0) root.device = d;
            }
        }
    }

    FileView {
        path: "/sys/class/backlight/" + root.device + "/max_brightness"
        onLoaded: {
            let val = parseInt(text().trim());
            if (!isNaN(val) && val > 0) root.max = val;
        }
    }

    FileView {
        path: "/sys/class/backlight/" + root.device + "/brightness"
        watchChanges: true
        onLoaded: {
            let val = parseInt(text().trim());
            if (!isNaN(val)) {
                let prev = root.percent;
                root.current = val;
                if (root._ready && root.max > 1) {
                    let next = Math.round((val / root.max) * 100);
                    if (next !== prev) {
                        root.brightnessChanged(next);
                    }
                } else if (root.max > 1) {
                    root._ready = true;
                }
            }
        }
        onFileChanged: reload()
    }

    function setBrightnessPercent(pct) {
        let clamped = Math.max(1, Math.min(100, pct));
        Quickshell.execDetached(["brightnessctl", "set", clamped + "%"]);
    }
}
