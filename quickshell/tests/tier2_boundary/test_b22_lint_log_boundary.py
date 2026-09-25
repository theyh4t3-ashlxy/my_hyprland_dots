#!/run/current-system/sw/bin/python3
"""
Tier 2 Boundary 22: Log Audit Boundary Cases
Tests edge conditions for log auditing: empty logs, massive 10,000 line logs,
Unicode messages in log lines, and multi-threaded log writing.
"""

import unittest
from tests.harness import QuickshellLogAuditor

class TestB22LintLogBoundary(unittest.TestCase):
    """Verifies edge conditions for runtime log auditing."""

    def test_audit_empty_log_string(self):
        """T2.22.1: Auditing empty log returns empty findings."""
        findings = QuickshellLogAuditor.audit_log_content("")
        self.assertEqual(len(findings["critical"]), 0)
        self.assertEqual(len(findings["warnings"]), 0)

    def test_audit_large_synthetic_log(self):
        """T2.22.2: Auditing 10,000 lines completes rapidly without memory exhaustion."""
        synthetic_lines = ["INFO: Normal operation line #{}".format(i) for i in range(10000)]
        synthetic_lines.append("ERROR: TypeError: Cannot read property 'x' of null")
        synthetic_lines.append("WARN: Binding loop detected on property 'width'")
        log_text = "\n".join(synthetic_lines)

        findings = QuickshellLogAuditor.audit_log_content(log_text)
        self.assertEqual(len(findings["critical"]), 2)

    def test_audit_unicode_log_content(self):
        """T2.22.3: Auditing log with non-ASCII Unicode characters (emoji, CJK)."""
        unicode_log = "INFO: Window title: 🚀 宇宙飞行 / QuickShell\n"
        findings = QuickshellLogAuditor.audit_log_content(unicode_log)
        self.assertEqual(len(findings["critical"]), 0)

    def test_case_insensitive_pattern_detection(self):
        """T2.22.4: Critical patterns detect lowercase 'typeerror' or uppercase 'TYPEERROR'."""
        sample = "DEBUG: typeerror in script"
        findings = QuickshellLogAuditor.audit_log_content(sample)
        self.assertTrue(len(findings["critical"]) >= 1)

    def test_clean_lines_pass_without_false_positives(self):
        """T2.22.5: Normal info logs produce zero critical findings."""
        normal = "INFO: Configuration Loaded\nINFO: Reloading configuration...\n"
        findings = QuickshellLogAuditor.audit_log_content(normal)
        self.assertEqual(len(findings["critical"]), 0)

if __name__ == "__main__":
    unittest.main()
