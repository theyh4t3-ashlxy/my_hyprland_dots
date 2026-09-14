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

        x: isLeft ? (Theme.barHeight + 16)
         : isRight ? (root.width - Theme.barHeight - width - 16)
         : (root.width - width - 16)

        y: isBottom ? (root.height - Theme.barHeight - height - 16)
         : isTop ? (Theme.barHeight + 16)
         : 16

        Behavior on x { NumberAnimation { duration: Theme?.animFast ?? 120; easing.type: Easing.OutCubic } }
        Behavior on y { NumberAnimation { duration: Theme?.animFast ?? 120; easing.type: Easing.OutCubic } }
        Behavior on height { NumberAnimation { duration: Theme?.animFast ?? 120; easing.type: Easing.OutCubic } }

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

                    onDismissed: {
                        root.removeToast(modelData);
                    }
                }
            }
        }
    }
}
