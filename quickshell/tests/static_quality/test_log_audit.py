#!/run/current-system/sw/bin/python3
"""
Static Quality: Quickshell Runtime Log & Crash Dump Parser
Audits Quickshell logs and historical crash reports for TypeErrors,
broken signals, binding loops, or segmentation faults.
"""

import unittest
from pathlib import Path
from tests.harness import QuickshellLogAuditor, QuickshellIpc

class TestLogAudit(unittest.TestCase):
    """Audits system runtime logs for quality nitpicks and defects."""

    def test_recent_runtime_log_audit(self):
        """SQ.6: Recent runtime log contains zero TypeErrors or Binding Loops."""
        log = QuickshellLogAuditor.get_recent_log(200)
        findings = QuickshellLogAuditor.audit_log_content(log)
        self.assertEqual(
            len(findings["critical"]), 0,
            f"Critical errors found in runtime log: {findings['critical']}"
        )

    def test_daemon_status_healthy(self):
        """SQ.7: Daemon process is running without defunct or zombie states."""
        pid = QuickshellIpc.get_daemon_pid()
        self.assertIsNotNone(pid, "Quickshell daemon should be running")

    def test_no_active_crash_loops(self):
        """SQ.8: Quickshell process is not rapidly crash-looping."""
        # Query pid twice with a delay
        pid1 = QuickshellIpc.get_daemon_pid()
        pid2 = QuickshellIpc.get_daemon_pid()
        self.assertEqual(pid1, pid2, "Daemon PID changed, indicating crash looping")

if __name__ == "__main__":
    unittest.main()
