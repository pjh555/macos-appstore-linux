import QtQuick

Item {
    id: root

    property string icon: "search"
    property string title: ""
    property string message: ""
    property string actionText: ""
    signal actionClicked()

    implicitHeight: 260

    Column {
        anchors.centerIn: parent
        width: Math.min(parent.width - 80, 420)
        spacing: 10

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 58
            height: 58
            radius: 16
            color: Theme.controlBg

            Icon {
                anchors.centerIn: parent
                width: 27
                height: 27
                name: root.icon
                color: Theme.textTertiary
            }
        }

        Item { width: 1; height: 4 }

        Text {
            width: parent.width
            text: root.title
            color: Theme.textPrimary
            font.family: Theme.fontFamily
            font.pixelSize: 17
            font.weight: Font.DemiBold
            horizontalAlignment: Text.AlignHCenter
        }

        Text {
            width: parent.width
            text: root.message
            color: Theme.textTertiary
            font.family: Theme.fontFamily
            font.pixelSize: 12
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            lineHeight: 1.35
        }

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: root.actionText !== ""
            width: actionLabel.implicitWidth + 28
            height: 30
            radius: 15
            color: actionMouse.containsMouse ? Theme.accentHover : Theme.accent

            Text {
                id: actionLabel
                anchors.centerIn: parent
                text: root.actionText
                color: "white"
                font.family: Theme.fontFamily
                font.pixelSize: 12
                font.weight: Font.DemiBold
            }

            MouseArea {
                id: actionMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.actionClicked()
            }
        }
    }
}
