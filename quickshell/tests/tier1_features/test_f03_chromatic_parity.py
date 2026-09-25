#!/run/current-system/sw/bin/python3
"""
Tier 1 Feature 3: Chromatic Parity for Fillets (R1)
Validates that Settings.cornerColorMode defaults to "bar" so that
concave fillets match Theme.barBg across all styles.
"""

import unittest
import re
from tests.harness import QmlCodeInspector

class TestF03ChromaticParity(unittest.TestCase):
    """Verifies chromatic parity between corner fillets and status bar background."""

    def setUp(self):
        self.settings_content = QmlCodeInspector.read_qml_content("services/Settings.qml")
        self.theme_content = QmlCodeInspector.read_qml_content("Theme.qml")

    def test_settings_corner_color_mode_default(self):
        """T1.3.1: Settings.cornerColorMode defaults to 'bar'."""
        self.assertRegex(
            self.settings_content,
            r'property\s+string\s+cornerColorMode:\s*"bar"',
            "Settings.cornerColorMode must default to 'bar' for chromatic parity"
        )

    def test_theme_corner_fill_handles_bar_mode(self):
        """T1.3.2: Theme.cornerFill evaluates to barBg when cornerColorMode is 'bar'."""
        self.assertIn(
            "cornerFill",
            self.theme_content,
            "Theme.qml must define cornerFill property"
        )
        self.assertRegex(
            self.theme_content,
            r'cm === "bar"|return barBg',
            "Theme.cornerFill must return barBg for mode 'bar'"
        )

    def test_theme_bar_bg_defined(self):
        """T1.3.3: Theme.barBg is defined as a color."""
        self.assertRegex(
            self.theme_content,
            r'property\s+color\s+barBg',
            "Theme.qml must define property color barBg"
        )

    def test_concave_corner_supports_styles(self):
        """T1.3.4: ConcaveCorner.qml accepts color parameter matching barBg."""
        corner_content = QmlCodeInspector.read_qml_content("corners/ConcaveCorner.qml")
        self.assertRegex(
            corner_content,
            r'property\s+(?:color|alias)\s+(?:fillColor|color)',
            "ConcaveCorner.qml must have a color/fillColor property"
        )

    def test_screen_corners_binds_corner_color(self):
        """T1.3.5: ScreenCorners.qml binds cornerColor using Theme.cornerFill or Theme.barBg."""
        sc_content = QmlCodeInspector.read_qml_content("corners/ScreenCorners.qml")
        self.assertRegex(
            sc_content,
            r'cornerColor:\s*Theme\?.cornerFill',
            "ScreenCorners.qml must bind cornerColor to Theme.cornerFill"
        )

if __name__ == "__main__":
    unittest.main()
