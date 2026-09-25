#!/run/current-system/sw/bin/python3
"""
Tier 1 Feature 7: Fullscreen Auto-Hide Stability (R1)
Validates that corners and bar layer shell surfaces yield and unmap immediately
when client windows enter fullscreen.
"""

import unittest
import re
from tests.harness import QmlCodeInspector, HyprlandHelper

class TestF07FullscreenAutohide(unittest.TestCase):
    """Verifies fullscreen auto-hide stability for corners and status bar."""

    def setUp(self):
        self.sc_content = QmlCodeInspector.read_qml_content("corners/ScreenCorners.qml")
        self.bar_content = QmlCodeInspector.read_qml_content("bar/StatusBar.qml")

    def test_screen_corners_tracks_fullscreen(self):
        """T1.7.1: ScreenCorners.qml binds isFullscreen."""
        self.assertIn("isFullscreen", self.sc_content)
        self.assertIn("hasFullscreen", self.sc_content)

    def test_screen_corners_hides_in_fullscreen(self):
        """T1.7.2: ScreenCorners PanelWindows include !root.isFullscreen in visible binding."""
        self.assertRegex(
            self.sc_content,
            r'visible:[^;\n]*!root\.isFullscreen',
            "ScreenCorners must hide corner PanelWindows during fullscreen"
        )

    def test_status_bar_tracks_fullscreen(self):
        """T1.7.3: StatusBar.qml checks hasFullscreen."""
        self.assertIn("hasFullscreen", self.bar_content)

    def test_safe_optional_chaining_on_workspace(self):
        """T1.7.4: Fullscreen check uses optional chaining on hyprMonitor."""
        self.assertRegex(
            self.sc_content,
            r'hyprMonitor\?\.activeWorkspace\?\.hasFullscreen',
            "Fullscreen check must use safe optional chaining"
        )

    def test_live_hyprland_monitors_readable(self):
        """T1.7.5: Live compositor monitors query executes without error."""
        mons = HyprlandHelper.get_monitors()
        self.assertIsInstance(mons, list)
        self.assertTrue(len(mons) >= 1, "At least one monitor should be detected in live environment")

if __name__ == "__main__":
    unittest.main()
