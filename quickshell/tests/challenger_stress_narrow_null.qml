import QtQuick

Item {
    id: root

    property int totalChecks: 0
    property int failures: 0

    function assertEq(name, actual, expected) {
        totalChecks++;
        if (actual !== expected) {
            console.log("[FAIL]", name, "- Actual:", actual, "Expected:", expected);
            failures++;
        }
    }

    function assertTrue(name, condition) {
        totalChecks++;
        if (!condition) {
            console.log("[FAIL]", name, "- Condition was false");
            failures++;
        }
    }

    // -------------------------------------------------------------------------
    // 1. Narrow Display Geometry Clamping
    // -------------------------------------------------------------------------
    function calcMaxRightRowWidth(screenWidth, centerWidth, padding, centerVisible) {
        let halfScreen = screenWidth / 2;
        let centerHalf = (centerVisible ? centerWidth : 0) / 2;
        let clockRight = halfScreen - centerHalf;
        return Math.max(160, clockRight - (padding * 2));
    }

    function calcMaxWindowTitleWidth(screenWidth, centerWidth, centerVisible) {
        let halfScreen = screenWidth / 2;
        let centerHalf = (centerVisible ? centerWidth : 0) / 2;
        let clockStart = halfScreen - centerHalf;
        return Math.max(160, clockStart - 260);
    }

    function calcRightRowX(screenWidth, padding, implicitWidth, maxRightRowWidth) {
        let actualWidth = Math.min(implicitWidth, maxRightRowWidth);
        return screenWidth - padding - actualWidth;
    }

    function calcCenterRightEdge(screenWidth, centerWidth, centerVisible) {
        if (!centerVisible) return 0;
        return (screenWidth / 2) + (centerWidth / 2);
    }

    function runNarrowDisplaySweeps() {
        console.log("=== 1. NARROW DISPLAY GEOMETRY STRESS SWEEPS ===");
        let displayWidths = [800, 1024, 1280, 1366, 1440, 1600, 1920, 2560, 3440, 3840];
        let clockWidths = [120, 160, 180, 200, 220, 250];
        let paddings = [8, 10, 12, 16];
        let rightRowImplicits = [180, 260, 350, 500, 750];

        for (let i = 0; i < displayWidths.length; i++) {
            let W = displayWidths[i];
            for (let j = 0; j < clockWidths.length; j++) {
                let C = clockWidths[j];
                for (let k = 0; k < paddings.length; k++) {
                    let P = paddings[k];
                    let maxR = calcMaxRightRowWidth(W, C, P, true);
                    let centerRight = calcCenterRightEdge(W, C, true);

                    for (let m = 0; m < rightRowImplicits.length; m++) {
                        let impR = rightRowImplicits[m];
                        let rightX = calcRightRowX(W, P, impR, maxR);
                        let clearance = rightX - centerRight;

                        // Verify rightRowH never overlaps centerRowH and maintains >= padding clearance
                        assertTrue(
                            "W=" + W + " C=" + C + " P=" + P + " impR=" + impR + " clearance=" + clearance + " >= P",
                            clearance >= P
                        );
                    }
                }
            }
        }
    }

    // -------------------------------------------------------------------------
    // 2. WindowTitle 1000-character sizing & Loader Clamping
    // -------------------------------------------------------------------------
    function runWindowTitleStress() {
        console.log("=== 2. WINDOW TITLE 1000-CHAR SIZING STRESS ===");
        // Generate long title (1000 chars)
        let longTitle = "";
        for (let i = 0; i < 100; i++) {
            longTitle += "AdversarialWindowTitleTest_";
        }
        longTitle = longTitle.substring(0, 1000);
        assertEq("longTitle length", longTitle.length, 1000);

        // Approximate 12px font width: ~7.5px per character -> 7500px
        let approxNaturalWidth = longTitle.length * 7.5 + 22 + 24;

        // Auto mode with maxW = 760
        let maxW = 760;
        let desiredAuto = Math.max(50, Math.min(approxNaturalWidth, maxW));
        assertEq("desiredWidth auto mode clamped to 760", desiredAuto, 760);

        // Compact mode clamped to 260
        let desiredCompact = Math.max(50, Math.min(approxNaturalWidth, 260));
        assertEq("desiredWidth compact mode clamped to 260", desiredCompact, 260);

        // Loader targetW clamping across screen widths
        let screens = [800, 1024, 1280, 1366, 1920];
        for (let s = 0; s < screens.length; s++) {
            let scrW = screens[s];
            let maxTitleW = calcMaxWindowTitleWidth(scrW, 200, true);
            let maxAllowed = Math.min(760, maxTitleW);
            let targetW = Math.max(40, Math.min(desiredAuto, maxAllowed));

            assertTrue(
                "scrW=" + scrW + " targetW=" + targetW + " <= maxWindowTitleWidth=" + maxTitleW,
                targetW <= maxTitleW
            );
            assertTrue(
                "scrW=" + scrW + " targetW=" + targetW + " <= 760",
                targetW <= 760
            );
        }
    }

    // -------------------------------------------------------------------------
    // 3. mapToItem Null Safety Simulation
    // -------------------------------------------------------------------------
    function runMapToItemNullStress() {
        console.log("=== 3. MAPTOITEM NULL SAFETY SIMULATION ===");

        // Test item with configurable mapToItem behavior
        let itemMock = {
            returnNull: true,
            mapToItem: function(target, x, y) {
                if (this.returnNull) return null;
                return { x: 120, y: 15 };
            },
            width: 80,
            height: 32
        };

        let statusBarMock = {
            isVertical: false,
            launcherPopup: {
                open: false,
                targetRelativeX: -1,
                targetRelativeY: -1
            }
        };

        // --- Simulate StatusBar launcher click with null mapToItem ---
        let sbNullThrew = false;
        try {
            let pt = itemMock.mapToItem(null, 0, 0);
            if (pt) {
                if (statusBarMock.isVertical) {
                    statusBarMock.launcherPopup.targetRelativeY = pt.y + (itemMock.height / 2);
                } else {
                    statusBarMock.launcherPopup.targetRelativeX = pt.x + (itemMock.width / 2);
                }
            }
            statusBarMock.launcherPopup.open = !statusBarMock.launcherPopup.open;
        } catch (e) {
            sbNullThrew = true;
            console.log("[FAIL] StatusBar launcher click threw:", e);
        }

        assertTrue("StatusBar null mapToItem did not throw", !sbNullThrew);
        assertTrue("StatusBar launcherPopup opened despite null mapToItem", statusBarMock.launcherPopup.open);
        assertEq("StatusBar targetRelativeX remained unchanged (-1)", statusBarMock.launcherPopup.targetRelativeX, -1);

        // --- Simulate IdleInhibitor hoverOpen with null mapToItem ---
        let cafPopupMock = {
            open: false,
            pinned: false,
            targetRelativeX: -1,
            targetRelativeY: -1
        };

        let idleNullThrew = false;
        try {
            let pt = itemMock.mapToItem(null, 0, 0);
            if (pt) {
                if (statusBarMock.isVertical) {
                    cafPopupMock.targetRelativeY = pt.y + (itemMock.height / 2);
                } else {
                    cafPopupMock.targetRelativeX = pt.x + (itemMock.width / 2);
                }
            }
            cafPopupMock.open = true;
        } catch (e) {
            idleNullThrew = true;
            console.log("[FAIL] IdleInhibitor hoverOpen threw:", e);
        }

        assertTrue("IdleInhibitor hoverOpen null mapToItem did not throw", !idleNullThrew);
        assertTrue("IdleInhibitor cafPopup opened despite null mapToItem", cafPopupMock.open);
        assertEq("IdleInhibitor targetRelativeX remained -1", cafPopupMock.targetRelativeX, -1);

        // --- Simulate IdleInhibitor right-click toggle with null mapToItem ---
        let idleRightClickThrew = false;
        try {
            let pt = itemMock.mapToItem(null, 0, 0);
            if (pt) {
                if (statusBarMock.isVertical) {
                    cafPopupMock.targetRelativeY = pt.y + (itemMock.height / 2);
                } else {
                    cafPopupMock.targetRelativeX = pt.x + (itemMock.width / 2);
                }
            }
            cafPopupMock.pinned = !cafPopupMock.open;
            cafPopupMock.open = !cafPopupMock.open;
        } catch (e) {
            idleRightClickThrew = true;
            console.log("[FAIL] IdleInhibitor right click threw:", e);
        }

        assertTrue("IdleInhibitor right-click null mapToItem did not throw", !idleRightClickThrew);

        // --- Now simulate with valid coordinate mapToItem ---
        itemMock.returnNull = false;
        let ptValid = itemMock.mapToItem(null, 0, 0);
        if (ptValid) {
            statusBarMock.launcherPopup.targetRelativeX = ptValid.x + (itemMock.width / 2);
        }
        assertEq("Valid mapToItem updates targetRelativeX correctly", statusBarMock.launcherPopup.targetRelativeX, 160);
    }

    Component.onCompleted: {
        runNarrowDisplaySweeps();
        runWindowTitleStress();
        runMapToItemNullStress();

        console.log("=== FINAL STRESS VERDICT ===");
        console.log("TOTAL_CHECKS:", totalChecks);
        console.log("FAILURES:", failures);
        if (failures === 0) {
            console.log("ALL_NARROW_NULL_STRESS_CHECKS_PASSED");
        } else {
            console.log("STRESS_TEST_FAILURES_DETECTED");
        }
        Qt.quit();
    }
}
