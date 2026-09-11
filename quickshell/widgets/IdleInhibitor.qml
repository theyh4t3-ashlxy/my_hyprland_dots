import QtQuick
import ".."
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

Rectangle {
    id: cafRoot

    property var barScreen: null
    property var barMonitor: null

    implicitWidth: Theme.isVertical ? Theme.barHeight - 8 : cafRow.implicitWidth + 24
    implicitHeight: Theme.barHeight - 8
    radius: Theme.radiusPill
    color: cafRoot.active ? Theme.primary_overlay : (cafMouse.containsMouse ? Theme.pillHover : Theme.pillBg)
    border.color: Theme.pillBorder
    border.width: Theme.pillBorder === "transparent" ? 0 : 1

    Behavior on color { ColorAnimation { duration: Theme.animFast } }
    Behavior on border.color { ColorAnimation { duration: Theme.animFast } }

    readonly property bool active: !IdleService.enabled

    function toggleInhibit() {
        IdleService.enabled = !IdleService.enabled;
    }

    Row {
        id: cafRow
        anchors.centerIn: parent
        spacing: 4

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Theme.iconCoffee
            font.family: Theme.fontIcon
            font.pixelSize: Theme.fontSizeMd
            color: cafRoot.active ? Theme.primary : Theme.on_surface
        }
    }

    IdlePopup {
        id: cafPopup
        screen: cafRoot.barScreen
    }

    Timer {
        id: hoverOpenTimer
        interval: Settings?.hoverDelay ?? 220
        repeat: false
        onTriggered: {
            if (cafMouse.containsMouse && (Settings?.hoverToOpen ?? true)) {
                let pt = cafRoot.mapToItem(null, 0, 0);
                if (Theme.isVertical) {
                    cafPopup.targetRelativeY = pt.y + (cafRoot.height / 2);
                } else {
                    cafPopup.targetRelativeX = pt.x + (cafRoot.width / 2);
                }
                cafPopup.open = true;
            }
        }
    }

    Timer {
        id: hoverCloseTimer
        interval: 350
        repeat: false
        onTriggered: {
            if (!cafMouse.containsMouse && !cafPopup.cardHovered && (Settings?.hoverAutoClose ?? true) && !cafPopup.pinned) {
                cafPopup.open = false;
            }
        }
    }

    MouseArea {
        id: cafMouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onEntered: {
            hoverCloseTimer.stop();
            hoverOpenTimer.restart();
        }
        onExited: {
            hoverOpenTimer.stop();
            hoverCloseTimer.restart();
        }
        onClicked: (mouse) => {
            if (mouse.button === Qt.RightButton) {
                let pt = cafRoot.mapToItem(null, 0, 0);
                if (Theme.isVertical) {
                    cafPopup.targetRelativeY = pt.y + (cafRoot.height / 2);
                } else {
                    cafPopup.targetRelativeX = pt.x + (cafRoot.width / 2);
                }
                cafPopup.pinned = !cafPopup.open;
                cafPopup.open = !cafPopup.open;
            } else {
                cafRoot.toggleInhibit();
            }
        }
    }

    Connections {
        target: cafPopup
        function onCardHoveredChanged() {
            if (cafPopup.cardHovered) {
                hoverCloseTimer.stop();
            } else if (!cafMouse.containsMouse) {
                hoverCloseTimer.restart();
            }
        }
    }

    Connections {
        target: Settings
        function onRequestIdleToggle() {
            if (!cafRoot.barScreen || Quickshell.screens.length <= 1 || (cafRoot.barMonitor && Hyprland.focusedMonitor && cafRoot.barMonitor.id === Hyprland.focusedMonitor.id)) {
                let pt = cafRoot.mapToItem(null, 0, 0);
                if (Theme.isVertical) {
                    cafPopup.targetRelativeY = pt ? (pt.y + (cafRoot.height / 2)) : 0;
                } else {
                    cafPopup.targetRelativeX = pt ? (pt.x + (cafRoot.width / 2)) : 0;
                }
                cafPopup.open = !cafPopup.open;
            }
        }
    }
}
