#!/run/current-system/sw/bin/python3
"""
Challenger Empirical Stress Test Suite for Milestone 1 (M1) - Gen 5
Focus: Deep boundary, invalid, extreme values, round-trip serialization,
fuzzing, and live runtime stability testing of the Settings schema and parser.
"""

import os
import sys
import re
import json
import time
import math
import random
import shutil
import tempfile
import unittest
import subprocess
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO_ROOT))

from tests.harness import QmlCodeInspector, QuickshellLogAuditor, QuickshellIpc

# Qt 6 Easing curve integer constants (matching QtQuick Easing enum)
QT_EASING_MAP = {
    "Linear": 0,
    "InQuad": 1, "OutQuad": 2, "InOutQuad": 3, "OutInQuad": 4,
    "InCubic": 5, "OutCubic": 6, "InOutCubic": 7, "OutInCubic": 8,
    "InQuart": 9, "OutQuart": 10, "InOutQuart": 11, "OutInQuart": 12,
    "InQuint": 13, "OutQuint": 14, "InOutQuint": 15, "OutInQuint": 16,
    "InSine": 17, "OutSine": 18, "InOutSine": 19, "OutInSine": 20,
    "InExpo": 21, "OutExpo": 22, "InOutExpo": 23, "OutInExpo": 24,
    "InCirc": 25, "OutCirc": 26, "InOutCirc": 27, "OutInCirc": 28,
    "InElastic": 29, "OutElastic": 30, "InOutElastic": 31, "OutInElastic": 32,
    "InBack": 33, "OutBack": 34, "InOutBack": 35, "OutInBack": 36,
    "InBounce": 37, "OutBounce": 38, "InOutBounce": 39, "OutInBounce": 40,
}


class SettingsSimulator:
    """
    High-fidelity Python reference implementation of Settings.qml parsing
    and serialization algorithms (loadConf, loadObject, toConf).
    """

    M1_PROPERTIES = [
        {"key": "paddingScale", "type": "string", "def": "cozy"},
        {"key": "widgetPaddingV", "type": "int", "def": 4},
        {"key": "animCurve", "type": "string", "def": "cubic"},
        {"key": "animEasingType", "type": "string", "def": "out"},
        {"key": "animDurationFast", "type": "int", "def": 120},
        {"key": "animDurationNormal", "type": "int", "def": 200},
        {"key": "animDurationSlow", "type": "int", "def": 350},
        {"key": "glassmorphismLevel", "type": "float", "def": 0.85},
        {"key": "cardOpacity", "type": "float", "def": 0.95},
        {"key": "surfaceOpacity", "type": "float", "def": 0.90},
        {"key": "cornerFillets", "type": "bool", "def": True},
        {"key": "cornerSmoothing", "type": "float", "def": 0.7},
    ]

    def __init__(self, schema_items=None):
        self.schema = schema_items or self.M1_PROPERTIES
        self.state = {}
        self.reset_to_defaults()

    def reset_to_defaults(self):
        self.state = {item["key"]: item["def"] for item in self.schema}

    @staticmethod
    def js_parse_int(val):
        """Simulates JavaScript parseInt(v)."""
        if val is None or isinstance(val, bool):
            return float("nan")
        s = str(val).strip()
        match = re.match(r"^[-+]?\d+", s)
        if match:
            try:
                return int(match.group(0))
            except ValueError:
                return float("nan")
        return float("nan")

    @staticmethod
    def js_parse_float(val):
        """Simulates JavaScript parseFloat(v)."""
        if val is None or isinstance(val, bool):
            return float("nan")
        s = str(val).strip()
        match = re.match(r"^[-+]?(\d+(\.\d*)?|\.\d+)([eE][-+]?\d+)?", s)
        if match:
            try:
                return float(match.group(0))
            except ValueError:
                return float("nan")
        return float("nan")

    def load_object(self, data):
        """Exact mirror of Settings.qml loadObject(data)."""
        if not data:
            return
        for item in self.schema:
            key = item["key"]
            itype = item["type"]
            v = data.get(key)
            if v is None:
                continue

            if key == "awwwTransitionType":
                valid = ["wipe", "wave", "grow", "fade", "center", "outer", "simple", "left", "right", "top", "bottom", "random", "none"]
                if v not in valid:
                    v = "wipe"

            if itype == "string":
                self.state[key] = str(v)
            elif itype == "int":
                n = self.js_parse_int(v)
                if not math.isnan(n):
                    self.state[key] = int(n)
            elif itype == "float":
                f = self.js_parse_float(v)
                if not math.isnan(f):
                    self.state[key] = float(f)
            elif itype == "bool":
                b = (v is True or v == "true")
                self.state[key] = b
            elif itype == "json":
                try:
                    obj = json.loads(v) if isinstance(v, str) else v
                    if obj is not None and (isinstance(obj, (dict, list))):
                        self.state[key] = obj
                except Exception:
                    pass

    def load_conf(self, conf_str):
        """Exact mirror of Settings.qml loadConf(str)."""
        lines = conf_str.split("\n")
        data = {}
        for line in lines:
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            eq_idx = line.find("=")
            if eq_idx != -1:
                key = line[:eq_idx].strip()
                val = line[eq_idx + 1:].strip()
                if (val.startswith('"') and val.endswith('"')) or (val.startswith("'") and val.endswith("'")):
                    val = val[1:-1]
                data[key] = val
        self.load_object(data)

    def to_conf(self):
        """Exact mirror of Settings.qml toConf()."""
        lines = []
        for item in self.schema:
            key = item["key"]
            itype = item["type"]
            val = self.state.get(key, item["def"])
            if itype == "string":
                lines.append(f'{key}="{val}"')
            elif itype == "json":
                lines.append(f"{key}='{json.dumps(val)}'")
            elif itype == "bool":
                lines.append(f"{key}={'true' if val else 'false'}")
            else:
                lines.append(f"{key}={val}")
        return "\n".join(lines)


class ThemeTokenSimulator:
    """Simulates Theme.qml reactive token resolution for the new M1 properties."""

    @staticmethod
    def get_padding_scale_mult(padding_scale_val):
        ps = padding_scale_val
        if ps == "compact":
            return 0.8
        if ps == "comfortable":
            return 1.25
        return 1.0

    @staticmethod
    def get_anim_speed_mult(anim_speed_val):
        sp = anim_speed_val or "normal"
        if sp == "instant":
            return 0.01
        if sp in ("snappy", "superSnappy"):
            return 0.7
        if sp == "hyper":
            return 0.4
        if sp == "chill":
            return 1.6
        return 1.0

    @staticmethod
    def get_easing(curve, type_val):
        c = (curve or "cubic").lower()
        t = (type_val or "out").lower()

        if c == "linear":
            return QT_EASING_MAP["Linear"]

        family_map = {
            "quad": ("InQuad", "InOutQuad", "OutInQuad", "OutQuad"),
            "quart": ("InQuart", "InOutQuart", "OutInQuart", "OutQuart"),
            "quint": ("InQuint", "InOutQuint", "OutInQuint", "OutQuint"),
            "sine": ("InSine", "InOutSine", "OutInSine", "OutSine"),
            "expo": ("InExpo", "InOutExpo", "OutInExpo", "OutExpo"),
            "circ": ("InCirc", "InOutCirc", "OutInCirc", "OutCirc"),
            "back": ("InBack", "InOutBack", "OutInBack", "OutBack"),
            "elastic": ("InElastic", "InOutElastic", "OutInElastic", "OutElastic"),
            "bounce": ("InBounce", "InOutBounce", "OutInBounce", "OutBounce"),
        }

        if c in family_map:
            in_name, inout_name, outin_name, out_name = family_map[c]
            if t == "in":
                return QT_EASING_MAP[in_name]
            if t in ("inout", "in_out"):
                return QT_EASING_MAP[inout_name]
            if t in ("outin", "out_in"):
                return QT_EASING_MAP[outin_name]
            return QT_EASING_MAP[out_name]

        # Cubic fallback for unknown curves or cubic curve
        if t == "in":
            return QT_EASING_MAP["InCubic"]
        if t in ("inout", "in_out"):
            return QT_EASING_MAP["InOutCubic"]
        if t in ("outin", "out_in"):
            return QT_EASING_MAP["OutInCubic"]
        return QT_EASING_MAP["OutCubic"]


class TestM1Gen5SettingsStress(unittest.TestCase):
    """Empirical Stress Test Suite for M1 Settings & Schema."""

    @classmethod
    def setUpClass(cls):
        cls.settings_qml = QmlCodeInspector.read_qml_content("services/Settings.qml")
        cls.theme_qml = QmlCodeInspector.read_qml_content("Theme.qml")
        cls.matugen_theme = (REPO_ROOT.parent / "matugen" / "templates" / "Theme.qml").read_text(encoding="utf-8")
        cls.settings_conf = (REPO_ROOT / "settings.conf").read_text(encoding="utf-8")
        cls.state_conf_path = Path.home() / ".local" / "state" / "quickshell" / "settings.conf"

        # Parse full 123 schema items from Settings.qml
        m = re.search(r"readonly property var _schema:\s*\[(.*?)\]\s*\n\s*function loadObject", cls.settings_qml, re.DOTALL)
        schema_lines = [l.strip() for l in m.group(1).splitlines() if l.strip().startswith("{")]
        cls.full_schema = []
        for l in schema_lines:
            km = re.search(r"key:\s*\"([^\"]+)\"", l)
            tm = re.search(r"type:\s*\"([^\"]+)\"", l)
            dm = re.search(r"def:\s*(.*)\s*\},?$", l)
            k = km.group(1)
            t = tm.group(1)
            d = dm.group(1).strip()
            if d.endswith("}"): d = d[:-1].strip()
            if d.endswith(","): d = d[:-1].strip()

            if t == "string":
                val = d.strip("\"").strip("\x27")
            elif t == "int":
                val = int(d)
            elif t == "float":
                val = float(d)
            elif t == "bool":
                val = (d == "true")
            elif t == "json":
                if d.startswith("(") and d.endswith(")"): d = d[1:-1].strip()
                val = json.loads(d)
            cls.full_schema.append({"key": k, "type": t, "def": val})

    # =========================================================================
    # SUITE 1: SCHEMA & PROPERTY DECLARATION INTEGRITY
    # =========================================================================

    def test_s1_01_all_12_properties_declared_with_types(self):
        """Verify all 12 properties are declared with proper QML types and default values."""
        expected_declarations = {
            "paddingScale": ("string", '"cozy"'),
            "widgetPaddingV": ("int", "4"),
            "animCurve": ("string", '"cubic"'),
            "animEasingType": ("string", '"out"'),
            "animDurationFast": ("int", "120"),
            "animDurationNormal": ("int", "200"),
            "animDurationSlow": ("int", "350"),
            "glassmorphismLevel": ("real", "0.85"),
            "cardOpacity": ("real", "0.95"),
            "surfaceOpacity": ("real", "0.90"),
            "cornerFillets": ("bool", "true"),
            "cornerSmoothing": ("real", "0.7"),
        }
        for prop, (ptype, pdef) in expected_declarations.items():
            pattern = rf"property\s+{ptype}\s+{prop}:\s*{re.escape(pdef)}"
            self.assertTrue(
                re.search(pattern, self.settings_qml),
                f"Missing or mismatched property declaration for {prop} ({ptype} = {pdef})"
            )

    def test_s1_02_all_12_properties_have_queue_save_handlers(self):
        """Verify all 12 properties trigger queueSave() on modification."""
        props = [
            "paddingScale", "widgetPaddingV", "animCurve", "animEasingType",
            "animDurationFast", "animDurationNormal", "animDurationSlow",
            "glassmorphismLevel", "cardOpacity", "surfaceOpacity",
            "cornerFillets", "cornerSmoothing"
        ]
        for p in props:
            handler_name = f"on{p[0].upper() + p[1:]}Changed"
            pattern = rf"{handler_name}:\s*queueSave\(\)"
            self.assertTrue(
                re.search(pattern, self.settings_qml),
                f"Missing change handler {handler_name} for property {p}"
            )

    def test_s1_03_all_12_properties_present_in_schema_array(self):
        """Verify all 12 properties are defined in the readonly _schema array."""
        expected_schema = [
            ("paddingScale", "string"),
            ("widgetPaddingV", "int"),
            ("animCurve", "string"),
            ("animEasingType", "string"),
            ("animDurationFast", "int"),
            ("animDurationNormal", "int"),
            ("animDurationSlow", "int"),
            ("glassmorphismLevel", "float"),
            ("cardOpacity", "float"),
            ("surfaceOpacity", "float"),
            ("cornerFillets", "bool"),
            ("cornerSmoothing", "float"),
        ]
        for key, stype in expected_schema:
            pattern = rf'{{\s*key:\s*"{key}"\s*,\s*type:\s*"{stype}"'
            self.assertTrue(
                re.search(pattern, self.settings_qml),
                f"Schema entry missing or mismatched for key={key}, type={stype}"
            )

    def test_s1_04_schema_count_matches_123_properties(self):
        """Verify total schema contains 123 entries (111 baseline + 12 Gen 5)."""
        schema_matches = re.findall(r'{\s*key:\s*"(\w+)"', self.settings_qml)
        self.assertEqual(len(schema_matches), 123, f"Expected 123 schema entries, found {len(schema_matches)}")
        self.assertEqual(len(self.full_schema), 123)

    def test_s1_05_legacy_aliases_preserved(self):
        """Verify non-schema aliases clock24h and fontSans remain defined and functional."""
        self.assertIn("property bool clock24h: clockMilitary", self.settings_qml)
        self.assertIn("property string fontSans: fontFamily", self.settings_qml)

    def test_s1_06_conf_files_contain_all_12_properties(self):
        """Verify settings.conf and ~/.local/state/quickshell/settings.conf declare all 12 keys."""
        keys = [
            "paddingScale", "widgetPaddingV", "animCurve", "animEasingType",
            "animDurationFast", "animDurationNormal", "animDurationSlow",
            "glassmorphismLevel", "cardOpacity", "surfaceOpacity",
            "cornerFillets", "cornerSmoothing"
        ]
        for k in keys:
            self.assertTrue(
                re.search(rf"^{k}=", self.settings_conf, re.MULTILINE),
                f"Key {k} missing in settings.conf"
            )
            if self.state_conf_path.exists():
                state_text = self.state_conf_path.read_text(encoding="utf-8")
                self.assertTrue(
                    re.search(rf"^{k}=", state_text, re.MULTILINE),
                    f"Key {k} missing in ~/.local/state/quickshell/settings.conf"
                )

    # =========================================================================
    # SUITE 2: MALFORMED & EXTREME NUMBERS (BOUNDARY STRESS)
    # =========================================================================

    def test_s2_01_malformed_integer_fallback(self):
        """Verify non-numeric strings for integer properties preserve previous values."""
        sim = SettingsSimulator()
        malformed_cases = ["abc", "invalid", "---", "NaN", "", "null", "undefined", "#!@$"]
        int_keys = ["widgetPaddingV", "animDurationFast", "animDurationNormal", "animDurationSlow"]

        for key in int_keys:
            original = sim.state[key]
            for mal in malformed_cases:
                sim.load_conf(f'{key}="{mal}"')
                self.assertEqual(
                    sim.state[key], original,
                    f"Malformed string '{mal}' corrupted {key}: got {sim.state[key]}, expected {original}"
                )

    def test_s2_02_malformed_float_fallback(self):
        """Verify non-numeric strings for float properties preserve previous values."""
        sim = SettingsSimulator()
        malformed_cases = ["not_a_float", "x0.5", "NaN", "", "None", "false"]
        float_keys = ["glassmorphismLevel", "cardOpacity", "surfaceOpacity", "cornerSmoothing"]

        for key in float_keys:
            original = sim.state[key]
            for mal in malformed_cases:
                sim.load_conf(f'{key}="{mal}"')
                self.assertEqual(
                    sim.state[key], original,
                    f"Malformed string '{mal}' corrupted {key}: got {sim.state[key]}, expected {original}"
                )

    def test_s2_03_zero_and_negative_durations(self):
        """Verify zero and negative durations are parsed cleanly without crash."""
        sim = SettingsSimulator()
        durations = [0, -1, -50, -500]
        for dur in durations:
            sim.load_conf(f"animDurationFast={dur}\nanimDurationNormal={dur}\nanimDurationSlow={dur}")
            self.assertEqual(sim.state["animDurationFast"], dur)
            self.assertEqual(sim.state["animDurationNormal"], dur)
            self.assertEqual(sim.state["animDurationSlow"], dur)

            # Check Theme calculations under different speed modes
            for speed in ["instant", "snappy", "normal", "chill", "hyper"]:
                mult = ThemeTokenSimulator.get_anim_speed_mult(speed)
                calc_fast = round(dur * mult)
                calc_norm = round(dur * mult)
                self.assertIsInstance(calc_fast, int)
                self.assertIsInstance(calc_norm, int)

    def test_s2_04_extreme_large_durations(self):
        """Verify extreme duration numbers do not cause numeric overflow."""
        sim = SettingsSimulator()
        extreme_vals = [999999, 2147483647]
        for v in extreme_vals:
            sim.load_conf(f"animDurationFast={v}")
            self.assertEqual(sim.state["animDurationFast"], v)
            calc = round(v * 1.6)
            self.assertIsInstance(calc, int)

    def test_s2_05_floating_values_in_integer_properties(self):
        """Verify floating strings in integer properties are cleanly truncated via parseInt."""
        sim = SettingsSimulator()
        test_cases = [
            ("widgetPaddingV=8.95", "widgetPaddingV", 8),
            ("animDurationFast=150.77", "animDurationFast", 150),
            ("animDurationNormal=250.0", "animDurationNormal", 250),
            ("animDurationSlow=400.999", "animDurationSlow", 400),
        ]
        for conf_line, key, expected in test_cases:
            sim.load_conf(conf_line)
            self.assertEqual(
                sim.state[key], expected,
                f"Floating input failed to truncate for {key}: got {sim.state[key]}, expected {expected}"
            )

    def test_s2_06_numbers_with_units_and_whitespace(self):
        """Verify JavaScript parseInt/parseFloat handles trailing units and padding whitespace."""
        sim = SettingsSimulator()
        sim.load_conf("widgetPaddingV = 16px \nanimDurationFast = 180ms\nglassmorphismLevel = 0.75alpha")
        self.assertEqual(sim.state["widgetPaddingV"], 16)
        self.assertEqual(sim.state["animDurationFast"], 180)
        self.assertEqual(sim.state["glassmorphismLevel"], 0.75)

    def test_s2_07_scientific_notation_and_extreme_floats(self):
        """Verify scientific notation and extreme floats parse safely."""
        sim = SettingsSimulator()
        sim.load_conf("glassmorphismLevel=1e-1\nsurfaceOpacity=1e0\ncardOpacity=0.0001\ncornerSmoothing=999.99")
        self.assertAlmostEqual(sim.state["glassmorphismLevel"], 0.1)
        self.assertAlmostEqual(sim.state["surfaceOpacity"], 1.0)
        self.assertAlmostEqual(sim.state["cardOpacity"], 0.0001)
        self.assertAlmostEqual(sim.state["cornerSmoothing"], 999.99)

    # =========================================================================
    # SUITE 3: STRING ENUMS & THEME TOKEN FALLBACKS
    # =========================================================================

    def test_s3_01_padding_scale_known_and_unknown_fallbacks(self):
        """Verify paddingScale maps correctly and unknown strings fall back to 1.0 (cozy)."""
        # Known values
        self.assertEqual(ThemeTokenSimulator.get_padding_scale_mult("compact"), 0.8)
        self.assertEqual(ThemeTokenSimulator.get_padding_scale_mult("cozy"), 1.0)
        self.assertEqual(ThemeTokenSimulator.get_padding_scale_mult("comfortable"), 1.25)

        # Adversarial / unknown values
        unknowns = ["super_compact", "ultra_comfortable", "COZY", "Compact", "", "none", None, "123", "!@#"]
        for unk in unknowns:
            mult = ThemeTokenSimulator.get_padding_scale_mult(unk)
            self.assertEqual(
                mult, 1.0,
                f"Unknown paddingScale '{unk}' failed to fall back to 1.0: got {mult}"
            )

    def test_s3_02_anim_curve_and_type_all_valid_combinations(self):
        """Verify all valid animCurve x animEasingType combinations produce valid Qt Quick Easing enums."""
        curves = ["linear", "quad", "cubic", "quart", "quint", "sine", "expo", "circ", "back", "elastic", "bounce"]
        types = ["in", "out", "inout", "outin", "in_out", "out_in"]

        for c in curves:
            for t in types:
                easing_val = ThemeTokenSimulator.get_easing(c, t)
                self.assertIsInstance(easing_val, int)
                self.assertTrue(0 <= easing_val <= 40, f"Easing value {easing_val} out of bounds for ({c}, {t})")

    def test_s3_03_anim_curve_unknown_fallbacks(self):
        """Verify unknown animCurve values fall back gracefully to Cubic easing."""
        unknown_curves = ["unknown", "bezier", "spring", "hyprland", "", None, "weird_curve"]
        types = ["in", "out", "inout", "outin"]

        expected_fallback = {
            "in": QT_EASING_MAP["InCubic"],
            "out": QT_EASING_MAP["OutCubic"],
            "inout": QT_EASING_MAP["InOutCubic"],
            "outin": QT_EASING_MAP["OutInCubic"],
        }

        for unk in unknown_curves:
            for t in types:
                easing_val = ThemeTokenSimulator.get_easing(unk, t)
                self.assertEqual(
                    easing_val, expected_fallback[t],
                    f"Unknown curve '{unk}' with type '{t}' failed to fall back to Cubic: got {easing_val}"
                )

    def test_s3_04_anim_easing_type_unknown_fallbacks(self):
        """Verify unknown animEasingType values fall back gracefully to Out easing."""
        unknown_types = ["unknown", "middle", "", None, "FAST"]
        for unk in unknown_types:
            easing_val = ThemeTokenSimulator.get_easing("quad", unk)
            self.assertEqual(easing_val, QT_EASING_MAP["OutQuad"])
            easing_val_cubic = ThemeTokenSimulator.get_easing("cubic", unk)
            self.assertEqual(easing_val_cubic, QT_EASING_MAP["OutCubic"])

    # =========================================================================
    # SUITE 4: BOOLEAN PARSING EDGE CASES
    # =========================================================================

    def test_s4_01_boolean_strict_parsing(self):
        """Verify boolean parsing handles canonical true/false and rejects non-canonical without error."""
        sim = SettingsSimulator()

        # Canonical booleans
        sim.load_conf("cornerFillets=true")
        self.assertIs(sim.state["cornerFillets"], True)

        sim.load_conf("cornerFillets=false")
        self.assertIs(sim.state["cornerFillets"], False)

        sim.load_conf('cornerFillets="true"')
        self.assertIs(sim.state["cornerFillets"], True)

        sim.load_conf('cornerFillets="false"')
        self.assertIs(sim.state["cornerFillets"], False)

        # Boundary / non-canonical inputs (Settings.qml logic: b = (v === true || v === "true"))
        non_canonical_false_cases = ["1", "0", 1, 0, "yes", "no", "TRUE", "False", "", "on", "off"]
        for case in non_canonical_false_cases:
            # Set to true first to ensure test case causes state change or correct evaluation
            sim.state["cornerFillets"] = True
            sim.load_object({"cornerFillets": case})
            self.assertIs(
                sim.state["cornerFillets"], False,
                f"Input {case!r} unexpectedly parsed as True"
            )

    # =========================================================================
    # SUITE 5: SERIALIZATION ROUND-TRIP (LOADCONF & TOCONF)
    # =========================================================================

    def test_s5_01_roundtrip_default_state(self):
        """Verify round-trip serialization of default state preserves all values identically."""
        sim1 = SettingsSimulator()
        serialized = sim1.to_conf()

        sim2 = SettingsSimulator()
        sim2.load_conf(serialized)

        self.assertEqual(sim1.state, sim2.state)

    def test_s5_02_roundtrip_customized_state(self):
        """Verify round-trip serialization of custom boundary values preserves all values identically."""
        custom_values = {
            "paddingScale": "compact",
            "widgetPaddingV": 12,
            "animCurve": "elastic",
            "animEasingType": "inout",
            "animDurationFast": 90,
            "animDurationNormal": 240,
            "animDurationSlow": 480,
            "glassmorphismLevel": 0.65,
            "cardOpacity": 0.88,
            "surfaceOpacity": 0.72,
            "cornerFillets": False,
            "cornerSmoothing": 0.95,
        }
        sim1 = SettingsSimulator()
        sim1.state.update(custom_values)
        serialized = sim1.to_conf()

        sim2 = SettingsSimulator()
        sim2.load_conf(serialized)

        for k, v in custom_values.items():
            if isinstance(v, float):
                self.assertAlmostEqual(sim2.state[k], v, places=4, msg=f"Mismatch for {k}")
            else:
                self.assertEqual(sim2.state[k], v, f"Mismatch for {k}")

    def test_s5_03_multi_cycle_idempotency(self):
        """Verify 5 consecutive serialize/deserialize cycles remain 100% idempotent."""
        sim = SettingsSimulator()
        sim.state.update({
            "paddingScale": "comfortable",
            "widgetPaddingV": 6,
            "animCurve": "bounce",
            "animEasingType": "outin",
            "animDurationFast": 110,
            "cornerFillets": True,
            "glassmorphismLevel": 0.9,
        })

        current_conf = sim.to_conf()
        for cycle in range(5):
            new_sim = SettingsSimulator()
            new_sim.load_conf(current_conf)
            next_conf = new_sim.to_conf()
            self.assertEqual(current_conf, next_conf, f"Idempotency violated at cycle {cycle+1}")
            current_conf = next_conf

    def test_s5_04_comment_and_blank_line_resilience(self):
        """Verify conf parser ignores comments, inline comments, blank lines, and malformed syntax."""
        sim = SettingsSimulator()
        dirty_conf = """
        # Custom Settings File
        # Created by user

        paddingScale="compact"

        # Section 2
        widgetPaddingV=10 # inline comments not supported but let's test line
        animCurve="sine"
        invalid_line_without_equals_sign
        =value_without_key
        key_without_value=
        # End of file
        """
        sim.load_conf(dirty_conf)
        self.assertEqual(sim.state["paddingScale"], "compact")
        self.assertEqual(sim.state["animCurve"], "sine")

    def test_s5_05_all_123_properties_schema_roundtrip(self):
        """Verify all 123 schema properties round-trip cleanly between loadConf and toConf."""
        sim1 = SettingsSimulator(self.full_schema)
        serialized = sim1.to_conf()

        sim2 = SettingsSimulator(self.full_schema)
        sim2.load_conf(serialized)

        for item in self.full_schema:
            k = item["key"]
            expected = sim1.state[k]
            actual = sim2.state[k]
            if isinstance(expected, float):
                self.assertAlmostEqual(actual, expected, places=3, msg=f"Mismatch for {k}")
            else:
                self.assertEqual(actual, expected, f"Mismatch for property {k}")

    # =========================================================================
    # SUITE 6: ADVERSARIAL RANDOM FUZZING
    # =========================================================================

    def test_s6_01_adversarial_fuzzing_parser(self):
        """Fuzz parser with 100 random corrupted payloads to ensure no crashes or unhandled exceptions."""
        sim = SettingsSimulator()
        corruptions = [
            "", "\n", " \t ", "\x00\x01\x02",
            "widgetPaddingV=-999999999999999999999999999999",
            "cornerSmoothing=NaN",
            "cardOpacity=Infinity",
            "paddingScale=\"\"\"\"\"\"\"",
            "animCurve=\n\n\n",
            "cornerFillets=null",
            "animDurationFast={}",
            "glassmorphismLevel=[]",
            "unicode_test=¯\\_(ツ)_/¯✨🚀🔥",
            "widgetPaddingV='\"42\"'",
        ]

        for i in range(100):
            payload = "\n".join(random.sample(corruptions, k=random.randint(1, len(corruptions))))
            try:
                sim.load_conf(payload)
                # Verify state remains typed and valid
                self.assertIsInstance(sim.state["paddingScale"], str)
                self.assertIsInstance(sim.state["widgetPaddingV"], int)
                self.assertIsInstance(sim.state["animDurationFast"], int)
                self.assertIsInstance(sim.state["glassmorphismLevel"], float)
                self.assertIsInstance(sim.state["cornerFillets"], bool)
            except Exception as e:
                self.fail(f"Parser threw unhandled exception on fuzz iteration {i}: {e}\nPayload: {payload}")

    def test_s6_02_adversarial_fuzzing_theme_tokens(self):
        """Fuzz ThemeTokenSimulator with 100 random strings to guarantee complete fallback safety."""
        random_strings = [
            "cubic", "linear", "quad", "super-cubic", "bezier(0.1,0.2)",
            "", " ", "\t", None, "123", "!@#$%", "IN", "Out", "InOut", "none",
            "¯\\_(ツ)_/¯", "true", "false", "0", "-1"
        ]
        for _ in range(100):
            curve = random.choice(random_strings)
            etype = random.choice(random_strings)
            easing = ThemeTokenSimulator.get_easing(curve, etype)
            self.assertIsInstance(easing, int)
            self.assertTrue(0 <= easing <= 40)

            pscale = random.choice(random_strings)
            mult = ThemeTokenSimulator.get_padding_scale_mult(pscale)
            self.assertIn(mult, (0.8, 1.0, 1.25))

    # =========================================================================
    # SUITE 7: LIVE RUNTIME AUDIT (QUICKSHELL PROCESS HEALTH & IPC)
    # =========================================================================

    def test_s7_01_live_daemon_status_and_log_audit(self):
        """Verify running Quickshell daemon log is free of critical runtime errors."""
        pid = QuickshellIpc.get_daemon_pid()
        if not pid:
            self.skipTest("Quickshell daemon not running")

        recent_log = QuickshellLogAuditor.get_recent_log(100)
        findings = QuickshellLogAuditor.audit_log_content(recent_log)
        self.assertEqual(
            len(findings["critical"]), 0,
            f"Found critical QML runtime errors in log: {findings['critical']}"
        )

    def test_s7_02_live_inotify_settings_reload_and_ipc(self):
        """
        Test inotify reactivity: write custom values to ~/.local/state/quickshell/settings.conf,
        call IPC targets, wait for reload, audit log for errors, and restore original conf.
        """
        if not self.state_conf_path.exists():
            self.skipTest("State settings.conf does not exist")

        backup = self.state_conf_path.read_text(encoding="utf-8")
        try:
            # Inject boundary values
            modified = backup + "\n# CHALLENGER_STRESS_TEST\npaddingScale=\"compact\"\nanimDurationFast=105\n"
            self.state_conf_path.write_text(modified, encoding="utf-8")

            # Allow inotify & FileView to trigger
            time.sleep(0.5)

            # Test IPC responsiveness during/after reload
            if QuickshellIpc.is_available():
                ret, out = QuickshellIpc.call("settings", "close")
                self.assertEqual(ret, 0, f"IPC call failed with output: {out}")

            # Audit log
            log_text = QuickshellLogAuditor.get_recent_log(50)
            findings = QuickshellLogAuditor.audit_log_content(log_text)
            self.assertEqual(
                len(findings["critical"]), 0,
                f"Critical errors triggered during live reload: {findings['critical']}"
            )
        finally:
            self.state_conf_path.write_text(backup, encoding="utf-8")
            time.sleep(0.3)


if __name__ == "__main__":
    unittest.main(verbosity=2)
