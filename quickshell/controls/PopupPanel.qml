import QtQuick
import ".."
import "../corners"
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

PanelWindow {
    id: root

    property bool open: false
    property real targetRelativeX: 0
    property real targetRelativeY: 0
    property int panelWidth: Theme.popupWidth
    property int panelHeight: Theme.popupHeight
    property alias cardWidth: root.panelWidth
    property alias cardHeight: root.panelHeight

    readonly property bool isTop: (Settings?.barPosition ?? "top") === "top"
    readonly property bool isBottom: (Settings?.barPosition ?? "top") === "bottom"
    readonly property bool isLeft: (Settings?.barPosition ?? "top") === "left"
    readonly property bool isRight: (Settings?.barPosition ?? "top") === "right"
    readonly property bool isVertical: isLeft || isRight

    readonly property real scoopW: Theme?.scoopRadiusX ?? 16
    readonly property real scoopH: Theme?.scoopRadiusY ?? 16
    readonly property real marginX: scoopW + 8
    readonly property real marginY: scoopH + 8

    // Animated dynamic concave expansion factor
    readonly property real scoopAnimFactor: Math.min(1.0, Math.max(0.01, root.morphProgress * 1.35))
    readonly property real curScoopW: root.scoopW * root.scoopAnimFactor
    readonly property real curScoopH: root.scoopH * root.scoopAnimFactor

    // Clamped positions for horizontal vs vertical bar docking
    readonly property real desiredBodyX: isVertical
        ? (isLeft ? Theme.barHeight : (root.width - Theme.barHeight - panelWidth))
        : (targetRelativeX - (panelWidth / 2))
    readonly property real clampedBodyX: isVertical
        ? desiredBodyX
        : Math.max(marginX, Math.min(root.width - marginX - panelWidth, desiredBodyX))

    readonly property real desiredBodyY: isVertical
        ? (targetRelativeY > 0 ? targetRelativeY - (panelHeight / 2) : (root.height / 2) - (panelHeight / 2))
        : (isTop ? Theme.barHeight : (root.height - Theme.barHeight - panelHeight))
    readonly property real clampedBodyY: isVertical
        ? Math.max(marginY, Math.min(root.height - marginY - panelHeight, desiredBodyY))
        : desiredBodyY

    default property alias content: contentItem.data

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
            duration: root.open ? 240 : 160
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

        // top docking scoops so my popups dont look detached
        ConcaveCorner {
            x: popupBody.x - root.curScoopW
            y: Theme.barHeight
            radiusX: root.curScoopW
            radiusY: root.curScoopH
            fillColor: Theme.popupBg
            flipX: true
            flipY: false
            visible: root.isTop && Settings.scoopRadius > 0 && root.morphProgress > 0.05
        }
        ConcaveCorner {
            x: popupBody.x + popupBody.width
            y: Theme.barHeight
            radiusX: root.curScoopW
            radiusY: root.curScoopH
            fillColor: Theme.popupBg
            flipX: false
            flipY: false
            visible: root.isTop && Settings.scoopRadius > 0 && root.morphProgress > 0.05
        }

        // bottom docking scoops
        ConcaveCorner {
            x: popupBody.x - root.curScoopW
            y: root.height - Theme.barHeight - root.curScoopH
            radiusX: root.curScoopW
            radiusY: root.curScoopH
            fillColor: Theme.popupBg
            flipX: true
            flipY: true
            visible: root.isBottom && Settings.scoopRadius > 0 && root.morphProgress > 0.05
        }
        ConcaveCorner {
            x: popupBody.x + popupBody.width
            y: root.height - Theme.barHeight - root.curScoopH
            radiusX: root.curScoopW
            radiusY: root.curScoopH
            fillColor: Theme.popupBg
            flipX: false
            flipY: true
            visible: root.isBottom && Settings.scoopRadius > 0 && root.morphProgress > 0.05
        }

        // left docking scoops
        ConcaveCorner {
            x: Theme.barHeight
            y: popupBody.y - root.curScoopH
            radiusX: root.curScoopW
            radiusY: root.curScoopH
            fillColor: Theme.popupBg
            flipX: false
            flipY: true
            visible: root.isLeft && Settings.scoopRadius > 0 && root.morphProgress > 0.05
        }
        ConcaveCorner {
            x: Theme.barHeight
            y: popupBody.y + popupBody.height
            radiusX: root.curScoopW
            radiusY: root.curScoopH
            fillColor: Theme.popupBg
            flipX: false
            flipY: false
            visible: root.isLeft && Settings.scoopRadius > 0 && root.morphProgress > 0.05
        }

        // right docking scoops
        ConcaveCorner {
            x: root.width - Theme.barHeight - root.curScoopW
            y: popupBody.y - root.curScoopH
            radiusX: root.curScoopW
            radiusY: root.curScoopH
            fillColor: Theme.popupBg
            flipX: true
            flipY: true
            visible: root.isRight && Settings.scoopRadius > 0 && root.morphProgress > 0.05
        }
        ConcaveCorner {
            x: root.width - Theme.barHeight - root.curScoopW
            y: popupBody.y + popupBody.height
            radiusX: root.curScoopW
            radiusY: root.curScoopH
            fillColor: Theme.popupBg
            flipX: true
            flipY: false
            visible: root.isRight && Settings.scoopRadius > 0 && root.morphProgress > 0.05
        }

        // physical expanding shell with 4-way directional welded joint radiuses
        Rectangle {
            id: popupBody
            x: root.clampedBodyX
            y: root.clampedBodyY
            width: root.panelWidth
            height: Math.max(1, root.morphProgress * root.panelHeight)
            color: Theme.popupBg
            border.width: 0
            clip: true

            topLeftRadius: (root.isTop || root.isLeft) ? 0 : Theme.popupRadius
            topRightRadius: (root.isTop || root.isRight) ? 0 : Theme.popupRadius
            bottomLeftRadius: (root.isBottom || root.isLeft) ? 0 : Theme.popupRadius
            bottomRightRadius: (root.isBottom || root.isRight) ? 0 : Theme.popupRadius

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.ArrowCursor
                acceptedButtons: Qt.AllButtons
            }

            Item {
                id: contentWrapper
                width: root.panelWidth
                height: root.panelHeight
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
                    anchors.margins: Theme.popupPadding
                }
            }
        }
    }
}
