pragma Singleton
import QtQuick
import ".."
import Quickshell.Networking

QtObject {
    id: root

    readonly property var net: Networking

    property bool wifiEnabled: net ? net.wifiEnabled : false
    onWifiEnabledChanged: {
        if (net && net.wifiEnabled !== wifiEnabled) {
            net.wifiEnabled = wifiEnabled
        }
    }

    // find and track wifi device
    readonly property var wifiDevice: {
        if (!net || !net.devices) return null;
        let devs = net.devices.values || net.devices;
        for (let i = 0; i < devs.length; i++) {
            let dev = devs[i] || net.devices.at?.(i);
            if (dev && (dev.deviceType === DeviceType.Wifi || dev.networks !== undefined)) {
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
            if (dev && (dev.deviceType === DeviceType.Wired || dev.hasLink !== undefined)) {
                return dev;
            }
        }
        return null;
    }

    readonly property bool isWiredConnected: wiredDevice ? (wiredDevice.hasLink ?? false) : false
    readonly property bool isWifiConnected: wifiDevice ? (wifiDevice.state === ConnectionState.Connected || wifiDevice.network !== null) : false
    readonly property bool isConnected: isWiredConnected || isWifiConnected

    readonly property string activeSsid: {
        if (isWiredConnected) return "Ethernet";
        if (wifiDevice && wifiDevice.network) return wifiDevice.network.name || "Connected";
        return isConnected ? "Online" : "Disconnected";
    }

    readonly property int signalStrength: {
        if (isWiredConnected) return 100;
        if (wifiDevice && wifiDevice.network) {
            let sig = wifiDevice.network.signalStrength ?? 0;
            return Math.round(sig <= 1.0 ? sig * 100 : sig);
        }
        return 0;
    }

    // keep scanner active so networks don't disappear into the void
    function ensureScanner() {
        if (wifiDevice && wifiEnabled) {
            wifiDevice.scannerEnabled = true;
        }
    }

    onWifiDeviceChanged: ensureScanner()
    onWifiEnabledChanged: ensureScanner()
    Component.onCompleted: ensureScanner()

    function toggleWifi() {
        if (net) {
            net.wifiEnabled = !net.wifiEnabled;
        }
    }

    function rescan() {
        if (wifiDevice) {
            wifiDevice.scannerEnabled = false;
            wifiDevice.scannerEnabled = true;
        }
    }
}
