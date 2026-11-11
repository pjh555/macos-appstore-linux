import QtQuick

Item {
    id: root

    property string categoryId: ""
    property string name: ""
    property string subtitle: ""
    property string icon: ""
    property string color1: "#0a84ff"
    property string color2: "#0057d9"
    property int appCount: 0
    property var windowRoot: null

    implicitHeight: 144
    clip: true

    HoverHandler { id: hover }

    Rectangle {
        anchors.fill: parent
        radius: 14
        gradient: Gradient {
            GradientStop { position: 0.0; color: root.color1 }
            GradientStop { position: 1.0; color: root.color2 }
        }
        scale: hover.hovered ? 1.012 : 1.0

        Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

        LineIcon {
            anchors.right: parent.right
            anchors.rightMargin: 18
            anchors.verticalCenter: parent.verticalCenter
            iconSize: 84
            name: root.icon
            alwaysWhite: true
            opacityValue: 0.18
        }

        Rectangle {
            x: 20
            y: 20
            width: 40
            height: 40
            radius: 10
            color: Qt.rgba(1, 1, 1, 0.16)

            LineIcon {
                anchors.centerIn: parent
                iconSize: 22
                name: root.icon
                alwaysWhite: true
            }
        }

        Text {
            anchors.left: parent.left
            anchors.leftMargin: 20
            anchors.right: parent.right
            anchors.rightMargin: 20
            anchors.top: parent.top
            anchors.topMargin: 75
            text: root.name
            color: "white"
            font.family: Theme.fontFamily
            font.pixelSize: 20
            font.weight: Font.Bold
            font.letterSpacing: -0.3
        }

        Text {
            anchors.left: parent.left
            anchors.leftMargin: 20
            anchors.right: parent.right
            anchors.rightMargin: 20
            anchors.top: parent.top
            anchors.topMargin: 101
            text: root.subtitle + "  ·  " + root.appCount + " 个应用"
            color: Qt.rgba(1, 1, 1, 0.75)
            font.family: Theme.fontFamily
            font.pixelSize: 11
            elide: Text.ElideRight
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: if (root.windowRoot) root.windowRoot.openCategory(root.categoryId)
    }
}
