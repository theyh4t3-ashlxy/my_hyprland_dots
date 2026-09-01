import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Hyprland
import ".."
import "../controls"

PopupPanel {
    id: root

    cardWidth: 460
    cardHeight: 560

    property string query: ""
    property string activeCategory: "all" // "all", "internet", "dev", "media", "games", "system"

    onOpenChanged: {
        if (open) {
            query = "";
            activeCategory = "all";
            searchInput.text = "";
            Qt.callLater(() => {
                searchInput.forceActiveFocus();
                appList.currentIndex = 0;
            });
        }
    }

    content: ColumnLayout {
        anchors.fill: parent
        spacing: Theme.popupSpacing

        // Search Input Box
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 42
            color: Theme.surface_container_highest
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
                    text: Theme.iconSearch
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
                            root.open = false;
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Down || (event.key === Qt.Key_Tab && !(event.modifiers & Qt.ShiftModifier))) {
                            appList.incrementCurrentIndex();
                            appList.positionViewAtIndex(appList.currentIndex, ListView.Contain);
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Up || (event.key === Qt.Key_Backtab) || (event.key === Qt.Key_Tab && (event.modifiers & Qt.ShiftModifier))) {
                            appList.decrementCurrentIndex();
                            appList.positionViewAtIndex(appList.currentIndex, ListView.Contain);
                            event.accepted = true;
                        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            if (appList.currentItem) {
                                appList.currentItem.launch();
                            }
                            event.accepted = true;
                        }
                    }
                }

                Rectangle {
                    width: 20
                    height: 20
                    radius: 10
                    color: clearMouse.containsMouse ? Theme.surface_variant : "transparent"
                    visible: searchInput.text.length > 0

                    Text {
                        anchors.centerIn: parent
                        text: Theme.iconClose
                        font.family: Theme.fontMono
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

        // Category Filter Chips
        RowLayout {
            Layout.fillWidth: true
            spacing: 4

            Repeater {
                model: [
                    { id: "all", label: "all", icon: "󰕰" },
                    { id: "internet", label: "web", icon: "󰖟" },
                    { id: "dev", label: "dev", icon: "󰅩" },
                    { id: "media", label: "media", icon: "󰝚" },
                    { id: "system", label: "sys", icon: "󰒓" }
                ]

                delegate: Rectangle {
                    required property var modelData
                    Layout.fillWidth: true
                    height: 26
                    radius: Theme.radiusSm
                    color: root.activeCategory === modelData.id ? Theme.primary : Theme.surface_container_high

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 4
                        Text {
                            text: modelData.icon
                            font.family: Theme.fontMono
                            font.pixelSize: 10
                            color: root.activeCategory === modelData.id ? Theme.on_primary : Theme.on_surface_variant
                        }
                        Text {
                            text: modelData.label
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                            font.weight: Font.Medium
                            color: root.activeCategory === modelData.id ? Theme.on_primary : Theme.on_surface
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.activeCategory = modelData.id;
                            appList.currentIndex = 0;
                            appList.positionViewAtBeginning();
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

        // App List
        ListView {
            id: appList
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 4
            boundsBehavior: Flickable.StopAtBounds

            model: ScriptModel {
                values: {
                    const q = root.query.trim().toLowerCase();
                    const cat = root.activeCategory;
                    let apps = [...DesktopEntries.applications.values].filter(a => a && a.name);

                    // Category filtering
                    if (cat !== "all") {
                        apps = apps.filter(app => {
                            let cats = (app.categories || []).map(c => c.toLowerCase());
                            let name = (app.name || "").toLowerCase();
                            let comment = (app.comment || "").toLowerCase();
                            if (cat === "internet") return cats.some(c => c.includes("network") || c.includes("web") || c.includes("browser")) || name.includes("firefox") || name.includes("chrome") || name.includes("discord") || name.includes("telegram");
                            if (cat === "dev") return cats.some(c => c.includes("development") || c.includes("ide") || c.includes("programming")) || name.includes("code") || name.includes("nvim") || name.includes("git") || name.includes("terminal") || name.includes("kitty");
                            if (cat === "media") return cats.some(c => c.includes("audio") || c.includes("video") || c.includes("player") || c.includes("media") || c.includes("graphics")) || name.includes("spotify") || name.includes("vlc") || name.includes("mpv") || name.includes("gimp");
                            if (cat === "system") return cats.some(c => c.includes("system") || c.includes("settings") || c.includes("utility")) || name.includes("settings") || name.includes("pavucontrol") || name.includes("btop");
                            return true;
                        });
                    }

                    if (!q) {
                        return apps.sort((a, b) => a.name.localeCompare(b.name));
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

                        if (kw.some(k => k.toLowerCase().includes(q))) score += 15;
                        if (comment.includes(q)) score += 10;

                        return { app, score };
                    })
                    .filter(item => item.score > 0)
                    .sort((a, b) => b.score !== a.score ? b.score - a.score : a.app.name.localeCompare(b.app.name))
                    .map(item => item.app);
                }
            }

            delegate: Rectangle {
                id: appDelegate
                required property var modelData
                required property int index

                readonly property bool isSelected: appList.currentIndex === index
                readonly property bool isHovered: mouseArea.containsMouse

                width: ListView.view.width
                implicitHeight: 50
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
                    anchors.leftMargin: 8
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
                            source: Quickshell.iconPath(modelData?.icon || "", "application-x-executable")
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1

                        Text {
                            text: modelData?.name ?? ""
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeSm
                            font.weight: Font.Medium
                            color: isSelected ? Theme.primary : Theme.on_surface
                            elide: Text.ElideRight
                            Layout.fillWidth: true

                            Behavior on color { ColorAnimation { duration: Theme.animFast } }
                        }

                        Text {
                            text: modelData?.genericName || modelData?.comment || ""
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
                            color: Theme.on_primary
                        }
                    }
                }

                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        appList.currentIndex = index;
                        appDelegate.launch();
                    }
                }
            }
        }

        // Empty state
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: appList.count === 0

            ColumnLayout {
                anchors.centerIn: parent
                spacing: 8

                Text {
                    text: Theme.kaoSad
                    font.family: Theme.fontMono
                    font.pixelSize: Theme.fontSizeXl
                    color: Theme.on_surface_variant
                    Layout.alignment: Qt.AlignHCenter
                }

                Text {
                    text: "no matching applications"
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSm
                    color: Theme.on_surface_variant
                    Layout.alignment: Qt.AlignHCenter
                }
            }
        }

        // Footer
        RowLayout {
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
                text: "↑↓/tab navigate  •  ↵ launch  •  esc close"
                font.family: Theme.fontMono
                font.pixelSize: 9
                color: Theme.on_surface_variant
                opacity: 0.7
            }
        }
    }
}
