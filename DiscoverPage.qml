import QtQuick
import QtQuick.Controls

Item {
    id: root

    property var windowRoot: null

    AppFilterModel {
        id: workModel
        sourceModel: store.apps
        category: "work"
        sortMode: "rating"
    }
    AppFilterModel {
        id: createModel
        sourceModel: store.apps
        category: "create"
        sortMode: "rating"
    }
    AppFilterModel {
        id: developModel
        sourceModel: store.apps
        category: "develop"
        sortMode: "rating"
    }
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
            id: content
            x: 32
            y: 14
            width: Math.max(320, scroll.availableWidth - 64)
            spacing: 14

            Column {
                width: parent.width
                spacing: 5
                Text {
                    text: "探索"
                    color: Theme.textPrimary
                    font.family: Theme.fontFamily
                    font.pixelSize: 30
                    font.weight: Font.Bold
                    font.letterSpacing: -0.7
                }
                Text {
                    text: "为你的 Linux 桌面精挑细选"
                    color: Theme.textTertiary
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                }
            }

            FeaturedCarousel {
                width: parent.width
                windowRoot: root.windowRoot
            }

            AppRow {
                width: parent.width
                title: "效率精选"
                subtitle: "让每天的工作更轻松一点"
                model: workModel
                windowRoot: root.windowRoot
            }

            AppRow {
                width: parent.width
                title: "创意工坊"
                subtitle: "绘画、设计、三维与影像创作"
                model: createModel
                windowRoot: root.windowRoot
            }

            AppRow {
                width: parent.width
                title: "开发者工具"
                subtitle: "写代码、管版本、连远程"
                model: developModel
                windowRoot: root.windowRoot
            }

            Column {
                width: parent.width
                spacing: 2

                SectionHeader {
                    width: parent.width
                    title: "热门排行"
                    subtitle: "看看大家最近在安装什么"
                    showAction: true
                    actionText: "查看全部"
                    onActionClicked: if (root.windowRoot) root.windowRoot.goPage("top")
                }

                ListView {
                    width: parent.width
                    height: Math.min(5, topModel.count) * 64
                    interactive: false
                    clip: true
                    model: topModel

                    delegate: Item {
                        id: topRow
                        width: content.width
                        height: 64

                        HoverHandler { id: rowHover }

                        Rectangle {
                            anchors.fill: parent
                            radius: 10
                            color: rowHover.hovered ? Theme.hover : "transparent"
                        }

                        Text {
                            x: 8
                            anchors.verticalCenter: parent.verticalCenter
                            width: 26
                            text: index + 1
                            color: index < 3 ? Theme.accent : Theme.textTertiary
                            font.family: Theme.fontFamily
                            font.pixelSize: 17
                            font.weight: Font.Bold
                            horizontalAlignment: Text.AlignHCenter
                        }

                        AppIcon {
                            x: 42
                            anchors.verticalCenter: parent.verticalCenter
                            size: 44
                            icon: model.icon
                            bg1: model.iconBg1
                            bg2: model.iconBg2
                            full: model.iconFull
                            fallbackText: model.name.charAt(0)
                        }

                        Column {
                            anchors.left: parent.left
                            anchors.leftMargin: 98
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 330
                            spacing: 2
                            Text {
                                text: model.name
                                color: Theme.textPrimary
                                font.family: Theme.fontFamily
                                font.pixelSize: 13
                                font.weight: Font.DemiBold
                                elide: Text.ElideRight
                                width: parent.width
                            }
                            Text {
                                text: model.categoryName + "  ·  " + model.subtitle
                                color: Theme.textTertiary
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                                elide: Text.ElideRight
                                width: parent.width
                            }
                        }

                        Row {
                            anchors.right: parent.right
                            anchors.rightMargin: 104
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 5
                            StarRating {
                                rating: model.rating
                            }
                            Text {
                                text: model.rating.toFixed(1)
                                color: Theme.textTertiary
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                            }
                        }

                        GetButton {
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

                        MouseArea {
                            anchors.fill: parent
                            anchors.rightMargin: 90
                            cursorShape: Qt.PointingHandCursor
                            onClicked: if (root.windowRoot) root.windowRoot.openApp(model.appId)
                        }
                    }
                }
            }

            Item {
                width: parent.width
                height: 26

                Text {
                    anchors.centerIn: parent
                    text: "点击应用查看详情 · 下载后自动安装 · 更新来自 Ubuntu 软件源、GitHub 与 Flathub"
                    color: Theme.textTertiary
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                    opacity: 0.7
                }
            }
        }
    }
}
