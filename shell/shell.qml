// apgo popup · draws the leader menu; Hyprland submaps (apgo.lua) own the keys.
// Follows `submap>>arp/w/…` events: pill (path) at once, panel after Tree.delay ms. Bottom-centre frosted float.
// IPC (qs ipc -p <this dir> call apgo …): ran <path> · fail <desc> <msg> · search · hide · sheet (M-/ key sheet toggle) · colors (debug: mode + palette)
// Run: qs -p <apgo>/shell -d  (apgo.lua starts it on first leader press)
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

ShellRoot {
    id: root
    property bool open: false     // in an arp submap or searching
    property bool shown: false    // panel visible (after delay)
    property var path: []
    property string query: ""
    property bool searching: false
    property int sel: 0
    property string toast: ""
    property bool bad: false
    property bool sheetOpen: false // M-/ key sheet (Sheet.qml)

    readonly property var node: Tree.at(path)
    readonly property var items: searching ? Tree.find(query) : Tree.sorted(node?.kids)

    function hypr(src) { Quickshell.execDetached(["hyprctl", "dispatch", src]); }
    function lstr(s) { return "[==[" + s + "]==]"; }
    function run(p) { hypr("function() apgo.run(" + lstr(p) + ") end"); }
    function enter(p) { hypr("hl.dsp.submap(" + lstr(p ? "arp/" + p : "arp") + ")"); }
    function pick(n) {
        if (n.kids) enter(n.p);
        else { root.searching = false; run(n.p); }
    }
    function toFocused() {
        const mon = Hyprland.focusedMonitor?.name;
        win.screen = Quickshell.screens.find(s => s.name === mon) ?? Quickshell.screens[0];
    }
    function begin() {
        if (!root.open) { root.shown = Tree.delay <= 0; delay.restart(); toFocused(); }
        root.open = true;
    }
    function close() { root.open = false; root.shown = false; root.searching = false; root.path = []; }
    function flash(msg, isBad) { root.toast = msg; root.bad = isBad; toastTimer.interval = isBad ? 4000 : 1800; toastTimer.restart(); }

    Timer { id: delay; interval: Math.max(1, Tree.delay); onTriggered: root.shown = true }
    Timer { id: toastTimer; onTriggered: root.toast = "" }

    Connections {
        target: Hyprland
        function onRawEvent(ev) {
            if (ev.name === "workspacev2") { root.sheetOpen = false; return; }
            if (ev.name !== "submap") return;
            const s = ev.data;
            if (s === "arp" || s.startsWith("arp/")) { root.path = s === "arp" ? [] : s.slice(4).split("/"); root.begin(); }
            else if (!root.searching) root.close();
        }
    }

    IpcHandler {
        target: "apgo"
        function ran(p: string): void {
            const n = Tree.at(p.split("/"));
            if (n?.chord) root.flash("␣ " + p.split("/").join(" ") + "  →  " + n.d + "   ·   faster: " + n.chord, false);
        }
        function fail(desc: string, msg: string): void { root.flash("✕ " + desc + ":  " + msg, true); }
        function search(): void { root.searching = true; root.query = ""; root.sel = 0; root.shown = true; root.open = true; root.toFocused(); }
        function hide(): void { root.close(); }
        function sheet(): void {
            if (!root.sheetOpen) {
                const mon = Hyprland.focusedMonitor?.name;
                sheetWin.screen = Quickshell.screens.find(s => s.name === mon) ?? Quickshell.screens[0];
            }
            root.sheetOpen = !root.sheetOpen;
        }
        function colors(): string { return "mode=" + Theme.mode + " keys=" + Object.keys(Theme.c).length + " base=" + Theme.base + " fg=" + Theme.fg; }
    }

    Sheet { id: sheetWin; open: root.sheetOpen; onDismiss: root.sheetOpen = false }

    PanelWindow {
        id: win
        visible: root.open || root.toast !== ""
        color: "transparent"
        anchors { bottom: true; left: true; right: true }
        implicitHeight: stack.height + 48
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "apgo:popup"
        WlrLayershell.keyboardFocus: root.searching ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        mask: Region { item: stack }

        Column {
            id: stack
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 28
            spacing: 8

            // panel: column-major grid, wider than tall
            Glass {
                id: panel
                visible: root.open && root.shown && (root.items.length > 0 || root.searching)
                anchors.horizontalCenter: parent.horizontalCenter
                width: grid.width + 44
                height: grid.height + 24
                Grid {
                    id: grid
                    x: 22; y: 12
                    flow: Grid.TopToBottom
                    rows: root.searching ? Math.max(1, Math.min(6, root.items.length)) : Math.max(3, Math.ceil(root.items.length / 4))
                    columnSpacing: 40
                    rowSpacing: 1
                    Repeater {
                        model: root.items
                        Entry {
                            required property var modelData
                            required property int index
                            node: modelData
                            hot: root.searching && index === root.sel
                            keyText: root.searching ? "␣ " + modelData.p.split("/").map(k => k === "space" ? "␣" : k === "Return" ? "⏎" : k).join(" ") : (modelData.k === "space" ? "␣" : modelData.k === "Return" ? "⏎" : modelData.k)
                            onPicked: root.pick(modelData)
                        }
                    }
                    Text {
                        visible: root.searching && root.items.length === 0
                        text: root.query ? "no match" : "type to search every action"
                        font { family: Theme.mono; pixelSize: Theme.size }
                        color: Theme.dim
                    }
                }
            }

            // pill: path · title, or search field, or toast
            Glass {
                id: pill
                anchors.horizontalCenter: parent.horizontalCenter
                radius: height / 2
                width: line.width + 32
                height: line.height + 12
                border.color: root.toast && root.bad && !root.open ? Qt.rgba(Theme.bad.r, Theme.bad.g, Theme.bad.b, 0.6) : Qt.rgba(1, 1, 1, 0.10)
                Row {
                    id: line
                    x: 16; y: 6
                    spacing: 8
                    Text {
                        text: root.open ? (root.searching ? "/" : "␣") : ""
                        visible: root.open
                        font { family: Theme.mono; pixelSize: Theme.size; bold: true }
                        color: Theme.accent
                    }
                    Text {
                        visible: root.open && !root.searching && root.path.length > 0
                        text: root.path.join(" ")
                        font { family: Theme.mono; pixelSize: Theme.size; bold: true }
                        color: Theme.fg
                    }
                    TextInput {
                        id: input
                        visible: root.searching
                        width: Math.max(contentWidth, 2)
                        text: root.query
                        focus: root.searching
                        font { family: Theme.mono; pixelSize: Theme.size; bold: true }
                        color: Theme.fg
                        cursorVisible: true
                        onTextChanged: { root.query = text; root.sel = 0; }
                        Keys.onPressed: ev => {
                            if (ev.key === Qt.Key_Escape) { root.close(); ev.accepted = true; }
                            else if (ev.key === Qt.Key_Return || ev.key === Qt.Key_Enter) { const n = root.items[root.sel]; if (n) root.pick(n); ev.accepted = true; }
                            else if (ev.key === Qt.Key_Down || ev.key === Qt.Key_Tab) { root.sel = Math.min(root.sel + 1, root.items.length - 1); ev.accepted = true; }
                            else if (ev.key === Qt.Key_Up || ev.key === Qt.Key_Backtab) { root.sel = Math.max(root.sel - 1, 0); ev.accepted = true; }
                        }
                    }
                    Text {
                        visible: root.open && !root.searching
                        text: "-"
                        font { family: Theme.mono; pixelSize: Theme.size }
                        color: Theme.dim
                        SequentialAnimation on opacity { loops: Animation.Infinite; running: root.open; NumberAnimation { to: 0.3; duration: 500 } NumberAnimation { to: 1; duration: 500 } }
                    }
                    Text {
                        text: !root.open ? root.toast
                            : root.searching ? "search  ·  ⏎ run  ·  ↑↓  ·  esc"
                            : (root.path.length ? Tree.trail(root.path).join(" › ") : "leader")
                        font { family: root.open ? Theme.ui : Theme.mono; pixelSize: Theme.size - (root.open ? 1 : 0) }
                        color: !root.open ? (root.bad ? Theme.bad : Theme.fg) : Theme.fg2
                        leftPadding: root.open ? 6 : 0
                    }
                }
            }
        }
    }
}
