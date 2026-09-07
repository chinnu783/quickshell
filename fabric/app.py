import fabric
import psutil
from gi.repository import Gtk
from fabric import Application, Fabricator
from fabric.widgets.box import Box
from fabric.widgets.label import Label
from fabric.widgets.datetime import DateTime
from fabric.widgets.centerbox import CenterBox
from fabric.widgets.wayland import WaylandWindow as Window
import work

class StatusBar(Window):
    def __init__(self, **kwargs):
        super().__init__(
            layer="top",
            anchor="left top right",
            exclusivity="auto",
            **kwargs
        )

        self.date_time = Label(label=f"Waiting For Tim...")
        self.ram_label = Label(label="RAM: ...")
        self.cpu_label = Label(label="CPU: ...")
        self.battery_label = Label(label="   --%")
        self.disk_label = Label(label="   --%")
        self.network_label = Label(label="   0.0 B/s")
        self.workspaces = work.NiriWorkspaces()

        self.ram_fabricator = Fabricator(
            interval=5000,
            poll_from=self.get_ram_usage
        )
        self.cpu_fabricator = Fabricator(
            interval=5000,
            poll_from=self.get_cpu_usage
        )
        self.battery_fabricator = Fabricator(
            interval=10000,
            poll_from=self.get_battery_status
        )
        self.disk_fabricator = Fabricator(
            interval=30000,
            poll_from=self.get_disk_usage
        )
        self.network_fabricator = Fabricator(
            interval=1000,
            poll_from=self.get_network_speed
        )
        self.date_time_fab = Fabricator(
            interval=500,
            poll_from='date +"%I:%M %p"'
            # on_changed=lambda f, v: print(f"{v.strip()}"),
        )

        self.ram_fabricator.connect("changed", lambda fab, val: self.ram_label.set_label(f" RAM: {val}  "))
        self.cpu_fabricator.connect("changed", lambda fab, val: self.cpu_label.set_label(f" CPU: {val}  "))
        self.date_time_fab.connect("changed", lambda fab, val: self.date_time.set_label(f" {str(val).strip()}  "))
        self.battery_fabricator.connect("changed", lambda fab, val: self.battery_label.set_label(f" {val} "))
        self.disk_fabricator.connect("changed", lambda fab, val: self.disk_label.set_label(f" {val} "))
        self.network_fabricator.connect("changed", lambda fab, val: self.network_label.set_label(f" {val} "))

        self.left_box = Box(
            orientation="h",
            spacing=10,
            children=[
                self.ram_label,
                self.cpu_label,
                self.disk_label,
                self.network_label
            ]
        )
        self.left_box.set_halign(Gtk.Align.START) # Locks this box to the far left

        self.center_box = Box(
            orientation="h",
            spacing=10,
            children=[
                self.workspaces
            ]
        )
        self.center_box.set_halign(Gtk.Align.CENTER) # Centers content within available space
        self.center_box.set_hexpand(True)     # Forces center box to push left/right boxes away

        self.right_box = Box(
            orientation="h",
            spacing=10,
            children=[
                self.battery_label,
                self.date_time
            ]
        )
        self.right_box.set_halign(Gtk.Align.END) # Locks this box to the far right
        self.left_box.set_homogeneous(False)
        self.right_box.set_homogeneous(False)

        self.left_spacer = Box()
        self.left_spacer.set_hexpand(True)

        self.right_spacer = Box()
        self.right_spacer.set_hexpand(True)

        # 3. Assemble everything inside a master horizontal layout box
        self.main_container = Box(
            orientation="h",
            # Order is critical: Left -> Center -> Right
            children=[self.left_box, self.left_spacer, self.center_box, self.right_spacer, self.right_box]
        )

        # 4. Attach the parent layout container to the main top-level window
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
            icon = " " if battery.power_plugged else " "
            return f" {percent}% {icon}"
        except Exception:
            return "   Err"
    def get_disk_usage(self, *args):
        usage = psutil.disk_usage('/')
        return f" {int(usage.percent)}%  "
    def get_network_speed(self, *args):
        if not hasattr(self, "_prev_net_io"):
            self._prev_net_io = psutil.net_io_counters()
            return " 0.0 B/s  "
        current_io = psutil.net_io_counters()
        bytes_recv = current_io.bytes_recv - self._prev_net_io.bytes_recv
        bytes_sent = current_io.bytes_sent - self._prev_net_io.bytes_sent
        self._prev_net_io = current_io # Update state for next cycle
        total_bytes = bytes_recv + bytes_sent
        if total_bytes < 1024:
            return f"{total_bytes} B/s  "
        elif total_bytes < 1024 * 1024:
            return f"{total_bytes / 1024:.1f} KB/s  "
        else:
            return f"{total_bytes / (1024 * 1024):.1f} MB/s  "

if __name__ == "__main__":
    bar = StatusBar()
    app = Application("bar-example", bar)
    app.run()
