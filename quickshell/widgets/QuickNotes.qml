import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import ".."
import "../controls"
import Quickshell
import Quickshell.Io

Rectangle {
    id: root
    implicitWidth: Theme.isVertical ? Theme.barHeight - 8 : noteRow.implicitWidth + 24
    implicitHeight: Theme.barHeight - 8
    radius: Theme.radiusPill
    color: popup.open ? Theme.primary_overlay : (nMouse.containsMouse ? Theme.pillHover : Theme.pillBg)
    border.color: Theme.pillBorder
    border.width: Theme.pillBorder === "transparent" ? 0 : 1
    visible: Settings.showQuickNotes

    Behavior on color { ColorAnimation { duration: Theme.animFast } }
    Behavior on border.color { ColorAnimation { duration: Theme.animFast } }

    property int activeIndex: 0
    property bool copiedFeedback: false

    ListModel {
        id: notesModel
    }

    readonly property string notesFilePath: "/home/ashley/.local/share/quickshell/notes.json"

    property FileView notesFile: FileView {
        path: root.notesFilePath
        watchChanges: false
        printErrors: false
        onLoaded: root.loadNotes(text())
    }

    function loadNotes(raw) {
        try {
            notesModel.clear();
            if (!raw || raw.trim() === "") {
                createDefaultNotes();
                return;
            }
            let parsed = JSON.parse(raw);
            if (Array.isArray(parsed) && parsed.length > 0) {
                for (let i = 0; i < parsed.length; i++) {
                    notesModel.append({
                        title: parsed[i].title || ("note " + (i + 1)),
                        content: parsed[i].content || ""
                    });
                }
            } else {
                createDefaultNotes();
            }
        } catch (e) {
            createDefaultNotes();
        }
    }

    function createDefaultNotes() {
        notesModel.clear();
        notesModel.append({
            title: "scratchpad",
            content: "# quick memo\n- [x] refine quickshell\n- [ ] test animations\n- [ ] chill"
        });
        notesModel.append({
            title: "ideas",
            content: "clean minimalist rice with reactive theme presets"
        });
        saveNotes();
    }

    function saveNotes() {
        let arr = [];
        for (let i = 0; i < notesModel.count; i++) {
            let item = notesModel.get(i);
            arr.push({
                title: item.title,
                content: item.content
            });
        }
        let jsonStr = JSON.stringify(arr, null, 2);
        Quickshell.execDetached(["python3", "-c", 'import sys, json, os; os.makedirs("/home/ashley/.local/share/quickshell", exist_ok=True); open("/home/ashley/.local/share/quickshell/notes.json", "w").write(sys.argv[1])', jsonStr]);
    }

    Component.onCompleted: {
        notesFile.reload();
    }

    Row {
        id: noteRow
        anchors.centerIn: parent
        spacing: 6

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Theme.iconNote
            font.family: Theme.fontIcon
            font.pixelSize: Theme.fontSizeSm
            color: popup.open ? Theme.primary : Theme.on_surface
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: notesModel.count + " notes"
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeSm
            font.weight: Font.Medium
            color: Theme.on_surface
            visible: !Theme.isVertical
        }
    }

    MouseArea {
        id: nMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            popup.targetRelativeX = root.mapToItem(null, 0, 0).x + (root.width / 2);
            popup.targetRelativeY = root.mapToItem(null, 0, 0).y + (root.height / 2);
            popup.open = !popup.open;
        }
    }

    PopupPanel {
        id: popup
        cardWidth: 460
        cardHeight: 560
        targetRelativeX: root.mapToItem(null, 0, 0).x + (root.width / 2)
        targetRelativeY: root.mapToItem(null, 0, 0).y + (root.height / 2)

        content: ColumnLayout {
            anchors.fill: parent
            spacing: 10

            // Header
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: Theme.iconNote
                    font.family: Theme.fontIcon
                    font.pixelSize: Theme.fontSizeLg
                    color: Theme.primary
                }

                Text {
                    text: "quick notes & scratchpad"
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeLg
                    font.weight: Font.Bold
                    color: Theme.on_surface
                    Layout.fillWidth: true
                }

                IconButton {
                    icon: root.copiedFeedback ? Theme.iconCheck : Theme.iconClipboard
                    tooltip: root.copiedFeedback ? "copied!" : "copy note to clipboard"
                    iconColor: root.copiedFeedback ? Theme.primary : Theme.on_surface
                    onClicked: {
                        if (notesModel.count > root.activeIndex) {
                            let textToCopy = notesModel.get(root.activeIndex).content;
                            Quickshell.execDetached(["wl-copy", textToCopy]);
                            root.copiedFeedback = true;
                            copyTimer.restart();
                        }
                    }
                }

                IconButton {
                    icon: Theme.iconClose
                    tooltip: "delete this note"
                    iconColor: Theme.error
                    visible: notesModel.count > 1
                    onClicked: {
                        if (notesModel.count > 1) {
                            notesModel.remove(root.activeIndex);
                            if (root.activeIndex >= notesModel.count) root.activeIndex = notesModel.count - 1;
                            root.saveNotes();
                        }
                    }
                }
            }

            Timer {
                id: copyTimer
                interval: 1500
                onTriggered: root.copiedFeedback = false
            }

            // Note tabs row
            Flickable {
                Layout.fillWidth: true
                height: 32
                contentWidth: noteTabsRow.width
                flickableDirection: Flickable.HorizontalFlick
                clip: true

                RowLayout {
                    id: noteTabsRow
                    spacing: 6

                    Repeater {
                        model: notesModel
                        delegate: Rectangle {
                            required property int index
                            required property string title
                            height: 28
                            width: tabText.implicitWidth + 20
                            radius: Theme.widgetRadius
                            color: root.activeIndex === index ? Theme.primary : Theme.cardBg
                            border.color: root.activeIndex === index ? Theme.primary : Theme.cardBorder
                            border.width: 1

                            Text {
                                id: tabText
                                text: title
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeXs
                                font.weight: Font.Medium
                                color: root.activeIndex === index ? Theme.on_primary : Theme.on_surface
                                anchors.centerIn: parent
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.activeIndex = index
                            }
                        }
                    }

                    // + New note tab button
                    Rectangle {
                        height: 28
                        width: 28
                        radius: Theme.widgetRadius
                        color: Theme.cardBg
                        border.color: Theme.cardBorder
                        border.width: 1

                        Text {
                            text: "+"
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeMd
                            font.weight: Font.Bold
                            color: Theme.primary
                            anchors.centerIn: parent
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                let newIdx = notesModel.count;
                                notesModel.append({
                                    title: "note " + (newIdx + 1),
                                    content: ""
                                });
                                root.activeIndex = newIdx;
                                root.saveNotes();
                            }
                        }
                    }
                }
            }

            // Quick Tag shortcuts row
            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Repeater {
                    model: ["- [ ] ", "#todo ", "#ideas ", "#scratch "]
                    delegate: Rectangle {
                        required property string modelData
                        height: 24
                        width: tagText.implicitWidth + 12
                        radius: Theme.radiusPill
                        color: Theme.pillBg
                        border.color: Theme.pillBorder
                        border.width: 1

                        Text {
                            id: tagText
                            text: modelData.trim()
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                            color: Theme.on_surface_variant
                            anchors.centerIn: parent
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (notesModel.count > root.activeIndex) {
                                    noteArea.insert(noteArea.cursorPosition, modelData);
                                    noteArea.forceActiveFocus();
                                }
                            }
                        }
                    }
                }
            }

            // Note title editor
            Rectangle {
                Layout.fillWidth: true
                height: 32
                radius: Theme.radiusSm
                color: Theme.cardBg
                border.color: titleInput.activeFocus ? Theme.primary : Theme.cardBorder
                border.width: 1

                TextInput {
                    id: titleInput
                    anchors.fill: parent
                    anchors.margins: 6
                    text: notesModel.count > root.activeIndex ? notesModel.get(root.activeIndex).title : ""
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSm
                    font.weight: Font.Bold
                    color: Theme.on_surface
                    selectByMouse: true
                    onTextEdited: {
                        if (notesModel.count > root.activeIndex) {
                            notesModel.setProperty(root.activeIndex, "title", text);
                            saveTimer.restart();
                        }
                    }
                }
            }

            // Main note content editor
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: Theme.radiusSm
                color: Theme.cardBg
                border.color: noteArea.activeFocus ? Theme.primary : Theme.cardBorder
                border.width: 1
                clip: true

                Flickable {
                    id: flick
                    anchors.fill: parent
                    anchors.margins: 10
                    contentWidth: noteArea.width
                    contentHeight: noteArea.height
                    clip: true

                    TextArea.flickable: TextArea {
                        id: noteArea
                        text: notesModel.count > root.activeIndex ? notesModel.get(root.activeIndex).content : ""
                        font.family: Theme.fontMono
                        font.pixelSize: Theme.fontSizeSm
                        color: Theme.on_surface
                        wrapMode: TextEdit.Wrap
                        selectByMouse: true
                        background: null
                        onTextChanged: {
                            if (notesModel.count > root.activeIndex) {
                                notesModel.setProperty(root.activeIndex, "content", text);
                                saveTimer.restart();
                            }
                        }
                    }

                    ScrollBar.vertical: ScrollBar {
                        policy: ScrollBar.AsNeeded
                    }
                }
            }

            // Auto-save debounce timer
            Timer {
                id: saveTimer
                interval: 500
                onTriggered: root.saveNotes()
            }

            // Footer info bar
            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: {
                        let content = notesModel.count > root.activeIndex ? notesModel.get(root.activeIndex).content : "";
                        let chars = content.length;
                        let words = content.trim() === "" ? 0 : content.trim().split(/\s+/).length;
                        let lines = content.split("\n").length;
                        return words + " words · " + chars + " chars · " + lines + " lines";
                    }
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                    color: Theme.on_surface_disabled
                    Layout.fillWidth: true
                }

                Text {
                    text: "auto-saved locally"
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                    color: Theme.primary
                }
            }
        }
    }
}
