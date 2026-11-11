import QtQuick

Item {
    id: root

    property string title: ""
    property string subtitle: ""
    property string actionText: "查看全部"
    property bool showAction: false
    signal actionClicked()

    implicitHeight: 44

    Column {
        anchors.left: parent.left
        anchors.right: actionArea.left
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2

        Text {
            text: root.title
            color: Theme.textPrimary
            font.family: Theme.fontFamily
            font.pixelSize: 19
            font.weight: Font.Bold
            font.letterSpacing: -0.25
        }

        Text {
            visible: root.subtitle !== ""
            text: root.subtitle
            color: Theme.textTertiary
            font.family: Theme.fontFamily
            font.pixelSize: 12
            elide: Text.ElideRight
            width: parent.width
        }
    }

    Item {
        id: actionArea
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: root.showAction ? actionRow.implicitWidth : 0
        height: 24
        visible: root.showAction

        Row {
            id: actionRow
            anchors.centerIn: parent
            spacing: 2
            Text {
                text: root.actionText
                color: Theme.accent
                font.family: Theme.fontFamily
                font.pixelSize: 12
                font.weight: Font.DemiBold
            }
            Icon {
                width: 11
                height: 11
                name: "chevron-right"
                color: Theme.accent
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        MouseArea {
            anchors.fill: parent
            enabled: root.showAction
            cursorShape: Qt.PointingHandCursor
            onClicked: root.actionClicked()
        }
    }
}
