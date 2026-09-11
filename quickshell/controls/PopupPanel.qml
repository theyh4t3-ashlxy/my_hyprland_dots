import QtQuick
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

    readonly property string pos: Settings?.barPosition ?? "up"
    readonly property bool isTop: pos === "up" || pos === "top"
    readonly property bool isBottom: pos === "down" || pos === "bottom"
    readonly property bool isLeft: pos === "left"
    readonly property bool isRight: pos === "right"
    readonly property bool isVertical: isLeft || isRight

    readonly property real scoopW: Math.max(16, Theme?.scoopRadiusX ?? 16)
    readonly property real scoopH: Math.max(16, Theme?.scoopRadiusY ?? 16)
    readonly property real marginX: scoopW + 8
    readonly property real marginY: scoopH + 8

    readonly property real screenW: root.screen?.width ?? root.width
    readonly property real screenH: root.screen?.height ?? root.height

    readonly property real maxAllowedWidth: Math.max(260, screenW - 32)
    readonly property real maxAllowedHeight: Math.max(200, screenH - 32)
    readonly property real effectiveWidth: Math.min(panelWidth, maxAllowedWidth)
    readonly property real effectiveHeight: Math.min(panelHeight, maxAllowedHeight)

    // animated expansion factor for smooth liquid welding
    readonly property real scoopAnimFactor: Math.min(1.0, Math.max(0.20, root.morphProgress))
    readonly property real curScoopW: root.scoopW * root.scoopAnimFactor
    readonly property real curScoopH: root.scoopH * root.scoopAnimFactor

    // clamped dock positioning
    readonly property real desiredBodyX: isVertical
        ? (isLeft ? 0 : (screenW - effectiveWidth))
        : (targetRelativeX > 0 ? (targetRelativeX - (effectiveWidth / 2)) : ((screenW / 2) - (effectiveWidth / 2)))
    readonly property real clampedBodyX: isVertical
        ? desiredBodyX
        : Math.max(marginX, Math.min(screenW - marginX - effectiveWidth, desiredBodyX))

    readonly property real desiredBodyY: isVertical
        ? (targetRelativeY > 0 ? targetRelativeY - (effectiveHeight / 2) : (screenH / 2) - (effectiveHeight / 2))
        : (isTop ? 0 : (screenH - effectiveHeight))
    readonly property real clampedBodyY: isVertical
        ? Math.max(marginY, Math.min(screenH - marginY - effectiveHeight, desiredBodyY))
        : desiredBodyY

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

    // Keep popup panel window outside the bar so the bar never loses mouse hover
    margins {
        top: root.isTop ? (Theme.barHeight ?? 32) : 0
        bottom: root.isBottom ? (Theme.barHeight ?? 32) : 0
        left: root.isLeft ? (Theme.barHeight ?? 32) : 0
        right: root.isRight ? (Theme.barHeight ?? 32) : 0
    }

    property bool wantsFocus: false
    exclusionMode: ExclusionMode.Ignore
    focusable: wantsFocus

    WlrLayershell.namespace: "quickshell:popup"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: (open && wantsFocus) ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    mask: Region {
        Region { item: popupBody }
        Region { item: scoopTopL.visible ? scoopTopL : null }
        Region { item: scoopTopR.visible ? scoopTopR : null }
        Region { item: scoopBottomL.visible ? scoopBottomL : null }
        Region { item: scoopBottomR.visible ? scoopBottomR : null }
        Region { item: scoopLeftT.visible ? scoopLeftT : null }
        Region { item: scoopLeftB.visible ? scoopLeftB : null }
        Region { item: scoopRightT.visible ? scoopRightT : null }
        Region { item: scoopRightB.visible ? scoopRightB : null }
        Region { item: root.pinned ? dismissArea : null }
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

    // click outside dismiss (only active when pinned via input mask)
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

        // Ambient soft drop-shadow / elevation glow
        Rectangle {
            visible: root.morphProgress > 0.1 && (Theme.barStyle === "glass" || Theme.barStyle === "glass-frost" || Theme.barStyle === "bento-floating" || Theme.barStyle === "cyber-neon")
            x: popupBody.x - 3
            y: popupBody.y - 3
            width: popupBody.width + 6
            height: popupBody.height + 6
            radius: (Theme.popupRadius ?? 16) + 3
            color: Theme.barStyle === "cyber-neon" ? Theme.glassGlow : Qt.rgba(0, 0, 0, 0.40 * root.morphProgress)
            z: 0
            opacity: root.morphProgress * 0.85
        }

        // top bar welding scoops
        ConcaveCorner {
            id: scoopTopL
            x: popupBody.x - root.curScoopW
            y: 0
            radiusX: root.curScoopW
            radiusY: root.curScoopH
            fillColor: Theme.popupBg
            showBorder: Theme.scoopBorderEnabled && Theme.popupBorderWidth > 0
            borderWidth: Theme.popupBorderWidth
            borderColor: Theme.popupBorderColor
            flipX: true
            flipY: false
            visible: root.isTop && root.scoopW > 0 && root.morphProgress > 0.20
        }
        ConcaveCorner {
            id: scoopTopR
            x: popupBody.x + popupBody.width
            y: 0
            radiusX: root.curScoopW
            radiusY: root.curScoopH
            fillColor: Theme.popupBg
            showBorder: Theme.scoopBorderEnabled && Theme.popupBorderWidth > 0
            borderWidth: Theme.popupBorderWidth
            borderColor: Theme.popupBorderColor
            flipX: false
            flipY: false
            visible: root.isTop && root.scoopW > 0 && root.morphProgress > 0.20
        }

        // bottom bar welding scoops
        ConcaveCorner {
            id: scoopBottomL
            x: popupBody.x - root.curScoopW
            y: root.height - root.curScoopH
            radiusX: root.curScoopW
            radiusY: root.curScoopH
            fillColor: Theme.popupBg
            showBorder: Theme.scoopBorderEnabled && Theme.popupBorderWidth > 0
            borderWidth: Theme.popupBorderWidth
            borderColor: Theme.popupBorderColor
            flipX: true
            flipY: true
            visible: root.isBottom && root.scoopW > 0 && root.morphProgress > 0.20
        }
        ConcaveCorner {
            id: scoopBottomR
            x: popupBody.x + popupBody.width
            y: root.height - root.curScoopH
            radiusX: root.curScoopW
            radiusY: root.curScoopH
            fillColor: Theme.popupBg
            showBorder: Theme.scoopBorderEnabled && Theme.popupBorderWidth > 0
            borderWidth: Theme.popupBorderWidth
            borderColor: Theme.popupBorderColor
            flipX: false
            flipY: true
            visible: root.isBottom && root.scoopW > 0 && root.morphProgress > 0.20
        }

        // left bar welding scoops
        ConcaveCorner {
            id: scoopLeftT
            x: 0
            y: popupBody.y - root.curScoopH
            radiusX: root.curScoopW
            radiusY: root.curScoopH
            fillColor: Theme.popupBg
            showBorder: Theme.scoopBorderEnabled && Theme.popupBorderWidth > 0
            borderWidth: Theme.popupBorderWidth
            borderColor: Theme.popupBorderColor
            flipX: false
            flipY: true
            visible: root.isLeft && root.scoopW > 0 && root.morphProgress > 0.20
        }
        ConcaveCorner {
            id: scoopLeftB
            x: 0
            y: popupBody.y + popupBody.height
            radiusX: root.curScoopW
            radiusY: root.curScoopH
            fillColor: Theme.popupBg
            showBorder: Theme.scoopBorderEnabled && Theme.popupBorderWidth > 0
            borderWidth: Theme.popupBorderWidth
            borderColor: Theme.popupBorderColor
            flipX: false
            flipY: false
            visible: root.isLeft && root.scoopW > 0 && root.morphProgress > 0.20
        }

        // right bar welding scoops
        ConcaveCorner {
            id: scoopRightT
            x: root.width - root.curScoopW
            y: popupBody.y - root.curScoopH
            radiusX: root.curScoopW
            radiusY: root.curScoopH
            fillColor: Theme.popupBg
            showBorder: Theme.scoopBorderEnabled && Theme.popupBorderWidth > 0
            borderWidth: Theme.popupBorderWidth
            borderColor: Theme.popupBorderColor
            flipX: true
            flipY: true
            visible: root.isRight && root.scoopW > 0 && root.morphProgress > 0.20
        }
        ConcaveCorner {
            id: scoopRightB
            x: root.width - root.curScoopW
            y: popupBody.y + popupBody.height
            radiusX: root.curScoopW
            radiusY: root.curScoopH
            fillColor: Theme.popupBg
            showBorder: Theme.scoopBorderEnabled && Theme.popupBorderWidth > 0
            borderWidth: Theme.popupBorderWidth
            borderColor: Theme.popupBorderColor
            flipX: true
            flipY: false
            visible: root.isRight && root.scoopW > 0 && root.morphProgress > 0.20
        }

        // physical expanding popup body
        Rectangle {
            id: popupBody
            x: root.isRight ? (root.width - popupBody.width) : (root.isLeft ? 0 : root.clampedBodyX)
            y: root.isBottom ? (root.height - popupBody.height) : (root.isTop ? 0 : root.clampedBodyY)
            width: root.isVertical ? Math.max(1, root.morphProgress * root.effectiveWidth) : root.effectiveWidth
            height: root.isVertical ? root.effectiveHeight : Math.max(1, root.morphProgress * root.effectiveHeight)
            color: Theme.popupBg
            border.width: Theme.popupBorderWidth ?? 1
            border.color: Theme.popupBorderColor
            clip: true
            z: 1

            topLeftRadius: (root.isTop || root.isLeft) ? 0 : (Theme.popupRadius ?? 16)
            topRightRadius: (root.isTop || root.isRight) ? 0 : (Theme.popupRadius ?? 16)
            bottomLeftRadius: (root.isBottom || root.isLeft) ? 0 : (Theme.popupRadius ?? 16)
            bottomRightRadius: (root.isBottom || root.isRight) ? 0 : (Theme.popupRadius ?? 16)

            // Specular top highlight line for glass depth
            Rectangle {
                visible: (Settings?.popupGlassHighlight ?? true) && (Theme.barStyle === "glass" || Theme.barStyle === "glass-frost" || Theme.barStyle === "bento-floating")
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: 1
                color: Theme.glassHighlight
                opacity: root.morphProgress
            }

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
                y: root.isTop ? (root.morphProgress - 1.0) * 16
                 : root.isBottom ? (1.0 - root.morphProgress) * 16
                 : 0
                x: root.isLeft ? (root.morphProgress - 1.0) * 16
                 : root.isRight ? (1.0 - root.morphProgress) * 16
                 : 0
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