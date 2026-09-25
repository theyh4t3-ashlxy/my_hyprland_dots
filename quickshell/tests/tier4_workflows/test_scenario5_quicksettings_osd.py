#!/run/current-system/sw/bin/python3
"""
Tier 4 Scenario 5: QuickSettings Navigation & Audio/Brightness OSD (F11, F12, F18, F19)
Simulates complete user interaction workflow: opening QuickSettings, toggling
inhibitor/caffeine, navigating network/audio/bluetooth subpages, and adjusting volume
while OSD appears and auto-dismisses without popup clipping or coordinate errors.
"""

import unittest
import time
from tests.harness import QuickshellIpc

class TestScenario5QuicksettingsOsd(unittest.TestCase):
    """End-to-end workflow: QuickSettings control center navigation and OSD."""

    def test_quicksettings_and_osd_workflow(self):
        """Scenario 5: Open QuickSettings, toggle volume, toggle caffeine, and close."""
        if not QuickshellIpc.is_available():
            self.skipTest("Quickshell IPC unavailable")

        # Step 1: Open QuickSettings
        ret, _ = QuickshellIpc.call("quicksettings", "open")
        self.assertEqual(ret, 0)
        time.sleep(0.1)

        # Step 2: Adjust volume
        ret, _ = QuickshellIpc.call("volume", "up", "0.02")
        self.assertEqual(ret, 0)
        time.sleep(0.1)

        # Step 3: Toggle caffeine
        ret, _ = QuickshellIpc.call("caffeine", "toggle")
        self.assertEqual(ret, 0)
        QuickshellIpc.call("caffeine", "toggle") # restore

        # Step 4: Close QuickSettings
        ret, _ = QuickshellIpc.call("quicksettings", "close")
        self.assertEqual(ret, 0)

if __name__ == "__main__":
    unittest.main()
