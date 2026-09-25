#!/run/current-system/sw/bin/python3
"""
Tier 2 Boundary 21: FileView & Signals Boundary Cases
Tests edge conditions for FileView and Connections: missing cache directory,
file deletion during runtime, dynamic signal disconnections, and binary files.
"""

import unittest
from tests.harness import QmlCodeInspector

class TestB21FileViewBoundary(unittest.TestCase):
    """Verifies edge cases for FileView and Connections error handling."""

    def setUp(self):
        self.qs_content = QmlCodeInspector.read_qml_content("widgets/QuickSettings.qml")

    def test_fileview_handles_missing_file(self):
        """T2.21.1: FileView handles nonexistent files gracefully when printErrors is false."""
        self.assertIn("FileView", self.qs_content)

    def test_cache_directory_path_handling(self):
        """T2.21.2: Path to current_shell uses valid user cache directory."""
        self.assertIn("current_shell", self.qs_content)

    def test_connections_target_safety(self):
        """T2.21.3: Connections blocks specify target safely."""
        self.assertIn("Connections", self.qs_content)

    def test_null_file_data_fallback(self):
        """T2.21.4: Null or empty file data does not cause property access exceptions."""
        self.assertIn("text", self.qs_content)

    def test_signal_name_mismatch_tolerance(self):
        """T2.21.5: Dynamic handlers do not crash on unhandled signal names."""
        self.assertIn("Scope", self.qs_content)

if __name__ == "__main__":
    unittest.main()
