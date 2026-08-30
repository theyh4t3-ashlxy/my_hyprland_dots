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
    readonly property string screenCornerMode:      Settings?.screenCornerMode ?? "all"
    readonly property string cornerColorMode:       Settings?.cornerColorMode ?? "theme"
    readonly property color  cornerFill:            cornerColorMode === "pure-black" ? "#000000" : (cornerColorMode === "bar" ? surface_container_low : (cornerColorMode === "accent" ? primary : background))

    readonly property color  widgetBg:              surface_container_low
    readonly property color  widgetHover:           surface_container_high
    readonly property color  widgetActive:          surface_container_highest
    readonly property color  widgetBorder:          alpha(outline_variant, 0.5)

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

    // nerd font glyphs so things don't look like an empty terminal
    readonly property string iconArch:              ""
    readonly property string iconCpu:               ""
    readonly property string iconMem:               ""
    readonly property string iconThermo:            ""
    readonly property string iconCoffee:            ""
    readonly property string iconClock:             ""
    readonly property string iconAppLauncher:       ""
    readonly property string iconGrid:              ""
    readonly property string iconNote:              ""
    readonly property string iconClipboard:         ""
    readonly property string iconSearch:            ""
    readonly property string iconClose:             ""
    readonly property string iconCheck:             ""
    readonly property string iconCheckCircle:       ""
    readonly property string iconTrash:             ""
    readonly property string iconSettings:          ""
    readonly property string iconGear:              iconSettings
    readonly property string iconSave:              ""
    readonly property string iconRefresh:           ""
    readonly property string iconEye:               ""
    readonly property string iconEyeOff:            ""
    readonly property string iconHeart:             ""
    readonly property string iconHeartbeat:         ""
    readonly property string iconDownload:          ""
    readonly property string iconFolder:            ""
    readonly property string iconGlobe:             ""
    readonly property string iconForward:           ""

    // Volume & Audio
    readonly property string iconVolMute:           "󰝟"
    readonly property string iconVolLow:            ""
    readonly property string iconVolMid:            ""
    readonly property string iconVolHigh:           ""
    readonly property string iconMic:               ""
    readonly property string iconMicMute:           ""
    readonly property string iconPalette:           ""

    // Battery
    readonly property string iconBatFull:           ""
    readonly property string iconBatHalf:           ""
    readonly property string iconBatQuarter:        ""
    readonly property string iconBatEmpty:          ""
    readonly property string iconBatCharge:         ""

    // Display & Brightness
    readonly property string iconSun:               ""
    readonly property string iconMoon:              ""
    readonly property string iconBrightness:        iconSun

    // Media & Music
    readonly property string iconMusic:             ""
    readonly property string iconPlay:              ""
    readonly property string iconPause:             ""
    readonly property string iconNext:              ""
    readonly property string iconPrev:              ""
    readonly property string iconShuffle:           ""
    readonly property string iconRepeat:            ""
    readonly property string iconRepeatOne:         "󰑘"

    // Notifications & Wallpapers
    readonly property string iconWallhaven:         ""
    readonly property string iconWallpaper:         ""
    readonly property string iconBell:              ""
    readonly property string iconBellOutline:       ""
    readonly property string iconBellOff:           "󰂲"

    // Connectivity
    readonly property string iconEthernet:          "󰈀"
    readonly property string iconWifi:              ""
    readonly property string iconWifiHigh:          "󰤨"
    readonly property string iconWifiMed:           "󰤥"
    readonly property string iconWifiLow:           "󰤟"
    readonly property string iconWifiOff:           "󰤮"
    readonly property string iconBluetooth:         ""
    readonly property string iconBluetoothConnected:"󰂱"
    readonly property string iconBluetoothOff:      "󰂲"

    // Power & Session
    readonly property string iconPower:             ""
    readonly property string iconShutdown:          iconPower
    readonly property string iconLock:              ""
    readonly property string iconLogout:            ""
    readonly property string iconReboot:            ""
    readonly property string iconSuspend:           ""
    readonly property string iconHibernate:         ""

    // Navigation & Chevrons
    readonly property string iconChevronRight:      ""
    readonly property string iconChevronLeft:       ""
    readonly property string iconChevronDown:       ""
    readonly property string iconChevronUp:         ""

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
}

