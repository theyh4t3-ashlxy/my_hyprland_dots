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
            x: barBg.x
            y: barBg.y
            width: barBg.width
            height: barBg.height
            visible: !root.isVertical

            // left widgets
            Row {
                anchors.left: parent.left
                anchors.leftMargin: Theme.widgetPaddingH
                anchors.verticalCenter: parent.verticalCenter
                spacing: Theme.widgetSpacing

                Rectangle {
                    id: launcherBtnH
                    visible: Settings?.showLauncher ?? true
                    width: 36
                    height: Theme.barHeight - 8
                    radius: Theme.radiusPill
                    color: lMouseH.pressed ? Theme.widgetActive : lMouseH.containsMouse ? Theme.pillHover : (launcherPopup.open ? Theme.primary_overlay : Theme.pillBg)
                    border.color: Theme.pillBorder
                    border.width: Theme.pillBorder === "transparent" ? 0 : 1

                    Behavior on color { ColorAnimation { duration: Theme.animFast } }
                    Behavior on border.color { ColorAnimation { duration: Theme.animFast } }

                    Text {
                        anchors.centerIn: parent
                        text: Theme.iconArch
                        font.family: Theme.fontIcon
                        font.pixelSize: Theme.fontSizeLg
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
                    active: (Settings?.showWallpaper ?? true) && !root.isVertical
                    visible: active
                    width: item ? item.implicitWidth : (Theme.barHeight - 8)
                    height: item ? item.implicitHeight : (Theme.barHeight - 8)
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

                Loader {
                    active: (Settings?.showWindowTitle ?? true) && !root.isVertical
                    visible: active
                    width: item ? item.implicitWidth : 0
                    height: item ? item.implicitHeight : (Theme.barHeight - 8)
                    anchors.verticalCenter: parent.verticalCenter
                    sourceComponent: Component { WindowTitle {} }
                }
            }

            // center clock
            Loader {
                active: (Settings?.showClock ?? true) && !root.isVertical
                visible: active
                width: item ? item.implicitWidth : 100
                height: item ? item.implicitHeight : (Theme.barHeight - 8)
                sourceComponent: Component { Clock {} }
                anchors.centerIn: parent
            }

            // right widgets
            Row {
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
                    active: (Settings?.showBluetooth ?? true) && !root.isVertical
                    visible: active
                    width: item ? item.implicitWidth : (Theme.barHeight - 8)
                    height: item ? item.implicitHeight : (Theme.barHeight - 8)
                    anchors.verticalCenter: parent.verticalCenter
                    sourceComponent: Component { Bluetooth {} }
                }

                Loader {
                    active: (Settings?.showSystemTray ?? true) && !root.isVertical
                    visible: active
                    width: item ? item.implicitWidth : (Theme.barHeight - 8)
                    height: item ? item.implicitHeight : (Theme.barHeight - 8)
                    anchors.verticalCenter: parent.verticalCenter
                    sourceComponent: Component { SystemTray {} }
                }

                Loader {
                    active: (Settings?.showNotifications ?? true) && !root.isVertical
                    visible: active
                    width: item ? item.implicitWidth : (Theme.barHeight - 8)
                    height: item ? item.implicitHeight : (Theme.barHeight - 8)
                    anchors.verticalCenter: parent.verticalCenter
                    sourceComponent: Component { Notifications {} }
                }

                Loader {
                    active: (Settings?.showIdleInhibitor ?? true) && !root.isVertical
                    visible: active
                    width: item ? item.implicitWidth : (Theme.barHeight - 8)
                    height: item ? item.implicitHeight : (Theme.barHeight - 8)
                    anchors.verticalCenter: parent.verticalCenter
                    sourceComponent: Component { IdleInhibitor {} }
                }

                Loader {
                    active: (Settings?.showClipboard ?? true) && !root.isVertical
                    visible: active
                    width: item ? item.implicitWidth : (Theme.barHeight - 8)
                    height: item ? item.implicitHeight : (Theme.barHeight - 8)
                    anchors.verticalCenter: parent.verticalCenter
                    sourceComponent: Component { Clipboard {} }
                }

                Loader {
                    active: (Settings?.showQuickNotes ?? true) && !root.isVertical
                    visible: active
                    width: item ? item.implicitWidth : (Theme.barHeight - 8)
                    height: item ? item.implicitHeight : (Theme.barHeight - 8)
                    anchors.verticalCenter: parent.verticalCenter
                    sourceComponent: Component { QuickNotes {} }
                }

                Loader {
                    active: (Settings?.showMedia ?? true) && !root.isVertical
                    visible: active
                    width: item ? item.implicitWidth : (Theme.barHeight - 8)
                    height: item ? item.implicitHeight : (Theme.barHeight - 8)
                    anchors.verticalCenter: parent.verticalCenter
                    sourceComponent: Component { NowPlaying {} }
                }
            }
        }

        // vertical bar layout (left / right)
        Item {
            x: barBg.x
            y: barBg.y
            width: barBg.width
            height: barBg.height
            visible: root.isVertical

            // top widgets
            Column {
                anchors.top: parent.top
                anchors.topMargin: Theme.widgetPaddingH
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Theme.widgetSpacing

                Rectangle {
                    id: launcherBtnV
                    visible: Settings?.showLauncher ?? true
                    width: Theme.barHeight - 8
                    height: 36
                    radius: Theme.radiusPill
                    color: lMouseV.pressed ? Theme.widgetActive : lMouseV.containsMouse ? Theme.pillHover : (launcherPopup.open ? Theme.primary_overlay : Theme.pillBg)
                    border.color: Theme.pillBorder
                    border.width: Theme.pillBorder === "transparent" ? 0 : 1

                    Behavior on color { ColorAnimation { duration: Theme.animFast } }
                    Behavior on border.color { ColorAnimation { duration: Theme.animFast } }

                    Text {
                        anchors.centerIn: parent
                        text: Theme.iconArch
                        font.family: Theme.fontIcon
                        font.pixelSize: Theme.fontSizeLg
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
                    active: (Settings?.showWallpaper ?? true) && root.isVertical
                    visible: active
                    width: item ? item.implicitWidth : (Theme.barHeight - 8)
                    height: item ? item.implicitHeight : (Theme.barHeight - 8)
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

            // center clock
            Loader {
                active: (Settings?.showClock ?? true) && root.isVertical
                visible: active
                width: item ? item.implicitWidth : (Theme.barHeight - 8)
                height: item ? item.implicitHeight : 38
                sourceComponent: Component { Clock {} }
                anchors.centerIn: parent
            }

            // bottom widgets
            Column {
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
                    sourceComponent: Component { NowPlaying {} }
                }

                Loader {
                    active: (Settings?.showClipboard ?? true) && root.isVertical
                    visible: active
                    width: item ? item.implicitWidth : (Theme.barHeight - 8)
                    height: item ? item.implicitHeight : (Theme.barHeight - 8)
                    anchors.horizontalCenter: parent.horizontalCenter
                    sourceComponent: Component { Clipboard {} }
                }

                Loader {
                    active: (Settings?.showIdleInhibitor ?? true) && root.isVertical
                    visible: active
                    width: item ? item.implicitWidth : (Theme.barHeight - 8)
                    height: item ? item.implicitHeight : (Theme.barHeight - 8)
                    anchors.horizontalCenter: parent.horizontalCenter
                    sourceComponent: Component { IdleInhibitor {} }
                }

                Loader {
                    active: (Settings?.showNotifications ?? true) && root.isVertical
                    visible: active
                    width: item ? item.implicitWidth : (Theme.barHeight - 8)
                    height: item ? item.implicitHeight : (Theme.barHeight - 8)
                    anchors.horizontalCenter: parent.horizontalCenter
                    sourceComponent: Component { Notifications {} }
                }

                Loader {
                    active: (Settings?.showSystemTray ?? true) && root.isVertical
                    visible: active
                    width: item ? item.implicitWidth : (Theme.barHeight - 8)
                    height: item ? item.implicitHeight : (Theme.barHeight - 8)
                    anchors.horizontalCenter: parent.horizontalCenter
                    sourceComponent: Component { SystemTray {} }
                }

                Loader {
                    active: (Settings?.showBluetooth ?? true) && root.isVertical
                    visible: active
                    width: item ? item.implicitWidth : (Theme.barHeight - 8)
                    height: item ? item.implicitHeight : (Theme.barHeight - 8)
                    anchors.horizontalCenter: parent.horizontalCenter
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
                    active: (Settings?.showQuickNotes ?? true) && root.isVertical
                    visible: active
                    width: item ? item.implicitWidth : (Theme.barHeight - 8)
                    height: item ? item.implicitHeight : (Theme.barHeight - 8)
                    anchors.horizontalCenter: parent.horizontalCenter
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