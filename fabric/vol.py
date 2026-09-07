import gi
gi.require_version("Gtk", "3.0")
from gi.repository import Gtk
from fabric import Fabricator
from fabric.widgets.box import Box
from fabric.widgets.label import Label
from fabric.widgets.wayland import WaylandWindow as Window
from fabric.utils import invoke_repeater
import subprocess

class OSDPopup(Window):
    def __init__(self, **kwargs):
        super().__init__(
            layer="overlay",
            anchor="bottom center",
            margin="0px 0px 100px 0px",
            exclusivity="none",
            visible=False,      # Keep hidden on startup
            all_visible=False,  # Keep hidden on startup
            **kwargs
        )

        self.timeout_id = None

        # FIX: Renamed 'container' to 'osd_box' to avoid Gtk internal conflicts
        self.osd_box = Box(
            orientation="v",
            spacing=8,
            name="osd-container",
            style="background-color: rgba(30, 30, 46, 0.9); padding: 12px; border-radius: 12px;"
        )

        self.label = Label(
            label="Volume",
            style="color: #cdd6f4; font-size: 14px; font-weight: bold;"
        )

        self.progress_bar = Gtk.ProgressBar()
        self.progress_bar.set_size_request(200, 8)

        self.osd_box.add(self.label)
        self.osd_box.add(self.progress_bar)
        self.add(self.osd_box)

        # Initialize but don't force show the window yet
        self.osd_box.show_all()

        self.audio_fabricator = Fabricator(
            interval=200,
            poll_from=self.get_system_volume
        )
        self.audio_fabricator.connect("changed", self.on_volume_changed)
        self._last_volume = -1
        self._last_mute = False

    def get_system_volume(self, *args):
        try:
            output = subprocess.check_output(["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"], text=True)
            return output.strip()
        except Exception:
            return ""

    def on_volume_changed(self, fabricator, value_str: str):
        if not value_str:
            return

        is_muted = "[MUTED]" in value_str
        try:
            vol_float = float(value_str.split()[1])
        except (IndexError, ValueError):
            return

        if vol_float != self._last_volume or is_muted != self._last_mute:
            if self._last_volume != -1:
                if is_muted:
                    self.display("󰝟 Muted", 0.0)
                else:
                    self.display(f"󰕾 Volume: {int(vol_float * 100)}%", vol_float)

            self._last_volume = vol_float
            self._last_mute = is_muted

    def display(self, text: str, value: float, timeout_ms: int = 2000):
        self.label.set_label(text)
        self.progress_bar.set_fraction(max(0.0, min(1.0, value)))

        # Reveal the window
        self.set_visible(True)
        self.show()

        # FIX: Correctly clear the old timeout handler if it exists
        if self.timeout_id is not None:
            from fabric.utils import remove_handler
            remove_handler(self.timeout_id)
            self.timeout_id = None

        # Register a new single-shot timer to dismiss the window
        self.timeout_id = invoke_repeater(
            timeout_ms,
            self._hide_osd,
            initial_call=False
        )

    def _hide_osd(self):
        self.set_visible(False)
        self.hide()

        # FIX: Clean up the reference tracking variable safely
        if self.timeout_id is not None:
            from fabric.utils import remove_handler
            remove_handler(self.timeout_id)
            self.timeout_id = None

        return False # Returning False stops invoke_repeater from looping again
