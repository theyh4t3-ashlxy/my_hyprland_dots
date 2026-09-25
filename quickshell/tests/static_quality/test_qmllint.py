#!/run/current-system/sw/bin/python3
"""
Static Quality: qmllint Automated Quality Runner
Executes Qt's official qmllint with Quickshell and QtQuick module paths
across all critical QML components in the repository.
"""

import unittest
from tests.harness import QmlCodeInspector, QMLLINT_BIN

class TestQmlLint(unittest.TestCase):
    """Executes qmllint static validation against QML source files."""

    def test_qmllint_binary_available(self):
        """SQ.1: qmllint binary is available in the environment."""
        self.assertIsNotNone(QMLLINT_BIN, "qmllint binary must be discovered in PATH or Nix store")

    def test_lint_concave_corner(self):
        """SQ.2: corners/ConcaveCorner.qml passes qmllint syntax analysis."""
        if not QMLLINT_BIN:
            self.skipTest("qmllint unavailable")
        code, out = QmlCodeInspector.run_qmllint("corners/ConcaveCorner.qml")
        self.assertEqual(code, 0, f"qmllint failed on ConcaveCorner.qml: {out}")

    def test_lint_screen_corners(self):
        """SQ.3: corners/ScreenCorners.qml passes qmllint syntax analysis."""
        if not QMLLINT_BIN:
            self.skipTest("qmllint unavailable")
        code, out = QmlCodeInspector.run_qmllint("corners/ScreenCorners.qml")
        self.assertEqual(code, 0, f"qmllint failed on ScreenCorners.qml: {out}")

    def test_lint_status_bar(self):
        """SQ.4: bar/StatusBar.qml passes qmllint syntax analysis."""
        if not QMLLINT_BIN:
            self.skipTest("qmllint unavailable")
        code, out = QmlCodeInspector.run_qmllint("bar/StatusBar.qml")
        # Exit code 0 indicates no fatal syntax errors
        self.assertEqual(code, 0, f"qmllint encountered fatal error on StatusBar.qml: {out}")

    def test_lint_quicksettings(self):
        """SQ.5: widgets/QuickSettings.qml passes qmllint syntax analysis."""
        if not QMLLINT_BIN:
            self.skipTest("qmllint unavailable")
        code, out = QmlCodeInspector.run_qmllint("widgets/QuickSettings.qml")
        self.assertEqual(code, 0, f"qmllint failed on QuickSettings.qml: {out}")

if __name__ == "__main__":
    unittest.main()
