import QtQuick

Item {
    id: testRoot

    // Reference presets from Theme.qml
    readonly property var hyprlandBezier:     [0.05, 0.9, 0.1, 1.05, 1.0, 1.0]
    readonly property var hyprlandExitBezier: [0.3, 0.0, 0.8, 0.15, 1.0, 1.0]
    readonly property var smoothBezier:       [0.16, 1.0, 0.3, 1.0, 1.0, 1.0]
    readonly property var snappyBezier:       [0.2, 0.0, 0.0, 1.0, 1.0, 1.0]
    readonly property var expressiveBezier:   [0.1, 1.15, 0.2, 1.0, 1.0, 1.0]
    readonly property var standardBezier:     [0.25, 0.1, 0.25, 1.0, 1.0, 1.0]

    // Exact implementation from Theme.qml
    function getBezierPoints(curve) {
        if (!curve) return standardBezier;
        if (Array.isArray(curve)) {
            if (curve.length >= 6) return [Number(curve[0]), Number(curve[1]), Number(curve[2]), Number(curve[3]), Number(curve[4]), Number(curve[5])];
            if (curve.length >= 4) return [Number(curve[0]), Number(curve[1]), Number(curve[2]), Number(curve[3]), 1.0, 1.0];
        }
        if (typeof curve !== "string") return standardBezier;
        let c = curve.trim().toLowerCase();
        if (c === "hyprland") return hyprlandBezier;
        if (c === "smooth" || c === "cubic") return smoothBezier;
        if (c === "snappy") return snappyBezier;
        if (c === "expressive") return expressiveBezier;
        if (c === "linear") return [0.0, 0.0, 1.0, 1.0, 1.0, 1.0];

        // Parse custom cubic-bezier(x1, y1, x2, y2) or "x1, y1, x2, y2"
        let m = c.match(/^(?:cubic-bezier\s*\(\s*)?([0-9.-]+)\s*,\s*([0-9.-]+)\s*,\s*([0-9.-]+)\s*,\s*([0-9.-]+)(?:\s*\))?$/);
        if (m) {
            let p1 = parseFloat(m[1]), p2 = parseFloat(m[2]), p3 = parseFloat(m[3]), p4 = parseFloat(m[4]);
            if (!isNaN(p1) && !isNaN(p2) && !isNaN(p3) && !isNaN(p4)) {
                return [p1, p2, p3, p4, 1.0, 1.0];
            }
        }
        return standardBezier;
    }

    // PopupPanel opacity formulas
    function getMorphContainerOpacity(isOpen, p) {
        return isOpen
            ? Math.min(1.0, p * 2.0)
            : Math.min(1.0, p * 1.4);
    }

    function getContentWrapperOpacity(isOpen, p) {
        return isOpen
            ? Math.max(0.0, Math.min(1.0, (p - 0.12) / 0.88))
            : Math.min(1.0, p / 0.70);
    }

    // PopupPanel duration scaling formula
    function computeScaledDuration(isOpen, currentProgress, expressiveDefault, expressiveFast) {
        let targetProgress = isOpen ? 1.0 : 0.0;
        let distance = Math.abs(targetProgress - currentProgress);
        let baseDuration = isOpen ? (expressiveDefault ?? 260) : (expressiveFast ?? 160);
        return Math.max(50, Math.round(baseDuration * Math.max(0.25, distance)));
    }

    function arraysEqual(a, b) {
        if (!Array.isArray(a) || !Array.isArray(b) || a.length !== b.length) return false;
        for (let i = 0; i < a.length; i++) {
            if (Math.abs(a[i] - b[i]) > 1e-6) return false;
        }
        return true;
    }

    Component.onCompleted: {
        let failures = 0;
        let checks = 0;

        function assertEq(name, actual, expected) {
            checks++;
            if (!arraysEqual(actual, expected)) {
                console.error("FAIL: " + name + " | Expected: " + JSON.stringify(expected) + " Got: " + JSON.stringify(actual));
                failures++;
            }
        }

        function assertTrue(name, cond, details) {
            checks++;
            if (!cond) {
                console.error("FAIL: " + name + " | " + (details ?? ""));
                failures++;
            }
        }

        console.log("=== 1. NAMED PRESETS TEST ===");
        assertEq("preset:hyprland", getBezierPoints("hyprland"), hyprlandBezier);
        assertEq("preset:HYPRLAND", getBezierPoints("HYPRLAND"), hyprlandBezier);
        assertEq("preset:  hyprland  ", getBezierPoints("  hyprland  "), hyprlandBezier);
        assertEq("preset:smooth", getBezierPoints("smooth"), smoothBezier);
        assertEq("preset:cubic", getBezierPoints("cubic"), smoothBezier);
        assertEq("preset:SMOOTH", getBezierPoints("SMOOTH"), smoothBezier);
        assertEq("preset:snappy", getBezierPoints("snappy"), snappyBezier);
        assertEq("preset:SNAPPY", getBezierPoints("SNAPPY"), snappyBezier);
        assertEq("preset:expressive", getBezierPoints("expressive"), expressiveBezier);
        assertEq("preset:EXPRESSIVE", getBezierPoints("EXPRESSIVE"), expressiveBezier);
        assertEq("preset:linear", getBezierPoints("linear"), [0.0, 0.0, 1.0, 1.0, 1.0, 1.0]);
        assertEq("preset:LINEAR", getBezierPoints("LINEAR"), [0.0, 0.0, 1.0, 1.0, 1.0, 1.0]);
        assertEq("preset:standard", getBezierPoints("standard"), standardBezier);
        assertEq("preset:STANDARD", getBezierPoints("STANDARD"), standardBezier);

        console.log("=== 2. CSS CUBIC-BEZIER & COMMA FORMATS ===");
        assertEq("css:standard", getBezierPoints("cubic-bezier(0.05, 0.9, 0.1, 1.05)"), [0.05, 0.9, 0.1, 1.05, 1.0, 1.0]);
        assertEq("css:no-space", getBezierPoints("cubic-bezier(0.05,0.9,0.1,1.05)"), [0.05, 0.9, 0.1, 1.05, 1.0, 1.0]);
        assertEq("css:extra-space", getBezierPoints("cubic-bezier(  0.05 , 0.9 , 0.1 , 1.05  )"), [0.05, 0.9, 0.1, 1.05, 1.0, 1.0]);
        assertEq("css:uppercase", getBezierPoints("CUBIC-BEZIER(0.05, 0.9, 0.1, 1.05)"), [0.05, 0.9, 0.1, 1.05, 1.0, 1.0]);
        assertEq("css:mixedcase", getBezierPoints("Cubic-Bezier(0.05, 0.9, 0.1, 1.05)"), [0.05, 0.9, 0.1, 1.05, 1.0, 1.0]);
        assertEq("comma:numbers", getBezierPoints("0.05, 0.9, 0.1, 1.05"), [0.05, 0.9, 0.1, 1.05, 1.0, 1.0]);
        assertEq("comma:spaced", getBezierPoints("  0.2 , 0.0 , 0.2 , 1.0  "), [0.2, 0.0, 0.2, 1.0, 1.0, 1.0]);
        assertEq("css:negative", getBezierPoints("cubic-bezier(-0.2, 1.5, 0.8, -0.5)"), [-0.2, 1.5, 0.8, -0.5, 1.0, 1.0]);

        console.log("=== 3. ARRAY INPUTS ===");
        assertEq("array:4-floats", getBezierPoints([0.2, 0.0, 0.2, 1.0]), [0.2, 0.0, 0.2, 1.0, 1.0, 1.0]);
        assertEq("array:6-floats", getBezierPoints([0.05, 0.9, 0.1, 1.05, 1.0, 1.0]), [0.05, 0.9, 0.1, 1.05, 1.0, 1.0]);
        assertEq("array:7-floats", getBezierPoints([0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7]), [0.1, 0.2, 0.3, 0.4, 0.5, 0.6]);
        assertEq("array:strings", getBezierPoints(["0.2", "0.0", "0.2", "1.0"]), [0.2, 0.0, 0.2, 1.0, 1.0, 1.0]);

        console.log("=== 4. EXTREME & BOUNDARY INPUTS ===");
        let boundaryCases = [
            null, undefined, "", "   ", "invalid", "cubic-bezier()",
            "cubic-bezier(a, b, c, d)", "cubic-bezier(1, 2, 3)",
            "1.2.3, 4, 5, 6", "..1, --2, 3..4, 5",
            123, 0, -1, true, false, {}, [], [1], [1, 2], [1, 2, 3],
            NaN
        ];

        for (let i = 0; i < boundaryCases.length; i++) {
            let res = getBezierPoints(boundaryCases[i]);
            assertTrue("boundary_not_null_" + i, res !== null && res !== undefined, "Result was null/undefined for " + boundaryCases[i]);
            assertTrue("boundary_is_array_" + i, Array.isArray(res), "Result was not array for " + boundaryCases[i]);
            assertTrue("boundary_length_6_" + i, res.length === 6, "Length was " + res.length + " for " + boundaryCases[i]);
            for (let j = 0; j < 6; j++) {
                assertTrue("boundary_element_valid_" + i + "_" + j, typeof res[j] === "number" && !isNaN(res[j]), "Element " + j + " invalid in " + JSON.stringify(res));
            }
        }

        console.log("=== 5. POPUPPANEL OPACITY LOCKSTEP & CLOSING VISIBILITY ===");
        // Test opening progress from 0.0 to 1.0
        let prevHull = -1.0;
        let prevContent = -1.0;
        for (let i = 0; i <= 100; i++) {
            let p = i / 100.0;
            let h = getMorphContainerOpacity(true, p);
            let c = getContentWrapperOpacity(true, p);
            assertTrue("open_hull_bounds_" + i, h >= 0.0 && h <= 1.0, "Hull opacity " + h + " out of bounds");
            assertTrue("open_content_bounds_" + i, c >= 0.0 && c <= 1.0, "Content opacity " + c + " out of bounds");
            assertTrue("open_hull_monotonic_" + i, h >= prevHull, "Hull opacity decreased");
            assertTrue("open_content_monotonic_" + i, c >= prevContent, "Content opacity decreased");
            if (p <= 0.12) {
                assertTrue("open_content_delayed_" + i, c === 0.0, "Content visible too early during open: " + c);
            }
            prevHull = h;
            prevContent = c;
        }

        // Test closing progress from 1.0 down to 0.0
        prevHull = 2.0;
        prevContent = 2.0;
        for (let i = 100; i >= 0; i--) {
            let p = i / 100.0;
            let h = getMorphContainerOpacity(false, p);
            let c = getContentWrapperOpacity(false, p);
            assertTrue("close_hull_bounds_" + i, h >= 0.0 && h <= 1.0, "Hull opacity " + h + " out of bounds");
            assertTrue("close_content_bounds_" + i, c >= 0.0 && c <= 1.0, "Content opacity " + c + " out of bounds");
            assertTrue("close_hull_monotonic_" + i, h <= prevHull, "Hull opacity increased during closing");
            assertTrue("close_content_monotonic_" + i, c <= prevContent, "Content opacity increased during closing");

            // Content remains visible down to p=0.0
            if (p > 0.0) {
                assertTrue("close_content_visible_" + i, c > 0.0, "Content extinguished prematurely at p=" + p);
            } else {
                assertTrue("close_content_zero_at_end", c === 0.0, "Content not zero at end");
                assertTrue("close_hull_zero_at_end", h === 0.0, "Hull not zero at end");
            }

            // Lockstep decay verification: difference between hull and content for p <= 0.70
            if (p <= 0.70) {
                let diff = Math.abs(h - c);
                // Difference between 1.4*p and p/0.70 (1.4286*p) is at most 0.0286 * 0.70 = 0.02
                assertTrue("lockstep_decay_" + i, diff <= 0.025, "Lockstep violated at p=" + p + ": diff=" + diff + " h=" + h + " c=" + c);
            }

            prevHull = h;
            prevContent = c;
        }

        console.log("=== 6. POPUPPANEL RAPID TOGGLE DURATION SCALING ===");
        // Full open: distance 1.0
        let dFullOpen = computeScaledDuration(true, 0.0, 260, 160);
        assertEq("duration_full_open", [dFullOpen], [260]);

        // Full close: distance 1.0
        let dFullClose = computeScaledDuration(false, 1.0, 260, 160);
        assertEq("duration_full_close", [dFullClose], [160]);

        // Small distance reversal: distance 0.1
        let dSmallOpen = computeScaledDuration(true, 0.9, 260, 160); // target 1.0, distance 0.1
        assertEq("duration_small_open", [dSmallOpen], [65]);

        let dSmallClose = computeScaledDuration(false, 0.1, 260, 160); // target 0.0, distance 0.1
        assertEq("duration_small_close", [dSmallClose], [50]);

        // Zero distance: clamped to at least 50ms
        let dZero = computeScaledDuration(false, 0.0, 260, 160);
        assertTrue("duration_zero_min_50", dZero >= 50, "Zero distance duration fell below 50ms: " + dZero);

        // Verify across all p in [0.0, 1.0] that duration is in [50, baseDuration]
        for (let i = 0; i <= 100; i++) {
            let p = i / 100.0;
            let dOpen = computeScaledDuration(true, p, 260, 160);
            let dClose = computeScaledDuration(false, p, 260, 160);
            assertTrue("dOpen_range_" + i, dOpen >= 50 && dOpen <= 260, "dOpen out of range: " + dOpen);
            assertTrue("dClose_range_" + i, dClose >= 50 && dClose <= 160, "dClose out of range: " + dClose);
        }

        console.log("=== SUMMARY ===");
        console.log("TOTAL_CHECKS: " + checks);
        console.log("FAILURES: " + failures);
        if (failures === 0) {
            console.log("ALL_TESTS_PASSED_SUCCESSFULLY");
        } else {
            console.error("TEST_SUITE_FAILED");
        }

        Qt.quit();
    }
}
