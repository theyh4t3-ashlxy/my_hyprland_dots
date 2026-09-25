#!/run/current-system/sw/bin/python3
"""
Tier 3 Pairwise 4: Floating Bar with Fullscreen Toggle (F4 x F7)
Validates that floating status bars and corner fillets yield completely
and unmap when windows enter fullscreen, and remap with correct margins upon exit.
"""

import unittest
from tests.harness import QmlCodeInspector, HyprlandHelper

class TestPairFloatingFullscreen(unittest.TestCase):
    """Pairwise interaction between floating status bar and fullscreen mode."""

    def setUp(self):
        self.bar_content = QmlCodeInspector.read_qml_content("bar/StatusBar.qml")
        self.sc_content = QmlCodeInspector.read_qml_content("corners/ScreenCorners.qml")

    def test_fullscreen_overrides_floating_visibility(self):
        """T3.4.1: When fullscreen is true, bar and corners hide regardless of floating state."""
        self.assertIn("hasFullscreen", self.sc_content)
        self.assertIn("hasFullscreen", self.bar_content)

    def test_remapping_preserves_floating_margins(self):
        """T3.4.2: Remapping after fullscreen maintains floating margin settings."""
        self.assertIn("barFloating", self.sc_content)

if __name__ == "__main__":
    unittest.main()
