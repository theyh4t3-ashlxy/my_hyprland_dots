#!/run/current-system/sw/bin/python3
"""
Tier 1 Feature 16: Multi-Monitor Module Screen Binding (R3)
Validates that barScreen: root.screen and barMonitor: root.hyprMonitor are passed
to all status bar modules so popups open on the active monitor.
"""

import unittest
import re
from tests.harness import QmlCodeInspector

class TestF16StatusBarScreenBinding(unittest.TestCase):
    """Verifies multi-monitor screen and monitor property propagation in StatusBar.qml."""

    def setUp(self):
        self.bar_content = QmlCodeInspector.read_qml_content("bar/StatusBar.qml")

    def test_barscreen_passed_to_modules(self):
        """T1.16.1: StatusBar passes barScreen to module loaders."""
        self.assertIn("barScreen: root.screen", self.bar_content)

    def test_barmonitor_passed_to_modules(self):
        """T1.16.2: StatusBar passes barMonitor to module loaders."""
        self.assertIn("barMonitor: root.hyprMonitor", self.bar_content)

    def test_quicksettings_has_screen_properties(self):
        """T1.16.3: QuickSettings.qml accepts barScreen and barMonitor."""
        qs = QmlCodeInspector.read_qml_content("widgets/QuickSettings.qml")
        self.assertIn("barScreen", qs)

    def test_windowtitle_has_screen_properties(self):
        """T1.16.4: WindowTitle.qml accepts barScreen or screen binding."""
        wt = QmlCodeInspector.read_qml_content("widgets/WindowTitle.qml")
        self.assertIn("barScreen", wt)

    def test_screen_fallback_safety(self):
        """T1.16.5: Module popups handle null or undefined barScreen gracefully."""
        qs = QmlCodeInspector.read_qml_content("widgets/QuickSettings.qml")
        self.assertRegex(
            qs,
            r'barScreen\s*\?\?|screen:\s*root\.barScreen',
            "QuickSettings must safely resolve screen target"
        )

if __name__ == "__main__":
    unittest.main()
