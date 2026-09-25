#!/run/current-system/sw/bin/python3
"""
Tier 1 Feature 12: Popup Coordinate Safe Navigation (R2)
Validates that unsafe mapToItem(null, 0, 0).[xy] calls are replaced with
optional chaining (?.) across all widget popup positioners to prevent TypeErrors.
"""

import unittest
import re
from tests.harness import QmlCodeInspector

class TestF12PopupSafeNavigation(unittest.TestCase):
    """Verifies safe optional chaining on mapToItem across all widget popups."""

    WIDGET_FILES = [
        "widgets/Workspaces.qml",
        "widgets/QuickNotes.qml",
        "widgets/Clipboard.qml",
        "widgets/Bluetooth.qml",
        "widgets/NetworkStatus.qml",
        "widgets/PowerMenu.qml",
    ]

    def test_no_unsafe_maptoitem_in_workspaces(self):
        """T1.12.1: Workspaces.qml does not contain unchained .x or .y on mapToItem."""
        content = QmlCodeInspector.read_qml_content("widgets/Workspaces.qml")
        unsafe = re.findall(r"mapToItem\([^)]*\)\.[xy]", content)
        self.assertEqual(
            len(unsafe), 0,
            f"Unsafe mapToItem calls found in Workspaces.qml: {unsafe}"
        )

    def test_no_unsafe_maptoitem_in_quicknotes(self):
        """T1.12.2: QuickNotes.qml does not contain unchained .x or .y on mapToItem."""
        content = QmlCodeInspector.read_qml_content("widgets/QuickNotes.qml")
        unsafe = re.findall(r"mapToItem\([^)]*\)\.[xy]", content)
        self.assertEqual(
            len(unsafe), 0,
            f"Unsafe mapToItem calls found in QuickNotes.qml: {unsafe}"
        )

    def test_no_unsafe_maptoitem_in_clipboard(self):
        """T1.12.3: Clipboard.qml does not contain unchained .x or .y on mapToItem."""
        content = QmlCodeInspector.read_qml_content("widgets/Clipboard.qml")
        unsafe = re.findall(r"mapToItem\([^)]*\)\.[xy]", content)
        self.assertEqual(
            len(unsafe), 0,
            f"Unsafe mapToItem calls found in Clipboard.qml: {unsafe}"
        )

    def test_no_unsafe_maptoitem_in_bluetooth_network(self):
        """T1.12.4: Bluetooth.qml and NetworkStatus.qml use optional chaining."""
        bt = QmlCodeInspector.read_qml_content("widgets/Bluetooth.qml")
        net = QmlCodeInspector.read_qml_content("widgets/NetworkStatus.qml")
        unsafe_bt = re.findall(r"mapToItem\([^)]*\)\.[xy]", bt)
        unsafe_net = re.findall(r"mapToItem\([^)]*\)\.[xy]", net)
        self.assertEqual(len(unsafe_bt), 0, f"Unsafe in Bluetooth: {unsafe_bt}")
        self.assertEqual(len(unsafe_net), 0, f"Unsafe in NetworkStatus: {unsafe_net}")

    def test_no_unsafe_maptoitem_in_powermenu(self):
        """T1.12.5: PowerMenu.qml does not contain unchained .x or .y on mapToItem."""
        content = QmlCodeInspector.read_qml_content("widgets/PowerMenu.qml")
        unsafe = re.findall(r"mapToItem\([^)]*\)\.[xy]", content)
        self.assertEqual(
            len(unsafe), 0,
            f"Unsafe mapToItem calls found in PowerMenu.qml: {unsafe}"
        )

if __name__ == "__main__":
    unittest.main()
