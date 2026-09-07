import QtQuick
import QtQuick.Layouts
import ".."
import "../controls"
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Notifications

Rectangle {
    id: root
    implicitWidth: (Theme?.isVertical ?? false) ? ((Theme?.barHeight ?? 48) - 8) : (notifRow.implicitWidth + 24)
    implicitHeight: (Theme?.barHeight ?? 48) - 8
    radius: Theme?.radiusPill ?? 999
    color: popup.open ? Theme.primary_overlay : (notifMouse.containsMouse ? Theme.pillHover : Theme.pillBg)
    border.color: (Settings?.dnd ?? false) ? Theme.tertiary : (Theme?.pillBorder ?? "transparent")
    border.width: ((Settings?.dnd ?? false) || (Theme?.pillBorder ?? "transparent") !== "transparent") ? 1 : 0

    Behavior on color { ColorAnimation { duration: Theme?.animFast ?? 150 } }
    Behavior on border.color { ColorAnimation { duration: Theme?.animFast ?? 150 } }
    Behavior on implicitWidth { NumberAnimation { duration: Theme?.animFast ?? 150; easing.type: Theme?.animEasing ?? Easing.OutQuad } }

    readonly property int notifCount: NotificationService?.trackedNotifications?.values?.length ?? NotificationService?.trackedNotifications?.count ?? 0

    Row {
        id: notifRow
        anchors.centerIn: parent
        spacing: 4

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: (Settings?.dnd ?? false) ? (Theme?.iconBellOff ?? "󰂛") : (root.notifCount > 0 ? (Theme?.iconBell ?? "󰂚") : (Theme?.iconBellOutline ?? "󰂜"))
            font.family: Theme?.fontIcon ?? "sans-serif"
            font.pixelSize: Theme?.fontSizeMd ?? 14
            color: (Settings?.dnd ?? false) ? Theme.tertiary : (root.notifCount > 0 ? Theme.primary : Theme.on_surface)
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.notifCount > 0
            text: root.notifCount
            font.family: Theme?.fontFamily ?? "sans-serif"
            font.pixelSize: Theme?.fontSizeXs ?? 10
            font.weight: Font.Bold
            color: (Settings?.dnd ?? false) ? Theme.tertiary : Theme.primary
        }
    }

    function togglePopup() {
        if (!popup.open) {
            openPopup();
        } else {
            popup.open = false;
        }
    }

    function openPopup() {
        let pt = root.mapToItem(null, 0, 0);
        if (Theme?.isVertical ?? false) {
            popup.targetRelativeY = pt ? (pt.y + (root.height / 2)) : ((popup.screen?.height ?? 1080) / 2);
        } else {
            popup.targetRelativeX = pt ? (pt.x + (root.width / 2)) : ((popup.screen?.width ?? 1920) / 2);
        }
        popup.open = true;
    }

    function closePopup() {
        popup.open = false;
    }

    Connections {
        target: NotificationService ?? null
        ignoreUnknownSignals: true

        function onToggleRequested() {
            let myScreen = root.QsWindow?.window?.screen;
            let focusedScreenName = Hyprland?.focusedMonitor?.name;
            if (popup.open) {
                popup.open = false;
            } else if (!focusedScreenName || !myScreen || myScreen.name === focusedScreenName) {
                root.openPopup();
            }
        }

        function onOpenRequested() {
            let myScreen = root.QsWindow?.window?.screen;
            let focusedScreenName = Hyprland?.focusedMonitor?.name;
            if (!focusedScreenName || !myScreen || myScreen.name === focusedScreenName) {
                root.openPopup();
            }
        }

        function onCloseRequested() {
            popup.open = false;
        }
    }

    MouseArea {
        id: notifMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.togglePopup()
    }

    PopupPanel {
        id: popup
        cardWidth: 380
        cardHeight: 460
        targetRelativeX: root.x + (root.width / 2)

        content: ColumnLayout {
            anchors.fill: parent
            spacing: Theme?.widgetSpacing ?? 10

            // Header
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: "notifications"
                    font.family: Theme?.fontFamily ?? "sans-serif"
                    font.pixelSize: Theme?.fontSizeLg ?? 16
                    font.weight: Font.Bold
                    color: Theme.on_surface
                }

                // spacer keeps controls pushed to the right
                Item {
                    Layout.fillWidth: true
                }

                // DND Toggle chip
                Rectangle {
                    Layout.preferredHeight: 26
                    Layout.preferredWidth: dndChipRow.implicitWidth + 14
                    radius: Theme?.radiusPill ?? 999
                    color: (Settings?.dnd ?? false) ? Theme.tertiary_container : Theme.surface_container_highest
                    border.color: (Settings?.dnd ?? false) ? Theme.tertiary : "transparent"
                    border.width: 1

                    Behavior on color { ColorAnimation { duration: Theme?.animFast ?? 150 } }

                    RowLayout {
                        id: dndChipRow
                        anchors.centerIn: parent
                        spacing: 4

                        Text {
                            text: (Settings?.dnd ?? false) ? (Theme?.iconBellOff ?? "󰂛") : (Theme?.iconBell ?? "󰂚")
                            font.family: Theme?.fontIcon ?? "sans-serif"
                            font.pixelSize: 11
                            color: (Settings?.dnd ?? false) ? (Theme?.on_tertiary_container ?? "#ffffff") : Theme.on_surface_variant
                        }

                        Text {
                            text: (Settings?.dnd ?? false) ? "dnd on" : "dnd off"
                            font.family: Theme?.fontFamily ?? "sans-serif"
                            font.pixelSize: 10
                            font.weight: Font.Bold
                            color: (Settings?.dnd ?? false) ? (Theme?.on_tertiary_container ?? "#ffffff") : Theme.on_surface_variant
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (Settings) Settings.dnd = !Settings.dnd;
                        }
                    }
                }

                IconButton {
                    icon: Theme?.iconTrash ?? "󰆴"
                    iconSize: Theme?.fontSizeMd ?? 14
                    tooltip: "clear all"
                    visible: root.notifCount > 0
                    onClicked: {
                        if (NotificationService?.clearAll) NotificationService.clearAll();
                    }
                }

                // mouse users can escape without clearing all
                IconButton {
                    icon: Theme?.iconClose ?? "✕"
                    iconSize: Theme?.fontSizeSm ?? 12
                    tooltip: "close panel"
                    onClicked: popup.open = false
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Theme.widgetBorder
            }

            // Notification List & Empty State Container
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                ListView {
                    id: notifListView
                    anchors.fill: parent
                    clip: true
                    spacing: 8
                    boundsBehavior: Flickable.StopAtBounds
                    visible: root.notifCount > 0
                    model: NotificationService?.trackedNotifications

                    delegate: Rectangle {
                        id: notifCard
                        required property var modelData
                        width: notifListView.width
                        implicitHeight: col.implicitHeight + (Theme?.widgetPaddingH ?? 8) * 2
                        color: Theme.surface_container_highest
                        radius: Theme?.widgetRadius ?? Theme?.radiusMd ?? 8

                        ColumnLayout {
                            id: col
                            anchors.fill: parent
                            anchors.margins: Theme?.widgetPaddingH ?? 8
                            spacing: 6

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                Text {
                                    text: modelData?.appName || "Notification"
                                    font.family: Theme?.fontFamily ?? "sans-serif"
                                    font.pixelSize: Theme?.fontSizeXs ?? 10
                                    font.weight: Font.Bold
                                    color: Theme.primary
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                }

                                IconButton {
                                    icon: Theme?.iconClose ?? "✕"
                                    iconSize: Theme?.fontSizeSm ?? 10
                                    Layout.preferredWidth: 20
                                    Layout.preferredHeight: 20
                                    tooltip: "dismiss"
                                    onClicked: {
                                        if (modelData?.dismiss) modelData.dismiss();
                                    }
                                }
                            }

                            Text {
                                text: modelData?.summary ?? ""
                                font.family: Theme?.fontFamily ?? "sans-serif"
                                font.pixelSize: Theme?.fontSizeMd ?? 13
                                font.weight: Font.Medium
                                color: Theme.on_surface
                                Layout.fillWidth: true
                                wrapMode: Text.Wrap
                                visible: text !== ""
                            }

                            Text {
                                text: modelData?.body ?? ""
                                font.family: Theme?.fontFamily ?? "sans-serif"
                                font.pixelSize: Theme?.fontSizeSm ?? 11
                                color: Theme.on_surface_variant
                                Layout.fillWidth: true
                                wrapMode: Text.Wrap
                                visible: text !== ""
                            }

                            // Actions
                            RowLayout {
                                Layout.fillWidth: true
                                visible: (modelData?.actions?.length ?? 0) > 0
                                spacing: 6

                                Repeater {
                                    model: modelData?.actions ?? []

                                    delegate: Rectangle {
                                        required property var modelData
                                        Layout.fillWidth: true
                                        Layout.preferredWidth: 1
                                        Layout.preferredHeight: 28
                                        radius: Theme?.radiusSm ?? 6
                                        color: actMouse.containsMouse ? Theme.primary_overlay : (Theme?.surface_variant ?? Theme.surface_container_high)

                                        Behavior on color { ColorAnimation { duration: Theme?.animFast ?? 150 } }

                                        Text {
                                            anchors.fill: parent
                                            anchors.margins: 4
                                            text: modelData?.text ?? ""
                                            font.family: Theme?.fontFamily ?? "sans-serif"
                                            font.pixelSize: Theme?.fontSizeSm ?? 11
                                            color: Theme.on_surface
                                            horizontalAlignment: Text.AlignHCenter
                                            verticalAlignment: Text.AlignVCenter
                                            elide: Text.ElideRight
                                        }

                                        MouseArea {
                                            id: actMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                if (modelData?.invoke) modelData.invoke();
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                Item {
                    anchors.fill: parent
                    visible: root.notifCount === 0

                    Text {
                        text: (Settings?.dnd ?? false)
                            ? ((Theme?.iconBellOff ?? "󰂛") + "\n" + (Theme?.getFlavor ? Theme.getFlavor("dnd_on", "do not disturb active") : "do not disturb active"))
                            : ((Theme?.getVibe ? Theme.getVibe(Theme?.kaoSleepy + "\n", (Theme?.iconBellOutline ?? "󰂚") + "\n", "") : "") + (Theme?.getFlavor ? Theme.getFlavor("notifs_empty", "all caught up") : "all caught up"))
                        font.family: Theme?.fontFamily ?? "sans-serif"
                        font.pixelSize: Theme?.fontSizeMd ?? 13
                        color: Theme.on_surface_variant
                        horizontalAlignment: Text.AlignHCenter
                        anchors.centerIn: parent
                        lineHeight: 1.5
                    }
                }
            }
        }
    }
}