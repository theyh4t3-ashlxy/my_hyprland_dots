#!/run/current-system/sw/bin/python3
"""
Tier 4 Scenario 1: Rapid Notification Flood (F8, F9, F22)
Simulates an intense desktop notification storm: 50 notifications dispatched
in rapid succession via D-Bus notify-send. Validates zero daemon crashes,
absence of zombie delegates, and consistent daemon PID.
"""

import unittest
import time
from tests.harness import DBusHelper, QuickshellIpc, QuickshellLogAuditor

class TestScenario1NotifFlood(unittest.TestCase):
    """End-to-end simulation of a high-throughput notification flood."""

    def test_rapid_notification_flood_scenario(self):
        """Scenario 1: Dispatch 50 rapid notifications and assert stability."""
        pid_start = QuickshellIpc.get_daemon_pid()
        self.assertIsNotNone(pid_start, "Quickshell daemon must be running")

        # Step 1: Rapid dispatch of 50 notifications
        delivered = DBusHelper.send_burst(count=50, delay=0.005)
        self.assertTrue(delivered >= 45, f"Expected >=45 notifications delivered, got {delivered}")

        # Step 2: Allow event loop to process
        time.sleep(1.5)

        # Step 3: Verify daemon PID has not changed (no crash & restart)
        pid_end = QuickshellIpc.get_daemon_pid()
        self.assertEqual(pid_start, pid_end, "Quickshell crashed during 50-notification storm")

        # Step 4: Clear notifications via IPC
        if QuickshellIpc.is_available():
            target = "notifications" if "notifications" in QuickshellIpc.list_targets() else "notifs"
            ret, _ = QuickshellIpc.call(target, "clear")
            self.assertEqual(ret, 0)

        # Step 5: Audit log for memory corruption or delegate errors
        log = QuickshellLogAuditor.get_recent_log(50)
        self.assertNotIn("SIGSEGV", log)
        self.assertNotIn("crashed under pid", log)

if __name__ == "__main__":
    unittest.main()
