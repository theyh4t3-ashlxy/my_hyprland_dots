#!/run/current-system/sw/bin/python3
"""
Tier 1 Feature 1: Non-interactive Corner Masking (R1)
Validates that screen corner layer surfaces use an empty Region mask
to eliminate input traps outside visual fillets.
"""

import unittest
import re
from tests.harness import QmlCodeInspector, HyprlandHelper

class TestF01CornerMasking(unittest.TestCase):
    """Verifies non-interactive corner masking in ScreenCorners.qml."""

    def setUp(self):
        self.qml_path = "corners/ScreenCorners.qml"
        self.content = QmlCodeInspector.read_qml_content(self.qml_path)

    def test_file_exists(self):
        """T1.1.1: ScreenCorners.qml exists and is readable."""
        self.assertTrue(len(self.content) > 0, "ScreenCorners.qml could not be loaded")

    def test_corner_mask_region_empty(self):
        """T1.1.2: PanelWindow defines mask: Region {} to make corners click-through."""
        # The contract requires mask: Region {} so no rectangular bounding box traps clicks
        has_empty_mask = bool(re.search(r"mask:\s*Region\s*\{\s*\}", self.content))
        self.assertTrue(
            has_empty_mask,
            "ScreenCorners.qml must define 'mask: Region {}' on corner surfaces to prevent click traps"
        )

    def test_corner_no_item_subregions(self):
        """T1.1.3: No subregions with item: cornerL/R trap pointer events."""
        # Negative assertion: items cornerL and cornerR should NOT be in the mask
        has_corner_item_traps = bool(re.search(r"Region\s*\{\s*item:\s*corner[LR]", self.content))
        self.assertFalse(
            has_corner_item_traps,
            "ScreenCorners.qml mask should not include cornerL or cornerR bounding items"
        )

    def test_corner_namespace(self):
        """T1.1.4: PanelWindow declares namespace quickshell:corners."""
        self.assertIn(
            'namespace: "quickshell:corners"',
            self.content,
            "Corner PanelWindow must declare namespace quickshell:corners"
        )

    def test_corner_keyboard_focus_none(self):
        """T1.1.5: Corner surfaces reject keyboard focus."""
        has_kb_focus_none = "keyboardFocus: WlrKeyboardFocus.None" in self.content
        self.assertTrue(
            has_kb_focus_none,
            "Corner surfaces must have WlrKeyboardFocus.None"
        )

if __name__ == "__main__":
    unittest.main()
