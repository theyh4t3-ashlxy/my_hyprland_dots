import QtQuick
import QtQuick.Layouts
import ".."
import "../components"

Rectangle {
    id: root

    signal copyClicked()
    signal saveClicked()
    signal editClicked()
    signal fullClicked()
    signal windowClicked()
    signal regionClicked()
    signal cancelClicked()

    readonly property var unhingedQuotes: [
        "taking a screenshot? u snitch.",
        "saving receipts? " + (Theme?.kaoWink ?? "(¬‿¬)"),
        "caught in 4k " + (Theme?.kaoLoading ?? "(⊙_⊙;)"),
        "who we cancelling today?",
        "snitch mode: engaged " + (Theme?.kaoCool ?? "(⌐■_■)"),
        "hope this isn't private " + (Theme?.kaoBolt ?? "(>ᐛ )>"),
        "pixels acquired, dignity lost"
    ]
    property string unhingedQuote: unhingedQuotes[0]

    function randomizeQuote(): void {
        let idx = Math.floor(Math.random() * unhingedQuotes.length);
        unhingedQuote = unhingedQuotes[idx];
    }

    Component.onCompleted: randomizeQuote()

    implicitHeight: 38
    implicitWidth: actionRow.implicitWidth + 20
    radius: Theme.radiusPill
    color: Theme.surface_container_highest
    border.color: Theme.outline_variant
    border.width: 1

    Behavior on color { ColorAnimation { duration: Theme.animFast } }
    Behavior on border.color { ColorAnimation { duration: Theme.animFast } }

    // Click shield on toolbar body so clicks never leak to overlay
    MouseArea {
        anchors.fill: parent
        z: -1
        hoverEnabled: true
        preventStealing: true
    }

    // Unhinged liquid scoop header tab
    Rectangle {
        id: headerTab
        visible: Settings.unhingedFlavor
        anchors.bottom: parent.top
        anchors.bottomMargin: -1
        anchors.horizontalCenter: parent.horizontalCenter
        height: 24
        implicitWidth: quoteRow.implicitWidth + 24
        radius: Theme.radiusPill
        color: Theme.surface_container_highest
        border.color: Theme.outline_variant
        border.width: 1

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.randomizeQuote()
        }

        RowLayout {
            id: quoteRow
            anchors.centerIn: parent
            spacing: 6

            Text {
                text: Theme.kaoWink
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeXs
                color: Theme.primary
            }

            Text {
                text: root.unhingedQuote
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeXs
                font.weight: Font.Medium
                color: Theme.on_surface
            }
        }
    }

    // Left concave liquid curve
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

    // Right concave liquid curve
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

    component ActionBtn: Rectangle {
        id: btnRoot
        property string icon: ""
        property string label: ""
        property color iconColor: Theme.on_surface
        property color hoverColor: Theme.primary_overlay
        property color activeColor: Theme.primary
        signal clicked()

        height: 28
        implicitWidth: btnRow.implicitWidth + 14
        radius: Theme.radiusPill
        color: btnMouse.pressed ? activeColor : (btnMouse.containsMouse ? hoverColor : "transparent")
        border.color: btnMouse.containsMouse ? Theme.outline : "transparent"
        border.width: 1

        Behavior on color { ColorAnimation { duration: Theme.animFast } }

        RowLayout {
            id: btnRow
            anchors.centerIn: parent
            spacing: 5

            Text {
                text: btnRoot.icon
                font.family: Theme.fontIcon
                font.pixelSize: Theme.fontSizeSm
                color: btnMouse.pressed ? Theme.on_primary : (btnMouse.containsMouse ? Theme.primary : btnRoot.iconColor)
            }

            Text {
                visible: btnRoot.label !== ""
                text: btnRoot.label
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeXs
                font.weight: Font.Medium
                color: btnMouse.pressed ? Theme.on_primary : (btnMouse.containsMouse ? Theme.primary : Theme.on_surface)
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

    RowLayout {
        id: actionRow
        anchors.centerIn: parent
        spacing: 4

        ActionBtn {
            icon: Theme.iconCrop
            label: "region"
            onClicked: root.regionClicked()
        }

        ActionBtn {
            icon: Theme.iconWorkspaces
            label: "window"
            onClicked: root.windowClicked()
        }

        ActionBtn {
            icon: Theme.iconExpand
            label: "full"
            onClicked: root.fullClicked()
        }

        Rectangle {
            width: 1
            height: 16
            color: Theme.outline_variant
        }

        ActionBtn {
            icon: Theme.iconCopy
            label: "copy"
            iconColor: Theme.primary
            onClicked: root.copyClicked()
        }

        ActionBtn {
            icon: Theme.iconSave
            label: "save"
            onClicked: root.saveClicked()
        }

        ActionBtn {
            icon: Theme.iconEdit
            label: "edit"
            onClicked: root.editClicked()
        }

        Rectangle {
            width: 1
            height: 16
            color: Theme.outline_variant
        }

        ActionBtn {
            icon: Theme.iconClose
            hoverColor: Theme.error_overlay
            iconColor: Theme.error
            onClicked: root.cancelClicked()
        }
    }
}
