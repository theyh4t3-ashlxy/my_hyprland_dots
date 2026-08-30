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

    property PwNode sink: Pipewire.defaultAudioSink
    property PwNode source: Pipewire.defaultAudioSource
    PwObjectTracker { objects: [root.sink, root.source].filter(Boolean) }

    property string activeTab: "layout"
    property string fontSearchQuery: ""

    // burning the /tmp json disk spam; qt literally has this built-in
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
        cardWidth: 460
        cardHeight: 620
        targetRelativeX: root.mapToItem(null, 0, 0).x + (root.width / 2)

        content: ColumnLayout {
            anchors.fill: parent
            anchors.margins: Theme.widgetPaddingH
            spacing: Theme.widgetSpacing

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: "settings"
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeLg
                    font.weight: Font.Bold
                    color: Theme.on_surface
                    Layout.fillWidth: true
                }

                IconButton {
                    icon: Theme.iconSave
                    iconSize: Theme.fontSizeMd
                    tooltip: "save configuration"
                    onClicked: Settings.save()
                }
            }

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
                                    font.pixelSize: Theme.fontSizeXs
                                    font.weight: Font.Bold
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

            // layout tab
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

                    Text {
                        text: "bar edge docking"
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeSm
                        font.weight: Font.Bold
                        color: Theme.primary
                    }

                    GridLayout {
                        Layout.fillWidth: true
                        columns: 4
                        columnSpacing: 6
                        rowSpacing: 6

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
                                radius: Theme.widgetRadius
                                color: Settings.barPosition === modelData.pos ? Theme.primary : Theme.surface_container_highest

                                Text {
                                    text: modelData.label
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSizeXs
                                    font.weight: Font.Medium
                                    color: Settings.barPosition === modelData.pos ? Theme.on_primary : Theme.on_surface
                                    anchors.centerIn: parent
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        Settings.barPosition = modelData.pos
                                        Settings.save()
                                    }
                                }
                            }
                        }
                    }

                    BarPreview {
                        Layout.fillWidth: true
                    }

                    Text {
                        text: "concave geometry style"
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
                                { label: "smooth curve", val: "cubic" },
                                { label: "flared deep", val: "flared" },
                                { label: "chamfer 45°", val: "chamfer" },
                                { label: "stepped notch", val: "stepped" }
                            ]

                            delegate: Rectangle {
                                required property var modelData
                                Layout.fillWidth: true
                                height: 28
                                radius: Theme.radiusSm
                                color: Settings.cornerStyle === modelData.val ? Theme.primary : Theme.surface_container_highest

                                Text {
                                    text: modelData.label
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 10
                                    color: Settings.cornerStyle === modelData.val ? Theme.on_primary : Theme.on_surface
                                    anchors.centerIn: parent
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        Settings.cornerStyle = modelData.val
                                        Settings.save()
                                    }
                                }
                            }
                        }
                    }

                    Text {
                        text: "bar scoop weld radius"
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
                                { label: "off (0px)", r: 0 },
                                { label: "12px subtle", r: 12 },
                                { label: "16px default", r: 16 },
                                { label: "24px chunky", r: 24 },
                                { label: "32px mega", r: 32 }
                            ]

                            delegate: Rectangle {
                                required property var modelData
                                Layout.fillWidth: true
                                height: 28
                                radius: Theme.radiusSm
                                color: Settings.scoopRadius === modelData.r ? Theme.primary : Theme.surface_container_highest

                                Text {
                                    text: modelData.label
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 10
                                    color: Settings.scoopRadius === modelData.r ? Theme.on_primary : Theme.on_surface
                                    anchors.centerIn: parent
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        Settings.scoopRadius = modelData.r
                                        Settings.save()
                                    }
                                }
                            }
                        }
                    }

                    Text {
                        text: "bezier curve tension"
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeSm
                        font.weight: Font.Bold
                        color: Theme.primary
                        visible: Settings.cornerStyle === "cubic"
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6
                        visible: Settings.cornerStyle === "cubic"

                        Repeater {
                            model: [
                                { label: "soft (0.45)", t: 0.45 },
                                { label: "circular (0.55)", t: 0.55228475 },
                                { label: "snappy (0.70)", t: 0.70 }
                            ]

                            delegate: Rectangle {
                                required property var modelData
                                Layout.fillWidth: true
                                height: 28
                                radius: Theme.radiusSm
                                color: Math.abs(Settings.scoopTension - modelData.t) < 0.02 ? Theme.primary : Theme.surface_container_highest

                                Text {
                                    text: modelData.label
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 10
                                    color: Math.abs(Settings.scoopTension - modelData.t) < 0.02 ? Theme.on_primary : Theme.on_surface
                                    anchors.centerIn: parent
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        Settings.scoopTension = modelData.t
                                        Settings.save()
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

                    Text {
                        text: "screen corners (around display)"
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
                                { label: "off", r: 0 },
                                { label: "12px", r: 12 },
                                { label: "16px", r: 16 },
                                { label: "24px", r: 24 },
                                { label: "32px", r: 32 },
                                { label: "48px", r: 48 }
                            ]

                            delegate: Rectangle {
                                required property var modelData
                                Layout.fillWidth: true
                                height: 28
                                radius: Theme.radiusSm
                                color: Settings.screenCornerRadius === modelData.r ? Theme.primary : Theme.surface_container_highest

                                Text {
                                    text: modelData.label
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 10
                                    color: Settings.screenCornerRadius === modelData.r ? Theme.on_primary : Theme.on_surface
                                    anchors.centerIn: parent
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        Settings.screenCornerRadius = modelData.r
                                        Settings.save()
                                    }
                                }
                            }
                        }
                    }

                    Text {
                        text: "screen corner placement"
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeSm
                        font.weight: Font.Bold
                        color: Theme.primary
                    }

                    GridLayout {
                        Layout.fillWidth: true
                        columns: 3
                        columnSpacing: 6
                        rowSpacing: 6

                        Repeater {
                            model: [
                                { label: "all 4 corners", m: "all" },
                                { label: "opposite bar", m: "opposite" },
                                { label: "bottom only", m: "bottom" },
                                { label: "top only", m: "top" },
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
                                    onClicked: {
                                        Settings.screenCornerMode = modelData.m
                                        Settings.save()
                                    }
                                }
                            }
                        }
                    }

                    Text {
                        text: "screen corner fill color"
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
                                { label: "theme dark", c: "theme" },
                                { label: "pure black", c: "pure-black" },
                                { label: "bar match", c: "bar" },
                                { label: "accent glow", c: "accent" }
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
                                    onClicked: {
                                        Settings.cornerColorMode = modelData.c
                                        Settings.save()
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // modules tab
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
                        text: "visible modules"
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeSm
                        font.weight: Font.Bold
                        color: Theme.primary
                    }

                    Repeater {
                        model: [
                            { prop: "showWorkspaces", label: "workspaces bar" },
                            { prop: "showWindowTitle", label: "window title" },
                            { prop: "showClock", label: "clock & date" },
                            { prop: "showLauncher", label: "application launcher" },
                            { prop: "showWallpaper", label: "wallpaper & theme browser" },
                            { prop: "showVolume", label: "volume control" },
                            { prop: "showMedia", label: "now playing / mpris" },
                            { prop: "showNetwork", label: "network / wifi" },
                            { prop: "showBluetooth", label: "bluetooth" },
                            { prop: "showClipboard", label: "clipboard history" },
                            { prop: "showIdleInhibitor", label: "caffeine / sleep inhibitor" },
                            { prop: "showBattery", label: "battery status" },
                            { prop: "showNotifications", label: "notifications" },
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
                                    onToggled: {
                                        Settings[modelData.prop] = !Settings[modelData.prop]
                                        Settings.save()
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // fonts tab
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: root.activeTab === "fonts"
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: "active font: " + Settings.fontFamily
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeSm
                        font.weight: Font.Bold
                        color: Theme.primary
                        Layout.fillWidth: true
                    }
                }

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

                // listview with real recycling instead of invisible ghost items
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
                            height: 30
                            radius: Theme.radiusSm
                            color: Settings.fontFamily === modelData ? Theme.primary : (fItemMouse.containsMouse ? Theme.surface_container_highest : "transparent")

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 6
                                spacing: 8

                                Text {
                                    text: modelData
                                    font.family: modelData
                                    font.pixelSize: 11
                                    color: Settings.fontFamily === modelData ? Theme.on_primary : Theme.on_surface
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                }

                                Text {
                                    text: Settings.fontFamily === modelData ? (Theme.iconCheck + " active") : "abc 123"
                                    font.family: modelData
                                    font.pixelSize: 10
                                    color: Settings.fontFamily === modelData ? Theme.on_primary : Theme.on_surface_variant
                                }
                            }

                            MouseArea {
                                id: fItemMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    Settings.fontFamily = modelData
                                    Settings.save()
                                }
                            }
                        }
                    }
                }

                Text {
                    text: "font scaling factor"
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeXs
                    color: Theme.on_surface_variant
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Repeater {
                        model: [
                            { label: "compact (90%)", s: 0.9 },
                            { label: "standard (100%)", s: 1.0 },
                            { label: "large (110%)", s: 1.1 },
                            { label: "big (125%)", s: 1.25 }
                        ]

                        delegate: Rectangle {
                            required property var modelData
                            Layout.fillWidth: true
                            height: 26
                            radius: Theme.radiusSm
                            color: Math.abs(Settings.fontScale - modelData.s) < 0.05 ? Theme.primary : Theme.surface_container_highest

                            Text {
                                text: modelData.label
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                                color: Math.abs(Settings.fontScale - modelData.s) < 0.05 ? Theme.on_primary : Theme.on_surface
                                anchors.centerIn: parent
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    Settings.fontScale = modelData.s
                                    Settings.save()
                                }
                            }
                        }
                    }
                }
            }

            // vibe tab
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

                    Text {
                        text: "motion profile"
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
                                { label: ">> hyper (60ms)", val: "hyper" },
                                { label: "snappy (180ms)", val: "snappy" },
                                { label: "~ chill (300ms)", val: "chill" }
                            ]

                            delegate: Rectangle {
                                required property var modelData
                                Layout.fillWidth: true
                                height: 28
                                radius: Theme.radiusSm
                                color: Settings.animSpeed === modelData.val ? Theme.primary : Theme.surface_container_highest

                                Text {
                                    text: modelData.label
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 10
                                    color: Settings.animSpeed === modelData.val ? Theme.on_primary : Theme.on_surface
                                    anchors.centerIn: parent
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        Settings.animSpeed = modelData.val
                                        Settings.save()
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 40
                        radius: Theme.widgetRadius
                        color: Theme.surface_container_highest

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: Theme.widgetPaddingH

                            Text {
                                text: (Settings.unhingedFlavor ? Theme.kaoChaos : "(¬‿¬)") + " unhinged mood mode"
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeSm
                                color: Theme.on_surface
                                Layout.fillWidth: true
                            }

                            ToggleSwitch {
                                checked: Settings.unhingedFlavor
                                onToggled: {
                                    Settings.unhingedFlavor = !Settings.unhingedFlavor
                                    Settings.save()
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}