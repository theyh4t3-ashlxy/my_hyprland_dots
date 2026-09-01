import QtQuick
import QtQuick.Layouts
import ".."
import Quickshell
import Quickshell.Services.Pipewire

Rectangle {
    id: root
    implicitWidth: Theme.isVertical ? Theme.barHeight - 8 : qsRow.implicitWidth + 24
    implicitHeight: Theme.barHeight - 8
    radius: Theme.radiusPill
    color: popup.open ? Theme.primary_overlay : (qsMouse.containsMouse ? Theme.surface_container_highest : Theme.surface_container_high)

    Behavior on color { ColorAnimation { duration: Theme.animFast } }

    property string activeTab: "layout"
    property string fontTarget: "sans" // "sans" or "mono"
    property string fontSearchQuery: ""

    readonly property var allFonts: Qt.fontFamilies()
    readonly property var filteredFonts: {
        if (!fontSearchQuery || fontSearchQuery.trim() === "") return allFonts
        const q = fontSearchQuery.trim().toLowerCase()
        return allFonts.filter(f => f.toLowerCase().includes(q))
    }

    Row {
        id: qsRow
        anchors.centerIn: parent
        spacing: 4

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Theme.iconSettings
            font.family: Theme.fontMono
            font.pixelSize: Theme.fontSizeMd
            color: popup.open ? Theme.primary : Theme.on_surface
        }
    }

    MouseArea {
        id: qsMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            popup.targetRelativeX = root.mapToItem(null, 0, 0).x + (root.width / 2)
            popup.open = !popup.open
        }
    }

    PopupPanel {
        id: popup
        cardWidth: 480
        cardHeight: 640
        targetRelativeX: root.mapToItem(null, 0, 0).x + (root.width / 2)

        content: ColumnLayout {
            anchors.fill: parent
            anchors.margins: Theme.widgetPaddingH
            spacing: Theme.widgetSpacing

            // Header with instant auto-save status
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: "settings & customization"
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeLg
                    font.weight: Font.Bold
                    color: Theme.on_surface
                    Layout.fillWidth: true
                }

                Rectangle {
                    height: 24
                    implicitWidth: saveBadgeRow.implicitWidth + 16
                    radius: Theme.radiusPill
                    color: Theme.primary_overlay

                    RowLayout {
                        id: saveBadgeRow
                        anchors.centerIn: parent
                        spacing: 4

                        Text {
                            text: Theme.iconCheck
                            font.family: Theme.fontMono
                            font.pixelSize: 10
                            color: Theme.primary
                        }

                        Text {
                            text: "auto-saved"
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                            font.weight: Font.Medium
                            color: Theme.primary
                        }
                    }
                }
            }

            // Tab bar
            Flickable {
                Layout.fillWidth: true
                height: 34
                contentWidth: tabRow.width
                flickableDirection: Flickable.HorizontalFlick
                clip: true

                RowLayout {
                    id: tabRow
                    spacing: 4

                    Repeater {
                        model: [
                            { id: "layout", label: "layout", icon: Theme.iconGrid },
                            { id: "modules", label: "modules", icon: Theme.iconEye },
                            { id: "fonts", label: "fonts", icon: Theme.iconNote },
                            { id: "animations", label: "animations", icon: Theme.iconFlame },
                            { id: "vibe", label: "vibe", icon: Theme.iconCoffee }
                        ]

                        delegate: Rectangle {
                            required property var modelData
                            height: 32
                            width: tabItemRow.implicitWidth + 20
                            radius: Theme.widgetRadius
                            color: root.activeTab === modelData.id ? Theme.primary : Theme.surface_container_highest

                            Behavior on color { ColorAnimation { duration: Theme.animFast } }

                            RowLayout {
                                id: tabItemRow
                                anchors.centerIn: parent
                                spacing: 6

                                Text {
                                    text: modelData.icon
                                    font.family: Theme.fontMono
                                    font.pixelSize: Theme.fontSizeXs
                                    color: root.activeTab === modelData.id ? Theme.on_primary : Theme.on_surface
                                }

                                Text {
                                    text: modelData.label
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSizeSm
                                    font.weight: Font.Medium
                                    color: root.activeTab === modelData.id ? Theme.on_primary : Theme.on_surface
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.activeTab = modelData.id
                            }
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Theme.widgetBorder
            }

            // TAB 1: LAYOUT
            Flickable {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: root.activeTab === "layout"
                clip: true
                contentWidth: width
                contentHeight: layoutCol.implicitHeight
                boundsBehavior: Flickable.StopAtBounds

                ColumnLayout {
                    id: layoutCol
                    width: parent.width - 4
                    spacing: 12

                    // Bar Position Selector
                    Text {
                        text: "bar position & orientation"
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeSm
                        font.weight: Font.Bold
                        color: Theme.primary
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Repeater {
                            model: [
                                { label: "top", pos: "top" },
                                { label: "bottom", pos: "bottom" },
                                { label: "left", pos: "left" },
                                { label: "right", pos: "right" }
                            ]

                            delegate: Rectangle {
                                required property var modelData
                                Layout.fillWidth: true
                                height: 32
                                radius: Theme.radiusSm
                                color: Settings.barPosition === modelData.pos ? Theme.primary : Theme.surface_container_highest

                                Text {
                                    text: modelData.label
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSizeXs
                                    font.weight: Font.Bold
                                    color: Settings.barPosition === modelData.pos ? Theme.on_primary : Theme.on_surface
                                    anchors.centerIn: parent
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Settings.barPosition = modelData.pos
                                }
                            }
                        }
                    }

                    // Bar Height Slider
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4

                        RowLayout {
                            Layout.fillWidth: true
                            Text {
                                text: "bar height: " + Settings.barHeight + "px"
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeXs
                                color: Theme.on_surface
                                Layout.fillWidth: true
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 6

                            Repeater {
                                model: [28, 32, 36, 40, 48]
                                delegate: Rectangle {
                                    required property int modelData
                                    Layout.fillWidth: true
                                    height: 28
                                    radius: Theme.radiusSm
                                    color: Settings.barHeight === modelData ? Theme.primary : Theme.surface_container_highest

                                    Text {
                                        text: modelData + "px"
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 10
                                        color: Settings.barHeight === modelData ? Theme.on_primary : Theme.on_surface
                                        anchors.centerIn: parent
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: Settings.barHeight = modelData
                                    }
                                }
                            }
                        }
                    }

                    // Scoop Radius Fillets
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4

                        Text {
                            text: "concave scoop radius: " + Settings.scoopRadius + "px"
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeXs
                            color: Theme.on_surface
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 6

                            Repeater {
                                model: [0, 10, 16, 20, 24]
                                delegate: Rectangle {
                                    required property int modelData
                                    Layout.fillWidth: true
                                    height: 28
                                    radius: Theme.radiusSm
                                    color: Settings.scoopRadius === modelData ? Theme.primary : Theme.surface_container_highest

                                    Text {
                                        text: modelData === 0 ? "none" : (modelData + "px")
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 10
                                        color: Settings.scoopRadius === modelData ? Theme.on_primary : Theme.on_surface
                                        anchors.centerIn: parent
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: Settings.scoopRadius = modelData
                                    }
                                }
                            }
                        }
                    }

                    // Screen Corners Mode
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4

                        Text {
                            text: "screen corner fillets"
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeXs
                            color: Theme.on_surface
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 6

                            Repeater {
                                model: [
                                    { label: "all 4 corners", m: "all" },
                                    { label: "bottom only", m: "bottom" },
                                    { label: "disabled", m: "none" }
                                ]

                                delegate: Rectangle {
                                    required property var modelData
                                    Layout.fillWidth: true
                                    height: 28
                                    radius: Theme.radiusSm
                                    color: Settings.screenCornerMode === modelData.m ? Theme.primary : Theme.surface_container_highest

                                    Text {
                                        text: modelData.label
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 10
                                        color: Settings.screenCornerMode === modelData.m ? Theme.on_primary : Theme.on_surface
                                        anchors.centerIn: parent
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: Settings.screenCornerMode = modelData.m
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // TAB 2: MODULES (BAR WIDGET TOGGLES)
            Flickable {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: root.activeTab === "modules"
                clip: true
                contentWidth: width
                contentHeight: modCol.implicitHeight
                boundsBehavior: Flickable.StopAtBounds

                ColumnLayout {
                    id: modCol
                    width: parent.width - 4
                    spacing: 8

                    Text {
                        text: "visible bar widgets"
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeSm
                        font.weight: Font.Bold
                        color: Theme.primary
                    }

                    Repeater {
                        model: [
                            { prop: "showLauncher", label: "application launcher" },
                            { prop: "showWorkspaces", label: "workspaces switcher" },
                            { prop: "showWindowTitle", label: "window title" },
                            { prop: "showClock", label: "clock & date" },
                            { prop: "showMedia", label: "now playing / mpris" },
                            { prop: "showWallpaper", label: "wallpaper & theme browser" },
                            { prop: "showVolume", label: "volume & audio mixer" },
                            { prop: "showNetwork", label: "network / wifi" },
                            { prop: "showBluetooth", label: "bluetooth" },
                            { prop: "showBattery", label: "battery status" },
                            { prop: "showSystemTray", label: "system tray" },
                            { prop: "showNotifications", label: "notifications center" },
                            { prop: "showIdleInhibitor", label: "caffeine / idle inhibitor" },
                            { prop: "showClipboard", label: "clipboard history" },
                            { prop: "showPowerMenu", label: "power session menu" }
                        ]

                        delegate: Rectangle {
                            required property var modelData
                            Layout.fillWidth: true
                            height: 38
                            radius: Theme.widgetRadius
                            color: Theme.surface_container_highest

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: Theme.widgetPaddingH
                                spacing: 8

                                Text {
                                    text: modelData.label
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSizeSm
                                    color: Theme.on_surface
                                    Layout.fillWidth: true
                                }

                                ToggleSwitch {
                                    checked: Settings[modelData.prop]
                                    onToggled: Settings[modelData.prop] = !Settings[modelData.prop]
                                }
                            }
                        }
                    }
                }
            }

            // TAB 3: FONTS (GRANULAR GNOME TWEAKS STYLE)
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: root.activeTab === "fonts"
                spacing: 8

                // Target Font Selector (Interface Sans vs Monospace)
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Rectangle {
                        Layout.fillWidth: true
                        height: 32
                        radius: Theme.radiusSm
                        color: root.fontTarget === "sans" ? Theme.primary : Theme.surface_container_highest

                        Text {
                            text: "interface font: " + Settings.fontFamily
                            font.family: Settings.fontFamily
                            font.pixelSize: Theme.fontSizeXs
                            font.weight: Font.Bold
                            color: root.fontTarget === "sans" ? Theme.on_primary : Theme.on_surface
                            anchors.centerIn: parent
                            elide: Text.ElideRight
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.fontTarget = "sans"
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 32
                        radius: Theme.radiusSm
                        color: root.fontTarget === "mono" ? Theme.primary : Theme.surface_container_highest

                        Text {
                            text: "monospace: " + Settings.fontMono
                            font.family: Settings.fontMono
                            font.pixelSize: Theme.fontSizeXs
                            font.weight: Font.Bold
                            color: root.fontTarget === "mono" ? Theme.on_primary : Theme.on_surface
                            anchors.centerIn: parent
                            elide: Text.ElideRight
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.fontTarget = "mono"
                        }
                    }
                }

                // Font Search Input
                Rectangle {
                    Layout.fillWidth: true
                    height: 36
                    color: Theme.surface_container_highest
                    radius: Theme.widgetRadius
                    border.color: fontSearchInput.activeFocus ? Theme.primary : Theme.widgetBorder
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: Theme.widgetPaddingH
                        spacing: 8

                        Text {
                            text: Theme.iconSearch
                            font.family: Theme.fontMono
                            font.pixelSize: Theme.fontSizeSm
                            color: Theme.on_surface_variant
                        }

                        TextInput {
                            id: fontSearchInput
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            verticalAlignment: TextInput.AlignVCenter
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeSm
                            color: Theme.on_surface
                            onTextChanged: root.fontSearchQuery = text.toLowerCase()
                        }
                    }
                }

                // Live Font List Browser
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: Theme.surface_container_low
                    radius: Theme.widgetRadius
                    border.color: Theme.widgetBorder
                    border.width: 1
                    clip: true

                    ListView {
                        id: fontListView
                        anchors.fill: parent
                        anchors.margins: 4
                        model: root.filteredFonts
                        boundsBehavior: Flickable.StopAtBounds

                        delegate: Rectangle {
                            required property string modelData
                            width: fontListView.width
                            height: 32
                            radius: Theme.radiusSm
                            readonly property bool isCurrent: (root.fontTarget === "sans" && Settings.fontFamily === modelData)
                                                           || (root.fontTarget === "mono" && Settings.fontMono === modelData)
                            color: isCurrent ? Theme.primary : (fItemMouse.containsMouse ? Theme.surface_container_highest : "transparent")

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 6
                                spacing: 8

                                Text {
                                    text: modelData
                                    font.family: modelData
                                    font.pixelSize: 12
                                    color: isCurrent ? Theme.on_primary : Theme.on_surface
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                }

                                Text {
                                    text: isCurrent ? (Theme.iconCheck + " active") : "The quick brown fox 123"
                                    font.family: modelData
                                    font.pixelSize: 10
                                    color: isCurrent ? Theme.on_primary : Theme.on_surface_variant
                                }
                            }

                            MouseArea {
                                id: fItemMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (root.fontTarget === "sans") {
                                        Settings.fontFamily = modelData
                                    } else {
                                        Settings.fontMono = modelData
                                    }
                                }
                            }
                        }
                    }
                }

                // Scaling Factor Buttons
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Repeater {
                        model: [
                            { label: "85%", s: 0.85 },
                            { label: "95%", s: 0.95 },
                            { label: "100%", s: 1.0 },
                            { label: "110%", s: 1.1 },
                            { label: "125%", s: 1.25 }
                        ]

                        delegate: Rectangle {
                            required property var modelData
                            Layout.fillWidth: true
                            height: 26
                            radius: Theme.radiusSm
                            color: Math.abs(Settings.fontScale - modelData.s) < 0.04 ? Theme.primary : Theme.surface_container_highest

                            Text {
                                text: modelData.label
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                                color: Math.abs(Settings.fontScale - modelData.s) < 0.04 ? Theme.on_primary : Theme.on_surface
                                anchors.centerIn: parent
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Settings.fontScale = modelData.s
                            }
                        }
                    }
                }
            }

            // TAB 4: ANIMATIONS & MOTION
            Flickable {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: root.activeTab === "animations"
                clip: true
                contentWidth: width
                contentHeight: animCol.implicitHeight
                boundsBehavior: Flickable.StopAtBounds

                ColumnLayout {
                    id: animCol
                    width: parent.width - 4
                    spacing: 12

                    Text {
                        text: "animation profiles & timing"
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeSm
                        font.weight: Font.Bold
                        color: Theme.primary
                    }

                    // Profile Cards
                    Repeater {
                        model: [
                            { id: "hyprland", label: "hyprland sync (default)", desc: "matches hyprland bezier curves & timing perfectly" },
                            { id: "snappy", label: "snappy & responsive", desc: "110ms ultra-fast transitions with zero delay" },
                            { id: "chill", label: "smooth & relaxed", desc: "luxurious 300ms cubic ease for smooth aesthetic" },
                            { id: "instant", label: "instant / zero lag", desc: "50ms minimal motion for raw performance" }
                        ]

                        delegate: Rectangle {
                            required property var modelData
                            Layout.fillWidth: true
                            height: 48
                            radius: Theme.radiusMd
                            color: Settings.animSpeed === modelData.id ? Theme.primary_overlay : Theme.surface_container_highest
                            border.color: Settings.animSpeed === modelData.id ? Theme.primary : "transparent"
                            border.width: 1

                            Behavior on color { ColorAnimation { duration: Theme.animFast } }

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: Theme.widgetPaddingH
                                spacing: 10

                                Text {
                                    text: Settings.animSpeed === modelData.id ? Theme.iconCheckCircle : Theme.iconFlame
                                    font.family: Theme.fontMono
                                    font.pixelSize: Theme.fontSizeSm
                                    color: Settings.animSpeed === modelData.id ? Theme.primary : Theme.on_surface_variant
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2

                                    Text {
                                        text: modelData.label
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.fontSizeSm
                                        font.weight: Font.Bold
                                        color: Theme.on_surface
                                    }

                                    Text {
                                        text: modelData.desc
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 10
                                        color: Theme.on_surface_variant
                                    }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Settings.animSpeed = modelData.id
                            }
                        }
                    }

                    // Interactive Motion Physics Test Box
                    Rectangle {
                        Layout.fillWidth: true
                        height: 64
                        radius: Theme.radiusMd
                        color: Theme.surface_container_low
                        border.color: Theme.widgetBorder
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 12

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                Text {
                                    text: "test motion physics"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSizeXs
                                    font.weight: Font.Bold
                                    color: Theme.on_surface
                                }
                                Text {
                                    text: "click to trigger live curve test"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 10
                                    color: Theme.on_surface_variant
                                }
                            }

                            Rectangle {
                                id: testBox
                                width: 40
                                height: 40
                                radius: Theme.radiusSm
                                color: testBoxMouse.pressed ? Theme.primary : Theme.surface_container_high

                                property real testScale: 1.0
                                scale: testScale

                                Behavior on scale {
                                    NumberAnimation { duration: Theme.animNormal; easing.type: Theme.animEasing }
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: Theme.kaoVibe
                                    font.family: Theme.fontMono
                                    font.pixelSize: 11
                                    color: Theme.primary
                                }

                                MouseArea {
                                    id: testBoxMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onPressed: testBox.testScale = 1.3
                                    onReleased: testBox.testScale = 1.0
                                }
                            }
                        }
                    }

                    // Open Full Drag Physics Sandbox Window
                    Rectangle {
                        Layout.fillWidth: true
                        height: 40
                        radius: Theme.widgetRadius
                        color: sandboxBtnMouse.containsMouse ? Theme.primary_overlay : Theme.surface_container_highest
                        border.color: Settings.showMotionSandbox ? Theme.primary : "transparent"
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: Theme.widgetPaddingH
                            spacing: 8

                            Text {
                                text: Theme.kaoDJ
                                font.family: Theme.fontMono
                                font.pixelSize: Theme.fontSizeSm
                                color: Theme.primary
                            }

                            Text {
                                text: Settings.showMotionSandbox ? "close motion sandbox window" : "open draggable physics sandbox"
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeXs
                                font.weight: Font.Bold
                                color: Theme.on_surface
                                Layout.fillWidth: true
                            }

                            Text {
                                text: Settings.showMotionSandbox ? "active " : "launch "
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                                color: Theme.primary
                            }
                        }

                        MouseArea {
                            id: sandboxBtnMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Settings.showMotionSandbox = !Settings.showMotionSandbox
                        }
                    }
                }
            }

            // TAB 5: VIBE & FLAVOR
            Flickable {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: root.activeTab === "vibe"
                clip: true
                contentWidth: width
                contentHeight: vibeCol.implicitHeight
                boundsBehavior: Flickable.StopAtBounds

                ColumnLayout {
                    id: vibeCol
                    width: parent.width - 4
                    spacing: 12

                    // Matugen Color Scheme Selector
                    Text {
                        text: "matugen palette scheme"
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeSm
                        font.weight: Font.Bold
                        color: Theme.primary
                    }

                    GridLayout {
                        Layout.fillWidth: true
                        columns: 2
                        rowSpacing: 6
                        columnSpacing: 6

                        Repeater {
                            model: [
                                { label: "tonal spot (default)", s: "scheme-tonal-spot" },
                                { label: "vibrant colors", s: "scheme-vibrant" },
                                { label: "expressive", s: "scheme-expressive" },
                                { label: "monochrome", s: "scheme-monochrome" }
                            ]

                            delegate: Rectangle {
                                required property var modelData
                                Layout.fillWidth: true
                                height: 32
                                radius: Theme.radiusSm
                                color: Settings.matugenScheme === modelData.s ? Theme.primary : Theme.surface_container_highest

                                Text {
                                    text: modelData.label
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 10
                                    font.weight: Font.Medium
                                    color: Settings.matugenScheme === modelData.s ? Theme.on_primary : Theme.on_surface
                                    anchors.centerIn: parent
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Settings.matugenScheme = modelData.s
                                }
                            }
                        }
                    }

                    // Wallpaper Transition
                    Text {
                        text: "wallpaper transition type"
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeSm
                        font.weight: Font.Bold
                        color: Theme.primary
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Repeater {
                            model: [
                                { label: "wave", t: "wave" },
                                { label: "wipe", t: "wipe" },
                                { label: "grow", t: "grow" },
                                { label: "fade", t: "fade" }
                            ]

                            delegate: Rectangle {
                                required property var modelData
                                Layout.fillWidth: true
                                height: 28
                                radius: Theme.radiusSm
                                color: Settings.awwwTransitionType === modelData.t ? Theme.primary : Theme.surface_container_highest

                                Text {
                                    text: modelData.label
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 10
                                    color: Settings.awwwTransitionType === modelData.t ? Theme.on_primary : Theme.on_surface
                                    anchors.centerIn: parent
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Settings.awwwTransitionType = modelData.t
                                }
                            }
                        }
                    }

                    // Unhinged Kaomoji Mode Toggle
                    Rectangle {
                        Layout.fillWidth: true
                        height: 48
                        radius: Theme.widgetRadius
                        color: Theme.surface_container_highest

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: Theme.widgetPaddingH
                            spacing: 8

                            Text {
                                text: Settings.unhingedFlavor ? Theme.kaoChaos : Theme.kaoCool
                                font.family: Theme.fontMono
                                font.pixelSize: Theme.fontSizeSm
                                color: Theme.primary
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                Text {
                                    text: "unhinged kaomoji flavor"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSizeSm
                                    font.weight: Font.Bold
                                    color: Theme.on_surface
                                }
                                Text {
                                    text: Settings.unhingedFlavor ? ("active: " + Theme.kaoHappy + " visual dopamine") : "minimal plain text"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 10
                                    color: Theme.on_surface_variant
                                }
                            }

                            ToggleSwitch {
                                checked: Settings.unhingedFlavor
                                onToggled: Settings.unhingedFlavor = !Settings.unhingedFlavor
                            }
                        }
                    }
                }
            }
        }
    }
}
