import os
import subprocess
import threading
from gi.repository import Gdk, Gtk, GdkPixbuf, GLib
from fabric.widgets.box import Box
from fabric.widgets.button import Button
from fabric.widgets.scrolledwindow import ScrolledWindow
from fabric.widgets.wayland import WaylandWindow as Window

class WallpaperSelector(Window):
    def __init__(self, **kwargs):
        super().__init__(
            name="wallpaper-window",
            layer="overlay",
            anchor="top bottom left right",
            exclusivity="none",
            keyboard_mode="exclusive",
            visible=False,
            **kwargs
        )

        self.wallpaper_dir = os.path.expanduser("~/.config/wallpaper")
        self.script_path = os.path.expanduser("~/.config/scripts/wl.sh")

        self.grid = Gtk.Grid(name="wallpaper-grid")
        self.grid.set_column_spacing(20)
        self.grid.set_row_spacing(20)
        self.grid.set_halign(Gtk.Align.CENTER)
        self.grid.set_valign(Gtk.Align.CENTER)

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
        
        # VITAL: Pre-load the grid layout in the background right at boot!
        self.first_load = True
        threading.Thread(target=self.preload_wallpapers, daemon=True).start()

    def preload_wallpapers(self):
        """Reads files and creates image textures on a background thread to prevent UI freezing."""
        if not os.path.exists(self.wallpaper_dir):
            return

        valid_exts = (".png", ".jpg", ".jpeg", ".webp")
        files = [f for f in os.listdir(self.wallpaper_dir) if f.lower().endswith(valid_exts)]
        files = sorted(files)

        max_columns = 5
        ui_elements = []

        for index, file in enumerate(files):
            full_path = os.path.join(self.wallpaper_dir, file)
            try:
                # Scaled securely in the background thread
                pixbuf = GdkPixbuf.Pixbuf.new_from_file_at_scale(
                    full_path, width=260, height=150, preserve_aspect_ratio=False
                )
                ui_elements.append((index, file, pixbuf))
            except Exception as e:
                print(f"Skipping image {file}: {e}")

        # Push the finalized components back to GTK's main loop safely
        GLib.idle_add(self.populate_grid, ui_elements, max_columns)

    def populate_grid(self, items, max_columns):
        """Runs safely on the main thread to instantly mount the pre-loaded items."""
        for child in self.grid.get_children():
            self.grid.remove(child)

        for index, file, pixbuf in items:
            img_preview = Gtk.Image.new_from_pixbuf(pixbuf)
            img_preview.set_name("wallpaper-img")

            btn = Button(
                name="wallpaper-item-btn",
                child=img_preview,
                on_clicked=lambda *_, f=file: self.set_wallpaper(f)
            )

            row = index // max_columns
            col = index % max_columns
            self.grid.attach(btn, col, row, 1, 1)

        self.grid.show_all()
        self.first_load = False

    def set_wallpaper(self, filename):
        if os.path.exists(self.script_path):
            subprocess.Popen(
                ["bash", "-l", "-c", f"{self.script_path} '{filename}'"],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL
            )
        self.close_selector()

    def on_key_press(self, window, event):
        if event.keyval == Gdk.KEY_Escape:
            self.close_selector()
            return True
        return False

    def open_selector(self):
        self.show_all()
        # If it isn't our first run, reload changes quietly in the background 
        # so the picker remains instant when opened!
        if not self.first_load:
            threading.Thread(target=self.preload_wallpapers, daemon=True).start()

    def close_selector(self):
        self.hide()
