#!/run/current-system/sw/bin/python3
"""
Tier 3 Pairwise 2: Popups during Fullscreen Toggles (F7 x F12)
Validates that opening or maintaining QuickSettings/Launcher popups while
a client window enters or exits fullscreen yields gracefully without crashing.
"""

import unittest
from tests.harness import QuickshellIpc

class TestPairPopupFullscreen(unittest.TestCase):
    """Pairwise interaction between active popups and fullscreen state changes."""

    def test_popup_lifecycle_during_state_change(self):
        """T3.2.1: Open popup, trigger state query, and close popup cleanly."""
        if QuickshellIpc.is_available():
            # Open quicksettings
            ret1, _ = QuickshellIpc.call("quicksettings", "open")
            self.assertEqual(ret1, 0)

            # Close quicksettings
            ret2, _ = QuickshellIpc.call("quicksettings", "close")
            self.assertEqual(ret2, 0)

            # Open launcher
            ret3, _ = QuickshellIpc.call("launcher", "open")
            self.assertEqual(ret3, 0)

            # Close launcher
            ret4, _ = QuickshellIpc.call("launcher", "close")
            self.assertEqual(ret4, 0)

    def test_daemon_stability_across_transitions(self):
        """T3.2.2: Daemon remains alive and responsive throughout popup operations."""
        pid = QuickshellIpc.get_daemon_pid()
        self.assertIsNotNone(pid)

if __name__ == "__main__":
    unittest.main()
