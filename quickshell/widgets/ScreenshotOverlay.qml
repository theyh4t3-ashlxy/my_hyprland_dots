import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import ".."
import "../controls"

PanelWindow {
    id: overlayRoot

    required property var modelData
    screen: modelData

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: "transparent"

    WlrLayershell.namespace: "quickshell:screenshot"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: ScreenshotService.isOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore

    visible: ScreenshotService.isOpen

    property bool isDragging: false
    property bool hasSelection: false
    property real startX: 0
    property real startY: 0
    property real currX: 0
    property real currY: 0
    property var hoveredClient: null
    property string pendingAction: "both"

    readonly property real selX: Math.min(startX, currX)
    readonly property real selY: Math.min(startY, currY)
    readonly property real selW: Math.abs(currX - startX)
    readonly property real selH: Math.abs(currY - startY)

    readonly property bool clientSnapped: (!hasSelection && !isDragging && hoveredClient !== null)
    readonly property real clientRelX: hoveredClient ? Math.max(0, hoveredClient.at[0] - screen.x) : 0
    readonly property real clientRelY: hoveredClient ? Math.max(0, hoveredClient.at[1] - screen.y) : 0
    readonly property real clientRelW: hoveredClient ? Math.min(screen.width - clientRelX, hoveredClient.size[0]) : 0
    readonly property real clientRelH: hoveredClient ? Math.min(screen.height - clientRelY, hoveredClient.size[1]) : 0

    readonly property real activeX: hasSelection ? selX : (clientSnapped ? clientRelX : (isDragging ? selX : 0))
    readonly property real activeY: hasSelection ? selY : (clientSnapped ? clientRelY : (isDragging ? selY : 0))
    readonly property real activeW: hasSelection ? selW : (clientSnapped ? clientRelW : (isDragging ? selW : 0))
    readonly property real activeH: hasSelection ? selH : (clientSnapped ? clientRelH : (isDragging ? selH : 0))
    readonly property bool hasActiveRegion: activeW > 4 && activeH > 4

    function checkHoveredClient(mx: real, my: real): void {
        if (!Settings.screenshotWindowSnapping || isDragging || hasSelection) return;
        let gx = screen.x + mx;
        let gy = screen.y + my;
        let list = ScreenshotService.clients || [];
        for (let i = 0; i < list.length; i++) {
            let c = list[i];
            if (!c.at || !c.size) continue;
            let cx = c.at[0];
            let cy = c.at[1];
            let cw = c.size[0];
            let ch = c.size[1];
            if (gx >= cx && gx <= cx + cw && gy >= cy && gy <= cy + ch) {
                hoveredClient = c;
                return;
            }
        }
        hoveredClient = null;
    }

    Timer {
        id: grabTimer
        interval: 60
        repeat: false
        onTriggered: overlayRoot.processGrab()
    }

    function executeNativeGrab(x: real, y: real, w: real, h: real, action: string): void {
        let grabX = Math.max(0, Math.round(x));
        let grabY = Math.max(0, Math.round(y));
        let grabW = Math.min(screen.width - grabX, Math.round(w));
        let grabH = Math.min(screen.height - grabY, Math.round(h));

        if (grabW <= 2 || grabH <= 2) return;

        pendingAction = action || Settings.screenshotDefaultAction || "both";
        cropExporter.x = grabX;
        cropExporter.y = grabY;
        cropExporter.width = grabW;
        cropExporter.height = grabH;
        innerScreencopy.x = -grabX;
        innerScreencopy.y = -grabY;

        if (Settings.screenshotFlash) {
            flashAnim.restart();
        }

        grabTimer.restart();
    }

    function processGrab(): void {
        let rawDir = Settings.screenshotDir || "~/Pictures/Screenshots";
        let dir = rawDir.replace(/^~/, Quickshell.env("HOME"));
        let timestamp = Qt.formatDateTime(new Date(), "yyyy-MM-dd_hh-mm-ss");
        let filePath = dir + "/Screenshot_" + timestamp + ".png";

        Quickshell.execDetached(["mkdir", "-p", dir]);

        cropExporter.grabToImage(function(result) {
            let saved = result.saveToFile(filePath);
            let act = overlayRoot.pendingAction;
            let scriptPath = Quickshell.env("HOME") + "/.config/quickshell/scripts/screenshot.py";

            Quickshell.execDetached([
                "python3",
                scriptPath,
                "post",
                act,
                filePath,
                Settings.screenshotNotify ? "1" : "0"
            ]);

            ScreenshotService.close();
        });
    }

    Connections {
        target: ScreenshotService
        function onIsOpenChanged() {
            if (!ScreenshotService.isOpen) {
                overlayRoot.isDragging = false;
                overlayRoot.hasSelection = false;
                overlayRoot.hoveredClient = null;
                overlayRoot.startX = 0;
                overlayRoot.startY = 0;
                overlayRoot.currX = 0;
                overlayRoot.currY = 0;
                grabTimer.stop();
            } else {
                actionsBar.randomizeQuote();
                if (Settings.screenshotFreeze) {
                    frozenScreencopy.captureFrame();
                }
            }
        }

        function onPerformCapture(targetScreen, action, x, y, w, h) {
            if (targetScreen && targetScreen.name !== overlayRoot.screen.name) return;
            overlayRoot.executeNativeGrab(x, y, w, h, action);
        }

        function onPerformFullscreen(targetScreen, action) {
            if (targetScreen && targetScreen.name !== overlayRoot.screen.name) return;
            overlayRoot.executeNativeGrab(0, 0, overlayRoot.screen.width, overlayRoot.screen.height, action);
        }
    }

    // Native Wayland background Screencopy (Freeze frame support)
    ScreencopyView {
        id: frozenScreencopy
        anchors.fill: parent
        captureSource: overlayRoot.screen
        live: !Settings.screenshotFreeze
        visible: Settings.screenshotFreeze
        z: 0
    }

    // Native Offscreen/Scene-Graph Crop Exporter (100% native QtQuick grab)
    Item {
        id: cropExporter
        x: overlayRoot.activeX
        y: overlayRoot.activeY
        width: Math.max(1, overlayRoot.activeW)
        height: Math.max(1, overlayRoot.activeH)
        clip: true
        z: -1

        ScreencopyView {
            id: innerScreencopy
            x: -overlayRoot.activeX
            y: -overlayRoot.activeY
            width: overlayRoot.screen.width
            height: overlayRoot.screen.height
            captureSource: overlayRoot.screen
            live: false
        }
    }

    // Keyboard navigation
    Item {
        id: keyHandler
        anchors.fill: parent
        focus: ScreenshotService.isOpen
        z: 1

        Keys.onEscapePressed: ScreenshotService.close()
        Keys.onReturnPressed: {
            if (overlayRoot.hasActiveRegion) {
                overlayRoot.executeNativeGrab(overlayRoot.activeX, overlayRoot.activeY, overlayRoot.activeW, overlayRoot.activeH, Settings.screenshotDefaultAction);
            } else {
                overlayRoot.executeNativeGrab(0, 0, overlayRoot.screen.width, overlayRoot.screen.height, Settings.screenshotDefaultAction);
            }
        }
        Keys.onSpacePressed: {
            overlayRoot.hasSelection = true;
            overlayRoot.startX = 0;
            overlayRoot.startY = 0;
            overlayRoot.currX = overlayRoot.screen.width;
            overlayRoot.currY = overlayRoot.screen.height;
        }
    }

    // Granular dimming backdrop: full screen when no selection
    Rectangle {
        anchors.fill: parent
        color: Theme.alpha("#000000", Settings.screenshotDimOpacity)
        visible: !overlayRoot.hasActiveRegion
        z: 2
    }

    // 4-Rect Cutout Dimming when selection active
    Item {
        anchors.fill: parent
        visible: overlayRoot.hasActiveRegion
        z: 2

        readonly property color dimColor: Theme.alpha("#000000", Settings.screenshotDimOpacity)

        // Top
        Rectangle {
            x: 0
            y: 0
            width: overlayRoot.width
            height: Math.max(0, overlayRoot.activeY)
            color: parent.dimColor
        }
        // Bottom
        Rectangle {
            x: 0
            y: overlayRoot.activeY + overlayRoot.activeH
            width: overlayRoot.width
            height: Math.max(0, overlayRoot.height - (overlayRoot.activeY + overlayRoot.activeH))
            color: parent.dimColor
        }
        // Left
        Rectangle {
            x: 0
            y: overlayRoot.activeY
            width: Math.max(0, overlayRoot.activeX)
            height: overlayRoot.activeH
            color: parent.dimColor
        }
        // Right
        Rectangle {
            x: overlayRoot.activeX + overlayRoot.activeW
            y: overlayRoot.activeY
            width: Math.max(0, overlayRoot.width - (overlayRoot.activeX + overlayRoot.activeW))
            height: overlayRoot.activeH
            color: parent.dimColor
        }
    }

    // Hairline Crosshairs
    Item {
        anchors.fill: parent
        visible: Settings.screenshotShowCrosshair && !overlayRoot.hasSelection && !overlayRoot.isDragging && !overlayRoot.clientSnapped
        z: 3

        Rectangle {
            x: 0
            y: mouseCapture.mouseY
            width: parent.width
            height: 1
            color: Theme.alpha(Theme.primary, 0.35)
        }
        Rectangle {
            x: mouseCapture.mouseX
            y: 0
            width: 1
            height: parent.height
            color: Theme.alpha(Theme.primary, 0.35)
        }
    }

    // Interactive mouse capture layer (Placed at z: 5, below selection badges and actionsBar)
    MouseArea {
        id: mouseCapture
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.CrossCursor
        z: 5

        function isOverActions(mx: real, my: real): bool {
            if (!actionsBar.visible) return false;
            let pad = 8;
            let bx = actionsBar.x - pad;
            let by = actionsBar.y - 32; // includes unhinged header tab!
            let bw = actionsBar.width + pad * 2;
            let bh = actionsBar.height + 32 + pad * 2;
            return (mx >= bx && mx <= bx + bw && my >= by && my <= by + bh);
        }

        onPressed: (mouse) => {
            if (isOverActions(mouse.x, mouse.y)) {
                mouse.accepted = false;
                return;
            }
            overlayRoot.isDragging = true;
            overlayRoot.startX = mouse.x;
            overlayRoot.startY = mouse.y;
            overlayRoot.currX = mouse.x;
            overlayRoot.currY = mouse.y;
        }

        onPositionChanged: (mouse) => {
            if (overlayRoot.isDragging) {
                overlayRoot.currX = mouse.x;
                overlayRoot.currY = mouse.y;
            } else if (!isOverActions(mouse.x, mouse.y)) {
                overlayRoot.checkHoveredClient(mouse.x, mouse.y);
            }
        }

        onReleased: (mouse) => {
            if (isOverActions(mouse.x, mouse.y)) {
                mouse.accepted = false;
                return;
            }
            overlayRoot.isDragging = false;
            if (overlayRoot.selW > 15 && overlayRoot.selH > 15) {
                overlayRoot.hasSelection = true;
            } else if (overlayRoot.hoveredClient) {
                // Clicked an active client window: snap exact bounds
                overlayRoot.hasSelection = true;
                let relX = Math.max(0, overlayRoot.hoveredClient.at[0] - screen.x);
                let relY = Math.max(0, overlayRoot.hoveredClient.at[1] - screen.y);
                let relW = Math.min(screen.width - relX, overlayRoot.hoveredClient.size[0]);
                let relH = Math.min(screen.height - relY, overlayRoot.hoveredClient.size[1]);
                overlayRoot.startX = relX;
                overlayRoot.startY = relY;
                overlayRoot.currX = relX + relW;
                overlayRoot.currY = relY + relH;
            } else {
                overlayRoot.hasSelection = false;
            }
        }
    }

    // Granular Selection Frame (z: 10)
    Rectangle {
        id: selectionBox
        visible: overlayRoot.hasActiveRegion
        x: overlayRoot.activeX
        y: overlayRoot.activeY
        width: overlayRoot.activeW
        height: overlayRoot.activeH
        color: "transparent"
        radius: Settings.screenshotBorderRadius
        border.width: Settings.screenshotBorderWidth
        border.color: Theme.primary
        z: 10

        // Corner accent handles
        Item {
            anchors.fill: parent
            visible: Settings.screenshotShowHandles

            Rectangle { x: -2; y: -2; width: 6; height: 6; color: Theme.primary }
            Rectangle { x: parent.width - 4; y: -2; width: 6; height: 6; color: Theme.primary }
            Rectangle { x: -2; y: parent.height - 4; width: 6; height: 6; color: Theme.primary }
            Rectangle { x: parent.width - 4; y: parent.height - 4; width: 6; height: 6; color: Theme.primary }
        }
    }

    // Granular Geometry & Metadata Badge (z: 20)
    Rectangle {
        id: dimBadge
        visible: Settings.screenshotShowBadge && overlayRoot.hasActiveRegion
        x: Math.max(12, Math.min(overlayRoot.width - implicitWidth - 12, overlayRoot.activeX))
        y: (overlayRoot.activeY > 36) ? (overlayRoot.activeY - 30) : (overlayRoot.activeY + 8)
        height: 24
        implicitWidth: badgeRow.implicitWidth + 16
        radius: Theme.radiusPill
        color: Theme.surface_container_highest
        border.color: Theme.outline_variant
        border.width: 1
        z: 20

        RowLayout {
            id: badgeRow
            anchors.centerIn: parent
            spacing: 6

            Text {
                visible: overlayRoot.hoveredClient !== null && (overlayRoot.hoveredClient.class || overlayRoot.hoveredClient.title)
                text: overlayRoot.hoveredClient ? (overlayRoot.hoveredClient.class || overlayRoot.hoveredClient.title) : ""
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeXs
                font.weight: Font.DemiBold
                color: Theme.primary
                elide: Text.ElideRight
                Layout.maximumWidth: 160
            }

            Text {
                text: Math.round(overlayRoot.activeW) + " × " + Math.round(overlayRoot.activeH)
                font.family: Theme.fontMono
                font.pixelSize: Theme.fontSizeXs
                color: Theme.on_surface
            }
        }
    }

    // Floating Action Toolbar with unhinged concave header (z: 100, highest priority)
    ScreenshotActions {
        id: actionsBar
        visible: !overlayRoot.isDragging
        z: 100

        x: Math.max(16, Math.min(overlayRoot.width - implicitWidth - 16,
            overlayRoot.hasActiveRegion
                ? (overlayRoot.activeX + (overlayRoot.activeW - implicitWidth) / 2)
                : ((overlayRoot.width - implicitWidth) / 2)
        ))

        y: overlayRoot.hasActiveRegion
            ? Math.max(36, Math.min(overlayRoot.height - implicitHeight - 20,
                ((overlayRoot.activeY + overlayRoot.activeH + implicitHeight + 36 < overlayRoot.height)
                    ? (overlayRoot.activeY + overlayRoot.activeH + 16)
                    : (overlayRoot.activeY - implicitHeight - 36))
              ))
            : 36

        Behavior on x { NumberAnimation { duration: Theme.animFast; easing.type: Easing.OutCubic } }
        Behavior on y { NumberAnimation { duration: Theme.animFast; easing.type: Easing.OutCubic } }

        onRegionClicked: {
            overlayRoot.hasSelection = false;
            overlayRoot.hoveredClient = null;
            overlayRoot.startX = 0;
            overlayRoot.startY = 0;
            overlayRoot.currX = 0;
            overlayRoot.currY = 0;
        }
        onWindowClicked: {
            if (overlayRoot.hoveredClient) {
                overlayRoot.hasSelection = true;
                let relX = Math.max(0, overlayRoot.hoveredClient.at[0] - screen.x);
                let relY = Math.max(0, overlayRoot.hoveredClient.at[1] - screen.y);
                let relW = Math.min(screen.width - relX, overlayRoot.hoveredClient.size[0]);
                let relH = Math.min(screen.height - relY, overlayRoot.hoveredClient.size[1]);
                overlayRoot.startX = relX;
                overlayRoot.startY = relY;
                overlayRoot.currX = relX + relW;
                overlayRoot.currY = relY + relH;
            } else if (ScreenshotService.clients.length > 0) {
                let first = ScreenshotService.clients[0];
                overlayRoot.hasSelection = true;
                let relX = Math.max(0, first.at[0] - screen.x);
                let relY = Math.max(0, first.at[1] - screen.y);
                let relW = Math.min(screen.width - relX, first.size[0]);
                let relH = Math.min(screen.height - relY, first.size[1]);
                overlayRoot.startX = relX;
                overlayRoot.startY = relY;
                overlayRoot.currX = relX + relW;
                overlayRoot.currY = relY + relH;
            }
        }
        onFullClicked: {
            overlayRoot.hasSelection = true;
            overlayRoot.startX = 0;
            overlayRoot.startY = 0;
            overlayRoot.currX = overlayRoot.screen.width;
            overlayRoot.currY = overlayRoot.screen.height;
        }
        onCopyClicked: {
            overlayRoot.executeNativeGrab(overlayRoot.activeX, overlayRoot.activeY, overlayRoot.activeW, overlayRoot.activeH, "copy");
        }
        onSaveClicked: {
            overlayRoot.executeNativeGrab(overlayRoot.activeX, overlayRoot.activeY, overlayRoot.activeW, overlayRoot.activeH, "save");
        }
        onEditClicked: {
            overlayRoot.executeNativeGrab(overlayRoot.activeX, overlayRoot.activeY, overlayRoot.activeW, overlayRoot.activeH, "edit");
        }
        onCancelClicked: {
            ScreenshotService.close();
        }
    }

    // Visual Flash Animation upon capture (z: 200)
    Rectangle {
        id: flashRect
        anchors.fill: parent
        color: "#ffffff"
        opacity: 0
        visible: opacity > 0
        z: 200

        SequentialAnimation {
            id: flashAnim
            NumberAnimation { target: flashRect; property: "opacity"; to: 0.65; duration: 40 }
            NumberAnimation { target: flashRect; property: "opacity"; to: 0.0; duration: 180 }
        }
    }
}
