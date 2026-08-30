import QtQuick
import Quickshell
import Quickshell.Wayland
import ".."

PanelWindow {
    id: root

    // pass the monitor or suffer
    required property var modelData
    screen: modelData
    color: "transparent"

    // quickshell window anchors use grouped syntax, not item-attached syntax
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

    // ghost mode — let clicks pass through to my actual windows
    mask: Region {}

    readonly property string mode: Theme?.screenCornerMode ?? "all"
    readonly property string barPos: Settings?.barPosition ?? "top"
    readonly property int cornerRadius: Theme?.screenCornerRadius ?? 16
    readonly property color cornerColor: Theme?.cornerFill ?? Theme.background

    readonly property bool showTopLeft: mode === "all" || mode === "top" || (mode === "opposite" && barPos !== "top" && barPos !== "left")
    readonly property bool showTopRight: mode === "all" || mode === "top" || (mode === "opposite" && barPos !== "top" && barPos !== "right")
    readonly property bool showBottomLeft: mode === "all" || mode === "bottom" || (mode === "opposite" && barPos !== "bottom" && barPos !== "left")
    readonly property bool showBottomRight: mode === "all" || mode === "bottom" || (mode === "opposite" && barPos !== "bottom" && barPos !== "right")

    visible: root.cornerRadius > 0 && root.mode !== "none"

    Item {
        anchors.fill: parent

        // top left screen corner
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

        // top right screen corner
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

        // bottom left screen corner
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

        // bottom right screen corner
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