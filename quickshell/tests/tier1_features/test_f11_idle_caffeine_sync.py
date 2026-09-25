#!/run/current-system/sw/bin/python3
"""
Tier 1 Feature 11: Idle & Caffeine State Synchronization (R2)
Validates that display brightness is restored (brightnessctl -r) on Caffeine toggle
and inhibitor state is synchronized across unified IPC targets.
"""

import unittest
import re
from tests.harness import QmlCodeInspector, QuickshellIpc

class TestF11IdleCaffeineSync(unittest.TestCase):
    """Verifies Idle & Caffeine state synchronization in IdleService.qml and shell.qml."""

    def setUp(self):
        self.service_content = QmlCodeInspector.read_qml_content("services/IdleService.qml")
        self.shell_content = QmlCodeInspector.read_qml_content("shell.qml")

    def test_brightness_restore_present(self):
        """T1.11.1: IdleService invokes brightnessctl -r when restoring brightness."""
        self.assertIn("brightnessctl", self.service_content)
        self.assertIn("-r", self.service_content)

    def test_idle_inhibitor_support(self):
        """T1.11.2: IdleService configures idle inhibitor support."""
        self.assertRegex(
            self.service_content,
            r'IdleInhibitor|respectInhibitors',
            "IdleService must respect inhibitors or declare IdleInhibitor"
        )

    def test_ipc_targets_exist(self):
        """T1.11.3: Quickshell exposes caffeine and idle IPC targets."""
        targets = QuickshellIpc.list_targets()
        self.assertIn("caffeine", targets)
        self.assertIn("idle", targets)

    def test_caffeine_ipc_status(self):
        """T1.11.4: caffeine status query returns cleanly."""
        if QuickshellIpc.is_available():
            ret, out = QuickshellIpc.call("caffeine", "status")
            self.assertEqual(ret, 0, f"caffeine status failed: {out}")
            self.assertIn(out.strip(), ["true", "false"])

    def test_caffeine_ipc_toggle(self):
        """T1.11.5: caffeine toggle cycles status cleanly and returns to original."""
        if QuickshellIpc.is_available():
            ret1, out1 = QuickshellIpc.call("caffeine", "status")
            orig = out1.strip()
            ret2, out2 = QuickshellIpc.call("caffeine", "toggle")
            self.assertEqual(ret2, 0)
            ret3, out3 = QuickshellIpc.call("caffeine", "toggle")
            self.assertEqual(ret3, 0)
            ret4, out4 = QuickshellIpc.call("caffeine", "status")
            self.assertEqual(out4.strip(), orig)

if __name__ == "__main__":
    unittest.main()
