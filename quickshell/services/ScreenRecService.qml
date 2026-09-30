pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import ".."

// ==============================================================================
// ScreenRecService: hardware-accelerated screen recording orchestrator
// zero slurp, zero pactl null-sink garbage, native gpu capture,
// and live status feedback.
// ==============================================================================
QtObject {
    id: root

    property bool isRecording: false
    property int elapsedSeconds: 0
    readonly property string elapsedTimeString: {
        let m = Math.floor(elapsedSeconds / 60);
        let s = elapsedSeconds % 60;
        return (m < 10 ? "0" : "") + m + ":" + (s < 10 ? "0" : "") + s;
    }

    property string activeTarget: "screen" // "screen", "window", "region"
    property string activeAudio: "both"    // "both", "desktop", "mic", "none"
    property int framerate: 60
    property string currentFilePath: ""
    property bool _discarding: false
    property var _pendingArgs: []

    readonly property string outputDirectory: {
        let home = Quickshell.env("HOME") || "";
        return home + "/Videos/Recordings";
    }

    property Timer elapsedTimer: Timer {
        id: elapsedTimer
        interval: 1000
        repeat: true
        running: false
        onTriggered: root.elapsedSeconds++
    }

    // Directory creation pre-check before starting recorder
    property Process mkdirProc: Process {
        id: mkdirProc
        command: []
        running: false
        onExited: (code) => {
            if (code === 0 && root._pendingArgs.length > 0) {
                recProc.command = root._pendingArgs;
                recProc.running = true;
            }
        }
    }

    // Main gpu-screen-recorder process
    property Process recProc: Process {
        id: recProc
        command: []
        running: false

        onStarted: {
            root.isRecording = true;
            root.elapsedSeconds = 0;
            elapsedTimer.restart();
            Quickshell.execDetached([
                "notify-send",
                "-a", "Quickshell Screen Recorder",
                "-i", "media-record",
                "Recording Started",
                "Target: " + root.activeTarget + " • Audio: " + root.activeAudio
            ]);
        }

        onExited: (exitCode, exitStatus) => {
            root.isRecording = false;
            elapsedTimer.stop();

            if (root._discarding) {
                root._discarding = false;
                Quickshell.execDetached(["rm", "-f", root.currentFilePath]);
                Quickshell.execDetached([
                    "notify-send",
                    "-a", "Quickshell Screen Recorder",
                    "-i", "edit-delete",
                    "Recording Discarded",
                    "Temporary video file deleted."
                ]);
            } else {
                Quickshell.execDetached([
                    "notify-send",
                    "-a", "Quickshell Screen Recorder",
                    "-i", "video-x-generic",
                    "Recording Saved (" + root.elapsedTimeString + ")",
                    root.currentFilePath
                ]);
            }
        }
    }

    function startRecording(target, audio) {
        if (root.isRecording) return;

        let tgt = target || root.activeTarget || "screen";
        let aud = audio || root.activeAudio || "both";
        root.activeTarget = tgt;
        root.activeAudio = aud;

        if (tgt === "region") {
            ScreenshotService.open("record");
        } else {
            root._executeLaunch(tgt);
        }
    }

    function startRecordingRegion(screen, x, y, w, h) {
        if (root.isRecording) return;
        let absX = Math.round((screen ? screen.x : 0) + x);
        let absY = Math.round((screen ? screen.y : 0) + y);
        let geom = Math.round(w) + "x" + Math.round(h) + "+" + absX + "+" + absY;
        root._executeLaunch("region", geom);
    }

    function _executeLaunch(target, regionGeom) {
        let dir = root.outputDirectory;
        let timestamp = Qt.formatDateTime(new Date(), "yyyy-MM-dd_hh-mm-ss");
        let scrName = Hyprland?.focusedMonitor?.name || "screen";
        root.currentFilePath = dir + "/Recording_" + timestamp + "_" + scrName + ".mp4";
        root._discarding = false;

        let args = ["gpu-screen-recorder", "-fallback-cpu-encoding", "yes"];

        // Target geometry / output resolution
        if (target === "region" && regionGeom) {
            args.push("-w", "region", "-region", regionGeom);
        } else if (target === "window") {
            args.push("-w", "focused");
        } else {
            // Full monitor: use focused monitor or fallback
            let mon = Hyprland?.focusedMonitor?.name;
            if (!mon && Quickshell.screens && Quickshell.screens.length > 0) {
                mon = Quickshell.screens[0].name;
            }
            args.push("-w", mon || "screen");
        }

        // Audio routing (gpu-screen-recorder mixes multiple -a natively in C)
        let aud = root.activeAudio;
        if (aud === "both") {
            args.push("-a", "default_output", "-a", "default_input");
        } else if (aud === "desktop") {
            args.push("-a", "default_output");
        } else if (aud === "mic") {
            args.push("-a", "default_input");
        }
        // "none" adds no -a flags

        // Framerate, format & output path
        args.push("-f", (root.framerate || 60).toString());
        args.push("-c", "mp4");
        args.push("-o", root.currentFilePath);

        root._pendingArgs = args;
        mkdirProc.command = ["mkdir", "-p", dir];
        mkdirProc.running = true;
    }

    function stopRecording() {
        if (!root.isRecording && !recProc.running) return;

        // SIGINT allows gpu-screen-recorder to cleanly write the MP4 moov atom
        if (recProc.processId) {
            Quickshell.execDetached(["kill", "-INT", recProc.processId.toString()]);
        }
        // Failsafe matching instance path in case processId binding is delayed
        Quickshell.execDetached(["pkill", "-f", "-INT", "gpu-screen-recorder.*" + root.currentFilePath]);
    }

    function discardRecording() {
        if (!root.isRecording && !recProc.running) return;
        root._discarding = true;
        root.stopRecording();
    }

    function toggle(target, audio) {
        if (root.isRecording) {
            root.stopRecording();
        } else {
            root.startRecording(target, audio);
        }
    }
}
