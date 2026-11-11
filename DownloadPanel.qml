import QtQuick

Item {
    id: root

    property var windowRoot: null
    property var currentApp: ({})

    width: 338
    height: 88
    visible: installer.busy
    opacity: installer.busy ? 1 : 0

    Behavior on opacity { NumberAnimation { duration: 180 } }

    function refresh() {
        currentApp = installer.currentAppId === "" ? ({}) : store.appData(installer.currentAppId);
    }

    onVisibleChanged: if (visible) refresh()

    Connections {
        target: installer
        function onCurrentChanged() { root.refresh(); }
    }

    Connections {
        target: store
        function onAppChanged(id) {
            if (id === installer.currentAppId)
                root.refresh();
        }
    }

    Rectangle {
        anchors.fill: parent
        anchors.topMargin: 3
        radius: 14
        color: "#50000000"
    }

    Rectangle {
        anchors.fill: parent
        radius: 14
        color: Theme.glassBg
        border.width: 1
        border.color: Theme.glassBorder

        AppIcon {
            id: appIcon
            x: 14
            y: 15
            size: 44
            icon: root.currentApp.icon || ""
            bg1: root.currentApp.iconBg1 || "#0a84ff"
            bg2: root.currentApp.iconBg2 || "#0057d9"
            full: root.currentApp.iconFull || false
            fallbackText: root.currentApp.name ? root.currentApp.name.charAt(0) : ""
        }

        Column {
            anchors.left: appIcon.right
            anchors.leftMargin: 11
            anchors.right: parent.right
            anchors.rightMargin: 14
            y: 15
            spacing: 4

            Text {
                width: parent.width
                text: root.currentApp.name || installer.currentName || "正在安装"
                color: Theme.textPrimary
                font.family: Theme.fontFamily
                font.pixelSize: 12
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }

            Text {
                width: parent.width
                text: (installer.phase !== "" ? installer.phase : "正在准备")
                      + (installer.progress >= 0 ? "  ·  " + Math.round(installer.progress * 100) + "%" : "")
                color: Theme.textSecondary
                font.family: Theme.fontFamily
                font.pixelSize: 11
                elide: Text.ElideRight
            }

            Text {
                width: parent.width
                text: installer.status
                visible: text !== "" && text !== "0%" && text !== installer.phase
                         && text.indexOf("正在下载") !== 0
                color: Theme.textTertiary
                font.family: Theme.fontFamily
                font.pixelSize: 10
                elide: Text.ElideRight
            }
        }

        Rectangle {
            id: track
            anchors.left: appIcon.right
            anchors.leftMargin: 11
            anchors.right: parent.right
            anchors.rightMargin: 14
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 12
            height: 4
            radius: 2
            color: Theme.controlBg
            clip: true

            Rectangle {
                id: progressBar
                height: parent.height
                radius: 2
                color: Theme.accent
                visible: installer.progress >= 0
                width: Math.max(0, parent.width * Math.max(0, installer.progress))

                Behavior on width {
                    NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
                }
            }

            Rectangle {
                id: indeterminateBar
                y: 0
                width: Math.max(32, track.width * 0.3)
                height: parent.height
                radius: 2
                color: Theme.accent
                visible: installer.progress < 0

                SequentialAnimation {
                    running: installer.progress < 0 && root.visible
                    loops: Animation.Infinite
                    NumberAnimation {
                        target: indeterminateBar
                        property: "x"
                        from: -indeterminateBar.width
                        to: track.width
                        duration: 1100
                        easing.type: Easing.InOutQuad
                    }
                }
            }
        }
    }
}
