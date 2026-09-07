import fabric
import psutil
import os
from gi.repository import Gtk
from fabric import Application, Fabricator
from fabric.widgets.box import Box
from fabric.widgets.label import Label
from fabric.widgets.datetime import DateTime
from fabric.widgets.centerbox import CenterBox
from fabric.widgets.wayland import WaylandWindow as Window
from fabric.utils import monitor_file, get_relative_path
from launcher import AppLauncher
from power import PowerMenu
from wallpaper import WallpaperSelector
from volume import VolumeSlider
import work
import notify
import osd

class StatusBar(Window):
    def __init__(self, **kwargs):
        super().__init__(
            name="bar-window",  # CSS ID target
            layer="top",
            anchor="left top right",
            exclusivity="auto",
            **kwargs
        )

        # Labels with standard module CSS class targets
        self.date_time = Label(label="Time...", name="clock-widget", style_classes="bar-module")
        self.ram_label = Label(label="RAM: ...", name="ram-widget", style_classes="bar-module")
        self.cpu_label = Label(label="CPU: ...", name="cpu-widget", style_classes="bar-module")
        self.battery_label = Label(label="   --%", name="battery-widget", style_classes="bar-module battery-module")
        self.disk_label = Label(label="   --%", name="disk-widget", style_classes="bar-module")
        self.network_label = Label(label="   0.0 B/s", name="network-widget", style_classes="bar-module")
        #self.volume_label = Label(label="   100%", name="volume-widget", style_classes="bar-module")

        # External Workspaces widget
        self.workspaces = work.NiriWorkspaces()
        self.workspaces.set_name("workspaces-widget")

        # Fabricators
        self.ram_fabricator = Fabricator(interval=5000, poll_from=self.get_ram_usage)
        self.cpu_fabricator = Fabricator(interval=5000, poll_from=self.get_cpu_usage)
        self.battery_fabricator = Fabricator(interval=10000, poll_from=self.get_battery_status)
        self.disk_fabricator = Fabricator(interval=30000, poll_from=self.get_disk_usage)
        self.network_fabricator = Fabricator(interval=1000, poll_from=self.get_network_speed)
        self.date_time_fab = Fabricator(interval=500, poll_from='date +"%I:%M %p"')
        #self.volume_fab = Fabricator(stream=true, poll_from='wpctl get-volume 55')

        # Signals
        self.ram_fabricator.connect("changed", lambda fab, val: self.ram_label.set_label(f"RAM: {val}  "))
        self.cpu_fabricator.connect("changed", lambda fab, val: self.cpu_label.set_label(f"CPU: {val}  "))
        self.date_time_fab.connect("changed", lambda fab, val: self.date_time.set_label(f"{str(val).strip()}  "))
        self.battery_fabricator.connect("changed", lambda fab, val: self.battery_label.set_label(f"{val}"))
        self.disk_fabricator.connect("changed", lambda fab, val: self.disk_label.set_label(f"{val}"))
        self.network_fabricator.connect("changed", lambda fab, val: self.network_label.set_label(f"{val}"))
        #self.volume_fab.connect("changed", lambda fab, val: self.date_time.set_label(f"{str(val).strip()}  "))

        # Left Container
        self.left_box = Box(
            orientation="h",
            spacing=6,
            children=[self.ram_label, self.cpu_label, self.disk_label, self.network_label]
        )
        self.left_box.set_halign(Gtk.Align.START)

        # Center Container
        self.center_box = Box(
            orientation="h",
            spacing=0,
            children=[self.workspaces]
        )
        self.center_box.set_halign(Gtk.Align.CENTER)
        self.center_box.set_hexpand(True)

        # Right Container
        self.right_box = Box(
            orientation="h",
            spacing=6,
            children=[VolumeSlider(),self.battery_label, self.date_time]
        )
        self.right_box.set_halign(Gtk.Align.END)
        self.left_box.set_homogeneous(False)
        self.right_box.set_homogeneous(False)

        # Main Layout Container
        self.main_container = CenterBox(
            name="main-container",  # CSS ID target
            start_children=[self.left_box],
            center_children=[self.center_box],
            end_children=[self.right_box]
        )
        self.main_container.set_homogeneous(False)

        self.add(self.main_container)
        self.show_all()

    def get_ram_usage(self, *args):
        return f"{psutil.virtual_memory().percent}%"
    def get_cpu_usage(self, *args):
        return f"{psutil.cpu_percent(interval=None)}%"
    def get_battery_status(self, *args):
        try:
            battery = psutil.sensors_battery()
            percent = int(battery.percent)
            if battery is None: return "Null  "
            icon = " " if battery.power_plugged else [" "," "," "," "," "][min(percent // 20, 4)]

            # --- DYNAMIC CSS CLASS UPDATES ---
            # Clear old state classes safely
            self.battery_label.remove_style_class("battery-good")
            self.battery_label.remove_style_class("battery-critical")

            # Apply the matching Matugen state class based on current percentage
            if (percent <= 20 or percent >= 90) and battery.power_plugged:
                self.battery_label.add_style_class("battery-critical")
            else:
                self.battery_label.add_style_class("battery-good")

            return f"{percent}% {icon}"
        except Exception: return "Err "
    def get_disk_usage(self, *args):
        return f"{int(psutil.disk_usage('/').percent)}%  "
    def get_network_speed(self, *args):
        if not hasattr(self, "_prev_net_io"):
            self._prev_net_io = psutil.net_io_counters()
            return "0.0 B/s  "
        current_io = psutil.net_io_counters()
        total_bytes = (current_io.bytes_recv - self._prev_net_io.bytes_recv) + (current_io.bytes_sent - self._prev_net_io.bytes_sent)
        self._prev_net_io = current_io
        if total_bytes < 1024: return f"{total_bytes} B/s  "
        return f"{total_bytes / 1024:.1f} KB/s  " if total_bytes < 1048576 else f"{total_bytes / 1048576:.1f} MB/s "

if __name__ == "__main__":
    bar = StatusBar()
    notifications = notify.NotificationPopup()
    notifications_center = notify.NotificationCenter()
    osd = osd.OSDPopup()
    app_launcher = AppLauncher()
    powermenu = PowerMenu()
    wal = WallpaperSelector()
    app = Application("bar-example", bar, notifications, notifications_center, osd, app_launcher, powermenu, wal)

    # Combines Matugen and style.css in memory to prevent GTK import crashes
    def apply_stylesheet(*_):
        # try:
        #     # Paths to both sheets
        #     matugen_path = os.path.expanduser("~/.cache/matugen/fabric/colors.css")
        #     local_style_path = get_relative_path("./style.css")

        #     combined_css = ""

        #     # Read Matugen variables first if they exist
        #     if os.path.exists(matugen_path):
        #         with open(matugen_path, "r") as f:
        #             combined_css += f.read() + "\n"

        #     # Read your structural layout choices
        #     if os.path.exists(local_style_path):
        #         with open(local_style_path, "r") as f:
        #             combined_css += f.read()

        #     # Load the final merged data string directly into the provider
        #     return app.set_stylesheet_from_string(combined_css)
        # except Exception as e:
        #     print(f"CSS Loading Error: {e}")
        return app.set_stylesheet_from_file(get_relative_path("./style.css"))

    # Watch both local files and cache files for changes
    style_monitor = monitor_file(get_relative_path("./style.css"))
    matugen_monitor = monitor_file(os.path.expanduser("~/.cache/matugen/colors.css"))

    style_monitor.connect("changed", apply_stylesheet)
    matugen_monitor.connect("changed", apply_stylesheet)

    # Run once at startup
    apply_stylesheet()

    app.run()
