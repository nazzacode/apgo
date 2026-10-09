// frosted card: translucent DMS surface over Hyprland blur (layer rule ^apgo:.*$), thin rim
import QtQuick

Rectangle {
    property real tint: 0.62 // surface α; text-heavy cards go ≥ .85 (Apple: legible text needs ≥70% frost)
    radius: 12
    color: Qt.rgba(Theme.base.r, Theme.base.g, Theme.base.b, tint)
    border.width: 1
    border.color: Qt.rgba(1, 1, 1, 0.10)
    Rectangle { // top highlight
        x: parent.radius; width: parent.width - 2 * parent.radius; height: 1
        color: Qt.rgba(1, 1, 1, 0.16)
    }
}
