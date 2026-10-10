import QtQuick
import QtQuick.Layouts
import ".."
import Quickshell.Hyprland

Rectangle {
    id: wsContainer
    implicitWidth: Theme.isVertical
        ? Theme.barHeight - (Theme.workspaceWidgetPadding * 2)
        : (wsRow.implicitWidth + Theme.workspaceWidgetPadding * 2)
    implicitHeight: Theme.isVertical
        ? (wsCol.implicitHeight + Theme.workspaceWidgetPadding * 2)
        : Theme.barHeight - (Theme.workspaceWidgetPadding * 2)
    radius: Theme.radiusPill
    color: popup.open ? Theme.primary_overlay : (wsMouse.containsMouse ? Theme.pillHover : Theme.pillBg)
    border.color: Theme.pillBorder
    border.width: Theme.pillBorder === "transparent" ? 0 : 1

    Behavior on color { ColorAnimation { duration: Theme.animFast } }
    Behavior on border.color { ColorAnimation { duration: Theme.animFast } }

    property var workspaceList: []

    // Workspace dispatcher targeting Hyprland (supports Lua configuration & runtime dispatchers)
    function dispatchWs(target) {
        Settings.dispatchWorkspace(target);
    }

    function toggleSpecialWs(name) {
        Settings.dispatchToggleSpecial(name);
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

    readonly property int currentWsId: Hyprland.focusedWorkspace?.id ?? 1
    readonly property int currentWsIdx: {
        for (let i = 0; i < workspaceList.length; i++) {
            if (workspaceList[i].id === currentWsId) return i;
        }
        return 0;
    }

    readonly property string wsMode: Settings.workspaceMode ?? "slide"

    // vertical bar layout with configurable indicator modes
    Item {
        id: wsTrackV
        visible: Theme.isVertical
        anchors.centerIn: parent
        implicitWidth: Theme.workspaceIndicatorSize + Theme.workspaceSpacing
        implicitHeight: wsCol.implicitHeight

        Rectangle {
            id: fluidIndicatorV
            visible: wsContainer.workspaceList.length > 0 && wsContainer.wsMode !== "discrete"
            radius: Theme.radiusXs
            color: Theme.primary
            z: 2

            readonly property var activeItem: wsRepeaterV.itemAt(wsContainer.currentWsIdx)
            readonly property real targetY: activeItem ? activeItem.y : 0
            readonly property real targetH: activeItem ? activeItem.height : Theme.workspaceActiveSize

            property real leadingY: targetY + targetH
            property real trailingY: targetY
            property int lastIdx: 0

            onActiveItemChanged: {
                if (!activeItem) return;
                let newIdx = wsContainer.currentWsIdx;
                lastIdx = newIdx;
                leadingY = targetY + targetH;
                trailingY = targetY;
            }

            y: wsContainer.wsMode === "fluid-trail" ? Math.min(leadingY, trailingY) : targetY
            height: wsContainer.wsMode === "fluid-trail" ? Math.max(Theme.workspaceIndicatorMin, Math.abs(leadingY - trailingY)) : targetH
            width: Theme.workspaceIndicatorSize
            anchors.horizontalCenter: parent.horizontalCenter

            Behavior on leadingY {
                enabled: wsContainer.wsMode === "fluid-trail"
                NumberAnimation { duration: Theme.animFast; easing.type: Theme.animEasing }
            }
            Behavior on trailingY {
                enabled: wsContainer.wsMode === "fluid-trail"
                NumberAnimation { duration: Theme.workspaceTrailDuration; easing.type: Theme.animEasing }
            }
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
                    property bool isFocused: wsContainer.currentWsId === modelData.id
                    property bool isActive: modelData.windows > 0

                    width: Theme.workspaceDotSize
                    height: (wsContainer.wsMode === "discrete" && isFocused) ? Theme.workspaceActiveSize : (isActive ? Theme.workspaceDotSize + 2 : Theme.workspaceDotSize)
                    Behavior on height { NumberAnimation { duration: Theme.animFast; easing.type: Theme.animEasing } }

                    Rectangle {
                        anchors.centerIn: parent
                        width: Theme.workspaceDotSize
                        height: parent.height
                        radius: Theme.radiusXs
                        color: (wsContainer.wsMode === "discrete" && parent.isFocused)
                            ? Theme.primary
                            : (parent.isActive ? Theme.on_surface_variant : Theme.outline_variant)
                        opacity: (wsContainer.wsMode !== "discrete" && parent.isFocused) ? 0 : 1

                        Behavior on color { ColorAnimation { duration: Theme.animFast } }
                        Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
                    }
                }
            }
        }
    }

    // horizontal bar layout with configurable indicator modes
    Item {
        id: wsTrackH
        visible: !Theme.isVertical
        anchors.centerIn: parent
        implicitWidth: wsRow.implicitWidth
        implicitHeight: 10

        Rectangle {
            id: fluidIndicatorH
            visible: wsContainer.workspaceList.length > 0 && wsContainer.wsMode !== "discrete"
            radius: Theme.radiusXs
            color: Theme.primary
            z: 2

            readonly property var activeItem: wsRepeaterH.itemAt(wsContainer.currentWsIdx)
            readonly property real targetX: activeItem ? activeItem.x : 0
            readonly property real targetW: activeItem ? activeItem.width : Theme.workspaceActiveSize

            property real leadingX: targetX + targetW
            property real trailingX: targetX
            property int lastIdx: 0

            onActiveItemChanged: {
                if (!activeItem) return;
                let newIdx = wsContainer.currentWsIdx;
                lastIdx = newIdx;
                leadingX = targetX + targetW;
                trailingX = targetX;
            }

            x: wsContainer.wsMode === "fluid-trail" ? Math.min(leadingX, trailingX) : targetX
            width: wsContainer.wsMode === "fluid-trail" ? Math.max(Theme.workspaceIndicatorMin, Math.abs(leadingX - trailingX)) : targetW
            height: Theme.workspaceIndicatorSize
            anchors.verticalCenter: parent.verticalCenter

            Behavior on leadingX {
                enabled: wsContainer.wsMode === "fluid-trail"
                NumberAnimation { duration: Theme.animFast; easing.type: Theme.animEasing }
            }
            Behavior on trailingX {
                enabled: wsContainer.wsMode === "fluid-trail"
                NumberAnimation { duration: Theme.workspaceTrailDuration; easing.type: Theme.animEasing }
            }
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
                    property bool isFocused: wsContainer.currentWsId === modelData.id
                    property bool isActive: modelData.windows > 0

                    width: (wsContainer.wsMode === "discrete" && isFocused) ? Theme.workspaceActiveSize : (isActive ? Theme.workspaceDotSize + 2 : Theme.workspaceDotSize)
                    height: Theme.workspaceDotSize
                    Behavior on width { NumberAnimation { duration: Theme.animFast; easing.type: Theme.animEasing } }

                    Rectangle {
                        anchors.centerIn: parent
                        width: parent.width
                        height: Theme.workspaceDotSize
                        radius: Theme.radiusXs
                        color: (wsContainer.wsMode === "discrete" && parent.isFocused)
                            ? Theme.primary
                            : (parent.isActive ? Theme.on_surface_variant : Theme.outline_variant)
                        opacity: (wsContainer.wsMode !== "discrete" && parent.isFocused) ? 0 : 1

                        Behavior on color { ColorAnimation { duration: Theme.animFast } }
                        Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
                    }
                }
            }
        }
    }

    Connections {
        target: Settings
        function onRequestWorkspacesToggle() {
            if (Theme.isVertical) {
                let pt = wsContainer.mapToItem(null, 0, 0);
                popup.targetRelativeY = pt ? (pt.y + (wsContainer.height / 2)) : 0;
            } else {
                let pt = wsContainer.mapToItem(null, 0, 0);
                popup.targetRelativeX = pt ? (pt.x + (wsContainer.width / 2)) : 0;
            }
            popup.pinned = !popup.open;
            popup.open = !popup.open;
        }
        function onRequestWorkspacesOpen() {
            if (Theme.isVertical) {
                let pt = wsContainer.mapToItem(null, 0, 0);
                popup.targetRelativeY = pt ? (pt.y + (wsContainer.height / 2)) : 0;
            } else {
                let pt = wsContainer.mapToItem(null, 0, 0);
                popup.targetRelativeX = pt ? (pt.x + (wsContainer.width / 2)) : 0;
            }
            popup.pinned = true;
            popup.open = true;
        }
        function onRequestWorkspacesClose() {
            popup.pinned = false;
            popup.open = false;
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
            // Derives width deterministically from popup.cardWidth to prevent binding loops
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
                            text: "active: workspace " + (Hyprland.focusedWorkspace?.id ?? 1)
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

                Text {
                    text: Theme.iconWorkspaces
                    font.family: Theme.fontIcon
                    font.pixelSize: Theme.fontSizeMd
                    color: Theme.primary
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: Theme.popupDividerHeight
                color: Theme.widgetBorder
            }

            // workspace grid grows with its contents; once it reaches the Theme limit, scroll it.
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

                // Replaced QtQuick.Layouts GridLayout with QtQuick Grid positioner
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
                            readonly property var wsObj: {
                                let list = Hyprland.workspaces?.values || [];
                                for (let i = 0; i < list.length; i++) {
                                    if (list[i].id === wsId) return list[i];
                                }
                                return null;
                            }
                            readonly property bool isCurrent: (Hyprland.focusedWorkspace?.id ?? 1) === wsId
                            readonly property bool hasWindows: (wsObj?.windows ?? 0) > 0
                            readonly property int winCount: wsObj?.windows ?? 0

                            width: workspaceGrid.cardWidth
                            height: Theme.popupCardHeight
                            radius: Theme.radiusMd
                            color: isCurrent ? Theme.primary_overlay : (cardMouse.containsMouse ? Theme.surface_container_highest : Theme.surface_container_high)
                            border.color: isCurrent ? Theme.primary : "transparent"
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
                                    color: isCurrent ? Theme.primary : (hasWindows ? Theme.surface_variant : Theme.surface_container)

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
                                        text: isCurrent ? "currently active" : (hasWindows ? (winCount + (winCount === 1 ? " window" : " windows")) : "empty")
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
                                    color: isCurrent ? Theme.primary : "transparent"

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

            // footer action: clean full-width scratchpad button
            Rectangle {
                Layout.preferredHeight: Theme.popupActionHeight
                Layout.fillWidth: true
                radius: Theme.radiusSm
                color: specialMouse.containsMouse ? Theme.primary_overlay : Theme.surface_container_high
                border.color: specialMouse.containsMouse ? Theme.primary : "transparent"
                border.width: 1

                Behavior on color { ColorAnimation { duration: Theme.animFast } }

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
