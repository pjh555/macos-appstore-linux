import QtQuick
import QtQuick.Controls

Item {
    id: root

    property var windowRoot: null

    AppFilterModel {
        id: updatesModel
        sourceModel: store.apps
        mode: "updates"
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
            spacing: 18

            Item {
                width: parent.width
                height: 58

                Column {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 5
                    Text {
                        text: "更新"
                        color: Theme.textPrimary
                        font.family: Theme.fontFamily
                        font.pixelSize: 30
                        font.weight: Font.Bold
                        font.letterSpacing: -0.7
                    }
                    Text {
                        text: store.scanning ? "正在检查更新…"
                                             : (updatesModel.count > 0
                                                ? "有 " + updatesModel.count + " 个应用可以更新"
                                                : "所有应用均为最新版本")
                        color: Theme.textTertiary
                        font.family: Theme.fontFamily
                        font.pixelSize: 13
                    }
                }

                Row {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 10

                    Rectangle {
                        width: checkLabel.implicitWidth + 26
                        height: 30
                        radius: 15
                        color: checkMouse.containsMouse ? Theme.controlHover : Theme.controlBg
                        border.width: 1
                        border.color: Theme.separator

                        Text {
                            id: checkLabel
                            anchors.centerIn: parent
                            text: "检查更新"
                            color: Theme.textPrimary
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                            font.weight: Font.DemiBold
                        }

                        MouseArea {
                            id: checkMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            enabled: !store.scanning
                            onClicked: store.refresh()
                        }
                    }

                    Rectangle {
                        width: allLabel.implicitWidth + 30
                        height: 30
                        radius: 15
                        color: updatesModel.count > 0 && !installer.busy
                               ? (allMouse.containsMouse ? Theme.accentHover : Theme.accent)
                               : Theme.controlBg
                        opacity: updatesModel.count > 0 && !installer.busy ? 1 : 0.55

                        Text {
                            id: allLabel
                            anchors.centerIn: parent
                            text: "全部更新"
                            color: updatesModel.count > 0 && !installer.busy ? "white" : Theme.textTertiary
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                            font.weight: Font.DemiBold
                        }

                        MouseArea {
                            id: allMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            enabled: updatesModel.count > 0 && !installer.busy
                            onClicked: installer.updateAll()
                        }
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 44
                radius: 10
                color: Theme.controlBg
                border.width: 1
                border.color: Theme.separator

                Icon {
                    id: statusIcon
                    anchors.left: parent.left
                    anchors.leftMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    width: 16
                    height: 16
                    name: store.updateCount > 0 ? "download" : "checkmark"
                    color: store.updateCount > 0 ? Theme.accent : Theme.success
                }

                Text {
                    anchors.left: statusIcon.right
                    anchors.leftMargin: 9
                    anchors.right: parent.right
                    anchors.rightMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    text: store.statusText + "  ·  更新来自 Ubuntu 软件源、GitHub Releases 与 Flathub"
                    color: Theme.textSecondary
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    elide: Text.ElideRight
                }
            }

            Column {
                width: parent.width
                spacing: 0
                visible: updatesModel.count > 0

                Repeater {
                    model: updatesModel

                    Item {
                        id: updateRow
                        width: parent.width
                        height: 82

                        HoverHandler { id: rowHover }

                        Rectangle {
                            anchors.fill: parent
                            radius: 10
                            color: rowHover.hovered ? Theme.hover : "transparent"
                        }

                        AppIcon {
                            x: 12
                            anchors.verticalCenter: parent.verticalCenter
                            size: 52
                            icon: model.icon
                            bg1: model.iconBg1
                            bg2: model.iconBg2
                            full: model.iconFull
                            fallbackText: model.name.charAt(0)
                        }

                        Column {
                            anchors.left: parent.left
                            anchors.leftMargin: 78
                            anchors.right: updateButton.left
                            anchors.rightMargin: 24
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
                                text: {
                                    const from = model.installedVersion !== "" ? model.installedVersion : "已安装版本";
                                    const to = model.latestVersion !== "" ? model.latestVersion : "最新版";
                                    return "版本 " + from + "  →  " + to;
                                }
                                color: Theme.textSecondary
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                                elide: Text.ElideRight
                            }

                            Text {
                                width: parent.width
                                text: model.whatsNew
                                color: Theme.textTertiary
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                                elide: Text.ElideRight
                            }
                        }

                        GetButton {
                            id: updateButton
                            anchors.right: parent.right
                            anchors.rightMargin: 10
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
                            anchors.leftMargin: 76
                            anchors.right: parent.right
                            anchors.rightMargin: 10
                            anchors.bottom: parent.bottom
                            height: 1
                            color: Theme.separator
                            opacity: 0.6
                        }

                        MouseArea {
                            anchors.fill: parent
                            anchors.rightMargin: 110
                            cursorShape: Qt.PointingHandCursor
                            onClicked: if (root.windowRoot) root.windowRoot.openApp(model.appId)
                        }
                    }
                }
            }

            EmptyState {
                width: parent.width
                visible: updatesModel.count === 0 && !store.scanning
                icon: "checkmark"
                title: "所有应用都是最新的"
                message: "App Store 会检查 Ubuntu 软件源、GitHub Releases 与 Flathub 中的新版本。"
                actionText: "探索更多应用"
                onActionClicked: if (root.windowRoot) root.windowRoot.goPage("discover")
            }

            Item { width: 1; height: 20 }
        }
    }
}
