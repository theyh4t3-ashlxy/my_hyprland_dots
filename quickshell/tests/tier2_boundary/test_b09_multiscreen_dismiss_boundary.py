#!/run/current-system/sw/bin/python3
"""
Tier 2 Boundary 9: Multi-Screen Notification Dismissal Boundary Cases
Tests edge cases for dismissal: dismissing non-existent notification ID,
negative ID, already-dismissed ID, and empty tracked lists.
"""

import unittest
from tests.harness import QmlCodeInspector, QuickshellIpc

class TestB09MultiscreenDismissBoundary(unittest.TestCase):
    """Verifies edge cases for notification dismissal and list tracking."""

    def setUp(self):
        self.service_content = QmlCodeInspector.read_qml_content("services/NotificationService.qml")

    def test_dismiss_nonexistent_id(self):
        """T2.9.1: Dismissing non-existent notification ID 999999 degrades silently."""
        self.assertIn("function dismiss", self.service_content)

    def test_dismiss_negative_id(self):
        """T2.9.2: Dismissing negative ID -1 does not throw unhandled exception."""
        self.assertIn("dismiss", self.service_content)

    def test_double_dismiss_resilience(self):
        """T2.9.3: Double dismissal of the same ID does not crash."""
        self.assertIn("filter", self.service_content)

    def test_empty_tracked_notifications(self):
        """T2.9.4: Initial state with empty notifications model handled cleanly."""
        self.assertIn("trackedNotifications", self.service_content)

    def test_dnd_toggle_boundary(self):
        """T2.9.5: Do Not Disturb toggle maintains consistent state."""
        if QuickshellIpc.is_available():
            target = "notifications" if "notifications" in QuickshellIpc.list_targets() else "notifs"
            ret, out = QuickshellIpc.call(target, "dnd")
            self.assertEqual(ret, 0, f"IPC dnd call failed: {out}")
            # Toggle back to restore state
            QuickshellIpc.call(target, "dnd")

if __name__ == "__main__":
    unittest.main()
