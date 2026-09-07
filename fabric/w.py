import os
import subprocess
from gi.repository import Gdk, Gtk
from fabric.widgets.box import Box
from fabric.widgets.button import Button
from fabric.widgets.scrolledwindow import ScrolledWindow
from fabric.widgets.image import Image
from fabric.widgets.wayland import WaylandWindow as Window

class WallpaperSelector(Window):
    def __init__(self, **kwargs):
        super().__init__(
            name="wallpaper-window",
            layer="overlay",
            # Anchors updated to span the entire fullscreen area
            anchor="top bottom left right",
            exclusivity="none",
            keyboard_mode="exclusive",
            visible=False,
            **kwargs
        )

        self.wallpaper_dir = os.path.expanduser("~/.config/wallpaper")
        self.script_path = os.path.expanduser("~/.config/scripts/wl.sh")

        # Native GTK Grid to arrange images without rigid border lines
        self.grid = Gtk.Grid(name="wallpaper-grid")
        self.grid.set_column_spacing(20)
        self.grid.set_row_spacing(20)
        self.grid.set_halign(Gtk.Align.CENTER)
        self.grid.set_valign(Gtk.Align.CENTER)

        # Centered viewport wrap
        self.center_box = Box(
            orientation="v",
            name="wallpaper-center-box",
            children=[self.grid]
        )

        self.scroller = ScrolledWindow(name="wallpaper-scroller", child=self.center_box)
        self.scroller.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)

        self.main_container = Box(
            orientation="v",
            name="wallpaper-container",
            children=[self.scroller]
        )

        self.add(self.main_container)
        self.connect("key-press-event", self.on_key_press)
        self.load_wallpapers()

    def load_wallpapers(self):
        # Clear previous grid nodes cleanly
        for child in self.grid.get_children():
            self.grid.remove(child)

        if not os.path.exists(self.wallpaper_dir):
            return

        from gi.repository import GdkPixbuf

        valid_exts = (".png", ".jpg", ".jpeg", ".webp")
        files = [f for f in os.listdir(self.wallpaper_dir) if f.lower().endswith(valid_exts)]
        files = sorted(files)

        max_columns = 4

        for index, file in enumerate(files):
            full_path = os.path.join(self.wallpaper_dir, file)

            # --- MEMORY SAFE STREAM SCALING ---
            # Creates thumbnails at load-time so Cairo doesn't blow up memory limits
            try:
                pixbuf = GdkPixbuf.Pixbuf.new_from_file_at_scale(
                    full_path,
                    width=260,
                    height=150,
                    preserve_aspect_ratio=False
                )
                # Use standard GTK image widget to render the safe thumbnail pixbuf
                img_preview = Gtk.Image.new_from_pixbuf(pixbuf)
                img_preview.set_name("wallpaper-img")
            except Exception as e:
                print(f"Skipping corrupt image {file}: {e}")
                continue

            btn = Button(
                name="wallpaper-item-btn",
                child=img_preview,
                on_clicked=lambda *_, f=file: self.set_wallpaper(f)
            )

            row = index // max_columns
            col = index % max_columns

            self.grid.attach(btn, col, row, 1, 1)

        self.grid.show_all()

    def set_wallpaper(self, filename):
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
