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

    property bool open: false
    readonly property bool isOpen: root.open

    function checkShouldOpen() {
        if (!Settings?.showWelcomeWizard) {
            root.open = false;
            return;
        }

        const focused = Hyprland?.focusedMonitor?.name;
        if (focused && root.screen?.name) {
            root.open = (root.screen.name === focused);
            return;
        }

        root.open = (!root.screen || (Quickshell.screens && Quickshell.screens.length > 0 && root.screen === Quickshell.screens[0]));
    }

    Connections {
        target: Settings
        function onShowWelcomeWizardChanged() {
            if (Settings?.showWelcomeWizard) {
                root.checkShouldOpen();
            } else {
                root.open = false;
            }
        }
        function onRequestWelcomeToggle() {
            if (root.open) {
                root.open = false;
            } else {
                root.checkShouldOpen();
            }
        }
        function onRequestWelcomeOpen() {
            root.checkShouldOpen();
        }
        function onRequestWelcomeClose() {
            root.open = false;
        }
    }

    Connections {
        target: Hyprland
        function onFocusedMonitorChanged() {
            if (root.open) {
                root.checkShouldOpen();
            }
        }
    }

    property int currentStep: Settings?.welcomeWizardStep ?? 0
    onCurrentStepChanged: {
        if (Settings && Settings.welcomeWizardStep !== currentStep) {
            Settings.welcomeWizardStep = currentStep;
        }
    }
    readonly property int totalSteps: 5

    readonly property string brainShellSrc: Quickshell.env("HOME") + "/.local/src/Brain_Shell"
    readonly property string brainShellConf: Quickshell.env("HOME") + "/.config/Brain_Shell"
    property bool brainShellDetected: false
    property bool isInstallingBrainShell: false

    Process {
        id: brainDetectProc
        command: ["sh", "-c", "test -d \"$HOME/.local/src/Brain_Shell\" || test -d \"$HOME/.config/Brain_Shell\""]
        running: false
        onExited: (code) => {
            root.brainShellDetected = (code === 0);
        }
    }

    Process {
        id: brainInstallProc
        command: ["sh", "-c", "git clone -b dev https://github.com/Brainitech/Brain_Shell.git ~/.local/src/Brain_Shell"]
        running: false
        onExited: (code) => {
            root.isInstallingBrainShell = false;
            root.checkBrainShell();
        }
    }

    function checkBrainShell() {
        brainDetectProc.running = false;
        brainDetectProc.running = true;
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
        NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
    }

    function close() {
        Settings.showWelcomeWizard = false;
        Settings.markWelcomeCompleted();
        Settings.welcomeWizardStep = 0;
    }

    function completeSetup() {
        Settings.markWelcomeCompleted();
        Settings.showWelcomeWizard = false;
        Settings.welcomeWizardStep = 0;
        Quickshell.execDetached([
            "notify-send",
            "-a", "quickshell",
            "-i", "preferences-desktop-theme",
            "session locked",
            "we are live. try not to break it immediately."
        ]);
    }

    onIsOpenChanged: {
        if (isOpen) {
            currentStep = 0;
            checkBrainShell();
            focusTrap.forceActiveFocus();
        }
    }

    Component.onCompleted: {
        checkBrainShell();
        if (Settings?.showWelcomeWizard) {
            checkShouldOpen();
        }
    }

    Item {
        id: focusTrap
        anchors.fill: parent
        focus: root.isOpen
        opacity: root.animReveal

        Keys.onEscapePressed: root.close()
        Keys.onRightPressed: if (root.currentStep < root.totalSteps - 1) root.currentStep++
        Keys.onLeftPressed: if (root.currentStep > 0) root.currentStep--
        Keys.onReturnPressed: if (root.currentStep === root.totalSteps - 1) root.completeSetup()

        Rectangle {
            anchors.fill: parent
            color: Theme.scrim ?? "#000000"
            opacity: 0.88 * root.animReveal

            MouseArea {
                anchors.fill: parent
                onClicked: root.close()
            }
        }

        Rectangle {
            id: dialogCard
            width: Math.min(900, Math.max(680, (root.screen?.width ?? 1920) - 80))
            height: Math.min(680, Math.max(540, (root.screen?.height ?? 1080) - 100))
            anchors.centerIn: parent

            radius: Math.max(16, Settings?.globalRounding ?? 16)
            color: Theme.surface_container ?? Theme.cardBackground
            border.color: Theme.outline_variant ?? Theme.cardBorder
            border.width: 1
            clip: true

            scale: 0.90 + (0.10 * root.animReveal)
            Behavior on scale {
                NumberAnimation { duration: 350; easing.type: Easing.OutBack; easing.overshoot: 1.5 }
            }

            MouseArea { anchors.fill: parent }

            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                Rectangle {
                    id: dialogHeader
                    Layout.fillWidth: true
                    implicitHeight: 68
                    radius: dialogCard.radius
                    color: Theme.surface_container_high ?? Theme.surface_container
                    border.width: 0

                    Rectangle {
                        anchors.bottom: parent.bottom
                        width: parent.width
                        height: parent.radius
                        color: parent.color
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 20
                        anchors.rightMargin: 16
                        spacing: 12

                        Rectangle {
                            width: 42
                            height: 42
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
                                    text: "the architecture of spite"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSizeMd
                                    font.weight: Theme.fontWeightBold
                                    color: Theme.on_surface
                                }

                                Rectangle {
                                    height: 20
                                    width: badgeText.implicitWidth + 12
                                    radius: Theme.radiusPill
                                    color: Theme.alpha(Theme.primary, 0.14)

                                    Text {
                                        id: badgeText
                                        anchors.centerIn: parent
                                        text: "onboarding"
                                        font.family: Theme.fontMono
                                        font.pixelSize: Theme.fontSizeXs - 1
                                        font.weight: Theme.fontWeightBold
                                        color: Theme.primary
                                    }
                                }
                            }

                            Text {
                                text: "zero electron bloat • built on borrowed time • wayland native"
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeXs
                                font.italic: true
                                color: Theme.on_surface_variant
                            }
                        }

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

                    Rectangle {
                        anchors.bottom: parent.bottom
                        width: parent.width
                        height: 1
                        color: Theme.outline_variant ?? Theme.cardBorder
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 44
                    color: Theme.surface_container_lowest ?? "transparent"

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 20
                        anchors.rightMargin: 20
                        spacing: 6

                        Repeater {
                            model: [
                                { label: "1. the stack", step: 0 },
                                { label: "2. dopamine", step: 1 },
                                { label: "3. brain_shell", step: 2 },
                                { label: "4. uplink", step: 3 },
                                { label: "5. warranty", step: 4 }
                            ]

                            delegate: Rectangle {
                                required property var modelData
                                Layout.fillWidth: true
                                height: 28
                                radius: Theme.radiusPill
                                readonly property bool isActive: root.currentStep === modelData.step
                                readonly property bool isPassed: root.currentStep > modelData.step

                                color: isActive
                                    ? Theme.primary
                                    : (isPassed ? Theme.alpha(Theme.primary, 0.2) : (stepMouse.containsMouse ? Theme.surface_container_high : "transparent"))

                                Behavior on color { ColorAnimation { duration: Theme.animFast } }

                                RowLayout {
                                    anchors.centerIn: parent
                                    spacing: 6

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

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true

                    Flickable {
                        id: flickBody
                        anchors.fill: parent
                        contentWidth: width
                        contentHeight: stepContentCol.implicitHeight + 40
                        boundsBehavior: Flickable.StopAtBounds
                        clip: true

                        ColumnLayout {
                            id: stepContentCol
                            width: parent.width - 48
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: 14

                            Item { height: 10 }

                            // step 0
                            ColumnLayout {
                                visible: root.currentStep === 0
                                Layout.fillWidth: true
                                spacing: 18

                                ColumnLayout {
                                    spacing: 6

                                    Text {
                                        text: "built on pure spite"
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.fontSizeTitle * 1.1
                                        font.weight: Theme.fontWeightBold
                                        color: Theme.on_surface
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        wrapMode: Text.Wrap
                                        text: "i don't write clean code. i burn cpu cycles coercing qml to do things it was never designed for until the session stops crashing. this is a layer-shell setup held together by digital duct tape and questionable design choices."
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.fontSizeSm
                                        color: Theme.on_surface_variant
                                    }
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    implicitHeight: philCol.implicitHeight + 28
                                    radius: Theme.radiusMd
                                    color: Theme.surface_container_high ?? Theme.cardBackground
                                    border.color: Theme.alpha(Theme.primary, 0.5)
                                    border.width: 1

                                    ColumnLayout {
                                        id: philCol
                                        anchors.fill: parent
                                        anchors.margins: 14
                                        spacing: 12

                                        RowLayout {
                                            spacing: 10
                                            Text { text: Theme.iconSparkles; font.family: Theme.fontIcon; font.pixelSize: Theme.fontSizeMd; color: Theme.primary }
                                            Text {
                                                text: "the philosophy"
                                                font.family: Theme.fontFamily
                                                font.pixelSize: Theme.fontSizeSm
                                                font.weight: Theme.fontWeightBold
                                                color: Theme.primary
                                            }
                                        }

                                        Text {
                                            Layout.fillWidth: true
                                            wrapMode: Text.Wrap
                                            text: "• most desktop bars hold your hand. this one expects you to read the source code if something breaks.\n" +
                                                  "• colors are ripped live from your wallpaper using matugen. if your wallpaper is ugly, your desktop will be ugly.\n" +
                                                  "• zero webviews. if you want a browser engine to render your taskbar, go back to windows."
                                            font.family: Theme.fontFamily
                                            font.pixelSize: Theme.fontSizeXs
                                            color: Theme.on_surface
                                            lineHeight: 1.4
                                        }
                                    }
                                }
                            }

                            // step 1
                            ColumnLayout {
                                visible: root.currentStep === 1
                                Layout.fillWidth: true
                                spacing: 14

                                ColumnLayout {
                                    spacing: 4

                                    Text {
                                        text: "visual dopamine"
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.fontSizeLg
                                        font.weight: Theme.fontWeightBold
                                        color: Theme.on_surface
                                    }

                                    Text {
                                        text: "adjust these live controls to trick your brain into thinking you are productive."
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.fontSizeXs
                                        color: Theme.on_surface_variant
                                    }
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    implicitHeight: 64
                                    radius: Theme.radiusSm
                                    color: Theme.surface_container_high
                                    border.color: Theme.outline_variant
                                    border.width: 1

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.margins: 12
                                        spacing: 12

                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 2
                                            Text { text: "color mode"; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSizeSm; font.weight: Theme.fontWeightMedium; color: Theme.on_surface }
                                            Text { Layout.fillWidth: true; wrapMode: Text.Wrap; text: "dark mode because we stare at screens all day. light mode if you hate yourself."; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSizeXs - 1; color: Theme.on_surface_variant }
                                        }

                                        RowLayout {
                                            spacing: 8
                                            Rectangle {
                                                id: darkBtn
                                                width: 86
                                                height: 34
                                                radius: Theme.radiusPill
                                                readonly property bool isDark: Settings.matugenMode === "dark"
                                                color: isDark ? Theme.primary : Theme.surface_container_lowest
                                                border.color: isDark ? "transparent" : Theme.outline_variant
                                                border.width: 1

                                                RowLayout {
                                                    anchors.centerIn: parent
                                                    spacing: 6
                                                    Text { text: Theme.iconMoon; font.family: Theme.fontIcon; font.pixelSize: Theme.fontSizeXs; color: darkBtn.isDark ? Theme.on_primary : Theme.on_surface }
                                                    Text { text: "dark"; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSizeXs; font.weight: Theme.fontWeightMedium; color: darkBtn.isDark ? Theme.on_primary : Theme.on_surface }
                                                }
                                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: WallpaperService.setMode("dark") }
                                            }

                                            Rectangle {
                                                id: lightBtn
                                                width: 86
                                                height: 34
                                                radius: Theme.radiusPill
                                                readonly property bool isLight: Settings.matugenMode === "light"
                                                color: isLight ? Theme.primary : Theme.surface_container_lowest
                                                border.color: isLight ? "transparent" : Theme.outline_variant
                                                border.width: 1

                                                RowLayout {
                                                    anchors.centerIn: parent
                                                    spacing: 6
                                                    Text { text: Theme.iconSun; font.family: Theme.fontIcon; font.pixelSize: Theme.fontSizeXs; color: lightBtn.isLight ? Theme.on_primary : Theme.on_surface }
                                                    Text { text: "light"; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSizeXs; font.weight: Theme.fontWeightMedium; color: lightBtn.isLight ? Theme.on_primary : Theme.on_surface }
                                                }
                                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: WallpaperService.setMode("light") }
                                            }
                                        }
                                    }
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    implicitHeight: 74
                                    radius: Theme.radiusSm
                                    color: Theme.surface_container_high
                                    border.color: Theme.outline_variant
                                    border.width: 1

                                    ColumnLayout {
                                        anchors.fill: parent
                                        anchors.margins: 12
                                        spacing: 8

                                        Text { text: "matugen dynamic scheme"; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSizeSm; font.weight: Theme.fontWeightMedium; color: Theme.on_surface }

                                        RowLayout {
                                            Layout.fillWidth: true
                                            spacing: 8

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
                                                    Layout.fillWidth: true
                                                    height: 30
                                                    radius: Theme.radiusPill
                                                    readonly property bool isSelected: Settings.matugenScheme === modelData.id
                                                    color: isSelected ? Theme.primary : (sMouse.containsMouse ? Theme.surface_container_highest : Theme.surface_container_lowest)
                                                    border.color: isSelected ? "transparent" : Theme.outline_variant
                                                    border.width: 1

                                                    Text {
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

                                Rectangle {
                                    Layout.fillWidth: true
                                    implicitHeight: 68
                                    radius: Theme.radiusSm
                                    color: Theme.surface_container_high
                                    border.color: Theme.outline_variant
                                    border.width: 1

                                    ColumnLayout {
                                        anchors.fill: parent
                                        anchors.margins: 12
                                        spacing: 4

                                        Slider {
                                            Layout.fillWidth: true
                                            from: 0
                                            to: 24
                                            stepSize: 1
                                            value: Settings.globalRounding
                                            label: "global corner rounding"
                                            unit: " px"
                                            icon: Theme.iconSliders
                                            accentColor: Theme.primary
                                            onMoved: (val) => Settings.globalRounding = Math.round(val)
                                        }
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 12

                                    Rectangle {
                                        Layout.fillWidth: true
                                        implicitHeight: 56
                                        radius: Theme.radiusSm
                                        color: Theme.surface_container_high
                                        border.color: Theme.outline_variant
                                        border.width: 1

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.margins: 12
                                            spacing: 12
                                            ColumnLayout {
                                                Layout.fillWidth: true
                                                spacing: 2
                                                Text { text: "floating bar island"; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSizeSm; font.weight: Theme.fontWeightMedium; color: Theme.on_surface }
                                                Text { text: "toggle between floating pill gaps or clamped edges."; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSizeXs - 1; color: Theme.on_surface_variant }
                                            }
                                            ToggleSwitch {
                                                checked: Settings.barFloating
                                                onToggled: Settings.barFloating = !Settings.barFloating
                                            }
                                        }
                                    }

                                    Rectangle {
                                        Layout.preferredWidth: 200
                                        implicitHeight: 56
                                        radius: Theme.radiusSm
                                        color: rollMouse.containsMouse ? Theme.surface_container_highest : Theme.surface_container_high
                                        border.color: Theme.outline_variant
                                        border.width: 1

                                        RowLayout {
                                            anchors.centerIn: parent
                                            spacing: 8
                                            Text { text: "🎲"; font.pixelSize: Theme.fontSizeMd }
                                            Text { text: "roll wallpaper"; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSizeSm; font.weight: Theme.fontWeightBold; color: Theme.primary }
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

                            // step 2
                            ColumnLayout {
                                visible: root.currentStep === 2
                                Layout.fillWidth: true
                                spacing: 14

                                ColumnLayout {
                                    spacing: 4

                                    Text {
                                        text: "the brain_shell dilemma"
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.fontSizeLg
                                        font.weight: Theme.fontWeightBold
                                        color: Theme.on_surface
                                    }

                                    Text {
                                        text: "brain_shell is an experimental mutation of this setup. decide if you want to deal with it."
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.fontSizeXs
                                        color: Theme.on_surface_variant
                                    }
                                }

                                // automated install card (skips rendering if already installed)
                                Rectangle {
                                    visible: !root.brainShellDetected
                                    Layout.fillWidth: true
                                    implicitHeight: devInstallCol.implicitHeight + 24
                                    radius: Theme.radiusSm
                                    color: Theme.surface_container_lowest
                                    border.color: Theme.outline_variant
                                    border.width: 1

                                    ColumnLayout {
                                        id: devInstallCol
                                        anchors.fill: parent
                                        anchors.margins: 12
                                        spacing: 10

                                        RowLayout {
                                            spacing: 6
                                            Text { text: "⚠️"; font.pixelSize: Theme.fontSizeSm }
                                            Text {
                                                text: "brain_shell not found on disk"
                                                font.family: Theme.fontFamily
                                                font.pixelSize: Theme.fontSizeSm
                                                font.weight: Theme.fontWeightBold
                                                color: Theme.on_surface
                                            }
                                        }
                                        
                                        Text {
                                            Layout.fillWidth: true
                                            wrapMode: Text.Wrap
                                            text: "the main branch is basically a biohazard right now, so we only use the dev branch. click below to let quickshell clone it directly into ~/.local/src for you, or just ignore it and run in purist mode."
                                            font.family: Theme.fontFamily
                                            font.pixelSize: Theme.fontSizeXs
                                            color: Theme.on_surface_variant
                                        }

                                        Rectangle {
                                            Layout.fillWidth: true
                                            height: 40
                                            radius: Theme.radiusSm
                                            color: root.isInstallingBrainShell ? Theme.surface_container_highest : (installMouse.containsMouse ? Theme.surface_container_highest : Theme.primary)
                                            border.color: root.isInstallingBrainShell ? Theme.outline_variant : Theme.primary
                                            border.width: 1

                                            RowLayout {
                                                anchors.centerIn: parent
                                                spacing: 8

                                                Text {
                                                    text: root.isInstallingBrainShell ? Theme.iconSync : Theme.iconDownload
                                                    font.family: Theme.fontIcon
                                                    font.pixelSize: Theme.fontSizeSm
                                                    color: root.isInstallingBrainShell ? Theme.on_surface_variant : Theme.on_primary
                                                    RotationAnimation on rotation {
                                                        loops: Animation.Infinite
                                                        from: 0; to: 360
                                                        duration: 1000
                                                        running: root.isInstallingBrainShell
                                                    }
                                                }

                                                Text {
                                                    text: root.isInstallingBrainShell ? "cloning dev branch into src... please wait." : "click to install brain_shell (dev branch)"
                                                    font.family: Theme.fontFamily
                                                    font.pixelSize: Theme.fontSizeXs
                                                    font.weight: Theme.fontWeightBold
                                                    color: root.isInstallingBrainShell ? Theme.on_surface_variant : Theme.on_primary
                                                }
                                            }

                                            MouseArea {
                                                id: installMouse
                                                anchors.fill: parent
                                                hoverEnabled: !root.isInstallingBrainShell
                                                cursorShape: root.isInstallingBrainShell ? Qt.WaitCursor : Qt.PointingHandCursor
                                                onClicked: {
                                                    if (!root.isInstallingBrainShell) {
                                                        root.isInstallingBrainShell = true;
                                                        brainInstallProc.running = true;
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }

                                // options (always visible so they can choose even if they don't install)
                                Rectangle {
                                    id: opt1Card
                                    Layout.fillWidth: true
                                    implicitHeight: opt1Col.implicitHeight + 24
                                    radius: Theme.radiusMd
                                    readonly property bool isSelected: Settings.showShellTab ?? true
                                    color: isSelected ? Theme.alpha(Theme.primary, 0.12) : Theme.surface_container_lowest
                                    border.color: isSelected ? Theme.primary : Theme.outline_variant
                                    border.width: isSelected ? 2 : 1
                                    Behavior on color { ColorAnimation { duration: Theme.animFast } }

                                    ColumnLayout {
                                        id: opt1Col
                                        anchors.fill: parent
                                        anchors.margins: 14
                                        spacing: 8

                                        RowLayout {
                                            spacing: 12
                                            Rectangle {
                                                width: 24
                                                height: 24
                                                radius: 12
                                                color: opt1Card.isSelected ? Theme.primary : "transparent"
                                                border.color: opt1Card.isSelected ? Theme.primary : Theme.outline
                                                border.width: 2
                                                Text { visible: opt1Card.isSelected; anchors.centerIn: parent; text: Theme.iconCheck; font.family: Theme.fontIcon; font.pixelSize: 12; color: Theme.on_primary }
                                            }
                                            ColumnLayout {
                                                Layout.fillWidth: true
                                                spacing: 2
                                                Text { text: "chaotic dual-shell mode"; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSizeSm; font.weight: Theme.fontWeightBold; color: opt1Card.isSelected ? Theme.primary : Theme.on_surface }
                                                Text { Layout.fillWidth: true; wrapMode: Text.Wrap; text: "keeps the 'shells' tab active in quicksettings. lets you hot-swap between this architecture and brain_shell with a single click."; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSizeXs; color: Theme.on_surface_variant }
                                            }
                                        }
                                    }
                                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Settings.showShellTab = true }
                                }

                                Rectangle {
                                    id: opt2Card
                                    Layout.fillWidth: true
                                    implicitHeight: opt2Col.implicitHeight + 24
                                    radius: Theme.radiusMd
                                    readonly property bool isSelected: !(Settings.showShellTab ?? true)
                                    color: isSelected ? Theme.alpha(Theme.primary, 0.12) : Theme.surface_container_lowest
                                    border.color: isSelected ? Theme.primary : Theme.outline_variant
                                    border.width: isSelected ? 2 : 1
                                    Behavior on color { ColorAnimation { duration: Theme.animFast } }

                                    ColumnLayout {
                                        id: opt2Col
                                        anchors.fill: parent
                                        anchors.margins: 14
                                        spacing: 8

                                        RowLayout {
                                            spacing: 12
                                            Rectangle {
                                                width: 24
                                                height: 24
                                                radius: 12
                                                color: opt2Card.isSelected ? Theme.primary : "transparent"
                                                border.color: opt2Card.isSelected ? Theme.primary : Theme.outline
                                                border.width: 2
                                                Text { visible: opt2Card.isSelected; anchors.centerIn: parent; text: Theme.iconCheck; font.family: Theme.fontIcon; font.pixelSize: 12; color: Theme.on_primary }
                                            }
                                            ColumnLayout {
                                                Layout.fillWidth: true
                                                spacing: 2
                                                Text { text: "purist quickshell mode"; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSizeSm; font.weight: Theme.fontWeightBold; color: opt2Card.isSelected ? Theme.primary : Theme.on_surface }
                                                Text { Layout.fillWidth: true; wrapMode: Text.Wrap; text: "purges the 'shells' tab entirely. keeps your interface locked into this setup without extra clutter."; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSizeXs; color: Theme.on_surface_variant }
                                            }
                                        }
                                    }
                                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Settings.showShellTab = false }
                                }
                            }

                            // step 3
                            ColumnLayout {
                                visible: root.currentStep === 3
                                Layout.fillWidth: true
                                spacing: 14

                                ColumnLayout {
                                    spacing: 4
                                    Text { text: "muscle memory"; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSizeLg; font.weight: Theme.fontWeightBold; color: Theme.on_surface }
                                    Text { text: "hyprland bindings designed to keep your hands on the home row where they belong."; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSizeXs; color: Theme.on_surface_variant }
                                }

                                GridLayout {
                                    Layout.fillWidth: true
                                    columns: 2
                                    rowSpacing: 10
                                    columnSpacing: 12

                                    Repeater {
                                        model: [
                                            { bind: "win + d", desc: "app launcher", note: "fuzzy search your binaries" },
                                            { bind: "win + t", desc: "terminal", note: "kitty instance directly into uwsm" },
                                            { bind: "win + w", desc: "roll wallpaper", note: "instantly mutate your color scheme" },
                                            { bind: "win + v", desc: "clipboard", note: "frecency based history picker" },
                                            { bind: "win + a", desc: "audio menu", note: "quick sink selectors" },
                                            { bind: "win + space", desc: "float", note: "rip window from the tiling grid" },
                                            { bind: "win + shft + spc", desc: "sticky pip", note: "pin floating window for video" },
                                            { bind: "win + q", desc: "kill", note: "vaporize focused window" },
                                            { bind: "print", desc: "screenshot", note: "marquee crop and hex harvesting" },
                                            { bind: "win + end", desc: "lock screen", note: "pam layer-shell lockdown" }
                                        ]

                                        delegate: Rectangle {
                                            required property var modelData
                                            Layout.fillWidth: true
                                            implicitHeight: 60
                                            radius: Theme.radiusSm
                                            color: Theme.surface_container_high
                                            border.color: Theme.outline_variant
                                            border.width: 1

                                            RowLayout {
                                                anchors.fill: parent
                                                anchors.margins: 10
                                                spacing: 12

                                                Rectangle {
                                                    height: 28
                                                    width: keyTxt.implicitWidth + 16
                                                    radius: Theme.radiusSm
                                                    color: Theme.surface_container_lowest
                                                    border.color: Theme.outline_variant
                                                    border.width: 1
                                                    Text { id: keyTxt; anchors.centerIn: parent; text: modelData.bind; font.family: Theme.fontMono; font.pixelSize: Theme.fontSizeXs; font.weight: Theme.fontWeightBold; color: Theme.primary }
                                                }

                                                ColumnLayout {
                                                    Layout.fillWidth: true
                                                    spacing: 1
                                                    Text { text: modelData.desc; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSizeXs; font.weight: Theme.fontWeightBold; color: Theme.on_surface }
                                                    Text { Layout.fillWidth: true; text: modelData.note; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSizeXs - 1; color: Theme.on_surface_variant; elide: Text.ElideRight }
                                                }
                                            }
                                        }
                                    }
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    implicitHeight: 46
                                    radius: Theme.radiusSm
                                    color: prevKbMouse.containsMouse ? Theme.surface_container_highest : Theme.surface_container_lowest
                                    border.color: Theme.outline_variant
                                    border.width: 1

                                    RowLayout {
                                        anchors.centerIn: parent
                                        spacing: 10
                                        Text { text: Theme.iconKeyboard; font.family: Theme.fontIcon; font.pixelSize: Theme.fontSizeMd; color: Theme.primary }
                                        Text { text: "view full keybind cheatsheet"; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSizeSm; font.weight: Theme.fontWeightBold; color: Theme.primary }
                                    }

                                    MouseArea {
                                        id: prevKbMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: { root.close(); Settings.requestKeybindsOpen(); }
                                    }
                                }
                            }

                            // step 4
                            ColumnLayout {
                                visible: root.currentStep === 4
                                Layout.fillWidth: true
                                spacing: 14

                                ColumnLayout {
                                    spacing: 4
                                    Text { text: "warranty void"; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSizeTitle * 1.1; font.weight: Theme.fontWeightBold; color: Theme.on_surface }
                                    Text { Layout.fillWidth: true; wrapMode: Text.Wrap; text: "you made it to the end. if the shell segfaults from here on out, do not open an issue on github. fix it yourself or learn to live with the bugs."; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSizeSm; color: Theme.on_surface_variant }
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    implicitHeight: summCol.implicitHeight + 24
                                    radius: Theme.radiusMd
                                    color: Theme.surface_container_high
                                    border.color: Theme.alpha(Theme.primary, 0.4)
                                    border.width: 1

                                    ColumnLayout {
                                        id: summCol
                                        anchors.fill: parent
                                        anchors.margins: 14
                                        spacing: 12

                                        Text { text: "final configuration payload"; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSizeSm; font.weight: Theme.fontWeightBold; color: Theme.primary }

                                        GridLayout {
                                            Layout.fillWidth: true
                                            columns: 2
                                            rowSpacing: 10
                                            columnSpacing: 16

                                            RowLayout { spacing: 8; Text { text: "✓"; font.pixelSize: Theme.fontSizeXs; color: Theme.primary } Text { text: "theme: " + Settings.matugenMode; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSizeXs; color: Theme.on_surface } }
                                            RowLayout { spacing: 8; Text { text: "✓"; font.pixelSize: Theme.fontSizeXs; color: Theme.primary } Text { text: "scheme: " + (Settings.matugenScheme ? Settings.matugenScheme.replace(/^scheme-/, "") : "unknown"); font.family: Theme.fontFamily; font.pixelSize: Theme.fontSizeXs; color: Theme.on_surface } }
                                            RowLayout { spacing: 8; Text { text: "✓"; font.pixelSize: Theme.fontSizeXs; color: Theme.primary } Text { text: "rounding: " + Settings.globalRounding + "px"; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSizeXs; color: Theme.on_surface } }
                                            RowLayout { spacing: 8; Text { text: "✓"; font.pixelSize: Theme.fontSizeXs; color: Theme.primary } Text { text: "dual-shell: " + (Settings.showShellTab ? "enabled" : "disabled"); font.family: Theme.fontFamily; font.pixelSize: Theme.fontSizeXs; color: Theme.on_surface } }
                                        }

                                        Text { Layout.fillWidth: true; wrapMode: Text.Wrap; text: "you can recall this menu by typing `qs-action welcome` in your terminal if you want to ruin your settings again later."; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSizeXs - 1; color: Theme.on_surface_variant }
                                    }
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    implicitHeight: 56
                                    radius: Theme.radiusMd
                                    color: ctaMouse.containsMouse ? Qt.lighter(Theme.primary, 1.15) : Theme.primary
                                    Behavior on color { ColorAnimation { duration: Theme.animFast } }

                                    RowLayout {
                                        anchors.centerIn: parent
                                        spacing: 12
                                        Text { text: Theme.iconSparkles; font.family: Theme.fontIcon; font.pixelSize: Theme.fontSizeLg; color: Theme.on_primary }
                                        Text { text: "save config and launch"; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSizeMd; font.weight: Theme.fontWeightBold; color: Theme.on_primary; font.letterSpacing: 1.1 }
                                    }

                                    MouseArea {
                                        id: ctaMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.completeSetup()
                                    }
                                }
                            }
                            Item { height: 10 }
                        }
                    }

                    Rectangle {
                        anchors.right: parent.right
                        anchors.top: flickBody.top
                        anchors.bottom: flickBody.bottom
                        width: 4
                        color: "transparent"

                        Rectangle {
                            width: parent.width
                            radius: 2
                            color: Theme.on_surface_variant
                            opacity: (flickBody.contentHeight > flickBody.height) ? (flickBody.moving ? 0.6 : 0.3) : 0.0
                            Behavior on opacity { NumberAnimation { duration: 150 } }
                            height: Math.max(20, flickBody.height * (flickBody.height / Math.max(1, flickBody.contentHeight)))
                            y: flickBody.visibleArea.yPosition * flickBody.height
                        }
                    }
                }

                Rectangle {
                    id: dialogFooter
                    Layout.fillWidth: true
                    implicitHeight: 64
                    radius: dialogCard.radius
                    color: Theme.surface_container_high ?? Theme.surface_container
                    border.width: 0

                    Rectangle {
                        anchors.top: parent.top
                        width: parent.width
                        height: parent.radius
                        color: parent.color
                    }
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

                        Rectangle {
                            visible: root.currentStep > 0
                            width: 90
                            height: 36
                            radius: Theme.radiusPill
                            color: backMouse.containsMouse ? Theme.surface_container_highest : Theme.surface_container_lowest
                            border.color: Theme.outline_variant
                            border.width: 1

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 6
                                Text { text: Theme.iconChevronLeft; font.family: Theme.fontIcon; font.pixelSize: Theme.fontSizeXs; color: Theme.on_surface }
                                Text { text: "back"; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSizeXs; font.weight: Theme.fontWeightMedium; color: Theme.on_surface }
                            }
                            MouseArea { id: backMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: if (root.currentStep > 0) root.currentStep-- }
                        }

                        Item { Layout.fillWidth: true }

                        Text {
                            text: "step " + (root.currentStep + 1) + " of " + root.totalSteps
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeXs
                            font.weight: Theme.fontWeightBold
                            color: Theme.on_surface_variant
                        }

                        Item { Layout.fillWidth: true }

                        Rectangle {
                            width: root.currentStep === root.totalSteps - 1 ? 160 : 100
                            height: 36
                            radius: Theme.radiusPill
                            color: nextMouse.containsMouse ? Qt.lighter(Theme.primary, 1.1) : Theme.primary

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 6
                                Text { text: root.currentStep === root.totalSteps - 1 ? "launch" : "next"; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSizeXs; font.weight: Theme.fontWeightBold; color: Theme.on_primary }
                                Text { text: root.currentStep === root.totalSteps - 1 ? Theme.iconSparkles : Theme.iconChevronRight; font.family: Theme.fontIcon; font.pixelSize: Theme.fontSizeXs; color: Theme.on_primary }
                            }
                            MouseArea {
                                id: nextMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (root.currentStep < root.totalSteps - 1) root.currentStep++;
                                    else root.completeSetup();
                                }
                            }
                        }
                    }
                }
            }

            Rectangle {
                anchors.fill: parent
                radius: dialogCard.radius
                color: "transparent"
                border.color: Theme.outline ?? Theme.cardBorder
                border.width: 1
                z: 99
            }
        }
    }
}
