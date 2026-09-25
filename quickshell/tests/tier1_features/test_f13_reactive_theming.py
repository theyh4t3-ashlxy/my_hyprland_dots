#!/run/current-system/sw/bin/python3
"""
Tier 1 Feature 13: Reactive Zero-Restart Theming (R3)
Validates that Theme.qml reactively watches palette data via FileView and that
touch shell.qml reload triggers are eliminated from wallpaper scripts and hooks.
"""

import unittest
import re
from pathlib import Path
from tests.harness import QmlCodeInspector, REPO_ROOT

class TestF13ReactiveTheming(unittest.TestCase):
    """Verifies reactive zero-restart theming pipeline."""

    def setUp(self):
        self.theme_content = QmlCodeInspector.read_qml_content("Theme.qml")
        self.wallpaper_script = (REPO_ROOT / "scripts" / "wallpaper.py").read_text(encoding="utf-8") if (REPO_ROOT / "scripts" / "wallpaper.py").exists() else ""
        matugen_conf = REPO_ROOT.parent / "matugen" / "config.toml"
        self.matugen_content = matugen_conf.read_text(encoding="utf-8") if matugen_conf.exists() else ""

    def test_theme_watches_palette(self):
        """T1.13.1: Theme.qml watches palette.css or colors.json."""
        has_watcher = bool(re.search(r'FileView|palette\.css|colors\.json', self.theme_content))
        self.assertTrue(has_watcher, "Theme.qml should reactively watch dynamic palette files")

    def test_wallpaper_script_no_touch_shell(self):
        """T1.13.2: scripts/wallpaper.py does not execute shell_qml.touch()."""
        if self.wallpaper_script:
            has_touch = "shell_qml.touch()" in self.wallpaper_script
            self.assertFalse(
                has_touch,
                "scripts/wallpaper.py should not touch shell.qml, avoiding reload churn"
            )

    def test_matugen_hook_no_touch_shell(self):
        """T1.13.3: matugen/config.toml does not execute touch shell.qml."""
        if self.matugen_content:
            has_touch = "touch ~/.config/quickshell/shell.qml" in self.matugen_content
            self.assertFalse(
                has_touch,
                "matugen/config.toml post_hook should not touch shell.qml"
            )

    def test_theme_exposes_core_colors(self):
        """T1.13.4: Theme.qml defines core semantic color properties."""
        self.assertIn("primary", self.theme_content)
        self.assertIn("barBg", self.theme_content)
        self.assertIn("cornerFill", self.theme_content)

    def test_palette_css_exists_and_readable(self):
        """T1.13.5: palette.css exists and defines standard CSS color variables."""
        css_path = REPO_ROOT / "palette.css"
        self.assertTrue(css_path.exists(), "palette.css should exist in repository root")
        css_text = css_path.read_text(encoding="utf-8")
        self.assertIn("--primary:", css_text)

if __name__ == "__main__":
    unittest.main()
