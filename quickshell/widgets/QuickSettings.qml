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
    property string fontTarget: "sans"
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

    component SettingCard: Rectangle {
        default property alias content: cardCol.data
        Layout.fillWidth: true
        width: parent ? parent.width : 0
        implicitHeight: cardCol.implicitHeight
        radius: Theme.widgetRadius
        color: Theme.cardBg
        border.color: Theme.cardBorder
        border.width: 1
        clip: true

        Column {
            id: cardCol
            width: parent.width
            spacing: 0
        }
    }

    component RowDivider: Rectangle {
        width: parent ? parent.width : 0
        height: 1
        color: Theme.widgetBorder
    }

    component ToggleRow: Rectangle {
        id: trRoot
        property string icon: ""
        property string title: ""
        property string subtitle: ""
        property bool checked: false
        signal toggled()

        width: parent ? parent.width : 0
        Layout.fillWidth: true
        implicitHeight: subtitle !== "" ? 48 : 38
        color: trMouse.containsMouse ? Theme.surface_container_highest : "transparent"
        Behavior on color { ColorAnimation { duration: Theme.animFast } }

        Text {
            id: trIcon
            visible: trRoot.icon !== ""
            anchors.left: parent.left
            anchors.leftMargin: Theme.widgetPaddingH
            anchors.verticalCenter: parent.verticalCenter
            width: visible ? 18 : 0
            text: trRoot.icon
            font.family: Theme.fontIcon
            font.pixelSize: Theme.fontSizeSm
            color: trRoot.checked ? Theme.primary : Theme.on_surface_variant
            horizontalAlignment: Text.AlignHCenter
        }

        ToggleSwitch {
            id: trSwitch
            anchors.right: parent.right
            anchors.rightMargin: Theme.widgetPaddingH
            anchors.verticalCenter: parent.verticalCenter
            checked: trRoot.checked
            onToggled: trRoot.toggled()
        }

        Column {
            anchors.left: trIcon.visible ? trIcon.right : parent.left
            anchors.leftMargin: trIcon.visible ? 10 : Theme.widgetPaddingH
            anchors.right: trSwitch.left
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            spacing: 1

            Text {
                width: parent.width
                text: trRoot.title
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeSm
                color: Theme.on_surface
                elide: Text.ElideRight
            }

            Text {
                visible: trRoot.subtitle !== ""
                width: parent.width
                text: trRoot.subtitle
                font.family: Theme.fontFamily
                font.pixelSize: 9
                color: Theme.on_surface_variant
                elide: Text.ElideRight
            }
        }

        MouseArea {
            id: trMouse
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.right: trSwitch.left
            anchors.rightMargin: 8
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: trRoot.toggled()
        }
    }

    component ChoiceRow: ColumnLayout {
        id: crRoot
        property string title: ""
        property var model: []
        property var currentValue
        property int buttonHeight: 28
        signal selected(var value)

        Layout.fillWidth: true
        width: parent ? parent.width : 0
        spacing: 6

        Text {
            visible: crRoot.title !== ""
            text: crRoot.title
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeXs
            color: Theme.on_surface_variant
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Repeater {
                model: crRoot.model

                delegate: Rectangle {
                    required property var modelData
                    readonly property var itemVal: modelData.value !== undefined ? modelData.value : (modelData.pos !== undefined ? modelData.pos : (modelData.s !== undefined ? modelData.s : (modelData.w !== undefined ? modelData.w : (modelData.c !== undefined ? modelData.c : (modelData.fmt !== undefined ? modelData.fmt : modelData)))))
                    readonly property string itemText: modelData.label !== undefined ? modelData.label : (typeof modelData === "number" ? (modelData === 0 ? "none" : modelData + "px") : String(modelData))
                    readonly property bool isSelected: (typeof crRoot.currentValue === "number" && typeof itemVal === "number" && !Number.isInteger(itemVal))
                        ? Math.abs(crRoot.currentValue - itemVal) < 0.04
                        : crRoot.currentValue === itemVal

                    Layout.fillWidth: true
                    height: crRoot.buttonHeight
                    radius: Theme.radiusSm
                    color: isSelected ? Theme.primary : (crMouse.containsMouse ? Theme.surface_container_high : Theme.surface_container_highest)

                    Behavior on color { ColorAnimation { duration: Theme.animFast } }

                    Text {
                        anchors.centerIn: parent
                        text: itemText
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                        font.weight: isSelected ? Font.Bold : Font.Normal
                        color: isSelected ? Theme.on_primary : Theme.on_surface
                        elide: Text.ElideRight
                    }

                    MouseArea {
                        id: crMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: crRoot.selected(itemVal)
                    }
                }
            }
        }
    }

    component ChoiceGrid: ColumnLayout {
        id: cgRoot
        property string title: ""
        property int columns: 2
        property var model: []
        property var currentValue
        property int buttonHeight: 28
        signal selected(var value)

        Layout.fillWidth: true
        width: parent ? parent.width : 0
        spacing: 6

        Text {
            visible: cgRoot.title !== ""
            text: cgRoot.title
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeXs
            color: Theme.on_surface_variant
        }

        GridLayout {
            Layout.fillWidth: true
            columns: cgRoot.columns
            rowSpacing: 6
            columnSpacing: 6

            Repeater {
                model: cgRoot.model

                delegate: Rectangle {
                    required property var modelData
                    readonly property var itemVal: modelData.value !== undefined ? modelData.value : (modelData.id !== undefined ? modelData.id : (modelData.s !== undefined ? modelData.s : (modelData.m !== undefined ? modelData.m : (modelData.fmt !== undefined ? modelData.fmt : modelData))))
                    readonly property string itemText: modelData.label !== undefined ? modelData.label : String(modelData)
                    readonly property bool isSelected: cgRoot.currentValue === itemVal

                    Layout.fillWidth: true
                    height: cgRoot.buttonHeight
                    radius: Theme.radiusSm
                    color: isSelected ? Theme.primary : (cgMouse.containsMouse ? Theme.surface_container_high : Theme.surface_container_highest)

                    Behavior on color { ColorAnimation { duration: Theme.animFast } }

                    Text {
                        anchors.centerIn: parent
                        text: itemText
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                        font.weight: isSelected ? Font.Bold : Font.Normal
                        color: isSelected ? Theme.on_primary : Theme.on_surface
                        elide: Text.ElideRight
                    }

                    MouseArea {
                        id: cgMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: cgRoot.selected(itemVal)
                    }
                }
            }
        }
    }

    component TabScrollTrack: Rectangle {
        id: stRoot
        required property Flickable target
        anchors.right: target.right
        anchors.top: target.top
        anchors.bottom: target.bottom
        anchors.margins: 2
        width: 3
        radius: 1.5
        color: "transparent"
        visible: target.visibleArea.heightRatio < 1.0

        Rectangle {
            width: parent.width
            y: Math.max(0, Math.min(stRoot.height - height, stRoot.target.visibleArea.yPosition * stRoot.height))
            height: Math.max(16, stRoot.target.visibleArea.heightRatio * stRoot.height)
            radius: 1.5
            color: Theme.primary_overlay
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
            const p = root.mapToItem(null, 0, 0);
            popup.targetRelativeX = p.x + (root.width / 2);
            popup.targetRelativeY = p.y + (root.height / 2);
            popup.open = !popup.open;
        }
    }

    PopupPanel {
        id: popup
        cardWidth: 480
        cardHeight: 640

        content: ColumnLayout {
            anchors.fill: parent
            anchors.margins: Theme.widgetPaddingH
            spacing: Theme.widgetSpacing

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

            Flickable {
                Layout.fillWidth: true
                height: 36
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
                            color: root.activeTab === modelData.id ? Theme.primary : (tabMouse.containsMouse ? Theme.surface_container_high : Theme.surface_container_highest)

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
                                id: tabMouse
                                anchors.fill: parent
                                hoverEnabled: true
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

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                Flickable {
                    id: flickLayout
                    anchors.fill: parent
                    visible: root.activeTab === "layout"
                    clip: true
                    contentWidth: width
                    contentHeight: layoutCol.implicitHeight
                    boundsBehavior: Flickable.StopAtBounds

                    ColumnLayout {
                        id: layoutCol
                        width: parent.width - 6
                        spacing: 10

                        CategoryHeader {
                            title: "bar geometry & position"
                            icon: Theme.iconGrid
                        }

                        ChoiceRow {
                            title: "screen placement"
                            model: [
                                { label: "top", value: "top" },
                                { label: "bottom", value: "bottom" },
                                { label: "left", value: "left" },
                                { label: "right", value: "right" }
                            ]
                            currentValue: Settings.barPosition === "up" ? "top" : (Settings.barPosition === "down" ? "bottom" : Settings.barPosition)
                            onSelected: val => Settings.barPosition = val
                        }

                        ChoiceRow {
                            title: "bar thickness: " + Settings.barHeight + "px"
                            model: [28, 32, 36, 40, 48]
                            currentValue: Settings.barHeight
                            onSelected: val => Settings.barHeight = val
                        }

                        ChoiceGrid {
                            title: "aesthetic theme & materials"
                            columns: 2
                            model: [
                                { label: "regular (solid)", value: "regular" },
                                { label: "frosted glass", value: "glass" },
                                { label: "pure black (oled)", value: "pure-black" },
                                { label: "translucent (tint)", value: "translucent" },
                                { label: "accent glow (cyber)", value: "accent-glow" },
                                { label: "monochrome", value: "monochrome" }
                            ]
                            currentValue: Settings.barStyle
                            onSelected: val => Settings.barStyle = val
                        }

                        CategoryHeader {
                            title: "screen corners & scoops"
                            icon: Theme.iconSparkles
                        }

                        ChoiceGrid {
                            title: "screen corner fillets"
                            columns: 2
                            model: [
                                { label: "all (workspace)", value: "all" },
                                { label: "monitor edges", value: "monitor" },
                                { label: "bar opposite", value: "opposite" },
                                { label: "disabled", value: "none" },
                                { label: "top only", value: "top" },
                                { label: "bottom only", value: "bottom" },
                                { label: "left only", value: "left" },
                                { label: "right only", value: "right" }
                            ]
                            currentValue: Settings.screenCornerMode
                            onSelected: val => Settings.screenCornerMode = val
                        }

                        ChoiceRow {
                            title: "corner curvature style"
                            model: [
                                { label: "cubic", value: "cubic" },
                                { label: "squircle", value: "squircle" },
                                { label: "chamfer 45°", value: "chamfer" },
                                { label: "flared", value: "flared" },
                                { label: "stepped", value: "stepped" }
                            ]
                            currentValue: Settings.cornerStyle
                            onSelected: val => Settings.cornerStyle = val
                        }

                        ChoiceRow {
                            title: "corner color mode"
                            model: [
                                { label: "bar match", value: "bar" },
                                { label: "matugen theme", value: "theme" },
                                { label: "accent", value: "accent" },
                                { label: "pure black", value: "pure-black" }
                            ]
                            currentValue: Settings.cornerColorMode
                            onSelected: val => Settings.cornerColorMode = val
                        }

                        SettingCard {
                            ToggleRow {
                                icon: Theme.iconSparkles
                                title: "docked frame & scoops"
                                subtitle: "anchor shell fillets directly to screen bounds"
                                checked: Settings.screenFrameDocked
                                onToggled: Settings.screenFrameDocked = !Settings.screenFrameDocked
                            }
                        }

                        ChoiceRow {
                            title: "frame border width: " + (Settings.screenBorderWidth === 0 ? "none (corners only)" : (Settings.screenBorderWidth + "px (full screen frame)"))
                            model: [0, 2, 4, 8, 12]
                            currentValue: Settings.screenBorderWidth
                            onSelected: val => Settings.screenBorderWidth = val
                        }

                        ChoiceRow {
                            title: "bar scoop radius: " + Settings.scoopRadius + "px"
                            model: [0, 8, 12, 16, 20, 24, 32]
                            currentValue: Settings.scoopRadius
                            onSelected: val => Settings.scoopRadius = val
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 6

                            Text {
                                text: "screen corner radius: " + Settings.screenCornerRadius + "px"
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeXs
                                color: Theme.on_surface_variant
                                Layout.fillWidth: true
                            }

                            Rectangle {
                                height: 22
                                implicitWidth: syncText.implicitWidth + 14
                                radius: Theme.radiusSm
                                color: Theme.surface_container_highest
                                visible: Settings.scoopRadius !== Settings.screenCornerRadius

                                Text {
                                    id: syncText
                                    anchors.centerIn: parent
                                    text: "match scoops (" + Settings.scoopRadius + "px)"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 9
                                    color: Theme.primary
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Settings.screenCornerRadius = Settings.scoopRadius
                                }
                            }
                        }

                        ChoiceRow {
                            model: [0, 8, 12, 16, 20, 24, 32]
                            currentValue: Settings.screenCornerRadius
                            onSelected: val => Settings.screenCornerRadius = val
                        }
                    }
                }
                TabScrollTrack { target: flickLayout; visible: root.activeTab === "layout" && flickLayout.visibleArea.heightRatio < 1.0 }

                Flickable {
                    id: flickModules
                    anchors.fill: parent
                    visible: root.activeTab === "modules"
                    clip: true
                    contentWidth: width
                    contentHeight: modCol.implicitHeight
                    boundsBehavior: Flickable.StopAtBounds

                    ColumnLayout {
                        id: modCol
                        width: parent.width - 6
                        spacing: 8

                        CategoryHeader {
                            title: "bar layout studio"
                            icon: Theme.iconSliders
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            height: 64
                            radius: Theme.radiusMd
                            color: studioBtnMouse.containsMouse ? Theme.surface_container_highest : Theme.surface_container_low
                            border.color: Settings.showBarStudio ? Theme.primary : Theme.widgetBorder
                            border.width: 1

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 12

                                Rectangle {
                                    width: 40
                                    height: 40
                                    radius: Theme.radiusSm
                                    color: Settings.showBarStudio ? Theme.primary_overlay : Theme.surface_container_high

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
                                        text: "bar layout studio"
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.fontSizeSm
                                        font.weight: Font.Bold
                                        color: Theme.on_surface
                                    }
                                    Text {
                                        text: Settings.showBarStudio ? "studio open on screen edge (click to close)" : "reorder, shift zones & customize bar modules interactively"
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 10
                                        color: Theme.on_surface_variant
                                    }
                                }

                                Rectangle {
                                    height: 26
                                    implicitWidth: launchStudioText.implicitWidth + 14
                                    radius: Theme.radiusPill
                                    color: Settings.showBarStudio ? Theme.primary : Theme.primary_overlay

                                    Text {
                                        id: launchStudioText
                                        anchors.centerIn: parent
                                        text: Settings.showBarStudio ? "active " : "open studio "
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 10
                                        font.weight: Font.Bold
                                        color: Settings.showBarStudio ? Theme.on_primary : Theme.primary
                                    }
                                }
                            }

                            MouseArea {
                                id: studioBtnMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Settings.showBarStudio = !Settings.showBarStudio
                            }
                        }

                        CategoryHeader {
                            title: "launcher & workspaces"
                            icon: Theme.iconWorkspaces
                        }

                        SettingCard {
                            ToggleRow {
                                icon: Theme.iconGrid
                                title: "application launcher"
                                checked: Settings.showLauncher
                                onToggled: Settings.showLauncher = !Settings.showLauncher
                            }
                            RowDivider {}
                            ToggleRow {
                                icon: Theme.iconWorkspaces
                                title: "workspaces switcher"
                                checked: Settings.showWorkspaces
                                onToggled: Settings.showWorkspaces = !Settings.showWorkspaces
                            }
                            RowDivider {}
                            ToggleRow {
                                icon: Theme.iconNote
                                title: "window title"
                                checked: Settings.showWindowTitle
                                onToggled: Settings.showWindowTitle = !Settings.showWindowTitle
                            }
                        }

                        CategoryHeader {
                            title: "media & status widgets"
                            icon: Theme.iconMusic
                        }

                        SettingCard {
                            ToggleRow {
                                icon: Theme.iconClock
                                title: "clock & date"
                                checked: Settings.showClock
                                onToggled: Settings.showClock = !Settings.showClock
                            }
                            RowDivider {}
                            ToggleRow {
                                icon: Theme.iconMusic
                                title: "now playing / mpris"
                                checked: Settings.showMedia
                                onToggled: Settings.showMedia = !Settings.showMedia
                            }
                            RowDivider {}
                            ToggleRow {
                                icon: Theme.iconSparkles
                                title: "wallpaper & theme browser"
                                checked: Settings.showWallpaper
                                onToggled: Settings.showWallpaper = !Settings.showWallpaper
                            }
                            RowDivider {}
                            ToggleRow {
                                icon: Theme.iconSliders
                                title: "volume & audio mixer"
                                checked: Settings.showVolume
                                onToggled: Settings.showVolume = !Settings.showVolume
                            }
                        }

                        CategoryHeader {
                            title: "connectivity & hardware"
                            icon: Theme.iconWifi
                        }

                        SettingCard {
                            ToggleRow {
                                icon: Theme.iconWifi
                                title: "network / wi-fi"
                                checked: Settings.showNetwork
                                onToggled: Settings.showNetwork = !Settings.showNetwork
                            }
                            RowDivider {}
                            ToggleRow {
                                icon: Theme.iconWifi
                                title: "bluetooth devices"
                                checked: Settings.showBluetooth
                                onToggled: Settings.showBluetooth = !Settings.showBluetooth
                            }
                            RowDivider {}
                            ToggleRow {
                                icon: Theme.iconFlame
                                title: "battery & power status"
                                checked: Settings.showBattery
                                onToggled: Settings.showBattery = !Settings.showBattery
                            }
                            RowDivider {}
                            ToggleRow {
                                icon: Theme.iconGrid
                                title: "system tray icons"
                                checked: Settings.showSystemTray
                                onToggled: Settings.showSystemTray = !Settings.showSystemTray
                            }
                        }

                        CategoryHeader {
                            title: "notifications & alert center"
                            icon: Theme.iconBell
                        }

                        SettingCard {
                            ToggleRow {
                                icon: Theme.iconBell
                                title: "notification center module"
                                checked: Settings.showNotifications
                                onToggled: Settings.showNotifications = !Settings.showNotifications
                            }
                            RowDivider {}
                            ToggleRow {
                                icon: Settings.dnd ? Theme.iconBellOff : Theme.iconBell
                                title: "do not disturb"
                                subtitle: "silence incoming notification toasts"
                                checked: Settings.dnd
                                onToggled: Settings.dnd = !Settings.dnd
                            }
                        }

                        CategoryHeader {
                            title: "tools & system utilities"
                            icon: Theme.iconSliders
                        }

                        SettingCard {
                            ToggleRow {
                                icon: Theme.iconCoffee
                                title: "caffeine / idle inhibitor"
                                checked: Settings.showIdleInhibitor
                                onToggled: Settings.showIdleInhibitor = !Settings.showIdleInhibitor
                            }
                            RowDivider {}
                            ToggleRow {
                                icon: Theme.iconNote
                                title: "clipboard history"
                                checked: Settings.showClipboard
                                onToggled: Settings.showClipboard = !Settings.showClipboard
                            }
                            RowDivider {}
                            ToggleRow {
                                icon: Theme.iconNote
                                title: "quick notes & scratchpad"
                                checked: Settings.showQuickNotes
                                onToggled: Settings.showQuickNotes = !Settings.showQuickNotes
                            }
                            RowDivider {}
                            ToggleRow {
                                icon: Theme.iconFlame
                                title: "power session menu"
                                checked: Settings.showPowerMenu
                                onToggled: Settings.showPowerMenu = !Settings.showPowerMenu
                            }
                        }
                    }
                }
                TabScrollTrack { target: flickModules; visible: root.activeTab === "modules" && flickModules.visibleArea.heightRatio < 1.0 }

                Flickable {
                    id: flickFonts
                    anchors.fill: parent
                    visible: root.activeTab === "fonts"
                    clip: true
                    contentWidth: width
                    contentHeight: fontCol.implicitHeight
                    boundsBehavior: Flickable.StopAtBounds

                    ColumnLayout {
                        id: fontCol
                        width: parent.width - 6
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
                                    color: fontSearchInput.activeFocus ? Theme.primary : Theme.on_surface_variant
                                }

                                Item {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true

                                    Text {
                                        anchors.fill: parent
                                        verticalAlignment: Text.AlignVCenter
                                        visible: fontSearchInput.text === "" && !fontSearchInput.activeFocus
                                        text: "filter installed fonts..."
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.fontSizeSm
                                        color: Theme.on_surface_variant
                                    }

                                    TextInput {
                                        id: fontSearchInput
                                        anchors.fill: parent
                                        verticalAlignment: TextInput.AlignVCenter
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.fontSizeSm
                                        color: Theme.on_surface
                                        onTextChanged: root.fontSearchQuery = text.toLowerCase()
                                    }
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

                            Text {
                                anchors.centerIn: parent
                                visible: root.filteredFonts.length === 0
                                text: "no fonts matching search"
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeXs
                                color: Theme.on_surface_variant
                            }
                        }

                        CategoryHeader {
                            title: "typography scale & weight"
                            icon: Theme.iconSliders
                        }

                        ChoiceRow {
                            title: "interface font scaling"
                            model: [
                                { label: "85%", value: 0.85 },
                                { label: "95%", value: 0.95 },
                                { label: "100%", value: 1.0 },
                                { label: "110%", value: 1.1 },
                                { label: "125%", value: 1.25 }
                            ]
                            currentValue: Settings.fontScale
                            onSelected: val => Settings.fontScale = val
                        }

                        ChoiceRow {
                            title: "font weight: " + Settings.fontWeight
                            model: [
                                { label: "light", value: "light" },
                                { label: "regular", value: "regular" },
                                { label: "medium", value: "medium" },
                                { label: "demibold", value: "demibold" },
                                { label: "bold", value: "bold" }
                            ]
                            currentValue: Settings.fontWeight
                            onSelected: val => Settings.fontWeight = val
                        }

                        CategoryHeader {
                            title: "icon glyph pack"
                            icon: Theme.iconSparkles
                        }

                        ChoiceGrid {
                            columns: 3
                            buttonHeight: 32
                            model: [
                                { label: "material", value: "material" },
                                { label: "windows segoe", value: "windows" },
                                { label: "font awesome", value: "awesome" },
                                { label: "(ﾉ◕ヮ◕)ﾉ kaomoji", value: "kaomoji" },
                                { label: "󰦨 plain text", value: "text" }
                            ]
                            currentValue: Settings.iconSet
                            onSelected: val => {
                                Settings.iconSet = val;
                                Settings.vibeStyle = (val === "kaomoji" || val === "text") ? val : "nerd";
                            }
                        }
                    }
                }
                TabScrollTrack { target: flickFonts; visible: root.activeTab === "fonts" && flickFonts.visibleArea.heightRatio < 1.0 }

                Flickable {
                    id: flickAnim
                    anchors.fill: parent
                    visible: root.activeTab === "animations"
                    clip: true
                    contentWidth: width
                    contentHeight: animCol.implicitHeight
                    boundsBehavior: Flickable.StopAtBounds

                    ColumnLayout {
                        id: animCol
                        width: parent.width - 6
                        spacing: 10

                        CategoryHeader {
                            title: "shell animation profiles"
                            icon: Theme.iconFlame
                        }

                        SettingCard {
                            Repeater {
                                model: [
                                    { id: "hyprland", label: "hyprland sync (default)", desc: "matches hyprland bezier curves & timing" },
                                    { id: "snappy", label: "snappy & responsive", desc: "110ms ultra-fast transitions with zero delay" },
                                    { id: "chill", label: "smooth & relaxed", desc: "luxurious 300ms cubic ease for aesthetic flow" },
                                    { id: "instant", label: "instant / zero lag", desc: "50ms minimal motion for raw performance" }
                                ]

                                delegate: Column {
                                    required property var modelData
                                    required property int index
                                    width: parent.width
                                    spacing: 0

                                    RowDivider { visible: index > 0 }

                                    Rectangle {
                                        width: parent.width
                                        height: 50
                                        color: Settings.animSpeed === modelData.id
                                            ? Theme.primary_overlay
                                            : (aMouse.containsMouse ? Theme.surface_container_highest : "transparent")

                                        Behavior on color { ColorAnimation { duration: Theme.animFast } }

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: Theme.widgetPaddingH
                                            anchors.rightMargin: Theme.widgetPaddingH
                                            spacing: 12

                                            Text {
                                                text: Settings.animSpeed === modelData.id ? Theme.iconCheckCircle : Theme.iconFlame
                                                font.family: Theme.fontIcon
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
                                            id: aMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: Settings.animSpeed = modelData.id
                                        }
                                    }
                                }
                            }
                        }

                        CategoryHeader {
                            title: "physics & motion playground"
                            icon: Theme.iconSparkles
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            height: 52
                            radius: Theme.radiusMd
                            color: Settings.showMotionSandbox ? Theme.primary_overlay : Theme.surface_container_highest
                            border.color: Settings.showMotionSandbox ? Theme.primary : Theme.widgetBorder
                            border.width: 1

                            Behavior on color { ColorAnimation { duration: Theme.animFast } }
                            Behavior on border.color { ColorAnimation { duration: Theme.animFast } }

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: Theme.widgetPaddingH
                                spacing: 12

                                Rectangle {
                                    width: 34
                                    height: 34
                                    radius: Theme.radiusSm
                                    color: Settings.showMotionSandbox ? Theme.primary_overlay : Theme.surface_container_high

                                    Text {
                                        anchors.centerIn: parent
                                        text: Theme.iconFlame
                                        font.family: Theme.fontIcon
                                        font.pixelSize: Theme.fontSizeMd
                                        color: Settings.showMotionSandbox ? Theme.primary : Theme.on_surface
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2

                                    Text {
                                        text: "motion sandbox"
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.fontSizeSm
                                        font.weight: Font.Bold
                                        color: Theme.on_surface
                                    }
                                    Text {
                                        text: Settings.showMotionSandbox ? "sandbox active on screen edge (click to dismiss)" : "interactive physics playground with springs & gravity"
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 10
                                        color: Theme.on_surface_variant
                                    }
                                }

                                Rectangle {
                                    height: 26
                                    implicitWidth: launchSandboxText.implicitWidth + 14
                                    radius: Theme.radiusPill
                                    color: Settings.showMotionSandbox ? Theme.primary : Theme.primary_overlay

                                    Text {
                                        id: launchSandboxText
                                        anchors.centerIn: parent
                                        text: Settings.showMotionSandbox ? "active " : "launch "
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 10
                                        font.weight: Font.Bold
                                        color: Settings.showMotionSandbox ? Theme.on_primary : Theme.primary
                                    }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Settings.showMotionSandbox = !Settings.showMotionSandbox
                            }
                        }
                    }
                }
                TabScrollTrack { target: flickAnim; visible: root.activeTab === "animations" && flickAnim.visibleArea.heightRatio < 1.0 }

                Flickable {
                    id: flickVibe
                    anchors.fill: parent
                    visible: root.activeTab === "vibe"
                    clip: true
                    contentWidth: width
                    contentHeight: vibeCol.implicitHeight
                    boundsBehavior: Flickable.StopAtBounds

                    ColumnLayout {
                        id: vibeCol
                        width: parent.width - 6
                        spacing: 10

                        CategoryHeader {
                            title: "personality & chaotic vibes"
                            icon: Theme.iconFlame
                        }

                        SettingCard {
                            ToggleRow {
                                icon: Theme.iconFlame
                                title: "unhinged flavor text"
                                subtitle: "chaotic system status quips & personality"
                                checked: Settings.unhingedFlavor
                                onToggled: Settings.unhingedFlavor = !Settings.unhingedFlavor
                            }
                        }

                        CategoryHeader {
                            title: "clock & date display formats"
                            icon: Theme.iconClock
                        }

                        ChoiceRow {
                            title: "clock time format"
                            model: [
                                { label: "24-hour (16:45)", value: "HH:mm" },
                                { label: "12-hour (4:45 pm)", value: "h:mm ap" },
                                { label: "seconds (16:45:00)", value: "HH:mm:ss" }
                            ]
                            currentValue: Settings.clockFormat
                            onSelected: val => Settings.clockFormat = val
                        }

                        ChoiceGrid {
                            title: "date display format"
                            columns: 2
                            model: [
                                { label: "hidden (time only)", value: "none" },
                                { label: "short (Mon, Sep 1)", value: "ddd, MMM d" },
                                { label: "standard (Sep 1)", value: "MMM d, yyyy" },
                                { label: "iso (2026-09-01)", value: "yyyy-MM-dd" }
                            ]
                            currentValue: !Settings.showBarDate ? "none" : Settings.dateFormat
                            onSelected: val => {
                                if (val === "none") {
                                    Settings.showBarDate = false;
                                } else {
                                    Settings.dateFormat = val;
                                    Settings.showBarDate = true;
                                }
                            }
                        }

                        ChoiceRow {
                            title: "workspace capacity: " + Settings.workspaceCount
                            model: [
                                { label: "5 spaces", value: 5 },
                                { label: "8 spaces", value: 8 },
                                { label: "10 spaces", value: 10 },
                                { label: "12 spaces", value: 12 },
                                { label: "16 spaces", value: 16 }
                            ]
                            currentValue: Settings.workspaceCount
                            onSelected: val => Settings.workspaceCount = val
                        }

                        CategoryHeader {
                            title: "local network aliases"
                            icon: Theme.iconWifi
                        }

                        readonly property var aliasKeys: Object.keys(Settings.networkAliases || {})

                        Rectangle {
                            Layout.fillWidth: true
                            height: 44
                            radius: Theme.widgetRadius
                            color: Theme.surface_container_low
                            border.color: Theme.widgetBorder
                            border.width: 1
                            visible: vibeCol.aliasKeys.length === 0

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: Theme.widgetPaddingH
                                spacing: 10

                                Text {
                                    text: Theme.iconWifi
                                    font.family: Theme.fontIcon
                                    font.pixelSize: Theme.fontSizeSm
                                    color: Theme.on_surface_variant
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: "no custom network aliases saved yet (rename in wi-fi menu)"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 10
                                    color: Theme.on_surface_variant
                                    elide: Text.ElideRight
                                }
                            }
                        }

                        SettingCard {
                            visible: vibeCol.aliasKeys.length > 0

                            Repeater {
                                model: vibeCol.aliasKeys

                                delegate: Column {
                                    required property string modelData
                                    required property int index
                                    width: parent.width
                                    spacing: 0

                                    RowDivider { visible: index > 0 }

                                    Rectangle {
                                        width: parent.width
                                        height: 38
                                        color: "transparent"

                                        Text {
                                            id: alIcon
                                            anchors.left: parent.left
                                            anchors.leftMargin: Theme.widgetPaddingH
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: Theme.iconWifi
                                            font.family: Theme.fontIcon
                                            font.pixelSize: Theme.fontSizeXs
                                            color: Theme.primary
                                        }

                                        IconButton {
                                            id: alTrash
                                            anchors.right: parent.right
                                            anchors.rightMargin: Theme.widgetPaddingH
                                            anchors.verticalCenter: parent.verticalCenter
                                            icon: Theme.iconTrash
                                            iconSize: 10
                                            tooltip: "remove alias"
                                            onClicked: Settings.setNetworkAlias(modelData, "")
                                        }

                                        RowLayout {
                                            anchors.left: alIcon.right
                                            anchors.leftMargin: 8
                                            anchors.right: alTrash.left
                                            anchors.rightMargin: 8
                                            anchors.verticalCenter: parent.verticalCenter
                                            spacing: 6

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
                                        }
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
                                    width: 64
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
                TabScrollTrack { target: flickVibe; visible: root.activeTab === "vibe" && flickVibe.visibleArea.heightRatio < 1.0 }
            }
        }

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