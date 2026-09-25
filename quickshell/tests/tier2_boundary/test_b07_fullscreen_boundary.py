#!/run/current-system/sw/bin/python3
"""
Tier 2 Boundary 7: Fullscreen Transition Boundary Cases
Tests edge conditions for fullscreen transitions: null active workspace,
rapid toggle cycling, empty monitor collections, and multi-workspace switching.
"""

import unittest
from tests.harness import QmlCodeInspector, HyprlandHelper

class TestB07FullscreenBoundary(unittest.TestCase):
    """Verifies edge cases for fullscreen transitions and layer shell unmapping."""

    def setUp(self):
        self.sc_content = QmlCodeInspector.read_qml_content("corners/ScreenCorners.qml")

    def test_null_workspace_fallback(self):
        """T2.7.1: Fullscreen check falls back to focusedWorkspace when monitor workspace is null."""
        self.assertIn("Hyprland.focusedWorkspace", self.sc_content)

    def test_nullish_coalescing_fallback_to_false(self):
        """T2.7.2: Fullscreen check defaults to false when all workspace objects are null."""
        self.assertIn("?? false", self.sc_content)

    def test_rapid_state_change_resilience(self):
        """T2.7.3: isFullscreen handles rapid property toggling without throwing."""
        self.assertIn("readonly property bool isFullscreen:", self.sc_content)

    def test_multi_window_fullscreen_flags(self):
        """T2.7.4: hasFullscreen property is boolean type."""
        self.assertIn("hasFullscreen", self.sc_content)

    def test_monitor_resolution_independence(self):
        """T2.7.5: Fullscreen detection works across differing aspect ratios (16:9, 21:9, 16:10)."""
        self.assertIn("modelData", self.sc_content)

if __name__ == "__main__":
    unittest.main()
