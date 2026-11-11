import QtQuick

Item {
    id: root

    property string appName: ""
    property string icon: ""
    property string color1: "#0a84ff"
    property string color2: "#0057d9"
    property string iconBg1: "#0a84ff"
    property string iconBg2: "#0057d9"
    property bool iconFull: false
    property int variant: 0

    implicitHeight: 178
    clip: true

    Rectangle {
        anchors.fill: parent
        radius: 12
        gradient: Gradient {
            GradientStop { position: 0.0; color: root.color1 }
            GradientStop { position: 1.0; color: root.color2 }
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: 12
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0.02) }
            GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.23) }
        }
    }

    Rectangle {
        x: 14
        y: 14
        width: parent.width - 28
        height: parent.height - 28
        radius: 9
        color: Qt.rgba(0.06, 0.06, 0.075, 0.80)
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.13)

        Row {
            id: lights
            x: 11
            y: 9
            spacing: 5
            Repeater {
                model: [Theme.trafficRed, Theme.trafficYellow, Theme.trafficGreen]
                Rectangle { width: 6; height: 6; radius: 3; color: modelData }
            }
        }

        Text {
            anchors.left: lights.right
            anchors.leftMargin: 9
            anchors.verticalCenter: lights.verticalCenter
            text: root.appName
            color: Qt.rgba(1, 1, 1, 0.50)
            font.family: Theme.fontFamily
            font.pixelSize: 8
            elide: Text.ElideRight
            width: parent.width - 90
        }

        Rectangle {
            x: 0
            y: 25
            width: parent.width
            height: 1
            color: Qt.rgba(1, 1, 1, 0.09)
        }

        Rectangle {
            x: 0
            y: 26
            width: 62
            height: parent.height - 26
            color: Qt.rgba(0, 0, 0, 0.16)
        }

        AppIcon {
            x: 11
            y: 37
            size: 24
            icon: root.icon
            bg1: root.iconBg1
            bg2: root.iconBg2
            full: root.iconFull
            fallbackText: root.appName.length > 0 ? root.appName.charAt(0) : ""
        }

        Repeater {
            model: 4
            Rectangle {
                x: 12
                y: 72 + index * 16
                width: 36 - (index % 2) * 8
                height: 5
                radius: 2.5
                color: Qt.rgba(1, 1, 1, index === 0 ? 0.22 : 0.11)
            }
        }

        Column {
            x: 78
            y: 42
            width: parent.width - 94
            spacing: 10

            Rectangle {
                width: parent.width * (root.variant === 0 ? 0.52 : 0.68)
                height: 10
                radius: 4
                color: Qt.rgba(1, 1, 1, 0.22)
            }

            Rectangle {
                width: parent.width * 0.36
                height: 6
                radius: 3
                color: Qt.rgba(1, 1, 1, 0.12)
            }

            Row {
                spacing: 8

                Repeater {
                    model: 3
                    Rectangle {
                        width: (parent.parent.width - 16) / 3
                        height: 52
                        radius: 6
                        color: Qt.rgba(1, 1, 1, index === 0 ? 0.11 : 0.07)
                        border.width: 1
                        border.color: Qt.rgba(1, 1, 1, 0.08)

                        Rectangle {
                            x: 8
                            y: 8
                            width: 14
                            height: 14
                            radius: 4
                            color: Qt.rgba(1, 1, 1, 0.21)
                        }
                        Rectangle {
                            x: 8
                            y: 30
                            width: parent.width - 16
                            height: 4
                            radius: 2
                            color: Qt.rgba(1, 1, 1, 0.15)
                        }
                        Rectangle {
                            x: 8
                            y: 38
                            width: (parent.width - 16) * 0.62
                            height: 4
                            radius: 2
                            color: Qt.rgba(1, 1, 1, 0.09)
                        }
                    }
                }
            }
        }
    }
}
