pragma Singleton
import QtQuick
import ".."
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

    // quickshell dbus model is lazy as hell unless you listen to it
    property var _deviceList: []
    property var _networkList: []

    property Connections devConn: Connections {
        target: Networking.devices
        function onValuesChanged() {
            root._deviceList = Networking.devices ? Networking.devices.values : [];
        }
    }

    // finding actual card without duck typing like a maniac
    readonly property WifiDevice wifiDevice: {
        for (let i = 0; i < _deviceList.length; i++) {
            if (_deviceList[i].type === DeviceType.Wifi) return _deviceList[i];
        }
        return null;
    }

    onWifiDeviceChanged: {
        if (wifiDevice) {
            wifiDevice.scannerEnabled = true;
            root._networkList = wifiDevice.networks ? wifiDevice.networks.values : [];
        }
    }

    readonly property WiredDevice wiredDevice: {
        for (let i = 0; i < _deviceList.length; i++) {
            if (_deviceList[i].type === DeviceType.Wired) return _deviceList[i];
        }
        return null;
    }

    property Connections netConn: Connections {
        target: root.wifiDevice ? root.wifiDevice.networks : null
        function onValuesChanged() {
            root._networkList = (root.wifiDevice && root.wifiDevice.networks) ? root.wifiDevice.networks.values : [];
        }
    }

    // access point beaming photons into my head
    readonly property var connectedWifi: {
        for (let i = 0; i < _networkList.length; i++) {
            if (_networkList[i].connected) return _networkList[i];
        }
        return null;
    }

    readonly property bool isWiredConnected: wiredDevice?.hasLink ?? false
    readonly property bool isWifiConnected: (wifiDevice?.connected ?? false) || (connectedWifi !== null)
    readonly property bool isConnected: isWiredConnected || isWifiConnected

    readonly property string rawActiveSsid: {
        if (isWiredConnected) return "Ethernet";
        if (connectedWifi?.name) return connectedWifi.name;
        if (connectedWifi?.ssid) return connectedWifi.ssid;
        if (isWifiConnected) return "Wi-Fi";
        return isConnected ? "Online" : "Disconnected";
    }

    readonly property string activeSsid: {
        if (!isConnected) return "Disconnected";
        return Settings.getNetworkAlias(rawActiveSsid);
    }

    readonly property int signalStrength: {
        if (isWiredConnected) return 100;
        if (!connectedWifi) return (isWifiConnected ? 70 : 0);

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
        root._deviceList = Networking.devices ? Networking.devices.values : [];
        if (wifiDevice) {
            wifiDevice.scannerEnabled = true;
            root._networkList = wifiDevice.networks ? wifiDevice.networks.values : [];
        }
    }
}
