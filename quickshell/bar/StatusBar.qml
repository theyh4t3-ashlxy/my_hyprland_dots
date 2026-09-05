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

    property alias launcherPopup: launcherPopup

    IdleInhibitor {
        enabled: !IdleService.enabled
    }

    AppLauncher {
        id: launcherPopup
        screen: root.screen
    }

    // component registry for dynamic reorderable modules
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
        if (modId === "battery") return Settings?.showBattery ?? true;
        if (modId === "quickSettings") return Settings?.showQuickSettings ?? true;
        if (modId === "powerMenu") return Settings?.showPowerMenu ?? true;
        return true;
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

            // glass specular highlight sheen facing workspaces
            Rectangle {
                visible: Settings?.barStyle === "glass"
                x: root.isLeft ? parent.width - 1 : 0
                y: root.isTop ? parent.height - 1 : 0
                width: root.isVertical ? 1 : parent.width
                height: root.isVertical ? parent.height : 1
                color: Qt.rgba(1, 1, 1, 0.22)
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
                        anchors.verticalCenter: parent.verticalCenter
                        readonly property real targetW: item ? (modelData === "windowTitle" ? Math.max(40, Math.min(item.implicitWidth, 260)) : item.implicitWidth) : (Theme.barHeight - 8)
                        width: targetW
                        height: item ? item.implicitHeight : (Theme.barHeight - 8)

                        Behavior on opacity { NumberAnimation { duration: Theme.animFast; easing.type: Theme.animEasing } }
                    }
                }
            }

            // center widgets (clock or whatever is placed in center)
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
                        anchors.verticalCenter: parent.verticalCenter
                        width: item ? item.implicitWidth : (Theme.barHeight - 8)
                        height: item ? item.implicitHeight : (Theme.barHeight - 8)

                        Behavior on opacity { NumberAnimation { duration: Theme.animFast; easing.type: Theme.animEasing } }
                    }
                }
            }

            // right widgets
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
                        anchors.verticalCenter: parent.verticalCenter
                        readonly property real targetW: item ? item.implicitWidth : (Theme.barHeight - 8)
                        width: targetW
                        height: item ? item.implicitHeight : (Theme.barHeight - 8)

                        Behavior on opacity { NumberAnimation { duration: Theme.animFast; easing.type: Theme.animEasing } }
                    }
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

                Repeater {
                    model: Settings.barModulesLeft ?? []
                    delegate: Loader {
                        required property string modelData
                        active: root.isModuleVisible(modelData) && root.isVertical
                        visible: active
                        sourceComponent: root.getModuleComponent(modelData)
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: item ? item.implicitWidth : (Theme.barHeight - 8)
                        height: item ? item.implicitHeight : (Theme.barHeight - 8)
                        Behavior on opacity { NumberAnimation { duration: Theme.animFast; easing.type: Theme.animEasing } }
                    }
                }
            }

            // center widgets
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
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: item ? item.implicitWidth : (Theme.barHeight - 8)
                        height: item ? item.implicitHeight : (Theme.barHeight - 8)
                        Behavior on opacity { NumberAnimation { duration: Theme.animFast; easing.type: Theme.animEasing } }
                    }
                }
            }

            // bottom widgets
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
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: item ? item.implicitWidth : (Theme.barHeight - 8)
                        height: item ? item.implicitHeight : (Theme.barHeight - 8)
                        Behavior on opacity { NumberAnimation { duration: Theme.animFast; easing.type: Theme.animEasing } }
                    }
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