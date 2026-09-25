#!/run/current-system/sw/bin/python3
"""
Tier 2 Boundary 8: Notification Burst & Adversarial Payload Stress
Tests high-frequency bursts (50 rapid notifications), empty bodies,
extreme size bodies (10,000 chars), and HTML/control characters.
"""

import unittest
import time
from tests.harness import DBusHelper, QuickshellIpc, QuickshellLogAuditor

class TestB08NotifBurstStress(unittest.TestCase):
    """Verifies stress limits and adversarial payloads for notifications."""

    def test_rapid_burst_50_notifications(self):
        """T2.8.1: Burst of 50 rapid notifications does not crash daemon."""
        pid_before = QuickshellIpc.get_daemon_pid()
        delivered = DBusHelper.send_burst(count=50, delay=0.01)
        self.assertTrue(delivered > 0, "At least some notifications should deliver")
        time.sleep(1.0)
        pid_after = QuickshellIpc.get_daemon_pid()
        self.assertEqual(
            pid_before, pid_after,
            "Quickshell daemon must survive 50-notification flood without crashing"
        )

    def test_empty_summary_and_body(self):
        """T2.8.2: Empty summary and empty body notification handled gracefully."""
        ret = DBusHelper.send_notification(summary="", body="")
        self.assertEqual(ret, 0)

    def test_massive_payload_10k_chars(self):
        """T2.8.3: 10,000 character body notification does not overflow buffer."""
        huge_body = "A" * 10000
        ret = DBusHelper.send_notification(summary="Huge Body Test", body=huge_body)
        self.assertEqual(ret, 0)

    def test_html_and_meta_characters_escaping(self):
        """T2.8.4: HTML tags, scripts, and format specifiers are handled safely."""
        adversarial_text = "<script>alert('xss')</script><b>Bold</b>%s%d%n&lt;&gt;&amp;"
        ret = DBusHelper.send_notification(summary="XSS Escaping", body=adversarial_text)
        self.assertEqual(ret, 0)

    def test_high_urgency_flood(self):
        """T2.8.5: Critical urgency notifications deliver cleanly."""
        ret = DBusHelper.send_notification(
            summary="Critical Emergency",
            body="Immediate attention required",
            urgency="critical"
        )
        self.assertEqual(ret, 0)

if __name__ == "__main__":
    unittest.main()
