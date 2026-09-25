// ScreenCorners.qml
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import ".."
import "../corners"

Scope {
    id: root

    required property var modelData

    function hasAdjacentMonitorAt(dir, corner) {
        if (!root.modelData) return false;
        let all = Quickshell.screens;
        if (!all || all.length <= 1) return false;
        let sx = root.modelData.x, sy = root.modelData.y, sw = root.modelData.width, sh = root.modelData.height;
        for (let i = 0; i < all.length; i++) {
            let o = all[i];
            if (o === root.modelData || o.name === root.modelData.name) continue;
            let ox = o.x, oy = o.y, ow = o.width, oh = o.height;
            if (dir === "right" && Math.abs(ox - (sx + sw)) <= 4) {
                if (!corner) {
                    if (!(oy + oh <= sy || oy >= sy + sh)) return true;
                } else if (corner === "topRight" || corner === "top" || corner === "topLeft") {
                    if (oy <= sy + 4 && (oy + oh) >= sy + 4) return true;
                } else if (corner === "bottomRight" || corner === "bottom" || corner === "bottomLeft") {
                    if (oy <= sy + sh - 4 && (oy + oh) >= sy + sh - 4) return true;
                }
            }
            if (dir === "left" && Math.abs((ox + ow) - sx) <= 4) {
                if (!corner) {
                    if (!(oy + oh <= sy || oy >= sy + sh)) return true;
                } else if (corner === "topLeft" || corner === "top" || corner === "topRight") {
                    if (oy <= sy + 4 && (oy + oh) >= sy + 4) return true;
                } else if (corner === "bottomLeft" || corner === "bottom" || corner === "bottomRight") {
                    if (oy <= sy + sh - 4 && (oy + oh) >= sy + sh - 4) return true;
                }
            }
            if (dir === "top" && Math.abs((oy + oh) - sy) <= 4) {
                if (!corner) {
                    if (!(ox + ow <= sx || ox >= sx + sw)) return true;
                } else if (corner === "topLeft" || corner === "left" || corner === "bottomLeft") {
                    if (ox <= sx + 4 && (ox + ow) >= sx + 4) return true;
                } else if (corner === "topRight" || corner === "right" || corner === "bottomRight") {
                    if (ox <= sx + sw - 4 && (ox + ow) >= sx + sw - 4) return true;
                }
            }
            if (dir === "bottom" && Math.abs(oy - (sy + sh)) <= 4) {
                if (!corner) {
                    if (!(ox + ow <= sx || ox >= sx + sw)) return true;
                } else if (corner === "bottomLeft" || corner === "left" || corner === "topLeft") {
                    if (ox <= sx + 4 && (ox + ow) >= sx + 4) return true;
                } else if (corner === "bottomRight" || corner === "right" || corner === "topRight") {
                    if (ox <= sx + sw - 4 && (ox + ow) >= sx + sw - 4) return true;
                }
            }
        }
        return false;
    }

    function hasAdjacentMonitor(dir) {
        return hasAdjacentMonitorAt(dir, null);
    }

    readonly property string rawBarPos: Settings?.barPosition ?? "up"
    readonly property string barPos: (rawBarPos === "up" || rawBarPos === "top") ? "top" : ((rawBarPos === "down" || rawBarPos === "bottom") ? "bottom" : rawBarPos)
    readonly property bool isBarFloating: Settings?.barFloating ?? false
    readonly property bool framingEnabled: Settings?.screenFrameDocked ?? true
    readonly property bool isDocked: framingEnabled && !isBarFloating
    readonly property int cornerRadius: Settings?.screenCornerRadius ?? 16
    readonly property int borderWidth: Settings?.screenBorderWidth ?? 0
    readonly property color cornerColor: Theme?.cornerFill ?? Theme?.barBg ?? "#221919"
    readonly property string mode: Settings?.screenCornerMode ?? "all"

    readonly property bool isHorizontalBar: barPos === "top" || barPos === "bottom"
    readonly property bool isVerticalBar: barPos === "left" || barPos === "right"

    readonly property var hyprMonitor: Hyprland.monitorFor ? Hyprland.monitorFor(root.modelData) : null
    readonly property bool isFullscreen: (hyprMonitor?.activeWorkspace?.hasFullscreen) ?? (Hyprland.focusedWorkspace?.hasFullscreen ?? false)

    readonly property bool showTopLeft: {
        if (mode === "none") return false;
        if (mode === "monitor") return !hasAdjacentMonitorAt("top", "topLeft") && !hasAdjacentMonitorAt("left", "topLeft");
        if (mode === "all") return true;
        if (mode === "opposite") return isBarFloating || (barPos !== "top" && barPos !== "left");
        if (mode === "top" || mode === "left") return true;
        return false;
    }
    readonly property bool showTopRight: {
        if (mode === "none") return false;
        if (mode === "monitor") return !hasAdjacentMonitorAt("top", "topRight") && !hasAdjacentMonitorAt("right", "topRight");
        if (mode === "all") return true;
        if (mode === "opposite") return isBarFloating || (barPos !== "top" && barPos !== "right");
        if (mode === "top" || mode === "right") return true;
        return false;
    }
    readonly property bool showBottomLeft: {
        if (mode === "none") return false;
        if (mode === "monitor") return !hasAdjacentMonitorAt("bottom", "bottomLeft") && !hasAdjacentMonitorAt("left", "bottomLeft");
        if (mode === "all") return true;
        if (mode === "opposite") return isBarFloating || (barPos !== "bottom" && barPos !== "left");
        if (mode === "bottom" || mode === "left") return true;
        return false;
    }
    readonly property bool showBottomRight: {
        if (mode === "none") return false;
        if (mode === "monitor") return !hasAdjacentMonitorAt("bottom", "bottomRight") && !hasAdjacentMonitorAt("right", "bottomRight");
        if (mode === "all") return true;
        if (mode === "opposite") return isBarFloating || (barPos !== "bottom" && barPos !== "right");
        if (mode === "bottom" || mode === "right") return true;
        return false;
    }

    readonly property bool borderTopAllowed: {
        if (mode === "none") return false;
        if (mode === "monitor") return !hasAdjacentMonitor("top");
        if (mode === "all" || mode === "top") return true;
        if (mode === "opposite") return barPos === "bottom";
        return false;
    }
    readonly property bool borderBottomAllowed: {
        if (mode === "none") return false;
        if (mode === "monitor") return !hasAdjacentMonitor("bottom");
        if (mode === "all" || mode === "bottom") return true;
        if (mode === "opposite") return barPos === "top";
        return false;
    }
    readonly property bool borderLeftAllowed: {
        if (mode === "none") return false;
        if (mode === "monitor") return !hasAdjacentMonitor("left");
        if (mode === "all" || mode === "left") return true;
        if (mode === "opposite") return barPos === "right";
        return false;
    }
    readonly property bool borderRightAllowed: {
        if (mode === "none") return false;
        if (mode === "monitor") return !hasAdjacentMonitor("right");
        if (mode === "all" || mode === "right") return true;
        if (mode === "opposite") return barPos === "left";
        return false;
    }

    PanelWindow {
        id: horizontalOppositeWindow
        screen: root.modelData
        color: "transparent"

        visible: root.framingEnabled && !root.isFullscreen && root.isHorizontalBar && (
            (root.barPos === "top" ? ((root.borderWidth > 0 && root.borderBottomAllowed) || ((root.showBottomLeft || root.showBottomRight) && root.cornerRadius > 0))
                                   : ((root.borderWidth > 0 && root.borderTopAllowed)    || ((root.showTopLeft    || root.showTopRight)    && root.cornerRadius > 0)))
        )

        anchors {
            top: root.barPos === "bottom"
            bottom: root.barPos === "top"
            left: true
            right: true
        }

        implicitWidth: root.modelData?.width ?? 1920
        implicitHeight: Math.max(1, root.borderWidth + (root.cornerRadius > 0 ? root.cornerRadius : 0))
        exclusiveZone: root.borderWidth
        exclusionMode: root.borderWidth > 0 ? ExclusionMode.Normal : ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "quickshell:corners"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        mask: Region {}

        Item {
            anchors.fill: parent

            Rectangle {
                id: horizontalBorderRect
                x: 0
                y: root.barPos === "bottom" ? 0 : Math.round(parent.height - root.borderWidth)
                width: parent.width
                height: root.borderWidth
                color: root.cornerColor
                visible: root.borderWidth > 0 && (root.barPos === "top" ? root.borderBottomAllowed : root.borderTopAllowed)
            }

            ConcaveCorner {
                id: cornerL
                visible: (root.barPos === "top" ? root.showBottomLeft : root.showTopLeft) && root.cornerRadius > 0
                x: (root.borderWidth > 0 && leftBorder.visible ? root.borderWidth : 0)
                y: root.barPos === "top" ? 0 : (root.borderWidth > 0 && horizontalBorderRect.visible ? root.borderWidth : 0)
                radiusX: root.cornerRadius
                radiusY: root.cornerRadius
                fillColor: root.cornerColor
                flipX: false
                flipY: root.barPos === "top"
            }

            ConcaveCorner {
                id: cornerR
                visible: (root.barPos === "top" ? root.showBottomRight : root.showTopRight) && root.cornerRadius > 0
                x: Math.round(parent.width - (root.borderWidth > 0 && rightBorder.visible ? root.borderWidth : 0) - width)
                y: root.barPos === "top" ? 0 : (root.borderWidth > 0 && horizontalBorderRect.visible ? root.borderWidth : 0)
                radiusX: root.cornerRadius
                radiusY: root.cornerRadius
                fillColor: root.cornerColor
                flipX: true
                flipY: root.barPos === "top"
            }
        }
    }

    PanelWindow {
        id: horizontalBarSideWindow
        screen: root.modelData
        color: "transparent"

        visible: root.framingEnabled && !root.isFullscreen && root.isHorizontalBar && root.isBarFloating && (
            (root.barPos === "top" ? ((root.borderWidth > 0 && root.borderTopAllowed)    || ((root.showTopLeft    || root.showTopRight)    && root.cornerRadius > 0))
                                   : ((root.borderWidth > 0 && root.borderBottomAllowed) || ((root.showBottomLeft || root.showBottomRight) && root.cornerRadius > 0)))
        )

        anchors {
            top: root.barPos === "top"
            bottom: root.barPos === "bottom"
            left: true
            right: true
        }

        implicitWidth: root.modelData?.width ?? 1920
        implicitHeight: Math.max(1, root.borderWidth + (root.cornerRadius > 0 ? root.cornerRadius : 0))
        exclusiveZone: root.borderWidth
        exclusionMode: root.borderWidth > 0 ? ExclusionMode.Normal : ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "quickshell:corners"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        mask: Region {}

        Item {
            anchors.fill: parent

            Rectangle {
                id: barSideHorizontalBorderRect
                x: 0
                y: root.barPos === "top" ? 0 : Math.round(parent.height - root.borderWidth)
                width: parent.width
                height: root.borderWidth
                color: root.cornerColor
                visible: root.borderWidth > 0 && (root.barPos === "top" ? root.borderTopAllowed : root.borderBottomAllowed)
            }

            ConcaveCorner {
                id: barSideCornerL
                visible: (root.barPos === "top" ? root.showTopLeft : root.showBottomLeft) && root.cornerRadius > 0
                x: (root.borderWidth > 0 && leftBorder.visible ? root.borderWidth : 0)
                y: root.barPos === "top" ? (root.borderWidth > 0 && barSideHorizontalBorderRect.visible ? root.borderWidth : 0) : 0
                radiusX: root.cornerRadius
                radiusY: root.cornerRadius
                fillColor: root.cornerColor
                flipX: false
                flipY: root.barPos === "bottom"
            }

            ConcaveCorner {
                id: barSideCornerR
                visible: (root.barPos === "top" ? root.showTopRight : root.showBottomRight) && root.cornerRadius > 0
                x: Math.round(parent.width - (root.borderWidth > 0 && rightBorder.visible ? root.borderWidth : 0) - width)
                y: root.barPos === "top" ? (root.borderWidth > 0 && barSideHorizontalBorderRect.visible ? root.borderWidth : 0) : 0
                radiusX: root.cornerRadius
                radiusY: root.cornerRadius
                fillColor: root.cornerColor
                flipX: true
                flipY: root.barPos === "bottom"
            }
        }
    }

    PanelWindow {
        id: leftBorder
        screen: root.modelData
        color: root.cornerColor

        visible: root.framingEnabled && root.borderWidth > 0 && !root.isFullscreen && root.isHorizontalBar && root.borderLeftAllowed

        anchors {
            top: true
            bottom: true
            left: true
        }

        implicitWidth: root.borderWidth
        exclusiveZone: root.borderWidth
        exclusionMode: ExclusionMode.Normal
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "quickshell:border-left"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        mask: Region {}
    }

    PanelWindow {
        id: rightBorder
        screen: root.modelData
        color: root.cornerColor

        visible: root.framingEnabled && root.borderWidth > 0 && !root.isFullscreen && root.isHorizontalBar && root.borderRightAllowed

        anchors {
            top: true
            bottom: true
            right: true
        }

        implicitWidth: root.borderWidth
        exclusiveZone: root.borderWidth
        exclusionMode: ExclusionMode.Normal
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "quickshell:border-right"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        mask: Region {}
    }

    PanelWindow {
        id: verticalOppositeWindow
        screen: root.modelData
        color: "transparent"

        visible: root.framingEnabled && !root.isFullscreen && root.isVerticalBar && (
            (root.barPos === "left" ? ((root.borderWidth > 0 && root.borderRightAllowed) || ((root.showTopRight || root.showBottomRight) && root.cornerRadius > 0))
                                    : ((root.borderWidth > 0 && root.borderLeftAllowed)  || ((root.showTopLeft  || root.showBottomLeft)  && root.cornerRadius > 0)))
        )

        anchors {
            top: true
            bottom: true
            left: root.barPos === "right"
            right: root.barPos === "left"
        }

        implicitWidth: Math.max(1, root.borderWidth + (root.cornerRadius > 0 ? root.cornerRadius : 0))
        implicitHeight: root.modelData?.height ?? 1080
        exclusiveZone: root.borderWidth
        exclusionMode: root.borderWidth > 0 ? ExclusionMode.Normal : ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "quickshell:corners-vertical"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        mask: Region {}

        Item {
            anchors.fill: parent

            Rectangle {
                id: verticalBorderRect
                x: root.barPos === "right" ? 0 : Math.round(parent.width - root.borderWidth)
                y: 0
                width: root.borderWidth
                height: parent.height
                color: root.cornerColor
                visible: root.borderWidth > 0 && (root.barPos === "left" ? root.borderRightAllowed : root.borderLeftAllowed)
            }

            ConcaveCorner {
                id: cornerT
                visible: (root.barPos === "left" ? root.showTopRight : root.showTopLeft) && root.cornerRadius > 0
                x: root.barPos === "right" ? (root.borderWidth > 0 && verticalBorderRect.visible ? root.borderWidth : 0) : 0
                y: (root.borderWidth > 0 && topBorder.visible ? root.borderWidth : 0)
                radiusX: root.cornerRadius
                radiusY: root.cornerRadius
                fillColor: root.cornerColor
                flipX: root.barPos === "left"
                flipY: false
            }

            ConcaveCorner {
                id: cornerB
                visible: (root.barPos === "left" ? root.showBottomRight : root.showBottomLeft) && root.cornerRadius > 0
                x: root.barPos === "right" ? (root.borderWidth > 0 && verticalBorderRect.visible ? root.borderWidth : 0) : 0
                y: Math.round(parent.height - (root.borderWidth > 0 && bottomBorder.visible ? root.borderWidth : 0) - height)
                radiusX: root.cornerRadius
                radiusY: root.cornerRadius
                fillColor: root.cornerColor
                flipX: root.barPos === "left"
                flipY: true
            }
        }
    }

    PanelWindow {
        id: verticalBarSideWindow
        screen: root.modelData
        color: "transparent"

        visible: root.framingEnabled && !root.isFullscreen && root.isVerticalBar && root.isBarFloating && (
            (root.barPos === "left" ? ((root.borderWidth > 0 && root.borderLeftAllowed)  || ((root.showTopLeft  || root.showBottomLeft)  && root.cornerRadius > 0))
                                    : ((root.borderWidth > 0 && root.borderRightAllowed) || ((root.showTopRight || root.showBottomRight) && root.cornerRadius > 0)))
        )

        anchors {
            top: true
            bottom: true
            left: root.barPos === "left"
            right: root.barPos === "right"
        }

        implicitWidth: Math.max(1, root.borderWidth + (root.cornerRadius > 0 ? root.cornerRadius : 0))
        implicitHeight: root.modelData?.height ?? 1080
        exclusiveZone: root.borderWidth
        exclusionMode: root.borderWidth > 0 ? ExclusionMode.Normal : ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "quickshell:corners-vertical"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        mask: Region {}

        Item {
            anchors.fill: parent

            Rectangle {
                id: barSideVerticalBorderRect
                x: root.barPos === "left" ? 0 : Math.round(parent.width - root.borderWidth)
                y: 0
                width: root.borderWidth
                height: parent.height
                color: root.cornerColor
                visible: root.borderWidth > 0 && (root.barPos === "left" ? root.borderLeftAllowed : root.borderRightAllowed)
            }

            ConcaveCorner {
                id: barSideCornerT
                visible: (root.barPos === "left" ? root.showTopLeft : root.showTopRight) && root.cornerRadius > 0
                x: root.barPos === "left" ? (root.borderWidth > 0 && barSideVerticalBorderRect.visible ? root.borderWidth : 0) : 0
                y: (root.borderWidth > 0 && topBorder.visible ? root.borderWidth : 0)
                radiusX: root.cornerRadius
                radiusY: root.cornerRadius
                fillColor: root.cornerColor
                flipX: root.barPos === "right"
                flipY: false
            }

            ConcaveCorner {
                id: barSideCornerB
                visible: (root.barPos === "left" ? root.showBottomLeft : root.showBottomRight) && root.cornerRadius > 0
                x: root.barPos === "left" ? (root.borderWidth > 0 && barSideVerticalBorderRect.visible ? root.borderWidth : 0) : 0
                y: Math.round(parent.height - (root.borderWidth > 0 && bottomBorder.visible ? root.borderWidth : 0) - height)
                radiusX: root.cornerRadius
                radiusY: root.cornerRadius
                fillColor: root.cornerColor
                flipX: root.barPos === "right"
                flipY: true
            }
        }
    }

    PanelWindow {
        id: topBorder
        screen: root.modelData
        color: root.cornerColor

        visible: root.framingEnabled && root.borderWidth > 0 && !root.isFullscreen && root.isVerticalBar && root.borderTopAllowed

        anchors {
            top: true
            left: true
            right: true
        }

        implicitHeight: root.borderWidth
        exclusiveZone: root.borderWidth
        exclusionMode: ExclusionMode.Normal
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "quickshell:border-top"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        mask: Region {}
    }

    PanelWindow {
        id: bottomBorder
        screen: root.modelData
        color: root.cornerColor

        visible: root.framingEnabled && root.borderWidth > 0 && !root.isFullscreen && root.isVerticalBar && root.borderBottomAllowed

        anchors {
            bottom: true
            left: true
            right: true
        }

        implicitHeight: root.borderWidth
        exclusiveZone: root.borderWidth
        exclusionMode: ExclusionMode.Normal
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "quickshell:border-bottom"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        mask: Region {}
    }
}