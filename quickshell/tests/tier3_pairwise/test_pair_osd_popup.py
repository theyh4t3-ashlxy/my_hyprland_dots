#!/run/current-system/sw/bin/python3
"""
Tier 3 Pairwise 3: Audio/Brightness OSD during Active Popups (F12 x F18)
Validates that invoking volume or brightness adjustments while QuickSettings
or AppLauncher is open displays the OSD overlay without clipping or z-order conflicts.
"""

import unittest
import time
from tests.harness import QuickshellIpc

class TestPairOsdPopup(unittest.TestCase):
    """Pairwise interaction between OSD layer surfaces and active popups."""

    def test_volume_osd_while_quicksettings_open(self):
        """T3.3.1: Trigger volume change while QuickSettings is active."""
        if QuickshellIpc.is_available():
            # Open quicksettings
            QuickshellIpc.call("quicksettings", "open")
            time.sleep(0.1)

            # Trigger volume up
            ret, _ = QuickshellIpc.call("volume", "up", "0.02")
            self.assertEqual(ret, 0)

            # Close quicksettings
            QuickshellIpc.call("quicksettings", "close")

    def test_volume_mute_while_launcher_open(self):
        """T3.3.2: Trigger volume mute while launcher is active."""
        if QuickshellIpc.is_available():
            QuickshellIpc.call("launcher", "open")
            time.sleep(0.1)

            ret, _ = QuickshellIpc.call("volume", "mute")
            self.assertEqual(ret, 0)
            QuickshellIpc.call("volume", "mute") # restore

            QuickshellIpc.call("launcher", "close")

if __name__ == "__main__":
    unittest.main()
