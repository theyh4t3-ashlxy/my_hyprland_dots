pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Networking

QtObject {
    id: root

    property bool wifiEnabled: Networking.wifiEnabled
    onWifiEnabledChanged: {
        if (Networking.wifiEnabled !== wifiEnabled) {
            Networking.wifiEnabled = wifiEnabled;
        }
    }

    // finding the actual hardware so we stop hallucinating offline mode
    readonly property var wifiDevice: {
        if (!Networking.devices) return null;
        for (const dev of Networking.devices.values) {
            if (dev.networks !== undefined) return dev;
        }
        return null;
    }

    readonly property var wiredDevice: {
        if (!Networking.devices) return null;
        for (const dev of Networking.devices.values) {
            if (dev.hasLink !== undefined && dev.networks === undefined) return dev;
        }
        return null;
    }

    // ground truth network poller via nmcli
    property string _cliSsid: ""
    property bool _cliWired: false
    property bool _cliWifi: false

    property Process cliPoller: Process {
        command: ["nmcli", "-t", "-f", "TYPE,STATE,CONNECTION", "dev"]
        running: false
        stdout: SplitParser {
            onRead: (data) => {
                let lines = (data || "").trim().split("\n");
                let foundWifi = false;
                let foundWired = false;
                for (let i = 0; i < lines.length; i++) {
                    let parts = lines[i].split(":");
                    if (parts[0] === "wifi" && parts[1] === "connected") {
                        root._cliWifi = true;
                        root._cliSsid = parts[2] || "Connected";
                        foundWifi = true;
                    } else if (parts[0] === "ethernet" && parts[1] === "connected") {
                        root._cliWired = true;
                        foundWired = true;
                    }
                }
                if (!foundWifi) {
                    root._cliWifi = false;
                    root._cliSsid = "";
                }
                if (!foundWired) {
                    root._cliWired = false;
                }
            }
        }
    }

    property Timer statusPoller: Timer {
        interval: 3000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: {
            if (!root.cliPoller.running) root.cliPoller.running = true;
        }
    }

    // the access point currently beaming radiation into our skull
    readonly property var connectedWifi: {
        if (wifiDevice?.network) return wifiDevice.network;
        if (wifiDevice?.networks) {
            for (const net of wifiDevice.networks.values) {
                if (net.connected) return net;
            }
        }
        return null;
    }

    readonly property bool isWiredConnected: (wiredDevice?.hasLink ?? false) || _cliWired
    readonly property bool isWifiConnected: (connectedWifi !== null && (connectedWifi.connected ?? true)) || _cliWifi
    readonly property bool isConnected: isWiredConnected || isWifiConnected

    readonly property string activeSsid: {
        if (isWiredConnected) return "Ethernet";
        if (connectedWifi?.name) return connectedWifi.name;
        if (_cliSsid !== "") return _cliSsid;
        if (wifiDevice?.networks) {
            for (const net of wifiDevice.networks.values) {
                if (net.connected && net.name) return net.name;
            }
        }
        return isConnected ? "Connected" : "Disconnected";
    }

    readonly property int signalStrength: {
        if (isWiredConnected) return 100;
        if (connectedWifi) {
            const sig = connectedWifi.signalStrength ?? 0;
            return Math.round(sig <= 1.0 ? sig * 100 : sig);
        }
        if (wifiDevice?.networks) {
            for (const net of wifiDevice.networks.values) {
                if (net.connected) {
                    const sig = net.signalStrength ?? 0;
                    return Math.round(sig <= 1.0 ? sig * 100 : sig);
                }
            }
        }
        return isConnected ? 85 : 0;
    }

    function toggleWifi() {
        Networking.wifiEnabled = !Networking.wifiEnabled;
        Quickshell.execDetached(["nmcli", "radio", "wifi", Networking.wifiEnabled ? "on" : "off"]);
        statusPoller.restart();
    }

    function rescan() {
        if (wifiDevice) {
            wifiDevice.scannerEnabled = false;
            wifiDevice.scannerEnabled = true;
        }
        Quickshell.execDetached(["nmcli", "dev", "wifi", "rescan"]);
        statusPoller.restart();
    }

    Component.onCompleted: {
        if (wifiDevice) {
            wifiDevice.scannerEnabled = true;
        }
    }
}
