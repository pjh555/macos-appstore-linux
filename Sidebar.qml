import QtQuick

Item {
    id: root

    property var windowRoot: null
    property real cornerRadius: Theme.windowRadius

    Rectangle {
        anchors.fill: parent
        topLeftRadius: root.cornerRadius
        bottomLeftRadius: root.cornerRadius
        topRightRadius: 0
        bottomRightRadius: 0
        gradient: Gradient {
            GradientStop { position: 0.0; color: Theme.sidebarBgTop }
            GradientStop { position: 1.0; color: Theme.sidebarBg }
        }
    }

    Item {
        id: header
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: Theme.titlebarHeight

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton
            onPressed: if (root.windowRoot) root.windowRoot.startSystemMove()
            onDoubleClicked: if (root.windowRoot) root.windowRoot.toggleMaximize()
        }

        Row {
            anchors.left: parent.left
            anchors.leftMargin: 19
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8
            z: 2

            TrafficLight {
                circleColor: Theme.trafficRed
                glyph: "close"
                onClicked: Qt.quit()
            }
            TrafficLight {
                circleColor: Theme.trafficYellow
                glyph: "minimize"
                onClicked: if (root.windowRoot) root.windowRoot.showMinimized()
            }
            TrafficLight {
                circleColor: Theme.trafficGreen
                glyph: "maximize"
                onClicked: if (root.windowRoot) root.windowRoot.toggleMaximize()
            }
        }
    }

    Column {
        id: navColumn
        anchors.top: header.bottom
        anchors.topMargin: 6
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        spacing: 2

        SidebarRow {
            label: "探索"
            icon: "compass"
            selected: root.windowRoot && root.windowRoot.page === "discover" && root.windowRoot.searchText.trim() === ""
            onClicked: root.windowRoot.goPage("discover")
        }
        SidebarRow {
            label: "排行榜"
            icon: "chart-bar"
            selected: root.windowRoot && root.windowRoot.page === "top" && root.windowRoot.searchText.trim() === ""
            onClicked: root.windowRoot.goPage("top")
        }

        Item { width: 1; height: 13 }

        Text {
            x: 9
            text: "类别"
            color: Theme.textTertiary
            font.family: Theme.fontFamily
            font.pixelSize: 10
            font.weight: Font.DemiBold
            font.letterSpacing: 0.8
            font.capitalization: Font.AllUppercase
        }

        SidebarRow {
            label: "创意"
            icon: "brush"
            selected: root.windowRoot && root.windowRoot.page === "category"
                      && root.windowRoot.activeCategory === "create"
                      && root.windowRoot.searchText.trim() === ""
            onClicked: root.windowRoot.openCategory("create")
        }
        SidebarRow {
            label: "效率"
            icon: "briefcase"
            selected: root.windowRoot && root.windowRoot.page === "category"
                      && root.windowRoot.activeCategory === "work"
                      && root.windowRoot.searchText.trim() === ""
            onClicked: root.windowRoot.openCategory("work")
        }
        SidebarRow {
            label: "娱乐"
            icon: "device-gamepad-2"
            selected: root.windowRoot && root.windowRoot.page === "category"
                      && root.windowRoot.activeCategory === "play"
                      && root.windowRoot.searchText.trim() === ""
            onClicked: root.windowRoot.openCategory("play")
        }
        SidebarRow {
            label: "开发"
            icon: "code"
            selected: root.windowRoot && root.windowRoot.page === "category"
                      && root.windowRoot.activeCategory === "develop"
                      && root.windowRoot.searchText.trim() === ""
            onClicked: root.windowRoot.openCategory("develop")
        }

        Item { width: 1; height: 8 }

        SidebarRow {
            label: "全部分类"
            icon: "layout-grid"
            selected: root.windowRoot && root.windowRoot.searchText.trim() === ""
                      && (root.windowRoot.page === "categories"
                          || (root.windowRoot.page === "category"
                              && ["utilities", "network"].indexOf(root.windowRoot.activeCategory) >= 0))
            onClicked: root.windowRoot.goPage("categories")
        }
        SidebarRow {
            label: "更新"
            icon: "cloud-download"
            badge: store.updateCount
            selected: root.windowRoot && root.windowRoot.page === "updates" && root.windowRoot.searchText.trim() === ""
            onClicked: root.windowRoot.goPage("updates")
        }
        SidebarRow {
            label: "已安装"
            icon: "check"
            selected: root.windowRoot && root.windowRoot.page === "installed" && root.windowRoot.searchText.trim() === ""
            onClicked: root.windowRoot.goPage("installed")
        }
    }

    Item {
        id: accountArea
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 10
        height: 46

        Rectangle {
            anchors.fill: parent
            radius: 8
            color: accountMouse.containsMouse ? Theme.hover : "transparent"
            Behavior on color { ColorAnimation { duration: 120 } }
        }

        Rectangle {
            id: avatar
            anchors.left: parent.left
            anchors.leftMargin: 6
            anchors.verticalCenter: parent.verticalCenter
            width: 28
            height: 28
            radius: 14
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#5e5ce6" }
                GradientStop { position: 1.0; color: "#0a84ff" }
            }
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.22)

            Text {
                anchors.centerIn: parent
                text: "X"
                color: "white"
                font.family: Theme.fontFamily
                font.pixelSize: 13
                font.weight: Font.Bold
            }
        }

        Column {
            anchors.left: avatar.right
            anchors.leftMargin: 9
            anchors.right: themeButton.left
            anchors.rightMargin: 6
            anchors.verticalCenter: parent.verticalCenter
            spacing: 1
            Text {
                text: "xiaomi"
                color: Theme.textPrimary
                font.family: Theme.fontFamily
                font.pixelSize: 12
                font.weight: Font.DemiBold
                elide: Text.ElideRight
                width: parent.width
            }
            Text {
                text: "本地账户 · 无需登录"
                color: Theme.textTertiary
                font.family: Theme.fontFamily
                font.pixelSize: 10
                elide: Text.ElideRight
                width: parent.width
            }
        }

        Rectangle {
            id: themeButton
            anchors.right: parent.right
            anchors.rightMargin: 5
            anchors.verticalCenter: parent.verticalCenter
            width: 27
            height: 27
            radius: 7
            color: themeMouse.containsMouse ? Theme.controlHover : Theme.controlBg
            Icon {
                anchors.centerIn: parent
                width: 14
                height: 14
                name: Theme.dark ? "sun" : "moon"
                color: Theme.textSecondary
            }
            MouseArea {
                id: themeMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    Theme.dark = !Theme.dark;
                    if (root.windowRoot)
                        root.windowRoot.showToast(Theme.dark ? "已切换到深色外观" : "已切换到浅色外观", false);
                }
            }
        }

        MouseArea {
            id: accountMouse
            anchors.fill: parent
            anchors.rightMargin: 34
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: if (root.windowRoot)
                root.windowRoot.showToast("本地账户：所有应用直接安装到这台设备", false)
        }
    }

    Rectangle {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 1
        color: Theme.separator
    }
}
