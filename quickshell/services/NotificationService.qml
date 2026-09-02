pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Notifications

QtObject {
    id: root

    property NotificationServer server: NotificationServer {
        id: notifServer

        // telling dbus we are not living in the stone age
        actionsSupported: true
        actionIconsSupported: true
        bodyMarkupSupported: true
        bodyHyperlinksSupported: true
        bodyImagesSupported: true
        imageSupported: true
        persistenceSupported: true

        onNotification: (notification) => {
            // track so our notification center widget doesn't have amnesia
            notification.tracked = true;
            root.notificationReceived(notification);
        }
    }

    signal notificationReceived(var notification)

    readonly property var trackedNotifications: notifServer.trackedNotifications

    // nuking every active notification from orbit
    function clearAll() {
        const notifs = notifServer.trackedNotifications?.values ? [...notifServer.trackedNotifications.values] : [];
        for (const n of notifs) {
            if (n && typeof n.dismiss === "function") {
                n.dismiss();
            }
        }
    }
}