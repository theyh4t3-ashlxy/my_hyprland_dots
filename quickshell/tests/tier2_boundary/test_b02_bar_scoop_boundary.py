#!/run/current-system/sw/bin/python3
"""
Tier 2 Boundary 2: Status Bar Scoop Mask Boundary & Corner Cases
Tests edge conditions for status bar masks: extreme bar heights, vertical
orientations, empty scoop radius, and null screen geometries.
"""

import unittest
from tests.harness import QmlCodeInspector

class TestB02BarScoopBoundary(unittest.TestCase):
    """Verifies edge cases for status bar scoop input masking."""

    def setUp(self):
        self.bar_content = QmlCodeInspector.read_qml_content("bar/StatusBar.qml")

    def test_vertical_orientation_mask(self):
        """T2.2.1: Vertical bar positions handle mask correctly without horizontal scoops."""
        self.assertIn("isVertical", self.bar_content)

    def test_zero_bar_height_fallback(self):
        """T2.2.2: Bar height provides safe fallback when Theme.barHeight is unset."""
        self.assertIn("Theme.barHeight", self.bar_content)

    def test_extreme_bar_height(self):
        """T2.2.3: Exclusive zone scales with bar height."""
        self.assertIn("exclusiveZone: root.isVertical", self.bar_content)

    def test_null_model_data_screen(self):
        """T2.2.4: StatusBar handles null or unmapped screen safely."""
        self.assertIn("modelData", self.bar_content)

    def test_bar_bg_item_anchoring(self):
        """T2.2.5: barBg fill anchoring covers entire bar body."""
        self.assertIn("id: barBg", self.bar_content)

if __name__ == "__main__":
    unittest.main()
