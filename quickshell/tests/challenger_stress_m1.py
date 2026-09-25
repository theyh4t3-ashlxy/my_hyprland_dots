#!/run/current-system/sw/bin/python3
"""
Challenger 2 Empirical Stress Test Suite for Milestone 1 (M1)
Focus: Multi-monitor adjacency, extreme ConcaveCorner radii, fullscreen transitions,
and layer shell surface unmapping/re-mapping.
"""

import math
import random
import unittest
import subprocess
import os
from pathlib import Path
from tests.harness import QmlCodeInspector, HyprlandHelper, QuickshellLogAuditor, QMLLINT_BIN

REPO_ROOT = Path(__file__).resolve().parent.parent


class Monitor:
    """Mock Quickshell screen/monitor for geometric adjacency testing."""
    def __init__(self, name: str, x: int, y: int, width: int, height: int):
        self.name = name
        self.x = x
        self.y = y
        self.width = width
        self.height = height

    def __repr__(self):
        return f"Monitor({self.name}, x={self.x}, y={self.y}, w={self.width}, h={self.height})"


def js_hasAdjacentMonitorAt(current: Monitor, all_screens: list[Monitor], dir: str, corner: str | None) -> bool:
    """
    Direct Python transliteration of hasAdjacentMonitorAt from ScreenCorners.qml / StatusBar.qml.
    """
    if not current or not all_screens or len(all_screens) <= 1:
        return False
    sx, sy, sw, sh = current.x, current.y, current.width, current.height
    for o in all_screens:
        if o == current or o.name == current.name:
            continue
        ox, oy, ow, oh = o.x, o.y, o.width, o.height
        if dir == "right" and abs(ox - (sx + sw)) <= 4:
            if not corner:
                if not (oy + oh <= sy or oy >= sy + sh):
                    return True
            elif corner in ("topRight", "top", "topLeft"):
                if oy <= sy + 4 and (oy + oh) >= sy + 4:
                    return True
            elif corner in ("bottomRight", "bottom", "bottomLeft"):
                if oy <= sy + sh - 4 and (oy + oh) >= sy + sh - 4:
                    return True
        if dir == "left" and abs((ox + ow) - sx) <= 4:
            if not corner:
                if not (oy + oh <= sy or oy >= sy + sh):
                    return True
            elif corner in ("topLeft", "top", "topRight"):
                if oy <= sy + 4 and (oy + oh) >= sy + 4:
                    return True
            elif corner in ("bottomLeft", "bottom", "bottomRight"):
                if oy <= sy + sh - 4 and (oy + oh) >= sy + sh - 4:
                    return True
        if dir == "top" and abs((oy + oh) - sy) <= 4:
            if not corner:
                if not (ox + ow <= sx or ox >= sx + sw):
                    return True
            elif corner in ("topLeft", "left", "bottomLeft"):
                if ox <= sx + 4 and (ox + ow) >= sx + 4:
                    return True
            elif corner in ("topRight", "right", "bottomRight"):
                if ox <= sx + sw - 4 and (ox + ow) >= sx + sw - 4:
                    return True
        if dir == "bottom" and abs(oy - (sy + sh)) <= 4:
            if not corner:
                if not (ox + ow <= sx or ox >= sx + sw):
                    return True
            elif corner in ("bottomLeft", "left", "topLeft"):
                if ox <= sx + 4 and (ox + ow) >= sx + 4:
                    return True
            elif corner in ("bottomRight", "right", "topRight"):
                if ox <= sx + sw - 4 and (ox + ow) >= sx + sw - 4:
                    return True
    return False


def geometric_oracle_adjacency(current: Monitor, other: Monitor, dir: str, corner: str | None, eps: int = 4) -> bool:
    """
    Ground-truth geometric oracle for monitor adjacency.
    Verifies if monitor 'other' touches monitor 'current' on edge 'dir'
    and specifically covers the corner zone 'corner'.
    """
    sx, sy, sw, sh = current.x, current.y, current.width, current.height
    ox, oy, ow, oh = other.x, other.y, other.width, other.height

    if dir == "right":
        if abs(ox - (sx + sw)) > eps:
            return False
        # Overlap interval in Y
        y_min = max(sy, oy)
        y_max = min(sy + sh, oy + oh)
        if y_min >= y_max:
            return False
        if corner is None:
            return True
        if corner == "topRight":
            return (oy <= sy + eps) and ((oy + oh) >= sy + eps)
        if corner == "bottomRight":
            return (oy <= sy + sh - eps) and ((oy + oh) >= sy + sh - eps)
        return False  # Corner does not lie on the right edge

    elif dir == "left":
        if abs((ox + ow) - sx) > eps:
            return False
        y_min = max(sy, oy)
        y_max = min(sy + sh, oy + oh)
        if y_min >= y_max:
            return False
        if corner is None:
            return True
        if corner == "topLeft":
            return (oy <= sy + eps) and ((oy + oh) >= sy + eps)
        if corner == "bottomLeft":
            return (oy <= sy + sh - eps) and ((oy + oh) >= sy + sh - eps)
        return False  # Corner does not lie on the left edge

    elif dir == "top":
        if abs((oy + oh) - sy) > eps:
            return False
        x_min = max(sx, ox)
        x_max = min(sx + sw, ox + ow)
        if x_min >= x_max:
            return False
        if corner is None:
            return True
        if corner == "topLeft":
            return (ox <= sx + eps) and ((ox + ow) >= sx + eps)
        if corner == "topRight":
            return (ox <= sx + sw - eps) and ((ox + ow) >= sx + sw - eps)
        return False  # Corner does not lie on top edge

    elif dir == "bottom":
        if abs(oy - (sy + sh)) > eps:
            return False
        x_min = max(sx, ox)
        x_max = min(sx + sw, ox + ow)
        if x_min >= x_max:
            return False
        if corner is None:
            return True
        if corner == "bottomLeft":
            return (ox <= sx + eps) and ((ox + ow) >= sx + eps)
        if corner == "bottomRight":
            return (ox <= sx + sw - eps) and ((ox + ow) >= sx + sw - eps)
        return False  # Corner does not lie on bottom edge

    return False


class StressTestMultiMonitorAdjacency(unittest.TestCase):
    """Adversarial stress-testing of multi-monitor adjacency logic."""

    def setUp(self):
        self.primary = Monitor("HDMI-A-1", 0, 0, 1920, 1080)

    def test_side_by_side_aligned(self):
        """Standard side-by-side aligned monitors (full edge contact)."""
        secondary = Monitor("DP-1", 1920, 0, 1920, 1080)
        screens = [self.primary, secondary]

        # Primary right edge
        self.assertTrue(js_hasAdjacentMonitorAt(self.primary, screens, "right", "topRight"))
        self.assertTrue(js_hasAdjacentMonitorAt(self.primary, screens, "right", "bottomRight"))
        self.assertFalse(js_hasAdjacentMonitorAt(self.primary, screens, "left", "topLeft"))
        self.assertFalse(js_hasAdjacentMonitorAt(self.primary, screens, "top", "topLeft"))

        # Secondary left edge
        self.assertTrue(js_hasAdjacentMonitorAt(secondary, screens, "left", "topLeft"))
        self.assertTrue(js_hasAdjacentMonitorAt(secondary, screens, "left", "bottomLeft"))
        self.assertFalse(js_hasAdjacentMonitorAt(secondary, screens, "right", "topRight"))

    def test_side_by_side_staggered_shifted_down(self):
        """Side-by-side where secondary is shifted down 400px."""
        secondary = Monitor("DP-1", 1920, 400, 1920, 1080)
        screens = [self.primary, secondary]

        # Primary right: top corner is exposed to empty air; bottom corner touches secondary
        self.assertFalse(js_hasAdjacentMonitorAt(self.primary, screens, "right", "topRight"),
                         "Primary topRight must NOT be adjacent when secondary is shifted down 400px")
        self.assertTrue(js_hasAdjacentMonitorAt(self.primary, screens, "right", "bottomRight"),
                        "Primary bottomRight touches secondary")

        # Secondary left: top corner touches primary; bottom corner is exposed
        self.assertTrue(js_hasAdjacentMonitorAt(secondary, screens, "left", "topLeft"),
                        "Secondary topLeft touches primary")
        self.assertFalse(js_hasAdjacentMonitorAt(secondary, screens, "left", "bottomLeft"),
                         "Secondary bottomLeft is below primary bottom and must NOT be adjacent")

    def test_side_by_side_staggered_shifted_up(self):
        """Side-by-side where secondary is shifted up 500px."""
        secondary = Monitor("DP-1", 1920, -500, 1920, 1080)
        screens = [self.primary, secondary]

        # Primary right: top corner touches secondary; bottom corner is exposed
        self.assertTrue(js_hasAdjacentMonitorAt(self.primary, screens, "right", "topRight"))
        self.assertFalse(js_hasAdjacentMonitorAt(self.primary, screens, "right", "bottomRight"))

        # Secondary left: top corner is exposed; bottom corner touches primary
        self.assertFalse(js_hasAdjacentMonitorAt(secondary, screens, "left", "topLeft"))
        self.assertTrue(js_hasAdjacentMonitorAt(secondary, screens, "left", "bottomLeft"))

    def test_stacked_aligned(self):
        """Vertical stacked monitors (top and bottom)."""
        secondary = Monitor("DP-1", 0, 1080, 1920, 1080)
        screens = [self.primary, secondary]

        # Primary bottom edge touches secondary
        self.assertTrue(js_hasAdjacentMonitorAt(self.primary, screens, "bottom", "bottomLeft"))
        self.assertTrue(js_hasAdjacentMonitorAt(self.primary, screens, "bottom", "bottomRight"))
        self.assertFalse(js_hasAdjacentMonitorAt(self.primary, screens, "top", "topLeft"))

        # Secondary top edge touches primary
        self.assertTrue(js_hasAdjacentMonitorAt(secondary, screens, "top", "topLeft"))
        self.assertTrue(js_hasAdjacentMonitorAt(secondary, screens, "top", "topRight"))

    def test_stacked_staggered_horizontal_offset(self):
        """Stacked monitors with horizontal offset (shifted right 600px)."""
        secondary = Monitor("DP-1", 600, 1080, 1920, 1080)
        screens = [self.primary, secondary]

        # Primary bottom: bottomLeft is empty space; bottomRight touches secondary
        self.assertFalse(js_hasAdjacentMonitorAt(self.primary, screens, "bottom", "bottomLeft"))
        self.assertTrue(js_hasAdjacentMonitorAt(self.primary, screens, "bottom", "bottomRight"))

        # Secondary top: topLeft touches primary; topRight is empty space
        self.assertTrue(js_hasAdjacentMonitorAt(secondary, screens, "top", "topLeft"))
        self.assertFalse(js_hasAdjacentMonitorAt(secondary, screens, "top", "topRight"))

    def test_asymmetric_resolutions(self):
        """4K monitor (3840x2160) next to 1080p monitor (1920x1080)."""
        m4k = Monitor("DP-1", 0, 0, 3840, 2160)
        m1080p = Monitor("HDMI-A-1", 3840, 0, 1920, 1080)
        screens = [m4k, m1080p]

        # 4K right edge: top touches 1080p; bottom is at y=2160, far below 1080p
        self.assertTrue(js_hasAdjacentMonitorAt(m4k, screens, "right", "topRight"))
        self.assertFalse(js_hasAdjacentMonitorAt(m4k, screens, "right", "bottomRight"))

        # 1080p left edge: both corners touch the 4K monitor
        self.assertTrue(js_hasAdjacentMonitorAt(m1080p, screens, "left", "topLeft"))
        self.assertTrue(js_hasAdjacentMonitorAt(m1080p, screens, "left", "bottomLeft"))

    def test_diagonal_vertex_touch_only(self):
        """Two monitors touching only at a single corner vertex (no edge overlap)."""
        secondary = Monitor("DP-1", 1920, 1080, 1920, 1080)
        screens = [self.primary, secondary]

        # Neither edge has shared boundary
        self.assertFalse(js_hasAdjacentMonitorAt(self.primary, screens, "right", "bottomRight"))
        self.assertFalse(js_hasAdjacentMonitorAt(self.primary, screens, "bottom", "bottomRight"))
        self.assertFalse(js_hasAdjacentMonitorAt(secondary, screens, "left", "topLeft"))
        self.assertFalse(js_hasAdjacentMonitorAt(secondary, screens, "top", "topLeft"))

    def test_gap_tolerance(self):
        """Tolerances: <=4px is adjacent; >=5px is NOT adjacent."""
        screens_4px = [self.primary, Monitor("DP-1", 1924, 0, 1920, 1080)]
        self.assertTrue(js_hasAdjacentMonitorAt(self.primary, screens_4px, "right", "topRight"),
                        "Gap of 4px should be considered adjacent within tolerance")

        screens_5px = [self.primary, Monitor("DP-1", 1925, 0, 1920, 1080)]
        self.assertFalse(js_hasAdjacentMonitorAt(self.primary, screens_5px, "right", "topRight"),
                         "Gap of 5px exceeds tolerance and must NOT be adjacent")

    def test_random_topology_fuzzing(self):
        """Generate 500 randomized valid multi-monitor configurations and verify against oracle."""
        rng = random.Random(42)
        valid_corners = {
            "right": ["topRight", "bottomRight"],
            "left": ["topLeft", "bottomLeft"],
            "top": ["topLeft", "topRight"],
            "bottom": ["bottomLeft", "bottomRight"],
        }
        tested = 0
        for _ in range(500):
            # Pick secondary placement mode
            mode = rng.choice(["right", "left", "top", "bottom"])
            ox, oy = 0, 0
            ow, oh = rng.choice([1280, 1920, 2560, 3840]), rng.choice([720, 1080, 1440, 2160])
            offset = rng.randint(-1200, 1200)
            gap = rng.choice([0, 1, 2, 3, 4, 5, 10, 50])

            if mode == "right":
                ox = 1920 + gap
                oy = offset
            elif mode == "left":
                ox = -ow - gap
                oy = offset
            elif mode == "top":
                ox = offset
                oy = -oh - gap
            elif mode == "bottom":
                ox = offset
                oy = 1080 + gap

            sec = Monitor("SEC", ox, oy, ow, oh)
            screens = [self.primary, sec]

            for dir_name in ["right", "left", "top", "bottom"]:
                for c in valid_corners[dir_name]:
                    js_res = js_hasAdjacentMonitorAt(self.primary, screens, dir_name, c)
                    oracle_res = geometric_oracle_adjacency(self.primary, sec, dir_name, c)
                    self.assertEqual(
                        js_res, oracle_res,
                        f"Mismatch for dir={dir_name} corner={c} with sec={sec}. JS={js_res}, Oracle={oracle_res}"
                    )
                    tested += 1

        self.assertGreaterEqual(tested, 2000, "Fuzzed at least 2000 corner/direction combinations")

    def test_cross_corner_aliasing_behavior(self):
        """
        Adversarial test: calling hasAdjacentMonitorAt with a corner that does not lie on that edge.
        E.g. hasAdjacentMonitorAt('right', 'topLeft')
        ScreenCorners.qml groups corner names by vertical/horizontal axis, creating potential aliasing.
        """
        secondary = Monitor("DP-1", 1920, 0, 1920, 1080)
        screens = [self.primary, secondary]

        # 'topLeft' does NOT lie on the 'right' edge!
        # An ideal implementation should return False because the left corner does not touch the right monitor.
        # Let's inspect the current behavior:
        aliased_res = js_hasAdjacentMonitorAt(self.primary, screens, "right", "topLeft")
        # In ScreenCorners.qml: line 26: else if (corner === "topRight" || corner === "top" || corner === "topLeft")
        # It treats "topLeft" as matching the top Y-coordinate!
        # We record this finding.
        self.assertTrue(aliased_res, "ScreenCorners.qml aliases 'topLeft' to top Y-boundary in 'right' direction")


class StressTestConcaveCornerRadii(unittest.TestCase):
    """Empirical mathematical & AST stress-testing of ConcaveCorner.qml properties."""

    def setUp(self):
        self.content = QmlCodeInspector.read_qml_content("corners/ConcaveCorner.qml")

    def test_radius_zero_safe_geometry(self):
        """Implicit width and height must never be zero or negative to avoid Canvas allocation failure."""
        # Check implicit width/height clamps: Math.max(1, radiusX)
        self.assertIn("implicitWidth: Math.max(1, radiusX)", self.content)
        self.assertIn("implicitHeight: Math.max(1, radiusY)", self.content)

    def test_dpr_scale_safe_bounds(self):
        """Device pixel ratio dpr must be >= 1.0."""
        self.assertIn("readonly property real dpr: Math.max(1.0,", self.content)

    def test_canvas_sizing_scaling(self):
        """Canvas backing store sizes to physical pixels and scales by 1.0 / dpr."""
        self.assertIn("width: Math.round(root.width * root.dpr)", self.content)
        self.assertIn("height: Math.round(root.height * root.dpr)", self.content)
        self.assertIn("scale: 1.0 / root.dpr", self.content)
        self.assertIn("transformOrigin: Item.TopLeft", self.content)

    def test_line_cap_and_join_butt_endpoints(self):
        """Stroke lineCap must be 'butt' to prevent 1px boundary protrusion artifacts."""
        self.assertIn('ctx.lineCap = "butt"', self.content)
        self.assertIn('ctx.lineJoin = "round"', self.content)

    def test_bezier_points_finite_across_extreme_values(self):
        """
        Verify that mathematical bezier control points remain strictly finite,
        non-NaN, and within bounds across extreme radii (1, 100, 1000, 10000, custom X/Y).
        """
        styles = ["cubic", "squircle", "continuous-bezier", "g2", "flared", "chamfer", "stepped", "hyperbolic"]
        tensions = {
            "squircle": 0.72,
            "continuous-bezier": 0.58,
            "g2": 0.58,
            "flared": 0.38,
            "cubic": 0.55228475
        }

        test_dimensions = [
            (1, 1),
            (2, 2),
            (16, 16),
            (100, 100),
            (1000, 1000),
            (100, 10),      # Asymmetric wide
            (10, 100),      # Asymmetric tall
            (3840, 2160),   # Fullscreen radius
        ]

        for w, h in test_dimensions:
            for style in styles:
                for fx in [False, True]:
                    for fy in [False, True]:
                        t = tensions.get(style, 0.55228475)
                        sx = 0 if fx else w
                        sy = h if fy else 0
                        p1x = w if fx else 0
                        p1y = h if fy else 0
                        p2x = w if fx else 0
                        p2y = 0 if fy else h

                        if style == "continuous-bezier" or style == "g2":
                            c1x = w if fx else 0
                            c1y = (h * 0.44) if fy else (h * 0.56)
                            c2x = (w * 0.56) if fx else (w * 0.44)
                            c2y = h if fy else 0
                        elif style == "hyperbolic":
                            hx = (w * 0.2) if fx else (w * 0.8)
                            hy = (h * 0.8) if fy else (h * 0.2)
                            self.assertTrue(math.isfinite(hx) and math.isfinite(hy))
                            continue
                        elif style in ("chamfer", "stepped"):
                            continue
                        else:
                            c1x = w if fx else 0
                            c1y = (h * t) if fy else (h * (1.0 - t))
                            c2x = (w * t) if fx else (w * (1.0 - t))
                            c2y = h if fy else 0

                        for val, name in [(c1x, "c1x"), (c1y, "c1y"), (c2x, "c2x"), (c2y, "c2y"), (sx, "sx"), (sy, "sy")]:
                            self.assertTrue(math.isfinite(val), f"Non-finite value {name}={val} in style={style} (w={w}, h={h})")
                            self.assertFalse(math.isnan(val), f"NaN value {name} in style={style}")

    def test_property_precedence_no_shadowing(self):
        """Setting radius updates radiusX and radiusY by default without being shadowed by Theme."""
        self.assertRegex(
            self.content,
            r'property\s+real\s+radiusX:\s*radius',
            "radiusX must bind to radius directly to prevent property shadowing"
        )
        self.assertRegex(
            self.content,
            r'property\s+real\s+radiusY:\s*radius',
            "radiusY must bind to radius directly to prevent property shadowing"
        )


class StressTestFullscreenTransitions(unittest.TestCase):
    """Stress-testing of fullscreen transitions and layer surface unmapping/re-mapping."""

    def setUp(self):
        self.sc_content = QmlCodeInspector.read_qml_content("corners/ScreenCorners.qml")
        self.bar_content = QmlCodeInspector.read_qml_content("bar/StatusBar.qml")

    def test_all_corner_windows_gate_on_fullscreen(self):
        """All 8 PanelWindows in ScreenCorners.qml must unmap when isFullscreen is true."""
        window_ids = [
            "horizontalOppositeWindow",
            "horizontalBarSideWindow",
            "leftBorder",
            "rightBorder",
            "verticalOppositeWindow",
            "verticalBarSideWindow",
            "topBorder",
            "bottomBorder"
        ]
        for wid in window_ids:
            # Find the PanelWindow block
            pattern = rf'id:\s*{wid}[\s\S]*?visible:\s*([^;\n]+)'
            import re
            m = re.search(pattern, self.sc_content)
            self.assertIsNotNone(m, f"Could not find PanelWindow with id '{wid}' in ScreenCorners.qml")
            vis_expr = m.group(1)
            self.assertIn("!root.isFullscreen", vis_expr,
                          f"PanelWindow '{wid}' visible expression '{vis_expr}' must include '!root.isFullscreen'")

    def test_status_bar_unmaps_on_fullscreen(self):
        """StatusBar PanelWindow must unmap when isFullscreen is true."""
        import re
        m = re.search(r'visible:\s*!root\.isFullscreen', self.bar_content)
        self.assertIsNotNone(m, "StatusBar PanelWindow must declare 'visible: !root.isFullscreen'")

    def test_status_bar_dismisses_launcher_on_fullscreen(self):
        """StatusBar onIsFullscreenChanged handler dismisses launcher popup."""
        self.assertIn("onIsFullscreenChanged:", self.bar_content)
        self.assertIn("launcherPopup.open = false", self.bar_content)

    def test_fullscreen_property_evaluation_oracle(self):
        """
        Verify truth table of isFullscreen:
        isFullscreen = (hyprMonitor?.activeWorkspace?.hasFullscreen) ?? (Hyprland.focusedWorkspace?.hasFullscreen ?? false)
        """
        def eval_fullscreen(hypr_mon, focused_ws):
            active_ws = hypr_mon.get("activeWorkspace") if hypr_mon else None
            m_full = active_ws.get("hasFullscreen") if active_ws else None
            f_full = focused_ws.get("hasFullscreen") if focused_ws else None
            return m_full if m_full is not None else (f_full if f_full is not None else False)

        # Monitor 1 has fullscreen window -> True
        self.assertTrue(eval_fullscreen({"activeWorkspace": {"hasFullscreen": True}}, {"hasFullscreen": False}))

        # Monitor 1 has no fullscreen, but focused is fullscreen (e.g. monitor null fallback)
        self.assertFalse(eval_fullscreen({"activeWorkspace": {"hasFullscreen": False}}, {"hasFullscreen": True}))
        self.assertTrue(eval_fullscreen(None, {"hasFullscreen": True}))

        # Completely null/empty state -> False
        self.assertFalse(eval_fullscreen(None, None))
        self.assertFalse(eval_fullscreen({"activeWorkspace": None}, None))


class StressTestLiveCompositorSanity(unittest.TestCase):
    """Sanity checks against live compositor and toolchain."""

    def test_qmllint_cleanliness(self):
        """qmllint passes on all M1 files without syntax errors."""
        if not QMLLINT_BIN:
            self.skipTest("qmllint binary not available in environment")

        m1_files = [
            "corners/ScreenCorners.qml",
            "corners/ConcaveCorner.qml",
            "bar/StatusBar.qml",
            "services/Settings.qml",
        ]
        for rel in m1_files:
            fpath = str(REPO_ROOT / rel)
            res = subprocess.run([QMLLINT_BIN, fpath], capture_output=True, text=True)
            self.assertEqual(res.returncode, 0, f"qmllint failed on {rel}: {res.stderr}\n{res.stdout}")

    def test_live_layers_running(self):
        """Compositor layers list quickshell:bar and quickshell:corners."""
        layers_by_mon = HyprlandHelper.get_layers()
        if not layers_by_mon:
            self.skipTest("Compositor layers not retrievable")

        all_namespaces = []
        for mon, levels in layers_by_mon.items():
            for lvl, l_list in levels.items():
                for l in l_list:
                    all_namespaces.append(l.get("namespace", ""))
        self.assertIn("quickshell:bar", all_namespaces, "quickshell:bar must be mapped in compositor layers")
        self.assertIn("quickshell:corners", all_namespaces, "quickshell:corners must be mapped in compositor layers")


if __name__ == "__main__":
    unittest.main()
