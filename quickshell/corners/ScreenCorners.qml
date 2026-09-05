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

    implicitWidth: root.screen?.width ?? 1920
    implicitHeight: root.screen?.height ?? 1080

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
    readonly property bool isBarFloating: Settings?.barFloating ?? false
    readonly property bool isDocked: (Settings?.screenFrameDocked ?? true) && !isBarFloating && mode !== "monitor"
    readonly property int barThickness: Theme?.barHeight ?? 32

    readonly property int topOffset: (isDocked && barPos === "top") ? barThickness : 0
    readonly property int bottomOffset: (isDocked && barPos === "bottom") ? barThickness : 0
    readonly property int leftOffset: (isDocked && barPos === "left") ? barThickness : 0
    readonly property int rightOffset: (isDocked && barPos === "right") ? barThickness : 0

    readonly property int cornerRadius: Theme?.screenCornerRadius ?? 16
    readonly property int borderWidth: Settings?.screenBorderWidth ?? (Theme?.cornerColorMode === "accent" ? 2 : 0)
    readonly property color cornerColor: Theme?.cornerFill ?? Theme?.surface_container_low ?? Theme?.background ?? "#14140c"

    // supporting vertical rice setups so it doesn't break
    readonly property bool showTopLeft: mode === "all" || mode === "monitor" || mode === "top" || mode === "up" || mode === "left" || (mode === "opposite" && barPos !== "top" && barPos !== "left")
    readonly property bool showTopRight: mode === "all" || mode === "monitor" || mode === "top" || mode === "up" || mode === "right" || (mode === "opposite" && barPos !== "top" && barPos !== "right")
    readonly property bool showBottomLeft: mode === "all" || mode === "monitor" || mode === "bottom" || mode === "down" || mode === "left" || (mode === "opposite" && barPos !== "bottom" && barPos !== "left")
    readonly property bool showBottomRight: mode === "all" || mode === "monitor" || mode === "bottom" || mode === "down" || mode === "right" || (mode === "opposite" && barPos !== "bottom" && barPos !== "right")

    visible: (root.cornerRadius > 0 || root.borderWidth > 0) && root.mode !== "none" && !root.isFullscreen

    Item {
        id: container
        anchors.fill: parent
        opacity: root.isFullscreen ? 0.0 : 1.0
        Behavior on opacity { NumberAnimation { duration: Theme.animNormal } }

        readonly property int screenW: container.width > 0 ? container.width : (root.screen?.width ?? 1920)
        readonly property int screenH: container.height > 0 ? container.height : (root.screen?.height ?? 1080)
        readonly property int usableW: Math.max(1, screenW - root.leftOffset - root.rightOffset)
        readonly property int usableH: Math.max(1, screenH - root.topOffset - root.bottomOffset)

        // continuous screen frame borders connecting the corners
        Rectangle {
            id: borderTop
            x: root.leftOffset
            y: root.topOffset
            width: container.usableW
            height: root.borderWidth
            color: root.cornerColor
            visible: root.borderWidth > 0 && root.mode !== "bottom" && root.mode !== "none"
        }

        Rectangle {
            id: borderBottom
            x: root.leftOffset
            y: container.screenH - root.bottomOffset - root.borderWidth
            width: container.usableW
            height: root.borderWidth
            color: root.cornerColor
            visible: root.borderWidth > 0 && root.mode !== "top" && root.mode !== "none"
        }

        Rectangle {
            id: borderLeft
            x: root.leftOffset
            y: root.topOffset
            width: root.borderWidth
            height: container.usableH
            color: root.cornerColor
            visible: root.borderWidth > 0 && root.mode !== "right" && root.mode !== "none"
        }

        Rectangle {
            id: borderRight
            x: container.screenW - root.rightOffset - root.borderWidth
            y: root.topOffset
            width: root.borderWidth
            height: container.usableH
            color: root.cornerColor
            visible: root.borderWidth > 0 && root.mode !== "left" && root.mode !== "none"
        }

        // top left screen scoop / corner
        ConcaveCorner {
            x: root.leftOffset
            y: root.topOffset
            radiusX: root.cornerRadius
            radiusY: root.cornerRadius
            fillColor: root.cornerColor
            flipX: false
            flipY: false
            visible: root.showTopLeft && root.cornerRadius > 0
        }

        // top right screen scoop / corner
        ConcaveCorner {
            x: container.screenW - root.rightOffset - width
            y: root.topOffset
            radiusX: root.cornerRadius
            radiusY: root.cornerRadius
            fillColor: root.cornerColor
            flipX: true
            flipY: false
            visible: root.showTopRight && root.cornerRadius > 0
        }

        // bottom left screen scoop / corner
        ConcaveCorner {
            x: root.leftOffset
            y: container.screenH - root.bottomOffset - height
            radiusX: root.cornerRadius
            radiusY: root.cornerRadius
            fillColor: root.cornerColor
            flipX: false
            flipY: true
            visible: root.showBottomLeft && root.cornerRadius > 0
        }

        // bottom right screen scoop / corner
        ConcaveCorner {
            x: container.screenW - root.rightOffset - width
            y: container.screenH - root.bottomOffset - height
            radiusX: root.cornerRadius
            radiusY: root.cornerRadius
            fillColor: root.cornerColor
            flipX: true
            flipY: true
            visible: root.showBottomRight && root.cornerRadius > 0
        }
    }
}