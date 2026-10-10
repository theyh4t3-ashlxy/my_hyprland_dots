import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import ".."
import "../controls"
import "../services"
import "../corners"
import Quickshell
import Quickshell.Widgets

Rectangle {
    id: root

    property var barScreen: null
    property var barMonitor: null

    // ── Concave Flare & Bezel Attachment ──────────────────────────────────
    readonly property bool isBarFloating: Settings?.barFloating ?? false
    readonly property bool isBarBottom: Settings?.barPosition === "bottom"
    readonly property bool isFlared: (Settings?.dynamicNotchFlared ?? true) && !(Theme?.isVertical ?? false) && !isBarFloating
    readonly property int flareRadius: Settings?.notchFlareRadius ?? 16

    // ── Time & Calendar Properties ─────────────────────────────────────────
    property var currentTime: new Date()
    property int todayYear: (new Date()).getFullYear()
    property int todayMonth: (new Date()).getMonth()
    property int todayDate: (new Date()).getDate()
    property int selectedYear: todayYear
    property int selectedMonth: todayMonth

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            root.currentTime = new Date();
            let d = new Date();
            if (d.getDate() !== root.todayDate || d.getMonth() !== root.todayMonth || d.getFullYear() !== root.todayYear) {
                root.todayYear = d.getFullYear();
                root.todayMonth = d.getMonth();
                root.todayDate = d.getDate();
            }
        }
    }

    function getDayOfYear(d) {
        let target = d || root.currentTime;
        let start = new Date(target.getFullYear(), 0, 0);
        let diff = (target - start) + ((start.getTimezoneOffset() - target.getTimezoneOffset()) * 60 * 1000);
        return Math.floor(diff / 86400000);
    }

    // ── Timer Service Integration ──────────────────────────────────────────
    readonly property bool hasTimerActive: (typeof TimerService !== "undefined" && TimerService) ? (TimerService.timerRunning || TimerService.timerPaused || TimerService.timerRemaining > 0) : false
    readonly property bool hasStopwatchActive: (typeof TimerService !== "undefined" && TimerService) ? (TimerService.stopwatchRunning || TimerService.stopwatchElapsed > 0) : false

    // ── Carousel Modes: "clock", "timer" ───────────────────────────────────
    readonly property var availableModes: {
        let forced = Settings?.dynamicNotchMode ?? "auto";
        if (forced === "clock") return ["clock"];
        if (forced === "timer") return ["timer"];
        let m = ["clock"];
        if (hasTimerActive || hasStopwatchActive) m.push("timer");
        return m;
    }

    property int activeModeIndex: 0
    readonly property string currentMode: {
        let forced = Settings?.dynamicNotchMode ?? "auto";
        if (forced === "clock") return "clock";
        if (forced === "timer") return "timer";
        if (availableModes.length === 0) return "clock";
        let idx = Math.max(0, Math.min(availableModes.length - 1, activeModeIndex));
        return availableModes[idx];
    }

    function nextMode() {
        if (availableModes.length <= 1) return;
        activeModeIndex = (activeModeIndex + 1) % availableModes.length;
    }

    function prevMode() {
        if (availableModes.length <= 1) return;
        activeModeIndex = (activeModeIndex - 1 + availableModes.length) % availableModes.length;
    }

    // Auto-switch to urgent timer when <= 30 seconds remaining, or return to clock when finished
    Connections {
        target: (typeof TimerService !== "undefined" && TimerService) ? TimerService : null
        function onTimerRemainingChanged() {
            if ((Settings?.dynamicNotchMode ?? "auto") === "auto" && TimerService?.timerRunning && TimerService.timerRemaining <= 30 && TimerService.timerRemaining > 0) {
                let tIdx = root.availableModes.indexOf("timer");
                if (tIdx >= 0) root.activeModeIndex = tIdx;
            }
        }
        function onTimerFinished() {
            if ((Settings?.dynamicNotchMode ?? "auto") === "auto") {
                root.activeModeIndex = 0;
            }
        }
    }

    // ── Physical Bar Sizing & Dynamic Geometry ─────────────────────────────
    readonly property real targetImplicitWidth: {
        if (Theme?.isVertical ?? false) return (Theme?.barHeight ?? 32) - 8;
        if (currentMode === "timer") {
            return Math.max(130, timerRow.implicitWidth + 24);
        }
        return Math.max(130, clockRow.implicitWidth + 24);
    }

    implicitWidth: targetImplicitWidth
    implicitHeight: (Theme?.isVertical ?? false) ? 46 : ((Theme?.barHeight ?? 32) - 8)
    width: implicitWidth
    height: isFlared ? ((Theme?.barHeight ?? 32) - 2) : implicitHeight
    y: isFlared ? (isBarBottom ? 2 : - Math.round(((Theme?.barHeight ?? 32) - implicitHeight) / 2)) : 0

    radius: isFlared ? 0 : (Theme?.radiusPill ?? 999)
    topLeftRadius: isFlared ? (isBarBottom ? (Theme.radiusMd > 4 ? Theme.radiusMd : 12) : 0) : (Theme?.radiusPill ?? 999)
    topRightRadius: isFlared ? (isBarBottom ? (Theme.radiusMd > 4 ? Theme.radiusMd : 12) : 0) : (Theme?.radiusPill ?? 999)
    bottomLeftRadius: isFlared ? (!isBarBottom ? (Theme.radiusMd > 4 ? Theme.radiusMd : 12) : 0) : (Theme?.radiusPill ?? 999)
    bottomRightRadius: isFlared ? (!isBarBottom ? (Theme.radiusMd > 4 ? Theme.radiusMd : 12) : 0) : (Theme?.radiusPill ?? 999)

    color: notchPopup.open ? Theme.primary_overlay : (notchMouse.containsMouse ? Theme.pillHover : Theme.pillBg)
    border.color: (Theme?.isCyberNeon ?? false) ? Theme.primary : (Theme?.pillBorder ?? "transparent")
    border.width: ((Theme?.isCyberNeon ?? false) || ((Theme?.pillBorder ?? "transparent") !== "transparent")) ? 1 : 0
    clip: false

    Behavior on color { ColorAnimation { duration: Theme?.animFast ?? 120 } }
    Behavior on border.color { ColorAnimation { duration: Theme?.animFast ?? 120 } }
    Behavior on height { NumberAnimation { duration: Theme?.animNormal ?? 200; easing.type: Theme?.animEasing ?? Easing.OutQuad } }
    Behavior on y { NumberAnimation { duration: Theme?.animNormal ?? 200; easing.type: Theme?.animEasing ?? Easing.OutQuad } }
    Behavior on implicitWidth {
        NumberAnimation {
            duration: Theme?.animNormal ?? 200
            easing.type: Theme?.animEasing ?? Easing.OutQuad
        }
    }
    Behavior on width {
        NumberAnimation {
            duration: Theme?.animNormal ?? 200
            easing.type: Theme?.animEasing ?? Easing.OutQuad
        }
    }

    // Hover scale lift physics (only when not flared into screen bezel)
    scale: !isFlared && (Settings?.bentoHoverLift ?? true) && notchMouse.containsMouse && !notchPopup.open ? 1.02 : 1.0
    Behavior on scale {
        NumberAnimation {
            duration: Theme?.animFast ?? 120
            easing.type: Easing.OutQuad
        }
    }

    // ── Concave Flares (Ears) Melting Into Screen Bezel ──────────────────
    ConcaveCorner {
        id: flareLeft
        visible: root.isFlared
        x: -width
        y: root.isBarBottom ? (root.height - height) : 0
        radiusX: root.flareRadius
        radiusY: root.flareRadius
        fillColor: root.color
        cornerStyle: Settings?.cornerStyle ?? "continuous-bezier"
        flipX: true
        flipY: root.isBarBottom
        showBorder: root.border.width > 0
        borderWidth: root.border.width
        borderColor: root.border.color
    }

    ConcaveCorner {
        id: flareRight
        visible: root.isFlared
        x: root.width
        y: root.isBarBottom ? (root.height - height) : 0
        radiusX: root.flareRadius
        radiusY: root.flareRadius
        fillColor: root.color
        cornerStyle: Settings?.cornerStyle ?? "continuous-bezier"
        flipX: false
        flipY: root.isBarBottom
        showBorder: root.border.width > 0
        borderWidth: root.border.width
        borderColor: root.border.color
    }

    // Glass specular top sheen
    Rectangle {
        visible: Theme?.isGlass ?? false
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 1
        color: Theme.glassHighlight ?? Qt.rgba(1, 1, 1, 0.25)
    }

    // ── Content Carousel Stack ─────────────────────────────────────────────
    Item {
        id: contentContainer
        anchors.fill: parent
        clip: true

        // 1. Clock Mode
        Row {
            id: clockRow
            anchors.centerIn: parent
            spacing: 6
            visible: root.currentMode === "clock"
            opacity: visible ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: Theme?.animFast ?? 120 } }

            Text {
                id: clockMood
                anchors.verticalCenter: parent.verticalCenter
                visible: !(Theme?.isVertical ?? false)
                text: {
                    let hrs = root.currentTime.getHours();
                    if (hrs < 6) return Theme?.iconMoon ?? "\uF186";
                    if (hrs < 12) return Theme?.iconCoffee ?? "\uEFEF";
                    if (hrs < 18) return Theme?.iconSun ?? "\uE518";
                    return Theme?.iconMusic ?? "\uE405";
                }
                font.family: Theme?.fontIcon ?? "sans-serif"
                font.pixelSize: Theme?.fontSizeSm ?? 12
                color: notchPopup.open ? Theme.primary : Theme.on_surface_variant
            }

            Text {
                id: clockTime
                anchors.verticalCenter: parent.verticalCenter
                horizontalAlignment: Text.AlignHCenter
                lineHeight: 0.95
                text: {
                    let now = root.currentTime;
                    let military = (Settings?.clock24h !== undefined ? Settings.clock24h : (Settings?.clockMilitary ?? true));
                    let is12 = (Settings?.clockFormat && /ap/i.test(Settings.clockFormat)) || !military;
                    let showSec = Settings?.clockShowSeconds ?? false;
                    if (Theme?.isVertical ?? false) {
                        if (is12) {
                            let h = now.getHours() % 12;
                            if (h === 0) h = 12;
                            let m = now.getMinutes();
                            let hStr = (h < 10 ? "0" : "") + h;
                            let mStr = (m < 10 ? "0" : "") + m;
                            return hStr + "\n" + mStr;
                        }
                        return Qt.formatDateTime(now, "HH\nmm");
                    }
                    let fmt = is12 ? (showSec ? "h:mm:ss ap" : "h:mm ap") : (showSec ? "HH:mm:ss" : "HH:mm");
                    let timeStr = Qt.formatDateTime(now, fmt).toLowerCase();
                    if (Settings?.showBarDate ?? false) {
                        let dateStr = Qt.formatDateTime(now, Settings?.dateFormat ?? "ddd, MMM d").toLowerCase();
                        return dateStr + "  " + timeStr;
                    }
                    return timeStr;
                }
                font.family: Theme?.fontFamily ?? "sans-serif"
                font.pixelSize: Theme?.fontSizeMd ?? 13
                font.weight: Font.Medium
                color: notchPopup.open ? Theme.primary : Theme.on_surface
            }
        }

        // 2. Timer / Stopwatch Mode
        Row {
            id: timerRow
            anchors.centerIn: parent
            spacing: 6
            visible: root.currentMode === "timer"
            opacity: visible ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: Theme?.animFast ?? 120 } }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: (typeof TimerService !== "undefined" && TimerService?.stopwatchRunning) ? (Theme?.iconClock ?? "\uEFD6") : (Theme?.iconBell ?? "\uE7F5")
                font.family: Theme?.fontIcon ?? "sans-serif"
                font.pixelSize: Theme?.fontSizeSm ?? 12
                color: (typeof TimerService !== "undefined" && TimerService?.timerRunning && TimerService.timerRemaining <= 30) ? Theme.error : Theme.primary
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                visible: !(Theme?.isVertical ?? false)
                text: {
                    if (typeof TimerService === "undefined" || !TimerService) return "00:00";
                    if (TimerService.stopwatchRunning || TimerService.stopwatchElapsed > 0) {
                        return TimerService.stopwatchDisplay;
                    }
                    return TimerService.timerDisplay;
                }
                font.family: Theme?.fontMono ?? "monospace"
                font.pixelSize: Theme?.fontSizeMd ?? 13
                font.weight: Font.Bold
                color: (typeof TimerService !== "undefined" && TimerService?.timerRunning && TimerService.timerRemaining <= 30) ? Theme.error : (notchPopup.open ? Theme.primary : Theme.on_surface)

                SequentialAnimation on opacity {
                    loops: Animation.Infinite
                    running: (typeof TimerService !== "undefined" && TimerService?.timerRunning && TimerService.timerRemaining <= 10 && TimerService.timerRemaining > 0)
                    NumberAnimation { from: 1.0; to: 0.25; duration: 400; easing.type: Easing.InOutQuad }
                    NumberAnimation { from: 0.25; to: 1.0; duration: 400; easing.type: Easing.InOutQuad }
                }
            }

            // Quick Play/Pause on bar for timer
            Text {
                visible: !(Theme?.isVertical ?? false)
                anchors.verticalCenter: parent.verticalCenter
                text: (typeof TimerService !== "undefined" && (TimerService?.timerRunning || TimerService?.stopwatchRunning)) ? (Theme?.iconPause ?? "\uE034") : (Theme?.iconPlay ?? "\uE037")
                font.family: Theme?.fontIcon ?? "sans-serif"
                font.pixelSize: Theme?.fontSizeSm ?? 12
                color: Theme.primary
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -4
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (typeof TimerService === "undefined" || !TimerService) return;
                        if (TimerService.stopwatchRunning || TimerService.stopwatchElapsed > 0) {
                            TimerService.toggleStopwatch();
                        } else {
                            TimerService.toggleTimer();
                        }
                    }
                }
            }
        }
    }

    function syncAnchor() {
        let pt = root.mapToItem(null, 0, 0);
        if (pt) {
            if (Theme?.isVertical ?? false) {
                notchPopup.targetRelativeY = pt.y + (root.height / 2);
            } else {
                notchPopup.targetRelativeX = pt.x + (root.width / 2);
            }
        }
    }

    HoverFlyoutHandler {
        popup: notchPopup
        mouseArea: notchMouse
        updatePos: () => root.syncAnchor()
    }

    // ── Mouse Area for Carousel Cycling & Popup Trigger ───────────────────
    MouseArea {
        id: notchMouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor

        onClicked: function(mouse) {
            if (mouse.button === Qt.LeftButton) {
                root.syncAnchor();
                if (!notchPopup.open) {
                    notchPopup.pinned = true;
                    notchPopup.open = true;
                } else if (!notchPopup.pinned) {
                    notchPopup.pinned = true;
                } else {
                    notchPopup.pinned = false;
                    notchPopup.open = false;
                }
            } else if (mouse.button === Qt.RightButton) {
                root.nextMode();
            }
        }

        onWheel: function(wheel) {
            if (wheel.angleDelta.y < 0) {
                root.nextMode();
            } else {
                root.prevMode();
            }
        }
    }

    // ── Interactive Notch Popup Card ───────────────────────────────────────
    PopupPanel {
        id: notchPopup
        screen: root.barScreen
        cardWidth: 360
        cardHeight: Math.max(Theme.popupMinHeight, Math.min(Theme.popupMaxHeight, notchContentLayout.implicitHeight + (Theme.popupPadding * 2)))

        property string activeTab: "calendar"
        onOpenChanged: {
            if (open) {
                activeTab = root.currentMode === "timer" ? "timer" : "calendar";
                root.selectedYear = root.todayYear;
                root.selectedMonth = root.todayMonth;
            }
        }

        content: ColumnLayout {
            id: notchContentLayout
            anchors.fill: parent
            spacing: Theme?.widgetSpacing ?? 10

            // Tab Bar: Calendar (Default & First) | Timer (Second)
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Rectangle {
                    Layout.fillWidth: true
                    height: 32
                    radius: Theme?.radiusPill ?? 16
                    color: notchPopup.activeTab === "calendar" ? Theme.primary : Theme.cardBg
                    border.color: notchPopup.activeTab === "calendar" ? Theme.primary : Theme.cardBorder
                    border.width: 1

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 6
                        Text {
                            text: Theme?.iconCalendar ?? "\uE935"
                            font.family: Theme?.fontIcon ?? "sans-serif"
                            font.pixelSize: Theme?.fontSizeSm ?? 12
                            color: notchPopup.activeTab === "calendar" ? Theme.on_primary : Theme.on_surface
                        }
                        Text {
                            text: "calendar"
                            font.family: Theme?.fontSans ?? "sans-serif"
                            font.pixelSize: Theme?.fontSizeSm ?? 12
                            font.weight: Font.DemiBold
                            color: notchPopup.activeTab === "calendar" ? Theme.on_primary : Theme.on_surface
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: notchPopup.activeTab = "calendar"
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 32
                    radius: Theme?.radiusPill ?? 16
                    color: notchPopup.activeTab === "timer" ? Theme.primary : Theme.cardBg
                    border.color: notchPopup.activeTab === "timer" ? Theme.primary : Theme.cardBorder
                    border.width: 1

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 6
                        Text {
                            text: Theme?.iconClock ?? "\uEFD6"
                            font.family: Theme?.fontIcon ?? "sans-serif"
                            font.pixelSize: Theme?.fontSizeSm ?? 12
                            color: notchPopup.activeTab === "timer" ? Theme.on_primary : Theme.on_surface
                        }
                        Text {
                            text: "timer"
                            font.family: Theme?.fontSans ?? "sans-serif"
                            font.pixelSize: Theme?.fontSizeSm ?? 12
                            font.weight: Font.DemiBold
                            color: notchPopup.activeTab === "timer" ? Theme.on_primary : Theme.on_surface
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: notchPopup.activeTab = "timer"
                    }
                }
            }

            // Tab 1: Real Calendar Month Grid View (First & Default)
            ColumnLayout {
                id: calendarSection
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: Theme?.widgetSpacing ?? 10
                visible: notchPopup.activeTab === "calendar"

                // Calendar Header: Current Date & Day of Year
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 64
                    radius: Theme?.widgetRadius ?? Theme?.radiusMd ?? 8
                    color: Theme?.cardBg ?? Theme.surface_container_highest
                    border.color: Theme.widgetBorder
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 12

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            Text {
                                text: {
                                    let dFmt = (Settings?.dateFormat && Settings.dateFormat !== "none" && Settings.dateFormat !== "")
                                        ? Settings.dateFormat
                                        : "dddd, MMMM d, yyyy";
                                    return Qt.formatDateTime(root.currentTime, dFmt).toLowerCase();
                                }
                                font.family: Theme?.fontFamily ?? "sans-serif"
                                font.pixelSize: Theme?.fontSizeSm ?? 12
                                font.weight: Font.Bold
                                color: Theme.on_surface
                            }

                            Text {
                                text: "day " + root.getDayOfYear(root.currentTime) + " of " + root.currentTime.getFullYear() + " • week " + Qt.formatDateTime(root.currentTime, "w")
                                font.family: Theme?.fontFamily ?? "sans-serif"
                                font.pixelSize: 10
                                color: Theme.on_surface_variant
                            }
                        }

                        Text {
                            text: Theme?.iconCalendar ?? "\uE935"
                            font.family: Theme?.fontIcon ?? "sans-serif"
                            font.pixelSize: 20
                            color: Theme.primary
                            Layout.alignment: Qt.AlignRight
                        }
                    }
                }

                // Month Navigation Bar
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Text {
                        id: monthTitle
                        text: {
                            let d = new Date(root.selectedYear, root.selectedMonth, 1);
                            return Qt.formatDate(d, "MMMM yyyy").toLowerCase();
                        }
                        font.family: Theme?.fontFamily ?? "sans-serif"
                        font.pixelSize: Theme?.fontSizeMd ?? 14
                        font.weight: Font.Bold
                        color: Theme.primary
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    IconButton {
                        icon: Theme?.iconChevronLeft ?? "◀"
                        iconSize: Theme?.fontSizeSm ?? 12
                        tooltip: "previous month"
                        onClicked: {
                            if (root.selectedMonth === 0) {
                                root.selectedMonth = 11;
                                root.selectedYear--;
                            } else {
                                root.selectedMonth--;
                            }
                        }
                    }

                    IconButton {
                        icon: Theme?.iconClock ?? "󰅐"
                        iconSize: Theme?.fontSizeSm ?? 12
                        tooltip: "jump to today"
                        onClicked: {
                            root.selectedYear = root.todayYear;
                            root.selectedMonth = root.todayMonth;
                        }
                    }

                    IconButton {
                        icon: Theme?.iconChevronRight ?? "▶"
                        iconSize: Theme?.fontSizeSm ?? 12
                        tooltip: "next month"
                        onClicked: {
                            if (root.selectedMonth === 11) {
                                root.selectedMonth = 0;
                                root.selectedYear++;
                            } else {
                                root.selectedMonth++;
                            }
                        }
                    }

                    IconButton {
                        icon: Theme?.iconClose ?? "✕"
                        iconSize: Theme?.fontSizeSm ?? 12
                        tooltip: "close"
                        onClicked: notchPopup.open = false
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: Theme.widgetBorder
                }

                // Days of Week Headers (mo, tu, we, th, fr, sa, su)
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    Repeater {
                        model: ["mo", "tu", "we", "th", "fr", "sa", "su"]

                        delegate: Item {
                            required property string modelData
                            required property int index
                            Layout.fillWidth: true
                            Layout.preferredWidth: 1
                            Layout.preferredHeight: 22

                            Text {
                                anchors.centerIn: parent
                                text: modelData
                                font.family: Theme?.fontMono ?? "monospace"
                                font.pixelSize: 10
                                font.weight: Font.Bold
                                color: (index >= 5) ? Theme.primary : Theme.on_surface_variant
                            }
                        }
                    }
                }

                // Calendar Days Interactive Month Grid
                GridLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    columns: 7
                    rowSpacing: 4
                    columnSpacing: 4

                    Repeater {
                        model: {
                            let y = root.selectedYear;
                            let m = root.selectedMonth;
                            let firstDay = new Date(y, m, 1).getDay();
                            let offset = (firstDay === 0) ? 6 : firstDay - 1;
                            let daysInMonth = new Date(y, m + 1, 0).getDate();
                            let prevDaysInMonth = new Date(y, m, 0).getDate();
                            let cells = [];

                            for (let i = offset - 1; i >= 0; i--) {
                                cells.push({ day: prevDaysInMonth - i, currentMonth: false, isToday: false });
                            }
                            for (let d = 1; d <= daysInMonth; d++) {
                                let isToday = (y === root.todayYear && m === root.todayMonth && d === root.todayDate);
                                cells.push({ day: d, currentMonth: true, isToday: isToday });
                            }
                            let totalCells = (cells.length > 35) ? 42 : 35;
                            let nextDay = 1;
                            while (cells.length < totalCells) {
                                cells.push({ day: nextDay++, currentMonth: false, isToday: false });
                            }
                            return cells;
                        }

                        delegate: Rectangle {
                            required property var modelData
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            Layout.preferredWidth: 1
                            Layout.preferredHeight: 1
                            radius: Theme?.radiusSm ?? 6
                            color: (modelData.currentMonth && modelData.isToday)
                                ? Theme.primary
                                : (calDayMouse.containsMouse && modelData.day > 0)
                                    ? Theme.surface_container_highest
                                    : "transparent"

                            border.color: (modelData.currentMonth && modelData.isToday) ? Theme.primary : "transparent"
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: modelData.day
                                font.family: Theme?.fontMono ?? "monospace"
                                font.pixelSize: 11
                                font.weight: modelData.isToday ? Font.Bold : Font.Normal
                                color: (modelData.currentMonth && modelData.isToday)
                                    ? (Theme.on_primary ?? "#ffffff")
                                    : (modelData.currentMonth ? Theme.on_surface : Theme.on_surface_disabled)
                            }

                            MouseArea {
                                id: calDayMouse
                                anchors.fill: parent
                                hoverEnabled: true
                            }
                        }
                    }
                }
            }

            // Tab 2: Timer & Stopwatch View
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: notchPopup.activeTab === "timer"
                spacing: 12

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: Theme?.radiusMd ?? 10
                    color: Theme.cardBg
                    border.color: Theme.cardBorder
                    border.width: 1

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 12

                        // Giant Digital Readout
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: {
                                if (typeof TimerService === "undefined" || !TimerService) return "00:00";
                                if (TimerService.stopwatchRunning || TimerService.stopwatchElapsed > 0) {
                                    return TimerService.stopwatchDisplay;
                                }
                                return TimerService.timerDisplay;
                            }
                            font.family: Theme?.fontMono ?? "monospace"
                            font.pixelSize: 42
                            font.weight: Font.Bold
                            color: Theme.primary
                        }

                        // Quick Preset Chips (+1m, +5m, +15m, +25m Pomodoro)
                        RowLayout {
                            Layout.alignment: Qt.AlignHCenter
                            spacing: 6

                            Repeater {
                                model: [
                                    { label: "+1m", val: 1 },
                                    { label: "+5m", val: 5 },
                                    { label: "+15m", val: 15 },
                                    { label: "+25m", val: 25 }
                                ]
                                delegate: Rectangle {
                                    width: 68; height: 28; radius: Theme?.radiusPill ?? 14
                                    color: Theme.surface_container_highest
                                    border.color: Theme.cardBorder
                                    border.width: 1

                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.label
                                        font.family: Theme?.fontMono ?? "sans-serif"
                                        font.pixelSize: Theme?.fontSizeXs ?? 11
                                        font.weight: Font.DemiBold
                                        color: Theme.on_surface
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            if (typeof TimerService !== "undefined" && TimerService) {
                                                TimerService.addTimerMinutes(modelData.val);
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // Start / Pause / Reset Buttons
                        RowLayout {
                            Layout.alignment: Qt.AlignHCenter
                            spacing: 12

                            Rectangle {
                                width: 100; height: 36; radius: 18
                                color: (typeof TimerService !== "undefined" && (TimerService?.timerRunning || TimerService?.stopwatchRunning)) ? Theme.error : Theme.primary

                                RowLayout {
                                    anchors.centerIn: parent
                                    spacing: 6
                                    Text {
                                        text: (typeof TimerService !== "undefined" && (TimerService?.timerRunning || TimerService?.stopwatchRunning)) ? (Theme?.iconPause ?? "\uE034") : (Theme?.iconPlay ?? "\uE037")
                                        font.family: Theme?.fontIcon ?? "sans-serif"
                                        font.pixelSize: Theme?.fontSizeSm ?? 12
                                        color: Theme.on_primary
                                    }
                                    Text {
                                        text: (typeof TimerService !== "undefined" && (TimerService?.timerRunning || TimerService?.stopwatchRunning)) ? "pause" : "start"
                                        font.family: Theme?.fontSans ?? "sans-serif"
                                        font.pixelSize: Theme?.fontSizeSm ?? 12
                                        font.weight: Font.Bold
                                        color: Theme.on_primary
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (typeof TimerService === "undefined" || !TimerService) return;
                                        if (TimerService.stopwatchRunning || TimerService.stopwatchElapsed > 0) {
                                            TimerService.toggleStopwatch();
                                        } else {
                                            TimerService.toggleTimer();
                                        }
                                    }
                                }
                            }

                            Rectangle {
                                width: 90; height: 36; radius: 18
                                color: Theme.surface_container_highest
                                border.color: Theme.cardBorder
                                border.width: 1

                                Text {
                                    anchors.centerIn: parent
                                    text: "reset"
                                    font.family: Theme?.fontSans ?? "sans-serif"
                                    font.pixelSize: Theme?.fontSizeSm ?? 12
                                    font.weight: Font.Medium
                                    color: Theme.on_surface
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (typeof TimerService === "undefined" || !TimerService) return;
                                        TimerService.resetTimer();
                                        TimerService.resetStopwatch();
                                    }
                                }
                            }
                        }

                        // Stopwatch Mode Toggle
                        Rectangle {
                            Layout.alignment: Qt.AlignHCenter
                            width: 160; height: 30; radius: 15
                            color: Theme.surface_container_high

                            Text {
                                anchors.centerIn: parent
                                text: (typeof TimerService !== "undefined" && (TimerService?.stopwatchRunning || TimerService?.stopwatchElapsed > 0)) ? "switch to timer" : "switch to stopwatch"
                                font.family: Theme?.fontSans ?? "sans-serif"
                                font.pixelSize: Theme?.fontSizeXs ?? 11
                                color: Theme.primary
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (typeof TimerService === "undefined" || !TimerService) return;
                                    if (TimerService.stopwatchRunning || TimerService.stopwatchElapsed > 0) {
                                        TimerService.resetStopwatch();
                                    } else {
                                        TimerService.resetTimer();
                                        TimerService.startStopwatch();
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
