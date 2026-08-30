import QtQuick
import QtQuick.Layouts
import ".."
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications

Item {
    id: cardRoot

    property var notifData: null
    property int cardIndex: 0
    signal closed()

    readonly property bool isTop: (Settings?.barPosition ?? "top") === "top"
    readonly property bool isVertical: Theme?.isVertical ?? false
    readonly property bool isCritical: (notifData?.urgency ?? 1) === NotificationUrgency.Critical
    readonly property bool hasTimer: (notifData?.expireTimeout ?? 5000) > 0 && !isCritical
    readonly property int timeoutMs: notifData?.expireTimeout > 0 ? notifData.expireTimeout : 5000
    readonly property real scoopW: Theme?.scoopRadiusX ?? 16
    readonly property real scoopH: Theme?.scoopRadiusY ?? 16
    readonly property bool isWeldedToBar: cardIndex === 0 && !isVertical

    width: 360 + (scoopW * 2)
    implicitHeight: cardBody.height

    property real morphProgress: 0.0

    ParallelAnimation {
        id: morphAnim
        NumberAnimation {
            target: cardRoot
            property: "morphProgress"
            from: 0.0
            to: 1.0
            duration: 260
            easing.type: Easing.OutCubic
        }
    }

    ParallelAnimation {
        id: dismissAnim
        NumberAnimation { target: cardRoot; property: "morphProgress"; to: 0.0; duration: 180; easing.type: Easing.InCubic }
        onFinished: {
            cardRoot.closed()
        }
    }

    Component.onCompleted: {
        morphAnim.restart()
        if (hasTimer) {
            progressAnim.start()
        }
    }

    function dismiss() {
        if (!dismissAnim.running) {
            dismissAnim.start()
        }
    }

    // left weld scoop into the status bar
    ConcaveCorner {
        x: cardBody.x - cardRoot.scoopW
        y: cardRoot.isTop ? 0 : cardBody.height - cardRoot.scoopH
        fillColor: cardRoot.isCritical ? Theme.error_container : Theme.surface_container_low
        flipX: true
        flipY: !cardRoot.isTop
        opacity: Math.min(1.0, cardRoot.morphProgress * 3.5)
        visible: cardRoot.isWeldedToBar
    }

    // right weld scoop into the status bar
    ConcaveCorner {
        x: cardBody.x + cardBody.width
        y: cardRoot.isTop ? 0 : cardBody.height - cardRoot.scoopH
        fillColor: cardRoot.isCritical ? Theme.error_container : Theme.surface_container_low
        flipX: false
        flipY: !cardRoot.isTop
        opacity: Math.min(1.0, cardRoot.morphProgress * 3.5)
        visible: cardRoot.isWeldedToBar
    }

    // physical expanding card body
    Rectangle {
        id: cardBody
        x: cardRoot.scoopW
        y: 0
        width: 360
        height: Math.max(1, cardRoot.morphProgress * (contentLayout.implicitHeight + 24 + (cardRoot.hasTimer ? 2 : 0)))
        color: cardRoot.isCritical ? Theme.error_container : Theme.surface_container_low
        clip: true

        // seamless weld with bar edge on top card, rounded pill/box for secondary cards
        topLeftRadius: (cardRoot.isWeldedToBar && cardRoot.isTop) ? 0 : Theme.popupRadius
        topRightRadius: (cardRoot.isWeldedToBar && cardRoot.isTop) ? 0 : Theme.popupRadius
        bottomLeftRadius: (cardRoot.isWeldedToBar && !cardRoot.isTop) ? 0 : Theme.popupRadius
        bottomRightRadius: (cardRoot.isWeldedToBar && !cardRoot.isTop) ? 0 : Theme.popupRadius

        border.color: cardRoot.isCritical ? Theme.error : (cardMouse.containsMouse ? Theme.primary : Theme.widgetBorder)
        border.width: 1

        Behavior on border.color { ColorAnimation { duration: Theme.animFast } }

        MouseArea {
            id: cardMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor

            onEntered: {
                if (cardRoot.hasTimer && progressAnim.running) progressAnim.pause()
            }
            onExited: {
                if (cardRoot.hasTimer && progressAnim.paused) progressAnim.resume()
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
                cardRoot.dismiss()
            }
        }

        // unrolling inner content with parallax translate
        Item {
            width: cardBody.width
            height: contentLayout.implicitHeight + 24
            y: cardRoot.isTop ? (cardRoot.morphProgress - 1.0) * 18 : (1.0 - cardRoot.morphProgress) * 18
            opacity: Math.max(0.0, (cardRoot.morphProgress - 0.2) / 0.8)

            ColumnLayout {
                id: contentLayout
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: 12
                spacing: 6

                // Header
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Rectangle {
                        Layout.preferredWidth: 22
                        Layout.preferredHeight: 22
                        radius: Theme.radiusSm
                        color: Theme.surface_container_high

                        IconImage {
                            id: appIconImg
                            anchors.centerIn: parent
                            width: 14
                            height: 14
                            source: {
                                let ic = notifData?.icon || notifData?.appIcon || ""
                                return (ic && ic.trim() !== "") ? Quickshell.iconPath(ic, "") : ""
                            }
                            visible: status === Image.Ready && source !== ""
                        }

                        Text {
                            anchors.centerIn: parent
                            text: cardRoot.isCritical ? "󰅚" : Theme.iconBell
                            font.family: Theme.fontMono
                            font.pixelSize: 11
                            color: cardRoot.isCritical ? Theme.error : Theme.primary
                            visible: !appIconImg.visible
                        }
                    }

                    Text {
                        text: (notifData?.appName || "system").toLowerCase()
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeXs
                        font.weight: Font.Bold
                        color: cardRoot.isCritical ? Theme.on_error_container : Theme.primary
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
                            onClicked: cardRoot.dismiss()
                        }
                    }
                }

                // Summary / Title
                Text {
                    text: notifData?.summary ?? ""
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeMd
                    font.weight: Font.Bold
                    color: cardRoot.isCritical ? Theme.on_error_container : Theme.on_surface
                    Layout.fillWidth: true
                    wrapMode: Text.Wrap
                    visible: text !== ""
                }

                // Body text
                Text {
                    text: notifData?.body ?? ""
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSm
                    color: cardRoot.isCritical ? Theme.on_error_container : Theme.on_surface_variant
                    Layout.fillWidth: true
                    wrapMode: Text.Wrap
                    maximumLineCount: 6
                    elide: Text.ElideRight
                    visible: text !== ""
                }

                // Action buttons
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
                            radius: Theme.radiusPill
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
                                    cardRoot.dismiss()
                                }
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
            color: cardRoot.isCritical ? Theme.error : Theme.primary
            visible: cardRoot.hasTimer

            NumberAnimation {
                id: progressAnim
                target: progressBar
                property: "width"
                from: cardBody.width
                to: 0
                duration: cardRoot.timeoutMs
                onFinished: cardRoot.dismiss()
            }
        }
    }
}
