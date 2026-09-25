#!/run/current-system/sw/bin/python3
"""
Tier 1 Feature 18: OSD Layer Surface Inactive Gating (R3)
Validates that PanelWindow.visible in osd/OSD.qml is bound to avoid maintaining
an active Wayland overlay layer surface 100% of the time.
"""

import unittest
import re
from tests.harness import QmlCodeInspector, HyprlandHelper, QuickshellIpc

class TestF18OsdLayerGating(unittest.TestCase):
    """Verifies OSD layer surface inactive gating in osd/OSD.qml."""

    def setUp(self):
        self.osd_content = QmlCodeInspector.read_qml_content("osd/OSD.qml")

    def test_osd_file_exists(self):
        """T1.18.1: osd/OSD.qml exists and is readable."""
        self.assertTrue(len(self.osd_content) > 0)

    def test_panel_window_visible_binding(self):
        """T1.18.2: PanelWindow binds visible property to active/showing state."""
        self.assertRegex(
            self.osd_content,
            r'visible:\s*(?:root\.showing|root\.visible|hideTimer\.running|timeoutTimer\.running)',
            "OSD PanelWindow.visible must be bound to active state rather than permanently open"
        )

    def test_osd_namespace(self):
        """T1.18.3: OSD declares namespace quickshell:osd."""
        self.assertIn('namespace: "quickshell:osd"', self.osd_content)

    def test_osd_has_timeout_timer(self):
        """T1.18.4: OSD contains a timer for auto-dismissal."""
        self.assertIn("Timer", self.osd_content)

    def test_volume_ipc_triggers_osd(self):
        """T1.18.5: Volume IPC call executes cleanly without daemon crash."""
        if QuickshellIpc.is_available():
            ret, out = QuickshellIpc.call("volume", "up", "0.02")
            self.assertEqual(ret, 0, f"Volume up IPC failed: {out}")

if __name__ == "__main__":
    unittest.main()
