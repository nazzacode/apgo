// M-/ key sheet: one frosted column on the right edge, popup-styled. Groups from keys.json + leader top level.
// Keyboard: exclusive only while open (like the old cheatsheet) · Esc / M-/ / click outside / workspace switch = close
// j k ↑ ↓ PgUp PgDn g G scroll when it doesn't fit.
import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: w
    property bool open: false
    signal dismiss()

    visible: open
    color: "transparent"
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "apgo:sheet"
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    readonly property var leader: ({
        name: "Leader · ␣",
        rows: Tree.sorted(Tree.data.tree).map(n => ({
            keys: "␣ " + (n.k === "space" ? "␣" : n.k === "Return" ? "⏎" : n.k),
            label: n.kids ? "+" + n.d : n.d, tier: n.kids ? 1 : 2 }))
    })
    readonly property var groups: [...KeyData.groups, leader]

    readonly property int px: Theme.size + 1
    FontMetrics { id: fm; font { family: Theme.mono; pixelSize: w.px; weight: Font.Medium } }
    readonly property real keyW: Math.min(15, groups.reduce((m, g) => g.rows.reduce((n, r) => Math.max(n, r.keys.length), m), 4)) * fm.averageCharacterWidth

    MouseArea { anchors.fill: parent; onClicked: w.dismiss() }

    Item {
        anchors.fill: parent
        focus: w.open
        Keys.onPressed: ev => {
            const step = 60, page = flick.height * 0.8;
            const k = ev.key;
            if (k === Qt.Key_Escape || k === Qt.Key_Slash || k === Qt.Key_Question || k === Qt.Key_Q) w.dismiss();
            else if (k === Qt.Key_J || k === Qt.Key_Down) flick.by(step);
            else if (k === Qt.Key_K || k === Qt.Key_Up) flick.by(-step);
            else if (k === Qt.Key_PageDown || k === Qt.Key_Space || k === Qt.Key_D) flick.by(page);
            else if (k === Qt.Key_PageUp || k === Qt.Key_U) flick.by(-page);
            else if (k === Qt.Key_G) flick.by(ev.modifiers & Qt.ShiftModifier ? 1e6 : -1e6);
            ev.accepted = true;
        }
    }

    Glass {
        id: card
        tint: 0.88
        anchors { right: parent.right; top: parent.top; rightMargin: 16; topMargin: 56 }
        width: col.width + 44
        height: Math.min(col.height + 28, parent.height - 56 - 16)
        MouseArea { anchors.fill: parent } // eat clicks: only outside closes

        Flickable {
            id: flick
            x: 22; y: 14
            width: col.width
            height: card.height - 28
            contentHeight: col.height
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            function by(dy) { contentY = Math.max(0, Math.min(contentHeight - height, contentY + dy)); }

            Column {
                id: col
                spacing: 0
                Repeater {
                    model: w.groups
                    Column {
                        id: grp
                        required property var modelData
                        required property int index
                        spacing: 1
                        Text {
                            text: grp.modelData.name
                            topPadding: grp.index ? 16 : 2
                            bottomPadding: 4
                            font { family: Theme.ui; pixelSize: w.px - 3; weight: Font.DemiBold; capitalization: Font.AllUppercase; letterSpacing: 0.8 }
                            color: Theme.fg2
                        }
                        Repeater {
                            model: grp.modelData.rows
                            Row {
                                required property var modelData
                                spacing: 14
                                topPadding: 2; bottomPadding: 2
                                Text {
                                    width: w.keyW
                                    text: modelData.keys.replace(/ \/ /g, "/") // long chords wrap, never elide
                                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                                    font { family: Theme.mono; pixelSize: w.px; weight: Font.Medium }
                                    color: Theme.fg // accent only marks focus/selection (theme rule)
                                }
                                Text {
                                    width: Math.min(implicitWidth, 360)
                                    text: modelData.label
                                    elide: Text.ElideRight
                                    font { family: Theme.ui; pixelSize: w.px }
                                    color: modelData.tier === 1 ? Theme.fg : Theme.fg2
                                }
                            }
                        }
                    }
                }
            }
        }

        Rectangle { // scroll hint: thin rail, only when it overflows
            visible: flick.contentHeight > flick.height
            x: card.width - 7; width: 2; radius: 1
            y: 14 + flick.visibleArea.yPosition * flick.height
            height: flick.visibleArea.heightRatio * flick.height
            color: Qt.rgba(Theme.dim.r, Theme.dim.g, Theme.dim.b, 0.5)
        }
    }
}
