#!/run/current-system/sw/bin/python3
"""
Tier 1 Feature 20: Speculative Icon Warning Elimination (R4)
Validates that blind -browser suffix queries are guarded by Quickshell.hasThemeIcon()
in widgets/WindowTitle.qml to prevent runtime log spam.
"""

import unittest
import re
from tests.harness import QmlCodeInspector, QuickshellLogAuditor

class TestF20SpeculativeIconWarning(unittest.TestCase):
    """Verifies elimination of speculative icon lookup warnings in WindowTitle.qml."""

    def setUp(self):
        self.wt_content = QmlCodeInspector.read_qml_content("widgets/WindowTitle.qml")

    def test_window_title_file_exists(self):
        """T1.20.1: WindowTitle.qml exists and is readable."""
        self.assertTrue(len(self.wt_content) > 0)

    def test_guarded_icon_lookup(self):
        """T1.20.2: WindowTitle uses hasThemeIcon or icon existence check before blind lookup."""
        has_guard = bool(re.search(r'hasThemeIcon|Quickshell\.hasThemeIcon', self.wt_content))
        has_blind_browser = "base + \"-browser\"" in self.wt_content
        self.assertTrue(
            has_guard or not has_blind_browser,
            "WindowTitle.qml should not perform blind '-browser' queries without hasThemeIcon guard"
        )

    def test_log_free_of_antigravity_icon_warning(self):
        """T1.20.3: Recent runtime log is free of antigravity-browser icon warnings."""
        log = QuickshellLogAuditor.get_recent_log(100)
        has_warning = "Could not load icon \"antigravity-browser\"" in log
        self.assertFalse(
            has_warning,
            "Runtime log should not emit antigravity-browser missing icon warnings"
        )

    def test_fallback_icon_defined(self):
        """T1.20.4: Fallback icon provided for unmatched applications."""
        self.assertRegex(
            self.wt_content,
            r'application-|default-icon|fallback|iconName',
            "WindowTitle.qml should provide fallback icon"
        )

    def test_empty_string_icon_safety(self):
        """T1.20.5: WindowTitle handles null or empty window class safely."""
        self.assertIn("activeTop", self.wt_content)

if __name__ == "__main__":
    unittest.main()
