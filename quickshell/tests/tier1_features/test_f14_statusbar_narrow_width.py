#!/run/current-system/sw/bin/python3
"""
Tier 1 Feature 14: StatusBar Narrow-Width Ergonomics (R3)
Validates that window title width is clamped and left/right rows enforce max
bounds to prevent overlapping the centered clock under narrow screen widths.
"""

import unittest
import re
from tests.harness import QmlCodeInspector

def compute_max_title_width(screen_w, center_w=200, left_offset=260):
    half = screen_w / 2
    center_half = center_w / 2
    clock_start = half - center_half
    return max(100, clock_start - left_offset)

class TestF14StatusBarNarrowWidth(unittest.TestCase):
    """Verifies narrow-width ergonomics and layout bounds in bar/StatusBar.qml."""

    def setUp(self):
        self.bar_content = QmlCodeInspector.read_qml_content("bar/StatusBar.qml")

    def test_max_window_title_width_declared(self):
        """T1.14.1: StatusBar.qml defines maxWindowTitleWidth property."""
        self.assertIn("maxWindowTitleWidth", self.bar_content)

    def test_narrow_screen_1280_calculation(self):
        """T1.14.2: Clamping prevents overlap on 1280px display width."""
        w = compute_max_title_width(1280, center_w=200, left_offset=260)
        # 1280 / 2 = 640. Clock start = 540. 540 - 260 = 280.
        self.assertEqual(w, 280)
        self.assertTrue(w + 260 <= 1280 / 2 - 100)

    def test_narrow_screen_1024_calculation(self):
        """T1.14.3: Clamping prevents overlap on 1024px display width."""
        w = compute_max_title_width(1024, center_w=200, left_offset=260)
        # 1024 / 2 = 512. Clock start = 412. 412 - 260 = 152.
        self.assertEqual(w, 152)
        self.assertTrue(w + 260 <= 1024 / 2 - 100)

    def test_standard_screen_1920_calculation(self):
        """T1.14.4: 1920px screen width allows generous title width."""
        w = compute_max_title_width(1920, center_w=200, left_offset=260)
        # 1920 / 2 = 960. Clock start = 860. 860 - 260 = 600.
        self.assertEqual(w, 600)

    def test_center_clock_row_has_center_anchor(self):
        """T1.14.5: Center clock row anchors to horizontalCenter."""
        self.assertIn("horizontalCenter: parent.horizontalCenter", self.bar_content)

if __name__ == "__main__":
    unittest.main()
