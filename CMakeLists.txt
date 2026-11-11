cmake_minimum_required(VERSION 3.21)
project(appstore VERSION 1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)

find_package(Qt6 6.5 REQUIRED COMPONENTS Quick Network Svg)
qt_standard_project_setup()

qt_add_executable(appstore
    src/main.cpp
    src/appmodel.cpp
    src/appmodel.h
    src/appfiltermodel.cpp
    src/appfiltermodel.h
    src/catalog.cpp
    src/catalog.h
    src/installer.cpp
    src/installer.h
)

set_source_files_properties(Theme.qml PROPERTIES QT_QML_SINGLETON_TYPE TRUE)

qt_add_qml_module(appstore
    URI AppStore
    VERSION 1.0
    RESOURCE_PREFIX "/qt/qml"
    QML_FILES
        Main.qml
        AppStoreWindow.qml
        Theme.qml
        Icon.qml
        LineIcon.qml
        TrafficLight.qml
        Toolbar.qml
        Sidebar.qml
        SidebarRow.qml
        AppIcon.qml
        GetButton.qml
        AppCard.qml
        AppCardDelegate.qml
        AppGrid.qml
        AppRow.qml
        SectionHeader.qml
        StarRating.qml
        HeroCard.qml
        FeaturedCarousel.qml
        CategoryTile.qml
        MacScrollBar.qml
        EmptyState.qml
        DiscoverPage.qml
        TopChartsPage.qml
        CategoryPage.qml
        CategoriesPage.qml
        UpdatesPage.qml
        InstalledPage.qml
        SearchPage.qml
        DetailPage.qml
        MockShot.qml
        DownloadPanel.qml
        PasswordSheet.qml
        UninstallSheet.qml
)

file(GLOB ICON_FILES CONFIGURE_DEPENDS RELATIVE "${CMAKE_CURRENT_SOURCE_DIR}" "assets/icons/*")
qt_add_resources(appstore "appstore_assets"
    PREFIX "/qt/qml/AppStore"
    FILES
        assets/appstore.svg
        ${ICON_FILES}
)

qt_add_resources(appstore "appstore_data"
    PREFIX "/qt/qml/AppStore"
    FILES data/apps.json
)

target_link_libraries(appstore PRIVATE
    Qt6::Quick
    Qt6::Network
    Qt6::Svg
)

install(TARGETS appstore RUNTIME DESTINATION lib/appstore)
