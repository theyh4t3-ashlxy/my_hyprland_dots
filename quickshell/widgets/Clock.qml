import QtQuick
import QtQuick.Layouts
import ".."
import "../controls"
import "../corners"

Rectangle {
    id: clockRoot

    // ── Concave Flare & Bezel Attachment ──────────────────────────────────
    readonly property int currentBarHeight: Theme?.barHeight ?? 48
    readonly property bool isBarFloating: Settings?.barFloating ?? false
    readonly property bool isBarBottom: Settings?.barPosition === "bottom"
    readonly property bool isCenterModule: (Settings?.barModulesCenter ?? []).indexOf("clock") !== -1
    readonly property bool hasNotchInCenter: (Settings?.barModulesCenter ?? []).indexOf("dynamicnotch") !== -1
    readonly property bool isFlared: (Settings?.dynamicNotchFlared ?? true) && !(Theme?.isVertical ?? false) && !isBarFloating && isCenterModule && !hasNotchInCenter
    readonly property int flareRadius: Settings?.notchFlareRadius ?? 16

    implicitWidth: (Theme?.isVertical ?? false) ? (currentBarHeight - 8) : (clockRow.implicitWidth + 24)
    implicitHeight: (Theme?.isVertical ?? false) ? 42 : (currentBarHeight - 8)
    width: implicitWidth
    height: isFlared ? currentBarHeight : implicitHeight
    y: isFlared ? (isBarBottom ? Math.round((currentBarHeight - implicitHeight) / 2) : -Math.round((currentBarHeight - implicitHeight) / 2)) : 0

    radius: isFlared ? 0 : (Theme?.radiusPill ?? 999)
    topLeftRadius: isFlared ? (isBarBottom ? Math.max(Theme?.radiusMd ?? 12, 12) : 0) : (Theme?.radiusPill ?? 999)
    topRightRadius: isFlared ? (isBarBottom ? Math.max(Theme?.radiusMd ?? 12, 12) : 0) : (Theme?.radiusPill ?? 999)
    bottomLeftRadius: isFlared ? (!isBarBottom ? Math.max(Theme?.radiusMd ?? 12, 12) : 0) : (Theme?.radiusPill ?? 999)
    bottomRightRadius: isFlared ? (!isBarBottom ? Math.max(Theme?.radiusMd ?? 12, 12) : 0) : (Theme?.radiusPill ?? 999)

    color: calPopup.open
        ? (Theme?.primary_overlay ?? Theme?.primaryOverlay ?? Theme?.surface_container_highest ?? "#3389b4fa")
        : (clkMouse.containsMouse ? (Theme?.pillHover ?? "#33ffffff") : (Theme?.pillBg ?? "#1e1e2e"))
    border.color: Theme?.pillBorder ?? "transparent"
    border.width: (Theme?.pillBorder ?? "transparent") === "transparent" ? 0 : 1
    visible: Settings?.showClock ?? true
    clip: false

    Behavior on color { ColorAnimation { duration: Theme?.animFast ?? 150 } }
    Behavior on border.color { ColorAnimation { duration: Theme?.animFast ?? 150 } }
    Behavior on height { NumberAnimation { duration: Theme?.animNormal ?? 200; easing.type: Theme?.animEasing ?? Easing.OutQuad } }
    Behavior on y { NumberAnimation { duration: Theme?.animNormal ?? 200; easing.type: Theme?.animEasing ?? Easing.OutQuad } }
    Behavior on width { NumberAnimation { duration: Theme?.animFast ?? 150; easing.type: Theme?.animEasing ?? Easing.OutQuad } }

    // ── Concave Flares (Ears) Melting Into Screen Bezel ──────────────────
    ConcaveCorner {
        id: flareLeft
        visible: clockRoot.isFlared
        width: clockRoot.flareRadius
        height: clockRoot.flareRadius
        x: -width
        y: clockRoot.isBarBottom ? (clockRoot.height - height) : 0
        radiusX: clockRoot.flareRadius
        radiusY: clockRoot.flareRadius
        fillColor: clockRoot.color
        cornerStyle: Settings?.cornerStyle ?? "continuous-bezier"
        flipX: true
        flipY: clockRoot.isBarBottom
        showBorder: clockRoot.border.width > 0
        borderWidth: clockRoot.border.width
        borderColor: clockRoot.border.color
    }

    ConcaveCorner {
        id: flareRight
        visible: clockRoot.isFlared
        width: clockRoot.flareRadius
        height: clockRoot.flareRadius
        x: clockRoot.width
        y: clockRoot.isBarBottom ? (clockRoot.height - height) : 0
        radiusX: clockRoot.flareRadius
        radiusY: clockRoot.flareRadius
        fillColor: clockRoot.color
        cornerStyle: Settings?.cornerStyle ?? "continuous-bezier"
        flipX: false
        flipY: clockRoot.isBarBottom
        showBorder: clockRoot.border.width > 0
        borderWidth: clockRoot.border.width
        borderColor: clockRoot.border.color
    }

    property date now: new Date()
    // breaking date parts out prevents the calendar from recreating 42 delegates every tick
    readonly property int todayYear: now.getFullYear()
    readonly property int todayMonth: now.getMonth()
    readonly property int todayDate: now.getDate()

    property int selectedYear: todayYear
    property int selectedMonth: todayMonth // 0-11

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            clockRoot.now = new Date();
        }
    }

    function getDayOfYear(d) {
        let target = d || clockRoot.now;
        let start = new Date(target.getFullYear(), 0, 0);
        let diff = (target - start) + ((start.getTimezoneOffset() - target.getTimezoneOffset()) * 60 * 1000);
        return Math.floor(diff / 86400000);
    }

    function getClockMoodIcon(hrs) {
        if (!Theme) return "";
        if (hrs < 6) {
            return Theme?.iconMoon ?? "󰖔";
        } else if (hrs < 12) {
            return Theme?.iconCoffee ?? "󰅶";
        } else if (hrs < 18) {
            return Theme?.iconSun ?? "󰖙";
        } else {
            return Theme?.iconMusic ?? "󰎈";
        }
    }

    Row {
        id: clockRow
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: (Theme?.isVertical ?? false) ? undefined : parent.left
        anchors.leftMargin: (Theme?.isVertical ?? false) ? 0 : 12
        anchors.horizontalCenter: (Theme?.isVertical ?? false) ? parent.horizontalCenter : undefined
        spacing: 6

        Text {
            id: clockMoodText
            anchors.verticalCenter: parent.verticalCenter
            text: {
                if (Theme?.isVertical ?? false) return "";
                let hrs = clockRoot.now.getHours();
                return clockRoot.getClockMoodIcon(hrs);
            }
            visible: text !== "" && !(Theme?.isVertical ?? false)
            font.family: Theme?.fontIcon ?? "sans-serif"
            font.pixelSize: Theme?.fontSizeSm ?? 12
            color: calPopup.open ? (Theme?.primary ?? "#89b4fa") : (Theme?.on_surface_variant ?? "#a6adc8")
        }

        Text {
            id: timeText
            anchors.verticalCenter: parent.verticalCenter
            horizontalAlignment: Text.AlignHCenter
            lineHeight: (Theme?.isVertical ?? false) ? 0.9 : 1.0
            text: {
                let military = (Settings?.clock24h !== undefined ? Settings.clock24h : (Settings?.clockMilitary ?? true));
                let is12 = (Settings?.clockFormat && /ap/i.test(Settings.clockFormat)) || !military;
                let showSec = Settings?.clockShowSeconds ?? (Settings?.clockFormat && /:ss/i.test(Settings.clockFormat));

                if (Theme?.isVertical ?? false) {
                    if (is12) {
                        let h = clockRoot.now.getHours() % 12;
                        if (h === 0) h = 12;
                        let m = clockRoot.now.getMinutes();
                        let hStr = (h < 10 ? "0" : "") + h;
                        let mStr = (m < 10 ? "0" : "") + m;
                        return hStr + "\n" + mStr;
                    }
                    return Qt.formatDateTime(clockRoot.now, "HH\nmm");
                }

                let timeFmt = Settings?.clockFormat;
                if (!timeFmt || timeFmt.trim() === "") {
                    timeFmt = is12 ? (showSec ? "h:mm:ss ap" : "h:mm ap") : (showSec ? "HH:mm:ss" : "HH:mm");
                }
                let timeStr = Qt.formatDateTime(clockRoot.now, timeFmt).toLowerCase();
                let dateFmt = (Settings?.dateFormat && Settings.dateFormat !== "none") ? Settings.dateFormat : "";
                let showDate = (Settings?.showBarDate ?? false) && dateFmt !== "";
                let dateStr = showDate ? Qt.formatDateTime(clockRoot.now, dateFmt).toLowerCase() : "";
                return (dateStr !== "") ? (dateStr + "  " + timeStr) : timeStr;
            }
            font.family: Theme?.fontFamily ?? "sans-serif"
            font.pixelSize: (Theme?.isVertical ?? false) ? 10 : (Theme?.fontSizeMd ?? 14)
            font.weight: Font.Medium
            color: calPopup.open ? (Theme?.primary ?? "#89b4fa") : (Theme?.on_surface ?? "#cdd6f4")
        }

        Row {
            visible: !(Theme?.isVertical ?? false) && (typeof TimerService !== "undefined" && TimerService) && (TimerService.timerRunning || TimerService.timerPaused || TimerService.stopwatchRunning)
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4

            Text {
                id: timerBullet
                anchors.verticalCenter: parent.verticalCenter
                text: "•"
                font.pixelSize: Theme?.fontSizeSm ?? 12
                color: (typeof TimerService !== "undefined" && TimerService?.timerRunning && TimerService?.timerRemaining <= 30) ? (Theme?.error ?? "#f38ba8") : (Theme?.primary ?? "#89b4fa")
                SequentialAnimation on opacity {
                    loops: Animation.Infinite
                    running: typeof TimerService !== "undefined" && (TimerService?.timerRunning ?? false) && ((TimerService?.timerRemaining ?? 999) <= 30)
                    NumberAnimation { from: 1.0; to: 0.2; duration: 400; easing.type: Easing.InOutQuad }
                    NumberAnimation { from: 0.2; to: 1.0; duration: 400; easing.type: Easing.InOutQuad }
                    onRunningChanged: {
                        if (!running) timerBullet.opacity = 1.0;
                    }
                }
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: {
                    if (typeof TimerService === "undefined" || !TimerService) return "";
                    if (TimerService.stopwatchRunning) return TimerService.stopwatchDisplay;
                    return TimerService.timerDisplay;
                }
                font.family: Theme?.fontMono ?? "monospace"
                font.pixelSize: Theme?.fontSizeSm ?? 11
                font.weight: Font.Bold
                color: (typeof TimerService !== "undefined" && TimerService?.timerRunning && TimerService?.timerRemaining <= 30) ? (Theme?.error ?? "#f38ba8") : (Theme?.primary ?? "#89b4fa")
            }
        }
    }

    function updatePopupPos() {
        let pt = clockRoot.mapToItem(null, 0, 0);
        if (pt) {
            calPopup.targetRelativeX = pt.x + (clockRoot.width / 2);
            calPopup.targetRelativeY = pt.y + (clockRoot.height / 2);
        }
    }

    HoverFlyoutHandler {
        popup: calPopup
        mouseArea: clkMouse
        updatePos: () => clockRoot.updatePopupPos()
    }

    MouseArea {
        id: clkMouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        cursorShape: Qt.PointingHandCursor
        onClicked: (mouse) => {
            if (mouse.button === Qt.LeftButton) {
                clockRoot.updatePopupPos();
                if (!calPopup.open) {
                    calPopup.pinned = true;
                    calPopup.open = true;
                } else if (!calPopup.pinned) {
                    calPopup.pinned = true;
                } else {
                    calPopup.pinned = false;
                    calPopup.open = false;
                }
                if (calPopup.open) {
                    clockRoot.selectedYear = clockRoot.todayYear;
                    clockRoot.selectedMonth = clockRoot.todayMonth;
                }
            } else if (mouse.button === Qt.RightButton) {
                if (Settings) {
                    Settings.showBarDate = !Settings.showBarDate;
                    if (Settings.showBarDate && (!Settings.dateFormat || Settings.dateFormat === "none")) {
                        Settings.dateFormat = "ddd, MMM d";
                    }
                }
            } else if (mouse.button === Qt.MiddleButton) {
                if (Settings) {
                    let curIs12 = (Settings?.clockFormat && /ap/i.test(Settings.clockFormat)) || (Settings?.clockMilitary === false) || (Settings?.clock24h === false);
                    let nextIs12 = !curIs12;
                    let showSec = Settings?.clockShowSeconds ?? (Settings?.clockFormat && /:ss/i.test(Settings.clockFormat));
                    Settings.clockMilitary = !nextIs12;
                    Settings.clock24h = !nextIs12;
                    Settings.clockFormat = nextIs12 ? (showSec ? "h:mm:ss ap" : "h:mm ap") : (showSec ? "HH:mm:ss" : "HH:mm");
                }
            }
        }

        onWheel: (wheel) => {
            if (wheel.angleDelta.y === 0) return;
            if (!Settings) return;
            const formats = ["ddd, MMM d", "MMM d, yyyy", "yyyy-MM-dd", "ddd, d MMM", "MM/dd"];
            let idx = formats.indexOf(Settings.dateFormat);
            if (idx === -1) idx = 0;
            if (wheel.angleDelta.y > 0) {
                idx = (idx + 1) % formats.length;
            } else {
                idx = (idx - 1 + formats.length) % formats.length;
            }
            Settings.dateFormat = formats[idx];
            Settings.showBarDate = true;
        }
    }

    Connections {
        target: Settings
        function onRequestClockToggle() {
            let pos = clockRoot.mapToItem(null, 0, 0);
            if (pos) {
                calPopup.targetRelativeX = pos.x + (clockRoot.width / 2);
                calPopup.targetRelativeY = pos.y + (clockRoot.height / 2);
            }
            calPopup.open = !calPopup.open;
            if (calPopup.open) {
                clockRoot.selectedYear = clockRoot.todayYear;
                clockRoot.selectedMonth = clockRoot.todayMonth;
            }
        }
        function onRequestClockOpen() {
            let pos = clockRoot.mapToItem(null, 0, 0);
            if (pos) {
                calPopup.targetRelativeX = pos.x + (clockRoot.width / 2);
                calPopup.targetRelativeY = pos.y + (clockRoot.height / 2);
            }
            calPopup.open = true;
            clockRoot.selectedYear = clockRoot.todayYear;
            clockRoot.selectedMonth = clockRoot.todayMonth;
        }
        function onRequestClockClose() {
            calPopup.open = false;
        }
    }

    PopupPanel {
        id: calPopup
        cardWidth: 360
        cardHeight: Math.max(Theme?.popupMinHeight ?? 280, Math.min(Theme?.popupMaxHeight ?? 560, calContentLayout.implicitHeight + ((Theme?.popupPadding ?? 12) * 2)))
        targetRelativeX: {
            let pt = clockRoot.mapToItem(null, 0, 0);
            return pt ? (pt.x + (clockRoot.width / 2)) : (clockRoot.x + (clockRoot.width / 2));
        }
        targetRelativeY: {
            let pt = clockRoot.mapToItem(null, 0, 0);
            return pt ? (pt.y + (clockRoot.height / 2)) : (clockRoot.y + (clockRoot.height / 2));
        }
        property string activeTab: "calendar"
        onOpenChanged: {
            if (open) {
                activeTab = "calendar";
            }
        }

        content: ColumnLayout {
            id: calContentLayout
            anchors.fill: parent
            spacing: Theme?.widgetSpacing ?? 10

            // Segmented Header Tab Bar: Calendar (Default & First) | Timer (Second)
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 32
                    implicitHeight: 32
                    radius: Theme?.radiusPill ?? 16
                    color: calPopup.activeTab === "calendar" ? (Theme?.primary ?? "#89b4fa") : (Theme?.cardBg ?? Theme?.surface_container_highest ?? "#1e1e2e")
                    border.color: calPopup.activeTab === "calendar" ? (Theme?.primary ?? "#89b4fa") : (Theme?.cardBorder ?? Theme?.widgetBorder ?? "#313244")
                    border.width: 1

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 6
                        Text {
                            text: Theme?.iconCalendar ?? "\uE935"
                            font.family: Theme?.fontIcon ?? "sans-serif"
                            font.pixelSize: Theme?.fontSizeSm ?? 12
                            color: calPopup.activeTab === "calendar" ? (Theme?.on_primary ?? "#11111b") : (Theme?.on_surface ?? "#cdd6f4")
                        }
                        Text {
                            text: "calendar"
                            font.family: Theme?.fontSans ?? Theme?.fontFamily ?? "sans-serif"
                            font.pixelSize: Theme?.fontSizeSm ?? 12
                            font.weight: Font.DemiBold
                            color: calPopup.activeTab === "calendar" ? (Theme?.on_primary ?? "#11111b") : (Theme?.on_surface ?? "#cdd6f4")
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: calPopup.activeTab = "calendar"
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 32
                    implicitHeight: 32
                    radius: Theme?.radiusPill ?? 16
                    color: calPopup.activeTab === "timer" ? (Theme?.primary ?? "#89b4fa") : (Theme?.cardBg ?? Theme?.surface_container_highest ?? "#1e1e2e")
                    border.color: calPopup.activeTab === "timer" ? (Theme?.primary ?? "#89b4fa") : (Theme?.cardBorder ?? Theme?.widgetBorder ?? "#313244")
                    border.width: 1

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 6
                        Text {
                            text: Theme?.iconClock ?? "\uEFD6"
                            font.family: Theme?.fontIcon ?? "sans-serif"
                            font.pixelSize: Theme?.fontSizeSm ?? 12
                            color: calPopup.activeTab === "timer" ? (Theme?.on_primary ?? "#11111b") : (Theme?.on_surface ?? "#cdd6f4")
                        }
                        Text {
                            text: "timer"
                            font.family: Theme?.fontSans ?? Theme?.fontFamily ?? "sans-serif"
                            font.pixelSize: Theme?.fontSizeSm ?? 12
                            font.weight: Font.DemiBold
                            color: calPopup.activeTab === "timer" ? (Theme?.on_primary ?? "#11111b") : (Theme?.on_surface ?? "#cdd6f4")
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: calPopup.activeTab = "timer"
                    }
                }
            }

            // Calendar View (First)
            ColumnLayout {
                id: calendarSection
                Layout.fillWidth: true
                spacing: Theme?.widgetSpacing ?? 10
                visible: calPopup.activeTab === "calendar"

                // Calendar Header: Current Date & Time
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 64
                    implicitHeight: 64
                    radius: Theme?.widgetRadius ?? Theme?.radiusMd ?? 8
                    color: Theme?.cardBg ?? Theme?.surface_container_highest ?? "#1e1e2e"
                    border.color: Theme?.widgetBorder ?? Theme?.cardBorder ?? "#313244"
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
                                    return Qt.formatDateTime(clockRoot.now, dFmt).toLowerCase();
                                }
                                font.family: Theme?.fontFamily ?? "sans-serif"
                                font.pixelSize: Theme?.fontSizeSm ?? 12
                                font.weight: Font.Bold
                                color: Theme?.on_surface ?? "#cdd6f4"
                            }

                            Text {
                                text: "day " + clockRoot.getDayOfYear(clockRoot.now) + " of " + clockRoot.now.getFullYear()
                                font.family: Theme?.fontFamily ?? "sans-serif"
                                font.pixelSize: 10
                                color: Theme?.on_surface_variant ?? "#a6adc8"
                            }
                        }

                        ColumnLayout {
                            spacing: 2
                            Layout.alignment: Qt.AlignRight

                            Text {
                                text: {
                                    let is12 = (Settings?.clockFormat && /ap/i.test(Settings.clockFormat)) || (Settings?.clockMilitary === false) || (Settings?.clock24h === false);
                                    return Qt.formatDateTime(clockRoot.now, is12 ? "h:mm:ss ap" : "HH:mm:ss").toLowerCase();
                                }
                                font.family: Theme?.fontMono ?? "monospace"
                                font.pixelSize: Theme?.fontSizeLg ?? 16
                                font.weight: Font.Bold
                                color: Theme?.primary ?? "#89b4fa"
                                Layout.alignment: Qt.AlignRight
                            }

                            Text {
                                text: Theme?.iconClock ?? "\uE8B5"
                                font.family: Theme?.fontIcon ?? "sans-serif"
                                font.pixelSize: 11
                                color: Theme?.primary ?? "#89b4fa"
                                Layout.alignment: Qt.AlignRight
                            }
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
                            let d = new Date(clockRoot.selectedYear, clockRoot.selectedMonth, 1);
                            return Qt.formatDate(d, "MMMM yyyy").toLowerCase();
                        }
                        font.family: Theme?.fontFamily ?? "sans-serif"
                        font.pixelSize: Theme?.fontSizeMd ?? 14
                        font.weight: Font.Bold
                        color: Theme?.primary ?? "#89b4fa"
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    IconButton {
                        icon: Theme?.iconChevronLeft ?? "◀"
                        iconSize: Theme?.fontSizeSm ?? 12
                        tooltip: "previous month"
                        onClicked: {
                            if (clockRoot.selectedMonth === 0) {
                                clockRoot.selectedMonth = 11;
                                clockRoot.selectedYear--;
                            } else {
                                clockRoot.selectedMonth--;
                            }
                        }
                    }

                    IconButton {
                        icon: Theme?.iconClock ?? "󰅐"
                        iconSize: Theme?.fontSizeSm ?? 12
                        tooltip: "jump to today"
                        onClicked: {
                            clockRoot.selectedYear = clockRoot.todayYear;
                            clockRoot.selectedMonth = clockRoot.todayMonth;
                        }
                    }

                    IconButton {
                        icon: Theme?.iconChevronRight ?? "▶"
                        iconSize: Theme?.fontSizeSm ?? 12
                        tooltip: "next month"
                        onClicked: {
                            if (clockRoot.selectedMonth === 11) {
                                clockRoot.selectedMonth = 0;
                                clockRoot.selectedYear++;
                            } else {
                                clockRoot.selectedMonth++;
                            }
                        }
                    }

                    IconButton {
                        icon: Theme?.iconClose ?? "✕"
                        iconSize: Theme?.fontSizeSm ?? 12
                        tooltip: "close calendar"
                        onClicked: calPopup.open = false
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    implicitHeight: 1
                    color: Theme?.widgetBorder ?? Theme?.cardBorder ?? "#313244"
                }

                // Days of Week Headers (Mo, Tu, We, Th, Fr, Sa, Su)
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
                            implicitHeight: 22

                            Text {
                                anchors.centerIn: parent
                                text: modelData
                                font.family: Theme?.fontMono ?? "monospace"
                                font.pixelSize: 10
                                font.weight: Font.Bold
                                color: (index >= 5) ? (Theme?.primary ?? "#89b4fa") : (Theme?.on_surface_variant ?? "#a6adc8")
                            }
                        }
                    }
                }

                // Calendar Days Grid
                GridLayout {
                    Layout.fillWidth: true
                    columns: 7
                    rowSpacing: 4
                    columnSpacing: 4

                    Repeater {
                        model: {
                            let y = clockRoot.selectedYear;
                            let m = clockRoot.selectedMonth;
                            let firstDay = new Date(y, m, 1).getDay();
                            let offset = (firstDay === 0) ? 6 : firstDay - 1;
                            let daysInMonth = new Date(y, m + 1, 0).getDate();
                            let prevDaysInMonth = new Date(y, m, 0).getDate();
                            let cells = [];

                            for (let i = offset - 1; i >= 0; i--) {
                                cells.push({ day: prevDaysInMonth - i, currentMonth: false, isToday: false });
                            }
                            for (let d = 1; d <= daysInMonth; d++) {
                                let isToday = (y === clockRoot.todayYear && m === clockRoot.todayMonth && d === clockRoot.todayDate);
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
                            Layout.preferredWidth: 1
                            Layout.preferredHeight: 32
                            implicitHeight: 32
                            radius: Theme?.radiusSm ?? 6
                            color: (modelData.currentMonth && modelData.isToday)
                                ? (Theme?.primary ?? "#89b4fa")
                                : (dayMouse.containsMouse
                                    ? (Theme?.surface_container_highest ?? "#313244")
                                    : "transparent")

                            border.color: (modelData.currentMonth && modelData.isToday) ? (Theme?.primary ?? "#89b4fa") : "transparent"
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: modelData.day
                                font.family: Theme?.fontMono ?? "monospace"
                                font.pixelSize: 11
                                font.weight: modelData.isToday ? Font.Bold : Font.Normal
                                color: (modelData.currentMonth && modelData.isToday)
                                    ? (Theme?.on_primary ?? "#11111b")
                                    : (modelData.currentMonth
                                        ? (Theme?.on_surface ?? "#cdd6f4")
                                        : (Theme?.on_surface_disabled ?? Qt.alpha(Theme?.on_surface ?? "#cdd6f4", 0.35)))
                            }

                            MouseArea {
                                id: dayMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (!modelData.currentMonth) {
                                        if (modelData.day > 15) {
                                            if (clockRoot.selectedMonth === 0) {
                                                clockRoot.selectedMonth = 11;
                                                clockRoot.selectedYear--;
                                            } else {
                                                clockRoot.selectedMonth--;
                                            }
                                        } else {
                                            if (clockRoot.selectedMonth === 11) {
                                                clockRoot.selectedMonth = 0;
                                                clockRoot.selectedYear++;
                                            } else {
                                                clockRoot.selectedMonth++;
                                            }
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
                    implicitHeight: 1
                    color: Theme?.widgetBorder ?? Theme?.cardBorder ?? "#313244"
                }

                // Footer: Day progress
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 6
                        implicitHeight: 6
                        radius: 3
                        color: Theme?.surface_container_highest ?? "#313244"
                        clip: true

                        Rectangle {
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: parent.width * Math.min(1.0, Math.max(0.0, ((clockRoot.now.getHours() * 60 + clockRoot.now.getMinutes()) / 1440)))
                            radius: 3
                            color: Theme?.primary ?? "#89b4fa"
                        }
                    }

                    Text {
                        text: Math.round(((clockRoot.now.getHours() * 60 + clockRoot.now.getMinutes()) / 1440) * 100) + "% day elapsed"
                        font.family: Theme?.fontMono ?? "monospace"
                        font.pixelSize: 9
                        color: Theme?.on_surface_variant ?? "#a6adc8"
                    }
                }
            }

            // Timer & Stopwatch View (Second)
            ColumnLayout {
                id: timerSection
                Layout.fillWidth: true
                spacing: 14
                visible: calPopup.activeTab === "timer"

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: timerInnerLayout.implicitHeight + 32
                    implicitHeight: timerInnerLayout.implicitHeight + 32
                    radius: Theme?.radiusMd ?? 10
                    color: Theme?.cardBg ?? Theme?.surface_container_highest ?? "#1e1e2e"
                    border.color: Theme?.cardBorder ?? Theme?.widgetBorder ?? "#313244"
                    border.width: 1

                    ColumnLayout {
                        id: timerInnerLayout
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 16

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
                            font.pixelSize: 46
                            font.weight: Font.Bold
                            color: (typeof TimerService !== "undefined" && TimerService?.timerRunning && TimerService.timerRemaining <= 30) ? (Theme?.error ?? "#f38ba8") : (Theme?.primary ?? "#89b4fa")
                        }

                        // Quick Preset Chips (+1m, +5m, +15m, +25m Pomodoro)
                        RowLayout {
                            Layout.alignment: Qt.AlignHCenter
                            spacing: 8

                            Repeater {
                                model: [
                                    { label: "+1m", val: 1 },
                                    { label: "+5m", val: 5 },
                                    { label: "+15m", val: 15 },
                                    { label: "+25m", val: 25 }
                                ]
                                delegate: Rectangle {
                                    Layout.preferredWidth: 68
                                    Layout.preferredHeight: 32
                                    implicitWidth: 68
                                    implicitHeight: 32
                                    radius: Theme?.radiusPill ?? 16
                                    color: Theme?.surface_container_highest ?? "#313244"
                                    border.color: Theme?.cardBorder ?? Theme?.widgetBorder ?? "#45475a"
                                    border.width: 1

                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.label
                                        font.family: Theme?.fontMono ?? "monospace"
                                        font.pixelSize: Theme?.fontSizeSm ?? 12
                                        font.weight: Font.DemiBold
                                        color: Theme?.on_surface ?? "#cdd6f4"
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

                        // Start / Pause / Reset Controls
                        RowLayout {
                            Layout.alignment: Qt.AlignHCenter
                            spacing: 14

                            Rectangle {
                                Layout.preferredWidth: 110
                                Layout.preferredHeight: 40
                                implicitWidth: 110
                                implicitHeight: 40
                                radius: 20
                                color: (typeof TimerService !== "undefined" && (TimerService?.timerRunning || TimerService?.stopwatchRunning)) ? (Theme?.error ?? "#f38ba8") : (Theme?.primary ?? "#89b4fa")

                                RowLayout {
                                    anchors.centerIn: parent
                                    spacing: 6
                                    Text {
                                        text: (typeof TimerService !== "undefined" && (TimerService?.timerRunning || TimerService?.stopwatchRunning)) ? (Theme?.iconPause ?? "\uE034") : (Theme?.iconPlay ?? "\uE037")
                                        font.family: Theme?.fontIcon ?? "sans-serif"
                                        font.pixelSize: Theme?.fontSizeSm ?? 12
                                        color: Theme?.on_primary ?? "#11111b"
                                    }
                                    Text {
                                        text: (typeof TimerService !== "undefined" && (TimerService?.timerRunning || TimerService?.stopwatchRunning)) ? "pause" : "start"
                                        font.family: Theme?.fontSans ?? Theme?.fontFamily ?? "sans-serif"
                                        font.pixelSize: Theme?.fontSizeSm ?? 12
                                        font.weight: Font.Bold
                                        color: Theme?.on_primary ?? "#11111b"
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
                                Layout.preferredWidth: 96
                                Layout.preferredHeight: 40
                                implicitWidth: 96
                                implicitHeight: 40
                                radius: 20
                                color: Theme?.surface_container_highest ?? "#313244"
                                border.color: Theme?.cardBorder ?? Theme?.widgetBorder ?? "#45475a"
                                border.width: 1

                                Text {
                                    anchors.centerIn: parent
                                    text: "reset"
                                    font.family: Theme?.fontSans ?? Theme?.fontFamily ?? "sans-serif"
                                    font.pixelSize: Theme?.fontSizeSm ?? 12
                                    font.weight: Font.Medium
                                    color: Theme?.on_surface ?? "#cdd6f4"
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

                        // Mode Switcher: Timer vs Stopwatch
                        Rectangle {
                            Layout.alignment: Qt.AlignHCenter
                            Layout.preferredWidth: 180
                            Layout.preferredHeight: 32
                            implicitWidth: 180
                            implicitHeight: 32
                            radius: 16
                            color: Theme?.surface_container_high ?? "#262837"

                            Text {
                                anchors.centerIn: parent
                                text: (typeof TimerService !== "undefined" && (TimerService?.stopwatchRunning || TimerService?.stopwatchElapsed > 0)) ? "switch to timer" : "switch to stopwatch"
                                font.family: Theme?.fontSans ?? Theme?.fontFamily ?? "sans-serif"
                                font.pixelSize: Theme?.fontSizeXs ?? 11
                                color: Theme?.primary ?? "#89b4fa"
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
