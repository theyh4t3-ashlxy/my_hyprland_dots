import QtQuick
import QtQuick.Layouts
import ".."
import Quickshell

Rectangle {
    id: root

    required property var modelData
    readonly property bool isConnected: modelData.connected || false
    readonly property string networkName: modelData.name || "hidden network"
    readonly property real signal: modelData.signalStrength || 0
    readonly property bool isSecured: (modelData.security !== undefined && modelData.security !== 0) || (modelData.flags !== undefined && modelData.flags > 0)

    property bool isExpanded: false

    width: parent.width
    implicitHeight: isExpanded ? 88 : 46
    color: root.isConnected ? Theme.primary_overlay : (netEntryMouse.containsMouse ? Theme.surface_container_highest : Theme.surface_container_low)
    radius: Theme.radiusMd
    border.color: root.isConnected ? Theme.primary : (root.isExpanded ? Theme.primary : "transparent")
    border.width: 1
    clip: true

    Behavior on implicitHeight { NumberAnimation { duration: Theme.animFast; easing.type: Theme.animEasing } }
    Behavior on color { ColorAnimation { duration: Theme.animFast } }
    Behavior on border.color { ColorAnimation { duration: Theme.animFast } }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 6

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                text: root.isConnected ? Theme.iconWifiHigh : (root.signal > 0.65 ? Theme.iconWifiHigh : root.signal > 0.35 ? Theme.iconWifiMed : Theme.iconWifiLow)
                font.family: Theme.fontMono
                font.pixelSize: Theme.fontSizeMd
                color: root.isConnected ? Theme.primary : Theme.on_surface
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                Text {
                    text: root.networkName
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSm
                    font.weight: root.isConnected ? Font.Bold : Font.Medium
                    color: root.isConnected ? Theme.primary : Theme.on_surface
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                RowLayout {
                    spacing: 4
                    Text {
                        text: root.isConnected ? "connected" : (Math.round(root.signal <= 1.0 ? root.signal * 100 : root.signal) + "% signal")
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                        color: Theme.on_surface_variant
                    }
                    Text {
                        text: "• secured "
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                        color: Theme.on_surface_variant
                        visible: root.isSecured && !root.isConnected
                    }
                }
            }

            IconButton {
                icon: root.isConnected ? Theme.iconClose : (root.isExpanded ? Theme.iconChevronUp : Theme.iconChevronDown)
                iconSize: Theme.fontSizeXs
                tooltip: root.isConnected ? "disconnect" : (root.isExpanded ? "collapse" : "options")
                onClicked: {
                    if (root.isConnected) {
                        if (root.modelData.disconnect) root.modelData.disconnect();
                        else Quickshell.execDetached(["nmcli", "dev", "disconnect", "iface", "wlan0"]);
                    } else {
                        root.isExpanded = !root.isExpanded;
                    }
                }
            }
        }

        // Password input drawer (when expanded)
        RowLayout {
            Layout.fillWidth: true
            spacing: 6
            visible: root.isExpanded && !root.isConnected

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
                    echoMode: TextInput.Password
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeXs
                    color: Theme.on_surface

                    Text {
                        anchors.fill: parent
                        verticalAlignment: Text.AlignVCenter
                        text: "enter wi-fi password..."
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeXs
                        color: Theme.on_surface_disabled
                        visible: pwdInput.text === "" && !pwdInput.activeFocus
                    }

                    onAccepted: connectBtnMouse.clicked(null)
                }
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
                        if (pwdInput.text.trim() !== "") {
                            Quickshell.execDetached(["nmcli", "dev", "wifi", "connect", root.networkName, "password", pwdInput.text.trim()]);
                        } else {
                            if (root.modelData.connect) root.modelData.connect();
                            else Quickshell.execDetached(["nmcli", "dev", "wifi", "connect", root.networkName]);
                        }
                        root.isExpanded = false;
                    }
                }
            }
        }
    }

    MouseArea {
        id: netEntryMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        z: -1
        onClicked: {
            if (root.isConnected) {
                if (root.modelData.disconnect) root.modelData.disconnect();
            } else {
                root.isExpanded = !root.isExpanded;
            }
        }
    }
}
