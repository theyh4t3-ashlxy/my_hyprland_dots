import QtQuick
import QtQuick.Layouts
import ".."
import "../services"
import Quickshell
import Quickshell.Networking

Rectangle {
    id: root

    implicitWidth: Theme.isVertical ? Theme.barHeight - 8 : (netRow.implicitWidth + 24)
    implicitHeight: Theme.barHeight - 8
    radius: Theme.radiusPill
    color: popup.open ? Theme.primary_overlay : (netMouse.containsMouse ? Theme.pillHover : Theme.pillBg)
    border.color: Theme.pillBorder
    border.width: Theme.pillBorder === "transparent" ? 0 : 1

    Behavior on color { ColorAnimation { duration: Theme.animFast } }
    Behavior on border.color { ColorAnimation { duration: Theme.animFast } }
    Behavior on implicitWidth { NumberAnimation { duration: Theme.animFast; easing.type: Theme.animEasing } }

    readonly property string activeSsidLower: (NetworkService.activeSsid || "").toLowerCase()
    readonly property string netIcon: Theme.getWifiIcon(
        NetworkService.signalStrength,
        NetworkService.wifiEnabled && NetworkService.isWifiConnected,
        NetworkService.isWiredConnected
    )

    function updatePopupPosition() {
        let pt = root.mapToItem(null, 0, 0);
        if (!pt) return;
        if (Theme.isVertical) {
            popup.targetRelativeY = pt.y + (root.height / 2);
        } else {
            popup.targetRelativeX = pt.x + (root.width / 2);
        }
    }

    function togglePopup() {
        updatePopupPosition();
        popup.open = !popup.open;
        if (popup.open) NetworkService.rescan();
    }

    function getConnectionText() {
        if (!NetworkService.isConnected) return Theme.getFlavor("network_off", "disconnected • offline");
        if (NetworkService.isWiredConnected) return Theme.getFlavor("network_on", "wired gigabit • connected");
        
        let txt = "connected • " + NetworkService.signalStrength + "% signal";
        if (NetworkService.rawActiveSsid !== NetworkService.activeSsid) {
            txt += " (" + NetworkService.rawActiveSsid + ")";
        }
        return Theme.getFlavor("network_on", txt);
    }

    function formatSignal(sig) {
        return Math.round(sig <= 1.0 ? sig * 100 : sig) + "% signal";
    }

    Row {
        id: netRow
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: Theme.isVertical ? undefined : parent.left
        anchors.leftMargin: Theme.isVertical ? 0 : 12
        anchors.horizontalCenter: Theme.isVertical ? parent.horizontalCenter : undefined
        spacing: 6

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.netIcon
            font.family: Theme.fontIcon
            font.pixelSize: Theme.fontSizeMd
            color: NetworkService.isConnected ? Theme.primary : Theme.on_surface
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: !Theme.isVertical && netMouse.containsMouse
            text: root.activeSsidLower
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeXs
            font.weight: Font.Medium
            color: NetworkService.isConnected ? Theme.primary : Theme.on_surface_variant
            elide: Text.ElideRight
            maximumLineCount: 1
            width: Math.min(implicitWidth, 140)
        }
    }

    MouseArea {
        id: netMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.togglePopup()
    }

    Connections {
        target: Settings
        function onRequestNetworkToggle() { root.togglePopup(); }
        function onRequestNetworkOpen() {
            root.updatePopupPosition();
            popup.open = true;
            NetworkService.rescan();
        }
        function onRequestNetworkClose() { popup.open = false; }
    }

    PopupPanel {
        id: popup
        cardWidth: 420
        cardHeight: 500

        readonly property var wifiNetworks: NetworkService.wifiDevice?.networks?.values ?? []
        readonly property int wifiNetworkCount: wifiNetworks.length

        content: ColumnLayout {
            anchors.fill: parent
            spacing: Theme.widgetSpacing

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: "network & wi-fi"
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeLg
                    font.weight: Font.Bold
                    color: Theme.on_surface
                    Layout.fillWidth: true
                }

                IconButton {
                    icon: Theme.iconRefresh
                    iconSize: Theme.fontSizeMd
                    tooltip: "rescan wireless networks"
                    onClicked: NetworkService.rescan()
                }

                IconButton {
                    icon: Theme.iconTerminal
                    iconSize: Theme.fontSizeSm
                    tooltip: "launch nmtui connection manager"
                    onClicked: {
                        Quickshell.execDetached(["kitty", "-e", "nmtui"]);
                        popup.open = false;
                    }
                }

                ToggleSwitch {
                    checked: NetworkService.wifiEnabled
                    onToggled: NetworkService.toggleWifi()
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Theme.widgetBorder
            }

            Rectangle {
                id: activeCard
                Layout.fillWidth: true
                implicitHeight: isRenamingActive ? 64 : 56
                color: NetworkService.isConnected ? Theme.primary_overlay : Theme.surface_container_highest
                radius: Theme.radiusMd
                border.color: NetworkService.isConnected ? Theme.primary : Theme.widgetBorder
                border.width: 1

                property bool isRenamingActive: false

                Behavior on implicitHeight { NumberAnimation { duration: Theme.animFast; easing.type: Theme.animEasing } }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 12
                    visible: !activeCard.isRenamingActive

                    Text {
                        text: NetworkService.isWiredConnected ? Theme.iconEthernet : (NetworkService.isWifiConnected ? Theme.iconWifiHigh : Theme.iconWifiOff)
                        font.family: Theme.fontIcon
                        font.pixelSize: 24
                        color: NetworkService.isConnected ? Theme.primary : Theme.on_surface_variant
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        RowLayout {
                            spacing: 6
                            Layout.fillWidth: true

                            Text {
                                text: root.activeSsidLower
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeSm
                                font.weight: Font.Bold
                                color: NetworkService.isConnected ? Theme.primary : Theme.on_surface
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }

                            IconButton {
                                visible: NetworkService.isConnected
                                icon: Theme.iconEdit
                                iconSize: 10
                                tooltip: "rename display name"
                                onClicked: {
                                    aliasEditInput.text = Settings.getNetworkAlias(NetworkService.rawActiveSsid);
                                    activeCard.isRenamingActive = true;
                                    aliasEditInput.forceActiveFocus();
                                }
                            }
                        }

                        Text {
                            text: root.getConnectionText()
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                            color: Theme.on_surface_variant
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }

                    Rectangle {
                        visible: NetworkService.isWifiConnected
                        width: 78
                        height: 28
                        radius: Theme.radiusSm
                        color: discMouse.containsMouse ? Theme.error_overlay : Theme.surface_container_high
                        border.color: discMouse.containsMouse ? Theme.error : "transparent"
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: "disconnect"
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                            font.weight: Font.Medium
                            color: discMouse.containsMouse ? Theme.error : Theme.on_surface_variant
                        }

                        MouseArea {
                            id: discMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                const iface = NetworkService.wifiDevice?.name;
                                if (iface) {
                                    Quickshell.execDetached(["nmcli", "dev", "disconnect", "iface", iface]);
                                }
                            }
                        }
                    }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 6
                    visible: activeCard.isRenamingActive

                    Rectangle {
                        Layout.fillWidth: true
                        height: 32
                        radius: Theme.radiusSm
                        color: Theme.surface_container_highest
                        border.color: aliasEditInput.activeFocus ? Theme.primary : Theme.widgetBorder
                        border.width: 1

                        TextInput {
                            id: aliasEditInput
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            verticalAlignment: TextInput.AlignVCenter
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeXs
                            color: Theme.on_surface
                            selectByMouse: true
                            
                            onAccepted: {
                                Settings.setNetworkAlias(NetworkService.rawActiveSsid, text);
                                activeCard.isRenamingActive = false;
                            }
                        }
                    }

                    IconButton {
                        icon: Theme.iconCheck
                        iconSize: Theme.fontSizeXs
                        tooltip: "save local display name"
                        onClicked: {
                            Settings.setNetworkAlias(NetworkService.rawActiveSsid, aliasEditInput.text);
                            activeCard.isRenamingActive = false;
                        }
                    }

                    IconButton {
                        icon: Theme.iconTrash
                        iconSize: Theme.fontSizeXs
                        tooltip: "reset to real ssid"
                        onClicked: {
                            Settings.setNetworkAlias(NetworkService.rawActiveSsid, "");
                            activeCard.isRenamingActive = false;
                        }
                    }

                    IconButton {
                        icon: Theme.iconClose
                        iconSize: Theme.fontSizeXs
                        tooltip: "cancel"
                        onClicked: activeCard.isRenamingActive = false
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                visible: NetworkService.wifiEnabled && popup.wifiNetworkCount > 0
                spacing: 6

                Text {
                    text: "available wireless networks (" + popup.wifiNetworkCount + ")"
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeXs
                    font.weight: Font.Bold
                    color: Theme.primary
                    Layout.fillWidth: true
                }
            }

            ListView {
                id: netList
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: 6
                boundsBehavior: Flickable.StopAtBounds
                visible: NetworkService.wifiEnabled && popup.wifiNetworkCount > 0
                model: NetworkService.wifiEnabled ? popup.wifiNetworks : []

                delegate: Rectangle {
                    id: netItem
                    required property var modelData
                    readonly property bool isItemConnected: modelData.connected || false
                    readonly property string networkName: modelData.name || ""
                    readonly property real signal: modelData.signalStrength || 0
                    readonly property bool isSecured: (modelData.security !== undefined && modelData.security !== 0) || (modelData.flags !== undefined && modelData.flags > 0)
                    
                    readonly property string aliasName: Settings.getNetworkAlias(networkName)
                    readonly property string displayName: (aliasName !== "" ? aliasName : (networkName !== "" ? networkName : "hidden network")).toLowerCase()
                    readonly property string rawHint: (aliasName !== "" && aliasName !== networkName) ? ("raw: " + networkName.toLowerCase() + " • ") : ""

                    property bool isExpanded: false

                    width: netList.width
                    height: isExpanded ? 92 : 48
                    color: isItemConnected ? Theme.primary_overlay : (itemHover.containsMouse ? Theme.surface_container_highest : Theme.surface_container_low)
                    radius: Theme.radiusMd
                    border.color: isItemConnected ? Theme.primary : (netItem.isExpanded ? Theme.primary : "transparent")
                    border.width: 1
                    clip: true

                    Behavior on height { NumberAnimation { duration: Theme.animFast; easing.type: Theme.animEasing } }
                    Behavior on color { ColorAnimation { duration: Theme.animFast } }
                    Behavior on border.color { ColorAnimation { duration: Theme.animFast } }

                    onIsExpandedChanged: {
                        if (isExpanded && !isItemConnected) {
                            pwdInput.forceActiveFocus();
                        }
                    }

                    MouseArea {
                        id: itemHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (!netItem.isItemConnected) {
                                netItem.isExpanded = !netItem.isExpanded;
                            }
                        }
                    }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 6

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Text {
                                text: netItem.isItemConnected ? Theme.iconWifiHigh : (netItem.signal > 0.65 ? Theme.iconWifiHigh : netItem.signal > 0.35 ? Theme.iconWifiMed : Theme.iconWifiLow)
                                font.family: Theme.fontIcon
                                font.pixelSize: Theme.fontSizeMd
                                color: netItem.isItemConnected ? Theme.primary : Theme.on_surface
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 1

                                Text {
                                    text: netItem.displayName
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSizeSm
                                    font.weight: netItem.isItemConnected ? Font.Bold : Font.Medium
                                    color: netItem.isItemConnected ? Theme.primary : Theme.on_surface
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }

                                RowLayout {
                                    spacing: 4
                                    Text {
                                        text: netItem.rawHint + (netItem.isItemConnected ? "active connection" : root.formatSignal(netItem.signal))
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 10
                                        color: Theme.on_surface_variant
                                    }
                                    Text {
                                        text: "• secured"
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 10
                                        color: Theme.on_surface_variant
                                        visible: netItem.isSecured && !netItem.isItemConnected
                                    }
                                    Text {
                                        text: Theme.iconLock
                                        font.family: Theme.fontIcon
                                        font.pixelSize: 10
                                        color: Theme.on_surface_variant
                                        visible: netItem.isSecured && !netItem.isItemConnected
                                    }
                                }
                            }

                            IconButton {
                                icon: netItem.isItemConnected ? Theme.iconClose : (netItem.isExpanded ? Theme.iconChevronUp : Theme.iconChevronDown)
                                iconSize: Theme.fontSizeXs
                                tooltip: netItem.isItemConnected ? "disconnect" : (netItem.isExpanded ? "collapse" : "options")
                                onClicked: {
                                    if (netItem.isItemConnected) {
                                        const iface = NetworkService.wifiDevice?.name;
                                        if (iface) Quickshell.execDetached(["nmcli", "dev", "disconnect", "iface", iface]);
                                    } else {
                                        netItem.isExpanded = !netItem.isExpanded;
                                    }
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 6
                            visible: netItem.isExpanded && !netItem.isItemConnected

                            Rectangle {
                                Layout.fillWidth: true
                                height: 30
                                radius: Theme.radiusSm
                                color: Theme.surface_container_highest
                                border.color: pwdInput.activeFocus ? Theme.primary : Theme.widgetBorder
                                border.width: 1

                                TextInput {
                                    id: pwdInput
                                    anchors.fill: parent
                                    anchors.leftMargin: 8
                                    anchors.rightMargin: 8
                                    verticalAlignment: TextInput.AlignVCenter
                                    echoMode: showPwdBtn.showPassword ? TextInput.Normal : TextInput.Password
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSizeXs
                                    color: Theme.on_surface
                                    selectByMouse: true

                                    Text {
                                        anchors.fill: parent
                                        verticalAlignment: Text.AlignVCenter
                                        text: "enter wi-fi password..."
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.fontSizeXs
                                        color: Theme.on_surface_disabled
                                        visible: pwdInput.text === ""
                                    }

                                    onAccepted: connectBtnMouse.clicked(null)
                                }
                            }

                            IconButton {
                                id: showPwdBtn
                                property bool showPassword: false
                                icon: showPassword ? Theme.iconEyeOff : Theme.iconEye
                                iconSize: Theme.fontSizeXs
                                tooltip: showPassword ? "hide password" : "show password"
                                onClicked: showPassword = !showPassword
                            }

                            Rectangle {
                                width: 72
                                height: 30
                                radius: Theme.radiusSm
                                color: connectBtnMouse.containsMouse ? Theme.primary_overlay : Theme.primary

                                Text {
                                    anchors.centerIn: parent
                                    text: "connect"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSizeXs
                                    font.weight: Font.Bold
                                    color: connectBtnMouse.containsMouse ? Theme.primary : Theme.on_primary
                                }

                                MouseArea {
                                    id: connectBtnMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        const target = netItem.networkName;
                                        if (target === "") return;

                                        if (pwdInput.text.trim() !== "") {
                                            Quickshell.execDetached(["nmcli", "dev", "wifi", "connect", target, "password", pwdInput.text.trim()]);
                                        } else {
                                            Quickshell.execDetached(["nmcli", "dev", "wifi", "connect", target]);
                                        }
                                        netItem.isExpanded = false;
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: !NetworkService.wifiEnabled || popup.wifiNetworkCount === 0

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 8

                    Text {
                        text: !NetworkService.wifiEnabled ? Theme.iconWifiOff : Theme.iconWifi
                        font.family: Theme.fontIcon
                        font.pixelSize: 32
                        color: Theme.primary
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Text {
                        text: !NetworkService.wifiEnabled ? "wi-fi is turned off" : "scanning for wireless networks..."
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeSm
                        font.weight: Font.Bold
                        color: Theme.on_surface
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Text {
                        text: !NetworkService.wifiEnabled ? "toggle the switch above to enable wi-fi" : "searching for local ssids in range..."
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                        color: Theme.on_surface_variant
                        Layout.alignment: Qt.AlignHCenter
                    }
                }
            }
        }
    }
}
