import QtQuick
import QtQuick.Layouts
import ".."
import "../controls"
import "../corners"
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
        return notif.urgency === 2 ? 10000 : (Settings?.notificationTimeout ?? 5000);
    }

    property bool dockTop: (Settings?.barPosition ?? "top") === "top" || (Settings?.barPosition ?? "top") === "up"
    property bool dockBottom: (Settings?.barPosition ?? "top") === "bottom" || (Settings?.barPosition ?? "top") === "down"
    property bool dockLeft: (Settings?.barPosition ?? "top") === "left"
    property bool dockRight: (Settings?.barPosition ?? "top") === "right"

    readonly property string notifEdge: Settings?.notificationEdge ?? "right"
    readonly property bool isEdgeRight: notifEdge === "right"
    readonly property bool isEdgeLeft: notifEdge === "left"
    readonly property bool isEdgeTop: notifEdge === "top"
    readonly property bool isEdgeBottom: notifEdge === "bottom"

    readonly property bool isConcave: (Settings?.notificationCornerStyle ?? "concave") === "concave"
    readonly property real scoopR: Math.min(18, Math.max(8, Theme?.scoopRadiusX ?? 14))
    readonly property color cardBg: Theme?.popupBg ?? Theme?.surface ?? "#1e1e2e"
    readonly property color cardBorderColor: notif?.urgency === 2 ? Theme.error : (Theme?.popupBorderColor ?? Theme?.widgetBorder ?? "#33ffffff")
    readonly property real cardBorderWidth: Theme?.popupBorderWidth ?? 1

    width: 360
    implicitHeight: col.implicitHeight + (col.anchors.topMargin ?? 14) + (col.anchors.bottomMargin ?? 18)
    height: implicitHeight
    Layout.preferredHeight: implicitHeight
    readonly property real defaultRadius: Theme?.popupRadius ?? Theme?.radiusMd ?? 14
    radius: !isConcave ? defaultRadius : 0
    topLeftRadius: !isConcave ? defaultRadius : (isEdgeRight || isEdgeBottom ? defaultRadius : 0)
    bottomLeftRadius: !isConcave ? defaultRadius : (isEdgeRight || isEdgeTop ? defaultRadius : 0)
    topRightRadius: !isConcave ? defaultRadius : (isEdgeLeft || isEdgeBottom ? defaultRadius : 0)
    bottomRightRadius: !isConcave ? defaultRadius : (isEdgeLeft || isEdgeTop ? defaultRadius : 0)
    color: cardBg
    border.color: cardBorderColor
    border.width: cardBorderWidth
    clip: false

    // Concave flares melting into the screen bezel
    ConcaveCorner {
        id: flareTopRight
        visible: root.isConcave && root.isEdgeRight
        width: root.scoopR
        height: root.scoopR
        x: root.width - width
        y: -height + 1
        radius: root.scoopR
        radiusX: root.scoopR
        radiusY: root.scoopR
        fillColor: root.cardBg
        cornerStyle: Settings?.cornerStyle ?? "continuous-bezier"
        flipX: true
        flipY: true
        showBorder: root.cardBorderWidth > 0
        borderWidth: root.cardBorderWidth
        borderColor: root.cardBorderColor
    }

    ConcaveCorner {
        id: flareBottomRight
        visible: root.isConcave && root.isEdgeRight
        width: root.scoopR
        height: root.scoopR
        x: root.width - width
        y: root.height - 1
        radius: root.scoopR
        radiusX: root.scoopR
        radiusY: root.scoopR
        fillColor: root.cardBg
        cornerStyle: Settings?.cornerStyle ?? "continuous-bezier"
        flipX: true
        flipY: false
        showBorder: root.cardBorderWidth > 0
        borderWidth: root.cardBorderWidth
        borderColor: root.cardBorderColor
    }

    ConcaveCorner {
        id: flareTopLeft
        visible: root.isConcave && root.isEdgeLeft
        width: root.scoopR
        height: root.scoopR
        x: 0
        y: -height + 1
        radius: root.scoopR
        radiusX: root.scoopR
        radiusY: root.scoopR
        fillColor: root.cardBg
        cornerStyle: Settings?.cornerStyle ?? "continuous-bezier"
        flipX: false
        flipY: true
        showBorder: root.cardBorderWidth > 0
        borderWidth: root.cardBorderWidth
        borderColor: root.cardBorderColor
    }

    ConcaveCorner {
        id: flareBottomLeft
        visible: root.isConcave && root.isEdgeLeft
        width: root.scoopR
        height: root.scoopR
        x: 0
        y: root.height - 1
        radius: root.scoopR
        radiusX: root.scoopR
        radiusY: root.scoopR
        fillColor: root.cardBg
        cornerStyle: Settings?.cornerStyle ?? "continuous-bezier"
        flipX: false
        flipY: false
        showBorder: root.cardBorderWidth > 0
        borderWidth: root.cardBorderWidth
        borderColor: root.cardBorderColor
    }

    ConcaveCorner {
        id: flareTopEdgeL
        visible: root.isConcave && root.isEdgeTop
        width: root.scoopR
        height: root.scoopR
        x: -width + 1
        y: 0
        radius: root.scoopR
        radiusX: root.scoopR
        radiusY: root.scoopR
        fillColor: root.cardBg
        cornerStyle: Settings?.cornerStyle ?? "continuous-bezier"
        flipX: true
        flipY: false
        showBorder: root.cardBorderWidth > 0
        borderWidth: root.cardBorderWidth
        borderColor: root.cardBorderColor
    }

    ConcaveCorner {
        id: flareTopEdgeR
        visible: root.isConcave && root.isEdgeTop
        width: root.scoopR
        height: root.scoopR
        x: root.width - 1
        y: 0
        radius: root.scoopR
        radiusX: root.scoopR
        radiusY: root.scoopR
        fillColor: root.cardBg
        cornerStyle: Settings?.cornerStyle ?? "continuous-bezier"
        flipX: false
        flipY: false
        showBorder: root.cardBorderWidth > 0
        borderWidth: root.cardBorderWidth
        borderColor: root.cardBorderColor
    }

    ConcaveCorner {
        id: flareBottomEdgeL
        visible: root.isConcave && root.isEdgeBottom
        width: root.scoopR
        height: root.scoopR
        x: -width + 1
        y: root.height - height
        radius: root.scoopR
        radiusX: root.scoopR
        radiusY: root.scoopR
        fillColor: root.cardBg
        cornerStyle: Settings?.cornerStyle ?? "continuous-bezier"
        flipX: true
        flipY: true
        showBorder: root.cardBorderWidth > 0
        borderWidth: root.cardBorderWidth
        borderColor: root.cardBorderColor
    }

    ConcaveCorner {
        id: flareBottomEdgeR
        visible: root.isConcave && root.isEdgeBottom
        width: root.scoopR
        height: root.scoopR
        x: root.width - 1
        y: root.height - height
        radius: root.scoopR
        radiusX: root.scoopR
        radiusY: root.scoopR
        fillColor: root.cardBg
        cornerStyle: Settings?.cornerStyle ?? "continuous-bezier"
        flipX: false
        flipY: true
        showBorder: root.cardBorderWidth > 0
        borderWidth: root.cardBorderWidth
        borderColor: root.cardBorderColor
    }

    // safely resolve icon path to prevent qrc missing-icon warnings
    readonly property string resolvedIcon: {
        if (!root.notif?.appIcon) return "";
        let path = Quickshell.iconPath(root.notif.appIcon);
        return path || "";
    }

    // dynamic slide & fade entrance/exit
    readonly property real slideDistance: 120
    readonly property real ingressOffsetX: isEdgeLeft ? -slideDistance : (isEdgeRight ? slideDistance : 0)
    readonly property real ingressOffsetY: isEdgeTop ? -slideDistance : (isEdgeBottom ? slideDistance : 0)

    property real slideOffsetX: root.ingressOffsetX
    property real slideOffsetY: root.ingressOffsetY
    property real cardOpacity: 0.0

    transform: Translate {
        x: root.slideOffsetX
        y: root.slideOffsetY
    }
    opacity: root.cardOpacity

    Component.onCompleted: {
        console.log("NotifCard debug: isConcave=" + isConcave + " isEdgeRight=" + isEdgeRight + " scoopR=" + scoopR);
        enterAnim.restart();
    }

    ParallelAnimation {
        id: enterAnim
        NumberAnimation {
            target: root
            property: "slideOffsetX"
            from: root.ingressOffsetX
            to: 0
            duration: Theme?.animNormal ?? 200
            easing.type: Theme?.animEasing ?? Easing.OutCubic
        }
        NumberAnimation {
            target: root
            property: "slideOffsetY"
            from: root.ingressOffsetY
            to: 0
            duration: Theme?.animNormal ?? 200
            easing.type: Theme?.animEasing ?? Easing.OutCubic
        }
        NumberAnimation {
            target: root
            property: "cardOpacity"
            from: 0.0
            to: 1.0
            duration: Theme?.animFast ?? 120
            easing.type: Theme?.animEasing ?? Easing.OutCubic
        }
    }

    ParallelAnimation {
        id: exitAnim
        NumberAnimation {
            target: root
            property: "slideOffsetX"
            to: root.ingressOffsetX
            duration: Theme?.animFast ?? 120
            easing.type: Easing.InCubic
        }
        NumberAnimation {
            target: root
            property: "slideOffsetY"
            to: root.ingressOffsetY
            duration: Theme?.animFast ?? 120
            easing.type: Easing.InCubic
        }
        NumberAnimation {
            target: root
            property: "cardOpacity"
            to: 0.0
            duration: Theme?.animFast ?? 120
            easing.type: Easing.InCubic
        }
        onFinished: root.dismissed()
    }

    function dismissToast() {
        progressTimer.stop();
        exitAnim.restart();
    }

    readonly property bool isHovered: cardMouse.containsMouse
    onIsHoveredChanged: {
        if (!isHovered) _lastTick = Date.now();
    }

    // elapsed timer avoids setPaused() warnings on NumberAnimation
    property real elapsedMs: 0
    property real _lastTick: 0
    readonly property real progressRatio: root.timeoutMs > 0 ? Math.max(0.0, 1.0 - (elapsedMs / root.timeoutMs)) : 1.0

    Timer {
        id: progressTimer
        interval: 30
        repeat: true
        running: root.timeoutMs > 0 && !root.isHovered
        onTriggered: {
            let now = Date.now();
            if (root._lastTick > 0) {
                root.elapsedMs += (now - root._lastTick);
            }
            root._lastTick = now;
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
                    if (root.notif?.id !== undefined && root.notif?.id !== null) {
                        NotificationService.dismiss(root.notif.id);
                    } else if (root.notif && typeof root.notif.dismiss === "function") {
                        try { root.notif.dismiss(); } catch (e) {}
                    }
                }
            }
        }

        Text {
            text: (root.notif?.summary ?? "").toLowerCase()
            font.family: Theme?.fontFamily ?? "sans-serif"
            font.pixelSize: Theme?.fontSizeMd ?? 14
            font.weight: Font.DemiBold
            color: Theme?.on_surface ?? "#cdd6f4"
            Layout.fillWidth: true
            wrapMode: Text.Wrap
            visible: text !== ""
        }

        Text {
            text: (root.notif?.body ?? "").toLowerCase()
            font.family: Theme?.fontFamily ?? "sans-serif"
            font.pixelSize: Theme?.fontSizeSm ?? 12
            color: Theme?.on_surface_variant ?? "#a6adc8"
            Layout.fillWidth: true
            wrapMode: Text.Wrap
            textFormat: Text.AutoText
            baseUrl: "file:///"
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
                        text: (modelData?.text || modelData?.id || "action").toLowerCase()
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
        anchors.leftMargin: root.isConcave ? (root.scoopR + 4) : 0
        anchors.rightMargin: root.isConcave ? (root.scoopR + 4) : 0
        height: 3
        radius: 1.5
        color: Theme?.surface_container_highest ?? "#2a2a3c"
        visible: root.timeoutMs > 0

        Rectangle {
            id: progressBar
            height: parent.height
            radius: 1.5
            color: notif?.urgency === 2 ? Theme.error : Theme.primary
            width: parent.width * root.progressRatio
        }
    }
}
