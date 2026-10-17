import QtQuick
import QtQuick.Layouts
import ".."
import "../controls"
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

    Behavior on color { ColorAnimation { duration: Theme.animFast; easing.type: Theme.animColorEasing } }
    Behavior on border.color { ColorAnimation { duration: Theme.animFast; easing.type: Theme.animColorEasing } }

    property var barScreen: null
    property var barMonitor: null
    property string activeTab: "layout"
    property string fontTarget: "sans"
    property string fontSearchQuery: ""
    property bool showResetConfirm: false
    property string activeShell: "quickshell"

    readonly property string userHome: Quickshell.env("HOME") || ""
    readonly property string cacheDir: Quickshell.env("XDG_CACHE_HOME") || (userHome + "/.cache")
    readonly property string configDir: Quickshell.env("XDG_CONFIG_HOME") || (userHome + "/.config")
    readonly property string lockSandboxPath: configDir + "/quickshell/lockscreen.json"

    // sandboxed lockscreen state (persisted independently in ~/.config/quickshell/lockscreen.json)
    property var lockCfg: ({
        syncClockGlobal: false,
        clock24h: false,
        showSeconds: false,
        clockScale: 1.0,
        quoteMode: "hyprland",
        scrimDim: 0.58,
        showMedia: true,
        showUser: true,
        wallpaperSync: true,
        customWallpaper: ""
    })

    FileView {
        id: lockSandboxFile
        path: root.lockSandboxPath
        watchChanges: true
        printErrors: false
        onFileChanged: {
            reload();
            root.loadLockSandbox();
        }
        onLoaded: root.loadLockSandbox()
    }

    function loadLockSandbox() {
        let raw = lockSandboxFile.text();
        if (!raw || raw.trim() === "") return;
        try {
            let parsed = JSON.parse(raw);
            root.lockCfg = Object.assign({}, root.lockCfg, parsed);
        } catch (e) {}
    }

    function updateLockCfg(key, val) {
        let next = Object.assign({}, root.lockCfg);
        next[key] = val;
        root.lockCfg = next;
        lockSandboxFile.setText(JSON.stringify(next, null, 2));

        // if global clock sync is enabled, mirror clock changes to the bar Settings singleton
        if (next.syncClockGlobal && (key === "clock24h" || key === "showSeconds" || key === "syncClockGlobal")) {
            root.applyGlobalClock(next.clock24h, next.showSeconds);
        }
    }

    function applyGlobalClock(is24h, withSec) {
        if (!Settings) return;
        let fmt = is24h ? (withSec ? "HH:mm:ss" : "HH:mm") : (withSec ? "h:mm:ss ap" : "h:mm ap");
        Settings.clockFormat = fmt;
        Settings.clock24h = is24h;
        Settings.clockMilitary = is24h;
        Settings.clockShowSeconds = withSec;
        if (Settings.save) Settings.save();
    }

    Component.onCompleted: loadLockSandbox()

    readonly property bool usingMaterialIcons: Settings.iconSet === "material"
        || Settings.iconSet === "material-outlined"
        || Settings.iconSet === "material-sharp"

    readonly property string activeTabTitle: ({
        layout: "layout",
        style: "appearance",
        behavior: "behavior",
        capture: "capture",
        keybinds: "keybinds",
        advanced: "system"
    })[root.activeTab] || "settings"

    readonly property string activeTabSubtitle: ({
        layout: "arrange the bar and choose what lives on it",
        style: "shape, color, typography, and visual personality",
        behavior: "motion, lock screen sandbox, clock, and feedback",
        capture: "screenshots, recording, and selection overlays",
        keybinds: "view and manage your shell shortcuts",
        advanced: "shell profiles, cache, aliases, and recovery tools"
    })[root.activeTab] || ""

    onActiveTabChanged: {
        if (root.activeTab === "layout" && flickLayout) flickLayout.contentY = 0;
        else if (root.activeTab === "style" && flickStyle) flickStyle.contentY = 0;
        else if (root.activeTab === "behavior" && flickBehavior) flickBehavior.contentY = 0;
        else if (root.activeTab === "capture" && flickScreenshot) flickScreenshot.contentY = 0;
        else if (root.activeTab === "advanced" && flickAdvanced) flickAdvanced.contentY = 0;
    }

    FileView {
        id: shellWatcher
        printErrors: false
        path: root.cacheDir + "/current_shell"
        watchChanges: true
        onFileChanged: reload()
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
            command = [root.userHome + "/.local/bin/qs-switch", target];
            running = true;
        }
        function restartCurrent() {
            switchShell("restart");
        }
        onExited: shellWatcher.reload()
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

    function isTargetMonitorActive() {
        return !root.barScreen
            || Quickshell.screens.length <= 1
            || (root.barMonitor && Hyprland.focusedMonitor && root.barMonitor.id === Hyprland.focusedMonitor.id);
    }

    function updatePopupPos() {
        const p = root.mapToItem(null, 0, 0);
        if (p) {
            popup.targetRelativeX = p.x + (root.width / 2);
            popup.targetRelativeY = p.y + (root.height / 2);
        }
    }

    // reusable setting components

    component CategoryHeader: ColumnLayout {
        id: catHdr
        property string title: ""
        property string icon: ""
        property string subtitle: ""

        Layout.fillWidth: true
        Layout.topMargin: 12
        Layout.bottomMargin: 2
        spacing: 4

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
            color: Theme.on_surface_variant
            wrapMode: Text.Wrap
        }
    }

    component SettingCard: Rectangle {
        default property alias content: cardCol.data
        Layout.fillWidth: true
        width: parent ? parent.width : undefined
        implicitHeight: cardCol.implicitHeight + (Theme.widgetPaddingV * 2) + 8
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
            anchors.leftMargin: Theme.widgetPaddingH
            anchors.rightMargin: Theme.widgetPaddingH
            anchors.topMargin: Theme.widgetPaddingV + 4
            spacing: 2
        }
    }

    component RowDivider: Rectangle {
        width: parent ? parent.width - 16 : 0
        anchors.horizontalCenter: parent ? parent.horizontalCenter : undefined
        height: 1
        color: Theme.outline_variant
        opacity: 0.38
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

    component ColorTile: Rectangle {
        id: colorTileRoot
        property string title: ""
        property string subtitle: ""
        property color swatchColor: Theme.primary
        signal clicked()

        width: parent ? parent.width : 0
        Layout.fillWidth: true
        height: 54
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
                width: 30
                height: 30
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
                    font.pixelSize: 9
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
        property int buttonHeight: 28
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
                            ? (modelData.value !== undefined ? modelData.value : modelData)
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
                width: 16
                height: 16
                radius: 8
                y: (track.height - height) / 2
                x: Math.max(0, Math.min(track.width - width, track.width * track.ratio - width / 2))
                color: Theme.primary
                border.color: Theme.surface_bright
                border.width: 2
                scale: dragArea.pressed ? 1.15 : 1.0
                Behavior on scale { NumberAnimation { duration: Theme.animFast; easing.type: Theme.animEasing } }
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
                    if (slRoot.stepSize > 0) raw = Math.round(raw / slRoot.stepSize) * slRoot.stepSize;
                    raw = Math.max(slRoot.from, Math.min(slRoot.to, raw));
                    if (Math.abs(raw - slRoot.value) > 1e-9) slRoot.moved(raw);
                }

                onPressed: commit(mouseX - 8)
                onPositionChanged: if (pressed) commit(mouseX - 8)
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
                    readonly property var itemVal: modelData && typeof modelData === "object"
                        ? (modelData.value !== undefined ? modelData.value : (modelData.id !== undefined ? modelData.id : modelData))
                        : modelData
                    readonly property string itemText: modelData && typeof modelData === "object" && modelData.label !== undefined
                        ? String(modelData.label)
                        : String(modelData || "")
                    readonly property bool isSelected: (typeof cgRoot.currentValue === "number" && typeof itemVal === "number" && !Number.isInteger(itemVal))
                        ? Math.abs(cgRoot.currentValue - itemVal) < 0.04
                        : cgRoot.currentValue === itemVal

                    width: Math.max(1, (choiceGrid.width - choiceGrid.columnSpacing * (choiceGrid.columns - 1)) / choiceGrid.columns)
                    height: cgRoot.buttonHeight
                    radius: Theme.radiusSm
                    color: isSelected
                        ? Theme.primary_container
                        : (cgMouse.containsMouse ? Theme.surface_container_highest : Theme.surface_container_low)
                    border.color: isSelected ? Theme.primary : Theme.outline_variant
                    border.width: 1

                    Behavior on color { ColorAnimation { duration: Theme.animFast; easing.type: Theme.animColorEasing } }

                    Text {
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

    // bar button content
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
            if (root.isTargetMonitorActive()) {
                root.updatePopupPos();
                popup.open = !popup.open;
            }
        }
        function onRequestQuickSettingsOpen() {
            if (root.isTargetMonitorActive()) {
                root.updatePopupPos();
                popup.open = true;
            }
        }
        function onRequestQuickSettingsClose() {
            popup.open = false;
        }
        function onRequestKeybindsToggle() {
            if (root.isTargetMonitorActive()) {
                root.updatePopupPos();
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
            if (root.isTargetMonitorActive()) {
                root.updatePopupPos();
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

            // top header
            RowLayout {
                Layout.fillWidth: true
                spacing: Math.max(8, Theme.popupSpacing)

                Rectangle {
                    width: 40
                    height: 40
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
                    height: 24
                    implicitWidth: saveBadgeRow.implicitWidth + 14
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
                            text: "live"
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

            // horizontal tab bar
            Flickable {
                id: tabFlick
                Layout.fillWidth: true
                height: 36
                contentWidth: tabRow.implicitWidth
                flickableDirection: Flickable.HorizontalFlick
                boundsBehavior: Flickable.StopAtBounds
                clip: true

                WheelHandler {
                    orientation: Qt.Vertical
                    onWheel: (event) => {
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
                            height: 30
                            width: tabItemRow.implicitWidth + 22
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

            // tab views
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                // 1. layout & modules tab
                Flickable {
                    id: flickLayout
                    anchors.fill: parent
                    visible: root.activeTab === "layout"
                    clip: true
                    contentWidth: width
                    contentHeight: layoutCol.implicitHeight + 28
                    boundsBehavior: Flickable.StopAtBounds

                    WheelHandler {
                        orientation: Qt.Vertical
                        target: parent
                    }

                    function isModAssigned(modId) {
                        return (Settings?.barModulesLeft || []).includes(modId)
                            || (Settings?.barModulesCenter || []).includes(modId)
                            || (Settings?.barModulesRight || []).includes(modId);
                    }

                    function toggleBarModule(modId, propName) {
                        if (!Settings) return;
                        let currentlyActive = Boolean(Settings[propName]) && isModAssigned(modId);
                        let nextVal = !currentlyActive;
                        Settings[propName] = nextVal;
                        if (nextVal && !isModAssigned(modId)) {
                            let right = (Settings.barModulesRight || []).slice();
                            right.push(modId);
                            Settings.barModulesRight = right;
                        }
                        if (Settings.save) Settings.save();
                    }

                    ColumnLayout {
                        id: layoutCol
                        width: parent.width
                        spacing: Theme.popupSpacing

                        // single unified bar summary & layout studio trigger card
                        SettingCard {
                            RowLayout {
                                width: parent.width
                                spacing: 10

                                Rectangle {
                                    width: 40
                                    height: 40
                                    radius: Theme.radiusSm
                                    color: Settings.showBarStudio ? Theme.primary : Theme.primary_container

                                    Text {
                                        anchors.centerIn: parent
                                        text: Theme.iconSliders
                                        font.family: Theme.fontIcon
                                        font.pixelSize: Theme.fontSizeMd
                                        color: Settings.showBarStudio ? Theme.on_primary : Theme.on_primary_container
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2

                                    Text {
                                        text: (Settings.barPosition === "up" ? "top" : (Settings.barPosition === "down" ? "bottom" : Settings.barPosition)) + " bar • layout studio"
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.fontSizeSm
                                        font.weight: Theme.fontWeightBold
                                        color: Theme.on_surface
                                    }

                                    Text {
                                        text: Settings.showBarStudio
                                            ? "studio active on screen edge"
                                            : (Settings.barHeight + "px  •  " + Settings.widgetSpacing + "px gap  •  drag & reorder modules")
                                        font.family: Theme.fontMono
                                        font.pixelSize: 9
                                        color: Settings.showBarStudio ? Theme.primary : Theme.on_surface_variant
                                    }
                                }

                                Rectangle {
                                    height: 28
                                    implicitWidth: studioQuickTxt.implicitWidth + 20
                                    radius: Theme.radiusPill
                                    color: Settings.showBarStudio ? Theme.primary_overlay : Theme.primary
                                    border.color: Settings.showBarStudio ? Theme.primary : "transparent"
                                    border.width: 1

                                    Text {
                                        id: studioQuickTxt
                                        anchors.centerIn: parent
                                        text: Settings.showBarStudio ? "close studio" : "open studio"
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 10
                                        font.weight: Theme.fontWeightBold
                                        color: Settings.showBarStudio ? Theme.primary : Theme.on_primary
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: Settings.showBarStudio = !Settings.showBarStudio
                                    }
                                }
                            }
                        }

                        CategoryHeader {
                            title: "bar geometry"
                            subtitle: "position, thickness, rounding, and spacing"
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
                            onSelected: (val) => Settings.barPosition = val
                        }

                        SliderRow {
                            title: "bar thickness"
                            from: 24
                            to: 56
                            stepSize: 2
                            suffix: "px"
                            value: Settings.barHeight
                            onMoved: (val) => Settings.barHeight = val
                        }

                        SliderRow {
                            title: "global corner rounding"
                            from: 0
                            to: 24
                            stepSize: 1
                            suffix: "px"
                            value: Settings.globalRounding
                            onMoved: (val) => {
                                Settings.globalRounding = val;
                                Settings.widgetRadius = Math.max(1, Math.round(val * 0.5));
                                Settings.popupRadius = Math.max(2, Math.round(val));
                            }
                        }

                        SliderRow {
                            title: "widget spacing"
                            from: 0
                            to: 16
                            stepSize: 1
                            suffix: "px"
                            value: Settings.widgetSpacing
                            onMoved: (val) => Settings.widgetSpacing = val
                        }

                        SliderRow {
                            title: "widget horizontal padding"
                            from: 2
                            to: 18
                            stepSize: 1
                            suffix: "px"
                            value: Settings.widgetPaddingH
                            onMoved: (val) => Settings.widgetPaddingH = val
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
                            onSelected: (val) => Settings.widgetRadius = val
                        }

                        SliderRow {
                            title: "popup corner radius"
                            from: 0
                            to: 28
                            stepSize: 2
                            suffix: "px"
                            value: Settings.popupRadius
                            onMoved: (val) => Settings.popupRadius = val
                        }

                        CategoryHeader {
                            title: "floating bar"
                            subtitle: "detach the bar from the screen edge"
                            icon: Theme.iconExpand
                        }

                        SettingCard {
                            ToggleRow {
                                icon: Theme.iconExpand
                                title: "floating bar"
                                subtitle: "detach status bar from screen edge"
                                checked: Settings.barFloating
                                onToggled: Settings.barFloating = !Settings.barFloating
                            }

                            RowDivider { visible: Settings.barFloating }

                            Item {
                                visible: Settings.barFloating
                                width: parent.width
                                implicitHeight: floatRadiusRow.implicitHeight + 14

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
                                    onMoved: (v) => Settings.barRadius = v
                                }
                            }

                            RowDivider { visible: Settings.barFloating }

                            Item {
                                visible: Settings.barFloating
                                width: parent.width
                                implicitHeight: floatMarginRow.implicitHeight + 14

                                SliderRow {
                                    id: floatMarginRow
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.margins: 8
                                    title: "floating margin"
                                    from: 0
                                    to: 32
                                    stepSize: 2
                                    suffix: "px"
                                    value: Settings.barMargin
                                    onMoved: (v) => Settings.barMargin = v
                                }
                            }

                            RowDivider { visible: Settings.barFloating }

                            ToggleRow {
                                visible: Settings.barFloating
                                icon: Theme.iconSparkles
                                title: "bento island hover lift"
                                subtitle: "elevate capsules slightly on hover"
                                checked: Settings.bentoHoverLift
                                onToggled: Settings.bentoHoverLift = !Settings.bentoHoverLift
                            }
                        }

                        CategoryHeader {
                            title: "navigation modules"
                            subtitle: "core workspace and window controls on the bar"
                            icon: Theme.iconWorkspaces
                        }

                        SettingCard {
                            ToggleRow {
                                icon: Theme.iconAppLauncher
                                title: "application launcher"
                                checked: Settings.showLauncher && flickLayout.isModAssigned("launcher")
                                onToggled: flickLayout.toggleBarModule("launcher", "showLauncher")
                            }
                            RowDivider {}
                            ToggleRow {
                                icon: Theme.iconWorkspaces
                                title: "workspaces switcher"
                                checked: Settings.showWorkspaces && flickLayout.isModAssigned("workspaces")
                                onToggled: flickLayout.toggleBarModule("workspaces", "showWorkspaces")
                            }
                            RowDivider {}
                            ToggleRow {
                                icon: Theme.iconGrid
                                title: "tiling layout switcher"
                                checked: Settings.showLayoutSwitcher && flickLayout.isModAssigned("layout")
                                onToggled: flickLayout.toggleBarModule("layout", "showLayoutSwitcher")
                            }
                            RowDivider {}
                            ToggleRow {
                                icon: Theme.iconTerminal
                                title: "window title"
                                checked: Settings.showWindowTitle && flickLayout.isModAssigned("windowTitle")
                                onToggled: flickLayout.toggleBarModule("windowTitle", "showWindowTitle")
                            }
                            RowDivider { visible: Settings.showWindowTitle }
                            Item {
                                visible: Settings.showWindowTitle
                                width: parent.width
                                implicitHeight: winTitleStretchRow.implicitHeight + 14
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
                                    onSelected: (val) => Settings.windowTitleMode = val
                                }
                            }
                            RowDivider { visible: Settings.showWindowTitle }
                            ToggleRow {
                                visible: Settings.showWindowTitle
                                icon: Theme.iconEye
                                title: "app icon in window title"
                                checked: Settings.windowTitleShowIcon
                                onToggled: Settings.windowTitleShowIcon = !Settings.windowTitleShowIcon
                            }
                        }

                        CategoryHeader {
                            title: "status, connectivity & utilities"
                            icon: Theme.iconWifi
                        }

                        SettingCard {
                            ToggleRow {
                                icon: Theme.iconClock
                                title: "clock & date"
                                checked: Settings.showClock && flickLayout.isModAssigned("clock")
                                onToggled: flickLayout.toggleBarModule("clock", "showClock")
                            }
                            RowDivider {}
                            ToggleRow {
                                icon: Theme.iconMusic
                                title: "now playing / mpris"
                                checked: Settings.showMedia && flickLayout.isModAssigned("media")
                                onToggled: flickLayout.toggleBarModule("media", "showMedia")
                            }
                            RowDivider {}
                            ToggleRow {
                                icon: Theme.iconWallpaper
                                title: "wallpaper & theme browser"
                                checked: Settings.showWallpaper && flickLayout.isModAssigned("wallpaper")
                                onToggled: flickLayout.toggleBarModule("wallpaper", "showWallpaper")
                            }
                            RowDivider {}
                            ToggleRow {
                                icon: Theme.iconVolHigh
                                title: "volume & audio mixer"
                                checked: Settings.showVolume && flickLayout.isModAssigned("volume")
                                onToggled: flickLayout.toggleBarModule("volume", "showVolume")
                            }
                            RowDivider {}
                            ToggleRow {
                                icon: Theme.iconWifi
                                title: "network / wi-fi"
                                checked: Settings.showNetwork && flickLayout.isModAssigned("network")
                                onToggled: flickLayout.toggleBarModule("network", "showNetwork")
                            }
                            RowDivider {}
                            ToggleRow {
                                icon: Theme.iconBluetooth
                                title: "bluetooth devices"
                                checked: Settings.showBluetooth && flickLayout.isModAssigned("bluetooth")
                                onToggled: flickLayout.toggleBarModule("bluetooth", "showBluetooth")
                            }
                            RowDivider {}
                            ToggleRow {
                                icon: Theme.iconBatFull
                                title: "battery & power status"
                                checked: Settings.showBattery && flickLayout.isModAssigned("battery")
                                onToggled: flickLayout.toggleBarModule("battery", "showBattery")
                            }
                            RowDivider {}
                            ToggleRow {
                                icon: Theme.iconTray
                                title: "system tray icons"
                                checked: Settings.showSystemTray && flickLayout.isModAssigned("systemTray")
                                onToggled: flickLayout.toggleBarModule("systemTray", "showSystemTray")
                            }
                            RowDivider {}
                            ToggleRow {
                                icon: Theme.iconCoffee
                                title: "caffeine / idle inhibitor"
                                checked: Settings.showIdleInhibitor && flickLayout.isModAssigned("idleInhibitor")
                                onToggled: flickLayout.toggleBarModule("idleInhibitor", "showIdleInhibitor")
                            }
                            RowDivider {}
                            ToggleRow {
                                icon: Theme.iconClipboard
                                title: "clipboard history"
                                checked: Settings.showClipboard && flickLayout.isModAssigned("clipboard")
                                onToggled: flickLayout.toggleBarModule("clipboard", "showClipboard")
                            }
                            RowDivider {}
                            ToggleRow {
                                icon: Theme.iconNote
                                title: "quick notes & scratchpad"
                                checked: Settings.showQuickNotes && flickLayout.isModAssigned("quickNotes")
                                onToggled: flickLayout.toggleBarModule("quickNotes", "showQuickNotes")
                            }
                            RowDivider {}
                            ToggleRow {
                                icon: Theme.iconCamera
                                title: "screen capture & recorder"
                                checked: Settings.showScreenCapture && flickLayout.isModAssigned("screenCapture")
                                onToggled: flickLayout.toggleBarModule("screenCapture", "showScreenCapture")
                            }
                            RowDivider {}
                            ToggleRow {
                                icon: Theme.iconBell
                                title: "notification center"
                                checked: Settings.showNotifications && flickLayout.isModAssigned("notifications")
                                onToggled: flickLayout.toggleBarModule("notifications", "showNotifications")
                            }
                            RowDivider {}
                            ToggleRow {
                                icon: Theme.iconPower
                                title: "power session menu"
                                checked: Settings.showPowerMenu && flickLayout.isModAssigned("powerMenu")
                                onToggled: flickLayout.toggleBarModule("powerMenu", "showPowerMenu")
                            }
                        }
                    }
                }
                TabScrollTrack { target: flickLayout }

                // 2. appearance & style tab
                Flickable {
                    id: flickStyle
                    anchors.fill: parent
                    visible: root.activeTab === "style"
                    clip: true
                    contentWidth: width
                    contentHeight: styleCol.implicitHeight + 28
                    boundsBehavior: Flickable.StopAtBounds

                    WheelHandler {
                        orientation: Qt.Vertical
                        target: parent
                    }

                    ColumnLayout {
                        id: styleCol
                        width: parent.width
                        spacing: Theme.popupSpacing

                        CategoryHeader {
                            title: "surface & material"
                            subtitle: "bar shader preset, opacity, and custom color overrides"
                            icon: Theme.iconSparkles
                        }

                        ChoiceGrid {
                            columns: 3
                            buttonHeight: 32
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
                            onSelected: (val) => Settings.barStyle = val
                        }

                        SliderRow {
                            title: "bar background opacity"
                            from: 0.3
                            to: 1.0
                            stepSize: 0.05
                            value: Settings.barOpacity
                            formatter: (v) => Math.round(v * 100) + "%"
                            onMoved: (val) => Settings.barOpacity = val
                        }

                        SliderRow {
                            title: "popup background opacity"
                            from: 0.5
                            to: 1.0
                            stepSize: 0.05
                            value: Settings.popupOpacity
                            formatter: (v) => Math.round(v * 100) + "%"
                            onMoved: (val) => Settings.popupOpacity = val
                        }

                        SettingCard {
                            ToggleRow {
                                icon: Theme.iconPalette
                                title: "custom color overrides"
                                subtitle: "override matugen palette tokens with custom hex colors"
                                checked: Settings.customColorsEnabled
                                onToggled: {
                                    Settings.customColorsEnabled = !Settings.customColorsEnabled;
                                    if (Settings.save) Settings.save();
                                }
                            }

                            GridLayout {
                                visible: Settings.customColorsEnabled
                                width: parent.width
                                columns: 2
                                columnSpacing: 6
                                rowSpacing: 6

                                ColorTile {
                                    title: "background"
                                    subtitle: Settings.customBg !== "" ? Settings.customBg : "default"
                                    swatchColor: Settings.customBg !== "" ? Settings.customBg : Theme.background
                                    onClicked: colorStudioModal.open("customBg", "background color", "main background surface color", Settings.customBg, Theme.background)
                                }

                                ColorTile {
                                    title: "accent"
                                    subtitle: Settings.customActive !== "" ? Settings.customActive : "default"
                                    swatchColor: Settings.customActive !== "" ? Settings.customActive : Theme.primary
                                    onClicked: colorStudioModal.open("customActive", "accent color", "primary highlight color", Settings.customActive, Theme.primary)
                                }

                                ColorTile {
                                    title: "text"
                                    subtitle: Settings.customText !== "" ? Settings.customText : "default"
                                    swatchColor: Settings.customText !== "" ? Settings.customText : Theme.on_surface
                                    onClicked: colorStudioModal.open("customText", "text color", "primary foreground text", Settings.customText, Theme.on_surface)
                                }

                                ColorTile {
                                    title: "subtext"
                                    subtitle: Settings.customSubtext !== "" ? Settings.customSubtext : "default"
                                    swatchColor: Settings.customSubtext !== "" ? Settings.customSubtext : Theme.on_surface_variant
                                    onClicked: colorStudioModal.open("customSubtext", "subtext color", "secondary labels and muted icons", Settings.customSubtext, Theme.on_surface_variant)
                                }

                                ColorTile {
                                    title: "border"
                                    subtitle: Settings.customBorder !== "" ? Settings.customBorder : "default"
                                    swatchColor: Settings.customBorder !== "" ? Settings.customBorder : Theme.outline
                                    onClicked: colorStudioModal.open("customBorder", "border color", "outlines and dividers", Settings.customBorder, Theme.outline)
                                }

                                ColorTile {
                                    title: "widget & pill"
                                    subtitle: Settings.customWidgetBg !== "" ? Settings.customWidgetBg : "default"
                                    swatchColor: Settings.customWidgetBg !== "" ? Settings.customWidgetBg : Theme.pillBg
                                    onClicked: colorStudioModal.open("customWidgetBg", "widget & pill color", "surface color for bar pills", Settings.customWidgetBg, Theme.pillBg)
                                }
                            }
                        }

                        CategoryHeader {
                            title: "screen shape & dynamic notch"
                            subtitle: "concave fillets, scoops, curvature, and center island"
                            icon: Theme.iconGrid
                        }

                        SettingCard {
                            ToggleRow {
                                icon: Theme.iconSparkles
                                title: "reactive dynamic notch"
                                subtitle: "interactive center island (clock, calendar & timer)"
                                checked: Settings.dynamicNotchEnabled
                                onToggled: Settings.dynamicNotchEnabled = !Settings.dynamicNotchEnabled
                            }

                            RowDivider { visible: Settings.dynamicNotchEnabled }

                            ChoiceGrid {
                                visible: Settings.dynamicNotchEnabled
                                title: "dynamic notch mode"
                                columns: 3
                                model: [
                                    { label: "adaptive auto", value: "auto" },
                                    { label: "clock only", value: "clock" },
                                    { label: "timer only", value: "timer" }
                                ]
                                currentValue: Settings.dynamicNotchMode
                                onSelected: (val) => Settings.dynamicNotchMode = val
                            }

                            RowDivider { visible: Settings.dynamicNotchEnabled }

                            ToggleRow {
                                visible: Settings.dynamicNotchEnabled
                                icon: Theme.iconSparkles
                                title: "dynamic notch concave flares"
                                subtitle: "melt center notch into screen bezel"
                                checked: Settings.dynamicNotchFlared
                                onToggled: Settings.dynamicNotchFlared = !Settings.dynamicNotchFlared
                            }

                            SliderRow {
                                visible: Settings.dynamicNotchEnabled && Settings.dynamicNotchFlared
                                title: "notch flare radius"
                                from: 8
                                to: 32
                                stepSize: 2
                                suffix: "px"
                                value: Settings.notchFlareRadius
                                onMoved: (val) => Settings.notchFlareRadius = val
                            }
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
                            onSelected: (val) => Settings.screenCornerMode = val
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
                            onSelected: (val) => Settings.cornerStyle = val
                        }

                        SettingCard {
                            ToggleRow {
                                icon: Theme.iconSparkles
                                title: "scoop border outlines"
                                subtitle: "draw continuous stroke along concave curves"
                                checked: Settings.scoopBorderEnabled
                                onToggled: Settings.scoopBorderEnabled = !Settings.scoopBorderEnabled
                            }
                            RowDivider {}
                            ToggleRow {
                                icon: Theme.iconGrid
                                title: "docked frame & scoops"
                                subtitle: "anchor shell fillets directly to screen bounds"
                                checked: Settings.screenFrameDocked
                                onToggled: Settings.screenFrameDocked = !Settings.screenFrameDocked
                            }
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
                            onSelected: (val) => Settings.cornerColorMode = val
                        }

                        SliderRow {
                            title: "scoop border width"
                            from: 1
                            to: 6
                            stepSize: 1
                            suffix: "px"
                            value: Settings.scoopBorderWidth
                            onMoved: (val) => Settings.scoopBorderWidth = val
                        }

                        SliderRow {
                            title: "frame border width"
                            from: 0
                            to: 16
                            stepSize: 2
                            value: Settings.screenBorderWidth
                            formatter: (v) => v === 0 ? "none (corners only)" : (Math.round(v) + "px (full frame)")
                            onMoved: (val) => Settings.screenBorderWidth = val
                        }

                        SliderRow {
                            title: "bar scoop radius"
                            from: 0
                            to: 32
                            stepSize: 2
                            suffix: "px"
                            value: Settings.scoopRadius
                            onMoved: (val) => Settings.scoopRadius = val
                        }

                        SliderRow {
                            title: "screen corner radius"
                            from: 0
                            to: 40
                            stepSize: 2
                            suffix: "px"
                            value: Settings.screenCornerRadius
                            onMoved: (val) => Settings.screenCornerRadius = val
                        }

                        Rectangle {
                            Layout.alignment: Qt.AlignRight
                            visible: Settings.scoopRadius !== Settings.screenCornerRadius
                            height: 24
                            implicitWidth: syncText.implicitWidth + 20
                            radius: Theme.radiusPill
                            color: syncMouse.containsMouse ? Theme.primary_overlay : Theme.surface_container_highest
                            border.color: Theme.primary
                            border.width: 1

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
                                onClicked: Settings.screenCornerRadius = Settings.scoopRadius
                            }
                        }

                        CategoryHeader {
                            title: "typography & icon system"
                            subtitle: "font families, scale, weight, and icon pack"
                            icon: Theme.iconNote
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Rectangle {
                                Layout.fillWidth: true
                                height: 34
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
                                    onClicked: root.fontTarget = "sans"
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                height: 34
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
                                    onClicked: root.fontTarget = "mono"
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            height: 38
                            color: Theme.cardBg
                            radius: Theme.widgetRadius
                            border.color: fontSearchInput.activeFocus ? Theme.primary : Theme.cardBorder
                            border.width: 1

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 10
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
                            height: 180
                            color: Theme.cardBg
                            radius: Theme.widgetRadius
                            border.color: Theme.outline_variant
                            border.width: 1
                            clip: true

                            WheelHandler {
                                target: fontListView
                                onWheel: (event) => {
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
                                    height: 34
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
                                            if (root.fontTarget === "sans") Settings.fontFamily = modelData;
                                            else Settings.fontMono = modelData;
                                        }
                                    }
                                }
                            }

                            TabScrollTrack { target: fontListView }
                        }

                        SliderRow {
                            title: "interface font scaling"
                            from: 0.8
                            to: 1.4
                            stepSize: 0.05
                            value: Settings.fontScale
                            formatter: (v) => Math.round(v * 100) + "%"
                            onMoved: (val) => Settings.fontScale = val
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
                            onSelected: (val) => Settings.fontWeight = val
                        }

                        SettingCard {
                            ChoiceGrid {
                                columns: 2
                                buttonHeight: 32
                                title: "icon family"
                                model: [
                                    { label: "material", value: "material" },
                                    { label: "nerd fonts", value: "nerd" },
                                    { label: "windows segoe", value: "windows" },
                                    { label: "font awesome", value: "awesome" },
                                    { label: "(ﾉ◕ヮ◕)ﾉ kaomoji", value: "kaomoji" },
                                    { label: "plain text", value: "text" }
                                ]
                                currentValue: root.usingMaterialIcons ? "material" : Settings.iconSet
                                onSelected: (value) => {
                                    Settings.iconSet = value;
                                    if (value === "material" &&
                                        Settings.fontMaterial !== "Material Symbols Rounded" &&
                                        Settings.fontMaterial !== "Material Symbols Outlined" &&
                                        Settings.fontMaterial !== "Material Symbols Sharp") {
                                        Settings.fontMaterial = "Material Symbols Rounded";
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
                                onSelected: (value) => {
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
                                onSelected: (value) => Settings.fontNerd = value
                            }
                        }
                    }
                }
                TabScrollTrack { target: flickStyle }

                // 3. behavior, lock screen sandbox & clock tab
                Flickable {
                    id: flickBehavior
                    anchors.fill: parent
                    visible: root.activeTab === "behavior"
                    clip: true
                    contentWidth: width
                    contentHeight: behaviorCol.implicitHeight + 28
                    boundsBehavior: Flickable.StopAtBounds

                    WheelHandler {
                        orientation: Qt.Vertical
                        target: parent
                    }

                    ColumnLayout {
                        id: behaviorCol
                        width: parent.width
                        spacing: Theme.popupSpacing

                        CategoryHeader {
                            title: "lock screen & clock scope"
                            subtitle: "keep lock screen tweaks in their own sandbox file or sync them globally across the rice"
                            icon: Theme.iconLock
                        }

                        SettingCard {
                            ToggleRow {
                                icon: Theme.iconClock
                                title: "sync clock globally across rice"
                                subtitle: root.lockCfg.syncClockGlobal
                                    ? "global mode: lock screen & bar share 12h/24h and seconds"
                                    : "sandbox mode: lock screen clock stays independent in lockscreen.json"
                                checked: Boolean(root.lockCfg.syncClockGlobal)
                                onToggled: root.updateLockCfg("syncClockGlobal", !root.lockCfg.syncClockGlobal)
                            }

                            RowDivider {}

                            Item {
                                width: parent.width
                                implicitHeight: lockQuoteRow.implicitHeight + 12

                                ChoiceRow {
                                    id: lockQuoteRow
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.margins: 6
                                    title: "lock screen quote source"
                                    model: [
                                        { label: "hyprctl splash", value: "hyprland" },
                                        { label: "unhinged", value: "unhinged" },
                                        { label: "hidden", value: "off" }
                                    ]
                                    currentValue: root.lockCfg.quoteMode ?? "hyprland"
                                    onSelected: (val) => root.updateLockCfg("quoteMode", val)
                                }
                            }

                            RowDivider {}

                            Item {
                                width: parent.width
                                implicitHeight: lockClockRow.implicitHeight + 12

                                ChoiceRow {
                                    id: lockClockRow
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.margins: 6
                                    title: root.lockCfg.syncClockGlobal ? "global clock format (bar + lock screen)" : "sandboxed lock screen clock format"
                                    model: [
                                        { label: "12h", value: "12h" },
                                        { label: "24h", value: "24h" },
                                        { label: "12h + sec", value: "12h_sec" },
                                        { label: "24h + sec", value: "24h_sec" }
                                    ]
                                    currentValue: (root.lockCfg.clock24h ? "24h" : "12h") + (root.lockCfg.showSeconds ? "_sec" : "")
                                    onSelected: (val) => {
                                        let is24 = val.startsWith("24h");
                                        let hasSec = val.endsWith("_sec");
                                        let next = Object.assign({}, root.lockCfg, { clock24h: is24, showSeconds: hasSec });
                                        root.lockCfg = next;
                                        lockSandboxFile.setText(JSON.stringify(next, null, 2));
                                        if (next.syncClockGlobal) root.applyGlobalClock(is24, hasSec);
                                    }
                                }
                            }

                            RowDivider {}

                            Item {
                                width: parent.width
                                implicitHeight: lockDimSlider.implicitHeight + 14

                                SliderRow {
                                    id: lockDimSlider
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.margins: 6
                                    title: "lock screen backdrop dim"
                                    from: 0.20
                                    to: 0.90
                                    stepSize: 0.05
                                    value: root.lockCfg.scrimDim ?? 0.58
                                    formatter: (v) => Math.round(v * 100) + "%"
                                    onMoved: (val) => root.updateLockCfg("scrimDim", val)
                                }
                            }

                            RowDivider {}

                            ToggleRow {
                                icon: Theme.iconWallpaper
                                title: "sync lock wallpaper with desktop"
                                subtitle: "disable to keep a separate shuffled wallpaper on the lock screen"
                                checked: root.lockCfg.wallpaperSync ?? true
                                onToggled: root.updateLockCfg("wallpaperSync", !(root.lockCfg.wallpaperSync ?? true))
                            }
                        }

                        CategoryHeader {
                            title: "bar clock, workspaces & audio"
                            icon: Theme.iconClock
                        }

                        CollapsibleSection {
                            Layout.fillWidth: true
                            title: "bar clock & workspace capacity"
                            subtitle: "bar time/date formats & max workspaces"
                            icon: Theme.iconClock
                            badge: Settings.showBarDate ? Settings.clockFormat : "time only"

                            Dropdown {
                                width: parent.width
                                label: "bar clock format"
                                icon: Theme.iconClock
                                model: [
                                    { label: "24h (16:45)", value: "HH:mm" },
                                    { label: "12h (4:45 pm)", value: "h:mm ap" },
                                    { label: "24h + sec", value: "HH:mm:ss" },
                                    { label: "12h + sec", value: "h:mm:ss ap" }
                                ]
                                currentValue: Settings.clockFormat
                                onSelected: (value) => {
                                    Settings.clockFormat = value;
                                    let is12 = /ap/i.test(value);
                                    let hasSec = /:ss/i.test(value);
                                    Settings.clockMilitary = !is12;
                                    Settings.clock24h = !is12;
                                    Settings.clockShowSeconds = hasSec;
                                    if (root.lockCfg.syncClockGlobal) {
                                        let next = Object.assign({}, root.lockCfg, { clock24h: !is12, showSeconds: hasSec });
                                        root.lockCfg = next;
                                        lockSandboxFile.setText(JSON.stringify(next, null, 2));
                                    }
                                }
                            }

                            Dropdown {
                                width: parent.width
                                label: "bar date format"
                                icon: Theme.iconCalendar
                                model: [
                                    { label: "hidden (time only)", value: "none" },
                                    { label: "short (mon, sep 1)", value: "ddd, MMM d" },
                                    { label: "standard (sep 1)", value: "MMM d, yyyy" },
                                    { label: "iso (2026-09-01)", value: "yyyy-MM-dd" }
                                ]
                                currentValue: !Settings.showBarDate ? "none" : Settings.dateFormat
                                onSelected: (value) => {
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
                                onSelected: (value) => Settings.workspaceCount = value
                            }
                        }

                        CategoryHeader {
                            title: "motion & interaction"
                            subtitle: "animation speed presets, workspace trail, and hover behavior"
                            icon: Theme.iconFlame
                        }

                        SettingCard {
                            Repeater {
                                model: [
                                    { id: "hyprland", label: "hyprland sync (default)", desc: "matches hyprland bezier curves & timing" },
                                    { id: "snappy", label: "snappy & responsive", desc: "110ms ultra-fast transitions with zero delay" },
                                    { id: "chill", label: "smooth & relaxed", desc: "300ms cubic ease for aesthetic flow" },
                                    { id: "instant", label: "instant / zero lag", desc: "minimal motion for raw performance" }
                                ]

                                delegate: Column {
                                    required property var modelData
                                    required property int index
                                    width: parent.width

                                    RowDivider { visible: index > 0 }

                                    Rectangle {
                                        width: parent.width
                                        height: 48
                                        radius: Theme.radiusSm
                                        color: Settings.animSpeed === modelData.id
                                            ? Theme.primary_overlay
                                            : (aMouse.containsMouse ? Theme.surface_container_highest : "transparent")

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: 10
                                            anchors.rightMargin: 10
                                            spacing: 10

                                            Text {
                                                text: Settings.animSpeed === modelData.id ? Theme.iconCheckCircle : Theme.iconFlame
                                                font.family: Theme.fontIcon
                                                font.pixelSize: Theme.fontSizeSm
                                                color: Settings.animSpeed === modelData.id ? Theme.primary : Theme.on_surface_variant
                                            }

                                            ColumnLayout {
                                                Layout.fillWidth: true
                                                spacing: 1

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
                                            onClicked: Settings.animSpeed = modelData.id
                                        }
                                    }
                                }
                            }
                        }

                        CollapsibleSection {
                            Layout.fillWidth: true
                            title: "workspace indicator motion"
                            subtitle: "pill physics & fluid trail duration"
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
                                onSelected: (value) => Settings.workspaceMode = value
                            }

                            SliderRow {
                                visible: Settings.workspaceMode === "fluid-trail"
                                title: "trail duration"
                                from: 120
                                to: 400
                                stepSize: 10
                                suffix: "ms"
                                value: Settings.workspaceTrailDuration
                                onMoved: (val) => Settings.workspaceTrailDuration = val
                            }
                        }

                        CollapsibleSection {
                            Layout.fillWidth: true
                            title: "hover & flyouts"
                            subtitle: "pill hover triggers & auto-close"
                            icon: Theme.iconEye
                            badge: Settings.hoverToOpen ? "enabled" : "click only"

                            SettingCard {
                                width: parent.width
                                ToggleRow {
                                    icon: Theme.iconEye
                                    title: "hover to open flyouts"
                                    subtitle: "hover over bar pills to open popups"
                                    checked: Settings.hoverToOpen
                                    onToggled: Settings.hoverToOpen = !Settings.hoverToOpen
                                }
                                RowDivider {}
                                ToggleRow {
                                    icon: Theme.iconEyeOff
                                    title: "hover auto-close"
                                    subtitle: "dismiss popup when cursor leaves"
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
                                onMoved: (val) => Settings.hoverDelay = val
                            }
                        }

                        CollapsibleSection {
                            Layout.fillWidth: true
                            title: "audio & notifications"
                            subtitle: "volume limits, toast timeout & dnd"
                            icon: Theme.iconBell
                            badge: Settings.dnd ? "dnd on" : (Settings.volumeMax + "% max")

                            SliderRow {
                                title: "volume scroll step"
                                from: 1
                                to: 15
                                stepSize: 1
                                value: Settings.volumeStep
                                formatter: (v) => Math.round(v) + "%"
                                onMoved: (val) => Settings.volumeStep = val
                            }

                            SliderRow {
                                title: "max volume ceiling"
                                from: 100
                                to: 200
                                stepSize: 5
                                value: Settings.volumeMax
                                formatter: (v) => Math.round(v) + "%"
                                onMoved: (val) => Settings.volumeMax = val
                            }

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
                                onSelected: (value) => Settings.notificationTimeout = value
                            }

                            SettingCard {
                                width: parent.width
                                ToggleRow {
                                    icon: Theme.iconBellOff
                                    title: "do not disturb"
                                    subtitle: "suppress on-screen notification popups"
                                    checked: Settings.dnd
                                    onToggled: Settings.dnd = !Settings.dnd
                                }
                                RowDivider {}
                                ToggleRow {
                                    icon: Theme.iconFlame
                                    title: "unhinged flavor text"
                                    subtitle: "chaotic system status quips & personality"
                                    checked: Settings.unhingedFlavor
                                    onToggled: Settings.unhingedFlavor = !Settings.unhingedFlavor
                                }
                                RowDivider {}
                                ToggleRow {
                                    icon: Theme.iconSparkles
                                    title: "motion sandbox playground"
                                    subtitle: "open interactive physics playground on screen edge"
                                    checked: Settings.showMotionSandbox
                                    onToggled: Settings.showMotionSandbox = !Settings.showMotionSandbox
                                }
                            }
                        }
                    }
                }
                TabScrollTrack { target: flickBehavior }

                // 4. capture & recording tab
                Flickable {
                    id: flickScreenshot
                    anchors.fill: parent
                    visible: root.activeTab === "capture"
                    clip: true
                    contentWidth: width
                    contentHeight: screenshotCol.implicitHeight + 28
                    boundsBehavior: Flickable.StopAtBounds

                    WheelHandler {
                        orientation: Qt.Vertical
                        target: parent
                    }

                    ColumnLayout {
                        id: screenshotCol
                        width: parent.width
                        spacing: Theme.popupSpacing

                        CategoryHeader {
                            title: "quick capture & recording"
                            subtitle: "launch a screenshot or screen recording directly"
                            icon: Theme.iconCamera
                        }

                        SettingCard {
                            Item {
                                width: parent.width
                                implicitHeight: 48

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 4
                                    spacing: 8

                                    Repeater {
                                        model: [
                                            { id: "region", label: "shot region", icon: Theme.iconCrop },
                                            { id: "window", label: "shot window", icon: Theme.iconWorkspaces },
                                            { id: "full", label: "shot display", icon: Theme.iconExpand }
                                        ]

                                        delegate: Rectangle {
                                            required property var modelData
                                            Layout.fillWidth: true
                                            height: 38
                                            radius: Theme.widgetRadius
                                            color: scQuickM.pressed ? Theme.primary : (scQuickM.containsMouse ? Theme.primary_overlay : Theme.surface_container_highest)
                                            border.color: scQuickM.containsMouse ? Theme.primary : Theme.outline_variant
                                            border.width: 1

                                            RowLayout {
                                                anchors.centerIn: parent
                                                spacing: 6
                                                Text {
                                                    text: modelData.icon
                                                    font.family: Theme.fontIcon
                                                    font.pixelSize: Theme.fontSizeSm
                                                    color: scQuickM.pressed ? Theme.on_primary : Theme.primary
                                                }
                                                Text {
                                                    text: modelData.label
                                                    font.family: Theme.fontFamily
                                                    font.pixelSize: Theme.fontSizeXs
                                                    font.weight: Theme.fontWeightMedium
                                                    color: scQuickM.pressed ? Theme.on_primary : Theme.on_surface
                                                }
                                            }

                                            MouseArea {
                                                id: scQuickM
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    popup.open = false;
                                                    if (modelData.id === "full") {
                                                        const scr = root.barScreen || (Quickshell.screens?.length > 0 ? Quickshell.screens[0] : null);
                                                        ScreenshotService.captureFullscreen(scr, Settings.screenshotDefaultAction || "both");
                                                    } else {
                                                        ScreenshotService.open(modelData.id);
                                                    }
                                                }
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
                            onSelected: (val) => ScreenRecService.activeAudio = val
                        }

                        ChoiceRow {
                            title: "default screenshot action"
                            model: [
                                { label: "save & copy", value: "both" },
                                { label: "clipboard only", value: "copy" },
                                { label: "save only", value: "save" },
                                { label: "editor / markup", value: "edit" }
                            ]
                            currentValue: Settings.screenshotDefaultAction
                            onSelected: (val) => Settings.screenshotDefaultAction = val
                        }

                        CategoryHeader {
                            title: "selection overlay & behavior"
                            icon: Theme.iconSliders
                        }

                        SettingCard {
                            ToggleRow {
                                icon: Theme.iconWorkspaces
                                title: "window snapping"
                                subtitle: "hover over any hyprland client to snap to its geometry"
                                checked: Settings.screenshotWindowSnapping
                                onToggled: Settings.screenshotWindowSnapping = !Settings.screenshotWindowSnapping
                            }
                            RowDivider {}
                            ToggleRow {
                                icon: Theme.iconEye
                                title: "freeze frame on open"
                                subtitle: "freeze display during selection so windows don't move"
                                checked: Settings.screenshotFreeze
                                onToggled: Settings.screenshotFreeze = !Settings.screenshotFreeze
                            }
                            RowDivider {}
                            ToggleRow {
                                icon: Theme.iconFlame
                                title: "shutter flash"
                                subtitle: "visual flash animation when capture finishes"
                                checked: Settings.screenshotFlash
                                onToggled: Settings.screenshotFlash = !Settings.screenshotFlash
                            }
                            RowDivider {}
                            ToggleRow {
                                icon: Theme.iconBell
                                title: "desktop notification"
                                subtitle: "send notification with image preview on capture"
                                checked: Settings.screenshotNotify
                                onToggled: Settings.screenshotNotify = !Settings.screenshotNotify
                            }
                            RowDivider {}
                            ToggleRow {
                                icon: Theme.iconGrid
                                title: "hairline crosshairs"
                                subtitle: "show alignment crosshairs tracking cursor"
                                checked: Settings.screenshotShowCrosshair
                                onToggled: Settings.screenshotShowCrosshair = !Settings.screenshotShowCrosshair
                            }
                            RowDivider {}
                            ToggleRow {
                                icon: Theme.iconNote
                                title: "live dimension badge"
                                subtitle: "show [w × h] and window class above selection"
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

                        SliderRow {
                            title: "backdrop dimming opacity"
                            from: 0.1
                            to: 0.9
                            stepSize: 0.05
                            value: Settings.screenshotDimOpacity
                            formatter: (v) => Math.round(v * 100) + "%"
                            onMoved: (val) => Settings.screenshotDimOpacity = val
                        }

                        SliderRow {
                            title: "selection border width"
                            from: 1
                            to: 6
                            stepSize: 1
                            suffix: "px"
                            value: Settings.screenshotBorderWidth
                            onMoved: (val) => Settings.screenshotBorderWidth = val
                        }

                        SliderRow {
                            title: "selection corner radius"
                            from: 0
                            to: 20
                            stepSize: 2
                            suffix: "px"
                            value: Settings.screenshotBorderRadius
                            onMoved: (val) => Settings.screenshotBorderRadius = val
                        }
                    }
                }
                TabScrollTrack { target: flickScreenshot }

                // 5. system & recovery tab
                Flickable {
                    id: flickAdvanced
                    anchors.fill: parent
                    visible: root.activeTab === "advanced"
                    clip: true
                    contentWidth: width
                    contentHeight: advancedCol.implicitHeight + 28
                    boundsBehavior: Flickable.StopAtBounds

                    WheelHandler {
                        orientation: Qt.Vertical
                        target: parent
                    }

                    ColumnLayout {
                        id: advancedCol
                        width: parent.width
                        spacing: Theme.popupSpacing

                        readonly property var aliasKeys: Object.keys(Settings.networkAliases || {})

                        CategoryHeader {
                            title: "shell profiles & process"
                            icon: Theme.iconTerminal
                        }

                        SettingCard {
                            Repeater {
                                model: [
                                    {
                                        id: "quickshell",
                                        name: "quickshell (native)",
                                        desc: "primary custom quickshell setup",
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

                                    RowDivider { visible: index > 0 }

                                    Rectangle {
                                        width: parent.width
                                        implicitHeight: 62
                                        radius: Theme.radiusSm
                                        color: root.activeShell === modelData.id
                                            ? Theme.primary_overlay
                                            : (shMouse.containsMouse ? Theme.surface_container_highest : "transparent")

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.margins: 10
                                            spacing: 12

                                            Rectangle {
                                                width: 38
                                                height: 38
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
                                                spacing: 1

                                                Text {
                                                    text: modelData.name
                                                    font.family: Theme.fontFamily
                                                    font.pixelSize: Theme.fontSizeSm
                                                    font.weight: Theme.fontWeightBold
                                                    color: Theme.on_surface
                                                }

                                                Text {
                                                    text: modelData.desc + "  •  " + modelData.path
                                                    font.family: Theme.fontMono
                                                    font.pixelSize: 9
                                                    color: Theme.on_surface_variant
                                                    elide: Text.ElideRight
                                                    Layout.fillWidth: true
                                                }
                                            }

                                            Rectangle {
                                                height: 28
                                                width: 68
                                                radius: Theme.radiusPill
                                                color: root.activeShell === modelData.id ? Theme.primary : Theme.surface_container_highest

                                                Text {
                                                    anchors.centerIn: parent
                                                    text: root.activeShell === modelData.id ? "active" : "switch"
                                                    font.family: Theme.fontFamily
                                                    font.pixelSize: 10
                                                    font.weight: Theme.fontWeightBold
                                                    color: root.activeShell === modelData.id ? Theme.on_primary : Theme.on_surface
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

                        Rectangle {
                            Layout.fillWidth: true
                            height: 42
                            radius: Theme.widgetRadius
                            color: rstMouse.containsMouse ? Theme.primary_overlay : Theme.surface_container_highest
                            border.color: rstMouse.containsMouse ? Theme.primary : Theme.widgetBorder
                            border.width: 1

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 8

                                Text {
                                    text: Theme.iconRefresh
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
                                onClicked: switchProc.restartCurrent()
                            }
                        }

                        CategoryHeader {
                            title: "network aliases"
                            icon: Theme.iconWifi
                        }

                        SettingCard {
                            Rectangle {
                                width: parent.width
                                height: 38
                                color: "transparent"
                                visible: advancedCol.aliasKeys.length === 0

                                Text {
                                    anchors.centerIn: parent
                                    text: "no custom network aliases saved yet (rename in wi-fi menu)"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 10
                                    color: Theme.on_surface_variant
                                }
                            }

                            Repeater {
                                model: advancedCol.aliasKeys

                                delegate: Column {
                                    required property string modelData
                                    required property int index
                                    width: parent.width

                                    RowDivider { visible: index > 0 }

                                    Rectangle {
                                        width: parent.width
                                        height: 40
                                        color: "transparent"

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: 10
                                            anchors.rightMargin: 10
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
                                                font.pixelSize: Theme.fontSizeSm
                                                font.weight: Theme.fontWeightBold
                                                color: Theme.on_surface
                                            }

                                            Text {
                                                text: "(" + modelData + ")"
                                                font.family: Theme.fontMono
                                                font.pixelSize: 10
                                                color: Theme.on_surface_variant
                                                Layout.fillWidth: true
                                                elide: Text.ElideRight
                                            }

                                            IconButton {
                                                icon: Theme.iconTrash
                                                iconSize: 12
                                                tooltip: "remove alias"
                                                onClicked: Settings.setNetworkAlias(modelData, "")
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        CategoryHeader {
                            title: "onboarding & recovery"
                            icon: Theme.iconSparkles
                        }

                        SettingCard {
                            ToggleRow {
                                icon: Theme.iconSparkles
                                title: "reopen welcome guide"
                                subtitle: "launch the onboarding & vibe calibration wizard"
                                checked: false
                                onToggled: {
                                    popup.open = false;
                                    Settings.requestWelcomeOpen();
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            height: 52
                            radius: Theme.widgetRadius
                            color: nukeMouse.containsMouse ? Theme.error_overlay : Theme.surface_container_highest
                            border.color: nukeMouse.containsMouse ? Theme.error : Theme.widgetBorder
                            border.width: 1

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
                                    spacing: 1

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
                                    width: 60
                                    height: 28
                                    radius: Theme.radiusPill
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
                                onClicked: root.showResetConfirm = true
                            }
                        }
                    }
                }
                TabScrollTrack { target: flickAdvanced }

                // 6. keybinds tab
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

            // footer
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

        // reset confirmation modal
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
                    text: "are you sure? this will wipe every tweak and revert everything back to stock defaults."
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
                            onClicked: root.showResetConfirm = false
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 40
                        radius: Theme.radiusSm
                        color: confirmMouse.containsMouse ? Theme.error_container : Theme.error

                        Text {
                            text: "reset everything"
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeSm
                            font.weight: Theme.fontWeightBold
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

        ColorStudioModal {
            id: colorStudioModal
        }
    }
}
