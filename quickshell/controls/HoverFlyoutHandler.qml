import QtQuick
import ".."

Item {
    id: root

    required property var popup
    required property var mouseArea
    property var updatePos: null

    readonly property bool enabled: Settings?.hoverToOpen ?? false
    readonly property int openDelay: Settings?.hoverDelay ?? 220
    readonly property int closeDelay: 350
    readonly property bool autoClose: Settings?.hoverAutoClose ?? true

    Timer {
        id: openTimer
        interval: Math.max(50, root.openDelay)
        repeat: false
        onTriggered: {
            if (root.enabled && root.mouseArea && root.mouseArea.containsMouse && root.popup) {
                if (typeof root.updatePos === "function") root.updatePos();
                root.popup.pinned = false;
                root.popup.open = true;
            }
        }
    }

    Timer {
        id: closeTimer
        interval: root.closeDelay
        repeat: false
        onTriggered: {
            if (root.autoClose && root.popup && !root.popup.pinned) {
                let mouseInPill = root.mouseArea && root.mouseArea.containsMouse;
                let mouseInCard = root.popup.cardHovered;
                if (!mouseInPill && !mouseInCard) {
                    root.popup.open = false;
                }
            }
        }
    }

    Connections {
        target: root.mouseArea
        function onEntered() {
            closeTimer.stop();
            if (root.enabled) {
                openTimer.restart();
            }
        }
        function onExited() {
            openTimer.stop();
            if (root.autoClose && root.popup && root.popup.open && !root.popup.pinned) {
                closeTimer.restart();
            }
        }
    }

    Connections {
        target: root.popup
        function onCardHoveredChanged() {
            if (root.popup.cardHovered) {
                closeTimer.stop();
            } else {
                let mouseInPill = root.mouseArea && root.mouseArea.containsMouse;
                if (!mouseInPill && root.autoClose && root.popup.open && !root.popup.pinned) {
                    closeTimer.restart();
                }
            }
        }
    }

    function handlePillClick() {
        if (!root.popup) return;
        if (typeof root.updatePos === "function") root.updatePos();
        if (!root.popup.open) {
            root.popup.pinned = true;
            root.popup.open = true;
        } else if (!root.popup.pinned) {
            root.popup.pinned = true;
        } else {
            root.popup.pinned = false;
            root.popup.open = false;
        }
    }
}
