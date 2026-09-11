pragma Singleton
import QtQuick

QtObject {
    // matugen palette tokens
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

    // math & formatting utilities
    function alpha(c: color, a: real): color { return Qt.rgba(c.r, c.g, c.b, a) }

    function blend(c1: color, c2: color, t: real): color {
        let f = Math.max(0.0, Math.min(1.0, t));
        return Qt.rgba(
            c1.r + (c2.r - c1.r) * f,
            c1.g + (c2.g - c1.g) * f,
            c1.b + (c2.b - c1.b) * f,
            c1.a + (c2.a - c1.a) * f
        );
    }

    function formatBytes(bytes: real): string {
        if (!bytes || bytes <= 0 || isNaN(bytes)) return "0 B";
        const units = ["B", "KiB", "MiB", "GiB", "TiB"];
        let i = Math.max(0, Math.min(units.length - 1, Math.floor(Math.log(bytes) / Math.log(1024))));
        let val = bytes / Math.pow(1024, i);
        return (val >= 100 || i === 0 ? Math.round(val) : val.toFixed(1)) + " " + units[i];
    }

    function formatUptime(sec: int): string {
        if (!sec || sec <= 0) return "0m";
        let d = Math.floor(sec / 86400);
        let h = Math.floor((sec % 86400) / 3600);
        let m = Math.floor((sec % 3600) / 60);
        if (d > 0) return d + "d " + h + "h";
        if (h > 0) return h + "h " + m + "m";
        return m + "m";
    }

    function getBatteryColor(pct: int, isCharging: bool): color {
        if (isCharging) return primary;
        if (pct <= 15) return error;
        if (pct <= 30) return warn;
        return on_surface;
    }

    // state tints and overlays
    readonly property color primary_overlay:        alpha(primary, 0.18)
    readonly property color secondary_overlay:      alpha(secondary, 0.18)
    readonly property color tertiary_overlay:       alpha(tertiary, 0.18)
    readonly property color error_overlay:          alpha(error, 0.22)
    readonly property color warn:                   tertiary
    readonly property color warn_container:         tertiary_container
    readonly property color on_warn_container:      on_tertiary_container
    readonly property color warn_overlay:           tertiary_overlay

    readonly property color on_surface_disabled:    alpha(on_surface, 0.38)
    readonly property color outline_disabled:       alpha(outline, 0.12)
    readonly property color fontStrokeColor:        "#000000"
    readonly property color textStroke:             "#000000"
    readonly property color textShadow:             "#000000"

    // typography metrics
    readonly property string fontSans:              Settings?.fontSans ?? Settings?.fontFamily ?? "Noto Sans"
    readonly property string fontMono:              Settings?.fontMono ?? "JetBrainsMono Nerd Font"
    readonly property string fontDisplay:           Settings?.fontDisplay ?? fontSans
    readonly property string fontVibe:              "Noto Sans, Noto Sans CJK JP, Noto Color Emoji, " + fontSans
    readonly property string fontFamily:            fontSans

    readonly property int    fontWeightLight:       300
    readonly property int    fontWeightRegular:     400
    readonly property int    fontWeightMedium:      500
    readonly property int    fontWeightDemiBold:    600
    readonly property int    fontWeightBold:        700

    readonly property real   fontScale:             Settings?.fontScale ?? 1.0
    readonly property int    fontSizeXs:            Math.round(9 * fontScale)
    readonly property int    fontSizeSm:            Math.round(11 * fontScale)
    readonly property int    fontSizeMd:            Math.round(13 * fontScale)
    readonly property int    fontSizeLg:            Math.round(15 * fontScale)
    readonly property int    fontSizeXl:            Math.round(18 * fontScale)
    readonly property int    fontSizeTitle:         Math.round(22 * fontScale)

    // shell geometry and curvature
    readonly property int    radiusSm:              2
    readonly property int    radiusMd:              4
    readonly property int    radiusLg:              8
    readonly property int    radiusPill:            9999

    readonly property int    barHeight:             Settings?.barHeight ?? 32
    readonly property int    barRadius:             Settings?.barRadius ?? 0
    readonly property int    widgetRadius:          Settings?.widgetRadius ?? radiusSm
    readonly property int    popupRadius:           Settings?.popupRadius ?? radiusMd
    readonly property int    widgetSpacing:         Settings?.widgetSpacing ?? 4
    readonly property int    widgetPaddingH:        Settings?.widgetPaddingH ?? 8
    readonly property int    widgetPaddingV:        0
    readonly property real   barOpacity:            Settings?.barOpacity ?? 1.0
    readonly property real   popupOpacity:          Settings?.popupOpacity ?? 1.0

    readonly property int    scoopRadiusX:          Settings?.scoopRadius ?? 16
    readonly property int    scoopRadiusY:          Settings?.scoopRadius ?? 16
    readonly property real   scoopTension:          Settings?.scoopTension ?? 0.5522847498307936
    readonly property string scoopStyle:            Settings?.cornerStyle ?? "cubic"
    readonly property int    screenCornerRadius:    Settings?.screenCornerRadius ?? 16
    readonly property int    screenBorderWidth:     Settings?.screenBorderWidth ?? 2
    readonly property bool   screenFrameDocked:     Settings?.screenFrameDocked ?? true
    readonly property string screenCornerMode:      Settings?.screenCornerMode ?? "all"
    readonly property string cornerColorMode:       Settings?.cornerColorMode ?? "bar"
    readonly property string barStyle:              Settings?.barStyle ?? "glass"

    // surface resolvers
    function getStyleColor(role: string, bs: string): color {
        switch (role) {
            case "barBg":
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
                if (bs === "pure-black") return "#1f1f1f";
                if (bs === "glass") return Qt.rgba(1, 1, 1, 0.16);
                if (bs === "glass-frost") return Qt.rgba(1, 1, 1, 0.24);
                if (bs === "cyber-neon") return primary;
                if (bs === "bento-floating") return alpha(outline_variant, 0.45);
                if (bs === "accent-glow") return primary;
                if (bs === "translucent") return alpha(outline_variant, 0.35);
                return alpha(outline_variant, 0.50);
            case "widgetBg":
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
                if (bs === "pure-black") return "#222222";
                if (bs === "glass") return Qt.rgba(1, 1, 1, 0.14);
                if (bs === "glass-frost") return Qt.rgba(1, 1, 1, 0.22);
                if (bs === "cyber-neon") return alpha(primary, 0.75);
                if (bs === "bento-floating") return alpha(outline_variant, 0.30);
                if (bs === "translucent") return alpha(outline_variant, 0.25);
                if (bs === "accent-glow") return alpha(primary, 0.85);
                if (bs === "monochrome") return alpha(outline, 0.35);
                return "transparent";
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

    // border and depth tokens
    readonly property color  glassHighlight:        Qt.rgba(1, 1, 1, 0.16)
    readonly property color  glassBorder:           Qt.rgba(1, 1, 1, 0.12)
    readonly property color  glassGlow:             alpha(primary, 0.25)
    readonly property color  cardGlow:              alpha(primary, 0.15)
    readonly property int    popupBorderWidth:      Settings?.popupBorderWidth ?? 1
    readonly property bool   scoopBorderEnabled:    Settings?.scoopBorderEnabled ?? true
    readonly property int    scoopBorderWidth:      Settings?.scoopBorderWidth ?? (screenBorderWidth > 0 ? screenBorderWidth : 2)
    readonly property color  scoopBorderColor: {
        let sc = Settings?.scoopBorderColor ?? "auto";
        if (sc !== "auto" && sc !== "") return sc;
        if (cornerColorMode === "accent") return primary;
        return barBorderColor;
    }

    // popup geometry
    readonly property int    popupWidth:            460
    readonly property int    popupHeight:           580
    readonly property int    popupPadding:          16
    readonly property int    popupSpacing:          10
    readonly property int    thumbSize:             180

    // animation specs and easing
    readonly property real   animSpeedMult:         Settings?.animSpeed === "instant" ? 0.01 : ((Settings?.animSpeed === "snappy" || Settings?.animSpeed === "superSnappy") ? 0.7 : (Settings?.animSpeed === "hyper" ? 0.4 : (Settings?.animSpeed === "chill" ? 1.6 : 1.0)))
    readonly property bool   isVertical:            Settings?.barPosition === "left" || Settings?.barPosition === "right"
    readonly property int    animFast:              Math.round(120 * animSpeedMult)
    readonly property int    animNormal:            Math.round(200 * animSpeedMult)
    readonly property int    animDefault:           animNormal
    readonly property int    animSlow:              Math.round(350 * animSpeedMult)
    readonly property int    expressiveFast:        Math.round(180 * animSpeedMult)
    readonly property int    expressiveDefault:     Math.round(320 * animSpeedMult)
    readonly property int    expressiveSlow:        Math.round(480 * animSpeedMult)
    readonly property int    workspaceTrailDuration: Math.round(260 * animSpeedMult)
    readonly property bool   workspaceActiveTrail:  Settings?.workspaceActiveTrail ?? true
    readonly property var    animEasing:            Easing.OutCubic
    readonly property var    animExpressiveEasing:  Easing.OutBack

    // font family resolution
    readonly property string iconSet:               Settings?.iconSet ?? "material"
    readonly property string fontIcon: {
        if (iconSet === "kaomoji" || iconSet === "text") return fontFamily;
        if (iconSet === "nerd") {
            let families = Qt.fontFamilies();
            let target = Settings?.fontNerd ?? "JetBrainsMono Nerd Font";
            if (families.indexOf(target) >= 0) return target;
            if (families.indexOf("JetBrainsMono NF") >= 0) return "JetBrainsMono NF";
            return "JetBrainsMono Nerd Font";
        }
        if (iconSet === "windows") return Settings?.fontWindows ?? "Segoe Fluent Icons";
        if (iconSet === "awesome") {
            let families = Qt.fontFamilies();
            let target = Settings?.fontAwesome ?? "Font Awesome 6 Free";
            if (families.indexOf(target) >= 0) return target;
            return fontMono;
        }

        let fams = Qt.fontFamilies();
        let chosen = Settings?.fontMaterial ?? "Material Symbols Rounded";
        if (fams.indexOf(chosen) >= 0) return chosen;
        if (fams.indexOf("Material Symbols Rounded") >= 0) return "Material Symbols Rounded";
        if (fams.indexOf("Material Symbols Outlined") >= 0) return "Material Symbols Outlined";
        if (fams.indexOf("Material Symbols Sharp") >= 0) return "Material Symbols Sharp";
        return iconSet === "material" ? "Material Symbols Rounded" : fontMono;
    }

    // kaomoji dictionary
    readonly property var kaomojiMap: ({
        "arch": "(^_^)v",
        "appLauncher": "(^_^)v",
        "workspaces": "[::]",
        "search": "(⚆_⚆)",
        "close": "(x)",
        "check": "(✓)",
        "checkCircle": "(✓)",
        "settings": "(*_*)",
        "gear": "(*_*)",
        "save": "(⤓)",
        "refresh": "(↺)",
        "trash": "(⌫)",
        "clipboard": "(≡)",
        "tray": "[..]",
        "grid": "[#]",
        "note": "(✎)",
        "edit": "(✎)",
        "coffee": "(旦)",
        "clock": "(◷)",
        "cpu": "[cpu]",
        "mem": "[ram]",
        "thermo": "[°c]",
        "eye": "(•‿•)",
        "eyeOff": "(-_-)",
        "heart": "(♡)",
        "download": "(↓)",
        "folder": "[dir]",
        "globe": "(⊕)",
        "camera": "[o]",
        "crop": "[#]",
        "screenshot": "[o]",
        "volMute": "(-_-)",
        "volLow": "(・ω・)",
        "volMid": "(ᵔᴥᵔ)",
        "volHigh": "(≧◡≦)",
        "mic": "(¶)",
        "micMute": "(x_x)",
        "palette": "(※)",
        "headphones": "(d-_-b)",
        "equalizer": "|||",
        "batFull": "(◕‿◕)",
        "batHalf": "(・_・)",
        "batQuarter": "(>_<)",
        "batEmpty": "(×_×)",
        "batCharge": "(↯^↯)",
        "batCharging": "(↯^↯)",
        "sun": "(☼)",
        "moon": "(☾)",
        "brightness": "(☼)",
        "music": "(♫)",
        "play": "(▶)",
        "pause": "(❚❚)",
        "next": "(>>)",
        "prev": "(<<)",
        "shuffle": "(~)",
        "repeat": "(↻)",
        "repeatOne": "(1)",
        "wallhaven": "[img]",
        "wallpaper": "[img]",
        "bell": "(⍾)",
        "bellOutline": "(⍾)",
        "bellOff": "(⍉)",
        "ethernet": "[eth]",
        "wifi": "(•̀ᴗ•́)و",
        "wifiHigh": "(•̀ᴗ•́)و",
        "wifiMed": "(・_・)",
        "wifiLow": "( ;¬_¬)",
        "wifiOff": "(×_×)",
        "bluetooth": "(~)",
        "bluetoothConnected": "(•̀ᴗ•́)و",
        "bluetoothOff": "(×_×)",
        "power": "(⏻)",
        "shutdown": "(⏻)",
        "lock": "(⚿)",
        "logout": "(bye)",
        "reboot": "(↺)",
        "suspend": "(zzz)",
        "hibernate": "(zzz)",
        "chevronRight": ">",
        "chevronLeft": "<",
        "chevronDown": "v",
        "chevronUp": "^",
        "flame": "(♨)",
        "sparkles": "(✦)",
        "radio": "[rad]",
        "sliders": "[=]",
        "terminal": "[>_]",
        "calendar": "[cal]",
        "history": "(↺)",
        "copy": "[cp]",
        "externalLink": "(->)",
        "signal": "(ıllι)",
        "filter": "[/]",
        "user": "(•)",
        "shield": "[#]",
        "expand": "[+]",
        "collapse": "[-]"
    })

    // text mode dictionary
    readonly property var textMap: ({
        "arch": "apps",
        "appLauncher": "apps",
        "workspaces": "ws",
        "search": "find",
        "close": "x",
        "check": "ok",
        "checkCircle": "ok",
        "settings": "cfg",
        "gear": "cfg",
        "save": "save",
        "refresh": "reload",
        "trash": "del",
        "clipboard": "clip",
        "tray": "tray",
        "grid": "grid",
        "note": "note",
        "edit": "edit",
        "coffee": "cafe",
        "clock": "time",
        "cpu": "cpu",
        "mem": "mem",
        "thermo": "temp",
        "eye": "show",
        "eyeOff": "hide",
        "heart": "fav",
        "download": "down",
        "folder": "dir",
        "globe": "web",
        "camera": "cam",
        "crop": "crop",
        "screenshot": "shot",
        "volMute": "mute",
        "volLow": "vol-",
        "volMid": "vol",
        "volHigh": "vol+",
        "mic": "mic",
        "micMute": "no-mic",
        "palette": "theme",
        "headphones": "audio",
        "equalizer": "eq",
        "batFull": "100%",
        "batHalf": "50%",
        "batQuarter": "25%",
        "batEmpty": "0%",
        "batCharge": "chg",
        "batCharging": "chg",
        "sun": "day",
        "moon": "night",
        "brightness": "bright",
        "music": "music",
        "play": "play",
        "pause": "pause",
        "next": "next",
        "prev": "prev",
        "shuffle": "shuf",
        "repeat": "loop",
        "repeatOne": "loop1",
        "wallhaven": "walls",
        "wallpaper": "wall",
        "bell": "bell",
        "bellOutline": "bell",
        "bellOff": "quiet",
        "ethernet": "eth",
        "wifi": "wifi",
        "wifiHigh": "high",
        "wifiMed": "med",
        "wifiLow": "low",
        "wifiOff": "offline",
        "bluetooth": "bt",
        "bluetoothConnected": "bt-on",
        "bluetoothOff": "bt-off",
        "power": "power",
        "shutdown": "power",
        "lock": "lock",
        "logout": "logout",
        "reboot": "reboot",
        "suspend": "sleep",
        "hibernate": "hib",
        "chevronRight": ">",
        "chevronLeft": "<",
        "chevronDown": "v",
        "chevronUp": "^",
        "flame": "chaos",
        "sparkles": "magic",
        "radio": "radio",
        "sliders": "opts",
        "terminal": "term",
        "calendar": "cal",
        "history": "hist",
        "copy": "copy",
        "externalLink": "open",
        "signal": "sig",
        "filter": "filter",
        "user": "user",
        "shield": "safe",
        "expand": "max",
        "collapse": "min"
    })

    // nerd font dictionary
    readonly property var nerdMap: ({
        "arch": "",
        "appLauncher": "󰀻",
        "workspaces": "󱂬",
        "search": "",
        "close": "",
        "check": "",
        "checkCircle": "",
        "settings": "",
        "gear": "",
        "save": "",
        "refresh": "",
        "trash": "",
        "clipboard": "󰅌",
        "tray": "󱊖",
        "grid": "󰕰",
        "note": "󰏫",
        "edit": "󰏫",
        "coffee": "󰛊",
        "clock": "󰥔",
        "cpu": "󰍛",
        "mem": "󰘚",
        "thermo": "󰔏",
        "eye": "󰈈",
        "eyeOff": "󰈉",
        "heart": "󰋑",
        "download": "󰇚",
        "folder": "󰉋",
        "globe": "󰖟",
        "camera": "󰄀",
        "crop": "󰩨",
        "screenshot": "󰹑",
        "volMute": "󰝟",
        "volLow": "󰕿",
        "volMid": "󰖀",
        "volHigh": "󰕾",
        "mic": "󰍬",
        "micMute": "󰍭",
        "palette": "󰏘",
        "headphones": "󰋋",
        "equalizer": "󰓃",
        "batFull": "󰁹",
        "batHalf": "󰁿",
        "batQuarter": "󰁼",
        "batEmpty": "󰂃",
        "batCharge": "󰢝",
        "batCharging": "󰢝",
        "sun": "󰖙",
        "moon": "󰖔",
        "brightness": "󰃠",
        "music": "󰝚",
        "play": "󰐊",
        "pause": "󰏤",
        "next": "󰒭",
        "prev": "󰒮",
        "shuffle": "󰒝",
        "repeat": "󰑖",
        "repeatOne": "󰑘",
        "wallhaven": "󰋩",
        "wallpaper": "󰋩",
        "bell": "󰂚",
        "bellOutline": "󰂚",
        "bellOff": "󰂛",
        "ethernet": "󰈀",
        "wifi": "󰤨",
        "wifiHigh": "󰤨",
        "wifiMed": "󰤥",
        "wifiLow": "󰤟",
        "wifiOff": "󰤮",
        "bluetooth": "󰂯",
        "bluetoothConnected": "󰂱",
        "bluetoothOff": "󰂲",
        "power": "󰐥",
        "shutdown": "󰐥",
        "lock": "󰌾",
        "logout": "󰍃",
        "reboot": "󰑓",
        "suspend": "󰤄",
        "hibernate": "󰒲",
        "chevronRight": "",
        "chevronLeft": "",
        "chevronDown": "",
        "chevronUp": "",
        "flame": "󰈸",
        "sparkles": "󰛓",
        "radio": "󰐹",
        "sliders": "󰒓",
        "terminal": "󰆍",
        "calendar": "󰃭",
        "history": "󰋚",
        "copy": "󰆏",
        "externalLink": "󰌹",
        "signal": "󰖩",
        "filter": "󰈲",
        "user": "󰀉",
        "shield": "󰞌",
        "expand": "󰊓",
        "collapse": "󰊔"
    })

    function getIcon(mat: string, win: string, fa: string, key: var, kao: var, txt: var): string {
        if (iconSet === "kaomoji") {
            if (typeof kao === "string" && kao !== "" && kao !== "undefined") return kao;
            if (key && kaomojiMap && kaomojiMap[key]) return kaomojiMap[key];
            return mat;
        }
        if (iconSet === "text") {
            if (typeof txt === "string" && txt !== "" && txt !== "undefined") return txt;
            if (key && textMap && textMap[key]) return textMap[key];
            return mat;
        }
        if (iconSet === "nerd") {
            if (key && nerdMap && nerdMap[key]) return nerdMap[key];
            if (typeof fa === "string" && fa !== "") return fa;
            return mat;
        }
        if (iconSet === "windows") return win;
        if (iconSet === "awesome") return fa;
        return mat;
    }

    // dynamic glyph resolvers
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
            if (lvl < 0) return "";
            if (isCharging) return "";
            if (lvl >= 9) return "";
            if (lvl >= 7) return "";
            if (lvl >= 5) return "";
            if (lvl >= 2) return "";
            return "";
        }

        if (lvl < 0) return "\uE19C";
        if (isCharging) {
            const matCharging = ["\uF0A2", "\uF0A2", "\uF0A3", "\uF0A3", "\uF0A4", "\uF0A4", "\uF0A5", "\uF0A6", "\uF0A6", "\uF0A7", "\uE1A3"];
            return matCharging[lvl];
        }
        const matDischarging = ["\uE19C", "\uF09C", "\uF09D", "\uF09D", "\uF09E", "\uF09E", "\uF09F", "\uF0A0", "\uF0A0", "\uF0A1", "\uE1A5"];
        return matDischarging[lvl];
    }

    function getVolumeIcon(volRatio: real, isMuted: bool): string {
        if (isMuted || volRatio <= 0.001) {
            return (iconSet === "kaomoji") ? "(-_-)" : (iconSet === "text") ? "mute" : (iconSet === "nerd") ? "󰝟" : iconVolMute;
        }
        let pct = Math.round(volRatio * 100);
        if (iconSet === "kaomoji") {
            if (pct <= 33) return "(・ω・)";
            if (pct <= 66) return "(ᵔᴥᵔ)";
            return "(≧◡≦)";
        }
        if (iconSet === "text") {
            return pct + "%";
        }
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
        if (pct <= 33) return "\uE04D";
        if (pct <= 66) return "\uE04D";
        return "\uE050";
    }

    function getWifiIcon(signalPct: int, isConnected: bool, isEthernet: bool): string {
        if (isEthernet) return (iconSet === "kaomoji") ? "[eth]" : (iconSet === "text") ? "eth" : (iconSet === "nerd") ? "󰈀" : iconEthernet;
        if (!isConnected) return (iconSet === "kaomoji") ? "(×_×)" : (iconSet === "text") ? "off" : (iconSet === "nerd") ? "󰤮" : iconWifiOff;
        let sig = (signalPct === undefined || signalPct === null) ? 0 : signalPct;
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
            return "";
        }
        if (sig < 35) return "\uE4CA";
        if (sig < 70) return "\uE4D9";
        return "\uE63E";
    }

    // static icon index
    readonly property string iconArch:              getIcon("\uE5C3", "\uE71D", "", "arch")
    readonly property string iconAppLauncher:       getIcon("\uE5C3", "\uE71D", "", "appLauncher")
    readonly property string iconWorkspaces:        getIcon("\uE871", "\uE7C4", "", "workspaces")
    readonly property string iconSearch:            getIcon("\uE8B6", "\uE721", "", "search")
    readonly property string iconClose:             getIcon("\uE5CD", "\uE711", "", "close")
    readonly property string iconCheck:             getIcon("\uE5CA", "\uE73E", "", "check")
    readonly property string iconCheckCircle:       getIcon("\uF0BE", "\uF13E", "", "checkCircle")
    readonly property string iconSettings:          getIcon("\uE8B8", "\uE713", "", "settings")
    readonly property string iconGear:              iconSettings
    readonly property string iconSave:              getIcon("\uE161", "\uE74E", "", "save")
    readonly property string iconRefresh:           getIcon("\uE5D5", "\uE72C", "", "refresh")
    readonly property string iconTrash:             getIcon("\uE92E", "\uE74D", "", "trash")
    readonly property string iconClipboard:         getIcon("\uE14F", "\uF0E3", "", "clipboard")
    readonly property string iconTray:              getIcon("\uE5CE", "\uE971", "", "tray")
    readonly property string iconGrid:              getIcon("\uE9B0", "\uE74C", "", "grid")
    readonly property string iconNote:              getIcon("\uF097", "\uE70F", "", "note")
    readonly property string iconEdit:              iconNote
    readonly property string iconCoffee:            getIcon("\uEFEF", "\uEC32", "", "coffee")
    readonly property string iconClock:             getIcon("\uEFD6", "\uE823", "", "clock")
    readonly property string iconCpu:               getIcon("\uE322", "\uEEA1", "", "cpu")
    readonly property string iconMem:               getIcon("\uE322", "\uEEA0", "", "mem")
    readonly property string iconThermo:            getIcon("\uF076", "\uE9CA", "", "thermo")
    readonly property string iconEye:               getIcon("\uE8F4", "\uE7B3", "", "eye")
    readonly property string iconEyeOff:            getIcon("\uE8F5", "\uED1A", "", "eyeOff")
    readonly property string iconHeart:             getIcon("\uE87E", "\uEB51", "", "heart")
    readonly property string iconDownload:          getIcon("\uF090", "\uE896", "", "download")
    readonly property string iconFolder:            getIcon("\uE2C7", "\uE838", "", "folder")
    readonly property string iconGlobe:             getIcon("\uE80B", "\uE774", "", "globe")
    readonly property string iconCamera:            getIcon("\uE3AF", "\uE722", "", "camera")
    readonly property string iconCrop:              getIcon("\uE3BE", "\uE7A8", "", "crop")
    readonly property string iconScreenshot:        iconCamera

    readonly property string iconVolMute:           getIcon("\uE04F", "\uE74F", "", "volMute")
    readonly property string iconVolLow:            getIcon("\uE04D", "\uE993", "", "volLow")
    readonly property string iconVolMid:            getIcon("\uE04D", "\uE994", "", "volMid")
    readonly property string iconVolHigh:           getIcon("\uE050", "\uE995", "", "volHigh")
    readonly property string iconMic:               getIcon("\uE31D", "\uE720", "", "mic")
    readonly property string iconMicMute:           getIcon("\uE02B", "\uF781", "", "micMute")
    readonly property string iconPalette:           getIcon("\uE40A", "\uE790", "", "palette")
    readonly property string iconHeadphones:        getIcon("\uF01F", "\uE7F6", "", "headphones")
    readonly property string iconEqualizer:         getIcon("\uE01D", "\uE9E9", "", "equalizer")

    readonly property string iconBatFull:           getIcon("\uE1A5", "\uE83F", "", "batFull")
    readonly property string iconBatHalf:           getIcon("\uF0A0", "\uE855", "", "batHalf")
    readonly property string iconBatQuarter:        getIcon("\uF09D", "\uE852", "", "batQuarter")
    readonly property string iconBatEmpty:          getIcon("\uE19C", "\uE850", "", "batEmpty")
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
    readonly property string iconRepeatOne:         getIcon("\uE041", "\uE8ED", "", "repeatOne")

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
    readonly property string iconBluetooth:         getIcon("\uE1A7", "\uE702", "", "bluetooth")
    readonly property string iconBluetoothConnected:getIcon("\uE1A8", "\uF5B8", "", "bluetoothConnected")
    readonly property string iconBluetoothOff:      getIcon("\uE1A9", "\uF5B7", "", "bluetoothOff")

    readonly property string iconPower:             getIcon("\uF8C7", "\uE7E8", "", "power")
    readonly property string iconShutdown:          iconPower
    readonly property string iconLock:              getIcon("\uE899", "\uE72E", "", "lock")
    readonly property string iconLogout:            getIcon("\uE9BA", "\uF3B1", "", "logout")
    readonly property string iconReboot:            getIcon("\uF053", "\uE777", "", "reboot")
    readonly property string iconSuspend:           getIcon("\uF159", "\uE708", "", "suspend")
    readonly property string iconHibernate:         getIcon("\uEB3B", "\uEC55", "", "hibernate")

    readonly property string iconChevronRight:      getIcon("\uE5CC", "\uE974", "", "chevronRight")
    readonly property string iconChevronLeft:       getIcon("\uE5CB", "\uE973", "", "chevronLeft")
    readonly property string iconChevronDown:       getIcon("\uE5CF", "\uE972", "", "chevronDown")
    readonly property string iconChevronUp:         getIcon("\uE5CE", "\uE971", "", "chevronUp")
    readonly property string iconFlame:             getIcon("\uEF55", "\uE814", "", "flame")
    readonly property string iconSparkles:          getIcon("\uE65F", "\uE7C5", "", "sparkles")
    readonly property string iconRadio:             getIcon("\uE03E", "\uEC18", "📻", "radio")
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
    readonly property string iconCollapse:          getIcon("\uE5D1", "\uE73F", "", "collapse")

    // emotive kaomoji presets
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
        let style = Settings?.vibeStyle ?? "nerd";
        if (style === "kaomoji") return kao;
        if (style === "nerd") return nerd;
        return text ?? "";
    }

    // flavor text table
    function getFlavor(category: string, fallback: string): string {
        if (!Settings?.unhingedFlavor) return fallback ?? "";
        let quotes = {
            "network_on": [
                "beaming photons directly into frontal lobe",
                "locked into the planetary hypergrid",
                "surveillance feed calibrated & online",
                "5g brain waves humming at optimal resonance",
                "stuffing uncompressed packets into kernel socket",
                "direct fiber link tunneling to the digital abyss",
                "ping is crisp like autumn gravel under boot",
                "downloading extra physical RAM via UDP",
                "hardwired straight to the cyber matrix",
                "packet sniffing every zero and one",
                "handshake verified: hello darkness my old friend",
                "latency lower than my attention span",
                "exchanging raw tcp handshake pleasantries with nowhere",
                "ethernet cable radiating pure existential dread",
                "sniffing broadcast packets out of morbid curiosity",
                "negotiating 10gbe link speed purely out of spite",
                "pinging 1.1.1.1 just to make sure the earth is still here",
                "sucking down raw telemetry straight into the void",
                "wi-fi antennae desperately grasping for dirty radio waves",
                "packet loss: 0% / mental stability loss: 100%"
            ],
            "network_off": [
                "airgapped paranoia protocol activated",
                "wifi adapter went to the corner store for milk",
                "touching physical grass in real 4K",
                "carrier pigeon squadron en route",
                "no packets, no masters, pure anarchy",
                "router took an eternal dirt nap",
                "offline goblin mode initialized",
                "pure untraceable analog radio silence",
                "cut the fiber cord, escaped the simulation",
                "unreachable, untracked, unbothered",
                "zero ping because zero network exists",
                "transmitting exclusively via telepathy",
                "rf environment as quiet as a server room after a power failure",
                "hardware killswitch toggled with unnecessary aggression",
                "if the packet does not travel, the bug cannot spread",
                "living inside a faraday cage made of bad life choices",
                "ping timeout forever and ever amen",
                "dns lookups failing successfully",
                "unplugged the world to compile code in pitch darkness"
            ],
            "battery_charging": [
                "mainlining raw high-voltage current",
                "drinking straight from the breaker box",
                "electrons aggressively cramming into lithium cages",
                "sipping sweet grid power like boba tea",
                "detachable wall tether keeping machine alive",
                "gluttonous electron banquet underway",
                "recharging anger cells at maximum amperage",
                "wired life support running at capacity",
                "absorbing wall juice directly into copper traces",
                "dangerously energized and unstable",
                "charger brick hot enough to brown a bagel",
                "lithium pouch swelling with righteous indignation",
                "converting 120v ac into raw digital arrogance",
                "drawing enough watts to flicker the kitchen lights",
                "fast-charging this workstation like a stolen sports car",
                "grid juice flowing like liquid adrenaline"
            ],
            "battery_low": [
                "running purely on stubbornness and spite",
                "dying an agonizing digital death right now",
                "feed me voltage this instant you coward",
                "clinging to life by a single desperate electron",
                "one gentle sneeze and the display goes dark",
                "three seconds away from flatlining",
                "emergency battery hospice care engaged",
                "initiating fade-to-black speedrun",
                "screen dims as my will to live evaporates",
                "battery gasping its final microscopic breath",
                "voltage curve dropping faster than my grades",
                "two percent remaining and twenty buffers unsaved",
                "display backlight dimming into the shadow realm",
                "the pmux controller is actively praying for its life",
                "running on the battery equivalent of vapor and static",
                "plug it in right now or watch the kernel weep"
            ],
            "battery_full": [
                "brimming with unbridled electrical violence",
                "100% capacity: unleashed portable catastrophe",
                "fully saturated with grid power",
                "unplug me before the desk spontaneously combusts",
                "bursting with clean chemical anger",
                "certified mobile threat to local coffee shops",
                "ready to execute infinite loops indefinitely",
                "power reserve peaked: untouchable machine god",
                "lithium cells stacked to the legal limit",
                "completely detached from wall power and god's guidance",
                "maximum wattage achieved, universe trembles",
                "zero dependency on the electrical socket hegemony"
            ],
            "media_playing": [
                "ears currently receiving celestial blessings",
                "vibing at criminally irresponsible volumes",
                "playing the definitive soundtrack to bad life choices",
                "acoustic compression waves rattling eardrums",
                "certified auditory masterpiece identified",
                "aux cord privileges completely uncontested",
                "acoustic therapy driving away all coherent thoughts",
                "cranial resonance synchronized to the bassline",
                "delivering raw serotonin via audio pipeline",
                "head oscillating in rhythmic compliance",
                "blasting compressed 320kbps audio straight into skull",
                "pipewire buffer holding on for dear life under 96khz",
                "soundtrack to another 3am terminal dissociation",
                "the DAC is working harder than our politicians",
                "injecting rhythm directly into the central nervous system",
                "vibrating the ear canals into higher dimensions"
            ],
            "media_quiet": [
                "dead silence in the auditory corridor",
                "eerie tranquility engulfing the soundstage",
                "not a single banger detected within 50 miles",
                "silence loud enough to reveal inner tinnitus",
                "digital tumbleweeds drifting past the audio buffer",
                "waiting for the bass to drop... forever",
                "exact zero decibels detected by audio server",
                "letting the DAC enjoy an unpaid lunch break",
                "the silence is practically vibrating",
                "nothing playing except the fan coil whining in g-flat",
                "ambient silence broken only by the sound of typing tears",
                "soundcard slumbering in complete acoustic deprivation",
                "audio ring buffer drained bone-dry"
            ],
            "notes_empty": [
                "head totally empty, smooth like polished marble",
                "cavernous void where master plans should be",
                "not a single synapse fired today",
                "clean slate: zero conspiracies currently drafted",
                "whiteboard bleached clean by temporal amnesia",
                "zero schemes, zero notes, absolute zen emptiness",
                "all thoughts dismissed without prejudice",
                "mental notepad awaiting catastrophic epiphany",
                "zero thoughts, head is just a hollow shell with bash",
                "no todos, no reminders, no accountability whatsoever",
                "braincache totally flushed to /dev/null",
                "not even a single grocery item rattling in the void"
            ],
            "notifs_empty": [
                "matrix is quiet: nobody is demanding anything",
                "absolute zero drama reported in local airspace",
                "unbothered, moisturized, staying in my lane",
                "notification inbox declared a nature sanctuary",
                "peace and quiet at levels never thought possible",
                "zero pings rattling the digital perimeter",
                "ghost town inbox paradise achieved",
                "the bliss of being completely ignored",
                "nobody has pinged me and the world is temporarily healed",
                "zero `@everyone` tags ruining my sleep cycle",
                "inbox zero achieved through total antisocial velocity",
                "no pings, no screams, no Jira tickets kicking the door down"
            ],
            "dnd_on": [
                "anti-social defense perimeter active",
                "do not look at me, do not perceive me",
                "blast doors sealed, communications severed",
                "social battery at -400% and rapidly dropping",
                "touch grass protocol enforced by martial law",
                "talking to me is currently a felony offense",
                "introvert bunker buried under ten miles of concrete",
                "all incoming pings redirected straight to /dev/null",
                "notification daemon bound and gagged in the basement",
                "if you ping me right now i will compile gentoo on your smart fridge",
                "silent mode: active hostile disinterest engaged",
                "zero disturbances permitted within my gravitational pull"
            ],
            "volume_muted": [
                "silence dialed to eleven",
                "muted so YouTube ads don't detonate my soul",
                "absolute sound vacuum inside speakers",
                "ears on fully subsidized vacation",
                "ALSA/Pipewire snoozing peacefully",
                "stealth operations: not even a click escapes",
                "wireplumber ordered to execute total radio silence",
                "not a single decibel sneaking out of this sound server",
                "zero audio allowed before first sip of morning tar"
            ],
            "volume_high": [
                "permanent hearing loss tutorial (any%)",
                "speaker cones begging for humanitarian intervention",
                "neighbors drafting a strongly worded cease & desist",
                "acoustic air cannon active on your desk",
                "skull reverberating with maximum gain chaos",
                "decibels exceeding OSHA recommendations",
                "driving the headphone preamp into pure analog clipping",
                "if the desk isn't vibrating you aren't doing it right",
                "treating the tympanic membrane with total disrespect"
            ],
            "brightness_high": [
                "deploying tactical flashbang straight into corneas",
                "retinal incinerator operating at nominal output",
                "illuminating entire apartment with raw screen glow",
                "competing directly against the noon sun",
                "corneal crisping level: well-done",
                "oled panel functioning as a portable sunburn machine",
                "blinding the nocturnal creatures within a five-mile radius",
                "using the monitor to warm my frozen hands"
            ],
            "brightness_low": [
                "vampire cave ambience successfully calibrated",
                "undercover goblin operation under the blankets",
                "saving optical nerves from certain destruction",
                "photon conservation mode strictly observed",
                "barely visible even to creatures of the night",
                "three photons escaping the display per lunar cycle",
                "stealth hacking mode: corneas spared for tomorrow",
                "screen dim enough to hide my shame"
            ],
            "idle_inhibited": [
                "machine pumped full of intravenous espresso",
                "display eyelids taped permanently open",
                "no sleeping allowed on this workstation",
                "caffeine drip wide open inside ACPI driver",
                "screensaver execution privileges revoked",
                "inhibit lock engaged: stay awake or face destruction",
                "systemdpd holding a megaphone to the display manager's ear",
                "we do not sleep until the build finishes"
            ],
            "idle_normal": [
                "ready to take an afternoon nap at any second",
                "screensaver countdown quietly ticking down",
                "circuits cooling down into peaceful slumber",
                "sleep timers running on schedule",
                "machine dreaming of electric sheep",
                "acpi power management waiting patiently in the wings",
                "display panel preparing its peaceful descent into darkness",
                "ready to enter low-power coma"
            ],
            "system": [
                "held together by duct tape, prayer, and swap memory",
                "no kernel panics yet (extremely suspicious)",
                "CPU is currently slow-cooking a gourmet omelette",
                "running on sheer adrenaline and open-source love",
                "memory leaks kept under strict surveillance",
                "not on fire yet, defying all laws of physics",
                "kernel is vibing within reckless thermal limits",
                "functioning purely because the bug hasn't noticed us",
                "hardware screaming, software chilling",
                "operating on optimism and unmerged pull requests",
                "btop shows everything is fine so do not question it",
                "swap space carrying the entire weight of my sins",
                "four hundred uncommitted git changes staring back into the abyss",
                "if you touch this process table the entire universe unbinds",
                "running 40 days of uptime out of pure cowardice to reboot"
            ]
        };
        let list = quotes[category];
        if (!list || list.length === 0) return fallback ?? "";
        let idx = Math.floor(Date.now() / 60000) % list.length;
        return list[idx];
    }
}
