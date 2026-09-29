import QtQuick
import QtQuick.Layouts
import ".."

Item {
    id: root

    property string label: ""
    property string icon: ""
    property var model: []
    property int currentIndex: 0
    property var currentValue: null
    property bool expanded: false
    property int maxVisibleItems: 6
    property color accentColor: Theme.primary

    signal activated(int index, var value)
    signal selected(var value)

    implicitWidth: 200
    implicitHeight: headerButton.height + (root.expanded ? (menuContainer.implicitHeight + 4) : 0)

    Behavior on implicitHeight {
        NumberAnimation { duration: Theme.animNormal; easing.type: Theme.animEasing }
    }

    // Helper functions to normalize model data
    function getItemLabel(item, idx) {
        if (item === null || item === undefined) return "";
        if (typeof item === "string" || typeof item === "number") return String(item);
        if (typeof item === "object") {
            return item.label ?? item.title ?? item.name ?? item.text ?? item.value ?? String(idx);
        }
        return String(item);
    }

    function getItemValue(item, idx) {
        if (item === null || item === undefined) return null;
        if (typeof item === "string" || typeof item === "number") return item;
        if (typeof item === "object") {
            return item.value !== undefined ? item.value : (item.id !== undefined ? item.id : item);
        }
        return item;
    }

    function getItemIcon(item) {
        if (typeof item === "object" && item !== null && item.icon) return item.icon;
        return "";
    }

    // Synchronize currentValue and currentIndex
    onCurrentValueChanged: {
        if (root.model && root.model.length > 0) {
            for (let i = 0; i < root.model.length; i++) {
                if (root.getItemValue(root.model[i], i) === root.currentValue) {
                    if (root.currentIndex !== i) root.currentIndex = i;
                    break;
                }
            }
        }
    }

    onCurrentIndexChanged: {
        if (root.model && root.currentIndex >= 0 && root.currentIndex < root.model.length) {
            const v = root.getItemValue(root.model[root.currentIndex], root.currentIndex);
            if (root.currentValue !== v) root.currentValue = v;
        }
    }

    // Header Button
    Rectangle {
        id: headerButton
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 32
        radius: Theme.widgetRadius
        color: headerMouse.pressed
            ? Theme.surface_container_highest
            : (headerMouse.containsMouse ? Theme.surface_container_high : Theme.surface_container)
        border.width: 1
        border.color: root.expanded ? root.accentColor : (headerMouse.containsMouse ? Theme.outline : Theme.outline_variant)

        Behavior on color { ColorAnimation { duration: Theme.animFast } }
        Behavior on border.color { ColorAnimation { duration: Theme.animFast } }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            spacing: 6

            Text {
                visible: root.icon !== ""
                text: root.icon
                font.family: Theme.fontIcon
                font.pixelSize: Theme.fontSizeSm
                color: root.expanded ? root.accentColor : Theme.on_surface_variant
            }

            Text {
                visible: root.label !== ""
                text: root.label + ":"
                font.family: Theme.fontSans
                font.pixelSize: Theme.fontSizeXs
                font.weight: Font.Medium
                color: Theme.on_surface_variant
            }

            Text {
                Layout.fillWidth: true
                text: {
                    if (root.model && root.currentIndex >= 0 && root.currentIndex < root.model.length) {
                        return root.getItemLabel(root.model[root.currentIndex], root.currentIndex);
                    }
                    return "Select...";
                }
                font.family: Theme.fontSans
                font.pixelSize: Theme.fontSizeSm
                font.weight: Font.DemiBold
                color: Theme.on_surface
                elide: Text.ElideRight
            }

            Text {
                text: Theme.iconChevronDown
                font.family: Theme.fontIcon
                font.pixelSize: Theme.fontSizeXs
                color: root.expanded ? root.accentColor : Theme.on_surface_variant
                rotation: root.expanded ? 180 : 0

                Behavior on rotation {
                    NumberAnimation { duration: Theme.animFast; easing.type: Theme.animEasing }
                }
                Behavior on color { ColorAnimation { duration: Theme.animFast } }
            }
        }

        MouseArea {
            id: headerMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.expanded = !root.expanded
        }
    }

    // Expanding Items List
    Rectangle {
        id: menuContainer
        anchors.top: headerButton.bottom
        anchors.topMargin: 4
        anchors.left: parent.left
        anchors.right: parent.right
        clip: true
        visible: height > 0
        height: root.expanded ? Math.min(root.maxVisibleItems * 30 + 8, itemsList.contentHeight + 8) : 0
        implicitHeight: Math.min(root.maxVisibleItems * 30 + 8, itemsList.contentHeight + 8)
        radius: Theme.widgetRadius
        color: Theme.surface_container
        border.width: 1
        border.color: Theme.outline_variant

        Behavior on height {
            NumberAnimation { duration: Theme.animNormal; easing.type: Theme.animEasing }
        }

        Flickable {
            id: itemsList
            anchors.fill: parent
            anchors.margins: 4
            contentHeight: itemsCol.implicitHeight
            flickableDirection: Flickable.VerticalFlick
            boundsBehavior: Flickable.StopAtBounds
            clip: true

            Column {
                id: itemsCol
                width: parent.width
                spacing: 2

                Repeater {
                    model: root.model ?? []

                    delegate: Rectangle {
                        id: itemDelegate
                        required property var modelData
                        required property int index

                        readonly property bool isSelected: root.currentIndex === index
                        readonly property string itemLabel: root.getItemLabel(modelData, index)
                        readonly property var itemVal: root.getItemValue(modelData, index)
                        readonly property string itemIcon: root.getItemIcon(modelData)

                        width: itemsCol.width
                        height: 28
                        radius: Theme.radiusSm
                        color: isSelected
                            ? Theme.primary_container
                            : (itemMouse.containsMouse ? Theme.surface_container_high : "transparent")

                        Behavior on color { ColorAnimation { duration: Theme.animFast } }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            spacing: 6

                            Text {
                                visible: itemDelegate.itemIcon !== ""
                                text: itemDelegate.itemIcon
                                font.family: Theme.fontIcon
                                font.pixelSize: Theme.fontSizeSm
                                color: itemDelegate.isSelected ? Theme.on_primary_container : Theme.on_surface_variant
                            }

                            Text {
                                Layout.fillWidth: true
                                text: itemDelegate.itemLabel
                                font.family: Theme.fontSans
                                font.pixelSize: Theme.fontSizeSm
                                font.weight: itemDelegate.isSelected ? Font.DemiBold : Font.Normal
                                color: itemDelegate.isSelected ? Theme.on_primary_container : Theme.on_surface
                                elide: Text.ElideRight
                            }

                            Text {
                                visible: itemDelegate.isSelected
                                text: Theme.iconCheck
                                font.family: Theme.fontIcon
                                font.pixelSize: Theme.fontSizeXs
                                color: Theme.on_primary_container
                            }
                        }

                        MouseArea {
                            id: itemMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.currentIndex = itemDelegate.index;
                                root.currentValue = itemDelegate.itemVal;
                                root.activated(itemDelegate.index, itemDelegate.itemVal);
                                root.selected(itemDelegate.itemVal);
                                root.expanded = false;
                            }
                        }
                    }
                }
            }
        }
    }
}
