import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root

    property var windowRoot: null

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
                    text: "分类"
                    color: Theme.textPrimary
                    font.family: Theme.fontFamily
                    font.pixelSize: 30
                    font.weight: Font.Bold
                    font.letterSpacing: -0.7
                }
                Text {
                    text: "按类别浏览 App Store 中的 Linux 应用"
                    color: Theme.textTertiary
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                }
            }

            GridLayout {
                width: parent.width
                columns: 2
                columnSpacing: 12
                rowSpacing: 12

                Repeater {
                    model: store.categories

                    CategoryTile {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 144
                        categoryId: modelData.id
                        name: modelData.name
                        subtitle: modelData.subtitle
                        icon: modelData.icon
                        color1: modelData.color1
                        color2: modelData.color2
                        appCount: store.categoryCount(modelData.id)
                        windowRoot: root.windowRoot
                    }
                }
            }

            Item { width: 1; height: 20 }
        }
    }
}
