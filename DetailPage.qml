import QtQuick
import QtQuick.Controls

Item {
    id: root

    property var windowRoot: null
    property var app: ({})

    readonly property string currentId: windowRoot ? windowRoot.detailAppId : ""
    readonly property var infoRows: [
        { label: "开发者", value: app.developer || "—" },
        { label: "类别", value: app.categoryName || "—" },
        { label: "版本", value: (app.installed ? (app.installedVersion || app.version) : app.version) || "—" },
        { label: "大小", value: app.size || "—" },
        { label: "架构", value: app.architecture || "arm64" },
        { label: "兼容性", value: app.compatibility || ("Ubuntu · " + store.arch) },
        { label: "安装方式", value: methodLabel(app.method) }
    ]

    function refresh() {
        app = currentId === "" ? ({}) : store.appData(currentId);
    }

    function methodLabel(method) {
        switch (method) {
        case "apt": return "Ubuntu 软件源";
        case "githubDeb":
        case "githubAppImage": return "GitHub Releases";
        case "directDeb": return "官方 .deb";
        case "flatpak": return "Flathub";
        case "webapp": return "Web 应用";
        case "external": return "官网";
        default: return method || "—";
        }
    }

    function sourceDetail(method) {
        switch (method) {
        case "apt":
            return "通过 Ubuntu 官方软件源下载并安装，安装时需要管理员授权。";
        case "githubDeb":
        case "githubAppImage":
            return "从 GitHub Releases 自动选择适用于 arm64 的安装包，下载完成后自动安装。";
        case "directDeb":
            return "从开发者官方地址下载 arm64 安装包，下载完成后自动安装。";
        case "flatpak":
            return "通过 Flathub 安装到用户空间，不需要管理员权限，也不修改系统软件包。";
        case "webapp":
            return "创建一个本地 Web 应用启动项，使用浏览器的应用模式打开网页版；卸载时会删除启动项。";
        case "external":
            return "这个应用需要从官网下载。Steam 官方客户端目前只提供 x86_64 版本，当前 arm64 设备需要 FEX-Emu 或 Box64 等兼容层才能尝试运行。";
        default:
            return "下载完成后由 App Store 自动安装。";
        }
    }

    onCurrentIdChanged: refresh()

    Component.onCompleted: refresh()

    Connections {
        target: store
        function onAppChanged(id) {
            if (id === root.currentId)
                root.refresh();
        }
    }

    ScrollView {
        id: scroll
        anchors.fill: parent
        contentWidth: availableWidth
        clip: true
        ScrollBar.vertical: MacScrollBar {}

        Column {
            width: scroll.availableWidth
            spacing: 0

            Item {
                width: parent.width
                height: 286

                Rectangle {
                    anchors.fill: parent
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: root.app.heroColor1 || root.app.iconBg1 || "#1b1b1d" }
                        GradientStop { position: 1.0; color: root.app.heroColor2 || root.app.iconBg2 || "#0a84ff" }
                    }
                }

                Rectangle {
                    width: 430
                    height: 430
                    radius: 215
                    x: parent.width * 0.63
                    y: -230
                    color: Qt.rgba(1, 1, 1, 0.055)
                }

                Rectangle {
                    width: 300
                    height: 300
                    radius: 150
                    x: parent.width - 240
                    y: 100
                    color: Qt.rgba(0, 0, 0, 0.10)
                }

                Image {
                    anchors.right: parent.right
                    anchors.rightMargin: -50
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.min(460, root.width * 0.44)
                    height: width
                    source: root.app.icon ? Theme.assetRoot + "icons/" + root.app.icon : ""
                    fillMode: Image.PreserveAspectFit
                    opacity: 0.08
                }

                Row {
                    anchors.left: parent.left
                    anchors.leftMargin: 36
                    anchors.right: parent.right
                    anchors.rightMargin: 36
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 22

                    AppIcon {
                        id: heroIcon
                        width: 112
                        height: 112
                        size: 112
                        icon: root.app.icon || ""
                        bg1: root.app.iconBg1 || "#0a84ff"
                        bg2: root.app.iconBg2 || "#0057d9"
                        full: root.app.iconFull || false
                        fallbackText: root.app.name ? root.app.name.charAt(0) : ""
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Column {
                        id: heroTextColumn
                        width: Math.min(560, parent.width - 160)
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 8

                        Rectangle {
                            visible: root.app.featured === true
                            width: featuredText.implicitWidth + 18
                            height: 22
                            radius: 11
                            color: Qt.rgba(1, 1, 1, 0.15)
                            border.width: 1
                            border.color: Qt.rgba(1, 1, 1, 0.16)

                            Text {
                                id: featuredText
                                anchors.centerIn: parent
                                text: "编辑精选"
                                color: "white"
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                                font.weight: Font.DemiBold
                            }
                        }

                        Text {
                            width: parent.width
                            text: root.app.name || ""
                            color: "white"
                            font.family: Theme.fontFamily
                            font.pixelSize: 30
                            font.weight: Font.Bold
                            font.letterSpacing: -0.6
                            elide: Text.ElideRight
                        }

                        Text {
                            width: parent.width
                            text: root.app.subtitle || ""
                            color: Qt.rgba(1, 1, 1, 0.78)
                            font.family: Theme.fontFamily
                            font.pixelSize: 14
                            elide: Text.ElideRight
                        }

                        Flow {
                            width: parent.width
                            spacing: 8

                            Row {
                                spacing: 5
                                StarRating { rating: root.app.rating || 0; starSize: 10 }
                                Text {
                                    text: (root.app.rating || 0).toFixed(1)
                                    color: Qt.rgba(1, 1, 1, 0.70)
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 11
                                }
                            }

                            Text {
                                text: root.app.categoryName || ""
                                color: Qt.rgba(1, 1, 1, 0.70)
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                            }
                            Text {
                                text: (root.app.architecture || "arm64") + " · " + (root.app.size || "")
                                color: Qt.rgba(1, 1, 1, 0.70)
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                            }
                        }

                        Row {
                            spacing: 10

                            GetButton {
                                large: true
                                appId: root.app.appId || ""
                                appName: root.app.name || ""
                                installed: root.app.installed || false
                                updatable: root.app.updatable || false
                                state: root.app.state || "idle"
                                progress: root.app.progress || 0
                            }

                            Rectangle {
                                visible: heroTextColumn.width > 340
                                width: siteLabel.implicitWidth + 28
                                height: 34
                                radius: 17
                                color: siteMouse.containsMouse ? Qt.rgba(0, 0, 0, 0.20) : Qt.rgba(0, 0, 0, 0.13)
                                border.width: 1
                                border.color: Qt.rgba(1, 1, 1, 0.18)

                                Row {
                                    id: siteRow
                                    anchors.centerIn: parent
                                    spacing: 5
                                    Text {
                                        id: siteLabel
                                        text: "开发者网站"
                                        color: "white"
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 12
                                        font.weight: Font.DemiBold
                                    }
                                    Icon {
                                        width: 10
                                        height: 10
                                        name: "external"
                                        color: "white"
                                    }
                                }

                                MouseArea {
                                    id: siteMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: if (root.app.homepage) store.openUrl(root.app.homepage)
                                }
                            }

                            Rectangle {
                                visible: root.app.installed === true
                                width: 80
                                height: 34
                                radius: 17
                                color: uninstallMouse.containsMouse ? Qt.rgba(1, 0.27, 0.23, 0.18)
                                                                    : Qt.rgba(0, 0, 0, 0.12)
                                border.width: 1
                                border.color: Qt.rgba(1, 1, 1, 0.16)

                                Row {
                                    anchors.centerIn: parent
                                    spacing: 5
                                    Icon {
                                        width: 12
                                        height: 12
                                        name: "trash"
                                        color: Theme.danger
                                    }
                                    Text {
                                        text: "卸载"
                                        color: Theme.danger
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 12
                                        font.weight: Font.DemiBold
                                    }
                                }

                                MouseArea {
                                    id: uninstallMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: if (root.windowRoot)
                                        root.windowRoot.requestUninstall(root.app.appId, root.app.name)
                                }
                            }
                        }

                        Text {
                            visible: root.app.installed === true
                            text: root.app.updatable
                                  ? "已安装 " + (root.app.installedVersion || "") + "，可更新至 " + (root.app.latestVersion || "最新版")
                                  : "已安装" + (root.app.installedVersion ? " · " + root.app.installedVersion : "")
                            color: Qt.rgba(1, 1, 1, 0.72)
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                        }
                    }
                }
            }

            Column {
                x: 32
                width: Math.max(320, scroll.availableWidth - 64)
                spacing: 28

                Item { width: 1; height: 2 }

                Column {
                    width: parent.width
                    spacing: 10

                    SectionHeader {
                        width: parent.width
                        title: "预览"
                        subtitle: "来自应用的界面示意"
                    }

                    Row {
                        width: parent.width
                        spacing: 10

                        Repeater {
                            model: 3
                            MockShot {
                                width: (parent.width - 20) / 3
                                height: Math.max(120, width * 0.58)
                                appName: root.app.shortName || root.app.name || ""
                                icon: root.app.icon || ""
                                color1: root.app.heroColor1 || root.app.iconBg1 || "#0a84ff"
                                color2: root.app.heroColor2 || root.app.iconBg2 || "#0057d9"
                                iconBg1: root.app.iconBg1 || "#0a84ff"
                                iconBg2: root.app.iconBg2 || "#0057d9"
                                iconFull: root.app.iconFull || false
                                variant: index
                            }
                        }
                    }
                }

                Flow {
                    width: parent.width
                    spacing: 24

                    Column {
                        width: root.width < 760 ? parent.width : Math.max(280, parent.width - 324)
                        spacing: 22

                        Column {
                            width: parent.width
                            spacing: 8
                            Text {
                                text: "关于此应用"
                                color: Theme.textPrimary
                                font.family: Theme.fontFamily
                                font.pixelSize: 19
                                font.weight: Font.Bold
                                font.letterSpacing: -0.25
                            }
                            Text {
                                width: parent.width
                                text: root.app.longDescription || root.app.description || ""
                                color: Theme.textSecondary
                                font.family: Theme.fontFamily
                                font.pixelSize: 13
                                lineHeight: 1.5
                                wrapMode: Text.WordWrap
                            }
                        }

                        Rectangle {
                            width: parent.width
                            height: whatsNewColumn.implicitHeight + 32
                            radius: 12
                            color: Theme.cardBg
                            border.width: 1
                            border.color: Theme.cardBorder

                            Column {
                                id: whatsNewColumn
                                x: 16
                                y: 16
                                width: parent.width - 32
                                spacing: 7

                                Row {
                                    width: parent.width

                                    Text {
                                        text: "新功能"
                                        color: Theme.textPrimary
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 14
                                        font.weight: Font.Bold
                                    }

                                    Item { width: parent.width - 190; height: 1 }

                                    Text {
                                        text: "版本 " + (root.app.version || "")
                                        color: Theme.textTertiary
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 11
                                    }
                                }

                                Text {
                                    width: parent.width
                                    text: root.app.whatsNew || "性能优化与问题修复。"
                                    color: Theme.textSecondary
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 12
                                    lineHeight: 1.4
                                    wrapMode: Text.WordWrap
                                }
                            }
                        }
                    }

                    Column {
                        width: root.width < 760 ? parent.width : 300
                        spacing: 14

                        Rectangle {
                            width: parent.width
                            height: infoColumn.implicitHeight + 32
                            radius: 12
                            color: Theme.cardBg
                            border.width: 1
                            border.color: Theme.cardBorder

                            Column {
                                id: infoColumn
                                x: 16
                                y: 16
                                width: parent.width - 32
                                spacing: 0

                                Text {
                                    text: "信息"
                                    color: Theme.textPrimary
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 14
                                    font.weight: Font.Bold
                                }

                                Repeater {
                                    model: root.infoRows
                                    Item {
                                        width: infoColumn.width
                                        height: 28
                                        Text {
                                            anchors.left: parent.left
                                            anchors.verticalCenter: parent.verticalCenter
                                            width: 72
                                            text: modelData.label
                                            color: Theme.textTertiary
                                            font.family: Theme.fontFamily
                                            font.pixelSize: 11
                                        }
                                        Text {
                                            anchors.left: parent.left
                                            anchors.leftMargin: 76
                                            anchors.right: parent.right
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: modelData.value
                                            color: Theme.textSecondary
                                            font.family: Theme.fontFamily
                                            font.pixelSize: 11
                                            horizontalAlignment: Text.AlignRight
                                            elide: Text.ElideRight
                                        }
                                    }
                                }
                            }
                        }

                        Rectangle {
                            width: parent.width
                            height: sourceColumn.implicitHeight + 32
                            radius: 12
                            color: Theme.cardBg
                            border.width: 1
                            border.color: Theme.cardBorder

                            Column {
                                id: sourceColumn
                                x: 16
                                y: 16
                                width: parent.width - 32
                                spacing: 8

                                Row {
                                    spacing: 7
                                    Rectangle {
                                        width: 26
                                        height: 26
                                        radius: 7
                                        color: Theme.controlBg
                                        LineIcon {
                                            anchors.centerIn: parent
                                            iconSize: 15
                                            name: root.app.method === "flatpak" ? "cloud-download"
                                                                               : (root.app.method === "apt" ? "server" : "download")
                                            opacityValue: 0.85
                                        }
                                    }
                                    Text {
                                        text: root.app.source || root.methodLabel(root.app.method)
                                        color: Theme.textPrimary
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 12
                                        font.weight: Font.DemiBold
                                    }
                                }

                                Text {
                                    width: parent.width
                                    text: root.sourceDetail(root.app.method)
                                    color: Theme.textTertiary
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 11
                                    lineHeight: 1.4
                                    wrapMode: Text.WordWrap
                                }

                                Rectangle {
                                    width: parent.width
                                    height: 29
                                    radius: 8
                                    color: homepageMouse.containsMouse ? Theme.controlHover : Theme.controlBg
                                    border.width: 1
                                    border.color: Theme.separator

                                    Text {
                                        anchors.centerIn: parent
                                        text: "访问官方网站"
                                        color: Theme.accent
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 11
                                        font.weight: Font.DemiBold
                                    }

                                    MouseArea {
                                        id: homepageMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: if (root.app.homepage) store.openUrl(root.app.homepage)
                                    }
                                }
                            }
                        }
                    }
                }

                Item { width: 1; height: 18 }
            }
        }
    }

    EmptyState {
        anchors.centerIn: parent
        width: 420
        visible: !root.app || !root.app.appId
        icon: "info"
        title: "找不到这个应用"
        message: "应用可能已从目录中移除。"
        actionText: "返回探索"
        onActionClicked: if (root.windowRoot) root.windowRoot.goPage("discover")
    }
}
