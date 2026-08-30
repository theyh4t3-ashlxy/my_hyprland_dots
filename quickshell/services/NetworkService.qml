pragma Singleton
import QtQuick
import ".."
import Quickshell.Networking

QtObject {
    id: root

    // raw networking singleton from quickshell
    readonly property var net: Networking

    property bool wifiEnabled: net ? net.wifiEnabled : false
    onWifiEnabledChanged: {
        if (net && net.wifiEnabled !== wifiEnabled) {
            net.wifiEnabled = wifiEnabled
        }
    }

    // find wifi device
    readonly property var wifiDevice: {
        if (!net || !net.devices) return null;
        for (let i = 0; i < net.devices.length; i++) {
            let dev = net.devices.at(i);
            if (dev.deviceType === DeviceType.Wifi) return dev;
        }
        return null;
    }

    // find ethernet device
    readonly property var wiredDevice: {
        if (!net || !net.devices) return null;
        for (let i = 0; i < net.devices.length; i++) {
            let dev = net.devices.at(i);
            if (dev.deviceType === DeviceType.Wired) return dev;
        }
        return null;
    }

    readonly property bool isWiredConnected: wiredDevice ? wiredDevice.hasLink : false
    readonly property bool isWifiConnected: wifiDevice ? (wifiDevice.state === ConnectionState.Connected) : false
    readonly property bool isConnected: isWiredConnected || isWifiConnected

    readonly property string activeSsid: {
        if (isWiredConnected) return "Ethernet";
        if (wifiDevice && wifiDevice.network) return wifiDevice.network.name || "Connected";
        return isConnected ? "Online" : "Disconnected";
    }

    readonly property int signalStrength: {
        if (isWiredConnected) return 100;
        if (wifiDevice && wifiDevice.network) return Math.round(wifiDevice.network.signalStrength * 100);
        return 0;
    }

    function toggleWifi() {
        if (net) {
            net.wifiEnabled = !net.wifiEnabled;
        }
    }

    function rescan() {
        if (wifiDevice && wifiDevice.scannerEnabled !== undefined) {
            wifiDevice.scannerEnabled = false;
            wifiDevice.scannerEnabled = true;
        }
    }
}
