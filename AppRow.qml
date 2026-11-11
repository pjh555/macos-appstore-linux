import QtQuick

Item {
    id: root

    property string title: ""
    property string subtitle: ""
    property string actionText: "查看全部"
    property bool showAction: false
    property var model: null
    property var windowRoot: null

    implicitHeight: 230

    SectionHeader {
        id: header
        width: parent.width
        title: root.title
        subtitle: root.subtitle
        actionText: root.actionText
        showAction: root.showAction
        onActionClicked: if (root.windowRoot) root.windowRoot.goPage("categories")
    }

    ListView {
        id: list
        anchors.top: header.bottom
        anchors.topMargin: 8
        anchors.left: parent.left
        anchors.right: parent.right
        height: 180
        orientation: ListView.Horizontal
        spacing: 4
        clip: true
        model: root.model
        boundsBehavior: Flickable.StopAtBounds

        delegate: AppCardDelegate {
            width: 166
            height: 180
            windowRoot: root.windowRoot
        }

        WheelHandler {
            onWheel: event => {
                if (Math.abs(event.angleDelta.y) > Math.abs(event.angleDelta.x))
                    list.contentX = Math.max(0, Math.min(list.contentWidth - list.width,
                                                          list.contentX - event.angleDelta.y));
            }
        }
    }
}
