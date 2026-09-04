pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: root

    property int current: 0
    property int max: 19393
    readonly property int percent: max > 0 ? Math.round((current / max) * 100) : 0

    property bool _ready: false
    signal brightnessChanged(int newPercent)

    FileView {
        path: "/sys/class/backlight/intel_backlight/max_brightness"
        onLoaded: {
            let val = parseInt(text().trim());
            if (!isNaN(val) && val > 0) root.max = val;
        }
    }

    FileView {
        path: "/sys/class/backlight/intel_backlight/brightness"
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
