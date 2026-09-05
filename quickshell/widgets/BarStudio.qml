import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."
import "../controls"
import "../corners"

PopupPanel {
    id: root

    required property var modelData
    screen: modelData

    cardWidth: Math.min(1080, (root.screen?.width ?? 1920) - 48)
    cardHeight: Math.min(460, (root.screen?.height ?? 1080) - Theme.barHeight - 32)
    targetRelativeX: (root.screen?.width ?? 1920) / 2
    open: Settings?.showBarStudio ?? false

    onOpenChanged: {
        if (!open) {
            if (Settings.showBarStudio) Settings.showBarStudio = false;
            if (Settings.showMotionSandbox) Settings.showMotionSandbox = false;
        }
    }

    // human readable module metadata
    function getModuleInfo(modId) {
        let meta = {
            "launcher":       { name: "app launcher",       icon: Theme.iconArch ?? "󰣇",     desc: "application search & grid" },
            "wallpaper":      { name: "wallpaper browser",  icon: Theme.iconWallpaper ?? "󰸉", desc: "swww & mpvpaper selector" },
            "workspaces":     { name: "workspaces",         icon: Theme.iconWorkspaces ?? "󰍹", desc: "hyprland workspace dots" },
            "windowTitle":    { name: "active window",      icon: Theme.iconSparkles ?? "󰄛", desc: "focused window title badge" },
            "clock":          { name: "clock & date",       icon: Theme.iconClock ?? "󰅐",    desc: "time, date & calendar" },
            "media":          { name: "media player",       icon: Theme.iconMusic ?? "󰝚",    desc: "mpris music controls" },
            "quickNotes":     { name: "quick notes",        icon: Theme.iconEdit ?? "󰏫",     desc: "floating scratchpad notes" },
            "clipboard":      { name: "clipboard manager",  icon: Theme.iconClipboard ?? "󰅌", desc: "cliphist history & sync" },
            "idleInhibitor":  { name: "idle inhibitor",     icon: Theme.iconCoffee ?? "󰅠",   desc: "stay awake toggle" },
            "notifications":  { name: "notifications",      icon: Theme.iconBell ?? "󰂙",     desc: "alert center & toast log" },
            "systemTray":     { name: "system tray",        icon: Theme.iconGrid ?? "󰕰",     desc: "statusnotifier tray icons" },
            "bluetooth":      { name: "bluetooth",          icon: Theme.iconBluetooth ?? "󰂯", desc: "bluetooth devices & scan" },
            "network":        { name: "network status",     icon: Theme.iconWifi ?? "󰤨",      desc: "wifi & ethernet monitor" },
            "volume":         { name: "volume & sink",      icon: Theme.iconVolHigh ?? "󰕾",  desc: "pipewire audio controls" },
            "battery":        { name: "battery & power",    icon: Theme.iconBatFull ?? "󰁹",  desc: "upower level & charging" },
            "quickSettings":  { name: "quick settings",     icon: Theme.iconSettings ?? "󰒓", desc: "system & appearance toggles" },
            "powerMenu":      { name: "power menu",         icon: Theme.iconPower ?? "󰐥",    desc: "lock, logout & power off" }
        };
        return meta[modId] ?? { name: modId, icon: Theme.iconGrid ?? "󰕰", desc: "status bar widget" };
    }

    function isModuleVisible(modId) {
        if (modId === "launcher") return Settings?.showLauncher ?? true;
        if (modId === "wallpaper") return Settings?.showWallpaper ?? true;
        if (modId === "workspaces") return Settings?.showWorkspaces ?? true;
        if (modId === "windowTitle") return Settings?.showWindowTitle ?? true;
        if (modId === "clock") return Settings?.showClock ?? true;
        if (modId === "media") return Settings?.showMedia ?? true;
        if (modId === "quickNotes") return Settings?.showQuickNotes ?? true;
        if (modId === "clipboard") return Settings?.showClipboard ?? true;
        if (modId === "idleInhibitor") return Settings?.showIdleInhibitor ?? true;
        if (modId === "notifications") return Settings?.showNotifications ?? true;
        if (modId === "systemTray") return Settings?.showSystemTray ?? true;
        if (modId === "bluetooth") return Settings?.showBluetooth ?? true;
        if (modId === "network") return Settings?.showNetwork ?? true;
        if (modId === "volume") return Settings?.showVolume ?? true;
        if (modId === "battery") return Settings?.showBattery ?? true;
        if (modId === "quickSettings") return Settings?.showQuickSettings ?? true;
        if (modId === "powerMenu") return Settings?.showPowerMenu ?? true;
        return true;
    }

    function toggleModuleVisibility(modId) {
        if (modId === "launcher") Settings.showLauncher = !Settings.showLauncher;
        else if (modId === "wallpaper") Settings.showWallpaper = !Settings.showWallpaper;
        else if (modId === "workspaces") Settings.showWorkspaces = !Settings.showWorkspaces;
        else if (modId === "windowTitle") Settings.showWindowTitle = !Settings.showWindowTitle;
        else if (modId === "clock") Settings.showClock = !Settings.showClock;
        else if (modId === "media") Settings.showMedia = !Settings.showMedia;
        else if (modId === "quickNotes") Settings.showQuickNotes = !Settings.showQuickNotes;
        else if (modId === "clipboard") Settings.showClipboard = !Settings.showClipboard;
        else if (modId === "idleInhibitor") Settings.showIdleInhibitor = !Settings.showIdleInhibitor;
        else if (modId === "notifications") Settings.showNotifications = !Settings.showNotifications;
        else if (modId === "systemTray") Settings.showSystemTray = !Settings.showSystemTray;
        else if (modId === "bluetooth") Settings.showBluetooth = !Settings.showBluetooth;
        else if (modId === "network") Settings.showNetwork = !Settings.showNetwork;
        else if (modId === "volume") Settings.showVolume = !Settings.showVolume;
        else if (modId === "battery") Settings.showBattery = !Settings.showBattery;
        else if (modId === "quickSettings") Settings.showQuickSettings = !Settings.showQuickSettings;
        else if (modId === "powerMenu") Settings.showPowerMenu = !Settings.showPowerMenu;
    }

    content: ColumnLayout {
        anchors.fill: parent
        spacing: 12

        // Header
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Rectangle {
                width: 34
                height: 34
                radius: Theme.radiusPill
                color: Theme.primary_overlay
                Text {
                    anchors.centerIn: parent
                    text: Theme.iconSparkles
                    font.family: Theme.fontIcon
                    font.pixelSize: Theme.fontSizeMd
                    color: Theme.primary
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                Text {
                    text: "bar layout studio"
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeMd
                    font.weight: Font.Bold
                    color: Theme.on_surface
                }
                Text {
                    text: "reorder modules, shift zones, or customize visibility with live bar reactivity"
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeXs
                    color: Theme.on_surface_variant
                }
            }

            // Reset Layout Button
            Rectangle {
                height: 30
                width: resetRow.implicitWidth + 20
                radius: Theme.radiusPill
                color: resetMouse.containsMouse ? Theme.surface_container_highest : Theme.surface_container_high
                border.color: Theme.widgetBorder
                border.width: 1

                Row {
                    id: resetRow
                    anchors.centerIn: parent
                    spacing: 6
                    Text {
                        text: "↺"
                        font.pixelSize: 11
                        color: Theme.on_surface
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        text: "reset layout"
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                        color: Theme.on_surface
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea {
                    id: resetMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Settings.resetBarLayout()
                }
            }

            // Close Button
            Rectangle {
                width: 30
                height: 30
                radius: Theme.radiusPill
                color: closeMouse.containsMouse ? Theme.error_overlay : Theme.surface_container_high
                border.color: Theme.widgetBorder
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: "✕"
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    color: closeMouse.containsMouse ? Theme.error : Theme.on_surface
                }

                MouseArea {
                    id: closeMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        Settings.showBarStudio = false;
                        Settings.showMotionSandbox = false;
                        root.open = false;
                    }
                }
            }
        }

        // 3 Layout Zones: Left, Center, Right
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 12

            // LEFT ZONE
            ZoneColumn {
                Layout.fillWidth: true
                Layout.fillHeight: true
                zoneId: "left"
                zoneTitle: "left modules"
                modulesList: Settings.barModulesLeft ?? []
            }

            // CENTER ZONE
            ZoneColumn {
                Layout.preferredWidth: 260
                Layout.fillHeight: true
                zoneId: "center"
                zoneTitle: "center modules"
                modulesList: Settings.barModulesCenter ?? []
            }

            // RIGHT ZONE
            ZoneColumn {
                Layout.fillWidth: true
                Layout.fillHeight: true
                zoneId: "right"
                zoneTitle: "right modules"
                modulesList: Settings.barModulesRight ?? []
            }
        }
    }

    // Reusable Zone Column Component
    component ZoneColumn: Rectangle {
        id: zoneRoot
        required property string zoneId
        required property string zoneTitle
        required property var modulesList

        radius: Theme.radiusMd
        color: Theme.surface_container_low
        border.color: Theme.widgetBorder
        border.width: 1

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 8

            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: zoneRoot.zoneTitle
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeXs
                    font.weight: Font.Bold
                    color: Theme.primary
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: zoneRoot.modulesList.length + " modules"
                    font.family: Theme.fontFamily
                    font.pixelSize: 9
                    color: Theme.on_surface_variant
                }
            }

            // Scrollable list of modules
            Flickable {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                contentHeight: moduleCol.implicitHeight
                contentWidth: width
                boundsBehavior: Flickable.StopAtBounds

                Column {
                    id: moduleCol
                    width: parent.width
                    spacing: 6

                    Repeater {
                        model: zoneRoot.modulesList

                        delegate: Rectangle {
                            id: card
                            required property string modelData
                            required property int index
                            readonly property var info: root.getModuleInfo(modelData)
                            readonly property bool isVisible: root.isModuleVisible(modelData)

                            width: moduleCol.width
                            height: 38
                            radius: Theme.radiusSm
                            color: cardMouse.containsMouse ? Theme.surface_container_highest : Theme.surface_container_high
                            border.color: isVisible ? Theme.widgetBorder : Theme.error_overlay
                            border.width: 1

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 6
                                spacing: 8

                                // Module icon
                                Text {
                                    text: card.info.icon
                                    font.family: Theme.fontIcon
                                    font.pixelSize: Theme.fontSizeSm
                                    color: card.isVisible ? Theme.primary : Theme.on_surface_disabled
                                }

                                // Module name
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 1
                                    Text {
                                        text: card.info.name
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 10
                                        font.weight: Font.DemiBold
                                        color: card.isVisible ? Theme.on_surface : Theme.on_surface_disabled
                                        elide: Text.ElideRight
                                    }
                                }

                                // Move up / left button
                                Rectangle {
                                    width: 22
                                    height: 22
                                    radius: Theme.radiusSm
                                    color: upMouse.containsMouse ? Theme.primary_overlay : "transparent"
                                    opacity: card.index > 0 ? 1.0 : 0.25

                                    Text {
                                        anchors.centerIn: parent
                                        text: "◀"
                                        font.pixelSize: 9
                                        color: Theme.on_surface
                                    }
                                    MouseArea {
                                        id: upMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: card.index > 0 ? Qt.PointingHandCursor : Qt.ArrowCursor
                                        onClicked: {
                                            if (card.index > 0) Settings.moveModule(zoneRoot.zoneId, card.index, card.index - 1);
                                        }
                                    }
                                }

                                // Move down / right button
                                Rectangle {
                                    width: 22
                                    height: 22
                                    radius: Theme.radiusSm
                                    color: downMouse.containsMouse ? Theme.primary_overlay : "transparent"
                                    opacity: card.index < zoneRoot.modulesList.length - 1 ? 1.0 : 0.25

                                    Text {
                                        anchors.centerIn: parent
                                        text: "▶"
                                        font.pixelSize: 9
                                        color: Theme.on_surface
                                    }
                                    MouseArea {
                                        id: downMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: card.index < zoneRoot.modulesList.length - 1 ? Qt.PointingHandCursor : Qt.ArrowCursor
                                        onClicked: {
                                            if (card.index < zoneRoot.modulesList.length - 1) Settings.moveModule(zoneRoot.zoneId, card.index, card.index + 1);
                                        }
                                    }
                                }

                                // Move Zone Left / Right
                                Rectangle {
                                    width: 22
                                    height: 22
                                    radius: Theme.radiusSm
                                    color: zoneShiftMouse.containsMouse ? Theme.secondary_overlay : "transparent"
                                    visible: true

                                    Text {
                                        anchors.centerIn: parent
                                        text: zoneRoot.zoneId === "left" ? "↷" : (zoneRoot.zoneId === "center" ? "⇄" : "↶")
                                        font.pixelSize: 11
                                        color: Theme.secondary
                                    }
                                    MouseArea {
                                        id: zoneShiftMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            let nextZone = (zoneRoot.zoneId === "left") ? "center" : (zoneRoot.zoneId === "center" ? "right" : "left");
                                            Settings.transferModule(zoneRoot.zoneId, nextZone, card.index);
                                        }
                                    }
                                }

                                // Toggle Visibility Button
                                Rectangle {
                                    width: 22
                                    height: 22
                                    radius: Theme.radiusSm
                                    color: eyeMouse.containsMouse ? (card.isVisible ? Theme.primary_overlay : Theme.error_overlay) : "transparent"

                                    Text {
                                        anchors.centerIn: parent
                                        text: card.isVisible ? "👁" : "🚫"
                                        font.pixelSize: 10
                                        color: card.isVisible ? Theme.primary : Theme.error
                                    }
                                    MouseArea {
                                        id: eyeMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.toggleModuleVisibility(card.modelData)
                                    }
                                }
                            }

                            MouseArea {
                                id: cardMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                z: -1
                            }
                        }
                    }
                }
            }
        }
    }
}
