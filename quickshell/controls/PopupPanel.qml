import QtQuick
import QtQuick.Shapes
import ".."
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

PanelWindow {
    id: root

    property bool open: false
    property bool pinned: false
    property bool cardHovered: open && ((cardHoverArea && cardHoverArea.containsMouse) || (cardHoverHandler && cardHoverHandler.hovered))
    property real targetRelativeX: 0
    property real targetRelativeY: 0
    property int panelWidth: Theme?.popupWidth ?? 420
    property int panelHeight: Theme?.popupHeight ?? 500
    property alias cardWidth: root.panelWidth
    property alias cardHeight: root.panelHeight

    readonly property string rawPos: Settings?.barPosition ?? "top"
    readonly property string pos: (rawPos === "up" || rawPos === "top") ? "top" : ((rawPos === "down" || rawPos === "bottom") ? "bottom" : rawPos)
    readonly property bool isTop: pos === "top"
    readonly property bool isBottom: pos === "bottom"
    readonly property bool isLeft: pos === "left"
    readonly property bool isRight: pos === "right"
    readonly property bool isVertical: isLeft || isRight

    readonly property bool isFloating: Settings?.barFloating ?? false

    readonly property real scoopW: isFloating ? 0 : Math.max(8, Theme?.scoopRadiusX ?? Settings?.scoopRadius ?? 16)
    readonly property real scoopH: isFloating ? 0 : Math.max(8, Theme?.scoopRadiusY ?? Settings?.scoopRadius ?? 16)
    readonly property real screenMargin: 8

    readonly property real screenW: root.screen?.width ?? root.width
    readonly property real screenH: root.screen?.height ?? root.height

    readonly property real barSize: Theme.barHeight ?? 32

    readonly property real maxAllowedWidth: Math.max(260, (isVertical ? (screenW - barSize - 16) : (screenW - 32)))
    readonly property real maxAllowedHeight: Math.max(200, (!isVertical ? (screenH - barSize - 16) : (screenH - 32)))
    readonly property real effectiveWidth: Math.min(panelWidth, maxAllowedWidth)
    readonly property real effectiveHeight: Math.min(panelHeight, maxAllowedHeight)

    // clamped dock positioning (reserves margin for outward concave scoops)
    readonly property real desiredBodyX: isVertical
        ? (isLeft ? 0 : (root.width - effectiveWidth))
        : (targetRelativeX > 0 ? (targetRelativeX - (effectiveWidth / 2)) : ((root.width / 2) - (effectiveWidth / 2)))
    readonly property real clampedBodyX: isVertical
        ? desiredBodyX
        : Math.max(scoopW + screenMargin, Math.min(root.width - scoopW - screenMargin - effectiveWidth, desiredBodyX))

    readonly property real desiredBodyY: isVertical
        ? (targetRelativeY > 0 ? (targetRelativeY - (effectiveHeight / 2)) : ((root.height / 2) - (effectiveHeight / 2)))
        : (isTop ? 0 : (root.height - effectiveHeight))
    readonly property real clampedBodyY: isVertical
        ? Math.max(scoopH + screenMargin, Math.min(root.height - scoopH - screenMargin - effectiveHeight, desiredBodyY))
        : desiredBodyY

    // fluid animation & curvature metrics
    readonly property real morphT: Math.max(0.0001, root.morphProgress)
    readonly property real curBodyW: isVertical ? Math.max(1, morphT * effectiveWidth) : effectiveWidth
    readonly property real curBodyH: isVertical ? effectiveHeight : Math.max(1, morphT * effectiveHeight)

    readonly property real curScoopW: isVertical
        ? Math.max(0, Math.min(scoopW * morphT, curBodyW * 0.40))
        : Math.max(0, scoopW * Math.min(1.0, morphT * 1.5))
    readonly property real curScoopH: isVertical
        ? Math.max(0, scoopH * Math.min(1.0, morphT * 1.5))
        : Math.max(0, Math.min(scoopH * morphT, curBodyH * 0.40))
    readonly property real curRadius: Math.max(0, Math.min((Theme?.popupRadius ?? 16), (isVertical ? curBodyW : curBodyH) * 0.40))

    readonly property real tension: {
        let cs = Settings?.cornerStyle ?? "cubic";
        if (cs === "squircle") return 0.65;
        if (cs === "flared") return 0.44;
        if (cs === "continuous-bezier" || cs === "g2") return 0.58;
        return Settings?.scoopTension ?? 0.55228475;
    }

    // coordinate shorthands for the welded vector contour
    readonly property real bx: isVertical ? (isLeft ? 0 : (root.width - curBodyW)) : clampedBodyX
    readonly property real by: isVertical ? clampedBodyY : (isTop ? 0 : (root.height - curBodyH))
    readonly property real bw: curBodyW
    readonly property real bh: curBodyH
    readonly property real sw: curScoopW
    readonly property real sh: curScoopH
    readonly property real br: curRadius
    readonly property real k: tension

    default property alias content: contentItem.data

    implicitWidth: screenW
    implicitHeight: screenH

    visible: open || morphAnim.running
    color: "transparent"

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    // Dock window precisely against the bar edge
    margins {
        top: root.isTop ? root.barSize : 0
        bottom: root.isBottom ? root.barSize : 0
        left: root.isLeft ? root.barSize : 0
        right: root.isRight ? root.barSize : 0
    }

    property bool wantsFocus: false
    property int keyboardFocusMode: WlrKeyboardFocus.OnDemand
    exclusionMode: ExclusionMode.Ignore
    focusable: wantsFocus

    WlrLayershell.namespace: "quickshell:popup"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: (open && wantsFocus) ? keyboardFocusMode : WlrKeyboardFocus.None

    mask: Region {
        Region { item: dockedHullItem }
        Region { item: root.open ? dismissArea : null }
    }

    property real morphProgress: 0.0

    ParallelAnimation {
        id: morphAnim
        NumberAnimation {
            id: numAnim
            target: root
            property: "morphProgress"
            duration: root.open ? (Theme.expressiveDefault ?? 260) : (Theme.expressiveFast ?? 160)
            easing.type: root.open ? Easing.OutCubic : Easing.InCubic
        }
    }

    onOpenChanged: {
        numAnim.to = open ? 1.0 : 0.0;
        morphAnim.restart();
    }

    // click outside dismiss (active whenever open)
    MouseArea {
        id: dismissArea
        anchors.fill: parent
        cursorShape: Qt.ArrowCursor
        enabled: root.open
        onClicked: {
            root.pinned = false;
            root.open = false;
        }
    }

    Item {
        id: morphContainer
        anchors.fill: parent

        // ==========================================
        // AMBIENT ELEVATION DROP SHADOWS
        // ==========================================

        // Shadow: Top Docked
        Shape {
            id: shadowTop
            anchors.fill: parent
            visible: !root.isFloating && root.isTop && root.morphProgress > 0.05
            preferredRendererType: Shape.CurveRenderer
            y: 2
            opacity: root.morphProgress * 0.75
            z: 0

            ShapePath {
                fillColor: Qt.rgba(0, 0, 0, 0.28 * root.morphProgress)
                strokeColor: Theme.barStyle === "cyber-neon" ? Theme.glassGlow : Qt.rgba(0, 0, 0, 0.20 * root.morphProgress)
                strokeWidth: Theme.barStyle === "cyber-neon" ? 4 : 3
                capStyle: ShapePath.RoundCap
                joinStyle: ShapePath.RoundJoin

                startX: root.bx - root.sw; startY: 0
                PathCubic {
                    x: root.bx; y: root.sh
                    control1X: root.bx - root.sw * (1.0 - root.k); control1Y: 0
                    control2X: root.bx; control2Y: root.sh * (1.0 - root.k)
                }
                PathLine { x: root.bx; y: root.bh - root.br }
                PathCubic {
                    x: root.bx + root.br; y: root.bh
                    control1X: root.bx; control1Y: root.bh - root.br * (1.0 - root.k)
                    control2X: root.bx + root.br * (1.0 - root.k); control2Y: root.bh
                }
                PathLine { x: root.bx + root.bw - root.br; y: root.bh }
                PathCubic {
                    x: root.bx + root.bw; y: root.bh - root.br
                    control1X: root.bx + root.bw - root.br * (1.0 - root.k); control1Y: root.bh
                    control2X: root.bx + root.bw; control2Y: root.bh - root.br * (1.0 - root.k)
                }
                PathLine { x: root.bx + root.bw; y: root.sh }
                PathCubic {
                    x: root.bx + root.bw + root.sw; y: 0
                    control1X: root.bx + root.bw; control1Y: root.sh * (1.0 - root.k)
                    control2X: root.bx + root.bw + root.sw * (1.0 - root.k); control2Y: 0
                }
                PathLine { x: root.bx - root.sw; y: 0 }
            }
        }

        // Shadow: Bottom Docked
        Shape {
            id: shadowBottom
            anchors.fill: parent
            visible: !root.isFloating && root.isBottom && root.morphProgress > 0.05
            preferredRendererType: Shape.CurveRenderer
            y: -2
            opacity: root.morphProgress * 0.75
            z: 0

            readonly property real botY: root.by + root.bh

            ShapePath {
                fillColor: Qt.rgba(0, 0, 0, 0.28 * root.morphProgress)
                strokeColor: Theme.barStyle === "cyber-neon" ? Theme.glassGlow : Qt.rgba(0, 0, 0, 0.20 * root.morphProgress)
                strokeWidth: Theme.barStyle === "cyber-neon" ? 4 : 3
                capStyle: ShapePath.RoundCap
                joinStyle: ShapePath.RoundJoin

                startX: root.bx - root.sw; startY: shadowBottom.botY
                PathCubic {
                    x: root.bx; y: shadowBottom.botY - root.sh
                    control1X: root.bx - root.sw * (1.0 - root.k); control1Y: shadowBottom.botY
                    control2X: root.bx; control2Y: shadowBottom.botY - root.sh * (1.0 - root.k)
                }
                PathLine { x: root.bx; y: root.by + root.br }
                PathCubic {
                    x: root.bx + root.br; y: root.by
                    control1X: root.bx; control1Y: root.by + root.br * (1.0 - root.k)
                    control2X: root.bx + root.br * (1.0 - root.k); control2Y: root.by
                }
                PathLine { x: root.bx + root.bw - root.br; y: root.by }
                PathCubic {
                    x: root.bx + root.bw; y: root.by + root.br
                    control1X: root.bx + root.bw - root.br * (1.0 - root.k); control1Y: root.by
                    control2X: root.bx + root.bw; control2Y: root.by + root.br * (1.0 - root.k)
                }
                PathLine { x: root.bx + root.bw; y: shadowBottom.botY - root.sh }
                PathCubic {
                    x: root.bx + root.bw + root.sw; y: shadowBottom.botY
                    control1X: root.bx + root.bw; control1Y: shadowBottom.botY - root.sh * (1.0 - root.k)
                    control2X: root.bx + root.bw + root.sw * (1.0 - root.k); control2Y: shadowBottom.botY
                }
                PathLine { x: root.bx - root.sw; y: shadowBottom.botY }
            }
        }

        // Shadow: Left Docked
        Shape {
            id: shadowLeft
            anchors.fill: parent
            visible: !root.isFloating && root.isLeft && root.morphProgress > 0.05
            preferredRendererType: Shape.CurveRenderer
            x: 2
            opacity: root.morphProgress * 0.75
            z: 0

            ShapePath {
                fillColor: Qt.rgba(0, 0, 0, 0.28 * root.morphProgress)
                strokeColor: Theme.barStyle === "cyber-neon" ? Theme.glassGlow : Qt.rgba(0, 0, 0, 0.20 * root.morphProgress)
                strokeWidth: Theme.barStyle === "cyber-neon" ? 4 : 3
                capStyle: ShapePath.RoundCap
                joinStyle: ShapePath.RoundJoin

                startX: 0; startY: root.by - root.sh
                PathCubic {
                    x: root.sw; y: root.by
                    control1X: 0; control1Y: root.by - root.sh * (1.0 - root.k)
                    control2X: root.sw * (1.0 - root.k); control2Y: root.by
                }
                PathLine { x: root.bw - root.br; y: root.by }
                PathCubic {
                    x: root.bw; y: root.by + root.br
                    control1X: root.bw - root.br * (1.0 - root.k); control1Y: root.by
                    control2X: root.bw; control2Y: root.by + root.br * (1.0 - root.k)
                }
                PathLine { x: root.bw; y: root.by + root.bh - root.br }
                PathCubic {
                    x: root.bw - root.br; y: root.by + root.bh
                    control1X: root.bw; control1Y: root.by + root.bh - root.br * (1.0 - root.k)
                    control2X: root.bw - root.br * (1.0 - root.k); control2Y: root.by + root.bh
                }
                PathLine { x: root.sw; y: root.by + root.bh }
                PathCubic {
                    x: 0; y: root.by + root.bh + root.sh
                    control1X: root.sw * (1.0 - root.k); control1Y: root.by + root.bh
                    control2X: 0; control2Y: root.by + root.bh + root.sh * (1.0 - root.k)
                }
                PathLine { x: 0; y: root.by - root.sh }
            }
        }

        // Shadow: Right Docked
        Shape {
            id: shadowRight
            anchors.fill: parent
            visible: !root.isFloating && root.isRight && root.morphProgress > 0.05
            preferredRendererType: Shape.CurveRenderer
            x: -2
            opacity: root.morphProgress * 0.75
            z: 0

            readonly property real rx: root.bx + root.bw

            ShapePath {
                fillColor: Qt.rgba(0, 0, 0, 0.28 * root.morphProgress)
                strokeColor: Theme.barStyle === "cyber-neon" ? Theme.glassGlow : Qt.rgba(0, 0, 0, 0.20 * root.morphProgress)
                strokeWidth: Theme.barStyle === "cyber-neon" ? 4 : 3
                capStyle: ShapePath.RoundCap
                joinStyle: ShapePath.RoundJoin

                startX: shadowRight.rx; startY: root.by - root.sh
                PathCubic {
                    x: shadowRight.rx - root.sw; y: root.by
                    control1X: shadowRight.rx; control1Y: root.by - root.sh * (1.0 - root.k)
                    control2X: shadowRight.rx - root.sw * (1.0 - root.k); control2Y: root.by
                }
                PathLine { x: root.bx + root.br; y: root.by }
                PathCubic {
                    x: root.bx; y: root.by + root.br
                    control1X: root.bx + root.br * (1.0 - root.k); control1Y: root.by
                    control2X: root.bx; control2Y: root.by + root.br * (1.0 - root.k)
                }
                PathLine { x: root.bx; y: root.by + root.bh - root.br }
                PathCubic {
                    x: root.bx + root.br; y: root.by + root.bh
                    control1X: root.bx; control1Y: root.by + root.bh - root.br * (1.0 - root.k)
                    control2X: root.bx + root.br * (1.0 - root.k); control2Y: root.by + root.bh
                }
                PathLine { x: shadowRight.rx - root.sw; y: root.by + root.bh }
                PathCubic {
                    x: shadowRight.rx; y: root.by + root.bh + root.sh
                    control1X: shadowRight.rx - root.sw * (1.0 - root.k); control1Y: root.by + root.bh
                    control2X: shadowRight.rx; control2Y: root.by + root.bh + root.sh * (1.0 - root.k)
                }
                PathLine { x: shadowRight.rx; y: root.by - root.sh }
            }
        }

        // Shadow: Floating Card
        Shape {
            id: shadowFloating
            anchors.fill: parent
            visible: root.isFloating && root.morphProgress > 0.05
            preferredRendererType: Shape.CurveRenderer
            y: 3
            opacity: root.morphProgress * 0.75
            z: 0

            ShapePath {
                fillColor: Qt.rgba(0, 0, 0, 0.28 * root.morphProgress)
                strokeColor: Theme.barStyle === "cyber-neon" ? Theme.glassGlow : Qt.rgba(0, 0, 0, 0.20 * root.morphProgress)
                strokeWidth: Theme.barStyle === "cyber-neon" ? 4 : 3
                capStyle: ShapePath.RoundCap
                joinStyle: ShapePath.RoundJoin

                startX: root.bx + root.br; startY: root.by
                PathLine { x: root.bx + root.bw - root.br; y: root.by }
                PathCubic {
                    x: root.bx + root.bw; y: root.by + root.br
                    control1X: root.bx + root.bw - root.br * (1.0 - root.k); control1Y: root.by
                    control2X: root.bx + root.bw; control2Y: root.by + root.br * (1.0 - root.k)
                }
                PathLine { x: root.bx + root.bw; y: root.by + root.bh - root.br }
                PathCubic {
                    x: root.bx + root.bw - root.br; y: root.by + root.bh
                    control1X: root.bx + root.bw; control1Y: root.by + root.bh - root.br * (1.0 - root.k)
                    control2X: root.bx + root.bw - root.br * (1.0 - root.k); control2Y: root.by + root.bh
                }
                PathLine { x: root.bx + root.br; y: root.by + root.bh }
                PathCubic {
                    x: root.bx; y: root.by + root.bh - root.br
                    control1X: root.bx + root.br * (1.0 - root.k); control1Y: root.by + root.bh
                    control2X: root.bx; control2Y: root.by + root.bh - root.br * (1.0 - root.k)
                }
                PathLine { x: root.bx; y: root.by + root.br }
                PathCubic {
                    x: root.bx + root.br; y: root.by
                    control1X: root.bx; control1Y: root.by + root.br * (1.0 - root.k)
                    control2X: root.bx + root.br * (1.0 - root.k); control2Y: root.by
                }
            }
        }

        // ==========================================
        // WELDED HULLS & OPEN PERIMETER BORDERS
        // ==========================================

        // Hull: Top Docked
        Shape {
            id: hullTop
            anchors.fill: parent
            visible: !root.isFloating && root.isTop && root.morphProgress > 0.01
            preferredRendererType: Shape.CurveRenderer
            z: 1

            // Unified Solid Fill
            ShapePath {
                fillColor: Theme.popupBg
                strokeColor: "transparent"
                strokeWidth: 0

                startX: root.bx - root.sw; startY: 0
                PathCubic {
                    x: root.bx; y: root.sh
                    control1X: root.bx - root.sw * (1.0 - root.k); control1Y: 0
                    control2X: root.bx; control2Y: root.sh * (1.0 - root.k)
                }
                PathLine { x: root.bx; y: root.bh - root.br }
                PathCubic {
                    x: root.bx + root.br; y: root.bh
                    control1X: root.bx; control1Y: root.bh - root.br * (1.0 - root.k)
                    control2X: root.bx + root.br * (1.0 - root.k); control2Y: root.bh
                }
                PathLine { x: root.bx + root.bw - root.br; y: root.bh }
                PathCubic {
                    x: root.bx + root.bw; y: root.bh - root.br
                    control1X: root.bx + root.bw - root.br * (1.0 - root.k); control1Y: root.bh
                    control2X: root.bx + root.bw; control2Y: root.bh - root.br * (1.0 - root.k)
                }
                PathLine { x: root.bx + root.bw; y: root.sh }
                PathCubic {
                    x: root.bx + root.bw + root.sw; y: 0
                    control1X: root.bx + root.bw; control1Y: root.sh * (1.0 - root.k)
                    control2X: root.bx + root.bw + root.sw * (1.0 - root.k); control2Y: 0
                }
                PathLine { x: root.bx - root.sw; y: 0 }
            }

            // Continuous Perimeter Border (open at top boundary, zero seam)
            ShapePath {
                fillColor: "transparent"
                strokeColor: (Theme.popupBorderWidth > 0) ? Theme.popupBorderColor : "transparent"
                strokeWidth: Theme.popupBorderWidth ?? 1
                capStyle: ShapePath.RoundCap
                joinStyle: ShapePath.RoundJoin

                startX: root.bx - root.sw; startY: 0
                PathCubic {
                    x: root.bx; y: root.sh
                    control1X: root.bx - root.sw * (1.0 - root.k); control1Y: 0
                    control2X: root.bx; control2Y: root.sh * (1.0 - root.k)
                }
                PathLine { x: root.bx; y: root.bh - root.br }
                PathCubic {
                    x: root.bx + root.br; y: root.bh
                    control1X: root.bx; control1Y: root.bh - root.br * (1.0 - root.k)
                    control2X: root.bx + root.br * (1.0 - root.k); control2Y: root.bh
                }
                PathLine { x: root.bx + root.bw - root.br; y: root.bh }
                PathCubic {
                    x: root.bx + root.bw; y: root.bh - root.br
                    control1X: root.bx + root.bw - root.br * (1.0 - root.k); control1Y: root.bh
                    control2X: root.bx + root.bw; control2Y: root.bh - root.br * (1.0 - root.k)
                }
                PathLine { x: root.bx + root.bw; y: root.sh }
                PathCubic {
                    x: root.bx + root.bw + root.sw; y: 0
                    control1X: root.bx + root.bw; control1Y: root.sh * (1.0 - root.k)
                    control2X: root.bx + root.bw + root.sw * (1.0 - root.k); control2Y: 0
                }
            }
        }

        // Hull: Bottom Docked
        Shape {
            id: hullBottom
            anchors.fill: parent
            visible: !root.isFloating && root.isBottom && root.morphProgress > 0.01
            preferredRendererType: Shape.CurveRenderer
            z: 1

            readonly property real botY: root.by + root.bh

            // Unified Solid Fill
            ShapePath {
                fillColor: Theme.popupBg
                strokeColor: "transparent"
                strokeWidth: 0

                startX: root.bx - root.sw; startY: hullBottom.botY
                PathCubic {
                    x: root.bx; y: hullBottom.botY - root.sh
                    control1X: root.bx - root.sw * (1.0 - root.k); control1Y: hullBottom.botY
                    control2X: root.bx; control2Y: hullBottom.botY - root.sh * (1.0 - root.k)
                }
                PathLine { x: root.bx; y: root.by + root.br }
                PathCubic {
                    x: root.bx + root.br; y: root.by
                    control1X: root.bx; control1Y: root.by + root.br * (1.0 - root.k)
                    control2X: root.bx + root.br * (1.0 - root.k); control2Y: root.by
                }
                PathLine { x: root.bx + root.bw - root.br; y: root.by }
                PathCubic {
                    x: root.bx + root.bw; y: root.by + root.br
                    control1X: root.bx + root.bw - root.br * (1.0 - root.k); control1Y: root.by
                    control2X: root.bx + root.bw; control2Y: root.by + root.br * (1.0 - root.k)
                }
                PathLine { x: root.bx + root.bw; y: hullBottom.botY - root.sh }
                PathCubic {
                    x: root.bx + root.bw + root.sw; y: hullBottom.botY
                    control1X: root.bx + root.bw; control1Y: hullBottom.botY - root.sh * (1.0 - root.k)
                    control2X: root.bx + root.bw + root.sw * (1.0 - root.k); control2Y: hullBottom.botY
                }
                PathLine { x: root.bx - root.sw; y: hullBottom.botY }
            }

            // Continuous Perimeter Border (open at bottom boundary, zero seam)
            ShapePath {
                fillColor: "transparent"
                strokeColor: (Theme.popupBorderWidth > 0) ? Theme.popupBorderColor : "transparent"
                strokeWidth: Theme.popupBorderWidth ?? 1
                capStyle: ShapePath.RoundCap
                joinStyle: ShapePath.RoundJoin

                startX: root.bx - root.sw; startY: hullBottom.botY
                PathCubic {
                    x: root.bx; y: hullBottom.botY - root.sh
                    control1X: root.bx - root.sw * (1.0 - root.k); control1Y: hullBottom.botY
                    control2X: root.bx; control2Y: hullBottom.botY - root.sh * (1.0 - root.k)
                }
                PathLine { x: root.bx; y: root.by + root.br }
                PathCubic {
                    x: root.bx + root.br; y: root.by
                    control1X: root.bx; control1Y: root.by + root.br * (1.0 - root.k)
                    control2X: root.bx + root.br * (1.0 - root.k); control2Y: root.by
                }
                PathLine { x: root.bx + root.bw - root.br; y: root.by }
                PathCubic {
                    x: root.bx + root.bw; y: root.by + root.br
                    control1X: root.bx + root.bw - root.br * (1.0 - root.k); control1Y: root.by
                    control2X: root.bx + root.bw; control2Y: root.by + root.br * (1.0 - root.k)
                }
                PathLine { x: root.bx + root.bw; y: hullBottom.botY - root.sh }
                PathCubic {
                    x: root.bx + root.bw + root.sw; y: hullBottom.botY
                    control1X: root.bx + root.bw; control1Y: hullBottom.botY - root.sh * (1.0 - root.k)
                    control2X: root.bx + root.bw + root.sw * (1.0 - root.k); control2Y: hullBottom.botY
                }
            }
        }

        // Hull: Left Docked
        Shape {
            id: hullLeft
            anchors.fill: parent
            visible: !root.isFloating && root.isLeft && root.morphProgress > 0.01
            preferredRendererType: Shape.CurveRenderer
            z: 1

            // Unified Solid Fill
            ShapePath {
                fillColor: Theme.popupBg
                strokeColor: "transparent"
                strokeWidth: 0

                startX: 0; startY: root.by - root.sh
                PathCubic {
                    x: root.sw; y: root.by
                    control1X: 0; control1Y: root.by - root.sh * (1.0 - root.k)
                    control2X: root.sw * (1.0 - root.k); control2Y: root.by
                }
                PathLine { x: root.bw - root.br; y: root.by }
                PathCubic {
                    x: root.bw; y: root.by + root.br
                    control1X: root.bw - root.br * (1.0 - root.k); control1Y: root.by
                    control2X: root.bw; control2Y: root.by + root.br * (1.0 - root.k)
                }
                PathLine { x: root.bw; y: root.by + root.bh - root.br }
                PathCubic {
                    x: root.bw - root.br; y: root.by + root.bh
                    control1X: root.bw; control1Y: root.by + root.bh - root.br * (1.0 - root.k)
                    control2X: root.bw - root.br * (1.0 - root.k); control2Y: root.by + root.bh
                }
                PathLine { x: root.sw; y: root.by + root.bh }
                PathCubic {
                    x: 0; y: root.by + root.bh + root.sh
                    control1X: root.sw * (1.0 - root.k); control1Y: root.by + root.bh
                    control2X: 0; control2Y: root.by + root.bh + root.sh * (1.0 - root.k)
                }
                PathLine { x: 0; y: root.by - root.sh }
            }

            // Continuous Perimeter Border (open at left boundary, zero seam)
            ShapePath {
                fillColor: "transparent"
                strokeColor: (Theme.popupBorderWidth > 0) ? Theme.popupBorderColor : "transparent"
                strokeWidth: Theme.popupBorderWidth ?? 1
                capStyle: ShapePath.RoundCap
                joinStyle: ShapePath.RoundJoin

                startX: 0; startY: root.by - root.sh
                PathCubic {
                    x: root.sw; y: root.by
                    control1X: 0; control1Y: root.by - root.sh * (1.0 - root.k)
                    control2X: root.sw * (1.0 - root.k); control2Y: root.by
                }
                PathLine { x: root.bw - root.br; y: root.by }
                PathCubic {
                    x: root.bw; y: root.by + root.br
                    control1X: root.bw - root.br * (1.0 - root.k); control1Y: root.by
                    control2X: root.bw; control2Y: root.by + root.br * (1.0 - root.k)
                }
                PathLine { x: root.bw; y: root.by + root.bh - root.br }
                PathCubic {
                    x: root.bw - root.br; y: root.by + root.bh
                    control1X: root.bw; control1Y: root.by + root.bh - root.br * (1.0 - root.k)
                    control2X: root.bw - root.br * (1.0 - root.k); control2Y: root.by + root.bh
                }
                PathLine { x: root.sw; y: root.by + root.bh }
                PathCubic {
                    x: 0; y: root.by + root.bh + root.sh
                    control1X: root.sw * (1.0 - root.k); control1Y: root.by + root.bh
                    control2X: 0; control2Y: root.by + root.bh + root.sh * (1.0 - root.k)
                }
            }
        }

        // Hull: Right Docked
        Shape {
            id: hullRight
            anchors.fill: parent
            visible: !root.isFloating && root.isRight && root.morphProgress > 0.01
            preferredRendererType: Shape.CurveRenderer
            z: 1

            readonly property real rx: root.bx + root.bw

            // Unified Solid Fill
            ShapePath {
                fillColor: Theme.popupBg
                strokeColor: "transparent"
                strokeWidth: 0

                startX: hullRight.rx; startY: root.by - root.sh
                PathCubic {
                    x: hullRight.rx - root.sw; y: root.by
                    control1X: hullRight.rx; control1Y: root.by - root.sh * (1.0 - root.k)
                    control2X: hullRight.rx - root.sw * (1.0 - root.k); control2Y: root.by
                }
                PathLine { x: root.bx + root.br; y: root.by }
                PathCubic {
                    x: root.bx; y: root.by + root.br
                    control1X: root.bx + root.br * (1.0 - root.k); control1Y: root.by
                    control2X: root.bx; control2Y: root.by + root.br * (1.0 - root.k)
                }
                PathLine { x: root.bx; y: root.by + root.bh - root.br }
                PathCubic {
                    x: root.bx + root.br; y: root.by + root.bh
                    control1X: root.bx; control1Y: root.by + root.bh - root.br * (1.0 - root.k)
                    control2X: root.bx + root.br * (1.0 - root.k); control2Y: root.by + root.bh
                }
                PathLine { x: hullRight.rx - root.sw; y: root.by + root.bh }
                PathCubic {
                    x: hullRight.rx; y: root.by + root.bh + root.sh
                    control1X: hullRight.rx - root.sw * (1.0 - root.k); control1Y: root.by + root.bh
                    control2X: hullRight.rx; control2Y: root.by + root.bh + root.sh * (1.0 - root.k)
                }
                PathLine { x: hullRight.rx; y: root.by - root.sh }
            }

            // Continuous Perimeter Border (open at right boundary, zero seam)
            ShapePath {
                fillColor: "transparent"
                strokeColor: (Theme.popupBorderWidth > 0) ? Theme.popupBorderColor : "transparent"
                strokeWidth: Theme.popupBorderWidth ?? 1
                capStyle: ShapePath.RoundCap
                joinStyle: ShapePath.RoundJoin

                startX: hullRight.rx; startY: root.by - root.sh
                PathCubic {
                    x: hullRight.rx - root.sw; y: root.by
                    control1X: hullRight.rx; control1Y: root.by - root.sh * (1.0 - root.k)
                    control2X: hullRight.rx - root.sw * (1.0 - root.k); control2Y: root.by
                }
                PathLine { x: root.bx + root.br; y: root.by }
                PathCubic {
                    x: root.bx; y: root.by + root.br
                    control1X: root.bx + root.br * (1.0 - root.k); control1Y: root.by
                    control2X: root.bx; control2Y: root.by + root.br * (1.0 - root.k)
                }
                PathLine { x: root.bx; y: root.by + root.bh - root.br }
                PathCubic {
                    x: root.bx + root.br; y: root.by + root.bh
                    control1X: root.bx; control1Y: root.by + root.bh - root.br * (1.0 - root.k)
                    control2X: root.bx + root.br * (1.0 - root.k); control2Y: root.by + root.bh
                }
                PathLine { x: hullRight.rx - root.sw; y: root.by + root.bh }
                PathCubic {
                    x: hullRight.rx; y: root.by + root.bh + root.sh
                    control1X: hullRight.rx - root.sw * (1.0 - root.k); control1Y: root.by + root.bh
                    control2X: hullRight.rx; control2Y: root.by + root.bh + root.sh * (1.0 - root.k)
                }
            }
        }

        // Hull: Floating Card
        Shape {
            id: hullFloating
            anchors.fill: parent
            visible: root.isFloating && root.morphProgress > 0.01
            preferredRendererType: Shape.CurveRenderer
            z: 1

            // Solid Fill
            ShapePath {
                fillColor: Theme.popupBg
                strokeColor: "transparent"
                strokeWidth: 0

                startX: root.bx + root.br; startY: root.by
                PathLine { x: root.bx + root.bw - root.br; y: root.by }
                PathCubic {
                    x: root.bx + root.bw; y: root.by + root.br
                    control1X: root.bx + root.bw - root.br * (1.0 - root.k); control1Y: root.by
                    control2X: root.bx + root.bw; control2Y: root.by + root.br * (1.0 - root.k)
                }
                PathLine { x: root.bx + root.bw; y: root.by + root.bh - root.br }
                PathCubic {
                    x: root.bx + root.bw - root.br; y: root.by + root.bh
                    control1X: root.bx + root.bw; control1Y: root.by + root.bh - root.br * (1.0 - root.k)
                    control2X: root.bx + root.bw - root.br * (1.0 - root.k); control2Y: root.by + root.bh
                }
                PathLine { x: root.bx + root.br; y: root.by + root.bh }
                PathCubic {
                    x: root.bx; y: root.by + root.bh - root.br
                    control1X: root.bx + root.br * (1.0 - root.k); control1Y: root.by + root.bh
                    control2X: root.bx; control2Y: root.by + root.bh - root.br * (1.0 - root.k)
                }
                PathLine { x: root.bx; y: root.by + root.br }
                PathCubic {
                    x: root.bx + root.br; y: root.by
                    control1X: root.bx; control1Y: root.by + root.br * (1.0 - root.k)
                    control2X: root.bx + root.br * (1.0 - root.k); control2Y: root.by
                }
            }

            // Continuous Perimeter Border (full perimeter)
            ShapePath {
                fillColor: "transparent"
                strokeColor: (Theme.popupBorderWidth > 0) ? Theme.popupBorderColor : "transparent"
                strokeWidth: Theme.popupBorderWidth ?? 1
                capStyle: ShapePath.RoundCap
                joinStyle: ShapePath.RoundJoin

                startX: root.bx + root.br; startY: root.by
                PathLine { x: root.bx + root.bw - root.br; y: root.by }
                PathCubic {
                    x: root.bx + root.bw; y: root.by + root.br
                    control1X: root.bx + root.bw - root.br * (1.0 - root.k); control1Y: root.by
                    control2X: root.bx + root.bw; control2Y: root.by + root.br * (1.0 - root.k)
                }
                PathLine { x: root.bx + root.bw; y: root.by + root.bh - root.br }
                PathCubic {
                    x: root.bx + root.bw - root.br; y: root.by + root.bh
                    control1X: root.bx + root.bw; control1Y: root.by + root.bh - root.br * (1.0 - root.k)
                    control2X: root.bx + root.bw - root.br * (1.0 - root.k); control2Y: root.by + root.bh
                }
                PathLine { x: root.bx + root.br; y: root.by + root.bh }
                PathCubic {
                    x: root.bx; y: root.by + root.bh - root.br
                    control1X: root.bx + root.br * (1.0 - root.k); control1Y: root.by + root.bh
                    control2X: root.bx; control2Y: root.by + root.bh - root.br * (1.0 - root.k)
                }
                PathLine { x: root.bx; y: root.by + root.br }
                PathCubic {
                    x: root.bx + root.br; y: root.by
                    control1X: root.bx; control1Y: root.by + root.br * (1.0 - root.k)
                    control2X: root.bx + root.br * (1.0 - root.k); control2Y: root.by
                }
            }
        }

        // Hit-test item covering body and scoops for input masking
        Item {
            id: dockedHullItem
            x: root.isVertical ? root.bx : Math.max(0, root.bx - root.sw)
            y: root.isVertical ? Math.max(0, root.by - root.sh) : root.by
            width: root.isVertical ? root.bw : (root.bw + (root.sw * 2))
            height: root.isVertical ? (root.bh + (root.sh * 2)) : root.bh
        }

        // Interactive content container (clips content smoothly during emergence)
        Item {
            id: popupBody
            x: root.bx
            y: root.by
            width: root.bw
            height: root.bh
            clip: true
            z: 2

            MouseArea {
                id: cardHoverArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.ArrowCursor
                acceptedButtons: Qt.LeftButton | Qt.RightButton
            }

            HoverHandler {
                id: cardHoverHandler
            }

            Item {
                id: contentWrapper
                width: root.effectiveWidth
                height: root.effectiveHeight
                x: root.isLeft
                    ? (root.morphProgress - 1.0) * 16
                    : (root.isRight ? (root.curBodyW - root.effectiveWidth) + (1.0 - root.morphProgress) * 16 : 0)
                y: root.isTop
                    ? (root.morphProgress - 1.0) * 16
                    : (root.isBottom ? (root.curBodyH - root.effectiveHeight) + (1.0 - root.morphProgress) * 16 : 0)
                opacity: Math.max(0.0, (root.morphProgress - 0.2) / 0.8)

                Item {
                    id: contentItem
                    anchors.fill: parent
                    anchors.margins: Theme.popupPadding ?? 16
                }
            }
        }
    }
}