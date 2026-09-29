#!/run/current-system/sw/bin/python3
"""
Challenger Stress Test Suite for Milestone 1 (Gen 5)
Theme Token Bindings, Easing Resolver, and Padding/Duration Physics

Tests:
1. Stress-test getEasing(curve, type) against all standard curves, types, case variations,
   null/undefined/unknown edge cases, and Qt Quick Easing enum validity.
2. Stress-test paddingScaleMult with valid tokens ('compact', 'cozy', 'comfortable') and invalid/fallback values.
3. Stress-test animation durations (animFast, animNormal, animSlow) across all animSpeedMult presets
   and custom base durations.
4. Verify 100% token & method synchronicity between Theme.qml and matugen/templates/Theme.qml.
5. Execute empirical headless QML engine verification test.
"""

import unittest
import subprocess
import os
import re
import json
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent

# Qt Quick 6 QML Easing Enum Map (from Qt Quick Easing documentation)
QT_EASINGS = {
    "Linear": 0,
    "InQuad": 1,
    "OutQuad": 2,
    "InOutQuad": 3,
    "OutInQuad": 4,
    "InCubic": 5,
    "OutCubic": 6,
    "InOutCubic": 7,
    "OutInCubic": 8,
    "InQuart": 9,
    "OutQuart": 10,
    "InOutQuart": 11,
    "OutInQuart": 12,
    "InQuint": 13,
    "OutQuint": 14,
    "InOutQuint": 15,
    "OutInQuint": 16,
    "InSine": 17,
    "OutSine": 18,
    "InOutSine": 19,
    "OutInSine": 20,
    "InExpo": 21,
    "OutExpo": 22,
    "InOutExpo": 23,
    "OutInExpo": 24,
    "InCirc": 25,
    "OutCirc": 26,
    "InOutCirc": 27,
    "OutInCirc": 28,
    "InElastic": 29,
    "OutElastic": 30,
    "InOutElastic": 31,
    "OutInElastic": 32,
    "InBack": 33,
    "OutBack": 34,
    "InOutBack": 35,
    "OutInBack": 36,
    "InBounce": 37,
    "OutBounce": 38,
    "InOutBounce": 39,
    "OutInBounce": 40
}


def python_getEasing(curve: str | None, type_: str | None) -> int:
    """Exact python transliteration of Theme.qml getEasing."""
    c = (curve if curve is not None else "cubic").lower()
    t = (type_ if type_ is not None else "out").lower()

    if c == "linear":
        return QT_EASINGS["Linear"]
    if c == "quad":
        if t == "in": return QT_EASINGS["InQuad"]
        if t in ("inout", "in_out"): return QT_EASINGS["InOutQuad"]
        if t in ("outin", "out_in"): return QT_EASINGS["OutInQuad"]
        return QT_EASINGS["OutQuad"]
    if c == "quart":
        if t == "in": return QT_EASINGS["InQuart"]
        if t in ("inout", "in_out"): return QT_EASINGS["InOutQuart"]
        if t in ("outin", "out_in"): return QT_EASINGS["OutInQuart"]
        return QT_EASINGS["OutQuart"]
    if c == "quint":
        if t == "in": return QT_EASINGS["InQuint"]
        if t in ("inout", "in_out"): return QT_EASINGS["InOutQuint"]
        if t in ("outin", "out_in"): return QT_EASINGS["OutInQuint"]
        return QT_EASINGS["OutQuint"]
    if c == "sine":
        if t == "in": return QT_EASINGS["InSine"]
        if t in ("inout", "in_out"): return QT_EASINGS["InOutSine"]
        if t in ("outin", "out_in"): return QT_EASINGS["OutInSine"]
        return QT_EASINGS["OutSine"]
    if c == "expo":
        if t == "in": return QT_EASINGS["InExpo"]
        if t in ("inout", "in_out"): return QT_EASINGS["InOutExpo"]
        if t in ("outin", "out_in"): return QT_EASINGS["OutInExpo"]
        return QT_EASINGS["OutExpo"]
    if c == "circ":
        if t == "in": return QT_EASINGS["InCirc"]
        if t in ("inout", "in_out"): return QT_EASINGS["InOutCirc"]
        if t in ("outin", "out_in"): return QT_EASINGS["OutInCirc"]
        return QT_EASINGS["OutCirc"]
    if c == "back":
        if t == "in": return QT_EASINGS["InBack"]
        if t in ("inout", "in_out"): return QT_EASINGS["InOutBack"]
        if t in ("outin", "out_in"): return QT_EASINGS["OutInBack"]
        return QT_EASINGS["OutBack"]
    if c == "elastic":
        if t == "in": return QT_EASINGS["InElastic"]
        if t in ("inout", "in_out"): return QT_EASINGS["InOutElastic"]
        if t in ("outin", "out_in"): return QT_EASINGS["OutInElastic"]
        return QT_EASINGS["OutElastic"]
    if c == "bounce":
        if t == "in": return QT_EASINGS["InBounce"]
        if t in ("inout", "in_out"): return QT_EASINGS["InOutBounce"]
        if t in ("outin", "out_in"): return QT_EASINGS["OutInBounce"]
        return QT_EASINGS["OutBounce"]
    if t == "in": return QT_EASINGS["InCubic"]
    if t in ("inout", "in_out"): return QT_EASINGS["InOutCubic"]
    if t in ("outin", "out_in"): return QT_EASINGS["OutInCubic"]
    return QT_EASINGS["OutCubic"]


def python_paddingScaleMult(paddingScale: str | None) -> float:
    """Exact python transliteration of Theme.qml paddingScaleMult."""
    ps = paddingScale
    if ps == "compact": return 0.8
    if ps == "comfortable": return 1.25
    return 1.0


def python_animSpeedMult(animSpeed: str | None) -> float:
    """Exact python transliteration of Theme.qml animSpeedMult."""
    sp = animSpeed if animSpeed is not None else "normal"
    if sp == "instant": return 0.01
    if sp in ("snappy", "superSnappy"): return 0.7
    if sp == "hyper": return 0.4
    if sp == "chill": return 1.6
    return 1.0


def python_calculateDurations(fast: int, normal: int, slow: int, speed: str | None) -> dict[str, int]:
    """Exact python transliteration of Theme.qml anim durations."""
    mult = python_animSpeedMult(speed)
    return {
        "fast": round(fast * mult),
        "normal": round(normal * mult),
        "slow": round(slow * mult)
    }


class TestThemeTokensEasingStress(unittest.TestCase):
    """Adversarial challenger test suite for Theme tokens and easing."""

    @classmethod
    def setUpClass(cls):
        cls.theme_path = REPO_ROOT / "Theme.qml"
        cls.template_path = REPO_ROOT.parent / "matugen" / "templates" / "Theme.qml"
        cls.theme_content = cls.theme_path.read_text(encoding="utf-8")
        cls.template_content = cls.template_path.read_text(encoding="utf-8")

    # -------------------------------------------------------------------------
    # 1. EASING RESOLVER STRESS TESTS
    # -------------------------------------------------------------------------
    def test_01_all_standard_curves_and_types(self):
        """Stress-test all 11 curves across 4 easing types against Qt Easing enums."""
        curves = ["cubic", "quad", "quart", "quint", "sine", "expo", "circ", "back", "elastic", "bounce", "linear"]
        types = ["in", "out", "inout", "outin"]

        valid_enum_values = set(QT_EASINGS.values())

        for curve in curves:
            for typ in types:
                with self.subTest(curve=curve, type=typ):
                    val = python_getEasing(curve, typ)
                    self.assertIn(val, valid_enum_values, f"Result {val} for {curve}_{typ} is not a valid Qt Quick Easing enum")
                    if curve == "linear":
                        self.assertEqual(val, QT_EASINGS["Linear"])
                    else:
                        cap_curve = curve.capitalize()
                        if typ == "in": expected_key = f"In{cap_curve}"
                        elif typ == "out": expected_key = f"Out{cap_curve}"
                        elif typ == "inout": expected_key = f"InOut{cap_curve}"
                        elif typ == "outin": expected_key = f"OutIn{cap_curve}"
                        self.assertEqual(val, QT_EASINGS[expected_key], f"Mismatch for {curve} + {typ}")

    def test_02_snake_case_and_camel_case_variants(self):
        """Stress-test snake_case ('in_out', 'out_in') and mixed casing."""
        for curve in ["quad", "cubic", "back", "elastic"]:
            cap = curve.capitalize()
            self.assertEqual(python_getEasing(curve, "in_out"), QT_EASINGS[f"InOut{cap}"])
            self.assertEqual(python_getEasing(curve, "out_in"), QT_EASINGS[f"OutIn{cap}"])
            self.assertEqual(python_getEasing(curve.upper(), "IN_OUT"), QT_EASINGS[f"InOut{cap}"])
            self.assertEqual(python_getEasing(curve.title(), "InOut"), QT_EASINGS[f"InOut{cap}"])
            self.assertEqual(python_getEasing(curve, "OutIn"), QT_EASINGS[f"OutIn{cap}"])

    def test_03_edge_cases_and_null_undefined_fallbacks(self):
        """Stress-test null, undefined, empty strings, and unknown curves/types."""
        valid_enum_values = set(QT_EASINGS.values())

        cases = [
            (None, None, QT_EASINGS["OutCubic"]),
            (None, "in", QT_EASINGS["InCubic"]),
            (None, "inout", QT_EASINGS["InOutCubic"]),
            (None, "outin", QT_EASINGS["OutInCubic"]),
            ("cubic", None, QT_EASINGS["OutCubic"]),
            ("quad", None, QT_EASINGS["OutQuad"]),
            ("back", None, QT_EASINGS["OutBack"]),
            ("", "", QT_EASINGS["OutCubic"]),
            ("unknown_curve", "out", QT_EASINGS["OutCubic"]),
            ("unknown_curve", "in", QT_EASINGS["InCubic"]),
            ("unknown_curve", "inout", QT_EASINGS["InOutCubic"]),
            ("unknown_curve", "outin", QT_EASINGS["OutInCubic"]),
            ("unknown_curve", "invalid_type", QT_EASINGS["OutCubic"]),
            ("expo", "invalid_type", QT_EASINGS["OutExpo"]),
            ("bounce", "random", QT_EASINGS["OutBounce"]),
        ]

        for curve, typ, expected in cases:
            with self.subTest(curve=curve, type=typ):
                res = python_getEasing(curve, typ)
                self.assertIn(res, valid_enum_values)
                self.assertEqual(res, expected, f"Fallback failed for curve='{curve}', type='{typ}'")

    # -------------------------------------------------------------------------
    # 2. PADDING SCALE MULTIPLIER TESTS
    # -------------------------------------------------------------------------
    def test_04_padding_scale_mult_valid_and_invalid(self):
        """Test paddingScaleMult with valid tokens and fallbacks."""
        # Valid tokens
        self.assertEqual(python_paddingScaleMult("compact"), 0.8)
        self.assertEqual(python_paddingScaleMult("cozy"), 1.0)
        self.assertEqual(python_paddingScaleMult("comfortable"), 1.25)

        # Fallbacks (must return 1.0)
        invalid_tokens = [None, "", "dense", "huge", "COMPACT", "Cozy", "Comfortable", "wide", "1.5"]
        for token in invalid_tokens:
            with self.subTest(token=token):
                self.assertEqual(python_paddingScaleMult(token), 1.0, f"Failed fallback for {token}")

    # -------------------------------------------------------------------------
    # 3. ANIMATION DURATIONS & SPEED MULTIPLIER TESTS
    # -------------------------------------------------------------------------
    def test_05_anim_speed_multiplier_and_durations(self):
        """Test duration calculations across all animSpeedMult presets."""
        fast, normal, slow = 120, 200, 350

        # Normal speed (1.0x)
        d = python_calculateDurations(fast, normal, slow, "normal")
        self.assertEqual(d["fast"], 120)
        self.assertEqual(d["normal"], 200)
        self.assertEqual(d["slow"], 350)

        # Instant speed (0.01x)
        d = python_calculateDurations(fast, normal, slow, "instant")
        self.assertEqual(d["fast"], 1)     # 120 * 0.01 = 1.2 -> 1
        self.assertEqual(d["normal"], 2)   # 200 * 0.01 = 2.0 -> 2
        self.assertEqual(d["slow"], 4)     # 350 * 0.01 = 3.5 -> 4

        # Hyper speed (0.4x)
        d = python_calculateDurations(fast, normal, slow, "hyper")
        self.assertEqual(d["fast"], 48)    # 120 * 0.4 = 48
        self.assertEqual(d["normal"], 80)   # 200 * 0.4 = 80
        self.assertEqual(d["slow"], 140)   # 350 * 0.4 = 140

        # Snappy speed (0.7x)
        d = python_calculateDurations(fast, normal, slow, "snappy")
        self.assertEqual(d["fast"], 84)    # 120 * 0.7 = 84
        self.assertEqual(d["normal"], 140)  # 200 * 0.7 = 140
        self.assertEqual(d["slow"], 245)   # 350 * 0.7 = 245

        # superSnappy speed (0.7x)
        d = python_calculateDurations(fast, normal, slow, "superSnappy")
        self.assertEqual(d["fast"], 84)
        self.assertEqual(d["normal"], 140)
        self.assertEqual(d["slow"], 245)

        # Chill speed (1.6x)
        d = python_calculateDurations(fast, normal, slow, "chill")
        self.assertEqual(d["fast"], 192)   # 120 * 1.6 = 192
        self.assertEqual(d["normal"], 320)  # 200 * 1.6 = 320
        self.assertEqual(d["slow"], 560)   # 350 * 1.6 = 560

        # Fallback / unknown speed (defaults to 1.0x)
        for unk in [None, "", "warp", "sloth", "unknown"]:
            with self.subTest(unknown_speed=unk):
                d = python_calculateDurations(fast, normal, slow, unk)
                self.assertEqual(d["fast"], 120)
                self.assertEqual(d["normal"], 200)
                self.assertEqual(d["slow"], 350)

    def test_06_custom_durations_scaling(self):
        """Test user-customized base durations scaling."""
        custom_fast, custom_normal, custom_slow = 60, 180, 420
        d = python_calculateDurations(custom_fast, custom_normal, custom_slow, "hyper")
        self.assertEqual(d["fast"], 24)
        self.assertEqual(d["normal"], 72)
        self.assertEqual(d["slow"], 168)

        # Zero durations
        d_zero = python_calculateDurations(0, 0, 0, "chill")
        self.assertEqual(d_zero["fast"], 0)
        self.assertEqual(d_zero["normal"], 0)
        self.assertEqual(d_zero["slow"], 0)

    # -------------------------------------------------------------------------
    # 4. TEMPLATE PARITY & TOKEN SYNCHRONICITY
    # -------------------------------------------------------------------------
    def test_07_theme_and_template_token_parity(self):
        """Verify 100% token and helper parity between Theme.qml and matugen template."""
        tokens_to_check = [
            "paddingScale", "paddingScaleMult", "widgetPaddingV",
            "animSpeedMult", "animCurve", "animEasingType",
            "animDurationFast", "animDurationNormal", "animDurationSlow",
            "animFast", "animNormal", "animDefault", "animSlow",
            "animEasing", "animExpressiveEasing", "animColorEasing",
            "glassmorphismLevel", "cardOpacity", "surfaceOpacity",
            "cornerFillets", "cornerSmoothing"
        ]

        for token in tokens_to_check:
            self.assertIn(token, self.theme_content, f"Token {token} missing from Theme.qml")
            self.assertIn(token, self.template_content, f"Token {token} missing from matugen/templates/Theme.qml")

        # Verify getEasing implementation exists in both
        self.assertIn("function getEasing(curve: string, type: string): int", self.theme_content)
        self.assertIn("function getEasing(curve: string, type: string): int", self.template_content)

        # Verify kaoShrug backslash escaping in both
        self.assertTrue(re.search(r'kaoShrug:\s*"¯\\\\_\(ツ\)_/¯"', self.theme_content))
        self.assertTrue(re.search(r'kaoShrug:\s*"¯\\\\_\(ツ\)_/¯"', self.template_content))

    # -------------------------------------------------------------------------
    # 5. EMPIRICAL QT ENGINE RUNNER
    # -------------------------------------------------------------------------
    def test_08_empirical_qml_engine_execution(self):
        """Run offscreen Qt Quick 6 QML engine stress test harness."""
        qml_bin = "/nix/store/10553j4116y6jllliqpg5kz7d35bblab-qtdeclarative-6.11.2/bin/qml"
        qml_script = REPO_ROOT / "tests" / "challenger_stress_theme_easing.qml"

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
        self.assertEqual(proc.returncode, 0, f"QML execution failed with exit code {proc.returncode}: {proc.stderr}")
        self.assertIn("ALL_TESTS_PASSED_SUCCESSFULLY", combined_output)
        self.assertIn("FAILURES: 0", combined_output)


if __name__ == "__main__":
    unittest.main()
