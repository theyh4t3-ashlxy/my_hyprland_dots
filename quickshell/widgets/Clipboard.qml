import QtQuick
import QtQuick.Layouts
import ".."
import Quickshell
import Quickshell.Io

Rectangle {
    id: root
    implicitWidth: Theme.isVertical ? Theme.barHeight - 8 : clipRow.implicitWidth + 24
    implicitHeight: Theme.barHeight - 8
    radius: Theme.radiusPill
    color: popup.open ? Theme.primary_overlay : (clipMouse.containsMouse ? Theme.pillHover : Theme.pillBg)
    border.color: Theme.pillBorder
    border.width: Theme.pillBorder === "transparent" ? 0 : 1

    Behavior on color { ColorAnimation { duration: Theme.animFast } }
    Behavior on border.color { ColorAnimation { duration: Theme.animFast } }

    ListModel {
        id: clipModel
    }

    property string searchFilter: ""
    property int selectedIndex: 0

    function getFilteredIndices() {
        let res = [];
        for (let i = 0; i < clipModel.count; i++) {
            let item = clipModel.get(i);
            if (!item || !item.text) continue;
            if (root.searchFilter === "" || item.text.toLowerCase().includes(root.searchFilter)) {
                res.push(i);
            }
        }
        return res;
    }

    readonly property var filteredIndices: getFilteredIndices()

    onSearchFilterChanged: {
        let matches = getFilteredIndices();
        selectedIndex = matches.length > 0 ? matches[0] : 0;
    }

    function removeItem(idx) {
        if (idx >= 0 && idx < clipModel.count) {
            clipModel.remove(idx);
            let matches = getFilteredIndices();
            if (matches.length === 0) {
                selectedIndex = 0;
            } else if (matches.indexOf(selectedIndex) === -1) {
                selectedIndex = matches[0];
            }
        }
    }

    property FileView clipFile: FileView {
        path: "/tmp/qs_curclip.txt"
        watchChanges: true
        printErrors: false
        onFileChanged: {
            reload();
            let str = text();
            if (!str) return;
            let val = str.trim();
            if (val === "") return;
            let found = false;
            for (let i = 0; i < clipModel.count; i++) {
                if (clipModel.get(i).text === val) {
                    found = true;
                    break;
                }
            }
            if (!found) {
                clipModel.insert(0, { text: val, timestamp: Qt.formatTime(new Date(), "hh:mm") });
                if (clipModel.count > 50) clipModel.remove(50, clipModel.count - 50);
            }
        }
    }

    Component.onCompleted: {
        syncCurrentClip();
    }

    readonly property string scriptPath: Qt.resolvedUrl("../scripts/clipboard.py").toString().replace(/^file:\/\//, "")

    function syncCurrentClip() {
        Quickshell.execDetached(["python3", scriptPath, "sync"]);
    }

    function copyToClipboard(content) {
        Quickshell.execDetached(["python3", scriptPath, "copy", content]);
        popup.open = false;
    }

    Row {
        id: clipRow
        anchors.centerIn: parent
        spacing: 4

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Theme.iconClipboard
            font.family: Theme.fontIcon
            font.pixelSize: Theme.fontSizeMd
            color: popup.open ? Theme.primary : Theme.on_surface
        }
    }

    MouseArea {
        id: clipMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (Theme.isVertical) {
                popup.targetRelativeY = (root.mapToItem(null, 0, 0)?.y ?? 0) + (root.height / 2);
            } else {
                popup.targetRelativeX = (root.mapToItem(null, 0, 0)?.x ?? 0) + (root.width / 2);
            }
            popup.open = !popup.open;
            if (popup.open) {
                syncCurrentClip();
                root.searchFilter = "";
                root.selectedIndex = 0;
                clipInput.text = "";
                clipInput.forceActiveFocus();
            }
        }
    }

    Connections {
        target: Settings
        function onRequestClipboardToggle() {
            let pt = root.mapToItem(null, 0, 0);
            popup.targetRelativeX = pt ? (pt.x + (root.width / 2)) : 0;
            popup.targetRelativeY = pt ? (pt.y + (root.height / 2)) : 0;
            popup.open = !popup.open;
            if (popup.open) {
                syncCurrentClip();
                root.searchFilter = "";
                root.selectedIndex = 0;
                clipInput.text = "";
                clipInput.forceActiveFocus();
            }
        }
        function onRequestClipboardOpen() {
            let pt = root.mapToItem(null, 0, 0);
            popup.targetRelativeX = pt ? (pt.x + (root.width / 2)) : 0;
            popup.targetRelativeY = pt ? (pt.y + (root.height / 2)) : 0;
            popup.open = true;
            syncCurrentClip();
            root.searchFilter = "";
            root.selectedIndex = 0;
            clipInput.text = "";
            clipInput.forceActiveFocus();
        }
        function onRequestClipboardClose() {
            popup.open = false;
        }
    }

    PopupPanel {
        id: popup
        wantsFocus: true

        content: ColumnLayout {
            anchors.fill: parent
            spacing: Theme.widgetSpacing
            Keys.onPressed: (event) => {
                if (event.key === Qt.Key_Escape) {
                    popup.open = false;
                    event.accepted = true;
                }
            }

            // header
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: "clipboard"
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeLg
                    font.weight: Font.Bold
                    color: Theme.on_surface
                    Layout.fillWidth: true
                }

                IconButton {
                    icon: Theme.iconTrash
                    iconSize: Theme.fontSizeMd
                    tooltip: "clear history"
                    onClicked: clipModel.clear()
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Theme.widgetBorder
            }

            // search filter
            Rectangle {
                Layout.fillWidth: true
                height: 40
                color: Theme.surface_container_highest
                radius: Theme.widgetRadius
                border.color: clipInput.activeFocus ? Theme.primary : Theme.widgetBorder
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
                        id: clipInput
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        verticalAlignment: TextInput.AlignVCenter
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeSm
                        color: Theme.on_surface
                        focus: popup.open
                        onTextChanged: root.searchFilter = text.toLowerCase()
                        Keys.onPressed: (event) => {
                            if (event.key === Qt.Key_Escape) {
                                popup.open = false;
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Down || (event.key === Qt.Key_Tab && !(event.modifiers & Qt.ShiftModifier))) {
                                let matches = root.filteredIndices;
                                if (matches.length > 0) {
                                    let curPos = matches.indexOf(root.selectedIndex);
                                    if (curPos === -1) curPos = 0;
                                    let nextPos = Math.min(matches.length - 1, curPos + 1);
                                    root.selectedIndex = matches[nextPos];
                                }
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Up || event.key === Qt.Key_Backtab || (event.key === Qt.Key_Tab && (event.modifiers & Qt.ShiftModifier))) {
                                let matches = root.filteredIndices;
                                if (matches.length > 0) {
                                    let curPos = matches.indexOf(root.selectedIndex);
                                    if (curPos === -1) curPos = 0;
                                    let prevPos = Math.max(0, curPos - 1);
                                    root.selectedIndex = matches[prevPos];
                                }
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                let matches = root.filteredIndices;
                                if (matches.length > 0) {
                                    if (matches.indexOf(root.selectedIndex) === -1) {
                                        root.selectedIndex = matches[0];
                                    }
                                    let item = clipModel.get(root.selectedIndex);
                                    if (item && item.text) {
                                        root.copyToClipboard(item.text);
                                    }
                                }
                                event.accepted = true;
                            }
                        }
                    }
                }
            }

            // list of clips
            FlickList {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                visible: clipModel.count > 0

                Repeater {
                    model: clipModel

                    delegate: Rectangle {
                        id: clipDelegate
                        required property string text
                        required property string timestamp
                        required property int index

                        readonly property bool isSelected: index === root.selectedIndex && root.filteredIndices.indexOf(index) !== -1

                        visible: root.searchFilter === "" || text.toLowerCase().includes(root.searchFilter)
                        width: parent.width
                        implicitHeight: visible ? (col.implicitHeight + Theme.widgetPaddingH * 2) : 0
                        height: visible ? implicitHeight : 0
                        color: isSelected ? Theme.primary_overlay : (cMouse.containsMouse ? Theme.surface_container_highest : Theme.surface_container_low)
                        radius: Theme.widgetRadius
                        border.color: isSelected ? Theme.primary : "transparent"
                        border.width: 1

                        Behavior on color { ColorAnimation { duration: Theme.animFast } }
                        Behavior on border.color { ColorAnimation { duration: Theme.animFast } }

                        ColumnLayout {
                            id: col
                            anchors.fill: parent
                            anchors.margins: Theme.widgetPaddingH
                            spacing: 4

                            RowLayout {
                                Layout.fillWidth: true
                                Text {
                                    text: clipDelegate.timestamp
                                    font.family: Theme.fontMono
                                    font.pixelSize: Theme.fontSizeXs
                                    color: Theme.on_surface_variant
                                    Layout.fillWidth: true
                                }
                                Text {
                                    text: "click to copy"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSizeXs
                                    color: Theme.primary
                                    visible: cMouse.containsMouse && !clipDelegate.isSelected
                                }
                                Rectangle {
                                    visible: clipDelegate.isSelected
                                    implicitWidth: 18
                                    implicitHeight: 18
                                    radius: Theme?.radiusSm ?? 4
                                    color: Theme.primary

                                    Text {
                                        anchors.centerIn: parent
                                        text: "↵"
                                        font.family: Theme?.fontMono ?? "monospace"
                                        font.pixelSize: 10
                                        font.weight: Font.Bold
                                        color: Theme?.on_primary ?? "#ffffff"
                                    }
                                }
                            }

                            Text {
                                text: clipDelegate.text
                                font.family: Theme.fontMono
                                font.pixelSize: Theme.fontSizeSm
                                color: clipDelegate.isSelected ? Theme.primary : Theme.on_surface
                                wrapMode: Text.Wrap
                                maximumLineCount: 3
                                elide: Text.ElideRight
                                Layout.fillWidth: true

                                Behavior on color { ColorAnimation { duration: Theme.animFast } }
                            }
                        }

                        MouseArea {
                            id: cMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            cursorShape: Qt.PointingHandCursor
                            onClicked: (mouse) => {
                                if (mouse.button === Qt.LeftButton) {
                                    root.selectedIndex = clipDelegate.index;
                                    root.copyToClipboard(clipDelegate.text);
                                } else if (mouse.button === Qt.RightButton) {
                                    root.removeItem(clipDelegate.index);
                                }
                            }
                        }
                    }
                }
            }

            // empty state
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: clipModel.count === 0

                Text {
                    text: Theme.iconClipboard + "\nclipboard is empty"
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeMd
                    color: Theme.on_surface_variant
                    horizontalAlignment: Text.AlignHCenter
                    anchors.centerIn: parent
                    lineHeight: 1.5
                }
            }
        }
    }
}
