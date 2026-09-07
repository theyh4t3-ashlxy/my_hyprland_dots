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
    readonly property bool isVertical: isLeft || isRight

    readonly property int scoopRadius: Math.round(Settings?.scoopRadius ?? 16)
    readonly property string cornerMode: Settings?.screenCornerMode ?? "all"

    readonly property bool showTopLeft: {
        if (cornerMode === "none") return false;
        if (cornerMode === "monitor") return !hasAdjacentMonitor("top") && !hasAdjacentMonitor("left");
        if (cornerMode === "all") return true;
        if (cornerMode === "opposite") return !root.isTop && !root.isLeft;
        if (cornerMode === "top" || cornerMode === "left") return true;
        return false;
    }
    readonly property bool showTopRight: {
        if (cornerMode === "none") return false;
        if (cornerMode === "monitor") return !hasAdjacentMonitor("top") && !hasAdjacentMonitor("right");
        if (cornerMode === "all") return true;
        if (cornerMode === "opposite") return !root.isTop && !root.isRight;
        if (cornerMode === "top" || cornerMode === "right") return true;
        return false;
    }
    readonly property bool showBottomLeft: {
        if (cornerMode === "none") return false;
        if (cornerMode === "monitor") return !hasAdjacentMonitor("bottom") && !hasAdjacentMonitor("left");
        if (cornerMode === "all") return true;
        if (cornerMode === "opposite") return !root.isBottom && !root.isLeft;
        if (cornerMode === "bottom" || cornerMode === "left") return true;
        return false;
    }
    readonly property bool showBottomRight: {
        if (cornerMode === "none") return false;
        if (cornerMode === "monitor") return !hasAdjacentMonitor("bottom") && !hasAdjacentMonitor("right");
        if (cornerMode === "all") return true;
        if (cornerMode === "opposite") return !root.isBottom && !root.isRight;
        if (cornerMode === "bottom" || cornerMode === "right") return true;
        return false;
    }

    readonly property bool borderTopAllowed: {
        if (cornerMode === "none") return false;
        if (cornerMode === "monitor") return !hasAdjacentMonitor("top");
        if (cornerMode === "all" || cornerMode === "top") return true;
        if (cornerMode === "opposite") return root.isBottom;
        return false;
    }
    readonly property bool borderBottomAllowed: {
        if (cornerMode === "none") return false;
        if (cornerMode === "monitor") return !hasAdjacentMonitor("bottom");
        if (cornerMode === "all" || cornerMode === "bottom") return true;
        if (cornerMode === "opposite") return root.isTop;
        return false;
    }
    readonly property bool borderLeftAllowed: {
        if (cornerMode === "none") return false;
        if (cornerMode === "monitor") return !hasAdjacentMonitor("left");
        if (cornerMode === "all" || cornerMode === "left") return true;
        if (cornerMode === "opposite") return root.isRight;
        return false;
    }
    readonly property bool borderRightAllowed: {
        if (cornerMode === "none") return false;
        if (cornerMode === "monitor") return !hasAdjacentMonitor("right");
        if (cornerMode === "all" || cornerMode === "right") return true;
        if (cornerMode === "opposite") return root.isLeft;
        return false;
    }

    readonly property int borderWidth: Math.round((Settings?.screenFrameDocked ?? true) ? (Settings?.screenBorderWidth ?? 0) : 0)
    readonly property bool hasBarScoops: !(Settings?.barFloating ?? false) && (Settings?.screenFrameDocked ?? true) && (
        root.isTop ? (showTopLeft || showTopRight) :
        root.isBottom ? (showBottomLeft || showBottomRight) :
        root.isLeft ? (showTopLeft || showBottomLeft) :
        (showTopRight || showBottomRight)
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
        Region { item: leftBorderScoopCap.visible ? leftBorderScoopCap : null }
        Region { item: rightBorderScoopCap.visible ? rightBorderScoopCap : null }
        Region { item: topBorderScoopCap.visible ? topBorderScoopCap : null }
        Region { item: bottomBorderScoopCap.visible ? bottomBorderScoopCap : null }
    }

    property alias launcherPopup: launcherPopup

    AppLauncher {
        id: launcherPopup
        screen: root.screen
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
                if (Theme.isVertical) {
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
    Component { id: compWindowTitle; WindowTitle {} }
    Component { id: compClock; Clock {} }
    Component { id: compMedia; NowPlaying {} }
    Component { id: compQuickNotes; QuickNotes {} }
    Component { id: compClipboard; Clipboard {} }
    Component { id: compIdleInhibitor; IdleInhibitor {} }
    Component { id: compNotifications; Notifications {} }
    Component { id: compSystemTray; SystemTray {} }
    Component { id: compBluetooth; Bluetooth {} }
    Component { id: compNetwork; NetworkStatus {} }
    Component { id: compVolume; VolumeControl {} }
    Component { id: compBattery; Battery {} }
    Component { id: compQuickSettings; QuickSettings {} }
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
                visible: Settings?.barStyle === "accent-glow"
                x: Math.round(root.isVertical ? (root.isLeft ? parent.width - 2 : 0) : ((root.hasBarScoops && scoopLeftH.visible) ? (root.borderWidth + root.scoopRadius) : 0))
                y: Math.round(root.isVertical ? ((root.hasBarScoops && scoopTopV.visible) ? (root.borderWidth + root.scoopRadius) : 0) : (root.isTop ? parent.height - 2 : 0))
                width: Math.round(root.isVertical ? 2 : (parent.width - ((root.hasBarScoops && scoopLeftH.visible) ? (root.borderWidth + root.scoopRadius) : 0) - ((root.hasBarScoops && scoopRightH.visible) ? (root.borderWidth + root.scoopRadius) : 0)))
                height: Math.round(root.isVertical ? (parent.height - ((root.hasBarScoops && scoopTopV.visible) ? (root.borderWidth + root.scoopRadius) : 0) - ((root.hasBarScoops && scoopBottomV.visible) ? (root.borderWidth + root.scoopRadius) : 0)) : 2)
                color: Theme.primary
                opacity: 0.90
            }

            Rectangle {
                visible: Settings?.barStyle === "glass"
                x: Math.round(root.isVertical ? (root.isLeft ? parent.width - 1 : 0) : ((root.hasBarScoops && scoopLeftH.visible) ? (root.borderWidth + root.scoopRadius) : 0))
                y: Math.round(root.isVertical ? ((root.hasBarScoops && scoopTopV.visible) ? (root.borderWidth + root.scoopRadius) : 0) : (root.isTop ? parent.height - 1 : 0))
                width: Math.round(root.isVertical ? 1 : (parent.width - ((root.hasBarScoops && scoopLeftH.visible) ? (root.borderWidth + root.scoopRadius) : 0) - ((root.hasBarScoops && scoopRightH.visible) ? (root.borderWidth + root.scoopRadius) : 0)))
                height: Math.round(root.isVertical ? (parent.height - ((root.hasBarScoops && scoopTopV.visible) ? (root.borderWidth + root.scoopRadius) : 0) - ((root.hasBarScoops && scoopBottomV.visible) ? (root.borderWidth + root.scoopRadius) : 0)) : 1)
                color: Qt.rgba(1, 1, 1, 0.22)
            }
        }

        Rectangle {
            id: leftBorderScoopCap
            x: 0
            y: root.isTop ? Theme.barHeight : 0
            width: root.borderWidth
            height: root.scoopRadius
            color: Theme.cornerFill ?? Theme.barBg
            visible: root.hasBarScoops && !root.isVertical && root.borderWidth > 0 && root.scoopRadius > 0 && root.borderLeftAllowed
        }

        Rectangle {
            id: rightBorderScoopCap
            x: parent.width - root.borderWidth
            y: root.isTop ? Theme.barHeight : 0
            width: root.borderWidth
            height: root.scoopRadius
            color: Theme.cornerFill ?? Theme.barBg
            visible: root.hasBarScoops && !root.isVertical && root.borderWidth > 0 && root.scoopRadius > 0 && root.borderRightAllowed
        }

        Rectangle {
            id: topBorderScoopCap
            x: root.isLeft ? Theme.barHeight : 0
            y: 0
            width: root.scoopRadius
            height: root.borderWidth
            color: Theme.cornerFill ?? Theme.barBg
            visible: root.hasBarScoops && root.isVertical && root.borderWidth > 0 && root.scoopRadius > 0 && root.borderTopAllowed
        }

        Rectangle {
            id: bottomBorderScoopCap
            x: root.isLeft ? Theme.barHeight : 0
            y: parent.height - root.borderWidth
            width: root.scoopRadius
            height: root.borderWidth
            color: Theme.cornerFill ?? Theme.barBg
            visible: root.hasBarScoops && root.isVertical && root.borderWidth > 0 && root.scoopRadius > 0 && root.borderBottomAllowed
        }

        ConcaveCorner {
            id: scoopLeftH
            visible: root.hasBarScoops && !root.isVertical && root.scoopRadius > 0 && (root.isTop ? root.showTopLeft : root.showBottomLeft)
            x: Math.round(root.borderWidth > 0 && root.borderLeftAllowed ? root.borderWidth : 0)
            y: Math.round(root.isTop ? Theme.barHeight : 0)
            radiusX: root.scoopRadius
            radiusY: root.scoopRadius
            fillColor: Theme.barBg
            flipX: false
            flipY: root.isBottom
        }

        ConcaveCorner {
            id: scoopRightH
            visible: root.hasBarScoops && !root.isVertical && root.scoopRadius > 0 && (root.isTop ? root.showTopRight : root.showBottomRight)
            x: Math.round(parent.width - (root.borderWidth > 0 && root.borderRightAllowed ? root.borderWidth : 0) - root.scoopRadius)
            y: Math.round(root.isTop ? Theme.barHeight : 0)
            radiusX: root.scoopRadius
            radiusY: root.scoopRadius
            fillColor: Theme.barBg
            flipX: true
            flipY: root.isBottom
        }

        ConcaveCorner {
            id: scoopTopV
            visible: root.hasBarScoops && root.isVertical && root.scoopRadius > 0 && (root.isLeft ? root.showTopLeft : root.showTopRight)
            x: Math.round(root.isLeft ? Theme.barHeight : 0)
            y: Math.round(root.borderWidth > 0 && root.borderTopAllowed ? root.borderWidth : 0)
            radiusX: root.scoopRadius
            radiusY: root.scoopRadius
            fillColor: Theme.barBg
            flipX: root.isRight
            flipY: false
        }

        ConcaveCorner {
            id: scoopBottomV
            visible: root.hasBarScoops && root.isVertical && root.scoopRadius > 0 && (root.isLeft ? root.showBottomLeft : root.showBottomRight)
            x: Math.round(root.isLeft ? Theme.barHeight : 0)
            y: Math.round(parent.height - (root.borderWidth > 0 && root.borderBottomAllowed ? root.borderWidth : 0) - root.scoopRadius)
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
                        readonly property real targetW: item ? (modelData === "windowTitle" ? Math.max(40, Math.min(item.implicitWidth, 260)) : item.implicitWidth) : (Theme.barHeight - 8)
                        width: Math.round(targetW)
                        height: Math.round(item ? item.implicitHeight : (Theme.barHeight - 8))
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