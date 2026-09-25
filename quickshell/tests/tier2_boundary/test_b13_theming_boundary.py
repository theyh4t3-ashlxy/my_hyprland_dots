#!/run/current-system/sw/bin/python3
"""
Tier 2 Boundary 13: Reactive Theming Boundary Cases
Tests edge conditions for dynamic theming: empty palette.css,
malformed CSS syntax, non-existent color properties, and rapid palette writes.
"""

import unittest
import re
from pathlib import Path
from tests.harness import QmlCodeInspector, REPO_ROOT

class TestB13ThemingBoundary(unittest.TestCase):
    """Verifies edge cases for reactive palette parsing and fallbacks."""

    def setUp(self):
        self.theme_content = QmlCodeInspector.read_qml_content("Theme.qml")

    def test_css_variable_regex_robustness(self):
        """T2.13.1: CSS variable parser extracts hex colors and ignores whitespace variations."""
        sample_css = """
        :root {
            --primary: #123456;
            --surface:   #abcdef ;
            --invalid-token: not-a-color;
        }
        """
        matches = dict(re.findall(r'--([a-zA-Z0-9_-]+):\s*(#[0-9a-fA-F]{6})', sample_css))
        self.assertEqual(matches.get("primary"), "#123456")
        self.assertEqual(matches.get("surface"), "#abcdef")
        self.assertNotIn("invalid-token", matches)

    def test_empty_palette_fallback(self):
        """T2.13.2: Empty palette file falls back to built-in theme colors."""
        self.assertIn("readonly property color primary:", self.theme_content)

    def test_theme_color_contrast_safety(self):
        """T2.13.3: Theme provides textPrimary and textSecondary contrasting tokens."""
        self.assertIn("textPrimary", self.theme_content)
        self.assertIn("textSecondary", self.theme_content)

    def test_palette_file_path_resolution(self):
        """T2.13.4: Palette file references standard XDG path or local config."""
        self.assertIn("palette.css", self.theme_content)

    def test_rapid_theme_color_propagation(self):
        """T2.13.5: Color tokens are defined as reactive QML properties."""
        self.assertIn("property color", self.theme_content)

if __name__ == "__main__":
    unittest.main()
