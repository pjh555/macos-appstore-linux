import QtQuick

Item {
    id: root

    property string name: ""
    property bool alwaysWhite: false
    property real iconSize: 18
    property real opacityValue: 1.0

    implicitWidth: iconSize
    implicitHeight: iconSize

    Image {
        anchors.fill: parent
        source: root.name === "" ? ""
                                 : Theme.assetRoot + "icons/tabler-" + root.name
                                   + ((Theme.dark || root.alwaysWhite) ? "" : "-light") + ".svg"
        fillMode: Image.PreserveAspectFit
        smooth: true
        opacity: root.opacityValue
    }
}
