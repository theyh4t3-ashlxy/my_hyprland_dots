import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import ".."
import "../corners"

PanelWindow {
    id: root

    // pass the monitor or suffer
    required property var modelData
    screen: modelData
    color: "transparent"

    // quickshell grouped window anchors
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    exclusionMode: ExclusionMode.Ignore

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell:corners"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    // ghost mode — click straight through this fullscreen overlay
    mask: Region {}

    readonly property bool isFullscreen: Hyprland.focusedWorkspace?.hasFullscreen ?? false

    readonly property string mode: Settings?.screenCornerMode ?? Theme?.screenCornerMode ?? "all"
    readonly property string rawBarPos: Settings?.barPosition ?? "up"
    readonly property string barPos: (rawBarPos === "up" || rawBarPos === "top") ? "top" : ((rawBarPos === "down" || rawBarPos === "bottom") ? "bottom" : rawBarPos)
    readonly property int cornerRadius: Theme?.screenCornerRadius ?? 16
    readonly property color cornerColor: Theme?.cornerFill ?? Theme?.barBg ?? Theme?.surface_container_low ?? "#14140c"

    // supporting vertical rice setups so it doesn't break
    readonly property bool showTopLeft: mode === "all" || mode === "top" || mode === "up" || mode === "left" || (mode === "opposite" && barPos !== "top" && barPos !== "left")
    readonly property bool showTopRight: mode === "all" || mode === "top" || mode === "up" || mode === "right" || (mode === "opposite" && barPos !== "top" && barPos !== "right")
    readonly property bool showBottomLeft: mode === "all" || mode === "bottom" || mode === "down" || mode === "left" || (mode === "opposite" && barPos !== "bottom" && barPos !== "left")
    readonly property bool showBottomRight: mode === "all" || mode === "bottom" || mode === "down" || mode === "right" || (mode === "opposite" && barPos !== "bottom" && barPos !== "right")

    visible: root.cornerRadius > 0 && root.mode !== "none" && !root.isFullscreen

    Item {
        anchors.fill: parent
        opacity: root.isFullscreen ? 0.0 : 1.0
        Behavior on opacity { NumberAnimation { duration: Theme.animNormal } }

        // top left screen scoop
        ConcaveCorner {
            anchors.top: parent.top
            anchors.left: parent.left
            radiusX: root.cornerRadius
            radiusY: root.cornerRadius
            fillColor: root.cornerColor
            flipX: false
            flipY: false
            visible: root.showTopLeft
        }

        // top right screen scoop
        ConcaveCorner {
            anchors.top: parent.top
            anchors.right: parent.right
            radiusX: root.cornerRadius
            radiusY: root.cornerRadius
            fillColor: root.cornerColor
            flipX: true
            flipY: false
            visible: root.showTopRight
        }

        // bottom left screen scoop
        ConcaveCorner {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            radiusX: root.cornerRadius
            radiusY: root.cornerRadius
            fillColor: root.cornerColor
            flipX: false
            flipY: true
            visible: root.showBottomLeft
        }

        // bottom right screen scoop
        ConcaveCorner {
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            radiusX: root.cornerRadius
            radiusY: root.cornerRadius
            fillColor: root.cornerColor
            flipX: true
            flipY: true
            visible: root.showBottomRight
        }
    }
}