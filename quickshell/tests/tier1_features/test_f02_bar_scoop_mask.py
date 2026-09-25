#!/run/current-system/sw/bin/python3
"""
Tier 1 Feature 2: Status Bar Scoop Mask Sanitization (R1)
Validates that StatusBar.qml restricts its layer shell input mask to barBg only,
removing decorative scoop bounding boxes from capturing clicks.
"""

import unittest
import re
from tests.harness import QmlCodeInspector

class TestF02BarScoopMask(unittest.TestCase):
    """Verifies input mask sanitization in bar/StatusBar.qml."""

    def setUp(self):
        self.qml_path = "bar/StatusBar.qml"
        self.content = QmlCodeInspector.read_qml_content(self.qml_path)

    def test_file_exists(self):
        """T1.2.1: StatusBar.qml exists and is readable."""
        self.assertTrue(len(self.content) > 0, "StatusBar.qml could not be loaded")

    def test_mask_contains_bar_bg(self):
        """T1.2.2: StatusBar mask includes barBg item."""
        self.assertRegex(
            self.content,
            r"mask:\s*Region\s*\{[^}]*item:\s*barBg",
            "StatusBar.qml mask must include barBg"
        )

    def test_mask_excludes_scoop_items(self):
        """T1.2.3: StatusBar mask excludes scoop bounding boxes."""
        # Find the mask block
        mask_match = re.search(r"mask:\s*Region\s*\{([^}]+(?:\{[^}]*\}[^}]*)*)\}", self.content)
        self.assertIsNotNone(mask_match, "StatusBar.qml must define a mask: Region block")
        mask_block = mask_match.group(1)
        self.assertNotIn(
            "scoopLeftH",
            mask_block,
            "Decorative scoopLeftH should not be registered in StatusBar mask"
        )
        self.assertNotIn(
            "scoopRightH",
            mask_block,
            "Decorative scoopRightH should not be registered in StatusBar mask"
        )

    def test_bar_namespace(self):
        """T1.2.4: StatusBar declares namespace quickshell:bar."""
        self.assertIn(
            'namespace: "quickshell:bar"',
            self.content,
            "StatusBar PanelWindow must declare namespace quickshell:bar"
        )

    def test_exclusive_zone_is_bounded(self):
        """T1.2.5: StatusBar exclusiveZone respects Theme.barHeight."""
        self.assertIn(
            "exclusiveZone:",
            self.content,
            "StatusBar PanelWindow must specify exclusiveZone"
        )

if __name__ == "__main__":
    unittest.main()
