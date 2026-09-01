pragma Singleton
import QtQuick
import ".."
import Quickshell
import Quickshell.Io
import Quickshell.Networking

QtObject {
    id: root

    readonly property var net: Networking

    property bool wifiEnabled: net ? net.wifiEnabled : false
    onWifiEnabledChanged: {
        if (net && net.wifiEnabled !== wifiEnabled) {
            net.wifiEnabled = wifiEnabled
        }
        root.ensureScanner()
    }

    // find and track wifi device
    readonly property var wifiDevice: {
        if (!net || !net.devices) return null;
        let devs = net.devices.values || net.devices;
        for (let i = 0; i < devs.length; i++) {
            let dev = devs[i] || net.devices.at?.(i);
            if (dev && (dev.type === DeviceType.Wifi || dev.deviceType === DeviceType.Wifi || dev.networks !== undefined)) {
                return dev;
            }
        }
        return null;
    }

    // find and track ethernet device
    readonly property var wiredDevice: {
        if (!net || !net.devices) return null;
        let devs = net.devices.values || net.devices;
        for (let i = 0; i < devs.length; i++) {
            let dev = devs[i] || net.devices.at?.(i);
            if (dev && (dev.type === DeviceType.Wired || dev.deviceType === DeviceType.Wired || dev.hasLink !== undefined)) {
                return dev;
            }
        }
        return null;
    }

    // search for connected wifi network across device property and network list
    readonly property var connectedWifiNetwork: {
        if (!wifiDevice) return null;
        if (wifiDevice.network && (wifiDevice.network.connected || wifiDevice.network.name)) {
            return wifiDevice.network;
        }
        let nets = wifiDevice.networks?.values || wifiDevice.networks;
        if (nets) {
            for (let i = 0; i < nets.length; i++) {
                let n = nets[i] || wifiDevice.networks.at?.(i);
                if (n && n.connected) return n;
            }
        }
        return null;
    }

    // fallback nmcli poller for instant 100% accurate SSID and status
    property string _cliSsid: ""
    property int _cliSignal: 0
    property bool _cliConnected: false

    property Process cliPoller: Process {
        command: ["nmcli", "-t", "-f", "TYPE,STATE,CONNECTION,SIGNAL", "dev"]
        running: false
        stdout: SplitParser {
            onRead: (data) => {
                let lines = (data || "").trim().split("\n");
                let foundWifi = false;
                for (let i = 0; i < lines.length; i++) {
                    let parts = lines[i].split(":");
                    if (parts[0] === "wifi" && parts[1] === "connected") {
                        root._cliConnected = true;
                        root._cliSsid = parts[2] || "Connected";
                        root._cliSignal = parseInt(parts[3]) || 80;
                        foundWifi = true;
                        break;
                    }
                }
                if (!foundWifi) {
                    root._cliConnected = false;
                    root._cliSsid = "";
                    root._cliSignal = 0;
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

    readonly property bool isWiredConnected: wiredDevice ? (wiredDevice.hasLink ?? false) : false
    readonly property bool isWifiConnected: (connectedWifiNetwork !== null) || _cliConnected
    readonly property bool isConnected: isWiredConnected || isWifiConnected

    readonly property string activeSsid: {
        if (isWiredConnected) return "Ethernet";
        if (connectedWifiNetwork && connectedWifiNetwork.name) return connectedWifiNetwork.name;
        if (_cliConnected && _cliSsid !== "") return _cliSsid;
        return isConnected ? "Online" : "Disconnected";
    }

    readonly property int signalStrength: {
        if (isWiredConnected) return 100;
        if (connectedWifiNetwork) {
            let sig = connectedWifiNetwork.signalStrength ?? 0;
            return Math.round(sig <= 1.0 ? sig * 100 : sig);
        }
        if (_cliConnected && _cliSignal > 0) return _cliSignal;
        return 0;
    }

    function ensureScanner() {
        if (wifiDevice && wifiEnabled) {
            wifiDevice.scannerEnabled = true;
        }
    }

    onWifiDeviceChanged: ensureScanner()
    Component.onCompleted: ensureScanner()

    function toggleWifi() {
        if (net) {
            net.wifiEnabled = !net.wifiEnabled;
        } else {
            Quickshell.execDetached(["nmcli", "radio", "wifi", wifiEnabled ? "off" : "on"]);
        }
    }

    function rescan() {
        if (wifiDevice) {
            wifiDevice.scannerEnabled = false;
            wifiDevice.scannerEnabled = true;
        }
        Quickshell.execDetached(["nmcli", "dev", "wifi", "rescan"]);
        statusPoller.restart();
    }
}
