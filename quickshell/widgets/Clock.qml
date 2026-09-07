import QtQuick
import QtQuick.Layouts
import ".."
import "../controls"

Rectangle {
    id: clockRoot
    implicitWidth: (Theme?.isVertical ?? false) ? ((Theme?.barHeight ?? 48) - 8) : (clockRow.implicitWidth + 24)
    implicitHeight: (Theme?.isVertical ?? false) ? 42 : ((Theme?.barHeight ?? 48) - 8)
    radius: Theme?.radiusPill ?? 999
    color: calPopup.open ? Theme.primary_overlay : (clkMouse.containsMouse ? Theme.pillHover : Theme.pillBg)
    border.color: Theme?.pillBorder ?? "transparent"
    border.width: (Theme?.pillBorder ?? "transparent") === "transparent" ? 0 : 1
    visible: Settings?.showClock ?? true

    Behavior on color { ColorAnimation { duration: Theme?.animFast ?? 150 } }
    Behavior on border.color { ColorAnimation { duration: Theme?.animFast ?? 150 } }
    Behavior on implicitWidth { NumberAnimation { duration: Theme?.animFast ?? 150; easing.type: Theme?.animEasing ?? Easing.OutQuad } }

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
        if (!Theme?.getIcon) return Theme?.iconClock ?? "\uEFD6";
        if (hrs < 6) {
            return Theme.getIcon("\uF159", "\uE708", "", "moon", Theme?.kaoSleepy ?? "(u_u)", "night");
        } else if (hrs < 12) {
            return Theme.getIcon("\uEFEF", "\uE706", "", "coffee", Theme?.kaoCoffee ?? "[_]~", "morn");
        } else if (hrs < 18) {
            return Theme.getIcon("\uE518", "\uE706", "", "sun", Theme?.kaoCool ?? "(^o^)", "day");
        } else {
            return Theme.getIcon("\uE405", "\uE708", "", "music", Theme?.kaoMusic ?? "♫", "eve");
        }
    }

    Row {
        id: clockRow
        anchors.centerIn: parent
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
            color: calPopup.open ? Theme.primary : Theme.on_surface_variant
        }

        Text {
            id: timeText
            anchors.verticalCenter: parent.verticalCenter
            horizontalAlignment: Text.AlignHCenter
            lineHeight: 0.9
            text: {
                if (Theme?.isVertical ?? false) {
                    return Qt.formatDateTime(clockRoot.now, "HH\nmm");
                }
                let timeFmt = Settings?.clockFormat || "HH:mm";
                let timeStr = Qt.formatDateTime(clockRoot.now, timeFmt);
                let dateFmt = (Settings?.dateFormat && Settings.dateFormat !== "none") ? Settings.dateFormat : "";
                let showDate = (Settings?.showBarDate ?? false) && dateFmt !== "";
                let dateStr = showDate ? Qt.formatDateTime(clockRoot.now, dateFmt) : "";
                return (dateStr !== "") ? (dateStr + "  " + timeStr) : timeStr;
            }
            font.family: Theme?.fontFamily ?? "sans-serif"
            font.pixelSize: (Theme?.isVertical ?? false) ? 10 : (Theme?.fontSizeMd ?? 14)
            font.weight: Font.Medium
            color: calPopup.open ? Theme.primary : Theme.on_surface
        }
    }

    MouseArea {
        id: clkMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            let pt = clockRoot.mapToItem(null, 0, 0);
            if (pt) {
                if (Theme?.isVertical ?? false) {
                    calPopup.targetRelativeY = pt.y + (clockRoot.height / 2);
                } else {
                    calPopup.targetRelativeX = pt.x + (clockRoot.width / 2);
                }
            }
            calPopup.open = !calPopup.open;
            if (calPopup.open) {
                clockRoot.selectedYear = clockRoot.todayYear;
                clockRoot.selectedMonth = clockRoot.todayMonth;
            }
        }
    }

    PopupPanel {
        id: calPopup
        cardWidth: 360
        cardHeight: 480
        targetRelativeX: clockRoot.x + (clockRoot.width / 2)

        content: ColumnLayout {
            anchors.fill: parent
            spacing: Theme?.widgetSpacing ?? 10

            // Calendar Header: Current Date & Time
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 64
                radius: Theme?.widgetRadius ?? Theme?.radiusMd ?? 8
                color: Theme.surface_container_highest
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
                                return Qt.formatDateTime(clockRoot.now, dFmt);
                            }
                            font.family: Theme?.fontFamily ?? "sans-serif"
                            font.pixelSize: Theme?.fontSizeSm ?? 12
                            font.weight: Font.Bold
                            color: Theme.on_surface
                        }

                        Text {
                            text: "day " + clockRoot.getDayOfYear(clockRoot.now) + " of " + clockRoot.now.getFullYear()
                            font.family: Theme?.fontFamily ?? "sans-serif"
                            font.pixelSize: 10
                            color: Theme.on_surface_variant
                        }
                    }

                    ColumnLayout {
                        spacing: 2
                        Layout.alignment: Qt.AlignRight

                        Text {
                            text: Qt.formatDateTime(clockRoot.now, "HH:mm:ss")
                            font.family: Theme?.fontMono ?? "monospace"
                            font.pixelSize: Theme?.fontSizeLg ?? 16
                            font.weight: Font.Bold
                            color: Theme.primary
                            Layout.alignment: Qt.AlignRight
                        }

                        Text {
                            text: Theme?.iconClock ?? "󰅐"
                            font.family: Theme?.fontIcon ?? "sans-serif"
                            font.pixelSize: 11
                            color: Theme.primary
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
                        return Qt.formatDate(d, "MMMM yyyy");
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
                color: Theme.widgetBorder
            }

            // Days of Week Headers (Mo, Tu, We, Th, Fr, Sa, Su)
            RowLayout {
                Layout.fillWidth: true
                spacing: 4

                Repeater {
                    model: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]

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

            // Calendar Days Grid
            GridLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                columns: 7
                rowSpacing: 4
                columnSpacing: 4

                Repeater {
                    // relies on cached day/month/year properties so ticks dont force full grid rebuilds
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
                        Layout.fillHeight: true
                        Layout.preferredWidth: 1
                        Layout.preferredHeight: 1
                        radius: Theme?.radiusSm ?? 6
                        color: (modelData.currentMonth && modelData.isToday)
                            ? Theme.primary
                            : (dayMouse.containsMouse && modelData.day > 0)
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
                            id: dayMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: modelData.currentMonth ? Qt.ArrowCursor : Qt.PointingHandCursor
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
                color: Theme.widgetBorder
            }

            // Footer: Day progress
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 6
                    radius: 3
                    color: Theme.surface_container_highest

                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: parent.width * Math.min(1.0, Math.max(0.0, ((clockRoot.now.getHours() * 60 + clockRoot.now.getMinutes()) / 1440)))
                        radius: 3
                        color: Theme.primary
                    }
                }

                Text {
                    text: Math.round(((clockRoot.now.getHours() * 60 + clockRoot.now.getMinutes()) / 1440) * 100) + "% day elapsed"
                    font.family: Theme?.fontMono ?? "monospace"
                    font.pixelSize: 9
                    color: Theme.on_surface_variant
                }
            }
        }
    }
}