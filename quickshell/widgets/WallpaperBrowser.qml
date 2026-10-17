import QtQuick
import QtQuick.Layouts
import ".."
import "../controls"
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

Rectangle {
    id: root
    implicitWidth: (Theme?.isVertical ?? false) ? ((Theme?.barHeight ?? 48) - 8) : (wpRow.implicitWidth + 24)
    implicitHeight: (Theme?.barHeight ?? 48) - 8
    radius: Theme?.radiusPill ?? 999
    color: popup.open ? Theme.primary_overlay : (wpMouse.containsMouse ? Theme.pillHover : Theme.pillBg)
    border.color: Theme?.pillBorder ?? "transparent"
    border.width: (Theme?.pillBorder ?? "transparent") === "transparent" ? 0 : 1
    visible: Settings?.showWallpaper ?? true

    Behavior on color { ColorAnimation { duration: Theme?.animFast ?? 150 } }
    Behavior on border.color { ColorAnimation { duration: Theme?.animFast ?? 150 } }

    property var barScreen: null
    property var barMonitor: null
    property string activeTab: "local"
    property string liveSubTab: "local"
    property string localCategoryFilter: "all"
    property string localSubCategoryFilter: "all"
    property string localSearchQuery: ""
    property string onlineQuery: ""
    property string onlineSorting: "date_added"
    property int onlinePage: 1

    // resolve resolution from the current bar's monitor first before falling back to primary screen
    readonly property string nativeRes: {
        if (root.barScreen?.width && root.barScreen?.height) {
            return root.barScreen.width + "x" + root.barScreen.height;
        }
        if (root.barMonitor?.width && root.barMonitor?.height) {
            return root.barMonitor.width + "x" + root.barMonitor.height;
        }
        if (Quickshell?.screens && Quickshell.screens.length > 0) {
            return Quickshell.screens[0].width + "x" + Quickshell.screens[0].height;
        }
        return "1920x1080";
    }

    property string onlineResolution: nativeRes
    property bool isOnlineLoading: false
    property bool isBatchDownloading: false
    property string batchStatusText: ""
    property string liveSearchQuery: ""

    property var allLocalWallpapers: []
    property var onlineWallpapers: []
    property var onlineLiveWallpapers: []

    readonly property string wpScriptPath: decodeURIComponent(
        Qt.resolvedUrl("../scripts/wallpaper.py").toString().replace(/^file:\/\//, "")
    )

    readonly property var localLiveWallpapers: {
        let res = [];
        let items = root.allLocalWallpapers || [];
        for (let i = 0; i < items.length; i++) {
            let item = items[i];
            if (item && (item.isVideo || item.isGif || item.isLive || ["gif", "mp4", "webm"].indexOf(item.ext) !== -1)) {
                res.push(item);
            }
        }
        return res;
    }

    readonly property var activeLiveList: root.liveSubTab === "local" ? root.localLiveWallpapers : root.onlineLiveWallpapers

    FileView {
        id: liveWpFile
        path: "/tmp/qs_live_wallpapers.json"
        watchChanges: true
        printErrors: false
        onFileChanged: {
            reload();
            root.loadLiveFromJson(text());
        }
    }

    Timer {
        id: liveParseTimer
        interval: 300
        repeat: false
        onTriggered: {
            liveWpFile.reload();
            root.loadLiveFromJson(liveWpFile.text());
        }
    }

    Timer {
        id: batchStatusResetTimer
        interval: 4000
        onTriggered: root.batchStatusText = ""
    }

    Process {
        id: batchDownloadProc
        command: []
        running: false
        onExited: (code) => {
            root.isBatchDownloading = false;
            root.batchStatusText = (code === 0) ? "saved to ~/.wallpapers/" : "download failed";
            batchStatusResetTimer.restart();
            reloadLocalWallpapers();
        }
    }

    Connections {
        target: WallpaperService ?? null
        ignoreUnknownSignals: true
        function onWallpapersUpdated() {
            root.parseLocalWallpapers();
        }
    }

    HyprlandFocusGrab {
        id: hyprFocusGrab
        active: popup.open
        windows: {
            let targets = [];
            if (popup) targets.push(popup);
            if (popup?.window) targets.push(popup.window);
            let barWin = root.QsWindow?.window;
            if (barWin && targets.indexOf(barWin) === -1) targets.push(barWin);
            return targets;
        }
        onCleared: popup.open = false
    }

    function syncKeyboardFocus(openState) {
        if (popup) {
            try {
                if (popup.focusable !== undefined) popup.focusable = openState;
                if (popup.grabFocus !== undefined) popup.grabFocus = openState;
                if (popup.WlrLayershell) {
                    popup.WlrLayershell.keyboardFocus = openState ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None;
                }
            } catch (e) {}
        }
        try {
            let win = root.QsWindow?.window;
            if (win) {
                if (win.focusable !== undefined) win.focusable = openState;
                if (win.WlrLayershell) {
                    win.WlrLayershell.keyboardFocus = openState ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None;
                }
            }
        } catch (e) {}
    }

    function focusActiveInput() {
        if (!popup.open) return;
        Qt.callLater(() => {
            if (root.activeTab === "local") localSearchField.focusInput();
            else if (root.activeTab === "online") onlineSearchField.focusInput();
            else if (root.activeTab === "live") liveUrlField.focusInput();
        });
    }

    Connections {
        target: popup
        function onOpenChanged() {
            root.syncKeyboardFocus(popup.open);
            if (popup.open) root.focusActiveInput();
        }
    }

    onActiveTabChanged: root.focusActiveInput()

    Component.onCompleted: {
        parseLocalWallpapers();
        reloadLocalWallpapers();
    }

    function syncAnchor() {
        const p = root.mapToItem(null, 0, 0);
        if (p) {
            popup.targetRelativeX = p.x + (root.width / 2);
            popup.targetRelativeY = p.y + (root.height / 2);
        }
    }

    function isTargetMonitorActive() {
        return !root.barScreen
            || Quickshell.screens.length <= 1
            || (root.barMonitor && Hyprland.focusedMonitor && root.barMonitor.id === Hyprland.focusedMonitor.id);
    }

    function rollRandomWallpaper() {
        let cat = "all";
        if (root.localCategoryFilter !== "all") {
            cat = root.localCategoryFilter;
            if (root.localSubCategoryFilter !== "all") {
                cat = root.localCategoryFilter + "/" + root.localSubCategoryFilter;
            }
        }
        if (WallpaperService?.applyRandomWallpaper) {
            WallpaperService.applyRandomWallpaper(cat);
        }
    }

    function fetchLiveWallpapers(q) {
        Quickshell.execDetached(["python3", wpScriptPath, "fetch-live", q || ""]);
        liveParseTimer.restart();
    }

    function loadLiveFromJson(raw) {
        try {
            if (!raw || raw.trim() === "") {
                root.onlineLiveWallpapers = [];
                return;
            }
            root.onlineLiveWallpapers = JSON.parse(raw) || [];
        } catch (e) {
            root.onlineLiveWallpapers = [];
        }
    }

    function parseLocalWallpapers() {
        if (!WallpaperService?.localWpListFile) return;
        WallpaperService.localWpListFile.reload();
        let str = WallpaperService.localWpListFile.text();
        if (!str || str.trim() === "") return;
        try {
            root.allLocalWallpapers = JSON.parse(str) || [];
        } catch (e) {}
    }

    function reloadLocalWallpapers() {
        if (WallpaperService?.scanLocalWallpapers) {
            WallpaperService.scanLocalWallpapers();
        }
    }

    function fetchWallhaven(query, sort, page, resolution) {
        root.isOnlineLoading = true;
        let req = new XMLHttpRequest();
        let q = (query !== undefined && query !== null) ? query.trim() : root.onlineQuery;
        let s = sort || root.onlineSorting || "date_added";
        let p = page || 1;
        let r = (resolution !== undefined && resolution !== null) ? resolution.trim() : root.onlineResolution;

        r = r.replace(/\s*[\*xX]\s*/g, "x").replace(/\s+/g, "");

        root.onlineQuery = q;
        root.onlineSorting = s;
        root.onlinePage = p;
        root.onlineResolution = r;

        let params = [];
        if (q !== "") params.push("q=" + encodeURIComponent(q));
        params.push("sorting=" + encodeURIComponent(s));
        params.push("page=" + p);
        params.push("categories=111");
        params.push("purity=100");

        if (r !== "" && r.toLowerCase() !== "any") {
            params.push("resolutions=" + encodeURIComponent(r));
        }

        req.open("GET", "https://wallhaven.cc/api/v1/search?" + params.join("&"));
        req.timeout = 10000;
        req.ontimeout = () => { root.isOnlineLoading = false; };
        req.onerror = () => { root.isOnlineLoading = false; };
        req.onreadystatechange = () => {
            if (req.readyState === XMLHttpRequest.DONE) {
                root.isOnlineLoading = false;
                if (req.status === 200) {
                    try {
                        let data = JSON.parse(req.responseText)?.data ?? [];
                        let parsed = [];
                        for (let i = 0; i < data.length; i++) {
                            parsed.push({
                                thumbUrl: data[i].thumbs?.small ?? "",
                                fullUrl: data[i].path ?? "",
                                id: String(data[i].id ?? ""),
                                resolution: data[i].resolution || "",
                                fileType: (data[i].file_type || "").replace("image/", "").toUpperCase(),
                                favorites: data[i].favorites || 0
                            });
                        }
                        root.onlineWallpapers = parsed;
                    } catch (e) {}
                }
            }
        };
        req.send();
    }

    function downloadUrls(urls) {
        if (root.isBatchDownloading || !urls || urls.length === 0) return;
        root.isBatchDownloading = true;
        root.batchStatusText = urls.length === 1
            ? "downloading wallpaper..."
            : ("downloading " + urls.length + " wallpapers...");

        if (WallpaperService?.batchDownload) {
            WallpaperService.batchDownload(urls);
            root.isBatchDownloading = false;
            batchStatusResetTimer.restart();
        } else {
            batchDownloadProc.command = ["python3", wpScriptPath, "batch-download", JSON.stringify(urls)];
            batchDownloadProc.running = true;
        }
    }

    function downloadCurrentSection() {
        let urls = [];
        if (root.activeTab === "online") {
            for (let i = 0; i < root.onlineWallpapers.length; i++) {
                let u = root.onlineWallpapers[i]?.fullUrl;
                if (u) urls.push(u);
            }
        } else if (root.activeTab === "live") {
            let list = root.activeLiveList;
            for (let i = 0; i < list.length; i++) {
                let u = list[i]?.url || list[i]?.path;
                if (u && (u.startsWith("http://") || u.startsWith("https://"))) urls.push(u);
            }
        }
        downloadUrls(urls);
    }

    // reusable UI components to keep tab layouts readable

    component GroupLabel: Text {
        font.family: Theme?.fontFamily ?? "sans-serif"
        font.pixelSize: Theme?.fontSizeXs ?? 10
        font.weight: Font.DemiBold
        color: Theme.on_surface_variant
    }

    component SettingCard: Rectangle {
        id: sCard
        property string title: ""
        property string icon: ""
        property string badge: ""
        default property alias body: cardCol.data

        Layout.fillWidth: true
        implicitHeight: cardCol.implicitHeight + 24
        radius: Theme?.radiusMd ?? 10
        color: Theme.cardBg
        border.color: Theme.cardBorder
        border.width: 1

        ColumnLayout {
            id: cardCol
            anchors.fill: parent
            anchors.margins: 12
            spacing: 10

            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                visible: sCard.title !== ""

                Text {
                    visible: sCard.icon !== ""
                    text: sCard.icon
                    font.family: Theme?.fontIcon ?? "sans-serif"
                    font.pixelSize: Theme?.fontSizeSm ?? 12
                    color: Theme.primary
                }

                Text {
                    text: sCard.title
                    font.family: Theme?.fontFamily ?? "sans-serif"
                    font.pixelSize: Theme?.fontSizeSm ?? 12
                    font.weight: Font.Bold
                    color: Theme.on_surface
                }

                Item { Layout.fillWidth: true }

                Rectangle {
                    visible: sCard.badge !== ""
                    height: 20
                    implicitWidth: cardBadgeText.implicitWidth + 14
                    radius: Theme?.radiusPill ?? 999
                    color: Theme.primary_overlay
                    border.color: Theme.alpha(Theme.primary, 0.35)
                    border.width: 1

                    Text {
                        id: cardBadgeText
                        anchors.centerIn: parent
                        text: sCard.badge
                        font.family: Theme?.fontMono ?? "monospace"
                        font.pixelSize: (Theme?.fontSizeXs ?? 10) - 1
                        font.weight: Font.Bold
                        color: Theme.primary
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Theme.widgetBorder
                visible: sCard.title !== ""
            }
        }
    }

    component SearchField: Rectangle {
        id: fieldRoot
        property alias text: inputItem.text
        property string placeholder: ""
        property string icon: Theme?.iconSearch ?? "󰍉"
        property string badgeText: ""
        property bool monoFont: false
        signal submitted(string value)
        signal cleared()

        function focusInput() {
            inputItem.forceActiveFocus();
        }

        Layout.fillWidth: true
        Layout.preferredHeight: 36
        color: Theme.cardBg
        radius: Theme?.radiusMd ?? 10
        border.color: inputItem.activeFocus ? Theme.primary : Theme.cardBorder
        border.width: 1

        Behavior on border.color { ColorAnimation { duration: Theme?.animFast ?? 150 } }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 8
            spacing: 8

            Text {
                text: fieldRoot.icon
                font.family: Theme?.fontIcon ?? "sans-serif"
                font.pixelSize: Theme?.fontSizeSm ?? 12
                color: inputItem.activeFocus ? Theme.primary : Theme.on_surface_variant
            }

            TextInput {
                id: inputItem
                Layout.fillWidth: true
                Layout.fillHeight: true
                verticalAlignment: TextInput.AlignVCenter
                font.family: fieldRoot.monoFont ? (Theme?.fontMono ?? "monospace") : (Theme?.fontFamily ?? "sans-serif")
                font.pixelSize: Theme?.fontSizeSm ?? 12
                color: Theme.on_surface
                selectByMouse: true
                activeFocusOnTab: true
                clip: true

                Text {
                    text: fieldRoot.placeholder
                    font.family: Theme?.fontFamily ?? "sans-serif"
                    font.pixelSize: Theme?.fontSizeSm ?? 12
                    color: Theme.on_surface_disabled
                    visible: inputItem.text.length === 0 && !inputItem.activeFocus
                    anchors.verticalCenter: parent.verticalCenter
                }

                Keys.onPressed: (event) => {
                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        fieldRoot.submitted(inputItem.text);
                        event.accepted = true;
                    }
                }
            }

            Rectangle {
                visible: fieldRoot.badgeText !== ""
                height: 20
                implicitWidth: badgeLbl.implicitWidth + 12
                radius: Theme?.radiusPill ?? 999
                color: Theme.surface_container_high

                Text {
                    id: badgeLbl
                    anchors.centerIn: parent
                    text: fieldRoot.badgeText
                    font.family: Theme?.fontMono ?? "monospace"
                    font.pixelSize: (Theme?.fontSizeXs ?? 10) - 1
                    color: Theme.on_surface_variant
                }
            }

            IconButton {
                icon: Theme?.iconClose ?? "✕"
                iconSize: 10
                tooltip: "clear"
                visible: inputItem.text.length > 0
                onClicked: {
                    inputItem.text = "";
                    fieldRoot.cleared();
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.IBeamCursor
            propagateComposedEvents: true
            onPressed: (mouse) => {
                inputItem.forceActiveFocus();
                mouse.accepted = false;
            }
        }
    }

    component Chip: Rectangle {
        id: chipRoot
        property bool selected: false
        property string label: ""
        property string icon: ""
        property real chipHeight: 26
        property real chipRadius: Theme?.radiusPill ?? 999
        property int fontSize: Theme?.fontSizeXs ?? 10
        property bool fillWidth: false
        property color activeBg: Theme.primary_overlay
        property color inactiveBg: "transparent"
        property color activeFg: Theme.primary
        property color inactiveFg: Theme.on_surface_variant
        signal clicked()

        Layout.fillWidth: fillWidth
        Layout.preferredHeight: chipHeight
        Layout.preferredWidth: fillWidth ? -1 : (chipRow.implicitWidth + 20)
        radius: chipRadius
        color: selected ? activeBg : (chipMouse.containsMouse ? Theme.surface_container_high : inactiveBg)
        border.color: selected ? Theme.primary : (chipMouse.containsMouse ? Theme.outline : (Theme.outline_variant ?? Theme.widgetBorder))
        border.width: 1

        Behavior on color { ColorAnimation { duration: Theme?.animFast ?? 150 } }
        Behavior on border.color { ColorAnimation { duration: Theme?.animFast ?? 150 } }

        RowLayout {
            id: chipRow
            anchors.centerIn: parent
            spacing: 5

            Text {
                visible: chipRoot.icon !== ""
                text: chipRoot.icon
                font.family: Theme?.fontIcon ?? "sans-serif"
                font.pixelSize: chipRoot.fontSize
                color: chipRoot.selected ? chipRoot.activeFg : chipRoot.inactiveFg
            }

            Text {
                text: chipRoot.label
                font.family: Theme?.fontFamily ?? "sans-serif"
                font.pixelSize: chipRoot.fontSize
                font.weight: chipRoot.selected ? Font.DemiBold : Font.Normal
                color: chipRoot.selected ? chipRoot.activeFg : chipRoot.inactiveFg
            }
        }

        MouseArea {
            id: chipMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: chipRoot.clicked()
        }
    }

    component EmptyState: Item {
                    id: emptyRoot
                    property string icon: Theme?.iconFolder ?? "󰉋"
                    property string message: "no wallpapers found"
                    property bool loading: false
            
                    Layout.fillWidth: true
                    Layout.fillHeight: true
            
                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 8
            
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: emptyRoot.loading ? (Theme?.iconRefresh ?? "↺") : emptyRoot.icon
                            font.family: Theme?.fontIcon ?? "sans-serif"
                            font.pixelSize: 32
                            color: emptyRoot.loading ? Theme.primary : Theme.on_surface_disabled
            
                            RotationAnimator on rotation {
                                running: emptyRoot.loading
                                loops: Animation.Infinite
                                from: 0
                                to: 360
                                duration: 1000
                            }
                        }
            
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: emptyRoot.message
                            font.family: Theme?.fontFamily ?? "sans-serif"
                            font.pixelSize: Theme?.fontSizeSm ?? 12
                            color: Theme.on_surface_variant
                            horizontalAlignment: Text.AlignHCenter
                            lineHeight: 1.4
                        }
                    }
                }

        component WallpaperCard: Rectangle {
        id: cardRoot
        property string thumbUrl: ""
        property string titleText: ""
        property string badgeText: ""
        property string tagText: ""
        property bool tagAccent: false
        property bool isSelected: false
        property bool allowDownload: false
        signal applyRequested()
        signal downloadRequested()

        color: "transparent"

        Rectangle {
            id: innerCard
            anchors.fill: parent
            anchors.margins: 4
            color: Theme.cardBg
            radius: Theme?.radiusMd ?? 10
            clip: true
            border.color: cardRoot.isSelected ? Theme.primary : (cardMouse.containsMouse ? Theme.primary : Theme.cardBorder)
            border.width: cardRoot.isSelected ? 2 : 1

            Behavior on border.color { ColorAnimation { duration: Theme?.animFast ?? 150 } }

            Image {
                anchors.fill: parent
                source: (cardRoot.thumbUrl.startsWith("http://") || cardRoot.thumbUrl.startsWith("https://") || cardRoot.thumbUrl.startsWith("file://"))
                    ? cardRoot.thumbUrl
                    : (cardRoot.thumbUrl !== "" ? ("file://" + cardRoot.thumbUrl) : "")
                sourceSize: Qt.size(280, 180)
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
            }

            Rectangle {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                height: 40
                z: 1
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "transparent" }
                    GradientStop { position: 1.0; color: Theme.alpha(Theme.surface, 0.90) }
                }
            }

            Rectangle {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.margins: 8
                height: 20
                width: bText.implicitWidth + 12
                radius: Theme?.radiusPill ?? 999
                color: Theme.alpha(Theme.surface, 0.82)
                border.color: Theme.alpha(Theme.outline, 0.25)
                border.width: 1
                visible: cardRoot.badgeText !== ""
                z: 2

                Text {
                    id: bText
                    anchors.centerIn: parent
                    text: cardRoot.badgeText
                    font.family: Theme?.fontFamily ?? "sans-serif"
                    font.pixelSize: (Theme?.fontSizeXs ?? 10) - 1
                    font.weight: Font.Medium
                    color: Theme.on_surface
                }
            }

            Row {
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.margins: 8
                spacing: 6
                z: 2

                Rectangle {
                    height: 20
                    width: tText.implicitWidth + 12
                    radius: Theme?.radiusPill ?? 999
                    color: cardRoot.tagAccent ? Theme.primary : Theme.alpha(Theme.surface, 0.82)
                    border.color: cardRoot.tagAccent ? "transparent" : Theme.alpha(Theme.outline, 0.25)
                    border.width: 1
                    visible: cardRoot.tagText !== ""

                    Text {
                        id: tText
                        anchors.centerIn: parent
                        text: cardRoot.tagText
                        font.family: Theme?.fontMono ?? "monospace"
                        font.pixelSize: (Theme?.fontSizeXs ?? 10) - 1
                        font.weight: Font.Bold
                        color: cardRoot.tagAccent ? (Theme.on_primary ?? "#ffffff") : Theme.on_surface_variant
                    }
                }

                Rectangle {
                    height: 20
                    width: 20
                    radius: 10
                    color: Theme.primary
                    visible: cardRoot.isSelected

                    Text {
                        anchors.centerIn: parent
                        text: Theme?.iconCheck ?? "✓"
                        font.family: Theme?.fontIcon ?? "sans-serif"
                        font.pixelSize: 10
                        color: Theme.on_primary ?? "#ffffff"
                    }
                }
            }

            MouseArea {
                id: cardMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: cardRoot.applyRequested()
            }

            RowLayout {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: 8
                spacing: 6
                z: 3

                Text {
                    Layout.fillWidth: true
                    text: cardRoot.titleText !== "" ? cardRoot.titleText : "click to set"
                    font.family: Theme?.fontFamily ?? "sans-serif"
                    font.pixelSize: Theme?.fontSizeXs ?? 10
                    font.weight: Font.Medium
                    color: Theme.on_surface
                    elide: Text.ElideRight
                }

                Rectangle {
                    width: 22
                    height: 22
                    radius: Theme?.radiusPill ?? 999
                    color: dlMouse.containsMouse ? Theme.primary : Theme.alpha(Theme.surface, 0.82)
                    border.color: Theme.alpha(Theme.outline, 0.25)
                    border.width: 1
                    visible: cardRoot.allowDownload

                    Text {
                        anchors.centerIn: parent
                        text: Theme?.iconDownload ?? "󰇚"
                        font.family: Theme?.fontIcon ?? "sans-serif"
                        font.pixelSize: 10
                        color: dlMouse.containsMouse ? (Theme.on_primary ?? "#ffffff") : Theme.on_surface
                    }

                    MouseArea {
                        id: dlMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: cardRoot.downloadRequested()
                    }
                }
            }
        }
    }

    // bar pill icon
    Row {
        id: wpRow
        anchors.centerIn: parent
        spacing: 4

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Theme?.iconWallpaper ?? "󰸉"
            font.family: Theme?.fontIcon ?? "sans-serif"
            font.pixelSize: Theme?.fontSizeMd ?? 14
            color: popup.open ? Theme.primary : Theme.on_surface
        }
    }

    MouseArea {
        id: wpMouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: (mouse) => {
            if (mouse.button === Qt.RightButton) {
                root.rollRandomWallpaper();
                return;
            }
            root.syncAnchor();
            popup.open = !popup.open;
            if (popup.open) reloadLocalWallpapers();
        }
    }

    Connections {
        target: Settings
        function onRequestWallpaperToggle() {
            if (root.isTargetMonitorActive()) {
                root.syncAnchor();
                popup.open = !popup.open;
                if (popup.open) reloadLocalWallpapers();
            }
        }
        function onRequestWallpaperOpen() {
            if (root.isTargetMonitorActive()) {
                root.syncAnchor();
                popup.open = true;
                reloadLocalWallpapers();
            }
        }
        function onRequestWallpaperClose() {
            popup.open = false;
        }
    }

    PopupPanel {
        id: popup
        screen: root.barScreen
        wantsFocus: true
        cardWidth: 760
        cardHeight: Math.min(600, (popup.screen?.height ?? 800) - 80)
        targetRelativeX: (root.mapToItem(null, 0, 0)?.x ?? 0) + (root.width / 2)
        targetRelativeY: (root.mapToItem(null, 0, 0)?.y ?? 0) + (root.height / 2)

        content: ColumnLayout {
            anchors.fill: parent
            spacing: 8

            // top header: title + status on left, target monitor pills + actions on right
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Rectangle {
                    width: 34
                    height: 34
                    radius: Theme?.radiusMd ?? 8
                    color: Theme.primary_overlay
                    border.color: Theme.alpha(Theme.primary, 0.35)
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: Theme?.iconWallpaper ?? "󰸉"
                        font.family: Theme?.fontIcon ?? "sans-serif"
                        font.pixelSize: Theme?.fontSizeLg ?? 16
                        color: Theme.primary
                    }
                }

                ColumnLayout {
                    spacing: 1

                    Text {
                        text: "wallpapers & aesthetics"
                        font.family: Theme?.fontFamily ?? "sans-serif"
                        font.pixelSize: Theme?.fontSizeMd ?? 14
                        font.weight: Font.Bold
                        color: Theme.on_surface
                    }

                    Text {
                        text: {
                            if (root.batchStatusText !== "") return root.batchStatusText;
                            if (root.activeTab === "local") return localView.filteredLocalWps.length + " wallpapers in local gallery";
                            if (root.activeTab === "online") return root.onlineWallpapers.length > 0 ? (root.onlineWallpapers.length + " wallhaven results (page " + root.onlinePage + ")") : "explore wallhaven community gallery";
                            if (root.activeTab === "live") return root.activeLiveList.length + " animated & video streams";
                            return "matugen palette, awww transitions & mpvpaper";
                        }
                        font.family: Theme?.fontFamily ?? "sans-serif"
                        font.pixelSize: Theme?.fontSizeXs ?? 10
                        color: root.batchStatusText !== "" ? Theme.primary : Theme.on_surface_variant
                    }
                }

                Item { Layout.fillWidth: true }

                // target monitor pills tucked cleanly into the header
                RowLayout {
                    spacing: 4
                    visible: root.activeTab !== "theme" && (Quickshell?.screens?.length ?? 0) > 1

                    Chip {
                        icon: Theme?.iconWorkspaces ?? "󰍹"
                        label: "all"
                        selected: (WallpaperService?.targetMonitor ?? "all") === "all"
                        chipHeight: 26
                        onClicked: if (WallpaperService) WallpaperService.targetMonitor = "all"
                    }

                    Repeater {
                        model: Quickshell?.screens ?? []
                        delegate: Chip {
                            required property var modelData
                            label: modelData?.name ?? "screen"
                            selected: WallpaperService?.targetMonitor === modelData.name
                            chipHeight: 26
                            onClicked: if (WallpaperService) WallpaperService.targetMonitor = modelData.name
                        }
                    }
                }

                // batch download button for online & live tabs
                Chip {
                    visible: (root.activeTab === "online" && root.onlineWallpapers.length > 0)
                        || (root.activeTab === "live" && root.activeLiveList.length > 0)
                    icon: root.isBatchDownloading ? (Theme?.iconRefresh ?? "↺") : (Theme?.iconDownload ?? "󰇚")
                    label: root.isBatchDownloading
                        ? "saving..."
                        : ("save page (" + (root.activeTab === "online" ? root.onlineWallpapers.length : root.activeLiveList.length) + ")")
                    chipHeight: 28
                    selected: root.isBatchDownloading
                    onClicked: root.downloadCurrentSection()
                }

                IconButton {
                    icon: Theme?.iconShuffle ?? "󰒝"
                    tooltip: "roll random wallpaper"
                    onClicked: root.rollRandomWallpaper()
                }

                IconButton {
                    icon: Theme?.iconRefresh ?? "↺"
                    tooltip: "refresh current tab"
                    onClicked: {
                        if (root.activeTab === "local") reloadLocalWallpapers();
                        else if (root.activeTab === "online") fetchWallhaven(onlineSearchField.text, root.onlineSorting, 1, resField.text);
                        else if (root.activeTab === "live") fetchLiveWallpapers(root.liveSearchQuery);
                        else if (WallpaperService?.reapplyTheme) WallpaperService.reapplyTheme();
                    }
                }

                IconButton {
                    icon: Theme?.iconClose ?? "✕"
                    tooltip: "close panel"
                    onClicked: popup.open = false
                }
            }

            // segmented tab bar
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 36
                radius: Theme?.radiusPill ?? 999
                color: Theme.surface_container_lowest
                border.color: Theme.outline_variant ?? Theme.widgetBorder
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 3
                    spacing: 3

                    Repeater {
                        model: [
                            { id: "local", label: "local gallery", icon: Theme?.iconFolder ?? "󰉋" },
                            { id: "online", label: "wallhaven", icon: Theme?.iconGlobe ?? "󰖟" },
                            { id: "live", label: "live / video", icon: Theme?.iconFlame ?? "󰈸" },
                            { id: "theme", label: "effects & theme", icon: Theme?.iconPalette ?? "󰏘" }
                        ]

                        delegate: Rectangle {
                            required property var modelData
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: Theme?.radiusPill ?? 999

                            readonly property bool isSelected: root.activeTab === modelData.id

                            color: isSelected
                                ? (Theme.surface_container_high ?? Theme.primary_container)
                                : (tabMouse.containsMouse ? Theme.surface_container_low : "transparent")
                            border.color: isSelected ? (Theme.outline_variant ?? Theme.primary) : "transparent"
                            border.width: isSelected ? 1 : 0

                            Behavior on color { ColorAnimation { duration: Theme?.animFast ?? 150 } }

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 6

                                Text {
                                    text: modelData.icon
                                    font.family: Theme?.fontIcon ?? "sans-serif"
                                    font.pixelSize: Theme?.fontSizeSm ?? 12
                                    color: isSelected ? Theme.primary : Theme.on_surface_variant
                                }

                                Text {
                                    text: modelData.label
                                    font.family: Theme?.fontFamily ?? "sans-serif"
                                    font.pixelSize: Theme?.fontSizeSm ?? 11
                                    font.weight: isSelected ? Font.DemiBold : Font.Medium
                                    color: isSelected ? Theme.on_surface : Theme.on_surface_variant
                                }
                            }

                            MouseArea {
                                id: tabMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.activeTab = modelData.id;
                                    if (modelData.id === "local") reloadLocalWallpapers();
                                    else if (modelData.id === "online" && root.onlineWallpapers.length === 0) fetchWallhaven(root.onlineQuery, root.onlineSorting, root.onlinePage, root.onlineResolution);
                                    else if (modelData.id === "live" && root.onlineLiveWallpapers.length === 0) fetchLiveWallpapers(root.liveSearchQuery);
                                }
                            }
                        }
                    }
                }
            }

            // local gallery tab
            ColumnLayout {
                id: localView
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: root.activeTab === "local"
                spacing: 8

                readonly property var uniqueParentCategories: {
                    let cats = ["all"];
                    let items = root.allLocalWallpapers || [];
                    for (let i = 0; i < items.length; i++) {
                        let pCat = items[i]?.parentCategory || "root";
                        if (pCat && cats.indexOf(pCat) === -1) cats.push(pCat);
                    }
                    return cats;
                }

                readonly property var uniqueSubCategories: {
                    if (root.localCategoryFilter === "all") return [];
                    let subs = ["all"];
                    let items = root.allLocalWallpapers || [];
                    for (let i = 0; i < items.length; i++) {
                        let item = items[i];
                        if (item && item.parentCategory === root.localCategoryFilter && item.subCategory && item.subCategory !== "") {
                            if (subs.indexOf(item.subCategory) === -1) subs.push(item.subCategory);
                        }
                    }
                    return subs.length > 1 ? subs : [];
                }

                readonly property var filteredLocalWps: {
                    let result = [];
                    let items = root.allLocalWallpapers || [];
                    let pFilter = root.localCategoryFilter;
                    let subFilter = root.localSubCategoryFilter;
                    let sQuery = root.localSearchQuery.trim().toLowerCase();
                    for (let i = 0; i < items.length; i++) {
                        let item = items[i];
                        if (!item) continue;
                        let catStr = (item.category ?? "").toLowerCase();
                        let nameStr = (item.name ?? "").toLowerCase();
                        let pCat = item.parentCategory ?? "";
                        let subCat = item.subCategory ?? "";
                        let pMatch = pFilter === "all" || pCat === pFilter || catStr.indexOf(pFilter.toLowerCase()) !== -1;
                        let subMatch = subFilter === "all" || subCat === subFilter;
                        let searchMatch = sQuery === "" || nameStr.indexOf(sQuery) !== -1 || catStr.indexOf(sQuery) !== -1;

                        if (pMatch && subMatch && searchMatch) result.push(item);
                    }
                    return result;
                }

                // row 1: search input with inline match badge + random from filter button
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    SearchField {
                        id: localSearchField
                        placeholder: "search local wallpapers by name or folder..."
                        badgeText: localView.filteredLocalWps.length + " matched"
                        onTextChanged: root.localSearchQuery = text.toLowerCase()
                        onCleared: root.localSearchQuery = ""
                    }

                    Chip {
                        icon: Theme?.iconShuffle ?? "󰒝"
                        label: "random here"
                        chipHeight: 36
                        inactiveBg: Theme.cardBg
                        onClicked: root.rollRandomWallpaper()
                    }
                }

                // row 2: unified category + subfolder strip in one horizontal flickable
                Flickable {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 28
                    contentWidth: unifiedCatRow.implicitWidth
                    flickableDirection: Flickable.HorizontalFlick
                    boundsBehavior: Flickable.StopAtBounds
                    clip: true

                    RowLayout {
                        id: unifiedCatRow
                        spacing: 6

                        Repeater {
                            model: localView.uniqueParentCategories
                            delegate: Chip {
                                required property string modelData
                                label: modelData
                                selected: root.localCategoryFilter === modelData
                                chipHeight: 26
                                onClicked: {
                                    root.localCategoryFilter = modelData;
                                    root.localSubCategoryFilter = "all";
                                }
                            }
                        }

                        Rectangle {
                            visible: localView.uniqueSubCategories.length > 0
                            Layout.preferredWidth: 1
                            Layout.preferredHeight: 16
                            Layout.leftMargin: 4
                            Layout.rightMargin: 4
                            color: Theme.outline_variant ?? Theme.widgetBorder
                        }

                        Text {
                            visible: localView.uniqueSubCategories.length > 0
                            text: Theme?.iconFolder ?? "󰉋"
                            font.family: Theme?.fontIcon ?? "sans-serif"
                            font.pixelSize: Theme?.fontSizeXs ?? 10
                            color: Theme.primary
                        }

                        Repeater {
                            model: localView.uniqueSubCategories
                            delegate: Chip {
                                required property string modelData
                                label: modelData
                                selected: root.localSubCategoryFilter === modelData
                                chipHeight: 26
                                onClicked: root.localSubCategoryFilter = modelData
                            }
                        }
                    }
                }

                GridView {
                    id: localGrid
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    cellWidth: width / 3
                    cellHeight: cellWidth * 0.65
                    model: localView.filteredLocalWps
                    visible: localView.filteredLocalWps.length > 0

                    WheelHandler {
                        orientation: Qt.Vertical
                        target: parent
                    }

                    delegate: WallpaperCard {
                        required property var modelData
                        width: localGrid.cellWidth
                        height: localGrid.cellHeight
                        thumbUrl: modelData?.thumb || modelData?.path || ""
                        titleText: modelData?.name ?? ""
                        badgeText: modelData?.category === "root" ? "" : (modelData?.category ?? "")
                        tagText: modelData?.isVideo ? "LIVE" : (modelData?.isGif ? "GIF" : (modelData?.ext ?? "").toUpperCase())
                        tagAccent: Boolean(modelData?.isLive || modelData?.isVideo)
                        isSelected: modelData?.path === WallpaperService?.currentWallpaperPath
                        onApplyRequested: if (WallpaperService?.applyLocalWallpaper) WallpaperService.applyLocalWallpaper(modelData?.path)
                    }
                }

                EmptyState {
                    visible: localView.filteredLocalWps.length === 0
                    icon: Theme?.iconFolder ?? "󰉋"
                    message: "no wallpapers found\ntry adjusting your category or search filter"
                }
            }

            // wallhaven tab
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: root.activeTab === "online"
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    SearchField {
                        id: onlineSearchField
                        text: root.onlineQuery
                        placeholder: "search wallhaven (anime, cyberpunk, nature, minimal...)"
                        onSubmitted: (val) => fetchWallhaven(val, root.onlineSorting, 1, resField.text)
                        onCleared: fetchWallhaven("", root.onlineSorting, 1, resField.text)
                    }

                    SearchField {
                        id: resField
                        Layout.fillWidth: false
                        Layout.preferredWidth: 165
                        text: root.onlineResolution
                        icon: Theme?.iconWorkspaces ?? "󰍹"
                        placeholder: "any (" + root.nativeRes + ")"
                        monoFont: true
                        onSubmitted: (val) => fetchWallhaven(onlineSearchField.text, root.onlineSorting, 1, val)
                        onCleared: fetchWallhaven(onlineSearchField.text, root.onlineSorting, 1, "")
                    }

                    Chip {
                        label: "native"
                        chipHeight: 36
                        selected: root.onlineResolution === root.nativeRes
                        inactiveBg: Theme.cardBg
                        onClicked: {
                            resField.text = root.nativeRes;
                            fetchWallhaven(onlineSearchField.text, root.onlineSorting, 1, root.nativeRes);
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Repeater {
                        model: [
                            { label: "latest", val: "date_added" },
                            { label: "toplist", val: "toplist" },
                            { label: "hot", val: "hot" },
                            { label: "views", val: "views" },
                            { label: "random", val: "random" }
                        ]

                        delegate: Chip {
                            required property var modelData
                            label: modelData.label
                            selected: root.onlineSorting === modelData.val
                            chipHeight: 26
                            onClicked: fetchWallhaven(onlineSearchField.text, modelData.val, 1, resField.text)
                        }
                    }

                    Item { Layout.fillWidth: true }

                    // compact pagination controls using Theme chevron icons
                    Chip {
                        icon: Theme?.iconChevronLeft ?? "<"
                        chipHeight: 26
                        opacity: root.onlinePage > 1 ? 1.0 : 0.4
                        onClicked: {
                            if (root.onlinePage > 1 && !root.isOnlineLoading) {
                                fetchWallhaven(onlineSearchField.text, root.onlineSorting, root.onlinePage - 1, resField.text);
                            }
                        }
                    }

                    Rectangle {
                        Layout.preferredHeight: 26
                        Layout.preferredWidth: pageText.implicitWidth + 18
                        radius: Theme?.radiusPill ?? 999
                        color: Theme.surface_container_high
                        border.color: Theme.widgetBorder
                        border.width: 1

                        Text {
                            id: pageText
                            anchors.centerIn: parent
                            text: "page " + root.onlinePage
                            font.family: Theme?.fontMono ?? "monospace"
                            font.pixelSize: Theme?.fontSizeXs ?? 10
                            font.weight: Font.Bold
                            color: Theme.primary
                        }
                    }

                    Chip {
                        icon: Theme?.iconChevronRight ?? ">"
                        chipHeight: 26
                        onClicked: {
                            if (!root.isOnlineLoading) {
                                fetchWallhaven(onlineSearchField.text, root.onlineSorting, root.onlinePage + 1, resField.text);
                            }
                        }
                    }
                }

                GridView {
                    id: onlineGrid
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    cellWidth: width / 3
                    cellHeight: cellWidth * 0.65
                    model: root.onlineWallpapers
                    visible: !root.isOnlineLoading && root.onlineWallpapers.length > 0

                    WheelHandler {
                        orientation: Qt.Vertical
                        target: parent
                    }

                    delegate: WallpaperCard {
                        required property var modelData
                        width: onlineGrid.cellWidth
                        height: onlineGrid.cellHeight
                        thumbUrl: modelData?.thumbUrl ?? ""
                        titleText: modelData?.id ?? ""
                        badgeText: modelData?.resolution ?? ""
                        tagText: modelData?.fileType ?? ""
                        tagAccent: modelData?.fileType === "PNG"
                        allowDownload: true
                        onApplyRequested: if (WallpaperService?.setWallpaper) WallpaperService.setWallpaper(modelData.fullUrl)
                        onDownloadRequested: root.downloadUrls([modelData.fullUrl])
                    }
                }

                EmptyState {
                    visible: root.isOnlineLoading || root.onlineWallpapers.length === 0
                    loading: root.isOnlineLoading
                    icon: Theme?.iconGlobe ?? "󰖟"
                    message: root.isOnlineLoading
                        ? ("fetching " + (root.onlineSorting === "date_added" ? "latest" : root.onlineSorting) + (root.onlineResolution ? (" " + root.onlineResolution) : "") + " wallpapers...")
                        : "no wallpapers found\ntry adjusting your search query or resolution"
                }
            }

            // live / video tab
            ColumnLayout {
                id: liveView
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: root.activeTab === "live"
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Chip {
                        label: "local (" + root.localLiveWallpapers.length + ")"
                        icon: Theme?.iconFolder ?? "󰉋"
                        selected: root.liveSubTab === "local"
                        chipHeight: 36
                        onClicked: root.liveSubTab = "local"
                    }

                    Chip {
                        label: "streams (" + root.onlineLiveWallpapers.length + ")"
                        icon: Theme?.iconGlobe ?? "󰖟"
                        selected: root.liveSubTab === "online"
                        chipHeight: 36
                        onClicked: {
                            root.liveSubTab = "online";
                            if (root.onlineLiveWallpapers.length === 0) fetchLiveWallpapers(root.liveSearchQuery);
                        }
                    }

                    SearchField {
                        id: liveUrlField
                        icon: Theme?.iconFlame ?? "󰈸"
                        placeholder: "paste video url or local path (.mp4, .webm, .gif)..."
                        onSubmitted: (val) => {
                            if (val.trim() !== "" && WallpaperService?.setWallpaper) {
                                WallpaperService.setWallpaper(val.trim());
                            }
                        }
                    }

                    IconButton {
                        icon: Theme?.iconClipboard ?? "󰅌"
                        tooltip: "paste from clipboard"
                        onClicked: {
                            let clip = Quickshell?.clipboardText ? Quickshell.clipboardText.trim() : "";
                            if (clip !== "") liveUrlField.text = clip;
                        }
                    }

                    Chip {
                        icon: Theme?.iconCheck ?? "✓"
                        label: "apply"
                        chipHeight: 36
                        selected: liveUrlField.text.trim() !== ""
                        onClicked: {
                            if (liveUrlField.text.trim() !== "" && WallpaperService?.setWallpaper) {
                                WallpaperService.setWallpaper(liveUrlField.text.trim());
                            }
                        }
                    }
                }

                GridView {
                    id: liveGrid
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    cellWidth: width / 3
                    cellHeight: cellWidth * 0.65
                    model: root.activeLiveList
                    visible: root.activeLiveList.length > 0

                    WheelHandler {
                        orientation: Qt.Vertical
                        target: parent
                    }

                    delegate: WallpaperCard {
                        required property var modelData
                        readonly property string targetPath: modelData?.path || modelData?.url || ""
                        width: liveGrid.cellWidth
                        height: liveGrid.cellHeight
                        thumbUrl: modelData?.thumb || targetPath
                        titleText: modelData?.name || modelData?.title || "live wallpaper"
                        badgeText: modelData?.isVideo ? "VIDEO" : (modelData?.isGif ? "GIF" : "STREAM")
                        tagText: (modelData?.ext ?? "LIVE").toUpperCase()
                        tagAccent: true
                        allowDownload: root.liveSubTab === "online" && (targetPath.startsWith("http://") || targetPath.startsWith("https://"))
                        isSelected: targetPath !== "" && targetPath === WallpaperService?.currentWallpaperPath
                        onApplyRequested: {
                            if (root.liveSubTab === "local" && WallpaperService?.applyLocalWallpaper) {
                                WallpaperService.applyLocalWallpaper(targetPath);
                            } else if (WallpaperService?.setWallpaper) {
                                WallpaperService.setWallpaper(targetPath);
                            }
                        }
                        onDownloadRequested: root.downloadUrls([targetPath])
                    }
                }

                EmptyState {
                    visible: root.activeLiveList.length === 0
                    icon: Theme?.iconFlame ?? "󰈸"
                    message: root.liveSubTab === "local"
                        ? "no local animated wallpapers found\ndrop .mp4, .webm, or .gif files into ~/.wallpapers"
                        : "no online live streams loaded"
                }
            }

            // effects & theme tab organized into clean bento cards
            Flickable {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: root.activeTab === "theme"
                clip: true
                contentWidth: width
                contentHeight: themeCol.implicitHeight
                boundsBehavior: Flickable.StopAtBounds

                WheelHandler {
                    orientation: Qt.Vertical
                    target: parent
                }

                ColumnLayout {
                    id: themeCol
                    width: parent.width - 4
                    spacing: 10

                    // 1. Matugen color extraction & scheme card
                    SettingCard {
                        title: "matugen color palette"
                        icon: Theme?.iconPalette ?? "󰏘"
                        badge: (WallpaperService?.currentMode ?? "dark") + " • " + (WallpaperService?.currentSchemeType ?? "scheme-tonal-spot").replace("scheme-", "")

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Chip {
                                icon: Theme?.iconMoon ?? "󰖔"
                                label: "dark mode"
                                selected: WallpaperService?.currentMode === "dark"
                                fillWidth: true
                                chipHeight: 30
                                onClicked: if (WallpaperService?.setMode) WallpaperService.setMode("dark")
                            }

                            Chip {
                                icon: Theme?.iconSun ?? "󰖙"
                                label: "light mode"
                                selected: WallpaperService?.currentMode === "light"
                                fillWidth: true
                                chipHeight: 30
                                onClicked: if (WallpaperService?.setMode) WallpaperService.setMode("light")
                            }
                        }

                        GroupLabel { text: "scheme algorithm" }

                        GridLayout {
                            Layout.fillWidth: true
                            columns: 5
                            rowSpacing: 6
                            columnSpacing: 6

                            Repeater {
                                model: [
                                    { label: "tonal spot", val: "scheme-tonal-spot" },
                                    { label: "smart", val: "scheme-smart" },
                                    { label: "vibrant", val: "scheme-vibrant" },
                                    { label: "expressive", val: "scheme-expressive" },
                                    { label: "content", val: "scheme-content" },
                                    { label: "fruit salad", val: "scheme-fruit-salad" },
                                    { label: "rainbow", val: "scheme-rainbow" },
                                    { label: "fidelity", val: "scheme-fidelity" },
                                    { label: "monochrome", val: "scheme-monochrome" },
                                    { label: "neutral", val: "scheme-neutral" }
                                ]

                                delegate: Chip {
                                    required property var modelData
                                    label: modelData.label
                                    selected: WallpaperService?.currentSchemeType === modelData.val
                                    fillWidth: true
                                    chipHeight: 26
                                    onClicked: if (WallpaperService?.setScheme) WallpaperService.setScheme(modelData.val)
                                }
                            }
                        }

                        GroupLabel { text: "seed color override" }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Rectangle {
                                Layout.preferredWidth: 32
                                Layout.preferredHeight: 32
                                radius: 16
                                color: {
                                    let h = hexField.text.trim();
                                    return (h.startsWith("#") && (h.length === 7 || h.length === 9)) ? h : Theme.primary;
                                }
                                border.color: Theme.on_surface
                                border.width: 1
                            }

                            SearchField {
                                id: hexField
                                Layout.preferredWidth: 150
                                Layout.fillWidth: false
                                Layout.preferredHeight: 32
                                icon: Theme?.iconSparkles ?? "✦"
                                text: Theme?.source_color || "#a8c8ff"
                                placeholder: "#rrggbb"
                                monoFont: true
                                onSubmitted: (val) => {
                                    let h = val.trim();
                                    if (h.startsWith("#") && (h.length === 7 || h.length === 9) && WallpaperService?.applyColor) {
                                        WallpaperService.applyColor(h);
                                    }
                                }
                            }

                            Chip {
                                label: "apply hex"
                                chipHeight: 32
                                selected: true
                                onClicked: {
                                    let h = hexField.text.trim();
                                    if (h.startsWith("#") && (h.length === 7 || h.length === 9) && WallpaperService?.applyColor) {
                                        WallpaperService.applyColor(h);
                                    }
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 5

                                Repeater {
                                    model: [
                                        "#a8c8ff", "#ffb4ab", "#c8bfff", "#8bf0ba",
                                        "#ffd700", "#ff7597", "#70d6ff", "#ff9e00",
                                        "#50fa7b", "#bd93f9", "#ff79c6"
                                    ]

                                    delegate: Rectangle {
                                        required property string modelData
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 24
                                        radius: Theme?.radiusPill ?? 999
                                        color: modelData
                                        border.color: hexField.text === modelData ? Theme.on_surface : Theme.alpha(Theme.outline, 0.3)
                                        border.width: hexField.text === modelData ? 2 : 1

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                hexField.text = modelData;
                                                if (WallpaperService?.applyColor) WallpaperService.applyColor(modelData);
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // 2. Awww transition & scaling engine card
                    SettingCard {
                        title: "awww transition engine"
                        icon: Theme?.iconFlame ?? "󰈸"
                        badge: (Settings?.awwwTransitionType ?? "fade") + " • " + (Settings?.awwwTransitionFps ?? 60) + " fps"

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 12

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 6

                                GroupLabel { text: "resize mode" }

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 6

                                    Repeater {
                                        model: [
                                            { label: "crop", val: "crop" },
                                            { label: "fit", val: "fit" },
                                            { label: "stretch", val: "stretch" },
                                            { label: "center", val: "no" }
                                        ]

                                        delegate: Chip {
                                            required property var modelData
                                            label: modelData.label
                                            selected: (Settings?.awwwResize ?? "crop") === modelData.val
                                            fillWidth: true
                                            chipHeight: 26
                                            onClicked: {
                                                if (Settings) {
                                                    Settings.awwwResize = modelData.val;
                                                    if (Settings.save) Settings.save();
                                                }
                                                if (WallpaperService?.reapplyTheme) WallpaperService.reapplyTheme();
                                            }
                                        }
                                    }
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 6

                                GroupLabel { text: "scaling filter" }

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 6

                                    Repeater {
                                        model: ["Lanczos3", "Bilinear", "CatmullRom", "Mitchell", "Nearest"]

                                        delegate: Chip {
                                            required property string modelData
                                            label: modelData.toLowerCase()
                                            selected: (Settings?.awwwFilter ?? "Lanczos3") === modelData
                                            fillWidth: true
                                            chipHeight: 26
                                            onClicked: {
                                                if (Settings) {
                                                    Settings.awwwFilter = modelData;
                                                    if (Settings.save) Settings.save();
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        GroupLabel { text: "transition animation" }

                        GridLayout {
                            Layout.fillWidth: true
                            columns: 7
                            rowSpacing: 6
                            columnSpacing: 6

                            Repeater {
                                model: ["fade", "simple", "wipe", "wave", "grow", "center", "outer", "any", "random", "left", "right", "top", "bottom", "none"]

                                delegate: Chip {
                                    required property string modelData
                                    label: modelData
                                    selected: (Settings?.awwwTransitionType ?? "fade") === modelData
                                    fillWidth: true
                                    chipHeight: 26
                                    onClicked: {
                                        if (Settings) {
                                            Settings.awwwTransitionType = modelData;
                                            if (Settings.save) Settings.save();
                                        }
                                    }
                                }
                            }
                        }

                        // contextual row for wipe/wave angle
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 6
                            visible: {
                                let t = Settings?.awwwTransitionType ?? "fade";
                                return t === "wipe" || t === "wave";
                            }

                            GroupLabel {
                                text: "angle:"
                                Layout.rightMargin: 4
                            }

                            Repeater {
                                model: [
                                    { label: "0°", val: 0 },
                                    { label: "45°", val: 45 },
                                    { label: "90°", val: 90 },
                                    { label: "135°", val: 135 },
                                    { label: "180°", val: 180 },
                                    { label: "270°", val: 270 }
                                ]

                                delegate: Chip {
                                    required property var modelData
                                    label: modelData.label
                                    selected: (Settings?.awwwTransitionAngle ?? 0) === modelData.val
                                    fillWidth: true
                                    chipHeight: 26
                                    onClicked: {
                                        if (Settings) {
                                            Settings.awwwTransitionAngle = modelData.val;
                                            if (Settings.save) Settings.save();
                                        }
                                    }
                                }
                            }
                        }

                        // contextual row for grow/outer circle origin
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 6
                            visible: {
                                let t = Settings?.awwwTransitionType ?? "fade";
                                return t === "grow" || t === "outer";
                            }

                            GroupLabel {
                                text: "origin:"
                                Layout.rightMargin: 4
                            }

                            Repeater {
                                model: ["center", "top", "bottom", "left", "right"]

                                delegate: Chip {
                                    required property string modelData
                                    label: modelData
                                    selected: (Settings?.awwwTransitionPos ?? "center") === modelData
                                    fillWidth: true
                                    chipHeight: 26
                                    onClicked: {
                                        if (Settings) {
                                            Settings.awwwTransitionPos = modelData;
                                            if (Settings.save) Settings.save();
                                        }
                                    }
                                }
                            }
                        }

                        GroupLabel { text: "transition frame rate" }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 6

                            Repeater {
                                model: [
                                    { label: "30 fps", val: 30 },
                                    { label: "60 fps", val: 60 },
                                    { label: "90 fps", val: 90 },
                                    { label: "120 fps", val: 120 },
                                    { label: "144 fps", val: 144 },
                                    { label: "165 fps", val: 165 },
                                    { label: "240 fps", val: 240 }
                                ]

                                delegate: Chip {
                                    required property var modelData
                                    label: modelData.label
                                    selected: (Settings?.awwwTransitionFps ?? 60) === modelData.val
                                    fillWidth: true
                                    chipHeight: 26
                                    onClicked: {
                                        if (Settings) {
                                            Settings.awwwTransitionFps = modelData.val;
                                            if (Settings.save) Settings.save();
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // 3. Mpvpaper live video engine card (side-by-side compact layout)
                    SettingCard {
                        title: "mpvpaper live video engine"
                        icon: Theme?.iconPlay ?? "▶"
                        badge: (Settings?.mpvAudio ?? false) ? "audio on" : "muted"

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 12

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 6

                                GroupLabel { text: "video aspect & panscan" }

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 6

                                    Repeater {
                                        model: [
                                            { label: "crop (fill)", val: 1.0 },
                                            { label: "balanced", val: 0.5 },
                                            { label: "letterbox", val: 0.0 }
                                        ]

                                        delegate: Chip {
                                            required property var modelData
                                            label: modelData.label
                                            selected: Math.abs((Settings?.mpvPanscan ?? 1.0) - modelData.val) < 0.05
                                            fillWidth: true
                                            chipHeight: 28
                                            onClicked: {
                                                if (Settings) {
                                                    Settings.mpvPanscan = modelData.val;
                                                    if (Settings.save) Settings.save();
                                                }
                                                if (WallpaperService?.reapplyTheme) WallpaperService.reapplyTheme();
                                            }
                                        }
                                    }
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 6

                                GroupLabel { text: "video audio" }

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 6

                                    Chip {
                                        icon: Theme?.iconVolMute ?? "󰝟"
                                        label: "mute"
                                        selected: !(Settings?.mpvAudio ?? false)
                                        fillWidth: true
                                        chipHeight: 28
                                        onClicked: {
                                            if (Settings) {
                                                Settings.mpvAudio = false;
                                                if (Settings.save) Settings.save();
                                            }
                                            if (WallpaperService?.reapplyTheme) WallpaperService.reapplyTheme();
                                        }
                                    }

                                    Chip {
                                        icon: Theme?.iconVolHigh ?? "󰕾"
                                        label: "ambient sound"
                                        selected: Settings?.mpvAudio ?? false
                                        fillWidth: true
                                        chipHeight: 28
                                        onClicked: {
                                            if (Settings) {
                                                Settings.mpvAudio = true;
                                                if (Settings.save) Settings.save();
                                            }
                                            if (WallpaperService?.reapplyTheme) WallpaperService.reapplyTheme();
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
}
