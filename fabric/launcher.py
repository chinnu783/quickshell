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
from fabric.widgets.image import Image
from fabric.widgets.scrolledwindow import ScrolledWindow
from fabric.widgets.wayland import WaylandWindow as Window

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

        self.set_size_request(480, 520)
        self.set_default_size(480, 520)
        self.set_resizable(False)

        # 1. SEARCH BAR WITH ICON
        self.search_entry = Entry(
            name="launcher-search",
            placeholder_text="Search applications...",
            on_changed=self.on_search_changed,
            on_activate=self.on_search_activated
        )
        self.search_entry.set_icon_from_icon_name(Gtk.EntryIconPosition.PRIMARY, "system-search-symbolic")
        self.search_entry.set_size_request(440, 48)

        # 2. RESULTS CONTAINER
        self.results_box = Box(
            orientation="v",
            spacing=6,
            name="launcher-results"
        )

        # 3. SCROLLER
        self.scroller = ScrolledWindow(
            name="launcher-scroller",
            child=self.results_box
        )
        self.scroller.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
        self.scroller.set_max_content_height(420)
        self.scroller.set_propagate_natural_height(True)

        # 4. MAIN CONTAINER LAYOUT
        self.main_container = Box(
            orientation="v",
            spacing=12,
            name="launcher-container",
            children=[self.search_entry, self.scroller]
        )

        self.add(self.main_container)

        self.connect("key-press-event", self.on_key_press)
        self.apps = get_desktop_applications()
        self.filter_apps("")

    def filter_apps(self, query):
        for child in self.results_box.get_children():
            self.results_box.remove(child)

        query = query.lower().strip()

        for app in self.apps:
            app_name = getattr(app, "name", "") or ""
            app_generic = getattr(app, "generic_name", "") or ""
            app_icon = getattr(app, "icon_name", "application-x-executable") or "application-x-executable"

            app_name_lower = app_name.lower()
            app_generic_lower = app_generic.lower()

            if query in app_name_lower or query in app_generic_lower:
                cmd = getattr(app, "command_line", None) or getattr(app, "get_command_line", lambda: "")()
                if not cmd and hasattr(app, "executable"):
                    cmd = app.executable

                if not cmd:
                    continue

                # UI ITEM ROW
                item_box = Box(orientation="h", spacing=12, name="launcher-item-box")
                
                # Icon (32x32)
                icon_img = Image(icon_name=app_icon, icon_size=32, name="launcher-item-icon")
                item_box.add(icon_img)

                # Text Container (Name + Subtitle)
                text_box = Box(orientation="v", spacing=2, name="launcher-item-text")
                
                name_label = Label(
                    label=app_name if app_name else "Unknown Application",
                    name="launcher-item-title"
                )
                name_label.set_alignment(0, 0.5)
                text_box.add(name_label)

                if app_generic:
                    desc_label = Label(
                        label=app_generic,
                        name="launcher-item-subtitle"
                    )
                    desc_label.set_alignment(0, 0.5)
                    text_box.add(desc_label)

                item_box.add(text_box)

                # Button Wrapper
                btn = Button(
                    name="launcher-item-btn",
                    style_classes="launcher-button-item",
                    child=item_box,
                    on_clicked=lambda *_, c=cmd: self.launch_and_close(c)
                )
                
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
            cmd_str = getattr(command, "command_line", None) or getattr(command, "get_command_line", lambda: str(command))()
            clean_cmd = re.sub(r'%[fFuUicdk]', '', str(cmd_str)).strip()
            os.system(f"{clean_cmd} &")
        self.close_launcher()

    def on_key_press(self, window, event):
        # Escape to exit
        if event.keyval == Gdk.KEY_Escape:
            self.close_launcher()
            return True

        # Keyboard Navigation (Up / Down Arrow Keys)
        children = self.results_box.get_children()
        if children:
            focused = window.get_focus()
            
            if event.keyval == Gdk.KEY_Down:
                if focused not in children:
                    children[0].grab_focus()
                else:
                    idx = children.index(focused)
                    if idx < len(children) - 1:
                        children[idx + 1].grab_focus()
                return True

            elif event.keyval == Gdk.KEY_Up:
                if focused in children:
                    idx = children.index(focused)
                    if idx > 0:
                        children[idx - 1].grab_focus()
                    else:
                        self.search_entry.grab_focus()
                return True

        return False

    def open_launcher(self):
        self.show_all()
        self.search_entry.set_text("")
        self.filter_apps("")
        self.search_entry.grab_focus()

    def close_launcher(self):
        self.hide()
