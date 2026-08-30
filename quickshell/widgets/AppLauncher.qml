import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Hyprland
import ".."

PopupWindow {
    id: root

    property bool open: false
    property string query: ""
    property var parentWindow: null

    readonly property bool isTop: (Settings?.barPosition ?? "top") === "top"
    readonly property bool isBottom: (Settings?.barPosition ?? "top") === "bottom"
    readonly property bool isLeft: (Settings?.barPosition ?? "top") === "left"
    readonly property bool isRight: (Settings?.barPosition ?? "top") === "right"
    readonly property bool isVertical: Theme?.isVertical ?? false
    readonly property real cardWidth: 420
    readonly property real cardHeight: 540
    readonly property real scoopW: Theme?.scoopRadiusX ?? 16
    readonly property real scoopH: Theme?.scoopRadiusY ?? 16

    property real targetRelativeX: 0
    readonly property real desiredX: targetRelativeX > 0 ? (targetRelativeX - (implicitWidth / 2)) : 0
    readonly property real clampedX: Math.max(0, parentWindow ? Math.min(parentWindow.width - implicitWidth, desiredX) : desiredX)

    visible: open || morphAnim.running
    color: "transparent"
    
    // so wayland stops eating my keystrokes
    grabFocus: true

    implicitWidth: root.cardWidth + (root.isVertical ? 0 : (root.scoopW * 2))
    implicitHeight: root.cardHeight

    anchor.window: parentWindow
    anchor.rect.x: root.isVertical ? (root.isLeft ? Theme.barHeight + 8 : (parentWindow ? (parentWindow.width - Theme.barHeight - root.implicitWidth - 8) : 0)) : clampedX
    anchor.rect.y: root.isVertical ? 8 : (root.isTop ? Theme.barHeight : (parentWindow ? (parentWindow.height - Theme.barHeight - root.implicitHeight) : 0))
    anchor.edges: root.isVertical ? (root.isLeft ? (Edges.Top | Edges.Left) : (Edges.Top | Edges.Right)) : (root.isTop ? (Edges.Top | Edges.Left) : (Edges.Bottom | Edges.Left))
    anchor.gravity: root.isVertical ? (root.isLeft ? (Edges.Bottom | Edges.Right) : (Edges.Bottom | Edges.Left)) : (root.isTop ? (Edges.Bottom | Edges.Right) : (Edges.Top | Edges.Right))

    mask: Region {
        item: launcherBody
    }

    // click outside dismiss without tearing my hair out
    HyprlandFocusGrab {
        active: root.open
        windows: [root]
        onCleared: root.open = false
    }

    property real morphProgress: 0.0

    ParallelAnimation {
        id: morphAnim
        NumberAnimation {
            id: numAnim
            target: root
            property: "morphProgress"
            duration: root.open ? 240 : 160
            easing.type: root.open ? Easing.OutCubic : Easing.InCubic
        }
    }

    onOpenChanged: {
        if (open) {
            query = "";
            searchInput.text = "";
            numAnim.to = 1.0;
            morphAnim.restart();
            // qt hates instant focus before window maps, delay it or die
            Qt.callLater(() => {
                searchInput.forceActiveFocus();
                appList.currentIndex = 0;
            });
        } else {
            numAnim.to = 0.0;
            morphAnim.restart();
        }
    }

    Item {
        id: morphContainer
        anchors.fill: parent

        ConcaveCorner {
            x: 0
            y: root.isTop ? 0 : root.cardHeight - root.scoopH
            fillColor: Theme.surface_container_low
            flipX: true
            flipY: !root.isTop
            opacity: Math.min(1.0, root.morphProgress * 3.5)
            visible: !root.isVertical
        }

        ConcaveCorner {
            x: root.scoopW + root.cardWidth
            y: root.isTop ? 0 : root.cardHeight - root.scoopH
            fillColor: Theme.surface_container_low
            flipX: false
            flipY: !root.isTop
            opacity: Math.min(1.0, root.morphProgress * 3.5)
            visible: !root.isVertical
        }

        Rectangle {
            id: launcherBody
            x: root.isVertical ? 0 : root.scoopW
            y: (root.isTop || root.isVertical) ? 0 : root.cardHeight - height
            width: root.cardWidth
            height: Math.max(1, root.morphProgress * root.cardHeight)
            color: Theme.surface_container_low
            clip: true

            topLeftRadius: root.isVertical ? Theme.popupRadius : 0
            topRightRadius: root.isVertical ? Theme.popupRadius : 0
            bottomLeftRadius: (root.isTop || root.isVertical) ? Theme.popupRadius : 0
            bottomRightRadius: (root.isTop || root.isVertical) ? Theme.popupRadius : 0

            Item {
                width: root.cardWidth
                height: root.cardHeight
                y: root.isTop ? (root.morphProgress - 1.0) * 20 : (1.0 - root.morphProgress) * 20
                opacity: Math.max(0.0, (root.morphProgress - 0.15) / 0.85)

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Theme.popupPadding
                    spacing: Theme.popupSpacing

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
                                font.family: Theme.fontMono
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

                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: Theme.widgetBorder
                    }

                    ListView {
                        id: appList
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true
                        spacing: 4
                        boundsBehavior: Flickable.StopAtBounds

                        // ranking apps so actual matches dont get drowned in garbage
                        model: ScriptModel {
                            values: {
                                const q = root.query.trim().toLowerCase();
                                const apps = [...DesktopEntries.applications.values].filter(a => a && a.name);
                                
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

                                    // bye bye broken square artifacts
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
                                text: "no matching apps"
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeSm
                                color: Theme.on_surface_variant
                                Layout.alignment: Qt.AlignHCenter
                            }
                        }
                    }

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
        }
    }
}