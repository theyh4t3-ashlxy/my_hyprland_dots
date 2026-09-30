import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import ".."
import "../controls"
import Quickshell
import Quickshell.Hyprland

// ScreenCapture: dedicated hardware-accelerated screenshot & screen recording hub.
// Zero slurp, zero wf-recorder, native GPU encoding & Wayland overlay cropping.
Rectangle {
    id: root

    property bool isRecording: ScreenRecService.isRecording
    property string activeAudio: ScreenRecService.activeAudio

    implicitWidth: {
        if (Theme.isVertical) return Theme.barHeight - 8;
        if (root.isRecording) return recRow.implicitWidth + 24;
        return cMouse.containsMouse || popup.open ? iconRow.implicitWidth + 24 : Theme.barHeight - 8;
    }
    implicitHeight: Theme.barHeight - 8
    radius: Theme.radiusPill

    color: {
        if (root.isRecording) return Theme.alpha(Theme.error ?? "#ff5449", 0.18);
        if (popup.open) return Theme.primary_overlay;
        if (cMouse.containsMouse) return Theme.pillHover;
        return Theme.pillBg;
    }
    border.color: {
        if (root.isRecording) return Theme.error ?? "#ff5449";
        return Theme.pillBorder;
    }
    border.width: (border.color === "transparent") ? 0 : 1
    clip: true

    Behavior on color { ColorAnimation { duration: Theme.animFast } }
    Behavior on border.color { ColorAnimation { duration: Theme.animFast } }
    Behavior on implicitWidth { NumberAnimation { duration: Theme.animFast; easing.type: Theme.animEasing } }

    // Idle Content (Camera icon + label on hover)
    Row {
        id: iconRow
        anchors.centerIn: parent
        spacing: 6
        visible: !root.isRecording

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Theme.iconCamera
            font.family: Theme.fontIcon
            font.pixelSize: Theme.fontSizeSm
            color: popup.open ? Theme.primary : (cMouse.containsMouse ? Theme.primary : Theme.on_surface)

            Behavior on color { ColorAnimation { duration: Theme.animFast } }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "capture"
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeSm
            font.weight: Font.Medium
            color: Theme.on_surface
            visible: !Theme.isVertical && (cMouse.containsMouse || popup.open)
        }
    }

    // Live Recording Pill Content
    RowLayout {
        id: recRow
        anchors.centerIn: parent
        spacing: 6
        visible: root.isRecording

        // Pulsing red recording dot
        Rectangle {
            width: 8
            height: 8
            radius: 4
            color: Theme.error ?? "#ff5449"

            SequentialAnimation on opacity {
                loops: Animation.Infinite
                running: root.isRecording
                NumberAnimation { from: 1.0; to: 0.20; duration: 650; easing.type: Easing.InOutQuad }
                NumberAnimation { from: 0.20; to: 1.0; duration: 650; easing.type: Easing.InOutQuad }
            }
        }

        Text {
            text: "REC " + ScreenRecService.elapsedTimeString
            font.family: Theme.fontMono
            font.pixelSize: Theme.fontSizeXs
            font.weight: Font.Bold
            color: Theme.error ?? "#ff5449"
        }
    }

    MouseArea {
        id: cMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (root.isRecording) {
                ScreenRecService.stopRecording();
            } else {
                root.syncAnchor();
                popup.open = !popup.open;
            }
        }
    }

    function syncAnchor() {
        const pt = root.mapToItem(null, 0, 0);
        popup.targetRelativeX = (pt?.x ?? 0) + (root.width / 2);
        popup.targetRelativeY = (pt?.y ?? 0) + (root.height / 2);
    }

    Connections {
        target: Settings
        function onRequestCaptureToggle() {
            root.syncAnchor();
            popup.open = !popup.open;
        }
        function onRequestCaptureOpen() {
            root.syncAnchor();
            popup.open = true;
        }
        function onRequestCaptureClose() {
            popup.open = false;
        }
    }

    PopupPanel {
        id: popup
        cardWidth: 380
        cardHeight: Math.round(captureLayout.implicitHeight + ((Theme.popupPadding ?? 16) * 2))
        targetRelativeX: (root.mapToItem(null, 0, 0)?.x ?? 0) + (root.width / 2)
        targetRelativeY: (root.mapToItem(null, 0, 0)?.y ?? 0) + (root.height / 2)

        content: ColumnLayout {
            id: captureLayout
            anchors.fill: parent
            spacing: 12

            // Header
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: Theme.iconCamera
                    font.family: Theme.fontIcon
                    font.pixelSize: Theme.fontSizeLg
                    color: Theme.primary
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1

                    Text {
                        text: "screen capture & recorder"
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeMd
                        font.weight: Font.Bold
                        color: Theme.on_surface
                    }

                    Text {
                        text: "gpu accelerated • native wayland"
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                        color: Theme.on_surface_variant
                    }
                }

                Rectangle {
                    height: 22
                    implicitWidth: statusText.implicitWidth + 12
                    radius: Theme.radiusPill
                    color: root.isRecording ? Theme.alpha(Theme.error ?? "#ff5449", 0.18) : Theme.primary_overlay
                    border.color: root.isRecording ? (Theme.error ?? "#ff5449") : Theme.primary
                    border.width: 1

                    Text {
                        id: statusText
                        anchors.centerIn: parent
                        text: root.isRecording ? ("REC " + ScreenRecService.elapsedTimeString) : "ready"
                        font.family: Theme.fontMono
                        font.pixelSize: 10
                        font.weight: Font.Bold
                        color: root.isRecording ? (Theme.error ?? "#ff5449") : Theme.primary
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Theme.widgetBorder
            }

            // =========================================================================
            // SCREENSHOT SECTION
            // =========================================================================
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6

                Text {
                    text: "screenshot"
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSm
                    font.weight: Font.DemiBold
                    color: Theme.on_surface
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    // Region Screenshot
                    Rectangle {
                        Layout.fillWidth: true
                        height: 38
                        radius: Theme.radiusSm
                        color: sRegM.pressed ? Theme.primary : (sRegM.containsMouse ? Theme.primary_overlay : Theme.surface_container_highest)
                        border.color: Theme.widgetBorder
                        border.width: 1

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 6
                            Text {
                                text: Theme.iconCrop
                                font.family: Theme.fontIcon
                                font.pixelSize: Theme.fontSizeSm
                                color: sRegM.pressed ? Theme.on_primary : Theme.primary
                            }
                            Text {
                                text: "region"
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeXs
                                font.weight: Font.Medium
                                color: sRegM.pressed ? Theme.on_primary : Theme.on_surface
                            }
                        }

                        MouseArea {
                            id: sRegM
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                popup.open = false;
                                ScreenshotService.open("region");
                            }
                        }
                    }

                    // Window Screenshot
                    Rectangle {
                        Layout.fillWidth: true
                        height: 38
                        radius: Theme.radiusSm
                        color: sWinM.pressed ? Theme.primary : (sWinM.containsMouse ? Theme.primary_overlay : Theme.surface_container_highest)
                        border.color: Theme.widgetBorder
                        border.width: 1

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 6
                            Text {
                                text: Theme.iconWorkspaces
                                font.family: Theme.fontIcon
                                font.pixelSize: Theme.fontSizeSm
                                color: sWinM.pressed ? Theme.on_primary : Theme.primary
                            }
                            Text {
                                text: "window"
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeXs
                                font.weight: Font.Medium
                                color: sWinM.pressed ? Theme.on_primary : Theme.on_surface
                            }
                        }

                        MouseArea {
                            id: sWinM
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                popup.open = false;
                                ScreenshotService.open("window");
                            }
                        }
                    }

                    // Fullscreen Screenshot
                    Rectangle {
                        Layout.fillWidth: true
                        height: 38
                        radius: Theme.radiusSm
                        color: sFullM.pressed ? Theme.primary : (sFullM.containsMouse ? Theme.primary_overlay : Theme.surface_container_highest)
                        border.color: Theme.widgetBorder
                        border.width: 1

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 6
                            Text {
                                text: Theme.iconExpand
                                font.family: Theme.fontIcon
                                font.pixelSize: Theme.fontSizeSm
                                color: sFullM.pressed ? Theme.on_primary : Theme.primary
                            }
                            Text {
                                text: "display"
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeXs
                                font.weight: Font.Medium
                                color: sFullM.pressed ? Theme.on_primary : Theme.on_surface
                            }
                        }

                        MouseArea {
                            id: sFullM
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                popup.open = false;
                                const scr = Quickshell.screens && Quickshell.screens.length > 0 ? Quickshell.screens[0] : null;
                                ScreenshotService.captureFullscreen(scr, Settings?.screenshotDefaultAction || "both");
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

            // =========================================================================
            // SCREEN RECORDING SECTION (GPU-SCREEN-RECORDER)
            // =========================================================================
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: "screen recording"
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeSm
                        font.weight: Font.DemiBold
                        color: Theme.on_surface
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: "60 fps • nvenc/vaapi"
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                        color: Theme.on_surface_disabled
                    }
                }

                // If recording is active: prominent stop/discard card
                Rectangle {
                    visible: root.isRecording
                    Layout.fillWidth: true
                    height: 52
                    radius: Theme.radiusSm
                    color: Theme.alpha(Theme.error ?? "#ff5449", 0.12)
                    border.color: Theme.error ?? "#ff5449"
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 8

                        Rectangle {
                            width: 10
                            height: 10
                            radius: 5
                            color: Theme.error ?? "#ff5449"
                        }

                        Text {
                            text: "Recording (" + ScreenRecService.elapsedTimeString + ")"
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeSm
                            font.weight: Font.Bold
                            color: Theme.error ?? "#ff5449"
                            Layout.fillWidth: true
                        }

                        Rectangle {
                            height: 32
                            implicitWidth: stopTxt.implicitWidth + 16
                            radius: Theme.radiusSm
                            color: Theme.error ?? "#ff5449"

                            Text {
                                id: stopTxt
                                anchors.centerIn: parent
                                text: "Stop"
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeXs
                                font.weight: Font.Bold
                                color: "#ffffff"
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: ScreenRecService.stopRecording()
                            }
                        }

                        Rectangle {
                            height: 32
                            implicitWidth: discTxt.implicitWidth + 16
                            radius: Theme.radiusSm
                            color: "transparent"
                            border.color: Theme.error ?? "#ff5449"
                            border.width: 1

                            Text {
                                id: discTxt
                                anchors.centerIn: parent
                                text: "Discard"
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeXs
                                font.weight: Font.Medium
                                color: Theme.error ?? "#ff5449"
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: ScreenRecService.discardRecording()
                            }
                        }
                    }
                }

                // If NOT recording: 3 trigger buttons
                RowLayout {
                    visible: !root.isRecording
                    Layout.fillWidth: true
                    spacing: 8

                    // Record Region
                    Rectangle {
                        Layout.fillWidth: true
                        height: 38
                        radius: Theme.radiusSm
                        color: rRegM.pressed ? Theme.primary : (rRegM.containsMouse ? Theme.primary_overlay : Theme.surface_container_highest)
                        border.color: Theme.widgetBorder
                        border.width: 1

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 6
                            Text {
                                text: Theme.iconCrop
                                font.family: Theme.fontIcon
                                font.pixelSize: Theme.fontSizeSm
                                color: rRegM.pressed ? Theme.on_primary : Theme.primary
                            }
                            Text {
                                text: "region"
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeXs
                                font.weight: Font.Medium
                                color: rRegM.pressed ? Theme.on_primary : Theme.on_surface
                            }
                        }

                        MouseArea {
                            id: rRegM
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                popup.open = false;
                                ScreenRecService.startRecording("region");
                            }
                        }
                    }

                    // Record Screen
                    Rectangle {
                        Layout.fillWidth: true
                        height: 38
                        radius: Theme.radiusSm
                        color: rScrM.pressed ? Theme.primary : (rScrM.containsMouse ? Theme.primary_overlay : Theme.surface_container_highest)
                        border.color: Theme.widgetBorder
                        border.width: 1

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 6
                            Text {
                                text: Theme.iconExpand
                                font.family: Theme.fontIcon
                                font.pixelSize: Theme.fontSizeSm
                                color: rScrM.pressed ? Theme.on_primary : Theme.primary
                            }
                            Text {
                                text: "display"
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeXs
                                font.weight: Font.Medium
                                color: rScrM.pressed ? Theme.on_primary : Theme.on_surface
                            }
                        }

                        MouseArea {
                            id: rScrM
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                popup.open = false;
                                ScreenRecService.startRecording("screen");
                            }
                        }
                    }

                    // Record Window
                    Rectangle {
                        Layout.fillWidth: true
                        height: 38
                        radius: Theme.radiusSm
                        color: rWinM.pressed ? Theme.primary : (rWinM.containsMouse ? Theme.primary_overlay : Theme.surface_container_highest)
                        border.color: Theme.widgetBorder
                        border.width: 1

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 6
                            Text {
                                text: Theme.iconWorkspaces
                                font.family: Theme.fontIcon
                                font.pixelSize: Theme.fontSizeSm
                                color: rWinM.pressed ? Theme.on_primary : Theme.primary
                            }
                            Text {
                                text: "window"
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeXs
                                font.weight: Font.Medium
                                color: rWinM.pressed ? Theme.on_primary : Theme.on_surface
                            }
                        }

                        MouseArea {
                            id: rWinM
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                popup.open = false;
                                ScreenRecService.startRecording("window");
                            }
                        }
                    }
                }

                // Audio Routing Mode Chips
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    Text {
                        text: "audio:"
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                        color: Theme.on_surface_variant
                    }

                    Repeater {
                        model: [
                            { id: "both", label: "desktop + mic" },
                            { id: "desktop", label: "desktop" },
                            { id: "mic", label: "mic" },
                            { id: "none", label: "muted" }
                        ]

                        delegate: Rectangle {
                            required property var modelData
                            height: 22
                            width: aTxt.implicitWidth + 12
                            radius: Theme.radiusPill
                            color: ScreenRecService.activeAudio === modelData.id ? Theme.primary : Theme.pillBg
                            border.color: ScreenRecService.activeAudio === modelData.id ? Theme.primary : Theme.pillBorder
                            border.width: 1

                            Text {
                                id: aTxt
                                anchors.centerIn: parent
                                text: modelData.label
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                                font.weight: ScreenRecService.activeAudio === modelData.id ? Font.Bold : Font.Normal
                                color: ScreenRecService.activeAudio === modelData.id ? Theme.on_primary : Theme.on_surface_variant
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: ScreenRecService.activeAudio = modelData.id
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

            // =========================================================================
            // QUICK FOLDER LINKS
            // =========================================================================
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Rectangle {
                    Layout.fillWidth: true
                    height: 32
                    radius: Theme.radiusSm
                    color: oScM.containsMouse ? Theme.surface_container_highest : Theme.surface_container
                    border.color: Theme.widgetBorder
                    border.width: 1

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 6
                        Text {
                            text: Theme.iconFolder
                            font.family: Theme.fontIcon
                            font.pixelSize: Theme.fontSizeSm
                            color: Theme.primary
                        }
                        Text {
                            text: "screenshots"
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeXs
                            color: Theme.on_surface
                        }
                    }

                    MouseArea {
                        id: oScM
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            popup.open = false;
                            let dir = Settings?.screenshotDir || (Quickshell.env("HOME") + "/Pictures/Screenshots");
                            Quickshell.execDetached(["xdg-open", dir]);
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 32
                    radius: Theme.radiusSm
                    color: oRecM.containsMouse ? Theme.surface_container_highest : Theme.surface_container
                    border.color: Theme.widgetBorder
                    border.width: 1

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 6
                        Text {
                            text: Theme.iconFolder
                            font.family: Theme.fontIcon
                            font.pixelSize: Theme.fontSizeSm
                            color: Theme.primary
                        }
                        Text {
                            text: "recordings"
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeXs
                            color: Theme.on_surface
                        }
                    }

                    MouseArea {
                        id: oRecM
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            popup.open = false;
                            Quickshell.execDetached(["xdg-open", ScreenRecService.outputDirectory]);
                        }
                    }
                }
            }
        }
    }
}
