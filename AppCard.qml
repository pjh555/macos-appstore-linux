import QtQuick

Item {
    id: root

    property string appId: ""
    property string name: ""
    property string subtitle: ""
    property string categoryName: ""
    property string icon: ""
    property string iconBg1: "#0a84ff"
    property string iconBg2: "#0057d9"
    property bool iconFull: false
    property bool installed: false
    property bool updatable: false
    property string state: "idle"
    property real progress: 0
    property real rating: 0
    property var windowRoot: null
    signal activated()

    implicitWidth: 168
    implicitHeight: 180

    HoverHandler { id: hover }

    Rectangle {
        anchors.fill: parent
        radius: 12
        color: hover.hovered ? Theme.hover : "transparent"

        Behavior on color { ColorAnimation { duration: 140 } }
    }

    AppIcon {
        id: appIcon
        anchors.horizontalCenter: parent.horizontalCenter
        y: 10
        size: Math.min(64, root.width * 0.48)
        icon: root.icon
        bg1: root.iconBg1
        bg2: root.iconBg2
        full: root.iconFull
        fallbackText: root.name.length > 0 ? root.name.charAt(0) : ""
        scale: hover.hovered ? 1.035 : 1.0

        Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
    }

    Text {
        id: nameText
        anchors.top: appIcon.bottom
        anchors.topMargin: 9
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width - 18
        text: root.name
        color: Theme.textPrimary
        font.family: Theme.fontFamily
        font.pixelSize: 13
        font.weight: Font.DemiBold
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight
        maximumLineCount: 1
    }

    Text {
        id: subtitleText
        anchors.top: nameText.bottom
        anchors.topMargin: 3
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width - 20
        text: root.subtitle !== "" ? root.subtitle : root.categoryName
        color: Theme.textTertiary
        font.family: Theme.fontFamily
        font.pixelSize: 11
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight
        maximumLineCount: 1
    }

    GetButton {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 6
        appId: root.appId
        appName: root.name
        installed: root.installed
        updatable: root.updatable
        state: root.state
        progress: root.progress
    }

    MouseArea {
        anchors.fill: parent
        anchors.bottomMargin: 44
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.activated()
    }
}
