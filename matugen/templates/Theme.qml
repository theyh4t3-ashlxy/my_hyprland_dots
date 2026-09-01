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

    // transparent magic so things don't look like concrete
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

    // fonts so text doesn't look like enchantment table hieroglyphs
    readonly property string fontSans:              Settings.fontFamily ? Settings.fontFamily : "Noto Sans"
    readonly property string fontMono:              Settings.fontMono ? Settings.fontMono : "JetBrainsMono Nerd Font"
    readonly property string fontDisplay:           fontSans
    readonly property string fontFamily:            fontSans

    readonly property real   fontScale:             Settings.fontScale ?? 1.0
    readonly property int    fontSizeXs:            Math.round(9 * fontScale)
    readonly property int    fontSizeSm:            Math.round(11 * fontScale)
    readonly property int    fontSizeMd:            Math.round(13 * fontScale)
    readonly property int    fontSizeLg:            Math.round(15 * fontScale)
    readonly property int    fontSizeXl:            Math.round(18 * fontScale)
    readonly property int    fontSizeTitle:         Math.round(22 * fontScale)

    // sizing so we don't end up with microscopic shit
    readonly property int    radiusSm:              2
    readonly property int    radiusMd:              4
    readonly property int    radiusLg:              8
    readonly property int    radiusPill:            9999

    readonly property int    barHeight:             Settings.barHeight ?? 32
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
    readonly property string barStyle:              Settings?.barStyle ?? "glass"
    readonly property color  barBg: {
        let bs = Settings?.barStyle ?? "glass";
        if (bs === "pure-black") return "#000000";
        if (bs === "translucent") return alpha(surface_container_low, 0.72);
        if (bs === "accent-glow") return alpha(primary_container, 0.90);
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
        let cm = Settings?.cornerColorMode ?? "theme";
        if (cm === "pure-black") return "#000000";
        if (cm === "accent") return primary;
        if (cm === "bar") return barBg;
        return background;
    }

    readonly property color  widgetBg: {
        let bs = Settings?.barStyle ?? "glass";
        if (bs === "pure-black") return "#111111";
        if (bs === "translucent") return alpha(surface_container_high, 0.40);
        if (bs === "accent-glow") return alpha(primary_container, 0.55);
        if (bs === "monochrome") return surface_container_high;
        return surface_container_low;
    }
    readonly property color  widgetHover: {
        let bs = Settings?.barStyle ?? "glass";
        if (bs === "pure-black") return "#1c1c1c";
        if (bs === "translucent") return alpha(surface_container_highest, 0.65);
        if (bs === "accent-glow") return alpha(primary, 0.25);
        if (bs === "monochrome") return surface_container_highest;
        return surface_container_highest;
    }
    readonly property color  widgetActive: {
        let bs = Settings?.barStyle ?? "glass";
        if (bs === "pure-black") return "#262626";
        if (bs === "translucent") return alpha(surface_container_highest, 0.85);
        if (bs === "accent-glow") return alpha(primary, 0.40);
        if (bs === "monochrome") return alpha(on_surface, 0.20);
        return surface_container_highest;
    }
    readonly property color  widgetBorder: {
        let bs = Settings?.barStyle ?? "glass";
        if (bs === "pure-black") return "#282828";
        if (bs === "translucent") return alpha(outline_variant, 0.35);
        if (bs === "accent-glow") return alpha(primary, 0.50);
        if (bs === "monochrome") return alpha(outline, 0.4);
        return alpha(outline_variant, 0.5);
    }
    readonly property color  pillBg: {
        let bs = Settings?.barStyle ?? "glass";
        if (bs === "pure-black") return "#121212";
        if (bs === "translucent") return alpha(surface_container_high, 0.45);
        if (bs === "accent-glow") return alpha(primary, 0.16);
        if (bs === "monochrome") return surface_container;
        return surface_container_high;
    }
    readonly property color  pillHover: {
        let bs = Settings?.barStyle ?? "glass";
        if (bs === "pure-black") return "#222222";
        if (bs === "translucent") return alpha(surface_container_highest, 0.70);
        if (bs === "accent-glow") return alpha(primary, 0.28);
        if (bs === "monochrome") return surface_container_highest;
        return surface_container_highest;
    }
    readonly property color  pillBorder: {
        let bs = Settings?.barStyle ?? "glass";
        if (bs === "pure-black") return "#2a2a2a";
        if (bs === "translucent") return alpha(outline_variant, 0.25);
        if (bs === "accent-glow") return alpha(primary, 0.45);
        if (bs === "monochrome") return alpha(outline, 0.35);
        return "transparent";
    }

    readonly property int    popupWidth:            460
    readonly property int    popupHeight:           580
    readonly property int    popupPadding:          16
    readonly property int    popupSpacing:          10
    readonly property int    thumbSize:             180

    // fast transitions so clicking doesn't feel like dial-up
    readonly property real   animSpeedMult:         Settings?.animSpeed === "hyper" ? 0.5 : (Settings?.animSpeed === "chill" ? 1.6 : 1.0)
    readonly property bool   isVertical:            Settings?.barPosition === "left" || Settings?.barPosition === "right"
    readonly property int    animFast:              Math.round(120 * animSpeedMult)
    readonly property int    animNormal:            Math.round(200 * animSpeedMult)
    readonly property int    animSlow:              Math.round(350 * animSpeedMult)
    readonly property var    animEasing:            Easing.OutCubic

    // Icon Set Selection & Dynamic Font
    readonly property string iconSet:               Settings?.iconSet ?? "material"
    readonly property string fontIcon:              (iconSet === "windows") ? "Segoe Fluent Icons" : fontMono

    function getIcon(mat: string, win: string, fa: string): string {
        if (iconSet === "windows") return win;
        if (iconSet === "awesome") return fa;
        return mat;
    }

    // Core System Icons
    readonly property string iconArch:              getIcon("󰣇", "\uE8A9", "")
    readonly property string iconAppLauncher:       iconArch
    readonly property string iconSearch:            getIcon("󰍉", "\uE721", "")
    readonly property string iconClose:             getIcon("󰅖", "\uE8BB", "")
    readonly property string iconCheck:             getIcon("󰄲", "\uE73E", "")
    readonly property string iconCheckCircle:       getIcon("󰄲", "\uE73E", "")
    readonly property string iconSettings:          getIcon("󰒓", "\uE713", "")
    readonly property string iconGear:              iconSettings
    readonly property string iconSave:              getIcon("󰆓", "\uE74E", "")
    readonly property string iconRefresh:           getIcon("󰑐", "\uE72C", "")
    readonly property string iconTrash:             getIcon("󰩹", "\uE74D", "")
    readonly property string iconClipboard:         getIcon("󰅌", "\uE8C8", "")
    readonly property string iconGrid:              getIcon("󰕰", "\uE80A", "")
    readonly property string iconNote:              getIcon("󰏫", "\uE70F", "")
    readonly property string iconCoffee:            getIcon("󰅐", "\uE703", "")
    readonly property string iconClock:             getIcon("󰅐", "\uE823", "")
    readonly property string iconCpu:               getIcon("󰍛", "\uE950", "")
    readonly property string iconMem:               getIcon("󰘚", "\uE950", "")
    readonly property string iconThermo:            getIcon("󰔏", "\uE9CA", "")
    readonly property string iconEye:               getIcon("󰈈", "\uE890", "")
    readonly property string iconEyeOff:            getIcon("󰈉", "\uE891", "")
    readonly property string iconHeart:             getIcon("󰋑", "\uEB51", "")
    readonly property string iconDownload:          getIcon("󰇚", "\uE896", "")
    readonly property string iconFolder:            getIcon("󰉋", "\uE8B7", "")
    readonly property string iconGlobe:             getIcon("󰖟", "\uE774", "")

    // Volume & Audio
    readonly property string iconVolMute:           getIcon("󰝟", "\uE74F", "")
    readonly property string iconVolLow:            getIcon("󰕿", "\uE992", "")
    readonly property string iconVolMid:            getIcon("󰖀", "\uE994", "")
    readonly property string iconVolHigh:           getIcon("󰕾", "\uE767", "")
    readonly property string iconMic:               getIcon("󰍬", "\uE720", "")
    readonly property string iconMicMute:           getIcon("󰍭", "\uE720", "")
    readonly property string iconPalette:           getIcon("󰏘", "\uE790", "")
    readonly property string iconHeadphones:        getIcon("󰋋", "\uE7F6", "")
    readonly property string iconEqualizer:         getIcon("󰎎", "\uE9E9", "󰎎")

    // Battery
    readonly property string iconBatFull:           getIcon("󰁹", "\uE839", "")
    readonly property string iconBatHalf:           getIcon("󰁾", "\uE859", "")
    readonly property string iconBatQuarter:        getIcon("󰁼", "\uE855", "")
    readonly property string iconBatEmpty:          getIcon("󰁺", "\uE850", "")
    readonly property string iconBatCharge:         getIcon("󰂄", "\uE839", "")

    // Display & Brightness
    readonly property string iconSun:               getIcon("󰃠", "\uE706", "")
    readonly property string iconMoon:              getIcon("󰃞", "\uE708", "")
    readonly property string iconBrightness:        iconSun

    // Media & Music
    readonly property string iconMusic:             getIcon("󰝚", "\uE8D6", "")
    readonly property string iconPlay:              getIcon("󰐊", "\uE768", "")
    readonly property string iconPause:             getIcon("󰏤", "\uE769", "")
    readonly property string iconNext:              getIcon("󰒭", "\uE893", "")
    readonly property string iconPrev:              getIcon("󰒮", "\uE892", "")
    readonly property string iconShuffle:           getIcon("󰒝", "\uE8B1", "")
    readonly property string iconRepeat:            getIcon("󰑖", "\uE8EE", "")
    readonly property string iconRepeatOne:         getIcon("󰑘", "\uE8ED", "󰑘")

    // Notifications & Wallpapers
    readonly property string iconWallhaven:         getIcon("󰸉", "\uE91B", "")
    readonly property string iconWallpaper:         getIcon("󰸉", "\uE91B", "")
    readonly property string iconBell:              getIcon("󰂚", "\uEA8F", "")
    readonly property string iconBellOutline:       getIcon("󰂚", "\uEA8F", "")
    readonly property string iconBellOff:           getIcon("󰂛", "\uEC42", "󰂲")

    // Connectivity
    readonly property string iconEthernet:          getIcon("󰈀", "\uEB55", "󰈀")
    readonly property string iconWifi:              getIcon("󰤨", "\uE701", "")
    readonly property string iconWifiHigh:          getIcon("󰤨", "\uEC3E", "")
    readonly property string iconWifiMed:           getIcon("󰤥", "\uEC3C", "")
    readonly property string iconWifiLow:           getIcon("󰤢", "\uEC3A", "")
    readonly property string iconWifiOff:           getIcon("󰤮", "\uEB5E", "󰤮")
    readonly property string iconBluetooth:         getIcon("󰂯", "\uE702", "")
    readonly property string iconBluetoothConnected:getIcon("󰂱", "\uE702", "󰂱")
    readonly property string iconBluetoothOff:      getIcon("󰂲", "\uE702", "󰂲")

    // Power & Session
    readonly property string iconPower:             getIcon("󰐥", "\uE7E8", "")
    readonly property string iconShutdown:          iconPower
    readonly property string iconLock:              getIcon("󰌾", "\uE72E", "")
    readonly property string iconLogout:            getIcon("󰍃", "\uF3B1", "")
    readonly property string iconReboot:            getIcon("󰑐", "\uE72C", "")
    readonly property string iconSuspend:           getIcon("󰤄", "\uE708", "")
    readonly property string iconHibernate:         getIcon("󰒲", "\uE708", "")

    // Navigation & Chevrons
    readonly property string iconChevronRight:      getIcon("󰅂", "\uE76C", "")
    readonly property string iconChevronLeft:       getIcon("󰅁", "\uE76B", "")
    readonly property string iconChevronDown:       getIcon("󰅀", "\uE70D", "")
    readonly property string iconChevronUp:         getIcon("󰅃", "\uE70E", "")
    readonly property string iconFlame:             getIcon("󰈸", "\uE7E8", "")
    readonly property string iconSparkles:          getIcon("󰓏", "\uE7C5", "󰓏")
    readonly property string iconRadio:             getIcon("󰐹", "\uE8D6", "󰐹")
    readonly property string iconSliders:           getIcon("󰝚", "\uE9E9", "󰝚")
    readonly property string iconTerminal:          getIcon("", "\uE756", "")

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
}

