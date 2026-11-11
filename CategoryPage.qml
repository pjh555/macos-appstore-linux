import QtQuick
import QtQuick.Controls

Item {
    id: root

    property var windowRoot: null
    readonly property string categoryId: windowRoot ? windowRoot.activeCategory : ""

    AppFilterModel {
        id: categoryModel
        sourceModel: store.apps
        category: root.categoryId
        sortMode: "rating"
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
            spacing: 22

            Column {
                spacing: 5
                Text {
                    text: store.categoryName(root.categoryId)
                    color: Theme.textPrimary
                    font.family: Theme.fontFamily
                    font.pixelSize: 30
                    font.weight: Font.Bold
                    font.letterSpacing: -0.7
                }
                Text {
                    text: store.categorySubtitle(root.categoryId) + " · " + categoryModel.count + " 款应用"
                    color: Theme.textTertiary
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                }
            }

            Rectangle {
                width: parent.width
                height: 106
                radius: 14
                gradient: Gradient {
                    GradientStop {
                        position: 0.0
                        color: {
                            const category = store.categories.find(item => item.id === root.categoryId);
                            return category ? category.color1 : Theme.accent;
                        }
                    }
                    GradientStop {
                        position: 1.0
                        color: {
                            const category = store.categories.find(item => item.id === root.categoryId);
                            return category ? category.color2 : "#0057d9";
                        }
                    }
                }

                LineIcon {
                    id: bannerIcon
                    anchors.right: parent.right
                    anchors.rightMargin: 24
                    anchors.verticalCenter: parent.verticalCenter
                    iconSize: 62
                    alwaysWhite: true
                    opacityValue: 0.28
                    name: {
                        const category = store.categories.find(item => item.id === root.categoryId);
                        return category ? category.icon : "layout-grid";
                    }
                }

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 24
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 130
                    text: "在「" + store.categoryName(root.categoryId) + "」中发现更多"
                    color: "white"
                    font.family: Theme.fontFamily
                    font.pixelSize: 20
                    font.weight: Font.Bold
                    elide: Text.ElideRight
                }
            }

            AppGrid {
                width: parent.width
                model: categoryModel
                windowRoot: root.windowRoot
            }

            EmptyState {
                width: parent.width
                visible: categoryModel.count === 0
                icon: "grid"
                title: "这个分类暂时没有应用"
                message: "稍后再来看看，或者浏览其他分类。"
            }

            Item { width: 1; height: 20 }
        }
    }
}
