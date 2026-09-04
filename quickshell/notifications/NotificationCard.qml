import QtQuick
import QtQuick.Layouts
import ".."
import "../controls"
import Quickshell
import Quickshell.Widgets

Rectangle {
    id: root

    required property var notificationItem
    readonly property var notif: notificationItem
    signal dismissed()

    property int timeoutMs: {
        if (!notif) return 5000;
        if (notif.expireTimeout > 0) return notif.expireTimeout;
        if (notif.expireTimeout === 0) return 0;
        return notif.urgency === 2 ? 10000 : 5000;
    }

    property bool dockTop: false
    property bool dockBottom: false
    property bool dockLeft: false
    property bool dockRight: false

    width: 360
    implicitHeight: col.implicitHeight + 24
    readonly property real defaultRadius: Theme?.widgetRadius ?? 14
    topLeftRadius: (dockTop || dockLeft) ? 0 : defaultRadius
    topRightRadius: (dockTop || dockRight) ? 0 : defaultRadius
    bottomLeftRadius: (dockBottom || dockLeft) ? 0 : defaultRadius
    bottomRightRadius: (dockBottom || dockRight) ? 0 : defaultRadius
    color: Theme?.popupBg ?? Theme?.surface ?? "#1e1e2e"
    border.color: notif?.urgency === 2 ? Theme.error : (Theme?.widgetBorder ?? "#33ffffff")
    border.width: 1
    clip: true

    // safely resolve icon path to prevent qrc missing-icon warnings
    readonly property string resolvedIcon: {
        if (!root.notif?.appIcon) return "";
        let path = Quickshell.iconPath(root.notif.appIcon);
        return path || "";
    }

    // dynamic slide & fade entrance/exit
    property real slideOffset: 80
    property real cardOpacity: 0.0

    transform: Translate {
        x: root.slideOffset
    }
    opacity: root.cardOpacity

    Component.onCompleted: {
        enterAnim.restart();
    }

    ParallelAnimation {
        id: enterAnim
        NumberAnimation {
            target: root
            property: "slideOffset"
            from: 80
            to: 0
            duration: 240
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: root
            property: "cardOpacity"
            from: 0.0
            to: 1.0
            duration: 200
            easing.type: Easing.OutCubic
        }
    }

    ParallelAnimation {
        id: exitAnim
        NumberAnimation {
            target: root
            property: "slideOffset"
            to: 80
            duration: 180
            easing.type: Easing.InCubic
        }
        NumberAnimation {
            target: root
            property: "cardOpacity"
            to: 0.0
            duration: 150
            easing.type: Easing.InCubic
        }
        onFinished: root.dismissed()
    }

    function dismissToast() {
        progressTimer.stop();
        exitAnim.restart();
    }

    readonly property bool isHovered: cardMouse.containsMouse

    // elapsed timer avoids setPaused() warnings on NumberAnimation
    property real elapsedMs: 0
    readonly property real progressRatio: root.timeoutMs > 0 ? Math.max(0.0, 1.0 - (elapsedMs / root.timeoutMs)) : 1.0

    Timer {
        id: progressTimer
        interval: 40
        repeat: true
        running: root.timeoutMs > 0 && !root.isHovered
        onTriggered: {
            root.elapsedMs += 40;
            if (root.elapsedMs >= root.timeoutMs) {
                root.dismissToast();
            }
        }
    }

    MouseArea {
        id: cardMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.ArrowCursor
    }

    ColumnLayout {
        id: col
        anchors.fill: parent
        anchors.margins: 14
        anchors.bottomMargin: root.timeoutMs > 0 ? 18 : 14
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Rectangle {
                Layout.preferredWidth: 22
                Layout.preferredHeight: 22
                radius: Theme?.radiusSm ?? 6
                color: Theme?.surface_container_highest ?? "#2a2a3c"
                clip: true

                IconImage {
                    id: notifIconImg
                    anchors.centerIn: parent
                    width: 16
                    height: 16
                    source: root.resolvedIcon
                    visible: root.resolvedIcon !== "" && notifIconImg.status !== Image.Error
                }

                Text {
                    anchors.centerIn: parent
                    visible: root.resolvedIcon === "" || notifIconImg.status === Image.Error
                    text: Theme?.iconBell ?? "󰂚"
                    font.family: Theme?.fontIcon ?? Theme?.fontMono
                    font.pixelSize: 12
                    color: Theme?.primary ?? "#89b4fa"
                }
            }

            Text {
                text: (root.notif?.appName || "system").toLowerCase()
                font.family: Theme?.fontFamily ?? "sans-serif"
                font.pixelSize: Theme?.fontSizeXs ?? 11
                font.weight: Font.Bold
                color: Theme?.primary ?? "#89b4fa"
                Layout.fillWidth: true
                elide: Text.ElideRight
            }

            IconButton {
                icon: Theme?.iconClose ?? "󰅖"
                iconSize: 12
                Layout.preferredWidth: 20
                Layout.preferredHeight: 20
                tooltip: "dismiss"
                onClicked: {
                    root.dismissToast();
                    if (root.notif && typeof root.notif.dismiss === "function") {
                        try { root.notif.dismiss(); } catch (e) {}
                    }
                }
            }
        }

        Text {
            text: root.notif?.summary ?? ""
            font.family: Theme?.fontFamily ?? "sans-serif"
            font.pixelSize: Theme?.fontSizeMd ?? 14
            font.weight: Font.DemiBold
            color: Theme?.on_surface ?? "#cdd6f4"
            Layout.fillWidth: true
            wrapMode: Text.Wrap
            visible: text !== ""
        }

        Text {
            text: root.notif?.body ?? ""
            font.family: Theme?.fontFamily ?? "sans-serif"
            font.pixelSize: Theme?.fontSizeSm ?? 12
            color: Theme?.on_surface_variant ?? "#a6adc8"
            Layout.fillWidth: true
            wrapMode: Text.Wrap
            textFormat: Text.AutoText
            visible: text !== ""
            maximumLineCount: 6
            elide: Text.ElideRight
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 120
            radius: Theme?.radiusSm ?? 6
            color: "transparent"
            clip: true
            visible: Boolean(root.notif?.image)

            Image {
                anchors.fill: parent
                source: root.notif?.image ?? ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 6
            visible: Boolean(root.notif?.actions && root.notif.actions.length > 0)

            Repeater {
                model: root.notif?.actions ?? []

                delegate: Rectangle {
                    required property var modelData
                    Layout.fillWidth: true
                    height: 28
                    radius: Theme?.radiusSm ?? 6
                    color: actMouse.containsMouse ? Theme.primary_overlay : Theme.surface_container_highest
                    border.color: Theme?.widgetBorder ?? "#33ffffff"
                    border.width: 1

                    Behavior on color { ColorAnimation { duration: Theme?.animFast ?? 120 } }

                    Text {
                        anchors.centerIn: parent
                        text: (modelData.text || modelData.id || "action").toLowerCase()
                        font.family: Theme?.fontFamily ?? "sans-serif"
                        font.pixelSize: Theme?.fontSizeXs ?? 11
                        font.weight: Font.Medium
                        color: actMouse.containsMouse ? Theme.primary : Theme.on_surface
                        elide: Text.ElideRight
                        width: parent.width - 12
                        horizontalAlignment: Text.AlignHCenter
                    }

                    MouseArea {
                        id: actMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (modelData && typeof modelData.invoke === "function") {
                                modelData.invoke();
                            }
                            root.dismissToast();
                        }
                    }
                }
            }
        }
    }

    Rectangle {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: 3
        color: Theme?.surface_container_highest ?? "#2a2a3c"
        visible: root.timeoutMs > 0

        Rectangle {
            id: progressBar
            height: parent.height
            color: notif?.urgency === 2 ? Theme.error : Theme.primary
            width: parent.width * root.progressRatio
        }
    }
}
