import os
import re
import shlex
import subprocess
from gi.repository import Gdk, Gtk
from fabric.widgets.window import Window
from fabric.widgets.box import Box
from fabric.widgets.entry import Entry
from fabric.widgets.button import Button
from fabric.widgets.label import Label
from fabric.utils import get_desktop_applications

class AppLauncher(Window):
    def __init__(self, **kwargs):
        super().__init__(
            name="launcher-window",
            layer="overlay",
            anchor="center",
            exclusivity="none",
            keyboard_mode="exclusive",
            visible=False,
            **kwargs
        )
        
        # Main Layout Container
        self.main_box = Box(
            orientation="v",
            spacing=10,
            name="launcher-main-box"
        )
        
        # Search Entry
        self.search_entry = Entry(
            name="launcher-search-entry",
            placeholder="Search applications...",
            on_changed=self.on_search_changed,
            on_activate=self.on_search_activated
        )
        
        # Scrollable Results Window
        self.scrolled_window = Gtk.ScrolledWindow(name="launcher-scroll")
        self.scrolled_window.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
        self.scrolled_window.set_min_content_height(400)
        self.scrolled_window.set_min_content_width(350)
        
        # Results Box
        self.results_box = Box(
            orientation="v",
            spacing=6,
            name="launcher-results-box"
        )
        
        self.scrolled_window.add(self.results_box)
        self.main_box.add(self.search_entry)
        self.main_box.add(self.scrolled_window)
        self.add(self.main_box)
        
        # Intercept Escape to close
        self.connect("key-press-event", self.on_key_press)
        
        # Initial App Query Cache
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

    def on_search_changed(self, entry):
        self.filter_apps(entry.get_text())

    def on_search_activated(self, entry):
        children = self.results_box.get_children()
        if children:
            children[0].clicked()

    def launch_and_close(self, command):
        if command:
            # 1. Clean out the GTK url/file placeholders (%u, %U, %f, %F, etc.)
            clean_cmd = re.sub(r'%[fFuUicdk]', '', str(command)).strip()
            print(f"[Launcher] Resolved execution command line: '{clean_cmd}'")
            
            try:
                # 2. Use os.system with background shell fork '&'
                # This detaches it fully and handles any complex nested Flatpak paths beautifully.
                os.system(f"{clean_cmd} &")
                print("[Launcher] Process successfully handed off to system shell.")
            except Exception as e:
                print(f"[Launcher Error] Failed to execute run sequence: {e}")
                
        self.close_launcher()

    def on_key_press(self, window, event):
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
