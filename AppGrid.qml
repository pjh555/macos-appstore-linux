import QtQuick
import QtQuick.Layouts

GridLayout {
    id: grid

    property var model: null
    property var windowRoot: null
    property int cardHeight: 200
    property int minimumCardWidth: 170

    columns: Math.max(1, Math.floor(width / 184))
    columnSpacing: 6
    rowSpacing: 4

    Repeater {
        model: grid.model
        AppCardDelegate {
            windowRoot: grid.windowRoot
            Layout.fillWidth: true
            Layout.preferredWidth: grid.minimumCardWidth
            Layout.minimumWidth: grid.minimumCardWidth
            Layout.maximumWidth: 220
            Layout.alignment: Qt.AlignHCenter | Qt.AlignTop
            Layout.preferredHeight: grid.cardHeight
        }
    }
}
