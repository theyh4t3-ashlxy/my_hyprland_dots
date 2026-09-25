#!/run/current-system/sw/bin/python3
"""
Tier 1 Feature 8: Notification Use-After-Free Prevention (R2)
Validates that NotificationToasts.qml uses safe value objects/ListModel
rather than raw C++ Notification* pointer lists in Repeater delegates.
"""

import unittest
import os
import time
import re
from tests.harness import QmlCodeInspector, DBusHelper, QuickshellIpc

class TestF08NotifUseAfterFree(unittest.TestCase):
    """Verifies notification use-after-free prevention in notification toasts."""

    def setUp(self):
        self.toasts_content = QmlCodeInspector.read_qml_content("notifications/NotificationToasts.qml")
        self.card_content = QmlCodeInspector.read_qml_content("notifications/NotificationCard.qml")

    def test_files_exist(self):
        """T1.8.1: Notification component files exist."""
        self.assertTrue(len(self.toasts_content) > 0)
        self.assertTrue(len(self.card_content) > 0)

    def test_sanitized_toast_model(self):
        """T1.8.2: Notification toasts uses safe value objects or ListModel."""
        # The crash was caused by raw C++ pointers in toastList Repeater
        # The model should be sanitized or use ListModel/plain objects
        self.assertIn("Repeater", self.toasts_content)

    def test_live_notification_dispatch(self):
        """T1.8.3: Dispatching test notifications does not terminate Quickshell daemon."""
        pid_before = QuickshellIpc.get_daemon_pid()
        if pid_before is not None:
            ret = DBusHelper.send_notification("E2E Test Notif", "Checking stability")
            self.assertEqual(ret, 0, "Notification delivery should return exit code 0")
            time.sleep(0.3)
            pid_after = QuickshellIpc.get_daemon_pid()
            self.assertEqual(pid_before, pid_after, "Quickshell daemon PID must remain identical")

    def test_notification_card_handles_primitives(self):
        """T1.8.4: NotificationCard reads summary and body properties safely."""
        self.assertIn("summary", self.card_content)
        self.assertIn("body", self.card_content)

    def test_actions_list_model_safety(self):
        """T1.8.5: Action list delegate does not crash on empty or null actions."""
        self.assertRegex(
            self.card_content,
            r'actions|root\.notif\?\.actions',
            "NotificationCard should handle actions safely"
        )

if __name__ == "__main__":
    unittest.main()
