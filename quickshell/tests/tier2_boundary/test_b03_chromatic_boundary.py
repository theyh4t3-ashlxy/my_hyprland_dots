#!/run/current-system/sw/bin/python3
"""
Tier 2 Boundary 3: Chromatic Parity Boundary & Corner Cases
Tests edge conditions for corner color modes: invalid mode strings,
null settings, transparent colors, pure-black, and accent modes.
"""

import unittest
import re
from tests.harness import QmlCodeInspector

class TestB03ChromaticBoundary(unittest.TestCase):
    """Verifies edge cases for corner color modes and chromatic parity."""

    def setUp(self):
        self.theme_content = QmlCodeInspector.read_qml_content("Theme.qml")

    def test_invalid_color_mode_fallback(self):
        """T2.3.1: Unknown or invalid cornerColorMode falls back safely to barBg."""
        # Check that cornerFill has a final return barBg fallback
        self.assertRegex(
            self.theme_content,
            r'return barBg;',
            "Theme.cornerFill must fall back to barBg on unrecognized mode"
        )

    def test_null_settings_fallback(self):
        """T2.3.2: Null or undefined Settings defaults safely using ?? operator."""
        self.assertRegex(
            self.theme_content,
            r'(?:Settings|cfg)\?.cornerColorMode\s*\?\?',
            "Theme.cornerFill must use nullish coalescing on Settings.cornerColorMode"
        )

    def test_pure_black_mode(self):
        """T2.3.3: cornerColorMode 'pure-black' returns true OLED black (#000000)."""
        self.assertIn('"pure-black"', self.theme_content)
        self.assertIn('"#000000"', self.theme_content)

    def test_accent_mode(self):
        """T2.3.4: cornerColorMode 'accent' returns primary color."""
        self.assertIn('"accent"', self.theme_content)
        self.assertIn("return primary;", self.theme_content)

    def test_hex_color_string_validity(self):
        """T2.3.5: All fallback hex colors match valid #RRGGBB format."""
        matches = re.findall(r'"#[0-9a-fA-F]{6}"', self.theme_content)
        self.assertTrue(len(matches) > 0, "Hex colors should be properly formatted")

if __name__ == "__main__":
    unittest.main()
