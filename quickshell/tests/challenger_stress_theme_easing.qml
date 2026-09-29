import QtQuick

Item {
    id: root

    // Direct transliteration from Theme.qml
    function getEasing(curve, type) {
        let c = (curve ?? "cubic").toLowerCase();
        let t = (type ?? "out").toLowerCase();
        if (c === "linear") return Easing.Linear;
        if (c === "quad") {
            if (t === "in") return Easing.InQuad;
            if (t === "inout" || t === "in_out") return Easing.InOutQuad;
            if (t === "outin" || t === "out_in") return Easing.OutInQuad;
            return Easing.OutQuad;
        }
        if (c === "quart") {
            if (t === "in") return Easing.InQuart;
            if (t === "inout" || t === "in_out") return Easing.InOutQuart;
            if (t === "outin" || t === "out_in") return Easing.OutInQuart;
            return Easing.OutQuart;
        }
        if (c === "quint") {
            if (t === "in") return Easing.InQuint;
            if (t === "inout" || t === "in_out") return Easing.InOutQuint;
            if (t === "outin" || t === "out_in") return Easing.OutInQuint;
            return Easing.OutQuint;
        }
        if (c === "sine") {
            if (t === "in") return Easing.InSine;
            if (t === "inout" || t === "in_out") return Easing.InOutSine;
            if (t === "outin" || t === "out_in") return Easing.OutInSine;
            return Easing.OutSine;
        }
        if (c === "expo") {
            if (t === "in") return Easing.InExpo;
            if (t === "inout" || t === "in_out") return Easing.InOutExpo;
            if (t === "outin" || t === "out_in") return Easing.OutInExpo;
            return Easing.OutExpo;
        }
        if (c === "circ") {
            if (t === "in") return Easing.InCirc;
            if (t === "inout" || t === "in_out") return Easing.InOutCirc;
            if (t === "outin" || t === "out_in") return Easing.OutInCirc;
            return Easing.OutCirc;
        }
        if (c === "back") {
            if (t === "in") return Easing.InBack;
            if (t === "inout" || t === "in_out") return Easing.InOutBack;
            if (t === "outin" || t === "out_in") return Easing.OutInBack;
            return Easing.OutBack;
        }
        if (c === "elastic") {
            if (t === "in") return Easing.InElastic;
            if (t === "inout" || t === "in_out") return Easing.InOutElastic;
            if (t === "outin" || t === "out_in") return Easing.OutInElastic;
            return Easing.OutElastic;
        }
        if (c === "bounce") {
            if (t === "in") return Easing.InBounce;
            if (t === "inout" || t === "in_out") return Easing.InOutBounce;
            if (t === "outin" || t === "out_in") return Easing.OutInBounce;
            return Easing.OutBounce;
        }
        if (t === "in") return Easing.InCubic;
        if (t === "inout" || t === "in_out") return Easing.InOutCubic;
        if (t === "outin" || t === "out_in") return Easing.OutInCubic;
        return Easing.OutCubic;
    }

    // Direct transliteration of paddingScaleMult from Theme.qml
    function getPaddingScaleMult(paddingScale) {
        let ps = paddingScale;
        if (ps === "compact") return 0.8;
        if (ps === "comfortable") return 1.25;
        return 1.0;
    }

    // Direct transliteration of animSpeedMult from Theme.qml
    function getAnimSpeedMult(animSpeed) {
        let sp = animSpeed ?? "normal";
        if (sp === "instant") return 0.01;
        if (sp === "snappy" || sp === "superSnappy") return 0.7;
        if (sp === "hyper") return 0.4;
        if (sp === "chill") return 1.6;
        return 1.0;
    }

    // Direct transliteration of durations from Theme.qml
    function calculateDurations(fast, normal, slow, speed) {
        let mult = getAnimSpeedMult(speed);
        return {
            fast: Math.round((fast ?? 120) * mult),
            normal: Math.round((normal ?? 200) * mult),
            slow: Math.round((slow ?? 350) * mult)
        };
    }

    Component.onCompleted: {
        let failures = 0;
        let total = 0;

        function assertEq(name, actual, expected) {
            total++;
            if (actual !== expected) {
                console.log("[FAIL]", name, "- Actual:", actual, "Expected:", expected);
                failures++;
            } else {
                // pass
            }
        }

        function assertValidEasing(name, val) {
            total++;
            if (typeof val !== "number" || isNaN(val) || val === undefined || val === null || val < 0) {
                console.log("[FAIL]", name, "- Invalid easing enum value:", val);
                failures++;
            }
        }

        console.log("=== 1. STANDARD CURVES & EASING TYPES ===");
        const curves = [
            { name: "linear", in: Easing.Linear, out: Easing.Linear, inout: Easing.Linear, outin: Easing.Linear },
            { name: "quad", in: Easing.InQuad, out: Easing.OutQuad, inout: Easing.InOutQuad, outin: Easing.OutInQuad },
            { name: "cubic", in: Easing.InCubic, out: Easing.OutCubic, inout: Easing.InOutCubic, outin: Easing.OutInCubic },
            { name: "quart", in: Easing.InQuart, out: Easing.OutQuart, inout: Easing.InOutQuart, outin: Easing.OutInQuart },
            { name: "quint", in: Easing.InQuint, out: Easing.OutQuint, inout: Easing.InOutQuint, outin: Easing.OutInQuint },
            { name: "sine", in: Easing.InSine, out: Easing.OutSine, inout: Easing.InOutSine, outin: Easing.OutInSine },
            { name: "expo", in: Easing.InExpo, out: Easing.OutExpo, inout: Easing.InOutExpo, outin: Easing.OutInExpo },
            { name: "circ", in: Easing.InCirc, out: Easing.OutCirc, inout: Easing.InOutCirc, outin: Easing.OutInCirc },
            { name: "back", in: Easing.InBack, out: Easing.OutBack, inout: Easing.InOutBack, outin: Easing.OutInBack },
            { name: "elastic", in: Easing.InElastic, out: Easing.OutElastic, inout: Easing.InOutElastic, outin: Easing.OutInElastic },
            { name: "bounce", in: Easing.InBounce, out: Easing.OutBounce, inout: Easing.InOutBounce, outin: Easing.OutInBounce }
        ];

        for (let item of curves) {
            assertEq(item.name + "_in", getEasing(item.name, "in"), item.in);
            assertEq(item.name + "_out", getEasing(item.name, "out"), item.out);
            assertEq(item.name + "_inout", getEasing(item.name, "inout"), item.inout);
            assertEq(item.name + "_outin", getEasing(item.name, "outin"), item.outin);

            // test snake_case variants
            assertEq(item.name + "_in_out", getEasing(item.name, "in_out"), item.inout);
            assertEq(item.name + "_out_in", getEasing(item.name, "out_in"), item.outin);
        }

        console.log("=== 2. CASE INSENSITIVITY ===");
        assertEq("CUBIC_OUT", getEasing("CUBIC", "OUT"), Easing.OutCubic);
        assertEq("QuAd_InOuT", getEasing("QuAd", "InOuT"), Easing.InOutQuad);
        assertEq("BoUnCe_OuTiN", getEasing("BoUnCe", "OuTiN"), Easing.OutInBounce);
        assertEq("LiNeAr_IN", getEasing("LiNeAr", "IN"), Easing.Linear);
        assertEq("ELASTIC_IN", getEasing("ELASTIC", "IN"), Easing.InElastic);
        assertEq("CIRC_OUTIN", getEasing("CIRC", "OUTIN"), Easing.OutInCirc);

        console.log("=== 3. EDGE CASES & FALLBACK ROBUSTNESS ===");
        // null / undefined combinations
        assertEq("null_null", getEasing(null, null), Easing.OutCubic);
        assertEq("undefined_undefined", getEasing(undefined, undefined), Easing.OutCubic);
        assertEq("cubic_null", getEasing("cubic", null), Easing.OutCubic);
        assertEq("quad_null", getEasing("quad", null), Easing.OutQuad);
        assertEq("null_in", getEasing(null, "in"), Easing.InCubic);
        assertEq("null_inout", getEasing(null, "inout"), Easing.InOutCubic);
        assertEq("null_outin", getEasing(null, "outin"), Easing.OutInCubic);

        // Unknown curve fallback (must fallback to cubic with given type)
        assertEq("unknown_curve_out", getEasing("superCustom", "out"), Easing.OutCubic);
        assertEq("unknown_curve_in", getEasing("superCustom", "in"), Easing.InCubic);
        assertEq("unknown_curve_inout", getEasing("superCustom", "inout"), Easing.InOutCubic);
        assertEq("unknown_curve_outin", getEasing("superCustom", "outin"), Easing.OutInCubic);
        assertEq("unknown_curve_unknown_type", getEasing("foobar", "baz"), Easing.OutCubic);

        // Empty string
        assertEq("empty_empty", getEasing("", ""), Easing.OutCubic);
        assertEq("quad_empty", getEasing("quad", ""), Easing.OutQuad);

        // Verify return type is strictly a valid Qt Quick Easing enum
        const testInputs = [
            [null, null], [undefined, undefined], ["", ""], ["unknown", "unknown"],
            ["quad", "invalid"], ["elastic", 123], [true, false], [{}, []]
        ];
        for (let pair of testInputs) {
            try {
                let res = getEasing(pair[0], pair[1]);
                assertValidEasing("valid_enum_" + pair[0] + "_" + pair[1], res);
            } catch (e) {
                // If it throws on non-string like {} or 123 because of toLowerCase()
                console.log("[INFO] Non-string input threw as expected in JS:", pair[0], pair[1], e.message);
            }
        }

        console.log("=== 4. PADDING SCALE MULTIPLIER ===");
        assertEq("padding_compact", getPaddingScaleMult("compact"), 0.8);
        assertEq("padding_cozy", getPaddingScaleMult("cozy"), 1.0);
        assertEq("padding_comfortable", getPaddingScaleMult("comfortable"), 1.25);
        // Fallbacks
        assertEq("padding_null", getPaddingScaleMult(null), 1.0);
        assertEq("padding_undefined", getPaddingScaleMult(undefined), 1.0);
        assertEq("padding_empty", getPaddingScaleMult(""), 1.0);
        assertEq("padding_unknown", getPaddingScaleMult("dense"), 1.0);
        assertEq("padding_numeric", getPaddingScaleMult(123), 1.0);

        console.log("=== 5. ANIMATION SPEED MULTIPLIER & DURATION CALCULATION ===");
        // animSpeedMult values
        assertEq("speed_instant", getAnimSpeedMult("instant"), 0.01);
        assertEq("speed_snappy", getAnimSpeedMult("snappy"), 0.7);
        assertEq("speed_superSnappy", getAnimSpeedMult("superSnappy"), 0.7);
        assertEq("speed_hyper", getAnimSpeedMult("hyper"), 0.4);
        assertEq("speed_chill", getAnimSpeedMult("chill"), 1.6);
        assertEq("speed_normal", getAnimSpeedMult("normal"), 1.0);
        assertEq("speed_null", getAnimSpeedMult(null), 1.0);
        assertEq("speed_undefined", getAnimSpeedMult(undefined), 1.0);
        assertEq("speed_unknown", getAnimSpeedMult("ludicrous"), 1.0);

        // Durations with defaults: 120, 200, 350
        let dNormal = calculateDurations(120, 200, 350, "normal");
        assertEq("d_normal_fast", dNormal.fast, 120);
        assertEq("d_normal_normal", dNormal.normal, 200);
        assertEq("d_normal_slow", dNormal.slow, 350);

        let dInstant = calculateDurations(120, 200, 350, "instant");
        assertEq("d_instant_fast", dInstant.fast, 1);    // Math.round(120 * 0.01) = 1
        assertEq("d_instant_normal", dInstant.normal, 2);  // Math.round(200 * 0.01) = 2
        assertEq("d_instant_slow", dInstant.slow, 4);    // Math.round(350 * 0.01) = 4

        let dHyper = calculateDurations(120, 200, 350, "hyper");
        assertEq("d_hyper_fast", dHyper.fast, 48);   // Math.round(120 * 0.4) = 48
        assertEq("d_hyper_normal", dHyper.normal, 80); // Math.round(200 * 0.4) = 80
        assertEq("d_hyper_slow", dHyper.slow, 140);  // Math.round(350 * 0.4) = 140

        let dSnappy = calculateDurations(120, 200, 350, "snappy");
        assertEq("d_snappy_fast", dSnappy.fast, 84);   // Math.round(120 * 0.7) = 84
        assertEq("d_snappy_normal", dSnappy.normal, 140); // Math.round(200 * 0.7) = 140
        assertEq("d_snappy_slow", dSnappy.slow, 245);  // Math.round(350 * 0.7) = 245

        let dChill = calculateDurations(120, 200, 350, "chill");
        assertEq("d_chill_fast", dChill.fast, 192);  // Math.round(120 * 1.6) = 192
        assertEq("d_chill_normal", dChill.normal, 320); // Math.round(200 * 1.6) = 320
        assertEq("d_chill_slow", dChill.slow, 560);  // Math.round(350 * 1.6) = 560

        // Zero / Boundary duration checks
        let dZero = calculateDurations(0, 0, 0, "normal");
        assertEq("d_zero_fast", dZero.fast, 0);
        assertEq("d_zero_normal", dZero.normal, 0);
        assertEq("d_zero_slow", dZero.slow, 0);

        console.log("=== RESULTS ===");
        console.log("TOTAL_CHECKS:", total);
        console.log("FAILURES:", failures);
        if (failures === 0) {
            console.log("ALL_TESTS_PASSED_SUCCESSFULLY");
        } else {
            console.log("TESTS_FAILED_WITH_ERRORS:", failures);
        }

        Qt.quit();
    }
}
