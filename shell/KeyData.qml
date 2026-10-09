pragma Singleton
// keys.json (dotfiles/hypr/keys.lua, rewritten on every Hyprland reload) → sheet groups, file order
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    readonly property string file: (Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state")) + "/apgo/keys.json"
    property var data: ({ kb: "us", rows: [] })

    // [{ name, rows: [{ keys, label, tier }] }] · first-seen group order
    readonly property var groups: {
        const by = {}, out = [];
        for (const r of data.rows) {
            let g = by[r.group];
            if (!g) { g = by[r.group] = { name: r.group, rows: [] }; out.push(g); }
            g.rows.push(r);
        }
        return out;
    }

    FileView {
        path: root.file
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try { root.data = JSON.parse(text()); } catch (e) { console.warn("apgo: bad keys.json", e); }
        }
    }
}
