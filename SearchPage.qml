import QtQuick
import QtQuick.Controls

Item {
    id: root

    property var windowRoot: null

    AppFilterModel {
        id: searchModel
        sourceModel: store.apps
        mode: "search"
        query: root.windowRoot ? root.windowRoot.searchText : ""
        sortMode: "popularity"
    }

    ScrollView {
        id: scroll
        anchors.fill: parent
        contentWidth: availableWidth
        clip: true
        ScrollBar.vertical: MacScrollBar {}

        Column {
            x: 32
            y: 24
            width: Math.max(320, scroll.availableWidth - 64)
            spacing: 20

            Column {
                spacing: 5
                Text {
                    text: "搜索结果"
                    color: Theme.textPrimary
                    font.family: Theme.fontFamily
                    font.pixelSize: 30
                    font.weight: Font.Bold
                    font.letterSpacing: -0.7
                }
                Text {
                    text: "“" + (root.windowRoot ? root.windowRoot.searchText : "") + "” · "
                          + searchModel.count + " 个结果"
                    color: Theme.textTertiary
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                }
            }

            AppGrid {
                width: parent.width
                model: searchModel
                visible: searchModel.count > 0
                windowRoot: root.windowRoot
            }

            Column {
                width: parent.width
                visible: searchModel.count === 0
                spacing: 10

                EmptyState {
                    width: parent.width
                    icon: "search"
                    title: "没有找到匹配的应用"
                    message: "换个关键词试试，或者从下面的热门搜索开始。"
                }

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 8

                    Repeater {
                        model: ["笔记", "视频", "开发", "远程", "设计"]

                        Rectangle {
                            width: chipLabel.implicitWidth + 24
                            height: 29
                            radius: 14.5
                            color: chipMouse.containsMouse ? Theme.controlHover : Theme.controlBg
                            border.width: 1
                            border.color: Theme.separator

                            Text {
                                id: chipLabel
                                anchors.centerIn: parent
                                text: modelData
                                color: Theme.textSecondary
                                font.family: Theme.fontFamily
                                font.pixelSize: 12
                            }

                            MouseArea {
                                id: chipMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: if (root.windowRoot)
                                    root.windowRoot.searchText = modelData;
                            }
                        }
                    }
                }
            }

            Item { width: 1; height: 20 }
        }
    }
}
