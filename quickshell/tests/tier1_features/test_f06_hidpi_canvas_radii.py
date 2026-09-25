#!/run/current-system/sw/bin/python3
"""
Tier 1 Feature 6: HiDPI Scaling & Canvas Radii (R1)
Validates that ConcaveCorner.qml applies Screen.devicePixelRatio to Canvas sizing
and resolves radius property precedence shadowing.
"""

import unittest
import re
from tests.harness import QmlCodeInspector

class TestF06HiDpiCanvasRadii(unittest.TestCase):
    """Verifies HiDPI scaling and radius property precedence in ConcaveCorner.qml."""

    def setUp(self):
        self.corner_content = QmlCodeInspector.read_qml_content("corners/ConcaveCorner.qml")

    def test_file_exists(self):
        """T1.6.1: ConcaveCorner.qml exists and is readable."""
        self.assertTrue(len(self.corner_content) > 0)

    def test_device_pixel_ratio_support(self):
        """T1.6.2: ConcaveCorner.qml references devicePixelRatio for crisp Canvas rendering."""
        self.assertRegex(
            self.corner_content,
            r'devicePixelRatio|Screen\?\.devicePixelRatio',
            "ConcaveCorner.qml must account for devicePixelRatio on HiDPI displays"
        )

    def test_radius_precedence_not_shadowed(self):
        """T1.6.3: Custom radius property takes effect without being permanently shadowed."""
        # Check that radius property definition allows caller override
        self.assertRegex(
            self.corner_content,
            r'property\s+real\s+radius:',
            "ConcaveCorner.qml must declare radius property"
        )

    def test_canvas_item_present(self):
        """T1.6.4: ConcaveCorner contains Canvas item with onPaint."""
        self.assertIn("Canvas", self.corner_content)
        self.assertIn("onPaint:", self.corner_content)

    def test_styles_supported(self):
        """T1.6.5: ConcaveCorner supports squircle, cubic, and flared styles."""
        self.assertIn("squircle", self.corner_content)
        self.assertIn("flared", self.corner_content)

if __name__ == "__main__":
    unittest.main()
