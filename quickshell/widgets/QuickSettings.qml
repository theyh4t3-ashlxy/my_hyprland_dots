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
    color: popup.open ? Theme.primary_container : (qsMouse.containsMouse ? Theme.pillHover : Theme.pillBg)
    border.color: Theme.pillBorder
    border.width: Theme.pillBorder === "transparent" ? 0 : Theme.popupBorderWidth
    // Scope safety guard for dynamic signal connections

    Behavior on color { ColorAnimation { duration: Theme.animFast; easing.type: Theme.animColorEasing } }
    Behavior on border.color { ColorAnimation { duration: Theme.animFast; easing.type: Theme.animColorEasing } }

    property var barScreen: null
    property var barMonitor: null
    property string activeTab: "layout"
    property string fontTarget: "sans"
    property string fontSearchQuery: ""
    property bool showResetConfirm: false
    property string activeShell: "quickshell"

    readonly property string activeTabTitle: ({
        layout: "layout",
        style: "appearance",
        behavior: "behavior",
        capture: "capture",
        keybinds: "keybinds",
        advanced: "system"
    })[root.activeTab] || "settings"

    readonly property bool usingMaterialIcons: Settings.iconSet === "material" || Settings.iconSet === "material-outlined" || Settings.iconSet === "material-sharp"
    // Material 3 / Matugen semantic surfaces used throughout this panel.
    readonly property color uiSurface0: Theme.surface_container_lowest
    readonly property color uiSurface1: Theme.surface_container_low
    readonly property color uiSurface2: Theme.surface_container
    readonly property color uiSurface3: Theme.surface_container_high
    readonly property color uiSurface4: Theme.surface_container_highest
    readonly property color uiAccentContainer: Theme.primary_container
    readonly property color uiAccentText: Theme.on_primary_container
    readonly property color uiOutline: Theme.outline_variant
    readonly property color uiSubtleText: Theme.on_surface_variant


    readonly property string activeTabSubtitle: ({
        layout: "arrange the bar and choose what lives on it",
        style: "shape, color, typography, and visual personality",
        behavior: "motion, hover behavior, feedback, and interaction",
        capture: "screenshots, recording, and selection overlays",
        keybinds: "view and manage your shell shortcuts",
        advanced: "shell profiles, cache, aliases, and recovery tools"
    })[root.activeTab] || ""

    onActiveTabChanged: {
        // Keep each page feeling like a fresh workspace instead of a stale scroll position.
        if (root.activeTab === "layout" && flickLayout) flickLayout.contentY = 0;
        else if (root.activeTab === "style" && flickStyle) flickStyle.contentY = 0;
        else if (root.activeTab === "behavior" && flickBehavior) flickBehavior.contentY = 0;
        else if (root.activeTab === "capture" && flickScreenshot) flickScreenshot.contentY = 0;
        else if (root.activeTab === "advanced" && flickAdvanced) flickAdvanced.contentY = 0;
    }

    Connections {
        target: Settings
        function onShowShellTabChanged() {
            if (Settings.showShellTab === false && root.activeTab === "advanced") {
                root.activeTab = "layout";
            }
        }
    }

    readonly property string userHome: Quickshell.env("HOME") || ""
    readonly property string cacheDir: Quickshell.env("XDG_CACHE_HOME") || (userHome + "/.cache")

    FileView {
        id: shellWatcher
        printErrors: false
        path: root.cacheDir + "/current_shell"
        watchChanges: true
        onFileChanged: { reload(); }
        onLoaded: {
            const s = text().trim();
            if (s === "brain_shell" || s === "quickshell") {
                root.activeShell = s;
            } else if (s === "oxytocin") {
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
        onExited: {
            shellWatcher.reload();
        }
    }

    readonly property var allFonts: {
        try {
            const raw = Qt.fontFamilies();
            if (!raw || raw.length === 0) return [];
            return Array.from(raw).sort(function(a, b) {
                return a.localeCompare(b, undefined, { sensitivity: "base" });
            });
        } catch (e) {
            return [];
        }
    }

    readonly property var filteredFonts: {
        if (!fontSearchQuery || fontSearchQuery.trim() === "") return allFonts;
        const q = fontSearchQuery.trim().toLowerCase();
        return allFonts.filter(function(f) { return f && f.toLowerCase().includes(q); });
    }

    // --- INLINE COMPONENTS (Safely inside root) ---

    component CategoryHeader: ColumnLayout {
    id: catHdr
    property string title: ""
    property string icon: ""
    property string subtitle: ""

    Layout.fillWidth: true
    Layout.topMargin: 14
    Layout.bottomMargin: 2
    spacing: 5

    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        Rectangle {
            visible: catHdr.icon !== ""
            width: 26
            height: 26
            radius: Theme.radiusSm
            color: Theme.primary_container
            border.color: Theme.alpha(Theme.outline_variant, 0.45)
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: catHdr.icon
                font.family: Theme.fontIcon
                font.pixelSize: Theme.fontSizeXs
                color: Theme.on_primary_container
            }
        }

        Text {
            text: catHdr.title
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeSm
            font.weight: Theme.fontWeightBold
            color: Theme.on_surface
            Layout.alignment: Qt.AlignVCenter
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Theme.outline_variant
            opacity: 0.55
            Layout.alignment: Qt.AlignVCenter
        }
    }

    Text {
        visible: catHdr.subtitle !== ""
        text: catHdr.subtitle
        Layout.leftMargin: 34
        Layout.fillWidth: true
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeXs
        font.weight: Theme.fontWeightRegular
        color: Theme.on_surface_variant
        wrapMode: Text.Wrap
    }
}

    component SettingCard: Rectangle {
    default property alias content: cardCol.data
    Layout.fillWidth: true
    width: parent ? parent.width : undefined
    implicitHeight: cardCol.implicitHeight + 18
    radius: Theme.radiusMd
    color: Theme.cardBg
    border.color: Theme.outline_variant
    border.width: Theme.popupBorderWidth
    clip: true

    Column {
        id: cardCol
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.leftMargin: Theme.widgetPaddingH
        anchors.rightMargin: Theme.widgetPaddingH
        anchors.topMargin: Theme.widgetPaddingV
        anchors.bottomMargin: Theme.widgetPaddingV
        spacing: 2
    }
}

    component RowDivider: Rectangle {
    width: parent ? parent.width - 24 : 0
    anchors.horizontalCenter: parent ? parent.horizontalCenter : undefined
    height: 1
    color: Theme.outline_variant
    opacity: 0.42
}

    component ToggleRow: Rectangle {
    id: trRoot
    property string icon: ""
    property string title: ""
    property string subtitle: ""
    property bool checked: false
    signal toggled()

    width: parent ? parent.width : 0
    implicitHeight: subtitle !== "" ? 50 : 40
    height: implicitHeight
    radius: Theme.radiusSm
    color: trMouse.containsMouse ? Theme.widgetHover : "transparent"
    Behavior on color { ColorAnimation { duration: Theme.animFast; easing.type: Theme.animColorEasing } }

    Rectangle {
        id: trIcon
        visible: trRoot.icon !== ""
        anchors.left: parent.left
        anchors.leftMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        width: 28
        height: 28
        radius: Theme.radiusSm
        color: trRoot.checked ? Theme.primary_container : Theme.surface_container_high
        border.color: trRoot.checked ? Theme.alpha(Theme.primary, 0.26) : Theme.outline_disabled
        border.width: 1

        Behavior on color { ColorAnimation { duration: Theme.animFast; easing.type: Theme.animColorEasing } }

        Text {
            anchors.centerIn: parent
            text: trRoot.icon
            font.family: Theme.fontIcon
            font.pixelSize: Theme.fontSizeXs
            color: trRoot.checked ? Theme.on_primary_container : Theme.on_surface_variant
        }
    }

    ToggleSwitch {
        id: trSwitch
        anchors.right: parent.right
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        checked: trRoot.checked
        onToggled: trRoot.toggled()
    }

    Column {
        anchors.left: trIcon.visible ? trIcon.right : parent.left
        anchors.leftMargin: trIcon.visible ? 12 : 8
        anchors.right: trSwitch.left
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2

        Text {
            width: parent.width
            text: trRoot.title
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeSm
            font.weight: trRoot.checked ? Theme.fontWeightDemiBold : Theme.fontWeightMedium
            color: Theme.on_surface
            elide: Text.ElideRight
        }

        Text {
            visible: trRoot.subtitle !== ""
            width: parent.width
            text: trRoot.subtitle
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeXs
            color: Theme.on_surface_variant
            opacity: 0.9
            elide: Text.ElideRight
        }
    }

    MouseArea {
        id: trMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: trRoot.toggled()
    }
}

    component ColorRow: Rectangle {
    id: colRowRoot
    property string title: ""
    property string subtitle: ""
    property color swatchColor: Theme.primary
    signal clicked()

    width: parent ? parent.width : 0
    implicitHeight: subtitle !== "" ? 50 : 40
    height: implicitHeight
    radius: Theme.radiusSm
    color: colRowMouse.containsMouse ? Theme.widgetHover : "transparent"
    Behavior on color { ColorAnimation { duration: Theme.animFast; easing.type: Theme.animColorEasing } }

    Rectangle {
        id: colRowSwatch
        anchors.right: parent.right
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        width: 36
        height: 24
        radius: Theme.radiusSm
        color: colRowRoot.swatchColor
        border.color: Theme.alpha(Theme.outline, 0.55)
        border.width: 1
    }

    Column {
        anchors.left: parent.left
        anchors.leftMargin: 8
        anchors.right: colRowSwatch.left
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2

        Text {
            width: parent.width
            text: colRowRoot.title
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeSm
            font.weight: Theme.fontWeightMedium
            color: Theme.on_surface
            elide: Text.ElideRight
        }

        Text {
            visible: colRowRoot.subtitle !== ""
            width: parent.width
            text: colRowRoot.subtitle
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeXs
            color: Theme.on_surface_variant
            elide: Text.ElideRight
        }
    }

    MouseArea {
        id: colRowMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: colRowRoot.clicked()
    }
}

    component ColorTile: Rectangle {
    id: colorTileRoot
    property string title: ""
    property string subtitle: ""
    property color swatchColor: Theme.primary
    signal clicked()

    width: parent ? parent.width : 0
    Layout.fillWidth: true
    height: 58
    radius: Theme.radiusMd
    color: colorTileMouse.containsMouse ? Theme.surface_container_high : Theme.surface_container_low
    border.color: colorTileMouse.containsMouse ? Theme.primary : Theme.outline_variant
    border.width: 1

    Behavior on color { ColorAnimation { duration: Theme.animFast; easing.type: Theme.animColorEasing } }
    Behavior on border.color { ColorAnimation { duration: Theme.animFast; easing.type: Theme.animColorEasing } }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 8

        Rectangle {
            width: 32
            height: 32
            radius: Theme.radiusSm
            color: colorTileRoot.swatchColor
            border.color: Theme.alpha(Theme.outline, 0.6)
            border.width: 1
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 1

            Text {
                text: colorTileRoot.title
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeXs
                font.weight: Theme.fontWeightDemiBold
                color: Theme.on_surface
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            Text {
                text: colorTileRoot.subtitle
                font.family: Theme.fontMono
                font.pixelSize: 8
                color: Theme.on_surface_variant
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
        }
    }

    MouseArea {
        id: colorTileMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: colorTileRoot.clicked()
    }
}

    component ChoiceRow: ColumnLayout {
    id: crRoot
    property string title: ""
    property var model: []
    property var currentValue
    property int buttonHeight: 30
    signal selected(var value)

    width: parent ? parent.width : 0
    implicitWidth: width
    Layout.fillWidth: true
    spacing: 6

    Text {
        visible: crRoot.title !== ""
        text: crRoot.title
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSizeXs
        font.weight: Theme.fontWeightDemiBold
        color: Theme.on_surface_variant
    }

    Rectangle {
        Layout.fillWidth: true
        height: crRoot.buttonHeight + 8
        radius: Theme.radiusMd
        color: Theme.surface_container_lowest
        border.color: Theme.outline_variant
        border.width: 1

        RowLayout {
            anchors.fill: parent
            anchors.margins: 4
            spacing: 4

            Repeater {
                model: crRoot.model

                delegate: Rectangle {
                    required property var modelData
                    readonly property var itemVal: modelData && typeof modelData === "object"
                        ? (modelData.value !== undefined ? modelData.value : (modelData.pos !== undefined ? modelData.pos : (modelData.s !== undefined ? modelData.s : (modelData.w !== undefined ? modelData.w : (modelData.c !== undefined ? modelData.c : (modelData.fmt !== undefined ? modelData.fmt : modelData))))))
                        : modelData
                    readonly property string itemText: modelData && typeof modelData === "object" && modelData.label !== undefined
                        ? String(modelData.label)
                        : (typeof modelData === "number" ? (modelData === 0 ? "none" : modelData + "px") : String(modelData || ""))
                    readonly property bool isSelected: (typeof crRoot.currentValue === "number" && typeof itemVal === "number" && !Number.isInteger(itemVal))
                        ? Math.abs(crRoot.currentValue - itemVal) < 0.04
                        : crRoot.currentValue === itemVal

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: Math.max(1, Theme.radiusSm)
                    color: isSelected
                        ? Theme.primary_container
                        : (crMouse.containsMouse ? Theme.surface_container_highest : "transparent")

                    Behavior on color { ColorAnimation { duration: Theme.animFast; easing.type: Theme.animColorEasing } }

                    Text {
                        anchors.centerIn: parent
                        text: itemText
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeXs
                        font.weight: isSelected ? Theme.fontWeightDemiBold : Theme.fontWeightMedium
                        color: isSelected ? Theme.on_primary_container : Theme.on_surface
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
}

    component SliderRow: ColumnLayout {
    id: slRoot
    property string title: ""
    property real from: 0
    property real to: 100
    property real value: 0
    property real stepSize: 1
    property string suffix: "px"
    property var formatter: null
    signal moved(real val)

    width: parent ? parent.width : 0
    implicitWidth: width
    Layout.fillWidth: true
    spacing: 7

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
            font.weight: Theme.fontWeightDemiBold
            color: Theme.on_surface_variant
            Layout.fillWidth: true
        }

        Text {
            text: slRoot.displayText
            font.family: Theme.fontMono
            font.pixelSize: Theme.fontSizeXs
            font.weight: Theme.fontWeightBold
            color: Theme.primary
        }
    }

    Rectangle {
        id: track
        Layout.fillWidth: true
        height: 8
        radius: 4
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
            width: 18
            height: 18
            radius: 9
            y: (track.height - height) / 2
            x: Math.max(0, Math.min(track.width - width, track.width * track.ratio - width / 2))
            color: Theme.primary
            border.color: Theme.surface_bright
            border.width: 2
            scale: dragArea.pressed ? 1.12 : 1.0
            Behavior on scale { NumberAnimation { duration: Theme.animFast; easing.type: Theme.animEasing } }
        }

        MouseArea {
            id: dragArea
            anchors.fill: parent
            anchors.margins: -10
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            preventStealing: true

            function commit(localX) {
                const t = Math.max(0, Math.min(1, localX / track.width));
                let raw = slRoot.from + t * (slRoot.to - slRoot.from);
                if (slRoot.stepSize > 0) raw = Math.round(raw / slRoot.stepSize) * slRoot.stepSize;
                raw = Math.max(slRoot.from, Math.min(slRoot.to, raw));
                if (Math.abs(raw - slRoot.value) > 1e-9) slRoot.moved(raw);
            }

            onPressed: commit(mouseX - 10)
            onPositionChanged: if (pressed) commit(mouseX - 10)
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

        width: parent ? parent.width : 0
        implicitWidth: width
        Layout.fillWidth: true
        spacing: 6

        Text {
            visible: cgRoot.title !== ""
            text: cgRoot.title
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeXs
            font.weight: Theme.fontWeightDemiBold
            color: Theme.on_surface_variant
        }

        Grid {
            id: choiceGrid
            width: parent.width
            Layout.fillWidth: true
            columns: Math.max(1, cgRoot.columns)
            rowSpacing: 6
            columnSpacing: 6

            Repeater {
                model: cgRoot.model

                delegate: Rectangle {
                    required property var modelData

                    readonly property var itemVal:
                        modelData && typeof modelData === "object"
                            ? (modelData.value !== undefined ? modelData.value
                            : (modelData.id !== undefined ? modelData.id
                            : (modelData.s !== undefined ? modelData.s
                            : (modelData.m !== undefined ? modelData.m
                            : (modelData.fmt !== undefined ? modelData.fmt : modelData)))))
                            : modelData

                    readonly property string itemText:
                        modelData && typeof modelData === "object" && modelData.label !== undefined
                            ? String(modelData.label)
                            : String(modelData || "")

                    readonly property bool isSelected:
                        (typeof cgRoot.currentValue === "number" &&
                         typeof itemVal === "number" &&
                         !Number.isInteger(itemVal))
                            ? Math.abs(cgRoot.currentValue - itemVal) < 0.04
                            : cgRoot.currentValue === itemVal

                    width: Math.max(
                        1,
                        (choiceGrid.width - choiceGrid.columnSpacing * (choiceGrid.columns - 1))
                        / choiceGrid.columns
                    )
                    height: cgRoot.buttonHeight
                    radius: Theme.radiusSm
                    color: isSelected
                        ? Theme.primary_container
                        : (cgMouse.containsMouse
                            ? Theme.surface_container_highest
                            : Theme.surface_container_low)
                    border.color: isSelected ? Theme.primary : Theme.outline_variant
                    border.width: 1

                    Behavior on color {
                        ColorAnimation {
                            duration: Theme.animFast
                            easing.type: Theme.animColorEasing
                        }
                    }

                    Text {
                        id: choiceText
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignHCenter
                        text: itemText
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeXs
                        font.weight: isSelected ? Theme.fontWeightDemiBold : Theme.fontWeightMedium
                        color: isSelected ? Theme.on_primary_container : Theme.on_surface
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
    anchors.right: target ? target.right : undefined
    anchors.top: target ? target.top : undefined
    anchors.bottom: target ? target.bottom : undefined
    anchors.margins: 2
    width: 4
    radius: 2
    color: "transparent"
    visible: target ? (target.visible && target.visibleArea.heightRatio < 1.0) : false

    Rectangle {
        width: parent.width
        readonly property real trackH: stRoot.height
        readonly property real thumbH: Math.max(20, Math.min(trackH, (stRoot.target ? stRoot.target.visibleArea.heightRatio : 1) * trackH))
        height: thumbH
        y: Math.max(0, Math.min(trackH - thumbH, (stRoot.target ? stRoot.target.visibleArea.yPosition : 0) * trackH))
        radius: 2
        color: Theme.primary
        opacity: 0.75
    }
}
    // --- MAIN UI ---

    Row {
        id: qsRow
        anchors.centerIn: parent
        spacing: 4

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Theme.iconSettings
            font.family: Theme.fontIcon
            font.pixelSize: Theme.fontSizeMd
            color: popup.open ? Theme.on_primary_container : Theme.on_surface
        }
    }

    function updatePopupPos() {
        const p = root.mapToItem(null, 0, 0);
        if (p) {
            popup.targetRelativeX = p.x + (root.width / 2);
            popup.targetRelativeY = p.y + (root.height / 2);
        }
    }

    HoverFlyoutHandler {
        popup: popup
        mouseArea: qsMouse
        updatePos: () => root.updatePopupPos()
    }

    MouseArea {
        id: qsMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            root.updatePopupPos();
            if (!popup.open) {
                popup.pinned = true;
                popup.open = true;
            } else if (!popup.pinned) {
                popup.pinned = true;
            } else {
                popup.pinned = false;
                popup.open = false;
            }
        }
    }

    Connections {
        target: Settings
        function onRequestQuickSettingsToggle() {
            if (!root.barScreen || Quickshell.screens.length <= 1 || (root.barMonitor && Hyprland.focusedMonitor && root.barMonitor.id === Hyprland.focusedMonitor.id)) {
                popup.open = !popup.open;
            }
        }
        function onRequestQuickSettingsOpen() {
            if (!root.barScreen || Quickshell.screens.length <= 1 || (root.barMonitor && Hyprland.focusedMonitor && root.barMonitor.id === Hyprland.focusedMonitor.id)) {
                popup.open = true;
            }
        }
        function onRequestQuickSettingsClose() {
            popup.open = false;
        }
        function onRequestKeybindsToggle() {
            if (!root.barScreen || Quickshell.screens.length <= 1 || (root.barMonitor && Hyprland.focusedMonitor && root.barMonitor.id === Hyprland.focusedMonitor.id)) {
                if (!popup.open) {
                    root.activeTab = "keybinds";
                    popup.open = true;
                } else if (root.activeTab === "keybinds") {
                    popup.open = false;
                } else {
                    root.activeTab = "keybinds";
                }
            }
        }
        function onRequestKeybindsOpen() {
            if (!root.barScreen || Quickshell.screens.length <= 1 || (root.barMonitor && Hyprland.focusedMonitor && root.barMonitor.id === Hyprland.focusedMonitor.id)) {
                root.activeTab = "keybinds";
                popup.open = true;
            }
        }
        function onRequestKeybindsClose() {
            if (root.activeTab === "keybinds") {
                popup.open = false;
            }
        }
    }

    PopupPanel {
        id: popup
        screen: root.barScreen
        wantsFocus: true
        keyboardFocusMode: WlrKeyboardFocus.OnDemand
        cardWidth: Theme.popupWidth
        cardHeight: Theme.popupHeight

        content: ColumnLayout {
            anchors.fill: parent
            spacing: Theme.popupSpacing

            RowLayout {
                Layout.fillWidth: true
                spacing: Math.max(8, Theme.popupSpacing)

                Rectangle {
                    width: 42
                    height: 42
                    radius: Theme.radiusMd
                    color: popup.open ? Theme.primary_container : Theme.surface_container_high

                    Text {
                        anchors.centerIn: parent
                        text: Theme.iconSettings
                        font.family: Theme.fontIcon
                        font.pixelSize: Theme.fontSizeLg
                        color: Theme.on_primary_container
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1

                    Text {
                        text: "settings & customization"
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeTitle
                        font.weight: Theme.fontWeightBold
                        color: Theme.on_surface
                    }

                    Text {
                        text: root.activeTabTitle + "  •  " + root.activeTabSubtitle
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeXs
                        color: Theme.on_surface_variant
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }

                Rectangle {
                    height: 26
                    implicitWidth: saveBadgeRow.implicitWidth + 16
                    radius: Theme.radiusPill
                    color: Theme.primary_container
                    border.color: Theme.alpha(Theme.outline_variant, 0.45)
                    border.width: 1

                    RowLayout {
                        id: saveBadgeRow
                        anchors.centerIn: parent
                        spacing: 4

                        Text {
                            text: Theme.iconCheck
                            font.family: Theme.fontIcon
                            font.pixelSize: 10
                            color: Theme.on_primary_container
                        }

                        Text {
                            text: "saved"
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                            font.weight: Theme.fontWeightDemiBold
                            color: Theme.on_primary_container
                        }
                    }
                }

                IconButton {
                    icon: Theme.iconClose
                    iconSize: Theme.fontSizeSm
                    tooltip: "close"
                    onClicked: popup.open = false
                }
            }

            // Beautifully Reorganized Tab Bar
            Flickable {
                id: tabFlick
                Layout.fillWidth: true
                height: 38
                contentWidth: tabRow.implicitWidth
                flickableDirection: Flickable.HorizontalFlick
                boundsBehavior: Flickable.StopAtBounds
                clip: true

                WheelHandler {
                    orientation: Qt.Vertical
                    onWheel: {
                        const delta = event.angleDelta.y !== 0 ? event.angleDelta.y : event.angleDelta.x;
                        const targetX = tabFlick.contentX - (delta * 0.8);
                        const maxX = Math.max(0, tabFlick.contentWidth - tabFlick.width);
                        tabFlick.contentX = Math.max(0, Math.min(maxX, targetX));
                        event.accepted = true;
                    }
                }

                RowLayout {
                    id: tabRow
                    spacing: Math.max(4, Theme.widgetSpacing)
                    anchors.verticalCenter: parent.verticalCenter

                    Repeater {
                        model: [
                            { id: "layout", label: "layout", icon: Theme.iconGrid },
                            { id: "style", label: "appearance", icon: Theme.iconSparkles },
                            { id: "behavior", label: "behavior", icon: Theme.iconFlame },
                            { id: "capture", label: "capture", icon: Theme.iconCamera },
                            { id: "keybinds", label: "keybinds", icon: Theme.iconKeyboard },
                            { id: "advanced", label: "system", icon: Theme.iconSliders }
                        ]

                        delegate: Rectangle {
                            required property var modelData
                            height: 32
                            width: tabItemRow.implicitWidth + 24
                            radius: Theme.radiusPill
                            readonly property bool isSelected: root.activeTab === modelData.id

                            color: isSelected
                            ? Theme.primary_container
                            : (tabMouse.containsMouse ? Theme.surface_container_highest : Theme.surface_container_low)
                            border.color: isSelected ? Theme.primary : Theme.outline_variant
                            border.width: 1

                            Behavior on color { ColorAnimation { duration: Theme.animFast; easing.type: Theme.animColorEasing } }

                            RowLayout {
                                id: tabItemRow
                                anchors.centerIn: parent
                                spacing: 6

                                Text {
                                    text: modelData.icon
                                    font.family: Theme.fontIcon
                                    font.pixelSize: Theme.fontSizeSm
                                    color: isSelected ? Theme.on_primary_container : Theme.on_surface_variant
                                }

                                Text {
                                    text: modelData.label
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSizeSm
                                    font.weight: isSelected ? Theme.fontWeightDemiBold : Theme.fontWeightMedium
                                    color: isSelected ? Theme.on_primary_container : Theme.on_surface_variant
                                }
                            }

                            MouseArea {
                                id: tabMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: { root.activeTab = modelData.id; }
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

            // Tab Contents
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                // 1. LAYOUT & MODULES TAB
                Flickable {
                    id: flickLayout
                    anchors.fill: parent
                    visible: root.activeTab === "layout"
                    clip: true
                    contentWidth: width
                    contentHeight: layoutCol.implicitHeight + 32
                    boundsBehavior: Flickable.StopAtBounds

                    function isModAssigned(modId) {
                        return (Settings && Settings.barModulesLeft ? Settings.barModulesLeft : []).includes(modId) ||
                        (Settings && Settings.barModulesCenter ? Settings.barModulesCenter : []).includes(modId) ||
                        (Settings && Settings.barModulesRight ? Settings.barModulesRight : []).includes(modId);
                    }

                    function toggleBarModule(modId, propName) {
                        if (!Settings) return;
                        let currentlyActive = Settings[propName] && isModAssigned(modId);
                        let nextVal = !currentlyActive;
                        Settings[propName] = nextVal;
                        if (nextVal) {
                            if (!isModAssigned(modId)) {
                                let right = (Settings.barModulesRight ? Settings.barModulesRight : []).slice();
                                right.push(modId);
                                Settings.barModulesRight = right;
                            }
                        }
                    }

                    ColumnLayout {
                        id: layoutCol
                        width: parent.width
                        spacing: Theme.popupSpacing

                        SettingCard {
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 10

                                Rectangle {
                                    width: 42
                                    height: 42
                                    radius: 12
                                    color: Theme.primary_container

                                    Text {
                                        anchors.centerIn: parent
                                        text: Theme.iconGrid
                                        font.family: Theme.fontIcon
                                        font.pixelSize: Theme.fontSizeMd
                                        color: Theme.primary
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2

                                    Text {
                                        text: (Settings.barPosition === "up" ? "top" : (Settings.barPosition === "down" ? "bottom" : Settings.barPosition)) + " bar"
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.fontSizeSm
                                        font.weight: Theme.fontWeightBold
                                        color: Theme.on_surface
                                    }

                                    Text {
                                        text: Settings.barHeight + "px  •  " + Settings.widgetSpacing + "px gap  •  " + Settings.widgetRadius + "px widgets"
                                        font.family: Theme.fontMono
                                        font.pixelSize: 9
                                        color: Theme.on_surface_variant
                                    }
                                }

                                Rectangle {
                                    height: 28
                                    implicitWidth: layoutStudioQuickText.implicitWidth + 18
                                    radius: Theme.radiusPill
                                    color: Theme.primary

                                    Text {
                                        id: layoutStudioQuickText
                                        anchors.centerIn: parent
                                        text: "open studio"
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 9
                                        font.weight: Theme.fontWeightBold
                                        color: Theme.on_primary
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: { Settings.showBarStudio = true; }
                                    }
                                }
                            }
                        }

                        CategoryHeader {
                            title: "bar"
                            subtitle: "position, size, spacing, and global geometry"
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
                            onSelected: { Settings.barPosition = value; }
                        }

                        SliderRow {
                            title: "bar thickness"
                            from: 24
                            to: 56
                            stepSize: 2
                            suffix: "px"
                            value: Settings.barHeight
                            onMoved: { Settings.barHeight = val; }
                        }

                        SliderRow {
                            title: "global corner rounding"
                            from: 0
                            to: 24
                            stepSize: 1
                            suffix: "px"
                            value: Settings.globalRounding
                            onMoved: {
                                Settings.globalRounding = val;
                                Settings.widgetRadius = Math.max(1, Math.round(val * 0.5));
                                Settings.popupRadius = Math.max(2, Math.round(val));
                            }
                        }

                        CategoryHeader {
                            title: "layout density"
                            subtitle: "spacing and radii that affect the whole shell"
                            icon: Theme.iconSliders
                        }

                        SliderRow {
                            title: "widget spacing"
                            from: 0
                            to: 16
                            stepSize: 1
                            suffix: "px"
                            value: Settings.widgetSpacing
                            onMoved: { Settings.widgetSpacing = val; }
                        }

                        SliderRow {
                            title: "widget padding"
                            from: 2
                            to: 18
                            stepSize: 1
                            suffix: "px"
                            value: Settings.widgetPaddingH
                            onMoved: { Settings.widgetPaddingH = val; }
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
                            onSelected: { Settings.widgetRadius = value; }
                        }

                        SliderRow {
                            title: "popup corner radius"
                            from: 0
                            to: 28
                            stepSize: 2
                            suffix: "px"
                            value: Settings.popupRadius
                            onMoved: { Settings.popupRadius = val; }
                        }

                        CategoryHeader {
                            title: "floating bar"
                            subtitle: "detach the bar from the screen edge and tune its breathing room"
                            icon: Theme.iconGrid
                        }

                        SettingCard {
                            ToggleRow {
                                icon: Theme.iconGrid
                                title: "floating bar"
                                subtitle: "detach status bar from screen edge"
                                checked: Settings.barFloating
                                onToggled: { Settings.barFloating = !Settings.barFloating; }
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
                                    anchors.margins: 8
                                    title: "floating bar corner radius"
                                    from: 0
                                    to: 24
                                    stepSize: 2
                                    suffix: "px"
                                    value: Settings.barRadius
                                    onMoved: function(v) { Settings.barRadius = v; }
                                }
                            }

                            RowDivider { visible: Settings.barFloating }

                            Item {
                                visible: Settings.barFloating
                                width: parent.width
                                implicitHeight: floatMarginRow.implicitHeight + 16

                                SliderRow {
                                    id: floatMarginRow
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.margins: 8
                                    title: "floating breathing room (margin)"
                                    from: 0
                                    to: 32
                                    stepSize: 2
                                    suffix: "px"
                                    value: Settings.barMargin
                                    onMoved: function(v) { Settings.barMargin = v; }
                                }
                            }

                            RowDivider { visible: Settings.barFloating }

                            ToggleRow {
                                visible: Settings.barFloating
                                icon: Theme.iconSparkles
                                title: "bento island hover lift"
                                subtitle: "elevate capsules slightly on hover"
                                checked: Settings.bentoHoverLift
                                onToggled: function() { Settings.bentoHoverLift = !Settings.bentoHoverLift; }
                            }
                        }

                        CategoryHeader {
                            title: "layout studio"
                            subtitle: "visually reorder modules and move them between bar zones"
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
                                    width: 44
                                    height: 44
                                    radius: Theme.radiusSm
                                    color: Settings.showBarStudio ? Theme.primary_overlay : Theme.surface_container_high

                                    Text {
                                        anchors.centerIn: parent
                                        text: "󰑮"
                                        font.family: Theme.fontIcon
                                        font.pixelSize: Theme.fontSizeLg
                                        color: Theme.primary
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2

                                    Text {
                                        text: "layout studio"
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.fontSizeSm
                                        font.weight: Theme.fontWeightBold
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
                                    height: 28
                                    implicitWidth: launchStudioText.implicitWidth + 24
                                    radius: Theme.radiusPill
                                    color: Settings.showBarStudio ? Theme.primary : Theme.primary_overlay

                                    Text {
                                        id: launchStudioText
                                        anchors.centerIn: parent
                                        text: Settings.showBarStudio ? "active ✓" : "open studio"
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 10
                                        font.weight: Theme.fontWeightBold
                                        color: Settings.showBarStudio ? Theme.on_primary : Theme.primary
                                    }
                                }
                            }

                            MouseArea {
                                id: studioBtnMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: { Settings.showBarStudio = !Settings.showBarStudio; }
                            }
                        }

                        CategoryHeader {
                            title: "navigation modules"
                            subtitle: "the things you keep within reach on the bar"
                            icon: Theme.iconWorkspaces
                        }

                        SettingCard {
                            ToggleRow {
                                icon: Theme.iconGrid
                                title: "application launcher"
                                checked: Settings.showLauncher && flickLayout.isModAssigned("launcher")
                                onToggled: { flickLayout.toggleBarModule("launcher", "showLauncher"); }
                            }
                            RowDivider {}
                            ToggleRow {
                                icon: Theme.iconWorkspaces
                                title: "workspaces switcher"
                                checked: Settings.showWorkspaces && flickLayout.isModAssigned("workspaces")
                                onToggled: { flickLayout.toggleBarModule("workspaces", "showWorkspaces"); }
                            }
                            RowDivider {}
                            ToggleRow {
                                icon: Theme.iconGrid ?? "⊞"
                                title: "tiling layout switcher"
                                checked: Settings.showLayoutSwitcher && flickLayout.isModAssigned("layout")
                                onToggled: { flickLayout.toggleBarModule("layout", "showLayoutSwitcher"); }
                            }
                            RowDivider {}
                            ToggleRow {
                                icon: Theme.iconNote
                                title: "window title"
                                checked: Settings.showWindowTitle && flickLayout.isModAssigned("windowTitle")
                                onToggled: { flickLayout.toggleBarModule("windowTitle", "showWindowTitle"); }
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
                                    anchors.margins: 8
                                    title: "window title stretch"
                                    model: [
                                        { label: "auto", value: "auto" },
                                        { label: "fill bar", value: "fill" },
                                        { label: "compact", value: "compact" }
                                    ]
                                    currentValue: Settings.windowTitleMode
                                    onSelected: { Settings.windowTitleMode = value; }
                                }
                            }
                            RowDivider {}
                            ToggleRow {
                                icon: Theme.iconTerminal
                                title: "app icon in window title"
                                checked: Settings.windowTitleShowIcon
                                onToggled: { Settings.windowTitleShowIcon = !Settings.windowTitleShowIcon; }
                            }
                        }

                        CategoryHeader {
                            title: "status & information"
                            icon: Theme.iconMusic
                        }

                        SettingCard {
                            ToggleRow {
                                icon: Theme.iconClock
                                title: "clock & date"
                                checked: Settings.showClock && flickLayout.isModAssigned("clock")
                                onToggled: { flickLayout.toggleBarModule("clock", "showClock"); }
                            }
                            RowDivider {}
                            ToggleRow {
                                icon: Theme.iconMusic
                                title: "now playing / mpris"
                                checked: Settings.showMedia && flickLayout.isModAssigned("media")
                                onToggled: { flickLayout.toggleBarModule("media", "showMedia"); }
                            }
                            RowDivider {}
                            ToggleRow {
                                icon: Theme.iconSparkles
                                title: "wallpaper & theme browser"
                                checked: Settings.showWallpaper && flickLayout.isModAssigned("wallpaper")
                                onToggled: { flickLayout.toggleBarModule("wallpaper", "showWallpaper"); }
                            }
                            RowDivider {}
                            ToggleRow {
                                icon: Theme.iconSliders
                                title: "volume & audio mixer"
                                checked: Settings.showVolume && flickLayout.isModAssigned("volume")
                                onToggled: { flickLayout.toggleBarModule("volume", "showVolume"); }
                            }
                        }

                        CategoryHeader {
                            title: "connectivity"
                            icon: Theme.iconWifi
                        }

                        SettingCard {
                            ToggleRow {
                                icon: Theme.iconWifi
                                title: "network / wi-fi"
                                checked: Settings.showNetwork && flickLayout.isModAssigned("network")
                                onToggled: { flickLayout.toggleBarModule("network", "showNetwork"); }
                            }
                            RowDivider {}
                            ToggleRow {
                                icon: Theme.iconWifi
                                title: "bluetooth devices"
                                checked: Settings.showBluetooth && flickLayout.isModAssigned("bluetooth")
                                onToggled: { flickLayout.toggleBarModule("bluetooth", "showBluetooth"); }
                            }
                            RowDivider {}
                            ToggleRow {
                                icon: Theme.iconFlame
                                title: "battery & power status"
                                checked: Settings.showBattery && flickLayout.isModAssigned("battery")
                                onToggled: { flickLayout.toggleBarModule("battery", "showBattery"); }
                            }
                            RowDivider {}
                            ToggleRow {
                                icon: Theme.iconGrid
                                title: "system tray icons"
                                checked: Settings.showSystemTray && flickLayout.isModAssigned("systemTray")
                                onToggled: { flickLayout.toggleBarModule("systemTray", "showSystemTray"); }
                            }
                        }

                        CategoryHeader {
                            title: "utilities"
                            icon: Theme.iconSliders
                        }

                        SettingCard {
                            ToggleRow {
                                icon: Theme.iconCoffee
                                title: "caffeine / idle inhibitor"
                                checked: Settings.showIdleInhibitor && flickLayout.isModAssigned("idleInhibitor")
                                onToggled: { flickLayout.toggleBarModule("idleInhibitor", "showIdleInhibitor"); }
                            }
                            RowDivider {}
                            ToggleRow {
                                icon: Theme.iconNote
                                title: "clipboard history"
                                checked: Settings.showClipboard && flickLayout.isModAssigned("clipboard")
                                onToggled: { flickLayout.toggleBarModule("clipboard", "showClipboard"); }
                            }
                            RowDivider {}
                            ToggleRow {
                                icon: Theme.iconNote
                                title: "quick notes & scratchpad"
                                checked: Settings.showQuickNotes && flickLayout.isModAssigned("quickNotes")
                                onToggled: { flickLayout.toggleBarModule("quickNotes", "showQuickNotes"); }
                            }
                            RowDivider {}
                            ToggleRow {
                                icon: Theme.iconCamera
                                title: "screen capture & recorder"
                                checked: Settings.showScreenCapture && flickLayout.isModAssigned("screenCapture")
                                onToggled: { flickLayout.toggleBarModule("screenCapture", "showScreenCapture"); }
                            }
                            RowDivider {}
                            ToggleRow {
                                icon: Theme.iconBell
                                title: "notification center module"
                                checked: Settings.showNotifications && flickLayout.isModAssigned("notifications")
                                onToggled: { flickLayout.toggleBarModule("notifications", "showNotifications"); }
                            }
                            RowDivider {}
                            ToggleRow {
                                icon: Theme.iconFlame
                                title: "power session menu"
                                checked: Settings.showPowerMenu && flickLayout.isModAssigned("powerMenu")
                                onToggled: { flickLayout.toggleBarModule("powerMenu", "showPowerMenu"); }
                            }
                        }
                    }
                }
                TabScrollTrack { target: flickLayout }

                // 2. STYLE & THEMES TAB
                Flickable {
                    id: flickStyle
                    anchors.fill: parent
                    visible: root.activeTab === "style"
                    clip: true
                    contentWidth: width
                    contentHeight: styleCol.implicitHeight + 32
                    boundsBehavior: Flickable.StopAtBounds

                    ColumnLayout {
                        id: styleCol
                        width: parent.width
                        spacing: Theme.popupSpacing

                        CategoryHeader {
                            title: "surface & material"
                            subtitle: "bar material, transparency, and visual density"
                            icon: Theme.iconSparkles
                        }

                        ChoiceGrid {
                            columns: 3
                            buttonHeight: 34
                            title: "bar material"
                            model: [
                                { label: "regular", value: "regular" },
                                { label: "frosted glass", value: "glass" },
                                { label: "glass frost", value: "glass-frost" },
                                { label: "pure black", value: "pure-black" },
                                { label: "cyber neon", value: "cyber-neon" },
                                { label: "bento", value: "bento-floating" },
                                { label: "translucent", value: "translucent" },
                                { label: "accent glow", value: "accent-glow" },
                                { label: "monochrome", value: "monochrome" }
                            ]
                            currentValue: Settings.barStyle
                            onSelected: function(val) { Settings.barStyle = val; }
                        }

                        SettingCard {
                            Item {
                                width: parent.width
                                implicitHeight: appearancePreviewCol.implicitHeight + 20

                                ColumnLayout {
                                    id: appearancePreviewCol
                                    anchors.fill: parent
                                    anchors.margins: 10
                                    spacing: 8

                                    RowLayout {
                                        Layout.fillWidth: true

                                        Text {
                                            text: "live style"
                                            font.family: Theme.fontFamily
                                            font.pixelSize: Theme.fontSizeXs
                                            font.weight: Theme.fontWeightBold
                                            color: Theme.on_surface
                                            Layout.fillWidth: true
                                        }

                                        Text {
                                            text: Settings.barStyle + "  •  " + Math.round(Settings.barOpacity * 100) + "% opacity"
                                            font.family: Theme.fontMono
                                            font.pixelSize: 9
                                            color: Theme.primary
                                        }
                                    }

                                    Rectangle {
                                        Layout.fillWidth: true
                                        height: 34
                                        radius: Math.min(Settings.widgetRadius, 16)
                                        color: Theme.alpha(Theme.surface_container_highest, Settings.barOpacity)
                                        border.color: Theme.alpha(Theme.primary, 0.28)
                                        border.width: 1

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: 10
                                            anchors.rightMargin: 10
                                            spacing: 8

                                            Text {
                                                text: Theme.iconGrid
                                                font.family: Theme.fontIcon
                                                font.pixelSize: Theme.fontSizeXs
                                                color: Theme.primary
                                            }
                                            Rectangle { width: 54; height: 8; radius: 4; color: Theme.primary_container }
                                            Rectangle { Layout.fillWidth: true; height: 8; radius: 4; color: Theme.outline_variant }
                                            Rectangle { width: 34; height: 18; radius: 9; color: Theme.primary_container }
                                            Text {
                                                text: Settings.barHeight + "px"
                                                font.family: Theme.fontMono
                                                font.pixelSize: 8
                                                color: Theme.on_surface_variant
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        SliderRow {
                            title: "bar background opacity"
                            from: 0.3
                            to: 1.0
                            stepSize: 0.05
                            value: Settings.barOpacity
                            formatter: function(v) { return Math.round(v * 100) + "%"; }
                            onMoved: { Settings.barOpacity = val; }
                        }

                        SliderRow {
                            title: "popup background opacity"
                            from: 0.5
                            to: 1.0
                            stepSize: 0.05
                            value: Settings.popupOpacity
                            formatter: function(v) { return Math.round(v * 100) + "%"; }
                            onMoved: { Settings.popupOpacity = val; }
                        }

                        CategoryHeader {
                            title: "color system"
                            icon: Theme.iconSparkles
                        }

                        SettingCard {
                            ToggleRow {
                                icon: Theme.iconSparkles
                                title: "use custom colors"
                                subtitle: "override system wallpaper colors with custom palette"
                                checked: Settings.customColorsEnabled
                                onToggled: {
                                    Settings.customColorsEnabled = !Settings.customColorsEnabled;
                                    Settings.save();
                                }
                            }

                            GridLayout {
                                id: colorGrid
                                visible: Settings.customColorsEnabled
                                width: parent.width
                                columns: 2
                                columnSpacing: 6
                                rowSpacing: 6
                                Layout.fillWidth: true
                                Layout.minimumWidth: 0

                                ColorTile {
                                    Layout.minimumWidth: 0
                                    Layout.fillWidth: true
                                    title: "background"
                                    subtitle: Settings.customBg !== "" ? Settings.customBg : "default"
                                    swatchColor: Settings.customBg !== "" ? Settings.customBg : Theme.background
                                    onClicked: colorStudioModal.open("customBg", "Background Color", "Main background surface color", Settings.customBg, Theme.background)
                                }

                                ColorTile {
                                    Layout.minimumWidth: 0
                                    Layout.fillWidth: true
                                    title: "accent"
                                    subtitle: Settings.customActive !== "" ? Settings.customActive : "default"
                                    swatchColor: Settings.customActive !== "" ? Settings.customActive : Theme.primary
                                    onClicked: colorStudioModal.open("customActive", "Active Accent Color", "Primary highlight color for active items", Settings.customActive, Theme.primary)
                                }

                                ColorTile {
                                    Layout.minimumWidth: 0
                                    Layout.fillWidth: true
                                    title: "text"
                                    subtitle: Settings.customText !== "" ? Settings.customText : "default"
                                    swatchColor: Settings.customText !== "" ? Settings.customText : Theme.on_surface
                                    onClicked: colorStudioModal.open("customText", "Text Color", "Primary typography & foreground glyphs", Settings.customText, Theme.on_surface)
                                }

                                ColorTile {
                                    Layout.minimumWidth: 0
                                    Layout.fillWidth: true
                                    title: "subtext"
                                    subtitle: Settings.customSubtext !== "" ? Settings.customSubtext : "default"
                                    swatchColor: Settings.customSubtext !== "" ? Settings.customSubtext : Theme.on_surface_variant
                                    onClicked: colorStudioModal.open("customSubtext", "Subtext Color", "Secondary text labels and inactive icons", Settings.customSubtext, Theme.on_surface_variant)
                                }

                                ColorTile {
                                    Layout.minimumWidth: 0
                                    Layout.fillWidth: true
                                    title: "border"
                                    subtitle: Settings.customBorder !== "" ? Settings.customBorder : "default"
                                    swatchColor: Settings.customBorder !== "" ? Settings.customBorder : Theme.outline
                                    onClicked: colorStudioModal.open("customBorder", "Border Color", "Outlines, dividers, and card borders", Settings.customBorder, Theme.outline)
                                }

                                ColorTile {
                                    Layout.minimumWidth: 0
                                    Layout.fillWidth: true
                                    title: "widget & pill"
                                    subtitle: Settings.customWidgetBg !== "" ? Settings.customWidgetBg : "default"
                                    swatchColor: Settings.customWidgetBg !== "" ? Settings.customWidgetBg : Theme.pillBg
                                    onClicked: colorStudioModal.open("customWidgetBg", "Widget & Pill Color", "Background color for bar pills & widgets", Settings.customWidgetBg, Theme.pillBg)
                                }
                            }
                        }

                        SettingCard {
                            ToggleRow {
                                icon: Theme.iconSparkles
                                title: "reactive dynamic notch"
                                subtitle: "interactive center island (clock, calendar & timer)"
                                checked: Settings.dynamicNotchEnabled
                                onToggled: function() { Settings.dynamicNotchEnabled = !Settings.dynamicNotchEnabled; }
                            }

                            RowDivider { visible: Settings.dynamicNotchEnabled }

                            ChoiceGrid {
                                visible: Settings.dynamicNotchEnabled
                                title: "dynamic notch carousel mode"
                                model: [
                                    { label: "adaptive auto", value: "auto" },
                                    { label: "clock only", value: "clock" },
                                    { label: "timer only", value: "timer" }
                                ]
                                currentValue: Settings.dynamicNotchMode
                                onSelected: function(val) { Settings.dynamicNotchMode = val; }
                            }
                        }

                        CategoryHeader {
                            title: "screen shape"
                            subtitle: "fillets, scoops, curvature, and frame treatment"
                            icon: Theme.iconGrid
                        }

                        Dropdown {
                            Layout.fillWidth: true
                            label: "screen corner fillets"
                            icon: Theme.iconSparkles
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
                            onSelected: { Settings.screenCornerMode = value; }
                        }

                        Dropdown {
                            Layout.fillWidth: true
                            label: "corner curvature style"
                            icon: Theme.iconSparkles
                            model: [
                                { label: "g2 continuous", value: "continuous-bezier" },
                                { label: "cubic", value: "cubic" },
                                { label: "squircle", value: "squircle" },
                                { label: "hyperbolic", value: "hyperbolic" },
                                { label: "chamfer 45°", value: "chamfer" },
                                { label: "flared", value: "flared" }
                            ]
                            currentValue: Settings.cornerStyle
                            onSelected: { Settings.cornerStyle = value; }
                        }

                        SettingCard {
                            ToggleRow {
                                icon: Theme.iconSparkles
                                title: "scoop border outlines"
                                subtitle: "draw continuous stroke along concave curves"
                                checked: Settings.scoopBorderEnabled
                                onToggled: { Settings.scoopBorderEnabled = !Settings.scoopBorderEnabled; }
                            }

                            RowDivider {}

                            ToggleRow {
                                icon: Theme.iconSparkles
                                title: "docked frame & scoops"
                                subtitle: "anchor shell fillets directly to screen bounds"
                                checked: Settings.screenFrameDocked
                                onToggled: { Settings.screenFrameDocked = !Settings.screenFrameDocked; }
                            }
                        }

                        SliderRow {
                            title: "scoop border width"
                            from: 1
                            to: 6
                            stepSize: 1
                            suffix: "px"
                            value: Settings.scoopBorderWidth
                            onMoved: { Settings.scoopBorderWidth = val; }
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
                            onSelected: { Settings.cornerColorMode = value; }
                        }

                        SliderRow {
                            title: "frame border width"
                            from: 0
                            to: 16
                            stepSize: 2
                            value: Settings.screenBorderWidth
                            formatter: function(v) { return v === 0 ? "none (corners only)" : (Math.round(v) + "px (full frame)"); }
                            onMoved: { Settings.screenBorderWidth = val; }
                        }

                        SliderRow {
                            title: "bar scoop radius"
                            from: 0
                            to: 32
                            stepSize: 2
                            suffix: "px"
                            value: Settings.scoopRadius
                            onMoved: { Settings.scoopRadius = val; }
                        }

                        SliderRow {
                            title: "screen corner radius"
                            from: 0
                            to: 40
                            stepSize: 2
                            suffix: "px"
                            value: Settings.screenCornerRadius
                            onMoved: { Settings.screenCornerRadius = val; }
                        }

                        Rectangle {
                            Layout.alignment: Qt.AlignRight
                            visible: Settings.scoopRadius !== Settings.screenCornerRadius
                            height: 22
                            implicitWidth: syncText.implicitWidth + 24
                            radius: Theme.radiusSm
                            color: syncMouse.containsMouse ? Theme.surface_container_high : Theme.surface_container_highest

                            Behavior on color { ColorAnimation { duration: Theme.animFast; easing.type: Theme.animColorEasing } }

                            Text {
                                id: syncText
                                anchors.centerIn: parent
                                text: "match scoops (" + Settings.scoopRadius + "px)"
                                font.family: Theme.fontFamily
                                font.pixelSize: 9
                                font.weight: Theme.fontWeightBold
                                color: Theme.primary
                            }

                            MouseArea {
                                id: syncMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                            }
                        }

                        SettingCard {
                            ToggleRow {
                                icon: Theme.iconSparkles
                                title: "dynamic notch concave flares"
                                subtitle: "melt center notch directly into screen bezel"
                                checked: Settings.dynamicNotchFlared
                                onToggled: { Settings.dynamicNotchFlared = !Settings.dynamicNotchFlared; }
                            }

                            RowDivider { visible: Settings.dynamicNotchFlared }

                            SliderRow {
                                visible: Settings.dynamicNotchFlared
                                title: "notch flare radius"
                                from: 8
                                to: 32
                                stepSize: 2
                                suffix: "px"
                                value: Settings.notchFlareRadius
                                onMoved: { Settings.notchFlareRadius = val; }
                            }
                        }

                        CategoryHeader {
                            title: "typography"
                            subtitle: "pick a font target, browse installed families, and preview them live"
                            icon: Theme.iconNote
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Rectangle {
                                Layout.fillWidth: true
                                height: 36
                                radius: Theme.radiusSm
                                color: root.fontTarget === "sans" ? Theme.primary : Theme.surface_container_highest

                                Text {
                                    text: "interface: " + Settings.fontFamily
                                    font.family: Settings.fontFamily
                                    font.pixelSize: Theme.fontSizeXs
                                    font.weight: Theme.fontWeightBold
                                    color: root.fontTarget === "sans" ? Theme.on_primary : Theme.on_surface
                                    anchors.centerIn: parent
                                    elide: Text.ElideRight
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: { root.fontTarget = "sans"; }
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                height: 36
                                radius: Theme.radiusSm
                                color: root.fontTarget === "mono" ? Theme.primary : Theme.surface_container_highest

                                Text {
                                    text: "monospace: " + Settings.fontMono
                                    font.family: Settings.fontMono
                                    font.pixelSize: Theme.fontSizeXs
                                    font.weight: Theme.fontWeightBold
                                    color: root.fontTarget === "mono" ? Theme.on_primary : Theme.on_surface
                                    anchors.centerIn: parent
                                    elide: Text.ElideRight
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: { root.fontTarget = "mono"; }
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            height: 40
                            color: Theme.cardBg
                            radius: Theme.widgetRadius
                            border.color: fontSearchInput.activeFocus ? Theme.primary : Theme.cardBorder
                            border.width: 1

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 12
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
                                        onTextChanged: { root.fontSearchQuery = text; }
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
                            border.color: Theme.outline_variant
                            border.width: 1
                            clip: true

                            WheelHandler {
                                target: fontListView
                                onWheel: {
                                    fontListView.flick(0, event.angleDelta.y * 6);
                                    event.accepted = true;
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
                                    height: 36
                                    radius: Theme.radiusSm
                                    readonly property bool isCurrent: (root.fontTarget === "sans" && Settings.fontFamily === modelData)
                                    || (root.fontTarget === "mono" && Settings.fontMono === modelData)
                                    color: isCurrent ? Theme.primary : (fItemMouse.containsMouse ? Theme.surface_container_highest : "transparent")

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.margins: 8
                                        spacing: 8

                                        Text {
                                            text: modelData.toLowerCase()
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

                            TabScrollTrack { target: fontListView }

                            Text {
                                anchors.centerIn: parent
                                visible: root.filteredFonts.length === 0
                                text: root.fontSearchQuery.trim() !== "" ? ("no fonts matching \"" + root.fontSearchQuery.trim() + "\"") : "no system fonts detected"
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeXs
                                color: Theme.on_surface_variant
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: prevCol.implicitHeight + 24
                            color: Theme.cardBg
                            radius: Theme.widgetRadius
                            border.color: Theme.outline_variant
                            border.width: 1

                            ColumnLayout {
                                id: prevCol
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 8

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text {
                                        text: "preview: " + (root.fontTarget === "sans" ? Settings.fontFamily : Settings.fontMono)
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.fontSizeXs
                                        font.weight: Theme.fontWeightBold
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
                            title: "type scale"
                            icon: Theme.iconSliders
                        }

                        SliderRow {
                            title: "interface font scaling"
                            from: 0.8
                            to: 1.4
                            stepSize: 0.05
                            value: Settings.fontScale
                            formatter: function(v) { return Math.round(v * 100) + "%"; }
                            onMoved: { Settings.fontScale = val; }
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
                            onSelected: function(val) { Settings.fontWeight = val; }
                        }

                        CategoryHeader {
                            title: "icon system"
                            subtitle: "choose one icon family; variants appear only for families that support them"
                            icon: Theme.iconSparkles
                        }

                        SettingCard {
                            ChoiceGrid {
                                columns: 2
                                buttonHeight: 34
                                title: "icon family"
                                model: [
                                    { label: "material", value: "material" },
                                    { label: "nerd fonts", value: "nerd" },
                                    { label: "windows segoe", value: "windows" },
                                    { label: "font awesome", value: "awesome" },
                                    { label: "(ﾉ◕ヮ◕)ﾉ kaomoji", value: "kaomoji" },
                                    { label: "plain text", value: "text" }
                                ]
                                currentValue: (root.usingMaterialIcons)
                                    ? "material"
                                    : Settings.iconSet
                                onSelected: {
                                    Settings.iconSet = value;
                                    if (value === "material") {
                                        if (Settings.fontMaterial !== "Material Symbols Rounded" &&
                                            Settings.fontMaterial !== "Material Symbols Outlined" &&
                                            Settings.fontMaterial !== "Material Symbols Sharp") {
                                            Settings.fontMaterial = "Material Symbols Rounded";
                                        }
                                    }
                                    Settings.vibeStyle = (value === "kaomoji" || value === "text") ? value : "nerd";
                                }
                            }

                            RowDivider { visible: root.usingMaterialIcons }

                            ChoiceRow {
                                visible: root.usingMaterialIcons
                                title: "material variant"
                                model: [
                                    { label: "rounded", value: "Material Symbols Rounded" },
                                    { label: "outlined", value: "Material Symbols Outlined" },
                                    { label: "sharp", value: "Material Symbols Sharp" }
                                ]
                                currentValue: Settings.fontMaterial || "Material Symbols Rounded"
                                onSelected: {
                                    Settings.iconSet = "material";
                                    Settings.fontMaterial = value;
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
                                onSelected: { Settings.fontNerd = value; }
                            }
                        }
                    }
                }
                TabScrollTrack { target: flickStyle }

                // 3. BEHAVIOR & MOTION TAB
                Flickable {
                    id: flickBehavior
                    anchors.fill: parent
                    visible: root.activeTab === "behavior"
                    clip: true
                    contentWidth: width
                    contentHeight: behaviorCol.implicitHeight + 32
                    boundsBehavior: Flickable.StopAtBounds

                    ColumnLayout {
                        id: behaviorCol
                        width: parent.width
                        spacing: Theme.popupSpacing

                        CategoryHeader {
                            title: "motion presets"
                            subtitle: "start with a personality preset before fine-tuning individual behavior"
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
                                        height: 52
                                        color: Settings.animSpeed === modelData.id
                                        ? Theme.primary_overlay
                                        : (aMouse.containsMouse ? Theme.surface_container_highest : "transparent")

                                        Behavior on color { ColorAnimation { duration: Theme.animFast; easing.type: Theme.animColorEasing } }

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: 12
                                            anchors.rightMargin: 12
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
                                                    font.weight: Theme.fontWeightBold
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
                                            onClicked: { Settings.animSpeed = modelData.id; }
                                        }
                                    }
                                }
                            }
                        }

                        CollapsibleSection {
                            Layout.fillWidth: true
                            title: "workspace motion"
                            subtitle: "motion physics & trail duration"
                            icon: Theme.iconWorkspaces
                            badge: Settings.workspaceMode

                            Dropdown {
                                width: parent.width
                                label: "motion style"
                                icon: Theme.iconWorkspaces
                                model: [
                                    { label: "smooth slide", value: "slide" },
                                    { label: "caelestia trail", value: "fluid-trail" },
                                    { label: "discrete pill", value: "discrete" }
                                ]
                                currentValue: Settings.workspaceMode
                                onSelected: { Settings.workspaceMode = value; }
                            }

                            SliderRow {
                                visible: Settings.workspaceMode === "fluid-trail"
                                title: "trail duration"
                                from: 120
                                to: 400
                                stepSize: 10
                                suffix: "ms"
                                value: Settings.workspaceTrailDuration
                                onMoved: { Settings.workspaceTrailDuration = val; }
                            }
                        }

                        CollapsibleSection {
                            Layout.fillWidth: true
                            title: "hover & interaction"
                            subtitle: "pill hover triggers & delay"
                            icon: Theme.iconEye
                            badge: Settings.hoverToOpen ? "enabled" : "click only"

                            SettingCard {
                                width: parent.width
                                ToggleRow {
                                    icon: Theme.iconEye
                                    title: "hover to open flyouts"
                                    subtitle: "hover over bar pills to open popups"
                                    checked: Settings.hoverToOpen
                                    onToggled: { Settings.hoverToOpen = !Settings.hoverToOpen; }
                                }

                                RowDivider {}

                                ToggleRow {
                                    icon: Theme.iconEyeOff
                                    title: "hover auto-close"
                                    subtitle: "dismiss popup when cursor leaves"
                                    checked: Settings.hoverAutoClose
                                    onToggled: { Settings.hoverAutoClose = !Settings.hoverAutoClose; }
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
                                onMoved: { Settings.hoverDelay = val; }
                            }
                        }

                        CategoryHeader {
                            title: "system feedback"
                            icon: Theme.iconSliders
                        }

                        CollapsibleSection {
                            Layout.fillWidth: true
                            title: "clock & date display"
                            subtitle: "formats & workspace capacity"
                            icon: Theme.iconClock
                            badge: Settings.showBarDate ? Settings.clockFormat : "time only"

                            Dropdown {
                                width: parent.width
                                label: "clock time format"
                                icon: Theme.iconClock
                                model: [
                                    { label: "24h (16:45)", value: "HH:mm" },
                                    { label: "12h (4:45 pm)", value: "h:mm ap" },
                                    { label: "24h + sec", value: "HH:mm:ss" },
                                    { label: "12h + sec", value: "h:mm:ss ap" }
                                ]
                                currentValue: Settings.clockFormat
                                onSelected: {
                                    Settings.clockFormat = value;
                                    let is12 = /ap/i.test(value);
                                    Settings.clockMilitary = !is12;
                                    Settings.clockShowSeconds = /:ss/i.test(value);
                                }
                            }

                            Dropdown {
                                width: parent.width
                                label: "date display format"
                                icon: Theme.iconCalendar
                                model: [
                                    { label: "hidden (time only)", value: "none" },
                                    { label: "short (mon, sep 1)", value: "ddd, MMM d" },
                                    { label: "standard (sep 1)", value: "MMM d, yyyy" },
                                    { label: "iso (2026-09-01)", value: "yyyy-MM-dd" }
                                ]
                                currentValue: !Settings.showBarDate ? "none" : Settings.dateFormat
                                onSelected: {
                                    if (value === "none") {
                                        Settings.showBarDate = false;
                                    } else {
                                        Settings.dateFormat = value;
                                        Settings.showBarDate = true;
                                    }
                                }
                            }

                            Dropdown {
                                width: parent.width
                                label: "workspace capacity"
                                icon: Theme.iconWorkspaces
                                model: [
                                    { label: "5 spaces", value: 5 },
                                    { label: "8 spaces", value: 8 },
                                    { label: "10 spaces", value: 10 },
                                    { label: "12 spaces", value: 12 },
                                    { label: "16 spaces", value: 16 }
                                ]
                                currentValue: Settings.workspaceCount
                                onSelected: { Settings.workspaceCount = value; }
                            }
                        }

                        CollapsibleSection {
                            Layout.fillWidth: true
                            title: "audio & volume limits"
                            subtitle: "scroll step & ceiling limit"
                            icon: Theme.iconVolHigh
                            badge: Settings.volumeMax + "%"

                            SliderRow {
                                title: "volume scroll step"
                                from: 1
                                to: 15
                                stepSize: 1
                                value: Settings.volumeStep
                                formatter: function(v) { return Math.round(v) + "%"; }
                                onMoved: { Settings.volumeStep = val; }
                            }

                            SliderRow {
                                title: "max volume ceiling"
                                from: 100
                                to: 200
                                stepSize: 5
                                value: Settings.volumeMax
                                formatter: function(v) { return Math.round(v) + "%"; }
                                onMoved: { Settings.volumeMax = val; }
                            }
                        }

                        CollapsibleSection {
                            Layout.fillWidth: true
                            title: "notifications & alerts"
                            subtitle: "auto-dismiss & do not disturb"
                            icon: Theme.iconBell
                            badge: Settings.dnd ? "dnd on" : (Settings.notificationTimeout === 0 ? "sticky" : (Settings.notificationTimeout / 1000 + "s"))

                            Dropdown {
                                width: parent.width
                                label: "toast auto-dismiss duration"
                                icon: Theme.iconBell
                                model: [
                                    { label: "3s (fast)", value: 3000 },
                                    { label: "5s (normal)", value: 5000 },
                                    { label: "8s (slow)", value: 8000 },
                                    { label: "12s (long)", value: 12000 },
                                    { label: "sticky (manual)", value: 0 }
                                ]
                                currentValue: Settings.notificationTimeout
                                onSelected: { Settings.notificationTimeout = value; }
                            }

                            SettingCard {
                                width: parent.width
                                ToggleRow {
                                    icon: Theme.iconBell
                                    title: "do not disturb"
                                    subtitle: "suppress on-screen notification popups"
                                    checked: Settings.dnd
                                    onToggled: { Settings.dnd = !Settings.dnd; }
                                }
                            }
                        }

                        CategoryHeader {
                            title: "personality"
                            icon: Theme.iconSparkles
                        }

                        SettingCard {
                            ToggleRow {
                                icon: Theme.iconFlame
                                title: "unhinged flavor text"
                                subtitle: "chaotic system status quips & personality"
                                checked: Settings.unhingedFlavor
                                onToggled: { Settings.unhingedFlavor = !Settings.unhingedFlavor; }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            height: 64
                            radius: Theme.radiusMd
                            color: Settings.showMotionSandbox ? Theme.primary_overlay : Theme.surface_container_highest
                            border.color: Settings.showMotionSandbox ? Theme.primary : Theme.widgetBorder
                            border.width: 1

                            Behavior on color { ColorAnimation { duration: Theme.animFast; easing.type: Theme.animColorEasing } }
                            Behavior on border.color { ColorAnimation { duration: Theme.animFast; easing.type: Theme.animColorEasing } }

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 12

                                Rectangle {
                                    width: 44
                                    height: 44
                                    radius: Theme.radiusSm
                                    color: Settings.showMotionSandbox ? Theme.primary_overlay : Theme.surface_container_high

                                    Text {
                                        anchors.centerIn: parent
                                        text: Theme.iconFlame
                                        font.family: Theme.fontIcon
                                        font.pixelSize: Theme.fontSizeLg
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
                                        font.weight: Theme.fontWeightBold
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
                                    height: 28
                                    implicitWidth: launchSandboxText.implicitWidth + 24
                                    radius: Theme.radiusPill
                                    color: Settings.showMotionSandbox ? Theme.primary : Theme.primary_overlay

                                    Text {
                                        id: launchSandboxText
                                        anchors.centerIn: parent
                                        text: Settings.showMotionSandbox ? "active ✓" : "launch"
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 10
                                        font.weight: Theme.fontWeightBold
                                        color: Settings.showMotionSandbox ? Theme.on_primary : Theme.primary
                                    }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: { Settings.showMotionSandbox = !Settings.showMotionSandbox; }
                            }
                        }
                    }
                }
                TabScrollTrack { target: flickBehavior }

                // 4. CAPTURE & MEDIA TAB
                Flickable {
                    id: flickScreenshot
                    anchors.fill: parent
                    visible: root.activeTab === "capture"
                    clip: true
                    contentWidth: width
                    contentHeight: screenshotCol.implicitHeight + 32
                    boundsBehavior: Flickable.StopAtBounds

                    ColumnLayout {
                        id: screenshotCol
                        width: parent.width
                        spacing: Theme.popupSpacing

                        CategoryHeader {
                            title: "capture"
                            subtitle: "instant actions first; behavior and visuals live underneath"
                            icon: Theme.iconCamera
                        }

                        SettingCard {
                            Item {
                                width: parent.width
                                implicitHeight: 56

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 8
                                    spacing: 8

                                    Rectangle {
                                        Layout.fillWidth: true
                                        height: 40
                                        radius: Theme.widgetRadius
                                        color: regMouse.pressed ? Theme.primary : (regMouse.containsMouse ? Theme.primary_overlay : Theme.surface_container_highest)
                                        border.color: Theme.outline_variant || Theme.primary
                                        border.width: 1

                                        Behavior on color { ColorAnimation { duration: Theme.animFast; easing.type: Theme.animColorEasing } }

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
                                                text: "capture region"
                                                font.family: Theme.fontFamily
                                                font.pixelSize: Theme.fontSizeSm
                                                font.weight: Theme.fontWeightMedium
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
                                        height: 40
                                        radius: Theme.widgetRadius
                                        color: winMouse.pressed ? Theme.primary : (winMouse.containsMouse ? Theme.primary_overlay : Theme.surface_container_highest)
                                        border.color: Theme.outline_variant || Theme.primary
                                        border.width: 1

                                        Behavior on color { ColorAnimation { duration: Theme.animFast; easing.type: Theme.animColorEasing } }

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
                                                text: "capture window"
                                                font.family: Theme.fontFamily
                                                font.pixelSize: Theme.fontSizeSm
                                                font.weight: Theme.fontWeightMedium
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
                                        height: 40
                                        radius: Theme.widgetRadius
                                        color: fullMouse.pressed ? Theme.primary : (fullMouse.containsMouse ? Theme.primary_overlay : Theme.surface_container_highest)
                                        border.color: Theme.outline_variant || Theme.primary
                                        border.width: 1

                                        Behavior on color { ColorAnimation { duration: Theme.animFast; easing.type: Theme.animColorEasing } }

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
                                                font.weight: Theme.fontWeightMedium
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
                            title: "recording"
                            subtitle: "gpu-screen-recorder controls and audio sources"
                            icon: Theme.iconCamera
                        }

                        SettingCard {
                            Item {
                                width: parent.width
                                implicitHeight: ScreenRecService.isRecording ? 58 : 56

                                RowLayout {
                                    visible: ScreenRecService.isRecording
                                    anchors.fill: parent
                                    anchors.margins: 8
                                    spacing: 8

                                    Rectangle {
                                        width: 10
                                        height: 10
                                        radius: 5
                                        color: Theme.error
                                    }

                                    Text {
                                        text: "recording (" + ScreenRecService.elapsedTimeString + ")"
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.fontSizeSm
                                        font.weight: Theme.fontWeightBold
                                        color: Theme.error
                                        Layout.fillWidth: true
                                    }

                                    Rectangle {
                                        height: 36
                                        implicitWidth: stopBtnTxt.implicitWidth + 24
                                        radius: Theme.radiusSm
                                        color: Theme.error

                                        Text {
                                            id: stopBtnTxt
                                            anchors.centerIn: parent
                                            text: "stop & save"
                                            font.family: Theme.fontFamily
                                            font.pixelSize: Theme.fontSizeXs
                                            font.weight: Theme.fontWeightBold
                                            color: Theme.on_error
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: { ScreenRecService.stopRecording(); }
                                        }
                                    }

                                    Rectangle {
                                        height: 36
                                        implicitWidth: discBtnTxt.implicitWidth + 20
                                        radius: Theme.radiusSm
                                        color: "transparent"
                                        border.color: Theme.error
                                        border.width: 1

                                        Text {
                                            id: discBtnTxt
                                            anchors.centerIn: parent
                                            text: "discard"
                                            font.family: Theme.fontFamily
                                            font.pixelSize: Theme.fontSizeXs
                                            font.weight: Theme.fontWeightBold
                                            color: Theme.error
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: { ScreenRecService.discardRecording(); }
                                        }
                                    }
                                }

                                RowLayout {
                                    visible: !ScreenRecService.isRecording
                                    anchors.fill: parent
                                    anchors.margins: 8
                                    spacing: 8

                                    Rectangle {
                                        Layout.fillWidth: true
                                        height: 40
                                        radius: Theme.widgetRadius
                                        color: recRegM.pressed ? Theme.primary : (recRegM.containsMouse ? Theme.primary_overlay : Theme.surface_container_highest)
                                        border.color: Theme.outline_variant || Theme.primary
                                        border.width: 1

                                        Behavior on color { ColorAnimation { duration: Theme.animFast; easing.type: Theme.animColorEasing } }

                                        RowLayout {
                                            anchors.centerIn: parent
                                            spacing: 6
                                            Text {
                                                text: Theme.iconCrop
                                                font.family: Theme.fontIcon
                                                font.pixelSize: Theme.fontSizeSm
                                                color: recRegM.pressed ? Theme.on_primary : Theme.primary
                                            }
                                            Text {
                                                text: "region"
                                                font.family: Theme.fontFamily
                                                font.pixelSize: Theme.fontSizeSm
                                                font.weight: Theme.fontWeightMedium
                                                color: recRegM.pressed ? Theme.on_primary : Theme.on_surface
                                            }
                                        }

                                        MouseArea {
                                            id: recRegM
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                popup.open = false;
                                                ScreenRecService.startRecording("region");
                                            }
                                        }
                                    }

                                    Rectangle {
                                        Layout.fillWidth: true
                                        height: 40
                                        radius: Theme.widgetRadius
                                        color: recScrM.pressed ? Theme.primary : (recScrM.containsMouse ? Theme.primary_overlay : Theme.surface_container_highest)
                                        border.color: Theme.outline_variant || Theme.primary
                                        border.width: 1

                                        Behavior on color { ColorAnimation { duration: Theme.animFast; easing.type: Theme.animColorEasing } }

                                        RowLayout {
                                            anchors.centerIn: parent
                                            spacing: 6
                                            Text {
                                                text: Theme.iconExpand
                                                font.family: Theme.fontIcon
                                                font.pixelSize: Theme.fontSizeSm
                                                color: recScrM.pressed ? Theme.on_primary : Theme.primary
                                            }
                                            Text {
                                                text: "screen"
                                                font.family: Theme.fontFamily
                                                font.pixelSize: Theme.fontSizeSm
                                                font.weight: Theme.fontWeightMedium
                                                color: recScrM.pressed ? Theme.on_primary : Theme.on_surface
                                            }
                                        }

                                        MouseArea {
                                            id: recScrM
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                popup.open = false;
                                                ScreenRecService.startRecording("screen");
                                            }
                                        }
                                    }

                                    Rectangle {
                                        Layout.fillWidth: true
                                        height: 40
                                        radius: Theme.widgetRadius
                                        color: recWinM.pressed ? Theme.primary : (recWinM.containsMouse ? Theme.primary_overlay : Theme.surface_container_highest)
                                        border.color: Theme.outline_variant || Theme.primary
                                        border.width: 1

                                        Behavior on color { ColorAnimation { duration: Theme.animFast; easing.type: Theme.animColorEasing } }

                                        RowLayout {
                                            anchors.centerIn: parent
                                            spacing: 6
                                            Text {
                                                text: Theme.iconWorkspaces
                                                font.family: Theme.fontIcon
                                                font.pixelSize: Theme.fontSizeSm
                                                color: recWinM.pressed ? Theme.on_primary : Theme.primary
                                            }
                                            Text {
                                                text: "window"
                                                font.family: Theme.fontFamily
                                                font.pixelSize: Theme.fontSizeSm
                                                font.weight: Theme.fontWeightMedium
                                                color: recWinM.pressed ? Theme.on_primary : Theme.on_surface
                                            }
                                        }

                                        MouseArea {
                                            id: recWinM
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                popup.open = false;
                                                ScreenRecService.startRecording("window");
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        ChoiceRow {
                            title: "recording audio input sources"
                            model: [
                                { label: "desktop + mic", value: "both" },
                                { label: "desktop only", value: "desktop" },
                                { label: "mic only", value: "mic" },
                                { label: "muted", value: "none" }
                            ]
                            currentValue: ScreenRecService.activeAudio
                            onSelected: { ScreenRecService.activeAudio = value; }
                        }

                        CategoryHeader {
                            title: "after capture"
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
                            onSelected: { Settings.screenshotDefaultAction = value; }
                        }

                        SettingCard {
                            ToggleRow {
                                icon: Theme.iconWorkspaces
                                title: "window snapping"
                                subtitle: "hover over any hyprland client to auto-detect its geometry"
                                checked: Settings.screenshotWindowSnapping
                                onToggled: { Settings.screenshotWindowSnapping = !Settings.screenshotWindowSnapping; }
                            }

                            RowDivider {}

                            ToggleRow {
                                icon: Theme.iconEye
                                title: "freeze frame on open"
                                subtitle: "freeze display during selection so animated windows don't move"
                                checked: Settings.screenshotFreeze
                                onToggled: { Settings.screenshotFreeze = !Settings.screenshotFreeze; }
                            }

                            RowDivider {}

                            ToggleRow {
                                icon: Theme.iconFlame
                                title: "shutter flash"
                                subtitle: "visual flash animation when capture is completed"
                                checked: Settings.screenshotFlash
                                onToggled: { Settings.screenshotFlash = !Settings.screenshotFlash; }
                            }

                            RowDivider {}

                            ToggleRow {
                                icon: Theme.iconBell
                                title: "desktop notification"
                                subtitle: "dispatch notification with image thumbnail on capture"
                                checked: Settings.screenshotNotify
                                onToggled: { Settings.screenshotNotify = !Settings.screenshotNotify; }
                            }
                        }

                        CategoryHeader {
                            title: "selection overlay"
                            subtitle: "everything the capture selector draws while you aim"
                            icon: Theme.iconSliders
                        }

                        SliderRow {
                            title: "backdrop dimming opacity"
                            from: 0.1
                            to: 0.9
                            stepSize: 0.05
                            value: Settings.screenshotDimOpacity
                            formatter: function(v) { return Math.round(v * 100) + "%"; }
                            onMoved: { Settings.screenshotDimOpacity = val; }
                        }

                        SliderRow {
                            title: "selection border width"
                            from: 1
                            to: 6
                            stepSize: 1
                            suffix: "px"
                            value: Settings.screenshotBorderWidth
                            onMoved: { Settings.screenshotBorderWidth = val; }
                        }

                        SliderRow {
                            title: "selection corner radius"
                            from: 0
                            to: 20
                            stepSize: 2
                            suffix: "px"
                            value: Settings.screenshotBorderRadius
                            onMoved: { Settings.screenshotBorderRadius = val; }
                        }

                        SettingCard {
                            ToggleRow {
                                icon: Theme.iconGrid
                                title: "hairline crosshairs"
                                subtitle: "show screen-spanning crosshair lines tracking cursor"
                                checked: Settings.screenshotShowCrosshair
                                onToggled: { Settings.screenshotShowCrosshair = !Settings.screenshotShowCrosshair; }
                            }

                            RowDivider {}

                            ToggleRow {
                                icon: Theme.iconNote
                                title: "live dimension badge"
                                subtitle: "show [w x h] badge and client name above selection"
                                checked: Settings.screenshotShowBadge
                                onToggled: { Settings.screenshotShowBadge = !Settings.screenshotShowBadge; }
                            }

                            RowDivider {}

                            ToggleRow {
                                icon: Theme.iconExpand
                                title: "corner accent handles"
                                subtitle: "render accent markers on selection corners"
                                checked: Settings.screenshotShowHandles
                                onToggled: { Settings.screenshotShowHandles = !Settings.screenshotShowHandles; }
                            }
                        }

                        CategoryHeader {
                            title: "storage"
                            icon: Theme.iconFolder
                        }

                        SettingCard {
                            Rectangle {
                                width: parent.width
                                implicitHeight: 48
                                height: implicitHeight
                                color: "transparent"

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 12
                                    anchors.rightMargin: 8
                                    spacing: 8

                                    Text {
                                        text: Theme.iconFolder
                                        font.family: Theme.fontIcon
                                        font.pixelSize: Theme.fontSizeSm
                                        color: Theme.primary
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 2

                                        Text {
                                            text: "screenshots & recordings"
                                            font.family: Theme.fontFamily
                                            font.pixelSize: Theme.fontSizeSm
                                            font.weight: Theme.fontWeightBold
                                            color: Theme.on_surface
                                        }

                                        Text {
                                            text: Settings.screenshotDir
                                            font.family: Theme.fontMono
                                            font.pixelSize: 10
                                            color: Theme.on_surface_variant
                                            elide: Text.ElideMiddle
                                            Layout.fillWidth: true
                                        }
                                    }

                                    Rectangle {
                                        height: 28
                                        implicitWidth: openScTxt.implicitWidth + 24
                                        radius: Theme.radiusSm
                                        color: oScMouse.containsMouse ? Theme.surface_container_highest : Theme.surface_container
                                        border.color: Theme.outline_variant || Theme.primary
                                        border.width: 1

                                        Text {
                                            id: openScTxt
                                            anchors.centerIn: parent
                                            text: "open files"
                                            font.family: Theme.fontFamily
                                            font.pixelSize: 10
                                            font.weight: Theme.fontWeightBold
                                            color: Theme.primary
                                        }

                                        MouseArea {
                                            id: oScMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                popup.open = false;
                                                let dir = Settings.screenshotDir || (Quickshell.env("HOME") + "/Pictures/Screenshots");
                                                Quickshell.execDetached(["xdg-open", dir]);
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                TabScrollTrack { target: flickScreenshot }

                // 5. ADVANCED & SYSTEM TAB
                Flickable {
                    id: flickAdvanced
                    anchors.fill: parent
                    visible: root.activeTab === "advanced"
                    clip: true
                    contentWidth: width
                    contentHeight: advancedCol.implicitHeight + 32
                    boundsBehavior: Flickable.StopAtBounds

                    ColumnLayout {
                        id: advancedCol
                        width: parent.width
                        spacing: Theme.popupSpacing

                        CategoryHeader {
                            title: "shell"
                            icon: Theme.iconTerminal
                        }

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
                                        implicitHeight: 68
                                        color: root.activeShell === modelData.id
                                        ? Theme.primary_overlay
                                        : (shMouse.containsMouse ? Theme.surface_container_highest : "transparent")

                                        Behavior on color { ColorAnimation { duration: Theme.animFast; easing.type: Theme.animColorEasing } }

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.margins: 12
                                            spacing: 12

                                            Rectangle {
                                                width: 40
                                                height: 40
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
                                                        font.weight: Theme.fontWeightBold
                                                        color: Theme.on_surface
                                                    }
                                                    Rectangle {
                                                        visible: root.activeShell === modelData.id
                                                        height: 16
                                                        width: activeText.implicitWidth + 12
                                                        radius: 8
                                                        color: Theme.primary

                                                        Text {
                                                            id: activeText
                                                            anchors.centerIn: parent
                                                            text: "active"
                                                            font.family: Theme.fontFamily
                                                            font.pixelSize: 9
                                                            font.weight: Theme.fontWeightBold
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
                                                height: 30
                                                width: 72
                                                radius: Theme.radiusSm
                                                color: root.activeShell === modelData.id
                                                ? Theme.surface_container_high
                                                : (shBtnMouse.containsMouse ? Theme.primary : Theme.surface_container_highest)
                                                border.color: root.activeShell === modelData.id ? Theme.primary : "transparent"
                                                border.width: 1

                                                Behavior on color { ColorAnimation { duration: Theme.animFast; easing.type: Theme.animColorEasing } }

                                                Text {
                                                    anchors.centerIn: parent
                                                    text: root.activeShell === modelData.id ? "current" : "switch"
                                                    font.family: Theme.fontFamily
                                                    font.pixelSize: 10
                                                    font.weight: Theme.fontWeightBold
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
                            title: "process & cache"
                            subtitle: "restart, persistence, and shell state diagnostics"
                            icon: Theme.iconSliders
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Rectangle {
                                Layout.fillWidth: true
                                height: 44
                                radius: Theme.widgetRadius
                                color: rstMouse.containsMouse ? Theme.primary_overlay : Theme.surface_container_highest
                                border.color: rstMouse.containsMouse ? Theme.primary : Theme.widgetBorder
                                border.width: 1

                                Behavior on color { ColorAnimation { duration: Theme.animFast; easing.type: Theme.animColorEasing } }
                                Behavior on border.color { ColorAnimation { duration: Theme.animFast; easing.type: Theme.animColorEasing } }

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
                                        text: switchProc.running ? "restarting shell..." : "restart active shell process"
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.fontSizeSm
                                        font.weight: Theme.fontWeightBold
                                        color: Theme.on_surface
                                    }
                                }

                                MouseArea {
                                    id: rstMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    enabled: !switchProc.running
                                    onClicked: { switchProc.restartCurrent(); }
                                }
                            }
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
                                            text: Theme.iconNote
                                            font.family: Theme.fontIcon
                                            font.pixelSize: Theme.fontSizeSm
                                            color: Theme.primary
                                        }
                                        Text {
                                            text: "state cache:"
                                            font.family: Theme.fontFamily
                                            font.pixelSize: Theme.fontSizeXs
                                            font.weight: Theme.fontWeightBold
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

                        CategoryHeader {
                            title: "network aliases"
                            icon: Theme.iconWifi
                        }

                        readonly property var aliasKeys: Object.keys(Settings.networkAliases || {})

                        Rectangle {
                            Layout.fillWidth: true
                            height: 48
                            radius: Theme.widgetRadius
                            color: Theme.cardBg
                            border.color: Theme.outline_variant
                            border.width: 1
                            visible: advancedCol.aliasKeys.length === 0

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 12
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
                            visible: advancedCol.aliasKeys.length > 0

                            Repeater {
                                model: advancedCol.aliasKeys

                                delegate: Column {
                                    required property string modelData
                                    required property int index
                                    width: parent.width
                                    spacing: 0

                                    RowDivider { visible: index > 0 }

                                    Rectangle {
                                        width: parent.width
                                        height: 44
                                        color: "transparent"

                                        Text {
                                            id: alIcon
                                            anchors.left: parent.left
                                            anchors.leftMargin: 12
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: Theme.iconWifi
                                            font.family: Theme.fontIcon
                                            font.pixelSize: Theme.fontSizeXs
                                            color: Theme.primary
                                        }

                                        IconButton {
                                            id: alTrash
                                            anchors.right: parent.right
                                            anchors.rightMargin: 12
                                            anchors.verticalCenter: parent.verticalCenter
                                            icon: Theme.iconTrash
                                            iconSize: 12
                                            tooltip: "remove alias"
                                            onClicked: { Settings.setNetworkAlias(modelData, ""); }
                                        }

                                        RowLayout {
                                            anchors.left: alIcon.right
                                            anchors.leftMargin: 10
                                            anchors.right: alTrash.left
                                            anchors.rightMargin: 10
                                            anchors.verticalCenter: parent.verticalCenter
                                            spacing: 6

                                            Text {
                                                text: (Settings.networkAliases && Settings.networkAliases[modelData]) || ""
                                                font.family: Theme.fontFamily
                                                font.pixelSize: Theme.fontSizeSm
                                                font.weight: Theme.fontWeightBold
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
                            title: "onboarding & reset"
                            subtitle: "small setup tools and the irreversible stuff"
                            icon: Theme.iconSparkles
                        }

                        SettingCard {
                            RowLayout {
                                width: parent.width
                                spacing: 12

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 1

                                    Text {
                                        text: "desktop shell profiles tab"
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.fontSizeSm
                                        font.weight: Theme.fontWeightBold
                                        color: Theme.on_surface
                                    }

                                    Text {
                                        text: "display or hide the shell switcher tab in quicksettings"
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.fontSizeXs
                                        color: Theme.on_surface_variant
                                    }
                                }

                                ToggleSwitch {
                                    checked: Settings.showShellTab !== false
                                    onToggled: { Settings.showShellTab = !Settings.showShellTab; }
                                }
                            }

                            RowDivider {}

                            Rectangle {
                                width: parent.width
                                implicitHeight: 52
                                radius: Theme.radiusSm
                                color: rewelcomeMouse.containsMouse ? Theme.surface_container_highest : "transparent"

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 8
                                    spacing: 12

                                    Text {
                                        text: Theme.iconSparkles
                                        font.family: Theme.fontIcon
                                        font.pixelSize: Theme.fontSizeSm
                                        color: Theme.primary
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 2

                                        Text {
                                            text: "reopen welcome guide"
                                            font.family: Theme.fontFamily
                                            font.pixelSize: Theme.fontSizeSm
                                            font.weight: Theme.fontWeightBold
                                            color: Theme.on_surface
                                        }

                                        Text {
                                            text: "revisit the asylum onboarding & vibe calibration"
                                            font.family: Theme.fontFamily
                                            font.pixelSize: Theme.fontSizeXs
                                            color: Theme.on_surface_variant
                                        }
                                    }

                                    Rectangle {
                                        width: 64
                                        height: 28
                                        radius: Theme.radiusPill
                                        color: Theme.primary

                                        Text {
                                            anchors.centerIn: parent
                                            text: "launch"
                                            font.family: Theme.fontFamily
                                            font.pixelSize: Theme.fontSizeXs
                                            font.weight: Theme.fontWeightBold
                                            color: Theme.on_primary
                                        }
                                    }
                                }

                                MouseArea {
                                    id: rewelcomeMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        popup.open = false;
                                        Settings.requestWelcomeOpen();
                                    }
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            height: 58
                            radius: Theme.widgetRadius
                            color: nukeMouse.containsMouse ? Theme.error_overlay : Theme.surface_container_highest
                            border.color: nukeMouse.containsMouse ? (Theme.error) : Theme.widgetBorder
                            border.width: 1

                            Behavior on color { ColorAnimation { duration: Theme.animFast; easing.type: Theme.animColorEasing } }
                            Behavior on border.color { ColorAnimation { duration: Theme.animFast; easing.type: Theme.animColorEasing } }

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 12
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
                                        text: "reset all custom settings"
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.fontSizeSm
                                        font.weight: Theme.fontWeightBold
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
                                    height: 30
                                    radius: Theme.radiusSm
                                    color: Theme.error

                                    Text {
                                        text: "nuke"
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.fontSizeXs
                                        font.weight: Theme.fontWeightBold
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
                                onClicked: { root.showResetConfirm = true; }
                            }
                        }
                    }
                }
                TabScrollTrack { target: flickAdvanced }

                // 6. KEYBINDS TAB
                Item {
                    id: tabKeybinds
                    anchors.fill: parent
                    visible: root.activeTab === "keybinds"

                    KeybindsPreview {
                        anchors.fill: parent
                        anchors.margins: 8
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: Theme.iconCheck
                    font.family: Theme.fontIcon
                    font.pixelSize: 9
                    color: Theme.primary
                }

                Text {
                    text: "changes apply immediately"
                    font.family: Theme.fontFamily
                    font.pixelSize: 9
                    color: Theme.on_surface_variant
                    Layout.fillWidth: true
                }

                Text {
                    text: "esc  close"
                    font.family: Theme.fontMono
                    font.pixelSize: 8
                    color: Theme.on_surface_variant
                    opacity: 0.75
                }
            }
        }

        // DANGER MODAL
        Rectangle {
            id: resetConfirmModal
            anchors.fill: parent
            color: Theme.alpha(Theme.background, 0.94)
            visible: root.showResetConfirm
            z: 999
            radius: Theme.popupRadius
            focus: visible

            Keys.onEscapePressed: { root.showResetConfirm = false; }

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
                    color: Theme.error_container

                    Text {
                        anchors.centerIn: parent
                        text: Theme.iconFlame
                        font.family: Theme.fontIcon
                        font.pixelSize: Theme.fontSizeXl
                        color: Theme.error
                    }
                }

                Text {
                    text: "reset all custom settings?"
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeLg
                    font.weight: Theme.fontWeightBold
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
                        height: 40
                        radius: Theme.radiusSm
                        color: cancelMouse.containsMouse ? Theme.surface_container_high : Theme.surface_container_highest
                        border.color: Theme.outline_variant
                        border.width: 1

                        Text {
                            text: "nevermind"
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeSm
                            font.weight: Theme.fontWeightBold
                            color: Theme.on_surface
                            anchors.centerIn: parent
                        }

                        MouseArea {
                            id: cancelMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: { root.showResetConfirm = false; }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 40
                        radius: Theme.radiusSm
                        color: confirmMouse.containsMouse ? Theme.error_container : (Theme.error)

                        Text {
                            text: "reset everything"
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeSm
                            font.weight: Theme.fontWeightBold
                            color: confirmMouse.containsMouse ? Theme.on_error_container : (Theme.on_error)
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

        ColorStudioModal {
            id: colorStudioModal
        }
    }
}
