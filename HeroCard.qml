import QtQuick

Item {
    id: root

    property string appId: ""
    property string name: ""
    property string heroTitle: ""
    property string heroSubtitle: ""
    property string heroTag: ""
    property string color1: "#1b1b1d"
    property string color2: "#0a84ff"
    property string icon: ""
    property string iconBg1: "#0a84ff"
    property string iconBg2: "#0057d9"
    property bool iconFull: false
    property var windowRoot: null

    clip: true
    implicitHeight: 240

    Rectangle {
        anchors.fill: parent
        radius: 18
        gradient: Gradient {
            GradientStop { position: 0.0; color: root.color1 }
            GradientStop { position: 1.0; color: root.color2 }
        }
    }

    Rectangle {
        width: 460
        height: 460
        radius: 230
        x: root.width * 0.58
        y: -230
        color: Qt.rgba(1, 1, 1, 0.055)
    }

    Rectangle {
        width: 320
        height: 320
        radius: 160
        x: root.width - 250
        y: 110
        color: Qt.rgba(0, 0, 0, 0.10)
    }

    Image {
        anchors.right: parent.right
        anchors.rightMargin: -40
        anchors.verticalCenter: parent.verticalCenter
        width: Math.min(440, root.width * 0.46)
        height: width
        source: root.icon === "" ? "" : Theme.assetRoot + "icons/" + root.icon
        fillMode: Image.PreserveAspectFit
        opacity: 0.09
    }

    Column {
        anchors.left: parent.left
        anchors.leftMargin: 36
        anchors.verticalCenter: parent.verticalCenter
        width: Math.min(490, root.width * 0.56)
        spacing: 12

        Rectangle {
            width: tagText.implicitWidth + 20
            height: 24
            radius: 12
            color: Theme.heroTagBg
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.16)

            Text {
                id: tagText
                anchors.centerIn: parent
                text: root.heroTag
                color: Theme.heroText
                font.family: Theme.fontFamily
                font.pixelSize: 11
                font.weight: Font.DemiBold
                font.letterSpacing: 0.2
            }
        }

        Text {
            width: parent.width
            text: root.heroTitle
            color: Theme.heroText
            font.family: Theme.fontFamily
            font.pixelSize: root.width < 800 ? 28 : 33
            font.weight: Font.Bold
            font.letterSpacing: -0.7
            lineHeight: 1.06
            wrapMode: Text.WordWrap
            maximumLineCount: 2
            elide: Text.ElideRight
        }

        Text {
            width: Math.min(parent.width, 390)
            text: root.heroSubtitle
            color: Theme.heroTextSecondary
            font.family: Theme.fontFamily
            font.pixelSize: 13
            lineHeight: 1.35
            wrapMode: Text.WordWrap
            maximumLineCount: 2
            elide: Text.ElideRight
        }

        Rectangle {
            width: viewRow.implicitWidth + 26
            height: 33
            radius: 16.5
            color: viewMouse.containsMouse ? "#f2f2f7" : "white"

            Behavior on color { ColorAnimation { duration: 120 } }

            Row {
                id: viewRow
                anchors.centerIn: parent
                spacing: 5
                Text {
                    text: "查看"
                    color: "#1d1d1f"
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                }
                Icon {
                    width: 11
                    height: 11
                    name: "chevron-right"
                    color: "#1d1d1f"
                }
            }

            MouseArea {
                id: viewMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: if (root.windowRoot) root.windowRoot.openApp(root.appId)
            }
        }
    }

    Item {
        id: art
        visible: root.width > 720
        width: 338
        height: 205
        anchors.right: parent.right
        anchors.rightMargin: 42
        anchors.verticalCenter: parent.verticalCenter

        Rectangle {
            anchors.fill: parent
            radius: 17
            color: Qt.rgba(1, 1, 1, 0.105)
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.20)
        }

        Row {
            id: artLights
            anchors.left: parent.left
            anchors.leftMargin: 14
            anchors.top: parent.top
            anchors.topMargin: 13
            spacing: 6
            Repeater {
                model: [Theme.trafficRed, Theme.trafficYellow, Theme.trafficGreen]
                Rectangle {
                    width: 8
                    height: 8
                    radius: 4
                    color: modelData
                }
            }
        }

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: artLights.bottom
            anchors.topMargin: 11
            height: 1
            color: Qt.rgba(1, 1, 1, 0.10)
        }

        AppIcon {
            id: artIcon
            x: 18
            y: 47
            size: 64
            icon: root.icon
            bg1: root.iconBg1
            bg2: root.iconBg2
            full: root.iconFull
            fallbackText: root.name.length > 0 ? root.name.charAt(0) : ""
        }

        Column {
            anchors.left: artIcon.right
            anchors.leftMargin: 12
            anchors.right: parent.right
            anchors.rightMargin: 18
            y: 49
            spacing: 7

            Text {
                text: root.name
                color: "white"
                font.family: Theme.fontFamily
                font.pixelSize: 14
                font.weight: Font.DemiBold
                elide: Text.ElideRight
                width: parent.width
            }

            Rectangle {
                width: parent.width * 0.78
                height: 6
                radius: 3
                color: Qt.rgba(1, 1, 1, 0.28)
            }
            Rectangle {
                width: parent.width * 0.56
                height: 6
                radius: 3
                color: Qt.rgba(1, 1, 1, 0.16)
            }
        }

        Rectangle {
            x: 18
            y: 128
            width: parent.width - 36
            height: 56
            radius: 10
            color: Qt.rgba(0, 0, 0, 0.15)

            Row {
                anchors.left: parent.left
                anchors.leftMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6

                Repeater {
                    model: 3
                    Rectangle {
                        width: 52
                        height: 36
                        radius: 6
                        color: Qt.rgba(1, 1, 1, index === 0 ? 0.22 : 0.10)
                    }
                }
            }
        }
    }
}
