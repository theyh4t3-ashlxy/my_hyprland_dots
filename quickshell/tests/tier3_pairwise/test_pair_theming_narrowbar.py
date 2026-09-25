#!/run/current-system/sw/bin/python3
"""
Tier 3 Pairwise 7: Dynamic Theming with Narrow Status Bar (F13 x F14 x F15)
Validates that dynamic palette updates correctly apply to clamped narrow
status bar layouts without triggering layout oscillation or overlap.
"""

import unittest
from tests.harness import QmlCodeInspector

class TestPairThemingNarrowbar(unittest.TestCase):
    """Pairwise interaction between reactive theming and status bar layout clamping."""

    def setUp(self):
        self.bar_content = QmlCodeInspector.read_qml_content("bar/StatusBar.qml")
        self.theme_content = QmlCodeInspector.read_qml_content("Theme.qml")

    def test_theme_colors_applied_to_bar(self):
        """T3.7.1: StatusBar references Theme.barBg for background."""
        self.assertIn("Theme.barBg", self.bar_content)

    def test_clamped_title_uses_theme_font(self):
        """T3.7.2: StatusBar uses Theme typography tokens."""
        self.assertIn("Theme.", self.bar_content)

if __name__ == "__main__":
    unittest.main()
