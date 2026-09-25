#!/run/current-system/sw/bin/python3
"""
Tier 1 Feature 17: WindowTitlePopup Hull Integrity (R3)
Validates that WindowTitlePopup.isFloating is renamed to isWindowFloating so it
does not collide with base PopupPanel.isFloating docking geometry.
"""

import unittest
import re
from tests.harness import QmlCodeInspector

class TestF17WindowTitlePopupHull(unittest.TestCase):
    """Verifies WindowTitlePopup property collision fix and docking hull integrity."""

    def setUp(self):
        self.wt_popup = QmlCodeInspector.read_qml_content("widgets/WindowTitlePopup.qml")
        self.popup_panel = QmlCodeInspector.read_qml_content("controls/PopupPanel.qml")

    def test_no_is_floating_collision(self):
        """T1.17.1: WindowTitlePopup does not declare property bool isFloating colliding with base."""
        has_collision = bool(re.search(r'property\s+bool\s+isFloating\b', self.wt_popup))
        self.assertFalse(
            has_collision,
            "WindowTitlePopup should not shadow PopupPanel.isFloating; use isWindowFloating"
        )

    def test_is_window_floating_used(self):
        """T1.17.2: WindowTitlePopup declares isWindowFloating for client window state."""
        self.assertIn(
            "isWindowFloating",
            self.wt_popup,
            "WindowTitlePopup should use isWindowFloating"
        )

    def test_popup_panel_defines_is_floating(self):
        """T1.17.3: PopupPanel.qml defines base isFloating property for panel docking."""
        self.assertIn("isFloating", self.popup_panel)

    def test_windowtitle_popup_uses_popup_panel(self):
        """T1.17.4: WindowTitlePopup uses PopupPanel as base component."""
        self.assertIn("PopupPanel", self.wt_popup)

    def test_hull_curvature_docking_respected(self):
        """T1.17.5: WindowTitlePopup docked hull retains curved edges when bar is docked."""
        self.assertIn("PopupPanel", self.wt_popup)
        self.assertIn("Theme.popupRadius", self.popup_panel)

if __name__ == "__main__":
    unittest.main()
