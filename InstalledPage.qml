import QtQuick
import QtQuick.Controls

Item {
    id: root

    property var windowRoot: null

    AppFilterModel {
        id: installedModel
        sourceModel: store.apps
        mode: "installed"
        sortMode: "name"
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
                    text: "已安装"
                    color: Theme.textPrimary
                    font.family: Theme.fontFamily
                    font.pixelSize: 30
                    font.weight: Font.Bold
                    font.letterSpacing: -0.7
                }
                Text {
                    text: installedModel.count + " 款来自 App Store 的应用已安装在这台设备上"
                    color: Theme.textTertiary
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                }
            }

            AppGrid {
                width: parent.width
                model: installedModel
                windowRoot: root.windowRoot
            }

            EmptyState {
                width: parent.width
                visible: installedModel.count === 0
                icon: "download"
                title: "还没有安装应用"
                message: "去探索页面挑选一些应用吧。下载完成后会自动安装并出现在这里。"
                actionText: "去探索"
                onActionClicked: if (root.windowRoot) root.windowRoot.goPage("discover")
            }

            Item { width: 1; height: 20 }
        }
    }
}
