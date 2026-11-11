import QtQuick
import QtQuick.Window

Window {
    id: window

    visible: true
    width: 1100
    height: 760
    minimumWidth: 600
    minimumHeight: 480
    color: Theme.windowBg
    flags: Qt.Window | Qt.FramelessWindowHint
    title: "App Store"
    onClosing: Qt.quit()

    readonly property bool isMaximized: visibility === Window.Maximized
    readonly property int shellMargin: 0
    readonly property int shellRadius: 0

    property string page: "discover"
    property string activeCategory: ""
    property string detailAppId: ""
    property string searchText: ""
    property var history: [{ page: "discover", category: "", detail: "" }]
    property int historyIndex: 0
    property string toastText: ""
    property bool toastError: false

    readonly property bool searchActive: searchText.trim() !== ""
    readonly property string effectivePage: searchActive ? "search" : page
    readonly property bool canGoBack: searchActive || historyIndex > 0
    readonly property bool canGoForward: !searchActive && historyIndex < history.length - 1

    readonly property string titleText: {
        if (searchActive)
            return "搜索";
        if (page === "detail") {
            const data = store.appData(detailAppId);
            return data.name || "应用详情";
        }
        switch (page) {
        case "discover": return "探索";
        case "top": return "排行榜";
        case "categories": return "分类";
        case "category": return store.categoryName(activeCategory);
        case "updates": return "更新";
        case "installed": return "已安装";
        default: return "App Store";
        }
    }

    readonly property string pageSource: {
        if (searchActive)
            return "SearchPage.qml";
        switch (page) {
        case "discover": return "DiscoverPage.qml";
        case "top": return "TopChartsPage.qml";
        case "categories": return "CategoriesPage.qml";
        case "category": return "CategoryPage.qml";
        case "updates": return "UpdatesPage.qml";
        case "installed": return "InstalledPage.qml";
        case "detail": return "DetailPage.qml";
        default: return "DiscoverPage.qml";
        }
    }

    function currentState() {
        return { page: page, category: activeCategory, detail: detailAppId };
    }

    function applyState(state) {
        page = state.page || "discover";
        activeCategory = state.category || "";
        detailAppId = state.detail || "";
        searchText = "";
    }

    function navigateTo(nextPage, category, detail) {
        if (!searchActive && nextPage === page && (category || "") === activeCategory
            && (detail || "") === detailAppId)
            return;

        searchText = "";
        let nextHistory = history.slice(0, historyIndex + 1);
        nextHistory.push({ page: nextPage, category: category || "", detail: detail || "" });
        history = nextHistory;
        historyIndex = history.length - 1;
        applyState(history[historyIndex]);
    }

    function goPage(targetPage) {
        navigateTo(targetPage, "", "");
    }

    function openCategory(categoryId) {
        navigateTo("category", categoryId, "");
    }

    function openApp(appId) {
        navigateTo("detail", "", appId);
    }

    function requestUninstall(appId, appName) {
        uninstallSheet.open(appId, appName);
    }

    function goBack() {
        if (searchActive) {
            searchText = "";
            return;
        }
        if (historyIndex <= 0)
            return;
        historyIndex -= 1;
        applyState(history[historyIndex]);
    }

    function goForward() {
        if (searchActive || historyIndex >= history.length - 1)
            return;
        historyIndex += 1;
        applyState(history[historyIndex]);
    }

    function toggleMaximize() {
        if (visibility === Window.Maximized)
            showNormal();
        else
            showMaximized();
    }

    function showToast(message, error) {
        toastText = message;
        toastError = error;
        toastTimer.restart();
    }

    Component.onCompleted: {
        Theme.dark = store.darkTheme;

        let startState = { page: "discover", category: "", detail: "" };
        if (store.initialPage !== "") {
            startState.page = store.initialPage;
            startState.category = store.initialCategory;
        }
        if (store.initialApp !== "") {
            startState.page = "detail";
            startState.detail = store.initialApp;
        }
        history = [startState];
        historyIndex = 0;
        applyState(startState);

        store.refresh();
    }

    Shortcut { sequence: "Ctrl+1"; onActivated: goPage("discover") }
    Shortcut { sequence: "Ctrl+2"; onActivated: goPage("top") }
    Shortcut { sequence: "Ctrl+3"; onActivated: goPage("categories") }
    Shortcut { sequence: "Ctrl+4"; onActivated: goPage("updates") }
    Shortcut { sequence: "Ctrl+5"; onActivated: goPage("installed") }
    Shortcut { sequence: "Ctrl+F"; onActivated: toolbar.focusSearch() }

    Timer {
        id: toastTimer
        interval: 3400
        onTriggered: window.toastText = ""
    }


    Connections {
        target: store
        function onToast(message, error) { window.showToast(message, error); }
    }

    Connections {
        target: installer
        function onAuthRequired(appId, name, message, update) {
            passwordSheet.open(appId, name, message, installer.action);
        }
        function onToast(message, error) { window.showToast(message, error); }
    }

    Rectangle {
        id: shell
        anchors.fill: parent
        anchors.margins: window.shellMargin
        radius: window.shellRadius
        color: Theme.windowBg
        border.width: 1
        border.color: Theme.windowBorder

        Rectangle {
            id: contentBackground
            x: Theme.sidebarWidth
            width: parent.width - Theme.sidebarWidth
            height: parent.height
            color: Theme.contentBg
            topLeftRadius: 0
            topRightRadius: window.shellRadius
            bottomLeftRadius: 0
            bottomRightRadius: window.shellRadius
        }

        Sidebar {
            id: sidebar
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: Theme.sidebarWidth
            windowRoot: window
            cornerRadius: window.shellRadius
        }

        Item {
            id: contentArea
            x: Theme.sidebarWidth
            width: parent.width - Theme.sidebarWidth
            height: parent.height

            Toolbar {
                id: toolbar
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                windowRoot: window
                cornerRadius: window.shellRadius
            }

            Loader {
                id: pageLoader
                anchors.top: toolbar.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                source: window.pageSource
                opacity: 0

                Behavior on opacity { NumberAnimation { duration: 170; easing.type: Easing.OutCubic } }

                onSourceChanged: opacity = 0

                onLoaded: {
                    if (item) {
                        item.windowRoot = window;
                        opacity = 1;
                    }
                }
            }

            DownloadPanel {
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.rightMargin: 18
                anchors.bottomMargin: 18
                z: 40
                windowRoot: window
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: window.shellRadius
            color: "transparent"
            border.width: 1
            border.color: Theme.windowBorder
            z: 200
        }
    }

    PasswordSheet {
        id: passwordSheet
        anchors.fill: shell
        onSubmitted: function(appId, password) {
            passwordSheet.close();
            installer.submitPassword(appId, password);
        }
        onCancelled: function(appId) {
            passwordSheet.close();
            installer.cancelAuth(appId);
        }
    }

    UninstallSheet {
        id: uninstallSheet
        anchors.fill: shell
        onConfirmed: function(appId) {
            uninstallSheet.close();
            installer.uninstall(appId);
        }
        onCancelled: uninstallSheet.close()
    }

    Rectangle {
        id: toast
        z: 90
        anchors.horizontalCenter: shell.horizontalCenter
        anchors.bottom: shell.bottom
        anchors.bottomMargin: 22
        width: toastRow.implicitWidth + 30
        height: 36
        radius: 18
        color: Theme.glassBg
        border.width: 1
        border.color: Theme.glassBorder
        opacity: window.toastText !== "" ? 1 : 0
        visible: opacity > 0

        Behavior on opacity { NumberAnimation { duration: 170 } }

        Row {
            id: toastRow
            anchors.centerIn: parent
            spacing: 7
            Icon {
                width: 14
                height: 14
                name: window.toastError ? "warning" : "checkmark"
                color: window.toastError ? Theme.danger : Theme.success
            }
            Text {
                text: window.toastText
                color: Theme.textPrimary
                font.family: Theme.fontFamily
                font.pixelSize: 12
                font.weight: Font.DemiBold
            }
        }
    }
}
