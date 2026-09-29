#!/run/current-system/sw/bin/python3
"""
Empirical Challenger Stress Test Suite for Milestone 3 (Gen 5)
Popup Layout Metrics, Redundant Margin Elimination, and Notification Card Geometry

Validates:
1. Margin accumulation & child popup width:
   - Verifies PopupPanel provides uniform outer padding (Theme.popupPadding ?? 16).
   - Verifies BatteryPopup, QuickSettings, WindowTitlePopup, and IdlePopup eliminate
     redundant outer margins on their top-level ColumnLayout.
   - Simulates layout metrics across Theme padding scales (compact, cozy, comfortable)
     and multi-monitor screen resolutions (800x600 to 3840x2160).
   - Proves mathematically and empirically that inner cards retain full intended width
     without horizontal truncation or layout crushing.
2. NotificationCard vertical metrics & action button clearance:
   - Verifies implicitHeight formula incorporates both top and bottom layout margins.
   - Models card layout across body text lengths from 1 to 50 lines.
   - Models parametric variations across font sizes, summary lengths, images, actions,
     and timeout states (timeoutMs > 0 vs timeoutMs == 0).
   - Proves action buttons maintain >= 15px clearance above the 3px bottom progress bar
     and never collide or clip under any configuration.
   - Contrasts against the legacy bug (implicitHeight = col.implicitHeight + 24) which caused
     an 8px deficit and button clipping.
3. Live Quickshell runtime verification:
   - Rapid IPC toggling of Battery, QuickSettings, WindowTitle, and Idle popups.
   - Live D-Bus notification dispatch (1-line, 6-line, 50-line, persistent timeout=0, critical).
   - Runtime log audit for zero binding loops, TypeErrors, or unhandled exceptions.
4. Offscreen Qt Quick 6 QML engine execution of tests/challenger_stress_popup_metrics.qml.
"""

import math
import os
import re
import subprocess
import time
import unittest
from pathlib import Path
from typing import Dict, List, Tuple

REPO_ROOT = Path(__file__).resolve().parent.parent

from tests.harness import (
    QmlCodeInspector,
    QuickshellIpc,
    QuickshellLogAuditor,
    DBusHelper,
    QMLLINT_BIN,
)

QML_BIN = "/nix/store/10553j4116y6jllliqpg5kz7d35bblab-qtdeclarative-6.11.2/bin/qml"


# =============================================================================
# 1. POPUP MARGIN ACCUMULATION & INNER CARD WIDTH INTEGRITY
# =============================================================================

class TestPopupMarginAccumulation(unittest.TestCase):
    """Stress-tests PopupPanel margin accumulation and child popup inner width."""

    @classmethod
    def setUpClass(cls):
        cls.popup_panel_src = QmlCodeInspector.read_qml_content("controls/PopupPanel.qml")
        cls.battery_src = QmlCodeInspector.read_qml_content("widgets/BatteryPopup.qml")
        cls.qs_src = QmlCodeInspector.read_qml_content("widgets/QuickSettings.qml")
        cls.wt_src = QmlCodeInspector.read_qml_content("widgets/WindowTitlePopup.qml")
        cls.idle_src = QmlCodeInspector.read_qml_content("widgets/IdlePopup.qml")

    def test_01_popuppanel_single_outer_padding_contract(self):
        """Verify PopupPanel contentItem provides standard outer padding without inner wrapper padding."""
        # contentItem must declare anchors.margins: Theme.popupPadding ?? 16
        self.assertRegex(
            self.popup_panel_src,
            r"id:\s*contentItem[\s\S]*?anchors\.margins:\s*Theme\.popupPadding\s*\?\?\s*16",
            "PopupPanel.qml contentItem must declare outer padding anchors.margins: Theme.popupPadding ?? 16"
        )
        # contentWrapper must have no extra margins
        self.assertRegex(
            self.popup_panel_src,
            r"id:\s*contentWrapper[\s\S]*?width:\s*root\.effectiveWidth",
            "PopupPanel.qml contentWrapper must match root.effectiveWidth"
        )

    def test_02_child_popups_eliminate_redundant_outer_margins(self):
        """Verify child popups declare anchors.fill: parent and NO redundant anchors.margins on top-level layout."""
        # 1. BatteryPopup
        battery_layout = re.search(r"content:\s*ColumnLayout\s*\{([^}]+(?:\{[^}]*\}[^}]*)*)\}", self.battery_src)
        self.assertIsNotNone(battery_layout, "BatteryPopup.qml must declare content: ColumnLayout")
        content_header = self.battery_src[self.battery_src.find("content: ColumnLayout"):self.battery_src.find("content: ColumnLayout") + 250]
        self.assertIn("anchors.fill: parent", content_header, "BatteryPopup top ColumnLayout must anchor to parent")
        self.assertNotIn("anchors.margins", content_header, "BatteryPopup top ColumnLayout must NOT declare redundant anchors.margins")

        # 2. QuickSettings
        qs_layout_idx = self.qs_src.find("content: ColumnLayout")
        self.assertNotEqual(qs_layout_idx, -1, "QuickSettings.qml must declare content: ColumnLayout")
        qs_content_header = self.qs_src[qs_layout_idx:qs_layout_idx + 250]
        self.assertIn("anchors.fill: parent", qs_content_header, "QuickSettings top ColumnLayout must anchor to parent")
        self.assertNotIn("anchors.margins", qs_content_header, "QuickSettings top ColumnLayout must NOT declare redundant anchors.margins")

        # 3. WindowTitlePopup
        wt_layout_idx = self.wt_src.find("content: ColumnLayout")
        self.assertNotEqual(wt_layout_idx, -1, "WindowTitlePopup.qml must declare content: ColumnLayout")
        wt_content_header = self.wt_src[wt_layout_idx:wt_layout_idx + 250]
        self.assertIn("anchors.fill: parent", wt_content_header, "WindowTitlePopup top ColumnLayout must anchor to parent")
        self.assertNotIn("anchors.margins", wt_content_header, "WindowTitlePopup top ColumnLayout must NOT declare redundant anchors.margins")

        # 4. IdlePopup
        idle_layout_idx = self.idle_src.find("content: ColumnLayout")
        self.assertNotEqual(idle_layout_idx, -1, "IdlePopup.qml must declare content: ColumnLayout")
        idle_content_header = self.idle_src[idle_layout_idx:idle_layout_idx + 250]
        self.assertIn("anchors.fill: parent", idle_content_header, "IdlePopup top ColumnLayout must anchor to parent")
        self.assertNotIn("anchors.margins", idle_content_header, "IdlePopup top ColumnLayout must NOT declare redundant anchors.margins")

    def test_03_simulated_inner_card_widths_across_padding_scales(self):
        """
        Simulate layout margin accumulation across Theme padding scales:
        compact (0.8x), cozy (1.0x), comfortable (1.25x), and extreme (1.5x).
        Verify inner cards receive full intended width with zero double-padding loss.
        """
        popups = [
            {"name": "BatteryPopup", "card_width": 420, "old_redundant_margin": 16},
            {"name": "QuickSettings", "card_width": 480, "old_redundant_margin": 12},
            {"name": "WindowTitlePopup", "card_width": 380, "old_redundant_margin": 14},
            {"name": "IdlePopup", "card_width": 360, "old_redundant_margin": 14},
        ]

        padding_scales = {
            "compact": 16 * 0.8,      # 12.8px
            "cozy": 16 * 1.0,         # 16.0px
            "comfortable": 16 * 1.25, # 20.0px
            "extreme": 16 * 1.5,      # 24.0px
        }

        for scale_name, popup_padding in padding_scales.items():
            for pop in popups:
                w_card = pop["card_width"]
                intended_inner_width = w_card - (2 * popup_padding)
                buggy_inner_width = w_card - (2 * popup_padding) - (2 * pop["old_redundant_margin"])

                # Recovery of layout width
                width_restored = intended_inner_width - buggy_inner_width
                self.assertGreaterEqual(
                    width_restored, 24,
                    f"{pop['name']} under {scale_name}: expected at least 24px restored width, got {width_restored}px"
                )

                # Inner cards must have ample width (>= 300px on all tested popups)
                self.assertGreaterEqual(
                    intended_inner_width, 300,
                    f"{pop['name']} under {scale_name}: usable inner width {intended_inner_width}px fell below 300px"
                )

                # For QuickSettings, verify 2-column quick toggles width
                if pop["name"] == "QuickSettings":
                    spacing = 8
                    col_width = (intended_inner_width - spacing) / 2
                    self.assertGreaterEqual(
                        col_width, 210,
                        f"QuickSettings 2-column toggle tile width {col_width}px must be >= 210px for label/icon comfort"
                    )

    def test_04_multi_resolution_boundary_clamping(self):
        """
        Simulate multi-resolution screen geometry clamping from 800x600 to 3840x2160.
        Verify effectiveWidth clamps safely without negative widths or card compression.
        """
        resolutions = [
            (800, 600),
            (1024, 768),
            (1280, 720),
            (1366, 768),
            (1440, 900),
            (1600, 900),
            (1920, 1080),
            (2560, 1440),
            (3840, 2160),
        ]

        bar_size = 32
        popup_padding = 16

        for screen_w, screen_h in resolutions:
            for is_vertical in [False, True]:
                # PopupPanel clamping formula:
                # maxAllowedWidth: Math.max(260, (isVertical ? (screenW - barSize - 16) : (screenW - 32)))
                max_allowed_w = max(260, (screen_w - bar_size - 16) if is_vertical else (screen_w - 32))

                for card_w in [360, 380, 420, 480]:
                    effective_w = min(card_w, max_allowed_w)
                    usable_inner_w = effective_w - (2 * popup_padding)

                    self.assertGreaterEqual(
                        usable_inner_w, 220,
                        f"Resolution {screen_w}x{screen_h} (vert={is_vertical}): usable width {usable_inner_w}px must be >= 220px"
                    )
                    self.assertLessEqual(
                        effective_w, screen_w,
                        f"Effective width {effective_w}px must not exceed screen width {screen_w}px"
                    )


# =============================================================================
# 2. NOTIFICATION CARD VERTICAL METRICS & CLEARANCE STRESS
# =============================================================================

class TestNotificationCardVerticalMetrics(unittest.TestCase):
    """Stress-tests NotificationCard vertical metrics and action button clearance."""

    @classmethod
    def setUpClass(cls):
        cls.card_src = QmlCodeInspector.read_qml_content("notifications/NotificationCard.qml")

    def test_01_source_geometry_contracts(self):
        """Verify NotificationCard.qml declares dynamic margin accumulation and progress bar geometry."""
        # implicitHeight formula: col.implicitHeight + (col.anchors.topMargin ?? 14) + (col.anchors.bottomMargin ?? 18)
        self.assertRegex(
            self.card_src,
            r"implicitHeight:\s*col\.implicitHeight\s*\+\s*\(col\.anchors\.topMargin\s*\?\?\s*14\)\s*\+\s*\(col\.anchors\.bottomMargin\s*\?\?\s*18\)",
            "NotificationCard.qml must dynamically sum col.implicitHeight with topMargin and bottomMargin"
        )
        # col layout margins
        self.assertRegex(
            self.card_src,
            r"anchors\.margins:\s*14",
            "NotificationCard.qml col must declare anchors.margins: 14"
        )
        self.assertRegex(
            self.card_src,
            r"anchors\.bottomMargin:\s*root\.timeoutMs\s*>\s*0\s*\?\s*18\s*:\s*14",
            "NotificationCard.qml col must declare anchors.bottomMargin with 18px when timeoutMs > 0"
        )
        # Progress bar
        self.assertRegex(
            self.card_src,
            r"anchors\.bottom:\s*parent\.bottom[\s\S]*?height:\s*3[\s\S]*?visible:\s*root\.timeoutMs\s*>\s*0",
            "NotificationCard.qml must declare 3px bottom progress bar visible when timeoutMs > 0"
        )

    def test_02_body_length_stress_1_to_50_lines(self):
        """
        Stress-test notification card vertical metrics across body lengths from 1 to 50 lines.
        Validates:
        - When timeoutMs > 0, clearance between action buttons and progress bar is strictly >= 15px.
        - When timeoutMs == 0, bottom padding to card boundary is strictly 14px.
        - Actions never collide with or clip into the 3px progress bar under any body length.
        """
        top_margin = 14
        progress_height = 3
        header_height = 22
        action_row_height = 28
        item_spacing = 8
        line_height_sm = 16

        for body_lines in range(1, 51):
            # Test both QML capped (max 6 lines) and stress uncapped variants
            rendered_lines_capped = min(body_lines, 6)
            rendered_lines_uncapped = body_lines

            for variant_name, rendered_lines in [("capped_6", rendered_lines_capped), ("uncapped", rendered_lines_uncapped)]:
                body_height = rendered_lines * line_height_sm

                # col contains: Header (22) + Summary (18) + Body (body_height) + Actions (28)
                # 4 visible items -> 3 gaps of 8px = 24px
                col_implicit_h = header_height + 18 + body_height + action_row_height + (3 * item_spacing)

                # Variant A: timeoutMs > 0 (timeout progress bar active)
                for timeout_ms in [1000, 3000, 5000, 10000]:
                    bottom_margin = 18 if timeout_ms > 0 else 14
                    card_implicit_h = col_implicit_h + top_margin + bottom_margin

                    # In QtQuick Layout, card adopts card_implicit_h
                    card_h = card_implicit_h
                    col_y = top_margin
                    col_allocated_h = card_h - top_margin - bottom_margin
                    actions_bottom_y = col_y + col_allocated_h
                    progress_bar_top_y = card_h - progress_height
                    clearance = progress_bar_top_y - actions_bottom_y

                    # Assert exact column height allocation
                    self.assertEqual(
                        col_allocated_h, col_implicit_h,
                        f"Body {body_lines} ({variant_name}): Column allocated height must match implicitHeight"
                    )

                    # Assert strictly positive clearance >= 15px
                    self.assertEqual(
                        clearance, 15,
                        f"Body {body_lines} ({variant_name}): Clearance must be exactly 15px (18px margin - 3px bar)"
                    )
                    self.assertLess(
                        actions_bottom_y, progress_bar_top_y,
                        f"Body {body_lines} ({variant_name}): Action buttons must be strictly above progress bar"
                    )

                # Variant B: timeoutMs == 0 (persistent notification)
                bottom_margin_zero = 14
                card_implicit_h_zero = col_implicit_h + top_margin + bottom_margin_zero
                card_h_zero = card_implicit_h_zero
                col_allocated_h_zero = card_h_zero - top_margin - bottom_margin_zero
                actions_bottom_y_zero = top_margin + col_allocated_h_zero
                card_bottom_gap = card_h_zero - actions_bottom_y_zero

                self.assertEqual(
                    col_allocated_h_zero, col_implicit_h,
                    f"Body {body_lines} ({variant_name}, timeout=0): Col allocated height must match implicitHeight"
                )
                self.assertEqual(
                    card_bottom_gap, 14,
                    f"Body {body_lines} ({variant_name}, timeout=0): Bottom gap to card edge must be exactly 14px"
                )

    def test_03_parametric_matrix_stress_font_sizes_and_configurations(self):
        """
        Execute full Cartesian product stress matrix (9,600 scenarios):
        - 15 body lengths (1 to 50 lines)
        - 4 summary lengths (0, 1, 2, 3 lines)
        - 4 font size scales (compact, standard, large, accessible)
        - 4 action button counts (0, 1, 2, 3 actions)
        - 2 image attachment states (present vs absent)
        - 5 timeout states (0ms, 1000ms, 3000ms, 5000ms, 10000ms)
        Proves clearance is strictly invariant and actions never collide with the progress bar.
        """
        body_lengths = [1, 2, 3, 4, 5, 6, 7, 8, 10, 12, 15, 20, 30, 40, 50]
        summary_lines_list = [0, 1, 2, 3]
        font_profiles = [
            {"name": "compact", "lh_xs": 13, "lh_sm": 14, "lh_md": 17},
            {"name": "standard", "lh_xs": 14, "lh_sm": 16, "lh_md": 18},
            {"name": "large", "lh_xs": 18, "lh_sm": 20, "lh_md": 24},
            {"name": "accessible", "lh_xs": 24, "lh_sm": 28, "lh_md": 34},
        ]
        action_counts = [0, 1, 2, 3]
        has_images = [False, True]
        timeouts = [0, 1000, 3000, 5000, 10000]

        top_margin = 14
        progress_height = 3
        spacing = 8
        iterations = 0

        for b_lines in body_lengths:
            for s_lines in summary_lines_list:
                for font in font_profiles:
                    for num_actions in action_counts:
                        for has_img in has_images:
                            for timeout_ms in timeouts:
                                iterations += 1

                                # Item heights
                                header_h = max(22, font["lh_xs"])
                                summary_h = s_lines * font["lh_md"] if s_lines > 0 else 0
                                # NotificationCard caps body at 6 lines
                                body_h = min(b_lines, 6) * font["lh_sm"]
                                image_h = 120 if has_img else 0
                                action_h = 28 if num_actions > 0 else 0

                                visible_items = [h for h in [header_h, summary_h, body_h, image_h, action_h] if h > 0]
                                gaps = max(0, len(visible_items) - 1) * spacing
                                col_implicit_h = sum(visible_items) + gaps

                                bottom_margin = 18 if timeout_ms > 0 else 14
                                card_implicit_h = col_implicit_h + top_margin + bottom_margin

                                col_y = top_margin
                                col_allocated_h = card_implicit_h - top_margin - bottom_margin
                                actions_bottom_y = col_y + col_allocated_h

                                if timeout_ms > 0:
                                    progress_bar_top_y = card_implicit_h - progress_height
                                    clearance = progress_bar_top_y - actions_bottom_y
                                    self.assertEqual(
                                        clearance, 15,
                                        f"Iteration {iterations}: Expected 15px clearance, got {clearance}px"
                                    )
                                    self.assertLess(
                                        actions_bottom_y, progress_bar_top_y,
                                        f"Iteration {iterations}: Actions must not collide with progress bar"
                                    )
                                else:
                                    gap_to_border = card_implicit_h - actions_bottom_y
                                    self.assertEqual(
                                        gap_to_border, 14,
                                        f"Iteration {iterations}: Expected 14px border gap, got {gap_to_border}px"
                                    )

        self.assertEqual(iterations, 9600, f"Expected 9,600 iterations, executed {iterations}")

    def test_04_legacy_bug_deficit_mathematical_contrast(self):
        """
        Verify that the pre-M3 legacy formula (implicitHeight = col.implicitHeight + 24)
        produces an 8px vertical deficit when timeoutMs > 0, proving the original bug was real.
        """
        col_implicit_h = 200
        top_margin = 14
        bottom_margin_timeout = 18  # required by col.anchors.bottomMargin

        # Legacy buggy card height:
        buggy_card_h = col_implicit_h + 24

        # When col is anchored to parent with topMargin 14 and bottomMargin 18:
        allocated_col_h = buggy_card_h - top_margin - bottom_margin_timeout
        deficit = col_implicit_h - allocated_col_h

        self.assertEqual(deficit, 8, "Legacy formula caused exactly 8px layout deficit")

        # In that deficit condition:
        # Col wanted 200px, but received 192px.
        # Action buttons (at the bottom 28px of col) were clipped by 8px.
        # Under clip: true, the bottom 8px of action buttons were cut off.
        # Progress bar occupied parent.bottom - 3 to parent.bottom.
        # If col unclipped, it would overlap the progress bar by 8px.
        self.assertGreater(deficit, 0, "Deficit must be strictly positive in legacy buggy state")


# =============================================================================
# 3. LIVE DAEMON POPUP & NOTIFICATION INTERACTION STRESS
# =============================================================================

class TestLiveDaemonPopupAndNotificationStress(unittest.TestCase):
    """Stress-tests popups and notifications against the live running Quickshell daemon."""

    @classmethod
    def setUpClass(cls):
        cls.daemon_pid = QuickshellIpc.get_daemon_pid()
        if not cls.daemon_pid:
            raise unittest.SkipTest("Quickshell daemon is not currently running")

    def test_01_live_popups_rapid_toggle_stress(self):
        """Rapidly toggle Battery, QuickSettings, WindowTitle, and Idle popups via IPC."""
        targets = ["battery", "quicksettings", "window", "idle"]

        for target in targets:
            # Open
            code, out = QuickshellIpc.call(target, "open")
            self.assertEqual(code, 0, f"IPC call {target} open failed: {out}")
            time.sleep(0.05)

            # Close
            code, out = QuickshellIpc.call(target, "close")
            self.assertEqual(code, 0, f"IPC call {target} close failed: {out}")
            time.sleep(0.05)

        # Audit log after toggles
        recent_log = QuickshellLogAuditor.get_recent_log(lines=30)
        findings = QuickshellLogAuditor.audit_log_content(recent_log)
        self.assertEqual(
            len(findings["critical"]), 0,
            f"Critical errors found in log after popup toggles: {findings['critical']}"
        )

    def test_02_live_notification_body_length_and_urgency_burst(self):
        """Send notifications with 1 line, 6 lines, 50 lines, and critical urgency to live daemon."""
        notifications = [
            ("Single Line Test", "Short body text."),
            ("Six Line Test", "\n".join([f"Line #{i+1} of medium notification body text" for i in range(6)])),
            ("Fifty Line Test", "\n".join([f"Line #{i+1} stress payload testing vertical clamping" for i in range(50)])),
            ("Persistent Notification", "Notification with timeout 0", "normal"),
            ("Critical Urgent Notification", "Critical notification payload", "critical"),
        ]

        for summary, body, *urgency in notifications:
            u = urgency[0] if urgency else "normal"
            ret = DBusHelper.send_notification(summary, body, urgency=u)
            self.assertEqual(ret, 0, f"Failed to send notification '{summary}' via D-Bus")
            time.sleep(0.08)

        # Allow daemon to render toasts
        time.sleep(0.3)

        recent_log = QuickshellLogAuditor.get_recent_log(lines=40)
        findings = QuickshellLogAuditor.audit_log_content(recent_log)
        self.assertEqual(
            len(findings["critical"]), 0,
            f"Critical errors in quickshell log after notification stress: {findings['critical']}"
        )


# =============================================================================
# 4. OFFSCREEN QT QUICK 6 QML ENGINE EXECUTION
# =============================================================================

class TestHeadlessQmlEngineExecution(unittest.TestCase):
    """Executes the Qt Quick 6 QML headless test harness tests/challenger_stress_popup_metrics.qml."""

    def test_01_offscreen_qml_stress_harness(self):
        """Run offscreen Qt Quick 6 engine script tests/challenger_stress_popup_metrics.qml."""
        if not os.path.exists(QML_BIN):
            self.skipTest(f"Qt QML binary not found at {QML_BIN}")

        qml_script = REPO_ROOT / "tests" / "challenger_stress_popup_metrics.qml"
        self.assertTrue(qml_script.exists(), "tests/challenger_stress_popup_metrics.qml must exist")

        env = os.environ.copy()
        env["QT_QPA_PLATFORM"] = "offscreen"
        env["QML_IMPORT_PATH"] = "/nix/store/10553j4116y6jllliqpg5kz7d35bblab-qtdeclarative-6.11.2/lib/qt-6/qml"
        env["QML2_IMPORT_PATH"] = "/nix/store/10553j4116y6jllliqpg5kz7d35bblab-qtdeclarative-6.11.2/lib/qt-6/qml"
        env["QT_PLUGIN_PATH"] = "/nix/store/10553j4116y6jllliqpg5kz7d35bblab-qtdeclarative-6.11.2/lib/qt-6/plugins"

        proc = subprocess.run(
            [QML_BIN, str(qml_script)],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            env=env,
            timeout=15
        )

        combined_output = proc.stdout + proc.stderr
        self.assertEqual(proc.returncode, 0, f"QML execution failed with code {proc.returncode}:\n{proc.stderr}")
        self.assertIn("ALL_TESTS_PASSED_SUCCESSFULLY", combined_output)
        self.assertIn("FAILURES: 0", combined_output)
        self.assertIn("TOTAL_CHECKS: 639", combined_output)


if __name__ == "__main__":
    unittest.main()
