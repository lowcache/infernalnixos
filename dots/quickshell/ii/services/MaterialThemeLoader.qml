pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property string filePath: Config.options.appearance.wallpaperTheming.masterTheme.enable ? Config.options.appearance.wallpaperTheming.masterTheme.jsonPath : Directories.generatedMaterialThemePath
    
    // Helper to expand ~ to home directory
    function expandPath(path) {
        if (path.startsWith("~")) {
            return Quickshell.env("HOME") + path.slice(1);
        }
        return path;
    }

    function reapplyTheme() {
        themeFileView.reload()
    }

    function applyColors(fileContent) {
        try {
            const json = JSON.parse(fileContent)
            let colorsToApply = {}

            // Handle nested theme format (palette + mappings)
            if (json.palette && json.mappings) {
                const TECHNICAL_MAP = {
                    "surfaces.main_bg": [
                        "background", "surface", "surface_dim", "surface_bright", 
                        "surface_container_lowest", "surface_container_low", 
                        "surface_container", "surface_container_high", 
                        "surface_container_highest"
                    ],
                    "accents.primary_active": [
                        "primary", "surface_tint", "primary_fixed", "primary_fixed_dim", "inverse_primary"
                    ],
                    "accents.secondary_active": [
                        "secondary", "secondary_container", "secondary_fixed", "secondary_fixed_dim", "outline", "outline_variant"
                    ],
                    "accents.tertiary_active": [
                        "tertiary", "tertiary_container", "tertiary_fixed", "tertiary_fixed_dim"
                    ],
                    "text.normal": [
                        "on_background", "on_surface", "on_surface_variant", "inverse_on_surface"
                    ],
                    "text.on_accent": [
                        "on_primary", "on_secondary", "on_tertiary", 
                        "on_primary_container", "on_secondary_container", "on_tertiary_container",
                        "on_primary_fixed", "on_secondary_fixed", "on_tertiary_fixed"
                    ]
                }

                for (const groupKey in TECHNICAL_MAP) {
                    const [section, groupName] = groupKey.split(".");
                    TECHNICAL_MAP[groupKey].forEach(techKey => {
                        // Specific role (e.g. surface_container) -> General role (e.g. main_bg)
                        let colorName = json.mappings[section]?.[techKey] || json.mappings[section]?.[groupName];
                        if (colorName) {
                            const hex = json.palette[colorName] || (colorName.startsWith("#") ? colorName : null);
                            if (hex) colorsToApply[techKey] = hex;
                        }
                    });
                }
                
                // Add terminal colors if present
                if (json.mappings.terminal) {
                    for (const termKey in json.mappings.terminal) {
                        const colorName = json.mappings.terminal[termKey]
                        const hex = json.palette[colorName]
                        if (hex) colorsToApply[termKey] = hex
                    }
                }
            } else {
                // Standard flat format
                colorsToApply = json
            }

            for (const key in colorsToApply) {
                const camelCaseKey = key.replace(/_([a-z])/g, (g) => g[1].toUpperCase())
                // In Appearance.qml, they are mostly m3surfaceContainerLow (lowercase m3 + camelCase)
                const m3Key = "m3" + camelCaseKey
                
                if (Appearance.m3colors.hasOwnProperty(m3Key)) {
                    Appearance.m3colors[m3Key] = colorsToApply[key]
                } else if (Appearance.m3colors.hasOwnProperty(key)) {
                    Appearance.m3colors[key] = colorsToApply[key]
                }
            }
            
            Appearance.m3colors.darkmode = (Appearance.m3colors.m3background.hslLightness < 0.5)
        } catch (e) {
            console.log("[MaterialThemeLoader] Error applying colors: " + e)
        }
    }

    function resetFilePathNextTime() {
        resetFilePathNextWallpaperChange.enabled = true
    }

    Connections {
        id: resetFilePathNextWallpaperChange
        enabled: false
        target: Config.options.background
        function onWallpaperPathChanged() {
            root.filePath = ""
            root.filePath = Directories.generatedMaterialThemePath
            resetFilePathNextWallpaperChange.enabled = false
        }
    }

    Timer {
        id: delayedFileRead
        interval: Config.options?.hacks?.arbitraryRaceConditionDelay ?? 100
        repeat: false
        onTriggered: root.applyColors(themeFileView.text())
    }

    FileView { 
        id: themeFileView
        path: root.expandPath(root.filePath)
        watchChanges: true
        onFileChanged: {
            this.reload()
            delayedFileRead.restart()
        }
        onLoadedChanged: {
            if (themeFileView.loaded) {
                root.applyColors(themeFileView.text())
            }
        }
        onLoadFailed: root.resetFilePathNextTime();
    }
}
