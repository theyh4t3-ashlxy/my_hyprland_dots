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
    readonly property string nativeRes: (Quickshell?.screens && Quickshell.screens.length > 0) ? (Quickshell.screens[0].width + "x" + Quickshell.screens[0].height) : "1920x1080"
    property string onlineResolution: nativeRes
    property bool isOnlineLoading: false
    property bool isBatchDownloading: false
    property string batchStatusText: ""
    property string liveSearchQuery: ""
    property var allLocalWallpapers: []

    readonly property string wpScriptPath: decodeURIComponent(Qt.resolvedUrl("../scripts/wallpaper.py").toString().replace(/^file:\/\//, ""))

    ListModel { id: onlineWpModel }
    ListModel { id: liveWpModel }

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
            root.batchStatusText = (code === 0) ? "wallpapers saved to ~/.wallpapers/" : "download failed";
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

    Connections {
        target: popup
        function onOpenChanged() {
            root.syncKeyboardFocus(popup.open);
            if (popup.open) {
                Qt.callLater(() => {
                    if (root.activeTab === "local") localSearchInput.forceActiveFocus();
                    else if (root.activeTab === "online") onlineInput.forceActiveFocus();
                });
            }
        }
    }

    onActiveTabChanged: {
        if (popup.open) {
            Qt.callLater(() => {
                if (root.activeTab === "local") localSearchInput.forceActiveFocus();
                else if (root.activeTab === "online") onlineInput.forceActiveFocus();
            });
        }
    }

    Component.onCompleted: {
        parseLocalWallpapers();
        reloadLocalWallpapers();
    }

    function fetchLiveWallpapers(q) {
        Quickshell.execDetached(["python3", wpScriptPath, "fetch-live", q || ""]);
        liveParseTimer.restart();
    }

    function loadLiveFromJson(raw) {
        try {
            liveWpModel.clear();
            if (!raw || raw.trim() === "") return;
            let list = JSON.parse(raw);
            for (let i = 0; i < list.length; i++) {
                liveWpModel.append(list[i]);
            }
        } catch(e) {}
    }

    function parseLocalWallpapers() {
        if (!WallpaperService?.localWpListFile) return;
        WallpaperService.localWpListFile.reload();
        let str = WallpaperService.localWpListFile.text();
        if (!str || str.trim() === "") return;
        try {
            root.allLocalWallpapers = JSON.parse(str) || [];
        } catch(e) {}
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
        if (q && q !== "") params.push("q=" + encodeURIComponent(q));
        params.push("sorting=" + encodeURIComponent(s));
        params.push("page=" + p);
        params.push("categories=111");
        params.push("purity=100");

        if (r && r !== "" && r.toLowerCase() !== "any") {
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
                        onlineWpModel.clear();
                        for (let i = 0; i < data.length; i++) {
                            onlineWpModel.append({
                                thumbUrl: data[i].thumbs?.small ?? "",
                                fullUrl: data[i].path ?? "",
                                id: String(data[i].id ?? ""),
                                resolution: data[i].resolution || "",
                                fileType: (data[i].file_type || "").replace("image/", "").toUpperCase(),
                                favorites: data[i].favorites || 0
                            });
                        }
                    } catch (e) {}
                }
            }
        };
        req.send();
    }

    function downloadCurrentSection() {
        if (root.isBatchDownloading) return;
        let urls = [];
        if (root.activeTab === "online") {
            for (let i = 0; i < onlineWpModel.count; i++) {
                let u = onlineWpModel.get(i)?.fullUrl;
                if (u) urls.push(u);
            }
        } else if (root.activeTab === "live") {
            let activeList = (root.liveSubTab === "local") ? root.localLiveWallpapers : [];
            if (root.liveSubTab === "local") {
                for (let i = 0; i < activeList.length; i++) {
                    let u = activeList[i]?.url || activeList[i]?.path;
                    if (u && (u.startsWith("http://") || u.startsWith("https://"))) urls.push(u);
                }
            } else {
                for (let i = 0; i < liveWpModel.count; i++) {
                    let u = liveWpModel.get(i)?.url || liveWpModel.get(i)?.path;
                    if (u && (u.startsWith("http://") || u.startsWith("https://"))) urls.push(u);
                }
            }
        }

        if (urls.length === 0) return;

        root.isBatchDownloading = true;
        root.batchStatusText = "downloading " + urls.length + " wallpapers...";
        batchDownloadProc.command = ["python3", wpScriptPath, "batch-download", JSON.stringify(urls)];
        batchDownloadProc.running = true;
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
            font.family: Theme?.fontIcon ?? "sans-serif"
            font.pixelSize: Theme?.fontSizeSm ?? 12
            color: Theme.primary
        }

        Text {
            text: catHdr.title
            font.family: Theme?.fontFamily ?? "sans-serif"
            font.pixelSize: Theme?.fontSizeXs ?? 10
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
        radius: Theme?.widgetRadius ?? 12
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

    component Chip: Rectangle {
        id: chipRoot
        property bool selected: false
        property string label: ""
        property real chipHeight: 28
        property real chipRadius: Theme?.radiusPill ?? 999
        property int fontSize: Theme?.fontSizeXs ?? 10
        property bool fillWidth: false
        property color activeBg: Theme.primary
        property color inactiveBg: Theme.surface_container_highest
        property color activeFg: Theme.on_primary ?? "#ffffff"
        property color inactiveFg: Theme.on_surface
        signal clicked()

        Layout.fillWidth: fillWidth
        Layout.preferredHeight: chipHeight
        Layout.preferredWidth: fillWidth ? -1 : (chipText.implicitWidth + 18)
        radius: chipRadius
        color: selected ? activeBg : (chipMouse.containsMouse ? Theme.surface_container_high : inactiveBg)
        border.color: selected ? Theme.primary : (Theme?.cardBorder ?? Theme?.widgetBorder ?? "transparent")
        border.width: 1

        Behavior on color { ColorAnimation { duration: Theme?.animFast ?? 150 } }
        Behavior on border.color { ColorAnimation { duration: Theme?.animFast ?? 150 } }

        Text {
            id: chipText
            anchors.centerIn: parent
            text: chipRoot.label
            font.family: Theme?.fontFamily ?? "sans-serif"
            font.pixelSize: chipRoot.fontSize
            font.weight: chipRoot.selected ? Font.Bold : Font.Medium
            color: chipRoot.selected ? chipRoot.activeFg : chipRoot.inactiveFg
        }

        MouseArea {
            id: chipMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: chipRoot.clicked()
        }
    }

    component SectionHeader: Text {
        font.family: Theme?.fontFamily ?? "sans-serif"
        font.pixelSize: Theme?.fontSizeSm ?? 12
        font.weight: Font.Bold
        color: Theme.primary
    }

    component GroupLabel: Text {
        font.family: Theme?.fontFamily ?? "sans-serif"
        font.pixelSize: Theme?.fontSizeXs ?? 10
        font.weight: Font.Medium
        color: Theme.on_surface_variant
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
            radius: Theme?.widgetRadius ?? 12
            clip: true
            border.color: cardRoot.isSelected ? Theme.primary : (cardMouse.containsMouse ? Theme.primary : Theme.cardBorder)
            border.width: cardRoot.isSelected ? 2 : 1

            Behavior on border.color { ColorAnimation { duration: Theme?.animFast ?? 150 } }

            Image {
                anchors.fill: parent
                source: (cardRoot.thumbUrl.startsWith("http://") || cardRoot.thumbUrl.startsWith("https://") || cardRoot.thumbUrl.startsWith("file://")) ? cardRoot.thumbUrl : ("file://" + cardRoot.thumbUrl)
                sourceSize: Qt.size(280, 180)
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
            }

            Rectangle {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                height: 42
                z: 1
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "transparent" }
                    GradientStop { position: 1.0; color: Theme.alpha(Theme.surface, 0.88) }
                }
            }

            Rectangle {
                id: leftBadge
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.margins: 8
                height: 20
                width: bText.implicitWidth + 12
                radius: Theme?.radiusPill ?? 999
                color: Theme.alpha(Theme.surface, 0.80)
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
                    color: cardRoot.tagAccent ? Theme.primary : Theme.alpha(Theme.surface, 0.80)
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
                    color: dlMouse.containsMouse ? Theme.primary : Theme.alpha(Theme.surface, 0.80)
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

            MouseArea {
                id: cardMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: cardRoot.applyRequested()
            }
        }
    }

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
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            const p = root.mapToItem(null, 0, 0);
            if (p) {
                popup.targetRelativeX = p.x + (root.width / 2);
                popup.targetRelativeY = p.y + (root.height / 2);
            }
            popup.open = !popup.open;
            if (popup.open) reloadLocalWallpapers();
        }
    }

    Connections {
        target: Settings
        function onRequestWallpaperToggle() {
            if (!root.barScreen || Quickshell.screens.length <= 1 || (root.barMonitor && Hyprland.focusedMonitor && root.barMonitor.id === Hyprland.focusedMonitor.id)) {
                const p = root.mapToItem(null, 0, 0);
                if (p) {
                    popup.targetRelativeX = p.x + (root.width / 2);
                    popup.targetRelativeY = p.y + (root.height / 2);
                }
                popup.open = !popup.open;
                if (popup.open) reloadLocalWallpapers();
            }
        }
        function onRequestWallpaperOpen() {
            if (!root.barScreen || Quickshell.screens.length <= 1 || (root.barMonitor && Hyprland.focusedMonitor && root.barMonitor.id === Hyprland.focusedMonitor.id)) {
                const p = root.mapToItem(null, 0, 0);
                if (p) {
                    popup.targetRelativeX = p.x + (root.width / 2);
                    popup.targetRelativeY = p.y + (root.height / 2);
                }
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
        cardHeight: Math.min(590, (popup.screen?.height ?? 800) - 80)
        targetRelativeX: (root.mapToItem(null, 0, 0)?.x ?? 0) + (root.width / 2)
        targetRelativeY: (root.mapToItem(null, 0, 0)?.y ?? 0) + (root.height / 2)

        content: ColumnLayout {
            anchors.fill: parent
            spacing: Theme?.widgetSpacing ?? 10

            // 1. Unified Window Header
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Text {
                    text: Theme?.iconWallpaper ?? "󰸉"
                    font.family: Theme?.fontIcon ?? "sans-serif"
                    font.pixelSize: Theme?.fontSizeLg ?? 16
                    color: Theme.primary
                }

                ColumnLayout {
                    spacing: 1
                    Layout.fillWidth: true

                    Text {
                        text: "wallpapers & aesthetics"
                        font.family: Theme?.fontFamily ?? "sans-serif"
                        font.pixelSize: Theme?.fontSizeMd ?? 14
                        font.weight: Font.Bold
                        color: Theme.on_surface
                    }

                    Text {
                        text: {
                            if (root.activeTab === "local") return (localView.filteredLocalWps ? localView.filteredLocalWps.length : 0) + " wallpapers in gallery";
                            if (root.activeTab === "online") return (onlineWpModel.count > 0 ? (onlineWpModel.count + " wallhaven wallpapers loaded") : "explore wallhaven community gallery");
                            if (root.activeTab === "live") return (root.liveSubTab === "local" ? root.localLiveWallpapers.length : liveWpModel.count) + " animated & video streams";
                            return "matugen color schemes & awww engine";
                        }
                        font.family: Theme?.fontFamily ?? "sans-serif"
                        font.pixelSize: Theme?.fontSizeXs ?? 10
                        color: Theme.on_surface_variant
                    }
                }

                // Batch download action
                Rectangle {
                    Layout.preferredHeight: 32
                    Layout.preferredWidth: dlAllRow.implicitWidth + 20
                    radius: Theme?.radiusPill ?? 999
                    color: dlAllMouse.containsMouse ? Theme.primary_overlay : Theme.surface_container_highest
                    border.color: Theme.widgetBorder
                    border.width: 1
                    visible: (root.activeTab === "online" && onlineWpModel.count > 0) || (root.activeTab === "live" && ((root.liveSubTab === "local" ? root.localLiveWallpapers.length : liveWpModel.count) > 0))
                    opacity: root.isBatchDownloading ? 0.6 : 1.0

                    RowLayout {
                        id: dlAllRow
                        anchors.centerIn: parent
                        spacing: 6

                        Text {
                            text: root.isBatchDownloading ? (Theme?.iconRefresh ?? "↺") : (Theme?.iconDownload ?? "󰇚")
                            font.family: Theme?.fontIcon ?? "sans-serif"
                            font.pixelSize: Theme?.fontSizeSm ?? 12
                            color: Theme.primary
                        }

                        Text {
                            text: root.isBatchDownloading ? "saving..." : ("download all (" + (root.activeTab === "online" ? onlineWpModel.count : (root.liveSubTab === "local" ? root.localLiveWallpapers.length : liveWpModel.count)) + ")")
                            font.family: Theme?.fontFamily ?? "sans-serif"
                            font.pixelSize: Theme?.fontSizeXs ?? 10
                            font.weight: Font.Bold
                            color: Theme.on_surface
                        }
                    }

                    MouseArea {
                        id: dlAllMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: root.isBatchDownloading ? Qt.ArrowCursor : Qt.PointingHandCursor
                        onClicked: downloadCurrentSection()
                    }
                }

                IconButton {
                    icon: Theme?.iconShuffle ?? "󰒝"
                    tooltip: "roll random wallpaper"
                    onClicked: {
                        let activeCat = "all";
                        if (root.localCategoryFilter !== "all") {
                            activeCat = root.localCategoryFilter;
                            if (root.localSubCategoryFilter !== "all") {
                                activeCat = root.localCategoryFilter + "/" + root.localSubCategoryFilter;
                            }
                        }
                        WallpaperService?.applyRandomWallpaper ? WallpaperService.applyRandomWallpaper(activeCat) : null;
                    }
                }

                IconButton {
                    icon: Theme?.iconRefresh ?? "↺"
                    tooltip: "refresh / rescan"
                    onClicked: {
                        if (root.activeTab === "local") reloadLocalWallpapers();
                        else if (root.activeTab === "online") fetchWallhaven(onlineInput.text, root.onlineSorting, 1, resInput.text);
                        else if (root.activeTab === "live") fetchLiveWallpapers(root.liveSearchQuery);
                        else WallpaperService?.reapplyTheme ? WallpaperService.reapplyTheme() : null;
                    }
                }

                IconButton {
                    icon: Theme?.iconClose ?? "✕"
                    tooltip: "close panel"
                    onClicked: popup.open = false
                }
            }

            // 2. Cohesive Segmented Tab Bar (matching QuickSettings)
            Flickable {
                Layout.fillWidth: true
                height: 36
                contentWidth: tabRow.implicitWidth
                flickableDirection: Flickable.HorizontalFlick
                boundsBehavior: Flickable.StopAtBounds
                clip: true

                RowLayout {
                    id: tabRow
                    spacing: 6

                    Repeater {
                        model: [
                            { id: "local", label: "local gallery", icon: Theme?.iconFolder ?? "󰉋" },
                            { id: "online", label: "wallhaven", icon: Theme?.iconGlobe ?? "󰖟" },
                            { id: "live", label: "live / video", icon: Theme?.iconFlame ?? "󰈸" },
                            { id: "theme", label: "effects & theme", icon: Theme?.iconPalette ?? "󰏘" }
                        ]

                        delegate: Rectangle {
                            required property var modelData
                            height: 32
                            width: tabItemRow.implicitWidth + 24
                            radius: Theme?.widgetRadius ?? 10
                            color: root.activeTab === modelData.id ? Theme.primary : (tabMouse.containsMouse ? Theme.surface_container_high : Theme.surface_container_highest)

                            Behavior on color { ColorAnimation { duration: Theme?.animFast ?? 150 } }

                            RowLayout {
                                id: tabItemRow
                                anchors.centerIn: parent
                                spacing: 6

                                Text {
                                    text: modelData.icon
                                    font.family: Theme?.fontIcon ?? "sans-serif"
                                    font.pixelSize: Theme?.fontSizeXs ?? 10
                                    color: root.activeTab === modelData.id ? (Theme.on_primary ?? "#ffffff") : Theme.on_surface
                                }

                                Text {
                                    text: modelData.label
                                    font.family: Theme?.fontFamily ?? "sans-serif"
                                    font.pixelSize: Theme?.fontSizeSm ?? 11
                                    font.weight: Font.Medium
                                    color: root.activeTab === modelData.id ? (Theme.on_primary ?? "#ffffff") : Theme.on_surface
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
                                    else if (modelData.id === "online" && onlineWpModel.count === 0) fetchWallhaven(root.onlineQuery, root.onlineSorting, root.onlinePage, root.onlineResolution);
                                    else if (modelData.id === "live" && liveWpModel.count === 0) fetchLiveWallpapers(root.liveSearchQuery);
                                }
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

            // Status message
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 28
                radius: Theme?.radiusSm ?? 6
                color: Theme.primary_overlay
                border.color: Theme.primary
                border.width: 1
                visible: root.batchStatusText !== ""

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 6

                    Text {
                        text: Theme?.iconCheck ?? "✓"
                        font.family: Theme?.fontIcon ?? "sans-serif"
                        font.pixelSize: Theme?.fontSizeXs ?? 10
                        color: Theme.primary
                    }

                    Text {
                        text: root.batchStatusText
                        font.family: Theme?.fontFamily ?? "sans-serif"
                        font.pixelSize: Theme?.fontSizeXs ?? 10
                        font.weight: Font.Medium
                        color: Theme.primary
                    }
                }
            }

            // Target Monitor Selector (visible for wallpaper tabs)
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                visible: root.activeTab !== "theme"

                GroupLabel {
                    text: "target monitor:"
                    font.weight: Font.Bold
                }

                Chip {
                    label: "all monitors 󰍹"
                    selected: WallpaperService?.targetMonitor === "all"
                    chipHeight: 26
                    chipRadius: Theme?.radiusPill ?? 999
                    fontSize: Theme?.fontSizeXs ?? 10
                    onClicked: if (WallpaperService) WallpaperService.targetMonitor = "all"
                }

                Repeater {
                    model: Quickshell?.screens ?? []
                    delegate: Chip {
                        required property var modelData
                        label: modelData?.name ?? "screen"
                        selected: WallpaperService?.targetMonitor === modelData.name
                        chipHeight: 26
                        chipRadius: Theme?.radiusPill ?? 999
                        fontSize: Theme?.fontSizeXs ?? 10
                        onClicked: if (WallpaperService) WallpaperService.targetMonitor = modelData.name
                    }
                }

                Item { Layout.fillWidth: true }
            }

            // LOCAL TAB
            ColumnLayout {
                id: localView
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: root.activeTab === "local"
                spacing: 8

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 38
                    color: Theme.cardBg
                    radius: Theme?.widgetRadius ?? 10
                    border.color: localSearchInput.activeFocus ? Theme.primary : Theme.cardBorder
                    border.width: 1

                    Behavior on border.color { ColorAnimation { duration: Theme?.animFast ?? 150 } }

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: Theme?.widgetPaddingH ?? 10
                        spacing: 8

                        Text {
                            text: Theme?.iconSearch ?? "󰍉"
                            font.family: Theme?.fontIcon ?? "sans-serif"
                            font.pixelSize: Theme?.fontSizeSm ?? 12
                            color: localSearchInput.activeFocus ? Theme.primary : Theme.on_surface_variant
                        }

                        TextInput {
                            id: localSearchInput
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            verticalAlignment: TextInput.AlignVCenter
                            font.family: Theme?.fontFamily ?? "sans-serif"
                            font.pixelSize: Theme?.fontSizeSm ?? 12
                            color: Theme.on_surface
                            selectByMouse: true
                            activeFocusOnTab: true
                            onTextChanged: root.localSearchQuery = text.toLowerCase()

                            Text {
                                text: "search local wallpapers by name or tag..."
                                font.family: Theme?.fontFamily ?? "sans-serif"
                                font.pixelSize: Theme?.fontSizeSm ?? 12
                                color: Theme.on_surface_disabled
                                visible: localSearchInput.text.length === 0 && !localSearchInput.activeFocus
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        IconButton {
                            icon: Theme?.iconClose ?? "✕"
                            iconSize: 10
                            tooltip: "clear search"
                            visible: localSearchInput.text.length > 0
                            onClicked: {
                                localSearchInput.text = "";
                                root.localSearchQuery = "";
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.IBeamCursor
                        propagateComposedEvents: true
                        onPressed: (mouse) => {
                            localSearchInput.forceActiveFocus();
                            mouse.accepted = false;
                        }
                    }
                }

                readonly property var uniqueParentCategories: {
                    let cats = ["all"];
                    let items = root.allLocalWallpapers || [];
                    for (let i = 0; i < items.length; i++) {
                        let pCat = items[i]?.parentCategory || "root";
                        if (pCat && cats.indexOf(pCat) === -1) cats.push(pCat);
                    }
                    return cats;
                }

                Flickable {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 28
                    contentWidth: catRow.implicitWidth
                    flickableDirection: Flickable.HorizontalFlick
                    boundsBehavior: Flickable.StopAtBounds
                    clip: true

                    RowLayout {
                        id: catRow
                        spacing: 6

                        Repeater {
                            model: localView.uniqueParentCategories
                            delegate: Chip {
                                required property string modelData
                                label: modelData
                                selected: root.localCategoryFilter === modelData
                                chipHeight: 26
                                chipRadius: Theme?.radiusPill ?? 999
                                fontSize: Theme?.fontSizeXs ?? 10
                                onClicked: {
                                    root.localCategoryFilter = modelData;
                                    root.localSubCategoryFilter = "all";
                                }
                            }
                        }
                    }
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

                Flickable {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 28
                    visible: localView.uniqueSubCategories.length > 0
                    contentWidth: subCatRow.implicitWidth
                    flickableDirection: Flickable.HorizontalFlick
                    boundsBehavior: Flickable.StopAtBounds
                    clip: true

                    RowLayout {
                        id: subCatRow
                        spacing: 6

                        Text {
                            text: (Theme?.iconFolder ?? "\uE2C7") + " subfolder:"
                            font.family: Theme?.fontFamily ?? "sans-serif"
                            font.pixelSize: Theme?.fontSizeXs ?? 10
                            font.weight: Font.Medium
                            color: Theme.on_surface_variant
                            Layout.alignment: Qt.AlignVCenter
                        }

                        Repeater {
                            model: localView.uniqueSubCategories
                            delegate: Chip {
                                required property string modelData
                                label: modelData
                                selected: root.localSubCategoryFilter === modelData
                                chipHeight: 26
                                chipRadius: Theme?.radiusPill ?? 999
                                fontSize: Theme?.fontSizeXs ?? 10
                                onClicked: root.localSubCategoryFilter = modelData
                            }
                        }
                    }
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

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    GroupLabel {
                        text: (localView.filteredLocalWps ? localView.filteredLocalWps.length : 0) + " wallpapers matching"
                    }

                    Item { Layout.fillWidth: true }

                    Rectangle {
                        Layout.preferredHeight: 26
                        Layout.preferredWidth: rollText.implicitWidth + 20
                        radius: Theme?.radiusPill ?? 999
                        color: rollMouse.containsMouse ? Theme.primary_overlay : Theme.surface_container_highest
                        border.color: Theme.widgetBorder
                        border.width: 1

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 5

                            Text {
                                text: Theme?.iconShuffle ?? "\uE043"
                                font.family: Theme?.fontIcon ?? "sans-serif"
                                font.pixelSize: Theme?.fontSizeXs ?? 10
                                color: Theme.primary
                            }

                            Text {
                                id: rollText
                                text: "random from here"
                                font.family: Theme?.fontFamily ?? "sans-serif"
                                font.pixelSize: Theme?.fontSizeXs ?? 10
                                font.weight: Font.Medium
                                color: Theme.on_surface
                            }
                        }

                        MouseArea {
                            id: rollMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                let cat = "all";
                                if (root.localCategoryFilter !== "all") {
                                    cat = root.localCategoryFilter;
                                    if (root.localSubCategoryFilter !== "all") {
                                        cat = root.localCategoryFilter + "/" + root.localSubCategoryFilter;
                                    }
                                }
                                WallpaperService?.applyRandomWallpaper ? WallpaperService.applyRandomWallpaper(cat) : null;
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
                        tagAccent: modelData?.isLive || modelData?.isVideo
                        isSelected: modelData?.path === WallpaperService?.currentWallpaperPath
                        onApplyRequested: WallpaperService?.applyLocalWallpaper ? WallpaperService.applyLocalWallpaper(modelData?.path) : null
                    }
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    visible: localView.filteredLocalWps.length === 0

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 8

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: Theme?.iconFolder ?? "󰉋"
                            font.family: Theme?.fontIcon ?? "sans-serif"
                            font.pixelSize: 32
                            color: Theme.on_surface_disabled
                        }

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "no wallpapers found\ntry adjusting your category or search filter"
                            font.family: Theme?.fontFamily ?? "sans-serif"
                            font.pixelSize: Theme?.fontSizeSm ?? 12
                            color: Theme.on_surface_variant
                            horizontalAlignment: Text.AlignHCenter
                            lineHeight: 1.4
                        }
                    }
                }
            }

            // WALLHAVEN TAB
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: root.activeTab === "online"
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 38
                        color: Theme.cardBg
                        radius: Theme?.widgetRadius ?? 10
                        border.color: onlineInput.activeFocus ? Theme.primary : Theme.cardBorder
                        border.width: 1

                        Behavior on border.color { ColorAnimation { duration: Theme?.animFast ?? 150 } }

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: Theme?.widgetPaddingH ?? 10
                            spacing: 8

                            Text {
                                text: Theme?.iconSearch ?? "󰍉"
                                font.family: Theme?.fontIcon ?? "sans-serif"
                                font.pixelSize: Theme?.fontSizeSm ?? 12
                                color: onlineInput.activeFocus ? Theme.primary : Theme.on_surface_variant
                            }

                            TextInput {
                                id: onlineInput
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                verticalAlignment: TextInput.AlignVCenter
                                font.family: Theme?.fontFamily ?? "sans-serif"
                                font.pixelSize: Theme?.fontSizeSm ?? 12
                                color: Theme.on_surface
                                text: root.onlineQuery
                                selectByMouse: true
                                activeFocusOnTab: true

                                Text {
                                    text: "search wallhaven (anime, nature, cyber...)"
                                    font.family: Theme?.fontFamily ?? "sans-serif"
                                    font.pixelSize: Theme?.fontSizeSm ?? 12
                                    color: Theme.on_surface_disabled
                                    visible: onlineInput.text.length === 0 && !onlineInput.activeFocus
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Keys.onPressed: (event) => {
                                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                        fetchWallhaven(text, root.onlineSorting, 1, resInput.text);
                                        event.accepted = true;
                                    }
                                }
                            }

                            IconButton {
                                icon: Theme?.iconClose ?? "✕"
                                iconSize: 10
                                tooltip: "clear search"
                                visible: onlineInput.text.length > 0
                                onClicked: {
                                    onlineInput.text = "";
                                    fetchWallhaven("", root.onlineSorting, 1, resInput.text);
                                }
                            }

                            IconButton {
                                icon: Theme?.iconSearch ?? "󰍉"
                                tooltip: "search"
                                onClicked: fetchWallhaven(onlineInput.text, root.onlineSorting, 1, resInput.text)
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.IBeamCursor
                            propagateComposedEvents: true
                            onPressed: (mouse) => {
                                onlineInput.forceActiveFocus();
                                mouse.accepted = false;
                            }
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: 190
                        Layout.preferredHeight: 38
                        color: Theme.cardBg
                        radius: Theme?.widgetRadius ?? 10
                        border.color: resInput.activeFocus ? Theme.primary : Theme.cardBorder
                        border.width: 1

                        Behavior on border.color { ColorAnimation { duration: Theme?.animFast ?? 150 } }

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: Theme?.widgetPaddingH ?? 10
                            spacing: 6

                            Text {
                                text: "󰍹"
                                font.family: Theme?.fontIcon ?? "sans-serif"
                                font.pixelSize: Theme?.fontSizeSm ?? 12
                                color: Theme.primary
                            }

                            TextInput {
                                id: resInput
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                verticalAlignment: TextInput.AlignVCenter
                                font.family: Theme?.fontMono ?? "monospace"
                                font.pixelSize: 11
                                color: Theme.on_surface
                                text: root.onlineResolution
                                selectByMouse: true
                                activeFocusOnTab: true

                                Text {
                                    text: "res (" + root.nativeRes + ")"
                                    font.family: Theme?.fontFamily ?? "sans-serif"
                                    font.pixelSize: 10
                                    color: Theme.on_surface_disabled
                                    visible: resInput.text.length === 0 && !resInput.activeFocus
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Keys.onPressed: (event) => {
                                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                        fetchWallhaven(onlineInput.text, root.onlineSorting, 1, text);
                                        event.accepted = true;
                                    }
                                }
                            }

                            IconButton {
                                icon: Theme?.iconRefresh ?? "↺"
                                iconSize: 10
                                tooltip: "native (" + root.nativeRes + ")"
                                onClicked: {
                                    resInput.text = root.nativeRes;
                                    fetchWallhaven(onlineInput.text, root.onlineSorting, 1, root.nativeRes);
                                }
                            }

                            IconButton {
                                icon: Theme?.iconClose ?? "✕"
                                iconSize: 10
                                tooltip: "clear resolution"
                                visible: resInput.text.length > 0
                                onClicked: {
                                    resInput.text = "";
                                    fetchWallhaven(onlineInput.text, root.onlineSorting, 1, "");
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.IBeamCursor
                            propagateComposedEvents: true
                            onPressed: (mouse) => {
                                resInput.forceActiveFocus();
                                mouse.accepted = false;
                            }
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
                            chipRadius: Theme?.radiusPill ?? 999
                            chipHeight: 26
                            fontSize: Theme?.fontSizeXs ?? 10
                            onClicked: fetchWallhaven(onlineInput.text, modelData.val, 1, resInput.text)
                        }
                    }

                    Item { Layout.fillWidth: true }

                    Rectangle {
                        Layout.preferredHeight: 26
                        Layout.preferredWidth: 32
                        radius: Theme?.radiusPill ?? 999
                        color: prevMouse.containsMouse ? Theme.surface_container_high : (root.onlinePage > 1 ? Theme.surface_container_highest : Theme.surface_container_low)
                        border.color: Theme.widgetBorder
                        border.width: 1
                        opacity: root.onlinePage > 1 ? 1.0 : 0.4

                        Text {
                            text: "◀"
                            font.family: Theme?.fontMono ?? "monospace"
                            font.pixelSize: 10
                            color: Theme.on_surface
                            anchors.centerIn: parent
                        }

                        MouseArea {
                            id: prevMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            enabled: root.onlinePage > 1 && !root.isOnlineLoading
                            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: {
                                if (root.onlinePage > 1) {
                                    fetchWallhaven(onlineInput.text, root.onlineSorting, root.onlinePage - 1, resInput.text);
                                }
                            }
                        }
                    }

                    Rectangle {
                        Layout.preferredHeight: 26
                        Layout.preferredWidth: pageText.implicitWidth + 16
                        radius: Theme?.radiusPill ?? 999
                        color: Theme.surface_container_high
                        border.color: Theme.widgetBorder
                        border.width: 1

                        Text {
                            id: pageText
                            text: "page " + root.onlinePage
                            font.family: Theme?.fontFamily ?? "sans-serif"
                            font.pixelSize: Theme?.fontSizeXs ?? 10
                            font.weight: Font.Bold
                            color: Theme.primary
                            anchors.centerIn: parent
                        }
                    }

                    Rectangle {
                        Layout.preferredHeight: 26
                        Layout.preferredWidth: 32
                        radius: Theme?.radiusPill ?? 999
                        color: nextMouse.containsMouse ? Theme.surface_container_high : Theme.surface_container_highest
                        border.color: Theme.widgetBorder
                        border.width: 1

                        Text {
                            text: "▶"
                            font.family: Theme?.fontMono ?? "monospace"
                            font.pixelSize: 10
                            color: Theme.on_surface
                            anchors.centerIn: parent
                        }

                        MouseArea {
                            id: nextMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            enabled: !root.isOnlineLoading
                            cursorShape: Qt.PointingHandCursor
                            onClicked: fetchWallhaven(onlineInput.text, root.onlineSorting, root.onlinePage + 1, resInput.text)
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
                    model: onlineWpModel
                    visible: !root.isOnlineLoading && onlineWpModel.count > 0

                    WheelHandler {
                        orientation: Qt.Vertical
                        target: parent
                    }

                    delegate: WallpaperCard {
                        required property var modelData
                        width: onlineGrid.cellWidth
                        height: onlineGrid.cellHeight
                        thumbUrl: modelData.thumbUrl
                        titleText: modelData.id
                        badgeText: modelData.resolution
                        tagText: modelData.fileType
                        tagAccent: modelData.fileType === "PNG"
                        allowDownload: true
                        onApplyRequested: WallpaperService?.setWallpaper ? WallpaperService.setWallpaper(modelData.fullUrl) : null
                        onDownloadRequested: WallpaperService?.batchDownload ? WallpaperService.batchDownload([modelData.fullUrl]) : null
                    }
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    visible: root.isOnlineLoading || onlineWpModel.count === 0

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 8

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: root.isOnlineLoading ? (Theme?.iconRefresh ?? "↺") : (Theme?.iconGlobe ?? "󰖟")
                            font.family: Theme?.fontIcon ?? "sans-serif"
                            font.pixelSize: 32
                            color: root.isOnlineLoading ? Theme.primary : Theme.on_surface_disabled

                            RotationAnimator on rotation {
                                running: root.isOnlineLoading
                                loops: Animation.Infinite
                                from: 0
                                to: 360
                                duration: 1000
                            }
                        }

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: root.isOnlineLoading
                                ? ("fetching " + (root.onlineSorting === "date_added" ? "latest" : root.onlineSorting) + (root.onlineResolution ? (" " + root.onlineResolution) : "") + " wallpapers...")
                                : "no wallpapers found\ntry adjusting search or resolution"
                            font.family: Theme?.fontFamily ?? "sans-serif"
                            font.pixelSize: Theme?.fontSizeSm ?? 12
                            color: Theme.on_surface_variant
                            horizontalAlignment: Text.AlignHCenter
                            lineHeight: 1.4
                        }
                    }
                }
            }

            // LIVE TAB
            ColumnLayout {
                id: liveView
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: root.activeTab === "live"
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 38
                        radius: Theme?.widgetRadius ?? 10
                        color: Theme.cardBg
                        border.color: liveUrlInput.activeFocus ? Theme.primary : Theme.cardBorder
                        border.width: 1

                        Behavior on border.color { ColorAnimation { duration: Theme?.animFast ?? 150 } }

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: Theme?.widgetPaddingH ?? 10
                            spacing: 8

                            Text {
                                text: Theme?.iconFlame ?? "󰈸"
                                font.family: Theme?.fontIcon ?? "sans-serif"
                                font.pixelSize: Theme?.fontSizeSm ?? 12
                                color: Theme.primary
                            }

                            TextInput {
                                id: liveUrlInput
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                verticalAlignment: TextInput.AlignVCenter
                                font.family: Theme?.fontFamily ?? "sans-serif"
                                font.pixelSize: Theme?.fontSizeSm ?? 12
                                color: Theme.on_surface
                                selectByMouse: true
                                activeFocusOnTab: true

                                Text {
                                    text: "video url or file path (.mp4, .webm, .gif)..."
                                    font.family: Theme?.fontFamily ?? "sans-serif"
                                    font.pixelSize: Theme?.fontSizeSm ?? 12
                                    color: Theme.on_surface_disabled
                                    visible: liveUrlInput.text.length === 0 && !liveUrlInput.activeFocus
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                onAccepted: {
                                    if (text.trim() !== "") WallpaperService?.setWallpaper(text.trim());
                                }
                            }

                            IconButton {
                                icon: Theme?.iconClose ?? "✕"
                                tooltip: "clear input"
                                iconSize: 10
                                visible: liveUrlInput.text.length > 0
                                onClicked: liveUrlInput.text = ""
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.IBeamCursor
                            propagateComposedEvents: true
                            onPressed: (mouse) => {
                                liveUrlInput.forceActiveFocus();
                                mouse.accepted = false;
                            }
                        }
                    }

                    IconButton {
                        icon: Theme?.iconClipboard ?? "󰅌"
                        tooltip: "paste clipboard"
                        onClicked: {
                            let clip = Quickshell?.clipboardText ? Quickshell.clipboardText.trim() : "";
                            if (clip !== "") liveUrlInput.text = clip;
                        }
                    }

                    Rectangle {
                        Layout.preferredHeight: 38
                        Layout.preferredWidth: applyLiveText.implicitWidth + 24
                        radius: Theme?.widgetRadius ?? 10
                        color: liveApplyMouse.containsMouse ? Theme.primary_overlay : Theme.primary
                        border.color: Theme.primary
                        border.width: 1
                        opacity: liveUrlInput.text.trim() !== "" ? 1.0 : 0.6

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 6

                            Text {
                                text: Theme?.iconCheck ?? "✓"
                                font.family: Theme?.fontIcon ?? "sans-serif"
                                font.pixelSize: Theme?.fontSizeXs ?? 10
                                color: liveApplyMouse.containsMouse ? Theme.primary : (Theme.on_primary ?? "#ffffff")
                            }
                            Text {
                                id: applyLiveText
                                text: "apply"
                                font.family: Theme?.fontFamily ?? "sans-serif"
                                font.pixelSize: Theme?.fontSizeSm ?? 12
                                font.weight: Font.Bold
                                color: liveApplyMouse.containsMouse ? Theme.primary : (Theme.on_primary ?? "#ffffff")
                            }
                        }

                        MouseArea {
                            id: liveApplyMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (liveUrlInput.text.trim() !== "") {
                                    WallpaperService?.setWallpaper(liveUrlInput.text.trim());
                                }
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Chip {
                        label: "local live (" + root.localLiveWallpapers.length + ")"
                        selected: root.liveSubTab === "local"
                        chipHeight: 26
                        chipRadius: Theme?.radiusPill ?? 999
                        fontSize: Theme?.fontSizeXs ?? 10
                        onClicked: root.liveSubTab = "local"
                    }

                    Chip {
                        label: "online streams (" + liveWpModel.count + ")"
                        selected: root.liveSubTab === "online"
                        chipHeight: 26
                        chipRadius: Theme?.radiusPill ?? 999
                        fontSize: Theme?.fontSizeXs ?? 10
                        onClicked: {
                            root.liveSubTab = "online";
                            if (liveWpModel.count === 0) fetchLiveWallpapers(root.liveSearchQuery);
                        }
                    }

                    Item { Layout.fillWidth: true }
                }

                GridView {
                    id: liveGrid
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    cellWidth: width / 3
                    cellHeight: cellWidth * 0.65
                    model: root.liveSubTab === "local" ? root.localLiveWallpapers : liveWpModel
                    visible: (root.liveSubTab === "local" ? root.localLiveWallpapers.length : liveWpModel.count) > 0

                    WheelHandler {
                        orientation: Qt.Vertical
                        target: parent
                    }

                    delegate: WallpaperCard {
                        required property var modelData
                        width: liveGrid.cellWidth
                        height: liveGrid.cellHeight
                        thumbUrl: modelData?.thumb || modelData?.url || modelData?.path || ""
                        titleText: modelData?.name || modelData?.title || "live wallpaper"
                        badgeText: (modelData?.isVideo ? "VIDEO" : (modelData?.isGif ? "GIF" : "STREAM"))
                        tagText: (modelData?.ext ?? "LIVE").toUpperCase()
                        tagAccent: true
                        isSelected: modelData?.path === WallpaperService?.currentWallpaperPath
                        onApplyRequested: {
                            let p = modelData?.path || modelData?.url;
                            if (root.liveSubTab === "local" && WallpaperService?.applyLocalWallpaper) {
                                WallpaperService.applyLocalWallpaper(p);
                            } else {
                                WallpaperService?.setWallpaper(p);
                            }
                        }
                    }
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    visible: (root.liveSubTab === "local" ? root.localLiveWallpapers.length : liveWpModel.count) === 0

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 8

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: Theme?.iconFlame ?? "󰈸"
                            font.family: Theme?.fontIcon ?? "sans-serif"
                            font.pixelSize: 32
                            color: Theme.on_surface_disabled
                        }

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "no live wallpapers found"
                            font.family: Theme?.fontFamily ?? "sans-serif"
                            font.pixelSize: Theme?.fontSizeSm ?? 12
                            color: Theme.on_surface_variant
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }
                }
            }

            // EFFECTS & THEME TAB
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
                    spacing: 12

                    CategoryHeader {
                        title: "matugen color extraction & theme"
                        icon: Theme?.iconPalette ?? "󰏘"
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Chip {
                            label: (Theme?.iconMoon ?? "󰖔") + "  dark mode"
                            selected: WallpaperService?.currentMode === "dark"
                            fillWidth: true
                            chipRadius: Theme?.radiusPill ?? 999
                            chipHeight: 32
                            onClicked: WallpaperService?.setMode ? WallpaperService.setMode("dark") : null
                        }

                        Chip {
                            label: (Theme?.iconSun ?? "󰖙") + "  light mode"
                            selected: WallpaperService?.currentMode === "light"
                            fillWidth: true
                            chipRadius: Theme?.radiusPill ?? 999
                            chipHeight: 32
                            onClicked: WallpaperService?.setMode ? WallpaperService.setMode("light") : null
                        }
                    }

                    GroupLabel { text: "matugen scheme type" }

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
                                chipRadius: Theme?.radiusPill ?? 999
                                chipHeight: 26
                                fontSize: Theme?.fontSizeXs ?? 10
                                onClicked: WallpaperService?.setScheme ? WallpaperService.setScheme(modelData.val) : null
                            }
                        }
                    }

                    GroupLabel { text: "custom hex color override" }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Rectangle {
                            Layout.preferredWidth: 38
                            Layout.preferredHeight: 38
                            radius: Theme?.radiusPill ?? 999
                            color: {
                                let h = hexInput.text.trim();
                                return (h.startsWith("#") && (h.length === 7 || h.length === 9)) ? h : Theme.primary;
                            }
                            border.color: Theme.on_surface
                            border.width: 1
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 38
                            radius: Theme?.widgetRadius ?? 10
                            color: Theme.cardBg
                            border.color: hexInput.activeFocus ? Theme.primary : Theme.cardBorder
                            border.width: 1

                            Behavior on border.color { ColorAnimation { duration: Theme?.animFast ?? 150 } }

                            TextInput {
                                id: hexInput
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                verticalAlignment: TextInput.AlignVCenter
                                text: Theme?.source_color || "#a8c8ff"
                                font.family: Theme?.fontMono ?? "monospace"
                                font.pixelSize: 11
                                color: Theme.on_surface
                                selectByMouse: true
                                activeFocusOnTab: true
                                onAccepted: {
                                    let h = text.trim();
                                    if (h.startsWith("#") && (h.length === 7 || h.length === 9)) {
                                        WallpaperService?.applyColor ? WallpaperService.applyColor(h) : null;
                                    }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.IBeamCursor
                                propagateComposedEvents: true
                                onPressed: (mouse) => {
                                    hexInput.forceActiveFocus();
                                    mouse.accepted = false;
                                }
                            }
                        }

                        Rectangle {
                            Layout.preferredWidth: 68
                            Layout.preferredHeight: 38
                            radius: Theme?.widgetRadius ?? 10
                            color: applyHexMouse.containsMouse ? Theme.primary_overlay : Theme.primary
                            border.color: Theme.primary
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: "apply"
                                font.family: Theme?.fontFamily ?? "sans-serif"
                                font.pixelSize: Theme?.fontSizeXs ?? 10
                                font.weight: Font.Bold
                                color: applyHexMouse.containsMouse ? Theme.primary : (Theme.on_primary ?? "#ffffff")
                            }

                            MouseArea {
                                id: applyHexMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    let h = hexInput.text.trim();
                                    if (h.startsWith("#") && (h.length === 7 || h.length === 9)) {
                                        WallpaperService?.applyColor ? WallpaperService.applyColor(h) : null;
                                    }
                                }
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Repeater {
                            model: [
                                "#a8c8ff", "#ffb4ab", "#c8bfff", "#8bf0ba",
                                "#ffd700", "#ff7597", "#70d6ff", "#e7c6ff",
                                "#ff9e00", "#50fa7b", "#bd93f9", "#ff79c6"
                            ]

                            delegate: Rectangle {
                                required property string modelData
                                Layout.fillWidth: true
                                Layout.preferredHeight: 24
                                radius: Theme?.radiusPill ?? 999
                                color: modelData
                                border.color: hexInput.text === modelData ? Theme.on_surface : Theme.alpha(Theme.outline, 0.3)
                                border.width: hexInput.text === modelData ? 2 : 1

                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        hexInput.text = modelData;
                                        WallpaperService?.applyColor ? WallpaperService.applyColor(modelData) : null;
                                    }
                                }
                            }
                        }
                    }

                    CategoryHeader {
                        title: "awww transition engine"
                        icon: Theme?.iconFlame ?? "󰈸"
                    }

                    GroupLabel { text: "image resize & aspect mode" }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Repeater {
                            model: [
                                { label: "crop (fill)", val: "crop" },
                                { label: "fit (letterbox)", val: "fit" },
                                { label: "stretch", val: "stretch" },
                                { label: "no resize", val: "no" }
                            ]

                            delegate: Chip {
                                required property var modelData
                                readonly property string currentResize: Settings?.awwwResize ?? "crop"
                                label: modelData.label
                                selected: currentResize === modelData.val
                                fillWidth: true
                                chipRadius: Theme?.radiusPill ?? 999
                                chipHeight: 26
                                fontSize: Theme?.fontSizeXs ?? 10
                                onClicked: {
                                    if (Settings) {
                                        Settings.awwwResize = modelData.val;
                                        if (Settings.save) Settings.save();
                                    }
                                    WallpaperService?.reapplyTheme ? WallpaperService.reapplyTheme() : null;
                                }
                            }
                        }
                    }

                    GroupLabel { text: "transition type" }

                    GridLayout {
                        Layout.fillWidth: true
                        columns: 5
                        rowSpacing: 6
                        columnSpacing: 6

                        Repeater {
                            model: ["fade", "simple", "wipe", "wave", "grow", "center", "outer", "any", "random", "left", "right", "top", "bottom", "none"]

                            delegate: Chip {
                                required property string modelData
                                readonly property string currentVal: Settings?.awwwTransitionType ?? "fade"
                                label: modelData
                                selected: currentVal === modelData
                                fillWidth: true
                                chipRadius: Theme?.radiusPill ?? 999
                                chipHeight: 26
                                fontSize: Theme?.fontSizeXs ?? 10
                                onClicked: {
                                    if (Settings) {
                                        Settings.awwwTransitionType = modelData;
                                        if (Settings.save) Settings.save();
                                    }
                                }
                            }
                        }
                    }

                    GroupLabel {
                        text: "transition angle (wipe / wave)"
                        visible: {
                            let t = Settings?.awwwTransitionType ?? "fade";
                            return t === "wipe" || t === "wave";
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6
                        visible: {
                            let t = Settings?.awwwTransitionType ?? "fade";
                            return t === "wipe" || t === "wave";
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
                                readonly property int currentAngle: Settings?.awwwTransitionAngle ?? 0
                                label: modelData.label
                                selected: currentAngle === modelData.val
                                fillWidth: true
                                chipRadius: Theme?.radiusPill ?? 999
                                chipHeight: 26
                                fontSize: Theme?.fontSizeXs ?? 10
                                onClicked: {
                                    if (Settings) {
                                        Settings.awwwTransitionAngle = modelData.val;
                                        if (Settings.save) Settings.save();
                                    }
                                }
                            }
                        }
                    }

                    GroupLabel {
                        text: "circle origin position (grow / outer)"
                        visible: {
                            let t = Settings?.awwwTransitionType ?? "fade";
                            return t === "grow" || t === "outer";
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6
                        visible: {
                            let t = Settings?.awwwTransitionType ?? "fade";
                            return t === "grow" || t === "outer";
                        }

                        Repeater {
                            model: ["center", "top", "bottom", "left", "right"]

                            delegate: Chip {
                                required property string modelData
                                readonly property string currentPos: Settings?.awwwTransitionPos ?? "center"
                                label: modelData
                                selected: currentPos === modelData
                                fillWidth: true
                                chipRadius: Theme?.radiusPill ?? 999
                                chipHeight: 26
                                fontSize: Theme?.fontSizeXs ?? 10
                                onClicked: {
                                    if (Settings) {
                                        Settings.awwwTransitionPos = modelData;
                                        if (Settings.save) Settings.save();
                                    }
                                }
                            }
                        }
                    }

                    GroupLabel { text: "transition frame rate (fps)" }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Repeater {
                            model: [
                                { label: "30 fps", val: 30 }, { label: "60 fps", val: 60 },
                                { label: "90 fps", val: 90 }, { label: "120 fps", val: 120 },
                                { label: "144 fps", val: 144 }, { label: "165 fps", val: 165 },
                                { label: "240 fps", val: 240 }
                            ]

                            delegate: Chip {
                                required property var modelData
                                readonly property int currentFps: Settings?.awwwTransitionFps ?? 60
                                label: modelData.label
                                selected: currentFps === modelData.val
                                fillWidth: true
                                chipRadius: Theme?.radiusPill ?? 999
                                chipHeight: 26
                                fontSize: Theme?.fontSizeXs ?? 10
                                onClicked: {
                                    if (Settings) {
                                        Settings.awwwTransitionFps = modelData.val;
                                        if (Settings.save) Settings.save();
                                    }
                                }
                            }
                        }
                    }

                    GroupLabel { text: "awww scaling filter" }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Repeater {
                            model: ["Lanczos3", "Bilinear", "CatmullRom", "Mitchell", "Nearest"]

                            delegate: Chip {
                                required property string modelData
                                readonly property string currentFilter: Settings?.awwwFilter ?? "Lanczos3"
                                label: modelData.toLowerCase()
                                selected: currentFilter === modelData
                                fillWidth: true
                                chipRadius: Theme?.radiusPill ?? 999
                                chipHeight: 26
                                fontSize: Theme?.fontSizeXs ?? 10
                                onClicked: {
                                    if (Settings) {
                                        Settings.awwwFilter = modelData;
                                        if (Settings.save) Settings.save();
                                    }
                                }
                            }
                        }
                    }

                    CategoryHeader {
                        title: "mpvpaper live video engine"
                        icon: Theme?.iconFilm ?? "󰿎"
                    }

                    GroupLabel { text: "video scaling & crop mode (panscan)" }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Repeater {
                            model: [
                                { label: "crop to fill (no black bars)", val: 1.0 },
                                { label: "fit / letterbox", val: 0.0 },
                                { label: "balanced zoom", val: 0.5 }
                            ]

                            delegate: Chip {
                                required property var modelData
                                label: modelData.label
                                selected: Math.abs((Settings?.mpvPanscan ?? 1.0) - modelData.val) < 0.05
                                fillWidth: true
                                chipRadius: Theme?.radiusPill ?? 999
                                chipHeight: 26
                                fontSize: Theme?.fontSizeXs ?? 10
                                onClicked: {
                                    if (Settings) {
                                        Settings.mpvPanscan = modelData.val;
                                        if (Settings.save) Settings.save();
                                    }
                                    WallpaperService?.reapplyTheme ? WallpaperService.reapplyTheme() : null;
                                }
                            }
                        }
                    }

                    GroupLabel { text: "video audio playback" }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Chip {
                            label: (Theme?.iconVolMute ?? "󰝟") + "  mute audio"
                            selected: !(Settings?.mpvAudio ?? false)
                            fillWidth: true
                            chipRadius: Theme?.radiusPill ?? 999
                            chipHeight: 28
                            onClicked: {
                                if (Settings) {
                                    Settings.mpvAudio = false;
                                    if (Settings.save) Settings.save();
                                }
                                WallpaperService?.reapplyTheme ? WallpaperService.reapplyTheme() : null;
                            }
                        }

                        Chip {
                            label: (Theme?.iconVolHigh ?? "󰕾") + "  play ambient sound"
                            selected: Settings?.mpvAudio ?? false
                            fillWidth: true
                            chipRadius: Theme?.radiusPill ?? 999
                            chipHeight: 28
                            onClicked: {
                                if (Settings) {
                                    Settings.mpvAudio = true;
                                    if (Settings.save) Settings.save();
                                }
                                WallpaperService?.reapplyTheme ? WallpaperService.reapplyTheme() : null;
                            }
                        }
                    }
                }
            }
        }
    }
}