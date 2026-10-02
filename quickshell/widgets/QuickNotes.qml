import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import ".."
import "../controls"
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

// QuickNotes & Tasks — because keeping thoughts in /dev/null is only funny until you miss a deadline.
// Native Quickshell FileView JSON persistence: zero bash subshells, zero waybar clunk, pure QtQuick speed.
Rectangle {
    id: root
    implicitWidth: {
        if (Theme.isVertical) return Theme.barHeight - 8;
        return (nMouse.containsMouse || popup.open) ? noteRow.implicitWidth + 24 : Theme.barHeight - 8;
    }
    implicitHeight: Theme.barHeight - 8
    radius: Theme.radiusPill
    color: popup.open ? Theme.primary_overlay : (nMouse.containsMouse ? Theme.pillHover : Theme.pillBg)
    border.color: Theme.pillBorder
    border.width: Theme.pillBorder === "transparent" ? 0 : 1
    visible: Settings.showQuickNotes

    Behavior on color { ColorAnimation { duration: Theme.animFast } }
    Behavior on border.color { ColorAnimation { duration: Theme.animFast } }
    Behavior on implicitWidth { NumberAnimation { duration: Theme.animFast; easing.type: Theme.animEasing } }

    property var barScreen: null
    property var barMonitor: null
    property int activeIndex: 0
    property bool copiedFeedback: false
    property string activeTab: "notes"       // "notes" | "tasks"
    property string taskFilter: "all"        // "all" | "todo" | "done"
    property string newPriority: "normal"    // "urgent" | "normal" | "low"

    function updatePosition() {
        let pt = root.mapToItem(null, 0, 0);
        let barFloats = Settings?.barFloating ?? false;
        let barMarg = barFloats ? ((Settings?.barMargin > 0) ? Settings.barMargin : 8) : 0;
        if (pt && pt.x > 0 && root.visible) {
            popup.targetRelativeX = pt.x + (root.width / 2) + barMarg;
            popup.targetRelativeY = pt.y + (root.height / 2);
        } else {
            popup.targetRelativeX = 0;
            popup.targetRelativeY = 0;
        }
    }

    readonly property int pendingTasksCount: {
        let count = 0;
        for (let i = 0; i < tasksModel.count; i++) {
            if (!tasksModel.get(i).done) count++;
        }
        return count;
    }

    ListModel {
        id: notesModel
    }

    ListModel {
        id: tasksModel
    }

    readonly property string notesFilePath: (Quickshell.env("XDG_DATA_HOME") || ((Quickshell.env("HOME") || "") + "/.local/share")) + "/quickshell/notes.json"
    readonly property string tasksFilePath: (Quickshell.env("XDG_DATA_HOME") || ((Quickshell.env("HOME") || "") + "/.local/share")) + "/quickshell/tasks.json"

    property FileView notesFile: FileView {
        path: root.notesFilePath
        watchChanges: false
        printErrors: false
        onLoaded: root.loadNotes(text())
    }

    property FileView tasksFile: FileView {
        path: root.tasksFilePath
        watchChanges: false
        printErrors: false
        onLoaded: root.loadTasks(text())
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
        notesFile.setText(jsonStr);
    }

    function loadTasks(raw) {
        try {
            tasksModel.clear();
            if (!raw || raw.trim() === "") {
                createDefaultTasks();
                return;
            }
            let parsed = JSON.parse(raw);
            let items = Array.isArray(parsed) ? parsed : (parsed.tasks || []);
            if (Array.isArray(items) && items.length > 0) {
                for (let i = 0; i < items.length; i++) {
                    tasksModel.append({
                        id: items[i].id || (Date.now() + i),
                        text: items[i].text || "",
                        done: Boolean(items[i].done),
                        priority: items[i].priority || "normal",
                        createdAt: items[i].createdAt || Date.now()
                    });
                }
            } else {
                createDefaultTasks();
            }
        } catch (e) {
            createDefaultTasks();
        }
    }

    function createDefaultTasks() {
        tasksModel.clear();
        tasksModel.append({
            id: 1,
            text: "replace waybar slurp & wf-recorder with native quickshell magic",
            done: true,
            priority: "urgent",
            createdAt: Date.now() - 60000
        });
        tasksModel.append({
            id: 2,
            text: "flex on brain_shell without spawning 500 bash subshells",
            done: true,
            priority: "urgent",
            createdAt: Date.now() - 30000
        });
        tasksModel.append({
            id: 3,
            text: "pipewire peak audio visualizer with 0% idle cpu",
            done: false,
            priority: "normal",
            createdAt: Date.now()
        });
        tasksModel.append({
            id: 4,
            text: "stare into the existential void and touch grass (optional)",
            done: false,
            priority: "low",
            createdAt: Date.now()
        });
        saveTasks();
    }

    function saveTasks() {
        let arr = [];
        for (let i = 0; i < tasksModel.count; i++) {
            let item = tasksModel.get(i);
            arr.push({
                id: item.id,
                text: item.text,
                done: item.done,
                priority: item.priority,
                createdAt: item.createdAt
            });
        }
        let jsonStr = JSON.stringify(arr, null, 2);
        tasksFile.setText(jsonStr);
    }

    function addTask() {
        let txt = taskInput.text.trim();
        if (!txt) return;
        tasksModel.insert(0, {
            id: Date.now(),
            text: txt,
            done: false,
            priority: root.newPriority,
            createdAt: Date.now()
        });
        taskInput.text = "";
        saveTasks();
    }

    function clearCompletedTasks() {
        for (let i = tasksModel.count - 1; i >= 0; i--) {
            if (tasksModel.get(i).done) {
                tasksModel.remove(i);
            }
        }
        saveTasks();
    }

    Component.onCompleted: {
        notesFile.reload();
        tasksFile.reload();
    }

    Row {
        id: noteRow
        anchors.centerIn: parent
        spacing: 6

        Item {
            width: iconTxt.implicitWidth
            height: iconTxt.implicitHeight
            anchors.verticalCenter: parent.verticalCenter

            Text {
                id: iconTxt
                anchors.centerIn: parent
                text: root.activeTab === "tasks" ? Theme.iconCheck : Theme.iconNote
                font.family: Theme.fontIcon
                font.pixelSize: Theme.fontSizeSm
                color: popup.open ? Theme.primary : (nMouse.containsMouse ? Theme.primary : Theme.on_surface)
            }

            Rectangle {
                visible: root.pendingTasksCount > 0 && !(nMouse.containsMouse || popup.open)
                width: 6
                height: 6
                radius: 3
                color: Theme.primary
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.topMargin: -2
                anchors.rightMargin: -2
            }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: {
                if (root.activeTab === "tasks") {
                    return root.pendingTasksCount === 0 ? "tasks (all done)" : (root.pendingTasksCount + " " + (root.pendingTasksCount === 1 ? "task" : "tasks"));
                }
                if (notesModel.count === 0 && root.pendingTasksCount === 0) {
                    return Theme.getFlavor("notes_empty", "no notes");
                }
                if (root.pendingTasksCount > 0) {
                    return notesModel.count + "n · " + root.pendingTasksCount + "t";
                }
                return notesModel.count + " notes";
            }
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeSm
            font.weight: Font.Medium
            color: Theme.on_surface
            visible: !Theme.isVertical && (nMouse.containsMouse || popup.open)
        }
    }

    MouseArea {
        id: nMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            root.updatePosition();
            popup.open = !popup.open;
            if (popup.open) {
                root.notesFile.reload();
                root.loadNotes(root.notesFile.text());
                root.tasksFile.reload();
                root.loadTasks(root.tasksFile.text());
            }
        }
    }

    Connections {
        target: Settings
        function onRequestQuickNotesToggle() {
            if (!root.barScreen || Quickshell.screens.length <= 1 || (root.barMonitor && Hyprland.focusedMonitor && root.barMonitor.id === Hyprland.focusedMonitor.id)) {
                root.updatePosition();
                popup.open = !popup.open;
                if (popup.open) {
                    root.notesFile.reload();
                    root.loadNotes(root.notesFile.text());
                    root.tasksFile.reload();
                    root.loadTasks(root.tasksFile.text());
                }
            }
        }
        function onRequestQuickNotesOpen() {
            if (!root.barScreen || Quickshell.screens.length <= 1 || (root.barMonitor && Hyprland.focusedMonitor && root.barMonitor.id === Hyprland.focusedMonitor.id)) {
                root.updatePosition();
                popup.open = true;
                root.notesFile.reload();
                root.loadNotes(root.notesFile.text());
                root.tasksFile.reload();
                root.loadTasks(root.tasksFile.text());
            }
        }
        function onRequestQuickNotesClose() {
            popup.open = false;
        }
    }

    PopupPanel {
        id: popup
        screen: root.barScreen
        wantsFocus: true
        cardWidth: 460
        cardHeight: 560
        targetRelativeX: 0
        targetRelativeY: 0

        content: ColumnLayout {
            anchors.fill: parent
            spacing: 10

            // Header with Tab Switcher & Actions
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                // Tab Switcher Pill: Notes vs Tasks
                Rectangle {
                    height: 32
                    radius: Theme.radiusPill
                    color: Theme.surface_container_highest
                    border.color: Theme.widgetBorder
                    border.width: 1
                    implicitWidth: tabsRow.implicitWidth + 8

                    RowLayout {
                        id: tabsRow
                        anchors.centerIn: parent
                        spacing: 2

                        // Notes Tab
                        Rectangle {
                            height: 26
                            implicitWidth: notesTabInner.implicitWidth + 16
                            radius: Theme.radiusPill
                            color: root.activeTab === "notes" ? Theme.primary : "transparent"

                            Behavior on color { ColorAnimation { duration: Theme.animFast } }

                            RowLayout {
                                id: notesTabInner
                                anchors.centerIn: parent
                                spacing: 4

                                Text {
                                    text: Theme.iconNote
                                    font.family: Theme.fontIcon
                                    font.pixelSize: Theme.fontSizeSm
                                    color: root.activeTab === "notes" ? Theme.on_primary : Theme.on_surface_variant
                                }

                                Text {
                                    text: "notes"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSizeSm
                                    font.weight: root.activeTab === "notes" ? Font.Bold : Font.Normal
                                    color: root.activeTab === "notes" ? Theme.on_primary : Theme.on_surface_variant
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.activeTab = "notes"
                            }
                        }

                        // Tasks Tab
                        Rectangle {
                            height: 26
                            implicitWidth: tasksTabInner.implicitWidth + 16
                            radius: Theme.radiusPill
                            color: root.activeTab === "tasks" ? Theme.primary : "transparent"

                            Behavior on color { ColorAnimation { duration: Theme.animFast } }

                            RowLayout {
                                id: tasksTabInner
                                anchors.centerIn: parent
                                spacing: 4

                                Text {
                                    text: Theme.iconCheck
                                    font.family: Theme.fontIcon
                                    font.pixelSize: Theme.fontSizeSm
                                    color: root.activeTab === "tasks" ? Theme.on_primary : Theme.on_surface_variant
                                }

                                Text {
                                    text: root.pendingTasksCount > 0 ? ("tasks (" + root.pendingTasksCount + ")") : "tasks"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSizeSm
                                    font.weight: root.activeTab === "tasks" ? Font.Bold : Font.Normal
                                    color: root.activeTab === "tasks" ? Theme.on_primary : Theme.on_surface_variant
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.activeTab = "tasks"
                            }
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                // Notes Actions
                IconButton {
                    visible: root.activeTab === "notes"
                    icon: root.copiedFeedback ? Theme.iconCheck : Theme.iconClipboard
                    tooltip: root.copiedFeedback ? "copied!" : "copy note to clipboard"
                    iconColor: root.copiedFeedback ? Theme.primary : Theme.on_surface
                    onClicked: {
                        if (notesModel.count > root.activeIndex) {
                            let textToCopy = notesModel.get(root.activeIndex).content;
                            Quickshell.clipboardText = textToCopy;
                            root.copiedFeedback = true;
                            copyTimer.restart();
                        }
                    }
                }

                IconButton {
                    visible: root.activeTab === "notes" && notesModel.count > 1
                    icon: Theme.iconClose
                    tooltip: "delete this note"
                    iconColor: Theme.error
                    onClicked: {
                        if (notesModel.count > 1) {
                            notesModel.remove(root.activeIndex);
                            if (root.activeIndex >= notesModel.count) root.activeIndex = notesModel.count - 1;
                            root.saveNotes();
                        }
                    }
                }

                // Tasks Actions
                IconButton {
                    visible: root.activeTab === "tasks"
                    icon: root.copiedFeedback ? Theme.iconCheck : Theme.iconClipboard
                    tooltip: root.copiedFeedback ? "copied markdown checklist!" : "copy tasks as markdown checklist"
                    iconColor: root.copiedFeedback ? Theme.primary : Theme.on_surface
                    onClicked: {
                        let lines = [];
                        for (let i = 0; i < tasksModel.count; i++) {
                            let item = tasksModel.get(i);
                            let tag = item.priority === "urgent" ? "[!] " : (item.priority === "low" ? "[low] " : "");
                            lines.push("- [" + (item.done ? "x" : " ") + "] " + tag + item.text);
                        }
                        Quickshell.clipboardText = lines.join("\n");
                        root.copiedFeedback = true;
                        copyTimer.restart();
                    }
                }

                IconButton {
                    visible: root.activeTab === "tasks" && (tasksModel.count - root.pendingTasksCount > 0)
                    icon: Theme.iconTrash
                    tooltip: "clear completed tasks"
                    iconColor: Theme.error
                    onClicked: root.clearCompletedTasks()
                }
            }

            Timer {
                id: copyTimer
                interval: 1500
                onTriggered: root.copiedFeedback = false
            }

            // =========================================================================
            // NOTES TAB VIEW
            // =========================================================================
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 10
                visible: root.activeTab === "notes"

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
                            placeholderText: Theme.getFlavor("notes_empty", "type notes or memos here...")
                            placeholderTextColor: Theme.on_surface_variant
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

            // =========================================================================
            // TASKS TAB VIEW
            // =========================================================================
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 10
                visible: root.activeTab === "tasks"

                // Filter & Urgency Controls Row
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    // Filter Pills
                    Repeater {
                        model: [
                            { id: "all", label: "all (" + tasksModel.count + ")" },
                            { id: "todo", label: "todo (" + root.pendingTasksCount + ")" },
                            { id: "done", label: "done (" + (tasksModel.count - root.pendingTasksCount) + ")" }
                        ]

                        delegate: Rectangle {
                            required property var modelData
                            height: 24
                            width: fText.implicitWidth + 14
                            radius: Theme.radiusPill
                            color: root.taskFilter === modelData.id ? Theme.primary : Theme.pillBg
                            border.color: root.taskFilter === modelData.id ? Theme.primary : Theme.pillBorder
                            border.width: 1

                            Behavior on color { ColorAnimation { duration: Theme.animFast } }

                            Text {
                                id: fText
                                anchors.centerIn: parent
                                text: modelData.label
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                                font.weight: root.taskFilter === modelData.id ? Font.Bold : Font.Normal
                                color: root.taskFilter === modelData.id ? Theme.on_primary : Theme.on_surface_variant
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.taskFilter = modelData.id
                            }
                        }
                    }

                    Item { Layout.fillWidth: true }
                }

                // Add Task Input Row
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    // Priority Selector Button
                    Rectangle {
                        height: 32
                        implicitWidth: pRow.implicitWidth + 14
                        radius: Theme.radiusSm
                        color: {
                            if (root.newPriority === "urgent") return Theme.alpha(Theme.error ?? "#ff5449", 0.15);
                            if (root.newPriority === "low") return Theme.surface_container_highest;
                            return Theme.primary_overlay;
                        }
                        border.color: {
                            if (root.newPriority === "urgent") return Theme.error ?? "#ff5449";
                            if (root.newPriority === "low") return Theme.outline;
                            return Theme.primary;
                        }
                        border.width: 1

                        RowLayout {
                            id: pRow
                            anchors.centerIn: parent
                            spacing: 4

                            Rectangle {
                                width: 6
                                height: 6
                                radius: 3
                                color: {
                                    if (root.newPriority === "urgent") return Theme.error ?? "#ff5449";
                                    if (root.newPriority === "low") return Theme.on_surface_variant;
                                    return Theme.primary;
                                }
                            }

                            Text {
                                text: root.newPriority
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeXs
                                font.weight: Font.Medium
                                color: {
                                    if (root.newPriority === "urgent") return Theme.error ?? "#ff5449";
                                    if (root.newPriority === "low") return Theme.on_surface_variant;
                                    return Theme.primary;
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (root.newPriority === "normal") root.newPriority = "urgent";
                                else if (root.newPriority === "urgent") root.newPriority = "low";
                                else root.newPriority = "normal";
                            }
                        }
                    }

                    // Task text input
                    Rectangle {
                        Layout.fillWidth: true
                        height: 32
                        radius: Theme.radiusSm
                        color: Theme.cardBg
                        border.color: taskInput.activeFocus ? Theme.primary : Theme.cardBorder
                        border.width: 1

                        TextInput {
                            id: taskInput
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            anchors.topMargin: 6
                            anchors.bottomMargin: 6
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeSm
                            color: Theme.on_surface
                            selectByMouse: true

                            Text {
                                text: "add a task... (press Enter)"
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeSm
                                color: Theme.on_surface_variant
                                visible: !taskInput.text && !taskInput.activeFocus
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Keys.onReturnPressed: root.addTask()
                        }
                    }

                    // Add Button
                    Rectangle {
                        width: 32
                        height: 32
                        radius: Theme.radiusSm
                        color: addMouse.containsMouse ? Theme.primary_overlay : Theme.cardBg
                        border.color: Theme.primary
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: "+"
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeLg
                            font.weight: Font.Bold
                            color: Theme.primary
                        }

                        MouseArea {
                            id: addMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.addTask()
                        }
                    }
                }

                // Tasks List Container
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: Theme.radiusSm
                    color: Theme.cardBg
                    border.color: Theme.cardBorder
                    border.width: 1
                    clip: true

                    // Empty State
                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 8
                        visible: tasksModel.count === 0 || (root.taskFilter === "todo" && root.pendingTasksCount === 0) || (root.taskFilter === "done" && tasksModel.count - root.pendingTasksCount === 0)

                        Text {
                            text: root.pendingTasksCount === 0 ? Theme.kaoSparkle : Theme.kaoCoffee
                            font.family: Theme.fontFamily
                            font.pixelSize: 28
                            color: Theme.primary
                            Layout.alignment: Qt.AlignHCenter
                        }

                        Text {
                            text: root.pendingTasksCount === 0 ? "zero pending tasks · absolute zen status" : "no tasks match this filter"
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeSm
                            color: Theme.on_surface_variant
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }

                    // Task Items
                    Flickable {
                        anchors.fill: parent
                        anchors.margins: 6
                        contentWidth: taskColumn.width
                        contentHeight: taskColumn.implicitHeight
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds

                        ColumnLayout {
                            id: taskColumn
                            width: parent.width
                            spacing: 4

                            Repeater {
                                model: tasksModel
                                delegate: Rectangle {
                                    id: taskItemDelegate
                                    required property int index
                                    required property int id
                                    required property string text
                                    required property bool done
                                    required property string priority

                                    readonly property bool matchesFilter: {
                                        if (root.taskFilter === "todo") return !done;
                                        if (root.taskFilter === "done") return done;
                                        return true;
                                    }

                                    visible: matchesFilter
                                    Layout.fillWidth: true
                                    implicitHeight: matchesFilter ? 38 : 0
                                    radius: Theme.radiusSm
                                    color: taskMouse.containsMouse ? Theme.surface_container_highest : Theme.surface_container
                                    border.color: done ? "transparent" : Theme.widgetBorder
                                    border.width: 1
                                    opacity: done ? 0.65 : 1.0

                                    Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
                                    Behavior on color { ColorAnimation { duration: Theme.animFast } }

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 10
                                        anchors.rightMargin: 10
                                        spacing: 8

                                        // Checkbox
                                        Rectangle {
                                            Layout.preferredWidth: 20
                                            Layout.preferredHeight: 20
                                            Layout.alignment: Qt.AlignVCenter
                                            radius: 5
                                            color: taskItemDelegate.done ? Theme.primary : "transparent"
                                            border.color: taskItemDelegate.done ? Theme.primary : Theme.outline
                                            border.width: taskItemDelegate.done ? 0 : 1.5

                                            Behavior on color { ColorAnimation { duration: Theme.animFast } }

                                            Text {
                                                anchors.centerIn: parent
                                                text: Theme.iconCheck
                                                font.family: Theme.fontIcon
                                                font.pixelSize: 12
                                                color: Theme.on_primary
                                                visible: taskItemDelegate.done
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    tasksModel.setProperty(taskItemDelegate.index, "done", !taskItemDelegate.done);
                                                    root.saveTasks();
                                                }
                                            }
                                        }

                                        // Priority Badge
                                        Rectangle {
                                            Layout.preferredWidth: pBadgeText.implicitWidth + 12
                                            Layout.preferredHeight: 20
                                            Layout.alignment: Qt.AlignVCenter
                                            radius: Theme.radiusPill
                                            color: {
                                                if (taskItemDelegate.priority === "urgent") return Theme.alpha(Theme.error ?? "#ff5449", 0.15);
                                                if (taskItemDelegate.priority === "low") return Theme.surface_container_highest;
                                                return Theme.alpha(Theme.primary, 0.15);
                                            }
                                            border.color: {
                                                if (taskItemDelegate.priority === "urgent") return Theme.error ?? "#ff5449";
                                                if (taskItemDelegate.priority === "low") return Theme.outline;
                                                return Theme.primary;
                                            }
                                            border.width: 1

                                            Text {
                                                id: pBadgeText
                                                anchors.centerIn: parent
                                                text: taskItemDelegate.priority
                                                font.family: Theme.fontFamily
                                                font.pixelSize: 9
                                                font.weight: Font.Bold
                                                color: {
                                                    if (taskItemDelegate.priority === "urgent") return Theme.error ?? "#ff5449";
                                                    if (taskItemDelegate.priority === "low") return Theme.on_surface_variant;
                                                    return Theme.primary;
                                                }
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    let nextP = taskItemDelegate.priority === "normal" ? "urgent" : (taskItemDelegate.priority === "urgent" ? "low" : "normal");
                                                    tasksModel.setProperty(taskItemDelegate.index, "priority", nextP);
                                                    root.saveTasks();
                                                }
                                            }
                                        }

                                        // Task Description
                                        Text {
                                            Layout.fillWidth: true
                                            Layout.alignment: Qt.AlignVCenter
                                            text: taskItemDelegate.text
                                            font.family: Theme.fontFamily
                                            font.pixelSize: Theme.fontSizeSm
                                            font.strikeout: taskItemDelegate.done
                                            color: taskItemDelegate.done ? Theme.on_surface_disabled : Theme.on_surface
                                            elide: Text.ElideRight
                                        }

                                        // Delete Task Button
                                        IconButton {
                                            Layout.preferredWidth: 24
                                            Layout.preferredHeight: 24
                                            Layout.alignment: Qt.AlignVCenter
                                            icon: Theme.iconClose
                                            tooltip: "delete task"
                                            iconColor: Theme.error
                                            iconSize: Theme.fontSizeSm
                                            opacity: taskMouse.containsMouse ? 1.0 : 0.2
                                            Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
                                            onClicked: {
                                                tasksModel.remove(taskItemDelegate.index);
                                                root.saveTasks();
                                            }
                                        }
                                    }

                                    MouseArea {
                                        id: taskMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        propagateComposedEvents: true
                                        z: -1
                                    }
                                }
                            }
                        }

                        ScrollBar.vertical: ScrollBar {
                            policy: ScrollBar.AsNeeded
                        }
                    }
                }

                // Footer stats
                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        text: root.pendingTasksCount === 0
                            ? "all done · no existential panic required"
                            : (root.pendingTasksCount + " pending · " + (tasksModel.count - root.pendingTasksCount) + " completed")
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                        color: Theme.on_surface_disabled
                        Layout.fillWidth: true
                    }

                    Text {
                        text: "auto-saved to tasks.json"
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                        color: Theme.primary
                    }
                }
            }
        }
    }
}
