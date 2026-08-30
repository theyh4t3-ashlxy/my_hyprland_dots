import QtQuick
import QtQuick.Layouts
import ".."
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications

PanelWindow {
    id: toastWindow

    readonly property bool isTop: (Settings?.barPosition ?? "top") === "top"
    readonly property real scoopW: Theme?.scoopRadiusX ?? 16

    anchors {
        top: toastWindow.isTop
        bottom: !toastWindow.isTop
        right: true
    }

    margins {
        top: toastWindow.isTop ? Theme.barHeight : 0
        bottom: !toastWindow.isTop ? Theme.barHeight : 0
        right: 16
    }

    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell:notifications"
    color: "transparent"

    implicitWidth: 360 + (toastWindow.scoopW * 2)
    implicitHeight: Math.max(1, toastCol.implicitHeight + 20)

    mask: Region {
        item: toastCol
    }

    ListModel {
        id: toastModel
    }

    Connections {
        target: NotificationService
        function onNotificationReceived(n) {
            let duration = n.expireTimeout > 0 ? n.expireTimeout : 5000
            if (n.urgency === NotificationUrgency.Critical) {
                duration = 0
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
            })
            if (toastModel.count > 5) {
                toastModel.remove(5, toastModel.count - 5)
            }
        }
    }

    ColumnLayout {
        id: toastCol
        anchors.top: toastWindow.isTop ? parent.top : undefined
        anchors.bottom: !toastWindow.isTop ? parent.bottom : undefined
        anchors.right: parent.right
        width: parent.width
        spacing: 6

        Repeater {
            model: toastModel

            delegate: NotificationCard {
                required property var modelData
                required property int index

                cardIndex: index
                notifData: modelData
                onClosed: {
                    if (index >= 0 && index < toastModel.count) {
                        toastModel.remove(index)
                    }
                }
            }
        }
    }
}
