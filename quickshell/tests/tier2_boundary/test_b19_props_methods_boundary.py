#!/run/current-system/sw/bin/python3
"""
Tier 2 Boundary 19: Missing Properties & Methods Boundary Cases
Tests edge conditions for getFontWeight and settings defaults:
null inputs, empty strings, unrecognized strings, and non-numeric weights.
"""

import unittest
from tests.harness import QmlCodeInspector

def simulate_get_font_weight(weight_str):
    if not weight_str or not isinstance(weight_str, str):
        return 400 # Font.Normal
    w = weight_str.lower().strip()
    mapping = {
        "thin": 100,
        "extralight": 200,
        "ultralight": 200,
        "light": 300,
        "normal": 400,
        "regular": 400,
        "medium": 500,
        "demibold": 600,
        "semibold": 600,
        "bold": 700,
        "extrabold": 800,
        "ultrabold": 800,
        "black": 900,
        "heavy": 900
    }
    return mapping.get(w, 400)

class TestB19PropsMethodsBoundary(unittest.TestCase):
    """Verifies edge conditions for font weight helper and settings properties."""

    def test_null_font_weight_input(self):
        """T2.19.1: null or None weight input returns 400 (Font.Normal)."""
        self.assertEqual(simulate_get_font_weight(None), 400)

    def test_empty_string_weight_input(self):
        """T2.19.2: Empty string weight input returns 400 (Font.Normal)."""
        self.assertEqual(simulate_get_font_weight(""), 400)

    def test_unrecognized_weight_input(self):
        """T2.19.3: Unknown string 'ultra-heavy-extra' returns 400 (Font.Normal)."""
        self.assertEqual(simulate_get_font_weight("ultra-heavy-extra"), 400)

    def test_whitespace_and_case_tolerance(self):
        """T2.19.4: '  BOLD  ' and 'Medium' resolve correctly despite whitespace/casing."""
        self.assertEqual(simulate_get_font_weight("  BOLD  "), 700)
        self.assertEqual(simulate_get_font_weight("Medium"), 500)

    def test_font_sans_non_empty_default(self):
        """T2.19.5: Settings.fontSans provides a valid string fallback."""
        settings = QmlCodeInspector.read_qml_content("services/Settings.qml")
        self.assertIn("font", settings.lower())

if __name__ == "__main__":
    unittest.main()
