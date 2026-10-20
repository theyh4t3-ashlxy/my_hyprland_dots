#!/run/current-system/sw/bin/python3
"""
Tier 1 Feature 23: Universal Hover Flyout & Dynamic Sizing Unification
Validates that HoverFlyoutHandler is registered and wired across all bar widgets
with popup panels, enabling consistent peek-on-hover and pin-on-click interactions.
"""

import unittest
from tests.harness import QmlCodeInspector

class TestF23HoverFlyoutUnification(unittest.TestCase):
    """Verifies universal HoverFlyoutHandler integration across bar widgets."""

    def test_hover_flyout_handler_registered_in_qmldir(self):
        """T1.23.1: HoverFlyoutHandler is registered in qmldir."""
        qmldir = QmlCodeInspector.read_qml_content("qmldir")
        self.assertIn("HoverFlyoutHandler", qmldir)

    def test_hover_flyout_handler_structure(self):
        """T1.23.2: HoverFlyoutHandler provides timers and bindings to Settings."""
        content = QmlCodeInspector.read_qml_content("controls/HoverFlyoutHandler.qml")
        self.assertIn("hoverToOpen", content)
        self.assertIn("openTimer", content)
        self.assertIn("closeTimer", content)
        self.assertIn("cardHovered", content)
        self.assertIn("handlePillClick", content)

    def test_widgets_instantiate_hover_flyout_handler(self):
        """T1.23.3: All bar popup widgets instantiate HoverFlyoutHandler."""
        widgets = [
            "widgets/Battery.qml",
            "widgets/VolumeControl.qml",
            "widgets/Clock.qml",
            "widgets/NetworkStatus.qml",
            "widgets/Bluetooth.qml",
            "widgets/NowPlaying.qml",
            "widgets/Workspaces.qml",
            "widgets/WindowTitle.qml",
            "widgets/QuickSettings.qml",
            "widgets/QuickNotes.qml",
            "widgets/Clipboard.qml",
            "widgets/PowerMenu.qml",
            "widgets/Notifications.qml",
            "widgets/LayoutSwitcher.qml",
        ]
        for w in widgets:
            with self.subTest(widget=w):
                content = QmlCodeInspector.read_qml_content(w)
                self.assertIn("HoverFlyoutHandler", content, f"{w} must instantiate HoverFlyoutHandler")

    def test_popup_panel_dynamic_dimensions(self):
        """T1.23.4: PopupPanel.qml derives dimensions dynamically from activeContentItem."""
        content = QmlCodeInspector.read_qml_content("controls/PopupPanel.qml")
        self.assertIn("activeContentItem", content)
        self.assertIn("dynamicContentWidth", content)
        self.assertIn("dynamicContentHeight", content)
        self.assertIn("implicitWidth", content)
        self.assertIn("implicitHeight", content)

if __name__ == "__main__":
    unittest.main()
