import "."
import "Lock"
import "Time"
import "Bars/Float"
import "Power"
// import "Vol_Bri"
import "SysInfo"
import "Widgets"
import "Wallpaper"
import "AppLauncher"
import "Notifications"
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

    // Notification Center & IPC
    // NotificationCenter {
    //     id: notifCenter
    // }

    IpcHandler {
        target: "notif"
        function toggle() {
            if (notifCenter) notifCenter.visible = !notifCenter.visible
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
