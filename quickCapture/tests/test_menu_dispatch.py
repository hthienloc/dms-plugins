"""Headless regression tests for both Quick Capture menu dispatch paths.

Requires Python 3 and Qt's qmltestrunner (including QtTest QML imports).
Extracts the production methods so the tests exercise their actual code,
without loading DMS or capturing the user's screen.
"""

import argparse
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile


def method(source, name):
    match = re.search(r"^    function " + name + r"\(.*?^    }", source, re.M | re.S)
    if not match:
        raise AssertionError(f"Missing production method: {name}")
    return match.group(0)


TEST = """import QtQuick
import QtTest

TestCase {
    id: testCase
    name: "MENU_NAME"

    Component {
        id: daemonComponent
        QtObject {
            id: root
            property int dispatchCount: 0
            property var lastArgs: []
            function capture(mode, action, output, fromCC) {
                lastArgs = [mode, action, output, fromCC];
                dispatchCount++;
            }
            function record(mode, geometry, fromCC) {
                lastArgs = [mode, geometry, fromCC];
                dispatchCount++;
            }
            DAEMON_METHODS
        }
    }
    Component {
        id: menuComponent
        QtObject {
            id: root
            property var daemon
            property var widget
            MENU_METHODS
        }
    }
    Component {
        id: widgetComponent
        QtObject {
            property var menu
            property bool closed: false
            function closePopout() {
                closed = true;
                menu.destroy();
            }
        }
    }
    function test_capture_data() {
        const rows = [];
        for (const mode of ["region", "full", "all", "window", "output", "last", "clipboard", "selectFile", "scroll"])
            for (const action of ["copy", "edit", "float"])
                rows.push({tag: mode + ":" + action, mode: mode, action: action});
        return rows;
    }
    function test_capture(data) {
        const daemon = daemonComponent.createObject(testCase);
        const widget = widgetComponent.createObject(testCase);
        const menu = menuComponent.createObject(testCase, {daemon: daemon, widget: widget});
        widget.menu = menu;
        menu.run(data.mode, data.action, "eDP-1");
        compare(widget.closed, true);
        tryCompare(daemon, "dispatchCount", 1);
        compare(daemon.lastArgs, [data.mode, data.action, "eDP-1", false]);
        widget.destroy();
        daemon.destroy();
    }
    function test_record_data() {
        return ["screen", "region", "portal"].map(mode => ({tag: mode, mode: mode}));
    }
    function test_record(data) {
        const daemon = daemonComponent.createObject(testCase);
        const widget = widgetComponent.createObject(testCase);
        const menu = menuComponent.createObject(testCase, {daemon: daemon, widget: widget});
        widget.menu = menu;
        menu.runRecording(data.mode);
        compare(widget.closed, true);
        tryCompare(daemon, "dispatchCount", 1);
        compare(daemon.lastArgs, [data.mode, "", false]);
        widget.destroy();
        daemon.destroy();
    }
    function test_missing_daemon() {
        const widget = widgetComponent.createObject(testCase);
        const menu = menuComponent.createObject(testCase, {daemon: null, widget: widget});
        widget.menu = menu;
        menu.run("region", "copy", "");
        menu.runRecording("region");
        compare(widget.closed, false);
        menu.destroy();
        widget.destroy();
    }
}
"""


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--qmltestrunner", default=shutil.which("qmltestrunner"))
    args = parser.parse_args()
    if not args.qmltestrunner:
        parser.error("qmltestrunner is not on PATH; supply --qmltestrunner")

    plugin = Path(__file__).resolve().parents[1]
    daemon = (plugin / "QuickCaptureDaemon.qml").read_text()
    daemon_methods = "\n".join(method(daemon, name) for name in ("captureFromMenu", "recordFromMenu"))
    with tempfile.TemporaryDirectory(prefix="quickcapture-menu-tests-") as directory:
        for name in ("CaptureLauncherModal", "CaptureMenu"):
            source = (plugin / "components" / "bar" / f"{name}.qml").read_text()
            assert "onTriggered: root.runRecording(modelData.value)" in source, name
            menu_methods = "\n".join(method(source, item) for item in ("run", "runRecording"))
            qml = TEST.replace("MENU_NAME", name)
            qml = qml.replace("DAEMON_METHODS", daemon_methods).replace("MENU_METHODS", menu_methods)
            Path(directory, f"tst_{name}.qml").write_text(qml)
        env = dict(os.environ)
        env["QT_QPA_PLATFORM"] = "offscreen"
        env["QT_QUICK_BACKEND"] = "software"
        return subprocess.run([args.qmltestrunner, "-input", directory], env=env).returncode


if __name__ == "__main__":
    raise SystemExit(main())
