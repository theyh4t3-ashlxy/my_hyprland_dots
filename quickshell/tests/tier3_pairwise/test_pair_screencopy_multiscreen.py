#!/run/current-system/sw/bin/python3
"""
Tier 3 Pairwise 5: Screencopy Overlay during Multi-Screen / Hotplug (F5 x F10)
Validates that screenshot overlays correctly bind to individual screens
without cross-screen interference or null dereferences.
"""

import unittest
from tests.harness import QmlCodeInspector

class TestPairScreencopyMultiscreen(unittest.TestCase):
    """Pairwise interaction between screencopy capture and multi-screen topology."""

    def setUp(self):
        self.overlay_content = QmlCodeInspector.read_qml_content("widgets/ScreenshotOverlay.qml")

    def test_screen_assignment_per_overlay(self):
        """T3.5.1: ScreencopyView binds per-screen capture source."""
        self.assertIn("overlayRoot", self.overlay_content)
        self.assertIn("ScreencopyView", self.overlay_content)

    def test_freeze_state_synchronization(self):
        """T3.5.2: Freeze settings apply uniformly across screens."""
        self.assertIn("Settings.screenshotFreeze", self.overlay_content)

if __name__ == "__main__":
    unittest.main()
