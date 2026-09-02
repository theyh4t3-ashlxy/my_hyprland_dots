pragma Singleton
import QtQuick
import Quickshell
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
            if (dev.networks && dev.networks.values !== undefined) return dev;
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

    readonly property bool isWiredConnected: wiredDevice?.hasLink ?? false
    readonly property bool isWifiConnected: connectedWifi !== null && (connectedWifi.connected ?? true)
    readonly property bool isConnected: isWiredConnected || isWifiConnected

    readonly property string activeSsid: {
        if (isWiredConnected) return "Ethernet";
        if (connectedWifi?.name) return connectedWifi.name;
        if (wifiDevice?.networks) {
            for (const net of wifiDevice.networks.values) {
                if (net.connected && net.name) return net.name;
            }
        }
        return isConnected ? "Connected" : "Disconnected";
    }

    readonly property int signalStrength: {
        if (isWiredConnected) return 100;
        if (!connectedWifi) return 0;

        // converting 0.0-1.0 float to 0-100 percentage
        const sig = connectedWifi.signalStrength ?? 0;
        return Math.round(sig <= 1.0 ? sig * 100 : sig);
    }

    function toggleWifi() {
        Networking.wifiEnabled = !Networking.wifiEnabled;
    }

    function rescan() {
        // tell networkmanager to stop sleeping
        if (wifiDevice) {
            wifiDevice.scannerEnabled = true;
        }
    }

    Component.onCompleted: {
        if (wifiDevice) {
            wifiDevice.scannerEnabled = true;
        }
    }
}
