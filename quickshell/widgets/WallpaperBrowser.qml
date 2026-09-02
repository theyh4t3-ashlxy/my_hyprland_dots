import QtQuick
import QtQuick.Layouts
import ".."
import Quickshell
import Quickshell.Io

Rectangle {
    id: root
    implicitWidth: Theme.isVertical ? Theme.barHeight - 8 : wpRow.implicitWidth + 24
    implicitHeight: Theme.barHeight - 8
    radius: Theme.radiusPill
    color: popup.open ? Theme.primary_overlay : (wpMouse.containsMouse ? Theme.pillHover : Theme.pillBg)
    border.color: Theme.pillBorder
    border.width: Theme.pillBorder === "transparent" ? 0 : 1
    visible: Settings.showWallpaper

    Behavior on color { ColorAnimation { duration: Theme.animFast } }
    Behavior on border.color { ColorAnimation { duration: Theme.animFast } }

    property string activeTab: "local" // "local", "online", "theme"
    property string localCategoryFilter: "all"
    property string localSubCategoryFilter: "all"
    property string localSearchQuery: ""
    property string onlineQuery: "anime"
    property string onlineSorting: "random"
    property int onlinePage: 1
    property bool isOnlineLoading: false

    ListModel {
        id: localWpModel
    }

    ListModel {
        id: localLiveWpModel
    }

    ListModel {
        id: onlineWpModel
    }

    ListModel {
        id: liveWpModel
    }

    property string liveSearchQuery: ""

    property FileView liveWpFile: FileView {
        path: "/tmp/qs_live_wallpapers.json"
        watchChanges: true
        printErrors: false
        onFileChanged: {
            reload();
            root.loadLiveFromJson(text());
        }
    }

    function fetchLiveWallpapers(q) {
        Quickshell.execDetached(["python3", "/home/ashley/.config/quickshell/scripts/fetch_live_wallpapers.py", q || ""]);
        liveParseTimer.restart();
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

    function reloadLocalWallpapers() {
        WallpaperService.scanLocalWallpapers()
        parseLocalTimer.restart()
    }

    Timer {
        id: parseLocalTimer
        interval: 150
        repeat: false
        onTriggered: {
            WallpaperService.localWpListFile.reload();
            let str = WallpaperService.localWpListFile.text();
            if (!str || str.trim() === "") return;
            try {
                let items = JSON.parse(str);
                localWpModel.clear();
                localLiveWpModel.clear();
                for (let i = 0; i < items.length; i++) {
                    localWpModel.append(items[i]);
                    if (items[i].isVideo || items[i].isGif || items[i].isLive || items[i].ext === "gif" || items[i].ext === "mp4" || items[i].ext === "webm") {
                        localLiveWpModel.append(items[i]);
                    }
                }
            } catch(e) {}
        }
    }

    function fetchWallhaven(query, sort, page) {
        root.isOnlineLoading = true
        let req = new XMLHttpRequest()
        let q = query && query.trim() !== "" ? query.trim() : "anime"
        let s = sort || root.onlineSorting || "random"
        let p = page || 1
        root.onlineQuery = q
        root.onlineSorting = s
        root.onlinePage = p

        let url = "https://wallhaven.cc/api/v1/search?q=" + encodeURIComponent(q) + "&sorting=" + encodeURIComponent(s) + "&page=" + p
        req.open("GET", url)
        req.onreadystatechange = function() {
            if (req.readyState === XMLHttpRequest.DONE) {
                root.isOnlineLoading = false
                if (req.status === 200) {
                    try {
                        let data = JSON.parse(req.responseText).data
                        onlineWpModel.clear()
                        for (let i = 0; i < data.length; i++) {
                            onlineWpModel.append({
                                thumbUrl: data[i].thumbs.small,
                                fullUrl: data[i].path,
                                id: data[i].id
                            })
                        }
                    } catch (e) {}
                }
            }
        }
        req.send()
    }

    Row {
        id: wpRow
        anchors.centerIn: parent
        spacing: 4

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Theme.iconWallpaper
            font.family: Theme.fontIcon
            font.pixelSize: Theme.fontSizeMd
            color: popup.open ? Theme.primary : Theme.on_surface
        }
    }

    MouseArea {
        id: wpMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            popup.targetRelativeX = root.mapToItem(null, 0, 0).x + (root.width / 2)
            popup.open = !popup.open
            if (popup.open) reloadLocalWallpapers()
        }
    }

    PopupPanel {
        id: popup
        cardWidth: 620
        cardHeight: 520
        targetRelativeX: root.width / 2

        content: ColumnLayout {
            anchors.fill: parent
            spacing: Theme.widgetSpacing

            // Tabs
            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Rectangle {
                    Layout.fillWidth: true
                    height: 34
                    radius: Theme.widgetRadius
                    color: root.activeTab === "local" ? Theme.primary : Theme.surface_container_highest

                    Behavior on color { ColorAnimation { duration: Theme.animFast } }

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 4

                        Text {
                            text: Theme.iconFolder
                            font.family: Theme.fontIcon
                            font.pixelSize: Theme.fontSizeXs
                            color: root.activeTab === "local" ? Theme.on_primary : Theme.on_surface
                        }
                        Text {
                            text: "local"
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeXs
                            font.weight: Font.Bold
                            color: root.activeTab === "local" ? Theme.on_primary : Theme.on_surface
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.activeTab = "local"
                            reloadLocalWallpapers()
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 34
                    radius: Theme.widgetRadius
                    color: root.activeTab === "online" ? Theme.primary : Theme.surface_container_highest

                    Behavior on color { ColorAnimation { duration: Theme.animFast } }

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 4

                        Text {
                            text: Theme.iconGlobe
                            font.family: Theme.fontIcon
                            font.pixelSize: Theme.fontSizeXs
                            color: root.activeTab === "online" ? Theme.on_primary : Theme.on_surface
                        }
                        Text {
                            text: "wallhaven"
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeXs
                            font.weight: Font.Bold
                            color: root.activeTab === "online" ? Theme.on_primary : Theme.on_surface
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.activeTab = "online"
                            if (onlineWpModel.count === 0) fetchWallhaven(root.onlineQuery, root.onlineSorting, root.onlinePage)
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 34
                    radius: Theme.widgetRadius
                    color: root.activeTab === "live" ? Theme.primary : Theme.surface_container_highest

                    Behavior on color { ColorAnimation { duration: Theme.animFast } }

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 4

                        Text {
                            text: Theme.iconFlame
                            font.family: Theme.fontIcon
                            font.pixelSize: Theme.fontSizeXs
                            color: root.activeTab === "live" ? Theme.on_primary : Theme.on_surface
                        }
                        Text {
                            text: "live"
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeXs
                            font.weight: Font.Bold
                            color: root.activeTab === "live" ? Theme.on_primary : Theme.on_surface
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.activeTab = "live"
                            if (liveWpModel.count === 0) fetchLiveWallpapers(root.liveSearchQuery)
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 34
                    radius: Theme.widgetRadius
                    color: root.activeTab === "theme" ? Theme.primary : Theme.surface_container_highest

                    Behavior on color { ColorAnimation { duration: Theme.animFast } }

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 4

                        Text {
                            text: Theme.iconPalette
                            font.family: Theme.fontIcon
                            font.pixelSize: Theme.fontSizeXs
                            color: root.activeTab === "theme" ? Theme.on_primary : Theme.on_surface
                        }
                        Text {
                            text: "effects & theme"
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeXs
                            font.weight: Font.Bold
                            color: root.activeTab === "theme" ? Theme.on_primary : Theme.on_surface
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.activeTab = "theme"
                    }
                }

                // Random roll button
                IconButton {
                    icon: Theme.iconShuffle
                    iconSize: Theme.fontSizeSm
                    tooltip: "roll random wallpaper"
                    onClicked: {
                        let activeCat = "all"
                        if (root.localCategoryFilter !== "all") {
                            activeCat = root.localCategoryFilter
                            if (root.localSubCategoryFilter !== "all") {
                                activeCat = root.localCategoryFilter + "/" + root.localSubCategoryFilter
                            }
                        }
                        WallpaperService.applyRandomWallpaper(activeCat)
                    }
                }

                IconButton {
                    icon: Theme.iconRefresh
                    iconSize: Theme.fontSizeSm
                    tooltip: "rescan"
                    onClicked: {
                        if (root.activeTab === "local") reloadLocalWallpapers()
                        else if (root.activeTab === "online") fetchWallhaven(onlineInput.text, root.onlineSorting, root.onlinePage)
                        else WallpaperService.reapplyTheme()
                    }
                }
            }

            // Monitor Selector Chip Row
            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Text {
                    text: "monitor:"
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                    font.weight: Font.Bold
                    color: Theme.on_surface_variant
                }

                // All monitors chip
                Rectangle {
                    height: 22
                    width: allMonText.implicitWidth + 14
                    radius: Theme.radiusPill
                    color: WallpaperService.targetMonitor === "all" ? Theme.primary : Theme.cardBg
                    border.color: Theme.cardBorder
                    border.width: 1

                    Text {
                        id: allMonText
                        text: "all monitors 󰍹"
                        font.family: Theme.fontFamily
                        font.pixelSize: 9
                        font.weight: Font.Medium
                        color: WallpaperService.targetMonitor === "all" ? Theme.on_primary : Theme.on_surface
                        anchors.centerIn: parent
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: WallpaperService.targetMonitor = "all"
                    }
                }

                // Individual connected monitor chips
                Repeater {
                    model: Quickshell.screens
                    delegate: Rectangle {
                        required property var modelData
                        height: 22
                        width: monChipText.implicitWidth + 14
                        radius: Theme.radiusPill
                        color: WallpaperService.targetMonitor === modelData.name ? Theme.primary : Theme.cardBg
                        border.color: Theme.cardBorder
                        border.width: 1

                        Text {
                            id: monChipText
                            text: modelData.name
                            font.family: Theme.fontFamily
                            font.pixelSize: 9
                            font.weight: Font.Medium
                            color: WallpaperService.targetMonitor === modelData.name ? Theme.on_primary : Theme.on_surface
                            anchors.centerIn: parent
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: WallpaperService.targetMonitor = modelData.name
                        }
                    }
                }

                Item { Layout.fillWidth: true }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Theme.widgetBorder
            }

            // LIVE TAB VIEW
            ColumnLayout {
                id: liveView
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: root.activeTab === "live"
                spacing: 10

                // Direct URL or local path input card
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: liveInputCol.implicitHeight + 20
                    color: Theme.cardBg
                    radius: Theme.widgetRadius
                    border.color: Theme.cardBorder
                    border.width: 1

                    ColumnLayout {
                        id: liveInputCol
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 8

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 6

                            Text {
                                text: Theme.iconFlame
                                font.family: Theme.fontIcon
                                font.pixelSize: Theme.fontSizeSm
                                color: Theme.primary
                            }

                            Text {
                                text: "custom video / animated url or path"
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeSm
                                font.weight: Font.Bold
                                color: Theme.on_surface
                                Layout.fillWidth: true
                            }

                            Text {
                                text: ".mp4 · .webm · .gif · .webp"
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                                color: Theme.on_surface_disabled
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 6

                            Rectangle {
                                Layout.fillWidth: true
                                height: 36
                                radius: Theme.radiusSm
                                color: Theme.surface_container_highest
                                border.color: liveUrlInput.activeFocus ? Theme.primary : Theme.widgetBorder
                                border.width: 1

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: Theme.widgetPaddingH
                                    spacing: 6

                                    TextInput {
                                        id: liveUrlInput
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        verticalAlignment: TextInput.AlignVCenter
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.fontSizeSm
                                        color: Theme.on_surface
                                        selectByMouse: true
                                        onAccepted: {
                                            if (text.trim() !== "") {
                                                WallpaperService.setWallpaper(text.trim());
                                            }
                                        }
                                    }

                                    IconButton {
                                        icon: Theme.iconClose
                                        tooltip: "clear input"
                                        iconSize: 10
                                        visible: liveUrlInput.text.length > 0
                                        onClicked: liveUrlInput.text = ""
                                    }
                                }
                            }

                            // Paste from clipboard button
                            IconButton {
                                icon: Theme.iconClipboard
                                tooltip: "paste url from clipboard"
                                onClicked: {
                                    let pasteProc = Qt.createQmlObject("import Quickshell.Io; Process { id: proc; command: [\"wl-paste\"]; stdout: SplitParser { onRead: data => { liveUrlInput.text = data.trim(); } } }", root, "pasteProc");
                                    pasteProc.exited.connect(function() { pasteProc.destroy(); });
                                    pasteProc.running = true;
                                }
                            }

                            // Apply live wallpaper button
                            Rectangle {
                                height: 36
                                width: applyLiveText.implicitWidth + 24
                                radius: Theme.radiusSm
                                color: Theme.primary
                                opacity: liveUrlInput.text.trim() !== "" ? 1.0 : 0.6

                                RowLayout {
                                    anchors.centerIn: parent
                                    spacing: 4

                                    Text {
                                        text: Theme.iconCheck
                                        font.family: Theme.fontIcon
                                        font.pixelSize: Theme.fontSizeXs
                                        color: Theme.on_primary
                                    }
                                    Text {
                                        id: applyLiveText
                                        text: "apply live"
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.fontSizeSm
                                        font.weight: Font.Bold
                                        color: Theme.on_primary
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (liveUrlInput.text.trim() !== "") {
                                            WallpaperService.setWallpaper(liveUrlInput.text.trim());
                                        }
                                    }
                                }
                            }
                        }

                        // Curated sample preset chips
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 6

                            Text {
                                text: "sample presets:"
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                                color: Theme.on_surface_variant
                            }

                            Repeater {
                                model: [
                                    { label: "pixel rain", url: "https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExdWU0MXhnbG05Mm11YWN5a2RmcGlkMGt1dXpnNnRpdDJva24ya3A2ayZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/3o7TKTDnUxE6uQja4U/giphy.gif" },
                                    { label: "lofi room", url: "https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExMHU2MnRhZW03NXpiOG1vd24xaWtvbTllYmg0cW81djE5OTl2YnBkayZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/LmNwrBhejkK9EFP504/giphy.gif" },
                                    { label: "cyberpunk train", url: "https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExNmtvaDVqbzZ2dHB1YXZsNWF5dWp2b3hpd2g4ODNsd28xNXc1OTU4NiZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/3oKIPnAiaMCws8nOsE/giphy.gif" },
                                    { label: "space nebula", url: "https://media.giphy.com/media/v1.Y2lkPTc5MGI3NjExOTR0NGh0d2R2dWd1dmZobnlvaHQ4MGoxbHRid2M4M21udmVvM3JmZSZlcD12MV9pbnRlcm5hbF9naWZfYnlfaWQmY3Q9Zw/l0MYEqEzwMWFCg8rm/giphy.gif" }
                                ]
                                delegate: Rectangle {
                                    required property var modelData
                                    height: 22
                                    width: pChipText.implicitWidth + 10
                                    radius: Theme.radiusPill
                                    color: Theme.pillBg
                                    border.color: Theme.pillBorder
                                    border.width: 1

                                    Text {
                                        id: pChipText
                                        text: modelData.label
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 9
                                        color: Theme.on_surface
                                        anchors.centerIn: parent
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            liveUrlInput.text = modelData.url;
                                            WallpaperService.setWallpaper(modelData.url);
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // Subheader for local live collection
                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        text: "your local live wallpapers (" + localLiveWpModel.count + ")"
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeSm
                        font.weight: Font.Bold
                        color: Theme.primary
                        Layout.fillWidth: true
                    }

                    Text {
                        text: "auto-extracted matugen palette"
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                        color: Theme.on_surface_disabled
                    }
                }

                GridView {
                    id: liveGrid
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    cellWidth: width / 2
                    cellHeight: cellWidth * 0.65
                    model: localLiveWpModel

                    delegate: Item {
                        required property var modelData
                        property string path: modelData.path
                        property string thumb: modelData.thumb || modelData.path
                        property string name: modelData.name
                        property string ext: modelData.ext ?? "live"
                        property bool isVideo: modelData.isVideo ?? false
                        property bool isGif: modelData.isGif ?? false

                        width: liveGrid.cellWidth
                        height: liveGrid.cellHeight

                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 4
                            color: Theme.surface_container_high
                            radius: Theme.widgetRadius
                            clip: true
                            border.color: liveLocMouse.containsMouse ? Theme.primary : "transparent"
                            border.width: 1

                            Image {
                                anchors.fill: parent
                                source: "file://" + thumb
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                            }

                            Rectangle {
                                anchors.top: parent.top
                                anchors.right: parent.right
                                anchors.margins: 6
                                height: 16
                                width: lBadgeText.implicitWidth + 8
                                radius: 4
                                color: Theme.primary

                                Text {
                                    id: lBadgeText
                                    text: isVideo ? "LIVE VIDEO" : (isGif ? "ANIMATED GIF" : ext.toUpperCase())
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 8
                                    font.weight: Font.Bold
                                    color: Theme.on_primary
                                    anchors.centerIn: parent
                                }
                            }

                            // title overlay on hover
                            Rectangle {
                                anchors.bottom: parent.bottom
                                anchors.left: parent.left
                                anchors.right: parent.right
                                height: 24
                                color: Qt.rgba(0, 0, 0, 0.75)
                                visible: liveLocMouse.containsMouse

                                Text {
                                    text: name
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSizeXs
                                    color: "#ffffff"
                                    elide: Text.ElideRight
                                    anchors.centerIn: parent
                                    width: parent.width - 8
                                    horizontalAlignment: Text.AlignHCenter
                                }
                            }

                            MouseArea {
                                id: liveLocMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    WallpaperService.applyLocalWallpaper(path);
                                }
                            }
                        }
                    }
                }
            }

            // local tab view so it doesnt explode
            ColumnLayout {
                id: localView
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: root.activeTab === "local"
                spacing: 8

                // Search Bar for Local
                Rectangle {
                    Layout.fillWidth: true
                    height: 36
                    color: Theme.surface_container_highest
                    radius: Theme.widgetRadius
                    border.color: localSearchInput.activeFocus ? Theme.primary : Theme.widgetBorder
                    border.width: 1

                    Behavior on border.color { ColorAnimation { duration: Theme.animFast } }

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: Theme.widgetPaddingH
                        spacing: 8

                        Text {
                            text: Theme.iconSearch
                            font.family: Theme.fontIcon
                            font.pixelSize: Theme.fontSizeSm
                            color: Theme.on_surface_variant
                        }

                        TextInput {
                            id: localSearchInput
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            verticalAlignment: TextInput.AlignVCenter
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeSm
                            color: Theme.on_surface
                            onTextChanged: root.localSearchQuery = text.toLowerCase()
                        }
                    }
                }

                // Top-Level Category Chips
                readonly property var uniqueParentCategories: {
                    let cats = ["all"];
                    for (let i = 0; i < localWpModel.count; i++) {
                        let pCat = localWpModel.get(i).parentCategory || "root";
                        if (pCat && cats.indexOf(pCat) === -1) {
                            cats.push(pCat);
                        }
                    }
                    return cats;
                }

                Flickable {
                    Layout.fillWidth: true
                    height: 28
                    contentWidth: catRow.width
                    flickableDirection: Flickable.HorizontalFlick
                    clip: true

                    RowLayout {
                        id: catRow
                        spacing: 6

                        Repeater {
                            model: localView.uniqueParentCategories

                            delegate: Rectangle {
                                required property string modelData
                                height: 26
                                width: catText.implicitWidth + 16
                                radius: Theme.radiusPill
                                color: root.localCategoryFilter === modelData ? Theme.primary : Theme.surface_container_high

                                Text {
                                    id: catText
                                    text: modelData
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSizeXs
                                    font.weight: Font.Medium
                                    color: root.localCategoryFilter === modelData ? Theme.on_primary : Theme.on_surface
                                    anchors.centerIn: parent
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        root.localCategoryFilter = modelData
                                        root.localSubCategoryFilter = "all"
                                    }
                                }
                            }
                        }
                    }
                }

                // Nested Subcategory Chips (when selected category has subfolders)
                readonly property var uniqueSubCategories: {
                    if (root.localCategoryFilter === "all") return [];
                    let subs = ["all"];
                    for (let i = 0; i < localWpModel.count; i++) {
                        let item = localWpModel.get(i);
                        if (item.parentCategory === root.localCategoryFilter && item.subCategory && item.subCategory !== "") {
                            if (subs.indexOf(item.subCategory) === -1) {
                                subs.push(item.subCategory);
                            }
                        }
                    }
                    return subs.length > 1 ? subs : [];
                }

                Flickable {
                    Layout.fillWidth: true
                    height: 26
                    visible: localView.uniqueSubCategories.length > 0
                    contentWidth: subCatRow.width
                    flickableDirection: Flickable.HorizontalFlick
                    clip: true

                    RowLayout {
                        id: subCatRow
                        spacing: 6

                        Text {
                            text: "󰉋 subfolder:"
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeXs
                            color: Theme.on_surface_variant
                            Layout.alignment: Qt.AlignVCenter
                        }

                        Repeater {
                            model: localView.uniqueSubCategories

                            delegate: Rectangle {
                                required property string modelData
                                height: 22
                                width: subCatText.implicitWidth + 14
                                radius: Theme.radiusPill
                                color: root.localSubCategoryFilter === modelData ? Theme.primary : Theme.surface_container_highest

                                Text {
                                    id: subCatText
                                    text: modelData
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 10
                                    font.weight: Font.Medium
                                    color: root.localSubCategoryFilter === modelData ? Theme.on_primary : Theme.on_surface
                                    anchors.centerIn: parent
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.localSubCategoryFilter = modelData
                                }
                            }
                        }
                    }
                }

                // Filtered local list
                readonly property var filteredLocalWps: {
                    let result = [];
                    for (let i = 0; i < localWpModel.count; i++) {
                        let item = localWpModel.get(i);
                        let pMatch = root.localCategoryFilter === "all" || item.parentCategory === root.localCategoryFilter || item.category.indexOf(root.localCategoryFilter) !== -1;
                        let subMatch = root.localSubCategoryFilter === "all" || item.subCategory === root.localSubCategoryFilter;
                        let sQuery = root.localSearchQuery.trim();
                        let searchMatch = sQuery === "" || item.name.toLowerCase().indexOf(sQuery) !== -1 || item.category.toLowerCase().indexOf(sQuery) !== -1;

                        if (pMatch && subMatch && searchMatch) {
                            result.push(item);
                        }
                    }
                    return result;
                }

                // Category summary and roll-random banner
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Text {
                        text: (localView.filteredLocalWps ? localView.filteredLocalWps.length : 0) + " wallpapers"
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeXs
                        color: Theme.on_surface_variant
                    }

                    Item { Layout.fillWidth: true }

                    Rectangle {
                        height: 24
                        width: rollText.implicitWidth + 18
                        radius: Theme.radiusPill
                        color: Theme.surface_container_highest

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 4
                            Text {
                                text: "󰒝"
                                font.family: Theme.fontMono
                                font.pixelSize: 10
                                color: Theme.primary
                            }
                            Text {
                                id: rollText
                                text: "random from here"
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                                font.weight: Font.Medium
                                color: Theme.on_surface
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                let cat = "all"
                                if (root.localCategoryFilter !== "all") {
                                    cat = root.localCategoryFilter
                                    if (root.localSubCategoryFilter !== "all") {
                                        cat = root.localCategoryFilter + "/" + root.localSubCategoryFilter
                                    }
                                }
                                WallpaperService.applyRandomWallpaper(cat)
                            }
                        }
                    }
                }

                GridView {
                    id: localGrid
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    cellWidth: width / 2
                    cellHeight: cellWidth * 0.65

                    model: parent.filteredLocalWps

                    delegate: Item {
                        required property var modelData
                        property string path: modelData.path
                        property string thumb: modelData.thumb || modelData.path
                        property string name: modelData.name
                        property string category: modelData.category
                        property bool isLive: modelData.isLive ?? false
                        property bool isVideo: modelData.isVideo ?? false
                        property bool isGif: modelData.isGif ?? false
                        property string ext: modelData.ext ?? ""

                        width: localGrid.cellWidth
                        height: localGrid.cellHeight

                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 4
                            color: Theme.surface_container_high
                            radius: Theme.widgetRadius
                            clip: true
                            border.color: locMouse.containsMouse ? Theme.primary : "transparent"
                            border.width: 1

                            Image {
                                anchors.fill: parent
                                source: "file://" + thumb
                                sourceSize: Qt.size(240, 156)
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                            }

                            // category badge
                            Rectangle {
                                anchors.top: parent.top
                                anchors.left: parent.left
                                anchors.margins: 6
                                height: 16
                                width: badgeText.implicitWidth + 8
                                radius: 4
                                color: Qt.rgba(0, 0, 0, 0.65)

                                Text {
                                    id: badgeText
                                    text: category
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 8
                                    color: "#ffffff"
                                    anchors.centerIn: parent
                                }
                            }

                            // live / format badge
                            Rectangle {
                                anchors.top: parent.top
                                anchors.right: parent.right
                                anchors.margins: 6
                                height: 16
                                width: formatBadgeText.implicitWidth + 8
                                radius: 4
                                color: isLive ? Theme.primary : Qt.rgba(0, 0, 0, 0.65)
                                visible: isLive || (ext !== "png" && ext !== "jpg" && ext !== "")

                                Text {
                                    id: formatBadgeText
                                    text: isVideo ? "LIVE" : (isGif ? "GIF" : ext.toUpperCase())
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 8
                                    font.weight: Font.Bold
                                    color: isLive ? Theme.on_primary : "#ffffff"
                                    anchors.centerIn: parent
                                }
                            }

                            // title overlay on hover
                            Rectangle {
                                anchors.bottom: parent.bottom
                                anchors.left: parent.left
                                anchors.right: parent.right
                                height: 22
                                color: Qt.rgba(0, 0, 0, 0.7)
                                visible: locMouse.containsMouse

                                Text {
                                    text: name
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSizeXs
                                    color: "#ffffff"
                                    elide: Text.ElideRight
                                    anchors.centerIn: parent
                                    width: parent.width - 8
                                    horizontalAlignment: Text.AlignHCenter
                                }
                            }

                            MouseArea {
                                id: locMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    WallpaperService.applyLocalWallpaper(path)
                                }
                            }
                        }
                    }
                }
            }

            // online tab view (wallhaven) so it doesnt explode
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: root.activeTab === "online"
                spacing: 8

                // Online Search Bar
                Rectangle {
                    Layout.fillWidth: true
                    height: 36
                    color: Theme.surface_container_highest
                    radius: Theme.widgetRadius
                    border.color: onlineInput.activeFocus ? Theme.primary : Theme.widgetBorder
                    border.width: 1

                    Behavior on border.color { ColorAnimation { duration: Theme.animFast } }

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: Theme.widgetPaddingH
                        spacing: 8

                        Text {
                            text: Theme.iconSearch
                            font.family: Theme.fontIcon
                            font.pixelSize: Theme.fontSizeSm
                            color: Theme.on_surface_variant
                        }

                        TextInput {
                            id: onlineInput
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            verticalAlignment: TextInput.AlignVCenter
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeSm
                            color: Theme.on_surface
                            text: root.onlineQuery

                            Keys.onPressed: (event) => {
                                if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                    fetchWallhaven(text, root.onlineSorting, 1)
                                    event.accepted = true
                                }
                            }
                        }

                        IconButton {
                            icon: Theme.iconSearch
                            iconSize: Theme.fontSizeSm
                            onClicked: fetchWallhaven(onlineInput.text, root.onlineSorting, 1)
                        }
                    }
                }

                // Preset Tag Chips
                Flickable {
                    Layout.fillWidth: true
                    height: 26
                    contentWidth: tagRow.width
                    flickableDirection: Flickable.HorizontalFlick
                    clip: true

                    RowLayout {
                        id: tagRow
                        spacing: 6

                        Repeater {
                            model: ["anime", "cyberpunk", "landscape", "minimalist", "dark", "pixel art", "space", "nature"]

                            delegate: Rectangle {
                                required property string modelData
                                height: 24
                                width: tagText.implicitWidth + 14
                                radius: Theme.radiusPill
                                color: root.onlineQuery === modelData ? Theme.primary : Theme.surface_container_high

                                Text {
                                    id: tagText
                                    text: modelData
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 10
                                    font.weight: Font.Medium
                                    color: root.onlineQuery === modelData ? Theme.on_primary : Theme.on_surface
                                    anchors.centerIn: parent
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        onlineInput.text = modelData
                                        fetchWallhaven(modelData, root.onlineSorting, 1)
                                    }
                                }
                            }
                        }
                    }
                }

                // Sorting + Pagination Bar
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    // Sorting chips
                    Repeater {
                        model: [
                            { label: "random", val: "random" },
                            { label: "toplist", val: "toplist" },
                            { label: "views", val: "views" },
                            { label: "latest", val: "date_added" }
                        ]

                        delegate: Rectangle {
                            required property var modelData
                            height: 24
                            width: sortText.implicitWidth + 12
                            radius: Theme.radiusSm
                            color: root.onlineSorting === modelData.val ? Theme.primary : Theme.surface_container_highest

                            Text {
                                id: sortText
                                text: modelData.label
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                                color: root.onlineSorting === modelData.val ? Theme.on_primary : Theme.on_surface
                                anchors.centerIn: parent
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    fetchWallhaven(onlineInput.text, modelData.val, 1)
                                }
                            }
                        }
                    }

                    Item { Layout.fillWidth: true }

                    // Left/Right pagination controls
                    Rectangle {
                        height: 24
                        width: 28
                        radius: Theme.radiusSm
                        color: root.onlinePage > 1 ? Theme.surface_container_highest : Theme.surface_container_low
                        opacity: root.onlinePage > 1 ? 1.0 : 0.4

                        Text {
                            text: "◀"
                            font.family: Theme.fontMono
                            font.pixelSize: 10
                            color: Theme.on_surface
                            anchors.centerIn: parent
                        }

                        MouseArea {
                            anchors.fill: parent
                            enabled: root.onlinePage > 1 && !root.isOnlineLoading
                            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: {
                                if (root.onlinePage > 1) {
                                    fetchWallhaven(onlineInput.text, root.onlineSorting, root.onlinePage - 1)
                                }
                            }
                        }
                    }

                    Rectangle {
                        height: 24
                        width: pageText.implicitWidth + 12
                        radius: Theme.radiusSm
                        color: Theme.surface_container_high

                        Text {
                            id: pageText
                            text: "p. " + root.onlinePage
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                            font.weight: Font.Bold
                            color: Theme.primary
                            anchors.centerIn: parent
                        }
                    }

                    Rectangle {
                        height: 24
                        width: 28
                        radius: Theme.radiusSm
                        color: Theme.surface_container_highest

                        Text {
                            text: "▶"
                            font.family: Theme.fontMono
                            font.pixelSize: 10
                            color: Theme.on_surface
                            anchors.centerIn: parent
                        }

                        MouseArea {
                            anchors.fill: parent
                            enabled: !root.isOnlineLoading
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                fetchWallhaven(onlineInput.text, root.onlineSorting, root.onlinePage + 1)
                            }
                        }
                    }
                }

                // Online Grid
                GridView {
                    id: onlineGrid
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    cellWidth: width / 2
                    cellHeight: cellWidth * 0.65
                    model: onlineWpModel
                    visible: !root.isOnlineLoading && onlineWpModel.count > 0

                    delegate: Item {
                        required property string thumbUrl
                        required property string fullUrl

                        width: onlineGrid.cellWidth
                        height: onlineGrid.cellHeight

                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 4
                            color: Theme.surface_container_high
                            radius: Theme.widgetRadius
                            clip: true
                            border.color: onMouse.containsMouse ? Theme.primary : "transparent"
                            border.width: 1

                            Image {
                                anchors.fill: parent
                                source: thumbUrl
                                sourceSize: Qt.size(240, 156)
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                            }

                            Rectangle {
                                anchors.bottom: parent.bottom
                                anchors.left: parent.left
                                anchors.right: parent.right
                                height: 22
                                color: Qt.rgba(0, 0, 0, 0.7)
                                visible: onMouse.containsMouse

                                Text {
                                    text: "click to download & apply"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 9
                                    color: "#ffffff"
                                    anchors.centerIn: parent
                                }
                            }

                            MouseArea {
                                id: onMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    WallpaperService.setWallpaper(fullUrl)
                                }
                            }
                        }
                    }
                }

                // Empty / loading state
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    visible: root.isOnlineLoading || onlineWpModel.count === 0

                    Text {
                        text: root.isOnlineLoading ? (Theme.iconRefresh + "\nfetching wallpapers from wallhaven...") : "no wallpapers found"
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeMd
                        color: Theme.on_surface_variant
                        horizontalAlignment: Text.AlignHCenter
                        anchors.centerIn: parent
                        lineHeight: 1.5
                    }
                }
            }

            // effects & theme tab view so it doesnt explode
            Flickable {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: root.activeTab === "theme"
                clip: true
                contentWidth: width
                contentHeight: themeCol.implicitHeight
                boundsBehavior: Flickable.StopAtBounds

                ColumnLayout {
                    id: themeCol
                    width: parent.width - 4
                    spacing: 12

                    // Matugen Mode
                    Text {
                        text: "matugen color mode"
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeSm
                        font.weight: Font.Bold
                        color: Theme.primary
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Rectangle {
                            Layout.fillWidth: true
                            height: 32
                            radius: Theme.widgetRadius
                            color: WallpaperService.currentMode === "dark" ? Theme.primary : Theme.surface_container_highest

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 6

                                Text {
                                    text: Theme.iconMoon
                                    font.family: Theme.fontIcon
                                    font.pixelSize: Theme.fontSizeXs
                                    color: WallpaperService.currentMode === "dark" ? Theme.on_primary : Theme.on_surface
                                }
                                Text {
                                    text: "dark mode"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSizeXs
                                    font.weight: Font.Medium
                                    color: WallpaperService.currentMode === "dark" ? Theme.on_primary : Theme.on_surface
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: WallpaperService.setMode("dark")
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            height: 32
                            radius: Theme.widgetRadius
                            color: WallpaperService.currentMode === "light" ? Theme.primary : Theme.surface_container_highest

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 6

                                Text {
                                    text: Theme.iconSun
                                    font.family: Theme.fontIcon
                                    font.pixelSize: Theme.fontSizeXs
                                    color: WallpaperService.currentMode === "light" ? Theme.on_primary : Theme.on_surface
                                }
                                Text {
                                    text: "light mode"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSizeXs
                                    font.weight: Font.Medium
                                    color: WallpaperService.currentMode === "light" ? Theme.on_primary : Theme.on_surface
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: WallpaperService.setMode("light")
                            }
                        }
                    }

                    // Scheme Type Grid
                    Text {
                        text: "matugen scheme type"
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeXs
                        color: Theme.on_surface_variant
                    }

                    GridLayout {
                        Layout.fillWidth: true
                        columns: 3
                        rowSpacing: 6
                        columnSpacing: 6

                        Repeater {
                            model: [
                                { label: "tonal spot", val: "scheme-tonal-spot" },
                                { label: "vibrant", val: "scheme-vibrant" },
                                { label: "expressive", val: "scheme-expressive" },
                                { label: "content", val: "scheme-content" },
                                { label: "fruit salad", val: "scheme-fruit-salad" },
                                { label: "rainbow", val: "scheme-rainbow" },
                                { label: "fidelity", val: "scheme-fidelity" },
                                { label: "monochrome", val: "scheme-monochrome" },
                                { label: "neutral", val: "scheme-neutral" }
                            ]

                            delegate: Rectangle {
                                required property var modelData
                                Layout.fillWidth: true
                                height: 28
                                radius: Theme.radiusSm
                                color: WallpaperService.currentSchemeType === modelData.val ? Theme.primary : Theme.surface_container_highest

                                Text {
                                    text: modelData.label
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSizeXs
                                    color: WallpaperService.currentSchemeType === modelData.val ? Theme.on_primary : Theme.on_surface
                                    anchors.centerIn: parent
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: WallpaperService.setScheme(modelData.val)
                                }
                            }
                        }
                    }

                    // Hex Color Picker & Palette Override
                    Text {
                        text: "custom hex color override"
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeXs
                        color: Theme.on_surface_variant
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Rectangle {
                            width: 32
                            height: 32
                            radius: Theme.radiusSm
                            color: {
                                let h = hexInput.text.trim()
                                return (h.startsWith("#") && (h.length === 7 || h.length === 9)) ? h : Theme.primary
                            }
                            border.color: Theme.on_surface
                            border.width: 1
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            height: 32
                            radius: Theme.radiusSm
                            color: Theme.surface_container_highest
                            border.color: hexInput.activeFocus ? Theme.primary : Theme.widgetBorder
                            border.width: 1

                            TextInput {
                                id: hexInput
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 8
                                verticalAlignment: TextInput.AlignVCenter
                                text: Theme.source_color || "#a8c8ff"
                                font.family: Theme.fontMono
                                font.pixelSize: Theme.fontSizeXs
                                color: Theme.on_surface
                                onAccepted: {
                                    let h = text.trim()
                                    if (h.startsWith("#") && (h.length === 7 || h.length === 9)) {
                                        WallpaperService.applyColor(h)
                                    }
                                }
                            }
                        }

                        Rectangle {
                            width: 64
                            height: 32
                            radius: Theme.radiusSm
                            color: applyHexMouse.containsMouse ? Theme.primary_overlay : Theme.primary

                            Text {
                                anchors.centerIn: parent
                                text: "apply"
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeXs
                                font.weight: Font.Bold
                                color: applyHexMouse.containsMouse ? Theme.primary : Theme.on_primary
                            }

                            MouseArea {
                                id: applyHexMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    let h = hexInput.text.trim()
                                    if (h.startsWith("#") && (h.length === 7 || h.length === 9)) {
                                        WallpaperService.applyColor(h)
                                    }
                                }
                            }
                        }
                    }

                    // Quick Color Swatches
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 4

                        Repeater {
                            model: [
                                "#a8c8ff", "#ffb4ab", "#c8bfff", "#8bf0ba",
                                "#ffd700", "#ff7597", "#70d6ff", "#e7c6ff",
                                "#ff9e00", "#50fa7b", "#bd93f9", "#ff79c6"
                            ]

                            delegate: Rectangle {
                                required property string modelData
                                Layout.fillWidth: true
                                height: 22
                                radius: Theme.radiusSm
                                color: modelData
                                border.color: Theme.on_surface
                                border.width: hexInput.text === modelData ? 2 : 0

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        hexInput.text = modelData
                                        WallpaperService.applyColor(modelData)
                                    }
                                }
                            }
                        }
                    }

                    // Reapply theme button
                    Rectangle {
                        Layout.fillWidth: true
                        height: 32
                        radius: Theme.widgetRadius
                        color: Theme.surface_container_high

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 6

                            Text {
                                text: Theme.iconRefresh
                                font.family: Theme.fontIcon
                                font.pixelSize: Theme.fontSizeXs
                                color: Theme.on_surface
                            }
                            Text {
                                text: "sync colors with current wallpaper"
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeXs
                                font.weight: Font.Medium
                                color: Theme.on_surface
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: WallpaperService.reapplyTheme()
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: Theme.widgetBorder
                    }

                    // awww Transitions
                    Text {
                        text: "awww transition effects"
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeSm
                        font.weight: Font.Bold
                        color: Theme.primary
                    }

                    Text {
                        text: "transition type"
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeXs
                        color: Theme.on_surface_variant
                    }

                    GridLayout {
                        Layout.fillWidth: true
                        columns: 4
                        rowSpacing: 6
                        columnSpacing: 6

                        Repeater {
                            model: ["wipe", "wave", "grow", "fade", "center", "outer", "slide", "left", "right", "top", "bottom", "any"]

                            delegate: Rectangle {
                                required property string modelData
                                Layout.fillWidth: true
                                height: 26
                                radius: Theme.radiusSm
                                color: Settings.awwwTransitionType === modelData ? Theme.primary : Theme.surface_container_highest

                                Text {
                                    text: modelData
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSizeXs
                                    color: Settings.awwwTransitionType === modelData ? Theme.on_primary : Theme.on_surface
                                    anchors.centerIn: parent
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        Settings.awwwTransitionType = modelData
                                        Settings.save()
                                    }
                                }
                            }
                        }
                    }

                    // Transition Angle
                    Text {
                        text: "transition angle"
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeXs
                        color: Theme.on_surface_variant
                    }

                    GridLayout {
                        Layout.fillWidth: true
                        columns: 5
                        rowSpacing: 6
                        columnSpacing: 6

                        Repeater {
                            model: [
                                { label: "0°", val: 0 },
                                { label: "30°", val: 30 },
                                { label: "45°", val: 45 },
                                { label: "60°", val: 60 },
                                { label: "90°", val: 90 },
                                { label: "120°", val: 120 },
                                { label: "135°", val: 135 },
                                { label: "180°", val: 180 },
                                { label: "225°", val: 225 },
                                { label: "270°", val: 270 }
                            ]

                            delegate: Rectangle {
                                required property var modelData
                                Layout.fillWidth: true
                                height: 24
                                radius: Theme.radiusSm
                                color: Settings.awwwTransitionAngle === modelData.val ? Theme.primary : Theme.surface_container_highest

                                Text {
                                    text: modelData.label
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSizeXs
                                    color: Settings.awwwTransitionAngle === modelData.val ? Theme.on_primary : Theme.on_surface
                                    anchors.centerIn: parent
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        Settings.awwwTransitionAngle = modelData.val
                                        Settings.save()
                                    }
                                }
                            }
                        }
                    }

                    // Transition FPS
                    Text {
                        text: "transition frame rate (fps)"
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeXs
                        color: Theme.on_surface_variant
                    }

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

                            delegate: Rectangle {
                                required property var modelData
                                Layout.fillWidth: true
                                height: 24
                                radius: Theme.radiusSm
                                color: Settings.awwwTransitionFps === modelData.val ? Theme.primary : Theme.surface_container_highest

                                Text {
                                    text: modelData.label
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 10
                                    color: Settings.awwwTransitionFps === modelData.val ? Theme.on_primary : Theme.on_surface
                                    anchors.centerIn: parent
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        Settings.awwwTransitionFps = modelData.val
                                        Settings.save()
                                    }
                                }
                            }
                        }
                    }

                    // Scaling Filter
                    Text {
                        text: "awww scaling filter"
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeXs
                        color: Theme.on_surface_variant
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Repeater {
                            model: ["Lanczos3", "Nearest", "CatmullRom", "Mitchell"]

                            delegate: Rectangle {
                                required property string modelData
                                Layout.fillWidth: true
                                height: 24
                                radius: Theme.radiusSm
                                color: Settings.awwwFilter === modelData ? Theme.primary : Theme.surface_container_highest

                                Text {
                                    text: modelData.toLowerCase()
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSizeXs
                                    color: Settings.awwwFilter === modelData ? Theme.on_primary : Theme.on_surface
                                    anchors.centerIn: parent
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        Settings.awwwFilter = modelData
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

                    // mpvpaper Live Video Settings
                    Text {
                        text: "mpvpaper live video controls"
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeSm
                        font.weight: Font.Bold
                        color: Theme.primary
                    }

                    Text {
                        text: "video scaling & crop mode (panscan)"
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeXs
                        color: Theme.on_surface_variant
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Repeater {
                            model: [
                                { label: "crop to fill (no black bars)", val: 1.0 },
                                { label: "fit / letterbox", val: 0.0 },
                                { label: "balanced zoom", val: 0.5 }
                            ]

                            delegate: Rectangle {
                                required property var modelData
                                Layout.fillWidth: true
                                height: 26
                                radius: Theme.radiusSm
                                color: Math.abs(Settings.mpvPanscan - modelData.val) < 0.05 ? Theme.primary : Theme.surface_container_highest

                                Text {
                                    text: modelData.label
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSizeXs
                                    color: Math.abs(Settings.mpvPanscan - modelData.val) < 0.05 ? Theme.on_primary : Theme.on_surface
                                    anchors.centerIn: parent
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        Settings.mpvPanscan = modelData.val;
                                        Settings.save();
                                        WallpaperService.reapplyTheme();
                                    }
                                }
                            }
                        }
                    }

                    Text {
                        text: "video audio"
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeXs
                        color: Theme.on_surface_variant
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Rectangle {
                            Layout.fillWidth: true
                            height: 28
                            radius: Theme.radiusSm
                            color: !Settings.mpvAudio ? Theme.primary : Theme.surface_container_highest

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 6

                                Text {
                                    text: Theme.iconVolMute
                                    font.family: Theme.fontIcon
                                    font.pixelSize: Theme.fontSizeXs
                                    color: !Settings.mpvAudio ? Theme.on_primary : Theme.on_surface
                                }
                                Text {
                                    text: "mute audio (silent)"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSizeXs
                                    font.weight: Font.Medium
                                    color: !Settings.mpvAudio ? Theme.on_primary : Theme.on_surface
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    Settings.mpvAudio = false;
                                    Settings.save();
                                    WallpaperService.reapplyTheme();
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            height: 28
                            radius: Theme.radiusSm
                            color: Settings.mpvAudio ? Theme.primary : Theme.surface_container_highest

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 6

                                Text {
                                    text: Theme.iconVolHigh
                                    font.family: Theme.fontIcon
                                    font.pixelSize: Theme.fontSizeXs
                                    color: Settings.mpvAudio ? Theme.on_primary : Theme.on_surface
                                }
                                Text {
                                    text: "play ambient sound"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSizeXs
                                    font.weight: Font.Medium
                                    color: Settings.mpvAudio ? Theme.on_primary : Theme.on_surface
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    Settings.mpvAudio = true;
                                    Settings.save();
                                    WallpaperService.reapplyTheme();
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
