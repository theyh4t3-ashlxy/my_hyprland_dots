import QtQuick
import QtQuick.Layouts
import ".."
import "../controls"
import Quickshell

Item {
    id: root

    property string searchQuery: ""
    property string activeCategory: "all"
    property int itemHeight: 40

    implicitWidth: 440
    implicitHeight: 520

    readonly property var allBinds: [
        // Shell & Desktop (qs-action)
        { keys: ["WIN", "D"], desc: "Toggle App Launcher", category: "shell", action: "qs-action launcher" },
        { keys: ["WIN", "N"], desc: "Toggle Notification Center", category: "shell", action: "qs-action notifs" },
        { keys: ["WIN", "V"], desc: "Toggle Clipboard History", category: "shell", action: "qs-action clipboard" },
        { keys: ["WIN", "W"], desc: "Toggle Wallpaper Browser", category: "shell", action: "qs-action wallpaper" },
        { keys: ["WIN", "A"], desc: "Toggle Audio & Volume Menu", category: "shell", action: "qs-action audio" },
        { keys: ["WIN", "ESCAPE"], desc: "Toggle Power Menu", category: "shell", action: "qs-action powermenu" },
        { keys: ["WIN", "END"], desc: "Lock Session", category: "shell", action: "qs-action lock" },
        { keys: ["WIN", "SHIFT", "END"], desc: "Log Out / Stop Session", category: "shell", action: "uwsm stop" },
        { keys: ["Print"], desc: "Capture Screenshot (Interactive)", category: "shell", action: "qs-action screenshot" },

        // Window Management
        { keys: ["WIN", "Q"], desc: "Close Active Window", category: "windows", action: "hl.dsp.window.close()" },
        { keys: ["WIN", "T"], desc: "Launch Terminal (Kitty)", category: "windows", action: "uwsm app -- kitty" },
        { keys: ["WIN", "F"], desc: "Toggle Fullscreen", category: "windows", action: "hl.dsp.window.fullscreen()" },
        { keys: ["WIN", "SPACE"], desc: "Toggle Floating Window", category: "windows", action: "hl.dsp.window.float()" },
        { keys: ["WIN", "SHIFT", "SPACE"], desc: "Sticky PIP Mode (Float + Pin)", category: "windows", action: "synchronized float+pin" },

        // Navigation (IJKL)
        { keys: ["WIN", "I"], desc: "Focus Window Up", category: "navigation", action: "focus up" },
        { keys: ["WIN", "K"], desc: "Focus Window Down", category: "navigation", action: "focus down" },
        { keys: ["WIN", "J"], desc: "Focus Window Left", category: "navigation", action: "focus left" },
        { keys: ["WIN", "L"], desc: "Focus Window Right", category: "navigation", action: "focus right" },
        { keys: ["WIN", "SHIFT", "I"], desc: "Swap Window Up", category: "navigation", action: "swap up" },
        { keys: ["WIN", "SHIFT", "K"], desc: "Swap Window Down", category: "navigation", action: "swap down" },
        { keys: ["WIN", "SHIFT", "J"], desc: "Swap Window Left", category: "navigation", action: "swap left" },
        { keys: ["WIN", "SHIFT", "L"], desc: "Swap Window Right", category: "navigation", action: "swap right" },
        { keys: ["WIN", "L-Click"], desc: "Drag / Move Window", category: "navigation", action: "mouse:272" },
        { keys: ["WIN", "R-Click"], desc: "Resize Window", category: "navigation", action: "mouse:273" },

        // Workspaces
        { keys: ["WIN", "1..0"], desc: "Switch to Workspace 1-10", category: "workspaces", action: "focus workspace" },
        { keys: ["WIN", "SHIFT", "1..0"], desc: "Move Window to Workspace 1-10", category: "workspaces", action: "movetoworkspace" },

        // Hardware Controls
        { keys: ["Vol Up / Down"], desc: "Adjust System Volume (5%)", category: "hardware", action: "wpctl set-volume" },
        { keys: ["Brightness ±"], desc: "Adjust Display Backlight (5%)", category: "hardware", action: "brightnessctl" },
        { keys: ["Mute / MicMute"], desc: "Toggle Output / Input Mute", category: "hardware", action: "wpctl set-mute" },
        { keys: ["WLAN"], desc: "Toggle Wi-Fi Radio", category: "hardware", action: "nmcli radio wifi" },
        { keys: ["Media Play"], desc: "Play / Pause Active Player", category: "hardware", action: "playerctl play-pause" }
    ]

    readonly property var filteredBinds: {
        const q = (root.searchQuery ?? "").toLowerCase().trim();
        const cat = root.activeCategory;

        return allBinds.filter(item => {
            if (cat !== "all" && item.category !== cat) return false;
            if (q === "") return true;

            const matchesDesc = (item.desc ?? "").toLowerCase().includes(q);
            const matchesAction = (item.action ?? "").toLowerCase().includes(q);
            const matchesKey = item.keys && item.keys.some(k => k.toLowerCase().includes(q));

            return matchesDesc || matchesAction || matchesKey;
        });
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        // Header Title & Search Bar
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Rectangle {
                Layout.fillWidth: true
                height: 36
                radius: Theme.widgetRadius
                color: Theme.surface_container_low
                border.width: 1
                border.color: searchInput.activeFocus ? Theme.primary : Theme.outline_variant

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: 6

                    Text {
                        text: Theme.iconSearch
                        font.family: Theme.fontIcon
                        font.pixelSize: Theme.fontSizeSm
                        color: searchInput.activeFocus ? Theme.primary : Theme.on_surface_variant
                    }

                    TextInput {
                        id: searchInput
                        Layout.fillWidth: true
                        font.family: Theme.fontSans
                        font.pixelSize: Theme.fontSizeSm
                        color: Theme.on_surface
                        clip: true
                        selectByMouse: true
                        text: root.searchQuery
                        onTextChanged: root.searchQuery = text

                        Text {
                            visible: parent.text === "" && !parent.activeFocus
                            text: "Search keybinds, actions, or keys..."
                            font.family: Theme.fontSans
                            font.pixelSize: Theme.fontSizeSm
                            color: Theme.on_surface_variant
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    IconButton {
                        visible: searchInput.text !== ""
                        icon: Theme.iconClose
                        iconSize: Theme.fontSizeXs
                        implicitWidth: 20
                        implicitHeight: 20
                        onClicked: {
                            searchInput.text = "";
                            root.searchQuery = "";
                        }
                    }
                }
            }

            Rectangle {
                implicitWidth: countText.implicitWidth + 14
                height: 36
                radius: Theme.widgetRadius
                color: Theme.surface_container_high

                Text {
                    id: countText
                    anchors.centerIn: parent
                    text: root.filteredBinds.length + " binds"
                    font.family: Theme.fontMono
                    font.pixelSize: Theme.fontSizeXs
                    font.weight: Font.DemiBold
                    color: Theme.primary
                }
            }
        }

        // Category Filter Chips (Horizontal Scrollable)
        Flickable {
            Layout.fillWidth: true
            height: 32
            contentWidth: catRow.implicitWidth
            flickableDirection: Flickable.HorizontalFlick
            boundsBehavior: Flickable.StopAtBounds
            clip: true

            WheelHandler {
                orientation: Qt.Vertical
                onWheel: (event) => {
                    const delta = event.angleDelta.y !== 0 ? event.angleDelta.y : event.angleDelta.x;
                    parent.contentX = Math.max(0, Math.min(parent.contentWidth - parent.width, parent.contentX - delta));
                }
            }

            RowLayout {
                id: catRow
                spacing: 6

                Repeater {
                    model: [
                        { id: "all", label: "All" },
                        { id: "shell", label: "Shell & Desktop" },
                        { id: "windows", label: "Windows" },
                        { id: "navigation", label: "IJKL Nav" },
                        { id: "workspaces", label: "Workspaces" },
                        { id: "hardware", label: "Hardware" }
                    ]

                    delegate: Rectangle {
                        required property var modelData
                        readonly property bool isSelected: root.activeCategory === modelData.id

                        implicitWidth: catLabel.implicitWidth + 16
                        height: 28
                        radius: Theme.radiusPill
                        color: isSelected ? Theme.primary_container : (catMouse.containsMouse ? Theme.surface_container_high : Theme.surface_container_low)
                        border.width: 1
                        border.color: isSelected ? Theme.primary : "transparent"

                        Behavior on color { ColorAnimation { duration: Theme.animFast } }

                        Text {
                            id: catLabel
                            anchors.centerIn: parent
                            text: modelData.label
                            font.family: Theme.fontSans
                            font.pixelSize: Theme.fontSizeXs
                            font.weight: isSelected ? Font.DemiBold : Font.Normal
                            color: isSelected ? Theme.on_primary_container : Theme.on_surface
                        }

                        MouseArea {
                            id: catMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.activeCategory = modelData.id
                        }
                    }
                }
            }
        }

        // Keybinds Cards List
        Flickable {
            id: bindsFlick
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentHeight: bindsCol.implicitHeight
            flickableDirection: Flickable.VerticalFlick
            boundsBehavior: Flickable.StopAtBounds
            clip: true

            WheelHandler {
                orientation: Qt.Vertical
                onWheel: (event) => {
                    const step = 48 * 2;
                    const delta = event.angleDelta.y > 0 ? -step : step;
                    parent.contentY = Math.max(0, Math.min(parent.contentHeight - parent.height, parent.contentY + delta));
                }
            }

            Column {
                id: bindsCol
                width: bindsFlick.width - (scrollTrack.visible ? 6 : 0)
                spacing: 6

                Repeater {
                    model: root.filteredBinds

                    delegate: Rectangle {
                        id: bindCard
                        required property var modelData

                        width: bindsCol.width
                        height: 48
                        radius: Theme.widgetRadius
                        color: cardMouse.containsMouse ? Theme.surface_container_high : Theme.surface_container_low
                        border.width: 1
                        border.color: cardMouse.containsMouse ? Theme.outline : Theme.outline_variant

                        Behavior on color { ColorAnimation { duration: Theme.animFast } }
                        Behavior on border.color { ColorAnimation { duration: Theme.animFast } }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 10

                            // Action & Description
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.desc
                                    font.family: Theme.fontSans
                                    font.pixelSize: Theme.fontSizeSm
                                    font.weight: Font.Medium
                                    color: Theme.on_surface
                                    elide: Text.ElideRight
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.action
                                    font.family: Theme.fontMono
                                    font.pixelSize: Theme.fontSizeXs
                                    color: Theme.on_surface_variant
                                    elide: Text.ElideRight
                                }
                            }

                            // Keycap Badges (<kbd> style)
                            Row {
                                spacing: 4

                                Repeater {
                                    model: modelData.keys ?? []

                                    delegate: Rectangle {
                                        required property string modelData
                                        implicitWidth: kbdText.implicitWidth + 10
                                        height: 24
                                        radius: 4
                                        color: Theme.surface_container_highest
                                        border.width: 1
                                        border.color: Theme.outline_variant

                                        Text {
                                            id: kbdText
                                            anchors.centerIn: parent
                                            text: modelData
                                            font.family: Theme.fontMono
                                            font.pixelSize: Theme.fontSizeXs
                                            font.weight: Font.Bold
                                            color: modelData === "WIN" ? Theme.primary : Theme.on_surface
                                        }
                                    }
                                }
                            }
                        }

                        MouseArea {
                            id: cardMouse
                            anchors.fill: parent
                            hoverEnabled: true
                        }
                    }
                }

                // Empty state if nothing matches
                Rectangle {
                    visible: root.filteredBinds.length === 0
                    width: bindsCol.width
                    height: 120
                    radius: Theme.widgetRadius
                    color: "transparent"

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 6

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: Theme.iconSearch
                            font.family: Theme.fontIcon
                            font.pixelSize: Theme.fontSizeXl
                            color: Theme.on_surface_variant
                        }

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "No keybinds match \"" + root.searchQuery + "\""
                            font.family: Theme.fontSans
                            font.pixelSize: Theme.fontSizeSm
                            color: Theme.on_surface_variant
                        }
                    }
                }
            }

            Rectangle {
                id: scrollTrack
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.margins: 2
                width: 3
                radius: 1.5
                color: "transparent"
                visible: bindsFlick.visibleArea.heightRatio < 1.0

                Rectangle {
                    width: parent.width
                    readonly property real trackH: scrollTrack.height
                    readonly property real thumbH: Math.max(16, Math.min(trackH, bindsFlick.visibleArea.heightRatio * trackH))
                    height: thumbH
                    y: Math.max(0, Math.min(trackH - thumbH, bindsFlick.visibleArea.yPosition * trackH))
                    radius: 1.5
                    color: Theme.primary_overlay
                }
            }
        }
    }
}
