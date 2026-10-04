import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Hyprland
import ".."
import "../controls"
import "../services"

PopupPanel {
    id: root

    wantsFocus: true
    keyboardFocusMode: WlrKeyboardFocus.Exclusive

    cardWidth: 480
    cardHeight: 570

    property string query: ""
    property string activeCategory: "all"
    property bool showCategoryManager: false
    property string activeManagingCatId: ""
    property string categoryAppFilter: ""
    property string newCategoryName: ""
    property string newCategoryIcon: "terminal"
    property var categoryAssignApp: null

    readonly property string cleanQuery: query.trim()
    readonly property bool isCommand: (cleanQuery.startsWith(">") || cleanQuery.startsWith("$") || cleanQuery.startsWith(":")) && (Settings?.launcherCommandEnabled ?? true)
    readonly property string cleanCommand: isCommand ? cleanQuery.slice(1).trim() : ""
    readonly property var calcResult: (Settings?.launcherCalcEnabled ?? true) && !isCommand ? evaluateMath(cleanQuery) : null

    readonly property var availableIcons: [
        { key: "terminal", icon: Theme?.iconTerminal ?? "󰆍", label: "dev" },
        { key: "globe",    icon: Theme?.iconGlobe ?? "󰖟",    label: "web" },
        { key: "music",    icon: Theme?.iconMusic ?? "󰝚",    label: "media" },
        { key: "flame",    icon: Theme?.iconFlame ?? "󰈸",    label: "games" },
        { key: "folder",   icon: Theme?.iconFolder ?? "󰉋",   label: "files" },
        { key: "settings", icon: Theme?.iconSettings ?? "󰒓", label: "sys" },
        { key: "heart",    icon: Theme?.iconHeart ?? "󰋑",    label: "fav" },
        { key: "sparkles", icon: Theme?.iconSparkles ?? "󰓏", label: "cool" },
        { key: "palette",  icon: Theme?.iconPalette ?? "󰏘",  label: "art" },
        { key: "sliders",  icon: Theme?.iconSliders ?? "󰔡",  label: "tools" }
    ]

    function resolveCategoryIcon(iconKey) {
        if (!iconKey) return Theme?.iconFolder ?? "󰉋";
        for (let i = 0; i < availableIcons.length; i++) {
            if (availableIcons[i].key === iconKey) return availableIcons[i].icon;
        }
        return iconKey;
    }

    readonly property var categoryList: {
        let list = [{ id: "all", label: "all", icon: Theme?.iconGrid ?? "󰕰" }];
        let custom = Settings?.launcherCustomCategories ?? [];
        if (Array.isArray(custom)) {
            for (let i = 0; i < custom.length; i++) {
                let c = custom[i];
                if (c && c.id && c.name) {
                    list.push({
                        id: c.id,
                        label: c.name,
                        icon: resolveCategoryIcon(c.icon),
                        appIds: c.appIds || []
                    });
                }
            }
        }
        return list;
    }

    function getActiveCatName() {
        let custom = Settings?.launcherCustomCategories ?? [];
        let c = custom.find(x => x && x.id === activeManagingCatId);
        return c ? c.name : "";
    }

    function getAppCategories(app) {
        if (!app) return [];
        let custom = Settings?.launcherCustomCategories ?? [];
        let aid = (app.id || "").toLowerCase();
        let aname = (app.name || "").toLowerCase();
        let res = [];
        for (let i = 0; i < custom.length; i++) {
            let c = custom[i];
            if (!c || !c.appIds) continue;
            let assigned = c.appIds.map(x => String(x).toLowerCase());
            if (assigned.includes(aid) || assigned.includes(aname)) {
                res.push({ id: c.id, name: c.name, icon: resolveCategoryIcon(c.icon) });
            }
        }
        return res;
    }

    function evaluateMath(expr) {
        if (!expr || expr.length < 2) return null;
        let s = expr.trim();
        if (!/^[\d\s\+\-\*\/\(\)\.\^\%eEpiPIsqrtSQRTabsABScosCOScinSINtanTAN\<\>\&\|\~]+$/.test(s) && !s.startsWith("0x")) {
            return null;
        }
        if (!/[\+\-\*\/\^\%]|sqrt|abs|sin|cos|tan|0x/i.test(s)) return null;
        try {
            let sanitized = s
                .replace(/sqrt\(/gi, "Math.sqrt(")
                .replace(/abs\(/gi, "Math.abs(")
                .replace(/sin\(/gi, "Math.sin(")
                .replace(/cos\(/gi, "Math.cos(")
                .replace(/tan\(/gi, "Math.tan(")
                .replace(/\^/g, "**")
                .replace(/\bpi\b/gi, "Math.PI");
            let res = Function('"use strict"; return (' + sanitized + ')')();
            if (typeof res === "number" && !isNaN(res) && isFinite(res)) {
                return String(Math.round(res * 100000) / 100000);
            }
        } catch(e) {}
        return null;
    }

    onOpenChanged: {
        if (open) {
            query = "";
            activeCategory = "all";
            showCategoryManager = false;
            activeManagingCatId = "";
            categoryAssignApp = null;
            searchInput.text = "";
            Qt.callLater(() => {
                searchInput.forceActiveFocus();
                appList.currentIndex = 0;
            });
        } else {
            query = "";
            showCategoryManager = false;
            activeManagingCatId = "";
            categoryAssignApp = null;
            searchInput.text = "";
        }
    }

    content: Item {
        anchors.fill: parent

        ColumnLayout {
            anchors.fill: parent
            spacing: Theme?.popupSpacing ?? Theme?.widgetSpacing ?? 10
            Keys.forwardTo: [searchInput]

            // ── View 1: Main Launcher (Search & Apps) ─────────────────────
            // Search Input Box
            Rectangle {
                visible: !root.showCategoryManager
                Layout.fillWidth: true
                Layout.preferredHeight: 42
                color: Theme.cardBg
                radius: Theme.radiusMd
                border.color: searchInput.activeFocus ? Theme.primary : Theme.widgetBorder
                border.width: 1

                Behavior on border.color { ColorAnimation { duration: Theme.animFast } }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 10
                    spacing: 10

                    Text {
                        text: Theme.iconSearch ?? "󰍉"
                        font.family: Theme.fontIcon
                        font.pixelSize: Theme.fontSizeMd
                        color: searchInput.activeFocus ? Theme.primary : Theme.on_surface_variant

                        Behavior on color { ColorAnimation { duration: Theme.animFast } }
                    }

                    TextInput {
                        id: searchInput
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        verticalAlignment: TextInput.AlignVCenter
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeSm
                        color: Theme.on_surface
                        selectByMouse: true
                        focus: true

                        Text {
                            text: "search apps..."
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeSm
                            color: Theme.on_surface_variant
                            opacity: 0.5
                            anchors.verticalCenter: parent.verticalCenter
                            visible: !searchInput.text && !searchInput.inputMethodComposing
                        }

                        onTextChanged: {
                            root.query = text;
                            appList.currentIndex = 0;
                            appList.positionViewAtBeginning();
                        }

                        Keys.onPressed: (event) => {
                            if (event.key === Qt.Key_Escape) {
                                if (root.categoryAssignApp !== null) {
                                    root.categoryAssignApp = null;
                                    event.accepted = true;
                                    return;
                                }
                                if (root.showCategoryManager) {
                                    if (root.activeManagingCatId !== "") {
                                        root.activeManagingCatId = "";
                                    } else {
                                        root.showCategoryManager = false;
                                    }
                                    event.accepted = true;
                                    return;
                                }
                                root.open = false;
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Down || (event.key === Qt.Key_Tab && !(event.modifiers & Qt.ShiftModifier))) {
                                if (appList.count > 0) {
                                    appList.incrementCurrentIndex();
                                    appList.positionViewAtIndex(appList.currentIndex, ListView.Contain);
                                }
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Up || (event.key === Qt.Key_Backtab) || (event.key === Qt.Key_Tab && (event.modifiers & Qt.ShiftModifier))) {
                                if (appList.count > 0) {
                                    appList.decrementCurrentIndex();
                                    appList.positionViewAtIndex(appList.currentIndex, ListView.Contain);
                                }
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                if (root.isCommand && root.cleanCommand.length > 0) {
                                    Quickshell.execDetached(["sh", "-c", root.cleanCommand]);
                                    root.open = false;
                                    event.accepted = true;
                                    return;
                                }
                                if (root.calcResult !== null) {
                                    Quickshell.execDetached(["wl-copy", "--", root.calcResult]);
                                    root.open = false;
                                    event.accepted = true;
                                    return;
                                }
                                if (appList.count === 0 && root.cleanQuery.length > 0 && (Settings?.launcherCommandEnabled ?? true)) {
                                    Quickshell.execDetached(["sh", "-c", root.cleanQuery]);
                                    root.open = false;
                                    event.accepted = true;
                                    return;
                                }
                                let targetApp = appList.model?.values ? appList.model.values[appList.currentIndex] : null;
                                if (targetApp?.execute) {
                                    targetApp.execute();
                                    root.open = false;
                                } else if (appList.currentItem?.launch) {
                                    appList.currentItem.launch();
                                }
                                event.accepted = true;
                            }
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: 20
                        Layout.preferredHeight: 20
                        Layout.alignment: Qt.AlignVCenter
                        radius: 10
                        color: clearMouse.containsMouse ? Theme.surface_variant : "transparent"
                        visible: searchInput.text.length > 0

                        Text {
                            anchors.centerIn: parent
                            text: Theme.iconClose ?? "✕"
                            font.family: Theme.fontIcon
                            font.pixelSize: 10
                            color: Theme.on_surface_variant
                        }

                        MouseArea {
                            id: clearMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                searchInput.text = "";
                                searchInput.forceActiveFocus();
                            }
                        }
                    }
                }
            }

            // Category Filter Chips & Manager Toggle
            RowLayout {
                visible: !root.showCategoryManager
                Layout.fillWidth: true
                spacing: 6

                Flickable {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 28
                    contentWidth: categoryRow.implicitWidth
                    contentHeight: 28
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    Row {
                        id: categoryRow
                        spacing: 4

                        Repeater {
                            model: root.categoryList
                            delegate: Rectangle {
                                required property var modelData
                                height: 26
                                width: Math.max(38, chipLayout.implicitWidth + 16)
                                radius: Theme.radiusSm
                                color: root.activeCategory === modelData.id ? Theme.primary : Theme.surface_container_high

                                RowLayout {
                                    id: chipLayout
                                    anchors.centerIn: parent
                                    spacing: 4
                                    Text {
                                        text: modelData.icon
                                        font.family: Theme.fontIcon
                                        font.pixelSize: 10
                                        color: root.activeCategory === modelData.id ? (Theme.on_primary ?? "#ffffff") : Theme.on_surface_variant
                                    }
                                    Text {
                                        text: modelData.label
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 10
                                        font.weight: Font.Medium
                                        color: root.activeCategory === modelData.id ? (Theme.on_primary ?? "#ffffff") : Theme.on_surface
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        root.activeCategory = modelData.id;
                                        appList.currentIndex = 0;
                                        appList.positionViewAtBeginning();
                                        searchInput.forceActiveFocus();
                                    }
                                }
                            }
                        }
                    }
                }

                // Category Settings Toggle Button
                Rectangle {
                    Layout.preferredWidth: 28
                    Layout.preferredHeight: 26
                    radius: Theme.radiusSm
                    color: manageHover.containsMouse ? Theme.surface_container_highest : Theme.surface_container_high
                    border.color: Theme.widgetBorder
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: (Settings?.launcherCustomCategories?.length > 0) ? (Theme.iconSliders ?? "󰔡") : "+"
                        font.family: (Settings?.launcherCustomCategories?.length > 0) ? Theme.fontIcon : Theme.fontFamily
                        font.pixelSize: (Settings?.launcherCustomCategories?.length > 0) ? 11 : 13
                        font.weight: Font.Bold
                        color: Theme.on_surface_variant
                    }

                    MouseArea {
                        id: manageHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.showCategoryManager = true;
                            root.activeManagingCatId = "";
                        }
                    }
                }
            }

            Rectangle {
                visible: !root.showCategoryManager
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Theme.widgetBorder
            }

            // Inline Calculator Card
            Rectangle {
                id: calcCard
                visible: !root.showCategoryManager && root.calcResult !== null
                Layout.fillWidth: true
                Layout.preferredHeight: 48
                radius: Theme.radiusMd
                color: Theme.primary_overlay
                border.color: Theme.primary
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 12

                    Rectangle {
                        Layout.preferredWidth: 28
                        Layout.preferredHeight: 28
                        radius: Theme.radiusSm
                        color: Theme.primary

                        Text {
                            text: "="
                            font.family: Theme.fontMono
                            font.pixelSize: 16
                            font.weight: Font.Bold
                            color: Theme.on_primary
                            anchors.centerIn: parent
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1

                        Text {
                            text: root.calcResult ?? ""
                            font.family: Theme.fontMono
                            font.pixelSize: Theme.fontSizeLg
                            font.weight: Font.Bold
                            color: Theme.primary
                        }

                        Text {
                            text: "enter to copy result to clipboard"
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeXs
                            color: Theme.on_surface_variant
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        Quickshell.execDetached(["wl-copy", "--", root.calcResult]);
                        root.open = false;
                    }
                }
            }

            // Inline Shell Command Runner Card
            Rectangle {
                id: cmdCard
                visible: !root.showCategoryManager && ((root.isCommand && root.cleanCommand.length > 0) || (appList.count === 0 && root.calcResult === null && root.cleanQuery.length > 0 && (Settings?.launcherCommandEnabled ?? true)))
                Layout.fillWidth: true
                Layout.preferredHeight: 48
                radius: Theme.radiusMd
                color: Theme.surface_container_high
                border.color: Theme.primary
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 12

                    Rectangle {
                        Layout.preferredWidth: 28
                        Layout.preferredHeight: 28
                        radius: Theme.radiusSm
                        color: Theme.surface_container_highest

                        Text {
                            text: ">_"
                            font.family: Theme.fontMono
                            font.pixelSize: 12
                            font.weight: Font.Bold
                            color: Theme.primary
                            anchors.centerIn: parent
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1

                        Text {
                            text: root.isCommand ? root.cleanCommand : root.cleanQuery
                            font.family: Theme.fontMono
                            font.pixelSize: Theme.fontSizeSm
                            font.weight: Font.DemiBold
                            color: Theme.on_surface
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        Text {
                            text: "enter to run in background"
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeXs
                            color: Theme.primary
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        let cmd = root.isCommand ? root.cleanCommand : root.cleanQuery;
                        Quickshell.execDetached(["sh", "-c", cmd]);
                        root.open = false;
                    }
                }
            }

            // App List View
            Item {
                visible: !root.showCategoryManager
                Layout.fillWidth: true
                Layout.fillHeight: true

                ListView {
                    id: appList
                    anchors.fill: parent
                    clip: true
                    spacing: 4
                    boundsBehavior: Flickable.StopAtBounds
                    keyNavigationWraps: true
                    visible: appList.count > 0

                    model: ScriptModel {
                        objectProp: "id"
                        values: {
                            const q = root.query.trim().toLowerCase();
                            const cat = root.activeCategory;
                            let apps = [...(DesktopEntries?.applications?.values ?? [])].filter(a => a && a.name);

                            // Category filtering
                            if (cat !== "all") {
                                let customList = Array.isArray(Settings?.launcherCustomCategories) ? Settings.launcherCustomCategories : [];
                                let targetCat = customList.find(c => c && c.id === cat);
                                if (targetCat) {
                                    let assigned = (targetCat.appIds || []).map(x => String(x).toLowerCase());
                                    apps = apps.filter(app => {
                                        let aid = (app.id || "").toLowerCase();
                                        let aname = (app.name || "").toLowerCase();
                                        return assigned.includes(aid) || assigned.includes(aname);
                                    });
                                }
                            }

                            if (!q) {
                                return apps.sort((a, b) => (a.name || "").localeCompare(b.name || ""));
                            }

                            return apps.map(app => {
                                let score = 0;
                                const name = (app.name || "").toLowerCase();
                                const gen = (app.genericName || "").toLowerCase();
                                const comment = (app.comment || "").toLowerCase();
                                const kw = app.keywords || [];

                                if (name.startsWith(q)) score += 100;
                                else if (name.includes(q)) score += 60;

                                if (gen.startsWith(q)) score += 40;
                                else if (gen.includes(q)) score += 25;

                                if (kw.some(k => (k || "").toLowerCase().includes(q))) score += 15;
                                if (comment.includes(q)) score += 10;

                                return { app, score };
                            })
                            .filter(item => item.score > 0)
                            .sort((a, b) => b.score !== a.score ? b.score - a.score : (a.app.name || "").localeCompare(b.app.name || ""))
                            .map(item => item.app);
                        }
                    }

                    delegate: Rectangle {
                        id: appDelegate
                        required property var modelData
                        required property int index

                        readonly property bool isSelected: appList.currentIndex === index
                        readonly property bool isHovered: mouseArea.containsMouse

                        width: appList.width
                        implicitHeight: 52
                        radius: Theme.radiusMd
                        color: isSelected
                            ? Theme.primary_overlay
                            : isHovered
                                ? Theme.surface_container_highest
                                : "transparent"

                        border.color: isSelected ? Theme.primary : "transparent"
                        border.width: 1

                        Behavior on color { ColorAnimation { duration: Theme.animFast } }
                        Behavior on border.color { ColorAnimation { duration: Theme.animFast } }

                        function launch() {
                            if (modelData?.execute) {
                                modelData.execute();
                            }
                            root.open = false;
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 12
                            spacing: 10

                            Rectangle {
                                Layout.preferredWidth: 34
                                Layout.preferredHeight: 34
                                radius: Theme.radiusSm
                                color: Theme.surface_container_high

                                IconImage {
                                    anchors.centerIn: parent
                                    width: 24
                                    height: 24
                                    source: {
                                        let ic = modelData?.icon || "";
                                        if (ic.startsWith("/")) return "file://" + ic;
                                        if (Quickshell?.hasThemeIcon && Quickshell.hasThemeIcon(ic)) {
                                            return Quickshell.iconPath(ic);
                                        }
                                        if (Quickshell?.hasThemeIcon && Quickshell.hasThemeIcon("application-x-executable")) {
                                            return Quickshell.iconPath("application-x-executable");
                                        }
                                        return "";
                                    }
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 6

                                    Text {
                                        text: (modelData?.name ?? "").toLowerCase()
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.fontSizeSm
                                        font.weight: Font.Medium
                                        color: isSelected ? Theme.primary : Theme.on_surface
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                        Behavior on color { ColorAnimation { duration: Theme.animFast } }
                                    }

                                    // Category tags assigned to this app
                                    Row {
                                        spacing: 4
                                        Repeater {
                                            model: root.getAppCategories(modelData)
                                            delegate: Rectangle {
                                                required property var modelData
                                                height: 16
                                                width: tagText.implicitWidth + 8
                                                radius: 4
                                                color: Theme.surface_container_highest
                                                Text {
                                                    id: tagText
                                                    anchors.centerIn: parent
                                                    text: modelData.name
                                                    font.family: Theme.fontFamily
                                                    font.pixelSize: 8
                                                    color: Theme.on_surface_variant
                                                }
                                            }
                                        }
                                    }
                                }

                                Text {
                                    text: (modelData?.genericName || modelData?.comment || "").toLowerCase()
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSizeXs
                                    color: Theme.on_surface_variant
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                    visible: text !== ""
                                }
                            }

                            Rectangle {
                                visible: isSelected
                                implicitWidth: 22
                                implicitHeight: 20
                                radius: Theme.radiusSm
                                color: Theme.primary

                                Text {
                                    anchors.centerIn: parent
                                    text: "↵"
                                    font.family: Theme.fontMono
                                    font.pixelSize: 11
                                    font.weight: Font.Bold
                                    color: Theme.on_primary ?? "#ffffff"
                                }
                            }
                        }

                        MouseArea {
                            id: mouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            cursorShape: Qt.PointingHandCursor
                            onClicked: (mouse) => {
                                if (mouse.button === Qt.LeftButton) {
                                    appList.currentIndex = index;
                                    appDelegate.launch();
                                } else if (mouse.button === Qt.RightButton) {
                                    root.categoryAssignApp = modelData;
                                }
                            }
                        }
                    }
                }

                // Empty state
                Item {
                    anchors.fill: parent
                    visible: appList.count === 0 && root.calcResult === null && !cmdCard.visible

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 8

                        Text {
                            text: Theme.iconSearch ?? "󰍉"
                            font.family: Theme.fontIcon
                            font.pixelSize: Theme.fontSizeXl
                            color: Theme.on_surface_variant
                            Layout.alignment: Qt.AlignHCenter
                        }

                        Text {
                            text: root.activeCategory !== "all" ? "no apps in this category" : "no matching applications"
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeSm
                            color: Theme.on_surface_variant
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }
                }
            }

            // Footer
            RowLayout {
                visible: !root.showCategoryManager
                Layout.fillWidth: true
                spacing: 12

                Text {
                    text: (appList.count) + " apps"
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                    color: Theme.on_surface_variant
                    Layout.fillWidth: true
                }

                Text {
                    text: "↑↓/tab navigate  •  ↵ launch  •  right-click tag  •  esc close"
                    font.family: Theme.fontMono
                    font.pixelSize: 9
                    color: Theme.on_surface_variant
                    opacity: 0.7
                }
            }

            // ── View 2: Category Manager ─────────────────────────────────
            ColumnLayout {
                visible: root.showCategoryManager
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 10

                // Header
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Rectangle {
                        Layout.preferredWidth: 28
                        Layout.preferredHeight: 28
                        radius: Theme.radiusSm
                        color: managerBackHover.containsMouse ? Theme.surface_container_highest : Theme.surface_container_high

                        Text {
                            anchors.centerIn: parent
                            text: Theme.iconChevronLeft ?? "‹"
                            font.family: Theme.fontIcon
                            font.pixelSize: 14
                            color: Theme.on_surface
                        }

                        MouseArea {
                            id: managerBackHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (root.activeManagingCatId !== "") {
                                    root.activeManagingCatId = "";
                                } else {
                                    root.showCategoryManager = false;
                                }
                            }
                        }
                    }

                    Text {
                        text: root.activeManagingCatId !== "" ? ("assign apps: " + root.getActiveCatName()) : "category manager"
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeMd
                        font.weight: Font.DemiBold
                        color: Theme.on_surface
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    Rectangle {
                        Layout.preferredWidth: 52
                        Layout.preferredHeight: 26
                        radius: Theme.radiusSm
                        color: Theme.primary

                        Text {
                            anchors.centerIn: parent
                            text: "done"
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            font.weight: Font.Medium
                            color: Theme.on_primary ?? "#ffffff"
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.activeManagingCatId = "";
                                root.showCategoryManager = false;
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: Theme.widgetBorder
                }

                // Subview A: List & Create Categories
                ColumnLayout {
                    visible: root.activeManagingCatId === ""
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 10

                    // Create New Category Card
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 88
                        radius: Theme.radiusMd
                        color: Theme.cardBg
                        border.color: Theme.widgetBorder
                        border.width: 1

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 8

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                TextInput {
                                    id: newCatInput
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 28
                                    verticalAlignment: TextInput.AlignVCenter
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSizeSm
                                    color: Theme.on_surface
                                    selectByMouse: true

                                    Text {
                                        text: "new category name (e.g. dev, games, media)..."
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.fontSizeSm
                                        color: Theme.on_surface_variant
                                        opacity: 0.5
                                        anchors.verticalCenter: parent.verticalCenter
                                        visible: !newCatInput.text && !newCatInput.inputMethodComposing
                                    }
                                }

                                Rectangle {
                                    Layout.preferredWidth: 62
                                    Layout.preferredHeight: 28
                                    radius: Theme.radiusSm
                                    color: newCatInput.text.trim().length > 0 ? Theme.primary : Theme.surface_container_highest
                                    opacity: newCatInput.text.trim().length > 0 ? 1.0 : 0.6

                                    Text {
                                        anchors.centerIn: parent
                                        text: "+ add"
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 11
                                        font.weight: Font.DemiBold
                                        color: newCatInput.text.trim().length > 0 ? (Theme.on_primary ?? "#ffffff") : Theme.on_surface_variant
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: newCatInput.text.trim().length > 0 ? Qt.PointingHandCursor : Qt.ArrowCursor
                                        onClicked: {
                                            if (newCatInput.text.trim().length > 0) {
                                                Settings.addLauncherCategory(newCatInput.text.trim(), root.newCategoryIcon);
                                                newCatInput.text = "";
                                            }
                                        }
                                    }
                                }
                            }

                            // Icon Selector Chips
                            Flickable {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 26
                                contentWidth: iconRow.implicitWidth
                                contentHeight: 26
                                clip: true
                                boundsBehavior: Flickable.StopAtBounds

                                Row {
                                    id: iconRow
                                    spacing: 4

                                    Repeater {
                                        model: root.availableIcons
                                        delegate: Rectangle {
                                            required property var modelData
                                            width: 26
                                            height: 24
                                            radius: Theme.radiusSm
                                            color: root.newCategoryIcon === modelData.key ? Theme.primary : (iconHover.containsMouse ? Theme.surface_container_highest : Theme.surface_container_high)

                                            Text {
                                                anchors.centerIn: parent
                                                text: modelData.icon
                                                font.family: Theme.fontIcon
                                                font.pixelSize: 11
                                                color: root.newCategoryIcon === modelData.key ? (Theme.on_primary ?? "#ffffff") : Theme.on_surface_variant
                                            }

                                            MouseArea {
                                                id: iconHover
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: root.newCategoryIcon = modelData.key
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Existing Categories List
                    ListView {
                        id: catManageList
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        spacing: 6
                        boundsBehavior: Flickable.StopAtBounds
                        model: Settings?.launcherCustomCategories ?? []

                        delegate: Rectangle {
                            required property var modelData
                            width: catManageList.width
                            implicitHeight: 46
                            radius: Theme.radiusMd
                            color: Theme.surface_container_high
                            border.color: Theme.widgetBorder
                            border.width: 1

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 10

                                Text {
                                    text: root.resolveCategoryIcon(modelData.icon)
                                    font.family: Theme.fontIcon
                                    font.pixelSize: 14
                                    color: Theme.primary
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2

                                    Text {
                                        text: modelData.name
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.fontSizeSm
                                        font.weight: Font.Medium
                                        color: Theme.on_surface
                                    }

                                    Text {
                                        text: (modelData.appIds ? modelData.appIds.length : 0) + " apps assigned"
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.fontSizeXs
                                        color: Theme.on_surface_variant
                                    }
                                }

                                // Manage Apps button
                                Rectangle {
                                    Layout.preferredWidth: 84
                                    Layout.preferredHeight: 26
                                    radius: Theme.radiusSm
                                    color: manageAppsHover.containsMouse ? Theme.surface_container_highest : Theme.surface_container
                                    border.color: Theme.widgetBorder
                                    border.width: 1

                                    Text {
                                        anchors.centerIn: parent
                                        text: "assign apps"
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 10
                                        color: Theme.on_surface
                                    }

                                    MouseArea {
                                        id: manageAppsHover
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            root.activeManagingCatId = modelData.id;
                                            root.categoryAppFilter = "";
                                        }
                                    }
                                }

                                // Delete Category button
                                Rectangle {
                                    Layout.preferredWidth: 26
                                    Layout.preferredHeight: 26
                                    radius: Theme.radiusSm
                                    color: delHover.containsMouse ? Theme.alpha(Theme.error ?? "#ff5449", 0.18) : "transparent"

                                    Text {
                                        anchors.centerIn: parent
                                        text: Theme.iconClose ?? "✕"
                                        font.family: Theme.fontIcon
                                        font.pixelSize: 11
                                        color: delHover.containsMouse ? (Theme.error ?? "#ff5449") : Theme.on_surface_variant
                                    }

                                    MouseArea {
                                        id: delHover
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: Settings.removeLauncherCategory(modelData.id)
                                    }
                                }
                            }
                        }
                    }

                    // Empty categories state
                    Item {
                        visible: (Settings?.launcherCustomCategories ?? []).length === 0
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 8

                            Text {
                                text: Theme.iconFolder ?? "󰉋"
                                font.family: Theme.fontIcon
                                font.pixelSize: Theme.fontSizeXl
                                color: Theme.on_surface_variant
                                Layout.alignment: Qt.AlignHCenter
                            }

                            Text {
                                text: "no custom categories yet"
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeSm
                                font.weight: Font.Medium
                                color: Theme.on_surface
                                Layout.alignment: Qt.AlignHCenter
                            }

                            Text {
                                text: "create one above to group and filter your favorite apps"
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeXs
                                color: Theme.on_surface_variant
                                Layout.alignment: Qt.AlignHCenter
                            }
                        }
                    }
                }

                // Subview B: Assign Apps to Selected Category
                ColumnLayout {
                    visible: root.activeManagingCatId !== ""
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 8

                    // Search input for apps
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 36
                        color: Theme.cardBg
                        radius: Theme.radiusMd
                        border.color: Theme.widgetBorder
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            spacing: 8

                            Text {
                                text: Theme.iconSearch ?? "󰍉"
                                font.family: Theme.fontIcon
                                font.pixelSize: Theme.fontSizeSm
                                color: Theme.on_surface_variant
                            }

                            TextInput {
                                id: catAppFilterInput
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                verticalAlignment: TextInput.AlignVCenter
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeSm
                                color: Theme.on_surface
                                selectByMouse: true

                                Text {
                                    text: "filter apps to assign..."
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSizeSm
                                    color: Theme.on_surface_variant
                                    opacity: 0.5
                                    anchors.verticalCenter: parent.verticalCenter
                                    visible: !catAppFilterInput.text && !catAppFilterInput.inputMethodComposing
                                }

                                onTextChanged: root.categoryAppFilter = text.trim().toLowerCase()
                            }
                        }
                    }

                    // App Checklist
                    ListView {
                        id: catAppPickList
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        spacing: 4
                        boundsBehavior: Flickable.StopAtBounds

                        model: {
                            let q = root.categoryAppFilter;
                            let apps = [...(DesktopEntries?.applications?.values ?? [])].filter(a => a && a.name);
                            if (q) {
                                apps = apps.filter(a => {
                                    let n = (a.name || "").toLowerCase();
                                    let g = (a.genericName || "").toLowerCase();
                                    return n.includes(q) || g.includes(q);
                                });
                            }
                            return apps.sort((a, b) => (a.name || "").localeCompare(b.name || ""));
                        }

                        delegate: Rectangle {
                            required property var modelData
                            width: catAppPickList.width
                            implicitHeight: 44
                            radius: Theme.radiusSm
                            color: rowHover.containsMouse ? Theme.surface_container_highest : Theme.surface_container_high

                            readonly property bool isChecked: {
                                let custom = Settings?.launcherCustomCategories ?? [];
                                let cat = custom.find(c => c && c.id === root.activeManagingCatId);
                                if (!cat || !cat.appIds) return false;
                                let aid = (modelData.id || "").toLowerCase();
                                let aname = (modelData.name || "").toLowerCase();
                                let assigned = cat.appIds.map(x => String(x).toLowerCase());
                                return assigned.includes(aid) || assigned.includes(aname);
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 12
                                spacing: 10

                                Rectangle {
                                    Layout.preferredWidth: 28
                                    Layout.preferredHeight: 28
                                    radius: 4
                                    color: Theme.surface_container_highest

                                    IconImage {
                                        anchors.centerIn: parent
                                        width: 20
                                        height: 20
                                        source: {
                                            let ic = modelData?.icon || "";
                                            if (ic.startsWith("/")) return "file://" + ic;
                                            if (Quickshell?.hasThemeIcon && Quickshell.hasThemeIcon(ic)) {
                                                return Quickshell.iconPath(ic);
                                            }
                                            if (Quickshell?.hasThemeIcon && Quickshell.hasThemeIcon("application-x-executable")) {
                                                return Quickshell.iconPath("application-x-executable");
                                            }
                                            return "";
                                        }
                                    }
                                }

                                Text {
                                    text: (modelData?.name ?? "").toLowerCase()
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSizeSm
                                    color: Theme.on_surface
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }

                                Rectangle {
                                    Layout.preferredWidth: 20
                                    Layout.preferredHeight: 20
                                    radius: 4
                                    color: isChecked ? Theme.primary : "transparent"
                                    border.color: isChecked ? Theme.primary : Theme.outline
                                    border.width: 1

                                    Text {
                                        anchors.centerIn: parent
                                        visible: isChecked
                                        text: "✓"
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 12
                                        font.weight: Font.Bold
                                        color: Theme.on_primary ?? "#ffffff"
                                    }
                                }
                            }

                            MouseArea {
                                id: rowHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Settings.toggleAppInLauncherCategory(root.activeManagingCatId, modelData.id || modelData.name)
                            }
                        }
                    }
                }
            }
        }

        // ── Quick Category Assign Modal for Right-Clicked App ────────────
        Rectangle {
            id: modalBackdrop
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, 0.55)
            visible: root.categoryAssignApp !== null
            z: 100

            MouseArea {
                anchors.fill: parent
                onClicked: root.categoryAssignApp = null
            }

            Rectangle {
                anchors.centerIn: parent
                width: Math.min(360, parent.width - 32)
                height: Math.min(320, parent.height - 32)
                radius: Theme.radiusMd
                color: Theme.cardBg
                border.color: Theme.primary
                border.width: 1

                MouseArea {
                    anchors.fill: parent
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 10

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Text {
                            text: "categorize: " + (root.categoryAssignApp?.name ?? "")
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeSm
                            font.weight: Font.DemiBold
                            color: Theme.on_surface
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        Rectangle {
                            Layout.preferredWidth: 22
                            Layout.preferredHeight: 22
                            radius: 11
                            color: modalCloseMouse.containsMouse ? Theme.surface_variant : "transparent"

                            Text {
                                anchors.centerIn: parent
                                text: Theme.iconClose ?? "✕"
                                font.family: Theme.fontIcon
                                font.pixelSize: 10
                                color: Theme.on_surface_variant
                            }

                            MouseArea {
                                id: modalCloseMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.categoryAssignApp = null
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 1
                        color: Theme.widgetBorder
                    }

                    Text {
                        visible: (Settings?.launcherCustomCategories ?? []).length === 0
                        text: "no custom categories created yet. click + on the category bar to create one."
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeXs
                        color: Theme.on_surface_variant
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }

                    ListView {
                        visible: (Settings?.launcherCustomCategories ?? []).length > 0
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        spacing: 6
                        model: Settings?.launcherCustomCategories ?? []

                        delegate: Rectangle {
                            required property var modelData
                            width: parent.width
                            height: 36
                            radius: Theme.radiusSm
                            color: modalCatHover.containsMouse ? Theme.surface_container_highest : Theme.surface_container_high

                            readonly property bool isAssigned: {
                                if (!root.categoryAssignApp || !modelData || !modelData.appIds) return false;
                                let aid = (root.categoryAssignApp.id || "").toLowerCase();
                                let aname = (root.categoryAssignApp.name || "").toLowerCase();
                                let assigned = modelData.appIds.map(x => String(x).toLowerCase());
                                return assigned.includes(aid) || assigned.includes(aname);
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 8
                                spacing: 8

                                Text {
                                    text: root.resolveCategoryIcon(modelData.icon)
                                    font.family: Theme.fontIcon
                                    font.pixelSize: Theme.fontSizeSm
                                    color: Theme.primary
                                }

                                Text {
                                    text: modelData.name
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSizeSm
                                    color: Theme.on_surface
                                    Layout.fillWidth: true
                                }

                                Rectangle {
                                    Layout.preferredWidth: 18
                                    Layout.preferredHeight: 18
                                    radius: 4
                                    color: isAssigned ? Theme.primary : "transparent"
                                    border.color: isAssigned ? Theme.primary : Theme.outline
                                    border.width: 1

                                    Text {
                                        anchors.centerIn: parent
                                        visible: isAssigned
                                        text: "✓"
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 11
                                        font.weight: Font.Bold
                                        color: Theme.on_primary ?? "#ffffff"
                                    }
                                }
                            }

                            MouseArea {
                                id: modalCatHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (root.categoryAssignApp) {
                                        Settings.toggleAppInLauncherCategory(modelData.id, root.categoryAssignApp.id || root.categoryAssignApp.name);
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