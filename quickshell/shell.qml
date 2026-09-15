import "."
import "Lock"
import "Notifications"
import "Widgets"
import "Bars/Float"
import "Popups"
import QtQuick
import Quickshell
import Quickshell.Io
import QtQuick.Layouts

ShellRoot {
    id: root

    readonly property string mainFont: "Cascadia Code NF" //"CaskaydiaCove Nerd Font"

    Component.onCompleted: {
        Qt.application.name = "Quickshell"
        Qt.application.organizationName = "quickshell"
        Qt.application.organizationDomain = "quickshell.org"
    }

    // Main Floating Bar
    LazyLoader {
        active: true
        component: Bar {}
    }

    // Wallpaper Management
    Wallpapers { id: wallpaperComp }
    WallpaperSelector { id: wallpaperSelector }

    // Lockscreen & IPC
    LockScreen {
        id: lockscreen
    }

    IpcHandler {
        target: "lock"

        function toggle() {
            lockscreen.locked = !lockscreen.locked
        }

        function lock() {
            lockscreen.locked = true
        }
    }

    // Application Launcher (Per Screen)
    Variants {
        model: Quickshell.screens
        AppLauncher {
            required property var modelData
            screen: modelData
        }
    }

    Variants {
        model: Quickshell.screens
        PowerMenu {
            required property var modelData
            screen: modelData
        }
    }

    CalendarPopup {
        id: calendarPopup
        visible: false
    }
    IpcHandler {
        target: "notif"
        function toggle() {
            if (calendarPopup) calendarPopup.visible = !calendarPopup.visible
        }
    }

    // Notification Popups (Per Screen - single instance)
    Variants {
        model: Quickshell.screens
        NotificationPopup {
            required property var modelData
            screen: modelData
        }
    }

    // On-Screen Display (Volume / Brightness)
    OSD {
        id: osd
    }
}
