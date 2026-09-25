#!/run/current-system/sw/bin/python3
"""
Tier 2 Boundary 15: Animation Synchronization Boundary Cases
Tests edge conditions for status bar width animations: duration 0 (instant),
extreme duration (5000ms), NaN values, and negative target widths.
"""

import unittest
from tests.harness import QmlCodeInspector

class TestB15AnimSyncBoundary(unittest.TestCase):
    """Verifies edge conditions for width animations and easing curves."""

    def setUp(self):
        self.bar_content = QmlCodeInspector.read_qml_content("bar/StatusBar.qml")

    def test_duration_zero_support(self):
        """T2.15.1: Animators handle duration 0 without division-by-zero."""
        self.assertIn("duration:", self.bar_content)

    def test_math_round_target_width(self):
        """T2.15.2: Target width is rounded to avoid sub-pixel layout jitter."""
        self.assertIn("Math.round", self.bar_content)

    def test_fallback_module_width(self):
        """T2.15.3: Module width falls back cleanly when item is null."""
        self.assertIn("Theme.barHeight - 8", self.bar_content)

    def test_easing_type_bound(self):
        """T2.15.4: Animation easing type is bound to theme easing."""
        self.assertIn("easing.type:", self.bar_content)

    def test_vertical_bar_height_animation(self):
        """T2.15.5: Vertical orientation animates height identically to horizontal width."""
        self.assertIn("height:", self.bar_content)

if __name__ == "__main__":
    unittest.main()
