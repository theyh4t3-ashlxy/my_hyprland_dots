import QtQuick
import ".."

Rectangle {
    id: clockRoot
    implicitWidth: Theme.isVertical ? Theme.barHeight - 8 : timeText.implicitWidth + 24
    implicitHeight: Theme.isVertical ? 38 : Theme.barHeight - 8
    radius: Theme.radiusPill
    color: clkMouse.containsMouse ? Theme.surface_container_highest : Theme.surface_container_high

    Behavior on color { ColorAnimation { duration: Theme.animFast } }

    property int viewMode: 0 // 0: clock, 1: date, 2: kaomoji vibe
    // epoch time is a social construct
    property date now: new Date()

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: now = new Date()
    }

    Text {
        id: timeText
        anchors.centerIn: parent
        horizontalAlignment: Text.AlignHCenter
        lineHeight: 0.9
        text: {
            if (Theme.isVertical) {
                if (clockRoot.viewMode === 1) return Qt.formatDateTime(now, "dd\nMMM");
                if (clockRoot.viewMode === 2) {
                    let hrs = now.getHours();
                    return (hrs < 6) ? "zzz" : (hrs < 12) ? "am" : (hrs < 18) ? "pm" : "eve";
                }
                return Qt.formatDateTime(now, "HH\nmm");
            }
            if (clockRoot.viewMode === 1) return Qt.formatDateTime(now, Settings.dateFormat);
            if (clockRoot.viewMode === 2) {
                let hrs = now.getHours();
                let mood = (hrs < 6) ? Theme.kaoSleepy : (hrs < 12) ? Theme.kaoCoffee : (hrs < 18) ? Theme.kaoCool : Theme.kaoMusic;
                return mood + " " + Qt.formatDateTime(now, Settings.clockFormat);
            }
            return Qt.formatDateTime(now, Settings.clockFormat);
        }
        font.family: Theme.fontFamily
        font.pixelSize: Theme.isVertical ? 10 : Theme.fontSizeMd
        font.weight: Font.Medium
        color: Theme.on_surface
    }

    MouseArea {
        id: clkMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: clockRoot.viewMode = (clockRoot.viewMode + 1) % 3
    }
}
