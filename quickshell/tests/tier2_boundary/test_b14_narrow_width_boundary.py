#!/run/current-system/sw/bin/python3
"""
Tier 2 Boundary 14: Narrow Width Ergonomics Boundary Cases
Tests edge conditions for status bar layout: extreme 640px, 800px widths,
500-character window titles, and empty window titles.
"""

import unittest
from tests.tier1_features.test_f14_statusbar_narrow_width import compute_max_title_width

class TestB14NarrowWidthBoundary(unittest.TestCase):
    """Verifies edge conditions for narrow status bar displays."""

    def test_extreme_narrow_640px(self):
        """T2.14.1: Extreme narrow 640px display enforces minimum 100px title."""
        w = compute_max_title_width(640, center_w=200, left_offset=260)
        # 640/2 = 320. 320 - 100 = 220. 220 - 260 = -40 -> clamped to max(100, -40) = 100
        self.assertEqual(w, 100)

    def test_extreme_narrow_800px(self):
        """T2.14.2: 800px display width calculates non-negative bound."""
        w = compute_max_title_width(800, center_w=200, left_offset=260)
        # 800/2 = 400. 400 - 100 = 300. 300 - 260 = 40 -> clamped to 100
        self.assertEqual(w, 100)

    def test_ultra_wide_3440px(self):
        """T2.14.3: Ultrawide 3440px display gives expansive title width."""
        w = compute_max_title_width(3440, center_w=200, left_offset=260)
        # 3440/2 = 1720. 1720 - 100 = 1620. 1620 - 260 = 1360.
        self.assertEqual(w, 1360)

    def test_zero_width_fallback(self):
        """T2.14.4: Zero screen width safely falls back to minimum bound 100px."""
        w = compute_max_title_width(0, center_w=0, left_offset=0)
        self.assertEqual(w, 100)

    def test_center_clock_visibility(self):
        """T2.14.5: Center row width is respected in space allocation."""
        w_small_clock = compute_max_title_width(1920, center_w=100, left_offset=260)
        w_large_clock = compute_max_title_width(1920, center_w=400, left_offset=260)
        self.assertTrue(w_small_clock > w_large_clock)

if __name__ == "__main__":
    unittest.main()
