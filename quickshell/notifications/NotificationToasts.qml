import QtQuick
import QtQuick.Layouts
import ".."
import "../corners"
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root

    required property var modelData
    screen: modelData

    readonly property string pos: Settings?.barPosition ?? "up"
    readonly property bool isTop: pos === "up" || pos === "top"
    readonly property bool isBottom: pos === "down" || pos === "bottom"
    readonly property bool isLeft: pos === "left"
    readonly property bool isRight: pos === "right"
    readonly property bool isVertical: isLeft || isRight

    readonly property real scoopW: Math.max(16, Theme?.scoopRadiusX ?? 16)
    readonly property real scoopH: Math.max(16, Theme?.scoopRadiusY ?? 16)

    color: "transparent"
    focusable: false
    exclusionMode: ExclusionMode.Ignore

    WlrLayershell.namespace: "quickshell:notifications"
    WlrLayershell.layer: WlrLayer.Overlay

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    // active toast list
    property var toastList: []

    visible: toastList.length > 0

    mask: Region {
        item: toastBox
    }

    Connections {
        target: NotificationService

        function onNotificationReceived(notif) {
            if (Settings?.dnd) return;
            if (!notif) return;

            let updated = root.toastList.filter(n => n && n !== notif && (notif.id === undefined || n.id !== notif.id));
            while (updated.length >= 5) {
                let dropped = updated.shift();
                if (dropped && typeof dropped.dismiss === "function") {
                    try { dropped.dismiss(); } catch (e) {}
                }
            }
            updated.push(notif);
            root.toastList = updated;
        }
    }

    function removeToast(notif) {
        if (!notif) return;
        root.toastList = root.toastList.filter(n => n && n !== notif && (notif.id === undefined || n.id !== notif.id));
    }

    // positioning container relative to bar
    Item {
        id: toastBox
        width: 360
        height: Math.max(1, toastCol.implicitHeight)

        x: isLeft ? Theme.barHeight
         : isRight ? (root.width - Theme.barHeight - width)
         : (root.width - width - root.scoopW - 20)

        y: isBottom ? (root.height - Theme.barHeight - height)
         : isTop ? Theme.barHeight
         : (20 + root.scoopH)

        Behavior on x { NumberAnimation { duration: Theme?.animFast ?? 120; easing.type: Easing.OutCubic } }
        Behavior on y { NumberAnimation { duration: Theme?.animFast ?? 120; easing.type: Easing.OutCubic } }
        Behavior on height { NumberAnimation { duration: Theme?.animFast ?? 120; easing.type: Easing.OutCubic } }

        // top bar welding scoops
        ConcaveCorner {
            x: -root.scoopW
            y: 0
            radiusX: root.scoopW
            radiusY: root.scoopH
            fillColor: Theme?.popupBg ?? Theme?.surface ?? "#1e1e2e"
            flipX: true
            flipY: false
            visible: root.isTop && root.toastList.length > 0
        }
        ConcaveCorner {
            x: toastBox.width
            y: 0
            radiusX: root.scoopW
            radiusY: root.scoopH
            fillColor: Theme?.popupBg ?? Theme?.surface ?? "#1e1e2e"
            flipX: false
            flipY: false
            visible: root.isTop && root.toastList.length > 0
        }

        // bottom bar welding scoops
        ConcaveCorner {
            x: -root.scoopW
            y: toastBox.height - root.scoopH
            radiusX: root.scoopW
            radiusY: root.scoopH
            fillColor: Theme?.popupBg ?? Theme?.surface ?? "#1e1e2e"
            flipX: true
            flipY: true
            visible: root.isBottom && root.toastList.length > 0
        }
        ConcaveCorner {
            x: toastBox.width
            y: toastBox.height - root.scoopH
            radiusX: root.scoopW
            radiusY: root.scoopH
            fillColor: Theme?.popupBg ?? Theme?.surface ?? "#1e1e2e"
            flipX: false
            flipY: true
            visible: root.isBottom && root.toastList.length > 0
        }

        // left bar welding scoops
        ConcaveCorner {
            x: 0
            y: -root.scoopH
            radiusX: root.scoopW
            radiusY: root.scoopH
            fillColor: Theme?.popupBg ?? Theme?.surface ?? "#1e1e2e"
            flipX: false
            flipY: true
            visible: root.isLeft && root.toastList.length > 0
        }
        ConcaveCorner {
            x: 0
            y: toastBox.height
            radiusX: root.scoopW
            radiusY: root.scoopH
            fillColor: Theme?.popupBg ?? Theme?.surface ?? "#1e1e2e"
            flipX: false
            flipY: false
            visible: root.isLeft && root.toastList.length > 0
        }

        // right bar welding scoops
        ConcaveCorner {
            x: toastBox.width - root.scoopW
            y: -root.scoopH
            radiusX: root.scoopW
            radiusY: root.scoopH
            fillColor: Theme?.popupBg ?? Theme?.surface ?? "#1e1e2e"
            flipX: true
            flipY: true
            visible: root.isRight && root.toastList.length > 0
        }
        ConcaveCorner {
            x: toastBox.width - root.scoopW
            y: toastBox.height
            radiusX: root.scoopW
            radiusY: root.scoopH
            fillColor: Theme?.popupBg ?? Theme?.surface ?? "#1e1e2e"
            flipX: true
            flipY: false
            visible: root.isRight && root.toastList.length > 0
        }

        ColumnLayout {
            id: toastCol
            width: parent.width
            spacing: 10

            Repeater {
                model: root.toastList

                delegate: NotificationCard {
                    required property var modelData
                    required property int index
                    notificationItem: modelData
                    Layout.fillWidth: true

                    dockTop: root.isTop && index === 0
                    dockBottom: root.isBottom && index === (root.toastList.length - 1)
                    dockLeft: root.isLeft
                    dockRight: root.isRight

                    onDismissed: {
                        root.removeToast(modelData);
                    }
                }
            }
        }
    }
}
