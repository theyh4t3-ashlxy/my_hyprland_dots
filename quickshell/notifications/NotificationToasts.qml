import QtQuick
import QtQuick.Layouts
import ".."
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications

PanelWindow {
    id: toastWindow

    required property var modelData
    screen: modelData

    readonly property bool isTop: (Settings?.barPosition ?? "top") === "top"
    readonly property bool isBottom: (Settings?.barPosition ?? "top") === "bottom"
    readonly property real scoopW: Theme?.scoopRadiusX ?? 16
    readonly property real scoopH: Theme?.scoopRadiusY ?? 16

    anchors {
        top: toastWindow.isTop
        bottom: !toastWindow.isTop
        right: true
    }

    margins {
        top: toastWindow.isTop ? Theme.barHeight : 0
        bottom: toastWindow.isBottom ? Theme.barHeight : 0
        right: 16
    }

    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell:notifications"
    color: "transparent"

    implicitWidth: 380
    implicitHeight: Math.max(1, toastList.contentHeight + 24)

    // hide surface completely when zero toasts exist so clicks pass through
    visible: toastModel.count > 0

    mask: Region {
        item: toastList
    }

    ListModel {
        id: toastModel
    }

    Connections {
        target: NotificationService
        function onNotificationReceived(n) {
            if (Settings?.dnd && n.urgency !== NotificationUrgency.Critical) {
                return;
            }

            let duration = n.expireTimeout > 0 ? n.expireTimeout : 5000;
            if (n.urgency === NotificationUrgency.Critical) {
                duration = 0;
            }

            toastModel.insert(0, {
                notifRef: n,
                appName: n.appName || "system",
                summary: n.summary || "",
                body: n.body || "",
                icon: n.appIcon || "",
                image: n.image || "",
                urgency: n.urgency || 1,
                expireTimeout: duration,
                actions: n.actions || []
            });

            if (toastModel.count > 5) {
                toastModel.remove(5, toastModel.count - 5);
            }
        }
    }

    // left welding scoop connecting the top toast directly to the status bar
    ConcaveCorner {
        x: (toastWindow.width - 360) / 2 - toastWindow.scoopW
        y: toastWindow.isTop ? 0 : (toastWindow.height - toastWindow.scoopH)
        radiusX: toastWindow.scoopW
        radiusY: toastWindow.scoopH
        fillColor: Theme.popupBg
        flipX: true
        flipY: !toastWindow.isTop
        visible: toastModel.count > 0 && toastWindow.scoopW > 0
    }

    // right welding scoop connecting to the status bar
    ConcaveCorner {
        x: (toastWindow.width - 360) / 2 + 360
        y: toastWindow.isTop ? 0 : (toastWindow.height - toastWindow.scoopH)
        radiusX: toastWindow.scoopW
        radiusY: toastWindow.scoopH
        fillColor: Theme.popupBg
        flipX: false
        flipY: !toastWindow.isTop
        visible: toastModel.count > 0 && toastWindow.scoopW > 0
    }

    ListView {
        id: toastList
        anchors.fill: parent
        anchors.topMargin: toastWindow.isTop ? 4 : 0
        anchors.bottomMargin: !toastWindow.isTop ? 4 : 0
        spacing: 10
        interactive: false
        model: toastModel

        delegate: NotificationCard {
            required property var modelData
            required property int index

            cardIndex: index
            notifData: modelData
            onClosed: {
                if (index >= 0 && index < toastModel.count) {
                    toastModel.remove(index);
                }
            }
        }

        add: Transition {
            NumberAnimation {
                property: "opacity"
                from: 0.0
                to: 1.0
                duration: 160
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                property: "y"
                from: toastWindow.isTop ? -24 : 24
                duration: 160
                easing.type: Easing.OutCubic
            }
        }

        displaced: Transition {
            NumberAnimation {
                property: "y"
                duration: 140
                easing.type: Easing.OutCubic
            }
        }
    }
}