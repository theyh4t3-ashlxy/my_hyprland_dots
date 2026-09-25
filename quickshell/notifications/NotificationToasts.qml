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

    function sanitize(notif): var {
        if (!notif) return null;
        if (notif.__sanitized) return notif;

        let safeActions = [];
        try {
            if (notif.actions) {
                for (let i = 0; i < notif.actions.length; ++i) {
                    const act = notif.actions[i];
                    if (act) {
                        safeActions.push({
                            id: act.id ?? "",
                            text: act.text ?? "",
                            invoke: function() {
                                try {
                                    if (typeof act.invoke === "function") act.invoke();
                                } catch (e) {}
                            }
                        });
                    }
                }
            }
        } catch (e) {}

        const notifId = notif.id ?? Date.now();
        return {
            __sanitized: true,
            id: notifId,
            summary: String(notif.summary ?? ""),
            body: String(notif.body ?? ""),
            appName: String(notif.appName ?? "system"),
            appIcon: String(notif.appIcon ?? ""),
            urgency: Number(notif.urgency ?? 1),
            expireTimeout: Number(notif.expireTimeout ?? -1),
            image: String(notif.image ?? ""),
            actions: safeActions,
            dismiss: function() {
                NotificationService.dismiss(notifId);
            }
        };
    }

    Connections {
        target: NotificationService

        function onNotificationReceived(notif) {
            if (Settings?.dnd) return;
            if (!notif) return;

            const safe = root.sanitize(notif);
            if (!safe) return;

            let updated = root.toastList.filter(n => n && n.id !== safe.id);
            while (updated.length >= 5) {
                let dropped = updated.shift();
                if (dropped && dropped.id !== undefined && dropped.id !== null) {
                    NotificationService.dismiss(dropped.id);
                } else if (dropped && typeof dropped.dismiss === "function") {
                    try { dropped.dismiss(); } catch (e) {}
                }
            }
            updated.push(safe);
            root.toastList = updated;
        }

        function onNotificationDismissed(id) {
            if (id === undefined || id === null) return;
            root.toastList = root.toastList.filter(n => n && n.id !== id);
        }

        function onAllCleared() {
            root.toastList = [];
        }
    }

    function removeToast(notif) {
        if (!notif) return;
        let id = (typeof notif === "object") ? notif.id : notif;
        if (id !== undefined && id !== null) {
            NotificationService.dismiss(id);
            root.toastList = root.toastList.filter(n => n && n.id !== id);
        } else {
            root.toastList = root.toastList.filter(n => n && n !== notif);
        }
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
