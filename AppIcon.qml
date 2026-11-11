import QtQuick

Item {
    id: root

    property real size: 64
    property string icon: ""
    property string bg1: "#0a84ff"
    property string bg2: "#0057d9"
    property bool full: false
    property string fallbackText: ""

    implicitWidth: size
    implicitHeight: size

    Rectangle {
        x: 0
        y: Math.max(2, size * 0.035)
        width: size
        height: size
        radius: size * 0.225
        color: "#3d000000"
    }

    Rectangle {
        id: face
        anchors.fill: parent
        radius: size * 0.225
        gradient: Gradient {
            GradientStop { position: 0.0; color: root.bg1 }
            GradientStop { position: 1.0; color: root.bg2 }
        }
        border.width: Math.max(1, size * 0.012)
        border.color: Qt.rgba(1, 1, 1, 0.16)

        Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            radius: parent.radius - 1
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.16) }
                GradientStop { position: 0.42; color: Qt.rgba(1, 1, 1, 0.015) }
                GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.10) }
            }
        }

        Image {
            id: image
            anchors.centerIn: parent
            width: face.width * (root.full ? 0.67 : 0.53)
            height: width
            source: root.icon === "" ? "" : Theme.assetRoot + "icons/" + root.icon
            fillMode: Image.PreserveAspectFit
            smooth: true
            visible: status === Image.Ready
        }

        Text {
            anchors.centerIn: parent
            visible: !image.visible
            text: root.fallbackText.length > 0 ? root.fallbackText
                                               : (root.icon.length > 0 ? root.icon.charAt(0).toUpperCase() : "?")
            color: "white"
            font.family: Theme.fontFamily
            font.pixelSize: Math.max(14, size * 0.34)
            font.weight: Font.Bold
        }
    }
}
