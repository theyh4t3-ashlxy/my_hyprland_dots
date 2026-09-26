import QtQuick
import QtQuick.Layouts
import ".."
import "../controls"
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower

PopupPanel {
    id: root

    cardWidth: Theme.popupWidth
    cardHeight: layoutContent.implicitHeight + (Theme.popupPadding * 2)

    property var device: UPower.displayDevice
    readonly property bool onBattery: UPower.onBattery ?? true
    readonly property int pct: Math.min(100, Math.max(0, Math.round((device?.percentage ?? 0) * 100)))
    readonly property bool isCharging: device?.state === UPowerDeviceState.Charging || device?.state === UPowerDeviceState.PendingCharge
    readonly property bool isFull: device?.state === UPowerDeviceState.FullyCharged || (pct >= 99 && !onBattery)
    readonly property bool isSaver: PowerProfiles.profile === PowerProfile.PowerSaver
    readonly property real watts: {
        let rate = Math.abs(device?.changeRate ?? 0);
        return rate > 0 ? (Math.round(rate * 10) / 10) : 0.0;
    }

    property int cycleCount: 0
    property int startThresh: 0
    property int stopThresh: 100
    property real energyFull: 0
    property real energyDesign: 0
    property string cpuLoad: "--"
    property bool hasDgpu: false
    property bool showDiagnostics: false

    readonly property real batteryHealth: {
        if (energyDesign > 0 && energyFull > 0) {
            return Math.min(100, Math.round((energyFull / energyDesign) * 1000) / 10);
        }
        if (device?.healthSupported && device?.healthPercentage > 0) {
            return Math.round(device.healthPercentage * 10) / 10;
        }
        return -1.0;
    }

    readonly property string userTerm: Quickshell.env("TERMINAL") || "kitty"

    // Kernel sysfs telemetry
    FileView {
        id: cycleFile
        path: "/sys/class/power_supply/BAT0/cycle_count"
        onLoaded: {
            let val = parseInt(text().trim());
            if (!isNaN(val)) root.cycleCount = val;
        }
    }

    FileView {
        id: startThreshFile
        path: "/sys/class/power_supply/BAT0/charge_control_start_threshold"
        onLoaded: {
            let val = parseInt(text().trim());
            if (!isNaN(val)) root.startThresh = val;
        }
    }

    FileView {
        id: stopThreshFile
        path: "/sys/class/power_supply/BAT0/charge_control_end_threshold"
        onLoaded: {
            let val = parseInt(text().trim());
            if (!isNaN(val)) root.stopThresh = val;
        }
    }

    FileView {
        id: energyFullFile
        path: "/sys/class/power_supply/BAT0/energy_full"
        onLoaded: {
            let val = parseFloat(text().trim());
            if (!isNaN(val) && val > 0) root.energyFull = val;
        }
    }

    FileView {
        id: energyDesignFile
        path: "/sys/class/power_supply/BAT0/energy_full_design"
        onLoaded: {
            let val = parseFloat(text().trim());
            if (!isNaN(val) && val > 0) root.energyDesign = val;
        }
    }

    // Dynamic cpu loadavg
    FileView {
        id: loadAvgFile
        path: "/proc/loadavg"
        onLoaded: {
            let raw = text().trim();
            if (raw.length > 0) {
                let parts = raw.split(/\s+/);
                if (parts.length > 0) root.cpuLoad = parts[0];
            }
        }
    }

    // Dynamic dgpu detection (nvidia or secondary pci card)
    FileView {
        id: dgpuCheckFile
        path: "/sys/class/drm/card1/device/vendor"
        onLoaded: {
            root.hasDgpu = text().trim().length > 0;
        }
    }

    function refreshHardwareStats() {
        cycleFile.reload();
        startThreshFile.reload();
        stopThreshFile.reload();
        energyFullFile.reload();
        energyDesignFile.reload();
        loadAvgFile.reload();
        dgpuCheckFile.reload();
    }

    onOpenChanged: {
        if (open) {
            refreshHardwareStats();
        }
    }

    content: ColumnLayout {
        id: layoutContent
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: Theme.popupPadding
        spacing: Theme.popupSpacing

        // Header
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Text {
                text: Theme.getBatteryIcon(root.pct, root.isCharging, root.isSaver, false)
                font.family: Theme.fontIcon
                font.pixelSize: 22
                color: Theme.getBatteryColor(root.pct, root.isCharging)
                Layout.alignment: Qt.AlignVCenter
            }

            ColumnLayout {
                spacing: 2
                Layout.alignment: Qt.AlignVCenter

                Text {
                    text: "battery & power hub"
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeMd
                    font.weight: Theme.fontWeightBold
                    color: Theme.on_surface
                }

                Text {
                    text: {
                        let prof = "balanced";
                        if (root.isSaver) prof = "power-saver";
                        else if (PowerProfiles.profile === PowerProfile.Performance) prof = "performance";
                        return "ppd active • " + prof;
                    }
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeXs
                    color: Theme.on_surface_variant
                }
            }

            Item {
                Layout.fillWidth: true
            }

            Rectangle {
                implicitHeight: 22
                implicitWidth: badgeText.implicitWidth + 14
                radius: Theme.radiusPill
                Layout.preferredHeight: 22
                Layout.alignment: Qt.AlignVCenter
                color: root.isCharging ? Theme.secondary_container : (root.pct <= 15 ? Theme.error_container : (root.pct <= 30 ? Theme.warn_container : Theme.primary_container))

                Text {
                    id: badgeText
                    anchors.centerIn: parent
                    text: root.isFull ? "full" : (root.isCharging ? "charging" : (root.pct + "%"))
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeXs
                    font.weight: Theme.fontWeightBold
                    color: root.isCharging ? Theme.on_secondary_container : (root.pct <= 15 ? Theme.on_error_container : (root.pct <= 30 ? Theme.on_warn_container : Theme.on_primary_container))
                }
            }
        }

        // Live gauge card
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 96
            radius: Theme.radiusMd
            color: Theme.cardBg
            border.color: Theme.cardBorder
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        text: root.pct + "%"
                        font.family: Theme.fontFamily
                        font.pixelSize: 32
                        font.weight: Font.Black
                        color: Theme.getBatteryColor(root.pct, root.isCharging)
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.leftMargin: 8
                        spacing: 2

                        Text {
                            text: {
                                if (root.isFull) return "connected to ac power";
                                if (root.isCharging) return "charging on ac power";
                                return "running on battery";
                            }
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeSm
                            font.weight: Theme.fontWeightMedium
                            color: Theme.on_surface
                        }

                        Text {
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                            text: {
                                let fallback = "";
                                if (root.isFull) {
                                    fallback = "battery full";
                                    return Theme.getFlavor("battery_full", fallback);
                                } else if (root.isCharging) {
                                    let sec = root.device?.timeToFull ?? 0;
                                    fallback = sec > 0 ? (Math.round(sec / 60) + " mins until full") : "charging";
                                    return Theme.getFlavor("battery_charging", fallback);
                                } else {
                                    let sec = root.device?.timeToEmpty ?? 0;
                                    fallback = sec > 0 ? (Math.round(sec / 60) + " mins remaining") : "discharging";
                                    if (root.pct <= 20) return Theme.getFlavor("battery_low", fallback);
                                    return fallback;
                                }
                            }
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeXs
                            color: Theme.on_surface_variant
                        }
                    }

                    Text {
                        visible: root.watts > 0
                        text: root.watts + " w"
                        font.family: Theme.fontMono
                        font.pixelSize: Theme.fontSizeSm
                        font.weight: Theme.fontWeightBold
                        color: Theme.primary
                    }
                }

                // Progress bar
                Rectangle {
                    Layout.fillWidth: true
                    height: 8
                    radius: Theme.radiusSm
                    color: Theme.surface_container_highest

                    Rectangle {
                        width: parent.width * (root.pct / 100.0)
                        height: parent.height
                        radius: Theme.radiusSm
                        color: Theme.getBatteryColor(root.pct, root.isCharging)

                        Behavior on width {
                            NumberAnimation {
                                duration: Theme.animNormal
                                easing.type: Theme.animEasing
                            }
                        }
                    }

                    // Threshold limit marker
                    Rectangle {
                        visible: root.stopThresh > 0 && root.stopThresh < 100
                        x: Math.round(parent.width * (root.stopThresh / 100.0)) - 1
                        width: 2
                        height: parent.height
                        color: Theme.on_surface
                        opacity: 0.8
                    }
                }
            }
        }

        // Hardware health grid
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.widgetSpacing

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                implicitHeight: 64
                radius: Theme.radiusMd
                color: Theme.cardBg
                border.color: Theme.cardBorder
                border.width: 1

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 2

                    Text {
                        text: "health"
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeXs
                        color: Theme.on_surface_variant
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Text {
                        text: root.batteryHealth > 0 ? (root.batteryHealth.toFixed(1) + "%") : "--"
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeMd
                        font.weight: Theme.fontWeightBold
                        color: Theme.on_surface
                        Layout.alignment: Qt.AlignHCenter
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                implicitHeight: 64
                radius: Theme.radiusMd
                color: Theme.cardBg
                border.color: Theme.cardBorder
                border.width: 1

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 2

                    Text {
                        text: "cycle count"
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeXs
                        color: Theme.on_surface_variant
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Text {
                        text: root.cycleCount > 0 ? (root.cycleCount + " cycles") : "--"
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeMd
                        font.weight: Theme.fontWeightBold
                        color: Theme.on_surface
                        Layout.alignment: Qt.AlignHCenter
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                implicitHeight: 64
                radius: Theme.radiusMd
                color: Theme.cardBg
                border.color: Theme.cardBorder
                border.width: 1

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 2

                    Text {
                        text: "stop threshold"
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeXs
                        color: Theme.on_surface_variant
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Text {
                        text: root.stopThresh > 0 && root.stopThresh < 100 ? (root.stopThresh + "%") : "100%"
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeMd
                        font.weight: Theme.fontWeightBold
                        color: Theme.on_surface
                        Layout.alignment: Qt.AlignHCenter
                    }
                }
            }
        }

        // Native PPD Profile Selector Card
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 90
            radius: Theme.radiusMd
            color: Theme.cardBg
            border.color: Theme.cardBorder
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 8

                Text {
                    text: "power profile daemon"
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeSm
                    font.weight: Theme.fontWeightBold
                    color: Theme.on_surface
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    // Power Saver
                    Rectangle {
                        id: btnSaver
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        Layout.preferredHeight: 36
                        implicitHeight: 36
                        radius: Theme.radiusSm
                        readonly property bool isCurrent: root.isSaver
                        color: isCurrent ? Theme.primary : (mouseSaver.containsMouse ? Theme.alpha(Theme.on_surface, 0.12) : Theme.alpha(Theme.on_surface, 0.06))
                        border.color: isCurrent ? "transparent" : Theme.cardBorder
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: "power saver"
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeXs
                            font.weight: btnSaver.isCurrent ? Theme.fontWeightBold : Theme.fontWeightMedium
                            color: btnSaver.isCurrent ? Theme.on_primary : Theme.on_surface
                        }

                        MouseArea {
                            id: mouseSaver
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: PowerProfiles.profile = PowerProfile.PowerSaver
                        }
                    }

                    // Balanced
                    Rectangle {
                        id: btnBalanced
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        Layout.preferredHeight: 36
                        implicitHeight: 36
                        radius: Theme.radiusSm
                        readonly property bool isCurrent: PowerProfiles.profile === PowerProfile.Balanced
                        color: isCurrent ? Theme.primary : (mouseBalanced.containsMouse ? Theme.alpha(Theme.on_surface, 0.12) : Theme.alpha(Theme.on_surface, 0.06))
                        border.color: isCurrent ? "transparent" : Theme.cardBorder
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: "balanced"
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeXs
                            font.weight: btnBalanced.isCurrent ? Theme.fontWeightBold : Theme.fontWeightMedium
                            color: btnBalanced.isCurrent ? Theme.on_primary : Theme.on_surface
                        }

                        MouseArea {
                            id: mouseBalanced
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: PowerProfiles.profile = PowerProfile.Balanced
                        }
                    }

                    // Performance
                    Rectangle {
                        id: btnPerf
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        Layout.preferredHeight: 36
                        implicitHeight: 36
                        radius: Theme.radiusSm
                        opacity: PowerProfiles.hasPerformanceProfile ? 1.0 : 0.35
                        readonly property bool isCurrent: PowerProfiles.profile === PowerProfile.Performance
                        color: isCurrent ? Theme.primary : (mousePerf.containsMouse && PowerProfiles.hasPerformanceProfile ? Theme.alpha(Theme.on_surface, 0.12) : Theme.alpha(Theme.on_surface, 0.06))
                        border.color: isCurrent ? "transparent" : Theme.cardBorder
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: "performance"
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeXs
                            font.weight: btnPerf.isCurrent ? Theme.fontWeightBold : Theme.fontWeightMedium
                            color: btnPerf.isCurrent ? Theme.on_primary : Theme.on_surface
                        }

                        MouseArea {
                            id: mousePerf
                            anchors.fill: parent
                            hoverEnabled: PowerProfiles.hasPerformanceProfile
                            cursorShape: PowerProfiles.hasPerformanceProfile ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: {
                                if (PowerProfiles.hasPerformanceProfile) {
                                    PowerProfiles.profile = PowerProfile.Performance;
                                }
                            }
                        }
                    }
                }
            }
        }

        // Collapsible diagnostics toggle bar
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 28
            implicitHeight: 28
            radius: Theme.radiusSm
            color: mouseDiag.containsMouse ? Theme.alpha(Theme.on_surface, 0.08) : "transparent"

            RowLayout {
                anchors.centerIn: parent
                spacing: 6

                Text {
                    text: root.showDiagnostics ? Theme.iconChevronUp : Theme.iconChevronDown
                    font.family: Theme.fontIcon
                    font.pixelSize: Theme.fontSizeXs
                    color: Theme.on_surface_variant
                }

                Text {
                    text: root.showDiagnostics ? "hide system diagnostics" : "system diagnostics (load " + root.cpuLoad + ")"
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeXs
                    color: Theme.on_surface_variant
                }
            }

            MouseArea {
                id: mouseDiag
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.showDiagnostics = !root.showDiagnostics
            }
        }

        // Context-aware dynamic launcher row
        RowLayout {
            id: launcherRow
            visible: root.showDiagnostics
            Layout.fillWidth: true
            Layout.preferredHeight: root.showDiagnostics ? 32 : 0
            implicitHeight: root.showDiagnostics ? 32 : 0
            spacing: Theme.widgetSpacing

            // Only rendered if dgpu is present
            Rectangle {
                id: nvtopBtn
                visible: root.hasDgpu
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredHeight: 32
                implicitHeight: 32
                radius: Theme.radiusSm
                color: mouseNvtop.containsMouse ? Theme.alpha(Theme.on_surface, 0.12) : Theme.alpha(Theme.on_surface, 0.06)
                border.color: Theme.cardBorder
                border.width: 1

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 6

                    Text {
                        text: Theme.iconTerminal
                        font.family: Theme.fontIcon
                        font.pixelSize: Theme.fontSizeSm
                        color: Theme.on_surface
                    }

                    Text {
                        text: "gpu top"
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeXs
                        color: Theme.on_surface
                    }
                }

                MouseArea {
                    id: mouseNvtop
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        Quickshell.execDetached([root.userTerm, "-e", "sh", "-c", "nvtop || top"]);
                        root.open = false;
                    }
                }
            }

            // CPU load + btop launcher
            Rectangle {
                id: btopBtn
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredHeight: 32
                implicitHeight: 32
                radius: Theme.radiusSm
                color: mouseBtop.containsMouse ? Theme.alpha(Theme.on_surface, 0.12) : Theme.alpha(Theme.on_surface, 0.06)
                border.color: Theme.cardBorder
                border.width: 1

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 6

                    Text {
                        text: Theme.iconCpu
                        font.family: Theme.fontIcon
                        font.pixelSize: Theme.fontSizeSm
                        color: Theme.on_surface
                    }

                    Text {
                        text: "cpu load " + root.cpuLoad + " • btop"
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeXs
                        color: Theme.on_surface
                    }
                }

                MouseArea {
                    id: mouseBtop
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        Quickshell.execDetached([root.userTerm, "-e", "sh", "-c", "btop || htop || top"]);
                        root.open = false;
                    }
                }
            }
        }
    }
}
