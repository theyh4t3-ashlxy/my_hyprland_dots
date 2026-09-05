import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."
import "../widgets"
import "../controls"
import "../corners"

PanelWindow {
    id: root

    required property var modelData
    screen: modelData
    color: "transparent"

    readonly property string pos: Settings?.barPosition ?? "up"
    readonly property bool isTop: pos === "up" || pos === "top"
    readonly property bool isBottom: pos === "down" || pos === "bottom"
    readonly property bool isLeft: pos === "left"
    readonly property bool isRight: pos === "right"
    readonly property bool isVertical: isLeft || isRight

    readonly property real scoopW: Theme?.scoopRadiusX ?? 16
    readonly property real scoopH: Theme?.scoopRadiusY ?? 16

    // 4-way dynamic docking
    anchors {
        top: root.isTop || root.isVertical
        bottom: root.isBottom || root.isVertical
        left: root.isLeft || !root.isVertical
        right: root.isRight || !root.isVertical
    }

    implicitWidth: root.isVertical ? (Theme.barHeight + root.scoopW) : (root.screen?.width ?? 1920)
    implicitHeight: root.isVertical ? (root.screen?.height ?? 1080) : (Theme.barHeight + root.scoopH)
    exclusiveZone: Theme.barHeight
    exclusionMode: ExclusionMode.Normal

    WlrLayershell.namespace: "quickshell:bar"

    // ensure the full bar area accepts user input
    mask: Region {
        item: barRootItem
    }

    IdleInhibitor {
        enabled: !IdleService.enabled
    }

    AppLauncher {
        id: launcherPopup
        screen: root.screen
    }

    component LauncherButton: Rectangle {
        id: lbtn
        property bool isVertical: root.isVertical
        visible: Settings?.showLauncher ?? true
        width: isVertical ? (Theme.barHeight - 8) : Math.max(36, lText.implicitWidth + 16)
        height: isVertical ? Math.max(36, lText.implicitHeight + 12) : (Theme.barHeight - 8)
        radius: Theme.radiusPill
        color: lMouse.pressed ? Theme.widgetActive : lMouse.containsMouse ? Theme.pillHover : (launcherPopup.open ? Theme.primary_overlay : Theme.pillBg)
        border.color: Theme.pillBorder
        border.width: Theme.pillBorder === "transparent" ? 0 : 1

        Behavior on color { ColorAnimation { duration: Theme.animFast } }
        Behavior on border.color { ColorAnimation { duration: Theme.animFast } }

        Text {
            id: lText
            anchors.centerIn: parent
            text: Theme.iconArch
            font.family: Theme.fontIcon
            font.pixelSize: (Theme.iconSet === "kaomoji" || Theme.iconSet === "text")
                ? (lbtn.isVertical ? Theme.fontSizeXs : Theme.fontSizeSm)
                : Theme.fontSizeLg
            color: launcherPopup.open ? Theme.primary : Theme.on_surface
        }

        MouseArea {
            id: lMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                if (lbtn.isVertical) {
                    launcherPopup.targetRelativeY = lbtn.mapToItem(null, 0, 0).y + (lbtn.height / 2);
                } else {
                    launcherPopup.targetRelativeX = lbtn.mapToItem(null, 0, 0).x + (lbtn.width / 2);
                }
                launcherPopup.open = !launcherPopup.open;
            }
        }
    }

    component BarWidgetLoader: Loader {
        id: bwl
        property bool crowded: false
        property bool veryCrowded: false
        property bool isVertical: root.isVertical
        property bool crowdSensitive: false
        property bool veryCrowdSensitive: false
        property bool requiresDevice: false
        property bool hasDevice: false
        property bool requiresCount: false
        property int count: 0

        readonly property bool condition: {
            let openPopup = item?.popup?.open ?? false;
            if (openPopup) return true;
            if (requiresDevice && !hasDevice) return false;
            if (requiresCount && count <= 0) return false;
            if (veryCrowdSensitive && veryCrowded) return false;
            if (crowdSensitive && crowded) return false;
            return true;
        }

        readonly property bool shouldShow: Boolean(active && condition)
        visible: shouldShow || (isVertical ? height > 0.5 : width > 0.5)
        opacity: shouldShow ? 1 : 0
        clip: true

        width: isVertical
            ? (item ? item.implicitWidth : (Theme.barHeight - 8))
            : (shouldShow ? (item ? item.implicitWidth : (Theme.barHeight - 8)) : 0)

        height: isVertical
            ? (shouldShow ? (item ? item.implicitHeight : (Theme.barHeight - 8)) : 0)
            : (item ? item.implicitHeight : (Theme.barHeight - 8))

        Behavior on width {
            enabled: !bwl.isVertical
            NumberAnimation { duration: Theme.animNormal; easing.type: Theme.animEasing }
        }
        Behavior on height {
            enabled: bwl.isVertical
            NumberAnimation { duration: Theme.animNormal; easing.type: Theme.animEasing }
        }
        Behavior on opacity {
            NumberAnimation { duration: Theme.animFast; easing.type: Theme.animEasing }
        }
    }

    Item {
        id: barRootItem
        anchors.fill: parent

        // bar background body
        Rectangle {
            id: barBg
            x: root.isRight ? root.scoopW : 0
            y: root.isBottom ? root.scoopH : 0
            width: root.isVertical ? Theme.barHeight : barRootItem.width
            height: root.isVertical ? barRootItem.height : Theme.barHeight
            color: Theme.barBg
            border.width: 0

            // glowing neon accent line facing workspaces
            Rectangle {
                visible: Settings?.barStyle === "accent-glow"
                x: root.isLeft ? parent.width - 2 : 0
                y: root.isTop ? parent.height - 2 : 0
                width: root.isVertical ? 2 : parent.width
                height: root.isVertical ? parent.height : 2
                color: Theme.primary
                opacity: 0.90
            }
        }

        // horizontal bar layout (up / down)
        Item {
            id: horizontalBarContent
            x: barBg.x
            y: barBg.y
            width: barBg.width
            height: barBg.height
            visible: !root.isVertical

            // dynamic spatial clearance metrics with hysteresis
            readonly property real rawClearance: Math.max(0, rightRow.x - (leftRow.x + leftRow.width))
            property bool isCrowded: false
            property bool isVeryCrowded: false

            onRawClearanceChanged: {
                if (!isCrowded && rawClearance < 160) {
                    isCrowded = true;
                } else if (isCrowded && rawClearance > 280) {
                    isCrowded = false;
                }

                if (!isVeryCrowded && rawClearance < 80) {
                    isVeryCrowded = true;
                } else if (isVeryCrowded && rawClearance > 180) {
                    isVeryCrowded = false;
                }
            }

            // left widgets
            Row {
                id: leftRow
                anchors.left: parent.left
                anchors.leftMargin: Theme.widgetPaddingH
                anchors.verticalCenter: parent.verticalCenter
                spacing: Theme.widgetSpacing

                LauncherButton {}

                BarWidgetLoader {
                    active: (Settings?.showWallpaper ?? true) && !root.isVertical
                    crowdSensitive: true
                    crowded: horizontalBarContent.isCrowded
                    anchors.verticalCenter: parent.verticalCenter
                    sourceComponent: Component { WallpaperBrowser {} }
                }

                Loader {
                    active: (Settings?.showWorkspaces ?? true) && !root.isVertical
                    visible: active
                    width: item ? item.implicitWidth : (Theme.barHeight - 8)
                    height: item ? item.implicitHeight : (Theme.barHeight - 8)
                    anchors.verticalCenter: parent.verticalCenter
                    sourceComponent: Component { Workspaces {} }
                }

                BarWidgetLoader {
                    active: (Settings?.showWindowTitle ?? true) && !root.isVertical
                    veryCrowdSensitive: true
                    veryCrowded: horizontalBarContent.isVeryCrowded
                    anchors.verticalCenter: parent.verticalCenter
                    sourceComponent: Component {
                        WindowTitle {
                            maxWidth: horizontalBarContent.isCrowded ? 110 : 220
                        }
                    }
                }
            }

            // center clock with dynamic collision avoidance and compacting
            Loader {
                id: centerClockLoader
                active: (Settings?.showClock ?? true) && !root.isVertical
                visible: active
                width: item ? item.implicitWidth : 100
                height: item ? item.implicitHeight : (Theme.barHeight - 8)
                sourceComponent: Component {
                    Clock {
                        compactMode: horizontalBarContent.isCrowded
                    }
                }

                readonly property real idealX: (parent.width - width) / 2
                readonly property real minX: (leftRow && leftRow.width > 0) ? (leftRow.x + leftRow.width + (Theme.widgetSpacing * 2)) : Theme.widgetPaddingH
                readonly property real maxX: (rightRow && rightRow.width > 0) ? (rightRow.x - width - (Theme.widgetSpacing * 2)) : (parent.width - width - Theme.widgetPaddingH)

                x: {
                    if (maxX <= minX) {
                        return (minX + maxX) / 2;
                    }
                    return Math.max(minX, Math.min(idealX, maxX));
                }
                y: (parent.height - height) / 2

                opacity: (maxX < minX - 10) ? 0.3 : 1.0

                Behavior on x {
                    NumberAnimation { duration: Theme.animNormal; easing.type: Theme.animEasing }
                }
                Behavior on opacity {
                    NumberAnimation { duration: Theme.animNormal }
                }
            }

            // right widgets
            Row {
                id: rightRow
                anchors.right: parent.right
                anchors.rightMargin: Theme.widgetPaddingH
                anchors.verticalCenter: parent.verticalCenter
                spacing: Theme.widgetSpacing
                layoutDirection: Qt.RightToLeft

                BarWidgetLoader {
                    active: (Settings?.showPowerMenu ?? true) && !root.isVertical
                    anchors.verticalCenter: parent.verticalCenter
                    sourceComponent: Component { PowerMenu {} }
                }

                BarWidgetLoader {
                    active: (Settings?.showQuickSettings ?? true) && !root.isVertical
                    anchors.verticalCenter: parent.verticalCenter
                    sourceComponent: Component { QuickSettings {} }
                }

                BarWidgetLoader {
                    active: (Settings?.showBattery ?? true) && !root.isVertical
                    anchors.verticalCenter: parent.verticalCenter
                    sourceComponent: Component { Battery {} }
                }

                BarWidgetLoader {
                    active: (Settings?.showVolume ?? true) && !root.isVertical
                    anchors.verticalCenter: parent.verticalCenter
                    sourceComponent: Component { VolumeControl {} }
                }

                BarWidgetLoader {
                    active: (Settings?.showNetwork ?? true) && !root.isVertical
                    anchors.verticalCenter: parent.verticalCenter
                    sourceComponent: Component { NetworkStatus {} }
                }

                BarWidgetLoader {
                    active: (Settings?.showBluetooth ?? true) && !root.isVertical
                    veryCrowdSensitive: true
                    veryCrowded: horizontalBarContent.isVeryCrowded
                    requiresDevice: true
                    hasDevice: item?.hasConnectedDevice ?? false
                    anchors.verticalCenter: parent.verticalCenter
                    sourceComponent: Component { Bluetooth {} }
                }

                BarWidgetLoader {
                    active: (Settings?.showSystemTray ?? true) && !root.isVertical
                    requiresDevice: true
                    hasDevice: item?.visible ?? false
                    anchors.verticalCenter: parent.verticalCenter
                    sourceComponent: Component { SystemTray {} }
                }

                BarWidgetLoader {
                    active: (Settings?.showNotifications ?? true) && !root.isVertical
                    veryCrowdSensitive: true
                    veryCrowded: horizontalBarContent.isVeryCrowded
                    requiresCount: true
                    count: item?.notifCount ?? 0
                    anchors.verticalCenter: parent.verticalCenter
                    sourceComponent: Component { Notifications {} }
                }

                BarWidgetLoader {
                    active: (Settings?.showIdleInhibitor ?? true) && !root.isVertical
                    crowdSensitive: true
                    crowded: horizontalBarContent.isCrowded
                    requiresDevice: true
                    hasDevice: item?.active ?? false
                    anchors.verticalCenter: parent.verticalCenter
                    sourceComponent: Component { IdleInhibitor {} }
                }

                BarWidgetLoader {
                    active: (Settings?.showClipboard ?? true) && !root.isVertical
                    crowdSensitive: true
                    crowded: horizontalBarContent.isCrowded
                    anchors.verticalCenter: parent.verticalCenter
                    sourceComponent: Component { Clipboard {} }
                }

                BarWidgetLoader {
                    active: (Settings?.showQuickNotes ?? true) && !root.isVertical
                    crowdSensitive: true
                    crowded: horizontalBarContent.isCrowded
                    anchors.verticalCenter: parent.verticalCenter
                    sourceComponent: Component { QuickNotes {} }
                }

                Loader {
                    id: mediaLoaderH
                    active: (Settings?.showMedia ?? true) && !root.isVertical
                    visible: active
                    width: item ? item.implicitWidth : (Theme.barHeight - 8)
                    height: item ? item.implicitHeight : (Theme.barHeight - 8)
                    anchors.verticalCenter: parent.verticalCenter
                    clip: true

                    Behavior on width { NumberAnimation { duration: Theme.animNormal; easing.type: Theme.animEasing } }

                    sourceComponent: Component {
                        NowPlaying {
                            compactMode: horizontalBarContent.isCrowded
                        }
                    }
                }
            }
        }

        // vertical bar layout (left / right)
        Item {
            id: verticalBarContent
            x: barBg.x
            y: barBg.y
            width: barBg.width
            height: barBg.height
            visible: root.isVertical

            // vertical clearance metrics with hysteresis
            readonly property real rawClearanceV: Math.max(0, botCol.y - (topCol.y + topCol.height))
            property bool isCrowdedV: false
            property bool isVeryCrowdedV: false

            onRawClearanceVChanged: {
                if (!isCrowdedV && rawClearanceV < 140) {
                    isCrowdedV = true;
                } else if (isCrowdedV && rawClearanceV > 240) {
                    isCrowdedV = false;
                }

                if (!isVeryCrowdedV && rawClearanceV < 70) {
                    isVeryCrowdedV = true;
                } else if (isVeryCrowdedV && rawClearanceV > 160) {
                    isVeryCrowdedV = false;
                }
            }

            // top widgets
            Column {
                id: topCol
                anchors.top: parent.top
                anchors.topMargin: Theme.widgetPaddingH
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Theme.widgetSpacing

                LauncherButton {}

                BarWidgetLoader {
                    active: (Settings?.showWallpaper ?? true) && root.isVertical
                    crowdSensitive: true
                    crowded: verticalBarContent.isCrowdedV
                    anchors.horizontalCenter: parent.horizontalCenter
                    sourceComponent: Component { WallpaperBrowser {} }
                }

                Loader {
                    active: (Settings?.showWorkspaces ?? true) && root.isVertical
                    visible: active
                    width: item ? item.implicitWidth : (Theme.barHeight - 8)
                    height: item ? item.implicitHeight : (Theme.barHeight - 8)
                    anchors.horizontalCenter: parent.horizontalCenter
                    sourceComponent: Component { Workspaces {} }
                }
            }

            // center clock with dynamic vertical collision avoidance and compacting
            Loader {
                id: centerClockVLoader
                active: (Settings?.showClock ?? true) && root.isVertical
                visible: active
                width: item ? item.implicitWidth : (Theme.barHeight - 8)
                height: item ? item.implicitHeight : 38
                sourceComponent: Component {
                    Clock {
                        compactMode: verticalBarContent.isCrowdedV
                    }
                }

                readonly property real idealY: (parent.height - height) / 2
                readonly property real minY: (topCol && topCol.height > 0) ? (topCol.y + topCol.height + (Theme.widgetSpacing * 2)) : Theme.widgetPaddingH
                readonly property real maxY: (botCol && botCol.height > 0) ? (botCol.y - height - (Theme.widgetSpacing * 2)) : (parent.height - height - Theme.widgetPaddingH)

                y: {
                    if (maxY <= minY) {
                        return (minY + maxY) / 2;
                    }
                    return Math.max(minY, Math.min(idealY, maxY));
                }
                x: (parent.width - width) / 2

                opacity: (maxY < minY - 10) ? 0.3 : 1.0

                Behavior on y {
                    NumberAnimation { duration: Theme.animNormal; easing.type: Theme.animEasing }
                }
                Behavior on opacity {
                    NumberAnimation { duration: Theme.animNormal }
                }
            }

            // bottom widgets
            Column {
                id: botCol
                anchors.bottom: parent.bottom
                anchors.bottomMargin: Theme.widgetPaddingH
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Theme.widgetSpacing

                Loader {
                    active: (Settings?.showMedia ?? true) && root.isVertical
                    visible: active
                    width: item ? item.implicitWidth : (Theme.barHeight - 8)
                    height: item ? item.implicitHeight : (Theme.barHeight - 8)
                    anchors.horizontalCenter: parent.horizontalCenter
                    sourceComponent: Component {
                        NowPlaying {
                            compactMode: verticalBarContent.isCrowdedV
                        }
                    }
                }

                BarWidgetLoader {
                    active: (Settings?.showClipboard ?? true) && root.isVertical
                    crowdSensitive: true
                    crowded: verticalBarContent.isCrowdedV
                    anchors.horizontalCenter: parent.horizontalCenter
                    sourceComponent: Component { Clipboard {} }
                }

                BarWidgetLoader {
                    active: (Settings?.showIdleInhibitor ?? true) && root.isVertical
                    crowdSensitive: true
                    crowded: verticalBarContent.isCrowdedV
                    requiresDevice: true
                    hasDevice: item?.active ?? false
                    anchors.horizontalCenter: parent.horizontalCenter
                    sourceComponent: Component { IdleInhibitor {} }
                }

                BarWidgetLoader {
                    active: (Settings?.showNotifications ?? true) && root.isVertical
                    veryCrowdSensitive: true
                    veryCrowded: verticalBarContent.isVeryCrowdedV
                    requiresCount: true
                    count: item?.notifCount ?? 0
                    anchors.horizontalCenter: parent.horizontalCenter
                    sourceComponent: Component { Notifications {} }
                }

                BarWidgetLoader {
                    active: (Settings?.showSystemTray ?? true) && root.isVertical
                    requiresDevice: true
                    hasDevice: item?.visible ?? false
                    anchors.horizontalCenter: parent.horizontalCenter
                    sourceComponent: Component { SystemTray {} }
                }

                BarWidgetLoader {
                    active: (Settings?.showBluetooth ?? true) && root.isVertical
                    veryCrowdSensitive: true
                    veryCrowded: verticalBarContent.isVeryCrowdedV
                    requiresDevice: true
                    hasDevice: item?.hasConnectedDevice ?? false
                    anchors.horizontalCenter: parent.horizontalCenter
                    sourceComponent: Component { Bluetooth {} }
                }

                BarWidgetLoader {
                    active: (Settings?.showNetwork ?? true) && root.isVertical
                    anchors.horizontalCenter: parent.horizontalCenter
                    sourceComponent: Component { NetworkStatus {} }
                }

                BarWidgetLoader {
                    active: (Settings?.showVolume ?? true) && root.isVertical
                    anchors.horizontalCenter: parent.horizontalCenter
                    sourceComponent: Component { VolumeControl {} }
                }

                BarWidgetLoader {
                    active: (Settings?.showBattery ?? true) && root.isVertical
                    anchors.horizontalCenter: parent.horizontalCenter
                    sourceComponent: Component { Battery {} }
                }

                BarWidgetLoader {
                    active: (Settings?.showQuickSettings ?? true) && root.isVertical
                    anchors.horizontalCenter: parent.horizontalCenter
                    sourceComponent: Component { QuickSettings {} }
                }

                BarWidgetLoader {
                    active: (Settings?.showQuickNotes ?? true) && root.isVertical
                    crowdSensitive: true
                    crowded: verticalBarContent.isCrowdedV
                    anchors.horizontalCenter: parent.horizontalCenter
                    sourceComponent: Component { QuickNotes {} }
                }

                BarWidgetLoader {
                    active: (Settings?.showPowerMenu ?? true) && root.isVertical
                    anchors.horizontalCenter: parent.horizontalCenter
                    sourceComponent: Component { PowerMenu {} }
                }
            }
        }

        // top bar edge scoops
        ConcaveCorner {
            y: barBg.height
            anchors.left: parent.left
            radiusX: root.scoopW
            radiusY: root.scoopH
            fillColor: Theme.cornerFill
            flipX: false
            flipY: false
            visible: root.isTop && root.scoopW > 0
        }
        ConcaveCorner {
            y: barBg.height
            anchors.right: parent.right
            radiusX: root.scoopW
            radiusY: root.scoopH
            fillColor: Theme.cornerFill
            flipX: true
            flipY: false
            visible: root.isTop && root.scoopW > 0
        }

        // bottom bar edge scoops
        ConcaveCorner {
            y: 0
            anchors.left: parent.left
            radiusX: root.scoopW
            radiusY: root.scoopH
            fillColor: Theme.cornerFill
            flipX: false
            flipY: true
            visible: root.isBottom && root.scoopW > 0
        }
        ConcaveCorner {
            y: 0
            anchors.right: parent.right
            radiusX: root.scoopW
            radiusY: root.scoopH
            fillColor: Theme.cornerFill
            flipX: true
            flipY: true
            visible: root.isBottom && root.scoopW > 0
        }

        // left bar edge scoops
        ConcaveCorner {
            x: barBg.width
            anchors.top: parent.top
            radiusX: root.scoopW
            radiusY: root.scoopH
            fillColor: Theme.cornerFill
            flipX: false
            flipY: false
            visible: root.isLeft && root.scoopW > 0
        }
        ConcaveCorner {
            x: barBg.width
            anchors.bottom: parent.bottom
            radiusX: root.scoopW
            radiusY: root.scoopH
            fillColor: Theme.cornerFill
            flipX: false
            flipY: true
            visible: root.isLeft && root.scoopW > 0
        }

        // right bar edge scoops
        ConcaveCorner {
            x: 0
            anchors.top: parent.top
            radiusX: root.scoopW
            radiusY: root.scoopH
            fillColor: Theme.cornerFill
            flipX: true
            flipY: false
            visible: root.isRight && root.scoopW > 0
        }
        ConcaveCorner {
            x: 0
            anchors.bottom: parent.bottom
            radiusX: root.scoopW
            radiusY: root.scoopH
            fillColor: Theme.cornerFill
            flipX: true
            flipY: true
            visible: root.isRight && root.scoopW > 0
        }
    }
}