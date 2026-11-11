import QtQuick

Item {
    id: root

    property color circleColor: "#ff5f57"
    property string glyph: "close"
    property bool glyphVisible: hover.hovered
    signal clicked(var mouse)

    implicitWidth: 13
    implicitHeight: 13

    HoverHandler {
        id: hover
    }

    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: root.circleColor
        border.width: 1
        border.color: Qt.rgba(0, 0, 0, 0.12)

        Icon {
            anchors.centerIn: parent
            width: 8
            height: 8
            name: root.glyph
            color: Qt.darker(root.circleColor, 3.0)
            strokeWidth: 2.4
            opacity: root.glyphVisible ? 0.85 : 0
            visible: opacity > 0

            Behavior on opacity {
                NumberAnimation { duration: 100 }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        cursorShape: Qt.ArrowCursor
        onClicked: mouse => root.clicked(mouse)
    }
}
