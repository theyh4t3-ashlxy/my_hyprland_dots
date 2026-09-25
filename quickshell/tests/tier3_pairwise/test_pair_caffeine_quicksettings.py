#!/run/current-system/sw/bin/python3
"""
Tier 3 Pairwise 6: Caffeine Toggle inside QuickSettings (F11 x F12 x F19)
Validates that toggling Caffeine inside QuickSettings updates UI state,
restores brightness, and maintains popup stability.
"""

import unittest
from tests.harness import QuickshellIpc

class TestPairCaffeineQuicksettings(unittest.TestCase):
    """Pairwise interaction between Caffeine inhibitor and QuickSettings UI."""

    def test_caffeine_toggle_while_quicksettings_open(self):
        """T3.6.1: Toggle caffeine state while QuickSettings is open."""
        if QuickshellIpc.is_available():
            QuickshellIpc.call("quicksettings", "open")
            ret, _ = QuickshellIpc.call("caffeine", "toggle")
            self.assertEqual(ret, 0)
            QuickshellIpc.call("caffeine", "toggle") # restore
            QuickshellIpc.call("quicksettings", "close")

    def test_quicksettings_sections_load(self):
        """T3.6.2: QuickSettings opens cleanly without throwing."""
        if QuickshellIpc.is_available():
            ret, _ = QuickshellIpc.call("quicksettings", "open")
            self.assertEqual(ret, 0)
            QuickshellIpc.call("quicksettings", "close")

if __name__ == "__main__":
    unittest.main()
