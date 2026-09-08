import QtQuick
import QtQuick.Layouts
import ".."
import Quickshell.Hyprland

Rectangle {
    id: wsContainer
    implicitWidth: Theme.isVertical ? Theme.barHeight - 8 : (wsRow.implicitWidth + 24)
    implicitHeight: Theme.isVertical ? (wsCol.implicitHeight + 24) : Theme.barHeight - 8
    radius: Theme.radiusPill
    color: popup.open ? Theme.primary_overlay : (wsMouse.containsMouse ? Theme.pillHover : Theme.pillBg)
    border.color: Theme.pillBorder
    border.width: Theme.pillBorder === "transparent" ? 0 : 1

    Behavior on color { ColorAnimation { duration: Theme.animFast } }
    Behavior on border.color { ColorAnimation { duration: Theme.animFast } }

    property var workspaceList: []

    // universal dispatcher helper supporting both lua and legacy hyprlang
    function dispatchWs(target) {
        if (Hyprland.usingLua) {
            let arg = typeof target === "number" ? target : `"${target}"`;
            Hyprland.dispatch(`hl.dsp.focus({ workspace = ${arg} })`);
        } else {
            Hyprland.dispatch(`workspace ${target}`);
        }
    }

    function toggleSpecialWs(name) {
        if (Hyprland.usingLua) {
            Hyprland.dispatch(`hl.dsp.workspace.toggle_special("${name}")`);
        } else {
            Hyprland.dispatch(`togglespecialworkspace ${name}`);
        }
    }

    // filter out negative ids so scratchpads don't pollute bar dots
    function updateWorkspaceList() {
        let vals = Hyprland.workspaces?.values || [];
        workspaceList = vals
            .filter(w => w.id > 0)
            .slice()
            .sort((a, b) => a.id - b.id);
    }

    Component.onCompleted: updateWorkspaceList()

    Connections {
        target: Hyprland.workspaces
        function onValuesChanged() {
            wsDebounce.restart();
        }
    }

    Timer {
        id: wsDebounce
        interval: 10
        repeat: false
        onTriggered: wsContainer.updateWorkspaceList()
    }

    // vertical bar layout
    Column {
        id: wsCol
        visible: Theme.isVertical
        anchors.centerIn: parent
        spacing: 4

        Repeater {
            model: wsContainer.workspaceList

            Rectangle {
                required property var modelData
                property bool isFocused: Hyprland.focusedWorkspace?.id === modelData.id
                property bool isActive: modelData.windows > 0

                width: 6
                height: isFocused ? 18 : (isActive ? 8 : 6)
                radius: 3
                color: isFocused ? Theme.primary
                     : isActive  ? Theme.on_surface_variant
                                 : Theme.outline_variant

                Behavior on height { NumberAnimation { duration: Theme.animFast; easing.type: Theme.animEasing } }
                Behavior on color  { ColorAnimation  { duration: Theme.animFast; easing.type: Theme.animEasing } }
            }
        }
    }

    // horizontal bar layout
    Row {
        id: wsRow
        visible: !Theme.isVertical
        anchors.centerIn: parent
        spacing: 4

        Repeater {
            model: wsContainer.workspaceList

            Rectangle {
                required property var modelData
                property bool isFocused: Hyprland.focusedWorkspace?.id === modelData.id
                property bool isActive: modelData.windows > 0

                width: isFocused ? 18 : (isActive ? 8 : 6)
                height: 6
                radius: 3
                color: isFocused ? Theme.primary
                     : isActive  ? Theme.on_surface_variant
                                 : Theme.outline_variant

                Behavior on width  { NumberAnimation { duration: Theme.animFast; easing.type: Theme.animEasing } }
                Behavior on color  { ColorAnimation  { duration: Theme.animFast; easing.type: Theme.animEasing } }
            }
        }
    }

    // click to open popup, scroll to cycle workspaces
    MouseArea {
        id: wsMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        onClicked: (mouse) => {
            if (Theme.isVertical) {
                popup.targetRelativeY = wsContainer.mapToItem(null, 0, 0).y + (wsContainer.height / 2);
            } else {
                popup.targetRelativeX = wsContainer.mapToItem(null, 0, 0).x + (wsContainer.width / 2);
            }
            popup.open = !popup.open;
        }

        onWheel: (wheel) => {
            wheel.accepted = true;
            let delta = wheel.angleDelta.y !== 0 ? wheel.angleDelta.y : wheel.angleDelta.x;
            if (delta < 0) {
                // "r+1" scrolls forward relative on monitor with wrap
                wsContainer.dispatchWs("r+1");
            } else if (delta > 0) {
                // "r-1" scrolls backward relative on monitor with wrap
                wsContainer.dispatchWs("r-1");
            }
        }
    }

    PopupPanel {
        id: popup
        cardWidth: 440
        cardHeight: 420
        targetRelativeX: wsContainer.mapToItem(null, 0, 0).x + (wsContainer.width / 2)

        content: ColumnLayout {
            anchors.fill: parent
            spacing: Theme.widgetSpacing

            // header with title, active indicator, and scroll hint
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        text: "which workspace would you like to go?"
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeMd
                        font.weight: Font.Bold
                        color: Theme.primary
                        Layout.fillWidth: true
                    }

                    RowLayout {
                        spacing: 6
                        Text {
                            text: "active: workspace " + (Hyprland.focusedWorkspace?.id ?? 1)
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeXs
                            color: Theme.on_surface_variant
                        }
                        Text {
                            text: "•"
                            font.pixelSize: 8
                            color: Theme.outline_variant
                        }
                        Text {
                            text: "scroll bar to cycle"
                            font.family: Theme.fontMono
                            font.pixelSize: 9
                            color: Theme.primary
                        }
                    }
                }

                Text {
                    text: Theme.iconWorkspaces
                    font.family: Theme.fontIcon
                    font.pixelSize: Theme.fontSizeMd
                    color: Theme.primary
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Theme.widgetBorder
            }

            // grid of workspaces
            GridLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                columns: 2
                columnSpacing: 8
                rowSpacing: 6

                Repeater {
                    model: Settings?.workspaceCount ?? 10

                    delegate: Rectangle {
                        required property int index
                        readonly property int wsId: index + 1
                        readonly property var wsObj: {
                            let list = Hyprland.workspaces.values || [];
                            for (let i = 0; i < list.length; i++) {
                                if (list[i].id === wsId) return list[i];
                            }
                            return null;
                        }
                        readonly property bool isCurrent: (Hyprland.focusedWorkspace?.id ?? 1) === wsId
                        readonly property bool hasWindows: (wsObj?.windows ?? 0) > 0
                        readonly property int winCount: wsObj?.windows ?? 0

                        Layout.fillWidth: true
                        Layout.preferredHeight: 44
                        radius: Theme.radiusMd
                        color: isCurrent ? Theme.primary_overlay : (cardMouse.containsMouse ? Theme.surface_container_highest : Theme.surface_container_high)
                        border.color: isCurrent ? Theme.primary : "transparent"
                        border.width: 1

                        Behavior on color { ColorAnimation { duration: Theme.animFast } }
                        Behavior on border.color { ColorAnimation { duration: Theme.animFast } }

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 10

                            Rectangle {
                                Layout.preferredWidth: 26
                                Layout.preferredHeight: 26
                                radius: Theme.radiusSm
                                color: isCurrent ? Theme.primary : (hasWindows ? Theme.surface_variant : Theme.surface_container)

                                Text {
                                    text: wsId
                                    font.family: Theme.fontMono
                                    font.pixelSize: Theme.fontSizeSm
                                    font.weight: Font.Bold
                                    color: isCurrent ? Theme.on_primary : Theme.on_surface
                                    anchors.centerIn: parent
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 1

                                Text {
                                    text: "workspace " + wsId
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSizeSm
                                    font.weight: Font.Medium
                                    color: isCurrent ? Theme.primary : Theme.on_surface
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }

                                Text {
                                    text: isCurrent ? "currently active" : (hasWindows ? (winCount + (winCount === 1 ? " window" : " windows")) : "empty")
                                    font.family: Theme.fontFamily
                                    font.pixelSize: Theme.fontSizeXs
                                    color: isCurrent ? Theme.primary : Theme.on_surface_variant
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                            }

                            Rectangle {
                                Layout.preferredWidth: 22
                                Layout.preferredHeight: 20
                                radius: Theme.radiusSm
                                color: isCurrent ? Theme.primary : "transparent"

                                Text {
                                    text: isCurrent ? Theme.iconCheck : "↵"
                                    font.family: Theme.fontMono
                                    font.pixelSize: 10
                                    font.weight: Font.Bold
                                    color: isCurrent ? Theme.on_primary : Theme.on_surface_variant
                                    anchors.centerIn: parent
                                }
                            }
                        }

                        MouseArea {
                            id: cardMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                wsContainer.dispatchWs(wsId);
                                popup.open = false;
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

            // footer action: clean full-width scratchpad button
            Rectangle {
                Layout.preferredHeight: 32
                Layout.fillWidth: true
                radius: Theme.radiusSm
                color: specialMouse.containsMouse ? Theme.primary_overlay : Theme.surface_container_high
                border.color: specialMouse.containsMouse ? Theme.primary : "transparent"
                border.width: 1

                Behavior on color { ColorAnimation { duration: Theme.animFast } }

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 6

                    Text {
                        text: "󰒝"
                        font.family: Theme.fontMono
                        font.pixelSize: Theme.fontSizeSm
                        color: Theme.primary
                    }

                    Text {
                        text: "toggle scratchpad"
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeXs
                        font.weight: Font.Medium
                        color: Theme.on_surface
                    }
                }

                MouseArea {
                    id: specialMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        wsContainer.toggleSpecialWs("scratchpad");
                        popup.open = false;
                    }
                }
            }
        }
    }
}
