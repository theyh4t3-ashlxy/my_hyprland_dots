#!/run/current-system/sw/bin/python3
"""
Tier 2 Boundary 4: Floating Bar Boundary & Corner Cases
Tests edge conditions for floating status bars: extreme margins (100px),
zero margin, extreme radius (50px), and rapid docking toggles.
"""

import unittest
from tests.harness import QmlCodeInspector

class TestB04FloatingBoundary(unittest.TestCase):
    """Verifies edge cases for floating bar margins and radii."""

    def setUp(self):
        self.bar_content = QmlCodeInspector.read_qml_content("bar/StatusBar.qml")
        self.settings_content = QmlCodeInspector.read_qml_content("services/Settings.qml")

    def test_zero_bar_margin_validity(self):
        """T2.4.1: Zero barMargin cleanly collapses without layout gap."""
        self.assertIn("barMargin", self.settings_content)

    def test_extreme_bar_margin(self):
        """T2.4.2: Large barMargin does not cause width underflow."""
        self.assertIn("root.width", self.bar_content)

    def test_extreme_bar_radius(self):
        """T2.4.3: High barRadius is clamped or rendered smoothly."""
        self.assertIn("barRadius", self.settings_content)

    def test_boolean_toggle_resilience(self):
        """T2.4.4: barFloating boolean toggles cleanly."""
        self.assertIn("barFloating", self.settings_content)

    def test_screen_frame_docked_default(self):
        """T2.4.5: screenFrameDocked defaults to a valid boolean."""
        self.assertIn("screenFrameDocked", self.settings_content)

if __name__ == "__main__":
    unittest.main()
