pragma Singleton
// colours = DMS theme (dms-colors.json, regenerated on theme change) → apgo follows DMS live
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property var c: ({})
    property string mode: ""
    readonly property color accent: c.primary ?? "#42a5f5"
    readonly property color base: c.surface_container ?? "#101418"
    readonly property color fg: c.on_surface ?? "#e0e2e8"
    readonly property color fg2: c.on_surface_variant ?? "#c2c7cf"
    readonly property color dim: c.outline ?? "#8c9199"
    readonly property color edge: c.outline_variant ?? "#42474e"
    readonly property color bad: c.error ?? "#f2b8b5"
    readonly property string mono: "JetBrainsMono Nerd Font"
    readonly property string ui: "Inter"
    readonly property int size: 15

    FileView {
        path: Quickshell.env("HOME") + "/.cache/DankMaterialShell/dms-colors.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                const j = JSON.parse(text());
                root.mode = j.mode;
                root.c = j.colors[j.mode] ?? j.colors.dark;
            } catch (e) { console.warn("apgo: bad dms-colors.json", e); }
        }
    }
}
