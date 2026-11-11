import QtQuick
import QtQuick.Controls

ScrollBar {
    id: control

    policy: ScrollBar.AsNeeded
    width: 9
    minimumSize: 0.08

    contentItem: Rectangle {
        implicitWidth: 6
        radius: 3
        color: control.pressed ? Theme.textSecondary : Theme.scrollThumb
        opacity: control.active ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 160 } }
    }

    background: Item {}
}
