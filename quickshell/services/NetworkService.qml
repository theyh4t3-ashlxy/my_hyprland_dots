pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Networking

QtObject {
    id: root

    // qml aliases hate singletons so we do this instead
    property bool wifiEnabled: Networking.wifiEnabled
    onWifiEnabledChanged: {
        if (Networking.wifiEnabled !== wifiEnabled) {
            Networking.wifiEnabled = wifiEnabled;
        }
    }

    readonly property WifiDevice wifiDevice: {
        for (const dev of Networking.devices.values) {
            if (dev.deviceType === DeviceType.Wifi) return dev;
        }
        return null;
    }

    readonly property WiredDevice wiredDevice: {
        for (const dev of Networking.devices.values) {
            if (dev.deviceType === DeviceType.Wired) return dev;
        }
        return null;
    }

    // don't wake me if we are offline
    readonly property WifiNetwork connectedWifi: wifiDevice?.network ?? null

    readonly property bool isWiredConnected: wiredDevice?.hasLink ?? false
    readonly property bool isWifiConnected: connectedWifi !== null && connectedWifi.connected
    readonly property bool isConnected: isWiredConnected || isWifiConnected

    readonly property string activeSsid: {
        if (isWiredConnected) return "Ethernet";
        if (connectedWifi?.name) return connectedWifi.name;
        return isConnected ? "Online" : "Disconnected";
    }

    readonly property int signalStrength: {
        if (isWiredConnected) return 100;
        if (!connectedWifi) return 0;

        // brain math
        return Math.round((connectedWifi.signalStrength ?? 0) * 100);
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
