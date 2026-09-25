"""
Quickshell E2E Test Harness & Shared Infrastructure
Provides opaque-box interaction helpers for Hyprland, Quickshell IPC,
D-Bus notifications, log auditing, and QML static analysis.
"""

import os
import sys
import json
import time
import shutil
import re
import subprocess
from pathlib import Path
from typing import Dict, List, Optional, Any, Tuple

REPO_ROOT = Path(__file__).resolve().parent.parent

def find_binary(name: str, fallback_paths: List[str] = None) -> Optional[str]:
    """Find binary from PATH or fallback nix-store paths."""
    found = shutil.which(name)
    if found:
        return found
    if fallback_paths:
        for p in fallback_paths:
            if os.path.exists(p) and os.access(p, os.X_OK):
                return p
    return None

QMLLINT_BIN = find_binary(
    "qmllint",
    ["/nix/store/dbnyhkzcp2bnmm7gqlwrslbawqlkam96-qtdeclarative-6.11.2/bin/qmllint"]
)

NOTIFY_SEND_BIN = find_binary(
    "notify-send",
    [
        "/nix/store/0sdzywcdz692krax2xsdi3qk9sx69xzi-libnotify-0.8.8/bin/notify-send",
        "/nix/store/48zpr03lhzxp6k4wn3vpjdx3dm4p1631-libnotify-0.8.8/bin/notify-send"
    ]
)

QUICKSHELL_BIN = find_binary("quickshell", ["/run/current-system/sw/bin/quickshell"])
HYPRCTL_BIN = find_binary("hyprctl", ["/run/current-system/sw/bin/hyprctl"])
BUSCTL_BIN = find_binary("busctl", ["/run/current-system/sw/bin/busctl"])


class QuickshellLogAuditor:
    """Parses Quickshell runtime logs and crash dumps."""

    CRITICAL_PATTERNS = [
        re.compile(r"TypeError\b", re.IGNORECASE),
        re.compile(r"ReferenceError\b", re.IGNORECASE),
        re.compile(r"Binding loop detected", re.IGNORECASE),
        re.compile(r"Segmentation fault", re.IGNORECASE),
        re.compile(r"Cannot assign to non-existent property", re.IGNORECASE),
        re.compile(r"Uncaught exception", re.IGNORECASE),
    ]

    WARNING_PATTERNS = [
        re.compile(r"Could not load icon \"antigravity-browser\"", re.IGNORECASE),
        re.compile(r"Read of .* failed: File does not exist", re.IGNORECASE),
        re.compile(r"Member \".*\" not found on type", re.IGNORECASE),
    ]

    @staticmethod
    def get_recent_log(lines: int = 100) -> str:
        if not QUICKSHELL_BIN:
            return ""
        try:
            res = subprocess.run(
                [QUICKSHELL_BIN, "log", "-t", str(lines), "--no-color"],
                capture_output=True,
                text=True,
                timeout=5
            )
            return res.stdout + res.stderr
        except Exception as e:
            return f"Failed to retrieve log: {e}"

    @classmethod
    def audit_log_content(cls, log_text: str) -> Dict[str, List[str]]:
        findings = {"critical": [], "warnings": []}
        for line in log_text.splitlines():
            for pat in cls.CRITICAL_PATTERNS:
                if pat.search(line):
                    findings["critical"].append(line.strip())
                    break
            for pat in cls.WARNING_PATTERNS:
                if pat.search(line):
                    findings["warnings"].append(line.strip())
                    break
        return findings


class DBusHelper:
    """Dispatches D-Bus notifications and monitors."""

    @staticmethod
    def send_notification(summary: str, body: str = "", urgency: str = "normal", app_name: str = "quickshell-test") -> int:
        if NOTIFY_SEND_BIN:
            cmd = [NOTIFY_SEND_BIN, "-a", app_name, "-u", urgency, summary, body]
            res = subprocess.run(cmd, capture_output=True, text=True, timeout=5)
            return res.returncode
        elif BUSCTL_BIN:
            cmd = [
                BUSCTL_BIN, "--user", "call",
                "org.freedesktop.Notifications",
                "/org/freedesktop/Notifications",
                "org.freedesktop.Notifications",
                "Notify",
                "susssasa{sv}i",
                app_name, 0, "", summary, body, 0, 0, -1
            ]
            res = subprocess.run(cmd, capture_output=True, text=True, timeout=5)
            return res.returncode
        return -1

    @staticmethod
    def send_burst(count: int = 50, delay: float = 0.01) -> int:
        success = 0
        for i in range(count):
            ret = DBusHelper.send_notification(f"Burst Test #{i+1}", f"Payload sequence #{i+1}")
            if ret == 0:
                success += 1
            if delay > 0:
                time.sleep(delay)
        return success


class QuickshellIpc:
    """Interacts with Quickshell IPC socket targets."""

    @staticmethod
    def is_available() -> bool:
        if not QUICKSHELL_BIN:
            return False
        try:
            res = subprocess.run([QUICKSHELL_BIN, "ipc", "show"], capture_output=True, text=True, timeout=3)
            return res.returncode == 0
        except Exception:
            return False

    @staticmethod
    def list_targets() -> List[str]:
        if not QUICKSHELL_BIN:
            return []
        try:
            res = subprocess.run([QUICKSHELL_BIN, "ipc", "show"], capture_output=True, text=True, timeout=3)
            targets = []
            for line in res.stdout.splitlines():
                if line.startswith("target "):
                    targets.append(line.split()[1])
            return targets
        except Exception:
            return []

    @staticmethod
    def call(target: str, method: str, *args) -> Tuple[int, str]:
        if not QUICKSHELL_BIN:
            return (-1, "quickshell binary not found")
        cmd = [QUICKSHELL_BIN, "ipc", "call", target, method] + [str(a) for a in args]
        try:
            res = subprocess.run(cmd, capture_output=True, text=True, timeout=5)
            return (res.returncode, res.stdout + res.stderr)
        except Exception as e:
            return (-1, str(e))

    @staticmethod
    def get_daemon_pid() -> Optional[int]:
        if not QUICKSHELL_BIN:
            return None
        try:
            res = subprocess.run([QUICKSHELL_BIN, "list"], capture_output=True, text=True, timeout=3)
            for line in res.stdout.splitlines():
                if "Process ID:" in line:
                    return int(line.split(":")[-1].strip())
        except Exception:
            pass
        return None


class HyprlandHelper:
    """Queries Hyprland compositor state for windows, monitors, and layers."""

    @staticmethod
    def is_available() -> bool:
        if not HYPRCTL_BIN or not os.environ.get("HYPRLAND_INSTANCE_SIGNATURE"):
            return False
        return True

    @staticmethod
    def get_monitors() -> List[Dict[str, Any]]:
        if not HYPRCTL_BIN:
            return []
        try:
            res = subprocess.run([HYPRCTL_BIN, "monitors", "-j"], capture_output=True, text=True, timeout=3)
            return json.loads(res.stdout)
        except Exception:
            return []

    @staticmethod
    def get_layers() -> Dict[str, Any]:
        """Parses output of hyprctl layers into structured dictionary."""
        if not HYPRCTL_BIN:
            return {}
        try:
            res = subprocess.run([HYPRCTL_BIN, "layers"], capture_output=True, text=True, timeout=3)
            lines = res.stdout.splitlines()
            result = {}
            current_monitor = None
            current_level = None
            for line in lines:
                if line.startswith("Monitor "):
                    current_monitor = line.split()[1].rstrip(":")
                    result[current_monitor] = {0: [], 1: [], 2: [], 3: []}
                elif "Layer level " in line:
                    lvl_match = re.search(r"Layer level (\d+)", line)
                    if lvl_match:
                        current_level = int(lvl_match.group(1))
                elif "namespace: " in line and current_monitor and current_level is not None:
                    # e.g.: Layer 5a43cfc08e70: xywh: 1916 0 4 1080, namespace: quickshell:border-right, pid: 16018
                    ns_match = re.search(r"namespace:\s*([^\s,]+)", line)
                    xywh_match = re.search(r"xywh:\s*(\d+)\s+(\d+)\s+(\d+)\s+(\d+)", line)
                    pid_match = re.search(r"pid:\s*(\d+)", line)
                    layer_info = {
                        "namespace": ns_match.group(1) if ns_match else "",
                        "x": int(xywh_match.group(1)) if xywh_match else 0,
                        "y": int(xywh_match.group(2)) if xywh_match else 0,
                        "w": int(xywh_match.group(3)) if xywh_match else 0,
                        "h": int(xywh_match.group(4)) if xywh_match else 0,
                        "pid": int(pid_match.group(1)) if pid_match else 0,
                        "raw": line.strip()
                    }
                    result[current_monitor][current_level].append(layer_info)
            return result
        except Exception:
            return {}

    @staticmethod
    def get_quickshell_layers() -> List[Dict[str, Any]]:
        layers = HyprlandHelper.get_layers()
        qs_layers = []
        for mon, lvls in layers.items():
            for lvl, items in lvls.items():
                for itm in items:
                    if "quickshell" in itm["namespace"]:
                        itm["monitor"] = mon
                        itm["level"] = lvl
                        qs_layers.append(itm)
        return qs_layers


class QmlCodeInspector:
    """Inspects and validates QML source code directly for contracts."""

    @staticmethod
    def read_qml_content(relpath: str) -> str:
        filepath = REPO_ROOT / relpath
        if not filepath.exists():
            return ""
        return filepath.read_text(encoding="utf-8")

    @staticmethod
    def check_pattern(relpath: str, pattern: str, is_regex: bool = False) -> bool:
        content = QmlCodeInspector.read_qml_content(relpath)
        if not content:
            return False
        if is_regex:
            return bool(re.search(pattern, content, re.MULTILINE))
        return pattern in content

    @staticmethod
    def run_qmllint(relpath: str) -> Tuple[int, str]:
        if not QMLLINT_BIN:
            return (-1, "qmllint binary not found")
        filepath = REPO_ROOT / relpath
        cmd = [
            QMLLINT_BIN,
            "-I", str(REPO_ROOT),
            "-I", "/nix/store/xxn0r8g13ynxc9sx7bf56v735a8bshan-quickshell-0.3.0/lib/qt-6/qml",
            "-I", "/nix/store/dbnyhkzcp2bnmm7gqlwrslbawqlkam96-qtdeclarative-6.11.2/lib/qt-6/qml",
            str(filepath)
        ]
        try:
            res = subprocess.run(cmd, capture_output=True, text=True, timeout=10)
            return (res.returncode, res.stdout + res.stderr)
        except Exception as e:
            return (-1, str(e))
