#include "catalog.h"

#include <QCoreApplication>
#include <QDesktopServices>
#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QProcessEnvironment>
#include <QStandardPaths>
#include <QSysInfo>
#include <QTimer>
#include <QUrl>
#include <QDebug>

namespace {
QString resolveCommand(const QString &name)
{
    if (name.isEmpty())
        return {};
    const QString found = QStandardPaths::findExecutable(name);
    if (!found.isEmpty())
        return found;
    const QStringList fallbacks = {
        QDir::homePath() + QStringLiteral("/.local/bin/") + name,
        QDir::homePath() + QStringLiteral("/.npm-global/bin/") + name
    };
    for (const QString &candidate : fallbacks) {
        if (QFileInfo(candidate).isExecutable())
            return candidate;
    }
    return {};
}
}

Catalog::Catalog(QObject *parent)
    : QObject(parent)
{
    m_model.load(QStringLiteral(":/qt/qml/AppStore/data/apps.json"));

    connect(&m_model, &AppListModel::entryChanged, this, &Catalog::appChanged);
    connect(&m_model, &AppListModel::countsChanged, this, &Catalog::countsChanged);

    connect(&m_scanProcess, &QProcess::readyReadStandardOutput, this, [this]() {
        m_scanOutput += QString::fromUtf8(m_scanProcess.readAllStandardOutput());
    });
    connect(&m_scanProcess, &QProcess::readyReadStandardError, this, [this]() {
        m_scanError += QString::fromUtf8(m_scanProcess.readAllStandardError());
    });
    connect(&m_scanProcess, &QProcess::finished, this, &Catalog::handleScanFinished);
    connect(&m_scanProcess, &QProcess::errorOccurred, this, &Catalog::handleScanError);

    m_darkTheme = true;
    if (qEnvironmentVariable("APPSTORE_LIGHT") == QStringLiteral("1")) {
        m_darkTheme = false;
    } else {
        QFile config(QDir::homePath() + QStringLiteral("/.config/clavis/config.json"));
        if (config.open(QIODevice::ReadOnly)) {
            const QJsonDocument document = QJsonDocument::fromJson(config.readAll());
            const QJsonObject theme = document.object().value(QStringLiteral("theme")).toObject();
            if (theme.value(QStringLiteral("mode")).toString() == QStringLiteral("light"))
                m_darkTheme = false;
        }
    }

    m_initialPage = qEnvironmentVariable("APPSTORE_PAGE");
    m_initialCategory = qEnvironmentVariable("APPSTORE_CATEGORY");
    m_initialApp = qEnvironmentVariable("APPSTORE_APP");

    m_statusText = QStringLiteral("尚未检查更新");
}

QString Catalog::arch() const
{
    const QString arch = QSysInfo::currentCpuArchitecture();
    if (arch.contains(QStringLiteral("arm")) || arch.contains(QStringLiteral("aarch64")))
        return QStringLiteral("arm64");
    return arch;
}

QString Catalog::downloadDir() const
{
    QString downloads = QStandardPaths::writableLocation(QStandardPaths::DownloadLocation);
    if (downloads.isEmpty())
        downloads = QDir::homePath() + QStringLiteral("/Downloads");
    return downloads + QStringLiteral("/App Store");
}

QString Catalog::applicationsDir() const
{
    return QDir::homePath() + QStringLiteral("/Applications");
}

QVariantMap Catalog::appData(const QString &id) const
{
    const AppEntry *app = m_model.entry(id);
    return app ? m_model.toMap(*app) : QVariantMap();
}

QString Catalog::categoryName(const QString &id) const
{
    return m_model.categoryName(id);
}

QString Catalog::categorySubtitle(const QString &id) const
{
    return m_model.categorySubtitle(id);
}

int Catalog::categoryCount(const QString &id) const
{
    return m_model.categoryCount(id);
}

void Catalog::refresh()
{
    if (m_scanning) {
        m_refreshQueued = true;
        return;
    }

    m_scanning = true;
    m_refreshQueued = false;
    emit scanningChanged();
    setStatusText(QStringLiteral("正在检查已安装应用…"));

    m_model.clearInstalled();

    m_scanPackages.clear();
    QSet<QString> seen;
    for (const AppEntry &app : m_model.entries()) {
        if (app.package.isEmpty())
            continue;
        if (app.method != QStringLiteral("apt")
            && app.method != QStringLiteral("directDeb")
            && app.method != QStringLiteral("githubDeb"))
            continue;
        if (seen.contains(app.package))
            continue;
        seen.insert(app.package);
        m_scanPackages.append(app.package);
    }

    if (m_scanPackages.isEmpty()) {
        startScanCommand(QStringLiteral("flatpak"),
                         {QStringLiteral("list"), QStringLiteral("--app"),
                          QStringLiteral("--columns=application,version,installation")},
                         FlatpakStage);
        return;
    }

    QStringList arguments;
    arguments << QStringLiteral("-W")
              << QStringLiteral("-f")
              << QStringLiteral("${binary:Package}\t${Status}\t${Version}\n");
    arguments << m_scanPackages;
    startScanCommand(QStringLiteral("dpkg-query"), arguments, DpkgStage);
}

void Catalog::startScanCommand(const QString &program, const QStringList &arguments, ScanStage stage)
{
    m_scanStage = stage;
    m_scanOutput.clear();
    m_scanError.clear();

    QProcessEnvironment environment = QProcessEnvironment::systemEnvironment();
    environment.insert(QStringLiteral("LC_ALL"), QStringLiteral("C"));
    environment.insert(QStringLiteral("LANG"), QStringLiteral("C"));
    m_scanProcess.setProcessEnvironment(environment);
    m_scanProcess.setProgram(program);
    m_scanProcess.setArguments(arguments);
    m_scanProcess.start();
}

void Catalog::handleScanFinished(int exitCode, QProcess::ExitStatus status)
{
    Q_UNUSED(exitCode)
    Q_UNUSED(status)

    if (m_scanStage == NoStage)
        return;

    const ScanStage finishedStage = m_scanStage;
    m_scanStage = NoStage;

    m_scanOutput += QString::fromUtf8(m_scanProcess.readAllStandardOutput());
    m_scanError += QString::fromUtf8(m_scanProcess.readAllStandardError());

    const QString output = m_scanOutput;
    m_scanOutput.clear();
    m_scanError.clear();

    continueScan(finishedStage, output);
}

void Catalog::handleScanError(QProcess::ProcessError error)
{
    if (m_scanStage == NoStage)
        return;
    if (error != QProcess::FailedToStart)
        return;

    const ScanStage finishedStage = m_scanStage;
    m_scanStage = NoStage;
    m_scanOutput.clear();
    m_scanError.clear();
    continueScan(finishedStage, QString());
}

void Catalog::continueScan(ScanStage finishedStage, const QString &output)
{
    switch (finishedStage) {
    case DpkgStage: {
        QHash<QString, QString> installed;
        const QStringList lines = output.split(QLatin1Char('\n'), Qt::SkipEmptyParts);
        for (const QString &line : lines) {
            const QStringList fields = line.split(QLatin1Char('\t'));
            if (fields.size() < 3)
                continue;
            QString package = fields.at(0).trimmed();
            package = package.section(QLatin1Char(':'), 0, 0);
            const QString status = fields.at(1).trimmed();
            if (status == QStringLiteral("install ok installed"))
                installed.insert(package, fields.at(2).trimmed());
        }

        for (const AppEntry &app : m_model.entries()) {
            if (app.package.isEmpty())
                continue;
            if (installed.contains(app.package))
                m_model.setInstalled(app.id, true, installed.value(app.package));
        }

        startScanCommand(QStringLiteral("flatpak"),
                         {QStringLiteral("list"), QStringLiteral("--app"),
                          QStringLiteral("--columns=application,version,installation")},
                         FlatpakStage);
        break;
    }
    case FlatpakStage: {
        const QStringList lines = output.split(QLatin1Char('\n'), Qt::SkipEmptyParts);
        for (const QString &line : lines) {
            const QStringList fields = line.split(QLatin1Char('\t'));
            if (fields.size() < 2)
                continue;
            const QString flatpakId = fields.at(0).trimmed();
            const QString version = fields.at(1).trimmed();
            const QString scope = fields.size() > 2 ? fields.at(2).trimmed() : QString();
            for (const AppEntry &app : m_model.entries()) {
                if (!app.flatpakId.isEmpty() && app.flatpakId == flatpakId)
                    m_model.setInstalled(app.id, true, version, scope);
            }
        }

        // AppImages installed by this store live in ~/Applications/<id>/.
        const QDir applications(applicationsDir());
        for (const AppEntry &app : m_model.entries()) {
            if (app.method != QStringLiteral("githubAppImage"))
                continue;
            const bool extracted = QFileInfo(applications.filePath(app.id + QStringLiteral("/AppRun"))).exists();
            const bool direct = QFileInfo(applications.filePath(app.id + QStringLiteral(".AppImage"))).exists();
            if (extracted || direct)
                m_model.setInstalled(app.id, true, app.version, QStringLiteral("user"));
        }

        // Web apps are desktop entries created by this store.
        const QDir desktopApps(QStandardPaths::writableLocation(QStandardPaths::ApplicationsLocation));
        for (const AppEntry &app : m_model.entries()) {
            if (app.method != QStringLiteral("webapp"))
                continue;
            QString desktopId = app.desktopId;
            if (desktopId.isEmpty())
                desktopId = QStringLiteral("org.clavis.AppStore.%1.desktop").arg(app.id);
            if (!desktopId.endsWith(QStringLiteral(".desktop")))
                desktopId += QStringLiteral(".desktop");
            if (QFileInfo(desktopApps.filePath(desktopId)).exists())
                m_model.setInstalled(app.id, true, app.version, QStringLiteral("user"));
        }

        // CLI tools installed by npm or the vendor's install script.
        const QDir npmBin(QDir::homePath() + QStringLiteral("/.npm-global/bin"));
        for (const AppEntry &app : m_model.entries()) {
            if (app.method == QStringLiteral("npm")) {
                if (QFileInfo(npmBin.filePath(app.launch)).isExecutable()
                    || !QStandardPaths::findExecutable(app.launch).isEmpty())
                    m_model.setInstalled(app.id, true, app.version, QStringLiteral("user"));
            } else if (app.method == QStringLiteral("script")) {
                const QString localBin = QDir::homePath() + QStringLiteral("/.local/bin/") + app.launch;
                if (QFileInfo(localBin).isExecutable()
                    || !QStandardPaths::findExecutable(app.launch).isEmpty())
                    m_model.setInstalled(app.id, true, app.version, QStringLiteral("user"));
            }
        }

        startScanCommand(QStringLiteral("apt"),
                         {QStringLiteral("list"), QStringLiteral("--upgradable")},
                         AptUpdatesStage);
        break;
    }
    case AptUpdatesStage: {
        QHash<QString, QString> updates;
        const QStringList lines = output.split(QLatin1Char('\n'), Qt::SkipEmptyParts);
        for (const QString &line : lines) {
            if (line.startsWith(QStringLiteral("Listing")))
                continue;
            const QStringList fields = line.split(QLatin1Char(' '), Qt::SkipEmptyParts);
            if (fields.size() < 2)
                continue;
            QString package = fields.at(0).section(QLatin1Char('/'), 0, 0);
            package = package.section(QLatin1Char(':'), 0, 0);
            updates.insert(package, fields.at(1));
        }

        for (const AppEntry &app : m_model.entries()) {
            if (!app.installed || app.package.isEmpty())
                continue;
            if (updates.contains(app.package))
                m_model.setUpdate(app.id, true, updates.value(app.package));
            else
                m_model.setUpdate(app.id, false, app.installedVersion);
        }

        startScanCommand(QStringLiteral("flatpak"),
                         {QStringLiteral("remote-ls"), QStringLiteral("--updates"),
                          QStringLiteral("--columns=application,version")},
                         FlatpakUpdatesStage);
        break;
    }
    case FlatpakUpdatesStage: {
        QHash<QString, QString> updates;
        const QStringList lines = output.split(QLatin1Char('\n'), Qt::SkipEmptyParts);
        for (const QString &line : lines) {
            const QStringList fields = line.split(QLatin1Char('\t'), Qt::SkipEmptyParts);
            if (fields.isEmpty())
                continue;
            const QString flatpakId = fields.at(0).trimmed();
            const QString version = fields.size() > 1 ? fields.at(1).trimmed() : QString();
            updates.insert(flatpakId, version);
        }

        for (const AppEntry &app : m_model.entries()) {
            if (!app.installed || app.flatpakId.isEmpty())
                continue;
            if (updates.contains(app.flatpakId)) {
                QString version = updates.value(app.flatpakId);
                if (version.isEmpty())
                    version = QStringLiteral("新版本");
                m_model.setUpdate(app.id, true, version);
            } else {
                m_model.setUpdate(app.id, false, app.installedVersion);
            }
        }

        finishScan();
        break;
    }
    case NoStage:
    default:
        break;
    }
}

void Catalog::finishScan()
{
    m_scanning = false;
    emit scanningChanged();

    const int updates = m_model.updateCount();
    if (updates > 0)
        setStatusText(QStringLiteral("有 %1 个可用更新").arg(updates));
    else
        setStatusText(QStringLiteral("所有应用均为最新版本"));

    emit countsChanged();
    emit scanFinished();

    if (m_refreshQueued) {
        m_refreshQueued = false;
        QTimer::singleShot(250, this, &Catalog::refresh);
    }
}

void Catalog::setStatusText(const QString &text)
{
    if (m_statusText == text)
        return;
    m_statusText = text;
    emit statusTextChanged();
}

void Catalog::openUrl(const QString &url)
{
    QDesktopServices::openUrl(QUrl(url));
}

void Catalog::launchApp(const QString &id)
{
    const AppEntry *app = m_model.entry(id);
    if (!app)
        return;
    if (!app->installed) {
        emit toast(QStringLiteral("请先安装「%1」").arg(app->name), true);
        return;
    }

    if (app->method == QStringLiteral("githubAppImage")) {
        const QDir applications(applicationsDir());
        const QString appRun = applications.filePath(app->id + QStringLiteral("/AppRun"));
        const QString appImage = applications.filePath(app->id + QStringLiteral(".AppImage"));
        const QString program = QFileInfo(appRun).exists() ? appRun : appImage;
        if (program.isEmpty() || !QFileInfo(program).exists()) {
            emit toast(QStringLiteral("找不到已安装的应用文件"), true);
            return;
        }
        QProcess::startDetached(program, {});
        return;
    }

    if (!app->flatpakId.isEmpty()) {
        if (!QProcess::startDetached(QStringLiteral("flatpak"),
                                     {QStringLiteral("run"), app->flatpakId})) {
            emit toast(QStringLiteral("无法启动「%1」").arg(app->name), true);
        }
        return;
    }

    if (!app->desktopId.isEmpty()) {
        const QString gtkLaunch = QStandardPaths::findExecutable(QStringLiteral("gtk-launch"));
        if (!gtkLaunch.isEmpty()
            && QProcess::startDetached(gtkLaunch, {app->desktopId}))
            return;
    }

    if (app->launch.isEmpty()) {
        emit toast(QStringLiteral("这个应用没有可用的启动命令"), true);
        return;
    }

    const QString command = resolveCommand(app->launch);
    if (app->terminal) {
        const QString terminal = QStandardPaths::findExecutable(QStringLiteral("alacritty"));
        if (!terminal.isEmpty()) {
            QProcess::startDetached(terminal, {QStringLiteral("-e"),
                                               command.isEmpty() ? app->launch : command});
            return;
        }
        const QString fallback = QStandardPaths::findExecutable(QStringLiteral("x-terminal-emulator"));
        if (!fallback.isEmpty()) {
            QProcess::startDetached(fallback, {QStringLiteral("-e"),
                                               command.isEmpty() ? app->launch : command});
            return;
        }
        emit toast(QStringLiteral("没有找到可用的终端程序"), true);
        return;
    }

    if (!QProcess::startDetached(command.isEmpty() ? app->launch : command, {}))
        emit toast(QStringLiteral("无法启动「%1」").arg(app->name), true);
}
