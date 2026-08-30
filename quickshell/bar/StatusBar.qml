import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."

PanelWindow {
    id: root

    required property var modelData
    screen: modelData
    color: "transparent"

    readonly property bool isTop: Settings.barPosition === "top"
    readonly property bool isBottom: Settings.barPosition === "bottom"
    readonly property bool isLeft: Settings.barPosition === "left"
    readonly property bool isRight: Settings.barPosition === "right"
    readonly property bool isVertical: isLeft || isRight

    // full 4-way docking without undefined anchor locks
    anchors {
        top: root.isTop || root.isVertical
        bottom: root.isBottom || root.isVertical
        left: root.isLeft || !root.isVertical
        right: root.isRight || !root.isVertical
    }

    implicitWidth: root.isVertical ? (Theme.barHeight + Theme.scoopRadiusX) : 0
    implicitHeight: root.isVertical ? 0 : (Theme.barHeight + Theme.scoopRadiusY)
    exclusiveZone: Theme.barHeight
    exclusionMode: ExclusionMode.Normal

    WlrLayershell.namespace: "quickshell:bar"

    mask: Region {
        item: barBg
    }

    AppLauncher {
        id: launcherPopup
        parentWindow: root
    }

    Item {
        anchors.fill: parent

        // bar background body positioned by clean explicit geometry
        Rectangle {
            id: barBg
            x: root.isRight ? Theme.scoopRadiusX : 0
            y: root.isBottom ? Theme.scoopRadiusY : 0
            width: root.isVertical ? Theme.barHeight : parent.width
            height: root.isVertical ? parent.height : Theme.barHeight
            color: Theme.surface_container_low
            radius: 0
        }

        // === HORIZONTAL BAR LAYOUT (top / bottom) ===
        Item {
            x: barBg.x
            y: barBg.y
            width: barBg.width
            height: barBg.height
            visible: !root.isVertical

            // left widgets
            RowLayout {
                anchors.left: parent.left
                anchors.leftMargin: Theme.widgetPaddingH
                anchors.verticalCenter: parent.verticalCenter
                spacing: Theme.widgetSpacing

                Rectangle {
                    id: launcherBtnH
                    visible: Settings.showLauncher
                    implicitWidth: 36
                    implicitHeight: Theme.barHeight - 8
                    radius: Theme.radiusPill
                    color: lMouseH.pressed ? Theme.widgetActive : lMouseH.containsMouse ? Theme.surface_container_highest : (launcherPopup.open ? Theme.primary_overlay : Theme.surface_container_high)

                    Behavior on color { ColorAnimation { duration: Theme.animFast } }

                    Text {
                        anchors.centerIn: parent
                        text: Theme.iconArch
                        font.family: Theme.fontMono
                        font.pixelSize: Theme.fontSizeLg
                        color: launcherPopup.open ? Theme.primary : Theme.on_surface
                    }

                    MouseArea {
                        id: lMouseH
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            launcherPopup.targetRelativeX = launcherBtnH.mapToItem(null, 0, 0).x + (launcherBtnH.width / 2)
                            launcherPopup.open = !launcherPopup.open
                        }
                    }
                }

                Loader {
                    active: Settings.showWallpaper
                    visible: active
                    sourceComponent: Component { WallpaperBrowser {} }
                }

                Loader {
                    active: Settings.showWorkspaces
                    visible: active
                    sourceComponent: Component { Workspaces {} }
                }

                Loader {
                    active: Settings.showWindowTitle
                    visible: active
                    sourceComponent: Component { WindowTitle {} }
                }
            }

            // clock in center
            Loader {
                active: Settings.showClock
                visible: active
                sourceComponent: Component { Clock {} }
                anchors.centerIn: parent
            }

            // right widgets
            RowLayout {
                anchors.right: parent.right
                anchors.rightMargin: Theme.widgetPaddingH
                anchors.verticalCenter: parent.verticalCenter
                spacing: Theme.widgetSpacing
                layoutDirection: Qt.RightToLeft

                Loader {
                    active: Settings.showPowerMenu
                    visible: active
                    sourceComponent: Component { PowerMenu {} }
                }

                Loader {
                    active: Settings.showQuickSettings
                    visible: active
                    sourceComponent: Component { QuickSettings {} }
                }

                Loader {
                    active: Settings.showSystemTray
                    visible: active
                    sourceComponent: Component { SystemTray {} }
                }

                Loader {
                    active: Settings.showNotifications
                    visible: active
                    sourceComponent: Component { Notifications {} }
                }

                Loader {
                    active: Settings.showMedia
                    visible: active
                    sourceComponent: Component { NowPlaying {} }
                }

                Loader {
                    active: Settings.showClipboard
                    visible: active
                    sourceComponent: Component { Clipboard {} }
                }

                Loader {
                    active: Settings.showIdleInhibitor
                    visible: active
                    sourceComponent: Component { IdleInhibitor {} }
                }

                Loader {
                    active: Settings.showBluetooth
                    visible: active
                    sourceComponent: Component { Bluetooth {} }
                }

                Loader {
                    active: Settings.showNetwork
                    visible: active
                    sourceComponent: Component { NetworkStatus {} }
                }

                Loader {
                    active: Settings.showVolume
                    visible: active
                    sourceComponent: Component { VolumeControl {} }
                }

                Loader {
                    active: Settings.showBattery
                    visible: active
                    sourceComponent: Component { Battery {} }
                }
            }
        }

        // === VERTICAL BAR LAYOUT (left / right) ===
        Item {
            x: barBg.x
            y: barBg.y
            width: barBg.width
            height: barBg.height
            visible: root.isVertical

            // top widgets
            ColumnLayout {
                anchors.top: parent.top
                anchors.topMargin: Theme.widgetPaddingH
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Theme.widgetSpacing

                Rectangle {
                    id: launcherBtnV
                    visible: Settings.showLauncher
                    implicitWidth: Theme.barHeight - 8
                    implicitHeight: 36
                    radius: Theme.radiusPill
                    color: lMouseV.pressed ? Theme.widgetActive : lMouseV.containsMouse ? Theme.surface_container_highest : (launcherPopup.open ? Theme.primary_overlay : Theme.surface_container_high)

                    Behavior on color { ColorAnimation { duration: Theme.animFast } }

                    Text {
                        anchors.centerIn: parent
                        text: Theme.iconArch
                        font.family: Theme.fontMono
                        font.pixelSize: Theme.fontSizeLg
                        color: launcherPopup.open ? Theme.primary : Theme.on_surface
                    }

                    MouseArea {
                        id: lMouseV
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            launcherPopup.open = !launcherPopup.open
                        }
                    }
                }

                Loader {
                    active: Settings.showWallpaper
                    visible: active
                    sourceComponent: Component { WallpaperBrowser {} }
                }

                Loader {
                    active: Settings.showWorkspaces
                    visible: active
                    sourceComponent: Component { Workspaces {} }
                }
            }

            // clock in center
            Loader {
                active: Settings.showClock
                visible: active
                sourceComponent: Component { Clock {} }
                anchors.centerIn: parent
            }

            // bottom widgets
            ColumnLayout {
                anchors.bottom: parent.bottom
                anchors.bottomMargin: Theme.widgetPaddingH
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Theme.widgetSpacing

                Loader {
                    active: Settings.showBattery
                    visible: active
                    sourceComponent: Component { Battery {} }
                }

                Loader {
                    active: Settings.showVolume
                    visible: active
                    sourceComponent: Component { VolumeControl {} }
                }

                Loader {
                    active: Settings.showNetwork
                    visible: active
                    sourceComponent: Component { NetworkStatus {} }
                }

                Loader {
                    active: Settings.showBluetooth
                    visible: active
                    sourceComponent: Component { Bluetooth {} }
                }

                Loader {
                    active: Settings.showIdleInhibitor
                    visible: active
                    sourceComponent: Component { IdleInhibitor {} }
                }

                Loader {
                    active: Settings.showClipboard
                    visible: active
                    sourceComponent: Component { Clipboard {} }
                }

                Loader {
                    active: Settings.showMedia
                    visible: active
                    sourceComponent: Component { NowPlaying {} }
                }

                Loader {
                    active: Settings.showNotifications
                    visible: active
                    sourceComponent: Component { Notifications {} }
                }

                Loader {
                    active: Settings.showSystemTray
                    visible: active
                    sourceComponent: Component { SystemTray {} }
                }

                Loader {
                    active: Settings.showQuickSettings
                    visible: active
                    sourceComponent: Component { QuickSettings {} }
                }

                Loader {
                    active: Settings.showPowerMenu
                    visible: active
                    sourceComponent: Component { PowerMenu {} }
                }
            }
        }

        // top bar scoops
        ConcaveCorner {
            y: barBg.height
            anchors.left: parent.left
            fillColor: barBg.color
            flipX: false
            flipY: false
            visible: root.isTop
        }
        ConcaveCorner {
            y: barBg.height
            anchors.right: parent.right
            fillColor: barBg.color
            flipX: true
            flipY: false
            visible: root.isTop
        }

        // bottom bar scoops
        ConcaveCorner {
            y: 0
            anchors.left: parent.left
            fillColor: barBg.color
            flipX: false
            flipY: true
            visible: root.isBottom
        }
        ConcaveCorner {
            y: 0
            anchors.right: parent.right
            fillColor: barBg.color
            flipX: true
            flipY: true
            visible: root.isBottom
        }

        // left bar scoops
        ConcaveCorner {
            x: barBg.width
            anchors.top: parent.top
            fillColor: barBg.color
            flipX: false
            flipY: false
            visible: root.isLeft
        }
        ConcaveCorner {
            x: barBg.width
            anchors.bottom: parent.bottom
            fillColor: barBg.color
            flipX: false
            flipY: true
            visible: root.isLeft
        }

        // right bar scoops
        ConcaveCorner {
            x: 0
            anchors.top: parent.top
            fillColor: barBg.color
            flipX: true
            flipY: false
            visible: root.isRight
        }
        ConcaveCorner {
            x: 0
            anchors.bottom: parent.bottom
            fillColor: barBg.color
            flipX: true
            flipY: true
            visible: root.isRight
        }
    }
}