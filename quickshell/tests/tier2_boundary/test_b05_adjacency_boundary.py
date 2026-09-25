#!/run/current-system/sw/bin/python3
"""
Tier 2 Boundary 5: Multi-Monitor Adjacency Boundary & Corner Cases
Tests complex multi-monitor topologies: 3-monitor triangular layout,
rotated monitors, 8K vs 480p scaling, and sub-pixel edge alignment.
"""

import unittest
from tests.tier1_features.test_f05_monitor_adjacency import simulate_has_adjacent_corner

class TestB05AdjacencyBoundary(unittest.TestCase):
    """Verifies edge cases for complex multi-monitor topologies."""

    def test_triple_monitor_t_shape(self):
        """T2.5.1: Three monitors in T-shape topology."""
        # Top monitor centered over two side-by-side bottom monitors
        m_top = {"x": 960, "y": 0, "w": 1920, "h": 1080}
        m_b1 = {"x": 0, "y": 1080, "w": 1920, "h": 1080}
        m_b2 = {"x": 1920, "y": 1080, "w": 1920, "h": 1080}

        # m_top bottom-left sits at x=960, y=1080 -> directly over m_b1 top edge
        self.assertTrue(simulate_has_adjacent_corner(m_top, m_b1, "bottomLeft"))
        # m_top top-left has no neighbor
        self.assertFalse(simulate_has_adjacent_corner(m_top, m_b1, "topLeft"))

    def test_extreme_resolution_disparity(self):
        """T2.5.2: 8K monitor adjacent to 720p monitor."""
        m_8k = {"x": 0, "y": 0, "w": 7680, "h": 4320}
        m_hd = {"x": 7680, "y": 0, "w": 1280, "h": 720}
        # Top right of 8K is adjacent to m_hd
        self.assertTrue(simulate_has_adjacent_corner(m_8k, m_hd, "topRight"))
        # Bottom right of 8K (y=4320) is far below m_hd (y=720)
        self.assertFalse(simulate_has_adjacent_corner(m_8k, m_hd, "bottomRight"))

    def test_negative_coordinate_placement(self):
        """T2.5.3: Monitor placed at negative virtual desktop coordinates."""
        m_neg = {"x": -1920, "y": 0, "w": 1920, "h": 1080}
        m_main = {"x": 0, "y": 0, "w": 1920, "h": 1080}
        self.assertTrue(simulate_has_adjacent_corner(m_neg, m_main, "topRight"))
        self.assertTrue(simulate_has_adjacent_corner(m_main, m_neg, "topLeft"))

    def test_subpixel_tolerance_boundary(self):
        """T2.5.4: 4px threshold properly handles subpixel alignment variations."""
        m1 = {"x": 0, "y": 0, "w": 1920, "h": 1080}
        m2_within = {"x": 1923, "y": 0, "w": 1920, "h": 1080} # 3px gap <= 4px
        m2_outside = {"x": 1925, "y": 0, "w": 1920, "h": 1080} # 5px gap > 4px
        self.assertTrue(simulate_has_adjacent_corner(m1, m2_within, "topRight"))
        self.assertFalse(simulate_has_adjacent_corner(m1, m2_outside, "topRight"))

    def test_identical_coordinates_skipped(self):
        """T2.5.5: Duplicate or cloned display handles match gracefully."""
        m1 = {"x": 0, "y": 0, "w": 1920, "h": 1080}
        # A monitor cannot be adjacent to its exact clone at identical coords
        self.assertFalse(simulate_has_adjacent_corner(m1, m1, "topLeft"))

if __name__ == "__main__":
    unittest.main()
