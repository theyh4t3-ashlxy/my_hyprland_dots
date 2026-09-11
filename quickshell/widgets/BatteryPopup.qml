import QtQuick
import QtQuick.Layouts
import ".."
import "../controls"
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower

PopupPanel {
    id: root

    cardWidth: 420
    cardHeight: 520

    property var device: UPower.displayDevice
    readonly property int pct: {
        let p = device?.percentage ?? 0;
        return Math.min(100, Math.max(0, Math.round(p <= 1.0 ? p * 100 : p)));
    }
    readonly property bool isCharging: device?.state === UPowerDeviceState.Charging || device?.state === UPowerDeviceState.PendingCharge
    readonly property real watts: {
        let rate = device?.energyRate ?? 0;
        if (rate > 0) return Math.round(rate * 10) / 10;
        return 0.0;
    }

    property string tlpProfile: "BAT"
    property string tlpStatus: "enabled"
    property string platformProfile: "balanced"
    property int cycleCount: 0
    property real batteryHealth: 100.0
    property int startThresh: 75
    property int stopThresh: 80
    property string lastActionMsg: ""
    property alias cmdRunner: cmdRunner

    // Read live kernel & TLP telemetry
    Process {
        id: tlpStatProc
        command: ["sudo", "-n", "tlp-stat", "-b"]
        stdout: StdioCollector {
            onStreamFinished: {
                let mCycles = text.match(/cycle_count\s*=\s*(\d+)/);
                if (mCycles) root.cycleCount = parseInt(mCycles[1]);

                let mHealth = text.match(/Capacity\s*=\s*([\d\.]+)/);
                if (mHealth) root.batteryHealth = parseFloat(mHealth[1]);

                let mStart = text.match(/charge_control_start_threshold\s*=\s*(\d+)/);
                if (mStart) root.startThresh = parseInt(mStart[1]);

                let mStop = text.match(/charge_control_end_threshold\s*=\s*(\d+)/);
                if (mStop) root.stopThresh = parseInt(mStop[1]);
            }
        }
    }

    Process {
        id: tlpProfileProc
        command: ["sudo", "-n", "tlp-stat", "-s"]
        stdout: StdioCollector {
            onStreamFinished: {
                let mProf = text.match(/TLP profile\s*=\s*([^\n\r]+)/);
                if (mProf) root.tlpProfile = mProf[1].trim();

                let mStat = text.match(/tlp\s*=\s*(\w+)/);
                if (mStat) root.tlpStatus = mStat[1].trim();
            }
        }
    }

    FileView {
        path: "/sys/firmware/acpi/platform_profile"
        watchChanges: true
        onLoaded: {
            let t = text().trim();
            if (t.length > 0) root.platformProfile = t;
        }
    }

    Process {
        id: cmdRunner
        function exec(args, msg) {
            command = args;
            running = true;
            if (msg) root.lastActionMsg = msg;
            refreshTimer.restart();
        }
    }

    Timer {
        id: refreshTimer
        interval: 1200
        repeat: false
        onTriggered: {
            tlpStatProc.running = true;
            tlpProfileProc.running = true;
        }
    }

    onOpenChanged: {
        if (open) {
            tlpStatProc.running = true;
            tlpProfileProc.running = true;
            lastActionMsg = "";
        }
    }

    content: ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.widgetPaddingH + 4
        spacing: 12

        // Header
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                text: Theme.getBatteryIcon(root.pct, root.isCharging, !(UPower.onBattery ?? true), false)
                font.family: Theme.fontIcon
                font.pixelSize: Theme.fontSizeLg
                color: root.isCharging ? Theme.secondary : (root.pct < 20 ? Theme.error : Theme.primary)
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Text {
                    text: "battery & power hub"
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeMd
                    font.weight: Font.Bold
                    color: Theme.on_surface
                }

                Text {
                    text: "TLP " + root.tlpStatus + " • " + root.tlpProfile
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeXs
                    color: Theme.on_surface_variant
                }
            }

            Rectangle {
                height: 22
                implicitWidth: badgeText.implicitWidth + 14
                radius: Theme.radiusPill
                color: root.isCharging ? Theme.secondary_container : (root.pct < 20 ? Theme.error_container : Theme.primary_container)

                Text {
                    id: badgeText
                    anchors.centerIn: parent
                    text: root.isCharging ? "charging" : (root.pct + "%")
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                    font.weight: Font.Bold
                    color: root.isCharging ? Theme.on_secondary_container : (root.pct < 20 ? Theme.on_error_container : Theme.on_primary_container)
                }
            }
        }

        // Live gauge card
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 90
            radius: Theme.radiusMd
            color: Theme.surface_container
            border.color: Theme.glassBorder
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
                        color: root.pct < 20 && !root.isCharging ? Theme.error : Theme.on_surface
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.leftMargin: 8
                        spacing: 2

                        Text {
                            text: root.isCharging ? "plugged into AC power" : "running on internal battery"
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeSm
                            font.weight: Font.Medium
                            color: Theme.on_surface
                        }

                        Text {
                            text: {
                                if (root.isCharging) {
                                    let sec = root.device?.timeToFull ?? 0;
                                    return sec > 0 ? (Math.round(sec / 60) + " mins until full") : "charging battery";
                                } else {
                                    let sec = root.device?.timeToEmpty ?? 0;
                                    return sec > 0 ? (Math.round(sec / 60) + " mins remaining") : "discharging";
                                }
                            }
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSizeXs
                            color: Theme.on_surface_variant
                        }
                    }

                    Text {
                        visible: root.watts > 0
                        text: root.watts + " W"
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeSm
                        font.weight: Font.Bold
                        color: Theme.primary
                    }
                }

                // Smooth Progress Bar
                Rectangle {
                    Layout.fillWidth: true
                    height: 8
                    radius: 4
                    color: Theme.surface_container_highest

                    Rectangle {
                        width: parent.width * (root.pct / 100.0)
                        height: parent.height
                        radius: 4
                        color: root.isCharging ? Theme.secondary : (root.pct < 20 ? Theme.error : Theme.primary)

                        Behavior on width { NumberAnimation { duration: Theme.animNormal; easing.type: Easing.OutCubic } }
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

        // Hardware Health Grid
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                implicitHeight: 64
                radius: Theme.radiusMd
                color: Theme.surface_container_low
                border.color: Theme.glassBorder
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
                        font.weight: Font.Bold
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
                color: Theme.surface_container_low
                border.color: Theme.glassBorder
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
                        font.weight: Font.Bold
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
                color: Theme.surface_container_low
                border.color: Theme.glassBorder
                border.width: 1

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 2

                    Text {
                        text: "thresholds"
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeXs
                        color: Theme.on_surface_variant
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Text {
                        text: root.startThresh + "% - " + root.stopThresh + "%"
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeMd
                        font.weight: Font.Bold
                        color: Theme.on_surface
                        Layout.alignment: Qt.AlignHCenter
                    }
                }
            }
        }

        // TLP Profile Switcher Card
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 110
            radius: Theme.radiusMd
            color: Theme.surface_container
            border.color: Theme.glassBorder
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        text: "tlp power profile & governor"
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeSm
                        font.weight: Font.Bold
                        color: Theme.on_surface
                        Layout.fillWidth: true
                    }

                    Text {
                        visible: root.lastActionMsg !== ""
                        text: root.lastActionMsg
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeXs
                        color: Theme.primary
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        height: 36
                        radius: Theme.radiusSm
                        color: root.tlpProfile.includes("AC") ? Theme.primary : Theme.surface_container_high
                        border.color: root.tlpProfile.includes("AC") ? "transparent" : Theme.glassBorder
                        border.width: 1

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 4

                            Text {
                                text: Theme.iconFlame
                                font.family: Theme.fontIcon
                                font.pixelSize: Theme.fontSizeSm
                                color: root.tlpProfile.includes("AC") ? Theme.on_primary : Theme.on_surface
                            }

                            Text {
                                text: "performance (ac)"
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeXs
                                font.weight: Font.Medium
                                color: root.tlpProfile.includes("AC") ? Theme.on_primary : Theme.on_surface
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.cmdRunner.exec(["sudo", "-n", "tlp", "ac"], "switched to performance (ac)")
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        height: 36
                        radius: Theme.radiusSm
                        color: root.tlpProfile.includes("BAT") ? Theme.primary : Theme.surface_container_high
                        border.color: root.tlpProfile.includes("BAT") ? "transparent" : Theme.glassBorder
                        border.width: 1

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 4

                            Text {
                                text: Theme.iconShield
                                font.family: Theme.fontIcon
                                font.pixelSize: Theme.fontSizeSm
                                color: root.tlpProfile.includes("BAT") ? Theme.on_primary : Theme.on_surface
                            }

                            Text {
                                text: "battery saver"
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSizeXs
                                font.weight: Font.Medium
                                color: root.tlpProfile.includes("BAT") ? Theme.on_primary : Theme.on_surface
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.cmdRunner.exec(["sudo", "-n", "tlp", "bat"], "switched to battery saver")
                        }
                    }
                }

                // Battery Care Toggle
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        height: 28
                        radius: Theme.radiusSm
                        color: Theme.surface_container_highest

                        Text {
                            anchors.centerIn: parent
                            text: "set longevity limit (80%)"
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                            color: Theme.on_surface
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.cmdRunner.exec(["sudo", "-n", "tlp", "setcharge", "75", "80"], "threshold locked at 80%")
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        height: 28
                        radius: Theme.radiusSm
                        color: Theme.surface_container_highest

                        Text {
                            anchors.centerIn: parent
                            text: "charge to 100% once"
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                            color: Theme.on_surface
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.cmdRunner.exec(["sudo", "-n", "tlp", "fullcharge"], "charging to 100% once")
                        }
                    }
                }
            }
        }

        // Quick System Launchers
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Rectangle {
                Layout.fillWidth: true
                height: 32
                radius: Theme.radiusSm
                color: Theme.surface_container_high
                border.color: Theme.glassBorder
                border.width: 1

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 4

                    Text {
                        text: Theme.iconTerminal
                        font.family: Theme.fontIcon
                        font.pixelSize: Theme.fontSizeSm
                        color: Theme.on_surface
                    }

                    Text {
                        text: "launch nvtop"
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeXs
                        color: Theme.on_surface
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        Quickshell.execDetached(["kitty", "-e", "nvtop"]);
                        root.open = false;
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 32
                radius: Theme.radiusSm
                color: Theme.surface_container_high
                border.color: Theme.glassBorder
                border.width: 1

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 4

                    Text {
                        text: Theme.iconCpu
                        font.family: Theme.fontIcon
                        font.pixelSize: Theme.fontSizeSm
                        color: Theme.on_surface
                    }

                    Text {
                        text: "launch btop"
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSizeXs
                        color: Theme.on_surface
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        Quickshell.execDetached(["kitty", "-e", "btop"]);
                        root.open = false;
                    }
                }
            }
        }
    }
}
