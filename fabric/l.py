import os
import subprocess
import shlex
import re
from gi.repository import Gdk, Gtk
from fabric import Application
from fabric.utils import get_desktop_applications
from fabric.widgets.box import Box
from fabric.widgets.entry import Entry
from fabric.widgets.button import Button
from fabric.widgets.label import Label
from fabric.widgets.scrolledwindow import ScrolledWindow
from fabric.widgets.wayland import WaylandWindow as Window

class AppLauncher(Window):
    def __init__(self, **kwargs):
        super().__init__(
            name="launcher-window",
            layer="overlay",
            anchor="center",
            exclusivity="none",
            keyboard_mode="exclusive", # Safely locks keyboard to the entry
            visible=False,
            **kwargs
        )

        # Main window sizing layout constraints
        self.set_size_request(450, 480)
        self.set_resizable(False)

        # INPUT FIELD
        self.search_entry = Entry(
            name="launcher-search",
            placeholder_text="Search applications...",
            on_changed=self.on_search_changed,
            on_activate=self.on_search_activated
        )
        self.search_entry.set_size_request(410, 45)

        # RESULTS TARGETS
        self.results_box = Box(
            orientation="v",
            spacing=4,
            name="launcher-results"
        )

        # SCROLLER
        self.scroller = ScrolledWindow(
            name="launcher-scroller",
            child=self.results_box
        )
        self.scroller.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
        self.scroller.set_size_request(410, 380) # Locked vertical space for scrolling

        # CORE BOX CONTAINER
        self.main_container = Box(
            orientation="v",
            spacing=10,
            name="launcher-container",
            children=[self.search_entry, self.scroller]
        )

        self.add(self.main_container)

        # Intercept Key Events globally for Escape handler action routing
        self.connect("key-press-event", self.on_key_press)
        self.apps = get_desktop_applications()
        self.filter_apps("")


    def filter_apps(self, query):
        # Clear existing buttons
        for child in self.results_box.get_children():
            self.results_box.remove(child)

        query = query.lower()

        for app in self.apps:
            # 1. Safely extract attributes and force them to empty strings if they are None
            app_name = getattr(app, "name", "") or ""
            app_generic = getattr(app, "generic_name", "") or ""

            # Lowercase them now that we are 100% sure they are strings
            app_name_lower = app_name.lower()
            app_generic_lower = app_generic.lower()

            if query in app_name_lower or query in app_generic_lower:
                # --- VITAL FLATPAK FIX ---
                # Retrieve the COMPLETE command line flags, not just the raw binary path
                cmd = getattr(app, "command_line", None) or getattr(app, "get_command_line", lambda: "")()
                if not cmd and hasattr(app, "executable"):
                    cmd = app.executable

                # Make sure we don't accidentally pass an empty executable launcher configuration
                if not cmd:
                    continue

                btn = Button(
                    name="launcher-item-btn",
                    style_classes="launcher-button-item",
                    on_clicked=lambda *_, c=cmd: self.launch_and_close(c)
                )

                btn_label = Label(
                    label=app_name if app_name else "Unknown Application",
                    name="launcher-btn-label"
                )
                btn.add(btn_label)
                btn.set_alignment(0, 0.5)
                self.results_box.add(btn)

        self.results_box.show_all()

    # def filter_apps(self, query: str):
    #     # Clear previous rows safely
    #     for child in self.results_box.get_children():
    #         child.destroy()

    #     query = query.lower()

    #     # FIXED: Reading proper Fabric DesktopApp attributes directly
    #     for app in get_desktop_applications():
    #         name = app.name or ""
    #         generic_name = app.generic_name or ""

    #         if query in name.lower() or query in generic_name.lower():
    #             cmd = app.executable

    #             btn = Button(
    #                 label=name,
    #                 name="launcher-item-btn",
    #                 on_clicked=lambda *_, c=cmd: self.launch_and_close(c)
    #             )
    #             btn.set_alignment(0, 0.5)
    #             self.results_box.add(btn)

    #     self.results_box.show_all()

    def on_search_changed(self, entry):
        self.filter_apps(entry.get_text())

    def on_search_activated(self, entry):
        children = self.results_box.get_children()
        if children:
            children[0].clicked()

    def launch_and_close(self, command):
        if command:
            import os
            import re
            # Extract the actual full command line if it's a Fabric object, else use the string
            cmd_str = getattr(command, "command_line", None) or getattr(command, "get_command_line", lambda: str(command))()
            clean_cmd = re.sub(r'%[fFuUicdk]', '', str(cmd_str)).strip()
            os.system(f"{clean_cmd} &")
        self.close_launcher()

    def on_key_press(self, window, event):
        # KEYBOARD INTERCEPT: Escape closes instantly, ignoring text entry traps
        if event.keyval == Gdk.KEY_Escape:
            self.close_launcher()
            return True
        return False

    def open_launcher(self):
        self.show_all()
        self.search_entry.set_text("")
        self.filter_apps("")
        self.search_entry.grab_focus()

    def close_launcher(self):
        self.hide()
