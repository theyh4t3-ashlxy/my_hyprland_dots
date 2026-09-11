import QtQuick
import QtQuick.Layouts
import ".."
import Quickshell
import Quickshell.Widgets
import Quickshell.Hyprland

Rectangle {
    id: windowTitleRoot

    property var barScreen: null
    property var barMonitor: null

    readonly property var activeTop: Hyprland?.activeToplevel
    readonly property string rawTitle: (activeTop?.title ?? "").trim()
    readonly property string rawClass: {
        if (!activeTop) return "";
        let c = "";
        if (activeTop.lastIpcObject) {
            c = activeTop.lastIpcObject["class"] || activeTop.lastIpcObject.initialClass || "";
        }
        if (!c && activeTop.waylandHandle) c = activeTop.waylandHandle.appId;
        if (!c && activeTop.appId) c = activeTop.appId;
        return (c || "").trim();
    }
    readonly property bool isDesktop: !activeTop || rawTitle.length === 0
    readonly property string fallbackText: Theme?.getFlavor
        ? Theme.getFlavor("system", (Theme?.getVibe ? Theme.getVibe(Theme?.kaoEmpty, Theme?.iconArch ?? "desktop", "desktop") : "desktop"))
        : "desktop"
    readonly property string displayTitle: !isDesktop ? rawTitle : fallbackText

    // dynamic app icon resolution
    readonly property string resolvedIcon: {
        if (isDesktop || !rawClass) return "";
        let base = rawClass.toLowerCase();

        // Check DesktopEntries first for authoritative .desktop icon
        if (typeof DesktopEntries !== "undefined" && DesktopEntries?.applications?.values) {
            let apps = DesktopEntries.applications.values;
            for (let i = 0; i < apps.length; i++) {
                let a = apps[i];
                if (!a) continue;
                let aid = (a.id ?? "").toLowerCase().replace(/\.desktop$/, "");
                let wm = (a.startupWmClass ?? "").toLowerCase();
                if (aid === base || wm === base) {
                    if (a.icon) {
                        let p = Quickshell.iconPath(a.icon);
                        if (p) return p;
                    }
                }
            }
        }

        let candidates = [
            base + "-browser",
            base,
            base.replace(/-/g, ""),
            base.replace(/_bin$/, ""),
            base.replace(/-bin$/, "")
        ];
        let parts = base.split(".");
        if (parts.length > 1) {
            candidates.push(parts[parts.length - 1]);
        }
        for (let i = 0; i < candidates.length; i++) {
            let p = Quickshell.iconPath(candidates[i]);
            if (p) return p;
        }
        return Quickshell.iconPath("application-x-executable") || "";
    }
    readonly property bool showAppIcon: (Settings?.windowTitleShowIcon ?? true)
    readonly property bool hasAppIcon: showAppIcon && resolvedIcon !== ""

    // measurement element for unconstrained text width
    Text {
        id: titleMeasure
        visible: false
        text: windowTitleRoot.displayTitle
        font.family: Theme?.fontFamily ?? "sans-serif"
        font.pixelSize: Theme?.fontSizeSm ?? 12
    }

    readonly property real iconTotalWidth: showAppIcon ? 22 : 0
    readonly property real naturalWidth: titleMeasure.implicitWidth + iconTotalWidth + 24
    readonly property real desiredWidth: {
        if (Theme?.isVertical ?? false) return 0;
        let mode = Settings?.windowTitleMode ?? "auto";
        let maxW = Settings?.windowTitleMaxWidth ?? 760;
        if (mode === "compact") {
            return Math.max(50, Math.min(naturalWidth, 260));
        }
        return Math.max(50, Math.min(naturalWidth, maxW));
    }

    visible: !(Theme?.isVertical ?? false) && (Settings?.showWindowTitle ?? true)
    implicitWidth: (Theme?.isVertical ?? false) ? 0 : desiredWidth
    implicitHeight: (Theme?.isVertical ?? false) ? 0 : ((Theme?.barHeight ?? 48) - 8)
    radius: Theme?.radiusPill ?? 999
    clip: true
    color: wtMouse.containsMouse ? (Theme?.pillHover ?? "#33ffffff") : (Theme?.pillBg ?? "#1a000000")
    border.color: Theme?.pillBorder ?? "transparent"
    border.width: (Theme?.pillBorder ?? "transparent") === "transparent" ? 0 : 1

    Behavior on color { ColorAnimation { duration: Theme?.animFast ?? 150 } }
    Behavior on border.color { ColorAnimation { duration: Theme?.animFast ?? 150 } }
    Behavior on implicitWidth { NumberAnimation { duration: Theme?.animFast ?? 150; easing.type: Theme?.animEasing ?? Easing.OutQuad } }

    WindowTitlePopup {
        id: winPopup
        screen: windowTitleRoot.barScreen
    }

    Timer {
        id: hoverOpenTimer
        interval: Settings?.hoverDelay ?? 220
        repeat: false
        onTriggered: {
            if (wtMouse.containsMouse && (Settings?.hoverToOpen ?? true)) {
                let pt = windowTitleRoot.mapToItem(null, 0, 0);
                winPopup.targetRelativeX = pt.x + (windowTitleRoot.width / 2);
                winPopup.open = true;
            }
        }
    }

    Timer {
        id: hoverCloseTimer
        interval: 350
        repeat: false
        onTriggered: {
            if (!wtMouse.containsMouse && !winPopup.cardHovered && (Settings?.hoverAutoClose ?? true) && !winPopup.pinned) {
                winPopup.open = false;
            }
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        spacing: 6

        IconImage {
            id: appIcon
            Layout.preferredWidth: 16
            Layout.preferredHeight: 16
            Layout.alignment: Qt.AlignVCenter
            source: windowTitleRoot.resolvedIcon
            visible: windowTitleRoot.hasAppIcon
        }

        Text {
            id: fallbackIcon
            Layout.alignment: Qt.AlignVCenter
            text: windowTitleRoot.isDesktop ? (Theme.iconArch ?? "") : (Theme.iconTerminal ?? "")
            font.family: Theme.fontIcon
            font.pixelSize: Theme.fontSizeSm
            color: Theme.primary
            visible: windowTitleRoot.showAppIcon && (!appIcon.visible || appIcon.status === Image.Error)
        }

        Text {
            id: titleText
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            text: windowTitleRoot.displayTitle
            font.family: Theme?.fontFamily ?? "sans-serif"
            font.pixelSize: Theme?.fontSizeSm ?? 12
            color: Theme?.on_surface ?? "#ffffff"
            elide: Text.ElideRight
            maximumLineCount: 1
            opacity: (!windowTitleRoot.isDesktop) ? 1.0 : 0.6

            Behavior on opacity { NumberAnimation { duration: Theme?.animFast ?? 150; easing.type: Theme?.animEasing ?? Easing.OutQuad } }
        }
    }

    MouseArea {
        id: wtMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        z: 10
        onEntered: {
            hoverCloseTimer.stop();
            hoverOpenTimer.restart();
        }
        onExited: {
            hoverOpenTimer.stop();
            hoverCloseTimer.restart();
        }
        onClicked: {
            let pt = windowTitleRoot.mapToItem(null, 0, 0);
            winPopup.targetRelativeX = pt.x + (windowTitleRoot.width / 2);
            winPopup.pinned = !winPopup.open;
            winPopup.open = !winPopup.open;
        }
    }

    Connections {
        target: winPopup
        function onCardHoveredChanged() {
            if (winPopup.cardHovered) {
                hoverCloseTimer.stop();
            } else if (!wtMouse.containsMouse) {
                hoverCloseTimer.restart();
            }
        }
    }

    Connections {
        target: Settings
        function onRequestWindowTitleToggle() {
            if (!windowTitleRoot.barScreen || Quickshell.screens.length <= 1 || (windowTitleRoot.barMonitor && Hyprland.focusedMonitor && windowTitleRoot.barMonitor.id === Hyprland.focusedMonitor.id)) {
                let pt = windowTitleRoot.mapToItem(null, 0, 0);
                winPopup.targetRelativeX = pt ? (pt.x + (windowTitleRoot.width / 2)) : 0;
                winPopup.open = !winPopup.open;
            }
        }
    }
}