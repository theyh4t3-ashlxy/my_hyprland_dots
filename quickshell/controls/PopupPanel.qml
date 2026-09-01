import QtQuick
import ".."
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

PanelWindow {
    id: root

    property bool open: false
    property real targetRelativeX: 0
    property int panelWidth: Theme.popupWidth
    property int panelHeight: Theme.popupHeight
    property alias cardWidth: root.panelWidth
    property alias cardHeight: root.panelHeight

    readonly property bool isTop: (Settings?.barPosition ?? "top") === "top"
    readonly property bool isVertical: Theme?.isVertical ?? false
    readonly property real scoopW: Theme?.scoopRadiusX ?? 16
    readonly property real scoopH: Theme?.scoopRadiusY ?? 16
    readonly property real margin: scoopW + 8
    readonly property real desiredBodyX: targetRelativeX - (panelWidth / 2)
    readonly property real clampedBodyX: Math.max(margin, Math.min(root.width - margin - panelWidth, desiredBodyX))

    default property alias content: contentItem.data

    // don't murder the window until closing animation finishes
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
            duration: root.open ? 260 : 180
            easing.type: root.open ? Easing.OutCubic : Easing.InCubic
        }
    }

    onOpenChanged: {
        numAnim.to = open ? 1.0 : 0.0;
        morphAnim.restart();
    }

    // grab focus in hyprland so clicking outside or switching focus closes the popup
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

    // full screen outside click catcher
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

        // left weld scoop — only for horizontal bar
        ConcaveCorner {
            x: popupBody.x - root.scoopW
            y: root.isTop ? Theme.barHeight : root.height - Theme.barHeight - root.scoopH
            fillColor: Theme.surface_container_low
            flipX: true
            flipY: !root.isTop
            opacity: Math.min(1.0, root.morphProgress * 3.5)
            visible: !root.isVertical
        }

        // right weld scoop — only for horizontal bar
        ConcaveCorner {
            x: popupBody.x + popupBody.width
            y: root.isTop ? Theme.barHeight : root.height - Theme.barHeight - root.scoopH
            fillColor: Theme.surface_container_low
            flipX: false
            flipY: !root.isTop
            opacity: Math.min(1.0, root.morphProgress * 3.5)
            visible: !root.isVertical
        }

        // physical expanding shell
        Rectangle {
            id: popupBody
            x: root.clampedBodyX
            y: root.isTop ? Theme.barHeight
               : root.isVertical ? (root.height - height - 12)
               : (root.height - Theme.barHeight - height)
            width: root.panelWidth
            height: Math.max(1, root.morphProgress * root.panelHeight)
            color: Theme.surface_container_low
            clip: true

            // vertical bars get full rounded corners since theres no bar edge to weld to
            topLeftRadius: (root.isTop && !root.isVertical) ? 0 : Theme.popupRadius
            topRightRadius: (root.isTop && !root.isVertical) ? 0 : Theme.popupRadius
            bottomLeftRadius: (!root.isTop && !root.isVertical) ? 0 : Theme.popupRadius
            bottomRightRadius: (!root.isTop && !root.isVertical) ? 0 : Theme.popupRadius

            // prevent clicks inside the card from closing the popup
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.ArrowCursor
                acceptedButtons: Qt.AllButtons
            }

            // content unrolls with parallax translate and staggered opacity
            Item {
                id: contentWrapper
                width: root.panelWidth
                height: root.panelHeight
                y: root.isTop ? (root.morphProgress - 1.0) * 20 : (1.0 - root.morphProgress) * 20
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
