// StatusBar.qml
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import ".."
import "../widgets"
import "../controls"
import "../corners"
import Quickshell.Services.UPower

PanelWindow {
    id: root

    required property var modelData
    screen: modelData
    color: "transparent"

    function hasAdjacentMonitor(dir) {
        if (!root.screen) return false;
        let all = Quickshell.screens;
        if (!all || all.length <= 1) return false;
        let sx = root.screen.x, sy = root.screen.y, sw = root.screen.width, sh = root.screen.height;
        for (let i = 0; i < all.length; i++) {
            let o = all[i];
            if (o === root.screen || o.name === root.screen.name) continue;
            let ox = o.x, oy = o.y, ow = o.width, oh = o.height;
            if (dir === "right" && Math.abs(ox - (sx + sw)) <= 4 && !(oy + oh <= sy || oy >= sy + sh)) return true;
            if (dir === "left" && Math.abs((ox + ow) - sx) <= 4 && !(oy + oh <= sy || oy >= sy + sh)) return true;
            if (dir === "top" && Math.abs((oy + oh) - sy) <= 4 && !(ox + ow <= sx || ox >= sx + sw)) return true;
            if (dir === "bottom" && Math.abs(oy - (sy + sh)) <= 4 && !(ox + ow <= sx || ox >= sx + sw)) return true;
        }
        return false;
    }

    readonly property var hyprMonitor: Hyprland.monitorFor ? Hyprland.monitorFor(root.screen) : null
    readonly property bool isFullscreen: (hyprMonitor?.activeWorkspace?.hasFullscreen) ?? (Hyprland.focusedWorkspace?.hasFullscreen ?? false)
    visible: !root.isFullscreen

    readonly property string pos: Settings?.barPosition ?? "up"
    readonly property bool isTop: pos === "up" || pos === "top"
    readonly property bool isBottom: pos === "down" || pos === "bottom"
    readonly property bool isLeft: pos === "left"
    readonly property bool isRight: pos === "right"

    readonly property real maxWindowTitleWidth: {
        let halfScreen = root.width / 2;
        let centerHalf = (centerRowH.visible ? centerRowH.width : 0) / 2;
        let clockStart = halfScreen - centerHalf;
        return Math.max(160, clockStart - 260);
    }
    readonly property bool isVertical: isLeft || isRight

    readonly property int scoopRadius: Math.round(Settings?.scoopRadius ?? Settings?.screenCornerRadius ?? 16)
    readonly property string cornerMode: Settings?.screenCornerMode ?? "all"

    // bar scoops belong to the bar, dont let "opposite" kill them
    readonly property bool scoopAllowedLeft: cornerMode !== "none" && (cornerMode !== "monitor" || !hasAdjacentMonitor("left"))
    readonly property bool scoopAllowedRight: cornerMode !== "none" && (cornerMode !== "monitor" || !hasAdjacentMonitor("right"))
    readonly property bool scoopAllowedTop: cornerMode !== "none" && (cornerMode !== "monitor" || !hasAdjacentMonitor("top"))
    readonly property bool scoopAllowedBottom: cornerMode !== "none" && (cornerMode !== "monitor" || !hasAdjacentMonitor("bottom"))

    readonly property int borderWidth: Math.round((Settings?.screenFrameDocked ?? true) ? (Settings?.screenBorderWidth ?? 0) : 0)
    readonly property bool hasBarScoops: !(Settings?.barFloating ?? false) && (Settings?.screenFrameDocked ?? true) && (
        root.isVertical ? (scoopAllowedTop || scoopAllowedBottom) : (scoopAllowedLeft || scoopAllowedRight)
    )

    anchors {
        top: root.isTop || root.isVertical
        bottom: root.isBottom || root.isVertical
        left: root.isLeft || !root.isVertical
        right: root.isRight || !root.isVertical
    }

    implicitWidth: root.isVertical ? (Theme.barHeight + (root.hasBarScoops ? root.scoopRadius : 0)) : (root.screen?.width ?? 1920)
    implicitHeight: root.isVertical ? (root.screen?.height ?? 1080) : (Theme.barHeight + (root.hasBarScoops ? root.scoopRadius : 0))
    exclusiveZone: Theme.barHeight
    exclusionMode: ExclusionMode.Normal

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "quickshell:bar"

    mask: Region {
        Region { item: barBg }
        Region { item: scoopLeftH.visible ? scoopLeftH : null }
        Region { item: scoopRightH.visible ? scoopRightH : null }
        Region { item: scoopTopV.visible ? scoopTopV : null }
        Region { item: scoopBottomV.visible ? scoopBottomV : null }
    }

    property alias launcherPopup: launcherPopup

    AppLauncher {
        id: launcherPopup
        screen: root.screen
    }

    Connections {
        target: Settings
        function onRequestLauncherToggle() {
            if (!root.screen || Quickshell.screens.length <= 1 || (root.hyprMonitor && Hyprland.focusedMonitor && root.hyprMonitor.id === Hyprland.focusedMonitor.id)) {
                root.launcherPopup.targetRelativeX = 0;
                root.launcherPopup.targetRelativeY = 0;
                root.launcherPopup.open = !root.launcherPopup.open;
            }
        }
    }

    Component { id: compLauncher; Rectangle {
        id: launcherPill
        visible: Settings?.showLauncher ?? true
        implicitWidth: root.isVertical ? (Theme.barHeight - 8) : Math.max(36, launcherText.implicitWidth + 16)
        implicitHeight: root.isVertical ? Math.max(36, launcherText.implicitHeight + 12) : (Theme.barHeight - 8)
        width: implicitWidth
        height: implicitHeight
        radius: Theme.radiusPill
        color: lMouse.pressed ? Theme.widgetActive : lMouse.containsMouse ? Theme.pillHover : (root.launcherPopup.open ? Theme.primary_overlay : Theme.pillBg)
        border.color: Theme.pillBorder
        border.width: Theme.pillBorder === "transparent" ? 0 : 1
        Behavior on color { ColorAnimation { duration: Theme.animFast } }
        Behavior on border.color { ColorAnimation { duration: Theme.animFast } }
        Behavior on implicitWidth { NumberAnimation { duration: Theme.animFast; easing.type: Theme.animEasing } }
        Text {
            id: launcherText
            anchors.centerIn: parent
            text: Theme.iconArch
            font.family: Theme.fontIcon
            font.pixelSize: (Theme.iconSet === "kaomoji" || Theme.iconSet === "text") ? (root.isVertical ? Theme.fontSizeXs : Theme.fontSizeSm) : Theme.fontSizeLg
            color: root.launcherPopup.open ? Theme.primary : Theme.on_surface
        }
        MouseArea {
            id: lMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                let pt = launcherPill.mapToItem(null, 0, 0);
                if (root.isVertical) {
                    root.launcherPopup.targetRelativeY = pt.y + (launcherPill.height / 2);
                } else {
                    root.launcherPopup.targetRelativeX = pt.x + (launcherPill.width / 2);
                }
                root.launcherPopup.open = !root.launcherPopup.open;
            }
        }
    }}

    Component { id: compWallpaper; WallpaperBrowser {} }
    Component { id: compWorkspaces; Workspaces {} }
    Component { id: compWindowTitle; WindowTitle { barScreen: root.screen; barMonitor: root.hyprMonitor } }
    Component { id: compClock; Clock {} }
    Component { id: compMedia; NowPlaying {} }
    Component { id: compQuickNotes; QuickNotes {} }
    Component { id: compClipboard; Clipboard {} }
    Component { id: compIdleInhibitor; IdleInhibitor { barScreen: root.screen; barMonitor: root.hyprMonitor } }
    Component { id: compNotifications; Notifications {} }
    Component { id: compSystemTray; SystemTray {} }
    Component { id: compBluetooth; Bluetooth {} }
    Component { id: compNetwork; NetworkStatus {} }
    Component { id: compVolume; VolumeControl {} }
    Component { id: compBattery; Battery { barScreen: root.screen; barMonitor: root.hyprMonitor } }
    Component { id: compQuickSettings; QuickSettings { barScreen: root.screen; barMonitor: root.hyprMonitor } }
    Component { id: compPowerMenu; PowerMenu {} }

    function getModuleComponent(modId) {
        if (modId === "launcher") return compLauncher;
        if (modId === "wallpaper") return compWallpaper;
        if (modId === "workspaces") return compWorkspaces;
        if (modId === "windowTitle") return compWindowTitle;
        if (modId === "clock") return compClock;
        if (modId === "media") return compMedia;
        if (modId === "quickNotes") return compQuickNotes;
        if (modId === "clipboard") return compClipboard;
        if (modId === "idleInhibitor") return compIdleInhibitor;
        if (modId === "notifications") return compNotifications;
        if (modId === "systemTray") return compSystemTray;
        if (modId === "bluetooth") return compBluetooth;
        if (modId === "network") return compNetwork;
        if (modId === "volume") return compVolume;
        if (modId === "battery") return compBattery;
        if (modId === "quickSettings") return compQuickSettings;
        if (modId === "powerMenu") return compPowerMenu;
        return null;
    }

    function isModuleVisible(modId) {
        if (modId === "launcher") return Settings?.showLauncher ?? true;
        if (modId === "wallpaper") return Settings?.showWallpaper ?? true;
        if (modId === "workspaces") return Settings?.showWorkspaces ?? true;
        if (modId === "windowTitle") return (Settings?.showWindowTitle ?? true) && !root.isVertical;
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
        if (modId === "battery") return (Settings?.showBattery ?? true) && (UPower.displayDevice?.isPresent ?? false);
        if (modId === "quickSettings") return Settings?.showQuickSettings ?? true;
        if (modId === "powerMenu") return Settings?.showPowerMenu ?? true;
        return true;
    }

    Item {
        id: barRootItem
        anchors.fill: parent

        Rectangle {
            id: barBg
            x: root.isRight && root.hasBarScoops && root.scoopRadius > 0 ? root.scoopRadius : 0
            y: root.isBottom && root.hasBarScoops && root.scoopRadius > 0 ? root.scoopRadius : 0
            width: root.isVertical ? Theme.barHeight : parent.width
            height: root.isVertical ? parent.height : Theme.barHeight
            color: Theme.barBg
            border.width: 0

            Rectangle {
                visible: Settings?.barStyle === "accent-glow" || Settings?.barStyle === "cyber-neon"
                x: Math.round(root.isVertical ? (root.isLeft ? parent.width - 2 : 0) : ((root.hasBarScoops && scoopLeftH.visible) ? (root.borderWidth + root.scoopRadius) : 0))
                y: Math.round(root.isVertical ? ((root.hasBarScoops && scoopTopV.visible) ? (root.borderWidth + root.scoopRadius) : 0) : (root.isTop ? parent.height - 2 : 0))
                width: Math.round(root.isVertical ? 2 : (parent.width - ((root.hasBarScoops && scoopLeftH.visible) ? (root.borderWidth + root.scoopRadius) : 0) - ((root.hasBarScoops && scoopRightH.visible) ? (root.borderWidth + root.scoopRadius) : 0)))
                height: Math.round(root.isVertical ? (parent.height - ((root.hasBarScoops && scoopTopV.visible) ? (root.borderWidth + root.scoopRadius) : 0) - ((root.hasBarScoops && scoopBottomV.visible) ? (root.borderWidth + root.scoopRadius) : 0)) : 2)
                color: Theme.primary
                opacity: Settings?.barStyle === "cyber-neon" ? 1.0 : 0.90
            }

            Rectangle {
                visible: Settings?.barStyle === "glass" || Settings?.barStyle === "glass-frost"
                x: Math.round(root.isVertical ? (root.isLeft ? parent.width - 1 : 0) : ((root.hasBarScoops && scoopLeftH.visible) ? (root.borderWidth + root.scoopRadius) : 0))
                y: Math.round(root.isVertical ? ((root.hasBarScoops && scoopTopV.visible) ? (root.borderWidth + root.scoopRadius) : 0) : (root.isTop ? parent.height - 1 : 0))
                width: Math.round(root.isVertical ? 1 : (parent.width - ((root.hasBarScoops && scoopLeftH.visible) ? (root.borderWidth + root.scoopRadius) : 0) - ((root.hasBarScoops && scoopRightH.visible) ? (root.borderWidth + root.scoopRadius) : 0)))
                height: Math.round(root.isVertical ? (parent.height - ((root.hasBarScoops && scoopTopV.visible) ? (root.borderWidth + root.scoopRadius) : 0) - ((root.hasBarScoops && scoopBottomV.visible) ? (root.borderWidth + root.scoopRadius) : 0)) : 1)
                color: Theme.glassHighlight ?? Qt.rgba(1, 1, 1, 0.22)
            }
        }

        ConcaveCorner {
            id: scoopLeftH
            visible: root.hasBarScoops && !root.isVertical && root.scoopRadius > 0 && root.scoopAllowedLeft
            x: Math.round(root.borderWidth > 0 && root.scoopAllowedLeft ? root.borderWidth : 0)
            y: Math.round(root.isTop ? Theme.barHeight : 0)
            radiusX: root.scoopRadius
            radiusY: root.scoopRadius
            fillColor: Theme.barBg
            flipX: false
            flipY: root.isBottom
        }

        ConcaveCorner {
            id: scoopRightH
            visible: root.hasBarScoops && !root.isVertical && root.scoopRadius > 0 && root.scoopAllowedRight
            x: Math.round(parent.width - (root.borderWidth > 0 && root.scoopAllowedRight ? root.borderWidth : 0) - root.scoopRadius)
            y: Math.round(root.isTop ? Theme.barHeight : 0)
            radiusX: root.scoopRadius
            radiusY: root.scoopRadius
            fillColor: Theme.barBg
            flipX: true
            flipY: root.isBottom
        }

        ConcaveCorner {
            id: scoopTopV
            visible: root.hasBarScoops && root.isVertical && root.scoopRadius > 0 && root.scoopAllowedTop
            x: Math.round(root.isLeft ? Theme.barHeight : 0)
            y: Math.round(root.borderWidth > 0 && root.scoopAllowedTop ? root.borderWidth : 0)
            radiusX: root.scoopRadius
            radiusY: root.scoopRadius
            fillColor: Theme.barBg
            flipX: root.isRight
            flipY: false
        }

        ConcaveCorner {
            id: scoopBottomV
            visible: root.hasBarScoops && root.isVertical && root.scoopRadius > 0 && root.scoopAllowedBottom
            x: Math.round(root.isLeft ? Theme.barHeight : 0)
            y: Math.round(parent.height - (root.borderWidth > 0 && root.scoopAllowedBottom ? root.borderWidth : 0) - root.scoopRadius)
            radiusX: root.scoopRadius
            radiusY: root.scoopRadius
            fillColor: Theme.barBg
            flipX: root.isRight
            flipY: true
        }

        Item {
            anchors.fill: barBg
            visible: !root.isVertical

            Row {
                id: leftRowH
                anchors.left: parent.left
                anchors.leftMargin: Theme.widgetPaddingH
                anchors.verticalCenter: parent.verticalCenter
                spacing: Theme.widgetSpacing

                Repeater {
                    model: Settings.barModulesLeft ?? []
                    delegate: Loader {
                        id: lModLoader
                        required property string modelData
                        active: root.isModuleVisible(modelData) && !root.isVertical
                        visible: active
                        sourceComponent: root.getModuleComponent(modelData)
                        readonly property real targetW: {
                            if (!item) return (Theme.barHeight - 8);
                            if (modelData === "windowTitle") {
                                let mode = Settings?.windowTitleMode ?? "auto";
                                if (mode === "fill") {
                                    return Math.max(80, root.maxWindowTitleWidth);
                                }
                                if (mode === "compact") {
                                    return Math.max(40, Math.min(item.implicitWidth, 260));
                                }
                                let maxAllowed = Math.min(Settings?.windowTitleMaxWidth ?? 760, root.maxWindowTitleWidth);
                                return Math.max(40, Math.min(item.implicitWidth, maxAllowed));
                            }
                            return item.implicitWidth;
                        }
                        width: Math.round(targetW)
                        height: Math.round(item ? item.implicitHeight : (Theme.barHeight - 8))
                        Behavior on width { NumberAnimation { duration: Theme.animFast; easing.type: Theme.animEasing } }
                        Behavior on opacity { NumberAnimation { duration: Theme.animFast; easing.type: Theme.animEasing } }
                    }
                }
            }

            Row {
                id: centerRowH
                anchors.centerIn: parent
                spacing: Theme.widgetSpacing
                z: 10

                Repeater {
                    model: Settings.barModulesCenter ?? ["clock"]
                    delegate: Loader {
                        required property string modelData
                        active: root.isModuleVisible(modelData) && !root.isVertical
                        visible: active
                        sourceComponent: root.getModuleComponent(modelData)
                        width: Math.round(item ? item.implicitWidth : (Theme.barHeight - 8))
                        height: Math.round(item ? item.implicitHeight : (Theme.barHeight - 8))
                        Behavior on opacity { NumberAnimation { duration: Theme.animFast; easing.type: Theme.animEasing } }
                    }
                }
            }

            Row {
                id: rightRowH
                anchors.right: parent.right
                anchors.rightMargin: Theme.widgetPaddingH
                anchors.verticalCenter: parent.verticalCenter
                spacing: Theme.widgetSpacing

                Repeater {
                    model: Settings.barModulesRight ?? []
                    delegate: Loader {
                        required property string modelData
                        active: root.isModuleVisible(modelData) && !root.isVertical
                        visible: active
                        sourceComponent: root.getModuleComponent(modelData)
                        readonly property real targetW: item ? item.implicitWidth : (Theme.barHeight - 8)
                        width: Math.round(targetW)
                        height: Math.round(item ? item.implicitHeight : (Theme.barHeight - 8))
                        Behavior on opacity { NumberAnimation { duration: Theme.animFast; easing.type: Theme.animEasing } }
                    }
                }
            }
        }

        Item {
            anchors.fill: barBg
            visible: root.isVertical

            Column {
                anchors.top: parent.top
                anchors.topMargin: Theme.widgetPaddingH
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Theme.widgetSpacing

                Repeater {
                    model: Settings.barModulesLeft ?? []
                    delegate: Loader {
                        required property string modelData
                        active: root.isModuleVisible(modelData) && root.isVertical
                        visible: active
                        sourceComponent: root.getModuleComponent(modelData)
                        width: Math.round(item ? item.implicitWidth : (Theme.barHeight - 8))
                        height: Math.round(item ? item.implicitHeight : (Theme.barHeight - 8))
                        Behavior on opacity { NumberAnimation { duration: Theme.animFast; easing.type: Theme.animEasing } }
                    }
                }
            }

            Column {
                anchors.centerIn: parent
                spacing: Theme.widgetSpacing
                z: 10

                Repeater {
                    model: Settings.barModulesCenter ?? ["clock"]
                    delegate: Loader {
                        required property string modelData
                        active: root.isModuleVisible(modelData) && root.isVertical
                        visible: active
                        sourceComponent: root.getModuleComponent(modelData)
                        width: Math.round(item ? item.implicitWidth : (Theme.barHeight - 8))
                        height: Math.round(item ? item.implicitHeight : (Theme.barHeight - 8))
                        Behavior on opacity { NumberAnimation { duration: Theme.animFast; easing.type: Theme.animEasing } }
                    }
                }
            }

            Column {
                anchors.bottom: parent.bottom
                anchors.bottomMargin: Theme.widgetPaddingH
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Theme.widgetSpacing

                Repeater {
                    model: Settings.barModulesRight ?? []
                    delegate: Loader {
                        required property string modelData
                        active: root.isModuleVisible(modelData) && root.isVertical
                        visible: active
                        sourceComponent: root.getModuleComponent(modelData)
                        width: Math.round(item ? item.implicitWidth : (Theme.barHeight - 8))
                        height: Math.round(item ? item.implicitHeight : (Theme.barHeight - 8))
                        Behavior on opacity { NumberAnimation { duration: Theme.animFast; easing.type: Theme.animEasing } }
                    }
                }
            }
        }
    }
}