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
            anchor="top right",
            margin="20px 20px 0px 0px",
            exclusivity="none",
            visible=False,
            all_visible=False,
            name="osd-window", # <-- Allows styling the window directly in CSS
            **kwargs
        )

        self.timeout_id = None

        # Removed hardcoded colors. Now entirely customizable via CSS!
        self.osd_box = Box(
            orientation="v",
            spacing=8,
            name="osd-container", # #osd-container target for CSS
        )

        self.label = Label(
            label="Feedback",
            name="osd-label",     # #osd-label target for CSS
        )

        self.progress_bar = Gtk.ProgressBar(
            name="osd-progress"   # #osd-progress target for CSS
        )
        self.progress_bar.set_size_request(200, 8)

        self.osd_box.add(self.label)
        self.osd_box.add(self.progress_bar)
        self.add(self.osd_box)
        self.osd_box.show_all()

        # --- AUDIO TRACKING CONFIG ---
        self.audio_fabricator = Fabricator(interval=200, poll_from=self.get_system_volume)
        self.audio_fabricator.connect("changed", self.on_volume_changed)
        self._last_volume = -1
        self._last_mute = False

        # --- BRIGHTNESS TRACKING CONFIG ---
        self.brightness_fabricator = Fabricator(interval=200, poll_from=self.get_system_brightness)
        self.brightness_fabricator.connect("changed", self.on_brightness_changed)
        self._last_brightness = -1

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

    def get_system_brightness(self, *args):
        try:
            output = subprocess.check_output(["brightnessctl", "m"], text=True).strip()
            max_b = float(output)
            curr_b = float(subprocess.check_output(["brightnessctl", "g"], text=True).strip())
            return curr_b / max_b
        except Exception:
            return -1.0

    def on_brightness_changed(self, fabricator, bri_val: float):
        if bri_val < 0.0:
            return
        if bri_val != self._last_brightness:
            if self._last_brightness != -1:
                self.display(f"󰃠 Brightness: {int(bri_val * 100)}%", bri_val)
            self._last_brightness = bri_val

    def display(self, text: str, value: float, timeout_ms: int = 2000):
        self.label.set_label(text)
        self.progress_bar.set_fraction(max(0.0, min(1.0, value)))

        self.set_visible(True)
        self.show()

        if self.timeout_id is not None:
            from fabric.utils import remove_handler
            remove_handler(self.timeout_id)
            self.timeout_id = None

        self.timeout_id = invoke_repeater(
            timeout_ms,
            self._hide_osd,
            initial_call=False
        )

    def _hide_osd(self):
        self.set_visible(False)
        self.hide()
        if self.timeout_id is not None:
            from fabric.utils import remove_handler
            remove_handler(self.timeout_id)
            self.timeout_id = None
        return False
