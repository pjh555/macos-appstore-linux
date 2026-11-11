pragma Singleton

import QtQuick

QtObject {
    id: root

    // The desktop shell owns the session appearance. The store follows the
    // Clavis dark look by default and can switch at runtime from the sidebar.
    property bool dark: true

    readonly property string fontFamily: "Noto Sans CJK SC"
    readonly property string assetRoot: "qrc:/qt/qml/AppStore/assets/"
    readonly property int windowRadius: 14
    readonly property int titlebarHeight: 54
    readonly property int sidebarWidth: 232

    readonly property color textPrimary: dark ? "#f5f5f7" : "#1d1d1f"
    readonly property color textSecondary: dark ? "#a1a1a6" : "#6e6e73"
    readonly property color textTertiary: dark ? "#6e6e73" : "#8e8e93"
    readonly property color textOnAccent: "#ffffff"
    readonly property color accent: dark ? "#0a84ff" : "#007aff"
    readonly property color accentHover: dark ? "#3395ff" : "#3395ff"
    readonly property color danger: "#ff453a"
    readonly property color success: "#30d158"
    readonly property color warning: "#ffd60a"

    readonly property color windowBg: dark ? "#1b1b1d" : "#f7f7f9"
    readonly property color windowBorder: dark ? Qt.rgba(1, 1, 1, 0.15) : Qt.rgba(0, 0, 0, 0.14)
    readonly property color sidebarBg: dark ? "#222225" : "#ececef"
    readonly property color sidebarBgTop: dark ? "#262629" : "#f2f2f4"
    readonly property color contentBg: dark ? "#1b1b1d" : "#ffffff"
    readonly property color toolbarBg: dark ? Qt.rgba(1, 1, 1, 0.025) : Qt.rgba(1, 1, 1, 0.55)
    readonly property color separator: dark ? Qt.rgba(1, 1, 1, 0.09) : Qt.rgba(0, 0, 0, 0.09)
    readonly property color separatorStrong: dark ? Qt.rgba(1, 1, 1, 0.15) : Qt.rgba(0, 0, 0, 0.15)

    readonly property color hover: dark ? Qt.rgba(1, 1, 1, 0.07) : Qt.rgba(0, 0, 0, 0.05)
    readonly property color pressed: dark ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(0, 0, 0, 0.09)
    readonly property color selection: dark ? Qt.rgba(1, 1, 1, 0.105) : Qt.rgba(0, 0, 0, 0.075)
    readonly property color controlBg: dark ? Qt.rgba(1, 1, 1, 0.075) : Qt.rgba(0, 0, 0, 0.045)
    readonly property color controlHover: dark ? Qt.rgba(1, 1, 1, 0.135) : Qt.rgba(0, 0, 0, 0.085)
    readonly property color controlActive: dark ? Qt.rgba(1, 1, 1, 0.17) : Qt.rgba(0, 0, 0, 0.12)
    readonly property color searchBg: dark ? Qt.rgba(0, 0, 0, 0.25) : Qt.rgba(0, 0, 0, 0.055)
    readonly property color searchBorder: dark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.08)

    readonly property color glassBg: dark ? Qt.rgba(0.13, 0.13, 0.15, 0.96) : Qt.rgba(1, 1, 1, 0.96)
    readonly property color glassBorder: dark ? Qt.rgba(1, 1, 1, 0.16) : Qt.rgba(0, 0, 0, 0.12)
    readonly property color cardBg: dark ? "#242427" : "#ffffff"
    readonly property color cardBorder: dark ? Qt.rgba(1, 1, 1, 0.09) : Qt.rgba(0, 0, 0, 0.08)
    readonly property color dimBg: dark ? Qt.rgba(0, 0, 0, 0.48) : Qt.rgba(0, 0, 0, 0.22)
    readonly property color scrollThumb: dark ? Qt.rgba(1, 1, 1, 0.22) : Qt.rgba(0, 0, 0, 0.22)

    readonly property color trafficRed: "#ff5f57"
    readonly property color trafficYellow: "#febc2e"
    readonly property color trafficGreen: "#28c840"

    readonly property color heroText: "#ffffff"
    readonly property color heroTextSecondary: Qt.rgba(1, 1, 1, 0.78)
    readonly property color heroTagBg: Qt.rgba(1, 1, 1, 0.15)

    function alpha(color, value) {
        return Qt.rgba(color.r, color.g, color.b, value);
    }

    function rgba(hex, value) {
        return Qt.rgba(parseInt(hex.slice(1, 3), 16) / 255,
                       parseInt(hex.slice(3, 5), 16) / 255,
                       parseInt(hex.slice(5, 7), 16) / 255,
                       value);
    }
}
