pragma Singleton
import QtQuick

QtObject {
    // matugen color soup that burns my retinas
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

    // transparent magic so things dont look like concrete
    function alpha(c: color, a: real): color { return Qt.rgba(c.r, c.g, c.b, a) }

    readonly property color primary_overlay:        alpha(primary, 0.18)
    readonly property color secondary_overlay:      alpha(secondary, 0.18)
    readonly property color tertiary_overlay:       alpha(tertiary, 0.18)
    readonly property color error_overlay:          alpha(error, 0.22)
    readonly property color warn:                   tertiary
    readonly property color warn_container:         tertiary_container
    readonly property color on_warn_container:      on_tertiary_container
    readonly property color warn_overlay:           tertiary_overlay

    // so disabled buttons actually look dead
    readonly property color on_surface_disabled:    alpha(on_surface, 0.38)
    readonly property color outline_disabled:       alpha(outline, 0.12)
    readonly property color fontStrokeColor:        "#000000"
    readonly property color textStroke:             "#000000"
    readonly property color textShadow:             "#000000"

    // fonts so text doesnt look like enchantment table hieroglyphs
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

    // sizing so we dont end up with microscopic shit
    readonly property int    radiusSm:              2
    readonly property int    radiusMd:              4
    readonly property int    radiusLg:              8
    readonly property int    radiusPill:            9999

    readonly property int    barHeight:             Settings?.barHeight ?? 32
    readonly property int    barRadius:             0
    readonly property int    widgetRadius:          radiusSm
    readonly property int    popupRadius:           radiusMd
    readonly property int    widgetSpacing:         4
    readonly property int    widgetPaddingH:        8
    readonly property int    widgetPaddingV:        0

    readonly property int    scoopRadiusX:          Settings?.scoopRadius ?? 16
    readonly property int    scoopRadiusY:          Settings?.scoopRadius ?? 16
    readonly property real   scoopTension:          Settings?.scoopTension ?? 0.5522847498307936
    readonly property string scoopStyle:            Settings?.cornerStyle ?? "cubic"
    readonly property int    screenCornerRadius:    Settings?.screenCornerRadius ?? 16
    readonly property string screenCornerMode:      Settings?.screenCornerMode ?? "all"
    readonly property string cornerColorMode:       Settings?.cornerColorMode ?? "bar"
    readonly property string barStyle:              Settings?.barStyle ?? "glass"
    readonly property color  barBg: {
        let bs = Settings?.barStyle ?? "glass";
        if (bs === "pure-black") return "#000000";
        if (bs === "translucent") return alpha(surface_container_low, 0.72);
        if (bs === "accent-glow") return alpha(surface_container_lowest, 0.90);
        if (bs === "monochrome") return surface_container_highest;
        return surface_container_low;
    }
    readonly property color  barBorderColor: {
        let bs = Settings?.barStyle ?? "glass";
        if (bs === "pure-black") return "#282828";
        if (bs === "accent-glow") return primary;
        if (bs === "translucent") return alpha(outline_variant, 0.35);
        return widgetBorder;
    }

    readonly property color  cornerFill: {
        let cm = Settings?.cornerColorMode ?? "bar";
        if (cm === "bar") return barBg;
        if (cm === "accent") return primary;
        if (cm === "pure-black") return "#000000";
        if (cm === "theme") return surface_container_high;
        return barBg;
    }

    readonly property color  widgetBg: {
        let bs = Settings?.barStyle ?? "glass";
        if (bs === "pure-black") return "#111111";
        if (bs === "translucent") return alpha(surface_container_high, 0.40);
        if (bs === "accent-glow") return alpha(primary_container, 0.65);
        if (bs === "monochrome") return surface_container_high;
        return surface_container_low;
    }
    readonly property color  widgetHover: {
        let bs = Settings?.barStyle ?? "glass";
        if (bs === "pure-black") return "#1c1c1c";
        if (bs === "translucent") return alpha(surface_container_highest, 0.65);
        if (bs === "accent-glow") return alpha(primary, 0.35);
        if (bs === "monochrome") return surface_container_highest;
        return surface_container_highest;
    }
    readonly property color  widgetActive: {
        let bs = Settings?.barStyle ?? "glass";
        if (bs === "pure-black") return "#262626";
        if (bs === "translucent") return alpha(surface_container_highest, 0.85);
        if (bs === "accent-glow") return alpha(primary, 0.55);
        if (bs === "monochrome") return alpha(on_surface, 0.20);
        return surface_container_highest;
    }
    readonly property color  widgetBorder: {
        let bs = Settings?.barStyle ?? "glass";
        if (bs === "pure-black") return "#282828";
        if (bs === "translucent") return alpha(outline_variant, 0.35);
        if (bs === "accent-glow") return alpha(primary, 0.70);
        if (bs === "monochrome") return alpha(outline, 0.4);
        return alpha(outline_variant, 0.5);
    }
    readonly property color  popupBg: {
        let bs = Settings?.barStyle ?? "glass";
        if (bs === "pure-black") return "#0a0a0a";
        if (bs === "translucent") return alpha(surface_container_low, 0.82);
        if (bs === "accent-glow") return alpha(surface_container_lowest, 0.95);
        if (bs === "monochrome") return surface_container_low;
        return surface_container_low;
    }
    readonly property color  popupBorderColor: {
        let bs = Settings?.barStyle ?? "glass";
        if (bs === "pure-black") return "#282828";
        if (bs === "translucent") return alpha(outline_variant, 0.40);
        if (bs === "accent-glow") return alpha(primary, 0.85);
        if (bs === "monochrome") return alpha(outline, 0.45);
        return widgetBorder;
    }
    readonly property color  cardBg: {
        let bs = Settings?.barStyle ?? "glass";
        if (bs === "pure-black") return "#111111";
        if (bs === "translucent") return alpha(surface_container_high, 0.50);
        if (bs === "accent-glow") return alpha(primary_container, 0.55);
        if (bs === "monochrome") return surface_container_high;
        return surface_container_high;
    }
    readonly property color  cardBorder: {
        let bs = Settings?.barStyle ?? "glass";
        if (bs === "pure-black") return "#222222";
        if (bs === "translucent") return alpha(outline_variant, 0.30);
        if (bs === "accent-glow") return alpha(primary, 0.60);
        if (bs === "monochrome") return alpha(outline, 0.35);
        return widgetBorder;
    }
    readonly property color  pillBg: {
        let bs = Settings?.barStyle ?? "glass";
        if (bs === "pure-black") return "#121212";
        if (bs === "translucent") return alpha(surface_container_high, 0.45);
        if (bs === "accent-glow") return alpha(primary, 0.22);
        if (bs === "monochrome") return surface_container;
        return surface_container_high;
    }
    readonly property color  pillHover: {
        let bs = Settings?.barStyle ?? "glass";
        if (bs === "pure-black") return "#222222";
        if (bs === "translucent") return alpha(surface_container_highest, 0.70);
        if (bs === "accent-glow") return alpha(primary, 0.40);
        if (bs === "monochrome") return surface_container_highest;
        return surface_container_highest;
    }
    readonly property color  pillBorder: {
        let bs = Settings?.barStyle ?? "glass";
        if (bs === "pure-black") return "#2a2a2a";
        if (bs === "translucent") return alpha(outline_variant, 0.25);
        if (bs === "accent-glow") return alpha(primary, 0.85);
        if (bs === "monochrome") return alpha(outline, 0.35);
        return "transparent";
    }

    readonly property int    popupWidth:            460
    readonly property int    popupHeight:           580
    readonly property int    popupPadding:          16
    readonly property int    popupSpacing:          10
    readonly property int    thumbSize:             180

    // fast transitions so clicking doesnt feel like dial-up
    readonly property real   animSpeedMult:         Settings?.animSpeed === "instant" ? 0.01 : (Settings?.animSpeed === "snappy" ? 0.7 : (Settings?.animSpeed === "hyper" ? 0.4 : (Settings?.animSpeed === "chill" ? 1.6 : 1.0)))
    readonly property bool   isVertical:            Settings?.barPosition === "left" || Settings?.barPosition === "right"
    readonly property int    animFast:              Math.round(120 * animSpeedMult)
    readonly property int    animNormal:            Math.round(200 * animSpeedMult)
    readonly property int    animSlow:              Math.round(350 * animSpeedMult)
    readonly property var    animEasing:            Easing.OutCubic

    readonly property string iconSet:               Settings?.iconSet ?? "material"
    readonly property string fontIcon: {
        if (iconSet === "kaomoji" || iconSet === "text") return fontFamily;
        if (iconSet === "windows") return Settings?.fontWindows ?? "Segoe Fluent Icons";
        if (iconSet === "awesome") {
            let families = Qt.fontFamilies();
            let target = Settings?.fontAwesome ?? "Font Awesome 6 Free";
            if (families.indexOf(target) >= 0) return target;
            return fontMono;
        }
        return Settings?.fontIcon ?? fontMono;
    }

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
        "save": "(💾)",
        "refresh": "(↺)",
        "trash": "(🗑)",
        "clipboard": "(📋)",
        "grid": "[#]",
        "note": "(✎)",
        "edit": "(✎)",
        "coffee": "(旦)",
        "clock": "(🕒)",
        "cpu": "[cpu]",
        "mem": "[ram]",
        "thermo": "[°C]",
        "eye": "(•‿•)",
        "eyeOff": "(-_-)",
        "heart": "(♥)",
        "download": "(↓)",
        "folder": "[dir]",
        "globe": "(🌐)",
        "volMute": "(-_-)",
        "volLow": "(・ω・)",
        "volMid": "(ᵔᴥᵔ)",
        "volHigh": "(≧◡≦)",
        "mic": "(🎙)",
        "micMute": "(x_x)",
        "palette": "(🎨)",
        "headphones": "(🎧)",
        "equalizer": "|||",
        "batFull": "(◕‿◕)",
        "batHalf": "(・_・)",
        "batQuarter": "(>_<)",
        "batEmpty": "(×_×)",
        "batCharge": "(⚡^⚡)",
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
        "wallhaven": "(🖼)",
        "wallpaper": "(🖼)",
        "bell": "(🔔)",
        "bellOutline": "(🔔)",
        "bellOff": "(🔕)",
        "ethernet": "[eth]",
        "wifi": "(•̀ᴗ•́)و",
        "wifiHigh": "(•̀ᴗ•́)و",
        "wifiMed": "(・_・)",
        "wifiLow": "( ;¬_¬)",
        "wifiOff": "(×_×)",
        "bluetooth": "(⚡)",
        "bluetoothConnected": "(•̀ᴗ•́)و",
        "bluetoothOff": "(×_×)",
        "power": "(⏻)",
        "shutdown": "(⏻)",
        "lock": "(🔒)",
        "logout": "(bye)",
        "reboot": "(↺)",
        "suspend": "(zzz)",
        "hibernate": "(❄)",
        "chevronRight": ">",
        "chevronLeft": "<",
        "chevronDown": "v",
        "chevronUp": "^",
        "flame": "(🔥)",
        "sparkles": "(✨)",
        "radio": "(📻)",
        "sliders": "[=]",
        "terminal": "[>_]",
        "calendar": "(📅)",
        "history": "(↺)",
        "copy": "[cp]",
        "externalLink": "(->)",
        "signal": "(📶)",
        "filter": "[/]",
        "user": "(👤)",
        "shield": "[#]",
        "expand": "[+]",
        "collapse": "[-]"
    })

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
        if (iconSet === "windows") return win;
        if (iconSet === "awesome") return fa;
        return mat;
    }

    function getBatteryIcon(pct: int, isCharging: bool, isSaver: bool, isVertical: bool): string {
        let p = (pct === undefined || pct === null || isNaN(pct)) ? -1 : Math.max(0, Math.min(100, Math.round(pct)));
        let lvl = p < 0 ? -1 : Math.min(10, Math.floor(p / 10));

        if (iconSet === "kaomoji") {
            if (isCharging) return "(⚡^⚡)";
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

        // default: material / nerd font
        if (lvl < 0) return "󰂎";
        if (isCharging) {
            const matCharging = ["󰢟", "󰢜", "󰂆", "󰂇", "󰂈", "󰢝", "󰂉", "󰢞", "󰂊", "󰂋", "󰂅"];
            return matCharging[lvl];
        }
        const matDischarging = ["󰂎", "󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"];
        return matDischarging[lvl];
    }

    function getVolumeIcon(volRatio: real, isMuted: bool): string {
        if (isMuted || volRatio <= 0.001) {
            return (iconSet === "kaomoji") ? "(-_-)" : (iconSet === "text") ? "mute" : iconVolMute;
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
        if (iconSet === "windows") {
            if (pct <= 33) return "\uE993";
            if (pct <= 66) return "\uE994";
            return "\uE995";
        }
        if (iconSet === "awesome") {
            if (pct <= 50) return "";
            return "";
        }
        if (pct <= 33) return "󰕿";
        if (pct <= 66) return "󰖀";
        return "󰕾";
    }

    function getWifiIcon(signalPct: int, isConnected: bool, isEthernet: bool): string {
        if (isEthernet) return (iconSet === "kaomoji") ? "[eth]" : (iconSet === "text") ? "eth" : iconEthernet;
        if (!isConnected) return (iconSet === "kaomoji") ? "(×_×)" : (iconSet === "text") ? "off" : iconWifiOff;
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
        if (iconSet === "windows") {
            if (sig < 35) return "\uE872";
            if (sig < 70) return "\uE873";
            return "\uE874";
        }
        if (iconSet === "awesome") {
            return "";
        }
        if (sig < 35) return "󰤢";
        if (sig < 70) return "󰤥";
        return "󰤨";
    }

    readonly property string iconArch:              getIcon("󰣇", "\uE700", "", "arch")
    readonly property string iconAppLauncher:       iconArch
    readonly property string iconWorkspaces:        getIcon("󰍹", "\uF0E2", "", "workspaces")
    readonly property string iconSearch:            getIcon("󰍉", "\uE721", "", "search")
    readonly property string iconClose:             getIcon("󰅖", "\uE711", "", "close")
    readonly property string iconCheck:             getIcon("󰄬", "\uE73E", "", "check")
    readonly property string iconCheckCircle:       getIcon("󰄲", "\uF13E", "", "checkCircle")
    readonly property string iconSettings:          getIcon("󰒓", "\uE713", "", "settings")
    readonly property string iconGear:              iconSettings
    readonly property string iconSave:              getIcon("󰆓", "\uE74E", "", "save")
    readonly property string iconRefresh:           getIcon("󰑐", "\uE895", "", "refresh")
    readonly property string iconTrash:             getIcon("󰩹", "\uE74D", "", "trash")
    readonly property string iconClipboard:         getIcon("󰅌", "\uF0E3", "", "clipboard")
    readonly property string iconGrid:              getIcon("󰕰", "\uE74C", "", "grid")
    readonly property string iconNote:              getIcon("󰏫", "\uE70F", "", "note")
    readonly property string iconEdit:              iconNote
    readonly property string iconCoffee:            getIcon("󰅠", "\uE703", "", "coffee")
    readonly property string iconClock:             getIcon("󰅐", "\uEC92", "", "clock")
    readonly property string iconCpu:               getIcon("󰍛", "\uE9F5", "", "cpu")
    readonly property string iconMem:               getIcon("󰘚", "\uE772", "", "mem")
    readonly property string iconThermo:            getIcon("󰔏", "\uE9CA", "", "thermo")
    readonly property string iconEye:               getIcon("󰈈", "\uE890", "", "eye")
    readonly property string iconEyeOff:            getIcon("󰈉", "\uED1A", "", "eyeOff")
    readonly property string iconHeart:             getIcon("󰋑", "\uEB51", "", "heart")
    readonly property string iconDownload:          getIcon("󰇚", "\uE896", "", "download")
    readonly property string iconFolder:            getIcon("󰉋", "\uE838", "", "folder")
    readonly property string iconGlobe:             getIcon("󰖟", "\uE774", "", "globe")

    readonly property string iconVolMute:           getIcon("󰝟", "\uE74F", "", "volMute")
    readonly property string iconVolLow:            getIcon("󰕿", "\uE992", "", "volLow")
    readonly property string iconVolMid:            getIcon("󰖀", "\uE994", "", "volMid")
    readonly property string iconVolHigh:           getIcon("󰕾", "\uE767", "", "volHigh")
    readonly property string iconMic:               getIcon("󰍬", "\uE720", "", "mic")
    readonly property string iconMicMute:           getIcon("󰍭", "\uF781", "", "micMute")
    readonly property string iconPalette:           getIcon("󰏘", "\uE790", "", "palette")
    readonly property string iconHeadphones:        getIcon("󰋋", "\uE7F6", "", "headphones")
    readonly property string iconEqualizer:         getIcon("󰎎", "\uE9E9", "", "equalizer")

    readonly property string iconBatFull:           getIcon("󰁹", "\uE83F", "", "batFull")
    readonly property string iconBatHalf:           getIcon("󰁾", "\uE855", "", "batHalf")
    readonly property string iconBatQuarter:        getIcon("󰁼", "\uE852", "", "batQuarter")
    readonly property string iconBatEmpty:          getIcon("󰁺", "\uE850", "", "batEmpty")
    readonly property string iconBatCharge:         getIcon("󰂄", "\uE83E", "", "batCharge")

    readonly property string iconSun:               getIcon("󰃠", "\uE706", "", "sun")
    readonly property string iconMoon:              getIcon("󰃞", "\uE708", "", "moon")
    readonly property string iconBrightness:        iconSun

    readonly property string iconMusic:             getIcon("󰝚", "\uE8D6", "", "music")
    readonly property string iconPlay:              getIcon("󰐊", "\uE768", "", "play")
    readonly property string iconPause:             getIcon("󰏤", "\uE769", "", "pause")
    readonly property string iconNext:              getIcon("󰒭", "\uE893", "", "next")
    readonly property string iconPrev:              getIcon("󰒮", "\uE892", "", "prev")
    readonly property string iconShuffle:           getIcon("󰒝", "\uE8B1", "", "shuffle")
    readonly property string iconRepeat:            getIcon("󰑖", "\uE8EE", "", "repeat")
    readonly property string iconRepeatOne:         getIcon("󰑘", "\uE8ED", "", "repeatOne")

    readonly property string iconWallhaven:         getIcon("󰸉", "\uE91B", "", "wallhaven")
    readonly property string iconWallpaper:         getIcon("󰸉", "\uE91B", "", "wallpaper")
    readonly property string iconBell:              getIcon("󰂙", "\uE7E7", "", "bell")
    readonly property string iconBellOutline:       getIcon("󰂚", "\uE7E7", "", "bellOutline")
    readonly property string iconBellOff:           getIcon("󰂛", "\uEE79", "", "bellOff")

    readonly property string iconEthernet:          getIcon("󰈀", "\uE839", "", "ethernet")
    readonly property string iconWifi:              getIcon("󰤨", "\uE701", "", "wifi")
    readonly property string iconWifiHigh:          getIcon("󰤨", "\uE874", "", "wifiHigh")
    readonly property string iconWifiMed:           getIcon("󰤥", "\uE873", "", "wifiMed")
    readonly property string iconWifiLow:           getIcon("󰤢", "\uE872", "", "wifiLow")
    readonly property string iconWifiOff:           getIcon("󰤮", "\uE998", "", "wifiOff")
    readonly property string iconBluetooth:         getIcon("󰂯", "\uE702", "", "bluetooth")
    readonly property string iconBluetoothConnected:getIcon("󰂱", "\uE702", "", "bluetoothConnected")
    readonly property string iconBluetoothOff:      getIcon("󰂲", "\uE702", "", "bluetoothOff")

    readonly property string iconPower:             getIcon("󰐥", "\uE7E8", "", "power")
    readonly property string iconShutdown:          iconPower
    readonly property string iconLock:              getIcon("󰌾", "\uE72E", "", "lock")
    readonly property string iconLogout:            getIcon("󰍃", "\uF3B1", "", "logout")
    readonly property string iconReboot:            getIcon("󰑐", "\uE895", "", "reboot")
    readonly property string iconSuspend:           getIcon("󰤄", "\uE708", "", "suspend")
    readonly property string iconHibernate:         getIcon("󰒲", "\uE708", "", "hibernate")

    readonly property string iconChevronRight:      getIcon("󰅂", "\uE974", "", "chevronRight")
    readonly property string iconChevronLeft:       getIcon("󰅁", "\uE973", "", "chevronLeft")
    readonly property string iconChevronDown:       getIcon("󰅀", "\uE972", "", "chevronDown")
    readonly property string iconChevronUp:         getIcon("󰅃", "\uE70E", "", "chevronUp")
    readonly property string iconFlame:             getIcon("󰈸", "\uE7E8", "", "flame")
    readonly property string iconSparkles:          getIcon("󰓏", "\uE7C5", "", "sparkles")
    readonly property string iconRadio:             getIcon("󰐹", "\uE8D6", "", "radio")
    readonly property string iconSliders:           getIcon("󰘮", "\uE9E9", "", "sliders")
    readonly property string iconTerminal:          getIcon("󰆍", "\uE756", "", "terminal")
    readonly property string iconCalendar:          getIcon("󰸉", "\uE787", "", "calendar")
    readonly property string iconHistory:           getIcon("󰋚", "\uE81C", "", "history")
    readonly property string iconCopy:              getIcon("󰆏", "\uE8C8", "", "copy")
    readonly property string iconExternalLink:      getIcon("󰌹", "\uE8A7", "", "externalLink")
    readonly property string iconSignal:            getIcon("󰈀", "\uE874", "", "signal")
    readonly property string iconFilter:            getIcon("󰈲", "\uE71C", "", "filter")
    readonly property string iconUser:              getIcon("󰄛", "\uE77B", "", "user")
    readonly property string iconShield:            getIcon("󰞌", "\uEA18", "", "shield")
    readonly property string iconExpand:            getIcon("󰁌", "\uE740", "", "expand")
    readonly property string iconCollapse:          getIcon("󰁋", "\uE73F", "", "collapse")

    // kaomojis without emoji junk
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
    readonly property string kaoSleepy:             "(-.-)Zzz"
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
    readonly property string kaoVibe:               "( ˘ ³˘)♥"
    readonly property string kaoJam:                "(~‾▿‾)~"
    readonly property string kaoDJ:                 "(ノ^_^)ノ"
    readonly property string kaoSilent:             "( ˙-˙ )"
    readonly property string kaoCozy:               "(っ˘ω˘ς)"
    readonly property string kaoCheer:              "(ﾉ>ω<)ﾉ :｡･:*:･ﾟ"
    readonly property string kaoSmug:               "( ˘⌣˘ )"
    readonly property string kaoFire:               "(ง🔥Д🔥)ง"
    readonly property string kaoSparkle:            "(★ω★)"
    readonly property string kaoTableFlip:          "(╯°□°)╯︵ ┻━┻"
    readonly property string kaoPutBack:            "┬─┬ノ( º _ ºノ)"

    function getVibe(kao: string, nerd: string, text: string): string {
        let style = Settings?.vibeStyle ?? "nerd";
        if (style === "kaomoji") return kao;
        if (style === "nerd") return nerd;
        return text ?? "";
    }

    // unhinged flavor generator for contextual system quotes
    function getFlavor(category: string, fallback: string): string {
        if (!Settings?.unhingedFlavor) return fallback ?? "";
        let quotes = {
            "network_on": [
                "beaming photons into brain",
                "locked into the grid",
                "surveillance feed online",
                "5G brain waves active"
            ],
            "network_off": [
                "off the grid, touching grass",
                "wifi machine broke",
                "radio silence",
                "airgapped paranoia"
            ],
            "battery_charging": [
                "injecting pure voltage",
                "drinking from the wall",
                "fast charging go brrr"
            ],
            "battery_low": [
                "running on fumes",
                "im literally dying",
                "plug me in coward"
            ],
            "battery_full": [
                "overflowing with juice",
                "100% pure power",
                "ready for chaos"
            ],
            "media_quiet": [
                "dead silence",
                "eerie calm",
                "no bangers playing"
            ],
            "notes_empty": [
                "head empty, no thoughts",
                "void of ideas",
                "not a single braincell"
            ],
            "system": [
                "barely holding together",
                "no crashes yet (suspicious)",
                "kernel is vibing"
            ]
        };
        let list = quotes[category];
        if (!list || list.length === 0) return fallback ?? "";
        let idx = Math.floor(Date.now() / 60000) % list.length;
        return list[idx];
    }
}
