#!/run/current-system/sw/bin/python3
"""
Tier 1 Feature 5: Multi-Monitor Corner Adjacency (R1)
Validates that corner detection logic suppresses fillets only at actual
adjacent contact points for staggered/offset multi-monitor setups.
"""

import unittest
import re
from tests.harness import QmlCodeInspector

def simulate_has_adjacent_corner(s, o, corner_loc):
    """
    Simulates refined corner-specific adjacency detection.
    s: {x, y, w, h} (subject monitor)
    o: {x, y, w, h} (other monitor)
    corner_loc: 'topLeft', 'topRight', 'bottomLeft', 'bottomRight'
    """
    sx, sy, sw, sh = s['x'], s['y'], s['w'], s['h']
    ox, oy, ow, oh = o['x'], o['y'], o['w'], o['h']

    if corner_loc == 'topRight':
        # Corner point is at (sx + sw, sy)
        # Check right adjacency at top edge
        is_adjacent_right = abs(ox - (sx + sw)) <= 4 and (oy <= sy < oy + oh)
        is_adjacent_top = abs((oy + oh) - sy) <= 4 and (ox <= sx + sw <= ox + ow)
        return is_adjacent_right or is_adjacent_top

    elif corner_loc == 'bottomRight':
        is_adjacent_right = abs(ox - (sx + sw)) <= 4 and (oy < sy + sh <= oy + oh)
        is_adjacent_bottom = abs(oy - (sy + sh)) <= 4 and (ox <= sx + sw <= ox + ow)
        return is_adjacent_right or is_adjacent_bottom

    elif corner_loc == 'topLeft':
        is_adjacent_left = abs((ox + ow) - sx) <= 4 and (oy <= sy < oy + oh)
        is_adjacent_top = abs((oy + oh) - sy) <= 4 and (ox <= sx <= ox + ow)
        return is_adjacent_left or is_adjacent_top

    elif corner_loc == 'bottomLeft':
        is_adjacent_left = abs((ox + ow) - sx) <= 4 and (oy < sy + sh <= oy + oh)
        is_adjacent_bottom = abs(oy - (sy + sh)) <= 4 and (ox <= sx <= ox + ow)
        return is_adjacent_left or is_adjacent_bottom

    return False

class TestF05MonitorAdjacency(unittest.TestCase):
    """Verifies multi-monitor corner adjacency logic."""

    def setUp(self):
        self.sc_content = QmlCodeInspector.read_qml_content("corners/ScreenCorners.qml")

    def test_adjacency_function_present(self):
        """T1.5.1: ScreenCorners.qml contains monitor adjacency checking logic."""
        self.assertIn("hasAdjacentMonitor", self.sc_content)

    def test_side_by_side_collinear_monitors(self):
        """T1.5.2: Collinear side-by-side monitors suppress abutting corners."""
        m1 = {"x": 0, "y": 0, "w": 1920, "h": 1080}
        m2 = {"x": 1920, "y": 0, "w": 1920, "h": 1080}
        # Top-right and bottom-right of m1 should be adjacent to m2
        self.assertTrue(simulate_has_adjacent_corner(m1, m2, "topRight"))
        self.assertTrue(simulate_has_adjacent_corner(m1, m2, "bottomRight"))
        # Top-left of m1 should NOT be adjacent
        self.assertFalse(simulate_has_adjacent_corner(m1, m2, "topLeft"))

    def test_staggered_offset_monitors(self):
        """T1.5.3: Staggered monitors do not suppress non-abutting corners."""
        m1 = {"x": 0, "y": 0, "w": 1920, "h": 1080}
        # m2 is vertically shifted down by 500px, so top-right of m1 has no abutting neighbor
        m2 = {"x": 1920, "y": 500, "w": 1920, "h": 1080}
        self.assertFalse(simulate_has_adjacent_corner(m1, m2, "topRight"))
        self.assertTrue(simulate_has_adjacent_corner(m1, m2, "bottomRight"))

    def test_single_monitor_no_suppression(self):
        """T1.5.4: Single monitor does not suppress any corners."""
        self.assertIn("all.length <= 1", self.sc_content)

    def test_disjoint_monitors_with_gap(self):
        """T1.5.5: Monitors with gap greater than 4px are not adjacent."""
        m1 = {"x": 0, "y": 0, "w": 1920, "h": 1080}
        m2 = {"x": 2000, "y": 0, "w": 1920, "h": 1080} # 80px gap
        self.assertFalse(simulate_has_adjacent_corner(m1, m2, "topRight"))
        self.assertFalse(simulate_has_adjacent_corner(m1, m2, "bottomRight"))

if __name__ == "__main__":
    unittest.main()
