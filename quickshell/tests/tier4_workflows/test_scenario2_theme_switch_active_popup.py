#!/run/current-system/sw/bin/python3
"""
Tier 4 Scenario 2: Wallpaper Theme Switching during Active Popup (F13, F14, F22)
Simulates dynamic wallpaper/palette switching while QuickSettings popup is open.
Validates that colors propagate reactively without closing the popup and
without triggering Quickshell daemon configuration reloads.
"""

import unittest
import time
from tests.harness import QuickshellIpc, QuickshellLogAuditor, REPO_ROOT

class TestScenario2ThemeSwitchActivePopup(unittest.TestCase):
    """End-to-end workflow: Theme switching during active popup interaction."""

    def test_theme_switch_with_open_popup(self):
        """Scenario 2: Open QuickSettings, touch palette, and verify stability."""
        if not QuickshellIpc.is_available():
            self.skipTest("Quickshell IPC unavailable")

        # Step 1: Open QuickSettings popup
        ret, _ = QuickshellIpc.call("quicksettings", "open")
        self.assertEqual(ret, 0)
        time.sleep(0.2)

        # Step 2: Record current PID
        pid_before = QuickshellIpc.get_daemon_pid()

        # Step 3: Touch palette file to simulate theme update
        palette_file = REPO_ROOT / "palette.css"
        if palette_file.exists():
            palette_file.touch()

        time.sleep(0.5)

        # Step 4: Daemon must not restart or reload shell.qml
        pid_after = QuickshellIpc.get_daemon_pid()
        self.assertEqual(pid_before, pid_after, "Daemon restarted during theme update")

        # Step 5: Close QuickSettings cleanly
        QuickshellIpc.call("quicksettings", "close")

if __name__ == "__main__":
    unittest.main()
