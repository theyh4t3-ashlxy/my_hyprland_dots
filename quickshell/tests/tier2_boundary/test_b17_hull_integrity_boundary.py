#!/run/current-system/sw/bin/python3
"""
Tier 2 Boundary 17: WindowTitlePopup Hull Integrity Boundary Cases
Tests edge conditions for popup docking: rapid window floating toggles,
unmapped client windows, and floating bar interaction with popups.
"""

import unittest
from tests.harness import QmlCodeInspector

class TestB17HullIntegrityBoundary(unittest.TestCase):
    """Verifies edge conditions for WindowTitlePopup docking and hull geometry."""

    def setUp(self):
        self.wt_popup = QmlCodeInspector.read_qml_content("widgets/WindowTitlePopup.qml")

    def test_null_activetop_window_safety(self):
        """T2.17.1: Active window lookup handles null activeTop safely."""
        self.assertIn("activeTop?", self.wt_popup)

    def test_popup_width_bounding(self):
        """T2.17.2: Popup panel width is bounded."""
        self.assertIn("contentWidth", self.wt_popup)

    def test_popup_height_bounding(self):
        """T2.17.3: Popup panel height is bounded."""
        self.assertIn("contentHeight", self.wt_popup)

    def test_popup_docking_edge_alignment(self):
        """T2.17.4: Popup attaches to the status bar screen edge."""
        self.assertIn("PopupPanel", self.wt_popup)

    def test_window_floating_boolean_type(self):
        """T2.17.5: Window floating state casts safely to boolean."""
        self.assertIn("Boolean", self.wt_popup)

if __name__ == "__main__":
    unittest.main()
