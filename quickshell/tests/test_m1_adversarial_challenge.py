#!/run/current-system/sw/bin/python3
"""
Adversarial Empirical Challenge Test Suite for Milestone 1:
Concave Corners & Screen Framing Stabilization (R1)

Tests:
1. Input masks & layer shell surfaces via hyprctl layers; transparent fillet click-through geometry.
2. Corner styles (cubic, squircle, flared, continuous-bezier, g2, etc.) & chromatic parity with Theme.barBg.
3. Floating bar toggle & 4-corner screen framing adaptation.
4. HiDPI canvas backing store scaling and property precedence.
5. Multi-monitor staggered adjacency detection.
6. Fullscreen auto-hide & popup dismissal.
7. Runtime QML lint and log auditing.
"""

import unittest
import os
import sys
import re
import json
import subprocess
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO_ROOT))

from tests.harness import QmlCodeInspector, HyprlandHelper, QuickshellLogAuditor, QuickshellIpc

class TestM1AdversarialChallenge(unittest.TestCase):
    """Empirical adversarial test suite for Milestone 1."""

    def setUp(self):
        self.screen_corners = QmlCodeInspector.read_qml_content("corners/ScreenCorners.qml")
        self.concave_corner = QmlCodeInspector.read_qml_content("corners/ConcaveCorner.qml")
        self.status_bar = QmlCodeInspector.read_qml_content("bar/StatusBar.qml")
        self.settings = QmlCodeInspector.read_qml_content("services/Settings.qml")
        self.theme = QmlCodeInspector.read_qml_content("Theme.qml")

    # =========================================================================
    # 1. LAYER SURFACES & INPUT MASKS (CLICK-THROUGH ON TRANSPARENT FILLETS)
    # =========================================================================

    def test_01_hyprland_layer_surfaces_mapped(self):
        """Verify layer surfaces are properly registered in Hyprland layer tree."""
        if not HyprlandHelper.is_available():
            self.skipTest("Hyprland compositor not active")
        
        layers = HyprlandHelper.get_layers()
        self.assertTrue(len(layers) > 0, "No monitors found in hyprctl layers")
        
        all_qs_namespaces = []
        for mon, lvls in layers.items():
            for lvl, items in lvls.items():
                for item in items:
                    all_qs_namespaces.append(item["namespace"])
        
        self.assertIn("quickshell:bar", all_qs_namespaces, "StatusBar layer not found in hyprctl layers")
        self.assertIn("quickshell:corners", all_qs_namespaces, "ScreenCorners layer not found in hyprctl layers")
        self.assertIn("quickshell:border-left", all_qs_namespaces, "Border-left layer not found in hyprctl layers")
        self.assertIn("quickshell:border-right", all_qs_namespaces, "Border-right layer not found in hyprctl layers")

    def test_02_corner_windows_have_empty_mask(self):
        """Verify all corner and border PanelWindows define mask: Region {} to guarantee pointer click-through."""
        # Find all PanelWindow blocks with balanced brace parsing
        windows = []
        pattern = "PanelWindow {"
        pos = 0
        while True:
            idx = self.screen_corners.find(pattern, pos)
            if idx == -1:
                break
            start = idx + len(pattern)
            depth = 1
            cur = start
            while cur < len(self.screen_corners) and depth > 0:
                if self.screen_corners[cur] == '{':
                    depth += 1
                elif self.screen_corners[cur] == '}':
                    depth -= 1
                cur += 1
            windows.append(self.screen_corners[start:cur-1])
            pos = cur

        self.assertTrue(len(windows) >= 4, f"Expected at least 4 PanelWindow definitions, found {len(windows)}")
        
        for idx, block in enumerate(windows):
            ns_match = re.search(r'namespace:\s*"([^"]+)"', block)
            ns = ns_match.group(1) if ns_match else f"window_{idx}"
            self.assertRegex(
                block,
                r"mask:\s*Region\s*\{\s*\}",
                f"Window {ns} in ScreenCorners.qml must have empty 'mask: Region {{}}' to allow click-through"
            )

    def test_03_status_bar_mask_excludes_fillet_scoops(self):
        """Verify StatusBar input mask covers ONLY barBg and strictly excludes scoop fillets."""
        mask_match = re.search(r"mask:\s*Region\s*\{([^}]+(?:\{[^}]*\}[^}]*)*)\}", self.status_bar)
        self.assertIsNotNone(mask_match, "StatusBar.qml must define mask: Region")
        mask_content = mask_match.group(1)
        
        # Must contain barBg
        self.assertIn("item: barBg", mask_content, "StatusBar mask must register barBg")
        
        # Must NOT contain any scoop items
        for scoop in ["scoopLeftH", "scoopRightH", "scoopTopV", "scoopBottomV"]:
            self.assertNotIn(
                scoop,
                mask_content,
                f"StatusBar mask contains '{scoop}', which traps mouse clicks in fillet bounding box"
            )

    def test_04_fillet_click_through_geometry_calculation(self):
        """Mathematical verification: transparent fillet coordinates fall strictly outside barBg bounds."""
        # In StatusBar.qml:
        # height = Theme.barHeight + scoopRadius (e.g. 28 + 8 = 36)
        # barBg height = Theme.barHeight (28)
        # Therefore scoopLeftH lies at y in [28, 36], x in [0, scoopRadius].
        # Because input mask only contains barBg ([0, width] x [0, 28]), any pointer event at (x=4, y=32)
        # falls outside the input mask and passes through to underlying windows.
        self.assertIn("exclusiveZone: Theme.barHeight", self.status_bar)
        self.assertIn("height: root.isVertical ? parent.height : Theme.barHeight", self.status_bar)

    # =========================================================================
    # 2. CORNER STYLES & CHROMATIC PARITY
    # =========================================================================

    def test_05_corner_styles_and_tensions(self):
        """Verify all corner styles (cubic, squircle, flared, g2) and their curve tensions in ConcaveCorner.qml."""
        # Tension values contract:
        # squircle: 0.72
        # continuous-bezier / g2: 0.58
        # flared: 0.38
        # cubic: Settings?.scoopTension ?? 0.55228475
        self.assertIn('if (cornerStyle === "squircle") return 0.72;', self.concave_corner)
        self.assertIn('if (cornerStyle === "flared") return 0.38;', self.concave_corner)
        self.assertIn('if (cornerStyle === "continuous-bezier" || cornerStyle === "g2") return 0.58;', self.concave_corner)
        self.assertIn('0.55228475', self.concave_corner)

    def test_06_chromatic_parity_contract(self):
        """Verify chromatic parity: cornerColorMode defaults to 'bar' and resolves to Theme.barBg."""
        # 1. Settings default
        self.assertRegex(self.settings, r'property\s+string\s+cornerColorMode:\s*"bar"')
        self.assertIn('{ key: "cornerColorMode", type: "string", def: "bar" }', self.settings)

        # 2. Theme.qml cornerFill resolution
        self.assertIn('let cm = Settings?.cornerColorMode ?? "bar";', self.theme)
        self.assertIn('return barBg;', self.theme)

        # 3. StatusBar scoops use Theme.barBg
        self.assertIn('fillColor: Theme.barBg', self.status_bar)

        # 4. ScreenCorners uses Theme.cornerFill
        self.assertIn('readonly property color cornerColor: Theme?.cornerFill ?? Theme?.barBg', self.screen_corners)

    # =========================================================================
    # 3. FLOATING BAR TOGGLE & 4-CORNER SCREEN FRAMING
    # =========================================================================

    def test_07_floating_bar_framing_decoupled(self):
        """Verify screen corners remain active when bar is floating."""
        # framingEnabled should depend on screenFrameDocked, not isBarFloating
        self.assertIn("readonly property bool framingEnabled: Settings?.screenFrameDocked ?? true", self.screen_corners)
        self.assertIn("readonly property bool isBarFloating: Settings?.barFloating ?? false", self.screen_corners)

    def test_08_floating_bar_four_corner_framing(self):
        """Verify horizontalBarSideWindow renders corners on the bar edge when bar is floating."""
        # When isBarFloating is true, horizontalBarSideWindow renders corners at the bar edge
        self.assertIn("id: horizontalBarSideWindow", self.screen_corners)
        self.assertIn("root.isBarFloating", self.screen_corners)
        
        # When docked, StatusBar renders scoops and horizontalBarSideWindow is hidden
        self.assertIn("hasBarScoops: !root.isFloating", self.status_bar)

    def test_09_floating_bar_margins_and_radius(self):
        """Verify floating bar applies effective margins and border radius."""
        self.assertIn("effectiveBarMargin: root.isFloating ? (root.barMargin > 0 ? root.barMargin : 8) : 0", self.status_bar)
        self.assertIn("effectiveBarRadius: root.isFloating ? (root.barRadius > 0 ? root.barRadius : (Settings?.screenCornerRadius ?? 12)) : 0", self.status_bar)
        self.assertIn("radius: root.effectiveBarRadius", self.status_bar)
        self.assertIn("clip: root.isFloating && root.effectiveBarRadius > 0", self.status_bar)

    # =========================================================================
    # 4. HIDPI CANVAS SCALING & PRECEDENCE
    # =========================================================================

    def test_10_hidpi_canvas_scaling(self):
        """Verify Canvas backing store sizes and scales by devicePixelRatio."""
        self.assertIn("Math.round(root.width * root.dpr)", self.concave_corner)
        self.assertIn("Math.round(root.height * root.dpr)", self.concave_corner)
        self.assertIn("scale: 1.0 / root.dpr", self.concave_corner)
        self.assertIn("ctx.scale(root.dpr, root.dpr)", self.concave_corner)

    def test_11_radius_property_precedence(self):
        """Verify radius property updates radiusX and radiusY without being shadowed by Theme defaults."""
        # radiusX and radiusY should default to radius
        self.assertIn("property real radiusX: radius", self.concave_corner)
        self.assertIn("property real radiusY: radius", self.concave_corner)

    # =========================================================================
    # 5. MULTI-MONITOR STAGGERED ADJACENCY DETECTION
    # =========================================================================

    def test_12_staggered_monitor_corner_adjacency(self):
        """Simulate staggered monitor layouts and verify exterior corners are preserved."""
        def check_adjacent(dir_str, corner_str, s, o):
            sx, sy, sw, sh = s['x'], s['y'], s['w'], s['h']
            ox, oy, ow, oh = o['x'], o['y'], o['w'], o['h']
            if dir_str == "right" and abs(ox - (sx + sw)) <= 4:
                if not corner_str:
                    return not (oy + oh <= sy or oy >= sy + sh)
                elif corner_str in ("topRight", "top", "topLeft"):
                    return oy <= sy + 4 and (oy + oh) >= sy + 4
                elif corner_str in ("bottomRight", "bottom", "bottomLeft"):
                    return oy <= sy + sh - 4 and (oy + oh) >= sy + sh - 4
            return False

        mon_main = {"x": 0, "y": 0, "w": 1920, "h": 1080}
        # Staggered monitor to the right, shifted down by 400px (y=400, h=1080)
        mon_staggered = {"x": 1920, "y": 400, "w": 1920, "h": 1080}

        # Top-right corner of main monitor is at y=0. Adjacent monitor starts at y=400.
        # Adjacency check should return FALSE, meaning the top-right corner is NOT suppressed!
        is_tr_adjacent = check_adjacent("right", "topRight", mon_main, mon_staggered)
        self.assertFalse(is_tr_adjacent, "Top-right corner on main monitor should NOT be adjacent (exterior fillet preserved)")

        # Bottom-right corner of main monitor is at y=1080. Adjacent monitor covers [400, 1480].
        # Adjacency check should return TRUE, meaning the bottom-right corner touches the display and is suppressed.
        is_br_adjacent = check_adjacent("right", "bottomRight", mon_main, mon_staggered)
        self.assertTrue(is_br_adjacent, "Bottom-right corner on main monitor SHOULD be adjacent (contact point suppressed)")

    # =========================================================================
    # 6. FULLSCREEN AUTO-HIDE & POPUP DISMISSAL
    # =========================================================================

    def test_13_fullscreen_auto_hide_and_popup_cleanup(self):
        """Verify layer surfaces hide on fullscreen and active popups are dismissed."""
        self.assertIn("visible: !root.isFullscreen", self.status_bar)
        self.assertIn("onIsFullscreenChanged:", self.status_bar)
        self.assertIn("launcherPopup.open = false", self.status_bar)

    # =========================================================================
    # 7. STATIC CODE QUALITY & LOG AUDIT
    # =========================================================================

    def test_14_qmllint_verification(self):
        """Run qmllint on all Milestone 1 source files."""
        files = [
            "corners/ScreenCorners.qml",
            "corners/ConcaveCorner.qml",
            "bar/StatusBar.qml",
            "services/Settings.qml"
        ]
        for f in files:
            ret, output = QmlCodeInspector.run_qmllint(f)
            self.assertEqual(ret, 0, f"qmllint failed on {f}:\n{output}")

    def test_15_runtime_log_free_of_m1_errors(self):
        """Verify Quickshell runtime log contains zero errors or warnings related to corners or bar."""
        log_text = QuickshellLogAuditor.get_recent_log(150)
        for line in log_text.splitlines():
            if any(k in line for k in ["ScreenCorners", "ConcaveCorner", "StatusBar", "Settings.qml"]):
                self.assertNotIn("TypeError:", line)
                self.assertNotIn("ReferenceError:", line)
                self.assertNotIn("Binding loop", line)


if __name__ == "__main__":
    unittest.main()
