import QtQuick
import QtQuick.Layouts
import ".."
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications

Rectangle {
    id: card

    property var notifData: null
    signal closed()

    // 360px wide so text doesn't look like a phone text message from 2004
    width: 360
    implicitHeight: mainCol.implicitHeight + (hasTimer ? 2 : 0)
    radius: Theme.radiusMd
    color: Theme.surface_container_low
    clip: true

    readonly property bool isCritical: (notifData?.urgency ?? 1) === NotificationUrgency.Critical
    readonly property bool hasTimer: (notifData?.expireTimeout ?? 5000) > 0 && !isCritical
    readonly property int timeoutMs: notifData?.expireTimeout > 0 ? notifData.expireTimeout : 5000

    border.color: isCritical ? Theme.error : (cardMouse.containsMouse ? Theme.primary : Theme.widgetBorder)
    border.width: 1

    Behavior on border.color { ColorAnimation { duration: Theme.animFast } }

    // slide in animation so it doesn't pop in like a flashbang
    opacity: 0.0
    scale: 0.96
    transformOrigin: Item.TopRight

    Component.onCompleted: {
        slideInAnim.start()
        if (hasTimer) {
            progressAnim.start()
        }
    }

    ParallelAnimation {
        id: slideInAnim
        NumberAnimation { target: card; property: "opacity"; to: 1.0; duration: Theme.animNormal; easing.type: Easing.OutCubic }
        NumberAnimation { target: card; property: "scale"; to: 1.0; duration: Theme.animNormal; easing.type: Easing.OutCubic }
    }

    ParallelAnimation {
        id: dismissAnim
        NumberAnimation { target: card; property: "opacity"; to: 0.0; duration: Theme.animFast; easing.type: Easing.InCubic }
        NumberAnimation { target: card; property: "scale"; to: 0.92; duration: Theme.animFast; easing.type: Easing.InCubic }
        onFinished: {
            card.closed()
        }
    }

    function dismiss() {
        if (!dismissAnim.running) {
            dismissAnim.start()
        }
    }

    MouseArea {
        id: cardMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onEntered: {
            if (hasTimer && progressAnim.running) progressAnim.pause()
        }
        onExited: {
            if (hasTimer && progressAnim.paused) progressAnim.resume()
        }
        onClicked: {
            if (notifData?.actions) {
                for (let i = 0; i < notifData.actions.length; i++) {
                    let act = notifData.actions[i]
                    if (act && (act.id === "default" || act.id === "0")) {
                        act.invoke()
                        break
                    }
                }
            }
            card.dismiss()
        }
    }

    ColumnLayout {
        id: mainCol
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 12
        spacing: 8

        // Header: app icon + app name + close button
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Rectangle {
                Layout.preferredWidth: 20
                Layout.preferredHeight: 20
                radius: 4
                color: Theme.surface_container_high

                IconImage {
                    anchors.centerIn: parent
                    width: 14
                    height: 14
                    source: Quickshell.iconPath(notifData?.icon || notifData?.appName || "", "dialog-information")
                }
            }

            Text {
                text: (notifData?.appName || "system").toLowerCase()
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeXs
                font.weight: Font.Bold
                color: card.isCritical ? Theme.error : Theme.primary
                Layout.fillWidth: true
                elide: Text.ElideRight
            }

            Rectangle {
                Layout.preferredWidth: 20
                Layout.preferredHeight: 20
                radius: 10
                color: closeMouse.containsMouse ? Theme.surface_variant : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: Theme.iconClose
                    font.family: Theme.fontMono
                    font.pixelSize: 10
                    color: Theme.on_surface_variant
                }

                MouseArea {
                    id: closeMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: card.dismiss()
                }
            }
        }

        // Summary / Title
        Text {
            text: notifData?.summary ?? ""
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeMd
            font.weight: Font.Bold
            color: Theme.on_surface
            Layout.fillWidth: true
            wrapMode: Text.Wrap
            visible: text !== ""
        }

        // Body text
        Text {
            text: notifData?.body ?? ""
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeSm
            color: Theme.on_surface_variant
            Layout.fillWidth: true
            wrapMode: Text.Wrap
            maximumLineCount: 6
            elide: Text.ElideRight
            visible: text !== ""
        }

        // Action Buttons Row
        RowLayout {
            Layout.fillWidth: true
            spacing: 6
            visible: (notifData?.actions?.length ?? 0) > 0

            Repeater {
                model: notifData?.actions ?? []

                delegate: Rectangle {
                    required property var modelData
                    Layout.fillWidth: true
                    height: 26
                    radius: Theme.radiusSm
                    color: btnMouse.containsMouse ? Theme.primary : Theme.surface_container_high

                    Behavior on color { ColorAnimation { duration: Theme.animFast } }

                    Text {
                        text: modelData.text || modelData.id
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeXs
                        font.weight: Font.Medium
                        color: btnMouse.containsMouse ? Theme.on_primary : Theme.on_surface
                        anchors.centerIn: parent
                        elide: Text.ElideRight
                    }

                    MouseArea {
                        id: btnMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            modelData.invoke()
                            card.dismiss()
                        }
                    }
                }
            }
        }
    }

    // Auto-dismiss countdown bar at the bottom edge
    Rectangle {
        id: progressBar
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        height: 2
        color: card.isCritical ? Theme.error : Theme.primary
        visible: card.hasTimer

        NumberAnimation {
            id: progressAnim
            target: progressBar
            property: "width"
            from: card.width
            to: 0
            duration: card.timeoutMs
            onFinished: card.dismiss()
        }
    }
}
