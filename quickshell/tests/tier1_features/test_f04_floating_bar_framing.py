#!/run/current-system/sw/bin/python3
"""
Tier 1 Feature 4: Floating Bar Framing Adaptation (R1)
Validates that screen corner framing is decoupled from isDocked so corners
remain visible when floating, and StatusBar applies barMargin and barRadius.
"""

import unittest
import re
from tests.harness import QmlCodeInspector

class TestF04FloatingBarFraming(unittest.TestCase):
    """Verifies floating bar framing adaptation in ScreenCorners and StatusBar."""

    def setUp(self):
        self.sc_content = QmlCodeInspector.read_qml_content("corners/ScreenCorners.qml")
        self.bar_content = QmlCodeInspector.read_qml_content("bar/StatusBar.qml")

    def test_screen_corners_not_hidden_by_floating(self):
        """T1.4.1: ScreenCorners does not unconditionally require isDocked for screen framing."""
        # Screen corners should remain visible when floating bar is enabled
        # Look for visible condition on corners: it should not be strictly gated by root.isDocked
        # when corner radius is greater than 0
        self.assertNotIn(
            "visible: root.isDocked && !root.isFullscreen",
            self.sc_content,
            "ScreenCorners visible binding should decouple corner framing from root.isDocked"
        )

    def test_status_bar_applies_floating_margin(self):
        """T1.4.2: StatusBar.qml references barMargin when barFloating is true."""
        self.assertRegex(
            self.bar_content,
            r'barMargin|Theme\?\.barMargin|Settings\?\.barMargin',
            "StatusBar.qml must support floating barMargin"
        )

    def test_status_bar_applies_floating_radius(self):
        """T1.4.3: StatusBar.qml references barRadius when barFloating is true."""
        self.assertRegex(
            self.bar_content,
            r'barRadius|Theme\?\.barRadius|Settings\?\.barRadius',
            "StatusBar.qml must apply barRadius to background when floating"
        )

    def test_status_bar_floating_property_exists(self):
        """T1.4.4: StatusBar.qml defines or reads isFloating property."""
        self.assertRegex(
            self.bar_content,
            r'isFloating|barFloating',
            "StatusBar.qml must track floating bar state"
        )

    def test_settings_declares_floating_properties(self):
        """T1.4.5: Settings.qml provides barFloating, barMargin, and barRadius."""
        settings = QmlCodeInspector.read_qml_content("services/Settings.qml")
        self.assertIn("barFloating", settings)
        self.assertIn("barMargin", settings)
        self.assertIn("barRadius", settings)

if __name__ == "__main__":
    unittest.main()
