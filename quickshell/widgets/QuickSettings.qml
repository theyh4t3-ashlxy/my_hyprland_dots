import QtQuick
import QtQuick.Layouts
import ".."
import Quickshell

Rectangle {
    id: root
    implicitWidth: Theme.isVertical ? Theme.barHeight - 8 : qsRow.implicitWidth + 24
    implicitHeight: Theme.barHeight - 8
    radius: Theme.radiusPill
    color: popup.open ? Theme.primary_overlay : (qsMouse.containsMouse ? Theme.pillHover : Theme.pillBg)
    border.color: Theme.pillBorder
    border.width: Theme.pillBorder === "transparent" ? 0 : 1

    Behavior on color { ColorAnimation { duration: Theme.animFast } }
    Behavior on border.color { ColorAnimation { duration: Theme.animFast } }

    property string activeTab: "layout"
    property string fontTarget: "sans" // "sans" or "mono"
    property string fontSearchQuery: ""
    property bool showResetConfirm: false

    readonly property var allFonts: {
        let f = Qt.fontFamilies();
        return f.slice().sort();
    }
    readonly property var filteredFonts: {
        if (!fontSearchQuery || fontSearchQuery.trim() === "") return allFonts;
        const q = fontSearchQuery.trim().toLowerCase();
        return allFonts.filter(f => f.toLowerCase().includes(q));
    }

    component CategoryHeader: RowLayout {
        id: catHdr
        property string title: ""
        property string icon: ""
        Layout.fillWidth: true
        spacing: 8
        Layout.topMargin: 8
        Layout.bottomMargin: 2

        Text {
            visible: catHdr.icon !== ""
            text: catHdr.icon
            font.family: Theme.fontIcon
            font.pixelSize: Theme.fontSizeSm
            color: Theme.primary
        }

        Text {
            text: catHdr.title
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeXs
            font.weight: Font.Bold
            color: Theme.primary
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Theme.widgetBorder
        }
    }

    Row {
        id: qsRow
        anchors.centerIn: parent
        spacing: 4

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Theme.iconSettings
            font.family: Theme.fontIcon
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
            popup.targetRelativeY = root.mapToItem(null, 0, 0).y + (root.height / 2)
            popup.open = !popup.open
        }
    }

    PopupPanel {
        id: popup
        cardWidth: 480
        cardHeight: 640
        targetRelativeX: root.mapToItem(null, 0, 0).x + (root.width / 2)
        targetRelativeY: root.mapToItem(null, 0, 0).y + (root.height / 2)

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
                            font.family: Theme.fontIcon
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

                Rectangle {
                    height: 24
                    implicitWidth: resetBadgeRow.implicitWidth + 16
                    radius: Theme.radiusPill
                    color: rMouse.containsMouse ? Theme.error_overlay : Theme.surface_container_highest
                    border.color: rMouse.containsMouse ? Theme.error : "transparent"
                    border.width: 1

                    Behavior on color { ColorAnimation { duration: Theme.animFast } }
                    Behavior on border.color { ColorAnimation { duration: Theme.animFast } }

                    RowLayout {
                        id: resetBadgeRow
                        anchors.centerIn: parent
                        spacing: 4

                        Text {
                            text: Theme.iconHistory
                            font.family: Theme.fontIcon
                            font.pixelSize: 10
                            color: rMouse.containsMouse ? Theme.error : Theme.on_surface_variant
                        }

                        Text {
                            text: "reset stock"
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                            font.weight: Font.Medium
                            color: rMouse.containsMouse ? Theme.error : Theme.on_surface_variant
                        }
                    }

                    MouseArea {
                        id: rMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.showResetConfirm = true
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
                                    font.family: Theme.fontIcon
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
                    spacing: 10

                    CategoryHeader {
                        title: "bar geometry & position"
                        icon: Theme.iconGrid
                    }

                    Text {
                        text: "screen placement"
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeXs
                        color: Theme.on_surface_variant
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
                                readonly property bool isSelected: Settings.barPosition === modelData.pos
                                    || (modelData.pos === "top" && Settings.barPosition === "up")
                                    || (modelData.pos === "bottom" && Settings.barPosition === "down")
                                Layout.fillWidth: true
                                height: 32
                                radius: Theme.radiusSm
                                color: isSelected ? Theme.primary : Theme.surface_container_highest

                                Text {
                                    text: modelData.label
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSizeXs
                                    font.weight: Font.Bold
                                    color: isSelected ? Theme.on_primary : Theme.on_surface
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

                    Text {
                        text: "bar thickness: " + Settings.barHeight + "px"
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeXs
                        color: Theme.on_surface_variant
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

                    Text {
                        text: "aesthetic theme & materials"
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeXs
                        color: Theme.on_surface_variant
                    }

                    GridLayout {
                        Layout.fillWidth: true
                        columns: 2
                        rowSpacing: 6
                        columnSpacing: 6

                        Repeater {
                            model: [
                                { label: "glass theme", s: "glass" },
                                { label: "pure black (oled)", s: "pure-black" },
                                { label: "translucent (glass)", s: "translucent" },
                                { label: "accent glow (cyber)", s: "accent-glow" },
                                { label: "monochrome", s: "monochrome" }
                            ]

                            delegate: Rectangle {
                                required property var modelData
                                Layout.fillWidth: true
                                height: 30
                                radius: Theme.radiusSm
                                color: Settings.barStyle === modelData.s ? Theme.primary : Theme.surface_container_highest

                                Text {
                                    text: modelData.label
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 10
                                    font.weight: Font.Medium
                                    color: Settings.barStyle === modelData.s ? Theme.on_primary : Theme.on_surface
                                    anchors.centerIn: parent
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Settings.barStyle = modelData.s
                                }
                            }
                        }
                    }

                    CategoryHeader {
                        title: "screen corners & scoops"
                        icon: Theme.iconSparkles
                    }

                    Text {
                        text: "screen corner fillets"
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeXs
                        color: Theme.on_surface_variant
                    }

                    GridLayout {
                        Layout.fillWidth: true
                        columns: 3
                        rowSpacing: 6
                        columnSpacing: 6

                        Repeater {
                            model: [
                                { label: "all 4 corners", m: "all" },
                                { label: "top only", m: "top" },
                                { label: "bottom only", m: "bottom" },
                                { label: "left only", m: "left" },
                                { label: "right only", m: "right" },
                                { label: "bar opposite", m: "opposite" },
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

                    Text {
                        text: "corner curvature style"
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeXs
                        color: Theme.on_surface_variant
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Repeater {
                            model: [
                                { label: "cubic", s: "cubic" },
                                { label: "squircle", s: "squircle" },
                                { label: "chamfer 45°", s: "chamfer" },
                                { label: "flared", s: "flared" },
                                { label: "stepped", s: "stepped" }
                            ]

                            delegate: Rectangle {
                                required property var modelData
                                Layout.fillWidth: true
                                height: 28
                                radius: Theme.radiusSm
                                color: Settings.cornerStyle === modelData.s ? Theme.primary : Theme.surface_container_highest

                                Text {
                                    text: modelData.label
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 10
                                    color: Settings.cornerStyle === modelData.s ? Theme.on_primary : Theme.on_surface
                                    anchors.centerIn: parent
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Settings.cornerStyle = modelData.s
                                }
                            }
                        }
                    }

                    Text {
                        text: "corner color mode"
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeXs
                        color: Theme.on_surface_variant
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Repeater {
                            model: [
                                { label: "bar match", c: "bar" },
                                { label: "matugen theme", c: "theme" },
                                { label: "accent", c: "accent" },
                                { label: "pure black", c: "pure-black" }
                            ]

                            delegate: Rectangle {
                                required property var modelData
                                Layout.fillWidth: true
                                height: 28
                                radius: Theme.radiusSm
                                color: Settings.cornerColorMode === modelData.c ? Theme.primary : Theme.surface_container_highest

                                Text {
                                    text: modelData.label
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 10
                                    color: Settings.cornerColorMode === modelData.c ? Theme.on_primary : Theme.on_surface
                                    anchors.centerIn: parent
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Settings.cornerColorMode = modelData.c
                                }
                            }
                        }
                    }

                    Text {
                        text: "screen corner radius: " + Settings.screenCornerRadius + "px"
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeXs
                        color: Theme.on_surface_variant
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Repeater {
                            model: [0, 10, 14, 16, 20, 24]
                            delegate: Rectangle {
                                required property int modelData
                                Layout.fillWidth: true
                                height: 28
                                radius: Theme.radiusSm
                                color: Settings.screenCornerRadius === modelData ? Theme.primary : Theme.surface_container_highest

                                Text {
                                    text: modelData === 0 ? "none" : (modelData + "px")
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 10
                                    color: Settings.screenCornerRadius === modelData ? Theme.on_primary : Theme.on_surface
                                    anchors.centerIn: parent
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Settings.screenCornerRadius = modelData
                                }
                            }
                        }
                    }

                    Text {
                        text: "concave scoop radius: " + Settings.scoopRadius + "px"
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeXs
                        color: Theme.on_surface_variant
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

                    CategoryHeader {
                        title: "launcher & workspace navigation"
                        icon: Theme.iconWorkspaces
                    }

                    Repeater {
                        model: [
                            { prop: "showLauncher", label: "application launcher" },
                            { prop: "showWorkspaces", label: "workspaces switcher" },
                            { prop: "showWindowTitle", label: "window title" }
                        ]

                        delegate: Rectangle {
                            required property var modelData
                            Layout.fillWidth: true
                            height: 38
                            radius: Theme.widgetRadius
                            color: Theme.cardBg
                            border.color: Theme.cardBorder
                            border.width: 1

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

                    CategoryHeader {
                        title: "status & media players"
                        icon: Theme.iconMusic
                    }

                    Repeater {
                        model: [
                            { prop: "showClock", label: "clock & date" },
                            { prop: "showMedia", label: "now playing / mpris" },
                            { prop: "showWallpaper", label: "wallpaper & theme browser" },
                            { prop: "showVolume", label: "volume & audio mixer" }
                        ]

                        delegate: Rectangle {
                            required property var modelData
                            Layout.fillWidth: true
                            height: 38
                            radius: Theme.widgetRadius
                            color: Theme.cardBg
                            border.color: Theme.cardBorder
                            border.width: 1

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

                    CategoryHeader {
                        title: "connectivity & hardware"
                        icon: Theme.iconWifi
                    }

                    Repeater {
                        model: [
                            { prop: "showNetwork", label: "network / wifi" },
                            { prop: "showBluetooth", label: "bluetooth" },
                            { prop: "showBattery", label: "battery status" },
                            { prop: "showSystemTray", label: "system tray" },
                            { prop: "showNotifications", label: "notifications center" }
                        ]

                        delegate: Rectangle {
                            required property var modelData
                            Layout.fillWidth: true
                            height: 38
                            radius: Theme.widgetRadius
                            color: Theme.cardBg
                            border.color: Theme.cardBorder
                            border.width: 1

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

                    CategoryHeader {
                        title: "tools & system utilities"
                        icon: Theme.iconSliders
                    }

                    Repeater {
                        model: [
                            { prop: "showIdleInhibitor", label: "caffeine / idle inhibitor" },
                            { prop: "showClipboard", label: "clipboard history" },
                            { prop: "showQuickNotes", label: "quick notes & scratchpad" },
                            { prop: "showPowerMenu", label: "power session menu" }
                        ]

                        delegate: Rectangle {
                            required property var modelData
                            Layout.fillWidth: true
                            height: 38
                            radius: Theme.widgetRadius
                            color: Theme.cardBg
                            border.color: Theme.cardBorder
                            border.width: 1

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

            // TAB 3: FONTS & TYPOGRAPHY
            Flickable {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: root.activeTab === "fonts"
                clip: true
                contentWidth: width
                contentHeight: fontCol.implicitHeight
                boundsBehavior: Flickable.StopAtBounds

                ColumnLayout {
                    id: fontCol
                    width: parent.width - 4
                    spacing: 10

                    CategoryHeader {
                        title: "font target & search"
                        icon: Theme.iconNote
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Rectangle {
                            Layout.fillWidth: true
                            height: 32
                            radius: Theme.radiusSm
                            color: root.fontTarget === "sans" ? Theme.primary : Theme.surface_container_highest

                            Text {
                                text: "interface: " + Settings.fontFamily
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
                        color: Theme.cardBg
                        radius: Theme.widgetRadius
                        border.color: fontSearchInput.activeFocus ? Theme.primary : Theme.cardBorder
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: Theme.widgetPaddingH
                            spacing: 8

                            Text {
                                text: Theme.iconSearch
                                font.family: Theme.fontIcon
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

                            IconButton {
                                visible: fontSearchInput.text !== ""
                                icon: Theme.iconClose
                                iconSize: 10
                                tooltip: "clear search"
                                onClicked: {
                                    fontSearchInput.text = "";
                                    root.fontSearchQuery = "";
                                }
                            }
                        }
                    }

                    // Live Font List Browser
                    Rectangle {
                        Layout.fillWidth: true
                        height: 160
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
                                            Settings.fontFamily = modelData;
                                        } else {
                                            Settings.fontMono = modelData;
                                        }
                                    }
                                }
                            }
                        }
                    }

                    CategoryHeader {
                        title: "typography scale & weight"
                        icon: Theme.iconSliders
                    }

                    Text {
                        text: "interface font scaling"
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeXs
                        color: Theme.on_surface_variant
                    }

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

                    Text {
                        text: "font weight: " + Settings.fontWeight
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeXs
                        color: Theme.on_surface_variant
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Repeater {
                            model: [
                                { label: "light", w: "light" },
                                { label: "regular", w: "regular" },
                                { label: "medium", w: "medium" },
                                { label: "demibold", w: "demibold" },
                                { label: "bold", w: "bold" }
                            ]

                            delegate: Rectangle {
                                required property var modelData
                                Layout.fillWidth: true
                                height: 26
                                radius: Theme.radiusSm
                                color: Settings.fontWeight === modelData.w ? Theme.primary : Theme.surface_container_highest

                                Text {
                                    text: modelData.label
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 10
                                    color: Settings.fontWeight === modelData.w ? Theme.on_primary : Theme.on_surface
                                    anchors.centerIn: parent
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Settings.fontWeight = modelData.w
                                }
                            }
                        }
                    }

                    CategoryHeader {
                        title: "icon glyph pack"
                        icon: Theme.iconSparkles
                    }

                    GridLayout {
                        columns: 3
                        Layout.fillWidth: true
                        columnSpacing: 6
                        rowSpacing: 6

                        Repeater {
                            model: [
                                { label: "material",        id: "material" },
                                { label: "windows segoe",   id: "windows" },
                                { label: "font awesome",    id: "awesome" },
                                { label: "(ﾉ◕ヮ◕)ﾉ kaomoji", id: "kaomoji" },
                                { label: "󰦨 plain text",    id: "text" }
                            ]

                            delegate: Rectangle {
                                required property var modelData
                                Layout.fillWidth: true
                                height: 32
                                radius: Theme.radiusSm
                                color: Settings.iconSet === modelData.id ? Theme.primary : Theme.surface_container_highest

                                Text {
                                    text: modelData.label
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 10
                                    font.weight: Font.Medium
                                    color: Settings.iconSet === modelData.id ? Theme.on_primary : Theme.on_surface
                                    anchors.centerIn: parent
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        Settings.iconSet = modelData.id;
                                        if (modelData.id === "kaomoji" || modelData.id === "text") {
                                            Settings.vibeStyle = modelData.id;
                                        } else {
                                            Settings.vibeStyle = "nerd";
                                        }
                                    }
                                }
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
                    spacing: 10

                    CategoryHeader {
                        title: "shell animation profiles"
                        icon: Theme.iconFlame
                    }

                    Repeater {
                        model: [
                            { id: "hyprland", label: "hyprland sync (default)", desc: "matches hyprland bezier curves & timing" },
                            { id: "snappy", label: "snappy & responsive", desc: "110ms ultra-fast transitions with zero delay" },
                            { id: "chill", label: "smooth & relaxed", desc: "luxurious 300ms cubic ease for aesthetic flow" },
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

                    CategoryHeader {
                        title: "interactive physics lab"
                        icon: Theme.iconSliders
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 64
                        radius: Theme.radiusMd
                        color: sandboxBtnMouse.containsMouse ? Theme.surface_container_highest : Theme.surface_container_low
                        border.color: Settings.showMotionSandbox ? Theme.primary : Theme.widgetBorder
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 12

                            Rectangle {
                                width: 40
                                height: 40
                                radius: Theme.radiusSm
                                color: Settings.showMotionSandbox ? Theme.primary_overlay : Theme.surface_container_high

                                Text {
                                    anchors.centerIn: parent
                                    text: "󰑮"
                                    font.family: Theme.fontIcon
                                    font.pixelSize: Theme.fontSizeMd
                                    color: Theme.primary
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                Text {
                                    text: "draggable physics sandbox"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSizeSm
                                    font.weight: Font.Bold
                                    color: Theme.on_surface
                                }
                                Text {
                                    text: Settings.showMotionSandbox ? "sandbox active on screen edge (click to close)" : "open interactive canvas with 4-way docking & physics"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 10
                                    color: Theme.on_surface_variant
                                }
                            }

                            Rectangle {
                                height: 26
                                implicitWidth: launchText.implicitWidth + 14
                                radius: Theme.radiusPill
                                color: Settings.showMotionSandbox ? Theme.primary : Theme.primary_overlay

                                Text {
                                    id: launchText
                                    anchors.centerIn: parent
                                    text: Settings.showMotionSandbox ? "active " : "test "
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 10
                                    font.weight: Font.Bold
                                    color: Settings.showMotionSandbox ? Theme.on_primary : Theme.primary
                                }
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

            // TAB 5: VIBE, PERSONALITY & FORMATS
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
                    spacing: 10



                    // Unhinged Personality Flavor Toggle
                    Rectangle {
                        Layout.fillWidth: true
                        height: 44
                        radius: Theme.radiusSm
                        color: Theme.surface_container_highest
                        border.color: Settings.unhingedFlavor ? Theme.primary : Theme.widgetBorder
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 10

                            Text {
                                text: Theme.iconFlame
                                font.family: Theme.fontIcon
                                font.pixelSize: Theme.fontSizeMd
                                color: Settings.unhingedFlavor ? Theme.primary : Theme.on_surface_variant
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 1

                                Text {
                                    text: "unhinged flavor text"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSizeXs
                                    font.weight: Font.Bold
                                    color: Theme.on_surface
                                }

                                Text {
                                    text: "chaotic system status vibes"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 9
                                    color: Theme.on_surface_variant
                                }
                            }

                            ToggleSwitch {
                                checked: Settings.unhingedFlavor
                                onToggled: Settings.unhingedFlavor = !Settings.unhingedFlavor
                            }
                        }
                    }

                    // Do Not Disturb Toggle
                    Rectangle {
                        Layout.fillWidth: true
                        height: 44
                        radius: Theme.radiusSm
                        color: Theme.surface_container_highest
                        border.color: Settings.dnd ? Theme.primary : Theme.widgetBorder
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 10

                            Text {
                                text: Settings.dnd ? Theme.iconBellOff : Theme.iconBell
                                font.family: Theme.fontIcon
                                font.pixelSize: Theme.fontSizeMd
                                color: Settings.dnd ? Theme.primary : Theme.on_surface_variant
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 1

                                Text {
                                    text: "do not disturb"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSizeXs
                                    font.weight: Font.Bold
                                    color: Theme.on_surface
                                }

                                Text {
                                    text: "silence incoming notification toasts"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 9
                                    color: Theme.on_surface_variant
                                }
                            }

                            ToggleSwitch {
                                checked: Settings.dnd
                                onToggled: Settings.dnd = !Settings.dnd
                            }
                        }
                    }

                    CategoryHeader {
                        title: "clock & date display formats"
                        icon: Theme.iconClock
                    }

                    // Show Date in Status Bar Toggle
                    Rectangle {
                        Layout.fillWidth: true
                        height: 44
                        radius: Theme.radiusSm
                        color: Theme.surface_container_highest
                        border.color: Settings.showBarDate ? Theme.primary : Theme.widgetBorder
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 10

                            Text {
                                text: Theme.iconCalendar
                                font.family: Theme.fontIcon
                                font.pixelSize: Theme.fontSizeMd
                                color: Settings.showBarDate ? Theme.primary : Theme.on_surface_variant
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 1

                                Text {
                                    text: "show date in status bar"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSizeXs
                                    font.weight: Font.Bold
                                    color: Theme.on_surface
                                }

                                Text {
                                    text: "keep bar clean with time only; click clock to view calendar"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 9
                                    color: Theme.on_surface_variant
                                }
                            }

                            ToggleSwitch {
                                checked: Settings.showBarDate
                                onToggled: Settings.showBarDate = !Settings.showBarDate
                            }
                        }
                    }

                    Text {
                        text: "clock time format"
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeXs
                        color: Theme.on_surface_variant
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Repeater {
                            model: [
                                { label: "24-hour (16:45)", fmt: "HH:mm" },
                                { label: "12-hour (4:45 pm)", fmt: "h:mm ap" },
                                { label: "seconds (16:45:00)", fmt: "HH:mm:ss" }
                            ]

                            delegate: Rectangle {
                                required property var modelData
                                Layout.fillWidth: true
                                height: 28
                                radius: Theme.radiusSm
                                color: Settings.clockFormat === modelData.fmt ? Theme.primary : Theme.surface_container_highest

                                Text {
                                    text: modelData.label
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 10
                                    font.weight: Font.Medium
                                    color: Settings.clockFormat === modelData.fmt ? Theme.on_primary : Theme.on_surface
                                    anchors.centerIn: parent
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Settings.clockFormat = modelData.fmt
                                }
                            }
                        }
                    }

                    Text {
                        text: "date display format"
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeXs
                        color: Theme.on_surface_variant
                    }

                    GridLayout {
                        columns: 2
                        Layout.fillWidth: true
                        columnSpacing: 6
                        rowSpacing: 6

                        Repeater {
                            model: [
                                { label: "hidden (time only)", fmt: "none" },
                                { label: "short (Mon, Sep 1)", fmt: "ddd, MMM d" },
                                { label: "standard (Sep 1)", fmt: "MMM d, yyyy" },
                                { label: "iso (2026-09-01)", fmt: "yyyy-MM-dd" }
                            ]

                            delegate: Rectangle {
                                required property var modelData
                                Layout.fillWidth: true
                                height: 28
                                radius: Theme.radiusSm
                                readonly property bool isCurrent: (modelData.fmt === "none" && !Settings.showBarDate) || (Settings.showBarDate && Settings.dateFormat === modelData.fmt)
                                color: isCurrent ? Theme.primary : Theme.surface_container_highest

                                Text {
                                    text: modelData.label
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 10
                                    font.weight: Font.Medium
                                    color: isCurrent ? Theme.on_primary : Theme.on_surface
                                    anchors.centerIn: parent
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (modelData.fmt === "none") {
                                            Settings.showBarDate = false;
                                        } else {
                                            Settings.dateFormat = modelData.fmt;
                                            Settings.showBarDate = true;
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Text {
                        text: "workspace capacity: " + Settings.workspaceCount
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeXs
                        color: Theme.on_surface_variant
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Repeater {
                            model: [5, 8, 10, 12, 16]

                            delegate: Rectangle {
                                required property int modelData
                                Layout.fillWidth: true
                                height: 28
                                radius: Theme.radiusSm
                                color: Settings.workspaceCount === modelData ? Theme.primary : Theme.surface_container_highest

                                Text {
                                    text: modelData + " spaces"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 10
                                    color: Settings.workspaceCount === modelData ? Theme.on_primary : Theme.on_surface
                                    anchors.centerIn: parent
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Settings.workspaceCount = modelData
                                }
                            }
                        }
                    }

                    CategoryHeader {
                        title: "local network aliases"
                        icon: Theme.iconWifi
                    }

                    readonly property var aliasKeys: Object.keys(Settings.networkAliases || {})

                    Text {
                        visible: vibeCol.aliasKeys.length === 0
                        text: "no custom network aliases saved yet.\nclick the pencil icon on your active network in the wi-fi popup to name it."
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                        color: Theme.on_surface_variant
                        lineHeight: 1.3
                    }

                    Repeater {
                        model: vibeCol.aliasKeys

                        delegate: Rectangle {
                            required property string modelData
                            Layout.fillWidth: true
                            height: 36
                            radius: Theme.radiusSm
                            color: Theme.surface_container_highest
                            border.color: Theme.widgetBorder
                            border.width: 1

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 8
                                spacing: 8

                                Text {
                                    text: Theme.iconWifi
                                    font.family: Theme.fontIcon
                                    font.pixelSize: Theme.fontSizeXs
                                    color: Theme.primary
                                }

                                Text {
                                    text: (Settings.networkAliases && Settings.networkAliases[modelData]) || ""
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSizeXs
                                    font.weight: Font.Bold
                                    color: Theme.on_surface
                                }

                                Text {
                                    text: "(" + modelData + ")"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 10
                                    color: Theme.on_surface_variant
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                }

                                IconButton {
                                    icon: Theme.iconTrash
                                    iconSize: 10
                                    tooltip: "remove alias"
                                    onClicked: Settings.setNetworkAlias(modelData, "")
                                }
                            }
                        }
                    }

                    CategoryHeader {
                        title: "factory reset"
                        icon: Theme.iconFlame
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 52
                        radius: Theme.widgetRadius
                        color: nukeMouse.containsMouse ? Theme.error_overlay : Theme.surface_container_highest
                        border.color: nukeMouse.containsMouse ? Theme.error : Theme.widgetBorder
                        border.width: 1

                        Behavior on color { ColorAnimation { duration: Theme.animFast } }
                        Behavior on border.color { ColorAnimation { duration: Theme.animFast } }

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: Theme.widgetPaddingH
                            spacing: 12

                            Text {
                                text: Theme.iconFlame
                                font.family: Theme.fontIcon
                                font.pixelSize: Theme.fontSizeMd
                                color: Theme.error
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                Text {
                                    text: "nuke all custom settings"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSizeSm
                                    font.weight: Font.Bold
                                    color: Theme.on_surface
                                }

                                Text {
                                    text: "wipe all tweaks and restore stock defaults"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSizeXs
                                    color: Theme.on_surface_variant
                                }
                            }

                            Rectangle {
                                width: 72
                                height: 28
                                radius: Theme.radiusSm
                                color: Theme.error

                                Text {
                                    text: "nuke"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSizeXs
                                    font.weight: Font.Bold
                                    color: Theme.on_error
                                    anchors.centerIn: parent
                                }
                            }
                        }

                        MouseArea {
                            id: nukeMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.showResetConfirm = true
                        }
                    }
                }
            }
        }

        // nuke confirmation modal overlay
        Rectangle {
            id: resetConfirmModal
            anchors.fill: parent
            color: Theme.alpha(Theme.background, 0.94)
            visible: root.showResetConfirm
            z: 999
            radius: Theme.popupRadius

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
            }

            ColumnLayout {
                anchors.centerIn: parent
                width: Math.min(parent.width - 48, 380)
                spacing: 16

                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    width: 56
                    height: 56
                    radius: Theme.radiusPill
                    color: Theme.error_overlay

                    Text {
                        anchors.centerIn: parent
                        text: Theme.iconFlame
                        font.family: Theme.fontIcon
                        font.pixelSize: Theme.fontSizeXl
                        color: Theme.error
                    }
                }

                Text {
                    text: "nuke all custom settings?"
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeLg
                    font.weight: Font.Bold
                    color: Theme.on_surface
                    Layout.alignment: Qt.AlignHCenter
                }

                Text {
                    text: "are you sure? this will wipe every tweak and revert everything back to stock defaults. there is no going back."
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSm
                    color: Theme.on_surface_variant
                    wrapMode: Text.Wrap
                    horizontalAlignment: Text.AlignHCenter
                    Layout.fillWidth: true
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    Rectangle {
                        Layout.fillWidth: true
                        height: 38
                        radius: Theme.radiusSm
                        color: cancelMouse.containsMouse ? Theme.surface_container_high : Theme.surface_container_highest
                        border.color: Theme.widgetBorder
                        border.width: 1

                        Text {
                            text: "nevermind"
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeSm
                            color: Theme.on_surface
                            anchors.centerIn: parent
                        }

                        MouseArea {
                            id: cancelMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.showResetConfirm = false
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 38
                        radius: Theme.radiusSm
                        color: confirmMouse.containsMouse ? Theme.error_container : Theme.error

                        Text {
                            text: "nuke everything"
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeSm
                            font.weight: Font.Bold
                            color: confirmMouse.containsMouse ? Theme.on_error_container : Theme.on_error
                            anchors.centerIn: parent
                        }

                        MouseArea {
                            id: confirmMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                Settings.resetToDefaults();
                                root.showResetConfirm = false;
                            }
                        }
                    }
                }
            }
        }
    }
}
