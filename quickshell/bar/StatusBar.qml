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
            readonly property bool isCrowded: rawClearance < (wasCrowded ? 280 : 160)
            property bool wasCrowded: false
            onIsCrowdedChanged: wasCrowded = isCrowded

            readonly property bool isVeryCrowded: rawClearance < (wasVeryCrowded ? 180 : 80)
            property bool wasVeryCrowded: false
            onIsVeryCrowdedChanged: wasVeryCrowded = isVeryCrowded

            // left widgets
            Row {
                id: leftRow
                anchors.left: parent.left
                anchors.leftMargin: Theme.widgetPaddingH
                anchors.verticalCenter: parent.verticalCenter
                spacing: Theme.widgetSpacing

                Rectangle {
                    id: launcherBtnH
                    visible: Settings?.showLauncher ?? true
                    width: Math.max(36, launcherTextH.implicitWidth + 16)
                    height: Theme.barHeight - 8
                    radius: Theme.radiusPill
                    color: lMouseH.pressed ? Theme.widgetActive : lMouseH.containsMouse ? Theme.pillHover : (launcherPopup.open ? Theme.primary_overlay : Theme.pillBg)
                    border.color: Theme.pillBorder
                    border.width: Theme.pillBorder === "transparent" ? 0 : 1

                    Behavior on color { ColorAnimation { duration: Theme.animFast } }
                    Behavior on border.color { ColorAnimation { duration: Theme.animFast } }

                    Text {
                        id: launcherTextH
                        anchors.centerIn: parent
                        text: Theme.iconArch
                        font.family: Theme.fontIcon
                        font.pixelSize: (Theme.iconSet === "kaomoji" || Theme.iconSet === "text") ? Theme.fontSizeSm : Theme.fontSizeLg
                        color: launcherPopup.open ? Theme.primary : Theme.on_surface
                    }

                    MouseArea {
                        id: lMouseH
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            launcherPopup.targetRelativeX = launcherBtnH.mapToItem(null, 0, 0).x + (launcherBtnH.width / 2);
                            launcherPopup.open = !launcherPopup.open;
                        }
                    }
                }

                Loader {
                    id: wpLoaderH
                    active: (Settings?.showWallpaper ?? true) && !root.isVertical
                    readonly property bool shouldShow: active && (!horizontalBarContent.isCrowded || (item && item.popup && item.popup.open))
                    visible: shouldShow || width > 0.5
                    opacity: shouldShow ? 1 : 0
                    width: shouldShow ? (item ? item.implicitWidth : (Theme.barHeight - 8)) : 0
                    height: item ? item.implicitHeight : (Theme.barHeight - 8)
                    anchors.verticalCenter: parent.verticalCenter
                    clip: true

                    Behavior on width { NumberAnimation { duration: Theme.animNormal; easing.type: Theme.animEasing } }
                    Behavior on opacity { NumberAnimation { duration: Theme.animFast; easing.type: Theme.animEasing } }

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

                Loader {
                    id: winTitleLoaderH
                    active: (Settings?.showWindowTitle ?? true) && !root.isVertical
                    readonly property bool shouldShow: active && !horizontalBarContent.isVeryCrowded
                    visible: shouldShow || width > 0.5
                    opacity: shouldShow ? 1 : 0
                    width: shouldShow ? (item ? item.implicitWidth : 0) : 0
                    height: item ? item.implicitHeight : (Theme.barHeight - 8)
                    anchors.verticalCenter: parent.verticalCenter
                    clip: true

                    Behavior on width { NumberAnimation { duration: Theme.animNormal; easing.type: Theme.animEasing } }
                    Behavior on opacity { NumberAnimation { duration: Theme.animFast; easing.type: Theme.animEasing } }

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

                Loader {
                    active: (Settings?.showPowerMenu ?? true) && !root.isVertical
                    visible: active
                    width: item ? item.implicitWidth : (Theme.barHeight - 8)
                    height: item ? item.implicitHeight : (Theme.barHeight - 8)
                    anchors.verticalCenter: parent.verticalCenter
                    sourceComponent: Component { PowerMenu {} }
                }

                Loader {
                    active: (Settings?.showQuickSettings ?? true) && !root.isVertical
                    visible: active
                    width: item ? item.implicitWidth : (Theme.barHeight - 8)
                    height: item ? item.implicitHeight : (Theme.barHeight - 8)
                    anchors.verticalCenter: parent.verticalCenter
                    sourceComponent: Component { QuickSettings {} }
                }

                Loader {
                    active: (Settings?.showBattery ?? true) && !root.isVertical
                    visible: active
                    width: item ? item.implicitWidth : (Theme.barHeight - 8)
                    height: item ? item.implicitHeight : (Theme.barHeight - 8)
                    anchors.verticalCenter: parent.verticalCenter
                    sourceComponent: Component { Battery {} }
                }

                Loader {
                    active: (Settings?.showVolume ?? true) && !root.isVertical
                    visible: active
                    width: item ? item.implicitWidth : (Theme.barHeight - 8)
                    height: item ? item.implicitHeight : (Theme.barHeight - 8)
                    anchors.verticalCenter: parent.verticalCenter
                    sourceComponent: Component { VolumeControl {} }
                }

                Loader {
                    active: (Settings?.showNetwork ?? true) && !root.isVertical
                    visible: active
                    width: item ? item.implicitWidth : (Theme.barHeight - 8)
                    height: item ? item.implicitHeight : (Theme.barHeight - 8)
                    anchors.verticalCenter: parent.verticalCenter
                    sourceComponent: Component { NetworkStatus {} }
                }

                Loader {
                    id: btLoaderH
                    active: (Settings?.showBluetooth ?? true) && !root.isVertical
                    readonly property bool shouldShow: active && (!horizontalBarContent.isVeryCrowded || (item && (item.hasConnectedDevice || (item.popup && item.popup.open))))
                    visible: shouldShow || width > 0.5
                    opacity: shouldShow ? 1 : 0
                    width: shouldShow ? (item ? item.implicitWidth : (Theme.barHeight - 8)) : 0
                    height: item ? item.implicitHeight : (Theme.barHeight - 8)
                    anchors.verticalCenter: parent.verticalCenter
                    clip: true

                    Behavior on width { NumberAnimation { duration: Theme.animNormal; easing.type: Theme.animEasing } }
                    Behavior on opacity { NumberAnimation { duration: Theme.animFast; easing.type: Theme.animEasing } }

                    sourceComponent: Component { Bluetooth {} }
                }

                Loader {
                    id: sysTrayLoaderH
                    active: (Settings?.showSystemTray ?? true) && !root.isVertical
                    visible: active && (item ? (item.visible && item.implicitWidth > 0) : false)
                    width: (item && visible) ? item.implicitWidth : 0
                    height: item ? item.implicitHeight : (Theme.barHeight - 8)
                    anchors.verticalCenter: parent.verticalCenter
                    clip: true

                    Behavior on width { NumberAnimation { duration: Theme.animNormal; easing.type: Theme.animEasing } }

                    sourceComponent: Component { SystemTray {} }
                }

                Loader {
                    id: notifLoaderH
                    active: (Settings?.showNotifications ?? true) && !root.isVertical
                    readonly property bool shouldShow: active && (!horizontalBarContent.isVeryCrowded || (item && (item.notifCount > 0 || (item.popup && item.popup.open))))
                    visible: shouldShow || width > 0.5
                    opacity: shouldShow ? 1 : 0
                    width: shouldShow ? (item ? item.implicitWidth : (Theme.barHeight - 8)) : 0
                    height: item ? item.implicitHeight : (Theme.barHeight - 8)
                    anchors.verticalCenter: parent.verticalCenter
                    clip: true

                    Behavior on width { NumberAnimation { duration: Theme.animNormal; easing.type: Theme.animEasing } }
                    Behavior on opacity { NumberAnimation { duration: Theme.animFast; easing.type: Theme.animEasing } }

                    sourceComponent: Component { Notifications {} }
                }

                Loader {
                    id: idleInhibitorLoaderH
                    active: (Settings?.showIdleInhibitor ?? true) && !root.isVertical
                    readonly property bool shouldShow: active && (!horizontalBarContent.isCrowded || (item && item.active))
                    visible: shouldShow || width > 0.5
                    opacity: shouldShow ? 1 : 0
                    width: shouldShow ? (item ? item.implicitWidth : (Theme.barHeight - 8)) : 0
                    height: item ? item.implicitHeight : (Theme.barHeight - 8)
                    anchors.verticalCenter: parent.verticalCenter
                    clip: true

                    Behavior on width { NumberAnimation { duration: Theme.animNormal; easing.type: Theme.animEasing } }
                    Behavior on opacity { NumberAnimation { duration: Theme.animFast; easing.type: Theme.animEasing } }

                    sourceComponent: Component { IdleInhibitor {} }
                }

                Loader {
                    id: clipLoaderH
                    active: (Settings?.showClipboard ?? true) && !root.isVertical
                    readonly property bool shouldShow: active && (!horizontalBarContent.isCrowded || (item && item.popup && item.popup.open))
                    visible: shouldShow || width > 0.5
                    opacity: shouldShow ? 1 : 0
                    width: shouldShow ? (item ? item.implicitWidth : (Theme.barHeight - 8)) : 0
                    height: item ? item.implicitHeight : (Theme.barHeight - 8)
                    anchors.verticalCenter: parent.verticalCenter
                    clip: true

                    Behavior on width { NumberAnimation { duration: Theme.animNormal; easing.type: Theme.animEasing } }
                    Behavior on opacity { NumberAnimation { duration: Theme.animFast; easing.type: Theme.animEasing } }

                    sourceComponent: Component { Clipboard {} }
                }

                Loader {
                    id: notesLoaderH
                    active: (Settings?.showQuickNotes ?? true) && !root.isVertical
                    readonly property bool shouldShow: active && (!horizontalBarContent.isCrowded || (item && item.popup && item.popup.open))
                    visible: shouldShow || width > 0.5
                    opacity: shouldShow ? 1 : 0
                    width: shouldShow ? (item ? item.implicitWidth : (Theme.barHeight - 8)) : 0
                    height: item ? item.implicitHeight : (Theme.barHeight - 8)
                    anchors.verticalCenter: parent.verticalCenter
                    clip: true

                    Behavior on width { NumberAnimation { duration: Theme.animNormal; easing.type: Theme.animEasing } }
                    Behavior on opacity { NumberAnimation { duration: Theme.animFast; easing.type: Theme.animEasing } }

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
            readonly property bool isCrowdedV: rawClearanceV < (wasCrowdedV ? 240 : 140)
            property bool wasCrowdedV: false
            onIsCrowdedVChanged: wasCrowdedV = isCrowdedV

            readonly property bool isVeryCrowdedV: rawClearanceV < (wasVeryCrowdedV ? 160 : 70)
            property bool wasVeryCrowdedV: false
            onIsVeryCrowdedVChanged: wasVeryCrowdedV = isVeryCrowdedV

            // top widgets
            Column {
                id: topCol
                anchors.top: parent.top
                anchors.topMargin: Theme.widgetPaddingH
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Theme.widgetSpacing

                Rectangle {
                    id: launcherBtnV
                    visible: Settings?.showLauncher ?? true
                    width: Theme.barHeight - 8
                    height: Math.max(36, launcherTextV.implicitHeight + 12)
                    radius: Theme.radiusPill
                    color: lMouseV.pressed ? Theme.widgetActive : lMouseV.containsMouse ? Theme.pillHover : (launcherPopup.open ? Theme.primary_overlay : Theme.pillBg)
                    border.color: Theme.pillBorder
                    border.width: Theme.pillBorder === "transparent" ? 0 : 1

                    Behavior on color { ColorAnimation { duration: Theme.animFast } }
                    Behavior on border.color { ColorAnimation { duration: Theme.animFast } }

                    Text {
                        id: launcherTextV
                        anchors.centerIn: parent
                        text: Theme.iconArch
                        font.family: Theme.fontIcon
                        font.pixelSize: (Theme.iconSet === "kaomoji" || Theme.iconSet === "text") ? Theme.fontSizeXs : Theme.fontSizeLg
                        color: launcherPopup.open ? Theme.primary : Theme.on_surface
                    }

                    MouseArea {
                        id: lMouseV
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            launcherPopup.targetRelativeY = launcherBtnV.mapToItem(null, 0, 0).y + (launcherBtnV.height / 2);
                            launcherPopup.open = !launcherPopup.open;
                        }
                    }
                }

                Loader {
                    id: wpLoaderV
                    active: (Settings?.showWallpaper ?? true) && root.isVertical
                    readonly property bool shouldShow: active && (!verticalBarContent.isCrowdedV || (item && item.popup && item.popup.open))
                    visible: shouldShow || height > 0.5
                    opacity: shouldShow ? 1 : 0
                    width: item ? item.implicitWidth : (Theme.barHeight - 8)
                    height: shouldShow ? (item ? item.implicitHeight : (Theme.barHeight - 8)) : 0
                    anchors.horizontalCenter: parent.horizontalCenter
                    clip: true

                    Behavior on height { NumberAnimation { duration: Theme.animNormal; easing.type: Theme.animEasing } }
                    Behavior on opacity { NumberAnimation { duration: Theme.animFast; easing.type: Theme.animEasing } }

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
                    id: mediaLoaderV
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

                Loader {
                    id: clipLoaderV
                    active: (Settings?.showClipboard ?? true) && root.isVertical
                    readonly property bool shouldShow: active && (!verticalBarContent.isCrowdedV || (item && item.popup && item.popup.open))
                    visible: shouldShow || height > 0.5
                    opacity: shouldShow ? 1 : 0
                    width: item ? item.implicitWidth : (Theme.barHeight - 8)
                    height: shouldShow ? (item ? item.implicitHeight : (Theme.barHeight - 8)) : 0
                    anchors.horizontalCenter: parent.horizontalCenter
                    clip: true

                    Behavior on height { NumberAnimation { duration: Theme.animNormal; easing.type: Theme.animEasing } }
                    Behavior on opacity { NumberAnimation { duration: Theme.animFast; easing.type: Theme.animEasing } }

                    sourceComponent: Component { Clipboard {} }
                }

                Loader {
                    id: idleInhibitorLoaderV
                    active: (Settings?.showIdleInhibitor ?? true) && root.isVertical
                    readonly property bool shouldShow: active && (!verticalBarContent.isCrowdedV || (item && item.active))
                    visible: shouldShow || height > 0.5
                    opacity: shouldShow ? 1 : 0
                    width: item ? item.implicitWidth : (Theme.barHeight - 8)
                    height: shouldShow ? (item ? item.implicitHeight : (Theme.barHeight - 8)) : 0
                    anchors.horizontalCenter: parent.horizontalCenter
                    clip: true

                    Behavior on height { NumberAnimation { duration: Theme.animNormal; easing.type: Theme.animEasing } }
                    Behavior on opacity { NumberAnimation { duration: Theme.animFast; easing.type: Theme.animEasing } }

                    sourceComponent: Component { IdleInhibitor {} }
                }

                Loader {
                    id: notifLoaderV
                    active: (Settings?.showNotifications ?? true) && root.isVertical
                    readonly property bool shouldShow: active && (!verticalBarContent.isVeryCrowdedV || (item && (item.notifCount > 0 || (item.popup && item.popup.open))))
                    visible: shouldShow || height > 0.5
                    opacity: shouldShow ? 1 : 0
                    width: item ? item.implicitWidth : (Theme.barHeight - 8)
                    height: shouldShow ? (item ? item.implicitHeight : (Theme.barHeight - 8)) : 0
                    anchors.horizontalCenter: parent.horizontalCenter
                    clip: true

                    Behavior on height { NumberAnimation { duration: Theme.animNormal; easing.type: Theme.animEasing } }
                    Behavior on opacity { NumberAnimation { duration: Theme.animFast; easing.type: Theme.animEasing } }

                    sourceComponent: Component { Notifications {} }
                }

                Loader {
                    id: sysTrayLoaderV
                    active: (Settings?.showSystemTray ?? true) && root.isVertical
                    visible: active && (item ? (item.visible && item.implicitHeight > 0) : false)
                    width: item ? item.implicitWidth : (Theme.barHeight - 8)
                    height: (item && visible) ? item.implicitHeight : 0
                    anchors.horizontalCenter: parent.horizontalCenter
                    clip: true

                    Behavior on height { NumberAnimation { duration: Theme.animNormal; easing.type: Theme.animEasing } }

                    sourceComponent: Component { SystemTray {} }
                }

                Loader {
                    id: btLoaderV
                    active: (Settings?.showBluetooth ?? true) && root.isVertical
                    readonly property bool shouldShow: active && (!verticalBarContent.isVeryCrowdedV || (item && (item.hasConnectedDevice || (item.popup && item.popup.open))))
                    visible: shouldShow || height > 0.5
                    opacity: shouldShow ? 1 : 0
                    width: item ? item.implicitWidth : (Theme.barHeight - 8)
                    height: shouldShow ? (item ? item.implicitHeight : (Theme.barHeight - 8)) : 0
                    anchors.horizontalCenter: parent.horizontalCenter
                    clip: true

                    Behavior on height { NumberAnimation { duration: Theme.animNormal; easing.type: Theme.animEasing } }
                    Behavior on opacity { NumberAnimation { duration: Theme.animFast; easing.type: Theme.animEasing } }

                    sourceComponent: Component { Bluetooth {} }
                }

                Loader {
                    active: (Settings?.showNetwork ?? true) && root.isVertical
                    visible: active
                    width: item ? item.implicitWidth : (Theme.barHeight - 8)
                    height: item ? item.implicitHeight : (Theme.barHeight - 8)
                    anchors.horizontalCenter: parent.horizontalCenter
                    sourceComponent: Component { NetworkStatus {} }
                }

                Loader {
                    active: (Settings?.showVolume ?? true) && root.isVertical
                    visible: active
                    width: item ? item.implicitWidth : (Theme.barHeight - 8)
                    height: item ? item.implicitHeight : (Theme.barHeight - 8)
                    anchors.horizontalCenter: parent.horizontalCenter
                    sourceComponent: Component { VolumeControl {} }
                }

                Loader {
                    active: (Settings?.showBattery ?? true) && root.isVertical
                    visible: active
                    width: item ? item.implicitWidth : (Theme.barHeight - 8)
                    height: item ? item.implicitHeight : (Theme.barHeight - 8)
                    anchors.horizontalCenter: parent.horizontalCenter
                    sourceComponent: Component { Battery {} }
                }

                Loader {
                    active: (Settings?.showQuickSettings ?? true) && root.isVertical
                    visible: active
                    width: item ? item.implicitWidth : (Theme.barHeight - 8)
                    height: item ? item.implicitHeight : (Theme.barHeight - 8)
                    anchors.horizontalCenter: parent.horizontalCenter
                    sourceComponent: Component { QuickSettings {} }
                }

                Loader {
                    id: notesLoaderV
                    active: (Settings?.showQuickNotes ?? true) && root.isVertical
                    readonly property bool shouldShow: active && (!verticalBarContent.isCrowdedV || (item && item.popup && item.popup.open))
                    visible: shouldShow || height > 0.5
                    opacity: shouldShow ? 1 : 0
                    width: item ? item.implicitWidth : (Theme.barHeight - 8)
                    height: shouldShow ? (item ? item.implicitHeight : (Theme.barHeight - 8)) : 0
                    anchors.horizontalCenter: parent.horizontalCenter
                    clip: true

                    Behavior on height { NumberAnimation { duration: Theme.animNormal; easing.type: Theme.animEasing } }
                    Behavior on opacity { NumberAnimation { duration: Theme.animFast; easing.type: Theme.animEasing } }

                    sourceComponent: Component { QuickNotes {} }
                }

                Loader {
                    active: (Settings?.showPowerMenu ?? true) && root.isVertical
                    visible: active
                    width: item ? item.implicitWidth : (Theme.barHeight - 8)
                    height: item ? item.implicitHeight : (Theme.barHeight - 8)
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
            fillColor: barBg.color
            flipX: false
            flipY: false
            visible: root.isTop && root.scoopW > 0
        }
        ConcaveCorner {
            y: barBg.height
            anchors.right: parent.right
            radiusX: root.scoopW
            radiusY: root.scoopH
            fillColor: barBg.color
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
            fillColor: barBg.color
            flipX: false
            flipY: true
            visible: root.isBottom && root.scoopW > 0
        }
        ConcaveCorner {
            y: 0
            anchors.right: parent.right
            radiusX: root.scoopW
            radiusY: root.scoopH
            fillColor: barBg.color
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
            fillColor: barBg.color
            flipX: false
            flipY: false
            visible: root.isLeft && root.scoopW > 0
        }
        ConcaveCorner {
            x: barBg.width
            anchors.bottom: parent.bottom
            radiusX: root.scoopW
            radiusY: root.scoopH
            fillColor: barBg.color
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
            fillColor: barBg.color
            flipX: true
            flipY: false
            visible: root.isRight && root.scoopW > 0
        }
        ConcaveCorner {
            x: 0
            anchors.bottom: parent.bottom
            radiusX: root.scoopW
            radiusY: root.scoopH
            fillColor: barBg.color
            flipX: true
            flipY: true
            visible: root.isRight && root.scoopW > 0
        }
    }
}