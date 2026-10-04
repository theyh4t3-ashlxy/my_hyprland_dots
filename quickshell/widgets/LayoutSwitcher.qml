import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import ".."
import "../controls"
import "../services"
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

Rectangle {
    id: root

    property var barScreen: null
    property var barMonitor: null

    // ── layout state ───────────────────────────────────────────────────────
    property string currentLayout: "dwindle"
    property int numWindows: 0
    property bool isMonocleActive: false
    property var availableLayouts: ["dwindle", "master", "scroller", "monocle"]

    readonly property var layoutDefinitions: [
        {
            id: "dwindle",
            title: "dwindle layout",
            badge: "binary tree",
            icon: "⊞",
            desc: "arranges windows like a binary tree, dynamically splitting space as windows open."
        },
        {
            id: "master",
            title: "master layout",
            badge: "master + stack",
            icon: "◫",
            desc: "keeps a primary master window alongside stacked slave windows."
        },
        {
            id: "scroller",
            title: "scrolling layout",
            badge: "infinite tape",
            icon: "↔",
            desc: "places windows on an infinitely scrolling horizontal tape, ideal for ultrawides."
        },
        {
            id: "monocle",
            title: "monocle layout",
            badge: "maximized",
            icon: "󰊓",
            desc: "maximizes the active window to fill the screen, keeping others stacked behind."
        }
    ]

    // ── physical bar sizing ────────────────────────────────────────────────
    implicitWidth: {
        if (Theme?.isVertical ?? false) return (Theme?.barHeight ?? 32) - 8;
        return (lMouse.containsMouse || popup.open)
            ? Math.max(38, pillRow.implicitWidth + 20)
            : Math.max(34, pillRow.implicitWidth + 14);
    }
    implicitHeight: (Theme?.isVertical ?? false) ? Math.max(36, pillCol.implicitHeight + 12) : ((Theme?.barHeight ?? 32) - 8)
    radius: Theme?.radiusPill ?? 999
    color: popup.open ? (Theme?.primary_overlay ?? "#33ffffff") : (lMouse.containsMouse ? (Theme?.pillHover ?? "#22ffffff") : (Theme?.pillBg ?? "#11ffffff"))
    border.color: (Theme?.isCyberNeon ?? false) ? (Theme?.primary ?? "#00ffff") : (Theme?.pillBorder ?? "transparent")
    border.width: ((Theme?.isCyberNeon ?? false) || ((Theme?.pillBorder ?? "transparent") !== "transparent")) ? 1 : 0
    visible: Settings?.showLayoutSwitcher ?? true

    Behavior on color { ColorAnimation { duration: Theme?.animFast ?? 120 } }
    Behavior on border.color { ColorAnimation { duration: Theme?.animFast ?? 120 } }
    Behavior on implicitWidth {
        NumberAnimation {
            duration: Theme?.animFast ?? 120
            easing.type: Theme?.animEasing ?? Easing.OutQuad
        }
    }

    scale: (Settings?.bentoHoverLift ?? true) && lMouse.containsMouse && !popup.open ? 1.02 : 1.0
    Behavior on scale {
        NumberAnimation {
            duration: Theme?.animFast ?? 120
            easing.type: Easing.OutQuad
        }
    }

    // ── helpers: icons & formatted labels ──────────────────────────────────
    function getLayoutIcon(layout) {
        let l = (layout || "").toLowerCase();
        if (l === "dwindle") return "⊞";
        if (l === "master") return "◫";
        if (l === "scroller" || l === "scrolling") return "↔";
        if (l === "monocle") return "󰊓";
        return "";
    }

    function getLayoutLabel(layout) {
        let l = (layout || "").toLowerCase();
        if (l === "dwindle") return "dwindle";
        if (l === "master") return "master";
        if (l === "scroller" || l === "scrolling") return "scroll";
        if (l === "monocle") return "monocle";
        return l !== "" ? l : "layout";
    }

    // ── query active hyprland layout (debounced) ───────────────────────────
    Process {
        id: queryProc
        command: ["hyprctl", "-j", "activeworkspace"]
        running: false
        stdout: StdioCollector {
            id: collector
            onStreamFinished: {
                try {
                    let obj = JSON.parse(collector.text);
                    if (obj) {
                        if (obj.windows !== undefined) {
                            root.numWindows = obj.windows;
                        }
                        // monocle takes precedence over underlying tiled layout
                        if (obj.hasfullscreen) {
                            root.isMonocleActive = true;
                            root.currentLayout = "monocle";
                        } else if (obj.tiledLayout) {
                            root.isMonocleActive = false;
                            root.currentLayout = obj.tiledLayout.toLowerCase();
                        }
                    }
                } catch (e) {}
            }
        }
    }

    Timer {
        id: debounceTimer
        interval: 60
        repeat: false
        onTriggered: {
            if (!queryProc.running) queryProc.running = true;
        }
    }

    function refreshLayout() {
        debounceTimer.restart();
    }

    Component.onCompleted: refreshLayout()

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "workspace" || 
                event.name === "focusedmon" || 
                event.name === "fullscreen" || 
                event.name === "openwindow" || 
                event.name === "closewindow") {
                root.refreshLayout();
            }
        }
    }

    Timer {
        interval: 3500
        running: true
        repeat: true
        onTriggered: root.refreshLayout()
    }

    // ── layout switch dispatcher (hyprland 0.55+ lua engine) ───────────────
    Process {
        id: setProc
        running: false
        stdout: StdioCollector {
            id: setOut
            onStreamFinished: {
                // fallback to legacy keyword if hl.config is not recognized
                if (setOut.text.includes("error") || setOut.text.includes("unknown")) {
                    legacyProc.command = ["hyprctl", "keyword", "general:layout", root.currentLayout];
                    legacyProc.running = true;
                }
            }
        }
    }

    Process {
        id: legacyProc
        running: false
    }

    function applyLayout(layoutName) {
        let target = (layoutName || "").trim().toLowerCase();
        if (!target) return;

        if (target === "monocle") {
            if (!root.isMonocleActive) {
                Hyprland.dispatch("fullscreen 1");
            }
            root.isMonocleActive = true;
            root.currentLayout = "monocle";
            return;
        }

        if (root.isMonocleActive) {
            Hyprland.dispatch("fullscreen 0");
            root.isMonocleActive = false;
        }

        root.currentLayout = target;

        // stop ongoing process if clicking rapidly
        if (setProc.running) setProc.running = false;

        // execute via hyprland 0.55+ lua evaluator directly
        setProc.command = ["hyprctl", "eval", `hl.config({ general = { layout = "${target}" } })`];
        setProc.running = true;
    }

    function addCustomLayout(layoutName) {
        let clean = (layoutName || "").trim().toLowerCase();
        if (!clean) return;
        if (!availableLayouts.includes(clean)) {
            availableLayouts = [...availableLayouts, clean];
        }
        applyLayout(clean);
    }

    function cycleNextLayout() {
        let idx = availableLayouts.indexOf(root.currentLayout);
        if (idx === -1) idx = 0;
        let nextIdx = (idx + 1) % availableLayouts.length;
        applyLayout(availableLayouts[nextIdx]);
    }

    function cyclePrevLayout() {
        let idx = availableLayouts.indexOf(root.currentLayout);
        if (idx === -1) idx = 0;
        let prevIdx = (idx - 1 + availableLayouts.length) % availableLayouts.length;
        applyLayout(availableLayouts[prevIdx]);
    }

    // ── popup geometry alignment ───────────────────────────────────────────
    function updatePosition() {
        let pt = root.mapToItem(null, 0, 0);
        let barFloats = Settings?.barFloating ?? false;
        let barMarg = barFloats ? ((Settings?.barMargin > 0) ? Settings.barMargin : 8) : 0;
        if (pt && pt.x !== undefined && root.visible) {
            popup.targetRelativeX = pt.x + (root.width / 2) + barMarg;
            popup.targetRelativeY = pt.y + (root.height / 2);
        } else {
            popup.targetRelativeX = 0;
            popup.targetRelativeY = 0;
        }
    }

    // ── bar pill contents: horizontal ──────────────────────────────────────
    Row {
        id: pillRow
        visible: !(Theme?.isVertical ?? false)
        anchors.centerIn: parent
        spacing: 6

        Text {
            id: iconText
            anchors.verticalCenter: parent.verticalCenter
            text: root.getLayoutIcon(root.currentLayout)
            font.family: Theme?.fontFamily ?? "sans-serif"
            font.pixelSize: (Theme?.fontSizeSm ?? 12) + 2
            font.weight: Font.Bold
            color: popup.open ? Theme.primary : Theme.on_surface
        }

        Text {
            id: labelText
            anchors.verticalCenter: parent.verticalCenter
            text: root.getLayoutLabel(root.currentLayout)
            font.family: Theme?.fontFamily ?? "sans-serif"
            font.pixelSize: Theme?.fontSizeXs ?? 11
            font.weight: Font.Medium
            color: popup.open ? Theme.primary : Theme.on_surface_variant
        }

        Text {
            id: countText
            visible: root.numWindows > 0
            anchors.verticalCenter: parent.verticalCenter
            text: root.numWindows.toString()
            font.family: Theme?.fontMono ?? "monospace"
            font.pixelSize: 10
            font.weight: Font.DemiBold
            color: Theme?.primary ?? "#00ffff"
            opacity: 0.85
        }
    }

    // ── bar pill contents: vertical ────────────────────────────────────────
    Column {
        id: pillCol
        visible: Theme?.isVertical ?? false
        anchors.centerIn: parent
        spacing: 2

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.getLayoutIcon(root.currentLayout)
            font.family: Theme?.fontFamily ?? "sans-serif"
            font.pixelSize: Theme?.fontSizeSm ?? 12
            font.weight: Font.Bold
            color: popup.open ? Theme.primary : Theme.on_surface
        }

        Text {
            visible: root.numWindows > 0
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.numWindows.toString()
            font.family: Theme?.fontMono ?? "monospace"
            font.pixelSize: 9
            font.weight: Font.DemiBold
            color: Theme?.primary ?? "#00ffff"
        }
    }

    // ── mouse area: click to toggle/cycle, wheel to step ───────────────────
    MouseArea {
        id: lMouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        cursorShape: Qt.PointingHandCursor

        onWheel: (wheel) => {
            if (wheel.angleDelta.y > 0) {
                root.cyclePrevLayout();
            } else if (wheel.angleDelta.y < 0) {
                root.cycleNextLayout();
            }
        }

        onClicked: (mouse) => {
            if (mouse.button === Qt.LeftButton) {
                root.cycleNextLayout();
            } else if (mouse.button === Qt.RightButton || mouse.button === Qt.MiddleButton) {
                root.updatePosition();
                popup.open = !popup.open;
            }
        }
    }

    // ── ipc listeners ──────────────────────────────────────────────────────
    Connections {
        target: Settings
        function onRequestLayoutSwitcherToggle() {
            root.updatePosition();
            popup.open = !popup.open;
        }
        function onRequestLayoutSwitcherOpen() {
            root.updatePosition();
            popup.open = true;
        }
        function onRequestLayoutSwitcherClose() {
            popup.open = false;
        }
    }

    // ── layout gui selector popup ──────────────────────────────────────────
    PopupPanel {
        id: popup
        panelWidth: 360
        panelHeight: 460
        screen: root.barScreen

        onOpenChanged: {
            if (open) root.refreshLayout();
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 10

            // ── header ─────────────────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Rectangle {
                    width: 32; height: 32; radius: 16
                    color: Theme?.primary_overlay ?? "#33ffffff"

                    Text {
                        anchors.centerIn: parent
                        text: root.getLayoutIcon(root.currentLayout)
                        font.family: Theme?.fontFamily ?? "sans-serif"
                        font.pixelSize: 16
                        font.weight: Font.Bold
                        color: Theme.primary
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1

                    Text {
                        text: "window tiling layouts"
                        font.family: Theme?.fontFamily ?? "sans-serif"
                        font.pixelSize: Theme?.fontSizeSm ?? 12
                        font.weight: Font.Bold
                        color: Theme.on_surface
                    }

                    Text {
                        text: "switch tiling engine or configure lua layout"
                        font.family: Theme?.fontFamily ?? "sans-serif"
                        font.pixelSize: Theme?.fontSizeXs ?? 10
                        color: Theme.on_surface_variant
                    }
                }

                Rectangle {
                    width: 26; height: 26; radius: 13
                    color: closeMouse.containsMouse ? (Theme?.surface_container_highest ?? "#33ffffff") : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: Theme?.iconClose ?? "✕"
                        font.family: Theme?.fontIcon ?? "sans-serif"
                        font.pixelSize: 11
                        color: Theme.on_surface_variant
                    }

                    MouseArea {
                        id: closeMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: popup.open = false
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Theme?.cardBorder ?? Qt.rgba(1, 1, 1, 0.08)
            }

            // ── layout cards grid ──────────────────────────────────────────
            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                ColumnLayout {
                    width: ScrollView.view ? ScrollView.view.availableWidth : parent.width
                    spacing: 8

                    Repeater {
                        model: root.layoutDefinitions

                        delegate: Rectangle {
                            id: layoutCard
                            required property var modelData
                            Layout.fillWidth: true
                            implicitHeight: cardCol.implicitHeight + 16
                            radius: Theme?.radiusSm ?? 8

                            readonly property bool isCurrent: root.currentLayout === modelData.id
                            color: isCurrent
                                ? (Theme?.primary_overlay ?? "#33ffffff")
                                : (cardMouse.containsMouse ? (Theme?.surface_container_high ?? "#22ffffff") : (Theme?.surface_container ?? "#11ffffff"))
                            border.color: isCurrent ? Theme.primary : (Theme?.cardBorder ?? Qt.rgba(1, 1, 1, 0.06))
                            border.width: isCurrent ? 1.5 : 1

                            Behavior on color { ColorAnimation { duration: Theme?.animFast ?? 120 } }
                            Behavior on border.color { ColorAnimation { duration: Theme?.animFast ?? 120 } }

                            ColumnLayout {
                                id: cardCol
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 4

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 8

                                    Text {
                                        text: layoutCard.modelData.icon
                                        font.family: Theme?.fontFamily ?? "sans-serif"
                                        font.pixelSize: 15
                                        font.weight: Font.Bold
                                        color: layoutCard.isCurrent ? Theme.primary : Theme.on_surface
                                    }

                                    Text {
                                        text: layoutCard.modelData.title
                                        font.family: Theme?.fontFamily ?? "sans-serif"
                                        font.pixelSize: Theme?.fontSizeSm ?? 12
                                        font.weight: Font.DemiBold
                                        color: layoutCard.isCurrent ? Theme.primary : Theme.on_surface
                                    }

                                    Rectangle {
                                        implicitWidth: badgeText.implicitWidth + 10
                                        height: 18
                                        radius: 9
                                        color: layoutCard.isCurrent 
                                            ? (Theme?.alpha ? Theme.alpha(Theme.primary, 0.2) : Qt.rgba(0,1,1,0.2)) 
                                            : (Theme?.surface_container_highest ?? "#22ffffff")

                                        Text {
                                            id: badgeText
                                            anchors.centerIn: parent
                                            text: layoutCard.modelData.badge
                                            font.family: Theme?.fontFamily ?? "sans-serif"
                                            font.pixelSize: 9
                                            font.weight: Font.Medium
                                            color: layoutCard.isCurrent ? Theme.primary : Theme.on_surface_variant
                                        }
                                    }

                                    Item { Layout.fillWidth: true }

                                    Text {
                                        visible: layoutCard.isCurrent
                                        text: "✓"
                                        font.pixelSize: 12
                                        font.weight: Font.Bold
                                        color: Theme.primary
                                    }
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: layoutCard.modelData.desc
                                    font.family: Theme?.fontFamily ?? "sans-serif"
                                    font.pixelSize: 10
                                    color: Theme.on_surface_variant
                                    wrapMode: Text.Wrap
                                    lineHeight: 1.15
                                }
                            }

                            MouseArea {
                                id: cardMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.applyLayout(layoutCard.modelData.id);
                                    popup.open = false;
                                }
                            }
                        }
                    }

                    // ── custom lua layout card ─────────────────────────────
                    Rectangle {
                        id: customCard
                        Layout.fillWidth: true
                        implicitHeight: customCol.implicitHeight + 16
                        radius: Theme?.radiusSm ?? 8

                        readonly property bool isCustomActive: !root.layoutDefinitions.some(d => d.id === root.currentLayout)
                        color: isCustomActive
                            ? (Theme?.primary_overlay ?? "#33ffffff")
                            : (Theme?.surface_container ?? "#11ffffff")
                        border.color: isCustomActive ? Theme.primary : (Theme?.cardBorder ?? Qt.rgba(1, 1, 1, 0.06))
                        border.width: isCustomActive ? 1.5 : 1

                        ColumnLayout {
                            id: customCol
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 6

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                Text {
                                    text: ""
                                    font.pixelSize: 13
                                    font.weight: Font.Bold
                                    color: Theme.primary
                                }

                                Text {
                                    text: "custom lua layout"
                                    font.family: Theme?.fontFamily ?? "sans-serif"
                                    font.pixelSize: Theme?.fontSizeSm ?? 12
                                    font.weight: Font.DemiBold
                                    color: Theme.on_surface
                                }

                                Rectangle {
                                    implicitWidth: luaBadge.implicitWidth + 10
                                    height: 18
                                    radius: 9
                                    color: customCard.isCustomActive 
                                        ? (Theme?.alpha ? Theme.alpha(Theme.primary, 0.2) : Qt.rgba(0,1,1,0.2)) 
                                        : (Theme?.surface_container_highest ?? "#22ffffff")

                                    Text {
                                        id: luaBadge
                                        anchors.centerIn: parent
                                        text: "lua engine"
                                        font.family: Theme?.fontFamily ?? "sans-serif"
                                        font.pixelSize: 9
                                        font.weight: Font.Medium
                                        color: customCard.isCustomActive ? Theme.primary : Theme.on_surface_variant
                                    }
                                }

                                Item { Layout.fillWidth: true }

                                Text {
                                    visible: customCard.isCustomActive
                                    text: "✓"
                                    font.pixelSize: 12
                                    font.weight: Font.Bold
                                    color: Theme.primary
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                text: "evaluates custom layout parameters or plugin engines via hyprctl eval."
                                font.family: Theme?.fontFamily ?? "sans-serif"
                                font.pixelSize: 10
                                color: Theme.on_surface_variant
                                wrapMode: Text.Wrap
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 6

                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 28
                                    radius: 6
                                    color: Theme?.surface_container_highest ?? "#22ffffff"
                                    border.color: luaInput.activeFocus ? Theme.primary : "transparent"
                                    border.width: 1

                                    TextInput {
                                        id: luaInput
                                        anchors.fill: parent
                                        anchors.leftMargin: 8
                                        anchors.rightMargin: 8
                                        verticalAlignment: TextInput.AlignVCenter
                                        font.family: Theme?.fontMono ?? "monospace"
                                        font.pixelSize: 11
                                        color: Theme.on_surface
                                        clip: true
                                        text: ""

                                        function submit() {
                                            if (luaInput.text.trim() !== "") {
                                                root.addCustomLayout(luaInput.text);
                                                popup.open = false;
                                                luaInput.text = "";
                                            }
                                        }

                                        Text {
                                            anchors.left: parent.left
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: "enter custom layout name..."
                                            font.family: Theme?.fontSans ?? "sans-serif"
                                            font.pixelSize: 10
                                            color: Theme.on_surface_variant
                                            opacity: 0.6
                                            visible: luaInput.text === "" && !luaInput.activeFocus
                                        }

                                        onAccepted: submit()
                                    }
                                }

                                Rectangle {
                                    width: applyBtnText.implicitWidth + 16
                                    height: 28
                                    radius: 6
                                    color: applyMouse.containsMouse ? (Theme?.primary_overlay ?? "#33ffffff") : (Theme?.surface_container_high ?? "#22ffffff")
                                    border.color: Theme.primary
                                    border.width: 1

                                    Text {
                                        id: applyBtnText
                                        anchors.centerIn: parent
                                        text: "apply"
                                        font.family: Theme?.fontSans ?? "sans-serif"
                                        font.pixelSize: 10
                                        font.weight: Font.Bold
                                        color: Theme.primary
                                    }

                                    MouseArea {
                                        id: applyMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: luaInput.submit()
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
