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

    // finding actual card without duck typing like a maniac
    readonly property WifiDevice wifiDevice: {
        if (!Networking.devices) return null;
        for (const dev of Networking.devices.values) {
            if (dev.type === DeviceType.Wifi) return dev;
        }
        return null;
    }

    readonly property WiredDevice wiredDevice: {
        if (!Networking.devices) return null;
        for (const dev of Networking.devices.values) {
            if (dev.type === DeviceType.Wired) return dev;
        }
        return null;
    }

    // access point beaming photons into my head
    readonly property WifiNetwork connectedWifi: wifiDevice?.network ?? null

    readonly property bool isWiredConnected: wiredDevice?.hasLink ?? false
    readonly property bool isWifiConnected: connectedWifi !== null && (connectedWifi.connected ?? true)
    readonly property bool isConnected: isWiredConnected || isWifiConnected

    readonly property string activeSsid: {
        if (isWiredConnected) return "Ethernet";
        if (connectedWifi?.name) return connectedWifi.name;
        return isConnected ? "Online" : "Disconnected";
    }

    readonly property int signalStrength: {
        if (isWiredConnected) return 100;
        if (!connectedWifi) return 0;

        // actual math instead of guessing 85%
        const sig = connectedWifi.signalStrength ?? 0;
        return Math.round(sig <= 1.0 ? sig * 100 : sig);
    }

    function toggleWifi() {
        Networking.wifiEnabled = !Networking.wifiEnabled;
    }

    function rescan() {
        // wake up babe new ap dropped
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
