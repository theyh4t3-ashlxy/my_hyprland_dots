import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import ".."
import "../controls"
import "../corners"

PopupPanel {
    id: root

    required property var modelData
    screen: modelData

    cardWidth: Math.min(1160, Math.max(780, (root.screen?.width ?? 1920) - 48))
    cardHeight: Math.min(680, Math.max(520, (root.screen?.height ?? 1080) - (Theme?.barHeight ?? 48) - 32))
    open: false

    property bool isDragging: false
    property string draggedModId: ""
    property string dragSourceZone: ""
    property int dragSourceIndex: -1
    property real ghostX: 0
    property real ghostY: 0
    property real ghostW: 240
    property real dragOffsetX: 0
    property real dragOffsetY: 0
    property string hoverZoneId: ""
    property int hoverIndex: -1

    readonly property var moduleCatalog: ({
        "launcher":      { name: "app launcher",      icon: Theme?.iconDistro ?? Theme?.iconArch ?? "\uE88A",      desc: "application search & grid" },
        "wallpaper":     { name: "wallpaper browser", icon: Theme?.iconWallpaper ?? "\uE1BC", desc: "awww & mpvpaper selector" },
        "workspaces":    { name: "workspaces",        icon: Theme?.iconWorkspaces ?? "\uE871", desc: "hyprland workspace dots" },
        "windowTitle":   { name: "active window",     icon: Theme?.iconSparkles ?? "\uE65F",   desc: "focused window title badge" },
        "clock":         { name: "clock & date",      icon: Theme?.iconClock ?? "\uEFD6",     desc: "time, date & calendar" },
        "media":         { name: "media player",      icon: Theme?.iconMusic ?? "\uE405",     desc: "mpris music controls" },
        "quickNotes":    { name: "quick notes",       icon: Theme?.iconEdit ?? "\uF097",      desc: "floating scratchpad notes" },
        "clipboard":     { name: "clipboard manager", icon: Theme?.iconClipboard ?? "\uE14D", desc: "cliphist history & sync" },
        "idleInhibitor": { name: "idle inhibitor",    icon: Theme?.iconCoffee ?? "\uEFEF",    desc: "stay awake toggle" },
        "notifications": { name: "notifications",     icon: Theme?.iconBell ?? "\uE7F5",      desc: "alert center & toast log" },
        "systemTray":    { name: "system tray",       icon: Theme?.iconGrid ?? "\uE9B0",      desc: "statusnotifier tray icons" },
        "bluetooth":     { name: "bluetooth",         icon: Theme?.iconBluetooth ?? "\uE1A7", desc: "bluetooth devices & scan" },
        "network":       { name: "network status",    icon: Theme?.iconWifi ?? "\uE63E",       desc: "wifi & ethernet monitor" },
        "volume":        { name: "volume & sink",     icon: Theme?.iconVolHigh ?? "\uE050",   desc: "pipewire audio controls" },
        "battery":       { name: "battery & power",   icon: Theme?.iconBatFull ?? "\uE1A5",   desc: "upower level & charging" },
        "quickSettings": { name: "quick settings",    icon: Theme?.iconSettings ?? "\uE8B8",  desc: "system & appearance toggles" },
        "powerMenu":     { name: "power menu",        icon: Theme?.iconPower ?? "\uF8C7",     desc: "lock, logout & power off" }
    })

    readonly property var unassignedModules: {
        const assigned = new Set([
            ...(Settings?.barModulesLeft ?? []),
            ...(Settings?.barModulesCenter ?? []),
            ...(Settings?.barModulesRight ?? [])
        ]);
        return Object.keys(root.moduleCatalog).filter(id => !assigned.has(id));
    }

    Component.onCompleted: {
        if (Settings?.showBarStudio) {
            const focused = Hyprland?.focusedMonitor?.name;
            if (!focused || !root.screen || root.screen?.name === focused) {
                root.open = true;
            }
        }
    }

    Connections {
        target: Settings

        function onShowBarStudioChanged() {
            if (Settings?.showBarStudio) {
                const focused = Hyprland?.focusedMonitor?.name;
                root.open = (!focused || !root.screen || root.screen?.name === focused);
            } else {
                root.open = false;
            }
        }
    }

    onOpenChanged: {
        if (!open) {
            if (isDragging) cancelDrag();
            if (Settings?.showBarStudio) {
                const focused = Hyprland?.focusedMonitor?.name;
                if (!focused || !root.screen || root.screen?.name === focused) {
                    Settings.showBarStudio = false;
                }
            }
        }
    }

    function getModuleInfo(modId) {
        return root.moduleCatalog[modId] ?? {
            name: modId,
            icon: Theme?.iconGrid ?? "\uE9B0",
            desc: "custom widget"
        };
    }

    function isModuleVisible(modId) {
        if (!Settings) return true;
        switch (modId) {
            case "launcher": return Settings.showLauncher ?? true;
            case "wallpaper": return Settings.showWallpaper ?? true;
            case "workspaces": return Settings.showWorkspaces ?? true;
            case "windowTitle": return Settings.showWindowTitle ?? true;
            case "clock": return Settings.showClock ?? true;
            case "media": return Settings.showMedia ?? true;
            case "quickNotes": return Settings.showQuickNotes ?? true;
            case "clipboard": return Settings.showClipboard ?? true;
            case "idleInhibitor": return Settings.showIdleInhibitor ?? true;
            case "notifications": return Settings.showNotifications ?? true;
            case "systemTray": return Settings.showSystemTray ?? true;
            case "bluetooth": return Settings.showBluetooth ?? true;
            case "network": return Settings.showNetwork ?? true;
            case "volume": return Settings.showVolume ?? true;
            case "battery": return Settings.showBattery ?? true;
            case "quickSettings": return Settings.showQuickSettings ?? true;
            case "powerMenu": return Settings.showPowerMenu ?? true;
            default: return true;
        }
    }

    function toggleModuleVisibility(modId) {
        if (!Settings) return;
        switch (modId) {
            case "launcher": Settings.showLauncher = !Settings.showLauncher; break;
            case "wallpaper": Settings.showWallpaper = !Settings.showWallpaper; break;
            case "workspaces": Settings.showWorkspaces = !Settings.showWorkspaces; break;
            case "windowTitle": Settings.showWindowTitle = !Settings.showWindowTitle; break;
            case "clock": Settings.showClock = !Settings.showClock; break;
            case "media": Settings.showMedia = !Settings.showMedia; break;
            case "quickNotes": Settings.showQuickNotes = !Settings.showQuickNotes; break;
            case "clipboard": Settings.showClipboard = !Settings.showClipboard; break;
            case "idleInhibitor": Settings.showIdleInhibitor = !Settings.showIdleInhibitor; break;
            case "notifications": Settings.showNotifications = !Settings.showNotifications; break;
            case "systemTray": Settings.showSystemTray = !Settings.showSystemTray; break;
            case "bluetooth": Settings.showBluetooth = !Settings.showBluetooth; break;
            case "network": Settings.showNetwork = !Settings.showNetwork; break;
            case "volume": Settings.showVolume = !Settings.showVolume; break;
            case "battery": Settings.showBattery = !Settings.showBattery; break;
            case "quickSettings": Settings.showQuickSettings = !Settings.showQuickSettings; break;
            case "powerMenu": Settings.showPowerMenu = !Settings.showPowerMenu; break;
        }
    }

    function getZoneList(z) {
        if (!Settings) return [];
        if (z === "left") return (Settings.barModulesLeft ?? []).slice();
        if (z === "center") return (Settings.barModulesCenter ?? []).slice();
        if (z === "right") return (Settings.barModulesRight ?? []).slice();
        return [];
    }

    function setZoneList(z, arr) {
        if (!Settings) return;
        if (z === "left") Settings.barModulesLeft = arr;
        else if (z === "center") Settings.barModulesCenter = arr;
        else if (z === "right") Settings.barModulesRight = arr;
    }

    function startDrag(zoneId, index, modId, cardItem, mouseX, mouseY) {
        isDragging = true;
        draggedModId = modId;
        dragSourceZone = zoneId;
        dragSourceIndex = index;
        ghostW = cardItem.width;
        dragOffsetX = mouseX;
        dragOffsetY = mouseY;

        // null maps directly to window scene coordinates without blowing up
        const p = cardItem.mapToItem(null, mouseX, mouseY);
        ghostX = p.x - dragOffsetX;
        ghostY = p.y - dragOffsetY;
        updateHoverTarget(p.x, p.y);
    }

    function updateDrag(globalX, globalY) {
        ghostX = globalX - dragOffsetX;
        ghostY = globalY - dragOffsetY;
        updateHoverTarget(globalX, globalY);
    }

    function updateHoverTarget(globalX, globalY) {
        const zones = [leftColZone, centerColZone, rightColZone];
        let foundZone = null;

        for (let i = 0; i < zones.length; ++i) {
            const z = zones[i];
            const p = z.mapFromItem(null, globalX, globalY);
            if (p.x >= -6 && p.x <= z.width + 6 && p.y >= -12 && p.y <= z.height + 12) {
                foundZone = z;
                break;
            }
        }

        if (!foundZone) {
            hoverZoneId = "";
            hoverIndex = -1;
            return;
        }

        hoverZoneId = foundZone.zoneId;
        hoverIndex = foundZone.getDropIndex(globalY);
    }

    function finishDrag() {
        if (!isDragging) return;

        const fromZ = dragSourceZone;
        const fromIdx = dragSourceIndex;
        const toZ = hoverZoneId;
        const toIdx = hoverIndex;

        cancelDrag();

        if (!toZ || toIdx < 0) return;
        reorderModule(fromZ, fromIdx, toZ, toIdx);
    }

    function cancelDrag() {
        isDragging = false;
        draggedModId = "";
        dragSourceZone = "";
        dragSourceIndex = -1;
        hoverZoneId = "";
        hoverIndex = -1;
    }

    function reorderModule(fromZone, fromIdx, toZone, toIdx) {
        const src = getZoneList(fromZone);
        if (fromIdx < 0 || fromIdx >= src.length) return;
        const item = src[fromIdx];

        if (fromZone === toZone) {
            const dest = (toIdx > fromIdx) ? (toIdx - 1) : toIdx;
            if (dest === fromIdx) return;
            src.splice(fromIdx, 1);
            src.splice(Math.max(0, Math.min(src.length, dest)), 0, item);
            setZoneList(fromZone, src);
        } else {
            src.splice(fromIdx, 1);
            const dst = getZoneList(toZone);
            dst.splice(Math.max(0, Math.min(dst.length, toIdx)), 0, item);
            setZoneList(fromZone, src);
            setZoneList(toZone, dst);
        }
    }

    function moveModuleStep(zoneId, index, delta) {
        const list = getZoneList(zoneId);
        const targetIdx = index + delta;
        if (targetIdx < 0 || targetIdx >= list.length) return;
        const item = list.splice(index, 1)[0];
        list.splice(targetIdx, 0, item);
        setZoneList(zoneId, list);
    }

    function transferModule(fromZone, index, targetZone) {
        if (fromZone === targetZone) return;
        const src = getZoneList(fromZone);
        if (index < 0 || index >= src.length) return;
        const item = src.splice(index, 1)[0];
        const dst = getZoneList(targetZone);
        dst.push(item);
        setZoneList(fromZone, src);
        setZoneList(targetZone, dst);
    }

    function removeModule(zoneId, index) {
        const list = getZoneList(zoneId);
        if (index < 0 || index >= list.length) return;
        list.splice(index, 1);
        setZoneList(zoneId, list);
    }

    function addModuleToZone(modId, targetZone) {
        const list = getZoneList(targetZone);
        if (list.includes(modId)) return;
        list.push(modId);
        setZoneList(targetZone, list);
    }

    content: ColumnLayout {
        id: contentRoot
        anchors.fill: parent
        spacing: 10
        focus: true

        Keys.onEscapePressed: (event) => {
            if (root.isDragging) {
                root.cancelDrag();
                event.accepted = true;
            } else if (root.open) {
                if (Settings) Settings.showBarStudio = false;
                root.open = false;
                event.accepted = true;
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Rectangle {
                Layout.preferredWidth: 32
                Layout.preferredHeight: 32
                radius: Theme?.radiusPill ?? 16
                color: Theme?.primary_overlay ?? "#20ffffff"

                Text {
                    anchors.centerIn: parent
                    text: Theme?.iconSparkles ?? "✦"
                    font.family: Theme?.fontIcon
                    font.pixelSize: Theme?.fontSizeMd ?? 14
                    color: Theme?.primary ?? "#ffffff"
                }
            }

            ColumnLayout {
                spacing: 1
                Text {
                    text: "bar layout studio"
                    font.family: Theme?.fontFamily
                    font.pixelSize: Theme?.fontSizeMd ?? 14
                    font.weight: Font.Bold
                    color: Theme?.on_surface ?? "#ffffff"
                }
                Text {
                    text: "drag cards or click arrows to hot-reorder panels on your status bar"
                    font.family: Theme?.fontFamily
                    font.pixelSize: Theme?.fontSizeXs ?? 11
                    color: Theme?.on_surface_variant ?? "#aaaaaa"
                }
            }

            Item { Layout.fillWidth: true }

            Rectangle {
                Layout.preferredHeight: 28
                Layout.preferredWidth: resetRow.implicitWidth + 18
                radius: Theme?.radiusPill ?? 14
                color: resetMouse.containsMouse ? (Theme?.surface_container_highest ?? "#383838") : (Theme?.surface_container_high ?? "#2b2b2b")
                border.color: Theme?.widgetBorder ?? "#444444"
                border.width: 1

                Row {
                    id: resetRow
                    anchors.centerIn: parent
                    spacing: 5
                    Text {
                        text: "↺"
                        font.pixelSize: 11
                        color: Theme?.on_surface ?? "#ffffff"
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        text: "reset layout"
                        font.family: Theme?.fontFamily
                        font.pixelSize: 10
                        color: Theme?.on_surface ?? "#ffffff"
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea {
                    id: resetMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Settings?.resetBarLayout ? Settings.resetBarLayout() : null
                }
            }

            Rectangle {
                Layout.preferredWidth: 28
                Layout.preferredHeight: 28
                radius: Theme?.radiusPill ?? 14
                color: closeMouse.containsMouse ? (Theme?.error_overlay ?? "#33ff5555") : (Theme?.surface_container_high ?? "#2b2b2b")
                border.color: Theme?.widgetBorder ?? "#444444"
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: "✕"
                    font.family: Theme?.fontFamily
                    font.pixelSize: 11
                    color: closeMouse.containsMouse ? (Theme?.error ?? "#ff5555") : (Theme?.on_surface ?? "#ffffff")
                }

                MouseArea {
                    id: closeMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (Settings) Settings.showBarStudio = false;
                        root.open = false;
                    }
                }
            }
        }

        Rectangle {
            id: barPreviewMock
            Layout.fillWidth: true
            Layout.preferredHeight: 84
            color: Theme?.surface_container_lowest ?? "#141414"
            radius: Theme?.radiusMd ?? 8
            border.color: Theme?.widgetBorder ?? "#333333"
            border.width: 1

            readonly property string barPos: Settings?.barPosition ?? "top"
            readonly property bool isTop: barPos === "up" || barPos === "top"
            readonly property bool isBottom: barPos === "down" || barPos === "bottom"
            readonly property bool isLeft: barPos === "left"
            readonly property bool isRight: barPos === "right"
            readonly property bool isVertical: isLeft || isRight

            Rectangle {
                id: screenMock
                anchors.fill: parent
                anchors.margins: 7
                color: Theme?.background ?? "#1e1e1e"
                radius: Theme?.radiusSm ?? 4
                clip: true

                Rectangle {
                    id: mockBar
                    anchors.left: !barPreviewMock.isRight ? parent.left : undefined
                    anchors.right: !barPreviewMock.isLeft ? parent.right : undefined
                    anchors.top: !barPreviewMock.isBottom ? parent.top : undefined
                    anchors.bottom: !barPreviewMock.isTop ? parent.bottom : undefined
                    width: barPreviewMock.isVertical ? 22 : parent.width
                    height: barPreviewMock.isVertical ? parent.height : 22
                    color: Theme?.surface_container_low ?? "#222222"
                    z: 2

                    component MiniModulePill: Rectangle {
                        required property string modelData
                        readonly property var info: root.getModuleInfo(modelData)
                        readonly property bool isVis: root.isModuleVisible(modelData)
                        readonly property bool isGhostTarget: root.isDragging && root.draggedModId === modelData

                        height: barPreviewMock.isVertical ? 14 : 12
                        width: barPreviewMock.isVertical ? 14 : Math.max(12, mText.implicitWidth + 6)
                        radius: 3
                        color: isGhostTarget ? (Theme?.primary ?? "#ffffff") : (isVis ? (Theme?.primary_overlay ?? "#25ffffff") : (Theme?.surface_container_highest ?? "#383838"))
                        border.color: isGhostTarget ? (Theme?.primary ?? "#ffffff") : "transparent"
                        border.width: 1

                        Text {
                            id: mText
                            anchors.centerIn: parent
                            text: parent.info.icon
                            font.family: Theme?.fontIcon
                            font.pixelSize: 8
                            color: parent.isGhostTarget ? (Theme?.on_primary ?? "#000000") : (parent.isVis ? (Theme?.primary ?? "#ffffff") : (Theme?.on_surface_disabled ?? "#666666"))
                        }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 3
                        spacing: 3
                        visible: !barPreviewMock.isVertical

                        Repeater {
                            model: Settings?.barModulesLeft ?? []
                            MiniModulePill {}
                        }

                        Item { Layout.fillWidth: true }

                        Repeater {
                            model: Settings?.barModulesCenter ?? []
                            MiniModulePill {}
                        }

                        Item { Layout.fillWidth: true }

                        Repeater {
                            model: Settings?.barModulesRight ?? []
                            MiniModulePill {}
                        }
                    }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 3
                        spacing: 3
                        visible: barPreviewMock.isVertical

                        Repeater {
                            model: Settings?.barModulesLeft ?? []
                            MiniModulePill {}
                        }

                        Item { Layout.fillHeight: true }

                        Repeater {
                            model: Settings?.barModulesCenter ?? []
                            MiniModulePill {}
                        }

                        Item { Layout.fillHeight: true }

                        Repeater {
                            model: Settings?.barModulesRight ?? []
                            MiniModulePill {}
                        }
                    }
                }

                Rectangle {
                    anchors.left: barPreviewMock.isLeft ? mockBar.right : parent.left
                    anchors.right: barPreviewMock.isRight ? mockBar.left : parent.right
                    anchors.top: barPreviewMock.isTop ? mockBar.bottom : parent.top
                    anchors.bottom: barPreviewMock.isBottom ? mockBar.top : parent.bottom
                    anchors.margins: 5
                    color: Theme?.surface_container_high ?? "#2c2c2c"
                    radius: Theme?.radiusSm ?? 4
                    border.color: Theme?.primary_overlay ?? "#1affffff"
                    border.width: 1

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 8

                        Text {
                            text: "dock position:"
                            font.family: Theme?.fontFamily
                            font.pixelSize: 9
                            color: Theme?.on_surface_variant ?? "#999999"
                        }

                        Repeater {
                            model: [
                                { pos: "top", label: "top ↑" },
                                { pos: "bottom", label: "bottom ↓" },
                                { pos: "left", label: "left ←" },
                                { pos: "right", label: "right →" }
                            ]

                            delegate: Rectangle {
                                required property var modelData
                                height: 20
                                implicitWidth: dockText.implicitWidth + 10
                                radius: Theme?.radiusPill ?? 10
                                readonly property bool isCurrent: (Settings?.barPosition === modelData.pos)
                                    || (modelData.pos === "top" && Settings?.barPosition === "up")
                                    || (modelData.pos === "bottom" && Settings?.barPosition === "down")
                                color: isCurrent ? (Theme?.primary ?? "#ffffff") : (dockMouse.containsMouse ? (Theme?.surface_container_highest ?? "#444444") : (Theme?.surface_container_low ?? "#202020"))

                                Text {
                                    id: dockText
                                    anchors.centerIn: parent
                                    text: modelData.label
                                    font.family: Theme?.fontFamily
                                    font.pixelSize: 8
                                    font.weight: isCurrent ? Font.Bold : Font.Normal
                                    color: isCurrent ? (Theme?.on_primary ?? "#000000") : (Theme?.on_surface ?? "#ffffff")
                                }

                                MouseArea {
                                    id: dockMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (Settings) Settings.barPosition = modelData.pos;
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 10

            ZoneColumn {
                id: leftColZone
                Layout.fillWidth: true
                Layout.fillHeight: true
                zoneId: "left"
                zoneTitle: "left modules"
                modulesList: Settings?.barModulesLeft ?? []
            }

            ZoneColumn {
                id: centerColZone
                Layout.fillWidth: true
                Layout.fillHeight: true
                zoneId: "center"
                zoneTitle: "center modules"
                modulesList: Settings?.barModulesCenter ?? []
            }

            ZoneColumn {
                id: rightColZone
                Layout.fillWidth: true
                Layout.fillHeight: true
                zoneId: "right"
                zoneTitle: "right modules"
                modulesList: Settings?.barModulesRight ?? []
            }
        }

        Rectangle {
            id: unassignedTray
            visible: root.unassignedModules.length > 0
            Layout.fillWidth: true
            Layout.preferredHeight: 38
            color: Theme?.surface_container_low ?? "#1c1c1c"
            radius: Theme?.radiusSm ?? 4
            border.color: Theme?.widgetBorder ?? "#333333"
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 8

                Text {
                    text: "unassigned (" + root.unassignedModules.length + "):"
                    font.family: Theme?.fontFamily
                    font.pixelSize: 9
                    font.weight: Font.DemiBold
                    color: Theme?.on_surface_variant ?? "#888888"
                }

                Flickable {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    contentWidth: unassignedRow.implicitWidth
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    Row {
                        id: unassignedRow
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 6

                        Repeater {
                            model: root.unassignedModules

                            delegate: Rectangle {
                                required property string modelData
                                readonly property var info: root.getModuleInfo(modelData)

                                height: 24
                                implicitWidth: pillRow.implicitWidth + 12
                                radius: Theme?.radiusPill ?? 12
                                color: Theme?.surface_container_high ?? "#282828"
                                border.color: Theme?.widgetBorder ?? "#3a3a3a"
                                border.width: 1

                                Row {
                                    id: pillRow
                                    anchors.centerIn: parent
                                    spacing: 5

                                    Text {
                                        text: parent.parent.info.icon
                                        font.family: Theme?.fontIcon
                                        font.pixelSize: 9
                                        color: Theme?.primary ?? "#ffffff"
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                    Text {
                                        text: parent.parent.info.name
                                        font.family: Theme?.fontFamily
                                        font.pixelSize: 9
                                        color: Theme?.on_surface ?? "#ffffff"
                                        anchors.verticalCenter: parent.verticalCenter
                                    }

                                    Text {
                                        text: "+left"
                                        font.family: Theme?.fontFamily
                                        font.pixelSize: 8
                                        font.weight: Font.Bold
                                        color: leftAddMouse.containsMouse ? (Theme?.primary ?? "#ffffff") : (Theme?.on_surface_variant ?? "#777777")
                                        anchors.verticalCenter: parent.verticalCenter

                                        MouseArea {
                                            id: leftAddMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.addModuleToZone(modelData, "left")
                                        }
                                    }

                                    Text {
                                        text: "+center"
                                        font.family: Theme?.fontFamily
                                        font.pixelSize: 8
                                        font.weight: Font.Bold
                                        color: centerAddMouse.containsMouse ? (Theme?.primary ?? "#ffffff") : (Theme?.on_surface_variant ?? "#777777")
                                        anchors.verticalCenter: parent.verticalCenter

                                        MouseArea {
                                            id: centerAddMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.addModuleToZone(modelData, "center")
                                        }
                                    }

                                    Text {
                                        text: "+right"
                                        font.family: Theme?.fontFamily
                                        font.pixelSize: 8
                                        font.weight: Font.Bold
                                        color: rightAddMouse.containsMouse ? (Theme?.primary ?? "#ffffff") : (Theme?.on_surface_variant ?? "#777777")
                                        anchors.verticalCenter: parent.verticalCenter

                                        MouseArea {
                                            id: rightAddMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.addModuleToZone(modelData, "right")
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

    component ZoneColumn: Rectangle {
        id: zoneRoot
        required property string zoneId
        required property string zoneTitle
        required property var modulesList

        readonly property bool isOverThisZone: root.isDragging && root.hoverZoneId === zoneRoot.zoneId

        radius: Theme?.radiusMd ?? 8
        color: isOverThisZone ? (Theme?.surface_container_high ?? "#333333") : (Theme?.surface_container_low ?? "#1f1f1f")
        border.color: isOverThisZone ? (Theme?.primary ?? "#ffffff") : (Theme?.widgetBorder ?? "#333333")
        border.width: isOverThisZone ? 2 : 1

        Behavior on color { ColorAnimation { duration: Theme?.animFast ?? 120 } }
        Behavior on border.color { ColorAnimation { duration: Theme?.animFast ?? 120 } }

        function getActiveCount() {
            const list = zoneRoot.modulesList ?? [];
            let count = 0;
            for (let i = 0; i < list.length; ++i) {
                if (root.isModuleVisible(list[i])) count++;
            }
            return count;
        }

        function getDropIndex(globalY) {
            const list = zoneRoot.modulesList;
            if (!list || list.length === 0) return 0;
            const p = moduleCol.mapFromItem(null, 0, globalY);
            const idx = Math.round((p.y - 19) / 44);
            return Math.max(0, Math.min(list.length, idx));
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 8

            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: zoneRoot.zoneTitle
                    font.family: Theme?.fontFamily
                    font.pixelSize: Theme?.fontSizeXs ?? 11
                    font.weight: Font.Bold
                    color: zoneRoot.isOverThisZone ? (Theme?.primary ?? "#ffffff") : (Theme?.on_surface ?? "#ffffff")
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: zoneRoot.getActiveCount() + "/" + zoneRoot.modulesList.length + " active"
                    font.family: Theme?.fontFamily
                    font.pixelSize: 9
                    color: Theme?.on_surface_variant ?? "#888888"
                }
            }

            Flickable {
                id: flickable
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                interactive: !root.isDragging
                contentHeight: Math.max(height, moduleCol.implicitHeight + 10)
                contentWidth: width
                boundsBehavior: Flickable.StopAtBounds

                Column {
                    id: moduleCol
                    width: flickable.width
                    spacing: 0

                    Repeater {
                        model: zoneRoot.modulesList

                        delegate: Column {
                            id: cardColWrap
                            required property string modelData
                            required property int index
                            readonly property var info: root.getModuleInfo(modelData)
                            readonly property bool isVisible: root.isModuleVisible(modelData)
                            readonly property bool isThisDragged: root.isDragging && root.draggedModId === modelData
                            readonly property bool isNoOpTarget: zoneRoot.zoneId === root.dragSourceZone && (root.hoverIndex === root.dragSourceIndex || root.hoverIndex === root.dragSourceIndex + 1)
                            readonly property bool showDropBefore: zoneRoot.isOverThisZone && root.hoverIndex === index && !isNoOpTarget

                            width: moduleCol.width
                            spacing: 0

                            Rectangle {
                                width: parent.width
                                height: cardColWrap.showDropBefore ? 6 : 0
                                color: "transparent"
                                visible: height > 0

                                Rectangle {
                                    anchors.centerIn: parent
                                    width: parent.width - 8
                                    height: 3
                                    radius: 1.5
                                    color: Theme?.primary ?? "#ffffff"
                                }
                            }

                            Rectangle {
                                id: card
                                width: parent.width
                                height: 38
                                radius: Theme?.radiusSm ?? 4
                                color: cardColWrap.isThisDragged ? (Theme?.surface_container_highest ?? "#3c3c3c") : (cardMouse.containsMouse ? (Theme?.surface_container_highest ?? "#353535") : (Theme?.surface_container_high ?? "#292929"))
                                border.color: cardColWrap.isThisDragged ? (Theme?.primary ?? "#ffffff") : (cardColWrap.isVisible ? (Theme?.widgetBorder ?? "#3b3b3b") : (Theme?.error_overlay ?? "#40ff5555"))
                                border.width: 1
                                opacity: cardColWrap.isThisDragged ? 0.35 : 1.0

                                MouseArea {
                                    id: cardMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    preventStealing: pressedLocal || root.isDragging
                                    cursorShape: root.isDragging ? Qt.ClosedHandCursor : Qt.OpenHandCursor

                                    property real pressX: 0
                                    property real pressY: 0
                                    property bool pressedLocal: false

                                    onPressed: (mouse) => {
                                        if (mouse.button !== Qt.LeftButton) return;
                                        pressX = mouse.x;
                                        pressY = mouse.y;
                                        pressedLocal = true;
                                    }

                                    onPositionChanged: (mouse) => {
                                        if (!pressedLocal) return;
                                        if (!root.isDragging) {
                                            if (Math.hypot(mouse.x - pressX, mouse.y - pressY) > 4) {
                                                root.startDrag(zoneRoot.zoneId, cardColWrap.index, cardColWrap.modelData, card, mouse.x, mouse.y);
                                            }
                                        } else {
                                            const p = card.mapToItem(null, mouse.x, mouse.y);
                                            root.updateDrag(p.x, p.y);
                                        }
                                    }

                                    onReleased: {
                                        if (root.isDragging) root.finishDrag();
                                        pressedLocal = false;
                                    }

                                    onCanceled: {
                                        if (root.isDragging) root.cancelDrag();
                                        pressedLocal = false;
                                    }
                                }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 8
                                    anchors.rightMargin: 8
                                    spacing: 6

                                    Text {
                                        text: "⠿"
                                        font.family: Theme?.fontIcon
                                        font.pixelSize: 13
                                        color: cardMouse.containsMouse ? (Theme?.primary ?? "#ffffff") : (Theme?.on_surface_variant ?? "#777777")
                                    }

                                    Text {
                                        text: cardColWrap.info.icon
                                        font.family: Theme?.fontIcon
                                        font.pixelSize: Theme?.fontSizeSm ?? 12
                                        color: cardColWrap.isVisible ? (Theme?.primary ?? "#ffffff") : (Theme?.on_surface_disabled ?? "#555555")
                                    }

                                    Text {
                                        text: cardColWrap.info.name
                                        font.family: Theme?.fontFamily
                                        font.pixelSize: 10
                                        font.weight: Font.DemiBold
                                        color: cardColWrap.isVisible ? (Theme?.on_surface ?? "#ffffff") : (Theme?.on_surface_disabled ?? "#555555")
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                    }

                                    RowLayout {
                                        z: 5
                                        spacing: 2
                                        opacity: cardMouse.containsMouse ? 1.0 : 0.45

                                        Rectangle {
                                            visible: zoneRoot.zoneId === "center" || zoneRoot.zoneId === "right"
                                            Layout.preferredWidth: 18
                                            Layout.preferredHeight: 18
                                            radius: 3
                                            color: shiftLeftMouse.containsMouse ? (Theme?.surface_container_highest ?? "#444444") : "transparent"

                                            Text {
                                                anchors.centerIn: parent
                                                text: "◀"
                                                font.pixelSize: 8
                                                color: Theme?.on_surface ?? "#ffffff"
                                            }

                                            MouseArea {
                                                id: shiftLeftMouse
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: root.transferModule(zoneRoot.zoneId, cardColWrap.index, zoneRoot.zoneId === "right" ? "center" : "left")
                                            }
                                        }

                                        Rectangle {
                                            visible: cardColWrap.index > 0
                                            Layout.preferredWidth: 18
                                            Layout.preferredHeight: 18
                                            radius: 3
                                            color: upMouse.containsMouse ? (Theme?.surface_container_highest ?? "#444444") : "transparent"

                                            Text {
                                                anchors.centerIn: parent
                                                text: "▲"
                                                font.pixelSize: 7
                                                color: Theme?.on_surface ?? "#ffffff"
                                            }

                                            MouseArea {
                                                id: upMouse
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: root.moveModuleStep(zoneRoot.zoneId, cardColWrap.index, -1)
                                            }
                                        }

                                        Rectangle {
                                            visible: cardColWrap.index < zoneRoot.modulesList.length - 1
                                            Layout.preferredWidth: 18
                                            Layout.preferredHeight: 18
                                            radius: 3
                                            color: downMouse.containsMouse ? (Theme?.surface_container_highest ?? "#444444") : "transparent"

                                            Text {
                                                anchors.centerIn: parent
                                                text: "▼"
                                                font.pixelSize: 7
                                                color: Theme?.on_surface ?? "#ffffff"
                                            }

                                            MouseArea {
                                                id: downMouse
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: root.moveModuleStep(zoneRoot.zoneId, cardColWrap.index, 1)
                                            }
                                        }

                                        Rectangle {
                                            visible: zoneRoot.zoneId === "left" || zoneRoot.zoneId === "center"
                                            Layout.preferredWidth: 18
                                            Layout.preferredHeight: 18
                                            radius: 3
                                            color: shiftRightMouse.containsMouse ? (Theme?.surface_container_highest ?? "#444444") : "transparent"

                                            Text {
                                                anchors.centerIn: parent
                                                text: "▶"
                                                font.pixelSize: 8
                                                color: Theme?.on_surface ?? "#ffffff"
                                            }

                                            MouseArea {
                                                id: shiftRightMouse
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: root.transferModule(zoneRoot.zoneId, cardColWrap.index, zoneRoot.zoneId === "left" ? "center" : "right")
                                            }
                                        }

                                        Rectangle {
                                            Layout.preferredWidth: 20
                                            Layout.preferredHeight: 20
                                            radius: Theme?.radiusSm ?? 3
                                            color: eyeMouse.containsMouse ? (cardColWrap.isVisible ? (Theme?.primary_overlay ?? "#25ffffff") : (Theme?.error_overlay ?? "#30ff5555")) : "transparent"

                                            Text {
                                                anchors.centerIn: parent
                                                text: cardColWrap.isVisible ? Theme.iconEye : Theme.iconEyeOff
                                                font.family: Theme.fontIcon
                                                font.pixelSize: 11
                                                color: cardColWrap.isVisible ? (Theme?.primary ?? "#ffffff") : (Theme?.error ?? "#ff5555")
                                            }

                                            MouseArea {
                                                id: eyeMouse
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: root.toggleModuleVisibility(cardColWrap.modelData)
                                            }
                                        }

                                        Rectangle {
                                            Layout.preferredWidth: 18
                                            Layout.preferredHeight: 18
                                            radius: 3
                                            color: removeMouse.containsMouse ? (Theme?.error_overlay ?? "#30ff5555") : "transparent"

                                            Text {
                                                anchors.centerIn: parent
                                                text: Theme.iconClose
                                                font.family: Theme.fontIcon
                                                font.pixelSize: 10
                                                color: removeMouse.containsMouse ? (Theme?.error ?? "#ff5555") : (Theme?.on_surface_variant ?? "#777777")
                                            }

                                            MouseArea {
                                                id: removeMouse
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: root.removeModule(zoneRoot.zoneId, cardColWrap.index)
                                            }
                                        }
                                    }
                                }
                            }

                            Rectangle {
                                width: parent.width
                                height: (zoneRoot.isOverThisZone && cardColWrap.index === zoneRoot.modulesList.length - 1 && root.hoverIndex >= zoneRoot.modulesList.length && !cardColWrap.isNoOpTarget) ? 6 : 0
                                color: "transparent"
                                visible: height > 0

                                Rectangle {
                                    anchors.centerIn: parent
                                    width: parent.width - 8
                                    height: 3
                                    radius: 1.5
                                    color: Theme?.primary ?? "#ffffff"
                                }
                            }

                            Item {
                                width: parent.width
                                height: 6
                            }
                        }
                    }

                    Rectangle {
                        visible: zoneRoot.modulesList.length === 0
                        width: parent.width
                        height: 64
                        radius: Theme?.radiusSm ?? 4
                        color: zoneRoot.isOverThisZone ? (Theme?.primary_overlay ?? "#20ffffff") : "transparent"
                        border.color: zoneRoot.isOverThisZone ? (Theme?.primary ?? "#ffffff") : (Theme?.widgetBorder ?? "#333333")
                        border.width: 1

                        Column {
                            anchors.centerIn: parent
                            spacing: 2
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: zoneRoot.isOverThisZone ? "drop module here" : "empty zone"
                                font.family: Theme?.fontFamily
                                font.pixelSize: 10
                                font.weight: Font.Bold
                                color: zoneRoot.isOverThisZone ? (Theme?.primary ?? "#ffffff") : (Theme?.on_surface_variant ?? "#777777")
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "drag cards across or use unassigned tray"
                                font.family: Theme?.fontFamily
                                font.pixelSize: 8
                                color: Theme?.on_surface_disabled ?? "#555555"
                            }
                        }
                    }
                }
            }
        }
    }

    Rectangle {
        id: dragGhost
        visible: root.isDragging
        x: root.ghostX
        y: root.ghostY
        width: root.ghostW
        height: 38
        radius: Theme?.radiusSm ?? 4
        color: Theme?.surface_container_highest ?? "#383838"
        border.color: Theme?.primary ?? "#ffffff"
        border.width: 2
        z: 99999
        opacity: 0.94
        scale: 1.03

        readonly property var info: root.getModuleInfo(root.draggedModId)

        RowLayout {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 8

            Text {
                text: "⠿"
                font.family: Theme?.fontIcon
                font.pixelSize: 13
                color: Theme?.primary ?? "#ffffff"
            }

            Text {
                text: dragGhost.info.icon
                font.family: Theme?.fontIcon
                font.pixelSize: Theme?.fontSizeSm ?? 12
                color: Theme?.primary ?? "#ffffff"
            }

            Text {
                text: dragGhost.info.name
                font.family: Theme?.fontFamily
                font.pixelSize: 10
                font.weight: Font.DemiBold
                color: Theme?.on_surface ?? "#ffffff"
                Layout.fillWidth: true
                elide: Text.ElideRight
            }
        }
    }
}