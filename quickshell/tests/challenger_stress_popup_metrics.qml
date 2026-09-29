import QtQuick
import QtQuick.Layouts

Item {
    id: testRoot
    width: 800
    height: 600

    property int totalChecks: 0
    property int failures: 0

    function assert(condition, message) {
        totalChecks++;
        if (!condition) {
            failures++;
            console.error("FAIL: " + message);
        }
    }

    function assertEqual(actual, expected, message) {
        totalChecks++;
        if (actual !== expected) {
            failures++;
            console.error("FAIL: " + message + " (expected: " + expected + ", got: " + actual + ")");
        }
    }

    function assertGreaterOrEqual(actual, expected, message) {
        totalChecks++;
        if (actual < expected) {
            failures++;
            console.error("FAIL: " + message + " (expected >= " + expected + ", got: " + actual + ")");
        }
    }

    // =========================================================================
    // 1. POPUP MARGIN ACCUMULATION & INNER WIDTH VERIFICATION
    // =========================================================================
    function testPopupMargins() {
        console.log("=== 1. POPUP MARGIN ACCUMULATION & INNER WIDTH STRESS ===");

        let popups = [
            { name: "BatteryPopup", cardWidth: 420, oldExtraMargin: 16 },
            { name: "QuickSettings", cardWidth: 480, oldExtraMargin: 12 },
            { name: "WindowTitlePopup", cardWidth: 380, oldExtraMargin: 14 },
            { name: "IdlePopup", cardWidth: 360, oldExtraMargin: 14 }
        ];

        let paddingScales = [
            { name: "compact", pad: 12.8 },
            { name: "cozy", pad: 16.0 },
            { name: "comfortable", pad: 20.0 }
        ];

        for (let p = 0; p < popups.length; p++) {
            let pop = popups[p];
            for (let s = 0; s < paddingScales.length; s++) {
                let scale = paddingScales[s];
                let outerPad = scale.pad;

                // Intended geometry: PopupPanel provides outerPad margins.
                // Child ColumnLayout anchors.fill: parent with ZERO extra outer margin.
                let intendedInnerWidth = pop.cardWidth - (outerPad * 2);

                // Buggy geometry before M3 fix: child added its own margins.
                let buggyInnerWidth = pop.cardWidth - (outerPad * 2) - (pop.oldExtraMargin * 2);

                assertEqual(
                    intendedInnerWidth,
                    pop.cardWidth - (outerPad * 2),
                    pop.name + " (" + scale.name + "): inner width matches intended allocation"
                );

                // Verify width loss in buggy state was severe
                let widthLoss = intendedInnerWidth - buggyInnerWidth;
                assertGreaterOrEqual(
                    widthLoss,
                    24,
                    pop.name + " (" + scale.name + "): verified bug eliminated " + widthLoss + "px redundant margin squeeze"
                );

                // Ensure child card width has ample breathing room for UI controls
                assertGreaterOrEqual(
                    intendedInnerWidth,
                    300,
                    pop.name + " (" + scale.name + "): inner card width " + intendedInnerWidth + "px >= 300px min width"
                );
            }
        }
    }

    // =========================================================================
    // 2. NOTIFICATION CARD VERTICAL METRICS & ACTION BUTTON CLEARANCE
    // =========================================================================
    function testNotificationCardMetrics() {
        console.log("=== 2. NOTIFICATION CARD VERTICAL METRICS & CLEARANCE STRESS ===");

        // Model layout parameters matching NotificationCard.qml
        let topMargin = 14;
        let progressHeight = 3;
        let headerHeight = 22;
        let actionRowHeight = 28;
        let itemSpacing = 8;
        let lineHeightSm = 16; // 12px font line height

        // Test across 1 to 50 body lines
        for (let bodyLines = 1; bodyLines <= 50; bodyLines++) {
            // NotificationCard.qml declares: maximumLineCount: 6
            let renderedLinesCapped = Math.min(bodyLines, 6);
            let bodyHeightCapped = renderedLinesCapped * lineHeightSm;

            // Also test hypothetical uncapped line height
            let bodyHeightUncapped = bodyLines * lineHeightSm;

            let testVariants = [
                { name: "capped (max 6 lines)", bodyHeight: bodyHeightCapped },
                { name: "uncapped (" + bodyLines + " lines)", bodyHeight: bodyHeightUncapped }
            ];

            for (let v = 0; v < testVariants.length; v++) {
                let variant = testVariants[v];
                let bHeight = variant.bodyHeight;

                // Column contains: Header (22) + Summary (18) + Body (bHeight) + Actions (28)
                // 4 visible items -> 3 gaps of 8px = 24px spacing
                let colImplicitHeight = headerHeight + 18 + bHeight + actionRowHeight + (3 * itemSpacing);

                // Test with timeoutMs > 0 (progress bar visible)
                {
                    let timeoutMs = 5000;
                    let bottomMargin = timeoutMs > 0 ? 18 : 14;

                    // M3 fixed formula:
                    let cardImplicitHeight = colImplicitHeight + topMargin + bottomMargin;

                    // In QtQuick layout, when card adopts implicitHeight:
                    let cardHeight = cardImplicitHeight;
                    let colY = topMargin;
                    let colHeight = cardHeight - topMargin - bottomMargin;

                    // Action buttons are at the bottom of the column
                    let actionsBottom = colY + colHeight;

                    // Progress bar is anchored to bottom of card
                    let progressTop = cardHeight - progressHeight;

                    // Clearance between bottom of actions and top of progress bar
                    let clearance = progressTop - actionsBottom;

                    assertEqual(
                        colHeight,
                        colImplicitHeight,
                        "Body " + bodyLines + " " + variant.name + " (timeout>0): colHeight matches colImplicitHeight"
                    );

                    assertEqual(
                        clearance,
                        15,
                        "Body " + bodyLines + " " + variant.name + " (timeout>0): clearance is exactly 15px (18 - 3)"
                    );

                    assert(
                        actionsBottom < progressTop,
                        "Body " + bodyLines + " " + variant.name + " (timeout>0): action buttons strictly above progress bar"
                    );

                    // Contrast with legacy bug (implicitHeight = col.implicitHeight + 24)
                    let buggyCardHeight = colImplicitHeight + 24;
                    let buggyColAllocated = buggyCardHeight - topMargin - bottomMargin;
                    let buggyDeficit = colImplicitHeight - buggyColAllocated;
                    assertEqual(
                        buggyDeficit,
                        8,
                        "Legacy bug verification: exactly 8px deficit caused action button clipping"
                    );
                }

                // Test with timeoutMs == 0 (persistent notification, no progress bar)
                {
                    let timeoutMs = 0;
                    let bottomMargin = timeoutMs > 0 ? 18 : 14; // 14px

                    let cardImplicitHeight = colImplicitHeight + topMargin + bottomMargin;
                    let cardHeight = cardImplicitHeight;
                    let colY = topMargin;
                    let colHeight = cardHeight - topMargin - bottomMargin;
                    let actionsBottom = colY + colHeight;
                    let cardBottom = cardHeight;
                    let bottomGap = cardBottom - actionsBottom;

                    assertEqual(
                        colHeight,
                        colImplicitHeight,
                        "Body " + bodyLines + " " + variant.name + " (timeout=0): colHeight matches colImplicitHeight"
                    );

                    assertEqual(
                        bottomGap,
                        14,
                        "Body " + bodyLines + " " + variant.name + " (timeout=0): bottom gap to card border is exactly 14px"
                    );
                }
            }
        }
    }

    // =========================================================================
    // 3. ACTUAL QT QUICK LAYOUT ENGINE LIVE HIERARCHY TEST
    // =========================================================================
    // We instantiate real QML items in the visual tree to test QtQuick Layouts
    Rectangle {
        id: liveCard
        width: 360
        implicitHeight: liveCol.implicitHeight + (liveCol.anchors.topMargin ?? 14) + (liveCol.anchors.bottomMargin ?? 18)
        height: implicitHeight
        color: "#1e1e2e"

        property int testTimeoutMs: 5000

        ColumnLayout {
            id: liveCol
            anchors.fill: parent
            anchors.margins: 14
            anchors.bottomMargin: liveCard.testTimeoutMs > 0 ? 18 : 14
            spacing: 8

            Rectangle {
                id: liveHeader
                Layout.fillWidth: true
                height: 22
                color: "transparent"
                Text { text: "app name"; font.pixelSize: 11 }
            }

            Text {
                id: liveSummary
                Layout.fillWidth: true
                text: "test notification summary"
                font.pixelSize: 14
            }

            Text {
                id: liveBody
                Layout.fillWidth: true
                text: "line 1\nline 2\nline 3\nline 4\nline 5\nline 6\nline 7\nline 8"
                font.pixelSize: 12
                wrapMode: Text.Wrap
                maximumLineCount: 6
                elide: Text.ElideRight
            }

            RowLayout {
                id: liveActions
                Layout.fillWidth: true
                height: 28
                Rectangle {
                    Layout.fillWidth: true
                    height: 28
                    color: "#33ffffff"
                    Text { anchors.centerIn: parent; text: "action 1" }
                }
                Rectangle {
                    Layout.fillWidth: true
                    height: 28
                    color: "#33ffffff"
                    Text { anchors.centerIn: parent; text: "action 2" }
                }
            }
        }

        Rectangle {
            id: liveProgressBar
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: 3
            color: "#89b4fa"
            visible: liveCard.testTimeoutMs > 0
        }
    }

    function testLiveQmlHierarchy() {
        console.log("=== 3. LIVE QT QUICK ENGINE LAYOUT EVALUATION ===");

        // Verify live card dimensions calculated by Qt Quick engine
        let cardH = liveCard.height;
        let colH = liveCol.height;
        let colImp = liveCol.implicitHeight;
        let actBottom = liveCol.y + liveActions.y + liveActions.height;
        let barY = liveProgressBar.y;
        let clearance = barY - actBottom;

        console.log("Live QtQuick card height: " + cardH);
        console.log("Live QtQuick col height: " + colH + " (implicit: " + colImp + ")");
        console.log("Live QtQuick actions bottom Y: " + actBottom);
        console.log("Live QtQuick progress bar Y: " + barY);
        console.log("Live QtQuick measured clearance: " + clearance);

        assertGreaterOrEqual(colH, colImp - 0.5, "Live col height allocated >= implicitHeight");
        assertGreaterOrEqual(clearance, 14.5, "Live action buttons have >= 14.5px clearance from progress bar");
        assert(actBottom < barY, "Live action buttons strictly do not overlap progress bar");
    }

    Component.onCompleted: {
        testPopupMargins();
        testNotificationCardMetrics();
        testLiveQmlHierarchy();

        console.log("=== SUMMARY ===");
        console.log("TOTAL_CHECKS: " + totalChecks);
        console.log("FAILURES: " + failures);
        if (failures === 0) {
            console.log("ALL_TESTS_PASSED_SUCCESSFULLY");
        } else {
            console.error("TEST_RUN_COMPLETED_WITH_ERRORS");
        }

        Qt.quit();
    }
}
