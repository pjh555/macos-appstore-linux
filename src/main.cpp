#include "appfiltermodel.h"
#include "catalog.h"
#include "installer.h"

#include <QGuiApplication>
#include <QIcon>
#include <QLocalServer>
#include <QLocalSocket>
#include <QQuickWindow>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QtQml/qqml.h>

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    QCoreApplication::setApplicationName(QStringLiteral("appstore"));
    QCoreApplication::setApplicationVersion(QStringLiteral("1.0"));
    QCoreApplication::setOrganizationName(QStringLiteral("org.clavis"));
    QGuiApplication::setApplicationDisplayName(QStringLiteral("App Store"));
    QGuiApplication::setDesktopFileName(QStringLiteral("org.clavis.AppStore"));
    app.setWindowIcon(QIcon(QStringLiteral(":/qt/qml/AppStore/assets/appstore.svg")));

    const QString serverName = QStringLiteral("org.clavis.AppStore.instance");
    QLocalSocket probe;
    probe.connectToServer(serverName);
    if (probe.waitForConnected(250)) {
        probe.write("activate");
        probe.waitForBytesWritten(250);
        return 0;
    }

    QLocalServer::removeServer(serverName);
    QLocalServer server;
    server.setSocketOptions(QLocalServer::UserAccessOption);
    if (!server.listen(serverName))
        qWarning() << "App Store: cannot listen on" << serverName << server.errorString();

    Catalog store;
    Installer installer(&store);

    qmlRegisterType<AppFilterModel>("AppStore", 1, 0, "AppFilterModel");

    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty(QStringLiteral("store"), &store);
    engine.rootContext()->setContextProperty(QStringLiteral("installer"), &installer);

    QObject::connect(&engine, &QQmlApplicationEngine::objectCreationFailed, &app, []() {
        QCoreApplication::exit(1);
    }, Qt::QueuedConnection);

    engine.loadFromModule("AppStore", "Main");
    if (engine.rootObjects().isEmpty())
        return 1;

    QWindow *mainWindow = qobject_cast<QWindow *>(engine.rootObjects().first());
    QObject::connect(&server, &QLocalServer::newConnection, &app, [&server, mainWindow]() {
        while (QLocalSocket *socket = server.nextPendingConnection()) {
            socket->readAll();
            socket->disconnectFromServer();
            socket->deleteLater();
        }
        if (mainWindow) {
            mainWindow->showNormal();
            mainWindow->requestActivate();
        }
    });

    return app.exec();
}
