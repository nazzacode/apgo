pragma Singleton
// apgo.json (written by apgo.lua on every Hyprland reload): { delay, tree: [{ k, d, p, chord?, alias?, sticky?, kids? }] }
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    readonly property string file: (Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state")) + "/apgo/apgo.json"
    property var data: ({ delay: 500, tree: [] })
    readonly property int delay: data.delay
    readonly property var root_: ({ d: "leader", kids: data.tree })

    function at(path) {
        let n = root_;
        for (const k of path) { n = (n.kids ?? []).find(x => x.k === k); if (!n) return null; }
        return n;
    }
    function trail(path) { return path.map((_, i) => at(path.slice(0, i + 1))?.d ?? "?"); }

    // alphabetical, Emacs-ish: named keys, then punctuation, then a A b B …
    function rank(k) {
        const named = ["space", "Return", "Tab"];
        if (named.includes(k)) return "0" + named.indexOf(k);
        if (/^[a-z]$/i.test(k)) return "2" + k.toLowerCase() + (k === k.toUpperCase() ? "1" : "0");
        return "1" + k;
    }
    function sorted(kids) { return [...(kids ?? [])].sort((a, b) => rank(a.k) < rank(b.k) ? -1 : 1); }

    readonly property var leaves: {
        const out = [];
        const walk = (ns, names) => ns.forEach(n => n.kids ? walk(n.kids, [...names, n.d])
            : out.push({ n, hay: [n.d, n.alias ?? "", ...names, n.chord ?? "", n.p.split("/").join(" ")].join(" ").toLowerCase() }));
        walk(data.tree, []);
        return out;
    }
    function find(q) {
        const ts = q.toLowerCase().split(/\s+/).filter(Boolean);
        if (!ts.length) return [];
        return leaves.filter(x => ts.every(t => x.hay.includes(t)))
            .sort((a, b) => b.n.d.toLowerCase().startsWith(ts[0]) - a.n.d.toLowerCase().startsWith(ts[0]))
            .slice(0, 16).map(x => x.n);
    }

    FileView {
        path: root.file
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try { root.data = JSON.parse(text()); } catch (e) { console.warn("apgo: bad apgo.json", e); }
        }
    }
}
