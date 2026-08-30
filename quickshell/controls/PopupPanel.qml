import QtQuick
import ".."
import Quickshell
import Quickshell.Wayland

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
        top: root.isTop && !root.isVertical
        bottom: !root.isTop || root.isVertical
        left: true
        right: true
    }

    exclusionMode: ExclusionMode.Ignore
    focusable: true

    WlrLayershell.namespace: "quickshell:popup"
    WlrLayershell.keyboardFocus: open
        ? WlrKeyboardFocus.OnDemand
        : WlrKeyboardFocus.None

    // vertical bars dont need the bar gap or scoop space
    implicitHeight: root.isVertical
        ? panelHeight
        : (panelHeight + Theme.barHeight + scoopH)

    property real morphProgress: 0.0

    ParallelAnimation {
        id: morphAnim
        NumberAnimation {
            id: numAnim
            target: root
            property: "morphProgress"
            duration: root.open ? 280 : 190
            easing.type: root.open ? Easing.OutCubic : Easing.InCubic
        }
    }

    onOpenChanged: {
        numAnim.to = open ? 1.0 : 0.0;
        morphAnim.restart();
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
               : root.isVertical ? (root.height - height)
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

            // content unrolls with parallax translate and staggered opacity
            Item {
                id: contentWrapper
                width: root.panelWidth
                height: root.panelHeight
                y: root.isTop ? (root.morphProgress - 1.0) * 24 : (1.0 - root.morphProgress) * 24
                opacity: Math.max(0.0, (root.morphProgress - 0.2) / 0.8)

                Item {
                    id: contentItem
                    anchors.fill: parent
                    anchors.margins: Theme.popupPadding
                }
            }
        }
    }

    mask: Region { item: popupBody }
}
