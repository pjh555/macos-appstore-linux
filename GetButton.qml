import QtQuick

Item {
    id: root

    property string appId: ""
    property string appName: ""
    property bool installed: false
    property bool updatable: false
    property string state: "idle"
    property real progress: 0
    property bool large: false

    readonly property var appInfo: appId === "" ? ({}) : store.appData(appId)
    readonly property bool external: appInfo.method === "external"

    readonly property bool busy: state === "preparing" || state === "downloading"
                                 || state === "waiting" || state === "installing"
                                 || state === "uninstalling" || state === "verifying"
    readonly property bool hasUpdate: installed && updatable
    readonly property string label: busy ? ""
                                         : (external ? "官网"
                                                     : (hasUpdate ? "更新" : (installed ? "打开" : "获取")))
    readonly property color foreground: external ? "#1d1d1f"
                                                   : (hasUpdate && !busy ? "white" : Theme.accent)
    readonly property color fillColor: external ? "white"
                                                : (hasUpdate && !busy ? Theme.accent : Theme.controlBg)
    readonly property color fillHover: external ? "#f2f2f7"
                                                : (hasUpdate && !busy ? Theme.accentHover : Theme.controlHover)

    implicitWidth: busy ? (large ? 38 : 30)
                        : (large ? (label.length > 1 ? 102 : 88)
                                 : (label === "更新" ? 70 : 66))
    implicitHeight: large ? 34 : 28

    width: implicitWidth
    height: implicitHeight

    Behavior on width { NumberAnimation { duration: 170; easing.type: Easing.OutCubic } }

    Rectangle {
        id: background
        anchors.fill: parent
        radius: height / 2
        color: mouseArea.pressed ? Theme.controlActive
                                : (mouseArea.containsMouse ? root.fillHover : root.fillColor)

        Behavior on color { ColorAnimation { duration: 120 } }
    }

    Text {
        anchors.centerIn: parent
        text: root.label
        color: root.foreground
        opacity: root.busy ? 0 : 1
        font.family: Theme.fontFamily
        font.pixelSize: root.large ? 13 : 12
        font.weight: Font.DemiBold
        Behavior on opacity { NumberAnimation { duration: 120 } }
    }

    Canvas {
        id: ring
        anchors.centerIn: parent
        width: root.large ? 22 : 19
        height: width
        visible: root.busy
        rotation: 0

        readonly property real value: root.progress

        onValueChanged: requestPaint()
        onVisibleChanged: requestPaint()

        onPaint: {
            const ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            const center = width / 2;
            const radius = center - 2.2;
            ctx.lineWidth = 2.1;
            ctx.lineCap = "round";

            ctx.beginPath();
            ctx.strokeStyle = Theme.alpha(root.foreground, 0.20);
            ctx.arc(center, center, radius, 0, Math.PI * 2);
            ctx.stroke();

            ctx.beginPath();
            ctx.strokeStyle = root.foreground;
            if (value >= 0) {
                const end = -Math.PI / 2 + Math.PI * 2 * Math.max(0.02, value);
                ctx.arc(center, center, radius, -Math.PI / 2, end);
            } else {
                ctx.arc(center, center, radius, -Math.PI / 2, -Math.PI / 2 + Math.PI * 1.42);
            }
            ctx.stroke();
        }

        RotationAnimator {
            target: ring
            from: 0
            to: 360
            duration: 950
            loops: Animation.Infinite
            running: root.busy && root.progress < 0
            onRunningChanged: if (!running) ring.rotation = 0
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        enabled: !root.busy
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (root.external) {
                if (root.appInfo.homepage)
                    store.openUrl(root.appInfo.homepage);
            } else if (root.installed && !root.updatable) {
                store.launchApp(root.appId);
            } else {
                installer.install(root.appId);
            }
        }
    }
}
