import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import ".."

Item {
    id: root
    anchors.fill: parent
    z: 999
    visible: opacity > 0
    opacity: 0

    property string targetKey: ""
    property string targetTitle: "Custom Color"
    property string targetDesc: ""
    property string defaultHex: "#80d5d2"

    property real hue: 210
    property real sat: 80
    property real lit: 60
    property bool copiedToast: false

    signal colorApplied(string key, string hex)

    Behavior on opacity {
        NumberAnimation { duration: Theme.animNormal; easing.type: Theme.animEasing }
    }

    function hexAt(h, s, l) {
        let l_norm = l / 100;
        let a = (s * Math.min(l_norm, 1 - l_norm)) / 100;
        let f = n => {
            let k = (n + h / 30) % 12;
            let c = l_norm - a * Math.max(Math.min(k - 3, 9 - k, 1), -1);
            return Math.round(255 * c).toString(16).padStart(2, '0');
        };
        return "#" + f(0) + f(8) + f(4);
    }

    readonly property string currentHex: hexAt(hue, sat, lit)

    function setFromHex(hexStr) {
        if (!hexStr) return;
        let hex = hexStr.trim();
        if (!hex.startsWith("#")) hex = "#" + hex;
        if (hex.length < 7) return;
        let r = parseInt(hex.slice(1, 3), 16) / 255;
        let g = parseInt(hex.slice(3, 5), 16) / 255;
        let b = parseInt(hex.slice(5, 7), 16) / 255;
        if (isNaN(r) || isNaN(g) || isNaN(b)) return;
        let max = Math.max(r, g, b), min = Math.min(r, g, b);
        let h = 0, s = 0, l = (max + min) / 2;
        if (max !== min) {
            let d = max - min;
            s = l > 0.5 ? d / (2 - max - min) : d / (max + min);
            if (max === r) h = (g - b) / d + (g < b ? 6 : 0);
            else if (max === g) h = (b - r) / d + 2;
            else if (max === b) h = (r - g) / d + 4;
            h /= 6;
        }
        hue = Math.round(h * 360);
        sat = Math.round(s * 100);
        lit = Math.round(l * 100);
        hexInput.text = currentHex;
    }

    function open(key, title, desc, curHex, defHex) {
        targetKey = key;
        targetTitle = title || "Custom Color";
        targetDesc = desc || "";
        defaultHex = defHex || "#80d5d2";
        let startColor = (curHex && curHex.length >= 7) ? curHex : defaultHex;
        setFromHex(startColor);
        hexInput.text = currentHex;
        root.opacity = 1.0;
    }

    function close() {
        root.opacity = 0.0;
    }

    function apply() {
        if (targetKey && typeof Settings !== "undefined") {
            Settings[targetKey] = currentHex;
            Settings.customColorsEnabled = true;
            Settings.save();
        }
        colorApplied(targetKey, currentHex);
        close();
    }

    function resetDefault() {
        if (targetKey && typeof Settings !== "undefined") {
            Settings[targetKey] = "";
            Settings.save();
        }
        setFromHex(defaultHex);
        colorApplied(targetKey, "");
        close();
    }

    Timer {
        id: toastTimer
        interval: 1600
        onTriggered: root.copiedToast = false
    }

    Process {
        id: eyeProc
        command: ["bash", "-c", "geom=$(slurp -p -b 00000000 -c 00000000 2>/dev/null) || exit 0; rgb=$(grim -g \"$geom\" -t ppm - 2>/dev/null | tail -c 3 | od -An -t u1) || exit 0; echo \"$rgb\" | awk '{ r=$1+0; g=$2+0; b=$3+0; printf \"#%02x%02x%02x\\n\", r, g, b }'"]
        stdout: SplitParser {
            onRead: function(line) {
                if (!line || !line.startsWith("#")) return;
                root.setFromHex(line.trim());
            }
        }
    }

    Process {
        id: copyProc
        command: []
    }

    function copyToClipboard(str) {
        copyProc.command = ["bash", "-c", "printf '%s' '" + str + "' | wl-copy"];
        copyProc.running = true;
        copiedToast = true;
        toastTimer.restart();
    }

    // Backdrop dismissal
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.65)
        MouseArea {
            anchors.fill: parent
            onClicked: root.close()
        }
    }

    // Modal Card
    Rectangle {
        id: modalContent
        anchors.centerIn: parent
        width: Math.min(420, parent.width - 32)
        implicitHeight: cardCol.implicitHeight + 36
        radius: Theme.radiusMd > 8 ? Theme.radiusMd : 16
        color: Theme.surface_container ?? Theme.cardBg
        border.color: Theme.outline_variant ?? Theme.cardBorder
        border.width: 1

        scale: root.opacity
        Behavior on scale {
            NumberAnimation { duration: Theme.animNormal; easing.type: Theme.animEasingEntrance }
        }

        MouseArea {
            anchors.fill: parent
            // block clicks through to backdrop
        }

        ColumnLayout {
            id: cardCol
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 18
            spacing: 12

            // Header Row
            RowLayout {
                Layout.fillWidth: true

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        text: root.targetTitle
                        font.family: Theme.fontSans
                        font.pixelSize: Theme.fontSizeMd
                        font.weight: Font.DemiBold
                        color: Theme.on_surface
                    }

                    Text {
                        visible: root.targetDesc !== ""
                        text: root.targetDesc
                        font.family: Theme.fontSans
                        font.pixelSize: Theme.fontSizeXs
                        color: Theme.on_surface_variant
                    }
                }

                Rectangle {
                    width: 28
                    height: 28
                    radius: 14
                    color: closeMouse.containsMouse ? Theme.pillHover : "transparent"
                    border.color: Theme.pillBorder
                    border.width: closeMouse.containsMouse ? 1 : 0

                    Text {
                        anchors.centerIn: parent
                        text: "✕"
                        font.family: Theme.fontSans
                        font.pixelSize: Theme.fontSizeSm
                        color: Theme.on_surface_variant
                    }

                    MouseArea {
                        id: closeMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.close()
                    }
                }
            }

            // Big Preview Swatch & Hex Badge
            Rectangle {
                Layout.fillWidth: true
                height: 72
                radius: Theme.radiusMd > 6 ? Theme.radiusMd : 12
                color: root.currentHex
                border.color: Qt.rgba(1, 1, 1, 0.20)
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 12

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            text: root.currentHex.toUpperCase()
                            font.family: Theme.fontMono
                            font.pixelSize: Theme.fontSizeLg
                            font.weight: Font.Bold
                            color: root.lit > 55 ? "#111111" : "#ffffff"
                        }

                        Text {
                            text: "Sample Typography"
                            font.family: Theme.fontSans
                            font.pixelSize: Theme.fontSizeXs
                            font.weight: Font.Medium
                            color: root.lit > 55 ? "#222222" : "#dddddd"
                        }
                    }

                    Rectangle {
                        width: 32
                        height: 32
                        radius: 16
                        color: copyMouse.containsMouse ? Qt.rgba(0, 0, 0, 0.3) : Qt.rgba(0, 0, 0, 0.15)

                        Text {
                            anchors.centerIn: parent
                            text: root.copiedToast ? "✓" : (Theme.iconClipboard ?? "📋")
                            font.family: Theme.fontIcon
                            font.pixelSize: Theme.fontSizeSm
                            color: root.lit > 55 ? "#111111" : "#ffffff"
                        }

                        MouseArea {
                            id: copyMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.copyToClipboard(root.currentHex)
                        }
                    }
                }
            }

            // Direct Hex Input & Eyedropper Row
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Rectangle {
                    Layout.fillWidth: true
                    height: 38
                    radius: Theme.radiusSm > 4 ? Theme.radiusSm : 8
                    color: Theme.surface_container_highest ?? Theme.pillBg
                    border.color: hexInput.activeFocus ? Theme.primary : Theme.outline_variant
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 6

                        Text {
                            text: "#"
                            font.family: Theme.fontMono
                            font.pixelSize: Theme.fontSizeMd
                            color: Theme.on_surface_variant
                        }

                        TextInput {
                            id: hexInput
                            Layout.fillWidth: true
                            font.family: Theme.fontMono
                            font.pixelSize: Theme.fontSizeSm
                            color: Theme.on_surface
                            selectByMouse: true
                            maximumLength: 7
                            text: root.currentHex
                            onTextChanged: {
                                if (text.startsWith("#") && text.length === 7) {
                                    root.setFromHex(text);
                                } else if (!text.startsWith("#") && text.length === 6) {
                                    root.setFromHex("#" + text);
                                }
                            }
                        }
                    }
                }

                // Eyedropper Screen Sampler Button
                Rectangle {
                    width: 38
                    height: 38
                    radius: Theme.radiusSm > 4 ? Theme.radiusSm : 8
                    color: eyeMouse.containsMouse ? Theme.primary_overlay : Theme.surface_container_highest
                    border.color: Theme.outline_variant
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: Theme.iconSparkles ?? "👁"
                        font.family: Theme.fontIcon
                        font.pixelSize: Theme.fontSizeMd
                        color: Theme.primary
                    }

                    MouseArea {
                        id: eyeMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            eyeProc.running = false;
                            eyeProc.running = true;
                        }
                    }
                }
            }

            // HSL Sliders
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 10

                // Hue Slider (0 - 360)
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: "Hue"
                            font.family: Theme.fontSans
                            font.pixelSize: Theme.fontSizeXs
                            color: Theme.on_surface_variant
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: Math.round(root.hue) + "°"
                            font.family: Theme.fontMono
                            font.pixelSize: Theme.fontSizeXs
                            color: Theme.on_surface
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 20
                        radius: 10
                        color: Theme.surface_container_highest

                        Rectangle {
                            anchors.fill: parent
                            radius: 10
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0.00; color: "#ff0000" }
                                GradientStop { position: 0.17; color: "#ffff00" }
                                GradientStop { position: 0.33; color: "#00ff00" }
                                GradientStop { position: 0.50; color: "#00ffff" }
                                GradientStop { position: 0.67; color: "#0000ff" }
                                GradientStop { position: 0.83; color: "#ff00ff" }
                                GradientStop { position: 1.00; color: "#ff0000" }
                            }
                        }

                        // Thumb handle
                        Rectangle {
                            x: Math.max(0, Math.min(parent.width - width, (root.hue / 360) * (parent.width - width)))
                            anchors.verticalCenter: parent.verticalCenter
                            width: 18
                            height: 18
                            radius: 9
                            color: "#ffffff"
                            border.color: "#333333"
                            border.width: 2
                        }

                        MouseArea {
                            anchors.fill: parent
                            preventStealing: true
                            onPositionChanged: (mouse) => {
                                let norm = Math.max(0, Math.min(1, mouse.x / width));
                                root.hue = Math.round(norm * 360);
                                hexInput.text = root.currentHex;
                            }
                            onPressed: (mouse) => {
                                let norm = Math.max(0, Math.min(1, mouse.x / width));
                                root.hue = Math.round(norm * 360);
                                hexInput.text = root.currentHex;
                            }
                        }
                    }
                }

                // Saturation Slider (0 - 100)
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: "Saturation"
                            font.family: Theme.fontSans
                            font.pixelSize: Theme.fontSizeXs
                            color: Theme.on_surface_variant
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: Math.round(root.sat) + "%"
                            font.family: Theme.fontMono
                            font.pixelSize: Theme.fontSizeXs
                            color: Theme.on_surface
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 20
                        radius: 10
                        color: Theme.surface_container_highest

                        Rectangle {
                            anchors.fill: parent
                            radius: 10
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0.0; color: root.hexAt(root.hue, 0, root.lit) }
                                GradientStop { position: 1.0; color: root.hexAt(root.hue, 100, root.lit) }
                            }
                        }

                        Rectangle {
                            x: Math.max(0, Math.min(parent.width - width, (root.sat / 100) * (parent.width - width)))
                            anchors.verticalCenter: parent.verticalCenter
                            width: 18
                            height: 18
                            radius: 9
                            color: "#ffffff"
                            border.color: "#333333"
                            border.width: 2
                        }

                        MouseArea {
                            anchors.fill: parent
                            preventStealing: true
                            onPositionChanged: (mouse) => {
                                let norm = Math.max(0, Math.min(1, mouse.x / width));
                                root.sat = Math.round(norm * 100);
                                hexInput.text = root.currentHex;
                            }
                            onPressed: (mouse) => {
                                let norm = Math.max(0, Math.min(1, mouse.x / width));
                                root.sat = Math.round(norm * 100);
                                hexInput.text = root.currentHex;
                            }
                        }
                    }
                }

                // Lightness Slider (0 - 100)
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: "Lightness"
                            font.family: Theme.fontSans
                            font.pixelSize: Theme.fontSizeXs
                            color: Theme.on_surface_variant
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: Math.round(root.lit) + "%"
                            font.family: Theme.fontMono
                            font.pixelSize: Theme.fontSizeXs
                            color: Theme.on_surface
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 20
                        radius: 10
                        color: Theme.surface_container_highest

                        Rectangle {
                            anchors.fill: parent
                            radius: 10
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0.0; color: "#000000" }
                                GradientStop { position: 0.5; color: root.hexAt(root.hue, root.sat, 50) }
                                GradientStop { position: 1.0; color: "#ffffff" }
                            }
                        }

                        Rectangle {
                            x: Math.max(0, Math.min(parent.width - width, (root.lit / 100) * (parent.width - width)))
                            anchors.verticalCenter: parent.verticalCenter
                            width: 18
                            height: 18
                            radius: 9
                            color: "#ffffff"
                            border.color: "#333333"
                            border.width: 2
                        }

                        MouseArea {
                            anchors.fill: parent
                            preventStealing: true
                            onPositionChanged: (mouse) => {
                                let norm = Math.max(0, Math.min(1, mouse.x / width));
                                root.lit = Math.round(norm * 100);
                                hexInput.text = root.currentHex;
                            }
                            onPressed: (mouse) => {
                                let norm = Math.max(0, Math.min(1, mouse.x / width));
                                root.lit = Math.round(norm * 100);
                                hexInput.text = root.currentHex;
                            }
                        }
                    }
                }
            }

            // Action Buttons Row
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 6
                spacing: 8

                // Reset Button
                Rectangle {
                    implicitWidth: resetText.implicitWidth + 20
                    height: 36
                    radius: Theme.radiusSm > 4 ? Theme.radiusSm : 8
                    color: resetMouse.containsMouse ? Theme.widgetHover : Theme.widgetBg
                    border.color: Theme.widgetBorder
                    border.width: 1

                    Text {
                        id: resetText
                        anchors.centerIn: parent
                        text: "Default"
                        font.family: Theme.fontSans
                        font.pixelSize: Theme.fontSizeSm
                        color: Theme.on_surface_variant
                    }

                    MouseArea {
                        id: resetMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.resetDefault()
                    }
                }

                Item { Layout.fillWidth: true }

                // Cancel Button
                Rectangle {
                    implicitWidth: cancelText.implicitWidth + 20
                    height: 36
                    radius: Theme.radiusSm > 4 ? Theme.radiusSm : 8
                    color: cancelMouse.containsMouse ? Theme.widgetHover : "transparent"
                    border.color: Theme.widgetBorder
                    border.width: cancelMouse.containsMouse ? 1 : 0

                    Text {
                        id: cancelText
                        anchors.centerIn: parent
                        text: "Cancel"
                        font.family: Theme.fontSans
                        font.pixelSize: Theme.fontSizeSm
                        color: Theme.on_surface_variant
                    }

                    MouseArea {
                        id: cancelMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.close()
                    }
                }

                // Apply Button
                Rectangle {
                    implicitWidth: applyText.implicitWidth + 24
                    height: 36
                    radius: Theme.radiusSm > 4 ? Theme.radiusSm : 8
                    color: applyMouse.pressed ? Theme.primary : (applyMouse.containsMouse ? Theme.blend(Theme.primary, "#ffffff", 0.15) : Theme.primary)

                    Text {
                        id: applyText
                        anchors.centerIn: parent
                        text: "Apply"
                        font.family: Theme.fontSans
                        font.pixelSize: Theme.fontSizeSm
                        font.weight: Font.DemiBold
                        color: Theme.on_primary
                    }

                    MouseArea {
                        id: applyMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.apply()
                    }
                }
            }
        }
    }
}
