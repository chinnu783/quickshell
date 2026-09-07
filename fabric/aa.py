import fabric
import psutil
import os
from gi.repository import Gtk, Gio
from fabric import Application, Fabricator
from fabric.widgets.box import Box
from fabric.widgets.label import Label
from fabric.widgets.button import Button
from fabric.widgets.datetime import DateTime
from fabric.widgets.centerbox import CenterBox
from fabric.widgets.wayland import WaylandWindow as Window
from fabric.utils import get_relative_path, invoke_repeater
from launcher import AppLauncher
from power import PowerMenu
from wallpaper import WallpaperSelector
import subprocess
import work
import notify
import osd

class BarVolumePill(Box):
    def __init__(self, **kwargs):
        super().__init__(name="bar-volume-pil", **kwargs)
        self.label = Label(label="--% 󰕾", name="bar-volume-pill", style_classes="bar-module")
        self.add(self.label)
        self.update_state()
        invoke_repeater(1000, self.update_state)

    def update_state(self):
        try:
            output = subprocess.check_output(["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"], text=True)
            parts = output.strip().split()
            if len(parts) >= 2:
                vol = int(float(parts[1]) * 100)
                icon = "󰝟" if "[MUTED]" in output else "󰕾"
                self.label.set_label(f"{vol}% {icon}")
        except Exception:
            self.label.set_label("Err 󰕾")
        return True


class BarBrightnessPill(Box):
    def __init__(self, **kwargs):
        super().__init__(name="bar-brightness-pil", **kwargs)
        self.label = Label(label="--% 󰛨", name="bar-brightness-pill", style_classes="bar-module")
        self.add(self.label)
        self.update_state()
        invoke_repeater(1000, self.update_state)

    def update_state(self):
        try:
            # Uses brightnessctl to get current percentage
            cur = float(subprocess.check_output(["brightnessctl", "g"], text=True).strip())
            max_b = float(subprocess.check_output(["brightnessctl", "m"], text=True).strip())
            pct = int((cur / max_b) * 100)
            self.label.set_label(f"{pct}% 󰛨")
        except Exception:
            self.label.set_label("Err 󰛨")
        return True

class StatusBar(Window):
    def __init__(self, **kwargs):
        super().__init__(
            name="bar-window",  # CSS ID target
            layer="top",
            anchor="left top right",
            exclusivity="auto",
            **kwargs
        )

        self.wallpaper_win = WallpaperSelector()
        self.notify_win = notify.NotificationCenter()
        # Labels with standard module CSS class targets
        self.date_time = Label(label="Time...", name="clock-widget", style_classes="bar-module")
        self.ram_label = Label(label="RAM: ...", name="ram-widget", style_classes="bar-module")
        self.cpu_label = Label(label="CPU: ...", name="cpu-widget", style_classes="bar-module")
        self.battery_label = Label(label="   --%", name="battery-widget", style_classes="bar-module battery-module")
        self.disk_label = Label(label="   --%", name="disk-widget", style_classes="bar-module")
        self.network_label = Label(label="   0.0 B/s", name="network-widget", style_classes="bar-module")

        # Buttons
        self.pw_btn = Button(
            label="⚙",
            name="pw-widget",
            style_classes="bar-module",
            # on_button_press_event=self.on_btn_click
        )
        self.pw_btn.connect("button-press-event", self.on_btn_click)

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

        # Signals
        self.ram_fabricator.connect("changed", lambda fab, val: self.ram_label.set_label(f" {val}  "))
        self.cpu_fabricator.connect("changed", lambda fab, val: self.cpu_label.set_label(f" {val}  "))
        self.date_time_fab.connect("changed", lambda fab, val: self.date_time.set_label(f"{str(val).strip()}  "))
        self.battery_fabricator.connect("changed", lambda fab, val: self.battery_label.set_label(f"{val}"))
        self.disk_fabricator.connect("changed", lambda fab, val: self.disk_label.set_label(f"{val}"))
        self.network_fabricator.connect("changed", lambda fab, val: self.network_label.set_label(f"{val}"))

        # Left Container
        self.left_box = Box(
            orientation="h",
            spacing=6,
            children=[self.cpu_label, self.ram_label, self.disk_label, self.network_label]
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
            children=[BarBrightnessPill(),BarVolumePill(),self.battery_label, self.date_time, self.pw_btn]
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
            if battery is None: 
                return "Null  "
            percent = int(battery.percent)
            icon = " " if battery.power_plugged else [" "," "," "," "," "][min(percent // 20, 4)]

            self.battery_label.remove_style_class("battery-good")
            self.battery_label.remove_style_class("battery-critical")

            if percent <= 20 or percent >= 90:
                self.battery_label.add_style_class("battery-critical")
            else:
                self.battery_label.add_style_class("battery-good")

            return f"{percent}% {icon}"
        except Exception: 
            return "Err "
            
    def get_disk_usage(self, *args):
        return f"{int(psutil.disk_usage('/').percent)}%  "

    def on_btn_click(self, *args):
        event = None
        for arg in args:
            if hasattr(arg, "button"):
                event = arg
                break

        if not event and len(args) > 0 and hasattr(args[0], "get_current_event"):
            try:
                from gi.repository import Gtk
                event = Gtk.get_current_event()
            except:
                pass

        if event and hasattr(event, "button"):
            if event.button == 3:  # Right-click
                self.wallpaper_win.open_selector()
                return True
            elif event.button == 1:  # Left-click
                print("Left click action here")
                self.notify_win.open_center()
                return True

        return False

    def get_network_speed(self, *args):
        if not hasattr(self, "_prev_net_io"):
            self._prev_net_io = psutil.net_io_counters()
            return "0.0 B/s  "
        current_io = psutil.net_io_counters()
        total_bytes = (current_io.bytes_recv - self._prev_net_io.bytes_recv) + (current_io.bytes_sent - self._prev_net_io.bytes_sent)
        self._prev_net_io = current_io
        if total_bytes < 1024: 
            return f"{total_bytes} B/s  "
        return f"{total_bytes / 1024:.1f} KB/s  " if total_bytes < 1048576 else f"{total_bytes / 1048576:.1f} MB/s "


if __name__ == "__main__":
    bar = StatusBar()
    notifications = notify.NotificationPopup()
    notifications_center = notify.NotificationCenter()
    osd = osd.OSDPopup()
    app_launcher = AppLauncher()
    powermenu = PowerMenu()
    wal = WallpaperSelector()
    
    app = Application(
        "bar-example", 
        bar, 
        notifications, 
        notifications_center, 
        osd, 
        app_launcher, 
        powermenu, 
        wal
    )

    def apply_stylesheet(*_):
        """Combines Matugen layout outputs and structural choices into memory cleanly."""
        try:
            matugen_path = os.path.expanduser("~/.cache/matugen/fabric/colors.css")
            local_style_path = get_relative_path("./style.css")

            combined_css = ""

            if os.path.exists(matugen_path):
                with open(matugen_path, "r") as f:
                    combined_css += f.read() + "\n"

            if os.path.exists(local_style_path):
                with open(local_style_path, "r") as f:
                    combined_css += f.read()

            print("[Styles] Reloading merged CSS variables live...")
            return app.set_stylesheet_from_string(combined_css)
        except Exception as e:
            print(f"[Styles] Error loading combined stylesheet: {e}")

    # Ensure the cache folder exists to avoid Gio crashes on boot
    os.makedirs(os.path.expanduser("~/.cache/matugen/fabric/"), exist_ok=True)

    # FIXED: Watch the DIRECTORIES instead of individual files to catch deletion/re-creation events
    local_dir = Gio.File.new_for_path(os.path.dirname(get_relative_path("./style.css")))
    matugen_dir = Gio.File.new_for_path(os.path.expanduser("~/.cache/matugen/fabric/"))

    monitor_local = local_dir.monitor_directory(Gio.FileMonitorFlags.NONE, None)
    monitor_matugen = matugen_dir.monitor_directory(Gio.FileMonitorFlags.NONE, None)

    # Route directory file creation/change signals to the styling updates
    monitor_local.connect("changed", lambda m, f, o, e: apply_stylesheet() if e in [Gio.FileMonitorEvent.CHANGES_DONE_HINT, Gio.FileMonitorEvent.CREATED] else None)
    monitor_matugen.connect("changed", lambda m, f, o, e: apply_stylesheet() if e in [Gio.FileMonitorEvent.CHANGES_DONE_HINT, Gio.FileMonitorEvent.CREATED] else None)

    # Hard event fallback: force update when the wallpaper selection window closes
    wal.connect("hide", lambda *_: apply_stylesheet())

    # Execute on initial script startup
    apply_stylesheet()

    app.run()
