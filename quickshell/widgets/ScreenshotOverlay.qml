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
    WlrLayershell.keyboardFocus: (ScreenshotService.isOpen && !overlayRoot.isQuickFullscreen)
        ? WlrKeyboardFocus.Exclusive
        : WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore

    visible: ScreenshotService.isOpen || closeAfterFlashTimer.running

    property bool isPointerDown: false
    property bool isDragging: false
    property bool hasSelection: false
    property real startX: 0
    property real startY: 0
    property real currX: 0
    property real currY: 0
    property var hoveredClient: null
    property bool isCapturing: false

    readonly property bool isQuickFullscreen: ScreenshotService.activeMode === "fullscreen" && !overlayRoot.hasSelection
    readonly property string scriptPath: decodeURIComponent(
        Qt.resolvedUrl("../scripts/screenshot.py").toString().replace(/^file:\/\//, "")
    )

    readonly property real selX: Math.min(startX, currX)
    readonly property real selY: Math.min(startY, currY)
    readonly property real selW: Math.abs(currX - startX)
    readonly property real selH: Math.abs(currY - startY)

    readonly property bool windowSnapEnabled: ScreenshotService.activeMode === "window"
        || (Settings?.screenshotWindowSnapping ?? true)
    readonly property bool clientSnapped: !hasSelection && !isDragging && hoveredClient !== null

    readonly property real clientRawX: hoveredClient ? (Number(hoveredClient.at[0]) - screen.x) : 0
    readonly property real clientRawY: hoveredClient ? (Number(hoveredClient.at[1]) - screen.y) : 0
    readonly property real clientRelX: Math.max(0, clientRawX)
    readonly property real clientRelY: Math.max(0, clientRawY)
    readonly property real clientRelW: hoveredClient
        ? Math.max(0, Math.min(screen.width - clientRelX, Number(hoveredClient.size[0]) - (clientRelX - clientRawX)))
        : 0
    readonly property real clientRelH: hoveredClient
        ? Math.max(0, Math.min(screen.height - clientRelY, Number(hoveredClient.size[1]) - (clientRelY - clientRawY)))
        : 0

    readonly property real activeX: hasSelection ? selX : (clientSnapped ? clientRelX : (isDragging ? selX : 0))
    readonly property real activeY: hasSelection ? selY : (clientSnapped ? clientRelY : (isDragging ? selY : 0))
    readonly property real activeW: hasSelection ? selW : (clientSnapped ? clientRelW : (isDragging ? selW : 0))
    readonly property real activeH: hasSelection ? selH : (clientSnapped ? clientRelH : (isDragging ? selH : 0))
    readonly property bool hasActiveRegion: activeW > 4 && activeH > 4

    function resetSelectionState() {
        overlayRoot.isPointerDown = false;
        overlayRoot.isDragging = false;
        overlayRoot.hasSelection = false;
        overlayRoot.hoveredClient = null;
        overlayRoot.startX = 0;
        overlayRoot.startY = 0;
        overlayRoot.currX = 0;
        overlayRoot.currY = 0;
    }

    function lockClientSelection(c) {
        if (!c || !c.at || !c.size) return;
        let rawX = Number(c.at[0]) - screen.x;
        let rawY = Number(c.at[1]) - screen.y;
        let relX = Math.max(0, rawX);
        let relY = Math.max(0, rawY);
        let relW = Math.max(0, Math.min(screen.width - relX, Number(c.size[0]) - (relX - rawX)));
        let relH = Math.max(0, Math.min(screen.height - relY, Number(c.size[1]) - (relY - rawY)));
        if (relW <= 4 || relH <= 4) return;

        overlayRoot.hoveredClient = c;
        overlayRoot.startX = relX;
        overlayRoot.startY = relY;
        overlayRoot.currX = relX + relW;
        overlayRoot.currY = relY + relH;
        overlayRoot.hasSelection = true;
    }

    function checkHoveredClient(mx: real, my: real): void {
        if (!overlayRoot.windowSnapEnabled || isDragging || hasSelection) {
            if (!hasSelection) hoveredClient = null;
            return;
        }
        let gx = screen.x + mx;
        let gy = screen.y + my;
        let list = ScreenshotService.clients || [];
        for (let i = 0; i < list.length; i++) {
            let c = list[i];
            if (!c || !c.at || !c.size) continue;
            let cx = Number(c.at[0]);
            let cy = Number(c.at[1]);
            let cw = Number(c.size[0]);
            let ch = Number(c.size[1]);
            if (gx >= cx && gx <= cx + cw && gy >= cy && gy <= cy + ch) {
                hoveredClient = c;
                return;
            }
        }
        hoveredClient = null;
    }

    Timer {
        id: pendingGrabTimer
        interval: 35
        repeat: false
        property int retries: 0
        property real grabX: 0
        property real grabY: 0
        property real grabW: 0
        property real grabH: 0
        property string action: "both"
        onTriggered: {
            if (retries > 10) {
                retries = 0;
                overlayRoot.isCapturing = false;
                ScreenshotService.close();
                return;
            }
            retries++;
            overlayRoot.executeNativeGrab(grabX, grabY, grabW, grabH, action);
        }
    }

    Timer {
        id: closeAfterFlashTimer
        interval: 180
        repeat: false
        onTriggered: ScreenshotService.close()
    }

    function runPostCaptureAction(act: string, filePath: string): void {
        let notifyFlag = (Settings?.screenshotNotify ?? true) ? "1" : "0";
        let escapedPath = "'" + filePath.replace(/'/g, "'\\''") + "'";
        let escapedScript = "'" + overlayRoot.scriptPath.replace(/'/g, "'\\''") + "'";

        // run screenshot.py if present, otherwise fall back to native wl-copy / swappy / notify-send
        let cmd = "if [ -f " + escapedScript + " ]; then "
            + "python3 " + escapedScript + " post " + act + " " + escapedPath + " " + notifyFlag + "; "
            + "else "
            + ((act === "copy" || act === "both") ? ("wl-copy --type image/png < " + escapedPath + " 2>/dev/null; ") : "")
            + (act === "edit" ? ("(swappy -f " + escapedPath + " || satty -f " + escapedPath + ") 2>/dev/null & ") : "")
            + (notifyFlag === "1" ? ("notify-send -a 'Screen Capture' -i " + escapedPath + " 'Screenshot Captured' " + escapedPath + " 2>/dev/null; ") : "")
            + (act === "copy" ? ("rm -f " + escapedPath + "; ") : "")
            + "fi";

        Quickshell.execDetached(["sh", "-c", cmd]);
    }

    function executeNativeGrab(x: real, y: real, w: real, h: real, action: string): void {
        if (overlayRoot.isCapturing && !pendingGrabTimer.running) return;

        let grabX = Math.max(0, Math.round(x));
        let grabY = Math.max(0, Math.round(y));
        let grabW = Math.min(screen.width - grabX, Math.round(w));
        let grabH = Math.min(screen.height - grabY, Math.round(h));

        if (grabW <= 2 || grabH <= 2) {
            grabX = 0;
            grabY = 0;
            grabW = screen.width;
            grabH = screen.height;
        }

        if (ScreenshotService.activeMode === "record" || action === "record") {
            overlayRoot.isCapturing = false;
            ScreenshotService.close();
            if (typeof ScreenRecService !== "undefined" && ScreenRecService?.startRecordingRegion) {
                ScreenRecService.startRecordingRegion(overlayRoot.screen, grabX, grabY, grabW, grabH);
            }
            return;
        }

        overlayRoot.isCapturing = true;

        if (!frozenScreencopy.hasContent) {
            frozenScreencopy.captureFrame();
            pendingGrabTimer.grabX = grabX;
            pendingGrabTimer.grabY = grabY;
            pendingGrabTimer.grabW = grabW;
            pendingGrabTimer.grabH = grabH;
            pendingGrabTimer.action = action;
            pendingGrabTimer.restart();
            return;
        }

        pendingGrabTimer.retries = 0;
        let act = action || Settings?.screenshotDefaultAction || "both";

        cropExporter.x = grabX;
        cropExporter.y = grabY;
        cropExporter.width = grabW;
        cropExporter.height = grabH;
        frozenScreencopy.x = -grabX;
        frozenScreencopy.y = -grabY;

        let rawDir = Settings?.screenshotDir || "~/Pictures/Screenshots";
        let dir = rawDir.replace(/^~/, Quickshell.env("HOME") || "");
        let scrSuffix = overlayRoot.screen.name ? ("_" + overlayRoot.screen.name) : "";
        let timestamp = Qt.formatDateTime(new Date(), "yyyy-MM-dd_hh-mm-ss") + scrSuffix;
        let filePath = (act === "copy" ? "/tmp" : dir) + "/Screenshot_" + timestamp + ".png";

        cropExporter.grabToImage(function(result) {
            cropExporter.x = 0;
            cropExporter.y = 0;
            cropExporter.width = overlayRoot.screen.width;
            cropExporter.height = overlayRoot.screen.height;
            frozenScreencopy.x = 0;
            frozenScreencopy.y = 0;
            overlayRoot.isCapturing = false;

            if (!result) {
                ScreenshotService.close();
                return;
            }

            let saved = result.saveToFile(filePath);
            if (!saved) {
                filePath = "/tmp/Screenshot_" + timestamp + ".png";
                result.saveToFile(filePath);
            }

            overlayRoot.runPostCaptureAction(act, filePath);

            if (Settings?.screenshotFlash ?? true) {
                flashAnim.restart();
                closeAfterFlashTimer.restart();
            } else {
                ScreenshotService.close();
            }
        });
    }

    Connections {
        target: ScreenshotService
        function onIsOpenChanged() {
            if (!ScreenshotService.isOpen) {
                overlayRoot.resetSelectionState();
                overlayRoot.isCapturing = false;
                pendingGrabTimer.stop();
                pendingGrabTimer.retries = 0;
            } else {
                let rawDir = Settings?.screenshotDir || "~/Pictures/Screenshots";
                let dir = rawDir.replace(/^~/, Quickshell.env("HOME") || "");
                Quickshell.execDetached(["mkdir", "-p", dir]);

                actionsBar.randomizeQuote();
                frozenScreencopy.captureFrame();
                keyHandler.forceActiveFocus();
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

    // off-overlay screencopy source used for clean cropping
    Item {
        id: cropExporter
        x: 0
        y: 0
        width: overlayRoot.screen.width
        height: overlayRoot.screen.height
        clip: true
        z: 0

        ScreencopyView {
            id: frozenScreencopy
            x: 0
            y: 0
            width: overlayRoot.screen.width
            height: overlayRoot.screen.height
            captureSource: (ScreenshotService.isOpen || overlayRoot.isCapturing) ? overlayRoot.screen : null
            live: !(Settings?.screenshotFreeze ?? true)
            visible: (Settings?.screenshotFreeze ?? true) || overlayRoot.isCapturing
        }
    }

    Item {
        id: keyHandler
        anchors.fill: parent
        focus: ScreenshotService.isOpen
        z: 1

        Keys.onEscapePressed: {
            if (overlayRoot.hasSelection) {
                overlayRoot.resetSelectionState();
            } else {
                ScreenshotService.close();
            }
        }
        Keys.onReturnPressed: {
            let act = Settings?.screenshotDefaultAction || "both";
            if (overlayRoot.hasActiveRegion) {
                overlayRoot.executeNativeGrab(overlayRoot.activeX, overlayRoot.activeY, overlayRoot.activeW, overlayRoot.activeH, act);
            } else {
                overlayRoot.executeNativeGrab(0, 0, overlayRoot.screen.width, overlayRoot.screen.height, act);
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

    // full-screen dim when no region is active (hidden during instant fullscreen capture)
    Rectangle {
        anchors.fill: parent
        color: Theme.alpha("#000000", Settings?.screenshotDimOpacity ?? 0.45)
        visible: !overlayRoot.hasActiveRegion && !overlayRoot.isQuickFullscreen && !closeAfterFlashTimer.running
        z: 2
    }

    // 4-part dim mask surrounding the active region
    Item {
        anchors.fill: parent
        visible: overlayRoot.hasActiveRegion && !overlayRoot.isQuickFullscreen && !closeAfterFlashTimer.running
        z: 2

        readonly property color dimColor: Theme.alpha("#000000", Settings?.screenshotDimOpacity ?? 0.45)

        Rectangle {
            x: 0
            y: 0
            width: overlayRoot.width
            height: Math.max(0, overlayRoot.activeY)
            color: parent.dimColor
        }
        Rectangle {
            x: 0
            y: overlayRoot.activeY + overlayRoot.activeH
            width: overlayRoot.width
            height: Math.max(0, overlayRoot.height - (overlayRoot.activeY + overlayRoot.activeH))
            color: parent.dimColor
        }
        Rectangle {
            x: 0
            y: overlayRoot.activeY
            width: Math.max(0, overlayRoot.activeX)
            height: overlayRoot.activeH
            color: parent.dimColor
        }
        Rectangle {
            x: overlayRoot.activeX + overlayRoot.activeW
            y: overlayRoot.activeY
            width: Math.max(0, overlayRoot.width - (overlayRoot.activeX + overlayRoot.activeW))
            height: overlayRoot.activeH
            color: parent.dimColor
        }
    }

    // alignment crosshair when hovering in region mode
    Item {
        anchors.fill: parent
        visible: (Settings?.screenshotShowCrosshair ?? true)
            && !overlayRoot.hasSelection
            && !overlayRoot.isDragging
            && !overlayRoot.clientSnapped
            && !overlayRoot.isQuickFullscreen
            && !closeAfterFlashTimer.running
        z: 3

        Rectangle {
            x: 0
            y: mouseCapture.mouseY
            width: parent.width
            height: 1
            color: Theme.alpha(Theme.primary, 0.4)
        }
        Rectangle {
            x: mouseCapture.mouseX
            y: 0
            width: 1
            height: parent.height
            color: Theme.alpha(Theme.primary, 0.4)
        }
    }

    MouseArea {
        id: mouseCapture
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: overlayRoot.clientSnapped ? Qt.PointingHandCursor : Qt.CrossCursor
        visible: !overlayRoot.isQuickFullscreen && !closeAfterFlashTimer.running
        z: 5

        function isOverActions(mx: real, my: real): bool {
            if (!actionsBar.visible) return false;
            let pad = 8;
            let actW = actionsBar.width > 0 ? actionsBar.width : actionsBar.implicitWidth;
            let actH = actionsBar.height > 0 ? actionsBar.height : actionsBar.implicitHeight;
            let bx = actionsBar.x - pad;
            let by = actionsBar.y - 32;
            let bw = actW + pad * 2;
            let bh = actH + 32 + pad * 2;
            return (mx >= bx && mx <= bx + bw && my >= by && my <= by + bh);
        }

        onPressed: (mouse) => {
            keyHandler.forceActiveFocus();

            if (mouse.button === Qt.RightButton) {
                if (overlayRoot.hasSelection || overlayRoot.isDragging) {
                    overlayRoot.resetSelectionState();
                    overlayRoot.checkHoveredClient(mouse.x, mouse.y);
                } else {
                    ScreenshotService.close();
                }
                return;
            }

            if (isOverActions(mouse.x, mouse.y)) {
                mouse.accepted = false;
                return;
            }

            overlayRoot.isPointerDown = true;
            overlayRoot.isDragging = false;
            overlayRoot.startX = mouse.x;
            overlayRoot.startY = mouse.y;
            overlayRoot.currX = mouse.x;
            overlayRoot.currY = mouse.y;
        }

        onPositionChanged: (mouse) => {
            if (overlayRoot.isPointerDown) {
                let dx = Math.abs(mouse.x - overlayRoot.startX);
                let dy = Math.abs(mouse.y - overlayRoot.startY);
                if (!overlayRoot.isDragging && (dx > 5 || dy > 5)) {
                    overlayRoot.isDragging = true;
                    overlayRoot.hasSelection = false;
                    overlayRoot.hoveredClient = null;
                }
                if (overlayRoot.isDragging) {
                    overlayRoot.currX = mouse.x;
                    overlayRoot.currY = mouse.y;
                }
            } else if (!isOverActions(mouse.x, mouse.y)) {
                overlayRoot.checkHoveredClient(mouse.x, mouse.y);
            }
        }

        onReleased: (mouse) => {
            if (mouse.button === Qt.RightButton) return;
            overlayRoot.isPointerDown = false;

            if (overlayRoot.isDragging) {
                overlayRoot.isDragging = false;
                overlayRoot.hasSelection = (overlayRoot.selW > 12 && overlayRoot.selH > 12);
                return;
            }

            if (isOverActions(mouse.x, mouse.y)) {
                mouse.accepted = false;
                return;
            }

            // single click without dragging: lock onto hovered window, or clear existing selection
            if (overlayRoot.hoveredClient && !overlayRoot.hasSelection) {
                overlayRoot.lockClientSelection(overlayRoot.hoveredClient);
            } else if (overlayRoot.hasSelection) {
                overlayRoot.resetSelectionState();
                overlayRoot.checkHoveredClient(mouse.x, mouse.y);
            }
        }

        onDoubleClicked: (mouse) => {
            if (mouse.button === Qt.LeftButton && overlayRoot.hasActiveRegion) {
                overlayRoot.executeNativeGrab(
                    overlayRoot.activeX,
                    overlayRoot.activeY,
                    overlayRoot.activeW,
                    overlayRoot.activeH,
                    Settings?.screenshotDefaultAction || "both"
                );
            }
        }
    }

    // active selection frame + rule-of-thirds guides while dragging + corner handles
    Rectangle {
        id: selectionBox
        visible: overlayRoot.hasActiveRegion && !overlayRoot.isQuickFullscreen && !closeAfterFlashTimer.running
        x: overlayRoot.activeX
        y: overlayRoot.activeY
        width: overlayRoot.activeW
        height: overlayRoot.activeH
        color: "transparent"
        radius: Settings?.screenshotBorderRadius ?? 0
        border.width: Settings?.screenshotBorderWidth ?? 2
        border.color: ScreenshotService.activeMode === "record" ? (Theme.error ?? "#ff5449") : Theme.primary
        z: 10

        // subtle rule-of-thirds grid while actively dragging a region
        Item {
            anchors.fill: parent
            visible: overlayRoot.isDragging && parent.width > 60 && parent.height > 60

            Rectangle { x: parent.width / 3; y: 0; width: 1; height: parent.height; color: Theme.alpha(Theme.primary, 0.25) }
            Rectangle { x: (parent.width * 2) / 3; y: 0; width: 1; height: parent.height; color: Theme.alpha(Theme.primary, 0.25) }
            Rectangle { x: 0; y: parent.height / 3; width: parent.width; height: 1; color: Theme.alpha(Theme.primary, 0.25) }
            Rectangle { x: 0; y: (parent.height * 2) / 3; width: parent.width; height: 1; color: Theme.alpha(Theme.primary, 0.25) }
        }

        Item {
            anchors.fill: parent
            visible: Settings?.screenshotShowHandles ?? true

            readonly property color handleColor: ScreenshotService.activeMode === "record"
                ? (Theme.error ?? "#ff5449")
                : Theme.primary

            Rectangle { x: -3; y: -3; width: 8; height: 8; radius: 2; color: parent.handleColor }
            Rectangle { x: parent.width - 5; y: -3; width: 8; height: 8; radius: 2; color: parent.handleColor }
            Rectangle { x: -3; y: parent.height - 5; width: 8; height: 8; radius: 2; color: parent.handleColor }
            Rectangle { x: parent.width - 5; y: parent.height - 5; width: 8; height: 8; radius: 2; color: parent.handleColor }
        }
    }

    // dimension & window title badge
    Rectangle {
        id: dimBadge
        visible: (Settings?.screenshotShowBadge ?? true)
            && overlayRoot.hasActiveRegion
            && !overlayRoot.isQuickFullscreen
            && !closeAfterFlashTimer.running
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
                visible: overlayRoot.hoveredClient !== null && Boolean(overlayRoot.hoveredClient.class || overlayRoot.hoveredClient.title)
                text: overlayRoot.hoveredClient ? (overlayRoot.hoveredClient.class || overlayRoot.hoveredClient.title) : ""
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeXs
                font.weight: Font.DemiBold
                color: Theme.primary
                elide: Text.ElideRight
                Layout.maximumWidth: 180
            }

            Text {
                text: Math.round(overlayRoot.activeW) + " × " + Math.round(overlayRoot.activeH)
                font.family: Theme.fontMono
                font.pixelSize: Theme.fontSizeXs
                color: Theme.on_surface
            }
        }
    }

    ScreenshotActions {
        id: actionsBar
        visible: !overlayRoot.isDragging && !overlayRoot.isQuickFullscreen && !closeAfterFlashTimer.running
        isRecordMode: ScreenshotService.activeMode === "record"
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
            ScreenshotService.activeMode = "region";
            overlayRoot.resetSelectionState();
        }
        onWindowClicked: {
            ScreenshotService.activeMode = "window";
            let clients = ScreenshotService.clients || [];
            if (overlayRoot.hoveredClient) {
                overlayRoot.lockClientSelection(overlayRoot.hoveredClient);
            } else if (clients.length > 0) {
                overlayRoot.lockClientSelection(clients[0]);
            }
        }
        onFullClicked: {
            ScreenshotService.activeMode = "fullscreen";
            overlayRoot.hoveredClient = null;
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
        onRecordClicked: {
            overlayRoot.executeNativeGrab(overlayRoot.activeX, overlayRoot.activeY, overlayRoot.activeW, overlayRoot.activeH, "record");
        }
        onCancelClicked: {
            ScreenshotService.close();
        }
    }

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
            NumberAnimation { target: flashRect; property: "opacity"; to: 0.0; duration: 140 }
        }
    }
}
