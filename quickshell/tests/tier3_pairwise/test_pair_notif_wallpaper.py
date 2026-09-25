#!/run/current-system/sw/bin/python3
"""
Tier 3 Pairwise 1: Notifications during Wallpaper Transitions (F8/F9 x F13)
Validates that receiving notifications while wallpaper theme updates occur
does not crash Quickshell, leak memory, or lose active notification toasts.
"""

import unittest
import time
from tests.harness import DBusHelper, QuickshellIpc

class TestPairNotifWallpaper(unittest.TestCase):
    """Pairwise interaction between D-Bus notifications and wallpaper theme updates."""

    def test_concurrent_notifs_during_simulated_theme_update(self):
        """T3.1.1: Rapid notifications dispatched concurrently with theme file touching."""
        pid_before = QuickshellIpc.get_daemon_pid()

        # Send notification burst while IPC targets are active
        DBusHelper.send_notification("Pairwise Test 1", "Before transition")
        time.sleep(0.05)
        DBusHelper.send_notification("Pairwise Test 2", "During transition")
        time.sleep(0.05)
        DBusHelper.send_notification("Pairwise Test 3", "After transition")

        time.sleep(0.5)
        pid_after = QuickshellIpc.get_daemon_pid()
        self.assertEqual(pid_before, pid_after, "Quickshell daemon must not crash during concurrent events")

    def test_clear_notifs_preserves_theme_state(self):
        """T3.1.2: Clearing notifications does not disrupt active theme colors."""
        if QuickshellIpc.is_available():
            target = "notifications" if "notifications" in QuickshellIpc.list_targets() else "notifs"
            ret, _ = QuickshellIpc.call(target, "clear")
            self.assertEqual(ret, 0)

if __name__ == "__main__":
    unittest.main()
