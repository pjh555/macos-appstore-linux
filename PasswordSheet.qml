import QtQuick
import QtQuick.Controls

Item {
    id: root

    property string appId: ""
    property string appName: ""
    property string message: ""
    property string action: "install"
    property var currentApp: ({})

    signal submitted(string appId, string password)
    signal cancelled(string appId)

    visible: false
    enabled: visible
    z: 100

    function open(appIdValue, nameValue, messageValue, actionValue) {
        appId = appIdValue;
        appName = nameValue;
        message = messageValue;
        action = actionValue;
        currentApp = store.appData(appIdValue);
        passwordField.text = "";
        visible = true;
        Qt.callLater(function() { passwordField.forceActiveFocus(); });
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
        width: 436
        height: 306
        anchors.centerIn: parent
        radius: 16
        color: Theme.glassBg
        border.width: 1
        border.color: Theme.glassBorder

        scale: 0.96
        opacity: 0

        Component.onCompleted: {
            openAnimation.start();
        }

        ParallelAnimation {
            id: openAnimation
            NumberAnimation { target: card; property: "opacity"; from: 0; to: 1; duration: 180 }
            NumberAnimation { target: card; property: "scale"; from: 0.96; to: 1; duration: 220; easing.type: Easing.OutCubic }
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
        }

        Row {
            id: headerRow
            x: 24
            y: 22
            spacing: 12

            AppIcon {
                width: 52
                height: 52
                size: 52
                icon: root.currentApp.icon || ""
                bg1: root.currentApp.iconBg1 || "#0a84ff"
                bg2: root.currentApp.iconBg2 || "#0057d9"
                full: root.currentApp.iconFull || false
                fallbackText: root.appName.length > 0 ? root.appName.charAt(0) : ""
            }

            Column {
                y: 8
                spacing: 3
                Text {
                    text: "需要管理员授权"
                    color: Theme.textPrimary
                    font.family: Theme.fontFamily
                    font.pixelSize: 17
                    font.weight: Font.Bold
                }
                Text {
                    text: root.appName
                    color: Theme.textTertiary
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    elide: Text.ElideRight
                }
            }
        }

        Text {
            x: 24
            y: 88
            width: parent.width - 48
            text: root.message !== "" ? root.message
                                      : ("App Store 需要管理员权限来" + (root.action === "uninstall" ? "卸载" : (root.action === "update" ? "更新" : "安装")) + "「" + root.appName + "」。")
            color: (root.message.indexOf("不正确") >= 0 || root.message.indexOf("失败") >= 0 || root.message.indexOf("错误") >= 0) ? Theme.danger : Theme.textSecondary
            font.family: Theme.fontFamily
            font.pixelSize: 12
            lineHeight: 1.35
            wrapMode: Text.WordWrap
        }

        Rectangle {
            id: passwordFrame
            x: 24
            y: 146
            width: parent.width - 48
            height: 38
            radius: 9
            color: Theme.searchBg
            border.width: 1
            border.color: passwordField.activeFocus ? Theme.accent : Theme.searchBorder

            Icon {
                id: lockIcon
                anchors.left: parent.left
                anchors.leftMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                width: 14
                height: 14
                name: "lock"
                color: Theme.textTertiary
            }

            TextField {
                id: passwordField
                anchors.left: lockIcon.right
                anchors.leftMargin: 8
                anchors.right: parent.right
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                height: parent.height
                padding: 0
                placeholderText: "输入登录密码"
                placeholderTextColor: Theme.textTertiary
                echoMode: TextInput.Password
                passwordCharacter: "●"
                color: Theme.textPrimary
                selectionColor: Theme.accent
                selectedTextColor: "white"
                font.family: Theme.fontFamily
                font.pixelSize: 13
                background: Item {}
                onAccepted: root.submit()
                Keys.onEscapePressed: root.cancel()
            }
        }

        Text {
            x: 24
            y: 196
            width: parent.width - 48
            text: "密码仅用于本次系统授权，不会被保存。"
            color: Theme.textTertiary
            font.family: Theme.fontFamily
            font.pixelSize: 10
        }

        Row {
            x: 24
            y: parent.height - 62
            width: parent.width - 48
            spacing: 10

            Item {
                width: Math.max(0, parent.width - 200)
                height: 1
            }

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
                    onClicked: root.cancel()
                }
            }

            Rectangle {
                width: 104
                height: 32
                radius: 8
                color: root.action === "uninstall" ? (confirmMouse.containsMouse ? "#ff6961" : Theme.danger) : (confirmMouse.containsMouse ? Theme.accentHover : Theme.accent)
                opacity: passwordField.text.length > 0 ? 1 : 0.55

                Text {
                    anchors.centerIn: parent
                    text: root.action === "uninstall" ? "卸载" : (root.action === "update" ? "更新" : "安装")
                    color: "white"
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                }

                MouseArea {
                    id: confirmMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    enabled: passwordField.text.length > 0
                    onClicked: root.submit()
                }
            }
        }
    }

    Shortcut {
        sequence: "Escape"
        enabled: root.visible
        onActivated: root.cancel()
    }

    function submit() {
        if (passwordField.text.length === 0)
            return;
        const pwd = passwordField.text;
        const id = appId;
        passwordField.text = "";
        submitted(id, pwd);
    }

    function cancel() {
        const id = appId;
        visible = false;
        cancelled(id);
    }
}
