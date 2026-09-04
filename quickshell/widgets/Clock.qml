import QtQuick
import QtQuick.Layouts
import ".."
import "../controls"

Rectangle {
    id: clockRoot
    implicitWidth: Theme.isVertical ? Theme.barHeight - 8 : timeText.implicitWidth + 24
    implicitHeight: Theme.isVertical ? 38 : Theme.barHeight - 8
    radius: Theme.radiusPill
    color: calPopup.open ? Theme.primary_overlay : (clkMouse.containsMouse ? Theme.pillHover : Theme.pillBg)
    border.color: Theme.pillBorder
    border.width: Theme.pillBorder === "transparent" ? 0 : 1

    Behavior on color { ColorAnimation { duration: Theme.animFast } }
    Behavior on border.color { ColorAnimation { duration: Theme.animFast } }

    property date now: new Date()
    property int selectedYear: now.getFullYear()
    property int selectedMonth: now.getMonth() // 0-11

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            clockRoot.now = new Date()
        }
    }

    function getDayOfYear(d) {
        let start = new Date(d.getFullYear(), 0, 0);
        let diff = (d - start) + ((start.getTimezoneOffset() - d.getTimezoneOffset()) * 60 * 1000);
        return Math.floor(diff / 86400000);
    }

    Text {
        id: timeText
        anchors.centerIn: parent
        horizontalAlignment: Text.AlignHCenter
        lineHeight: 0.9
        text: {
            if (Theme.isVertical) {
                return Qt.formatDateTime(clockRoot.now, "HH\nmm");
            }
            let hrs = clockRoot.now.getHours();
            let mood = (hrs < 6) ? Theme.getVibe(Theme.kaoSleepy, "󰤄", "")
                     : (hrs < 12) ? Theme.getVibe(Theme.kaoCoffee, "󰖨", "")
                     : (hrs < 18) ? Theme.getVibe(Theme.kaoCool, "󰖙", "")
                     : Theme.getVibe(Theme.kaoMusic, "󰖔", "");
            let timeStr = Qt.formatDateTime(clockRoot.now, Settings.clockFormat);
            let dateFmt = (Settings.dateFormat && Settings.dateFormat !== "none") ? Settings.dateFormat : "";
            let showDate = (Settings.showBarDate ?? false) && dateFmt !== "";
            let dateStr = showDate ? Qt.formatDateTime(clockRoot.now, dateFmt) : "";
            let combo = (dateStr !== "") ? (dateStr + "  " + timeStr) : timeStr;
            return mood !== "" ? (mood + " " + combo) : combo;
        }
        font.family: Theme.fontFamily
        font.pixelSize: Theme.isVertical ? 10 : Theme.fontSizeMd
        font.weight: Font.Medium
        color: calPopup.open ? Theme.primary : Theme.on_surface
    }

    MouseArea {
        id: clkMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            calPopup.targetRelativeX = clockRoot.mapToItem(null, 0, 0).x + (clockRoot.width / 2)
            calPopup.targetRelativeY = clockRoot.mapToItem(null, 0, 0).y + (clockRoot.height / 2)
            calPopup.open = !calPopup.open
            if (calPopup.open) {
                clockRoot.selectedYear = clockRoot.now.getFullYear()
                clockRoot.selectedMonth = clockRoot.now.getMonth()
            }
        }
    }

    // Welded Calendar & Date Overview Popup
    PopupPanel {
        id: calPopup
        cardWidth: 360
        cardHeight: 480

        content: ColumnLayout {
            anchors.fill: parent
            spacing: Theme.widgetSpacing

            // Calendar Header: Current Date & Time
            Rectangle {
                Layout.fillWidth: true
                height: 64
                radius: Theme.widgetRadius
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
                            text: Qt.formatDateTime(clockRoot.now, (Settings.dateFormat && Settings.dateFormat !== "") ? Settings.dateFormat : "dddd, MMMM d, yyyy")
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeSm
                            font.weight: Font.Bold
                            color: Theme.on_surface
                        }

                        Text {
                            text: "day " + clockRoot.getDayOfYear(clockRoot.now) + " of " + clockRoot.now.getFullYear()
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                            color: Theme.on_surface_variant
                        }
                    }

                    ColumnLayout {
                        spacing: 2
                        Layout.alignment: Qt.AlignRight

                        Text {
                            text: Qt.formatDateTime(clockRoot.now, "HH:mm:ss")
                            font.family: Theme.fontMono
                            font.pixelSize: Theme.fontSizeLg
                            font.weight: Font.Bold
                            color: Theme.primary
                            Layout.alignment: Qt.AlignRight
                        }

                        Text {
                            text: Theme.iconClock
                            font.family: Theme.fontIcon
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
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeMd
                    font.weight: Font.Bold
                    color: Theme.primary
                    Layout.fillWidth: true
                }

                IconButton {
                    icon: Theme.iconChevronLeft
                    iconSize: Theme.fontSizeSm
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
                    icon: Theme.iconClock
                    iconSize: Theme.fontSizeSm
                    tooltip: "jump to today"
                    onClicked: {
                        clockRoot.selectedYear = clockRoot.now.getFullYear();
                        clockRoot.selectedMonth = clockRoot.now.getMonth();
                    }
                }

                IconButton {
                    icon: Theme.iconChevronRight
                    iconSize: Theme.fontSizeSm
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
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
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
                        height: 22

                        Text {
                            anchors.centerIn: parent
                            text: modelData
                            font.family: Theme.fontMono
                            font.pixelSize: 10
                            font.weight: Font.Bold
                            color: (index >= 5) ? Theme.primary : Theme.on_surface_variant
                        }
                    }
                }
            }

            // Calendar Days Grid (5 or 6 rows x 7 columns)
            GridLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
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
                            let isToday = (y === clockRoot.now.getFullYear() && m === clockRoot.now.getMonth() && d === clockRoot.now.getDate());
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
                        radius: Theme.radiusSm
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
                            font.family: Theme.fontMono
                            font.pixelSize: 11
                            font.weight: modelData.isToday ? Font.Bold : Font.Normal
                            color: (modelData.currentMonth && modelData.isToday)
                                ? Theme.on_primary
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
                                        // clicked day in previous month
                                        if (clockRoot.selectedMonth === 0) {
                                            clockRoot.selectedMonth = 11;
                                            clockRoot.selectedYear--;
                                        } else {
                                            clockRoot.selectedMonth--;
                                        }
                                    } else {
                                        // clicked day in next month
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
                height: 1
                color: Theme.widgetBorder
            }

            // Footer: Day progress & quick quote
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Rectangle {
                    Layout.fillWidth: true
                    height: 6
                    radius: 3
                    color: Theme.surface_container_highest

                    Rectangle {
                        height: parent.height
                        width: parent.width * Math.min(1.0, ((clockRoot.now.getHours() * 60 + clockRoot.now.getMinutes()) / 1440))
                        radius: 3
                        color: Theme.primary
                    }
                }

                Text {
                    text: Math.round(((clockRoot.now.getHours() * 60 + clockRoot.now.getMinutes()) / 1440) * 100) + "% day elapsed"
                    font.family: Theme.fontMono
                    font.pixelSize: 9
                    color: Theme.on_surface_variant
                }
            }
        }
    }
}
