import QtQuick
import QtQuick.Layouts
import ".."
import Quickshell.Hyprland

Rectangle {
    id: wsContainer

    // extra padding on the ends of the pill so the outer dots don't hug the curved caps
    readonly property int trackPadding: Math.max(Theme.workspaceWidgetPadding * 2, 10)

    implicitWidth: Theme.isVertical
        ? Theme.barHeight - (Theme.workspaceWidgetPadding * 2)
        : (wsRow.implicitWidth + trackPadding * 2)
    implicitHeight: Theme.isVertical
        ? (wsCol.implicitHeight + trackPadding * 2)
        : Theme.barHeight - (Theme.workspaceWidgetPadding * 2)

    radius: Theme.radiusPill
    color: popup.open ? Theme.primary_overlay : (wsMouse.containsMouse ? Theme.pillHover : Theme.pillBg)
    border.color: Theme.pillBorder
    border.width: Theme.pillBorder === "transparent" ? 0 : 1

    Behavior on color { ColorAnimation { duration: Theme.animFast } }
    Behavior on border.color { ColorAnimation { duration: Theme.animFast } }

    property var workspaceList: []
    property var workspaceMap: ({})
    property int scratchpadWindows: 0

    // routes through Settings for Lua/custom config hooks, falls back to native Hyprland IPC
    function dispatchWs(target) {
        if (Settings?.dispatchWorkspace) {
            Settings.dispatchWorkspace(target);
        } else {
            Hyprland.dispatch("workspace " + target);
        }
    }

    function toggleSpecialWs(name) {
        if (Settings?.dispatchToggleSpecial) {
            Settings.dispatchToggleSpecial(name);
        } else {
            Hyprland.dispatch("togglespecialworkspace " + name);
        }
    }

    // filter out negative ids so scratchpads don't pollute bar dots,
    // and build a lookup map so popup cards don't loop over Hyprland values on every render
    function updateWorkspaceList() {
        let vals = Hyprland.workspaces?.values || [];
        let list = [];
        let map = {};
        let scratchCount = 0;

        for (let i = 0; i < vals.length; i++) {
            let w = vals[i];
            if (w.id > 0) {
                list.push(w);
                map[w.id] = w;
            } else if (w.name === "special:scratchpad" || w.name === "scratchpad") {
                scratchCount = w.windows ?? 0;
            }
        }

        list.sort((a, b) => a.id - b.id);
        workspaceList = list;
        workspaceMap = map;
        scratchpadWindows = scratchCount;
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

    readonly property int currentWsId: Hyprland.focusedWorkspace?.id ?? 1
    readonly property int currentWsIdx: {
        for (let i = 0; i < workspaceList.length; i++) {
            if (workspaceList[i].id === currentWsId) return i;
        }
        return 0;
    }

    // track travel direction so fluid-trail stretches the right edge first
    property int prevWsIdx: 0
    property bool movingForward: true
    onCurrentWsIdxChanged: {
        movingForward = currentWsIdx >= prevWsIdx;
        prevWsIdx = currentWsIdx;
    }

    readonly property string wsMode: Settings.workspaceMode ?? "slide"

    // vertical bar track
    Item {
        id: wsTrackV
        visible: Theme.isVertical
        anchors.centerIn: parent
        implicitWidth: Math.max(Theme.workspaceDotSize, Theme.workspaceIndicatorSize)
        implicitHeight: wsCol.implicitHeight

        Rectangle {
            id: fluidIndicatorV
            visible: wsContainer.workspaceList.length > 0 && wsContainer.wsMode !== "discrete"
            width: Theme.workspaceDotSize
            radius: width / 2
            color: Theme.primary
            z: 2
            anchors.horizontalCenter: parent.horizontalCenter

            readonly property var activeItem: wsRepeaterV.itemAt(wsContainer.currentWsIdx)
            readonly property real targetY: activeItem ? activeItem.y : 0
            readonly property real targetH: activeItem ? activeItem.height : Theme.workspaceActiveSize

            property real topEdge: targetY
            property real bottomEdge: targetY + targetH

            Behavior on topEdge {
                enabled: wsContainer.wsMode === "fluid-trail"
                NumberAnimation {
                    duration: wsContainer.movingForward ? Theme.workspaceTrailDuration : Theme.animFast
                    easing.type: Theme.animEasing
                }
            }
            Behavior on bottomEdge {
                enabled: wsContainer.wsMode === "fluid-trail"
                NumberAnimation {
                    duration: wsContainer.movingForward ? Theme.animFast : Theme.workspaceTrailDuration
                    easing.type: Theme.animEasing
                }
            }

            y: wsContainer.wsMode === "fluid-trail" ? topEdge : targetY
            height: wsContainer.wsMode === "fluid-trail"
                ? Math.max(Theme.workspaceDotSize, bottomEdge - topEdge)
                : targetH

            Behavior on y {
                enabled: wsContainer.wsMode === "slide"
                NumberAnimation { duration: Theme.animNormal; easing.type: Theme.animEasing }
            }
            Behavior on height {
                enabled: wsContainer.wsMode === "slide"
                NumberAnimation { duration: Theme.animFast; easing.type: Theme.animEasing }
            }
        }

        Column {
            id: wsCol
            spacing: Theme.workspaceSpacing
            anchors.horizontalCenter: parent.horizontalCenter
            z: 1

            Repeater {
                id: wsRepeaterV
                model: wsContainer.workspaceList

                Item {
                    id: wsItemV
                    required property var modelData
                    readonly property bool isFocused: wsContainer.currentWsId === modelData.id
                    readonly property bool isActive: modelData.windows > 0

                    width: Theme.workspaceDotSize
                    height: isFocused ? Theme.workspaceActiveSize : Theme.workspaceDotSize

                    Behavior on height {
                        NumberAnimation { duration: Theme.animFast; easing.type: Theme.animEasing }
                    }

                    Rectangle {
                        anchors.centerIn: parent
                        width: Theme.workspaceDotSize
                        height: parent.height
                        radius: width / 2
                        color: (wsContainer.wsMode === "discrete" && parent.isFocused)
                            ? Theme.primary
                            : (parent.isActive ? Theme.on_surface_variant : Theme.outline_variant)
                        opacity: (wsContainer.wsMode !== "discrete" && parent.isFocused)
                            ? 0.25
                            : (parent.isActive ? 0.9 : 0.4)

                        Behavior on color { ColorAnimation { duration: Theme.animFast } }
                        Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
                    }
                }
            }
        }
    }

    // horizontal bar track
    Item {
        id: wsTrackH
        visible: !Theme.isVertical
        anchors.centerIn: parent
        implicitWidth: wsRow.implicitWidth
        implicitHeight: Math.max(Theme.workspaceDotSize, Theme.workspaceIndicatorSize)

        Rectangle {
            id: fluidIndicatorH
            visible: wsContainer.workspaceList.length > 0 && wsContainer.wsMode !== "discrete"
            height: Theme.workspaceDotSize
            radius: height / 2
            color: Theme.primary
            z: 2
            anchors.verticalCenter: parent.verticalCenter

            readonly property var activeItem: wsRepeaterH.itemAt(wsContainer.currentWsIdx)
            readonly property real targetX: activeItem ? activeItem.x : 0
            readonly property real targetW: activeItem ? activeItem.width : Theme.workspaceActiveSize

            property real leftEdge: targetX
            property real rightEdge: targetX + targetW

            Behavior on leftEdge {
                enabled: wsContainer.wsMode === "fluid-trail"
                NumberAnimation {
                    duration: wsContainer.movingForward ? Theme.workspaceTrailDuration : Theme.animFast
                    easing.type: Theme.animEasing
                }
            }
            Behavior on rightEdge {
                enabled: wsContainer.wsMode === "fluid-trail"
                NumberAnimation {
                    duration: wsContainer.movingForward ? Theme.animFast : Theme.workspaceTrailDuration
                    easing.type: Theme.animEasing
                }
            }

            x: wsContainer.wsMode === "fluid-trail" ? leftEdge : targetX
            width: wsContainer.wsMode === "fluid-trail"
                ? Math.max(Theme.workspaceDotSize, rightEdge - leftEdge)
                : targetW

            Behavior on x {
                enabled: wsContainer.wsMode === "slide"
                NumberAnimation { duration: Theme.animNormal; easing.type: Theme.animEasing }
            }
            Behavior on width {
                enabled: wsContainer.wsMode === "slide"
                NumberAnimation { duration: Theme.animFast; easing.type: Theme.animEasing }
            }
        }

        Row {
            id: wsRow
            spacing: Theme.workspaceSpacing
            anchors.verticalCenter: parent.verticalCenter
            z: 1

            Repeater {
                id: wsRepeaterH
                model: wsContainer.workspaceList

                Item {
                    id: wsItemH
                    required property var modelData
                    readonly property bool isFocused: wsContainer.currentWsId === modelData.id
                    readonly property bool isActive: modelData.windows > 0

                    width: isFocused ? Theme.workspaceActiveSize : Theme.workspaceDotSize
                    height: Theme.workspaceDotSize

                    Behavior on width {
                        NumberAnimation { duration: Theme.animFast; easing.type: Theme.animEasing }
                    }

                    Rectangle {
                        anchors.centerIn: parent
                        width: parent.width
                        height: Theme.workspaceDotSize
                        radius: height / 2
                        color: (wsContainer.wsMode === "discrete" && parent.isFocused)
                            ? Theme.primary
                            : (parent.isActive ? Theme.on_surface_variant : Theme.outline_variant)
                        opacity: (wsContainer.wsMode !== "discrete" && parent.isFocused)
                            ? 0.25
                            : (parent.isActive ? 0.9 : 0.4)

                        Behavior on color { ColorAnimation { duration: Theme.animFast } }
                        Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
                    }
                }
            }
        }
    }

    function syncAnchor() {
        let pt = wsContainer.mapToItem(null, 0, 0);
        if (Theme.isVertical) {
            popup.targetRelativeY = pt ? (pt.y + (wsContainer.height / 2)) : 0;
        } else {
            popup.targetRelativeX = pt ? (pt.x + (wsContainer.width / 2)) : 0;
        }
    }

    Connections {
        target: Settings
        function onRequestWorkspacesToggle() {
            wsContainer.syncAnchor();
            popup.pinned = !popup.open;
            popup.open = !popup.open;
        }
        function onRequestWorkspacesOpen() {
            wsContainer.syncAnchor();
            popup.pinned = true;
            popup.open = true;
        }
        function onRequestWorkspacesClose() {
            popup.pinned = false;
            popup.open = false;
        }
    }

    HoverFlyoutHandler {
        popup: popup
        mouseArea: wsMouse
        updatePos: () => wsContainer.syncAnchor()
    }

    // click to open popup, scroll to cycle workspaces
    MouseArea {
        id: wsMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton

        onClicked: (mouse) => {
            wsContainer.syncAnchor();
            if (!popup.open) {
                popup.pinned = true;
                popup.open = true;
            } else if (!popup.pinned) {
                popup.pinned = true;
            } else {
                popup.pinned = false;
                popup.open = false;
            }
        }

        onWheel: (wheel) => {
            wheel.accepted = true;
            let delta = wheel.angleDelta.y !== 0 ? wheel.angleDelta.y : wheel.angleDelta.x;
            if (delta < 0) {
                wsContainer.dispatchWs("r+1");
            } else if (delta > 0) {
                wsContainer.dispatchWs("r-1");
            }
        }
    }

    PopupPanel {
        id: popup
        cardWidth: Math.max(
            Theme.popupMinWidth,
            Math.min(
                Theme.popupMaxWidth,
                Math.max(
                    popupHeader.implicitWidth,
                    (Theme.popupCardMinWidth * Theme.popupColumns) + (Theme.widgetSpacing * (Theme.popupColumns - 1))
                ) + (Theme.popupPadding * 2)
            )
        )
        cardHeight: Math.max(
            Theme.popupMinHeight,
            Math.min(Theme.popupMaxHeight, popupContent.implicitHeight + (Theme.popupPadding * 2))
        )
        targetRelativeX: (wsContainer.mapToItem(null, 0, 0)?.x ?? 0) + (wsContainer.width / 2)

        content: ColumnLayout {
            id: popupContent
            // derives width deterministically from popup.cardWidth to prevent binding loops
            width: Math.max(0, popup.cardWidth - (Theme.popupPadding * 2))
            spacing: Theme.popupSpacing

            // header with title, active indicator, and scroll hint
            RowLayout {
                id: popupHeader
                Layout.fillWidth: true
                spacing: Theme.widgetSpacing

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Theme.widgetSpacing / 2

                    Text {
                        text: "which workspace would you like to go?"
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeMd
                        font.weight: Theme.fontWeightBold
                        color: Theme.primary
                        Layout.fillWidth: true
                    }

                    RowLayout {
                        spacing: Theme.widgetSpacing

                        Text {
                            text: "active: workspace " + wsContainer.currentWsId
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeXs
                            color: Theme.on_surface_variant
                        }
                        Text {
                            text: "•"
                            font.pixelSize: Theme.fontSizeXs
                            color: Theme.outline_variant
                        }
                        Text {
                            text: "scroll bar to cycle"
                            font.family: Theme.fontMono
                            font.pixelSize: Theme.fontSizeXs
                            color: Theme.primary
                        }
                    }
                }

                Rectangle {
                    Layout.preferredWidth: Theme.popupCardIconSize
                    Layout.preferredHeight: Theme.popupCardIconSize
                    radius: Theme.radiusSm
                    color: Theme.primary_overlay

                    Text {
                        anchors.centerIn: parent
                        text: Theme.iconWorkspaces
                        font.family: Theme.fontIcon
                        font.pixelSize: Theme.fontSizeMd
                        color: Theme.primary
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: Theme.popupDividerHeight
                color: Theme.widgetBorder
            }

            // workspace grid grows with its contents; once it reaches the Theme limit, scroll it
            Flickable {
                id: workspaceScroller
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(workspaceGrid.implicitHeight, Theme.popupWorkspaceMaxHeight)
                clip: true
                contentWidth: width
                contentHeight: workspaceGrid.implicitHeight
                boundsBehavior: Flickable.StopAtBounds
                flickableDirection: Flickable.VerticalFlick
                interactive: contentHeight > height

                Grid {
                    id: workspaceGrid
                    width: workspaceScroller.width
                    columns: Math.max(1, Math.min(Theme.popupColumns, Settings?.workspaceCount ?? Theme.popupColumns))
                    columnSpacing: Theme.widgetSpacing
                    rowSpacing: Theme.popupCardGap

                    readonly property real cardWidth: Math.max(
                        0,
                        Math.floor((width - (columnSpacing * (columns - 1))) / columns)
                    )

                    Repeater {
                        model: Settings?.workspaceCount ?? 10

                        delegate: Rectangle {
                            id: cardDelegate
                            required property int index
                            readonly property int wsId: index + 1
                            readonly property var wsObj: wsContainer.workspaceMap[wsId] ?? null
                            readonly property bool isCurrent: wsContainer.currentWsId === wsId
                            readonly property int winCount: wsObj?.windows ?? 0
                            readonly property bool hasWindows: winCount > 0

                            width: workspaceGrid.cardWidth
                            height: Theme.popupCardHeight
                            radius: Theme.radiusMd
                            color: isCurrent
                                ? Theme.primary_overlay
                                : (cardMouse.containsMouse ? Theme.surface_container_highest : Theme.surface_container_high)
                            border.color: isCurrent
                                ? Theme.primary
                                : (cardMouse.containsMouse ? Theme.outline_variant : "transparent")
                            border.width: 1

                            Behavior on color { ColorAnimation { duration: Theme.animFast } }
                            Behavior on border.color { ColorAnimation { duration: Theme.animFast } }

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: Theme.popupCardPadding
                                spacing: Theme.widgetSpacing

                                Rectangle {
                                    Layout.preferredWidth: Theme.popupCardIconSize
                                    Layout.preferredHeight: Theme.popupCardIconSize
                                    radius: Theme.radiusSm
                                    color: isCurrent
                                        ? Theme.primary
                                        : (hasWindows ? Theme.surface_variant : Theme.surface_container)

                                    Behavior on color { ColorAnimation { duration: Theme.animFast } }

                                    Text {
                                        text: wsId
                                        font.family: Theme.fontMono
                                        font.pixelSize: Theme.fontSizeSm
                                        font.weight: Theme.fontWeightBold
                                        color: isCurrent ? Theme.on_primary : Theme.on_surface
                                        anchors.centerIn: parent
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: Theme.widgetSpacing / 2

                                    Text {
                                        text: "workspace " + wsId
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.fontSizeSm
                                        font.weight: Theme.fontWeightMedium
                                        color: isCurrent ? Theme.primary : Theme.on_surface
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }

                                    Text {
                                        text: isCurrent
                                            ? "currently active"
                                            : (hasWindows ? (winCount + (winCount === 1 ? " window" : " windows")) : "empty")
                                        font.family: Theme.fontFamily
                                        font.pixelSize: Theme.fontSizeXs
                                        color: isCurrent ? Theme.primary : Theme.on_surface_variant
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }
                                }

                                Rectangle {
                                    Layout.preferredWidth: Theme.popupCardIconSize - 4
                                    Layout.preferredHeight: Theme.popupCardIconSize - 6
                                    radius: Theme.radiusSm
                                    color: isCurrent
                                        ? Theme.primary
                                        : (cardMouse.containsMouse ? Theme.surface_variant : "transparent")
                                    opacity: (isCurrent || cardMouse.containsMouse) ? 1.0 : 0.45

                                    Behavior on color { ColorAnimation { duration: Theme.animFast } }
                                    Behavior on opacity { NumberAnimation { duration: Theme.animFast } }

                                    Text {
                                        text: isCurrent ? Theme.iconCheck : "↵"
                                        font.family: Theme.fontMono
                                        font.pixelSize: Theme.fontSizeXs
                                        font.weight: Theme.fontWeightBold
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
                                    popup.pinned = false;
                                    popup.open = false;
                                }
                            }
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: Theme.popupDividerHeight
                color: Theme.widgetBorder
            }

            // footer action: full-width scratchpad button with live window count
            Rectangle {
                Layout.preferredHeight: Theme.popupActionHeight
                Layout.fillWidth: true
                radius: Theme.radiusSm
                color: specialMouse.containsMouse ? Theme.primary_overlay : Theme.surface_container_high
                border.color: specialMouse.containsMouse ? Theme.primary : "transparent"
                border.width: 1

                Behavior on color { ColorAnimation { duration: Theme.animFast } }
                Behavior on border.color { ColorAnimation { duration: Theme.animFast } }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Theme.popupCardPadding
                    anchors.rightMargin: Theme.popupCardPadding
                    spacing: Theme.widgetSpacing
                    layoutDirection: Qt.LeftToRight

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
                        font.weight: Theme.fontWeightMedium
                        color: Theme.on_surface
                        Layout.fillWidth: true
                    }

                    Text {
                        visible: wsContainer.scratchpadWindows > 0
                        text: wsContainer.scratchpadWindows + (wsContainer.scratchpadWindows === 1 ? " window" : " windows")
                        font.family: Theme.fontMono
                        font.pixelSize: Theme.fontSizeXs
                        color: Theme.primary
                    }
                }

                MouseArea {
                    id: specialMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        wsContainer.toggleSpecialWs("scratchpad");
                        popup.pinned = false;
                        popup.open = false;
                    }
                }
            }
        }
    }
}
