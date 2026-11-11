import QtQuick

Item {
    id: root

    property string appId: ""
    property string appName: ""
    property var currentApp: ({})

    signal confirmed(string appId)
    signal cancelled()

    visible: false
    enabled: visible
    z: 100

    function open(appIdValue, nameValue) {
        appId = appIdValue;
        appName = nameValue;
        currentApp = store.appData(appIdValue);
        visible = true;
        openAnimation.restart();
    }

    function close() {
        visible = false;
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.dimBg

        MouseArea {
            anchors.fill: parent
            onClicked: {}
        }
    }

    Rectangle {
        id: card
        width: 430
        height: 258
        anchors.centerIn: parent
        radius: 16
        color: Theme.glassBg
        border.width: 1
        border.color: Theme.glassBorder
        scale: 0.96
        opacity: 0

        ParallelAnimation {
            id: openAnimation
            NumberAnimation { target: card; property: "opacity"; from: 0; to: 1; duration: 180 }
            NumberAnimation { target: card; property: "scale"; from: 0.96; to: 1; duration: 220; easing.type: Easing.OutCubic }
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
        }

        AppIcon {
            id: appIcon
            x: 24
            y: 22
            size: 54
            icon: root.currentApp.icon || ""
            bg1: root.currentApp.iconBg1 || "#0a84ff"
            bg2: root.currentApp.iconBg2 || "#0057d9"
            full: root.currentApp.iconFull || false
            fallbackText: root.appName.length > 0 ? root.appName.charAt(0) : ""
        }

        Column {
            x: 92
            y: 26
            width: parent.width - 116
            spacing: 4
            Text {
                text: "卸载「" + root.appName + "」？"
                color: Theme.textPrimary
                font.family: Theme.fontFamily
                font.pixelSize: 17
                font.weight: Font.Bold
                elide: Text.ElideRight
                width: parent.width
            }
            Text {
                text: "应用将从这台设备上移除"
                color: Theme.textTertiary
                font.family: Theme.fontFamily
                font.pixelSize: 11
            }
        }

        Text {
            x: 24
            y: 94
            width: parent.width - 48
            text: "通过 App Store 安装的应用文件会被删除。部分应用的个人数据、配置或缓存可能会保留。"
            color: Theme.textSecondary
            font.family: Theme.fontFamily
            font.pixelSize: 12
            lineHeight: 1.4
            wrapMode: Text.WordWrap
        }

        Rectangle {
            x: 24
            y: 158
            width: parent.width - 48
            height: 36
            radius: 8
            color: Theme.controlBg

            Icon {
                id: warningIcon
                anchors.left: parent.left
                anchors.leftMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                width: 14
                height: 14
                name: "warning"
                color: Theme.warning
            }

            Text {
                anchors.left: warningIcon.right
                anchors.leftMargin: 7
                anchors.right: parent.right
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                text: "此操作不会删除你在其他设备上的数据。"
                color: Theme.textTertiary
                font.family: Theme.fontFamily
                font.pixelSize: 10
                elide: Text.ElideRight
            }
        }

        Row {
            x: 24
            y: parent.height - 58
            width: parent.width - 48
            spacing: 10

            Item { width: Math.max(0, parent.width - 206); height: 1 }

            Rectangle {
                width: 86
                height: 32
                radius: 8
                color: cancelMouse.containsMouse ? Theme.controlHover : Theme.controlBg
                border.width: 1
                border.color: Theme.separator

                Text {
                    anchors.centerIn: parent
                    text: "取消"
                    color: Theme.textPrimary
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                }

                MouseArea {
                    id: cancelMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        root.close();
                        root.cancelled();
                    }
                }
            }

            Rectangle {
                width: 100
                height: 32
                radius: 8
                color: removeMouse.containsMouse ? "#ff6961" : Theme.danger

                Text {
                    anchors.centerIn: parent
                    text: "卸载"
                    color: "white"
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                }

                MouseArea {
                    id: removeMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        const id = root.appId;
                        root.close();
                        root.confirmed(id);
                    }
                }
            }
        }
    }

    Shortcut {
        sequence: "Escape"
        enabled: root.visible
        onActivated: {
            root.close();
            root.cancelled();
        }
    }
}
