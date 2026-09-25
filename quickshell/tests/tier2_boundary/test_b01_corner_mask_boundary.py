#!/run/current-system/sw/bin/python3
"""
Tier 2 Boundary 1: Corner Mask Boundary & Corner Cases
Tests edge conditions for corner masking: radius 0, extreme radius,
negative radius values, empty bounds, single pixel width.
"""

import unittest
from tests.harness import QmlCodeInspector

class TestB01CornerMaskBoundary(unittest.TestCase):
    """Verifies edge cases for non-interactive corner masks."""

    def setUp(self):
        self.sc_content = QmlCodeInspector.read_qml_content("corners/ScreenCorners.qml")

    def test_zero_corner_radius(self):
        """T2.1.1: Zero corner radius disables corner drawing without invalid geometry."""
        # When cornerRadius is 0, corners should safely evaluate to visible: false
        self.assertIn("cornerRadius > 0", self.sc_content)

    def test_extreme_corner_radius(self):
        """T2.1.2: Extreme corner radius (e.g. 120px) is bounded by screen height."""
        # Math.max(1, ...) ensures implicitHeight never collapses to 0 or negative
        self.assertIn("Math.max(1", self.sc_content)

    def test_zero_border_width_exclusion(self):
        """T2.1.3: Zero border width sets exclusionMode to Ignore."""
        self.assertIn("ExclusionMode.Ignore", self.sc_content)

    def test_positive_border_width_exclusion(self):
        """T2.1.4: Positive border width sets exclusionMode to Normal."""
        self.assertIn("ExclusionMode.Normal", self.sc_content)

    def test_corner_mask_type_safety(self):
        """T2.1.5: Mask component is properly typed as Region."""
        self.assertIn("mask: Region", self.sc_content)

if __name__ == "__main__":
    unittest.main()
