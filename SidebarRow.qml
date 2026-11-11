import QtQuick

Item {
    id: root

    property string label: ""
    property string icon: ""
    property bool selected: false
    property int badge: 0
    signal clicked()

    implicitHeight: 34
    width: parent ? parent.width : 210

    Rectangle {
        anchors.fill: parent
        radius: 7
        color: root.selected ? Theme.selection
                             : (mouseArea.containsMouse ? Theme.hover : "transparent")

        Behavior on color { ColorAnimation { duration: 120 } }
    }

    LineIcon {
        id: rowIcon
        anchors.left: parent.left
        anchors.leftMargin: 9
        anchors.verticalCenter: parent.verticalCenter
        iconSize: 16
        name: root.icon
        opacityValue: root.selected ? 0.98 : 0.72

        Behavior on opacity { NumberAnimation { duration: 120 } }
    }

    Text {
        id: rowLabel
        anchors.left: rowIcon.right
        anchors.leftMargin: 9
        anchors.right: badgeItem.left
        anchors.rightMargin: 6
        anchors.verticalCenter: parent.verticalCenter
        text: root.label
        color: root.selected ? Theme.textPrimary : Theme.textSecondary
        font.family: Theme.fontFamily
        font.pixelSize: 13
        font.weight: root.selected ? Font.DemiBold : Font.Normal
        elide: Text.ElideRight
    }

    Rectangle {
        id: badgeItem
        anchors.right: parent.right
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        visible: root.badge > 0
        width: Math.max(18, badgeText.implicitWidth + 10)
        height: 17
        radius: 8.5
        color: Theme.accent

        Text {
            id: badgeText
            anchors.centerIn: parent
            text: root.badge
            color: "white"
            font.family: Theme.fontFamily
            font.pixelSize: 10
            font.weight: Font.DemiBold
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
