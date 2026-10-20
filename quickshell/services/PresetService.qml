pragma Singleton
import QtQuick
import ".."
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    readonly property string catalogPath: decodeURIComponent(Qt.resolvedUrl("../presets/catalog.json").toString().replace(/^file:\/\//, ""))
    readonly property string presetsDir: decodeURIComponent(Qt.resolvedUrl("../presets").toString().replace(/^file:\/\//, ""))
    readonly property string userPresetsDir: {
        let xdgState = Quickshell.env("XDG_STATE_HOME");
        let base = (xdgState && xdgState.trim() !== "") ? xdgState.trim() : (Quickshell.env("HOME") + "/.local/state");
        return base + "/quickshell/presets";
    }

    property var catalog: ({})
    property var blockMap: ({})
    property var availablePresets: []
    property string activePresetName: "custom"

    // Scratch block category colors
    function getCategoryColor(category) {
        switch (category) {
            case "navigation": return "#4c97ff"; // scratch blue (motion)
            case "status":     return "#9966ff"; // scratch purple (looks)
            case "island":     return "#8552e6"; // violet
            case "system":     return "#ffab19"; // scratch amber (events)
            case "controls":   return "#00b4d8"; // cyan / control
            case "sensors":    return "#2ec4b6"; // emerald / sensing
            case "audio":      return "#cf63cf"; // scratch magenta (sound)
            case "tools":      return "#ff8c1a"; // scratch orange (variables)
            default:           return "#5cb85c"; // green
        }
    }

    function getBlockInfo(blockId) {
        if (!blockId) return null;
        let b = root.blockMap[blockId];
        if (b) return b;
        return {
            id: blockId,
            type: "widget",
            category: "tools",
            name: blockId,
            icon: Theme?.iconGrid ?? "\uE9B0",
            desc: "custom widget",
            color: root.getCategoryColor("tools")
        };
    }

    property FileView catalogFile: FileView {
        path: root.catalogPath
        blockLoading: true
        watchChanges: true
        printErrors: false
        onLoaded: root.loadCatalog()
    }

    function loadCatalog() {
        try {
            let str = catalogFile.text();
            if (!str || str.trim() === "") return;
            let data = JSON.parse(str);
            root.catalog = data;
            let blocks = data.blocks || {};
            let map = {};
            for (let k in blocks) {
                let item = blocks[k];
                map[k] = {
                    id: k,
                    type: item.type || "widget",
                    category: item.category || "tools",
                    name: item.name || k,
                    icon: item.icon || "\uE9B0",
                    desc: item.desc || "",
                    color: root.getCategoryColor(item.category || "tools")
                };
            }
            root.blockMap = map;
        } catch (e) {
            console.warn("PresetService: failed to parse catalog.json: " + e);
        }
    }

    // Built-in presets reader
    property FileView defaultPresetFile: FileView {
        path: root.presetsDir + "/default.json"
        blockLoading: true
        watchChanges: false
        printErrors: false
    }

    property FileView minimalPresetFile: FileView {
        path: root.presetsDir + "/minimal.json"
        blockLoading: true
        watchChanges: false
        printErrors: false
    }

    property FileView islandPresetFile: FileView {
        path: root.presetsDir + "/island.json"
        blockLoading: true
        watchChanges: false
        printErrors: false
    }

    function getPresetData(presetId) {
        try {
            if (presetId === "default") {
                let t = defaultPresetFile.text();
                if (t && t.trim() !== "") return JSON.parse(t);
            } else if (presetId === "minimal") {
                let t = minimalPresetFile.text();
                if (t && t.trim() !== "") return JSON.parse(t);
            } else if (presetId === "island") {
                let t = islandPresetFile.text();
                if (t && t.trim() !== "") return JSON.parse(t);
            }
        } catch (e) {
            console.warn("PresetService: error parsing preset " + presetId + ": " + e);
        }
        return null;
    }

    function refreshPresets() {
        root.availablePresets = [
            { id: "default", name: "default", desc: "standard balanced bar", isBuiltin: true },
            { id: "minimal", name: "minimal", desc: "clean floating dock", isBuiltin: true },
            { id: "island",  name: "island",  desc: "dynamic notch centered", isBuiltin: true }
        ];
    }

    function applyPresetById(presetId) {
        let data = getPresetData(presetId);
        if (data) {
            applyPreset(data, presetId);
            return true;
        }
        return false;
    }

    function applyPreset(presetData, presetName) {
        if (!presetData) return false;
        if (presetData.bar) {
            if (presetData.bar.position !== undefined) Settings.barPosition = presetData.bar.position;
            if (presetData.bar.floating !== undefined) Settings.barFloating = presetData.bar.floating;
            if (presetData.bar.margin !== undefined) Settings.barMargin = presetData.bar.margin;
            if (presetData.bar.height !== undefined) Settings.barHeight = presetData.bar.height;
            if (presetData.bar.style !== undefined) Settings.barStyle = presetData.bar.style;
        }
        if (presetData.zones) {
            if (presetData.zones.left) Settings.barModulesLeft = presetData.zones.left;
            if (presetData.zones.center) Settings.barModulesCenter = presetData.zones.center;
            if (presetData.zones.right) Settings.barModulesRight = presetData.zones.right;
        }
        if (presetData.styling) {
            if (presetData.styling.cornerStyle) Settings.cornerStyle = presetData.styling.cornerStyle;
            if (presetData.styling.notificationCornerStyle) Settings.notificationCornerStyle = presetData.styling.notificationCornerStyle;
            if (presetData.styling.scoopRadius) Settings.scoopRadius = presetData.styling.scoopRadius;
            if (presetData.styling.widgetRadius) Settings.widgetRadius = presetData.styling.widgetRadius;
        }
        if (presetName) root.activePresetName = presetName;
        Settings.save();
        return true;
    }

    function exportCurrentAsPreset(name) {
        if (!name || name.trim() === "") return false;
        let cleanName = name.trim().toLowerCase().replace(/[^a-z0-9_-]/g, "_");
        let presetObj = {
            "$schema": "quickshell-preset-v1",
            "name": cleanName,
            "version": 1,
            "bar": {
                "position": Settings?.barPosition ?? "top",
                "floating": Settings?.barFloating ?? false,
                "margin": Settings?.barMargin ?? 0,
                "height": Settings?.barHeight ?? 32,
                "radius": Settings?.screenCornerRadius ?? 16,
                "style": Settings?.barStyle ?? "regular"
            },
            "zones": {
                "left": (Settings?.barModulesLeft ?? []).slice(),
                "center": (Settings?.barModulesCenter ?? []).slice(),
                "right": (Settings?.barModulesRight ?? []).slice()
            },
            "styling": {
                "cornerStyle": Settings?.cornerStyle ?? "continuous-bezier",
                "notificationCornerStyle": Settings?.notificationCornerStyle ?? "concave",
                "scoopRadius": Settings?.scoopRadius ?? 16,
                "widgetRadius": Settings?.widgetRadius ?? 6
            }
        };

        let jsonStr = JSON.stringify(presetObj, null, 2);
        let targetFile = root.userPresetsDir + "/" + cleanName + ".json";
        let script = "mkdir -p '" + root.userPresetsDir + "' && cat << 'EOF' > '" + targetFile + "'\n" + jsonStr + "\nEOF";
        Quickshell.execDetached(["sh", "-c", script]);
        root.activePresetName = cleanName;
        root.refreshPresets();
        return true;
    }

    Component.onCompleted: {
        loadCatalog();
        refreshPresets();
    }
}
