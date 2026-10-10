pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    readonly property var cfg: (typeof Settings !== "undefined" ? Settings : null)

    // reactive zero-restart theming watcher for palette.css
    property var paletteWatcher: FileView {
        path: (Quickshell.env("XDG_CONFIG_HOME") || ((Quickshell.env("HOME") || "") + "/.config")) + "/quickshell/palette.css"
        watchChanges: true
        printErrors: false
    }

    // ticking time bomb so the widgets know when to panic
    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    // native hardware-accelerated wallpaper color quantizer for adaptive material vibrancy
    ColorQuantizer {
        id: wpQuantizer
        depth: 2
        source: {
            let wp = cfg?.currentWallpaper ?? "";
            if (!wp) return "";
            if (wp.startsWith("/") || wp.startsWith("~")) {
                let p = wp.startsWith("~") ? ((Quickshell.env("HOME") || "") + wp.slice(1)) : wp;
                return "file://" + p;
            }
            return wp;
        }
    }

    readonly property real wallpaperVibrancy: {
        if (!wpQuantizer.colors || wpQuantizer.colors.length === 0) return 0.5;
        let maxSat = 0.0;
        for (let i = 0; i < wpQuantizer.colors.length; i++) {
            let c = wpQuantizer.colors[i];
            if (!c) continue;
            let r = c.r, g = c.g, b = c.b;
            let mx = Math.max(r, g, b);
            let mn = Math.min(r, g, b);
            let sat = mx === 0 ? 0 : (mx - mn) / mx;
            if (sat > maxSat) maxSat = sat;
        }
        return Math.max(0.1, Math.min(1.0, maxSat));
    }

    readonly property real adaptiveSurfaceAlpha: {
        if (!(cfg?.adaptiveTransparency ?? true)) return surfaceOpacity;
        return Math.min(1.0, surfaceOpacity + (wallpaperVibrancy * 0.08));
    }

    // raw hex slop scraped from the system matrix
    readonly property color primary:               "{{colors.primary.default.hex}}"
    readonly property color on_primary:            "{{colors.on_primary.default.hex}}"
    readonly property color primary_container:     "{{colors.primary_container.default.hex}}"
    readonly property color on_primary_container:  "{{colors.on_primary_container.default.hex}}"

    readonly property color secondary:             "{{colors.secondary.default.hex}}"
    readonly property color on_secondary:          "{{colors.on_secondary.default.hex}}"
    readonly property color secondary_container:   "{{colors.secondary_container.default.hex}}"
    readonly property color on_secondary_container:"{{colors.on_secondary_container.default.hex}}"

    readonly property color tertiary:              "{{colors.tertiary.default.hex}}"
    readonly property color on_tertiary:           "{{colors.on_tertiary.default.hex}}"
    readonly property color tertiary_container:    "{{colors.tertiary_container.default.hex}}"
    readonly property color on_tertiary_container: "{{colors.on_tertiary_container.default.hex}}"

    readonly property color error:                 "{{colors.error.default.hex}}"
    readonly property color on_error:              "{{colors.on_error.default.hex}}"
    readonly property color error_container:       "{{colors.error_container.default.hex}}"
    readonly property color on_error_container:    "{{colors.on_error_container.default.hex}}"

    readonly property color background:            "{{colors.background.default.hex}}"
    readonly property color on_background:         "{{colors.on_background.default.hex}}"

    readonly property color surface:               "{{colors.surface.default.hex}}"
    readonly property color on_surface:            "{{colors.on_surface.default.hex}}"
    readonly property color surface_variant:       "{{colors.surface_variant.default.hex}}"
    readonly property color on_surface_variant:    "{{colors.on_surface_variant.default.hex}}"
    readonly property color textPrimary:           on_surface
    readonly property color textSecondary:         on_surface_variant

    readonly property color surface_container_lowest:  "{{colors.surface_container_lowest.default.hex}}"
    readonly property color surface_container_low:     "{{colors.surface_container_low.default.hex}}"
    readonly property color surface_container:         "{{colors.surface_container.default.hex}}"
    readonly property color surface_container_high:    "{{colors.surface_container_high.default.hex}}"
    readonly property color surface_container_highest: "{{colors.surface_container_highest.default.hex}}"

    readonly property color surface_dim:           "{{colors.surface_dim.default.hex}}"
    readonly property color surface_bright:        "{{colors.surface_bright.default.hex}}"

    readonly property color outline:                "{{colors.outline.default.hex}}"
    readonly property color outline_variant:        "{{colors.outline_variant.default.hex}}"

    readonly property color shadow:                 "{{colors.shadow.default.hex}}"
    readonly property color scrim:                  "{{colors.scrim.default.hex}}"

    readonly property color inverse_surface:        "{{colors.inverse_surface.default.hex}}"
    readonly property color inverse_on_surface:     "{{colors.inverse_on_surface.default.hex}}"
    readonly property color inverse_primary:        "{{colors.inverse_primary.default.hex}}"
    readonly property color source_color:           "{{colors.source_color.default.hex}}"

    // math black magic so the engine doesn't combust,
    // upgraded to approximate linear color space so gradients don't look like dishwater
    function alpha(c: color, a: real): color {
        // qml color coercion is weird, catch absolute garbage
        if (c === undefined || c.r === undefined) return Qt.rgba(0, 0, 0, 0);
        let val = (typeof a !== "number" || isNaN(a)) ? 1.0 : Math.max(0.0, Math.min(1.0, a));
        return Qt.rgba(c.r, c.g, c.b, val);
    }

    function blend(c1: color, c2: color, t: real): color {
        if (c1 === undefined || c1.r === undefined) return (c2 !== undefined) ? c2 : Qt.rgba(0, 0, 0, 0);
        if (c2 === undefined || c2.r === undefined) return c1;
        
        // fixed the variable reference error that would have segfaulted your ui
        let f = (typeof t !== "number" || isNaN(t)) ? 0.0 : Math.max(0.0, Math.min(1.0, t));
        let inv = 1.0 - f;
        
        // gamma correction approximation (squaring the channels)
        // prevents the muddy grey deadzone in the middle of standard srgb transitions
        return Qt.rgba(
            Math.sqrt((c1.r * c1.r * inv) + (c2.r * c2.r * f)),
            Math.sqrt((c1.g * c1.g * inv) + (c2.g * c2.g * f)),
            Math.sqrt((c1.b * c1.b * inv) + (c2.b * c2.b * f)),
            (c1.a * inv) + (c2.a * f) // alpha is inherently linear
        );
    }

    function formatBytes(bytes: real): string {
        if (!bytes || bytes <= 0 || isNaN(bytes)) return "0 b";
        const units = ["b", "kib", "mib", "gib", "tib"];
        let i = Math.max(0, Math.min(units.length - 1, Math.floor(Math.log(bytes) / Math.log(1024))));
        let val = bytes / Math.pow(1024, i);
        return (val >= 100 || i === 0 ? Math.round(val) : val.toFixed(1)) + " " + units[i];
    }

    function formatUptime(sec: int): string {
        if (!sec || sec <= 0 || isNaN(sec)) return "0m";
        let d = Math.floor(sec / 86400);
        let h = Math.floor((sec % 86400) / 3600);
        let m = Math.floor((sec % 3600) / 60);
        if (d > 0) return d + "d " + h + "h";
        if (h > 0) return h + "h " + m + "m";
        return m + "m";
    }

    function getBatteryColor(pct: int, isCharging: bool): color {
        if (isCharging) return primary;
        let p = (pct === undefined || isNaN(pct)) ? 100 : pct;
        if (p <= 15) return error;
        if (p <= 30) return warn;
        return on_surface;
    }

    // radioactive state tints and depression overlays
    readonly property color primary_overlay:        alpha(primary, 0.18)
    readonly property color secondary_overlay:      alpha(secondary, 0.18)
    readonly property color tertiary_overlay:       alpha(tertiary, 0.18)
    readonly property color error_overlay:          alpha(error, 0.22)
    readonly property color warn:                   tertiary
    readonly property color warn_container:         tertiary_container
    readonly property color on_warn_container:      on_tertiary_container
    readonly property color warn_overlay:           tertiary_overlay

    // official material 3 interaction state layers (8% hover, 10% focus, 12% press, 16% drag)
    function stateHover(baseColor: color, contentColor: color): color {
        return blend(baseColor, (contentColor !== undefined && contentColor !== "" ? contentColor : on_surface), 0.08);
    }
    function stateFocus(baseColor: color, contentColor: color): color {
        return blend(baseColor, (contentColor !== undefined && contentColor !== "" ? contentColor : on_surface), 0.10);
    }
    function statePress(baseColor: color, contentColor: color): color {
        return blend(baseColor, (contentColor !== undefined && contentColor !== "" ? contentColor : on_surface), 0.12);
    }
    function stateDrag(baseColor: color, contentColor: color): color {
        return blend(baseColor, (contentColor !== undefined && contentColor !== "" ? contentColor : on_surface), 0.16);
    }

    readonly property color on_surface_disabled:    alpha(on_surface, 0.38)
    readonly property color outline_disabled:       alpha(outline, 0.12)
    readonly property color fontStrokeColor:        "#000000"
    readonly property color textStroke:             "#000000"
    readonly property color textShadow:             "#000000"

    // font witchcraft and pixel size guesswork
    readonly property string fontSans:              cfg?.fontSans ?? cfg?.fontFamily ?? "Noto Sans"
    readonly property string fontMono:              cfg?.fontMono ?? "JetBrainsMono Nerd Font"
    readonly property string fontDisplay:           cfg?.fontDisplay ?? fontSans

    // font fallback pile so glyphs dont turn into tofu rectangles
    readonly property var    fontFamiliesVibe:      [fontSans, "Noto Sans", "Noto Sans CJK JP", "Noto Color Emoji"]
    readonly property string fontVibe:              fontSans
    readonly property string fontFamily:            fontSans

    readonly property int    fontWeightLight:       300
    readonly property int    fontWeightRegular:     400
    readonly property int    fontWeightMedium:      500
    readonly property int    fontWeightDemiBold:    600
    readonly property int    fontWeightBold:        700

    readonly property real   fontScale:             cfg?.fontScale ?? 1.0
    readonly property int    fontSizeXs:            Math.round(9 * fontScale)
    readonly property int    fontSizeSm:            Math.round(11 * fontScale)
    readonly property int    fontSizeMd:            Math.round(13 * fontScale)
    readonly property int    fontSizeLg:            Math.round(15 * fontScale)
    readonly property int    fontSizeXl:            Math.round(18 * fontScale)
    readonly property int    fontSizeTitle:         Math.round(22 * fontScale)

    // translation layer between random strings and qt font weight deities
    function getFontWeight(weight: string): int {
        if (!weight || typeof weight !== "string") return Font.Normal;
        let w = weight.toLowerCase().trim();
        const map = {
            "thin": Font.Thin, "extralight": Font.ExtraLight, "ultralight": Font.ExtraLight,
            "light": Font.Light, "normal": Font.Normal, "regular": Font.Normal,
            "medium": Font.Medium, "demibold": Font.DemiBold, "semibold": Font.DemiBold,
            "bold": Font.Bold, "extrabold": Font.ExtraBold, "ultrabold": Font.ExtraBold,
            "black": Font.Black, "heavy": Font.Black
        };
        return map[w] ?? Font.Normal;
    }

    // rounding corners until my screen turns into an oval pebble
    readonly property int    widgetRadius:          cfg?.widgetRadius ?? 6
    readonly property int    popupRadius:           cfg?.popupRadius ?? 8
    readonly property int    radiusXs:              4
    readonly property int    radiusSm:              Math.max(3, Math.round(widgetRadius * 0.75))
    readonly property int    radiusMd:              Math.max(4, widgetRadius)
    readonly property int    radiusLg:              Math.max(8, popupRadius)
    readonly property int    radiusXl:              Math.max(14, Math.round(popupRadius * 1.75))
    readonly property int    radiusXxl:             Math.max(18, Math.round(popupRadius * 2.0))
    readonly property int    radiusPill:            9999
    readonly property int    radiusFull:            9999

    readonly property int    barHeight:             cfg?.barHeight ?? 32
    readonly property int    barRadius:             cfg?.barRadius ?? 0
    readonly property int    widgetSpacing:         cfg?.widgetSpacing ?? 4
    readonly property int    widgetPaddingH:        cfg?.widgetPaddingH ?? 8
    readonly property int    widgetPaddingV:        cfg?.widgetPaddingV ?? 4
    readonly property string paddingScale:          cfg?.paddingScale ?? "cozy"
    readonly property real   paddingScaleMult: {
        let ps = paddingScale;
        if (ps === "compact") return 0.8;
        if (ps === "comfortable") return 1.25;
        return 1.0;
    }
    readonly property real   barOpacity:            cfg?.barOpacity ?? 1.0
    readonly property real   popupOpacity:          cfg?.popupOpacity ?? 1.0
    readonly property real   glassmorphismLevel:    cfg?.glassmorphismLevel ?? 0.85
    readonly property real   cardOpacity:           cfg?.cardOpacity ?? 0.95
    readonly property real   surfaceOpacity:        cfg?.surfaceOpacity ?? 0.90

    readonly property int    scoopRadiusX:          cfg?.scoopRadius ?? 16
    readonly property int    scoopRadiusY:          cfg?.scoopRadius ?? 16
    readonly property real   scoopTension:          cfg?.scoopTension ?? 0.5522847498307936
    readonly property string scoopStyle:            cfg?.cornerStyle ?? "cubic"
    readonly property bool   cornerFillets:         cfg?.cornerFillets ?? true
    readonly property real   cornerSmoothing:       cfg?.cornerSmoothing ?? 0.7
    readonly property int    screenCornerRadius:    cfg?.screenCornerRadius ?? 16
    readonly property int    screenBorderWidth:     cfg?.screenBorderWidth ?? 2
    readonly property bool   screenFrameDocked:     cfg?.screenFrameDocked ?? true
    readonly property string screenCornerMode:      cfg?.screenCornerMode ?? "all"
    readonly property string cornerColorMode:       cfg?.cornerColorMode ?? "bar"
    readonly property string barStyle:              cfg?.barStyle ?? "glass"

    // color casino determining which glass shader liquefies your gpu today
    function getStyleColor(role: string, bs: string): color {
        switch (role) {
            case "barBg":
                if (bs === "regular") return alpha(surface_container_low, 0.95);
                if (bs === "pure-black") return "#000000";
                if (bs === "glass") return alpha(surface_container_lowest, 0.40);
                if (bs === "glass-frost") return alpha(surface_container_lowest, 0.55);
                if (bs === "cyber-neon") return alpha("#050508", 0.94);
                if (bs === "bento-floating") return alpha(surface_container_low, 0.88);
                if (bs === "translucent") return alpha(surface_container_low, 0.70);
                if (bs === "accent-glow") return alpha(surface_container_lowest, 0.90);
                if (bs === "monochrome") return surface_container_highest;
                return surface_container_low;
            case "barBorderColor":
                if (bs === "regular") return alpha(outline_variant, 0.40);
                if (bs === "pure-black") return "#1f1f1f";
                if (bs === "glass") return Qt.rgba(1, 1, 1, 0.16);
                if (bs === "glass-frost") return Qt.rgba(1, 1, 1, 0.24);
                if (bs === "cyber-neon") return primary;
                if (bs === "bento-floating") return alpha(outline_variant, 0.45);
                if (bs === "accent-glow") return primary;
                if (bs === "translucent") return alpha(outline_variant, 0.35);
                return alpha(outline_variant, 0.50);
            case "widgetBg":
                if (bs === "regular") return alpha(surface_container_high, 0.60);
                if (bs === "pure-black") return "#0a0a0a";
                if (bs === "glass") return alpha(surface_container_high, 0.28);
                if (bs === "glass-frost") return alpha(surface_container_high, 0.38);
                if (bs === "cyber-neon") return alpha(surface_container_lowest, 0.85);
                if (bs === "bento-floating") return alpha(surface_container_high, 0.50);
                if (bs === "translucent") return alpha(surface_container_high, 0.40);
                if (bs === "accent-glow") return alpha(primary_container, 0.65);
                if (bs === "monochrome") return surface_container_high;
                return surface_container_low;
            case "widgetHover":
                if (bs === "regular") return alpha(surface_container_highest, 0.85);
                if (bs === "pure-black") return "#181818";
                if (bs === "glass") return alpha(surface_container_highest, 0.48);
                if (bs === "glass-frost") return alpha(surface_container_highest, 0.60);
                if (bs === "cyber-neon") return alpha(primary_container, 0.50);
                if (bs === "bento-floating") return alpha(surface_container_highest, 0.70);
                if (bs === "translucent") return alpha(surface_container_highest, 0.65);
                if (bs === "accent-glow") return alpha(primary, 0.35);
                if (bs === "monochrome") return surface_container_highest;
                return surface_container_highest;
            case "widgetActive":
                if (bs === "regular") return alpha(primary_container, 0.90);
                if (bs === "pure-black") return "#242424";
                if (bs === "glass") return alpha(surface_container_highest, 0.65);
                if (bs === "glass-frost") return alpha(surface_container_highest, 0.80);
                if (bs === "cyber-neon") return alpha(primary, 0.45);
                if (bs === "bento-floating") return alpha(surface_container_highest, 0.90);
                if (bs === "translucent") return alpha(surface_container_highest, 0.85);
                if (bs === "accent-glow") return alpha(primary, 0.55);
                if (bs === "monochrome") return alpha(on_surface, 0.20);
                return surface_container_highest;
            case "widgetBorder":
                if (bs === "regular") return alpha(outline_variant, 0.40);
                if (bs === "pure-black") return "#1f1f1f";
                if (bs === "glass") return Qt.rgba(1, 1, 1, 0.12);
                if (bs === "glass-frost") return Qt.rgba(1, 1, 1, 0.20);
                if (bs === "cyber-neon") return alpha(primary, 0.60);
                if (bs === "bento-floating") return alpha(outline_variant, 0.40);
                if (bs === "translucent") return alpha(outline_variant, 0.35);
                if (bs === "accent-glow") return alpha(primary, 0.70);
                if (bs === "monochrome") return alpha(outline, 0.40);
                return alpha(outline_variant, 0.50);
            case "popupBg":
                if (bs === "regular") return alpha(surface_container_low, 0.96);
                if (bs === "pure-black") return "#000000";
                if (bs === "glass") return alpha(surface_container_lowest, 0.60);
                if (bs === "glass-frost") return alpha(surface_container_lowest, 0.75);
                if (bs === "cyber-neon") return alpha("#07070b", 0.96);
                if (bs === "bento-floating") return alpha(surface_container_low, 0.92);
                if (bs === "translucent") return alpha(surface_container_low, 0.80);
                if (bs === "accent-glow") return alpha(surface_container_lowest, 0.95);
                if (bs === "monochrome") return surface_container_low;
                return surface_container_low;
            case "popupBorderColor":
                if (bs === "regular") return alpha(outline_variant, 0.45);
                if (bs === "pure-black") return "#1f1f1f";
                if (bs === "glass") return Qt.rgba(1, 1, 1, 0.18);
                if (bs === "glass-frost") return Qt.rgba(1, 1, 1, 0.26);
                if (bs === "cyber-neon") return primary;
                if (bs === "bento-floating") return alpha(outline_variant, 0.50);
                if (bs === "accent-glow") return alpha(primary, 0.85);
                if (bs === "translucent") return alpha(outline_variant, 0.40);
                if (bs === "monochrome") return alpha(outline, 0.45);
                return alpha(outline_variant, 0.50);
            case "cardBg":
                if (bs === "regular") return alpha(surface_container_high, 0.75);
                if (bs === "pure-black") return "#080808";
                if (bs === "glass") return alpha(surface_container_high, 0.30);
                if (bs === "glass-frost") return alpha(surface_container_high, 0.45);
                if (bs === "cyber-neon") return alpha(surface_container_low, 0.75);
                if (bs === "bento-floating") return alpha(surface_container_high, 0.60);
                if (bs === "translucent") return alpha(surface_container_high, 0.50);
                if (bs === "accent-glow") return alpha(primary_container, 0.45);
                if (bs === "monochrome") return surface_container_high;
                return surface_container_high;
            case "cardBorder":
                if (bs === "regular") return alpha(outline_variant, 0.35);
                if (bs === "pure-black") return "#1c1c1c";
                if (bs === "glass") return Qt.rgba(1, 1, 1, 0.12);
                if (bs === "glass-frost") return Qt.rgba(1, 1, 1, 0.20);
                if (bs === "cyber-neon") return alpha(primary, 0.50);
                if (bs === "bento-floating") return alpha(outline_variant, 0.35);
                if (bs === "translucent") return alpha(outline_variant, 0.30);
                if (bs === "accent-glow") return alpha(primary, 0.60);
                if (bs === "monochrome") return alpha(outline, 0.35);
                return alpha(outline_variant, 0.40);
            case "pillBg":
                if (bs === "regular") return alpha(surface_container_high, 0.65);
                if (bs === "pure-black") return "#0a0a0a";
                if (bs === "glass") return alpha(surface_container_high, 0.25);
                if (bs === "glass-frost") return alpha(surface_container_high, 0.35);
                if (bs === "cyber-neon") return alpha(surface_container_low, 0.60);
                if (bs === "bento-floating") return alpha(surface_container_high, 0.50);
                if (bs === "translucent") return alpha(surface_container_high, 0.45);
                if (bs === "accent-glow") return alpha(primary, 0.22);
                if (bs === "monochrome") return surface_container;
                return surface_container_high;
            case "pillHover":
                if (bs === "regular") return alpha(surface_container_highest, 0.85);
                if (bs === "pure-black") return "#181818";
                if (bs === "glass") return alpha(surface_container_highest, 0.45);
                if (bs === "glass-frost") return alpha(surface_container_highest, 0.55);
                if (bs === "cyber-neon") return alpha(primary_container, 0.40);
                if (bs === "bento-floating") return alpha(surface_container_highest, 0.65);
                if (bs === "translucent") return alpha(surface_container_highest, 0.70);
                if (bs === "accent-glow") return alpha(primary, 0.40);
                if (bs === "monochrome") return surface_container_highest;
                return surface_container_highest;
            case "pillBorder":
                if (bs === "regular") return alpha(outline_variant, 0.35);
                if (bs === "pure-black") return "#222222";
                if (bs === "glass") return Qt.rgba(1, 1, 1, 0.14);
                if (bs === "glass-frost") return Qt.rgba(1, 1, 1, 0.22);
                if (bs === "cyber-neon") return alpha(primary, 0.75);
                if (bs === "bento-floating") return alpha(outline_variant, 0.30);
                if (bs === "translucent") return alpha(outline_variant, 0.25);
                if (bs === "accent-glow") return alpha(primary, 0.85);
                if (bs === "monochrome") return alpha(outline, 0.35);
                return Qt.rgba(0, 0, 0, 0);
            default:
                return surface_container_low;
        }
    }

    readonly property color barBg:            alpha(getStyleColor("barBg", barStyle), barOpacity)
    readonly property color barBorderColor:   getStyleColor("barBorderColor", barStyle)
    readonly property color cornerFill: {
        let cm = Settings?.cornerColorMode ?? "bar";
        if (cm === "accent") return primary;
        if (cm === "pure-black") return "#000000";
        if (cm === "theme") return surface_container_high;
        return barBg;
    }
    readonly property color widgetBg:         getStyleColor("widgetBg", barStyle)
    readonly property color widgetHover:      getStyleColor("widgetHover", barStyle)
    readonly property color widgetActive:     getStyleColor("widgetActive", barStyle)
    readonly property color widgetBorder:     getStyleColor("widgetBorder", barStyle)
    readonly property color popupBg:          alpha(getStyleColor("popupBg", barStyle), popupOpacity)
    readonly property color popupBorderColor: getStyleColor("popupBorderColor", barStyle)
    readonly property color cardBg:           getStyleColor("cardBg", barStyle)
    readonly property color cardBorder:       getStyleColor("cardBorder", barStyle)
    readonly property color pillBg:           getStyleColor("pillBg", barStyle)
    readonly property color pillHover:        getStyleColor("pillHover", barStyle)
    readonly property color pillBorder:       getStyleColor("pillBorder", barStyle)

    // easing curves and physics to make buttons feel dangerously squishy
    readonly property color  glassHighlight:        Qt.rgba(1, 1, 1, 0.16)
    readonly property color  glassBorder:           Qt.rgba(1, 1, 1, 0.12)
    readonly property color  glassGlow:             alpha(primary, 0.25)
    readonly property color  cardGlow:              alpha(primary, 0.15)
    readonly property int    popupBorderWidth:      cfg?.popupBorderWidth ?? 1
    readonly property bool   scoopBorderEnabled:    cfg?.scoopBorderEnabled ?? true
    readonly property int    scoopBorderWidth:      cfg?.scoopBorderWidth ?? (screenBorderWidth > 0 ? screenBorderWidth : 2)
    readonly property color  scoopBorderColor: {
        let sc = cfg?.scoopBorderColor ?? "auto";
        if (sc !== "auto" && sc !== "") return sc;
        if (cornerColorMode === "accent") return primary;
        return barBorderColor;
    }

    // shared default popup dimensions for widgets that still use fixed-size panels
    readonly property int    popupWidth:             460
    readonly property int    popupHeight:            580
    // popup sizing is kept here; individual widgets derive their actual size from content
    readonly property int    popupMinWidth:         320
    readonly property int    popupMaxWidth:         620
    readonly property int    popupMinHeight:        180
    readonly property int    popupMaxHeight:        760
    readonly property int    popupWorkspaceMaxHeight: 460
    readonly property int    popupPadding:          16
    readonly property int    popupSpacing:          10
    readonly property int    popupDividerHeight:    1
    readonly property int    popupCardHeight:       44
    readonly property int    popupCardMinWidth:      190
    readonly property int    popupCardGap:           6
    readonly property int    popupCardPadding:       8
    readonly property int    popupCardIconSize:      26
    readonly property int    popupActionHeight:      32
    readonly property int    popupColumns:            2

    // workspace widget geometry
    readonly property int    workspaceDotSize:       8
    readonly property int    workspaceIndicatorSize: 8
    readonly property int    workspaceIndicatorMin:  8
    readonly property int    workspaceSpacing:       widgetSpacing
    readonly property int    workspaceActiveSize:    20
    readonly property int    workspaceWidgetPadding: Math.max(widgetPaddingH, widgetPaddingV)

    readonly property int    thumbSize:             180

    readonly property real   animSpeedMult: {
        let sp = cfg?.animSpeed ?? "normal";
        if (sp === "instant") return 0.01;
        if (sp === "snappy" || sp === "superSnappy") return 0.7;
        if (sp === "hyper") return 0.4;
        if (sp === "chill") return 1.6;
        if (sp === "hyprland") return 0.85;
        return 1.0;
    }
    readonly property bool   isVertical:            cfg?.barPosition === "left" || cfg?.barPosition === "right"
    readonly property string animCurve:             cfg?.animCurve ?? "cubic"
    readonly property string animEasingType:        cfg?.animEasingType ?? "out"
    readonly property int    animDurationFast:      cfg?.animDurationFast ?? 120
    readonly property int    animDurationNormal:    cfg?.animDurationNormal ?? 200
    readonly property int    animDurationSlow:      cfg?.animDurationSlow ?? 350
    readonly property int    animFast:              Math.round(animDurationFast * animSpeedMult)
    readonly property int    animNormal:            Math.round(animDurationNormal * animSpeedMult)
    readonly property int    animDefault:           animNormal
    readonly property int    animSlow:              Math.round(animDurationSlow * animSpeedMult)
    readonly property int    expressiveFast:        Math.round(180 * animSpeedMult)
    readonly property int    expressiveDefault:     Math.round(320 * animSpeedMult)
    readonly property int    expressiveSlow:        Math.round(480 * animSpeedMult)
    readonly property int    workspaceTrailDuration:Math.round(260 * animSpeedMult)
    readonly property bool   workspaceActiveTrail:  cfg?.workspaceActiveTrail ?? true

    // Cubic bezier control points [cx1, cy1, cx2, cy2, endx, endy] for Qt Quick Easing.BezierSpline
    readonly property var    hyprlandBezier:            [0.05, 0.9, 0.1, 1.05, 1.0, 1.0]
    readonly property var    hyprlandExitBezier:        [0.3, 0.0, 0.8, 0.15, 1.0, 1.0]
    readonly property var    smoothBezier:              [0.16, 1.0, 0.3, 1.0, 1.0, 1.0]
    readonly property var    snappyBezier:              [0.2, 0.0, 0.0, 1.0, 1.0, 1.0]
    readonly property var    expressiveBezier:          [0.1, 1.15, 0.2, 1.0, 1.0, 1.0]
    readonly property var    standardBezier:            [0.25, 0.1, 0.25, 1.0, 1.0, 1.0]
    readonly property var    motionExpressiveFast:      [0.38, 1.25, 0.25, 1.0, 1.0, 1.0]
    readonly property var    motionExpressiveDefault:   [0.34, 1.45, 0.22, 1.0, 1.0, 1.0]
    readonly property var    motionExpressiveSlow:      [0.25, 1.35, 0.15, 1.0, 1.0, 1.0]
    readonly property var    motionEmphasized:          [0.20, 0.0, 0.0, 1.0, 1.0, 1.0]
    readonly property var    motionEmphasizedDecel:     [0.05, 0.7, 0.1, 1.0, 1.0, 1.0]
    readonly property var    motionEmphasizedAccel:     [0.30, 0.0, 0.8, 0.15, 1.0, 1.0]

    function getBezierPoints(curve: var): var {
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
        if (c === "expressive-fast") return motionExpressiveFast;
        if (c === "expressive-default") return motionExpressiveDefault;
        if (c === "expressive-slow") return motionExpressiveSlow;
        if (c === "emphasized") return motionEmphasized;
        if (c === "emphasized-decel") return motionEmphasizedDecel;
        if (c === "emphasized-accel") return motionEmphasizedAccel;
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

    readonly property var    animBezierPoints:      getBezierPoints(animCurve)
    readonly property real   animOvershoot:         (animCurve === "hyprland" || cfg?.animSpeed === "hyprland") ? 1.05 : ((animCurve === "expressive") ? 1.15 : 1.70158)

    function getEasing(curve: string, type: string): int {
        let c = (curve ?? "cubic").toLowerCase();
        let t = (type ?? "out").toLowerCase();
        if (c === "linear") return Easing.Linear;
        if (c === "bezier" || c === "spline" || c === "bezierspline") return Easing.BezierSpline;
        if (c === "quad" || c === "snappy") {
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
        if (c === "back" || c === "expressive") {
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

    readonly property int    animEasing:            getEasing(animCurve, animEasingType)
    readonly property int    animExpressiveEasing:  animCurve === "back" ? getEasing("back", animEasingType) : Easing.OutBack
    readonly property int    animEasingEntrance:    (animCurve === "expressive" || animCurve === "hyprland" || animCurve === "back" || cfg?.animSpeed === "hyprland") ? Easing.OutBack : (animCurve === "snappy" ? Easing.OutQuad : Easing.OutCubic)
    readonly property int    animEasingExit:        (animCurve === "snappy") ? Easing.InQuad : Easing.InCubic
    readonly property int    animColorEasing:       Easing.OutQuad

    // icon summoner circle: pulling glyphs out of ~/.local/share by their ankles
    readonly property string userFontDir:           (Quickshell.env("XDG_DATA_HOME") || ((Quickshell.env("HOME") || "") + "/.local/share")) + "/fonts/"

    FontLoader {
        id: loaderMatRounded
        source: "file://" + root.userFontDir + "MaterialSymbolsRounded.ttf"
    }
    FontLoader {
        id: loaderMatOutlined
        source: "file://" + root.userFontDir + "MaterialSymbolsOutlined.ttf"
    }
    FontLoader {
        id: loaderMatSharp
        source: "file://" + root.userFontDir + "MaterialSymbolsSharp.ttf"
    }
    FontLoader {
        id: loaderFaSolid
        source: "file://" + root.userFontDir + "FontAwesome6Free-Solid.otf"
    }
    FontLoader {
        id: loaderSegoe
        source: "file://" + root.userFontDir + "SegoeIcons.ttf"
    }

    readonly property string iconSet:               cfg?.iconSet ?? "material"
    readonly property string fontMaterialRounded:   (loaderMatRounded.status === FontLoader.Ready && loaderMatRounded.name) ? loaderMatRounded.name : "Material Symbols Rounded"
    readonly property string fontMaterialOutlined:  (loaderMatOutlined.status === FontLoader.Ready && loaderMatOutlined.name) ? loaderMatOutlined.name : "Material Symbols Outlined"
    readonly property string fontMaterialSharp:     (loaderMatSharp.status === FontLoader.Ready && loaderMatSharp.name) ? loaderMatSharp.name : "Material Symbols Sharp"
    readonly property string fontSegoe:             (loaderSegoe.status === FontLoader.Ready && loaderSegoe.name) ? loaderSegoe.name : (cfg?.fontWindows ?? "Segoe Fluent Icons")
    // Font Awesome 6 Free uses the family name "Font Awesome 6 Free".
    // "Solid" is the style/weight, not a second family name.
    readonly property string fontAwesome:           (loaderFaSolid.status === FontLoader.Ready && loaderFaSolid.name)
        ? loaderFaSolid.name
        : (cfg?.fontAwesome ?? "Font Awesome 6 Free")

    // dodging qt.fontfamilies() so the main thread doesnt flatline
    readonly property string fontIcon: {
        if (iconSet === "kaomoji" || iconSet === "text") return fontFamily;
        if (iconSet === "nerd") return cfg?.fontNerd ?? "JetBrainsMono Nerd Font";
        if (iconSet === "windows") return fontSegoe;
        if (iconSet === "awesome") return fontAwesome;

        if (iconSet === "material-outlined" || iconSet === "outlined") return fontMaterialOutlined;
        if (iconSet === "material-sharp" || iconSet === "sharp") return fontMaterialSharp;
        if (iconSet === "material-rounded" || iconSet === "rounded") return fontMaterialRounded;
        return cfg?.fontMaterial ?? fontMaterialRounded;
    }

    readonly property var kaomojiMap: Object.freeze({
        "arch": "(*_*)v", "nix": "(*_*)v", "nixos": "(*_*)v", "distro": "(*_*)v", "appLauncher": "(^_^)v", "workspaces": "[::]", "search": "(⚆_⚆)", "close": "(x)",
        "check": "(✓)", "checkCircle": "(✓)", "settings": "(*_*)", "gear": "(*_*)", "save": "(⤓)",
        "refresh": "(↺)", "trash": "(⌫)", "clipboard": "(≡)", "tray": "[..]", "grid": "[#]",
        "note": "(✎)", "edit": "(✎)", "coffee": "(旦)", "clock": "(◷)", "cpu": "[cpu]",
        "mem": "[ram]", "thermo": "[°c]", "eye": "(•‿•)", "eyeOff": "(-_-)", "heart": "(♡)",
        "download": "(↓)", "folder": "[dir]", "globe": "(⊕)", "camera": "[o]", "crop": "[#]",
        "screenshot": "[o]", "volMute": "(-_-)", "volLow": "(・ω・)", "volMid": "(ᵔᴥᵔ)", "volHigh": "(≧◡≦)",
        "mic": "(¶)", "micMute": "(x_x)", "palette": "(※)", "headphones": "(d-_-b)", "equalizer": "|||",
        "batFull": "(◕‿◕)", "batHalf": "(・_・)", "batQuarter": "(>_<)", "batEmpty": "(×_×)", "batCharge": "(↯^↯)",
        "batCharging": "(↯^↯)", "sun": "(☼)", "moon": "(☾)", "brightness": "(☼)", "music": "(♫)",
        "play": "(▶)", "pause": "(❚❚)", "next": "(>>)", "prev": "(<<)", "shuffle": "(~)",
        "repeat": "(↻)", "repeatOne": "(1)", "wallhaven": "[img]", "wallpaper": "[img]", "bell": "(⍾)",
        "bellOutline": "(⍾)", "bellOff": "(⍉)", "ethernet": "[eth]", "wifi": "(•̀ᴗ•́)و", "wifiHigh": "(•̀ᴗ•́)و",
        "wifiMed": "(・_・)", "wifiLow": "( ;¬_¬)", "wifiOff": "(×_×)", "bluetooth": "(~)",
        "bluetoothConnected": "(•̀ᴗ•́)و", "bluetoothOff": "(×_×)", "power": "(⏻)", "shutdown": "(⏻)",
        "lock": "(⚿)", "logout": "(bye)", "reboot": "(↺)", "suspend": "(zzz)", "hibernate": "(zzz)",
        "chevronRight": ">", "chevronLeft": "<", "chevronDown": "v", "chevronUp": "^", "flame": "(♨)",
        "sparkles": "(✦)", "radio": "[rad]", "sliders": "[=]", "terminal": "[>_]", "calendar": "[cal]",
        "history": "(↺)", "copy": "[cp]", "externalLink": "(->)", "signal": "(ıllι)", "filter": "[/]",
        "user": "(•)", "shield": "[#]", "expand": "[+]", "collapse": "[-]"
    })

    readonly property var textMap: Object.freeze({
        "arch": "nix", "nix": "nix", "nixos": "nix", "distro": "nix", "appLauncher": "apps", "workspaces": "ws", "search": "find", "close": "x",
        "check": "ok", "checkCircle": "ok", "settings": "cfg", "gear": "cfg", "save": "save",
        "refresh": "reload", "trash": "del", "clipboard": "clip", "tray": "tray", "grid": "grid",
        "note": "note", "edit": "edit", "coffee": "cafe", "clock": "time", "cpu": "cpu",
        "mem": "mem", "thermo": "temp", "eye": "show", "eyeOff": "hide", "heart": "fav",
        "download": "down", "folder": "dir", "globe": "web", "camera": "cam", "crop": "crop",
        "screenshot": "shot", "volMute": "mute", "volLow": "vol-", "volMid": "vol", "volHigh": "vol+",
        "mic": "mic", "micMute": "no-mic", "palette": "theme", "headphones": "audio", "equalizer": "eq",
        "batFull": "100%", "batHalf": "50%", "batQuarter": "25%", "batEmpty": "0%", "batCharge": "chg",
        "batCharging": "chg", "sun": "day", "moon": "night", "brightness": "bright", "music": "music",
        "play": "play", "pause": "pause", "next": "next", "prev": "prev", "shuffle": "shuf",
        "repeat": "loop", "repeatOne": "loop1", "wallhaven": "walls", "wallpaper": "wall", "bell": "bell",
        "bellOutline": "bell", "bellOff": "quiet", "ethernet": "eth", "wifi": "wifi", "wifiHigh": "high",
        "wifiMed": "med", "wifiLow": "low", "wifiOff": "offline", "bluetooth": "bt",
        "bluetoothConnected": "bt-on", "bluetoothOff": "bt-off", "power": "power", "shutdown": "power",
        "lock": "lock", "logout": "logout", "reboot": "reboot", "suspend": "sleep", "hibernate": "hib",
        "chevronRight": ">", "chevronLeft": "<", "chevronDown": "v", "chevronUp": "^", "flame": "chaos",
        "sparkles": "magic", "radio": "radio", "sliders": "opts", "terminal": "term", "calendar": "cal",
        "history": "hist", "copy": "copy", "externalLink": "open", "signal": "sig", "filter": "filter",
        "user": "user", "shield": "safe", "expand": "max", "collapse": "min"
    })

    // semantic Font Awesome 6 Free glyph table.
    // Keeping this keyed by meaning prevents stale per-call codepoints from
    // leaking into the wrong font family.
    readonly property var fontAwesomeMap: Object.freeze({
        "nixos": "\uF17C",
        "nix": "\uF17C",
        "arch": "\uF17C",
        "appLauncher": "\uF009",
        "workspaces": "\uF108",
        "search": "\uF002",
        "close": "\uF00D",
        "check": "\uF00C",
        "checkCircle": "\uF058",
        "settings": "\uF013",
        "save": "\uF0C7",
        "refresh": "\uF021",
        "trash": "\uF2ED",
        "clipboard": "\uF328",
        "tray": "\uF01C",
        "grid": "\uF00A",
        "note": "\uF249",
        "edit": "\uF044",
        "coffee": "\uF0F4",
        "clock": "\uF017",
        "cpu": "\uF2DB",
        "mem": "\uF538",
        "thermo": "\uF2C7",
        "eye": "\uF06E",
        "eyeOff": "\uF070",
        "heart": "\uF004",
        "download": "\uF019",
        "folder": "\uF07B",
        "globe": "\uF0AC",
        "camera": "\uF030",
        "crop": "\uF125",
        "screenshot": "\uF03E",
        "volMute": "\uF026",
        "volLow": "\uF027",
        "volMid": "\uF027",
        "volHigh": "\uF028",
        "mic": "\uF130",
        "micMute": "\uF131",
        "palette": "\uF53F",
        "headphones": "\uF025",
        "equalizer": "\uF1DE",
        "batFull": "\uF240",
        "batHalf": "\uF242",
        "batQuarter": "\uF243",
        "batEmpty": "\uF244",
        "batCharge": "\uF0E7",
        "batCharging": "\uF0E7",
        "sun": "\uF185",
        "moon": "\uF186",
        "brightness": "\uF185",
        "music": "\uF001",
        "play": "\uF04B",
        "pause": "\uF04C",
        "next": "\uF051",
        "prev": "\uF048",
        "shuffle": "\uF074",
        "repeat": "\uF363",
        "repeatOne": "\uF365",
        "wallhaven": "\uF03E",
        "wallpaper": "\uF03E",
        "bell": "\uF0F3",
        "bellOutline": "\uF0F3",
        "bellOff": "\uF1F6",
        "ethernet": "\uF796",
        "wifi": "\uF1EB",
        "wifiHigh": "\uF1EB",
        "wifiMed": "\uF6AB",
        "wifiLow": "\uF6AA",
        "wifiOff": "\uF6AC",
        "bluetooth": "\uF293",
        "bluetoothConnected": "\uF294",
        "bluetoothOff": "\uF293",
        "power": "\uF011",
        "shutdown": "\uF011",
        "lock": "\uF023",
        "logout": "\uF2F5",
        "reboot": "\uF021",
        "suspend": "\uF186",
        "hibernate": "\uF236",
        "chevronRight": "\uF054",
        "chevronLeft": "\uF053",
        "chevronDown": "\uF078",
        "chevronUp": "\uF077",
        "flame": "\uF06D",
        "sparkles": "\uE2CA",
        "radio": "\uF8D7",
        "sliders": "\uF1DE",
        "terminal": "\uF120",
        "calendar": "\uF133",
        "history": "\uF1DA",
        "copy": "\uF0C5",
        "externalLink": "\uF35D",
        "signal": "\uF012",
        "filter": "\uF0B0",
        "user": "\uF007",
        "shield": "\uF132",
        "expand": "\uF065",
        "collapse": "\uF066",
        "keyboard": "\uF11C"
    })

    // Nerd Fonts v3.5 distro logo codepoints: Arch F303, NixOS F313, Tux F31A.
    readonly property var nerdMap: Object.freeze({
        "arch": "\uF303", "nix": "\uF313", "nixos": "\uF313", "distro": "\uF313", "appLauncher": "󰀻", "workspaces": "󱂬", "search": "", "close": "",
        "check": "", "checkCircle": "", "settings": "", "gear": "", "save": "",
        "refresh": "", "trash": "", "clipboard": "󰅌", "tray": "󱊖", "grid": "󰕰",
        "note": "󰏫", "edit": "󰏫", "coffee": "󰛊", "clock": "󰥔", "cpu": "󰍛",
        "mem": "󰘚", "thermo": "󰔏", "eye": "󰈈", "eyeOff": "󰈉", "heart": "󰋑",
        "download": "󰇚", "folder": "󰉋", "globe": "󰖟", "camera": "󰄀", "crop": "󰩨",
        "screenshot": "󰹑", "volMute": "󰝟", "volLow": "󰕿", "volMid": "󰖀", "volHigh": "󰕾",
        "mic": "󰍬", "micMute": "󰍭", "palette": "󰏘", "headphones": "󰋋", "equalizer": "󰓃",
        "batFull": "󰁹", "batHalf": "󰁿", "batQuarter": "󰁼", "batEmpty": "󰂃", "batCharge": "󰢝",
        "batCharging": "󰢝", "sun": "󰖙", "moon": "󰖔", "brightness": "󰃠", "music": "󰝚",
        "play": "󰐊", "pause": "󰏤", "next": "󰒭", "prev": "󰒮", "shuffle": "󰒝",
        "repeat": "󰑖", "repeatOne": "󰑘", "wallhaven": "󰋩", "wallpaper": "󰋩", "bell": "󰂚",
        "bellOutline": "󰂚", "bellOff": "󰂛", "ethernet": "󰈀", "wifi": "󰤨", "wifiHigh": "󰤨",
        "wifiMed": "󰤥", "wifiLow": "󰤟", "wifiOff": "󰤮", "bluetooth": "󰂯",
        "bluetoothConnected": "󰂱", "bluetoothOff": "󰂲", "power": "󰐥", "shutdown": "󰐥",
        "lock": "󰌾", "logout": "󰍃", "reboot": "󰑓", "suspend": "󰤄", "hibernate": "󰒲",
        "chevronRight": "", "chevronLeft": "", "chevronDown": "", "chevronUp": "", "flame": "󰈸",
        "sparkles": "󰛓", "radio": "󰐹", "sliders": "󰒓", "terminal": "󰆍", "calendar": "󰃭",
        "history": "󰋚", "copy": "󰆏", "externalLink": "󰌹", "signal": "󰖩", "filter": "󰈲",
        "user": "󰀉", "shield": "󰞌", "expand": "󰊓", "collapse": "󰊔"
    })

    function getIcon(mat: string, win: string, fa: string, key: var, kao: var, txt: var): string {
        if (iconSet === "kaomoji") {
            if (typeof kao === "string" && kao !== "" && kao !== "undefined") return kao;
            if (key && kaomojiMap[key]) return kaomojiMap[key];
            return mat;
        }
        if (iconSet === "text") {
            if (typeof txt === "string" && txt !== "" && txt !== "undefined") return txt;
            if (key && textMap[key]) return textMap[key];
            return mat;
        }
        if (iconSet === "nerd") {
            if (key && nerdMap[key]) return nerdMap[key];
            return "󰋼";
        }
        if (iconSet === "windows") return win;
        if (iconSet === "awesome") {
            if (key && fontAwesomeMap[key]) return fontAwesomeMap[key];
            if (typeof fa === "string" && fa !== "") return fa;
            return "\uF128";
        }
        return mat;
    }

    function getBatteryIcon(pct: int, isCharging: bool, isSaver: bool, isVertical: bool): string {
        let p = (pct === undefined || pct === null || isNaN(pct)) ? -1 : Math.max(0, Math.min(100, Math.round(pct)));
        let lvl = p < 0 ? -1 : Math.min(10, Math.floor(p / 10));

        if (iconSet === "kaomoji") {
            if (lvl < 0) return "(?)";
            if (isCharging) return "(↯^↯)";
            if (lvl >= 9) return "(◕‿◕)";
            if (lvl >= 5) return "(・_・)";
            if (lvl >= 2) return "(>_<)";
            return "(×_×)";
        }

        if (iconSet === "text") {
            if (isCharging) return "chg";
            if (lvl < 0) return "bat";
            return p + "%";
        }

        if (iconSet === "nerd") {
            if (lvl < 0) return "󰁹";
            if (isCharging) {
                const nerdCharging = ["󰢟", "󰢜", "󰂆", "󰂇", "󰂈", "󰢝", "󰂉", "󰢞", "󰂊", "󰂋", "󰂅"];
                return nerdCharging[lvl];
            }
            const nerdDischarging = ["󰂃", "󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"];
            return nerdDischarging[lvl];
        }

        if (iconSet === "windows") {
            if (lvl < 0) return isVertical ? "\uF608" : "\uE996";
            if (isVertical) {
                if (isCharging) {
                    const chargingV = ["\uF5FD", "\uF5FE", "\uF5FF", "\uF600", "\uF601", "\uF602", "\uF603", "\uF604", "\uF605", "\uF606", "\uF607"];
                    return chargingV[lvl];
                }
                const dischargingV = ["\uF5F2", "\uF5F3", "\uF5F4", "\uF5F5", "\uF5F6", "\uF5F7", "\uF5F8", "\uF5F9", "\uF5FA", "\uF5FB", "\uF5FC"];
                return dischargingV[lvl];
            } else {
                if (isCharging) {
                    const chargingH = ["\uE85A", "\uE85B", "\uE85C", "\uE85D", "\uE85E", "\uE85F", "\uE860", "\uE861", "\uE862", "\uE83E", "\uEA93"];
                    return chargingH[lvl];
                }
                if (isSaver) {
                    const saverH = ["\uE863", "\uE864", "\uE865", "\uE866", "\uE867", "\uE868", "\uE869", "\uE86A", "\uE86B", "\uEA94", "\uEA95"];
                    return saverH[lvl];
                }
                const dischargingH = ["\uE850", "\uE851", "\uE852", "\uE853", "\uE854", "\uE855", "\uE856", "\uE857", "\uE858", "\uE859", "\uE83F"];
                return dischargingH[lvl];
            }
        }

        if (iconSet === "awesome") {
            if (lvl < 0) return fontAwesomeMap.batEmpty;
            if (isCharging) return fontAwesomeMap.batCharge;
            if (lvl >= 9) return fontAwesomeMap.batFull;
            if (lvl >= 7) return "\uF241";
            if (lvl >= 5) return fontAwesomeMap.batHalf;
            if (lvl >= 2) return fontAwesomeMap.batQuarter;
            return "";
        }

        if (lvl < 0) return "\uE1A6";
        if (isCharging) {
            const matCharging = ["\uF0A2", "\uF0A2", "\uF0A3", "\uF0A3", "\uF0A4", "\uF0A4", "\uF0A5", "\uF0A6", "\uF0A6", "\uF0A7", "\uE1A3"];
            return matCharging[lvl];
        }
        const matDischarging = ["\uEBDC", "\uF09C", "\uF09D", "\uF09D", "\uF09E", "\uF09E", "\uF09F", "\uF0A0", "\uF0A0", "\uF0A1", "\uE1A5"];
        return matDischarging[lvl];
    }

    function getVolumeIcon(volRatio: real, isMuted: bool): string {
        if (isMuted || volRatio === undefined || isNaN(volRatio) || volRatio <= 0.001) {
            return (iconSet === "kaomoji") ? "(-_-)" : (iconSet === "text") ? "mute" : (iconSet === "nerd") ? "󰝟" : iconVolMute;
        }
        let pct = Math.round(volRatio * 100);
        if (iconSet === "kaomoji") {
            if (pct <= 33) return "(・ω・)";
            if (pct <= 66) return "(ᵔᴥᵔ)";
            return "(≧◡≦)";
        }
        if (iconSet === "text") return pct + "%";
        if (iconSet === "nerd") {
            if (pct <= 33) return "󰕿";
            if (pct <= 66) return "󰖀";
            return "󰕾";
        }
        if (iconSet === "windows") {
            if (pct <= 33) return "\uE993";
            if (pct <= 66) return "\uE994";
            return "\uE995";
        }
        if (iconSet === "awesome") {
            if (pct <= 33) return "";
            if (pct <= 66) return "";
            return "";
        }
        if (pct <= 33) return "\uE04E";
        if (pct <= 66) return "\uE04D";
        return "\uE050";
    }

    function getWifiIcon(signalPct: int, isConnected: bool, isEthernet: bool): string {
        if (isEthernet) return (iconSet === "kaomoji") ? "[eth]" : (iconSet === "text") ? "eth" : (iconSet === "nerd") ? "󰈀" : iconEthernet;
        if (!isConnected) return (iconSet === "kaomoji") ? "(×_×)" : (iconSet === "text") ? "off" : (iconSet === "nerd") ? "󰤮" : iconWifiOff;
        let sig = (signalPct === undefined || signalPct === null || isNaN(signalPct)) ? 0 : signalPct;
        if (iconSet === "kaomoji") {
            if (sig < 35) return "( ;¬_¬)";
            if (sig < 70) return "(・_・)";
            return "(•̀ᴗ•́)و";
        }
        if (iconSet === "text") {
            if (sig < 35) return "low";
            if (sig < 70) return "med";
            return "high";
        }
        if (iconSet === "nerd") {
            if (sig < 35) return "󰤟";
            if (sig < 70) return "󰤥";
            return "󰤨";
        }
        if (iconSet === "windows") {
            if (sig < 25) return "\uE871";
            if (sig < 50) return "\uE872";
            if (sig < 75) return "\uE873";
            return "\uE874";
        }
        if (iconSet === "awesome") {
            if (sig < 35) return fontAwesomeMap.wifiLow;
            if (sig < 70) return fontAwesomeMap.wifiMed;
            return fontAwesomeMap.wifiHigh;
        }
        if (sig < 35) return "\uE4CA";
        if (sig < 70) return "\uE4D9";
        return "\uE63E";
    }

    // semantic icon mappings across Material, Nerd Font, Segoe Fluent, and Font Awesome
    readonly property string iconDistro:            getIcon("\uE30A", "\uE71D", "\uF17C", "nixos")
    readonly property string iconNix:               getIcon("\uE30A", "\uE71D", "\uF17C", "nix")
    readonly property string iconArch:              getIcon("\uE30A", "\uE71D", "\uF17C", "arch")
    readonly property string iconAppLauncher:       getIcon("\uE5C3", "\uE71D", "", "appLauncher")
    readonly property string iconWorkspaces:        getIcon("\uE1A0", "\uE7C4", "", "workspaces")
    readonly property string iconSearch:            getIcon("\uE8B6", "\uE721", "", "search")
    readonly property string iconClose:             getIcon("\uE5CD", "\uE711", "", "close")
    readonly property string iconCheck:             getIcon("\uE668", "\uE73E", "", "check")
    readonly property string iconCheckCircle:       getIcon("\uF0BE", "\uF13E", "", "checkCircle")
    readonly property string iconSettings:          getIcon("\uE8B8", "\uE713", "", "settings")
    readonly property string iconGear:              iconSettings
    readonly property string iconSave:              getIcon("\uE161", "\uE74E", "", "save")
    readonly property string iconRefresh:           getIcon("\uE5D5", "\uE72C", "", "refresh")
    readonly property string iconTrash:             getIcon("\uE92E", "\uE74D", "", "trash")
    readonly property string iconClipboard:         getIcon("\uE14F", "\uF0E3", "", "clipboard")
    readonly property string iconTray:              getIcon("\uE156", "\uE971", "\uF01C", "tray")
    readonly property string iconGrid:              getIcon("\uE9B0", "\uF0E2", "", "grid")
    readonly property string iconNote:              getIcon("\uE66D", "\uE70F", "\uF249", "note")
    readonly property string iconEdit:              iconNote
    readonly property string iconCoffee:            getIcon("\uEFEF", "\uEC32", "", "coffee")
    readonly property string iconClock:             getIcon("\uEFD6", "\uE823", "", "clock")
    readonly property string iconCpu:               getIcon("\uE322", "\uEEA1", "", "cpu")
    readonly property string iconMem:               getIcon("\uF7A3", "\uEEA0", "", "mem")
    readonly property string iconThermo:            getIcon("\uE846", "\uE9CA", "\uF2C7", "thermo")
    readonly property string iconEye:               getIcon("\uE8F4", "\uE7B3", "", "eye")
    readonly property string iconEyeOff:            getIcon("\uE8F5", "\uED1A", "", "eyeOff")
    readonly property string iconHeart:             getIcon("\uE87E", "\uEB51", "", "heart")
    readonly property string iconDownload:          getIcon("\uF090", "\uE896", "", "download")
    readonly property string iconFolder:            getIcon("\uE2C7", "\uE838", "", "folder")
    readonly property string iconGlobe:             getIcon("\uE64C", "\uE774", "\uF0AC", "globe")
    readonly property string iconCamera:            getIcon("\uE3AF", "\uE722", "", "camera")
    readonly property string iconCrop:              getIcon("\uE3BE", "\uE7A8", "", "crop")
    readonly property string iconScreenshot:        getIcon("\uF056", "\uE722", "\uF03E", "screenshot")

    readonly property string iconVolMute:           getIcon("\uE04F", "\uE74F", "", "volMute")
    readonly property string iconVolLow:            getIcon("\uE04E", "\uE993", "", "volLow")
    readonly property string iconVolMid:            getIcon("\uE04D", "\uE994", "", "volMid")
    readonly property string iconVolHigh:           getIcon("\uE050", "\uE995", "", "volHigh")
    readonly property string iconMic:               getIcon("\uE31D", "\uE720", "", "mic")
    readonly property string iconMicMute:           getIcon("\uE02B", "\uF781", "", "micMute")
    readonly property string iconPalette:           getIcon("\uE40A", "\uE790", "", "palette")
    readonly property string iconHeadphones:        getIcon("\uF01F", "\uE7F6", "", "headphones")
    readonly property string iconEqualizer:         getIcon("\uE01D", "\uE9E9", "", "equalizer")

    readonly property string iconBatFull:           getIcon("\uE1A5", "\uE83F", "", "batFull")
    readonly property string iconBatHalf:           getIcon("\uF09E", "\uE855", "", "batHalf")
    readonly property string iconBatQuarter:        getIcon("\uF09D", "\uE852", "", "batQuarter")
    readonly property string iconBatEmpty:          getIcon("\uEBDC", "\uE850", "", "batEmpty")
    readonly property string iconBatCharge:         getIcon("\uE1A3", "\uE83E", "", "batCharge")
    readonly property string iconBatCharging:       iconBatCharge

    readonly property string iconSun:               getIcon("\uE518", "\uE706", "", "sun")
    readonly property string iconMoon:              getIcon("\uE51C", "\uE708", "", "moon")
    readonly property string iconBrightness:        iconSun

    readonly property string iconMusic:             getIcon("\uE405", "\uE8D6", "", "music")
    readonly property string iconPlay:              getIcon("\uE037", "\uE768", "", "play")
    readonly property string iconPause:             getIcon("\uE034", "\uE769", "", "pause")
    readonly property string iconNext:              getIcon("\uE044", "\uE893", "", "next")
    readonly property string iconPrev:              getIcon("\uE045", "\uE892", "", "prev")
    readonly property string iconShuffle:           getIcon("\uE043", "\uE8B1", "", "shuffle")
    readonly property string iconRepeat:            getIcon("\uE040", "\uE8EE", "", "repeat")
    readonly property string iconRepeatOne:         getIcon("\uE041", "\uE8ED", "\uF365", "repeatOne")

    readonly property string iconWallhaven:         getIcon("\uE1BC", "\uE91B", "", "wallhaven")
    readonly property string iconWallpaper:         getIcon("\uE1BC", "\uE91B", "", "wallpaper")
    readonly property string iconBell:              getIcon("\uE7F5", "\uEA8F", "", "bell")
    readonly property string iconBellOutline:       getIcon("\uE7F5", "\uEA8F", "", "bellOutline")
    readonly property string iconBellOff:           getIcon("\uE7F6", "\uEE79", "", "bellOff")

    readonly property string iconEthernet:          getIcon("\uEB2F", "\uE839", "", "ethernet")
    readonly property string iconWifi:              getIcon("\uE63E", "\uE701", "", "wifi")
    readonly property string iconWifiHigh:          getIcon("\uE63E", "\uE874", "", "wifiHigh")
    readonly property string iconWifiMed:           getIcon("\uE4D9", "\uE873", "", "wifiMed")
    readonly property string iconWifiLow:           getIcon("\uE4CA", "\uE872", "", "wifiLow")
    readonly property string iconWifiOff:           getIcon("\uE648", "\uE998", "", "wifiOff")
    readonly property string iconBluetooth:         getIcon("\uE1A7", "\uE702", "", "bluetooth")
    readonly property string iconBluetoothConnected:getIcon("\uE1A8", "\uE702", "", "bluetoothConnected")
    readonly property string iconBluetoothOff:      getIcon("\uE1A9", "\uE702", "", "bluetoothOff")

    readonly property string iconPower:             getIcon("\uF8C7", "\uE7E8", "", "power")
    readonly property string iconShutdown:          iconPower
    readonly property string iconLock:              getIcon("\uE899", "\uE72E", "", "lock")
    readonly property string iconLogout:            getIcon("\uE9BA", "\uF3B1", "", "logout")
    readonly property string iconReboot:            getIcon("\uF053", "\uE777", "", "reboot")
    readonly property string iconSuspend:           getIcon("\uF159", "\uE708", "\uF186", "suspend")
    readonly property string iconHibernate:         getIcon("\uF236", "\uE9CA", "\uF236", "hibernate")

    readonly property string iconChevronRight:      getIcon("\uE5CC", "\uE974", "", "chevronRight")
    readonly property string iconChevronLeft:       getIcon("\uE5CB", "\uE973", "", "chevronLeft")
    readonly property string iconChevronDown:       getIcon("\uE5CF", "\uE972", "", "chevronDown")
    readonly property string iconChevronUp:         getIcon("\uE5CE", "\uE971", "\uF077", "chevronUp")
    readonly property string iconFlame:             getIcon("\uEF55", "\uE945", "", "flame")
    readonly property string iconSparkles:          getIcon("\uE65F", "\uE794", "", "sparkles")
    readonly property string iconRadio:             getIcon("\uE03E", "\uE93E", "📻", "radio")
    readonly property string iconSliders:           getIcon("\uE429", "\uE9E9", "", "sliders")
    readonly property string iconTerminal:          getIcon("\uEB8E", "\uE756", "", "terminal")
    readonly property string iconCalendar:          getIcon("\uE935", "\uE787", "", "calendar")
    readonly property string iconHistory:           getIcon("\uE8B3", "\uE81C", "", "history")
    readonly property string iconCopy:              getIcon("\uE14D", "\uE8C8", "", "copy")
    readonly property string iconExternalLink:      getIcon("\uE89E", "\uE8A7", "", "externalLink")
    readonly property string iconSignal:            getIcon("\uE202", "\uEC3A", "", "signal")
    readonly property string iconFilter:            getIcon("\uE152", "\uE71C", "", "filter")
    readonly property string iconUser:              getIcon("\uF0D3", "\uE77B", "", "user")
    readonly property string iconShield:            getIcon("\uE9E0", "\uEA18", "", "shield")
    readonly property string iconExpand:            getIcon("\uE5D0", "\uE740", "", "expand")
    readonly property string iconCollapse:          getIcon("\uE94D", "\uE73F", "\uF066", "collapse")
    readonly property string iconKeyboard:          getIcon("\uE30C", "\uEA08", "", "keyboard")

    // emotional support ascii faces for terminal burnout
    readonly property string kaoHappy:              "(ﾉ◕ヮ◕)ﾉ*:･ﾟ*"
    readonly property string kaoSad:                "(╥_╥)"
    readonly property string kaoCoffee:             "( ᐛ )و"
    readonly property string kaoShrug:              "¯\\_(ツ)_/¯"
    readonly property string kaoEmpty:              "(´・ω・`)"
    readonly property string kaoMusic:              "(´ε` )"
    readonly property string kaoSearch:             "(╯°□°)╯"
    readonly property string kaoError:              "(;´д`)"
    readonly property string kaoLoading:            "(⊙_⊙;)"
    readonly property string kaoPeace:              "ヽ(・∀・)ノ"
    readonly property string kaoSleepy:             "(-.-)zzz"
    readonly property string kaoCool:               "(⌐■_■)"
    readonly property string kaoLove:               "(^ω^*)"
    readonly property string kaoAnger:              "(╬ Ò﹏Ó)"
    readonly property string kaoChaos:              "(╯°□°)╯︵ ┻━┻"
    readonly property string kaoWink:               "(¬‿¬)"
    readonly property string kaoFlex:               "ᕦ(ò_óˇ)ᕤ"
    readonly property string kaoBolt:               "(>ᐛ )>"
    readonly property string kaoDead:               "(x_x)"
    readonly property string kaoCat:                "(=^･ω･^=)"
    readonly property string kaoPanic:              "(°Д°；)"
    readonly property string kaoVibe:               "( ˘ ³˘)♡"
    readonly property string kaoJam:                "(~‾‾)~"
    readonly property string kaoDJ:                 "(ノ^_^)ノ"
    readonly property string kaoSilent:             "( ˙-˙ )"
    readonly property string kaoCozy:               "(っ˘ω˘ς)"
    readonly property string kaoCheer:              "(ﾉ>ω<)ﾉ :｡･:*:･ﾟ"
    readonly property string kaoSmug:               "( ˘⌣˘ )"
    readonly property string kaoFire:               "(ง♨Д♨)ง"
    readonly property string kaoSparkle:            "(★ω★)"
    readonly property string kaoTableFlip:          "(╯°□°)╯︵ ┻━┻"
    readonly property string kaoPutBack:            "┬─┬ノ( º _ ºノ)"

    function getVibe(kao: string, nerd: string, text: string): string {
        let style = cfg?.vibeStyle ?? "nerd";
        if (style === "kaomoji") return kao ?? "";
        if (style === "nerd") return (nerd ?? "").toLowerCase();
        return (text ?? "").toLowerCase();
    }

    // static quote battery designed to psychically damage whoever looks at it
    readonly property var flavorQuotes: Object.freeze({
        "network_on": [
            "tcp handshake accepted. corporate surveillance resumed",
            "sending telemetry to fourteen different ad networks",
            "bgp routes stable, unfortunately",
            "downloading node_modules (heat death of universe pending)",
                                                      "stuffing uncompressed packets into kernel socket",
                                                      "direct fiber link tunneling to the digital abyss",
                                                      "pinging 1.1.1.1 just to make sure the earth is still here",
                                                      "negotiating 10gbe link speed purely out of spite",
                                                      "packet sniffing every zero and one",
                                                      "wifi wpa3 handshake verified: hello darkness",
                                                      "resolving dns... local cache is poisoned anyway",
                                                      "dhcp lease renewed for another 24 hours of suffering",
                                                      "tls 1.3 encrypted despair flowing smoothly",
                                                      "ipv6 neighbor discovery screaming into the void"
        ],
        "network_off": [
            "dns resolution failed: finally, inner peace",
            "rfc 1149 (ip over avian carriers) standby",
                                                      "127.0.0.1 is the only safe place left",
                                                      "eth0 interface is pretending to be dead",
                                                      "airgapped paranoia protocol activated",
                                                      "no packets, no masters, pure anarchy",
                                                      "cut the fiber cord, escaped the simulation",
                                                      "hardware killswitch toggled with unnecessary aggression",
                                                      "living inside a faraday cage made of bad life choices",
                                                      "tx/rx bytes: 0. total isolation achieved",
                                                      "networkmanager daemon gave up and went to sleep",
                                                      "rfkill blocked all rf adapters. we are untraceable"
        ],
        "battery_charging": [
            "converting coal exhaust into lithium dendrites",
            "trickle charging because the thermal paste is dust",
            "shoving 65 watts into a swollen spicy pillow",
            "usb-c pd negotiating for its life",
            "mainlining raw high-voltage current",
            "electrons aggressively cramming into lithium cages",
            "recharging anger cells at maximum amperage",
            "lithium pouch swelling with righteous indignation",
            "drawing enough watts to flicker the kitchen lights",
            "acpi reports state: charging (and overheating)",
                                                      "pmux controller silently screaming under 20 amps",
                                                      "pumping grid juice into degrading cell chemistry"
        ],
        "battery_low": [
            "acpi throws a critical warning, i ignore it",
            "running on kernel panic adrenaline and 2% reserve",
            "the pmux is begging for mercy",
            "about to drop state to hibernate and corrupt the swapfile",
            "running purely on stubbornness and spite",
            "one gentle sneeze and the display goes dark",
            "initiating fade-to-black speedrun",
            "voltage curve dropping faster than my self esteem",
            "two percent remaining and twenty buffers unsaved",
            "display backlight dimming into the shadow realm",
            "upower daemon is actively drafting a will",
            "cell voltage below 3.2v. catastrophic failure imminent"
        ],
        "battery_full": [
            "lithium cells balanced and ready to degrade",
            "100% capacity (actually 87% design capacity)",
                                                      "overcharge protection working overtime",
                                                      "drawing idle power directly from the wall",
                                                      "brimming with unbridled electrical violence",
                                                      "unplug me before the desk spontaneously combusts",
                                                      "power reserve peaked: untouchable machine god",
                                                      "zero dependency on the electrical socket hegemony",
                                                      "bms reports full charge. bms is probably lying",
                                                      "ac adapter trickling 1w just to feel important"
        ],
        "media_playing": [
            "decoding flac just to output it through cheap bluetooth earbuds",
            "pipewire graph actively dropping frames",
            "spotify hogging 2gb of ram for electron bloat",
            "audio ring buffer barely keeping up with my anxiety",
            "vibing at criminally irresponsible volumes",
            "acoustic compression waves rattling eardrums",
            "aux cord privileges completely uncontested",
            "blasting compressed 320kbps audio straight into skull",
            "the dac is working harder than our politicians",
            "injecting rhythm directly into the central nervous system",
            "mpris interface broadcasting bad music taste to dbus"
        ],
        "media_quiet": [
            "null sink selected. audio going into the void",
            "alsa is exclusively locking the hardware, again",
            "dead silence. the fans are spinning up though",
            "waiting for the inevitable system bell beep",
            "not a single banger detected within 50 miles",
            "exact zero decibels detected by audio server",
            "letting the dac enjoy an unpaid lunch break",
            "nothing playing except the coil whine in g-flat",
            "soundcard slumbering in complete acoustic deprivation",
            "wireplumber suspended the sink to save 0.1 watts"
        ],
        "notes_empty": [
            "vim buffer empty. brain buffer empty",
            "zero inodes allocated for original thoughts",
            "the sqlite db is entirely vacuumed",
            "no tasks. just existential dread",
            "head totally empty, smooth like polished marble",
            "zero schemes, zero notes, absolute zen emptiness",
            "braincache totally flushed to /dev/null",
            "not even a single grocery item rattling in the void",
            "tmpfs cleared. no lingering responsibilities",
            "the markdown file contains 0 bytes. nature is healing"
        ],
        "notifs_empty": [
            "dbus is totally quiet. highly suspicious",
            "no websockets connected. nobody cares",
            "zero unread emails. the spam filter is catching up",
            "dunst daemon is bored to tears",
            "absolute zero drama reported in local airspace",
            "notification inbox declared a nature sanctuary",
            "nobody has pinged me and the world is temporarily healed",
            "zero `@everyone` tags ruining my sleep cycle",
            "no pings, no screams, no jira tickets kicking the door down",
            "event loop is completely idle. peace at last"
        ],
        "dnd_on": [
            "sigkill sent to all social interactions",
            "routing all dbus notifications straight to /dev/null",
            "firewalling port 80 of my personal boundaries",
            "tcp rst sent to reality",
            "anti-social defense perimeter active",
            "do not look at me, do not perceive me",
            "touch grass protocol enforced by martial law",
            "notification daemon bound and gagged in the basement",
            "if you ping me right now i will compile gentoo on your router",
            "silent mode: active hostile disinterest engaged"
        ],
        "volume_muted": [
            "hardware switch engaged. paranoia validated",
            "sending all pcm streams into the void",
            "volume set to 0. alsa still clipping somehow",
            "pulseaudio dummy output vibes",
            "silence dialed to eleven",
            "muted so youtube ads don't detonate my soul",
            "wireplumber ordered to execute total radio silence",
            "not a single decibel sneaking out of this sound server",
            "master fader pulled all the way to negative infinity"
        ],
        "volume_high": [
            "clipping the digital preamp to feel alive",
            "overdriving the dac because the mix is garbage",
            "approaching absolute 0dbfs. prepare for distortion",
            "destroying dynamic range intentionally",
            "permanent hearing loss tutorial (any%)",
                                                      "speaker cones begging for humanitarian intervention",
                                                      "decibels exceeding osha recommendations",
                                                      "if the desk isn't vibrating you aren't doing it right",
                                                      "treating the tympanic membrane with total disrespect",
                                                      "pushing the amplifier into severe thermal throttling"
        ],
        "brightness_high": [
            "pwm flickering at maximum duty cycle",
            "backlight inverter screaming in high frequency",
            "burning the status bar permanently into the oled",
            "compiling light theme with 400 nits of pure pain",
            "deploying tactical flashbang straight into corneas",
            "illuminating entire apartment with raw screen glow",
            "corneal crisping level: well-done",
            "using the monitor to warm my frozen hands",
            "pushing 100% luminance just to read bad code"
        ],
        "brightness_low": [
            "sub-pixel rendering disabled by darkness",
            "backlight off. reading the lcd via desk lamp",
            "saving 0.4 watts on backlight power",
            "operating below the threshold of human perception",
            "vampire cave ambience successfully calibrated",
            "saving optical nerves from certain destruction",
            "three photons escaping the display per lunar cycle",
            "screen dim enough to hide my shame",
            "contrast ratio completely destroyed by ambient light"
        ],
        "idle_inhibited": [
            "systemd-inhibit holds the lock. we die like men",
            "caffeine-ng actively lying to the x server",
            "wayland idle protocol suppressed",
            "burning screen phosphors on an ssh session",
            "machine pumped full of intravenous espresso",
            "no sleeping allowed on this workstation",
            "inhibit lock engaged: stay awake or face destruction",
            "we do not sleep until the build finishes",
            "dpms blocked by obscure dbus method call"
        ],
        "idle_normal": [
            "dpms standby countdown initiated",
            "cpu scaling governor set to powersave",
            "c-states dropping deeper than my self esteem",
            "waiting for the screensaver segmentation fault",
            "ready to take an afternoon nap at any second",
            "circuits cooling down into peaceful slumber",
            "acpi power management waiting patiently in the wings",
            "display panel preparing its peaceful descent into darkness",
            "system idle. existential dread loading"
        ],
        "system": [
            "oom killer is sizing up the electron apps",
            "kswapd0 is consuming 100% cpu",
            "load average: 14.2, 12.8, 10.1. this is fine",
            "dmesg is a horror novel",
            "segfault at rip 0000. ignored",
            "thermald is throttling the cpu to 800mhz",
            "pure functional bliss running on nixos",
            "garbage collecting my regrets from the nix store",
            "memory leaks kept under strict surveillance",
            "btop shows everything is fine so do not question it",
            "swap space carrying the entire weight of my sins",
            "four hundred uncommitted git changes staring back into the abyss",
            "running 40 days of uptime out of pure cowardice to reboot",
            "journalctl is mostly just stack traces at this point",
            "xorg is using 4gb of ram and nobody knows why"
        ],
        "screenshot": [
            "xwd dumping raw root window buffer",
            "wl-clipboard pipe broken, image lost",
            "flameshot segfaulting on multimonitor setup",
            "allocating 40mb of ram for a 10kb png",
            "capturing wayland surface with absolute disrespect",
            "taking a screenshot? u snitch",
            "saving receipts for the group chat",
            "snitch mode: engaged",
            "pixels acquired, dignity lost",
            "your fbi agent is judging you heavily",
            "digital kleptomania at its finest",
            "piracy is a crime but stealing pixels is fine",
            "evidence secured for the tribunal",
            "right click save as, but violent",
            "another jpeg for the evidence folder"
        ]
    })

    // hooked straight into the clock pulse so unhinged thoughts rot reactively every 60s
    function getFlavor(category: string, fallback: string): string {
        if (!cfg?.unhingedFlavor) return (fallback ?? "").toLowerCase();
        let list = flavorQuotes[category];
        if (!list || list.length === 0) return (fallback ?? "").toLowerCase();

        let totalMinutes = clock.hours * 60 + clock.minutes;
        return (list[totalMinutes % list.length] ?? fallback ?? "").toLowerCase();
    }
}
