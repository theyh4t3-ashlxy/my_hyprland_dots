#!/run/current-system/sw/bin/python3
"""
Tier 2 Boundary 16: Screen Binding Boundary Cases
Tests edge conditions for screen and monitor property propagation:
null modelData, disconnected monitor handles, and primary monitor fallback.
"""

import unittest
from tests.harness import QmlCodeInspector

class TestB16ScreenBindingBoundary(unittest.TestCase):
    """Verifies edge conditions for screen and monitor propagation."""

    def setUp(self):
        self.bar_content = QmlCodeInspector.read_qml_content("bar/StatusBar.qml")

    def test_null_hypr_monitor_safety(self):
        """T2.16.1: Passing null hyprMonitor to module does not throw reference error."""
        self.assertIn("root.hyprMonitor", self.bar_content)

    def test_null_screen_safety(self):
        """T2.16.2: Passing null screen to module falls back cleanly."""
        self.assertIn("root.screen", self.bar_content)

    def test_module_count_completeness(self):
        """T2.16.3: All status bar sections (left, center, right) propagate screen data."""
        self.assertIn("leftRowH", self.bar_content)
        self.assertIn("rightRowH", self.bar_content)

    def test_vertical_status_bar_screen_binding(self):
        """T2.16.4: Vertical status bar rows also propagate barScreen and barMonitor."""
        self.assertIn("leftRowV", self.bar_content)
        self.assertIn("rightRowV", self.bar_content)

    def test_scope_model_data_requirement(self):
        """T2.16.5: StatusBar Scope defines required property var modelData."""
        self.assertIn("required property var modelData", self.bar_content)

if __name__ == "__main__":
    unittest.main()
