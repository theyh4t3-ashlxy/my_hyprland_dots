import QtQuick
import ".."
import Quickshell
import Quickshell.Services.UPower
import Quickshell.Hyprland

Rectangle {
    id: container

    property var barScreen: null
    property var barMonitor: null
    property var device: UPower.displayDevice

    readonly property bool isVertical: Theme?.isVertical ?? false
    // handles both fractional 0-1 and raw 0-100 without turning into 9500%
    readonly property int pct: {
        let p = container.device?.percentage ?? 0;
        return Math.min(100, Math.max(0, Math.round(p <= 1.0 ? p * 100 : p)));
    }
    readonly property bool isCharging: container.device?.state === UPowerDeviceState.Charging
                                    || container.device?.state === UPowerDeviceState.PendingCharge
    readonly property bool isLow: pct < 20 && !isCharging

    visible: (Settings?.showBattery ?? true) && (device?.ready ?? false) && (device?.isPresent ?? false)

    implicitWidth: isVertical ? ((Theme?.barHeight ?? 48) - 8) : (contentRow.implicitWidth + 16)
    implicitHeight: (Theme?.barHeight ?? 48) - 8
    radius: Theme?.radiusPill ?? 999
    color: isLow ? Theme.error_overlay : (bMouse.containsMouse ? Theme.pillHover : Theme.pillBg)
    border.color: isLow ? Theme.error : (Theme?.pillBorder ?? "transparent")
    border.width: (isLow || (Theme?.pillBorder ?? "transparent") !== "transparent") ? 1 : 0

    Behavior on color { ColorAnimation { duration: Theme?.animFast ?? 150 } }
    Behavior on border.color { ColorAnimation { duration: Theme?.animFast ?? 150 } }
    Behavior on implicitWidth { NumberAnimation { duration: Theme?.animFast ?? 150; easing.type: Theme?.animEasing ?? Easing.OutQuad } }

    Row {
        id: contentRow
        anchors.centerIn: parent
        spacing: 4

        Text {
            id: batIcon
            anchors.verticalCenter: parent.verticalCenter
            text: Theme?.getBatteryIcon ? Theme.getBatteryIcon(container.pct, container.isCharging, !(UPower?.onBattery ?? true), container.isVertical) : (Theme?.iconBatFull ?? "\uE1A5")
            font.family: Theme?.fontIcon ?? "sans-serif"
            font.pixelSize: Theme?.fontSizeMd ?? 14
            color: container.isLow ? Theme.error : Theme.on_surface
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: !container.isVertical
            // killed the duplicate icons here so batIcon is the only glyph on screen
            text: {
                if (bMouse.containsMouse) {
                    if (container.isCharging) {
                        return Theme?.getFlavor
                            ? Theme.getFlavor("battery_charging", Theme.getVibe(Theme?.kaoBolt ? (Theme.kaoBolt + " chuggin watts") : "chuggin watts", "charging (" + container.pct + "%)", "charging (" + container.pct + "%)"))
                            : ("charging (" + container.pct + "%)");
                    }
                    if (container.pct < 15) {
                        return Theme?.getFlavor
                            ? Theme.getFlavor("battery_low", Theme.getVibe(Theme?.kaoSad ? (Theme.kaoSad + " feed me") : "feed me", "low (" + container.pct + "%)", "low (" + container.pct + "%)"))
                            : ("low (" + container.pct + "%)");
                    }
                    if (container.pct >= 95) {
                        return Theme?.getFlavor
                            ? Theme.getFlavor("battery_full", Theme.getVibe(Theme?.kaoHappy ? (Theme.kaoHappy + " full") : "full", "full (" + container.pct + "%)", "full (" + container.pct + "%)"))
                            : ("full (" + container.pct + "%)");
                    }
                }
                return container.pct + "%";
            }
            font.family: Theme?.fontFamily ?? "sans-serif"
            font.pixelSize: Theme?.fontSizeXs ?? 10
            font.weight: Font.Medium
            color: container.isLow ? Theme.error : Theme.on_surface
        }
    }

    BatteryPopup {
        id: batPopup
        screen: container.barScreen
        device: container.device
    }

    Timer {
        id: hoverOpenTimer
        interval: Settings?.hoverDelay ?? 220
        repeat: false
        onTriggered: {
            if (bMouse.containsMouse && (Settings?.hoverToOpen ?? true)) {
                let pt = container.mapToItem(null, 0, 0);
                if (container.isVertical) {
                    batPopup.targetRelativeY = pt.y + (container.height / 2);
                } else {
                    batPopup.targetRelativeX = pt.x + (container.width / 2);
                }
                batPopup.open = true;
            }
        }
    }

    readonly property bool isPillHovered: (bMouse.containsMouse || bHover.hovered)

    Timer {
        id: hoverCloseTimer
        interval: 350
        repeat: false
        onTriggered: {
            if (!container.isPillHovered && !batPopup.cardHovered && (Settings?.hoverAutoClose ?? true) && !batPopup.pinned) {
                batPopup.open = false;
            }
        }
    }

    HoverHandler {
        id: bHover
        onHoveredChanged: {
            if (hovered) {
                hoverCloseTimer.stop();
                hoverOpenTimer.restart();
            } else {
                hoverOpenTimer.stop();
                hoverCloseTimer.restart();
            }
        }
    }

    MouseArea {
        id: bMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: {
            hoverCloseTimer.stop();
            hoverOpenTimer.restart();
        }
        onExited: {
            hoverOpenTimer.stop();
            hoverCloseTimer.restart();
        }
        onClicked: {
            let pt = container.mapToItem(null, 0, 0);
            if (container.isVertical) {
                batPopup.targetRelativeY = pt.y + (container.height / 2);
            } else {
                batPopup.targetRelativeX = pt.x + (container.width / 2);
            }
            batPopup.pinned = !batPopup.open;
            batPopup.open = !batPopup.open;
        }
    }

    Connections {
        target: batPopup
        function onCardHoveredChanged() {
            if (batPopup.cardHovered) {
                hoverCloseTimer.stop();
            } else if (!container.isPillHovered) {
                hoverCloseTimer.restart();
            }
        }
    }

    Connections {
        target: Settings
        function onRequestBatteryToggle() {
            if (!container.barScreen || Quickshell.screens.length <= 1 || (container.barMonitor && Hyprland.focusedMonitor && container.barMonitor.id === Hyprland.focusedMonitor.id)) {
                let pt = container.mapToItem(null, 0, 0);
                if (container.isVertical) {
                    batPopup.targetRelativeY = pt ? (pt.y + (container.height / 2)) : 0;
                } else {
                    batPopup.targetRelativeX = pt ? (pt.x + (container.width / 2)) : 0;
                }
                batPopup.open = !batPopup.open;
            }
        }
    }
}