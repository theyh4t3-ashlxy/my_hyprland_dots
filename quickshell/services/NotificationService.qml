pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Notifications

QtObject {
    id: root

    property NotificationServer server: NotificationServer {
        id: notifServer
        onNotification: (notification) => {
            notification.tracked = true
            root.notificationReceived(notification)
        }
    }

    signal notificationReceived(var notification)

    readonly property var trackedNotifications: notifServer.trackedNotifications

    function clearAll() {
        let notifs = (notifServer.trackedNotifications.values || []).slice()
        for (let i = 0; i < notifs.length; i++) {
            let n = notifs[i]
            if (n && typeof n.dismiss === "function") {
                n.dismiss()
            }
        }
    }
}
