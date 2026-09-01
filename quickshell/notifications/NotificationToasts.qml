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

    anchors {
        top: toastWindow.isTop
        bottom: !toastWindow.isTop
        right: true
    }

    margins {
        top: toastWindow.isTop ? (Theme.barHeight + 8) : 0
        bottom: !toastWindow.isTop ? (Theme.barHeight + 8) : 0
        right: 16
    }

    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell:notifications"
    color: "transparent"

    implicitWidth: 380
    implicitHeight: Math.max(1, toastList.contentHeight + 16)

    mask: Region {
        item: toastList
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

    ListView {
        id: toastList
        anchors.fill: parent
        spacing: 8
        interactive: false
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

        add: Transition {
            NumberAnimation {
                property: "opacity"
                from: 0.0
                to: 1.0
                duration: Theme.animNormal
                easing.type: Theme.animEasing
            }
            NumberAnimation {
                property: "y"
                from: toastWindow.isTop ? -30 : 30
                duration: Theme.animNormal
                easing.type: Theme.animEasing
            }
        }

        displaced: Transition {
            NumberAnimation {
                property: "y"
                duration: Theme.animNormal
                easing.type: Theme.animEasing
            }
        }

        remove: Transition {
            NumberAnimation {
                property: "opacity"
                to: 0.0
                duration: Theme.animFast
                easing.type: Easing.InCubic
            }
        }
    }
}
