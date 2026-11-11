import QtQuick
import QtQuick.Controls

Item {
    id: root

    property var windowRoot: null

    AppFilterModel {
        id: topModel
        sourceModel: store.apps
        mode: "top"
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
            spacing: 18

            Column {
                spacing: 5
                Text {
                    text: "排行榜"
                    color: Theme.textPrimary
                    font.family: Theme.fontFamily
                    font.pixelSize: 30
                    font.weight: Font.Bold
                    font.letterSpacing: -0.7
                }
                Text {
                    text: "最受欢迎的 Linux 应用 · 共 " + topModel.count + " 款"
                    color: Theme.textTertiary
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                }
            }

            Rectangle {
                width: freeLabel.implicitWidth + 24
                height: 28
                radius: 14
                color: Theme.selection

                Text {
                    id: freeLabel
                    anchors.centerIn: parent
                    text: "免费应用"
                    color: Theme.textPrimary
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                }
            }

            Column {
                width: parent.width
                spacing: 0

                Repeater {
                    model: topModel

                    Item {
                        id: row
                        width: parent.width
                        height: 70

                        HoverHandler { id: hover }

                        Rectangle {
                            anchors.fill: parent
                            radius: 10
                            color: hover.hovered ? Theme.hover : "transparent"
                        }

                        Text {
                            x: 10
                            width: 34
                            anchors.verticalCenter: parent.verticalCenter
                            text: index + 1
                            color: index < 3 ? Theme.accent : Theme.textTertiary
                            font.family: Theme.fontFamily
                            font.pixelSize: 20
                            font.weight: Font.Bold
                            horizontalAlignment: Text.AlignHCenter
                        }

                        AppIcon {
                            x: 52
                            anchors.verticalCenter: parent.verticalCenter
                            size: 50
                            icon: model.icon
                            bg1: model.iconBg1
                            bg2: model.iconBg2
                            full: model.iconFull
                            fallbackText: model.name.charAt(0)
                        }

                        Column {
                            anchors.left: parent.left
                            anchors.leftMargin: 116
                            anchors.right: ratingRow.left
                            anchors.rightMargin: 20
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 3
                            Text {
                                width: parent.width
                                text: model.name
                                color: Theme.textPrimary
                                font.family: Theme.fontFamily
                                font.pixelSize: 14
                                font.weight: Font.DemiBold
                                elide: Text.ElideRight
                            }
                            Text {
                                width: parent.width
                                text: model.categoryName + "  ·  " + model.subtitle
                                color: Theme.textTertiary
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                                elide: Text.ElideRight
                            }
                        }

                        Row {
                            id: ratingRow
                            anchors.right: getButton.left
                            anchors.rightMargin: 22
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 6
                            StarRating { rating: model.rating }
                            Text {
                                text: model.rating.toFixed(1)
                                color: Theme.textTertiary
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                            }
                        }

                        GetButton {
                            id: getButton
                            anchors.right: parent.right
                            anchors.rightMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            appId: model.appId
                            appName: model.name
                            installed: model.installed
                            updatable: model.updatable
                            state: model.state
                            progress: model.progress
                        }

                        Rectangle {
                            anchors.left: parent.left
                            anchors.leftMargin: 104
                            anchors.right: parent.right
                            anchors.rightMargin: 8
                            anchors.bottom: parent.bottom
                            height: 1
                            color: Theme.separator
                            opacity: 0.6
                        }

                        MouseArea {
                            anchors.fill: parent
                            anchors.rightMargin: 100
                            cursorShape: Qt.PointingHandCursor
                            onClicked: if (root.windowRoot) root.windowRoot.openApp(model.appId)
                        }
                    }
                }
            }

            Item { width: 1; height: 24 }
        }
    }
}
