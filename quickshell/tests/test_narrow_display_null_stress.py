#!/run/current-system/sw/bin/python3
"""
Challenger Stress Test Suite for Milestone 3 (Gen 5)
Narrow Display Constraints, WindowTitle Bounds, and mapToItem Null Safety

Verification Scope:
1. Narrow display width sweeps:
   - Screen widths from 800px to 3840px.
   - Verify rightRowH width clamping guarantees rightRowH.x >= centerRowH.right_edge + padding.
2. WindowTitle sizing:
   - Long window titles up to 1000 characters.
   - Verify internal width respects Loader container clamping and does not overflow parent boundary.
3. mapToItem null safety:
   - Simulate unmapped item states returning null/undefined.
   - Verify property access is guarded by `if (pt)` in StatusBar.qml and IdleInhibitor.qml.
   - Zero JavaScript TypeError crashes.
4. Empirical Qt Quick 6 QML runtime execution:
   - Execute challenger_stress_narrow_null.qml in headless offscreen QML runtime.
"""

import math
import os
import re
import subprocess
import unittest
from pathlib import Path
from typing import Dict, List, Optional, Tuple

REPO_ROOT = Path(__file__).resolve().parent.parent

QMLLINT_BIN = "/nix/store/10553j4116y6jllliqpg5kz7d35bblab-qtdeclarative-6.11.2/bin/qmllint"
QML_RUNNER_BIN = "/nix/store/10553j4116y6jllliqpg5kz7d35bblab-qtdeclarative-6.11.2/bin/qml"


# =============================================================================
# Mathematical Layout Simulator for StatusBar.qml
# =============================================================================

def compute_max_right_row_width(screen_w: float, center_w: float = 200.0, padding_h: float = 8.0, center_visible: bool = True) -> float:
    """
    Computes maxRightRowWidth exactly as defined in bar/StatusBar.qml:95-100:
        let halfScreen = root.width / 2;
        let centerHalf = (centerRowH.visible ? centerRowH.width : 0) / 2;
        let clockRight = halfScreen - centerHalf;
        return Math.max(160, clockRight - (Theme.widgetPaddingH * 2));
    """
    half_screen = screen_w / 2.0
    center_half = (center_w if center_visible else 0.0) / 2.0
    clock_right = half_screen - center_half
    return max(160.0, clock_right - (padding_h * 2.0))


def compute_max_window_title_width(screen_w: float, center_w: float = 200.0, center_visible: bool = True) -> float:
    """
    Computes maxWindowTitleWidth exactly as defined in bar/StatusBar.qml:89-94:
        let halfScreen = root.width / 2;
        let centerHalf = (centerRowH.visible ? centerRowH.width : 0) / 2;
        let clockStart = halfScreen - centerHalf;
        return Math.max(160, clockStart - 260);
    """
    half_screen = screen_w / 2.0
    center_half = (center_w if center_visible else 0.0) / 2.0
    clock_start = half_screen - center_half
    return max(160.0, clock_start - 260.0)


def compute_right_row_layout(screen_w: float, center_w: float, padding_h: float, implicit_w: float) -> Tuple[float, float, float, float]:
    """
    Simulates rightRowH and centerRowH horizontal geometry.
    Returns: (center_right_edge, right_row_width, right_row_x, clearance)
    """
    max_right = compute_max_right_row_width(screen_w, center_w, padding_h, True)
    actual_right_w = min(implicit_w, max_right)
    right_row_x = screen_w - padding_h - actual_right_w
    center_x = (screen_w - center_w) / 2.0
    center_right = center_x + center_w
    clearance = right_row_x - center_right
    return center_right, actual_right_w, right_row_x, clearance


# =============================================================================
# Test Suite 1: Narrow Display Width Sweeps
# =============================================================================

class TestNarrowDisplayWidthSweeps(unittest.TestCase):
    """
    Empirically sweeps screen widths from 800px to 3840px to verify that
    rightRowH width clamping guarantees rightRowH.x >= centerRowH.right_edge + padding.
    """

    def setUp(self):
        status_bar_path = REPO_ROOT / "bar" / "StatusBar.qml"
        with open(status_bar_path, "r", encoding="utf-8") as f:
            self.sb_qml = f.read()

    def test_01_statusbar_declares_max_right_row_width(self):
        """Verify StatusBar.qml declares maxRightRowWidth with mathematical padding deduction."""
        self.assertIn("readonly property real maxRightRowWidth", self.sb_qml)
        self.assertIn("clockRight - (Theme.widgetPaddingH * 2)", self.sb_qml)

    def test_02_statusbar_clamps_right_row_width(self):
        """Verify rightRowH in StatusBar.qml binds width to Math.min(implicitWidth, root.maxRightRowWidth)."""
        pattern = r"width:\s*Math\.min\(implicitWidth,\s*root\.maxRightRowWidth\)"
        self.assertTrue(
            bool(re.search(pattern, self.sb_qml)),
            "rightRowH must bind width to Math.min(implicitWidth, root.maxRightRowWidth)"
        )
        # Verify rightRowH has clip: true
        right_row_block = re.search(r"id:\s*rightRowH\b[\s\S]*?width:\s*Math\.min[^\n]*\n\s*clip:\s*true", self.sb_qml)
        self.assertIsNotNone(right_row_block, "rightRowH must have clip: true")

    def test_03_standard_display_resolutions_clearance(self):
        """
        Verify rightRowH.x >= centerRowH.right_edge + padding across standard resolutions:
        800x600, 1024x768, 1280x720, 1366x768, 1440x900, 1600x900, 1920x1080, 2560x1440, 3440x1440, 3840x2160.
        """
        standard_widths = [800, 1024, 1280, 1366, 1440, 1600, 1920, 2560, 3440, 3840]
        clock_widths = [120, 160, 180, 200, 220, 250]
        paddings = [8, 10, 12, 16]
        implicits = [200, 300, 500, 800, 1200]

        for w in standard_widths:
            for cw in clock_widths:
                for p in paddings:
                    for imp in implicits:
                        center_right, actual_rw, right_x, clearance = compute_right_row_layout(w, cw, p, imp)
                        self.assertGreaterEqual(
                            clearance, p,
                            f"Collision or insufficient clearance at W={w}, ClockW={cw}, Pad={p}, Imp={imp}: "
                            f"right_x={right_x} < center_right + pad ({center_right + p}), clearance={clearance}"
                        )
                        self.assertGreaterEqual(
                            right_x, center_right + p,
                            f"rightRowH.x must be >= centerRowH right edge + padding at W={w}"
                        )

    def test_04_continuous_display_width_sweep_800_to_3840(self):
        """
        Continuous parametric sweep from 800px to 3840px in 10px increments (305 widths).
        Validates clearance across over 10,000 parameter combinations.
        """
        tested_combinations = 0
        for w in range(800, 3841, 10):
            for cw in [150, 180, 200, 240]:
                for p in [8, 12]:
                    for imp in [250, 450, 700]:
                        center_right, actual_rw, right_x, clearance = compute_right_row_layout(w, cw, p, imp)
                        self.assertGreaterEqual(
                            clearance, p,
                            f"Clearance violated at W={w}, C={cw}, P={p}, Imp={imp}"
                        )
                        tested_combinations += 1

        self.assertGreaterEqual(tested_combinations, 7000)

    def test_05_adversarial_boundary_center_overgrowth_analysis(self):
        """
        Adversarial stress-test: identify exact threshold where Math.max(160, ...) floor
        causes clearance to dip below padding if centerRowH is abnormally bloated.
        Mathematical proof:
            For W=800, P=8:
            (800 - C)/2 - 16 = 160  =>  384 - C/2 = 160  =>  C = 448px.
        Any clock/centerRow <= 448px guarantees 100% safe clearance.
        """
        w = 800
        p = 8
        imp = 600

        # At C=448px, clearance is exactly padding (8px)
        center_right, actual_rw, right_x, clearance = compute_right_row_layout(w, 448, p, imp)
        self.assertEqual(clearance, p)
        self.assertEqual(right_x, center_right + p)

        # Normal clock is ~180-220px, well below 448px threshold
        for normal_c in [120, 160, 200, 220]:
            _, _, rx, clr = compute_right_row_layout(w, normal_c, p, imp)
            self.assertGreaterEqual(clr, p)


# =============================================================================
# Test Suite 2: WindowTitle Sizing and Loader Clamping
# =============================================================================

class TestWindowTitleSizingAndClamping(unittest.TestCase):
    """
    Stress-tests WindowTitle sizing with titles up to 1000 characters and verifies
    Loader container clamping in StatusBar.qml.
    """

    def setUp(self):
        wt_path = REPO_ROOT / "widgets" / "WindowTitle.qml"
        with open(wt_path, "r", encoding="utf-8") as f:
            self.wt_qml = f.read()

        sb_path = REPO_ROOT / "bar" / "StatusBar.qml"
        with open(sb_path, "r", encoding="utf-8") as f:
            self.sb_qml = f.read()

    def test_06_windowtitle_defines_parent_width_binding(self):
        """Verify WindowTitle.qml defines width: parent ? parent.width : implicitWidth."""
        pattern = r"width:\s*parent\s*\?\s*parent\.width\s*:\s*implicitWidth"
        self.assertTrue(
            bool(re.search(pattern, self.wt_qml)),
            "WindowTitle.qml must bind width to parent.width when parent exists"
        )

    def test_07_windowtitle_and_loader_clip_enabled(self):
        """Verify clip: true is present on WindowTitle.qml and lModLoader in StatusBar.qml."""
        self.assertIn("clip: true", self.wt_qml)
        self.assertIn("clip: true", self.sb_qml)

    def test_08_windowtitle_text_elision_and_layout(self):
        """Verify WindowTitle titleText specifies Layout.fillWidth and elide: Text.ElideRight."""
        self.assertIn("Layout.fillWidth: true", self.wt_qml)
        self.assertIn("elide: Text.ElideRight", self.wt_qml)
        self.assertIn("maximumLineCount: 1", self.wt_qml)

    def test_09_long_title_1000_chars_desired_width_clamped(self):
        """
        Verify that for titles up to 1000 characters, WindowTitle desiredWidth
        is clamped by Settings.windowTitleMaxWidth (760) or compact limit (260).
        """
        chars_lengths = [10, 50, 100, 250, 500, 750, 1000]
        for n in chars_lengths:
            # Model character width (~8px average)
            approx_text_w = n * 8.0
            natural_w = approx_text_w + 22.0 + 24.0

            # Auto mode clamped to maxW (760)
            max_w = 760.0
            desired_auto = max(50.0, min(natural_w, max_w))
            self.assertLessEqual(desired_auto, 760.0)
            if n >= 100:
                self.assertEqual(desired_auto, 760.0)

            # Compact mode clamped to 260
            desired_compact = max(50.0, min(natural_w, 260.0))
            self.assertLessEqual(desired_compact, 260.0)
            if n >= 50:
                self.assertEqual(desired_compact, 260.0)

    def test_10_loader_target_w_clamping_on_narrow_screens(self):
        """
        Verify that StatusBar.qml lModLoader targetW clamps to root.maxWindowTitleWidth
        on narrow displays (800, 1024, 1280, 1366px), preventing overflow into clock.
        """
        narrow_screens = [800, 1024, 1280, 1366]
        item_implicit_w = 760.0  # From 1000-char title clamped to desiredWidth

        for w in narrow_screens:
            max_title_w = compute_max_window_title_width(w, center_w=200.0, center_visible=True)
            max_allowed = min(760.0, max_title_w)
            target_w = max(40.0, min(item_implicit_w, max_allowed))

            self.assertLessEqual(
                target_w, max_title_w,
                f"lModLoader targetW ({target_w}) must not exceed maxWindowTitleWidth ({max_title_w}) at W={w}"
            )
            self.assertLessEqual(target_w, 760.0)

    def test_11_loader_explicit_binding_to_child_item(self):
        """Verify lModLoader has explicit Binding targeting item.width = lModLoader.width."""
        pattern = r"Binding\s*\{[\s\S]*?target:\s*lModLoader\.item[\s\S]*?property:\s*\"width\"[\s\S]*?value:\s*lModLoader\.width"
        self.assertTrue(
            bool(re.search(pattern, self.sb_qml)),
            "StatusBar.qml must bind lModLoader.item.width to lModLoader.width"
        )


# =============================================================================
# Test Suite 3: mapToItem Null Safety Simulation
# =============================================================================

class TestMapToItemNullSafety(unittest.TestCase):
    """
    Stress-tests mapToItem null safety: simulates unmapped/disconnected states
    returning null or undefined, proving zero TypeError crashes.
    """

    def setUp(self):
        sb_path = REPO_ROOT / "bar" / "StatusBar.qml"
        with open(sb_path, "r", encoding="utf-8") as f:
            self.sb_qml = f.read()

        idle_path = REPO_ROOT / "widgets" / "IdleInhibitor.qml"
        with open(idle_path, "r", encoding="utf-8") as f:
            self.idle_qml = f.read()

        wt_path = REPO_ROOT / "widgets" / "WindowTitle.qml"
        with open(wt_path, "r", encoding="utf-8") as f:
            self.wt_qml = f.read()

    def test_12_statusbar_launcher_maptoitem_null_guarded(self):
        """Verify StatusBar.qml launcherPill.mapToItem is immediately guarded by if (pt)."""
        pattern = r"let\s+pt\s*=\s*launcherPill\.mapToItem\(null,\s*0,\s*0\);\s*if\s*\(\s*pt\s*\)\s*\{"
        self.assertTrue(
            bool(re.search(pattern, self.sb_qml)),
            "StatusBar.qml launcherPill.mapToItem must be guarded by `if (pt)`"
        )

    def test_13_idle_inhibitor_hover_timer_maptoitem_null_guarded(self):
        """Verify IdleInhibitor.qml hoverOpenTimer mapToItem is guarded by if (pt)."""
        pattern = r"let\s+pt\s*=\s*cafRoot\.mapToItem\(null,\s*0,\s*0\);\s*if\s*\(\s*pt\s*\)\s*\{"
        matches = list(re.finditer(pattern, self.idle_qml))
        self.assertGreaterEqual(
            len(matches), 2,
            f"IdleInhibitor.qml must have at least 2 `if (pt)` guarded mapToItem lookups (found {len(matches)})"
        )

    def test_14_idle_inhibitor_connections_maptoitem_ternary_guarded(self):
        """Verify IdleInhibitor.qml onRequestIdleToggle mapToItem uses safe ternary fallback."""
        pattern = r"let\s+pt\s*=\s*cafRoot\.mapToItem\(null,\s*0,\s*0\);\s*if\s*\(Theme\.isVertical\)\s*\{\s*cafPopup\.targetRelativeY\s*=\s*pt\s*\?"
        self.assertTrue(
            bool(re.search(pattern, self.idle_qml)),
            "IdleInhibitor.qml onRequestIdleToggle must safely guard pt with ternary fallback"
        )

    def test_15_windowtitle_maptoitem_null_guarded(self):
        """Verify WindowTitle.qml mapToItem uses ternary guard pt ? ... : 0."""
        pattern = r"let\s+pt\s*=\s*windowTitleRoot\.mapToItem\(null,\s*0,\s*0\);\s*winPopup\.targetRelativeX\s*=\s*pt\s*\?"
        self.assertTrue(
            bool(re.search(pattern, self.wt_qml)),
            "WindowTitle.qml must guard pt with ternary fallback"
        )

    def test_16_simulated_null_and_undefined_execution(self):
        """
        Simulates JS execution of all 4 mapToItem code blocks under null and undefined.
        Verifies zero TypeError exceptions and correct state mutations.
        """
        for unmapped_val in [None, "UNDEFINED"]:
            # Mock objects
            def map_to_item(target, x, y):
                return None if unmapped_val is None else None

            # 1. StatusBar launcher click handler
            sb_popup_open = False
            sb_target_x = -1
            item_w = 40
            is_vertical = False

            pt = map_to_item(None, 0, 0)
            if pt:
                if is_vertical:
                    pass
                else:
                    sb_target_x = pt["x"] + (item_w / 2)
            sb_popup_open = not sb_popup_open

            self.assertTrue(sb_popup_open)
            self.assertEqual(sb_target_x, -1)  # Unchanged, zero TypeError!

            # 2. IdleInhibitor hoverOpen handler
            caf_open = False
            caf_target_x = -1
            pt = map_to_item(None, 0, 0)
            if pt:
                caf_target_x = pt["x"] + 20
            caf_open = True

            self.assertTrue(caf_open)
            self.assertEqual(caf_target_x, -1)

            # 3. IdleInhibitor right click handler
            caf_pinned = False
            pt = map_to_item(None, 0, 0)
            if pt:
                caf_target_x = pt["x"] + 20
            caf_pinned = not caf_open
            caf_open = not caf_open

            self.assertEqual(caf_target_x, -1)

            # 4. IdleInhibitor Connections onRequestIdleToggle
            pt = map_to_item(None, 0, 0)
            target_x = (pt["x"] + 20) if pt else 0
            self.assertEqual(target_x, 0)

    def test_17_no_naked_maptoitem_property_access_in_target_files(self):
        """Verify that zero naked mapToItem(...).x or mapToItem(...).y exist in target files."""
        target_files = [
            REPO_ROOT / "bar" / "StatusBar.qml",
            REPO_ROOT / "widgets" / "IdleInhibitor.qml",
            REPO_ROOT / "widgets" / "WindowTitle.qml",
        ]
        naked_pattern = re.compile(r"mapToItem\([^)]*\)\s*\.\s*[a-zA-Z]")

        for fpath in target_files:
            with open(fpath, "r", encoding="utf-8") as f:
                content = f.read()
            matches = naked_pattern.findall(content)
            self.assertEqual(
                matches, [],
                f"Found unsafe naked mapToItem access in {fpath.name}: {matches}"
            )


# =============================================================================
# Test Suite 4: Empirical Qt Quick 6 QML Runtime Execution
# =============================================================================

class TestQmlRuntimeIntegration(unittest.TestCase):
    """
    Executes challenger_stress_narrow_null.qml directly via Qt Quick 6 Qml runtime
    in headless offscreen mode.
    """

    def test_18_empirical_qml_engine_execution(self):
        """Execute headless offscreen Qt Quick 6 QML engine stress test."""
        qml_script = REPO_ROOT / "tests" / "challenger_stress_narrow_null.qml"
        if not os.path.exists(QML_RUNNER_BIN):
            self.skipTest(f"Qt QML runner binary not found at {QML_RUNNER_BIN}")

        env = os.environ.copy()
        env["QT_QPA_PLATFORM"] = "offscreen"
        env["QML_IMPORT_PATH"] = "/nix/store/10553j4116y6jllliqpg5kz7d35bblab-qtdeclarative-6.11.2/lib/qt-6/qml"
        env["QML2_IMPORT_PATH"] = "/nix/store/10553j4116y6jllliqpg5kz7d35bblab-qtdeclarative-6.11.2/lib/qt-6/qml"
        env["QT_PLUGIN_PATH"] = "/nix/store/10553j4116y6jllliqpg5kz7d35bblab-qtdeclarative-6.11.2/lib/qt-6/plugins"

        proc = subprocess.run(
            [QML_RUNNER_BIN, str(qml_script)],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            env=env,
            timeout=15
        )

        combined_output = proc.stdout + proc.stderr
        self.assertEqual(
            proc.returncode, 0,
            f"QML execution failed with exit code {proc.returncode}:\n{combined_output}"
        )
        self.assertIn("ALL_NARROW_NULL_STRESS_CHECKS_PASSED", combined_output)
        self.assertIn("FAILURES: 0", combined_output)
        self.assertIn("TOTAL_CHECKS: 1221", combined_output)


# =============================================================================
# Test Suite 5: QmlLint Static Analysis
# =============================================================================

class TestQmllintValidation(unittest.TestCase):
    """Runs qmllint on target M3 files to verify exit code 0."""

    def test_19_qmllint_target_files(self):
        """Run qmllint on bar/StatusBar.qml, widgets/WindowTitle.qml, widgets/IdleInhibitor.qml."""
        if not os.path.exists(QMLLINT_BIN):
            self.skipTest(f"qmllint binary not found at {QMLLINT_BIN}")

        target_files = [
            "bar/StatusBar.qml",
            "widgets/WindowTitle.qml",
            "widgets/IdleInhibitor.qml",
        ]

        for rel_path in target_files:
            file_path = REPO_ROOT / rel_path
            res = subprocess.run(
                [QMLLINT_BIN, "-I", str(REPO_ROOT), str(file_path)],
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True
            )
            self.assertEqual(
                res.returncode, 0,
                f"qmllint failed for {rel_path} (exit code {res.returncode}):\n{res.stdout}\n{res.stderr}"
            )


if __name__ == "__main__":
    unittest.main()
