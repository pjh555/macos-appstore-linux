import QtQuick

Row {
    id: root

    property real rating: 0
    property real starSize: 9
    property color emptyColor: Theme.textTertiary

    spacing: 1

    Repeater {
        model: 5
        Icon {
            width: root.starSize
            height: root.starSize
            name: "star"
            color: index < Math.round(root.rating) ? "#ffd60a" : root.emptyColor
            opacity: index < Math.round(root.rating) ? 1 : 0.5
        }
    }
}
