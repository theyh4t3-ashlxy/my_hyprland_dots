#!/run/current-system/sw/bin/python3
"""
Empirical Challenger Stress Test Suite for Milestone 2:
Theme Bezier Spline Parser, Preset Matcher, and PopupPanel Morphing Mechanics

Verifies:
1. getBezierPoints(curve: var):
   - Named presets: hyprland, smooth, snappy, expressive, linear, standard (case-insensitive, trimmed).
   - CSS formats: cubic-bezier(x1, y1, x2, y2), with/without spaces, upper/lower/mixed case, comma-separated numbers.
   - Array inputs: 4-element arrays, 6-element arrays, oversized arrays, string-encoded number arrays.
   - Extreme & boundary inputs: invalid strings, empty string, malformed floats, NaN, out-of-bounds coords, null, undefined.
     Verifies it ALWAYS returns a valid 6-float array without throwing runtime exceptions.
2. PopupPanel morphing mechanics:
   - contentWrapper.opacity and morphContainer.opacity across normalized progress p in [0.0, 1.0] during open vs close.
   - During closing: content remains visible down to p=0.0, and hull opacity decays in lockstep (|diff| <= 0.025 for p <= 0.70),
     eliminating hollow rectangle collapse.
   - Rapid toggle duration scaling: duration proportionally scales with distance, clamped at minimum 50ms, never locking or stalling.
3. Code contract inspection & Matugen template synchronicity.
4. Offscreen Qt Quick 6 QML engine execution of challenger_stress_bezier_popup.qml.
"""

import unittest
import os
import re
import math
import subprocess
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent

# Preset definitions matching Theme.qml
HYPRLAND_BEZIER = [0.05, 0.9, 0.1, 1.05, 1.0, 1.0]
HYPRLAND_EXIT_BEZIER = [0.3, 0.0, 0.8, 0.15, 1.0, 1.0]
SMOOTH_BEZIER = [0.16, 1.0, 0.3, 1.0, 1.0, 1.0]
SNAPPY_BEZIER = [0.2, 0.0, 0.0, 1.0, 1.0, 1.0]
EXPRESSIVE_BEZIER = [0.1, 1.15, 0.2, 1.0, 1.0, 1.0]
STANDARD_BEZIER = [0.25, 0.1, 0.25, 1.0, 1.0, 1.0]
LINEAR_BEZIER = [0.0, 0.0, 1.0, 1.0, 1.0, 1.0]


def js_parseFloat(s: str) -> float:
    """Simulate JavaScript parseFloat which parses leading valid numeric characters."""
    m = re.match(r'^\s*([+-]?(?:(?:\d+\.?\d*|\.\d+)(?:[eE][+-]?\d+)?))', s)
    if m:
        try:
            return float(m.group(1))
        except ValueError:
            return float('nan')
    return float('nan')


def python_getBezierPoints(curve) -> list[float]:
    """Exact python transliteration of Theme.qml getBezierPoints."""
    if curve is None or curve is False:
        return list(STANDARD_BEZIER)
    if isinstance(curve, (list, tuple)):
        if len(curve) >= 6:
            try:
                return [float(curve[0]), float(curve[1]), float(curve[2]), float(curve[3]), float(curve[4]), float(curve[5])]
            except (ValueError, TypeError):
                return list(STANDARD_BEZIER)
        if len(curve) >= 4:
            try:
                return [float(curve[0]), float(curve[1]), float(curve[2]), float(curve[3]), 1.0, 1.0]
            except (ValueError, TypeError):
                return list(STANDARD_BEZIER)
        return list(STANDARD_BEZIER)

    if not isinstance(curve, str):
        return list(STANDARD_BEZIER)

    c = curve.strip().lower()
    if c == "hyprland": return list(HYPRLAND_BEZIER)
    if c in ("smooth", "cubic"): return list(SMOOTH_BEZIER)
    if c == "snappy": return list(SNAPPY_BEZIER)
    if c == "expressive": return list(EXPRESSIVE_BEZIER)
    if c == "linear": return list(LINEAR_BEZIER)

    m = re.match(r'^(?:cubic-bezier\s*\(\s*)?([0-9.-]+)\s*,\s*([0-9.-]+)\s*,\s*([0-9.-]+)\s*,\s*([0-9.-]+)(?:\s*\))?$', c)
    if m:
        p1 = js_parseFloat(m.group(1))
        p2 = js_parseFloat(m.group(2))
        p3 = js_parseFloat(m.group(3))
        p4 = js_parseFloat(m.group(4))
        if not math.isnan(p1) and not math.isnan(p2) and not math.isnan(p3) and not math.isnan(p4):
            return [p1, p2, p3, p4, 1.0, 1.0]

    return list(STANDARD_BEZIER)


def morphContainer_opacity(is_open: bool, p: float) -> float:
    """Exact transliteration of morphContainer opacity binding in PopupPanel.qml."""
    if is_open:
        return min(1.0, p * 2.0)
    else:
        return min(1.0, p * 1.4)


def contentWrapper_opacity(is_open: bool, p: float) -> float:
    """Exact transliteration of contentWrapper opacity binding in PopupPanel.qml."""
    if is_open:
        return max(0.0, min(1.0, (p - 0.12) / 0.88))
    else:
        return min(1.0, p / 0.70)


def compute_scaled_duration(is_open: bool, current_p: float, expressive_default: int = 260, expressive_fast: int = 160) -> int:
    """Exact transliteration of numAnim duration scaling in PopupPanel.qml onOpenChanged."""
    target_progress = 1.0 if is_open else 0.0
    distance = abs(target_progress - current_p)
    base_duration = expressive_default if is_open else expressive_fast
    return max(50, round(base_duration * max(0.25, distance)))


class TestBezierPopupStress(unittest.TestCase):
    """Empirical Stress Test Suite for Theme Bezier Engine & PopupPanel Morphing."""

    @classmethod
    def setUpClass(cls):
        cls.theme_path = REPO_ROOT / "Theme.qml"
        cls.template_path = REPO_ROOT.parent / "matugen" / "templates" / "Theme.qml"
        cls.popup_path = REPO_ROOT / "controls" / "PopupPanel.qml"

        cls.theme_src = cls.theme_path.read_text(encoding="utf-8")
        cls.template_src = cls.template_path.read_text(encoding="utf-8")
        cls.popup_src = cls.popup_path.read_text(encoding="utf-8")

    # =========================================================================
    # 1. THEME BEZIER: NAMED PRESETS
    # =========================================================================
    def test_01_named_presets(self):
        """Stress test named bezier presets with case variations and surrounding whitespace."""
        presets = {
            "hyprland": HYPRLAND_BEZIER,
            "smooth": SMOOTH_BEZIER,
            "cubic": SMOOTH_BEZIER,
            "snappy": SNAPPY_BEZIER,
            "expressive": EXPRESSIVE_BEZIER,
            "linear": LINEAR_BEZIER,
            "standard": STANDARD_BEZIER,
        }

        for name, expected in presets.items():
            variations = [
                name,
                name.upper(),
                name.capitalize(),
                f"  {name}  ",
                f"\t{name.upper()}\n",
            ]
            for var in variations:
                with self.subTest(preset=var):
                    res = python_getBezierPoints(var)
                    self.assertEqual(len(res), 6, f"Result must have length 6 for {var}")
                    self.assertEqual(res, expected, f"Failed matching preset {var}")
                    self.assertTrue(all(isinstance(x, (int, float)) and not math.isnan(x) for x in res))

    # =========================================================================
    # 2. THEME BEZIER: CSS FORMATS & COMMA STRINGS
    # =========================================================================
    def test_02_css_formats(self):
        """Stress test CSS cubic-bezier(...) and comma-separated numbers."""
        test_cases = [
            ("cubic-bezier(0.05, 0.9, 0.1, 1.05)", [0.05, 0.9, 0.1, 1.05, 1.0, 1.0]),
            ("cubic-bezier(0.05,0.9,0.1,1.05)", [0.05, 0.9, 0.1, 1.05, 1.0, 1.0]),
            ("cubic-bezier(  0.05 , 0.9 , 0.1 , 1.05  )", [0.05, 0.9, 0.1, 1.05, 1.0, 1.0]),
            ("CUBIC-BEZIER(0.05, 0.9, 0.1, 1.05)", [0.05, 0.9, 0.1, 1.05, 1.0, 1.0]),
            ("Cubic-Bezier(0.05, 0.9, 0.1, 1.05)", [0.05, 0.9, 0.1, 1.05, 1.0, 1.0]),
            ("0.05, 0.9, 0.1, 1.05", [0.05, 0.9, 0.1, 1.05, 1.0, 1.0]),
            ("  0.2 , 0.0 , 0.2 , 1.0  ", [0.2, 0.0, 0.2, 1.0, 1.0, 1.0]),
            ("cubic-bezier(-0.2, 1.5, 0.8, -0.5)", [-0.2, 1.5, 0.8, -0.5, 1.0, 1.0]),
            ("-0.5, 2.5, -1.0, 3.0", [-0.5, 2.5, -1.0, 3.0, 1.0, 1.0]),
        ]

        for s, expected in test_cases:
            with self.subTest(css=s):
                res = python_getBezierPoints(s)
                self.assertEqual(len(res), 6)
                for a, b in zip(res, expected):
                    self.assertAlmostEqual(a, b, places=5)

    # =========================================================================
    # 3. THEME BEZIER: ARRAY INPUTS
    # =========================================================================
    def test_03_array_inputs(self):
        """Stress test array inputs: 4-element, 6-element, oversized, and string-typed elements."""
        test_cases = [
            ([0.2, 0.0, 0.2, 1.0], [0.2, 0.0, 0.2, 1.0, 1.0, 1.0]),
            ([0.05, 0.9, 0.1, 1.05, 1.0, 1.0], [0.05, 0.9, 0.1, 1.05, 1.0, 1.0]),
            ([0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8], [0.1, 0.2, 0.3, 0.4, 0.5, 0.6]),
            (["0.2", "0.0", "0.2", "1.0"], [0.2, 0.0, 0.2, 1.0, 1.0, 1.0]),
            (["0.05", "0.9", "0.1", "1.05", "1.0", "1.0"], [0.05, 0.9, 0.1, 1.05, 1.0, 1.0]),
        ]

        for arr, expected in test_cases:
            with self.subTest(array=arr):
                res = python_getBezierPoints(arr)
                self.assertEqual(len(res), 6)
                for a, b in zip(res, expected):
                    self.assertAlmostEqual(a, b, places=5)

    # =========================================================================
    # 4. THEME BEZIER: EXTREME & BOUNDARY INPUTS
    # =========================================================================
    def test_04_extreme_and_boundary_inputs(self):
        """Verify getBezierPoints NEVER throws and always returns a valid 6-float array on any extreme input."""
        boundary_inputs = [
            None,
            "",
            "   ",
            "\n\t",
            "not-a-bezier",
            "cubic-bezier()",
            "cubic-bezier(a, b, c, d)",
            "cubic-bezier(1, 2, 3)",       # only 3 numbers
            "cubic-bezier(1, 2, 3, 4, 5)", # 5 numbers
            "1.2.3, 4, 5, 6",
            "..1, --2, 3..4, 5",
            float("nan"),
            "NaN, 0, 0, 1",
            123,
            0,
            -999,
            True,
            False,
            {},
            [],
            [1],
            [1, 2],
            [1, 2, 3],
            ["a", "b", "c", "d"],
        ]

        for inp in boundary_inputs:
            with self.subTest(boundary_input=repr(inp)):
                try:
                    res = python_getBezierPoints(inp)
                except Exception as e:
                    self.fail(f"getBezierPoints threw exception on input {inp!r}: {e}")

                self.assertIsInstance(res, list, f"Result must be a list for {inp!r}")
                self.assertEqual(len(res), 6, f"Result must have 6 elements for {inp!r}")
                for idx, val in enumerate(res):
                    self.assertIsInstance(val, (int, float), f"Element {idx} must be numeric in {res}")
                    self.assertFalse(math.isnan(val), f"Element {idx} cannot be NaN in {res}")
                    self.assertFalse(math.isinf(val), f"Element {idx} cannot be infinite in {res}")

    # =========================================================================
    # 5. POPUPPANEL: OPENING OPACITY MECHANICS
    # =========================================================================
    def test_05_popuppanel_opening_opacity(self):
        """Verify opening opacity curves: monotonic, bounded, and delayed content fade-in."""
        prev_hull = -1.0
        prev_content = -1.0

        for step in range(101):
            p = step / 100.0
            h = morphContainer_opacity(True, p)
            c = contentWrapper_opacity(True, p)

            # Bounds
            self.assertGreaterEqual(h, 0.0)
            self.assertLessEqual(h, 1.0)
            self.assertGreaterEqual(c, 0.0)
            self.assertLessEqual(c, 1.0)

            # Monotonicity
            self.assertGreaterEqual(h, prev_hull - 1e-9, f"Hull decreased at p={p}")
            self.assertGreaterEqual(c, prev_content - 1e-9, f"Content decreased at p={p}")

            # Delayed content fade-in during expansion (prevents content spilling outside unexpanded hull)
            if p <= 0.12:
                self.assertEqual(c, 0.0, f"Content should be delayed (0.0) at p={p}, got {c}")

            # At p=0.50 hull is fully opaque (2.0 * 0.50 = 1.0)
            if p >= 0.50:
                self.assertEqual(h, 1.0)

            # At p=1.0 both are fully opaque
            if p == 1.0:
                self.assertEqual(h, 1.0)
                self.assertEqual(c, 1.0)

            prev_hull = h
            prev_content = c

    # =========================================================================
    # 6. POPUPPANEL: CLOSING OPACITY LOCKSTEP & ZERO COLLAPSE
    # =========================================================================
    def test_06_popuppanel_closing_opacity_lockstep(self):
        """Verify closing opacity curves: content remains visible down to p=0, and decays in lockstep with hull."""
        prev_hull = 2.0
        prev_content = 2.0

        for step in range(100, -1, -1):
            p = step / 100.0
            h = morphContainer_opacity(False, p)
            c = contentWrapper_opacity(False, p)

            # Bounds
            self.assertGreaterEqual(h, 0.0)
            self.assertLessEqual(h, 1.0)
            self.assertGreaterEqual(c, 0.0)
            self.assertLessEqual(c, 1.0)

            # Monotonic decay
            self.assertLessEqual(h, prev_hull + 1e-9, f"Hull increased during close at p={p}")
            self.assertLessEqual(c, prev_content + 1e-9, f"Content increased during close at p={p}")

            # Content visibility down to p=0.0
            if p > 0.0:
                self.assertGreater(c, 0.0, f"Content vanished prematurely at p={p}: {c}")
                self.assertGreater(h, 0.0, f"Hull vanished prematurely at p={p}: {h}")
            else:
                self.assertEqual(c, 0.0, "Content must reach 0.0 at p=0.0")
                self.assertEqual(h, 0.0, "Hull must reach 0.0 at p=0.0")

            # Lockstep decay verification:
            # For p in [0.0, 0.70]: h = 1.4*p, c = p/0.70 = 1.4286*p
            # Max difference |1.4286*p - 1.4*p| = 0.0286 * 0.70 = 0.0200
            if p <= 0.70:
                diff = abs(h - c)
                self.assertLessEqual(diff, 0.025, f"Lockstep decay violated at p={p}: hull={h:.4f}, content={c:.4f}, diff={diff:.4f}")

            prev_hull = h
            prev_content = c

    # =========================================================================
    # 7. POPUPPANEL: RAPID TOGGLE DURATION SCALING
    # =========================================================================
    def test_07_popuppanel_rapid_toggle_scaling(self):
        """Verify duration scales proportionally with distance without locking or stalling."""
        expressive_default = 260
        expressive_fast = 160

        # Full open from p=0.0: distance = 1.0 -> duration = 260
        d_full_open = compute_scaled_duration(True, 0.0, expressive_default, expressive_fast)
        self.assertEqual(d_full_open, 260)

        # Full close from p=1.0: distance = 1.0 -> duration = 160
        d_full_close = compute_scaled_duration(False, 1.0, expressive_default, expressive_fast)
        self.assertEqual(d_full_close, 160)

        # Rapid toggle reversal at p=0.9 (almost open, reversed to close)
        # target = 0.0, distance = 0.9 -> 160 * 0.9 = 144
        d_rev_close = compute_scaled_duration(False, 0.9, expressive_default, expressive_fast)
        self.assertEqual(d_rev_close, 144)

        # Rapid toggle reversal at p=0.1 (barely opened, reversed to close)
        # target = 0.0, distance = 0.1 -> max(0.25, 0.1)=0.25 -> 160 * 0.25 = 40 -> max(50, 40) = 50
        d_small_close = compute_scaled_duration(False, 0.1, expressive_default, expressive_fast)
        self.assertEqual(d_small_close, 50, "Small toggle must be clamped to minimum 50ms")

        # Zero distance toggle (click when already reached)
        d_zero = compute_scaled_duration(True, 1.0, expressive_default, expressive_fast)
        self.assertGreaterEqual(d_zero, 50, "Zero distance toggle must never be 0ms to prevent lockups")

        # Sweep all intermediate values p in [0.0, 1.0]
        for step in range(101):
            p = step / 100.0
            d_open = compute_scaled_duration(True, p, expressive_default, expressive_fast)
            d_close = compute_scaled_duration(False, p, expressive_default, expressive_fast)

            # Never less than 50ms (no divide-by-zero or lockup)
            self.assertGreaterEqual(d_open, 50)
            self.assertGreaterEqual(d_close, 50)

            # Never greater than base duration
            self.assertLessEqual(d_open, expressive_default)
            self.assertLessEqual(d_close, expressive_fast)

    # =========================================================================
    # 8. CODE CONTRACT AUDIT: THEME & POPUPPANEL
    # =========================================================================
    def test_08_code_contract_audit(self):
        """Audit QML AST / regex tokens for exact milestone implementation requirements."""
        # 1. Theme.qml must have getBezierPoints
        self.assertIn("function getBezierPoints(curve: var): var", self.theme_src)
        self.assertIn("function getBezierPoints(curve: var): var", self.template_src)

        # 2. Preset definitions in Theme.qml
        presets = ["hyprlandBezier", "hyprlandExitBezier", "smoothBezier", "snappyBezier", "expressiveBezier", "standardBezier"]
        for p in presets:
            self.assertIn(p, self.theme_src)
            self.assertIn(p, self.template_src)

        # 3. PopupPanel decoupled opacity curves
        self.assertTrue(
            re.search(r'opacity:\s*root\.open\s*\?\s*Math\.min\(1\.0,\s*root\.morphProgress\s*\*\s*2\.0\)\s*:\s*Math\.min\(1\.0,\s*root\.morphProgress\s*\*\s*1\.4\)', self.popup_src),
            "morphContainer opacity binding mismatch in PopupPanel.qml"
        )
        self.assertTrue(
            re.search(r'opacity:\s*root\.open\s*\?\s*Math\.max\(0\.0,\s*Math\.min\(1\.0,\s*\(root\.morphProgress\s*-\s*0\.12\)\s*/\s*0\.88\)\)\s*:\s*Math\.min\(1\.0,\s*root\.morphProgress\s*/\s*0\.70\)', self.popup_src),
            "contentWrapper opacity binding mismatch in PopupPanel.qml"
        )

        # 4. PopupPanel duration scaling with distance and 50ms clamp
        self.assertTrue(
            re.search(r'Math\.max\(\s*50,\s*Math\.round\(\s*baseDuration\s*\*\s*Math\.max\(\s*0\.25,\s*distance\s*\)\s*\)\s*\)', self.popup_src),
            "numAnim duration scaling formula mismatch in PopupPanel.qml"
        )

    # =========================================================================
    # 9. EMPIRICAL QT ENGINE RUNNER
    # =========================================================================
    def test_09_empirical_headless_qml_engine(self):
        """Run offscreen Qt Quick 6 QML engine stress test harness challenger_stress_bezier_popup.qml."""
        qml_bin = "/nix/store/10553j4116y6jllliqpg5kz7d35bblab-qtdeclarative-6.11.2/bin/qml"
        qml_script = REPO_ROOT / "tests" / "challenger_stress_bezier_popup.qml"

        if not os.path.exists(qml_bin):
            self.skipTest(f"Qt QML binary not found at {qml_bin}")

        env = os.environ.copy()
        env["QT_QPA_PLATFORM"] = "offscreen"
        env["QML_IMPORT_PATH"] = "/nix/store/10553j4116y6jllliqpg5kz7d35bblab-qtdeclarative-6.11.2/lib/qt-6/qml"
        env["QML2_IMPORT_PATH"] = "/nix/store/10553j4116y6jllliqpg5kz7d35bblab-qtdeclarative-6.11.2/lib/qt-6/qml"
        env["QT_PLUGIN_PATH"] = "/nix/store/10553j4116y6jllliqpg5kz7d35bblab-qtdeclarative-6.11.2/lib/qt-6/plugins"

        proc = subprocess.run(
            [qml_bin, str(qml_script)],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            env=env,
            timeout=15
        )

        combined_output = proc.stdout + proc.stderr
        self.assertEqual(proc.returncode, 0, f"QML execution failed with exit code {proc.returncode}:\n{proc.stderr}")
        self.assertIn("ALL_TESTS_PASSED_SUCCESSFULLY", combined_output)
        self.assertIn("FAILURES: 0", combined_output)
        self.assertIn("TOTAL_CHECKS: 1416", combined_output)


if __name__ == "__main__":
    unittest.main()
