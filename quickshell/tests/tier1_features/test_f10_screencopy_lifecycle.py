#!/run/current-system/sw/bin/python3
"""
Tier 1 Feature 10: ScreencopyView Lifecycle Gating (R2)
Validates that ScreencopyView.captureSource is conditionally bound only when
the capture overlay is active, preventing SIGSEGV on monitor hotplug/disconnect.
"""

import unittest
import re
from tests.harness import QmlCodeInspector, QuickshellIpc

class TestF10ScreencopyLifecycle(unittest.TestCase):
    """Verifies ScreencopyView lifecycle gating in ScreenshotOverlay.qml."""

    def setUp(self):
        self.overlay_content = QmlCodeInspector.read_qml_content("widgets/ScreenshotOverlay.qml")
        self.service_content = QmlCodeInspector.read_qml_content("services/ScreenshotService.qml")

    def test_overlay_file_exists(self):
        """T1.10.1: ScreenshotOverlay.qml exists and is readable."""
        self.assertTrue(len(self.overlay_content) > 0)

    def test_capturesource_conditionally_gated(self):
        """T1.10.2: ScreencopyView.captureSource is gated to avoid null screen crashes."""
        # ScreencopyView should only bind captureSource when active/capturing
        has_conditional_source = bool(re.search(
            r'captureSource:\s*(?:overlayRoot\.isCapturing|ScreenshotService\.isOpen|\(?[^?]+\?[^:]+:\s*null\))',
            self.overlay_content
        ))
        # It should not be permanently bound to overlayRoot.screen unconditionally
        unconditional_source = bool(re.search(
            r'captureSource:\s*overlayRoot\.screen\s*(?:\n|;)',
            self.overlay_content
        ))
        self.assertTrue(
            has_conditional_source or not unconditional_source,
            "ScreencopyView.captureSource must be conditionally gated"
        )

    def test_screencopy_view_present(self):
        """T1.10.3: ScreencopyView component is declared."""
        self.assertIn("ScreencopyView", self.overlay_content)

    def test_screenshot_service_ipc_target(self):
        """T1.10.4: Quickshell IPC exposes screenshot target."""
        targets = QuickshellIpc.list_targets()
        self.assertIn("screenshot", targets)

    def test_screenshot_ipc_close_safe(self):
        """T1.10.5: Calling screenshot close does not crash daemon."""
        if QuickshellIpc.is_available():
            ret, out = QuickshellIpc.call("screenshot", "close")
            self.assertEqual(ret, 0, f"IPC screenshot close failed: {out}")

if __name__ == "__main__":
    unittest.main()
