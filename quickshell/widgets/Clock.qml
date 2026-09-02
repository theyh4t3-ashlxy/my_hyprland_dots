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

    Text {
        id: timeText
        anchors.centerIn: parent
        horizontalAlignment: Text.AlignHCenter
        lineHeight: 0.9
        text: {
            if (Theme.isVertical) {
                return Qt.formatDateTime(clockRoot.now, "HH\nmm");
            }
            if (Settings.unhingedFlavor) {
                let hrs = clockRoot.now.getHours();
                let mood = (hrs < 6) ? "󰤄" : (hrs < 12) ? "󰖨" : (hrs < 18) ? "󰖙" : "󰖔";
                return mood + " " + Qt.formatDateTime(clockRoot.now, Settings.clockFormat);
            }
            return Qt.formatDateTime(clockRoot.now, Settings.clockFormat);
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
                clockRoot.selectedYear = clockRoot.now.getFullYear();
                clockRoot.selectedMonth = clockRoot.now.getMonth();
            }
        }
    }

    // Welded Calendar & Date Overview Popup
    PopupPanel {
        id: calPopup
        cardWidth: 420
        cardHeight: 460

        content: ColumnLayout {
            anchors.fill: parent
            spacing: Theme.popupSpacing

            // Header with full date, digital time with live seconds & kaomoji
            Rectangle {
                Layout.fillWidth: true
                height: 70
                radius: Theme.radiusMd
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
                            text: Qt.formatDateTime(clockRoot.now, "dddd, MMMM d, yyyy")
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeSm
                            font.weight: Font.Bold
                            color: Theme.on_surface
                        }

                        Text {
                            text: "day " + Qt.formatDateTime(clockRoot.now, "DDD") + " of " + clockRoot.now.getFullYear()
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
                    icon: ""
                    iconSize: Theme.fontSizeXs
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
                    icon: ""
                    iconSize: Theme.fontSizeXs
                    tooltip: "jump to today"
                    onClicked: {
                        clockRoot.selectedYear = clockRoot.now.getFullYear();
                        clockRoot.selectedMonth = clockRoot.now.getMonth();
                    }
                }

                IconButton {
                    icon: ""
                    iconSize: Theme.fontSizeXs
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

            // Calendar Days Grid (6 rows x 7 columns)
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
                        let firstDay = new Date(y, m, 1).getDay(); // 0 = Sun, 1 = Mon
                        let offset = (firstDay === 0) ? 6 : firstDay - 1; // standard Monday-first
                        let daysInMonth = new Date(y, m + 1, 0).getDate();
                        let cells = [];
                        for (let i = 0; i < offset; i++) {
                            cells.push({ day: 0, currentMonth: false });
                        }
                        for (let d = 1; d <= daysInMonth; d++) {
                            let isToday = (y === clockRoot.now.getFullYear() && m === clockRoot.now.getMonth() && d === clockRoot.now.getDate());
                            cells.push({ day: d, currentMonth: true, isToday: isToday });
                        }
                        while (cells.length < 35) {
                            cells.push({ day: 0, currentMonth: false });
                        }
                        return cells;
                    }

                    delegate: Rectangle {
                        required property var modelData
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: Theme.radiusSm
                        color: (modelData.day > 0 && modelData.isToday)
                            ? Theme.primary
                            : (modelData.day > 0 && dayMouse.containsMouse)
                                ? Theme.surface_container_highest
                                : "transparent"

                        border.color: (modelData.day > 0 && modelData.isToday) ? Theme.primary : "transparent"
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: modelData.day > 0 ? modelData.day : ""
                            font.family: Theme.fontMono
                            font.pixelSize: 11
                            font.weight: modelData.isToday ? Font.Bold : Font.Normal
                            color: modelData.isToday
                                ? Theme.on_primary
                                : (modelData.currentMonth ? Theme.on_surface : Theme.on_surface_variant)
                        }

                        MouseArea {
                            id: dayMouse
                            anchors.fill: parent
                            enabled: modelData.day > 0
                            hoverEnabled: true
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
