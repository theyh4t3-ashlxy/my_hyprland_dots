#!/run/current-system/sw/bin/python3
"""
Tier 1 Feature 22: Static QML Lint & Log Verification (R4)
Validates that runtime log stream is free of binding loops, TypeErrors,
broken signal connections, and process crashes.
"""

import unittest
from tests.harness import QuickshellLogAuditor, QuickshellIpc

class TestF22StaticLintLogClean(unittest.TestCase):
    """Verifies runtime log stream cleanliness and absence of critical exceptions."""

    def setUp(self):
        self.log_text = QuickshellLogAuditor.get_recent_log(150)
        self.audit = QuickshellLogAuditor.audit_log_content(self.log_text)

    def test_daemon_is_running(self):
        """T1.22.1: Quickshell daemon is running with active PID."""
        pid = QuickshellIpc.get_daemon_pid()
        self.assertIsNotNone(pid, "Quickshell daemon should be running")

    def test_no_binding_loops(self):
        """T1.22.2: Log is free of 'Binding loop detected' errors."""
        binding_loops = [l for l in self.log_text.splitlines() if "binding loop" in l.lower()]
        self.assertEqual(len(binding_loops), 0, f"Binding loops found: {binding_loops}")

    def test_no_type_errors(self):
        """T1.22.3: Log is free of 'TypeError' exceptions."""
        type_errors = [l for l in self.log_text.splitlines() if "typeerror" in l.lower()]
        self.assertEqual(len(type_errors), 0, f"TypeErrors found: {type_errors}")

    def test_no_reference_errors(self):
        """T1.22.4: Log is free of 'ReferenceError' exceptions."""
        ref_errors = [l for l in self.log_text.splitlines() if "referenceerror" in l.lower()]
        self.assertEqual(len(ref_errors), 0, f"ReferenceErrors found: {ref_errors}")

    def test_no_crash_signatures(self):
        """T1.22.5: Log is free of crash signatures or SIGSEGV."""
        crash_lines = [l for l in self.log_text.splitlines() if "crashed under pid" in l.lower() or "sigsegv" in l.lower()]
        self.assertEqual(len(crash_lines), 0, f"Crash signatures found: {crash_lines}")

if __name__ == "__main__":
    unittest.main()
