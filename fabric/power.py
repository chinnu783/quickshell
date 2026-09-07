import os
import subprocess
from gi.repository import Gdk
from fabric.widgets.box import Box
from fabric.widgets.button import Button
from fabric.widgets.wayland import WaylandWindow as Window

class PowerMenu(Window):
    def __init__(self, **kwargs):
        super().__init__(
            name="powermenu-window",
            layer="overlay",
            anchor="center",
            exclusivity="none",
            keyboard_mode="exclusive",
            visible=False,
            **kwargs
        )

        # Action layout setup
        self.actions = {
            "Lock": "loginctl lock-session",
            "Exit": "niri msg action quit",
            "Suspend": "loginctl suspend",
            "Reboot": "loginctl reboot",
            "Power Off": "loginctl poweroff"
        }

        self.main_container = Box(
            orientation="h",
            spacing=15,
            name="powermenu-container"
        )

        for name, cmd in self.actions.items():
            btn = Button(
                label=name,
                name=f"powermenu-btn-{name.lower().replace(' ', '')}",
                on_clicked=lambda *_, c=cmd: self.execute_action(c)
            )
            btn.set_size_request(90, 90)
            self.main_container.add(btn)

        self.add(self.main_container)
        self.connect("key-press-event", self.on_key_press)

    def execute_action(self, cmd):
        subprocess.Popen(cmd.split(), stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        self.close_menu()

    def on_key_press(self, window, event):
        if event.keyval == Gdk.KEY_Escape:
            self.close_menu()
            return True
        return False

    def open_menu(self):
        self.show_all()

    def close_menu(self):
        self.hide()
