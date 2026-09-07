from typing import cast
from gi.repository import GdkPixbuf
from fabric.widgets.box import Box
from fabric.widgets.label import Label
from fabric.widgets.image import Image
from fabric.widgets.button import Button
from fabric.widgets.wayland import WaylandWindow as Window
from fabric.notifications import Notifications, Notification
from fabric.utils import invoke_repeater
from fabric.widgets.scrolledwindow import ScrolledWindow
from gi.repository import Gtk


NOTIFICATION_WIDTH = 360
NOTIFICATION_IMAGE_SIZE = 64
NOTIFICATION_TIMEOUT = 10 * 1000 # 10 seconds

class NotificationWidget(Box):
    def __init__(self, notification: Notification, **kwargs):
        super().__init__(
            size=(NOTIFICATION_WIDTH, -1),
            name="notification",
            spacing=8,
            orientation="v",
            **kwargs,
        )
        self._notification = notification
        body_container = Box(spacing=4, orientation="h")
        
        if image_pixbuf := self._notification.image_pixbuf:
            body_container.add(
                Image(
                    pixbuf=image_pixbuf.scale_simple(
                        NOTIFICATION_IMAGE_SIZE,
                        NOTIFICATION_IMAGE_SIZE,
                        GdkPixbuf.InterpType.BILINEAR,
                    )
                )
            )

        body_container.add(
            Box(
                spacing=4,
                orientation="v",
                children=[
                    Box(
                        orientation="h",
                        children=[
                            Label(
                                label=self._notification.summary,
                                ellipsization="middle",
                            )
                            .build()
                            .add_style_class("summary")
                            .unwrap(),
                        ],
                        h_expand=True,
                        v_expand=True,
                    ).build(
                        lambda box, _: box.pack_end(
                            Button(
                                image=Image(
                                    icon_name="close-symbolic",
                                    icon_size=18,
                                ),
                                v_align="center",
                                h_align="end",
                                on_clicked=lambda *_: self._notification.close(),
                            ),
                            False,
                            False,
                            0,
                        )
                    ),
                    Label(
                        label=self._notification.body,
                        line_wrap="word-char",
                        v_align="start",
                        h_align="start",
                    )
                    .build()
                    .add_style_class("body")
                    .unwrap(),
                ],
                h_expand=True,
                v_expand=True,
            )
        )
        self.add(body_container)

        if actions := self._notification.actions:
            self.add(
                Box(
                    spacing=4,
                    orientation="h",
                    children=[
                        Button(
                            h_expand=True,
                            v_expand=True,
                            label=action.label,
                            on_clicked=lambda *_, action=action: action.invoke(),
                        )
                        for action in actions
                    ],
                )
            )

        self._notification.connect(
            "closed",
            lambda *_: (
                parent.remove(self) if (parent := self.get_parent()) else None,
                self.destroy(),
            ),
        )

        invoke_repeater(
            NOTIFICATION_TIMEOUT,
            lambda: self._notification.close("expired"),
            initial_call=False,
        )


class NotificationPopup(Window):
    def __init__(self, **kwargs):
        super().__init__(
            layer="top",
            anchor="top right",
            margin="8px 8px 8px 8px",
            exclusivity="none", # Notification overlays shouldn't push windows around
            visible=True,
            all_visible=True,
            **kwargs
        )
        
        self.viewport = Box(
            size=2,  # Prevent compositor from ignoring layout size dimensions
            spacing=4,
            orientation="v",
        )
        
        # Connect the viewport to the Fabric Notifications service
        self.viewport.build(
            lambda viewport, _: Notifications(
                on_notification_added=lambda notifs_service, nid: viewport.add(
                    NotificationWidget(
                        cast(
                            Notification,
                            notifs_service.get_notification_from_id(nid),
                        )
                    )
                )
            )
        )
        
        self.add(self.viewport)

class NotificationCenter(Window):
    def __init__(self, **kwargs):
        super().__init__(
            name="notification-center-window",
            layer="overlay",
            anchor="top right bottom", # Fills the full vertical right side
            margin="0px 0px 0px 0px",
            exclusivity="none",
            keyboard_mode="exclusive",
            visible=False,
            **kwargs
        )

        self.set_size_request(400, -1) # SwayNC standard sidebar width

        # Header layout elements
        self.header_label = Label(label="Notification Center", name="center-header-title")
        self.clear_button = Button(
            label="Clear All",
            name="center-clear-btn",
            on_clicked=lambda *_: self.clear_all_notifications()
        )

        self.header_box = Box(
            orientation="h",
            name="center-header",
            children=[self.header_label, self.clear_button]
        )
        self.header_box.set_center_widget(self.header_label) # Center title perfectly

        # History layout lists
        self.history_box = Box(
            orientation="v",
            spacing=8,
            name="center-history-box"
        )

        # Scroll area container assignment
        self.scroller = ScrolledWindow(name="center-scroller", child=self.history_box)
        self.scroller.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
        self.scroller.set_v_expand(True)

        # Base layout container stack
        self.main_container = Box(
            orientation="v",
            spacing=12,
            name="center-container",
            children=[self.header_box, self.scroller]
        )

        self.add(self.main_container)
        self.connect("key-press-event", self.on_key_press)

        # Connect to Fabric core notifications engine instance
        self.notifs_service = Notifications()
        self.notifs_service.connect("notification-added", self.on_notification_received)

    def on_notification_received(self, service, nid):
        notification = cast(Notification, service.get_notification_from_id(nid))

        # Build persistent item card wrapper context
        widget = NotificationWidget(notification)

        # Disable the automatic timeout loop counter for persistent history
        widget.name = "center-notification-card"

        # Insert new notifications dynamically right at the top of the history list
        self.history_box.pack_start(widget, False, False, 0)
        self.history_box.show_all()

    def clear_all_notifications(self):
        # Destroys all tracked active widget cards safely
        for child in self.history_box.get_children():
            child.destroy()

    def on_key_press(self, window, event):
        if event.keyval == Gdk.KEY_Escape:
            self.close_center()
            return True
        return False

    def open_center(self):
        self.show_all()

    def close_center(self):
        self.hide()
