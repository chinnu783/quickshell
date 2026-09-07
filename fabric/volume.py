import subprocess
from fabric.widgets.box import Box
from fabric.widgets.label import Label
from fabric.widgets.scale import Scale
from fabric.utils import invoke_repeater

# --- PANEL SLIDERS (For the Notification Center) ---

class PanelVolumeSlider(Box):
    def __init__(self, **kwargs):
        super().__init__(orientation="h", spacing=8, name="panel-slider-container",style_classes="slider-pill-row", **kwargs)
        self.icon = Label(label="󰕾", name="panel-slider-icon")
        self.slider = Scale(orientation="h", min_value=0, max_value=100, value=0, name="volume-slider-bar")
        self.slider.set_size_request(200, -1)
        self.handler_id = self.slider.connect("value-changed", self.on_move)

        self.add(self.icon)
        self.add(self.slider)
        self.update_state()
        invoke_repeater(1000, self.update_state)

    def update_state(self):
        if self.slider.is_hovered(): return True
        try:
            out = subprocess.check_output(["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"], text=True)
            vol = int(float(out.strip().split()[1]) * 100)
            self.slider.handler_block(self.handler_id)
            self.slider.set_value(vol)
            self.icon.set_label("󰝟" if "[MUTED]" in out else "󰕾")
            self.slider.handler_unblock(self.handler_id)
        except Exception: pass
        return True

    def on_move(self, scale):
        val = int(scale.get_value())
        subprocess.Popen(["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", f"{val}%"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


class PanelBrightnessSlider(Box):
    def __init__(self, **kwargs):
        super().__init__(orientation="h", spacing=8, name="panel-slider-container", style_classes="slider-pill-row", **kwargs)
        self.icon = Label(label="󰛨", name="panel-slider-icon")
        self.slider = Scale(orientation="h", min_value=5, max_value=100, value=10, name="brightness-slider-bar")
        self.slider.set_size_request(200, -1)
        self.handler_id = self.slider.connect("value-changed", self.on_move)

        self.add(self.icon)
        self.add(self.slider)
        self.update_state()
        invoke_repeater(1000, self.update_state)

    def update_state(self):
        if self.slider.is_hovered(): return True
        try:
            cur = float(subprocess.check_output(["brightnessctl", "g"], text=True).strip())
            max_b = float(subprocess.check_output(["brightnessctl", "m"], text=True).strip())
            pct = int((cur / max_b) * 100)
            self.slider.handler_block(self.handler_id)
            self.slider.set_value(pct)
            self.slider.handler_unblock(self.handler_id)
        except Exception: pass
        return True

    def on_move(self, scale):
        val = int(scale.get_value())
        subprocess.Popen(["brightnessctl", "s", f"{val}%"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
