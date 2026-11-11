import QtQuick

AppCard {
    id: delegate

    property var windowRoot: null

    appId: model.appId
    name: model.name
    subtitle: model.subtitle
    categoryName: model.categoryName
    icon: model.icon
    iconBg1: model.iconBg1
    iconBg2: model.iconBg2
    iconFull: model.iconFull
    installed: model.installed
    updatable: model.updatable
    state: model.state
    progress: model.progress
    rating: model.rating

    onActivated: if (delegate.windowRoot) delegate.windowRoot.openApp(appId)
}
