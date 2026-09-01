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
            color: Theme.barBg
            border.width: 0
            radius: 0

            // glowing neon accent line on the edge facing workspaces
            Rectangle {
                visible: Settings.barStyle === "accent-glow"
                x: root.isLeft ? parent.width - 2 : 0
                y: root.isTop ? parent.height - 2 : 0
                width: root.isVertical ? 2 : parent.width
                height: root.isVertical ? parent.height : 2
                color: Theme.primary
                opacity: 0.90
            }
        }

        // horizontal bar layout (top / bottom) so it doesnt explode
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
                            launcherPopup.targetRelativeX = launcherBtnH.mapToItem(null, 0, 0).x + (launcherBtnH.width / 2)
                            launcherPopup.open = !launcherPopup.open
                        }
                    }
                }

                Loader {
                    active: Settings.showWallpaper && !root.isVertical
                    visible: active
                    sourceComponent: Component { WallpaperBrowser {} }
                }

                Loader {
                    active: Settings.showWorkspaces && !root.isVertical
                    visible: active
                    sourceComponent: Component { Workspaces {} }
                }

                Loader {
                    active: Settings.showWindowTitle && !root.isVertical
                    visible: active
                    sourceComponent: Component { WindowTitle {} }
                }
            }

            // clock in center
            Loader {
                active: Settings.showClock && !root.isVertical
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
                    active: Settings.showPowerMenu && !root.isVertical
                    visible: active
                    sourceComponent: Component { PowerMenu {} }
                }

                Loader {
                    active: Settings.showQuickSettings && !root.isVertical
                    visible: active
                    sourceComponent: Component { QuickSettings {} }
                }

                Loader {
                    active: Settings.showBattery && !root.isVertical
                    visible: active
                    sourceComponent: Component { Battery {} }
                }

                Loader {
                    active: Settings.showVolume && !root.isVertical
                    visible: active
                    sourceComponent: Component { VolumeControl {} }
                }

                Loader {
                    active: Settings.showNetwork && !root.isVertical
                    visible: active
                    sourceComponent: Component { NetworkStatus {} }
                }

                Loader {
                    active: Settings.showBluetooth && !root.isVertical
                    visible: active
                    sourceComponent: Component { Bluetooth {} }
                }

                Loader {
                    active: Settings.showSystemTray && !root.isVertical
                    visible: active
                    sourceComponent: Component { SystemTray {} }
                }

                Loader {
                    active: Settings.showNotifications && !root.isVertical
                    visible: active
                    sourceComponent: Component { Notifications {} }
                }

                Loader {
                    active: Settings.showIdleInhibitor && !root.isVertical
                    visible: active
                    sourceComponent: Component { IdleInhibitor {} }
                }

                Loader {
                    active: Settings.showClipboard && !root.isVertical
                    visible: active
                    sourceComponent: Component { Clipboard {} }
                }

                Loader {
                    active: Settings.showQuickNotes && !root.isVertical
                    visible: active
                    sourceComponent: Component { QuickNotes {} }
                }

                Loader {
                    active: Settings.showMedia && !root.isVertical
                    visible: active
                    sourceComponent: Component { NowPlaying {} }
                }
            }
        }

        // vertical bar layout (left / right) so it doesnt explode
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
                            launcherPopup.targetRelativeY = launcherBtnV.mapToItem(null, 0, 0).y + (launcherBtnV.height / 2)
                            launcherPopup.open = !launcherPopup.open
                        }
                    }
                }

                Loader {
                    active: Settings.showWallpaper && root.isVertical
                    visible: active
                    sourceComponent: Component { WallpaperBrowser {} }
                }

                Loader {
                    active: Settings.showWorkspaces && root.isVertical
                    visible: active
                    sourceComponent: Component { Workspaces {} }
                }
            }

            // clock in center
            Loader {
                active: Settings.showClock && root.isVertical
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
                    active: Settings.showMedia && root.isVertical
                    visible: active
                    sourceComponent: Component { NowPlaying {} }
                }

                Loader {
                    active: Settings.showClipboard && root.isVertical
                    visible: active
                    sourceComponent: Component { Clipboard {} }
                }

                Loader {
                    active: Settings.showIdleInhibitor && root.isVertical
                    visible: active
                    sourceComponent: Component { IdleInhibitor {} }
                }

                Loader {
                    active: Settings.showNotifications && root.isVertical
                    visible: active
                    sourceComponent: Component { Notifications {} }
                }

                Loader {
                    active: Settings.showSystemTray && root.isVertical
                    visible: active
                    sourceComponent: Component { SystemTray {} }
                }

                Loader {
                    active: Settings.showBluetooth && root.isVertical
                    visible: active
                    sourceComponent: Component { Bluetooth {} }
                }

                Loader {
                    active: Settings.showNetwork && root.isVertical
                    visible: active
                    sourceComponent: Component { NetworkStatus {} }
                }

                Loader {
                    active: Settings.showVolume && root.isVertical
                    visible: active
                    sourceComponent: Component { VolumeControl {} }
                }

                Loader {
                    active: Settings.showBattery && root.isVertical
                    visible: active
                    sourceComponent: Component { Battery {} }
                }

                Loader {
                    active: Settings.showQuickSettings && root.isVertical
                    visible: active
                    sourceComponent: Component { QuickSettings {} }
                }

                Loader {
                    active: Settings.showQuickNotes && root.isVertical
                    visible: active
                    sourceComponent: Component { QuickNotes {} }
                }

                Loader {
                    active: Settings.showPowerMenu && root.isVertical
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