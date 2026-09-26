import QtQuick
import QtQuick.Layouts
import ".."
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Hyprland

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

    property var barScreen: null
    property var barMonitor: null
    property string activeTab: "layout"
    property string fontTarget: "sans"
    property string fontSearchQuery: ""
    property bool showResetConfirm: false
    property string activeShell: "quickshell"

    readonly property string userHome: Quickshell.env("HOME") || ""
    readonly property string cacheDir: Quickshell.env("XDG_CACHE_HOME") || (userHome + "/.cache")

    // Scope signal safety & file watcher
    FileView {
        id: shellWatcher
        printErrors: false
        path: root.cacheDir + "/current_shell"
        watchChanges: true
        // disk writes dont notify without a reload kick
        onFileChanged: reload()
        onLoaded: {
            const s = text().trim();
            if (s === "brain_shell" || s === "quickshell") {
                root.activeShell = s;
            } else if (s === "oxytocin") {
                // automatic exorcism of old shell regret
                root.activeShell = "brain_shell";
                switchProc.switchShell("brain_shell");
            }
        }
    }

    Process {
        id: switchProc
        function switchShell(target) {
            if (!target) return;
            if (running) running = false;
            const bin = root.userHome + "/.local/bin/qs-switch";
            command = [bin, target];
            running = true;
        }
        function restartCurrent() {
            switchShell("restart");
        }
        onExited: (code) => {
            shellWatcher.reload();
        }
    }

    readonly property var allFonts: {
        try {
            const raw = Qt.fontFamilies();
            if (!raw || raw.length === 0) return [];
            return Array.from(raw).sort((a, b) => a.localeCompare(b, undefined, { sensitivity: "base" }));
        } catch (e) {
            return [];
        }
    }

    readonly property var filteredFonts: {
        if (!fontSearchQuery || fontSearchQuery.trim() === "") return allFonts;
        const q = fontSearchQuery.trim().toLowerCase();
        return allFonts.filter(f => f && f.toLowerCase().includes(q));
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
        implicitHeight: subtitle !== "" ? 48 : 38
        height: implicitHeight
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
                    readonly property var itemVal: modelData && typeof modelData === "object"
                        ? (modelData.value !== undefined ? modelData.value : (modelData.pos !== undefined ? modelData.pos : (modelData.s !== undefined ? modelData.s : (modelData.w !== undefined ? modelData.w : (modelData.c !== undefined ? modelData.c : (modelData.fmt !== undefined ? modelData.fmt : modelData))))))
                        : modelData
                    readonly property string itemText: modelData && typeof modelData === "object" && modelData.label !== undefined
                        ? String(modelData.label)
                        : (typeof modelData === "number" ? (modelData === 0 ? "none" : modelData + "px") : String(modelData ?? ""))
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
                    readonly property var itemVal: modelData && typeof modelData === "object"
                        ? (modelData.value !== undefined ? modelData.value : (modelData.id !== undefined ? modelData.id : (modelData.s !== undefined ? modelData.s : (modelData.m !== undefined ? modelData.m : (modelData.fmt !== undefined ? modelData.fmt : modelData)))))
                        : modelData
                    readonly property string itemText: modelData && typeof modelData === "object" && modelData.label !== undefined
                        ? String(modelData.label)
                        : String(modelData ?? "")
                    readonly property bool isSelected: (typeof cgRoot.currentValue === "number" && typeof itemVal === "number" && !Number.isInteger(itemVal))
                        ? Math.abs(cgRoot.currentValue - itemVal) < 0.04
                        : cgRoot.currentValue === itemVal

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

    component SliderRow: ColumnLayout {
        id: slRoot
        property string title: ""
        property real from: 0
        property real to: 100
        property real value: 0
        property real stepSize: 1
        property string suffix: "px"
        property var formatter: null // optional function(value) -> string
        signal moved(real val)

        Layout.fillWidth: true
        spacing: 6

        readonly property string displayText: slRoot.formatter
            ? slRoot.formatter(slRoot.value)
            : ((Math.round(slRoot.value * 100) / 100) + slRoot.suffix)

        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Text {
                visible: slRoot.title !== ""
                text: slRoot.title
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeXs
                color: Theme.on_surface_variant
                Layout.fillWidth: true
            }

            Text {
                text: slRoot.displayText
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeXs
                font.weight: Font.Bold
                color: Theme.primary
            }
        }

        Rectangle {
            id: track
            Layout.fillWidth: true
            height: 6
            radius: 3
            color: Theme.surface_container_highest

            readonly property real ratio: slRoot.to > slRoot.from
                ? Math.max(0, Math.min(1, (slRoot.value - slRoot.from) / (slRoot.to - slRoot.from)))
                : 0

            Rectangle {
                width: parent.width * track.ratio
                height: parent.height
                radius: parent.radius
                color: Theme.primary
            }

            Rectangle {
                id: handle
                width: 16
                height: 16
                radius: 8
                y: (track.height - height) / 2
                x: Math.max(0, Math.min(track.width - width, track.width * track.ratio - width / 2))
                color: Theme.primary
                border.color: Theme.on_primary
                border.width: 2
                scale: dragArea.pressed ? 1.2 : 1.0

                Behavior on scale { NumberAnimation { duration: Theme.animFast } }
            }

            MouseArea {
                id: dragArea
                anchors.fill: parent
                anchors.margins: -8
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                preventStealing: true

                function commit(localX) {
                    const t = Math.max(0, Math.min(1, localX / track.width));
                    let raw = slRoot.from + t * (slRoot.to - slRoot.from);
                    if (slRoot.stepSize > 0) {
                        raw = Math.round(raw / slRoot.stepSize) * slRoot.stepSize;
                    }
                    raw = Math.max(slRoot.from, Math.min(slRoot.to, raw));
                    if (Math.abs(raw - slRoot.value) > 1e-9) slRoot.moved(raw);
                }

                onPressed: (mouse) => commit(mouse.x - 8)
                onPositionChanged: (mouse) => { if (pressed) commit(mouse.x - 8); }
            }
        }
    }

    component TabScrollTrack: Rectangle {
        id: stRoot
        required property Flickable target
        anchors.right: target ? target.right : undefined
        anchors.top: target ? target.top : undefined
        anchors.bottom: target ? target.bottom : undefined
        anchors.margins: 2
        width: 3
        radius: 1.5
        color: "transparent"
        visible: target ? (target.visible && target.visibleArea.heightRatio < 1.0) : false

        Rectangle {
            width: parent.width
            readonly property real trackH: stRoot.height
            readonly property real thumbH: Math.max(16, Math.min(trackH, (stRoot.target ? stRoot.target.visibleArea.heightRatio : 1) * trackH))
            height: thumbH
            y: Math.max(0, Math.min(trackH - thumbH, (stRoot.target ? stRoot.target.visibleArea.yPosition : 0) * trackH))
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
            if (p) {
                popup.targetRelativeX = p.x + (root.width / 2);
                popup.targetRelativeY = p.y + (root.height / 2);
            }
            popup.open = !popup.open;
        }
    }

    Connections {
        target: Settings
        function onRequestQuickSettingsToggle() {
            if (!root.barScreen || Quickshell.screens.length <= 1 || (root.barMonitor && Hyprland.focusedMonitor && root.barMonitor.id === Hyprland.focusedMonitor.id)) {
                const p = root.mapToItem(null, 0, 0);
                if (p) {
                    popup.targetRelativeX = p.x + (root.width / 2);
                    popup.targetRelativeY = p.y + (root.height / 2);
                }
                popup.open = !popup.open;
            }
        }
        function onRequestQuickSettingsOpen() {
            if (!root.barScreen || Quickshell.screens.length <= 1 || (root.barMonitor && Hyprland.focusedMonitor && root.barMonitor.id === Hyprland.focusedMonitor.id)) {
                const p = root.mapToItem(null, 0, 0);
                if (p) {
                    popup.targetRelativeX = p.x + (root.width / 2);
                    popup.targetRelativeY = p.y + (root.height / 2);
                }
                popup.open = true;
            }
        }
        function onRequestQuickSettingsClose() {
            popup.open = false;
        }
    }

    PopupPanel {
        id: popup
        screen: root.barScreen
        wantsFocus: true
        keyboardFocusMode: WlrKeyboardFocus.OnDemand
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
                contentWidth: tabRow.implicitWidth
                flickableDirection: Flickable.HorizontalFlick
                boundsBehavior: Flickable.StopAtBounds
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
                            { id: "vibe", label: "vibe", icon: Theme.iconCoffee },
                            { id: "screenshot", label: "screenshot", icon: Theme.iconCamera },
                            { id: "shells", label: "shells", icon: Theme.iconTerminal }
                        ]

                        delegate: Rectangle {
                            required property var modelData
                            height: 30
                            width: tabItemRow.implicitWidth + 20
                            radius: Theme.radiusPill
                            readonly property bool isSelected: root.activeTab === modelData.id

                            color: isSelected
                                ? (Theme.surface_container_high ?? Theme.primary_container)
                                : (tabMouse.containsMouse ? Theme.surface_container_low : Theme.surface_container_lowest)
                            border.color: isSelected ? (Theme.outline_variant ?? Theme.primary) : "transparent"
                            border.width: isSelected ? 1 : 0

                            Behavior on color { ColorAnimation { duration: Theme.animFast } }

                            RowLayout {
                                id: tabItemRow
                                anchors.centerIn: parent
                                spacing: 6

                                Text {
                                    text: modelData.icon
                                    font.family: Theme.fontIcon
                                    font.pixelSize: Theme.fontSizeSm
                                    color: isSelected ? Theme.primary : Theme.on_surface_variant
                                }

                                Text {
                                    text: modelData.label
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSizeSm
                                    font.weight: isSelected ? Font.DemiBold : Font.Medium
                                    color: isSelected ? Theme.on_surface : Theme.on_surface_variant
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
                    contentHeight: layoutCol.implicitHeight + 12
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

                        SliderRow {
                            title: "bar thickness"
                            from: 24
                            to: 56
                            stepSize: 2
                            suffix: "px"
                            value: Settings.barHeight
                            onMoved: val => Settings.barHeight = val
                        }

                        ChoiceGrid {
                            title: "aesthetic theme & materials"
                            columns: 2
                            model: [
                                { label: "regular (solid)", value: "regular" },
                                { label: "frosted glass", value: "glass" },
                                { label: "glass frost (blur)", value: "glass-frost" },
                                { label: "pure black (oled)", value: "pure-black" },
                                { label: "cyber neon (glow)", value: "cyber-neon" },
                                { label: "bento floating", value: "bento-floating" },
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
                                { label: "g2 continuous", value: "continuous-bezier" },
                                { label: "cubic", value: "cubic" },
                                { label: "squircle", value: "squircle" },
                                { label: "hyperbolic", value: "hyperbolic" },
                                { label: "chamfer 45°", value: "chamfer" },
                                { label: "flared", value: "flared" }
                            ]
                            currentValue: Settings.cornerStyle
                            onSelected: val => Settings.cornerStyle = val
                        }

                        SettingCard {
                            ToggleRow {
                                icon: Theme.iconSparkles
                                title: "scoop border outlines"
                                subtitle: "draw continuous stroke along concave curves"
                                checked: Settings.scoopBorderEnabled
                                onToggled: Settings.scoopBorderEnabled = !Settings.scoopBorderEnabled
                            }
                        }

                        SliderRow {
                            title: "scoop border width"
                            from: 1
                            to: 6
                            stepSize: 1
                            suffix: "px"
                            value: Settings.scoopBorderWidth
                            onMoved: val => Settings.scoopBorderWidth = val
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

                        SliderRow {
                            title: "frame border width"
                            from: 0
                            to: 16
                            stepSize: 2
                            value: Settings.screenBorderWidth
                            formatter: v => v === 0 ? "none (corners only)" : (Math.round(v) + "px (full frame)")
                            onMoved: val => Settings.screenBorderWidth = val
                        }

                        SliderRow {
                            title: "bar scoop radius"
                            from: 0
                            to: 32
                            stepSize: 2
                            suffix: "px"
                            value: Settings.scoopRadius
                            onMoved: val => Settings.scoopRadius = val
                        }

                        SliderRow {
                            title: "screen corner radius"
                            from: 0
                            to: 40
                            stepSize: 2
                            suffix: "px"
                            value: Settings.screenCornerRadius
                            onMoved: val => Settings.screenCornerRadius = val
                        }

                        Rectangle {
                            Layout.alignment: Qt.AlignRight
                            visible: Settings.scoopRadius !== Settings.screenCornerRadius
                            height: 22
                            implicitWidth: syncText.implicitWidth + 14
                            radius: Theme.radiusSm
                            color: syncMouse.containsMouse ? Theme.surface_container_high : Theme.surface_container_highest

                            Behavior on color { ColorAnimation { duration: Theme.animFast } }

                            Text {
                                id: syncText
                                anchors.centerIn: parent
                                text: "match scoops (" + Settings.scoopRadius + "px)"
                                font.family: Theme.fontFamily
                                font.pixelSize: 9
                                color: Theme.primary
                            }

                            MouseArea {
                                id: syncMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Settings.screenCornerRadius = Settings.scoopRadius
                            }
                        }

                        CategoryHeader {
                            title: "granular density & metrics"
                            icon: Theme.iconSliders
                        }

                        SliderRow {
                            title: "widget spacing"
                            from: 0
                            to: 16
                            stepSize: 1
                            suffix: "px"
                            value: Settings.widgetSpacing
                            onMoved: val => Settings.widgetSpacing = val
                        }

                        SliderRow {
                            title: "widget padding"
                            from: 2
                            to: 18
                            stepSize: 1
                            suffix: "px"
                            value: Settings.widgetPaddingH
                            onMoved: val => Settings.widgetPaddingH = val
                        }

                        ChoiceRow {
                            title: "widget corner radius"
                            model: [
                                { label: "sharp (0px)", value: 0 },
                                { label: "2px", value: 2 },
                                { label: "4px", value: 4 },
                                { label: "8px", value: 8 },
                                { label: "pill", value: 9999 }
                            ]
                            currentValue: Settings.widgetRadius
                            onSelected: val => Settings.widgetRadius = val
                        }

                        SliderRow {
                            title: "popup corner radius"
                            from: 0
                            to: 28
                            stepSize: 2
                            suffix: "px"
                            value: Settings.popupRadius
                            onMoved: val => Settings.popupRadius = val
                        }

                        SliderRow {
                            title: "bar background opacity"
                            from: 0.3
                            to: 1.0
                            stepSize: 0.05
                            value: Settings.barOpacity
                            formatter: v => Math.round(v * 100) + "%"
                            onMoved: val => Settings.barOpacity = val
                        }

                        SliderRow {
                            title: "popup background opacity"
                            from: 0.5
                            to: 1.0
                            stepSize: 0.05
                            value: Settings.popupOpacity
                            formatter: v => Math.round(v * 100) + "%"
                            onMoved: val => Settings.popupOpacity = val
                        }

                        SettingCard {
                            ToggleRow {
                                icon: Theme.iconGrid
                                title: "floating bar"
                                subtitle: "detach status bar from screen edge"
                                checked: Settings.barFloating
                                onToggled: Settings.barFloating = !Settings.barFloating
                            }

                            RowDivider { visible: Settings.barFloating }

                            Item {
                                visible: Settings.barFloating
                                width: parent.width
                                implicitHeight: floatRadiusRow.implicitHeight + 16

                                SliderRow {
                                    id: floatRadiusRow
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.margins: Theme.widgetPaddingH
                                    title: "floating bar corner radius"
                                    from: 0
                                    to: 24
                                    stepSize: 2
                                    suffix: "px"
                                    value: Settings.barRadius
                                    onMoved: val => Settings.barRadius = val
                                }
                            }
                        }
                    }
                }
                TabScrollTrack { target: flickLayout }

                Flickable {
                    id: flickModules
                    anchors.fill: parent
                    visible: root.activeTab === "modules"
                    clip: true
                    contentWidth: width
                    contentHeight: modCol.implicitHeight + 12
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
                                        text: Settings.showBarStudio ? "active ✓" : "open studio →"
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
                            RowDivider {}
                            Item {
                                width: parent.width
                                implicitHeight: winTitleStretchRow.implicitHeight + 16
                                ChoiceRow {
                                    id: winTitleStretchRow
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.margins: Theme.widgetPaddingH
                                    title: "window title stretch"
                                    model: [
                                        { label: "full title (auto)", value: "auto" },
                                        { label: "fill bar", value: "fill" },
                                        { label: "compact (260px)", value: "compact" }
                                    ]
                                    currentValue: Settings.windowTitleMode
                                    onSelected: val => Settings.windowTitleMode = val
                                }
                            }
                            RowDivider {}
                            ToggleRow {
                                icon: Theme.iconTerminal
                                title: "app icon in window title"
                                checked: Settings.windowTitleShowIcon
                                onToggled: Settings.windowTitleShowIcon = !Settings.windowTitleShowIcon
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
                TabScrollTrack { target: flickModules }

                Flickable {
                    id: flickFonts
                    anchors.fill: parent
                    visible: root.activeTab === "fonts"
                    clip: true
                    contentWidth: width
                    contentHeight: fontCol.implicitHeight + 12
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
                                        text: "filter " + root.allFonts.length + " installed fonts..."
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
                                        onTextChanged: root.fontSearchQuery = text
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
                            height: 220
                            color: Theme.cardBg
                            radius: Theme.widgetRadius
                            border.color: Theme.widgetBorder
                            border.width: 1
                            clip: true

                            WheelHandler {
                                target: fontListView
                                onWheel: (event) => {
                                    fontListView.flick(0, event.angleDelta.y * 6);
                                }
                            }

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
                                            text: isCurrent ? (Theme.iconCheck + " active") : "the quick brown fox 123"
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

                            Rectangle {
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                anchors.margins: 2
                                width: 3
                                radius: 1.5
                                color: "transparent"
                                visible: fontListView.visibleArea.heightRatio < 1.0

                                Rectangle {
                                    width: parent.width
                                    readonly property real thumbH: Math.max(16, Math.min(parent.height, fontListView.visibleArea.heightRatio * parent.height))
                                    height: thumbH
                                    y: Math.max(0, Math.min(parent.height - thumbH, fontListView.visibleArea.yPosition * parent.height))
                                    radius: 1.5
                                    color: Theme.primary_overlay
                                }
                            }

                            Text {
                                anchors.centerIn: parent
                                visible: root.filteredFonts.length === 0
                                text: root.fontSearchQuery.trim() !== "" ? ("no fonts matching \"" + root.fontSearchQuery.trim() + "\"") : "no system fonts detected"
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeXs
                                color: Theme.on_surface_variant
                            }
                        }

                        // Live Typography Preview Card
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: prevCol.implicitHeight + 16
                            color: Theme.cardBg
                            radius: Theme.widgetRadius
                            border.color: Theme.cardBorder
                            border.width: 1

                            ColumnLayout {
                                id: prevCol
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 6

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text {
                                        text: "preview: " + (root.fontTarget === "sans" ? Settings.fontFamily : Settings.fontMono)
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.fontSizeXs
                                        font.weight: Font.Bold
                                        color: Theme.primary
                                        Layout.fillWidth: true
                                    }
                                    Text {
                                        text: Settings.fontScale + "x scale • " + Settings.fontWeight
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.fontSizeXs
                                        color: Theme.on_surface_variant
                                    }
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: "the quick brown fox jumps over the lazy dog 0123456789"
                                    font.family: root.fontTarget === "sans" ? Settings.fontFamily : Settings.fontMono
                                    font.pixelSize: Theme.fontSizeMd
                                    font.weight: Theme.getFontWeight ? Theme.getFontWeight(Settings.fontWeight) : Font.Normal
                                    color: Theme.on_surface
                                    wrapMode: Text.Wrap
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: "const vibe = async () => await rice.compile(); // 1234567890 != == ==="
                                    font.family: Settings.fontMono
                                    font.pixelSize: Theme.fontSizeSm
                                    color: Theme.primary
                                    wrapMode: Text.Wrap
                                }
                            }
                        }

                        CategoryHeader {
                            title: "typography scale & weight"
                            icon: Theme.iconSliders
                        }

                        SliderRow {
                            title: "interface font scaling"
                            from: 0.8
                            to: 1.4
                            stepSize: 0.05
                            value: Settings.fontScale
                            formatter: v => Math.round(v * 100) + "%"
                            onMoved: val => Settings.fontScale = val
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
                                { label: "material (rounded)", value: "material" },
                                { label: "material (outlined)", value: "material-outlined" },
                                { label: "material (sharp)", value: "material-sharp" },
                                { label: "nerd fonts", value: "nerd" },
                                { label: "windows segoe", value: "windows" },
                                { label: "font awesome", value: "awesome" },
                                { label: "(ﾉ◕ヮ◕)ﾉ kaomoji", value: "kaomoji" },
                                { label: "plain text", value: "text" }
                            ]
                            currentValue: (Settings.iconSet === "material" && Settings.fontMaterial === "Material Symbols Outlined") ? "material-outlined"
                                        : (Settings.iconSet === "material" && Settings.fontMaterial === "Material Symbols Sharp") ? "material-sharp"
                                        : Settings.iconSet
                            onSelected: val => {
                                Settings.iconSet = val;
                                if (val === "material-outlined") Settings.fontMaterial = "Material Symbols Outlined";
                                else if (val === "material-sharp") Settings.fontMaterial = "Material Symbols Sharp";
                                else if (val === "material") Settings.fontMaterial = "Material Symbols Rounded";
                                Settings.vibeStyle = (val === "kaomoji" || val === "text") ? val : "nerd";
                            }
                        }

                        ChoiceRow {
                            visible: Settings.iconSet === "nerd"
                            title: "nerd font family"
                            model: [
                                { label: "jetbrains mono nerd", value: "JetBrainsMono Nerd Font" },
                                { label: "jetbrains mono nf", value: "JetBrainsMono NF" }
                            ]
                            currentValue: Settings.fontNerd
                            onSelected: val => Settings.fontNerd = val
                        }

                        ChoiceRow {
                            visible: Settings.iconSet === "material" || Settings.iconSet.startsWith("material")
                            title: "material symbols style"
                            model: [
                                { label: "rounded", value: "Material Symbols Rounded" },
                                { label: "outlined", value: "Material Symbols Outlined" },
                                { label: "sharp", value: "Material Symbols Sharp" }
                            ]
                            currentValue: Settings.fontMaterial
                            onSelected: val => {
                                Settings.fontMaterial = val;
                                if (val === "Material Symbols Outlined") Settings.iconSet = "material-outlined";
                                else if (val === "Material Symbols Sharp") Settings.iconSet = "material-sharp";
                                else Settings.iconSet = "material";
                            }
                        }
                    }
                }
                TabScrollTrack { target: flickFonts }

                Flickable {
                    id: flickAnim
                    anchors.fill: parent
                    visible: root.activeTab === "animations"
                    clip: true
                    contentWidth: width
                    contentHeight: animCol.implicitHeight + 12
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
                            title: "workspace animation modes"
                            icon: Theme.iconWorkspaces
                        }

                        ChoiceRow {
                            title: "motion style"
                            model: [
                                { label: "smooth slide", value: "slide" },
                                { label: "caelestia trail", value: "fluid-trail" },
                                { label: "discrete pill", value: "discrete" }
                            ]
                            currentValue: Settings.workspaceMode
                            onSelected: val => Settings.workspaceMode = val
                        }

                        SliderRow {
                            visible: Settings.workspaceMode === "fluid-trail"
                            title: "trail duration"
                            from: 120
                            to: 400
                            stepSize: 10
                            suffix: "ms"
                            value: Settings.workspaceTrailDuration
                            onMoved: val => Settings.workspaceTrailDuration = val
                        }

                        CategoryHeader {
                            title: "hover gestures & auto-open"
                            icon: Theme.iconEye
                        }

                        SettingCard {
                            ToggleRow {
                                icon: Theme.iconEye
                                title: "hover to open flyouts"
                                subtitle: "hover over bar pills (battery, volume, window) to open popups"
                                checked: Settings.hoverToOpen
                                onToggled: Settings.hoverToOpen = !Settings.hoverToOpen
                            }

                            RowDivider {}

                            ToggleRow {
                                icon: Theme.iconEyeOff
                                title: "hover auto-close"
                                subtitle: "automatically dismiss popup when cursor leaves pill and card"
                                checked: Settings.hoverAutoClose
                                onToggled: Settings.hoverAutoClose = !Settings.hoverAutoClose
                            }
                        }

                        SliderRow {
                            visible: Settings.hoverToOpen
                            title: "hover activation delay"
                            from: 80
                            to: 600
                            stepSize: 10
                            suffix: "ms"
                            value: Settings.hoverDelay
                            onMoved: val => Settings.hoverDelay = val
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
                                        text: Settings.showMotionSandbox ? "active ✓" : "launch →"
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
                TabScrollTrack { target: flickAnim }

                Flickable {
                    id: flickVibe
                    anchors.fill: parent
                    visible: root.activeTab === "vibe"
                    clip: true
                    contentWidth: width
                    contentHeight: vibeCol.implicitHeight + 12
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
                                { label: "24h (16:45)", value: "HH:mm" },
                                { label: "12h (4:45 pm)", value: "h:mm ap" },
                                { label: "24h + sec", value: "HH:mm:ss" },
                                { label: "12h + sec", value: "h:mm:ss ap" }
                            ]
                            currentValue: Settings.clockFormat
                            onSelected: val => Settings.clockFormat = val
                        }

                        ChoiceGrid {
                            title: "date display format"
                            columns: 2
                            model: [
                                { label: "hidden (time only)", value: "none" },
                                { label: "short (mon, sep 1)", value: "ddd, MMM d" },
                                { label: "standard (sep 1)", value: "MMM d, yyyy" },
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
                            title: "audio & output volume"
                            icon: Theme.iconVolHigh
                        }

                        SliderRow {
                            title: "volume scroll step"
                            from: 1
                            to: 15
                            stepSize: 1
                            value: Settings.volumeStep
                            formatter: v => Math.round(v) + "%"
                            onMoved: val => Settings.volumeStep = val
                        }

                        SliderRow {
                            title: "max volume ceiling"
                            from: 100
                            to: 200
                            stepSize: 5
                            value: Settings.volumeMax
                            formatter: v => Math.round(v) + "%"
                            onMoved: val => Settings.volumeMax = val
                        }

                        CategoryHeader {
                            title: "notifications & alerts"
                            icon: Theme.iconBell
                        }

                        ChoiceRow {
                            title: "toast auto-dismiss duration"
                            model: [
                                { label: "3s (fast)", value: 3000 },
                                { label: "5s (normal)", value: 5000 },
                                { label: "8s (slow)", value: 8000 },
                                { label: "12s (long)", value: 12000 },
                                { label: "sticky", value: 0 }
                            ]
                            currentValue: Settings.notificationTimeout
                            onSelected: val => Settings.notificationTimeout = val
                        }

                        SettingCard {
                            ToggleRow {
                                icon: Theme.iconBell
                                title: "do not disturb"
                                subtitle: "suppress on-screen notification popups"
                                checked: Settings.dnd
                                onToggled: Settings.dnd = !Settings.dnd
                            }
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
                            color: Theme.cardBg
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
                TabScrollTrack { target: flickVibe }

                Flickable {
                    id: flickScreenshot
                    anchors.fill: parent
                    visible: root.activeTab === "screenshot"
                    clip: true
                    contentWidth: width
                    contentHeight: screenshotCol.implicitHeight + 12
                    boundsBehavior: Flickable.StopAtBounds

                    ColumnLayout {
                        id: screenshotCol
                        width: parent.width - 6
                        spacing: 10

                        CategoryHeader {
                            title: "quick capture triggers"
                            icon: Theme.iconCamera
                        }

                        SettingCard {
                            Item {
                                width: parent.width
                                implicitHeight: 52

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 8
                                    spacing: 8

                                    Rectangle {
                                        Layout.fillWidth: true
                                        height: 36
                                        radius: Theme.widgetRadius
                                        color: regMouse.pressed ? Theme.primary : (regMouse.containsMouse ? Theme.primary_overlay : Theme.surface_container_highest)
                                        border.color: Theme.outline_variant
                                        border.width: 1

                                        Behavior on color { ColorAnimation { duration: Theme.animFast } }

                                        RowLayout {
                                            anchors.centerIn: parent
                                            spacing: 6
                                            Text {
                                                text: Theme.iconCrop
                                                font.family: Theme.fontIcon
                                                font.pixelSize: Theme.fontSizeSm
                                                color: regMouse.pressed ? Theme.on_primary : Theme.primary
                                            }
                                            Text {
                                                text: "region"
                                                font.family: Theme.fontFamily
                                                font.pixelSize: Theme.fontSizeSm
                                                font.weight: Font.Medium
                                                color: regMouse.pressed ? Theme.on_primary : Theme.on_surface
                                            }
                                        }

                                        MouseArea {
                                            id: regMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                popup.open = false;
                                                ScreenshotService.open("region");
                                            }
                                        }
                                    }

                                    Rectangle {
                                        Layout.fillWidth: true
                                        height: 36
                                        radius: Theme.widgetRadius
                                        color: winMouse.pressed ? Theme.primary : (winMouse.containsMouse ? Theme.primary_overlay : Theme.surface_container_highest)
                                        border.color: Theme.outline_variant
                                        border.width: 1

                                        Behavior on color { ColorAnimation { duration: Theme.animFast } }

                                        RowLayout {
                                            anchors.centerIn: parent
                                            spacing: 6
                                            Text {
                                                text: Theme.iconWorkspaces
                                                font.family: Theme.fontIcon
                                                font.pixelSize: Theme.fontSizeSm
                                                color: winMouse.pressed ? Theme.on_primary : Theme.primary
                                            }
                                            Text {
                                                text: "window"
                                                font.family: Theme.fontFamily
                                                font.pixelSize: Theme.fontSizeSm
                                                font.weight: Font.Medium
                                                color: winMouse.pressed ? Theme.on_primary : Theme.on_surface
                                            }
                                        }

                                        MouseArea {
                                            id: winMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                popup.open = false;
                                                ScreenshotService.open("window");
                                            }
                                        }
                                    }

                                    Rectangle {
                                        Layout.fillWidth: true
                                        height: 36
                                        radius: Theme.widgetRadius
                                        color: fullMouse.pressed ? Theme.primary : (fullMouse.containsMouse ? Theme.primary_overlay : Theme.surface_container_highest)
                                        border.color: Theme.outline_variant
                                        border.width: 1

                                        Behavior on color { ColorAnimation { duration: Theme.animFast } }

                                        RowLayout {
                                            anchors.centerIn: parent
                                            spacing: 6
                                            Text {
                                                text: Theme.iconExpand
                                                font.family: Theme.fontIcon
                                                font.pixelSize: Theme.fontSizeSm
                                                color: fullMouse.pressed ? Theme.on_primary : Theme.primary
                                            }
                                            Text {
                                                text: "fullscreen"
                                                font.family: Theme.fontFamily
                                                font.pixelSize: Theme.fontSizeSm
                                                font.weight: Font.Medium
                                                color: fullMouse.pressed ? Theme.on_primary : Theme.on_surface
                                            }
                                        }

                                        MouseArea {
                                            id: fullMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                popup.open = false;
                                                const scr = root.barScreen || (Quickshell.screens && Quickshell.screens.length > 0 ? Quickshell.screens[0] : null);
                                                ScreenshotService.captureFullscreen(scr, Settings.screenshotDefaultAction || "both");
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        CategoryHeader {
                            title: "capture behavior & feedback"
                            icon: Theme.iconSliders
                        }

                        ChoiceRow {
                            title: "default action on confirmation"
                            model: [
                                { label: "save & copy", value: "both" },
                                { label: "clipboard only", value: "copy" },
                                { label: "save only", value: "save" },
                                { label: "editor / markup", value: "edit" }
                            ]
                            currentValue: Settings.screenshotDefaultAction
                            onSelected: val => Settings.screenshotDefaultAction = val
                        }

                        SettingCard {
                            ToggleRow {
                                icon: Theme.iconWorkspaces
                                title: "window snapping"
                                subtitle: "hover over any hyprland client to auto-detect its geometry"
                                checked: Settings.screenshotWindowSnapping
                                onToggled: Settings.screenshotWindowSnapping = !Settings.screenshotWindowSnapping
                            }

                            RowDivider {}

                            ToggleRow {
                                icon: Theme.iconEye
                                title: "freeze frame on open"
                                subtitle: "freeze display during selection so animated windows don't move"
                                checked: Settings.screenshotFreeze
                                onToggled: Settings.screenshotFreeze = !Settings.screenshotFreeze
                            }

                            RowDivider {}

                            ToggleRow {
                                icon: Theme.iconFlame
                                title: "shutter flash"
                                subtitle: "visual flash animation when capture is completed"
                                checked: Settings.screenshotFlash
                                onToggled: Settings.screenshotFlash = !Settings.screenshotFlash
                            }

                            RowDivider {}

                            ToggleRow {
                                icon: Theme.iconBell
                                title: "desktop notification"
                                subtitle: "dispatch notification with image thumbnail on capture"
                                checked: Settings.screenshotNotify
                                onToggled: Settings.screenshotNotify = !Settings.screenshotNotify
                            }
                        }

                        CategoryHeader {
                            title: "overlay visuals & geometry"
                            icon: Theme.iconSliders
                        }

                        SliderRow {
                            title: "backdrop dimming opacity"
                            from: 0.1
                            to: 0.9
                            stepSize: 0.05
                            value: Settings.screenshotDimOpacity
                            formatter: v => Math.round(v * 100) + "%"
                            onMoved: val => Settings.screenshotDimOpacity = val
                        }

                        SliderRow {
                            title: "selection border width"
                            from: 1
                            to: 6
                            stepSize: 1
                            suffix: "px"
                            value: Settings.screenshotBorderWidth
                            onMoved: val => Settings.screenshotBorderWidth = val
                        }

                        SliderRow {
                            title: "selection corner radius"
                            from: 0
                            to: 20
                            stepSize: 2
                            suffix: "px"
                            value: Settings.screenshotBorderRadius
                            onMoved: val => Settings.screenshotBorderRadius = val
                        }

                        SettingCard {
                            ToggleRow {
                                icon: Theme.iconGrid
                                title: "hairline crosshairs"
                                subtitle: "show screen-spanning crosshair lines tracking cursor"
                                checked: Settings.screenshotShowCrosshair
                                onToggled: Settings.screenshotShowCrosshair = !Settings.screenshotShowCrosshair
                            }

                            RowDivider {}

                            ToggleRow {
                                icon: Theme.iconNote
                                title: "live dimension badge"
                                subtitle: "show [W x H] badge and client name above selection"
                                checked: Settings.screenshotShowBadge
                                onToggled: Settings.screenshotShowBadge = !Settings.screenshotShowBadge
                            }

                            RowDivider {}

                            ToggleRow {
                                icon: Theme.iconExpand
                                title: "corner accent handles"
                                subtitle: "render accent markers on selection corners"
                                checked: Settings.screenshotShowHandles
                                onToggled: Settings.screenshotShowHandles = !Settings.screenshotShowHandles
                            }
                        }

                        CategoryHeader {
                            title: "storage directory"
                            icon: Theme.iconFolder
                        }

                        SettingCard {
                            Rectangle {
                                width: parent.width
                                implicitHeight: 44
                                height: implicitHeight
                                color: "transparent"

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: Theme.widgetPaddingH
                                    anchors.rightMargin: Theme.widgetPaddingH
                                    spacing: 8

                                    Text {
                                        text: Theme.iconFolder
                                        font.family: Theme.fontIcon
                                        font.pixelSize: Theme.fontSizeSm
                                        color: Theme.primary
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: Settings.screenshotDir
                                        font.family: Theme.fontMono
                                        font.pixelSize: Theme.fontSizeXs
                                        color: Theme.on_surface
                                        elide: Text.ElideMiddle
                                    }
                                }
                            }
                        }
                    }
                }
                TabScrollTrack { target: flickScreenshot }

                Flickable {
                    id: flickShells
                    anchors.fill: parent
                    visible: root.activeTab === "shells"
                    clip: true
                    contentWidth: width
                    contentHeight: shellsCol.implicitHeight + 16
                    boundsBehavior: Flickable.StopAtBounds

                    ColumnLayout {
                        id: shellsCol
                        width: parent.width - 6
                        spacing: 10

                        CategoryHeader {
                            title: "desktop shell profiles"
                            icon: Theme.iconTerminal
                        }

                        // Rich profile cards replacing the plain choice row
                        SettingCard {
                            Repeater {
                                model: [
                                    {
                                        id: "quickshell",
                                        name: "quickshell (native)",
                                        desc: "my shitty ai-generated quickshell setup",
                                        path: "~/.config/quickshell",
                                        icon: Theme.iconSliders
                                    },
                                    {
                                        id: "brain_shell",
                                        name: "brain shell",
                                        desc: "material you shell with dynamic matugen theming",
                                        path: "~/.config/Brain_Shell",
                                        icon: Theme.iconSparkles
                                    }
                                ]

                                delegate: Column {
                                    required property var modelData
                                    required property int index
                                    width: parent.width
                                    spacing: 0

                                    RowDivider { visible: index > 0 }

                                    Rectangle {
                                        width: parent.width
                                        implicitHeight: 64
                                        color: root.activeShell === modelData.id
                                            ? Theme.primary_overlay
                                            : (shMouse.containsMouse ? Theme.surface_container_highest : "transparent")

                                        Behavior on color { ColorAnimation { duration: Theme.animFast } }

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.margins: Theme.widgetPaddingH
                                            spacing: 12

                                            Rectangle {
                                                width: 36
                                                height: 36
                                                radius: Theme.radiusSm
                                                color: root.activeShell === modelData.id ? Theme.primary : Theme.surface_container_high

                                                Text {
                                                    anchors.centerIn: parent
                                                    text: modelData.icon
                                                    font.family: Theme.fontIcon
                                                    font.pixelSize: Theme.fontSizeSm
                                                    color: root.activeShell === modelData.id ? Theme.on_primary : Theme.on_surface_variant
                                                }
                                            }

                                            ColumnLayout {
                                                Layout.fillWidth: true
                                                spacing: 2

                                                RowLayout {
                                                    spacing: 6
                                                    Text {
                                                        text: modelData.name
                                                        font.family: Theme.fontFamily
                                                        font.pixelSize: Theme.fontSizeSm
                                                        font.weight: Font.Bold
                                                        color: Theme.on_surface
                                                    }
                                                    Rectangle {
                                                        visible: root.activeShell === modelData.id
                                                        height: 16
                                                        width: activeText.implicitWidth + 10
                                                        radius: 8
                                                        color: Theme.primary

                                                        Text {
                                                            id: activeText
                                                            anchors.centerIn: parent
                                                            text: "ACTIVE"
                                                            font.family: Theme.fontFamily
                                                            font.pixelSize: 8
                                                            font.weight: Font.Bold
                                                            color: Theme.on_primary
                                                        }
                                                    }
                                                }

                                                Text {
                                                    text: modelData.desc
                                                    font.family: Theme.fontFamily
                                                    font.pixelSize: 10
                                                    color: Theme.on_surface_variant
                                                }

                                                Text {
                                                    text: modelData.path
                                                    font.family: Theme.fontMono
                                                    font.pixelSize: 9
                                                    color: Theme.primary
                                                }
                                            }

                                            Rectangle {
                                                height: 28
                                                width: 72
                                                radius: Theme.radiusSm
                                                color: root.activeShell === modelData.id
                                                    ? Theme.surface_container_high
                                                    : (shBtnMouse.containsMouse ? Theme.primary : Theme.surface_container_highest)
                                                border.color: root.activeShell === modelData.id ? Theme.primary : "transparent"
                                                border.width: 1

                                                Behavior on color { ColorAnimation { duration: Theme.animFast } }

                                                Text {
                                                    anchors.centerIn: parent
                                                    text: root.activeShell === modelData.id ? "current" : "switch"
                                                    font.family: Theme.fontFamily
                                                    font.pixelSize: 10
                                                    font.weight: Font.Bold
                                                    color: root.activeShell === modelData.id ? Theme.primary : (shBtnMouse.containsMouse ? Theme.on_primary : Theme.on_surface)
                                                }

                                                MouseArea {
                                                    id: shBtnMouse
                                                    anchors.fill: parent
                                                    hoverEnabled: true
                                                    cursorShape: root.activeShell === modelData.id ? Qt.ArrowCursor : Qt.PointingHandCursor
                                                    onClicked: {
                                                        if (root.activeShell !== modelData.id) {
                                                            root.activeShell = modelData.id;
                                                            switchProc.switchShell(modelData.id);
                                                        }
                                                    }
                                                }
                                            }
                                        }

                                        MouseArea {
                                            id: shMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                if (root.activeShell !== modelData.id) {
                                                    root.activeShell = modelData.id;
                                                    switchProc.switchShell(modelData.id);
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        CategoryHeader {
                            title: "process controls"
                            icon: Theme.iconSliders
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Rectangle {
                                Layout.fillWidth: true
                                height: 38
                                radius: Theme.widgetRadius
                                color: rstMouse.containsMouse ? Theme.primary_overlay : Theme.surface_container_highest
                                border.color: rstMouse.containsMouse ? Theme.primary : Theme.widgetBorder
                                border.width: 1

                                Behavior on color { ColorAnimation { duration: Theme.animFast } }
                                Behavior on border.color { ColorAnimation { duration: Theme.animFast } }

                                RowLayout {
                                    anchors.centerIn: parent
                                    spacing: 8

                                    Text {
                                        text: Theme.iconHistory
                                        font.family: Theme.fontIcon
                                        font.pixelSize: Theme.fontSizeSm
                                        color: Theme.primary
                                    }

                                    Text {
                                        text: switchProc.running ? "restarting shell..." : "restart active shell"
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.fontSizeSm
                                        font.weight: Font.Medium
                                        color: Theme.on_surface
                                    }
                                }

                                MouseArea {
                                    id: rstMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    enabled: !switchProc.running
                                    onClicked: switchProc.restartCurrent()
                                }
                            }
                        }

                        CategoryHeader {
                            title: "shell state & info"
                            icon: Theme.iconNote
                        }

                        SettingCard {
                            Item {
                                width: parent.width
                                implicitHeight: infoCol.implicitHeight + 24
                                ColumnLayout {
                                    id: infoCol
                                    anchors.fill: parent
                                    anchors.margins: 12
                                    spacing: 8

                                    RowLayout {
                                        spacing: 8
                                        Text {
                                            text: "󰈙"
                                            font.family: Theme.fontIcon
                                            font.pixelSize: Theme.fontSizeSm
                                            color: Theme.primary
                                        }
                                        Text {
                                            text: "state cache:"
                                            font.family: Theme.fontFamily
                                            font.pixelSize: Theme.fontSizeXs
                                            font.weight: Font.Bold
                                            color: Theme.on_surface
                                        }
                                        Text {
                                            text: "~/.cache/current_shell"
                                            font.family: Theme.fontMono
                                            font.pixelSize: 10
                                            color: Theme.on_surface_variant
                                            Layout.fillWidth: true
                                        }
                                    }

                                    Text {
                                        text: "switch script automatically updates state cache so your selection persists across hyprland sessions and reboots."
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 10
                                        color: Theme.on_surface_variant
                                        wrapMode: Text.Wrap
                                        Layout.fillWidth: true
                                    }
                                }
                            }
                        }
                    }
                }
                TabScrollTrack { target: flickShells }
            }
        }

        Rectangle {
            id: resetConfirmModal
            anchors.fill: parent
            color: Theme.alpha(Theme.background, 0.94)
            visible: root.showResetConfirm
            z: 999
            radius: Theme.popupRadius
            focus: visible

            Keys.onEscapePressed: root.showResetConfirm = false

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
