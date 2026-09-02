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

    readonly property string pos: Settings?.barPosition ?? "up"
    readonly property bool isTop: pos === "up" || pos === "top"
    readonly property bool isCritical: (notifData?.urgency ?? 1) === NotificationUrgency.Critical
    readonly property bool hasTimer: (notifData?.expireTimeout ?? 5000) > 0 && !isCritical
    readonly property int timeoutMs: notifData?.expireTimeout > 0 ? notifData.expireTimeout : 5000

    width: 360
    implicitHeight: cardBody.height
    height: implicitHeight

    property real morphProgress: 0.0

    ParallelAnimation {
        id: morphAnim
        NumberAnimation {
            target: cardRoot
            property: "morphProgress"
            from: 0.0
            to: 1.0
            duration: 180
            easing.type: Easing.OutCubic
        }
    }

    ParallelAnimation {
        id: dismissAnim
        NumberAnimation { target: cardRoot; property: "morphProgress"; to: 0.0; duration: 140; easing.type: Easing.InCubic }
        onFinished: {
            // telling dbus we killed it so the client app stops waiting
            if (cardRoot.notifData?.notifRef?.dismiss) {
                cardRoot.notifData.notifRef.dismiss();
            }
            cardRoot.closed();
        }
    }

    Component.onCompleted: {
        morphAnim.restart();
        if (hasTimer) progressAnim.start();
    }

    function dismiss() {
        if (!dismissAnim.running) dismissAnim.start();
    }

    // physical card body
    Rectangle {
        id: cardBody
        anchors.horizontalCenter: parent.horizontalCenter
        width: 360
        height: Math.max(1, cardRoot.morphProgress * (contentLayout.implicitHeight + 24 + (cardRoot.hasTimer ? 3 : 0)))
        radius: Theme.popupRadius ?? 16
        color: cardRoot.isCritical ? Theme.error_container : Theme.popupBg
        clip: true

        border.color: cardRoot.isCritical ? Theme.error : (isHovered ? Theme.primary : Theme.popupBorderColor)
        border.width: cardRoot.isCritical ? 2 : 1

        Behavior on border.color { ColorAnimation { duration: Theme.animFast } }

        // persistent hover so child buttons don't resume timer
        readonly property bool isHovered: cardMouse.containsMouse || closeMouse.containsMouse

        onIsHoveredChanged: {
            if (!cardRoot.hasTimer) return;
            if (isHovered && progressAnim.running) {
                progressAnim.pause();
            } else if (!isHovered && progressAnim.paused) {
                progressAnim.resume();
            }
        }

        MouseArea {
            id: cardMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor

            onClicked: {
                // invoke default dbus action on card click
                const acts = notifData?.notifRef?.actions ?? notifData?.actions;
                if (acts) {
                    const count = acts.count ?? acts.length ?? 0;
                    for (let i = 0; i < count; i++) {
                        const act = acts.get ? acts.get(i) : acts[i];
                        if (act && (act.id === "default" || act.id === "0")) {
                            act.invoke();
                            break;
                        }
                    }
                }
                cardRoot.dismiss();
            }
        }

        // unrolling inner content without visual seizures
        Item {
            width: cardBody.width
            height: contentLayout.implicitHeight + 24
            y: cardRoot.isTop ? (cardRoot.morphProgress - 1.0) * 16 : (1.0 - cardRoot.morphProgress) * 16
            opacity: Math.max(0.0, (cardRoot.morphProgress - 0.2) / 0.8)

            ColumnLayout {
                id: contentLayout
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: 12
                spacing: 8

                // header row
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Rectangle {
                        Layout.preferredWidth: 24
                        Layout.preferredHeight: 24
                        radius: Theme.radiusSm ?? 6
                        color: cardRoot.isCritical ? Theme.error : Theme.surface_container_high

                        IconImage {
                            id: appIconImg
                            anchors.centerIn: parent
                            width: 16
                            height: 16
                            source: {
                                let ic = notifData?.icon || notifData?.appIcon || "";
                                return (ic && ic.trim() !== "") ? Quickshell.iconPath(ic, "") : "";
                            }
                            visible: status === Image.Ready && source !== ""
                        }

                        Text {
                            anchors.centerIn: parent
                            text: cardRoot.isCritical ? "󰅚" : Theme.iconBell
                            font.family: Theme.fontMono
                            font.pixelSize: 12
                            color: cardRoot.isCritical ? Theme.on_error : Theme.primary
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
                        id: closeBtn
                        Layout.preferredWidth: 22
                        Layout.preferredHeight: 22
                        radius: 11
                        color: closeMouse.containsMouse ? Theme.surface_variant : "transparent"

                        Text {
                            anchors.centerIn: parent
                            text: Theme.iconClose
                            font.family: Theme.fontIcon
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

                // summary / title
                Text {
                    text: notifData?.summary ?? ""
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeMd
                    font.weight: Font.Bold
                    textFormat: Text.StyledText
                    color: cardRoot.isCritical ? Theme.on_error_container : Theme.on_surface
                    Layout.fillWidth: true
                    wrapMode: Text.Wrap
                    visible: text !== ""
                }

                // rich attachment preview
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 130
                    radius: Theme.radiusMd ?? 8
                    color: Theme.surface_container_highest
                    clip: true
                    visible: notifData?.image !== undefined && notifData?.image !== ""

                    Image {
                        anchors.fill: parent
                        source: notifData?.image ? (notifData.image.startsWith("/") ? ("file://" + notifData.image) : notifData.image) : ""
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                    }
                }

                // body text
                Text {
                    text: notifData?.body ?? ""
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSm
                    textFormat: Text.StyledText
                    color: cardRoot.isCritical ? Theme.on_error_container : Theme.on_surface_variant
                    Layout.fillWidth: true
                    wrapMode: Text.Wrap
                    maximumLineCount: 6
                    elide: Text.ElideRight
                    visible: text !== ""
                }

                // action buttons (safe extraction for both raw arrays and QQmlListModel)
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6
                    visible: filteredActions.length > 0

                    // extracting actions before qt listmodel throws another tantrum
                    readonly property var filteredActions: {
                        const acts = cardRoot.notifData?.notifRef?.actions ?? cardRoot.notifData?.actions;
                        if (!acts) return [];

                        const result = [];
                        const count = acts.count ?? acts.length ?? 0;
                        for (let i = 0; i < count; i++) {
                            const act = acts.get ? acts.get(i) : acts[i];
                            if (act && act.id !== "default" && act.id !== "0") {
                                result.push(act);
                            }
                        }
                        return result;
                    }

                    Repeater {
                        model: parent.filteredActions

                        delegate: Rectangle {
                            required property var modelData
                            Layout.fillWidth: true
                            height: 28
                            radius: Theme.radiusPill ?? 14
                            color: actBtnMouse.containsMouse ? Theme.primary : Theme.surface_container_high

                            Behavior on color { ColorAnimation { duration: Theme.animFast } }

                            Text {
                                text: modelData.text || modelData.id
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeXs
                                font.weight: Font.Medium
                                color: actBtnMouse.containsMouse ? Theme.on_primary : Theme.on_surface
                                anchors.centerIn: parent
                                elide: Text.ElideRight
                            }

                            MouseArea {
                                id: actBtnMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    modelData.invoke();
                                    cardRoot.dismiss();
                                }
                            }
                        }
                    }
                }
            }
        }

        // countdown timer bar
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
                from: 360
                to: 0
                duration: cardRoot.timeoutMs
                onFinished: cardRoot.dismiss()
            }
        }
    }
}