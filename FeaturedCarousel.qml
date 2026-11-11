import QtQuick

Item {
    id: root

    property var windowRoot: null
    implicitHeight: 264

    AppFilterModel {
        id: featuredModel
        sourceModel: store.apps
        mode: "featured"
    }

    readonly property int page: Math.round(list.contentX / Math.max(1, list.width))

    ListView {
        id: list
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: 240
        orientation: ListView.Horizontal
        snapMode: ListView.SnapOneItem
        boundsBehavior: Flickable.StopAtBounds
        clip: true
        spacing: 0
        model: featuredModel

        delegate: HeroCard {
            width: list.width
            height: 240
            appId: model.appId
            name: model.name
            heroTitle: model.heroTitle
            heroSubtitle: model.heroSubtitle
            heroTag: model.heroTag
            color1: model.heroColor1
            color2: model.heroColor2
            icon: model.icon
            iconBg1: model.iconBg1
            iconBg2: model.iconBg2
            iconFull: model.iconFull
            windowRoot: root.windowRoot
        }
    }

    HoverHandler { id: hoverHandler }

    Timer {
        interval: 6800
        repeat: true
        running: featuredModel.count > 1 && !hoverHandler.hovered && list.moving === false
        onTriggered: {
            const next = (root.page + 1) % featuredModel.count;
            list.positionViewAtIndex(next, ListView.Beginning);
        }
    }

    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        spacing: 7

        Repeater {
            model: featuredModel.count
            Rectangle {
                width: index === root.page ? 18 : 6
                height: 6
                radius: 3
                color: index === root.page ? Theme.textPrimary : Theme.textTertiary
                opacity: index === root.page ? 0.95 : 0.42

                Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                Behavior on opacity { NumberAnimation { duration: 120 } }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: list.positionViewAtIndex(index, ListView.Beginning)
                }
            }
        }
    }
}
