import "."
import "Lock"
import "Time"
import "Bars/Float"
import "Power"
import "Vol_Bri"
import "SysInfo"
import "Widgets"
import "Wallpaper"
import "AppLauncher"
import "Notifications"
import Niri
import QtQuick
import Quickshell
import Quickshell.Io
import QtQuick.Layouts

ShellRoot{
    id: root

    readonly property string mainFont: "CaskaydiaCove Nerd Font"
    Component.onCompleted: {
        Qt.application.name = "Quickshell"
        Qt.application.organizationName = "quickshell"
        Qt.application.organizationDomain = "quickshell.org"
    }
    Niri {
        id: niri
        Component.onCompleted: connect()

        onConnected: console.info("Connected to niri")
        onErrorOccurred: function(error) {
            console.error("Niri error:", error)
        }
    }
    // LazyLoader{ active: true; component: Border{} }
    LazyLoader{ active: true; component: Bar{} }

    Wallpapers { id: wallpaperComp }
    WallpaperSelector {}

    LockScreen {
        id: lockscreen
    }
    IpcHandler {
        target: "lock"

        // Usage: quickshell ipc call lock toggle
        function toggle() {
            lockscreen.locked = !lockscreen.locked
        }

        // Usage: quickshell ipc call lock lock
        function lock() {
            lockscreen.locked = true
        }
    }

    Variants {
        model: Quickshell.screens
        AppLauncher {
            property var modelData
            screen: modelData
        }
    }

    Variants {
        model: Quickshell.screens
        Vol_Bri_Controls {
            property var modelData
            screen: modelData
        }
    }

    Variants {
        model: Quickshell.screens
        PowerMenu {
            property var modelData
            screen: modelData
        }
    }

    Variants {
        model: Quickshell.screens
        NotificationPopup {
            required property var modelData
            screen: modelData
        }
    }
    NotificationCenter {
        id: notifCenter
    }
    // IpcHandler {
    //     target: "notif"
    //     function toggle() {
    //         notifCenter.open = !notifCenter.open
    //     }
    // }
    NotificationPopup {}
    OSD {
        id: osd
    }
}
