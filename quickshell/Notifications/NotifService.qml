pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Notifications

Singleton {
    id: root

    // List of active toast popups
    property var activePopups: []

    // Directly bind to tracked notifications model
    readonly property alias trackedNotifications: server.trackedNotifications

    NotificationServer {
        id: server
        keepOnReload: true
        actionsSupported: true
        bodySupported: true
        imageSupported: true

        onNotification: notif => {
            // Add to active toast list without dismissing from main server
            var current = root.activePopups.slice()
            current.unshift(notif)
            root.activePopups = current

            var ms = notif.urgency === Notification.Critical ? 8000 : 4000
            var t = Qt.createQmlObject(
                'import QtQuick; Timer { interval: ' + ms + '; running: true; repeat: false }',
                root, "notifTimer_" + notif.id
            )
            t.triggered.connect(function() {
                root.dismissToast(notif.id)
                t.destroy()
            })
        }
    }

    // Only removes the notification from floating popups, keeps in Notification Center
    function dismissToast(id) {
        var current = root.activePopups.slice()
        for (var i = 0; i < current.length; i++) {
            if (current[i].id === id) {
                current.splice(i, 1)
                break
            }
        }
        root.activePopups = current
    }

    // Dismisses notification everywhere (Center + Popups)
    function dismissAll() {
        var list = server.trackedNotifications.values
        for (var i = 0; i < list.length; i++) {
            list[i].dismiss()
        }
        root.activePopups = []
    }
}
