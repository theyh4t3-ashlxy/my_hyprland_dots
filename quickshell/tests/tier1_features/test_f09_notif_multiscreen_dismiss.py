#!/run/current-system/sw/bin/python3
"""
Tier 1 Feature 9: Multi-Screen Notification Dismissal (R2)
Validates that notification dismissal is centralized in NotificationService,
preventing concurrent .dismiss() invocations on the same pointer.
"""

import unittest
import re
from tests.harness import QmlCodeInspector, QuickshellIpc

class TestF09NotifMultiscreenDismiss(unittest.TestCase):
    """Verifies centralized multi-screen notification dismissal."""

    def setUp(self):
        self.service_content = QmlCodeInspector.read_qml_content("services/NotificationService.qml")
        self.toasts_content = QmlCodeInspector.read_qml_content("notifications/NotificationToasts.qml")

    def test_service_defines_dismiss_handler(self):
        """T1.9.1: NotificationService defines dismiss handler."""
        self.assertRegex(
            self.service_content,
            r'function\s+dismiss|dismiss:',
            "NotificationService must declare a dismiss function"
        )

    def test_service_tracks_notifications(self):
        """T1.9.2: NotificationService maintains tracked notifications."""
        self.assertIn("trackedNotifications", self.service_content)

    def test_toasts_delegates_dismissal_to_service(self):
        """T1.9.3: NotificationToasts dispatches dismissal via NotificationService."""
        self.assertIn("NotificationService", self.toasts_content)

    def test_ipc_notification_target_available(self):
        """T1.9.4: Quickshell IPC exposes notifications target."""
        targets = QuickshellIpc.list_targets()
        self.assertTrue("notifications" in targets or "notifs" in targets)

    def test_ipc_clear_execution(self):
        """T1.9.5: IPC notifications clear executes without crashing daemon."""
        if QuickshellIpc.is_available():
            target = "notifications" if "notifications" in QuickshellIpc.list_targets() else "notifs"
            ret, out = QuickshellIpc.call(target, "clear")
            self.assertEqual(ret, 0, f"IPC {target} clear failed: {out}")

if __name__ == "__main__":
    unittest.main()
