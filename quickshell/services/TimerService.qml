pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import ".."

Singleton {
    id: root

    property int timerTotal: 300
    property int timerRemaining: 0
    property bool timerRunning: false
    property bool timerPaused: false

    property int stopwatchElapsed: 0
    property bool stopwatchRunning: false

    signal timerFinished()

    readonly property string timerDisplay: formatSeconds(timerRemaining)
    readonly property string stopwatchDisplay: formatSeconds(stopwatchElapsed)
    readonly property real timerProgress: (timerTotal > 0 && timerRemaining > 0) ? (timerRemaining / timerTotal) : 0

    function formatSeconds(sec) {
        let s = Math.max(0, Math.floor(sec || 0));
        let m = Math.floor(s / 60);
        let remS = s % 60;
        let h = Math.floor(m / 60);
        let remM = m % 60;
        if (h > 0) {
            return (h < 10 ? "0" : "") + h + ":" + (remM < 10 ? "0" : "") + remM + ":" + (remS < 10 ? "0" : "") + remS;
        }
        return (remM < 10 ? "0" : "") + remM + ":" + (remS < 10 ? "0" : "") + remS;
    }

    function startTimer(seconds) {
        let s = (typeof seconds === "number" && seconds > 0) ? seconds : 300;
        timerTotal = s;
        timerRemaining = s;
        timerRunning = true;
        timerPaused = false;
    }

    function pauseTimer() {
        if (timerRunning) {
            timerRunning = false;
            timerPaused = true;
        }
    }

    function resumeTimer() {
        if (timerPaused && timerRemaining > 0) {
            timerRunning = true;
            timerPaused = false;
        }
    }

    function toggleTimer() {
        if (timerRunning) {
            pauseTimer();
        } else if (timerPaused && timerRemaining > 0) {
            resumeTimer();
        } else {
            startTimer(timerTotal > 0 ? timerTotal : 300);
        }
    }

    function resetTimer() {
        timerRunning = false;
        timerPaused = false;
        timerRemaining = 0;
    }

    function addTimerMinutes(mins) {
        let addSec = (mins || 1) * 60;
        if (timerRunning || timerPaused) {
            timerRemaining += addSec;
            timerTotal += addSec;
        } else {
            startTimer(addSec);
        }
    }

    function startStopwatch() {
        stopwatchRunning = true;
    }

    function pauseStopwatch() {
        stopwatchRunning = false;
    }

    function toggleStopwatch() {
        stopwatchRunning = !stopwatchRunning;
    }

    function resetStopwatch() {
        stopwatchRunning = false;
        stopwatchElapsed = 0;
    }

    Timer {
        id: ticker
        interval: 1000
        repeat: true
        running: root.timerRunning || root.stopwatchRunning
        onTriggered: {
            if (root.timerRunning) {
                if (root.timerRemaining > 1) {
                    root.timerRemaining -= 1;
                } else {
                    root.timerRemaining = 0;
                    root.timerRunning = false;
                    root.timerPaused = false;
                    root.timerFinished();
                    root._sendFinishedNotification();
                }
            }
            if (root.stopwatchRunning) {
                root.stopwatchElapsed += 1;
            }
        }
    }

    function _sendFinishedNotification() {
        try {
            Quickshell.execDetached(["notify-send", "-a", "Quickshell", "-i", "alarm", "Timer Finished", "Your timer has completed!"]);
        } catch (e) {}
    }
}
