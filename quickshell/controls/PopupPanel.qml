import QtQuick
import ".."
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

PanelWindow {
    id: root

    property bool open: false
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

    readonly property real maxAllowedWidth: Math.max(260, root.width - (root.isVertical ? Theme.barHeight + 32 : 32))
    readonly property real maxAllowedHeight: Math.max(200, root.height - (root.isVertical ? 32 : Theme.barHeight + 32))
    readonly property real effectiveWidth: Math.min(panelWidth, maxAllowedWidth)
    readonly property real effectiveHeight: Math.min(panelHeight, maxAllowedHeight)

    // animated expansion factor for smooth liquid welding
    readonly property real scoopAnimFactor: Math.min(1.0, Math.max(0.20, root.morphProgress))
    readonly property real curScoopW: root.scoopW * root.scoopAnimFactor
    readonly property real curScoopH: root.scoopH * root.scoopAnimFactor

    // clamped dock positioning
    readonly property real desiredBodyX: isVertical
        ? (isLeft ? Theme.barHeight : (root.width - Theme.barHeight - effectiveWidth))
        : (targetRelativeX - (effectiveWidth / 2))
    readonly property real clampedBodyX: isVertical
        ? desiredBodyX
        : Math.max(marginX, Math.min(root.width - marginX - effectiveWidth, desiredBodyX))

    readonly property real desiredBodyY: isVertical
        ? (targetRelativeY > 0 ? targetRelativeY - (effectiveHeight / 2) : (root.height / 2) - (effectiveHeight / 2))
        : (isTop ? Theme.barHeight : (root.height - Theme.barHeight - effectiveHeight))
    readonly property real clampedBodyY: isVertical
        ? Math.max(marginY, Math.min(root.height - marginY - effectiveHeight, desiredBodyY))
        : desiredBodyY

    default property alias content: contentItem.data

    implicitWidth: root.screen?.width ?? 1920
    implicitHeight: root.screen?.height ?? 1080

    visible: open || morphAnim.running
    color: "transparent"

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    exclusionMode: ExclusionMode.Ignore
    focusable: true

    WlrLayershell.namespace: "quickshell:popup"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    property real morphProgress: 0.0

    ParallelAnimation {
        id: morphAnim
        NumberAnimation {
            id: numAnim
            target: root
            property: "morphProgress"
            duration: root.open ? 220 : 160
            easing.type: root.open ? Easing.OutCubic : Easing.InCubic
        }
    }

    onOpenChanged: {
        numAnim.to = open ? 1.0 : 0.0;
        morphAnim.restart();
    }

    HyprlandFocusGrab {
        id: focusGrab
        active: root.open
        windows: [root]
        onCleared: {
            if (root.open) {
                root.open = false;
            }
        }
    }

    // click outside dismiss
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.ArrowCursor
        enabled: root.open
        onClicked: {
            root.open = false;
        }
    }

    Item {
        id: morphContainer
        anchors.fill: parent

        // top bar welding scoops
        ConcaveCorner {
            x: popupBody.x - root.curScoopW
            y: Theme.barHeight
            radiusX: root.curScoopW
            radiusY: root.curScoopH
            fillColor: Theme.popupBg
            flipX: true
            flipY: false
            visible: root.isTop && root.scoopW > 0 && root.morphProgress > 0.20
        }
        ConcaveCorner {
            x: popupBody.x + popupBody.width
            y: Theme.barHeight
            radiusX: root.curScoopW
            radiusY: root.curScoopH
            fillColor: Theme.popupBg
            flipX: false
            flipY: false
            visible: root.isTop && root.scoopW > 0 && root.morphProgress > 0.20
        }

        // bottom bar welding scoops
        ConcaveCorner {
            x: popupBody.x - root.curScoopW
            y: root.height - Theme.barHeight - root.curScoopH
            radiusX: root.curScoopW
            radiusY: root.curScoopH
            fillColor: Theme.popupBg
            flipX: true
            flipY: true
            visible: root.isBottom && root.scoopW > 0 && root.morphProgress > 0.20
        }
        ConcaveCorner {
            x: popupBody.x + popupBody.width
            y: root.height - Theme.barHeight - root.curScoopH
            radiusX: root.curScoopW
            radiusY: root.curScoopH
            fillColor: Theme.popupBg
            flipX: false
            flipY: true
            visible: root.isBottom && root.scoopW > 0 && root.morphProgress > 0.20
        }

        // left bar welding scoops
        ConcaveCorner {
            x: Theme.barHeight
            y: popupBody.y - root.curScoopH
            radiusX: root.curScoopW
            radiusY: root.curScoopH
            fillColor: Theme.popupBg
            flipX: false
            flipY: true
            visible: root.isLeft && root.scoopW > 0 && root.morphProgress > 0.20
        }
        ConcaveCorner {
            x: Theme.barHeight
            y: popupBody.y + popupBody.height
            radiusX: root.curScoopW
            radiusY: root.curScoopH
            fillColor: Theme.popupBg
            flipX: false
            flipY: false
            visible: root.isLeft && root.scoopW > 0 && root.morphProgress > 0.20
        }

        // right bar welding scoops
        ConcaveCorner {
            x: root.width - Theme.barHeight - root.curScoopW
            y: popupBody.y - root.curScoopH
            radiusX: root.curScoopW
            radiusY: root.curScoopH
            fillColor: Theme.popupBg
            flipX: true
            flipY: true
            visible: root.isRight && root.scoopW > 0 && root.morphProgress > 0.20
        }
        ConcaveCorner {
            x: root.width - Theme.barHeight - root.curScoopW
            y: popupBody.y + popupBody.height
            radiusX: root.curScoopW
            radiusY: root.curScoopH
            fillColor: Theme.popupBg
            flipX: true
            flipY: false
            visible: root.isRight && root.scoopW > 0 && root.morphProgress > 0.20
        }

        // physical expanding popup body
        Rectangle {
            id: popupBody
            x: root.clampedBodyX
            y: root.clampedBodyY
            width: root.effectiveWidth
            height: Math.max(1, root.morphProgress * root.effectiveHeight)
            color: Theme.popupBg
            border.width: 0
            clip: true

            topLeftRadius: (root.isTop || root.isLeft) ? 0 : (Theme.popupRadius ?? 16)
            topRightRadius: (root.isTop || root.isRight) ? 0 : (Theme.popupRadius ?? 16)
            bottomLeftRadius: (root.isBottom || root.isLeft) ? 0 : (Theme.popupRadius ?? 16)
            bottomRightRadius: (root.isBottom || root.isRight) ? 0 : (Theme.popupRadius ?? 16)

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.ArrowCursor
                acceptedButtons: Qt.AllButtons
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