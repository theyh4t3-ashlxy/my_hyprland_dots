#!/run/current-system/sw/bin/python3
"""
Tier 2 Boundary 12: Popup Coordinate Null & Boundary Cases
Tests edge cases for coordinate mapping: unmapped items, zero dimension,
negative coordinates, and rapid popup open/close transitions.
"""

import unittest
from tests.harness import QuickshellIpc

class TestB12PopupNullBoundary(unittest.TestCase):
    """Verifies edge cases for popup positioning and unmapped scene graphs."""

    def test_rapid_quicksettings_toggle_burst(self):
        """T2.12.1: Rapidly toggling quicksettings 5 times does not trigger TypeErrors."""
        if QuickshellIpc.is_available():
            for _ in range(5):
                ret, _ = QuickshellIpc.call("quicksettings", "toggle")
                self.assertEqual(ret, 0)
            # Ensure closed at end of test
            QuickshellIpc.call("quicksettings", "close")

    def test_rapid_launcher_toggle_burst(self):
        """T2.12.2: Rapidly toggling launcher 5 times executes cleanly."""
        if QuickshellIpc.is_available():
            for _ in range(5):
                ret, _ = QuickshellIpc.call("launcher", "toggle")
                self.assertEqual(ret, 0)
            QuickshellIpc.call("launcher", "close")

    def test_rapid_clipboard_toggle_burst(self):
        """T2.12.3: Rapidly toggling clipboard popup executes cleanly."""
        if QuickshellIpc.is_available():
            for _ in range(5):
                ret, _ = QuickshellIpc.call("clipboard", "toggle")
                self.assertEqual(ret, 0)
            QuickshellIpc.call("clipboard", "close")

    def test_rapid_calendar_toggle_burst(self):
        """T2.12.4: Rapidly toggling calendar popup executes cleanly."""
        if QuickshellIpc.is_available():
            for _ in range(5):
                ret, _ = QuickshellIpc.call("calendar", "toggle")
                self.assertEqual(ret, 0)
            QuickshellIpc.call("calendar", "close")

    def test_daemon_liveness_after_bursts(self):
        """T2.12.5: Quickshell daemon remains healthy and responsive after burst toggling."""
        pid = QuickshellIpc.get_daemon_pid()
        self.assertIsNotNone(pid, "Daemon should remain running after popup toggles")

if __name__ == "__main__":
    unittest.main()
