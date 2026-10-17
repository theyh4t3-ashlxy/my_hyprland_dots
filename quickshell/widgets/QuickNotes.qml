import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import ".."
import "../controls"
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

Rectangle {
    id: root

    implicitWidth: Theme.isVertical ? (Theme.barHeight - 8) : (noteRow.implicitWidth + 20)
    implicitHeight: Theme.barHeight - 8
    radius: Theme.radiusPill
    color: popup.open ? Theme.primary_overlay : (nMouse.containsMouse ? Theme.pillHover : Theme.pillBg)
    border.color: Theme.pillBorder
    border.width: Theme.pillBorder === "transparent" ? 0 : 1
    visible: Settings.showQuickNotes

    Behavior on color { ColorAnimation { duration: Theme.animFast } }
    Behavior on border.color { ColorAnimation { duration: Theme.animFast } }

    property var barScreen: null
    property var barMonitor: null
    property int activeIndex: 0
    property int lastCursorPos: 0
    property bool isSyncingEditor: false
    property bool isSavingNotes: false
    property bool isSavingTasks: false
    property bool copiedFeedback: false
    property bool savedFeedback: false
    property string activeTab: "notes"
    property string taskFilter: "all"
    property string newPriority: "normal"

    property int pendingTasksCount: 0
    property int completedTasksCount: 0
    property int totalTasksCount: 0
    property int noteWordCount: 0
    property int noteCharCount: 0
    property int noteLineCount: 1

    readonly property string dataDir: (Quickshell.env("XDG_DATA_HOME") || ((Quickshell.env("HOME") || "") + "/.local/share")) + "/quickshell"
    readonly property string notesFilePath: dataDir + "/notes.json"
    readonly property string tasksFilePath: dataDir + "/tasks.json"

    ListModel { id: notesModel }
    ListModel { id: tasksModel }
    ListModel { id: filteredTasksModel }

    property FileView notesFile: FileView {
        path: root.notesFilePath
        watchChanges: true
        printErrors: false
        onFileChanged: {
            if (root.isSavingNotes) return;
            reload();
            root.loadNotes(text());
        }
        onLoaded: root.loadNotes(text())
    }

    property FileView tasksFile: FileView {
        path: root.tasksFilePath
        watchChanges: true
        printErrors: false
        onFileChanged: {
            if (root.isSavingTasks) return;
            reload();
            root.loadTasks(text());
        }
        onLoaded: root.loadTasks(text())
    }

    function isTargetMonitorActive() {
        return !root.barScreen
            || Quickshell.screens.length <= 1
            || (root.barMonitor && Hyprland.focusedMonitor && root.barMonitor.id === Hyprland.focusedMonitor.id);
    }

    function updatePosition() {
        let pt = root.mapToItem(null, 0, 0);
        let barFloats = Settings?.barFloating ?? false;
        let barMarg = barFloats ? ((Settings?.barMargin > 0) ? Settings.barMargin : 8) : 0;
        if (pt && root.visible) {
            popup.targetRelativeX = pt.x + (root.width / 2) + barMarg;
            popup.targetRelativeY = pt.y + (root.height / 2);
        } else {
            popup.targetRelativeX = 0;
            popup.targetRelativeY = 0;
        }
    }

    function computeFullNoteStats(s) {
        let str = s || "";
        let len = str.length;
        root.noteCharCount = len;
        if (len === 0) {
            root.noteWordCount = 0;
            root.noteLineCount = 1;
            return;
        }
        let words = 0;
        let lines = 1;
        let inWord = false;
        for (let i = 0; i < len; i++) {
            let code = str.charCodeAt(i);
            if (code === 10) lines++;
            let isSpace = (code === 32 || code === 9 || code === 10 || code === 13);
            if (!isSpace) {
                if (!inWord) {
                    words++;
                    inWord = true;
                }
            } else {
                inWord = false;
            }
        }
        root.noteWordCount = words;
        root.noteLineCount = lines;
    }

    function syncEditorFromModel() {
        root.isSyncingEditor = true;
        if (notesModel.count > 0) {
            let idx = Math.max(0, Math.min(root.activeIndex, notesModel.count - 1));
            if (idx !== root.activeIndex) root.activeIndex = idx;
            let item = notesModel.get(idx);
            let titleStr = item ? (item.title || "") : "";
            let bodyStr = item ? (item.content || "") : "";
            if (titleInput.text !== titleStr) titleInput.text = titleStr;
            if (noteArea.text !== bodyStr) noteArea.text = bodyStr;
            root.lastCursorPos = bodyStr.length;
            root.computeFullNoteStats(bodyStr);
        } else {
            titleInput.text = "";
            noteArea.text = "";
            root.lastCursorPos = 0;
            root.computeFullNoteStats("");
        }
        root.isSyncingEditor = false;
    }

    onActiveIndexChanged: syncEditorFromModel()
    onTaskFilterChanged: rebuildFilteredTasks()

    function recalcTaskCounts() {
        let pending = 0;
        let done = 0;
        for (let i = 0; i < tasksModel.count; i++) {
            if (tasksModel.get(i).done) done++;
            else pending++;
        }
        root.pendingTasksCount = pending;
        root.completedTasksCount = done;
        root.totalTasksCount = tasksModel.count;
    }

    function rebuildFilteredTasks() {
        root.recalcTaskCounts();
        filteredTasksModel.clear();
        for (let i = 0; i < tasksModel.count; i++) {
            let t = tasksModel.get(i);
            if (root.taskFilter === "todo" && t.done) continue;
            if (root.taskFilter === "done" && !t.done) continue;
            filteredTasksModel.append({
                sourceIdx: i,
                id: t.id,
                text: t.text,
                done: t.done,
                priority: t.priority,
                createdAt: t.createdAt
            });
        }
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
                if (root.activeIndex >= notesModel.count) {
                    root.activeIndex = Math.max(0, notesModel.count - 1);
                }
                root.syncEditorFromModel();
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
        root.activeIndex = 0;
        root.syncEditorFromModel();
        saveNotesNow();
    }

    function saveNotesNow() {
        root.computeFullNoteStats(noteArea.text);
        let arr = [];
        for (let i = 0; i < notesModel.count; i++) {
            let item = notesModel.get(i);
            arr.push({
                title: item.title,
                content: item.content
            });
        }
        root.isSavingNotes = true;
        notesFile.setText(JSON.stringify(arr));
        writeGuardTimer.restart();
        root.savedFeedback = true;
        savedBadgeTimer.restart();
    }

    function addNewNote() {
        let newIdx = notesModel.count;
        notesModel.append({
            title: "note " + (newIdx + 1),
            content: ""
        });
        root.activeIndex = newIdx;
        root.syncEditorFromModel();
        saveTimer.restart();
        Qt.callLater(() => {
            noteTabsFlick.contentX = Math.max(0, noteTabsRow.width - noteTabsFlick.width);
            if (popup.pinned) titleInput.forceActiveFocus();
        });
    }

    function deleteNoteAt(idx) {
        if (notesModel.count <= 1 || idx < 0 || idx >= notesModel.count) return;
        let wasActive = (idx === root.activeIndex);
        let wasBefore = (idx < root.activeIndex);
        notesModel.remove(idx);

        if (wasBefore) {
            root.activeIndex = Math.max(0, root.activeIndex - 1);
        } else if (root.activeIndex >= notesModel.count) {
            root.activeIndex = Math.max(0, notesModel.count - 1);
        } else if (wasActive) {
            root.syncEditorFromModel();
        }
        saveTimer.restart();
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
                root.rebuildFilteredTasks();
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
        root.rebuildFilteredTasks();
        saveTasksNow();
    }

    function saveTasksNow() {
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
        root.isSavingTasks = true;
        tasksFile.setText(JSON.stringify(arr));
        writeGuardTimer.restart();
        root.savedFeedback = true;
        savedBadgeTimer.restart();
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
        root.rebuildFilteredTasks();
        taskSaveTimer.restart();
    }

    function toggleTaskDone(filteredIdx, srcIdx) {
        if (srcIdx < 0 || srcIdx >= tasksModel.count) return;
        let nextDone = !tasksModel.get(srcIdx).done;
        tasksModel.setProperty(srcIdx, "done", nextDone);

        if (root.taskFilter === "all") {
            filteredTasksModel.setProperty(filteredIdx, "done", nextDone);
            root.recalcTaskCounts();
        } else {
            root.rebuildFilteredTasks();
        }
        taskSaveTimer.restart();
    }

    function cycleTaskPriority(filteredIdx, srcIdx) {
        if (srcIdx < 0 || srcIdx >= tasksModel.count) return;
        let cur = tasksModel.get(srcIdx).priority;
        let nextP = cur === "normal" ? "urgent" : (cur === "urgent" ? "low" : "normal");
        tasksModel.setProperty(srcIdx, "priority", nextP);
        if (filteredIdx >= 0 && filteredIdx < filteredTasksModel.count) {
            filteredTasksModel.setProperty(filteredIdx, "priority", nextP);
        }
        taskSaveTimer.restart();
    }

    function updateTaskText(filteredIdx, srcIdx, newText) {
        if (srcIdx < 0 || srcIdx >= tasksModel.count) return;
        tasksModel.setProperty(srcIdx, "text", newText);
        if (filteredIdx >= 0 && filteredIdx < filteredTasksModel.count) {
            filteredTasksModel.setProperty(filteredIdx, "text", newText);
        }
        taskSaveTimer.restart();
    }

    function removeTask(srcIdx) {
        if (srcIdx < 0 || srcIdx >= tasksModel.count) return;
        tasksModel.remove(srcIdx);
        root.rebuildFilteredTasks();
        taskSaveTimer.restart();
    }

    function clearCompletedTasks() {
        for (let i = tasksModel.count - 1; i >= 0; i--) {
            if (tasksModel.get(i).done) {
                tasksModel.remove(i);
            }
        }
        root.rebuildFilteredTasks();
        taskSaveTimer.restart();
    }

    function focusActiveField() {
        if (!popup.open || !popup.pinned) return;
        Qt.callLater(() => {
            if (root.activeTab === "notes") noteArea.forceActiveFocus();
            else taskInput.forceActiveFocus();
        });
    }

    Component.onCompleted: {
        notesFile.reload();
        tasksFile.reload();
    }

    component SlimScrollTrack: Rectangle {
        id: stRoot
        required property Flickable target
        anchors.right: target ? target.right : undefined
        anchors.top: target ? target.top : undefined
        anchors.bottom: target ? target.bottom : undefined
        anchors.margins: 2
        width: stMouse.containsMouse || stMouse.pressed ? 6 : 4
        radius: width / 2
        color: stMouse.containsMouse || stMouse.pressed ? Theme.alpha(Theme.surface_container_highest, 0.6) : "transparent"
        visible: target ? (target.visible && target.contentHeight > target.height + 1) : false

        Behavior on width { NumberAnimation { duration: Theme.animFast } }

        readonly property real trackH: stRoot.height
        readonly property real ratio: stRoot.target ? Math.min(1, stRoot.target.height / Math.max(1, stRoot.target.contentHeight)) : 1
        readonly property real thumbH: Math.max(24, trackH * ratio)
        readonly property real maxScroll: stRoot.target ? Math.max(1, stRoot.target.contentHeight - stRoot.target.height) : 1
        readonly property real scrollProgress: stRoot.target ? Math.max(0, Math.min(1, stRoot.target.contentY / maxScroll)) : 0

        Rectangle {
            width: parent.width
            height: stRoot.thumbH
            y: (stRoot.trackH - stRoot.thumbH) * stRoot.scrollProgress
            radius: parent.radius
            color: Theme.primary
            opacity: stMouse.pressed ? 1.0 : (stMouse.containsMouse ? 0.85 : 0.6)
        }

        MouseArea {
            id: stMouse
            anchors.fill: parent
            anchors.leftMargin: -4
            anchors.rightMargin: -2
            hoverEnabled: true
            preventStealing: true
            cursorShape: Qt.PointingHandCursor

            function scrubTo(mouseY) {
                if (!stRoot.target) return;
                let usable = Math.max(1, stRoot.trackH - stRoot.thumbH);
                let t = Math.max(0, Math.min(1, (mouseY - stRoot.thumbH / 2) / usable));
                stRoot.target.contentY = t * stRoot.maxScroll;
            }

            onPressed: (mouse) => scrubTo(mouse.y)
            onPositionChanged: (mouse) => {
                if (pressed) scrubTo(mouse.y);
            }
        }
    }

    component MiniChip: Rectangle {
        id: mChip
        property string label: ""
        property string icon: ""
        property bool selected: false
        property bool danger: false
        signal clicked()

        height: 24
        implicitWidth: mChipRow.implicitWidth + 14
        radius: Theme.radiusPill
        color: {
            if (mChip.selected) return mChip.danger ? (Theme.error_overlay ?? Theme.primary_overlay) : Theme.primary_overlay;
            if (mChipMouse.containsMouse) return Theme.surface_container_high;
            return "transparent";
        }
        border.color: {
            if (mChip.selected) return mChip.danger ? (Theme.error ?? "#ff5449") : Theme.primary;
            if (mChipMouse.containsMouse) return Theme.outline;
            return Theme.outline_variant ?? Theme.widgetBorder;
        }
        border.width: 1

        Behavior on color { ColorAnimation { duration: Theme.animFast } }
        Behavior on border.color { ColorAnimation { duration: Theme.animFast } }

        RowLayout {
            id: mChipRow
            anchors.centerIn: parent
            spacing: 4

            Text {
                visible: mChip.icon !== ""
                text: mChip.icon
                font.family: Theme.fontIcon
                font.pixelSize: 10
                color: mChip.danger ? (Theme.error ?? "#ff5449") : (mChip.selected ? Theme.primary : Theme.on_surface_variant)
            }

            Text {
                text: mChip.label
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeXs
                font.weight: mChip.selected ? Font.Bold : Font.Medium
                color: mChip.danger ? (Theme.error ?? "#ff5449") : (mChip.selected ? Theme.primary : Theme.on_surface_variant)
            }
        }

        MouseArea {
            id: mChipMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: mChip.clicked()
        }
    }

    Row {
        id: noteRow
        anchors.centerIn: parent
        spacing: 5

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.activeTab === "tasks" ? Theme.iconCheck : Theme.iconNote
            font.family: Theme.fontIcon
            font.pixelSize: Theme.fontSizeSm
            color: popup.open || nMouse.containsMouse ? Theme.primary : Theme.on_surface

            Behavior on color { ColorAnimation { duration: Theme.animFast } }
        }

        Text {
            visible: !Theme.isVertical
            anchors.verticalCenter: parent.verticalCenter
            text: root.pendingTasksCount > 0
                ? (notesModel.count + "n · " + root.pendingTasksCount + "t")
                : String(notesModel.count)
            font.family: Theme.fontMono
            font.pixelSize: Theme.fontSizeXs
            font.weight: Font.Medium
            color: root.pendingTasksCount > 0 ? Theme.primary : Theme.on_surface_variant
        }
    }

    HoverFlyoutHandler {
        popup: popup
        mouseArea: nMouse
        updatePos: () => root.updatePosition()
    }

    MouseArea {
        id: nMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            root.updatePosition();
            if (!popup.open) {
                popup.pinned = true;
                popup.open = true;
                root.focusActiveField();
            } else if (!popup.pinned) {
                popup.pinned = true;
                root.focusActiveField();
            } else {
                popup.pinned = false;
                popup.open = false;
            }
        }
    }

    Connections {
        target: Settings
        function onRequestQuickNotesToggle() {
            if (root.isTargetMonitorActive()) {
                root.updatePosition();
                if (!popup.open) {
                    popup.pinned = true;
                    popup.open = true;
                    root.focusActiveField();
                } else {
                    popup.pinned = false;
                    popup.open = false;
                }
            }
        }
        function onRequestQuickNotesOpen() {
            if (root.isTargetMonitorActive()) {
                root.updatePosition();
                popup.pinned = true;
                popup.open = true;
                root.focusActiveField();
            }
        }
        function onRequestQuickNotesClose() {
            popup.pinned = false;
            popup.open = false;
        }
    }

    Timer {
        id: copyTimer
        interval: 1500
        onTriggered: root.copiedFeedback = false
    }

    Timer {
        id: savedBadgeTimer
        interval: 1200
        onTriggered: root.savedFeedback = false
    }

    Timer {
        id: writeGuardTimer
        interval: 250
        onTriggered: {
            root.isSavingNotes = false;
            root.isSavingTasks = false;
        }
    }

    Timer {
        id: saveTimer
        interval: 450
        onTriggered: root.saveNotesNow()
    }

    Timer {
        id: taskSaveTimer
        interval: 150
        onTriggered: root.saveTasksNow()
    }

    PopupPanel {
        id: popup
        screen: root.barScreen
        wantsFocus: popup.pinned
        keyboardFocusMode: (popup.open && popup.pinned) ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
        cardWidth: Math.min(480, (popup.screen?.width ?? 1920) - 32)
        cardHeight: Math.min(560, (popup.screen?.height ?? 1080) - 80)
        targetRelativeX: 0
        targetRelativeY: 0

        onOpenChanged: {
            if (!open) {
                popup.pinned = false;
                if (saveTimer.running) {
                    saveTimer.stop();
                    root.saveNotesNow();
                }
                if (taskSaveTimer.running) {
                    taskSaveTimer.stop();
                    root.saveTasksNow();
                }
            }
        }

        content: ColumnLayout {
            id: mainCol
            anchors.fill: parent
            spacing: 10

            Keys.onEscapePressed: (event) => {
                popup.pinned = false;
                popup.open = false;
                event.accepted = true;
            }

            // 1. unified header
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Rectangle {
                    width: 36
                    height: 36
                    radius: Theme.radiusMd
                    color: Theme.primary_overlay
                    border.color: Theme.alpha(Theme.primary, 0.35)
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: root.activeTab === "tasks" ? Theme.iconCheck : Theme.iconNote
                        font.family: Theme.fontIcon
                        font.pixelSize: Theme.fontSizeLg
                        color: Theme.primary
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1

                    Text {
                        text: "scratchpad & tasks"
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeMd
                        font.weight: Font.Bold
                        color: Theme.on_surface
                    }

                    Text {
                        text: {
                            if (root.copiedFeedback) return "copied to clipboard ✓";
                            if (!popup.pinned) return "preview mode • click to edit";
                            if (root.activeTab === "tasks" && root.pendingTasksCount === 0 && Theme.getFlavor) {
                                return Theme.getFlavor("notes_empty", "zero pending tasks · absolute zen");
                            }
                            return notesModel.count + (notesModel.count === 1 ? " note" : " notes")
                                + "  •  " + root.pendingTasksCount + " pending " + (root.pendingTasksCount === 1 ? "task" : "tasks");
                        }
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeXs
                        color: root.copiedFeedback ? Theme.primary : Theme.on_surface_variant
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }

                MiniChip {
                    icon: root.copiedFeedback ? Theme.iconCheck : Theme.iconClipboard
                    label: root.copiedFeedback ? "copied" : "copy"
                    selected: root.copiedFeedback
                    onClicked: {
                        if (root.activeTab === "notes") {
                            if (notesModel.count > root.activeIndex) {
                                Quickshell.clipboardText = noteArea.text;
                                root.copiedFeedback = true;
                                copyTimer.restart();
                            }
                        } else {
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
                }

                MiniChip {
                    visible: root.activeTab === "tasks" && root.completedTasksCount > 0
                    icon: Theme.iconTrash
                    label: "clear done (" + root.completedTasksCount + ")"
                    danger: true
                    onClicked: root.clearCompletedTasks()
                }

                IconButton {
                    icon: Theme.iconClose
                    iconSize: Theme.fontSizeSm
                    tooltip: "close (esc)"
                    onClicked: {
                        popup.pinned = false;
                        popup.open = false;
                    }
                }
            }

            // 2. segmented tab bar
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 36
                radius: Theme.radiusPill
                color: Theme.surface_container_lowest
                border.color: Theme.outline_variant ?? Theme.widgetBorder
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 3
                    spacing: 3

                    Repeater {
                        model: [
                            { id: "notes", label: "scratchpad (" + notesModel.count + ")", icon: Theme.iconNote },
                            { id: "tasks", label: root.pendingTasksCount > 0 ? ("tasks (" + root.pendingTasksCount + " todo)") : "tasks (all done)", icon: Theme.iconCheck }
                        ]

                        delegate: Rectangle {
                            required property var modelData
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            radius: Theme.radiusPill

                            readonly property bool isSelected: root.activeTab === modelData.id

                            color: isSelected
                                ? (Theme.surface_container_high ?? Theme.primary_container)
                                : (segMouse.containsMouse ? Theme.surface_container_low : "transparent")
                            border.color: isSelected ? (Theme.outline_variant ?? Theme.primary) : "transparent"
                            border.width: isSelected ? 1 : 0

                            Behavior on color { ColorAnimation { duration: Theme.animFast } }

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 6

                                Text {
                                    text: modelData.icon
                                    font.family: Theme.fontIcon
                                    font.pixelSize: Theme.fontSizeSm
                                    color: isSelected ? Theme.primary : Theme.on_surface_variant
                                }

                                Text {
                                    text: modelData.label
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSizeSm
                                    font.weight: isSelected ? Font.DemiBold : Font.Medium
                                    color: isSelected ? Theme.on_surface : Theme.on_surface_variant
                                }
                            }

                            MouseArea {
                                id: segMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    popup.pinned = true;
                                    root.activeTab = modelData.id;
                                    root.focusActiveField();
                                }
                            }
                        }
                    }
                }
            }

            // 3. notes tab view
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 8
                visible: root.activeTab === "notes"

                // horizontal note tabs strip
                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: false
                    spacing: 6

                    Flickable {
                        id: noteTabsFlick
                        Layout.fillWidth: true
                        Layout.preferredHeight: 30
                        contentWidth: noteTabsRow.width
                        flickableDirection: Flickable.HorizontalFlick
                        boundsBehavior: Flickable.StopAtBounds
                        clip: true

                        WheelHandler {
                            orientation: Qt.Vertical
                            onWheel: (event) => {
                                const delta = event.angleDelta.y !== 0 ? event.angleDelta.y : event.angleDelta.x;
                                const maxX = Math.max(0, noteTabsFlick.contentWidth - noteTabsFlick.width);
                                noteTabsFlick.contentX = Math.max(0, Math.min(maxX, noteTabsFlick.contentX - delta * 0.6));
                                event.accepted = true;
                            }
                        }

                        Row {
                            id: noteTabsRow
                            height: parent.height
                            spacing: 6

                            Repeater {
                                model: notesModel
                                delegate: Rectangle {
                                    id: noteTabPill
                                    required property int index
                                    required property string title
                                    readonly property bool isCurrent: root.activeIndex === index
                                    readonly property bool showClose: notesModel.count > 1 && (isCurrent || tabPillMouse.containsMouse || delTabMouse.containsMouse)

                                    height: 28
                                    width: tabPillRow.implicitWidth + (showClose ? 14 : 20)
                                    anchors.verticalCenter: parent.verticalCenter
                                    radius: Theme.radiusPill
                                    color: isCurrent
                                        ? Theme.primary_overlay
                                        : (tabPillMouse.containsMouse ? Theme.surface_container_high : Theme.cardBg)
                                    border.color: isCurrent ? Theme.primary : Theme.cardBorder
                                    border.width: 1

                                    Behavior on color { ColorAnimation { duration: Theme.animFast } }
                                    Behavior on border.color { ColorAnimation { duration: Theme.animFast } }

                                    RowLayout {
                                        id: tabPillRow
                                        anchors.centerIn: parent
                                        spacing: 6

                                        Text {
                                            text: noteTabPill.title !== "" ? noteTabPill.title : ("note " + (noteTabPill.index + 1))
                                            font.family: Theme.fontFamily
                                            font.pixelSize: Theme.fontSizeXs
                                            font.weight: noteTabPill.isCurrent ? Font.Bold : Font.Medium
                                            color: noteTabPill.isCurrent ? Theme.primary : Theme.on_surface
                                            Layout.maximumWidth: 130
                                            elide: Text.ElideRight
                                        }

                                        Rectangle {
                                            visible: noteTabPill.showClose
                                            width: 16
                                            height: 16
                                            radius: 8
                                            color: delTabMouse.containsMouse ? (Theme.error ?? "#ff5449") : Theme.alpha(Theme.primary, 0.2)

                                            Text {
                                                anchors.centerIn: parent
                                                text: Theme.iconClose
                                                font.family: Theme.fontIcon
                                                font.pixelSize: 8
                                                color: delTabMouse.containsMouse ? "#ffffff" : Theme.primary
                                            }

                                            MouseArea {
                                                id: delTabMouse
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: root.deleteNoteAt(noteTabPill.index)
                                            }
                                        }
                                    }

                                    MouseArea {
                                        id: tabPillMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        z: -1
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            popup.pinned = true;
                                            root.activeIndex = noteTabPill.index;
                                            root.focusActiveField();
                                        }
                                    }
                                }
                            }
                        }
                    }

                    MiniChip {
                        label: "+ new"
                        selected: true
                        onClicked: {
                            popup.pinned = true;
                            root.addNewNote();
                        }
                    }
                }

                // unified notebook card
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: Theme.radiusMd
                    color: Theme.cardBg
                    border.color: (noteArea.activeFocus || titleInput.activeFocus) ? Theme.primary : Theme.cardBorder
                    border.width: 1
                    clip: true

                    Behavior on border.color { ColorAnimation { duration: Theme.animFast } }

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 0

                        // fixed-height top bar so it never steals vertical height from the editor
                        Item {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 38
                            Layout.minimumHeight: 38
                            Layout.maximumHeight: 38
                            Layout.fillHeight: false

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 10
                                spacing: 6

                                Text {
                                    text: Theme.iconEdit
                                    font.family: Theme.fontIcon
                                    font.pixelSize: Theme.fontSizeSm
                                    color: titleInput.activeFocus ? Theme.primary : Theme.on_surface_variant
                                }

                                TextInput {
                                    id: titleInput
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 28
                                    verticalAlignment: TextInput.AlignVCenter
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSizeSm
                                    font.weight: Font.Bold
                                    color: Theme.on_surface
                                    selectByMouse: true
                                    activeFocusOnTab: true
                                    KeyNavigation.tab: noteArea
                                    clip: true

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: "note title..."
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.fontSizeSm
                                        color: Theme.on_surface_disabled
                                        visible: titleInput.text.length === 0 && !titleInput.activeFocus
                                    }

                                    onActiveFocusChanged: {
                                        if (activeFocus) popup.pinned = true;
                                    }

                                    onTextEdited: {
                                        if (root.isSyncingEditor) return;
                                        if (notesModel.count > root.activeIndex && root.activeIndex >= 0) {
                                            notesModel.setProperty(root.activeIndex, "title", text);
                                            saveTimer.restart();
                                        }
                                    }

                                    Keys.onReturnPressed: noteArea.forceActiveFocus()
                                    Keys.onEscapePressed: {
                                        popup.pinned = false;
                                        popup.open = false;
                                    }
                                }

                                Repeater {
                                    model: [
                                        { label: "- [ ]", ins: "- [ ] " },
                                        { label: "# h1", ins: "# " },
                                        { label: "• list", ins: "- " },
                                        { label: "time", ins: "__TIME__" }
                                    ]

                                    delegate: Rectangle {
                                        required property var modelData
                                        height: 22
                                        implicitWidth: snipTxt.implicitWidth + 12
                                        radius: Theme.radiusPill
                                        color: snipMouse.containsMouse ? Theme.primary_overlay : Theme.surface_container_high
                                        border.color: snipMouse.containsMouse ? Theme.primary : Theme.outline_variant
                                        border.width: 1

                                        Text {
                                            id: snipTxt
                                            anchors.centerIn: parent
                                            text: modelData.label
                                            font.family: Theme.fontMono
                                            font.pixelSize: 9
                                            color: snipMouse.containsMouse ? Theme.primary : Theme.on_surface_variant
                                        }

                                        MouseArea {
                                            id: snipMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                if (notesModel.count > root.activeIndex) {
                                                    popup.pinned = true;
                                                    let str = modelData.ins === "__TIME__"
                                                        ? ("[" + Qt.formatDateTime(new Date(), "HH:mm") + "] ")
                                                        : modelData.ins;
                                                    let pos = Math.max(0, Math.min(noteArea.text.length, root.lastCursorPos));
                                                    noteArea.insert(pos, str);
                                                    root.lastCursorPos = pos + str.length;
                                                    noteArea.forceActiveFocus();
                                                    noteArea.cursorPosition = root.lastCursorPos;
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 1
                            Layout.fillHeight: false
                            color: Theme.widgetBorder
                        }

                        // main note body editor (expands to fill 100% of remaining card height)
                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            Flickable {
                                id: noteFlick
                                anchors.fill: parent
                                anchors.margins: 10
                                contentWidth: width
                                contentHeight: Math.max(height, noteArea.implicitHeight + 16)
                                boundsBehavior: Flickable.StopAtBounds
                                clip: true

                                WheelHandler {
                                    orientation: Qt.Vertical
                                    target: parent
                                }

                                TextEdit {
                                    id: noteArea
                                    width: noteFlick.width
                                    height: Math.max(noteFlick.height, implicitHeight)
                                    font.family: Theme.fontMono
                                    font.pixelSize: Theme.fontSizeSm
                                    color: Theme.on_surface
                                    selectionColor: Theme.primary_container
                                    selectedTextColor: Theme.on_primary_container
                                    wrapMode: TextEdit.Wrap
                                    selectByMouse: true
                                    activeFocusOnTab: true
                                    KeyNavigation.tab: titleInput

                                    Text {
                                        anchors.top: parent.top
                                        anchors.left: parent.left
                                        width: parent.width
                                        text: Theme.getFlavor
                                            ? Theme.getFlavor("notes_empty", "type notes, snippets, or markdown memos here...")
                                            : "type notes, snippets, or markdown memos here..."
                                        font.family: Theme.fontMono
                                        font.pixelSize: Theme.fontSizeSm
                                        color: Theme.on_surface_disabled
                                        wrapMode: Text.Wrap
                                        visible: noteArea.text.length === 0 && !noteArea.activeFocus
                                    }

                                    onActiveFocusChanged: {
                                        if (activeFocus) popup.pinned = true;
                                    }

                                    onCursorPositionChanged: {
                                        if (activeFocus && !root.isSyncingEditor) {
                                            root.lastCursorPos = cursorPosition;
                                        }
                                    }

                                    onCursorRectangleChanged: {
                                        if (cursorRectangle.y < noteFlick.contentY) {
                                            noteFlick.contentY = cursorRectangle.y;
                                        } else if (cursorRectangle.y + cursorRectangle.height > noteFlick.contentY + noteFlick.height) {
                                            noteFlick.contentY = cursorRectangle.y + cursorRectangle.height - noteFlick.height;
                                        }
                                    }

                                    onTextChanged: {
                                        if (root.isSyncingEditor) return;
                                        if (notesModel.count > root.activeIndex && root.activeIndex >= 0) {
                                            notesModel.setProperty(root.activeIndex, "content", text);
                                            root.noteCharCount = text.length;
                                            saveTimer.restart();
                                        }
                                    }

                                    Keys.onEscapePressed: {
                                        popup.pinned = false;
                                        popup.open = false;
                                    }
                                }
                            }

                            SlimScrollTrack { target: noteFlick }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 1
                            Layout.fillHeight: false
                            color: Theme.widgetBorder
                        }

                        // fixed-height bottom status bar
                        Item {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 28
                            Layout.minimumHeight: 28
                            Layout.maximumHeight: 28
                            Layout.fillHeight: false

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 8

                                Text {
                                    text: root.noteWordCount + " words  •  " + root.noteCharCount + " chars  •  " + root.noteLineCount + " lines"
                                    font.family: Theme.fontMono
                                    font.pixelSize: 9
                                    color: Theme.on_surface_variant
                                    Layout.fillWidth: true
                                }

                                Text {
                                    visible: noteArea.text.length > 0
                                    text: "clear"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 10
                                    font.weight: Font.Medium
                                    color: clearNoteMouse.containsMouse ? (Theme.error ?? "#ff5449") : Theme.on_surface_variant

                                    MouseArea {
                                        id: clearNoteMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            popup.pinned = true;
                                            noteArea.text = "";
                                            root.lastCursorPos = 0;
                                            noteArea.forceActiveFocus();
                                        }
                                    }
                                }

                                Text {
                                    text: saveTimer.running ? "saving..." : (root.savedFeedback ? "saved ✓" : "synced")
                                    font.family: Theme.fontMono
                                    font.pixelSize: 9
                                    font.weight: Font.Bold
                                    color: Theme.primary
                                }
                            }
                        }
                    }
                }
            }

            // 4. tasks tab view
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 8
                visible: root.activeTab === "tasks"

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 40
                    Layout.fillHeight: false
                    radius: Theme.radiusMd
                    color: Theme.cardBg
                    border.color: taskInput.activeFocus ? Theme.primary : Theme.cardBorder
                    border.width: 1

                    Behavior on border.color { ColorAnimation { duration: Theme.animFast } }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 6
                        spacing: 8

                        Rectangle {
                            height: 26
                            implicitWidth: prioComposerRow.implicitWidth + 14
                            radius: Theme.radiusPill
                            color: {
                                if (root.newPriority === "urgent") return Theme.alpha(Theme.error ?? "#ff5449", 0.16);
                                if (root.newPriority === "low") return Theme.surface_container_highest;
                                return Theme.primary_overlay;
                            }
                            border.color: {
                                if (root.newPriority === "urgent") return Theme.error ?? "#ff5449";
                                if (root.newPriority === "low") return Theme.outline_variant;
                                return Theme.primary;
                            }
                            border.width: 1

                            RowLayout {
                                id: prioComposerRow
                                anchors.centerIn: parent
                                spacing: 5

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
                                    font.family: Theme.fontMono
                                    font.pixelSize: 10
                                    font.weight: Font.Bold
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
                                    popup.pinned = true;
                                    if (root.newPriority === "normal") root.newPriority = "urgent";
                                    else if (root.newPriority === "urgent") root.newPriority = "low";
                                    else root.newPriority = "normal";
                                }
                            }
                        }

                        TextInput {
                            id: taskInput
                            Layout.fillWidth: true
                            Layout.preferredHeight: 28
                            verticalAlignment: TextInput.AlignVCenter
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeSm
                            color: Theme.on_surface
                            selectByMouse: true
                            activeFocusOnTab: true
                            clip: true

                            Text {
                                text: "add a new task... (press enter)"
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeSm
                                color: Theme.on_surface_disabled
                                visible: taskInput.text.length === 0 && !taskInput.activeFocus
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            onActiveFocusChanged: {
                                if (activeFocus) popup.pinned = true;
                            }

                            Keys.onReturnPressed: root.addTask()
                            Keys.onEscapePressed: {
                                popup.pinned = false;
                                popup.open = false;
                            }
                        }

                        Rectangle {
                            height: 28
                            implicitWidth: addBtnTxt.implicitWidth + 16
                            radius: Theme.radiusPill
                            color: taskInput.text.trim() !== ""
                                ? Theme.primary
                                : (addTaskMouse.containsMouse ? Theme.surface_container_highest : Theme.surface_container_high)

                            Text {
                                id: addBtnTxt
                                anchors.centerIn: parent
                                text: "+ add"
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeXs
                                font.weight: Font.Bold
                                color: taskInput.text.trim() !== "" ? Theme.on_primary : Theme.on_surface_variant
                            }

                            MouseArea {
                                id: addTaskMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    popup.pinned = true;
                                    root.addTask();
                                }
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: false
                    spacing: 6

                    Repeater {
                        model: [
                            { id: "all", label: "all (" + root.totalTasksCount + ")" },
                            { id: "todo", label: "todo (" + root.pendingTasksCount + ")" },
                            { id: "done", label: "done (" + root.completedTasksCount + ")" }
                        ]

                        delegate: MiniChip {
                            required property var modelData
                            label: modelData.label
                            selected: root.taskFilter === modelData.id
                            onClicked: root.taskFilter = modelData.id
                        }
                    }

                    Item { Layout.fillWidth: true }

                    RowLayout {
                        visible: root.totalTasksCount > 0
                        spacing: 6

                        Text {
                            text: Math.round((root.completedTasksCount / Math.max(1, root.totalTasksCount)) * 100) + "%"
                            font.family: Theme.fontMono
                            font.pixelSize: 10
                            font.weight: Font.Bold
                            color: Theme.primary
                        }

                        Rectangle {
                            width: 64
                            height: 6
                            radius: 3
                            color: Theme.surface_container_highest
                            clip: true

                            Rectangle {
                                height: parent.height
                                width: parent.width * (root.completedTasksCount / Math.max(1, root.totalTasksCount))
                                radius: 3
                                color: Theme.primary

                                Behavior on width { NumberAnimation { duration: Theme.animFast; easing.type: Theme.animEasing } }
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: Theme.radiusMd
                    color: Theme.cardBg
                    border.color: Theme.cardBorder
                    border.width: 1
                    clip: true

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 8
                        visible: filteredTasksModel.count === 0

                        Text {
                            text: root.pendingTasksCount === 0 ? Theme.kaoSparkle : Theme.kaoCoffee
                            font.family: Theme.fontFamily
                            font.pixelSize: 28
                            color: Theme.primary
                            Layout.alignment: Qt.AlignHCenter
                        }

                        Text {
                            text: root.pendingTasksCount === 0
                                ? (Theme.getFlavor ? Theme.getFlavor("notes_empty", "zero pending tasks · absolute zen status") : "zero pending tasks · absolute zen status")
                                : "no tasks match this filter"
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeSm
                            color: Theme.on_surface_variant
                            Layout.alignment: Qt.AlignHCenter
                            horizontalAlignment: Text.AlignHCenter
                        }
                    }

                    ListView {
                        id: tasksListView
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 6
                        model: filteredTasksModel
                        boundsBehavior: Flickable.StopAtBounds
                        clip: true
                        cacheBuffer: 240

                        WheelHandler {
                            orientation: Qt.Vertical
                            target: parent
                        }

                        delegate: Rectangle {
                            id: taskCard
                            required property int index
                            required property int sourceIdx
                            required property int id
                            required property string text
                            required property bool done
                            required property string priority

                            width: tasksListView.width
                            implicitHeight: Math.max(40, taskTextEdit.implicitHeight + 18)
                            height: implicitHeight
                            radius: Theme.radiusSm
                            color: taskHover.hovered || taskTextEdit.activeFocus ? Theme.surface_container_highest : Theme.surface_container_high
                            border.color: {
                                if (taskTextEdit.activeFocus) return Theme.primary;
                                if (taskCard.done) return "transparent";
                                if (taskHover.hovered) return Theme.outline_variant;
                                return Theme.widgetBorder;
                            }
                            border.width: 1
                            opacity: taskCard.done ? 0.62 : 1.0

                            Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
                            Behavior on color { ColorAnimation { duration: Theme.animFast } }

                            HoverHandler { id: taskHover }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 8
                                spacing: 8

                                Rectangle {
                                    Layout.preferredWidth: 20
                                    Layout.preferredHeight: 20
                                    Layout.alignment: Qt.AlignVCenter
                                    radius: 5
                                    color: taskCard.done ? Theme.primary : (chkMouse.containsMouse ? Theme.primary_overlay : "transparent")
                                    border.color: taskCard.done || chkMouse.containsMouse ? Theme.primary : Theme.outline
                                    border.width: taskCard.done ? 0 : 1.5

                                    Behavior on color { ColorAnimation { duration: Theme.animFast } }

                                    Text {
                                        anchors.centerIn: parent
                                        text: Theme.iconCheck
                                        font.family: Theme.fontIcon
                                        font.pixelSize: 11
                                        color: Theme.on_primary
                                        visible: taskCard.done
                                    }

                                    MouseArea {
                                        id: chkMouse
                                        anchors.fill: parent
                                        anchors.margins: -4
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.toggleTaskDone(taskCard.index, taskCard.sourceIdx)
                                    }
                                }

                                Rectangle {
                                    Layout.preferredWidth: pBadgeText.implicitWidth + 12
                                    Layout.preferredHeight: 20
                                    Layout.alignment: Qt.AlignVCenter
                                    radius: Theme.radiusPill
                                    color: {
                                        if (taskCard.priority === "urgent") return Theme.alpha(Theme.error ?? "#ff5449", 0.16);
                                        if (taskCard.priority === "low") return Theme.surface_container_highest;
                                        return Theme.primary_overlay;
                                    }
                                    border.color: {
                                        if (taskCard.priority === "urgent") return Theme.error ?? "#ff5449";
                                        if (taskCard.priority === "low") return Theme.outline_variant;
                                        return Theme.primary;
                                    }
                                    border.width: 1

                                    Text {
                                        id: pBadgeText
                                        anchors.centerIn: parent
                                        text: taskCard.priority
                                        font.family: Theme.fontMono
                                        font.pixelSize: 9
                                        font.weight: Font.Bold
                                        color: {
                                            if (taskCard.priority === "urgent") return Theme.error ?? "#ff5449";
                                            if (taskCard.priority === "low") return Theme.on_surface_variant;
                                            return Theme.primary;
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.cycleTaskPriority(taskCard.index, taskCard.sourceIdx)
                                    }
                                }

                                TextEdit {
                                    id: taskTextEdit
                                    Layout.fillWidth: true
                                    Layout.preferredWidth: 0
                                    Layout.alignment: Qt.AlignVCenter
                                    text: taskCard.text
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSizeSm
                                    font.strikeout: taskCard.done
                                    color: taskCard.done ? Theme.on_surface_disabled : Theme.on_surface
                                    selectionColor: Theme.primary_container
                                    selectedTextColor: Theme.on_primary_container
                                    wrapMode: TextEdit.WrapAnywhere
                                    selectByMouse: true
                                    activeFocusOnTab: true

                                    onActiveFocusChanged: {
                                        if (activeFocus) popup.pinned = true;
                                    }

                                    onTextChanged: {
                                        if (activeFocus && text !== taskCard.text) {
                                            root.updateTaskText(taskCard.index, taskCard.sourceIdx, text);
                                        }
                                    }

                                    Keys.onTabPressed: (event) => {
                                        taskTextEdit.focus = false;
                                        event.accepted = true;
                                    }
                                    Keys.onReturnPressed: (event) => {
                                        taskTextEdit.focus = false;
                                        event.accepted = true;
                                    }
                                    Keys.onEscapePressed: {
                                        popup.pinned = false;
                                        popup.open = false;
                                    }
                                }

                                IconButton {
                                    Layout.preferredWidth: 24
                                    Layout.preferredHeight: 24
                                    Layout.alignment: Qt.AlignVCenter
                                    icon: Theme.iconClose
                                    tooltip: "delete task"
                                    iconColor: Theme.error
                                    iconSize: 10
                                    opacity: taskHover.hovered ? 1.0 : 0.35
                                    Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
                                    onClicked: root.removeTask(taskCard.sourceIdx)
                                }
                            }
                        }
                    }

                    SlimScrollTrack { target: tasksListView }
                }
            }
        }
    }
}
