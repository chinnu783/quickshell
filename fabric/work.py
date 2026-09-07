import json
import subprocess
from gi.repository import GLib
from fabric.widgets.box import Box
from fabric.widgets.button import Button

class NiriWorkspaces(Box):
    """
    A flawless workspace switcher for Niri that routes clicks using
    accurate sequential visual index counts rather than volatile backend object IDs.
    """
    def __init__(self, **kwargs):
        super().__init__(spacing=6, orientation="h", **kwargs)
        self.workspace_buttons = {}
        self.signal_connections = {}

        # Safe GLib loop executing every 250ms
        GLib.timeout_add(150, self.update_workspaces)

    def _on_workspace_clicked(self, button, visual_index):
        """
        Niri demands the local visual index position (e.g. 1, 2, 3...)
        to switch workspaces correctly on the active monitor screen output.
        """
        subprocess.Popen(["niri", "msg", "action", "focus-workspace", str(visual_index)])

    def update_workspaces(self) -> bool:
        try:
            # Query Niri for live workspace data states
            result = subprocess.run(
                ["niri", "msg", "-j", "workspaces"],
                capture_output=True,
                text=True,
                check=True
            )
            workspaces_raw = json.loads(result.stdout)

            # Sort workspaces strictly by their creation sequence to prevent scrambling
            workspaces_data = sorted(workspaces_raw, key=lambda x: x.get("id", 0))
            active_ids = set()

            for index, ws in enumerate(workspaces_data, start=1):
                ws_id = ws.get("id")
                display_name = ws.get("name") or str(index)
                is_focused = ws.get("is_focused", False)
                is_active = ws.get("is_active", False)

                active_ids.add(ws_id)

                # Format matching CSS class targets
                style_classes = "workspace-btn"
                if is_focused:
                    style_classes = "workspace-btn focused"
                elif is_active:
                    style_classes = "workspace-btn active"

                # 1. Retrieve or Create the Button Widget
                if ws_id not in self.workspace_buttons:
                    btn = Button(label=display_name, style_classes=style_classes)
                    self.add(btn)
                    self.workspace_buttons[ws_id] = btn
                else:
                    btn = self.workspace_buttons[ws_id]
                    btn.set_label(display_name)
                    btn.set_style_classes(style_classes)

                # 2. Clear old click handlers to refresh routing bounds
                if ws_id in self.signal_connections:
                    old_handler_id = self.signal_connections[ws_id]
                    if btn.handler_is_connected(old_handler_id):
                        btn.disconnect(old_handler_id)

                # 3. CRITICAL FIX: Bind the click event to the visual sequential 'index' position
                # instead of passing the erratic backend 'ws_id' handle block.
                new_handler_id = btn.connect("clicked", self._on_workspace_clicked, index)
                self.signal_connections[ws_id] = new_handler_id

                # Maintain strict visual layout sequencing inside the GTK Bar Box
                self.reorder_child(btn, index - 1)

            # Prune out dead workspaces seamlessly when closed by Niri
            for stored_id in list(self.workspace_buttons.keys()):
                if stored_id not in active_ids:
                    btn_to_remove = self.workspace_buttons.pop(stored_id)
                    self.signal_connections.pop(stored_id, None)
                    btn_to_remove.destroy()

        except (subprocess.CalledProcessError, json.JSONDecodeError, FileNotFoundError):
            pass

        return True
