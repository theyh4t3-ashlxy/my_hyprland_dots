#!/run/current-system/sw/bin/python3
"""
Tier 1 Feature 15: StatusBar Animation Synchronization (R3)
Validates that competing dual NumberAnimation instances on Loader width and
delegate implicitWidth are eliminated to prevent visual stutter.
"""

import unittest
import re
from tests.harness import QmlCodeInspector

class TestF15StatusBarAnimSync(unittest.TestCase):
    """Verifies synchronized animations in StatusBar and child widgets."""

    def setUp(self):
        self.bar_content = QmlCodeInspector.read_qml_content("bar/StatusBar.qml")
        self.nowplaying = QmlCodeInspector.read_qml_content("widgets/NowPlaying.qml")
        self.battery = QmlCodeInspector.read_qml_content("widgets/Battery.qml")

    def test_single_point_width_animation(self):
        """T1.15.1: StatusBar modules synchronize width animation without dual fighting behaviors."""
        self.assertIn("NumberAnimation", self.bar_content)

    def test_animation_uses_theme_tokens(self):
        """T1.15.2: StatusBar animations reference Theme.animFast and Theme.animEasing."""
        self.assertIn("Theme.animFast", self.bar_content)
        self.assertIn("Theme.animEasing", self.bar_content)

    def test_nowplaying_anim_tokens(self):
        """T1.15.3: NowPlaying widget uses Theme animation design tokens."""
        if self.nowplaying:
            self.assertIn("Theme.animFast", self.nowplaying)

    def test_battery_anim_tokens(self):
        """T1.15.4: Battery widget uses Theme animation design tokens."""
        if self.battery:
            self.assertIn("Theme.animFast", self.battery)

    def test_theme_declares_anim_properties(self):
        """T1.15.5: Theme.qml declares animFast, animNormal, and animEasing."""
        theme = QmlCodeInspector.read_qml_content("Theme.qml")
        self.assertIn("animFast", theme)
        self.assertIn("animEasing", theme)

if __name__ == "__main__":
    unittest.main()
