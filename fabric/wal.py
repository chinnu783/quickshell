import os
import subprocess
from gi.repository import Gdk, Gtk
from fabric.widgets.box import Box
from fabric.widgets.button import Button
from fabric.widgets.scrolledwindow import ScrolledWindow
from fabric.widgets.wayland import WaylandWindow as Window

class WallpaperSelector(Window):
    def __init__(self, **kwargs):
        super().__init__(
            name="wallpaper-window",
            layer="overlay",
            anchor="center",
            exclusivity="none",
            keyboard_mode="exclusive",
            visible=False,
            **kwargs
        )

        # Match the wallpaper directory your shell script uses
        self.wallpaper_dir = os.path.expanduser("~/.config/wallpaper")
        self.script_path = os.path.expanduser("~/.config/scripts/wl.sh")
        self.set_size_request(400, 450)

        self.results_box = Box(orientation="v", spacing=6, name="wallpaper-results")

        self.scroller = ScrolledWindow(name="wallpaper-scroller", child=self.results_box)
        self.scroller.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
        self.scroller.set_size_request(360, 410)

        self.main_container = Box(
            orientation="v",
            name="wallpaper-container",
            children=[self.scroller]
        )

        self.add(self.main_container)
        self.connect("key-press-event", self.on_key_press)
        self.load_wallpapers()

    def load_wallpapers(self):
        for child in self.results_box.get_children():
            child.destroy()

        if not os.path.exists(self.wallpaper_dir):
            return

        valid_exts = (".png", ".jpg", ".jpeg", ".webp")
        files = [f for f in os.listdir(self.wallpaper_dir) if f.lower().endswith(valid_exts)]

        for file in sorted(files):
            # Pass just the filename string to match your script's $1 expectations
            btn = Button(
                label=file,
                name="wallpaper-item-btn",
                on_clicked=lambda *_, f=file: self.set_wallpaper(f)
            )
            btn.set_alignment(0, 0.5)
            self.results_box.add(btn)
        self.results_box.show_all()

    def set_wallpaper(self, filename):
        # Fire off your custom wl.sh script with the filename argument
        if os.path.exists(self.script_path):
            subprocess.Popen(
                [self.script_path, filename],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL
            )
        else:
            print(f"Error: Script not found at {self.script_path}")

        self.close_selector()

    def on_key_press(self, window, event):
        if event.keyval == Gdk.KEY_Escape:
            self.close_selector()
            return True
        return False

    def open_selector(self):
        self.load_wallpapers()
        self.show_all()

    def close_selector(self):
        self.hide()
