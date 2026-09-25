#!/run/current-system/sw/bin/python3
"""
Challenger 2 Empirical Stress Test Suite for Milestone 2 (M2)
Adversarial stress-testing of boundary and lifecycle cases:
1. ScreencopyView lifecycle gating under inactive/active states
2. IdleService brightness restoration on Caffeine toggle
3. Popup coordinate safety under rapid toggles
4. Boundary suites test_b08 through test_b12
"""

import json
import os
import random
import re
import subprocess
import time
import unittest
from pathlib import Path
from tests.harness import (
    QmlCodeInspector,
    QuickshellIpc,
    QuickshellLogAuditor,
    HyprlandHelper,
    REPO_ROOT,
    QMLLINT_BIN,
)


class TestScreencopyLifecycleGating(unittest.TestCase):
    """
    Stress-tests ScreencopyView lifecycle gating under inactive/active states.
    Addresses Feature 10 / Milestone 2 crash resilience.
    """

    def setUp(self):
        self.overlay_qml = QmlCodeInspector.read_qml_content("widgets/ScreenshotOverlay.qml")
        self.service_qml = QmlCodeInspector.read_qml_content("services/ScreenshotService.qml")
        self.daemon_pid = QuickshellIpc.get_daemon_pid()
        self.assertIsNotNone(self.daemon_pid, "Quickshell daemon must be running")

    def tearDown(self):
        # Always leave screenshot service closed
        if QuickshellIpc.is_available():
            QuickshellIpc.call("screenshot", "close")
            time.sleep(0.1)

    def test_screencopy_ternary_gating_contract(self):
        """Verify ScreencopyView.captureSource is conditionally gated with ternary null unbinding."""
        # Must have conditional ternary
        pattern = r"captureSource:\s*\(?ScreenshotService\.isOpen\s*\|\|\s*overlayRoot\.isCapturing\)?\s*\?\s*overlayRoot\.screen\s*:\s*null"
        self.assertTrue(
            bool(re.search(pattern, self.overlay_qml)),
            "ScreenshotOverlay.qml must conditionally bind captureSource to null when inactive"
        )
        # Must NOT have unconditional captureSource: overlayRoot.screen
        unconditional = bool(re.search(r"captureSource:\s*overlayRoot\.screen\s*(?:\n|;)", self.overlay_qml))
        self.assertFalse(
            unconditional,
            "ScreenshotOverlay.qml must not contain unconditional captureSource: overlayRoot.screen"
        )

    def test_screencopy_inactive_state_contract(self):
        """Verify overlayRoot visibility and focus are gated by ScreenshotService.isOpen."""
        self.assertTrue(
            bool(re.search(r"visible:\s*ScreenshotService\.isOpen", self.overlay_qml)),
            "overlayRoot.visible must be gated by ScreenshotService.isOpen"
        )
        self.assertTrue(
            bool(re.search(r"keyboardFocus:\s*ScreenshotService\.isOpen", self.overlay_qml)),
            "keyboardFocus must be gated by ScreenshotService.isOpen"
        )

    def test_screencopy_open_close_layer_lifecycle(self):
        """Verify Wayland layer shell surface maps with active PID on open and unmaps on close."""
        if not HyprlandHelper.is_available():
            self.skipTest("Hyprland compositor not available")

        # Close first
        QuickshellIpc.call("screenshot", "close")
        time.sleep(0.2)

        # Open
        ret, out = QuickshellIpc.call("screenshot", "open")
        self.assertEqual(ret, 0, f"screenshot open failed: {out}")
        time.sleep(0.3)

        # Verify active screenshot layer surface with daemon PID exists
        qs_layers = HyprlandHelper.get_quickshell_layers()
        screenshot_layers = [l for l in qs_layers if "screenshot" in l["namespace"]]
        active_screenshot_layers = [l for l in screenshot_layers if l["pid"] == self.daemon_pid]
        self.assertGreater(
            len(active_screenshot_layers), 0,
            f"Expected active screenshot layer shell surface with PID {self.daemon_pid}, found: {screenshot_layers}"
        )

        # Close
        ret, out = QuickshellIpc.call("screenshot", "close")
        self.assertEqual(ret, 0, f"screenshot close failed: {out}")
        time.sleep(0.3)

        # Verify screenshot layer surface is unmapped (pid -1 or not mapped)
        qs_layers_after = HyprlandHelper.get_quickshell_layers()
        screenshot_after = [l for l in qs_layers_after if "screenshot" in l["namespace"] and l["pid"] == self.daemon_pid]
        self.assertEqual(
            len(screenshot_after), 0,
            f"Expected no active screenshot layer shell surfaces with PID {self.daemon_pid} after close"
        )

    def test_screencopy_rapid_burst_transitions(self):
        """Stress-test 30 consecutive rapid open/close/toggle cycles without crashing daemon."""
        pid_before = QuickshellIpc.get_daemon_pid()
        for i in range(30):
            ret, _ = QuickshellIpc.call("screenshot", "toggle")
            self.assertEqual(ret, 0, f"Toggle iteration {i+1} failed")
            time.sleep(0.03)

        # Ensure cleanly closed
        QuickshellIpc.call("screenshot", "close")
        time.sleep(0.2)

        pid_after = QuickshellIpc.get_daemon_pid()
        self.assertEqual(
            pid_before, pid_after,
            f"Daemon crashed or restarted during rapid screenshot burst! Before: {pid_before}, After: {pid_after}"
        )

    def test_screencopy_idempotent_close(self):
        """Verify calling close repeatedly on an already closed screenshot service is safe."""
        for _ in range(5):
            ret, out = QuickshellIpc.call("screenshot", "close")
            self.assertEqual(ret, 0, f"Idempotent close failed: {out}")

        self.assertEqual(
            QuickshellIpc.get_daemon_pid(), self.daemon_pid,
            "Daemon died during repeated idempotent close calls"
        )

    def test_screencopy_fullscreen_capture_call(self):
        """Verify fullscreen capture trigger executes cleanly without exception."""
        ret, out = QuickshellIpc.call("screenshot", "full")
        self.assertEqual(ret, 0, f"Screenshot full capture failed: {out}")
        time.sleep(0.3)
        self.assertEqual(
            QuickshellIpc.get_daemon_pid(), self.daemon_pid,
            "Daemon died after fullscreen capture call"
        )


class TestIdleCaffeineBrightnessRestoration(unittest.TestCase):
    """
    Stress-tests IdleService brightness restoration on Caffeine toggle.
    Addresses Feature 11 / Milestone 2 service hardening.
    """

    def setUp(self):
        self.service_qml = QmlCodeInspector.read_qml_content("services/IdleService.qml")
        self.shell_qml = QmlCodeInspector.read_qml_content("shell.qml")
        self.daemon_pid = QuickshellIpc.get_daemon_pid()
        self.assertIsNotNone(self.daemon_pid, "Quickshell daemon must be running")

    def tearDown(self):
        # Reset idle service to enabled = true (caffeine = false)
        if QuickshellIpc.is_available():
            QuickshellIpc.call("idle", "set", "true")
            time.sleep(0.1)

    def test_idle_service_on_enabled_changed_contract(self):
        """Verify onEnabledChanged in IdleService.qml executes brightnessctl -r when disabled."""
        self.assertIn("onEnabledChanged:", self.service_qml)
        has_restore = bool(re.search(
            r'onEnabledChanged:\s*\{[^}]*brightnessctl[^}]*-r[^}]*\}',
            self.service_qml,
            re.DOTALL
        ))
        self.assertTrue(
            has_restore,
            "IdleService.qml must invoke brightnessctl -r inside onEnabledChanged when !root.enabled"
        )

    def test_live_brightness_restoration_on_caffeine_toggle(self):
        """Empirically test that toggling caffeine restores dimmed display brightness."""
        # Check if brightnessctl is available
        which_res = subprocess.run(["which", "brightnessctl"], capture_output=True, text=True)
        if which_res.returncode != 0:
            self.skipTest("brightnessctl binary not installed on system")

        try:
            # 1. Capture current baseline brightness
            orig_raw = subprocess.check_output(["brightnessctl", "get"]).decode().strip()
            orig_val = int(orig_raw)
            self.assertGreater(orig_val, 0)
        except Exception as e:
            self.skipTest(f"Hardware backlight not operable: {e}")

        try:
            # 2. Ensure caffeine is initially off (idle monitoring enabled)
            QuickshellIpc.call("idle", "set", "true")
            time.sleep(0.1)

            # 3. Simulate idle dimming by setting brightness to 20% with save (-s)
            subprocess.run(["brightnessctl", "-s", "set", "20%"], check=True, capture_output=True)
            dimmed_raw = subprocess.check_output(["brightnessctl", "get"]).decode().strip()
            dimmed_val = int(dimmed_raw)
            self.assertLess(dimmed_val, orig_val, "Brightness should be dimmed below original value")

            # 4. Toggle caffeine ON via Quickshell IPC
            # This sets IdleService.enabled = false, which triggers onEnabledChanged -> brightnessctl -r
            ret, out = QuickshellIpc.call("caffeine", "toggle")
            self.assertEqual(ret, 0, f"Caffeine toggle failed: {out}")
            time.sleep(0.4)

            # 5. Verify brightness was automatically restored!
            restored_raw = subprocess.check_output(["brightnessctl", "get"]).decode().strip()
            restored_val = int(restored_raw)
            self.assertEqual(
                restored_val, orig_val,
                f"Display brightness was not restored upon caffeine toggle! Expected {orig_val}, got {restored_val}"
            )
        finally:
            # Always restore baseline brightness and caffeine state
            subprocess.run(["brightnessctl", "set", str(orig_val)], capture_output=True)
            QuickshellIpc.call("idle", "set", "true")

    def test_caffeine_idle_state_bipolar_synchronization(self):
        """Verify strict boolean inversion synchronization between caffeine and idle IPC."""
        # Force idle enabled = true (caffeine = false)
        QuickshellIpc.call("idle", "set", "true")
        time.sleep(0.05)

        ret_c, caff_status = QuickshellIpc.call("caffeine", "status")
        ret_i, idle_status = QuickshellIpc.call("idle", "status")
        self.assertEqual(ret_c, 0)
        self.assertEqual(ret_i, 0)
        self.assertEqual(caff_status.strip(), "false")
        self.assertEqual(idle_status.strip(), "true")

        # Toggle caffeine -> caffeine = true, idle = false
        QuickshellIpc.call("caffeine", "toggle")
        time.sleep(0.05)
        _, caff_status2 = QuickshellIpc.call("caffeine", "status")
        _, idle_status2 = QuickshellIpc.call("idle", "status")
        self.assertEqual(caff_status2.strip(), "true")
        self.assertEqual(idle_status2.strip(), "false")

        # Toggle idle -> caffeine = false, idle = true
        QuickshellIpc.call("idle", "toggle")
        time.sleep(0.05)
        _, caff_status3 = QuickshellIpc.call("caffeine", "status")
        _, idle_status3 = QuickshellIpc.call("idle", "status")
        self.assertEqual(caff_status3.strip(), "false")
        self.assertEqual(idle_status3.strip(), "true")

    def test_rapid_caffeine_toggle_burst(self):
        """Stress-test 40 rapid caffeine toggles to verify IPC socket and child process stability."""
        pid_before = QuickshellIpc.get_daemon_pid()
        for i in range(40):
            ret, _ = QuickshellIpc.call("caffeine", "toggle")
            self.assertEqual(ret, 0, f"Caffeine toggle iteration {i+1} failed")
            time.sleep(0.02)

        pid_after = QuickshellIpc.get_daemon_pid()
        self.assertEqual(
            pid_before, pid_after,
            f"Daemon restarted during caffeine burst toggle: before={pid_before}, after={pid_after}"
        )

    def test_idle_monitors_inhibition_guards(self):
        """Verify all 4 IdleMonitors guard their callbacks against !root.enabled."""
        monitors = ["dimMonitor", "lockMonitor", "dpmsMonitor", "suspendMonitor"]
        for mon in monitors:
            self.assertIn(f"property IdleMonitor {mon}", self.service_qml)

        # Check respectInhibitors: true on all
        respect_count = len(re.findall(r"respectInhibitors:\s*true", self.service_qml))
        self.assertGreaterEqual(respect_count, 4, "All 4 IdleMonitors must set respectInhibitors: true")

        # Check timeout separation
        dim_t = int(re.search(r"dimMonitor:.*?timeout:\s*(\d+)", self.service_qml, re.DOTALL).group(1))
        lock_t = int(re.search(r"lockMonitor:.*?timeout:\s*(\d+)", self.service_qml, re.DOTALL).group(1))
        dpms_t = int(re.search(r"dpmsMonitor:.*?timeout:\s*(\d+)", self.service_qml, re.DOTALL).group(1))
        susp_t = int(re.search(r"suspendMonitor:.*?timeout:\s*(\d+)", self.service_qml, re.DOTALL).group(1))

        self.assertLess(dim_t, lock_t, "Dim timeout must precede Lock timeout")
        self.assertLess(lock_t, dpms_t, "Lock timeout must precede DPMS timeout")
        self.assertLess(dpms_t, susp_t, "DPMS timeout must precede Suspend timeout")


class TestPopupCoordinateSafety(unittest.TestCase):
    """
    Stress-tests popup coordinate safety under rapid toggles.
    Addresses Feature 12 / Milestone 2 crash resilience & TypeError elimination.
    """

    POPUP_TARGETS = [
        "quicksettings", "launcher", "clipboard", "calendar",
        "quicknotes", "bluetooth", "network", "powermenu",
        "battery", "window", "volume", "workspaces", "studio", "media"
    ]

    def setUp(self):
        self.daemon_pid = QuickshellIpc.get_daemon_pid()
        self.assertIsNotNone(self.daemon_pid, "Quickshell daemon must be running")

    def tearDown(self):
        # Close any open popups
        for target in self.POPUP_TARGETS:
            try:
                QuickshellIpc.call(target, "close")
            except Exception:
                pass
        time.sleep(0.1)

    def test_all_qml_maptoitem_zero_naked_access(self):
        """Verify across ALL QML files in project that zero naked unchained mapToItem.[xy] exist."""
        qml_files = [f for f in REPO_ROOT.glob("**/*.qml") if ".agents" not in f.parts]
        self.assertGreaterEqual(len(qml_files), 40, "Should inspect full QML codebase")

        violations = []
        for qml in qml_files:
            lines = qml.read_text(encoding="utf-8").splitlines()
            for idx, line in enumerate(lines, 1):
                if re.search(r"mapToItem\([^)]*\)\.[a-zA-Z]", line):
                    violations.append(f"{qml.relative_to(REPO_ROOT)}:{idx}: {line.strip()}")

        self.assertEqual(
            len(violations), 0,
            f"Found {len(violations)} naked unchained mapToItem accesses:\n" + "\n".join(violations)
        )

    def test_rapid_popup_toggle_burst_all_targets(self):
        """Stress-test rapid burst toggles (10 iterations each) across all 14 popup widgets."""
        pid_before = QuickshellIpc.get_daemon_pid()

        for target in self.POPUP_TARGETS:
            for i in range(10):
                ret, out = QuickshellIpc.call(target, "toggle")
                self.assertEqual(ret, 0, f"Toggle failed for target {target} on iter {i+1}: {out}")
            # Ensure closed
            QuickshellIpc.call(target, "close")
            time.sleep(0.03)

        pid_after = QuickshellIpc.get_daemon_pid()
        self.assertEqual(
            pid_before, pid_after,
            f"Daemon crashed or restarted during popup toggle bursts! {pid_before} -> {pid_after}"
        )

    def test_interleaved_chaos_popup_toggles(self):
        """Chaos stress-test: randomly toggle 100 mixed popup calls in rapid succession."""
        pid_before = QuickshellIpc.get_daemon_pid()
        rng = random.Random(42)  # Deterministic seed for reproducible challenger testing

        methods = ["toggle", "open", "close"]
        for i in range(100):
            target = rng.choice(self.POPUP_TARGETS)
            method = rng.choice(methods)
            ret, _ = QuickshellIpc.call(target, method)
            self.assertEqual(ret, 0, f"Chaos call failed: {target}.{method}() at iter {i+1}")
            if i % 10 == 0:
                time.sleep(0.01)

        # Cleanup
        for target in self.POPUP_TARGETS:
            QuickshellIpc.call(target, "close")
        time.sleep(0.2)

        pid_after = QuickshellIpc.get_daemon_pid()
        self.assertEqual(
            pid_before, pid_after,
            f"Daemon died during chaos popup stress! {pid_before} -> {pid_after}"
        )

    def test_runtime_log_free_of_type_errors(self):
        """Verify Quickshell log stream contains zero TypeErrors after rigorous stress testing."""
        log = QuickshellLogAuditor.get_recent_log(150)
        type_errors = [l for l in log.splitlines() if "TypeError" in l]
        self.assertEqual(
            len(type_errors), 0,
            f"Found runtime TypeErrors in Quickshell log:\n" + "\n".join(type_errors)
        )


class TestBoundarySuitesB08ThroughB12(unittest.TestCase):
    """
    Executes and validates the baseline boundary suites test_b08 through test_b12.
    """

    def test_run_all_b08_through_b12(self):
        """Execute boundary test files test_b08 through test_b12 and verify 100% pass."""
        test_files = [
            "tests/tier2_boundary/test_b08_notif_burst_stress.py",
            "tests/tier2_boundary/test_b09_multiscreen_dismiss_boundary.py",
            "tests/tier2_boundary/test_b10_screencopy_boundary.py",
            "tests/tier2_boundary/test_b11_idle_caffeine_boundary.py",
            "tests/tier2_boundary/test_b12_popup_null_boundary.py",
        ]
        cmd = ["python3", "-m", "unittest"] + test_files
        res = subprocess.run(cmd, cwd=str(REPO_ROOT), capture_output=True, text=True, timeout=30)
        self.assertEqual(
            res.returncode, 0,
            f"Boundary tests b08-b12 failed with code {res.returncode}:\nStdout:\n{res.stdout}\nStderr:\n{res.stderr}"
        )


if __name__ == "__main__":
    unittest.main()
