import QtQuick
import QtQuick.Layouts
import ".."
import "../controls"
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io

PanelWindow {
    id: root

    required property var modelData
    screen: modelData

    readonly property bool isPrimaryScreen: !screen || (Quickshell.screens && Quickshell.screens.length > 0 && screen === Quickshell.screens[0])
    readonly property bool isOpen: (Settings.showWelcomeWizard ?? false) && isPrimaryScreen

    property int currentStep: 0
    readonly property int totalSteps: 5

    // Detect if Brain_Shell is present on the filesystem
    readonly property string brainShellSrc: Quickshell.env("HOME") + "/.local/src/Brain_Shell"
    readonly property string brainShellConf: Quickshell.env("HOME") + "/.config/Brain_Shell"
    property bool brainShellDetected: false

    function checkBrainShell() {
        Quickshell.execDetached(["bash", "-c", "if [ -d '" + brainShellSrc + "' ] || [ -d '" + brainShellConf + "' ]; then touch /tmp/qs_brain_detected.tmp; else rm -f /tmp/qs_brain_detected.tmp; fi"]);
    }

    property FileView brainCheckFile: FileView {
        path: "/tmp/qs_brain_detected.tmp"
        watchChanges: true
        printErrors: false
        onFileChanged: {
            root.brainShellDetected = true;
        }
        onLoaded: {
            root.brainShellDetected = true;
        }
        onLoadFailed: {
            root.brainShellDetected = false;
        }
    }

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: "transparent"
    visible: animReveal > 0.001
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell:popup:welcome"
    WlrLayershell.keyboardFocus: isOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    property real animReveal: isOpen ? 1.0 : 0.0
    Behavior on animReveal {
        NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
    }


    function close() {
        Settings.showWelcomeWizard = false;
        if (!Settings.hasCompletedWelcome) {
            Settings.hasCompletedWelcome = true;
            Settings.save();
        }
    }

    function completeSetup() {
        Settings.hasCompletedWelcome = true;
        Settings.save();
        Settings.showWelcomeWizard = false;
        Quickshell.execDetached([
            "notify-send",
            "-a", "Quickshell",
            "-i", "preferences-desktop-theme",
            "Welcome Aboard!",
            "“follow the user, not the shell” • Your desktop is calibrated and ready."
        ]);
    }

    onIsOpenChanged: {
        if (isOpen) {
            currentStep = 0;
            checkBrainShell();
        }
    }

    Component.onCompleted: {
        checkBrainShell();
    }

    Item {
        anchors.fill: parent
        focus: root.isOpen
        opacity: root.animReveal

        Keys.onEscapePressed: root.close()
        Keys.onRightPressed: if (root.currentStep < root.totalSteps - 1) root.currentStep++
        Keys.onLeftPressed: if (root.currentStep > 0) root.currentStep--

        // Backdrop Dimming / Scrim
        Rectangle {
            anchors.fill: parent
            color: Theme.scrim ?? "#000000"
            opacity: 0.68 * root.animReveal

            MouseArea {
                anchors.fill: parent
                onClicked: root.close()
            }
        }

        // Centered Dialog Card
        Rectangle {
            id: dialogCard
            width: Math.min(820, Math.max(640, (root.screen?.width ?? 1920) - 64))
            height: Math.min(600, Math.max(500, (root.screen?.height ?? 1080) - 80))
            anchors.centerIn: parent

            radius: Math.max(16, Settings?.globalRounding ?? 16)
            color: Theme.surface_container ?? Theme.cardBackground
            border.color: Theme.outline_variant ?? Theme.cardBorder
            border.width: 1
            clip: true

            scale: 0.94 + (0.06 * root.animReveal)
            Behavior on scale {
                NumberAnimation { duration: 240; easing.type: Easing.OutBack }
            }

            // Catch clicks inside dialog so scrim doesn't close it
            MouseArea {
                anchors.fill: parent
            }

            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                // ── 1. DIALOG HEADER ──────────────────────────────────────────
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 64
                    color: Theme.surface_container_high ?? Theme.surface_container
                    border.color: Theme.outline_variant ?? Theme.cardBorder
                    border.width: 0

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 20
                        anchors.rightMargin: 16
                        spacing: 12

                        Rectangle {
                            width: 38
                            height: 38
                            radius: Theme.radiusMd
                            color: Theme.primary_container

                            Text {
                                anchors.centerIn: parent
                                text: Theme.iconSparkles
                                font.family: Theme.fontIcon
                                font.pixelSize: Theme.fontSizeLg
                                color: Theme.on_primary_container
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1

                            RowLayout {
                                spacing: 8

                                Text {
                                    text: "Ashley's Desktop Environment"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSizeMd
                                    font.weight: Theme.fontWeightBold
                                    color: Theme.on_surface
                                }

                                Rectangle {
                                    height: 18
                                    width: badgeText.implicitWidth + 10
                                    radius: Theme.radiusPill
                                    color: Theme.alpha(Theme.primary, 0.14)

                                    Text {
                                        id: badgeText
                                        anchors.centerIn: parent
                                        text: "first-time setup"
                                        font.family: Theme.fontMono
                                        font.pixelSize: Theme.fontSizeXs - 1
                                        font.weight: Theme.fontWeightBold
                                        color: Theme.primary
                                    }
                                }
                            }

                            Text {
                                text: "“follow the user, not the shell”"
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeXs
                                font.italic: true
                                color: Theme.on_surface_variant
                            }
                        }

                        // Close / Skip Button
                        Rectangle {
                            width: 32
                            height: 32
                            radius: Theme.radiusPill
                            color: closeMouse.containsMouse ? Theme.surface_container_highest : "transparent"

                            Text {
                                anchors.centerIn: parent
                                text: Theme.iconClose
                                font.family: Theme.fontIcon
                                font.pixelSize: Theme.fontSizeSm
                                color: Theme.on_surface_variant
                            }

                            MouseArea {
                                id: closeMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.close()
                            }
                        }
                    }

                    // Bottom divider
                    Rectangle {
                        anchors.bottom: parent.bottom
                        width: parent.width
                        height: 1
                        color: Theme.outline_variant ?? Theme.cardBorder
                    }
                }

                // ── 2. STEP BREADCRUMB STRIP ──────────────────────────────────
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 40
                    color: Theme.surface_container_lowest ?? "transparent"

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 20
                        anchors.rightMargin: 20
                        spacing: 6

                        Repeater {
                            model: [
                                { label: "1. Philosophy", step: 0 },
                                { label: "2. Aesthetics", step: 1 },
                                { label: "3. Brain_Shell", step: 2 },
                                { label: "4. Keybinds", step: 3 },
                                { label: "5. Ready", step: 4 }
                            ]

                            delegate: Rectangle {
                                required property var modelData
                                Layout.fillWidth: true
                                height: 26
                                radius: Theme.radiusPill
                                readonly property bool isActive: root.currentStep === modelData.step
                                readonly property bool isPassed: root.currentStep > modelData.step

                                color: isActive
                                    ? Theme.primary
                                    : (isPassed ? Theme.alpha(Theme.primary, 0.2) : (stepMouse.containsMouse ? Theme.surface_container_high : "transparent"))

                                Behavior on color { ColorAnimation { duration: Theme.animFast } }

                                RowLayout {
                                    anchors.centerIn: parent
                                    spacing: 4

                                    Text {
                                        visible: isPassed
                                        text: Theme.iconCheck
                                        font.family: Theme.fontIcon
                                        font.pixelSize: Theme.fontSizeXs - 1
                                        color: Theme.primary
                                    }

                                    Text {
                                        text: modelData.label
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.fontSizeXs
                                        font.weight: isActive ? Theme.fontWeightBold : Theme.fontWeightMedium
                                        color: isActive ? Theme.on_primary : (isPassed ? Theme.primary : Theme.on_surface_variant)
                                    }
                                }

                                MouseArea {
                                    id: stepMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.currentStep = modelData.step
                                }
                            }
                        }
                    }

                    Rectangle {
                        anchors.bottom: parent.bottom
                        width: parent.width
                        height: 1
                        color: Theme.alpha(Theme.outline_variant, 0.5)
                    }
                }

                // ── 3. MAIN WIZARD BODY (FLICKABLE VIEW) ───────────────────────
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true

                    Flickable {
                        id: flickBody
                        anchors.fill: parent
                        contentWidth: width
                        contentHeight: stepContentCol.implicitHeight + 32
                        boundsBehavior: Flickable.StopAtBounds

                        ColumnLayout {
                            id: stepContentCol
                            width: parent.width - 40
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: 14

                            Item { height: 6 }

                            // ══════════════════════════════════════════════════
                            // STEP 0: WELCOME & PHILOSOPHY
                            // ══════════════════════════════════════════════════
                            ColumnLayout {
                                visible: root.currentStep === 0
                                Layout.fillWidth: true
                                spacing: 14

                                ColumnLayout {
                                    spacing: 4

                                    Text {
                                        text: "Welcome Home"
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.fontSizeTitle
                                        font.weight: Theme.fontWeightBold
                                        color: Theme.on_surface
                                    }

                                    Text {
                                        text: "A fluid, opinionated Wayland desktop tuned to your rhythm."
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.fontSizeSm
                                        color: Theme.on_surface_variant
                                    }
                                }

                                // Philosophy Highlight Card
                                Rectangle {
                                    Layout.fillWidth: true
                                    implicitHeight: philCol.implicitHeight + 24
                                    radius: Theme.radiusMd
                                    color: Theme.surface_container_high ?? Theme.cardBackground
                                    border.color: Theme.alpha(Theme.primary, 0.3)
                                    border.width: 1

                                    ColumnLayout {
                                        id: philCol
                                        anchors.fill: parent
                                        anchors.margins: 14
                                        spacing: 8

                                        RowLayout {
                                            spacing: 8

                                            Text {
                                                text: Theme.iconSparkles
                                                font.family: Theme.fontIcon
                                                font.pixelSize: Theme.fontSizeMd
                                                color: Theme.primary
                                            }

                                            Text {
                                                text: "The Core Philosophy: Follow the User, Not the Shell"
                                                font.family: Theme.fontFamily
                                                font.pixelSize: Theme.fontSizeSm
                                                font.weight: Theme.fontWeightBold
                                                color: Theme.primary
                                            }
                                        }

                                        Text {
                                            Layout.fillWidth: true
                                            wrapMode: Text.Wrap
                                            text: "Most desktop setups force you into rigid, dogmatic workflows. This environment was crafted to adapt to you instead:\n\n" +
                                                  "• Colors extract live from your wallpaper with zero reloads or flicker.\n" +
                                                  "• Corner radii, scoop borders, and physics scale in real-time.\n" +
                                                  "• Dual-shell compatibility: switch between Quickshell and Brain_Shell effortlessly, or keep it 100% native."
                                            font.family: Theme.fontFamily
                                            font.pixelSize: Theme.fontSizeXs
                                            color: Theme.on_surface
                                            lineHeight: 1.3
                                        }
                                    }
                                }

                                // 3 Key Pillars
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 10

                                    Rectangle {
                                        Layout.fillWidth: true
                                        implicitHeight: 90
                                        radius: Theme.radiusSm
                                        color: Theme.surface_container_lowest
                                        border.color: Theme.outline_variant
                                        border.width: 1

                                        ColumnLayout {
                                            anchors.fill: parent
                                            anchors.margins: 10
                                            spacing: 4

                                            Text {
                                                text: "🎨 Reactive Colors"
                                                font.family: Theme.fontFamily
                                                font.pixelSize: Theme.fontSizeSm
                                                font.weight: Theme.fontWeightBold
                                                color: Theme.primary
                                            }
                                            Text {
                                                Layout.fillWidth: true
                                                wrapMode: Text.Wrap
                                                text: "Matugen generates Material 3 palettes instantly on wallpaper shifts."
                                                font.family: Theme.fontFamily
                                                font.pixelSize: Theme.fontSizeXs - 1
                                                color: Theme.on_surface_variant
                                            }
                                        }
                                    }

                                    Rectangle {
                                        Layout.fillWidth: true
                                        implicitHeight: 90
                                        radius: Theme.radiusSm
                                        color: Theme.surface_container_lowest
                                        border.color: Theme.outline_variant
                                        border.width: 1

                                        ColumnLayout {
                                            anchors.fill: parent
                                            anchors.margins: 10
                                            spacing: 4

                                            Text {
                                                text: "🧈 Tactile Physics"
                                                font.family: Theme.fontFamily
                                                font.pixelSize: Theme.fontSizeSm
                                                font.weight: Theme.fontWeightBold
                                                color: Theme.primary
                                            }
                                            Text {
                                                Layout.fillWidth: true
                                                wrapMode: Text.Wrap
                                                text: "Bezier curves, concave scoop fillets, and buttery smooth transitions."
                                                font.family: Theme.fontFamily
                                                font.pixelSize: Theme.fontSizeXs - 1
                                                color: Theme.on_surface_variant
                                            }
                                        }
                                    }

                                    Rectangle {
                                        Layout.fillWidth: true
                                        implicitHeight: 90
                                        radius: Theme.radiusSm
                                        color: Theme.surface_container_lowest
                                        border.color: Theme.outline_variant
                                        border.width: 1

                                        ColumnLayout {
                                            anchors.fill: parent
                                            anchors.margins: 10
                                            spacing: 4

                                            Text {
                                                text: "⌨️ Hand-Crafted Binds"
                                                font.family: Theme.fontFamily
                                                font.pixelSize: Theme.fontSizeSm
                                                font.weight: Theme.fontWeightBold
                                                color: Theme.primary
                                            }
                                            Text {
                                                Layout.fillWidth: true
                                                wrapMode: Text.Wrap
                                                text: "Fast keyboard navigation with live fuzzy cheatsheets and HUD."
                                                font.family: Theme.fontFamily
                                                font.pixelSize: Theme.fontSizeXs - 1
                                                color: Theme.on_surface_variant
                                            }
                                        }
                                    }
                                }
                            }

                            // ══════════════════════════════════════════════════
                            // STEP 1: AESTHETICS CALIBRATION
                            // ══════════════════════════════════════════════════
                            ColumnLayout {
                                visible: root.currentStep === 1
                                Layout.fillWidth: true
                                spacing: 14

                                ColumnLayout {
                                    spacing: 3

                                    Text {
                                        text: "Tune Your Aesthetics"
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.fontSizeLg
                                        font.weight: Theme.fontWeightBold
                                        color: Theme.on_surface
                                    }

                                    Text {
                                        text: "Adjust these live controls — watch the desktop react instantly in real time."
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.fontSizeXs
                                        color: Theme.on_surface_variant
                                    }
                                }

                                // 1. Theme Mode: Dark vs Light
                                Rectangle {
                                    Layout.fillWidth: true
                                    implicitHeight: 52
                                    radius: Theme.radiusSm
                                    color: Theme.surface_container_high
                                    border.color: Theme.outline_variant
                                    border.width: 1

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.margins: 10
                                        spacing: 12

                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 1

                                            Text {
                                                text: "Color Mode"
                                                font.family: Theme.fontFamily
                                                font.pixelSize: Theme.fontSizeSm
                                                font.weight: Theme.fontWeightMedium
                                                color: Theme.on_surface
                                            }
                                            Text {
                                                text: "Switch between dark and light palette rendering"
                                                font.family: Theme.fontFamily
                                                font.pixelSize: Theme.fontSizeXs - 1
                                                color: Theme.on_surface_variant
                                            }
                                        }

                                        RowLayout {
                                            spacing: 6

                                            Rectangle {
                                                width: 76
                                                height: 30
                                                radius: Theme.radiusPill
                                                readonly property bool isDark: Settings.matugenMode === "dark"
                                                color: isDark ? Theme.primary : Theme.surface_container_lowest
                                                border.color: isDark ? "transparent" : Theme.outline_variant
                                                border.width: 1

                                                RowLayout {
                                                    anchors.centerIn: parent
                                                    spacing: 4
                                                    Text { text: Theme.iconMoon; font.family: Theme.fontIcon; font.pixelSize: Theme.fontSizeXs; color: parent.parent.isDark ? Theme.on_primary : Theme.on_surface }
                                                    Text { text: "dark"; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSizeXs; font.weight: Theme.fontWeightMedium; color: parent.parent.isDark ? Theme.on_primary : Theme.on_surface }
                                                }

                                                MouseArea {
                                                    anchors.fill: parent
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: WallpaperService.setMode("dark")
                                                }
                                            }

                                            Rectangle {
                                                width: 76
                                                height: 30
                                                radius: Theme.radiusPill
                                                readonly property bool isLight: Settings.matugenMode === "light"
                                                color: isLight ? Theme.primary : Theme.surface_container_lowest
                                                border.color: isLight ? "transparent" : Theme.outline_variant
                                                border.width: 1

                                                RowLayout {
                                                    anchors.centerIn: parent
                                                    spacing: 4
                                                    Text { text: Theme.iconSun; font.family: Theme.fontIcon; font.pixelSize: Theme.fontSizeXs; color: parent.parent.isLight ? Theme.on_primary : Theme.on_surface }
                                                    Text { text: "light"; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSizeXs; font.weight: Theme.fontWeightMedium; color: parent.parent.isLight ? Theme.on_primary : Theme.on_surface }
                                                }

                                                MouseArea {
                                                    anchors.fill: parent
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: WallpaperService.setMode("light")
                                                }
                                            }
                                        }
                                    }
                                }

                                // 2. Palette Scheme Selection
                                Rectangle {
                                    Layout.fillWidth: true
                                    implicitHeight: 64
                                    radius: Theme.radiusSm
                                    color: Theme.surface_container_high
                                    border.color: Theme.outline_variant
                                    border.width: 1

                                    ColumnLayout {
                                        anchors.fill: parent
                                        anchors.margins: 10
                                        spacing: 6

                                        Text {
                                            text: "Matugen Dynamic Scheme"
                                            font.family: Theme.fontFamily
                                            font.pixelSize: Theme.fontSizeSm
                                            font.weight: Theme.fontWeightMedium
                                            color: Theme.on_surface
                                        }

                                        RowLayout {
                                            spacing: 6

                                            Repeater {
                                                model: [
                                                    { id: "scheme-tonal-spot", label: "tonal spot" },
                                                    { id: "scheme-vibrant", label: "vibrant" },
                                                    { id: "scheme-expressive", label: "expressive" },
                                                    { id: "scheme-fruit-salad", label: "fruit salad" },
                                                    { id: "scheme-monochrome", label: "monochrome" }
                                                ]

                                                delegate: Rectangle {
                                                    required property var modelData
                                                    height: 26
                                                    width: schemeText.implicitWidth + 16
                                                    radius: Theme.radiusPill
                                                    readonly property bool isSelected: Settings.matugenScheme === modelData.id
                                                    color: isSelected ? Theme.primary : (sMouse.containsMouse ? Theme.surface_container_highest : Theme.surface_container_lowest)
                                                    border.color: isSelected ? "transparent" : Theme.outline_variant
                                                    border.width: 1

                                                    Text {
                                                        id: schemeText
                                                        anchors.centerIn: parent
                                                        text: modelData.label
                                                        font.family: Theme.fontFamily
                                                        font.pixelSize: Theme.fontSizeXs
                                                        font.weight: isSelected ? Theme.fontWeightBold : Theme.fontWeightMedium
                                                        color: isSelected ? Theme.on_primary : Theme.on_surface
                                                    }

                                                    MouseArea {
                                                        id: sMouse
                                                        anchors.fill: parent
                                                        hoverEnabled: true
                                                        cursorShape: Qt.PointingHandCursor
                                                        onClicked: WallpaperService.setScheme(modelData.id)
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }

                                // 3. Corner Rounding Slider
                                Rectangle {
                                    Layout.fillWidth: true
                                    implicitHeight: 64
                                    radius: Theme.radiusSm
                                    color: Theme.surface_container_high
                                    border.color: Theme.outline_variant
                                    border.width: 1

                                    ColumnLayout {
                                        anchors.fill: parent
                                        anchors.margins: 10
                                        spacing: 2

                                        Slider {
                                            Layout.fillWidth: true
                                            from: 0
                                            to: 24
                                            stepSize: 1
                                            value: Settings.globalRounding
                                            label: "Global Corner Rounding"
                                            unit: " px"
                                            icon: Theme.iconSliders
                                            accentColor: Theme.primary
                                            onMoved: (val) => Settings.globalRounding = Math.round(val)
                                        }
                                    }
                                }

                                // 4. Bar Island / Wallpaper Shuffle Row
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 10

                                    Rectangle {
                                        Layout.fillWidth: true
                                        implicitHeight: 52
                                        radius: Theme.radiusSm
                                        color: Theme.surface_container_high
                                        border.color: Theme.outline_variant
                                        border.width: 1

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.margins: 10
                                            spacing: 10

                                            ColumnLayout {
                                                Layout.fillWidth: true
                                                spacing: 1
                                                Text { text: "Floating Bar Island"; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSizeSm; font.weight: Theme.fontWeightMedium; color: Theme.on_surface }
                                                Text { text: "Floating pill bar with screen gaps"; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSizeXs - 1; color: Theme.on_surface_variant }
                                            }

                                            ToggleSwitch {
                                                checked: Settings.barFloating
                                                onToggled: Settings.barFloating = !Settings.barFloating
                                            }
                                        }
                                    }

                                    Rectangle {
                                        Layout.preferredWidth: 180
                                        implicitHeight: 52
                                        radius: Theme.radiusSm
                                        color: rollMouse.containsMouse ? Theme.surface_container_highest : Theme.surface_container_high
                                        border.color: Theme.outline_variant
                                        border.width: 1

                                        RowLayout {
                                            anchors.centerIn: parent
                                            spacing: 6

                                            Text {
                                                text: "🎲"
                                                font.pixelSize: Theme.fontSizeMd
                                            }
                                            Text {
                                                text: "Roll Wallpaper"
                                                font.family: Theme.fontFamily
                                                font.pixelSize: Theme.fontSizeSm
                                                font.weight: Theme.fontWeightBold
                                                color: Theme.primary
                                            }
                                        }

                                        MouseArea {
                                            id: rollMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: WallpaperService.applyRandomWallpaper("all")
                                        }
                                    }
                                }
                            }

                            // ══════════════════════════════════════════════════
                            // STEP 2: THE BRAIN_SHELL DILEMMA
                            // ══════════════════════════════════════════════════
                            ColumnLayout {
                                visible: root.currentStep === 2
                                Layout.fillWidth: true
                                spacing: 14

                                ColumnLayout {
                                    spacing: 3

                                    Text {
                                        text: "The Shell Profile: To Brain or Not to Brain?"
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.fontSizeLg
                                        font.weight: Theme.fontWeightBold
                                        color: Theme.on_surface
                                    }

                                    Text {
                                        text: "Choose whether to enable the Brain_Shell switcher or keep your desktop pure native."
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.fontSizeXs
                                        color: Theme.on_surface_variant
                                    }
                                }

                                // Context explanation
                                Rectangle {
                                    Layout.fillWidth: true
                                    implicitHeight: bDescCol.implicitHeight + 18
                                    radius: Theme.radiusSm
                                    color: Theme.surface_container_high
                                    border.color: Theme.outline_variant
                                    border.width: 1

                                    ColumnLayout {
                                        id: bDescCol
                                        anchors.fill: parent
                                        anchors.margins: 10
                                        spacing: 4

                                        RowLayout {
                                            spacing: 6
                                            Text { text: "🧠"; font.pixelSize: Theme.fontSizeMd }
                                            Text {
                                                text: "What is Brain_Shell?"
                                                font.family: Theme.fontFamily
                                                font.pixelSize: Theme.fontSizeSm
                                                font.weight: Theme.fontWeightBold
                                                color: Theme.primary
                                            }
                                            Item { Layout.fillWidth: true }
                                            Rectangle {
                                                height: 18
                                                width: statusTxt.implicitWidth + 10
                                                radius: Theme.radiusPill
                                                color: root.brainShellDetected ? Theme.alpha(Theme.primary, 0.15) : Theme.alpha(Theme.outline, 0.15)
                                                Text {
                                                    id: statusTxt
                                                    anchors.centerIn: parent
                                                    text: root.brainShellDetected ? "✓ detected on disk" : "not yet installed"
                                                    font.family: Theme.fontMono
                                                    font.pixelSize: Theme.fontSizeXs - 1
                                                    color: root.brainShellDetected ? Theme.primary : Theme.on_surface_variant
                                                }
                                            }
                                        }

                                        Text {
                                            Layout.fillWidth: true
                                            wrapMode: Text.Wrap
                                            text: "Brainiac created Brain_Shell — an alternative Material You shell with its own distinct launcher, dashboard, and widgets. We engineered seamless coexistence so both shells share your wallpapers and theme colors."
                                            font.family: Theme.fontFamily
                                            font.pixelSize: Theme.fontSizeXs
                                            color: Theme.on_surface_variant
                                            lineHeight: 1.25
                                        }
                                    }
                                }

                                // Choice Option 1: Keep Shell Switcher
                                Rectangle {
                                    id: opt1Card
                                    Layout.fillWidth: true
                                    implicitHeight: opt1Col.implicitHeight + 20
                                    radius: Theme.radiusMd
                                    readonly property bool isSelected: Settings.showShellTab ?? true
                                    color: isSelected ? Theme.alpha(Theme.primary, 0.12) : Theme.surface_container_lowest
                                    border.color: isSelected ? Theme.primary : Theme.outline_variant
                                    border.width: isSelected ? 2 : 1

                                    Behavior on color { ColorAnimation { duration: Theme.animFast } }

                                    ColumnLayout {
                                        id: opt1Col
                                        anchors.fill: parent
                                        anchors.margins: 12
                                        spacing: 6

                                        RowLayout {
                                            spacing: 10

                                            Rectangle {
                                                width: 22
                                                height: 22
                                                radius: 11
                                                color: opt1Card.isSelected ? Theme.primary : "transparent"
                                                border.color: opt1Card.isSelected ? Theme.primary : Theme.outline
                                                border.width: 2

                                                Text {
                                                    visible: opt1Card.isSelected
                                                    anchors.centerIn: parent
                                                    text: Theme.iconCheck
                                                    font.family: Theme.fontIcon
                                                    font.pixelSize: 11
                                                    color: Theme.on_primary
                                                }
                                            }

                                            ColumnLayout {
                                                Layout.fillWidth: true
                                                spacing: 1

                                                Text {
                                                    text: "Enable Shell Switcher & Brain_Shell (Recommended)"
                                                    font.family: Theme.fontFamily
                                                    font.pixelSize: Theme.fontSizeSm
                                                    font.weight: Theme.fontWeightBold
                                                    color: opt1Card.isSelected ? Theme.primary : Theme.on_surface
                                                }

                                                Text {
                                                    Layout.fillWidth: true
                                                    wrapMode: Text.Wrap
                                                    text: "Keep the 'Shells' tab active in QuickSettings. Lets you switch between Quickshell and Brain_Shell with one click or with `qs-switch`."
                                                    font.family: Theme.fontFamily
                                                    font.pixelSize: Theme.fontSizeXs
                                                    color: Theme.on_surface_variant
                                                }
                                            }
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: Settings.showShellTab = true
                                    }
                                }

                                // Choice Option 2: Pure Native (Hide Switcher Tab)
                                Rectangle {
                                    id: opt2Card
                                    Layout.fillWidth: true
                                    implicitHeight: opt2Col.implicitHeight + 20
                                    radius: Theme.radiusMd
                                    readonly property bool isSelected: !(Settings.showShellTab ?? true)
                                    color: isSelected ? Theme.alpha(Theme.primary, 0.12) : Theme.surface_container_lowest
                                    border.color: isSelected ? Theme.primary : Theme.outline_variant
                                    border.width: isSelected ? 2 : 1

                                    Behavior on color { ColorAnimation { duration: Theme.animFast } }

                                    ColumnLayout {
                                        id: opt2Col
                                        anchors.fill: parent
                                        anchors.margins: 12
                                        spacing: 6

                                        RowLayout {
                                            spacing: 10

                                            Rectangle {
                                                width: 22
                                                height: 22
                                                radius: 11
                                                color: opt2Card.isSelected ? Theme.primary : "transparent"
                                                border.color: opt2Card.isSelected ? Theme.primary : Theme.outline
                                                border.width: 2

                                                Text {
                                                    visible: opt2Card.isSelected
                                                    anchors.centerIn: parent
                                                    text: Theme.iconCheck
                                                    font.family: Theme.fontIcon
                                                    font.pixelSize: 11
                                                    color: Theme.on_primary
                                                }
                                            }

                                            ColumnLayout {
                                                Layout.fillWidth: true
                                                spacing: 1

                                                Text {
                                                    text: "Pure Native Quickshell (Hide Shells Tab)"
                                                    font.family: Theme.fontFamily
                                                    font.pixelSize: Theme.fontSizeSm
                                                    font.weight: Theme.fontWeightBold
                                                    color: opt2Card.isSelected ? Theme.primary : Theme.on_surface
                                                }

                                                Text {
                                                    Layout.fillWidth: true
                                                    wrapMode: Text.Wrap
                                                    text: "Say no to Brain_Shell. The 'Shells' tab will completely disappear from QuickSettings to keep your interface clean and unified."
                                                    font.family: Theme.fontFamily
                                                    font.pixelSize: Theme.fontSizeXs
                                                    color: Theme.on_surface_variant
                                                }
                                            }
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: Settings.showShellTab = false
                                    }
                                }

                                Text {
                                    text: "Tip: You can re-enable or hide the Shells tab anytime in QuickSettings → Layout/Vibe."
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSizeXs - 1
                                    font.italic: true
                                    color: Theme.on_surface_variant
                                }
                            }

                            // ══════════════════════════════════════════════════
                            // STEP 3: ESSENTIAL KEYBINDS
                            // ══════════════════════════════════════════════════
                            ColumnLayout {
                                visible: root.currentStep === 3
                                Layout.fillWidth: true
                                spacing: 14

                                ColumnLayout {
                                    spacing: 3

                                    Text {
                                        text: "Master Your Keybinds"
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.fontSizeLg
                                        font.weight: Theme.fontWeightBold
                                        color: Theme.on_surface
                                    }

                                    Text {
                                        text: "Essential muscle memory shortcuts to navigate without lifting your hands."
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.fontSizeXs
                                        color: Theme.on_surface_variant
                                    }
                                }

                                // Keybind Cards Grid
                                GridLayout {
                                    Layout.fillWidth: true
                                    columns: 2
                                    rowSpacing: 8
                                    columnSpacing: 10

                                    Repeater {
                                        model: [
                                            { bind: "Win + Space", desc: "App Launcher", note: "Fuzzy search apps & quick calculator" },
                                            { bind: "Win + W", desc: "Shuffle Wallpaper", note: "Roll wallpaper + instant reactive theme" },
                                            { bind: "Win + S", desc: "QuickSettings", note: "Volume, network, theme toggles & studio" },
                                            { bind: "Win + /", desc: "Keybinds Cheatsheet", note: "Live searchable shortcuts HUD" },
                                            { bind: "Win + Shift + S", desc: "Screenshot Tool", note: "Interactive crop, OCR, & color grab" },
                                            { bind: "Win + Return", desc: "Spawn Terminal", note: "Quick access to your terminal emulator" }
                                        ]

                                        delegate: Rectangle {
                                            required property var modelData
                                            Layout.fillWidth: true
                                            implicitHeight: 56
                                            radius: Theme.radiusSm
                                            color: Theme.surface_container_high
                                            border.color: Theme.outline_variant
                                            border.width: 1

                                            RowLayout {
                                                anchors.fill: parent
                                                anchors.margins: 10
                                                spacing: 10

                                                Rectangle {
                                                    height: 26
                                                    width: keyTxt.implicitWidth + 14
                                                    radius: Theme.radiusSm
                                                    color: Theme.surface_container_lowest
                                                    border.color: Theme.outline_variant
                                                    border.width: 1

                                                    Text {
                                                        id: keyTxt
                                                        anchors.centerIn: parent
                                                        text: modelData.bind
                                                        font.family: Theme.fontMono
                                                        font.pixelSize: Theme.fontSizeXs
                                                        font.weight: Theme.fontWeightBold
                                                        color: Theme.primary
                                                    }
                                                }

                                                ColumnLayout {
                                                    Layout.fillWidth: true
                                                    spacing: 1

                                                    Text {
                                                        text: modelData.desc
                                                        font.family: Theme.fontFamily
                                                        font.pixelSize: Theme.fontSizeXs
                                                        font.weight: Theme.fontWeightBold
                                                        color: Theme.on_surface
                                                    }

                                                    Text {
                                                        text: modelData.note
                                                        font.family: Theme.fontFamily
                                                        font.pixelSize: Theme.fontSizeXs - 1
                                                        color: Theme.on_surface_variant
                                                        elide: Text.ElideRight
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }

                                // Interactive Button to trigger Keybinds Preview
                                Rectangle {
                                    Layout.fillWidth: true
                                    implicitHeight: 40
                                    radius: Theme.radiusSm
                                    color: prevKbMouse.containsMouse ? Theme.surface_container_highest : Theme.surface_container_lowest
                                    border.color: Theme.outline_variant
                                    border.width: 1

                                    RowLayout {
                                        anchors.centerIn: parent
                                        spacing: 8

                                        Text { text: Theme.iconKeyboard; font.family: Theme.fontIcon; font.pixelSize: Theme.fontSizeSm; color: Theme.primary }
                                        Text { text: "Preview Live Keybinds Cheatsheet (Win + /)"; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSizeSm; font.weight: Theme.fontWeightMedium; color: Theme.primary }
                                    }

                                    MouseArea {
                                        id: prevKbMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            Settings.requestKeybindsToggle();
                                        }
                                    }
                                }
                            }

                            // ══════════════════════════════════════════════════
                            // STEP 4: READY TO ROLL
                            // ══════════════════════════════════════════════════
                            ColumnLayout {
                                visible: root.currentStep === 4
                                Layout.fillWidth: true
                                spacing: 14

                                ColumnLayout {
                                    spacing: 3

                                    Text {
                                        text: "You're All Set!"
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.fontSizeTitle
                                        font.weight: Theme.fontWeightBold
                                        color: Theme.on_surface
                                    }

                                    Text {
                                        text: "Your configuration has been saved. Your desktop is ready for action."
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.fontSizeSm
                                        color: Theme.on_surface_variant
                                    }
                                }

                                // Calibration Summary Card
                                Rectangle {
                                    Layout.fillWidth: true
                                    implicitHeight: summCol.implicitHeight + 20
                                    radius: Theme.radiusMd
                                    color: Theme.surface_container_high
                                    border.color: Theme.alpha(Theme.primary, 0.4)
                                    border.width: 1

                                    ColumnLayout {
                                        id: summCol
                                        anchors.fill: parent
                                        anchors.margins: 12
                                        spacing: 8

                                        Text {
                                            text: "Your Active Profile Summary"
                                            font.family: Theme.fontFamily
                                            font.pixelSize: Theme.fontSizeSm
                                            font.weight: Theme.fontWeightBold
                                            color: Theme.primary
                                        }

                                        RowLayout {
                                            spacing: 12

                                            Text {
                                                text: "• Theme Mode: " + Settings.matugenMode
                                                font.family: Theme.fontFamily
                                                font.pixelSize: Theme.fontSizeXs
                                                color: Theme.on_surface
                                            }

                                            Text {
                                                text: "• Scheme: " + Settings.matugenScheme
                                                font.family: Theme.fontFamily
                                                font.pixelSize: Theme.fontSizeXs
                                                color: Theme.on_surface
                                            }

                                            Text {
                                                text: "• Rounding: " + Settings.globalRounding + "px"
                                                font.family: Theme.fontFamily
                                                font.pixelSize: Theme.fontSizeXs
                                                color: Theme.on_surface
                                            }

                                            Text {
                                                text: "• Shells Tab: " + (Settings.showShellTab ? "Visible" : "Hidden")
                                                font.family: Theme.fontFamily
                                                font.pixelSize: Theme.fontSizeXs
                                                color: Theme.on_surface
                                            }
                                        }

                                        Text {
                                            Layout.fillWidth: true
                                            wrapMode: Text.Wrap
                                            text: "You can reopen this setup guide anytime from terminal via `qs-action welcome` or through the QuickSettings menu."
                                            font.family: Theme.fontFamily
                                            font.pixelSize: Theme.fontSizeXs - 1
                                            color: Theme.on_surface_variant
                                        }
                                    }
                                }

                                // Celebratory Call to Action
                                Rectangle {
                                    Layout.fillWidth: true
                                    implicitHeight: 48
                                    radius: Theme.radiusSm
                                    color: Theme.primary

                                    RowLayout {
                                        anchors.centerIn: parent
                                        spacing: 8

                                        Text {
                                            text: Theme.iconSparkles
                                            font.family: Theme.fontIcon
                                            font.pixelSize: Theme.fontSizeMd
                                            color: Theme.on_primary
                                        }

                                        Text {
                                            text: "Finish Setup & Launch Desktop"
                                            font.family: Theme.fontFamily
                                            font.pixelSize: Theme.fontSizeMd
                                            font.weight: Theme.fontWeightBold
                                            color: Theme.on_primary
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.completeSetup()
                                    }
                                }
                            }

                            Item { height: 10 }
                        }
                    }
                }

                // ── 4. DIALOG FOOTER & NAVIGATION ─────────────────────────────
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 58
                    color: Theme.surface_container_high ?? Theme.surface_container
                    border.color: Theme.outline_variant ?? Theme.cardBorder
                    border.width: 0

                    Rectangle {
                        anchors.top: parent.top
                        width: parent.width
                        height: 1
                        color: Theme.outline_variant ?? Theme.cardBorder
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 20
                        anchors.rightMargin: 20
                        spacing: 12

                        // Back Button
                        Rectangle {
                            visible: root.currentStep > 0
                            width: 80
                            height: 34
                            radius: Theme.radiusPill
                            color: backMouse.containsMouse ? Theme.surface_container_highest : Theme.surface_container_lowest
                            border.color: Theme.outline_variant
                            border.width: 1

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 4
                                Text { text: Theme.iconChevronLeft; font.family: Theme.fontIcon; font.pixelSize: Theme.fontSizeXs; color: Theme.on_surface }
                                Text { text: "back"; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSizeXs; font.weight: Theme.fontWeightMedium; color: Theme.on_surface }
                            }

                            MouseArea {
                                id: backMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: if (root.currentStep > 0) root.currentStep--
                            }
                        }

                        Item { Layout.fillWidth: true }

                        // Step counter
                        Text {
                            text: "Step " + (root.currentStep + 1) + " of " + root.totalSteps
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeXs
                            color: Theme.on_surface_variant
                        }

                        Item { Layout.fillWidth: true }

                        // Next / Finish Button
                        Rectangle {
                            width: root.currentStep === root.totalSteps - 1 ? 140 : 90
                            height: 34
                            radius: Theme.radiusPill
                            color: Theme.primary

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 4

                                Text {
                                    text: root.currentStep === root.totalSteps - 1 ? "Launch Desktop" : "next"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSizeXs
                                    font.weight: Theme.fontWeightBold
                                    color: Theme.on_primary
                                }

                                Text {
                                    text: root.currentStep === root.totalSteps - 1 ? Theme.iconSparkles : Theme.iconChevronRight
                                    font.family: Theme.fontIcon
                                    font.pixelSize: Theme.fontSizeXs
                                    color: Theme.on_primary
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (root.currentStep < root.totalSteps - 1) {
                                        root.currentStep++;
                                    } else {
                                        root.completeSetup();
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
