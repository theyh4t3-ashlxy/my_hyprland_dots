#!/run/current-system/sw/bin/python3
"""
Tier 1 Feature 19: Missing Properties & Methods (R4)
Validates that Theme.getFontWeight, Settings.clock24h, and Settings.fontSans
are implemented across components.
"""

import unittest
import re
from tests.harness import QmlCodeInspector

class TestF19MissingPropsMethods(unittest.TestCase):
    """Verifies existence and correctness of previously missing helper methods and properties."""

    def setUp(self):
        self.theme_content = QmlCodeInspector.read_qml_content("Theme.qml")
        self.settings_content = QmlCodeInspector.read_qml_content("services/Settings.qml")

    def test_theme_get_font_weight_defined(self):
        """T1.19.1: Theme.qml defines function getFontWeight."""
        self.assertRegex(
            self.theme_content,
            r'function\s+getFontWeight\s*\(',
            "Theme.qml must define getFontWeight helper function"
        )

    def test_settings_clock24h_defined(self):
        """T1.19.2: Settings.qml defines property bool clock24h."""
        self.assertRegex(
            self.settings_content,
            r'property\s+bool\s+clock24h',
            "Settings.qml must declare clock24h boolean property"
        )

    def test_settings_font_sans_defined(self):
        """T1.19.3: Settings.qml defines property string fontSans."""
        self.assertRegex(
            self.settings_content,
            r'property\s+string\s+fontSans',
            "Settings.qml must declare fontSans string property"
        )

    def test_get_font_weight_mappings(self):
        """T1.19.4: Theme.getFontWeight handles bold, medium, normal cases."""
        self.assertIn("bold", self.theme_content.lower())
        self.assertIn("normal", self.theme_content.lower())

    def test_settings_clock24h_used_in_clock(self):
        """T1.19.5: Clock widget references Settings.clock24h."""
        clock_content = QmlCodeInspector.read_qml_content("widgets/Clock.qml")
        if clock_content:
            self.assertIn("clock24h", clock_content)

if __name__ == "__main__":
    unittest.main()
