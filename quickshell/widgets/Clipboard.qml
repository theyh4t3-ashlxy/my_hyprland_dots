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
                popup.targetRelativeY = root.mapToItem(null, 0, 0).y + (root.height / 2);
            } else {
                popup.targetRelativeX = root.mapToItem(null, 0, 0).x + (root.width / 2);
            }
            popup.open = !popup.open;
            if (popup.open) {
                syncCurrentClip();
                root.searchFilter = "";
                clipInput.text = "";
                clipInput.forceActiveFocus();
            }
        }
    }

    PopupPanel {
        id: popup

        content: ColumnLayout {
            anchors.fill: parent
            spacing: Theme.widgetSpacing

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

                        visible: root.searchFilter === "" || text.toLowerCase().includes(root.searchFilter)
                        width: parent.width
                        implicitHeight: col.implicitHeight + Theme.widgetPaddingH * 2
                        color: cMouse.containsMouse ? Theme.surface_container_highest : Theme.surface_container_low
                        radius: Theme.widgetRadius

                        Behavior on color { ColorAnimation { duration: Theme.animFast } }

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
                                    visible: cMouse.containsMouse
                                }
                            }

                            Text {
                                text: clipDelegate.text
                                font.family: Theme.fontMono
                                font.pixelSize: Theme.fontSizeSm
                                color: Theme.on_surface
                                wrapMode: Text.Wrap
                                maximumLineCount: 3
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }

                        MouseArea {
                            id: cMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.copyToClipboard(clipDelegate.text)
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
