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

    function hasAdjacentMonitor(dir) {
        if (!root.modelData) return false;
        let all = Quickshell.screens;
        if (!all || all.length <= 1) return false;
        let sx = root.modelData.x, sy = root.modelData.y, sw = root.modelData.width, sh = root.modelData.height;
        for (let i = 0; i < all.length; i++) {
            let o = all[i];
            if (o === root.modelData || o.name === root.modelData.name) continue;
            let ox = o.x, oy = o.y, ow = o.width, oh = o.height;
            if (dir === "right" && Math.abs(ox - (sx + sw)) <= 4 && !(oy + oh <= sy || oy >= sy + sh)) return true;
            if (dir === "left" && Math.abs((ox + ow) - sx) <= 4 && !(oy + oh <= sy || oy >= sy + sh)) return true;
            if (dir === "top" && Math.abs((oy + oh) - sy) <= 4 && !(ox + ow <= sx || ox >= sx + sw)) return true;
            if (dir === "bottom" && Math.abs(oy - (sy + sh)) <= 4 && !(ox + ow <= sx || ox >= sx + sw)) return true;
        }
        return false;
    }

    readonly property string rawBarPos: Settings?.barPosition ?? "up"
    readonly property string barPos: (rawBarPos === "up" || rawBarPos === "top") ? "top" : ((rawBarPos === "down" || rawBarPos === "bottom") ? "bottom" : rawBarPos)
    readonly property bool isBarFloating: Settings?.barFloating ?? false
    readonly property bool isDocked: (Settings?.screenFrameDocked ?? true) && !isBarFloating
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
        if (mode === "monitor") return !hasAdjacentMonitor("top") && !hasAdjacentMonitor("left");
        if (mode === "all") return true;
        if (mode === "opposite") return barPos !== "top" && barPos !== "left";
        if (mode === "top" || mode === "left") return true;
        return false;
    }
    readonly property bool showTopRight: {
        if (mode === "none") return false;
        if (mode === "monitor") return !hasAdjacentMonitor("top") && !hasAdjacentMonitor("right");
        if (mode === "all") return true;
        if (mode === "opposite") return barPos !== "top" && barPos !== "right";
        if (mode === "top" || mode === "right") return true;
        return false;
    }
    readonly property bool showBottomLeft: {
        if (mode === "none") return false;
        if (mode === "monitor") return !hasAdjacentMonitor("bottom") && !hasAdjacentMonitor("left");
        if (mode === "all") return true;
        if (mode === "opposite") return barPos !== "bottom" && barPos !== "left";
        if (mode === "bottom" || mode === "left") return true;
        return false;
    }
    readonly property bool showBottomRight: {
        if (mode === "none") return false;
        if (mode === "monitor") return !hasAdjacentMonitor("bottom") && !hasAdjacentMonitor("right");
        if (mode === "all") return true;
        if (mode === "opposite") return barPos !== "bottom" && barPos !== "right";
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

        visible: root.isDocked && !root.isFullscreen && root.isHorizontalBar && (
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

        mask: Region {
            Region { item: horizontalBorderRect.visible ? horizontalBorderRect : null }
            Region { item: cornerL.visible ? cornerL : null }
            Region { item: cornerR.visible ? cornerR : null }
        }

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
        id: leftBorder
        screen: root.modelData
        color: root.cornerColor

        visible: root.isDocked && root.borderWidth > 0 && !root.isFullscreen && root.isHorizontalBar && root.borderLeftAllowed

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
    }

    PanelWindow {
        id: rightBorder
        screen: root.modelData
        color: root.cornerColor

        visible: root.isDocked && root.borderWidth > 0 && !root.isFullscreen && root.isHorizontalBar && root.borderRightAllowed

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
    }

    PanelWindow {
        id: verticalOppositeWindow
        screen: root.modelData
        color: "transparent"

        visible: root.isDocked && !root.isFullscreen && root.isVerticalBar && (
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

        mask: Region {
            Region { item: verticalBorderRect.visible ? verticalBorderRect : null }
            Region { item: cornerT.visible ? cornerT : null }
            Region { item: cornerB.visible ? cornerB : null }
        }

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
        id: topBorder
        screen: root.modelData
        color: root.cornerColor

        visible: root.isDocked && root.borderWidth > 0 && !root.isFullscreen && root.isVerticalBar && root.borderTopAllowed

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
    }

    PanelWindow {
        id: bottomBorder
        screen: root.modelData
        color: root.cornerColor

        visible: root.isDocked && root.borderWidth > 0 && !root.isFullscreen && root.isVerticalBar && root.borderBottomAllowed

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
    }
}