pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Notifications

QtObject {
    id: root

    property var _rawNotifs: ({})
    property var _dismissedIds: ({})

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
            if (!notification) return;
            // track so our notification center widget doesn't have amnesia
            notification.tracked = true;
            if (notification.id !== undefined && notification.id !== null) {
                root._rawNotifs[notification.id] = notification;
            }
            const safeNotif = root.sanitize(notification);
            root.notificationReceived(safeNotif);
        }
    }

    signal notificationReceived(var notification)
    signal notificationDismissed(var id)
    signal allCleared()
    signal toggleRequested()
    signal openRequested()
    signal closeRequested()

    function sanitize(notification): var {
        if (!notification) return null;

        let safeActions = [];
        try {
            if (notification.actions) {
                for (let i = 0; i < notification.actions.length; ++i) {
                    const act = notification.actions[i];
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

        const notifId = notification.id ?? Date.now();

        return {
            __sanitized: true,
            id: notifId,
            summary: String(notification.summary ?? ""),
            body: String(notification.body ?? ""),
            appName: String(notification.appName ?? "system"),
            appIcon: String(notification.appIcon ?? ""),
            urgency: Number(notification.urgency ?? 1),
            expireTimeout: Number(notification.expireTimeout ?? -1),
            image: String(notification.image ?? ""),
            actions: safeActions,
            dismiss: function() {
                root.dismiss(notifId);
            }
        };
    }

    function dismiss(id): void {
        if (id === undefined || id === null) return;
        if (root._dismissedIds[id]) return;
        root._dismissedIds[id] = true;

        let dismissed = false;
        try {
            const notifs = notifServer.trackedNotifications?.values
                ? [...notifServer.trackedNotifications.values]
                : (Array.isArray(notifServer.trackedNotifications) ? notifServer.trackedNotifications : []);
            const targets = notifs.filter(n => {
                try { return n && n.id === id; } catch (e) { return false; }
            });
            for (const n of targets) {
                if (typeof n.dismiss === "function") {
                    try {
                        n.dismiss();
                        dismissed = true;
                    } catch (e) {}
                }
            }
        } catch (e) {}

        if (!dismissed && root._rawNotifs && root._rawNotifs[id]) {
            const raw = root._rawNotifs[id];
            if (raw && typeof raw.dismiss === "function") {
                try { raw.dismiss(); } catch (e) {}
            }
        }

        if (root._rawNotifs && root._rawNotifs[id]) {
            delete root._rawNotifs[id];
        }

        root.notificationDismissed(id);
    }

    function toggle() {
        root.toggleRequested();
    }

    function open() {
        root.openRequested();
    }

    function close() {
        root.closeRequested();
    }

    readonly property var trackedNotifications: notifServer.trackedNotifications

    // nuking every active notification from orbit
    function clearAll() {
        try {
            const notifs = notifServer.trackedNotifications?.values ? [...notifServer.trackedNotifications.values] : [];
            for (const n of notifs) {
                if (n) {
                    if (n.id !== undefined && n.id !== null) {
                        root._dismissedIds[n.id] = true;
                    }
                    if (typeof n.dismiss === "function") {
                        try { n.dismiss(); } catch (e) {}
                    }
                }
            }
        } catch (e) {}
        root._rawNotifs = {};
        root.allCleared();
    }
}