// one line: key · desc (+group) · dim chord. Click = same as typing the key.
import QtQuick

Item {
    id: e
    property var node
    property bool hot: false // search: highlighted first hit
    property string keyText: node.k === "space" ? "␣" : node.k === "Return" ? "⏎" : node.k
    signal picked()
    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight + 2

    Rectangle {
        anchors.fill: parent; anchors.margins: -1; anchors.leftMargin: -6; anchors.rightMargin: -6
        radius: 5
        color: Qt.rgba(1, 1, 1, ma.containsMouse || e.hot ? 0.07 : 0)
    }
    Row {
        id: row
        spacing: 10
        Text {
            text: e.keyText
            width: Math.max(implicitWidth, Theme.size * 1.4)
            font { family: Theme.mono; pixelSize: Theme.size; bold: true }
            color: Theme.accent
        }
        Text {
            id: desc
            text: e.node.kids ? "+" + e.node.d : e.node.d
            font { family: Theme.mono; pixelSize: Theme.size }
            color: e.node.kids ? Theme.fg : Theme.fg2
        }
        Text {
            visible: !!e.node.sticky
            text: "↻"
            font { family: Theme.mono; pixelSize: Theme.size - 2 }
            color: Theme.dim
        }
        Text {
            visible: !!e.node.chord
            text: e.node.chord ?? ""
            leftPadding: 4
            font { family: Theme.mono; pixelSize: Theme.size - 3 }
            color: Qt.rgba(Theme.dim.r, Theme.dim.g, Theme.dim.b, 0.65)
            anchors.baseline: desc.baseline
        }
    }
    MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: e.picked() }
}
