import QtQuick
import QtQuick.Controls

Item {
    id: root

    property var windowRoot: null
    property real cornerRadius: Theme.windowRadius

    function focusSearch() {
        input.forceActiveFocus();
        input.selectAll();
    }

    implicitHeight: Theme.titlebarHeight

    Rectangle {
        anchors.fill: parent
        topRightRadius: root.cornerRadius
        bottomRightRadius: 0
        topLeftRadius: 0
        bottomLeftRadius: 0
        color: Theme.toolbarBg
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        onPressed: if (root.windowRoot) root.windowRoot.startSystemMove()
        onDoubleClicked: if (root.windowRoot) root.windowRoot.toggleMaximize()
    }

    Row {
        anchors.left: parent.left
        anchors.leftMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        spacing: 3

        Rectangle {
            width: 28
            height: 28
            radius: 7
            color: backMouse.containsMouse && root.windowRoot && root.windowRoot.canGoBack
                   ? Theme.hover : "transparent"
            opacity: root.windowRoot && root.windowRoot.canGoBack ? 1 : 0.32

            Icon {
                anchors.centerIn: parent
                width: 15
                height: 15
                name: "chevron-left"
                color: Theme.textPrimary
            }

            MouseArea {
                id: backMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: if (root.windowRoot) root.windowRoot.goBack()
            }
        }

        Rectangle {
            width: 28
            height: 28
            radius: 7
            color: forwardMouse.containsMouse && root.windowRoot && root.windowRoot.canGoForward
                   ? Theme.hover : "transparent"
            opacity: root.windowRoot && root.windowRoot.canGoForward ? 1 : 0.32

            Icon {
                anchors.centerIn: parent
                width: 15
                height: 15
                name: "chevron-right"
                color: Theme.textPrimary
            }

            MouseArea {
                id: forwardMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: if (root.windowRoot) root.windowRoot.goForward()
            }
        }
    }

    Text {
        anchors.left: parent.left
        anchors.leftMargin: 76
        anchors.verticalCenter: parent.verticalCenter
        width: Math.max(0, parent.width - 76 - 292)
        text: root.windowRoot ? root.windowRoot.titleText : "App Store"
        color: Theme.textSecondary
        font.family: Theme.fontFamily
        font.pixelSize: 13
        font.weight: Font.DemiBold
        elide: Text.ElideRight
    }

    Row {
        anchors.right: parent.right
        anchors.rightMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8

        Rectangle {
            width: 28
            height: 28
            radius: 7
            color: refreshMouse.containsMouse ? Theme.hover : "transparent"

            Item {
                id: refreshIcon
                anchors.centerIn: parent
                width: 15
                height: 15
                Icon {
                    anchors.fill: parent
                    name: "refresh"
                    color: Theme.textSecondary
                }
                RotationAnimator {
                    target: refreshIcon
                    from: 0
                    to: 360
                    duration: 900
                    loops: Animation.Infinite
                    running: store.scanning
                }
            }

            MouseArea {
                id: refreshMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: store.refresh()
            }
        }

        Rectangle {
            id: searchField
            width: 226
            height: 29
            radius: 8
            color: Theme.searchBg
            border.width: 1
            border.color: searchField.activeFocus ? Theme.accent : Theme.searchBorder

            Icon {
                id: searchIcon
                anchors.left: parent.left
                anchors.leftMargin: 9
                anchors.verticalCenter: parent.verticalCenter
                width: 13
                height: 13
                name: "search"
                color: Theme.textTertiary
            }

            TextField {
                id: input
                anchors.left: searchIcon.right
                anchors.leftMargin: 6
                anchors.right: clearButton.left
                anchors.rightMargin: 2
                anchors.verticalCenter: parent.verticalCenter
                height: parent.height
                padding: 0
                text: root.windowRoot ? root.windowRoot.searchText : ""
                placeholderText: "搜索 App Store"
                placeholderTextColor: Theme.textTertiary
                color: Theme.textPrimary
                selectionColor: Theme.accent
                selectedTextColor: "white"
                font.family: Theme.fontFamily
                font.pixelSize: 12
                background: Item {}
                onTextEdited: if (root.windowRoot) root.windowRoot.searchText = text
                Keys.onEscapePressed: {
                    if (root.windowRoot)
                        root.windowRoot.searchText = "";
                    text = "";
                }
            }

            Connections {
                target: root.windowRoot
                function onSearchTextChanged() {
                    if (input.text !== root.windowRoot.searchText)
                        input.text = root.windowRoot.searchText;
                }
            }

            Rectangle {
                id: clearButton
                anchors.right: parent.right
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                width: 15
                height: 15
                radius: 7.5
                visible: input.text.length > 0
                color: clearMouse.containsMouse ? Theme.controlHover : Theme.controlBg

                Icon {
                    anchors.centerIn: parent
                    width: 7
                    height: 7
                    name: "close"
                    color: Theme.textSecondary
                    strokeWidth: 2.2
                }

                MouseArea {
                    id: clearMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (root.windowRoot) {
                            root.windowRoot.searchText = "";
                            input.text = "";
                            input.forceActiveFocus();
                        }
                    }
                }
            }
        }
    }

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 1
        color: Theme.separator
    }
}
