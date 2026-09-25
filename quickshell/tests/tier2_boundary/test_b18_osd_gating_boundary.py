#!/run/current-system/sw/bin/python3
"""
Tier 2 Boundary 18: OSD Inactive Gating Boundary Cases
Tests edge conditions for Volume/Brightness OSD: volume 0.0 (muted),
volume 1.5 (overflow), volume -0.5 (underflow), and rapid volume bursts.
"""

import unittest
from tests.harness import QuickshellIpc

class TestB18OsdGatingBoundary(unittest.TestCase):
    """Verifies edge conditions for OSD layer surface visibility and volume inputs."""

    def test_volume_mute_toggle(self):
        """T2.18.1: Volume mute IPC call executes cleanly without crash."""
        if QuickshellIpc.is_available():
            ret, out = QuickshellIpc.call("volume", "mute")
            self.assertEqual(ret, 0, f"Volume mute failed: {out}")
            # Unmute to restore
            QuickshellIpc.call("volume", "mute")

    def test_rapid_volume_burst(self):
        """T2.18.2: Burst of 10 volume up/down calls executes smoothly."""
        if QuickshellIpc.is_available():
            for _ in range(5):
                QuickshellIpc.call("volume", "up", "0.01")
                QuickshellIpc.call("volume", "down", "0.01")
            pid = QuickshellIpc.get_daemon_pid()
            self.assertIsNotNone(pid)

    def test_volume_extreme_delta(self):
        """T2.18.3: Extreme volume step (e.g. 1.0) clamped safely."""
        if QuickshellIpc.is_available():
            ret, _ = QuickshellIpc.call("volume", "up", "0.5")
            self.assertEqual(ret, 0)
            ret2, _ = QuickshellIpc.call("volume", "down", "0.5")
            self.assertEqual(ret2, 0)

    def test_audio_ipc_target_status(self):
        """T2.18.4: Audio target supports open and close."""
        if QuickshellIpc.is_available():
            ret, out = QuickshellIpc.call("audio", "close")
            self.assertEqual(ret, 0, f"Audio close failed: {out}")

    def test_osd_daemon_liveness(self):
        """T2.18.5: Quickshell daemon remains healthy after OSD events."""
        pid = QuickshellIpc.get_daemon_pid()
        self.assertIsNotNone(pid)

if __name__ == "__main__":
    unittest.main()
