import QtQuick
import QtQuick.Layouts
import ".."
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications

PanelWindow {
    id: toastWindow

    anchors {
        top: true
        right: true
    }

    margins {
        top: (Settings.barPosition === "top" ? (Theme.barHeight + 12) : 12)
        right: 16
    }

    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell:notifications"
    color: "transparent"

    implicitWidth: 380
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
            // don't flood the screen with 50 popups if an app goes feral
            if (toastModel.count > 5) {
                toastModel.remove(5, toastModel.count - 5)
            }
        }
    }

    ColumnLayout {
        id: toastCol
        anchors.top: parent.top
        anchors.right: parent.right
        width: 360
        spacing: 8

        Repeater {
            model: toastModel

            delegate: NotificationCard {
                required property var modelData
                required property int index

                width: 360
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
