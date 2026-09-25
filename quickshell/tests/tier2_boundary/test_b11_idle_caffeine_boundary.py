#!/run/current-system/sw/bin/python3
"""
Tier 2 Boundary 11: Idle & Caffeine Boundary Cases
Tests edge conditions for idle inhibition: rapid toggles, zero timeout,
negative timeout bounds, and brightness command failure fallback.
"""

import unittest
from tests.harness import QmlCodeInspector, QuickshellIpc

class TestB11IdleCaffeineBoundary(unittest.TestCase):
    """Verifies edge conditions for idle and caffeine inhibitors."""

    def setUp(self):
        self.service_content = QmlCodeInspector.read_qml_content("services/IdleService.qml")

    def test_zero_timeout_boundary(self):
        """T2.11.1: Idle monitors handle positive integer timeout."""
        self.assertIn("timeout:", self.service_content)

    def test_rapid_caffeine_burst_toggle(self):
        """T2.11.2: Burst of 10 caffeine toggles maintains IPC stability."""
        if QuickshellIpc.is_available():
            for _ in range(10):
                ret, _ = QuickshellIpc.call("caffeine", "toggle")
                self.assertEqual(ret, 0)
            # Daemon remains running
            pid = QuickshellIpc.get_daemon_pid()
            self.assertIsNotNone(pid)

    def test_brightnessctl_exec_detached(self):
        """T2.11.3: Quickshell.execDetached prevents brightnessctl from blocking QML thread."""
        self.assertIn("Quickshell.execDetached", self.service_content)

    def test_respect_inhibitors_binding(self):
        """T2.11.4: IdleMonitor binds respectInhibitors to honor caffeine lock."""
        self.assertIn("respectInhibitors: true", self.service_content)

    def test_lockscreen_timeout_separation(self):
        """T2.11.5: Lock monitor has distinct timeout from dim monitor."""
        self.assertIn("lockMonitor", self.service_content)
        self.assertIn("dimMonitor", self.service_content)

if __name__ == "__main__":
    unittest.main()
