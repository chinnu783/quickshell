import gi
gi.require_version("Gtk", "3.0")
from gi.repository import Gtk
from fabric.widgets.box import Box
from fabric.widgets.label import Label
from fabric.widgets.wayland import WaylandWindow as Window
from fabric.utils import invoke_repeater
# Import Fabric's native audio stream listener
from fabric.audio.service import Audio

class OSDPopup(Window):
    def __init__(self, **kwargs):
        super().__init__(
            layer="overlay",
            anchor="bottom center",
            margin="0px 0px 100px 0px",
            exclusivity="none",
            visible=False,
            all_visible=False,
            **kwargs
        )

        self.timeout_id = None

        # OSD Container UI
        self.container = Box(
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

        self.container.add(self.label)
        self.container.add(self.progress_bar)
        self.add(self.container)
        self.show_all()
        self.set_visible(False)

        # Connect to Fabric's Audio Service
        self.audio_service = Audio()
        # Watch the speaker stream for changes (volume up/down/mute)
        self.audio_service.connect("speaker-changed", self.on_speaker_changed)

    def on_speaker_changed(self, audio_service, *args):
        """Triggered automatically whenever the system volume changes."""
        speaker = audio_service.speaker
        if not speaker:
            return

        # Get volume as a percentage integer (e.g., 50) and a float fraction (0.5)
        volume_pct = int(speaker.volume)
        volume_fraction = speaker.volume / 100

        if speaker.muted:
            text = "󰝟 Muted"
            volume_fraction = 0.0
        else:
            text = f"󰕾 Volume: {volume_pct}%"

        # Pass it to our display handler
        self.display(text, volume_fraction)

    def display(self, text: str, value: float, timeout_ms: int = 2000):
        self.label.set_label(text)
        self.progress_bar.set_fraction(max(0.0, min(1.0, value)))
        self.set_visible(True)

        if self.timeout_id:
            self.timeout_id.cancel()

        self.timeout_id = invoke_repeater(
            timeout_ms,
            self._hide_osd,
            initial_call=False
        )

    def _hide_osd(self):
        self.set_visible(False)
        if self.timeout_id:
            self.timeout_id.cancel()
            self.timeout_id = None
        return False
