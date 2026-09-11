import QtQuick
import QtQuick.Layouts
import ".."
import "../controls"
import Quickshell
import Quickshell.Widgets
import Quickshell.Hyprland

PopupPanel {
    id: root

    cardWidth: 380
    cardHeight: 280

    readonly property var activeTop: Hyprland.activeToplevel
    readonly property string winTitle: (activeTop?.title ?? "").trim()
    readonly property string winClass: {
        if (!activeTop) return "";
        let c = "";
        if (activeTop.lastIpcObject) {
            c = activeTop.lastIpcObject["class"] || activeTop.lastIpcObject.initialClass || "";
        }
        if (!c && activeTop.waylandHandle) c = activeTop.waylandHandle.appId;
        if (!c && activeTop.appId) c = activeTop.appId;
        return (c || "").trim();
    }
    readonly property bool isFloating: Boolean(activeTop?.floating ?? (activeTop?.lastIpcObject ? activeTop.lastIpcObject.floating : false))
    readonly property bool isFullscreen: Boolean(activeTop?.fullscreen ?? (activeTop?.lastIpcObject ? activeTop.lastIpcObject.fullscreen : false))

    content: ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.widgetPaddingH + 4
        spacing: 12

        // Header
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Rectangle {
                Layout.preferredWidth: 32
                Layout.preferredHeight: 32
                radius: Theme.radiusSm
                color: Theme.surface_container_high

                IconImage {
                    id: popupAppIcon
                    anchors.centerIn: parent
                    width: 20
                    height: 20
                    source: {
                        if (!root.winClass) return "";
                        let base = root.winClass.toLowerCase();

                        // Check DesktopEntries first for authoritative .desktop icon
                        if (typeof DesktopEntries !== "undefined" && DesktopEntries?.applications?.values) {
                            let apps = DesktopEntries.applications.values;
                            for (let i = 0; i < apps.length; i++) {
                                let a = apps[i];
                                if (!a) continue;
                                let aid = (a.id ?? "").toLowerCase().replace(/\.desktop$/, "");
                                let wm = (a.startupWmClass ?? "").toLowerCase();
                                if (aid === base || wm === base) {
                                    if (a.icon) {
                                        let p = Quickshell.iconPath(a.icon);
                                        if (p) return p;
                                    }
                                }
                            }
                        }

                        let candidates = [
                            base + "-browser",
                            base,
                            base.replace(/-/g, ""),
                            base.replace(/_bin$/, ""),
                            base.replace(/-bin$/, "")
                        ];
                        let parts = base.split(".");
                        if (parts.length > 1) {
                            candidates.push(parts[parts.length - 1]);
                        }
                        for (let i = 0; i < candidates.length; i++) {
                            let p = Quickshell.iconPath(candidates[i]);
                            if (p) return p;
                        }
                        return Quickshell.iconPath("application-x-executable") || "";
                    }
                    visible: source !== "" && status !== Image.Error
                }

                Text {
                    anchors.centerIn: parent
                    text: root.activeTop ? (Theme.iconTerminal ?? "") : (Theme.iconArch ?? "desktop")
                    font.family: Theme.fontIcon
                    font.pixelSize: Theme.fontSizeMd
                    color: Theme.primary
                    visible: !popupAppIcon.visible
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Text {
                    text: root.winClass.length > 0 ? root.winClass : "desktop"
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeMd
                    font.weight: Font.Bold
                    color: Theme.on_surface
                    elide: Text.ElideRight
                }

                Text {
                    text: root.activeTop ? "focused window" : "no active window"
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeXs
                    color: Theme.on_surface_variant
                }
            }

            Rectangle {
                visible: root.activeTop !== null
                height: 22
                implicitWidth: statusText.implicitWidth + 14
                radius: Theme.radiusPill
                color: root.isFloating ? Theme.secondary_container : Theme.surface_container_highest

                Text {
                    id: statusText
                    anchors.centerIn: parent
                    text: root.isFloating ? "floating" : "tiled"
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                    font.weight: Font.Medium
                    color: root.isFloating ? Theme.on_secondary_container : Theme.on_surface_variant
                }
            }
        }

        // Full Title Card
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 70
            radius: Theme.radiusMd
            color: Theme.surface_container
            border.color: Theme.glassBorder
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 4

                Text {
                    text: "window title"
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                    color: Theme.on_surface_variant
                }

                Text {
                    Layout.fillWidth: true
                    text: root.winTitle.length > 0 ? root.winTitle : "no window focused"
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSm
                    font.weight: Font.Medium
                    color: Theme.on_surface
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    maximumLineCount: 2
                    elide: Text.ElideRight
                }
            }
        }

        // Actions Row
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Rectangle {
                Layout.fillWidth: true
                height: 36
                radius: Theme.radiusSm
                color: root.isFloating ? Theme.primary : Theme.surface_container_high
                border.color: Theme.glassBorder
                border.width: 1

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 4

                    Text {
                        text: Theme.iconCrop
                        font.family: Theme.fontIcon
                        font.pixelSize: Theme.fontSizeSm
                        color: root.isFloating ? Theme.on_primary : Theme.on_surface
                    }

                    Text {
                        text: "float"
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeXs
                        color: root.isFloating ? Theme.on_primary : Theme.on_surface
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Settings.dispatchToggleFloat()
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 36
                radius: Theme.radiusSm
                color: root.isFullscreen ? Theme.primary : Theme.surface_container_high
                border.color: Theme.glassBorder
                border.width: 1

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 4

                    Text {
                        text: Theme.iconExpand
                        font.family: Theme.fontIcon
                        font.pixelSize: Theme.fontSizeSm
                        color: root.isFullscreen ? Theme.on_primary : Theme.on_surface
                    }

                    Text {
                        text: "fullscreen"
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeXs
                        color: root.isFullscreen ? Theme.on_primary : Theme.on_surface
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Settings.dispatchToggleFullscreen()
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 36
                radius: Theme.radiusSm
                color: Theme.surface_container_high
                border.color: Theme.glassBorder
                border.width: 1

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 4

                    Text {
                        text: Theme.iconHeart
                        font.family: Theme.fontIcon
                        font.pixelSize: Theme.fontSizeSm
                        color: Theme.on_surface
                    }

                    Text {
                        text: "pin"
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeXs
                        color: Theme.on_surface
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Settings.dispatchPinWindow()
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 36
                radius: Theme.radiusSm
                color: Theme.error_container

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 4

                    Text {
                        text: Theme.iconClose
                        font.family: Theme.fontIcon
                        font.pixelSize: Theme.fontSizeSm
                        color: Theme.on_error_container
                    }

                    Text {
                        text: "kill"
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeXs
                        font.weight: Font.Bold
                        color: Theme.on_error_container
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        Settings.dispatchCloseWindow();
                        root.open = false;
                    }
                }
            }
        }
    }
}
