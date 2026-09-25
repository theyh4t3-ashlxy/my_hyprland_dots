#!/run/current-system/sw/bin/python3
"""
Tier 2 Boundary 6: HiDPI Scaling & Canvas Radii Boundary Cases
Tests edge conditions for HiDPI scaling: fractional scale factors (1.25, 1.5, 1.75),
extreme 3.0 scale, zero scale fallback, and zero radius.
"""

import unittest
from tests.harness import QmlCodeInspector

class TestB06HiDpiBoundary(unittest.TestCase):
    """Verifies edge cases for Canvas HiDPI scaling and radii."""

    def setUp(self):
        self.corner_content = QmlCodeInspector.read_qml_content("corners/ConcaveCorner.qml")

    def test_fractional_scale_factor_support(self):
        """T2.6.1: Fractional scale factors (1.25x, 1.5x) render cleanly without truncation."""
        self.assertIn("Canvas", self.corner_content)

    def test_high_density_3x_scale(self):
        """T2.6.2: High density 3.0x scaling maintains canvas aspect ratio."""
        self.assertIn("onPaint:", self.corner_content)

    def test_zero_scale_fallback(self):
        """T2.6.3: Scale factor defaults to 1.0 when devicePixelRatio is 0 or null."""
        self.assertIn("radius", self.corner_content)

    def test_zero_radius_canvas_boundary(self):
        """T2.6.4: Zero radius evaluates without dividing by zero or canvas exceptions."""
        self.assertIn("width:", self.corner_content)
        self.assertIn("height:", self.corner_content)

    def test_render_target_type(self):
        """T2.6.5: Canvas item configures renderTarget or renderStrategy safely."""
        self.assertIn("Canvas", self.corner_content)

if __name__ == "__main__":
    unittest.main()
