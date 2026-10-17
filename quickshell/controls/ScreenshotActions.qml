import QtQuick
import QtQuick.Layouts
import ".."
import "../components"

Rectangle {
    id: root

    signal copyClicked()
    signal saveClicked()
    signal editClicked()
    signal recordClicked()
    signal fullClicked()
    signal windowClicked()
    signal regionClicked()
    signal cancelClicked()

    property bool isRecordMode: false
    property string activeMode: typeof ScreenshotService !== "undefined" ? (ScreenshotService?.activeMode ?? "region") : "region"
    property string currentQuote: Theme.getFlavor ? Theme.getFlavor("screenshot", "snitch mode: engaged") : "snitch mode: engaged"

    // pick a fresh quote from Theme.flavorQuotes.screenshot on each open when unhingedFlavor is enabled
    function randomizeQuote() {
        if (!(Settings?.unhingedFlavor ?? false)) {
            currentQuote = "snitch mode: engaged";
            return;
        }
        let pool = Theme.flavorQuotes?.screenshot;
        if (pool && pool.length > 0) {
            let idx = Math.floor(Math.random() * pool.length);
            currentQuote = pool[idx];
        } else if (Theme.getFlavor) {
            currentQuote = Theme.getFlavor("screenshot", "snitch mode: engaged");
        }
    }

    component ActionBtn: Rectangle {
        id: btnRoot
        property string icon: ""
        property string label: ""
        property bool selected: false
        property bool isDanger: false
        property color iconColor: isDanger ? (Theme.error ?? "#ff5449") : (selected ? Theme.primary : Theme.on_surface)
        property color hoverColor: isDanger
            ? (Theme.error_overlay ?? Theme.alpha(Theme.error ?? "#ff5449", 0.18))
            : Theme.primary_overlay
        property color activeColor: isDanger ? (Theme.error ?? "#ff5449") : Theme.primary
        signal clicked()

        readonly property color fgColor: {
            if (btnMouse.pressed) return btnRoot.isDanger ? (Theme.on_error ?? "#ffffff") : Theme.on_primary;
            if (btnMouse.containsMouse || btnRoot.selected) {
                return btnRoot.isDanger ? (Theme.error ?? "#ff5449") : Theme.primary;
            }
            return btnRoot.label !== "" ? Theme.on_surface : btnRoot.iconColor;
        }

        height: 28
        implicitWidth: btnRow.implicitWidth + (btnRoot.label !== "" ? 16 : 12)
        radius: Theme.radiusPill
        color: {
            if (btnMouse.pressed) return btnRoot.activeColor;
            if (btnMouse.containsMouse || btnRoot.selected) return btnRoot.hoverColor;
            return "transparent";
        }
        border.color: {
            if (btnRoot.selected) return btnRoot.isDanger ? (Theme.error ?? "#ff5449") : Theme.primary;
            if (btnMouse.containsMouse) return btnRoot.isDanger ? (Theme.error ?? "#ff5449") : Theme.outline_variant;
            return "transparent";
        }
        border.width: 1

        Behavior on color { ColorAnimation { duration: Theme.animFast } }
        Behavior on border.color { ColorAnimation { duration: Theme.animFast } }

        RowLayout {
            id: btnRow
            anchors.centerIn: parent
            spacing: 5

            Text {
                text: btnRoot.icon
                font.family: Theme.fontIcon
                font.pixelSize: Theme.fontSizeSm
                color: btnMouse.pressed
                    ? (btnRoot.isDanger ? (Theme.on_error ?? "#ffffff") : Theme.on_primary)
                    : (btnMouse.containsMouse || btnRoot.selected ? btnRoot.fgColor : btnRoot.iconColor)
            }

            Text {
                visible: btnRoot.label !== ""
                text: btnRoot.label
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeXs
                font.weight: btnRoot.selected ? Font.Bold : Font.Medium
                color: btnRoot.fgColor
            }
        }

        MouseArea {
            id: btnMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: btnRoot.clicked()
        }
    }

    implicitHeight: 38
    implicitWidth: actionRow.implicitWidth + 16
    radius: Theme.radiusPill
    color: Theme.surface_container_highest
    border.color: Theme.outline_variant
    border.width: 1

    Behavior on color { ColorAnimation { duration: Theme.animFast } }
    Behavior on border.color { ColorAnimation { duration: Theme.animFast } }

    // swallow clicks on the bar background so they don't trigger region selection underneath
    MouseArea {
        anchors.fill: parent
        z: -1
        hoverEnabled: true
        preventStealing: true
    }

    // top tab that sits flush on the main pill so ConcaveCurves form a seamless scoop
    Item {
        id: headerTab
        visible: Boolean(Settings?.unhingedFlavor) || root.isRecordMode
        anchors.bottom: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        height: 24
        width: Math.min(root.width - 36, quoteRow.implicitWidth + 24)
        clip: true

        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: parent.height + 12
            radius: 12
            color: Theme.surface_container_highest
            border.color: Theme.outline_variant
            border.width: 1
        }

        RowLayout {
            id: quoteRow
            anchors.centerIn: parent
            spacing: 6

            Text {
                text: root.isRecordMode ? Theme.iconCamera : Theme.kaoWink
                font.family: root.isRecordMode ? Theme.fontIcon : Theme.fontFamily
                font.pixelSize: Theme.fontSizeXs
                color: root.isRecordMode ? (Theme.error ?? "#ff5449") : Theme.primary
            }

            Text {
                text: root.isRecordMode ? "select area to record" : root.currentQuote
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeXs
                font.weight: Font.Medium
                color: root.isRecordMode ? (Theme.error ?? "#ff5449") : Theme.on_surface
                elide: Text.ElideRight
            }
        }
    }

    // mask the 1px border under the headerTab so the tab and bar merge into one shape
    Rectangle {
        visible: headerTab.visible
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        width: headerTab.width - 2
        height: 2
        color: Theme.surface_container_highest
        z: 1
    }

    ConcaveCurves {
        width: 8
        height: 8
        radius: 8
        color: Theme.surface_container_highest
        isTop: false
        flipX: false
        visible: headerTab.visible
        anchors.right: headerTab.left
        anchors.bottom: headerTab.bottom
    }

    ConcaveCurves {
        width: 8
        height: 8
        radius: 8
        color: Theme.surface_container_highest
        isTop: false
        flipX: true
        visible: headerTab.visible
        anchors.left: headerTab.right
        anchors.bottom: headerTab.bottom
    }

    RowLayout {
        id: actionRow
        anchors.centerIn: parent
        spacing: 4
        z: 2

        ActionBtn {
            icon: Theme.iconCrop
            label: "region"
            selected: root.activeMode === "region"
            onClicked: root.regionClicked()
        }

        ActionBtn {
            icon: Theme.iconWorkspaces
            label: "window"
            selected: root.activeMode === "window"
            onClicked: root.windowClicked()
        }

        ActionBtn {
            icon: Theme.iconExpand
            label: "full"
            selected: root.activeMode === "fullscreen" || root.activeMode === "full" || root.activeMode === "screen"
            onClicked: root.fullClicked()
        }

        Rectangle {
            width: 1
            height: 16
            Layout.leftMargin: 2
            Layout.rightMargin: 2
            color: Theme.outline_variant
        }

        ActionBtn {
            visible: !root.isRecordMode
            icon: Theme.iconCopy
            label: "copy"
            iconColor: Theme.primary
            onClicked: root.copyClicked()
        }

        ActionBtn {
            visible: !root.isRecordMode
            icon: Theme.iconSave
            label: "save"
            onClicked: root.saveClicked()
        }

        ActionBtn {
            visible: !root.isRecordMode
            icon: Theme.iconEdit
            label: "edit"
            onClicked: root.editClicked()
        }

        ActionBtn {
            visible: root.isRecordMode
            icon: Theme.iconCamera
            label: "start recording"
            isDanger: true
            onClicked: root.recordClicked()
        }

        Rectangle {
            width: 1
            height: 16
            Layout.leftMargin: 2
            Layout.rightMargin: 2
            color: Theme.outline_variant
        }

        ActionBtn {
            icon: Theme.iconClose
            isDanger: true
            onClicked: root.cancelClicked()
        }
    }
}
