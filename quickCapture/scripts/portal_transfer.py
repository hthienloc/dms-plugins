#!/usr/bin/env python3
"""Register a local file with org.freedesktop.portal.FileTransfer for sandboxed DnD."""

import os
import signal
import sys

import gi

gi.require_version("Gio", "2.0")
gi.require_version("GLib", "2.0")
from gi.repository import Gio, GLib

BUS_NAME = "org.freedesktop.portal.Documents"
OBJECT_PATH = "/org/freedesktop/portal/documents"
IFACE = "org.freedesktop.portal.FileTransfer"
TIMEOUT_MS = 2000
KEEPALIVE_SECONDS = 60


def main() -> int:
    if len(sys.argv) < 2 or not sys.argv[1]:
        return 0

    path = os.path.abspath(sys.argv[1])
    prev_key = sys.argv[2] if len(sys.argv) > 2 else ""

    if not os.path.isfile(path):
        return 0

    try:
        bus = Gio.bus_get_sync(Gio.BusType.SESSION, None)
        if prev_key:
            try:
                bus.call_sync(
                    BUS_NAME,
                    OBJECT_PATH,
                    IFACE,
                    "StopTransfer",
                    GLib.Variant("(s)", (prev_key,)),
                    None,
                    Gio.DBusCallFlags.NONE,
                    TIMEOUT_MS,
                    None,
                )
            except Exception:
                pass

        res = bus.call_sync(
            BUS_NAME,
            OBJECT_PATH,
            IFACE,
            "StartTransfer",
            GLib.Variant(
                "(a{sv})",
                ({"writable": GLib.Variant("b", False), "autostop": GLib.Variant("b", False)},),
            ),
            GLib.VariantType("(s)"),
            Gio.DBusCallFlags.NONE,
            TIMEOUT_MS,
            None,
        )
        key = res.unpack()[0]
        if not key:
            return 0

        fd = os.open(path, os.O_RDONLY | os.O_CLOEXEC)
        try:
            fd_list = Gio.UnixFDList()
            fd_idx = fd_list.append(fd)
        finally:
            os.close(fd)

        bus.call_with_unix_fd_list_sync(
            BUS_NAME,
            OBJECT_PATH,
            IFACE,
            "AddFiles",
            GLib.Variant("(saha{sv})", (key, [fd_idx], {})),
            None,
            Gio.DBusCallFlags.NONE,
            TIMEOUT_MS,
            fd_list,
            None,
        )

        # Keep the D-Bus connection alive until the transfer completes or times out,
        # because xdg-desktop-portal revokes the key when the sender disconnects.
        loop = GLib.MainLoop()

        def on_signal(*_args):
            loop.quit()

        signal.signal(signal.SIGTERM, on_signal)
        signal.signal(signal.SIGINT, on_signal)

        def on_transfer_closed(_conn, _sender, _obj_path, _iface, _sig, params):
            try:
                if params.unpack()[0] == key:
                    loop.quit()
            except Exception:
                pass

        sub_id = bus.signal_subscribe(
            BUS_NAME,
            IFACE,
            "TransferClosed",
            OBJECT_PATH,
            None,
            Gio.DBusSignalFlags.NONE,
            on_transfer_closed,
        )
        GLib.timeout_add_seconds(KEEPALIVE_SECONDS, loop.quit)

        sys.stdout.write(key + "\n")
        sys.stdout.flush()

        loop.run()
        bus.signal_unsubscribe(sub_id)
    except Exception as exc:
        sys.stderr.write(f"portal_transfer: {exc}\n")
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
