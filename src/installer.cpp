#include "installer.h"

#include <QCoreApplication>
#include <QDateTime>
#include <QDir>
#include <QDirIterator>
#include <QFileInfo>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QProcessEnvironment>
#include <QRegularExpression>
#include <QStandardPaths>
#include <QTextStream>
#include <QTimer>
#include <QUrl>
#include <QDebug>

#include "catalog.h"

namespace {
QString sanitizedFileName(const QString &name)
{
    QString result = name;
    result.replace(QLatin1Char('/'), QLatin1Char('_'));
    result.replace(QLatin1Char('\\'), QLatin1Char('_'));
    if (result.trimmed().isEmpty())
        result = QStringLiteral("download");
    return result;
}

QString normalizedAssetName(const QString &name)
{
    QString result = name.toLower();
    result.remove(QLatin1Char('-'));
    result.remove(QLatin1Char('_'));
    return result;
}

bool looksLikeAuthFailure(const QString &text)
{
    const QString lower = text.toLower();
    return lower.contains(QStringLiteral("authentication failed"))
        || lower.contains(QStringLiteral("sorry, try again"))
        || lower.contains(QStringLiteral("incorrect password"))
        || lower.contains(QStringLiteral("password is required"))
        || lower.contains(QStringLiteral("认证失败"))
        || lower.contains(QStringLiteral("密码不正确"));
}
}

Installer::Installer(Catalog *catalog, QObject *parent)
    : QObject(parent)
    , m_catalog(catalog)
{
    m_network.setRedirectPolicy(QNetworkRequest::NoLessSafeRedirectPolicy);
    m_process.setProcessChannelMode(QProcess::SeparateChannels);

    connect(&m_process, &QProcess::readyReadStandardOutput, this, [this]() {
        handleProcessOutput(false);
    });
    connect(&m_process, &QProcess::readyReadStandardError, this, [this]() {
        handleProcessOutput(true);
    });
    connect(&m_process, &QProcess::started, this, [this]() {
        if (!m_pendingPassword.isEmpty()) {
            m_process.write(m_pendingPassword.toUtf8());
            m_process.write("\n");
            m_process.closeWriteChannel();
            m_pendingPassword.clear();
        }
    });
    connect(&m_process, &QProcess::finished, this, &Installer::handleProcessFinished);
    connect(&m_process, &QProcess::errorOccurred, this, [this](QProcess::ProcessError error) {
        if (error == QProcess::FailedToStart && m_processKind != NoProcess)
            fail(QStringLiteral("无法启动安装进程：%1").arg(m_process.errorString()));
    });
}

void Installer::install(const QString &appId)
{
    if (m_busy) {
        emit toast(QStringLiteral("请等待当前任务完成"), false);
        return;
    }

    const AppEntry *app = m_catalog->model()->entry(appId);
    if (!app)
        return;

    if (app->installed && !app->updatable) {
        m_catalog->launchApp(appId);
        return;
    }

    m_batch = false;
    m_queue.clear();
    startTask(appId, app->installed && app->updatable);
}

QString Installer::action() const
{
    if (m_task.uninstall)
        return QStringLiteral("uninstall");
    if (m_task.update)
        return QStringLiteral("update");
    return QStringLiteral("install");
}

void Installer::uninstall(const QString &appId)
{
    if (m_busy) {
        emit toast(QStringLiteral("请等待当前任务完成"), false);
        return;
    }

    const AppEntry *app = m_catalog->model()->entry(appId);
    if (!app)
        return;
    if (!app->installed) {
        emit toast(QStringLiteral("「%1」尚未安装").arg(app->name), true);
        return;
    }

    m_batch = false;
    m_queue.clear();
    startTask(appId, false, true);
}

void Installer::updateAll()
{
    if (m_busy) {
        emit toast(QStringLiteral("请等待当前任务完成"), false);
        return;
    }

    QStringList updates;
    for (const AppEntry &app : m_catalog->model()->entries()) {
        if (app.installed && app.updatable)
            updates.append(app.id);
    }

    if (updates.isEmpty()) {
        emit toast(QStringLiteral("所有应用均为最新版本"), false);
        return;
    }

    m_batch = true;
    m_queue.clear();
    for (const QString &id : updates)
        m_queue.enqueue(id);

    const QString first = m_queue.dequeue();
    startTask(first, true);
}

void Installer::startTask(const QString &appId, bool update, bool uninstall)
{
    const AppEntry *app = m_catalog->model()->entry(appId);
    if (!app)
        return;

    m_task = Task{};
    m_task.appId = app->id;
    m_task.name = app->name;
    m_task.method = app->method;
    m_task.package = app->package;
    m_task.githubRepo = app->githubRepo;
    m_task.assetHint = app->assetHint;
    m_task.directUrl = app->directUrl;
    m_task.fileName = app->fileName;
    m_task.flatpakId = app->flatpakId;
    m_task.installScope = app->installScope;
    m_task.update = update;
    m_task.uninstall = uninstall;
    m_task.uninstallCommand = app->uninstallCommand;
    m_task.version = app->latestVersion.isEmpty() ? app->version : app->latestVersion;

    m_processKind = NoProcess;
    m_networkKind = NoNetwork;
    m_waitingForAuth = false;
    m_processOutput.clear();
    m_processError.clear();

    setBusy(true);
    setProgress(-1);
    setPhase(uninstall ? QStringLiteral("准备卸载") : QStringLiteral("准备中"));
    setStatus(QString());
    setAppState(uninstall ? QStringLiteral("uninstalling") : QStringLiteral("preparing"),
                -1, uninstall ? QStringLiteral("准备卸载") : QStringLiteral("准备中"));
    emit currentChanged();
    emit actionChanged();

    appendLog(QStringLiteral("---- %1 %2 (%3) ----")
                  .arg(uninstall ? QStringLiteral("卸载")
                                 : (update ? QStringLiteral("更新") : QStringLiteral("安装")),
                       app->name, app->method));

    if (uninstall) {
        if (m_task.method == QStringLiteral("apt")
            || m_task.method == QStringLiteral("directDeb")
            || m_task.method == QStringLiteral("githubDeb")) {
            if (sudoAvailable())
                startApt(QString());
            else
                requestAuth(QStringLiteral("卸载「%1」需要管理员权限。请输入系统密码。").arg(m_task.name));
        } else if (m_task.method == QStringLiteral("flatpak")) {
            if (m_task.installScope == QStringLiteral("system")) {
                if (sudoAvailable())
                    startFlatpakSudo(QString());
                else
                    requestAuth(QStringLiteral("卸载系统级 Flatpak 应用「%1」需要管理员权限。").arg(m_task.name));
            } else {
                startFlatpakUserUninstall();
            }
        } else if (m_task.method == QStringLiteral("githubAppImage")) {
            uninstallAppImage();
        } else if (m_task.method == QStringLiteral("webapp")) {
            uninstallWebApp();
        } else if (m_task.method == QStringLiteral("npm")) {
            startNpm(true);
        } else if (m_task.method == QStringLiteral("script")) {
            startScript(true);
        } else {
            fail(QStringLiteral("不支持卸载这个应用：%1").arg(m_task.method));
        }
        return;
    }

    if (m_task.method == QStringLiteral("apt")) {
        if (sudoAvailable())
            startApt(QString());
        else
            requestAuth(QStringLiteral("安装「%1」需要管理员权限。请输入系统密码。").arg(m_task.name));
    } else if (m_task.method == QStringLiteral("directDeb")) {
        QString name = m_task.fileName;
        if (name.isEmpty())
            name = m_task.package + QStringLiteral(".deb");
        beginDownload(m_task.directUrl, name);
    } else if (m_task.method == QStringLiteral("githubDeb")
               || m_task.method == QStringLiteral("githubAppImage")) {
        resolveGitHub();
    } else if (m_task.method == QStringLiteral("flatpak")) {
        startFlatpak();
    } else if (m_task.method == QStringLiteral("webapp")) {
        installWebApp();
    } else if (m_task.method == QStringLiteral("npm")) {
        startNpm(false);
    } else if (m_task.method == QStringLiteral("script")) {
        startScript(false);
    } else {
        fail(QStringLiteral("不支持的安装方式：%1").arg(m_task.method));
    }
}

void Installer::resolveGitHub()
{
    if (m_task.githubRepo.isEmpty()) {
        fail(QStringLiteral("没有配置 GitHub 仓库地址"));
        return;
    }

    setPhase(QStringLiteral("正在获取最新版本"));
    setStatus(QStringLiteral("连接 GitHub Releases…"));
    setAppState(QStringLiteral("preparing"), -1, QStringLiteral("正在获取最新版本"));

    m_networkKind = GithubApi;
    QNetworkRequest request{QUrl(QStringLiteral("https://api.github.com/repos/%1/releases/latest")
                                     .arg(m_task.githubRepo))};
    request.setAttribute(QNetworkRequest::RedirectPolicyAttribute,
                         QNetworkRequest::NoLessSafeRedirectPolicy);
    request.setRawHeader("User-Agent", "ClavisAppStore/1.0 (Linux; arm64)");
    request.setRawHeader("Accept", "application/vnd.github+json");

    m_reply = m_network.get(request);
    connect(m_reply, &QNetworkReply::finished, this, [this]() {
        if (m_reply)
            handleNetworkFinished(m_reply);
    });
}

void Installer::beginDownload(const QString &url, const QString &fileName)
{
    if (url.isEmpty()) {
        fail(QStringLiteral("下载地址为空"));
        return;
    }

    QDir().mkpath(m_catalog->downloadDir());
    m_downloadPath = QDir(m_catalog->downloadDir()).filePath(sanitizedFileName(fileName));

    if (QFileInfo::exists(m_downloadPath))
        QFile::remove(m_downloadPath);

    m_downloadFile = new QFile(m_downloadPath);
    if (!m_downloadFile->open(QIODevice::WriteOnly | QIODevice::Truncate)) {
        const QString error = m_downloadFile->errorString();
        delete m_downloadFile;
        m_downloadFile = nullptr;
        fail(QStringLiteral("无法写入下载文件：%1").arg(error));
        return;
    }

    setPhase(QStringLiteral("正在下载"));
    setProgress(0);
    setStatus(QStringLiteral("0%"));
    setAppState(QStringLiteral("downloading"), 0, QStringLiteral("正在下载"));

    m_networkKind = Download;
    QNetworkRequest request{QUrl(url)};
    request.setAttribute(QNetworkRequest::RedirectPolicyAttribute,
                         QNetworkRequest::NoLessSafeRedirectPolicy);
    request.setRawHeader("User-Agent", "ClavisAppStore/1.0 (Linux; arm64)");
    request.setRawHeader("Accept", "*/*");

    m_reply = m_network.get(request);

    connect(m_reply, &QNetworkReply::downloadProgress, this,
            [this](qint64 received, qint64 total) {
        if (total > 0) {
            const double value = qBound(0.0, double(received) / double(total), 1.0);
            setProgress(value);
            setStatus(QStringLiteral("%1%").arg(int(value * 100)));
            setAppState(QStringLiteral("downloading"), value,
                        QStringLiteral("正在下载 %1%").arg(int(value * 100)));
        } else {
            setProgress(-1);
            setStatus(QStringLiteral("正在下载…"));
            setAppState(QStringLiteral("downloading"), -1, QStringLiteral("正在下载…"));
        }
    });

    connect(m_reply, &QNetworkReply::readyRead, this, [this]() {
        if (m_downloadFile && m_reply)
            m_downloadFile->write(m_reply->readAll());
    });

    connect(m_reply, &QNetworkReply::finished, this, [this]() {
        if (m_reply)
            handleNetworkFinished(m_reply);
    });
}

void Installer::handleNetworkFinished(QNetworkReply *reply)
{
    const NetworkKind kind = m_networkKind;
    m_networkKind = NoNetwork;
    m_reply = nullptr;

    const int status = reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
    const QNetworkReply::NetworkError networkError = reply->error();
    const QString networkErrorText = reply->errorString();
    const QByteArray payload = reply->readAll();
    reply->deleteLater();

    if (kind == GithubApi) {
        if (networkError != QNetworkReply::NoError || status >= 400) {
            QString message = networkErrorText;
            if (status == 403)
                message = QStringLiteral("GitHub API 访问受限（可能已达到速率限制），请稍后重试。");
            fail(QStringLiteral("获取 GitHub 版本失败：%1").arg(message));
            return;
        }

        const QJsonDocument document = QJsonDocument::fromJson(payload);
        if (!document.isObject()) {
            fail(QStringLiteral("GitHub 返回了无法解析的数据"));
            return;
        }

        const QJsonObject release = document.object();
        QString tag = release.value(QStringLiteral("tag_name")).toString();
        if (tag.startsWith(QLatin1Char('v')))
            tag.remove(0, 1);
        if (!tag.isEmpty())
            m_task.version = tag;

        const QJsonArray assets = release.value(QStringLiteral("assets")).toArray();
        QString url;
        QString fileName;
        const QString hint = normalizedAssetName(m_task.assetHint);

        for (const QJsonValue &value : assets) {
            const QJsonObject asset = value.toObject();
            const QString name = asset.value(QStringLiteral("name")).toString();
            const QString lower = name.toLower();
            if (lower.contains(QStringLiteral(".sha"))
                || lower.contains(QStringLiteral(".sig"))
                || lower.contains(QStringLiteral(".blockmap"))
                || lower.contains(QStringLiteral(".zsync")))
                continue;
            if (!hint.isEmpty() && normalizedAssetName(name).contains(hint)) {
                url = asset.value(QStringLiteral("browser_download_url")).toString();
                fileName = name;
                break;
            }
        }

        if (url.isEmpty()) {
            for (const QJsonValue &value : assets) {
                const QJsonObject asset = value.toObject();
                const QString name = asset.value(QStringLiteral("name")).toString();
                const QString lower = name.toLower();
                if (lower.contains(QStringLiteral(".sha"))
                    || lower.contains(QStringLiteral(".sig"))
                    || lower.contains(QStringLiteral(".blockmap"))
                    || lower.contains(QStringLiteral(".zsync")))
                    continue;
                const bool appImage = m_task.method == QStringLiteral("githubAppImage");
                const bool deb = m_task.method == QStringLiteral("githubDeb");
                const bool arm = lower.contains(QStringLiteral("arm64"))
                    || lower.contains(QStringLiteral("aarch64"))
                    || lower.contains(QStringLiteral("arm-64"));
                if (appImage && arm && lower.endsWith(QStringLiteral(".appimage"))) {
                    url = asset.value(QStringLiteral("browser_download_url")).toString();
                    fileName = name;
                    break;
                }
                if (deb && arm && lower.endsWith(QStringLiteral(".deb"))) {
                    url = asset.value(QStringLiteral("browser_download_url")).toString();
                    fileName = name;
                    break;
                }
            }
        }

        if (url.isEmpty()) {
            fail(QStringLiteral("在最新版本中没有找到适用于 arm64 的安装包"));
            return;
        }

        appendLog(QStringLiteral("GitHub %1 %2 -> %3").arg(m_task.githubRepo, m_task.version, fileName));
        beginDownload(url, fileName);
        return;
    }

    if (kind == Download) {
        if (m_downloadFile) {
            m_downloadFile->flush();
            m_downloadFile->close();
            delete m_downloadFile;
            m_downloadFile = nullptr;
        }

        if (networkError != QNetworkReply::NoError || status >= 400 || status == 0) {
            QFile::remove(m_downloadPath);
            fail(QStringLiteral("下载失败：%1").arg(networkErrorText));
            return;
        }

        const QFileInfo info(m_downloadPath);
        if (!info.exists() || info.size() == 0) {
            QFile::remove(m_downloadPath);
            fail(QStringLiteral("下载的文件为空"));
            return;
        }

        m_task.filePath = m_downloadPath;
        appendLog(QStringLiteral("downloaded %1 (%2 bytes)").arg(m_downloadPath).arg(info.size()));
        setProgress(1);
        setStatus(QStringLiteral("下载完成"));

        if (m_task.method == QStringLiteral("githubAppImage")) {
            installAppImage();
        } else {
            if (sudoAvailable())
                startApt(QString());
            else
                requestAuth(QStringLiteral("「%1」已下载完成。安装需要管理员权限。").arg(m_task.name));
        }
    }
}

void Installer::startApt(const QString &password)
{
    const QString target = m_task.uninstall
        ? m_task.package
        : (m_task.filePath.isEmpty() ? m_task.package : m_task.filePath);
    if (target.isEmpty()) {
        fail(m_task.uninstall ? QStringLiteral("没有可卸载的软件包")
                              : QStringLiteral("没有可安装的软件包"));
        return;
    }

    m_processKind = AptProcess;
    m_processOutput.clear();
    m_processError.clear();
    m_pendingPassword = password;

    setPhase(m_task.uninstall ? QStringLiteral("正在卸载") : QStringLiteral("正在安装"));
    setProgress(-1);
    setStatus(m_task.uninstall ? QStringLiteral("等待软件包管理器…")
                               : QStringLiteral("等待软件包管理器…"));
    setAppState(m_task.uninstall ? QStringLiteral("uninstalling") : QStringLiteral("installing"),
                -1, m_task.uninstall ? QStringLiteral("正在卸载") : QStringLiteral("正在安装"));

    QStringList arguments;
    if (password.isEmpty())
        arguments << QStringLiteral("-n");
    else
        arguments << QStringLiteral("-S") << QStringLiteral("-p") << QString();

    arguments << QStringLiteral("env")
              << QStringLiteral("DEBIAN_FRONTEND=noninteractive")
              << QStringLiteral("apt-get")
              << (m_task.uninstall ? QStringLiteral("remove") : QStringLiteral("install"))
              << QStringLiteral("-y")
              << target;

    QProcessEnvironment environment = QProcessEnvironment::systemEnvironment();
    environment.insert(QStringLiteral("LC_ALL"), QStringLiteral("C"));
    environment.insert(QStringLiteral("LANG"), QStringLiteral("C"));
    m_process.setProcessEnvironment(environment);
    m_process.setProcessChannelMode(QProcess::SeparateChannels);
    m_process.setWorkingDirectory(QDir::homePath());
    m_process.setProgram(QStringLiteral("sudo"));
    m_process.setArguments(arguments);
    m_process.start();
}

void Installer::startFlatpak()
{
    if (!m_task.update) {
        startFlatpakUserInstall();
        return;
    }

    if (m_task.installScope == QStringLiteral("system")) {
        if (sudoAvailable())
            startFlatpakSudo(QString());
        else
            requestAuth(QStringLiteral("更新系统级的 Flatpak 应用需要管理员权限。"));
        return;
    }

    startFlatpakUserUpdate();
}

void Installer::startFlatpakUserInstall()
{
    m_processKind = FlatpakProcess;
    m_processOutput.clear();
    m_processError.clear();
    m_pendingPassword.clear();

    setPhase(QStringLiteral("正在从 Flathub 下载"));
    setProgress(-1);
    setStatus(QStringLiteral("正在连接 Flathub…"));
    setAppState(QStringLiteral("downloading"), -1, QStringLiteral("正在从 Flathub 下载"));

    QProcessEnvironment environment = QProcessEnvironment::systemEnvironment();
    environment.insert(QStringLiteral("LC_ALL"), QStringLiteral("C"));
    environment.insert(QStringLiteral("LANG"), QStringLiteral("C"));
    m_process.setProcessEnvironment(environment);
    m_process.setWorkingDirectory(QDir::homePath());
    m_process.setProgram(QStringLiteral("flatpak"));
    m_process.setArguments({QStringLiteral("install"), QStringLiteral("-y"),
                            QStringLiteral("--user"), QStringLiteral("flathub"),
                            m_task.flatpakId});
    m_process.start();
}

void Installer::startFlatpakUserUpdate()
{
    m_processKind = FlatpakProcess;
    m_processOutput.clear();
    m_processError.clear();
    m_pendingPassword.clear();

    setPhase(QStringLiteral("正在更新"));
    setProgress(-1);
    setStatus(QStringLiteral("正在从 Flathub 获取更新…"));
    setAppState(QStringLiteral("installing"), -1, QStringLiteral("正在更新"));

    QProcessEnvironment environment = QProcessEnvironment::systemEnvironment();
    environment.insert(QStringLiteral("LC_ALL"), QStringLiteral("C"));
    environment.insert(QStringLiteral("LANG"), QStringLiteral("C"));
    m_process.setProcessEnvironment(environment);
    m_process.setWorkingDirectory(QDir::homePath());
    m_process.setProgram(QStringLiteral("flatpak"));
    m_process.setArguments({QStringLiteral("update"), QStringLiteral("-y"),
                            QStringLiteral("--user"), m_task.flatpakId});
    m_process.start();
}

void Installer::startNpm(bool uninstall)
{
    if (m_task.package.isEmpty()) {
        fail(QStringLiteral("没有配置 npm 包名"));
        return;
    }

    m_processKind = NpmProcess;
    m_processOutput.clear();
    m_processError.clear();
    m_pendingPassword.clear();

    setPhase(uninstall ? QStringLiteral("正在卸载") : QStringLiteral("正在安装"));
    setProgress(-1);
    setStatus(uninstall ? QStringLiteral("正在移除 npm 全局包…")
                        : QStringLiteral("正在从 npm 下载并安装…"));
    setAppState(uninstall ? QStringLiteral("uninstalling") : QStringLiteral("installing"),
                -1, uninstall ? QStringLiteral("正在卸载") : QStringLiteral("正在安装"));

    QProcessEnvironment environment = QProcessEnvironment::systemEnvironment();
    environment.insert(QStringLiteral("LC_ALL"), QStringLiteral("C"));
    m_process.setProcessEnvironment(environment);
    m_process.setWorkingDirectory(QDir::homePath());
    m_process.setProgram(QStringLiteral("npm"));
    m_process.setArguments({uninstall ? QStringLiteral("uninstall") : QStringLiteral("install"),
                            QStringLiteral("-g"), m_task.package});
    m_process.start();
}

void Installer::startScript(bool uninstall)
{
    const QString command = uninstall ? m_task.uninstallCommand
                                      : QStringLiteral("curl -fsSL %1 | bash").arg(m_task.directUrl);
    if (command.trimmed().isEmpty()) {
        fail(QStringLiteral("没有配置安装/卸载脚本"));
        return;
    }

    m_processKind = ScriptProcess;
    m_processOutput.clear();
    m_processError.clear();
    m_pendingPassword.clear();

    setPhase(uninstall ? QStringLiteral("正在卸载") : QStringLiteral("正在安装"));
    setProgress(-1);
    setStatus(uninstall ? QStringLiteral("正在移除命令行工具…")
                        : QStringLiteral("正在运行官方安装脚本…"));
    setAppState(uninstall ? QStringLiteral("uninstalling") : QStringLiteral("installing"),
                -1, uninstall ? QStringLiteral("正在卸载") : QStringLiteral("正在安装"));

    QProcessEnvironment environment = QProcessEnvironment::systemEnvironment();
    environment.insert(QStringLiteral("LC_ALL"), QStringLiteral("C"));
    m_process.setProcessEnvironment(environment);
    m_process.setWorkingDirectory(QDir::homePath());
    m_process.setProgram(QStringLiteral("bash"));
    m_process.setArguments({QStringLiteral("-lc"), command});
    m_process.start();
}

void Installer::startFlatpakUserUninstall()
{
    m_processKind = FlatpakProcess;
    m_processOutput.clear();
    m_processError.clear();
    m_pendingPassword.clear();

    setPhase(QStringLiteral("正在卸载"));
    setProgress(-1);
    setStatus(QStringLiteral("正在移除 Flatpak 应用…"));
    setAppState(QStringLiteral("uninstalling"), -1, QStringLiteral("正在卸载"));

    QProcessEnvironment environment = QProcessEnvironment::systemEnvironment();
    environment.insert(QStringLiteral("LC_ALL"), QStringLiteral("C"));
    environment.insert(QStringLiteral("LANG"), QStringLiteral("C"));
    m_process.setProcessEnvironment(environment);
    m_process.setWorkingDirectory(QDir::homePath());
    m_process.setProgram(QStringLiteral("flatpak"));
    m_process.setArguments({QStringLiteral("uninstall"), QStringLiteral("-y"),
                            QStringLiteral("--user"), m_task.flatpakId});
    m_process.start();
}

void Installer::startFlatpakSudo(const QString &password)
{
    m_processKind = FlatpakProcess;
    m_processOutput.clear();
    m_processError.clear();
    m_pendingPassword = password;

    const bool removing = m_task.uninstall;
    setPhase(removing ? QStringLiteral("正在卸载系统应用")
                      : (m_task.update ? QStringLiteral("正在更新系统应用")
                                       : QStringLiteral("正在安装系统应用")));
    setProgress(-1);
    setStatus(QStringLiteral("等待管理员授权…"));
    setAppState(removing ? QStringLiteral("uninstalling") : QStringLiteral("installing"), -1,
                removing ? QStringLiteral("正在卸载")
                         : (m_task.update ? QStringLiteral("正在更新") : QStringLiteral("正在安装")));

    QStringList arguments;
    if (password.isEmpty())
        arguments << QStringLiteral("-n");
    else
        arguments << QStringLiteral("-S") << QStringLiteral("-p") << QString();
    arguments << QStringLiteral("flatpak")
              << (removing ? QStringLiteral("uninstall")
                           : (m_task.update ? QStringLiteral("update") : QStringLiteral("install")))
              << QStringLiteral("-y");
    if (!m_task.update && !removing)
        arguments << QStringLiteral("flathub");
    arguments << m_task.flatpakId;

    QProcessEnvironment environment = QProcessEnvironment::systemEnvironment();
    environment.insert(QStringLiteral("LC_ALL"), QStringLiteral("C"));
    environment.insert(QStringLiteral("LANG"), QStringLiteral("C"));
    m_process.setProcessEnvironment(environment);
    m_process.setWorkingDirectory(QDir::homePath());
    m_process.setProgram(QStringLiteral("sudo"));
    m_process.setArguments(arguments);
    m_process.start();
}

void Installer::submitPassword(const QString &appId, const QString &password)
{
    if (!m_busy || !m_waitingForAuth || appId != m_task.appId)
        return;

    if (password.isEmpty()) {
        emit toast(QStringLiteral("请输入系统密码"), true);
        return;
    }

    m_waitingForAuth = false;
    setPhase(m_task.uninstall ? QStringLiteral("正在卸载") : QStringLiteral("正在安装"));
    setProgress(-1);
    setStatus(QStringLiteral("正在验证管理员权限…"));
    setAppState(m_task.uninstall ? QStringLiteral("uninstalling") : QStringLiteral("installing"),
                -1, m_task.uninstall ? QStringLiteral("正在卸载") : QStringLiteral("正在安装"));

    if (m_task.method == QStringLiteral("apt")
        || m_task.method == QStringLiteral("directDeb")
        || m_task.method == QStringLiteral("githubDeb")) {
        startApt(password);
    } else if (m_task.method == QStringLiteral("flatpak")) {
        startFlatpakSudo(password);
    } else {
        fail(QStringLiteral("当前任务不需要管理员授权"));
    }
}

void Installer::cancelAuth(const QString &appId)
{
    if (!m_busy || !m_waitingForAuth || appId != m_task.appId)
        return;

    m_waitingForAuth = false;
    setAppState(QStringLiteral("idle"), 0, QString());
    setPhase(QString());
    setStatus(QString());
    setProgress(0);
    setBusy(false);
    emit toast(m_task.uninstall ? QStringLiteral("已取消卸载") : QStringLiteral("已取消安装"), false);
    appendLog(QStringLiteral("authorization cancelled for %1").arg(m_task.appId));

    if (m_batch)
        nextQueuedTask();
}

void Installer::handleProcessOutput(bool errorChannel)
{
    const QByteArray data = errorChannel ? m_process.readAllStandardError()
                                         : m_process.readAllStandardOutput();
    if (data.isEmpty())
        return;

    const QString text = QString::fromUtf8(data);
    if (errorChannel)
        m_processError += text;
    else
        m_processOutput += text;

    const QStringList lines = text.split(QLatin1Char('\n'), Qt::SkipEmptyParts);
    for (const QString &rawLine : lines) {
        const QString line = rawLine.trimmed();
        if (line.isEmpty())
            continue;

        if (m_processKind == AptProcess) {
            if (m_task.uninstall) {
                if (line.contains(QStringLiteral("Removing"))) {
                    setPhase(QStringLiteral("正在卸载"));
                    setStatus(QStringLiteral("正在移除应用文件…"));
                } else if (line.contains(QStringLiteral("Purging"))) {
                    setStatus(QStringLiteral("正在清理配置文件…"));
                } else if (line.contains(QStringLiteral("Processing triggers"))) {
                    setStatus(QStringLiteral("正在完成卸载…"));
                }
            } else if (line.contains(QStringLiteral("Get:")) || line.contains(QStringLiteral("Fetching"))) {
                setPhase(QStringLiteral("正在下载软件包"));
                setStatus(QStringLiteral("正在从 Ubuntu 软件源下载…"));
            } else if (line.contains(QStringLiteral("Unpacking"))) {
                setPhase(QStringLiteral("正在安装"));
                setStatus(QStringLiteral("正在解压软件包…"));
            } else if (line.contains(QStringLiteral("Setting up"))) {
                setStatus(QStringLiteral("正在配置应用…"));
            } else if (line.contains(QStringLiteral("Processing triggers"))) {
                setStatus(QStringLiteral("正在完成安装…"));
            }
        } else if (m_processKind == NpmProcess || m_processKind == ScriptProcess) {
            if (line.contains(QStringLiteral("added")) || line.contains(QStringLiteral("installed"))) {
                setStatus(QStringLiteral("正在完成安装…"));
            } else if (line.contains(QStringLiteral("removed"))) {
                setStatus(QStringLiteral("正在完成卸载…"));
            }
        } else if (m_processKind == FlatpakProcess) {
            static const QRegularExpression percentExpression(QStringLiteral("(\\d{1,3})%"));
            const QRegularExpressionMatch match = percentExpression.match(line);
            if (match.hasMatch()) {
                const int percent = qBound(0, match.captured(1).toInt(), 99);
                const double value = double(percent) / 100.0;
                setProgress(value);
                setStatus(QStringLiteral("%1%").arg(percent));
                setAppState(m_task.uninstall ? QStringLiteral("uninstalling")
                                             : QStringLiteral("installing"),
                            value,
                            (m_task.uninstall ? QStringLiteral("正在卸载 %1%")
                                              : QStringLiteral("正在安装 %1%")).arg(percent));
            }
        }
    }
}

void Installer::handleProcessFinished(int exitCode, QProcess::ExitStatus status)
{
    handleProcessOutput(false);
    handleProcessOutput(true);

    const ProcessKind kind = m_processKind;
    m_processKind = NoProcess;

    if (kind == NoProcess)
        return;

    appendLog(QStringLiteral("process finished kind=%1 code=%2").arg(int(kind)).arg(exitCode));

    if (kind == ExtractProcess) {
        if (status != QProcess::NormalExit || exitCode != 0) {
            fail(QStringLiteral("展开 AppImage 失败：%1").arg(outputTail()));
            return;
        }

        const QString target = QDir(m_catalog->applicationsDir()).filePath(m_task.appId);
        const QString temp = QDir(m_catalog->applicationsDir())
                                 .filePath(QStringLiteral(".extract-%1-%2")
                                               .arg(m_task.appId)
                                               .arg(QCoreApplication::applicationPid()));
        const QString source = QDir(temp).filePath(QStringLiteral("squashfs-root"));

        if (!QFileInfo(source).isDir()) {
            fail(QStringLiteral("AppImage 中没有找到可用的应用目录"));
            return;
        }

        if (QFileInfo::exists(target) && !QDir(target).removeRecursively()) {
            fail(QStringLiteral("无法替换旧版本应用目录"));
            return;
        }

        if (!QDir().rename(source, target)) {
            fail(QStringLiteral("无法把 AppImage 安装到 ~/Applications"));
            return;
        }

        QDir(temp).removeRecursively();
        createDesktopEntry(target, m_task.name);
        finalizeSuccess();
        return;
    }

    if (status == QProcess::NormalExit && exitCode == 0) {
        if (m_task.uninstall)
            finalizeUninstall();
        else
            finalizeSuccess();
        return;
    }

    const QString combined = m_processError + QLatin1Char('\n') + m_processOutput;
    if (looksLikeAuthFailure(combined)) {
        requestAuth(QStringLiteral("密码不正确，请重试。密码仅用于本次系统授权。"));
        return;
    }

    if (kind == FlatpakProcess && (m_task.update || m_task.uninstall)
        && (m_task.installScope != QStringLiteral("system"))
        && (combined.contains(QStringLiteral("not installed"))
            || combined.contains(QStringLiteral("未安装"))
            || combined.contains(QStringLiteral("system installation")))) {
        m_task.installScope = QStringLiteral("system");
        requestAuth(m_task.uninstall
                        ? QStringLiteral("这个 Flatpak 应用安装在系统范围内，卸载需要管理员权限。")
                        : QStringLiteral("这个 Flatpak 应用安装在系统范围内，更新需要管理员权限。"));
        return;
    }

    if (kind == FlatpakProcess && !m_task.update && !m_task.uninstall
        && (combined.contains(QStringLiteral("No remote refs"))
            || combined.contains(QStringLiteral("未发现用于"))
            || combined.contains(QStringLiteral("remote refs found")))) {
        m_task.installScope = QStringLiteral("system");
        requestAuth(QStringLiteral("Flathub 只配置在系统范围，安装「%1」需要管理员权限。").arg(m_task.name));
        return;
    }

    fail((m_task.uninstall ? QStringLiteral("卸载失败：%1")
                           : QStringLiteral("安装失败：%1")).arg(outputTail()));
}

void Installer::installAppImage()
{
    if (!QFileInfo::exists(m_task.filePath)) {
        fail(QStringLiteral("AppImage 文件不存在"));
        return;
    }

    setPhase(QStringLiteral("正在展开应用"));
    setProgress(-1);
    setStatus(QStringLiteral("正在准备应用目录…"));
    setAppState(QStringLiteral("installing"), -1, QStringLiteral("正在安装"));

    QFile::setPermissions(m_task.filePath,
                          QFileDevice::ReadOwner | QFileDevice::WriteOwner
                              | QFileDevice::ExeOwner | QFileDevice::ReadGroup
                              | QFileDevice::ReadOther | QFileDevice::ExeGroup
                              | QFileDevice::ExeOther);

    const QDir applications(m_catalog->applicationsDir());
    QDir().mkpath(applications.absolutePath());
    const QString temp = applications.filePath(QStringLiteral(".extract-%1-%2")
                                                   .arg(m_task.appId)
                                                   .arg(QCoreApplication::applicationPid()));
    QDir(temp).removeRecursively();
    QDir().mkpath(temp);

    m_processKind = ExtractProcess;
    m_processOutput.clear();
    m_processError.clear();
    m_pendingPassword.clear();

    QProcessEnvironment environment = QProcessEnvironment::systemEnvironment();
    environment.insert(QStringLiteral("LC_ALL"), QStringLiteral("C"));
    environment.insert(QStringLiteral("LANG"), QStringLiteral("C"));
    m_process.setProcessEnvironment(environment);
    m_process.setWorkingDirectory(temp);
    m_process.setProgram(m_task.filePath);
    m_process.setArguments({QStringLiteral("--appimage-extract")});
    m_process.start();
}

void Installer::createDesktopEntry(const QString &targetDir, const QString &appName)
{
    const QString applications = QStandardPaths::writableLocation(QStandardPaths::ApplicationsLocation);
    const QString iconDir = QStandardPaths::writableLocation(QStandardPaths::GenericDataLocation)
        + QStringLiteral("/icons/hicolor/256x256/apps");
    QDir().mkpath(applications);
    QDir().mkpath(iconDir);

    QString iconPath;
    QDirIterator iterator(targetDir,
                          QStringList{QStringLiteral("*.png"), QStringLiteral("*.svg")},
                          QDir::Files, QDirIterator::Subdirectories);
    qint64 bestSize = -1;
    QString bestPath;
    while (iterator.hasNext()) {
        const QString candidate = iterator.next();
        const QFileInfo info(candidate);
        if (info.size() > bestSize) {
            bestSize = info.size();
            bestPath = candidate;
        }
    }

    if (!bestPath.isEmpty()) {
        const QFileInfo info(bestPath);
        const QString extension = info.suffix().toLower();
        const QString destination = QDir(iconDir).filePath(
            QStringLiteral("org.clavis.AppStore.%1.%2").arg(m_task.appId, extension));
        QFile::remove(destination);
        if (QFile::copy(bestPath, destination))
            iconPath = destination;
        else
            iconPath = bestPath;
    }

    if (iconPath.isEmpty()) {
        if (const AppEntry *app = m_catalog->model()->entry(m_task.appId)) {
            const QString resource = QStringLiteral(":/qt/qml/AppStore/assets/icons/%1").arg(app->icon);
            const QString destination = QDir(iconDir).filePath(
                QStringLiteral("org.clavis.AppStore.%1.svg").arg(m_task.appId));
            QFile::remove(destination);
            if (QFile::copy(resource, destination))
                iconPath = destination;
        }
    }

    const QString executable = QDir(targetDir).filePath(QStringLiteral("AppRun"));
    QString entry;
    entry += QStringLiteral("[Desktop Entry]\n");
    entry += QStringLiteral("Type=Application\n");
    entry += QStringLiteral("Version=1.0\n");
    entry += QStringLiteral("Name=%1\n").arg(appName);
    entry += QStringLiteral("Name[zh_CN]=%1\n").arg(appName);
    entry += QStringLiteral("Comment=Installed by App Store\n");
    entry += QStringLiteral("Exec=\"%1\"\n").arg(executable);
    if (!iconPath.isEmpty())
        entry += QStringLiteral("Icon=%1\n").arg(iconPath);
    entry += QStringLiteral("Terminal=false\n");
    entry += QStringLiteral("Categories=Utility;\n");
    entry += QStringLiteral("StartupNotify=true\n");
    entry += QStringLiteral("X-AppStore-Managed=true\n");

    QFile desktop(QDir(applications).filePath(
        QStringLiteral("org.clavis.AppStore.%1.desktop").arg(m_task.appId)));
    if (desktop.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
        desktop.write(entry.toUtf8());
        desktop.close();
    }

    QProcess::startDetached(QStringLiteral("update-desktop-database"),
                            QStringList{applications});
}

void Installer::installWebApp()
{
    const AppEntry *app = m_catalog->model()->entry(m_task.appId);
    if (!app) {
        fail(QStringLiteral("找不到应用信息"));
        return;
    }

    setPhase(QStringLiteral("正在创建 Web 应用"));
    setProgress(-1);
    setStatus(QStringLiteral("正在生成桌面启动项…"));
    setAppState(QStringLiteral("installing"), -1, QStringLiteral("正在创建 Web 应用"));

    const QString applications = QStandardPaths::writableLocation(QStandardPaths::ApplicationsLocation);
    const QString iconRoot = QStandardPaths::writableLocation(QStandardPaths::GenericDataLocation)
        + QStringLiteral("/icons/hicolor/scalable/apps");
    if (!QDir().mkpath(applications) || !QDir().mkpath(iconRoot)) {
        fail(QStringLiteral("无法创建桌面入口目录"));
        return;
    }

    QString desktopId = app->desktopId;
    if (desktopId.isEmpty())
        desktopId = QStringLiteral("org.clavis.AppStore.%1.desktop").arg(app->id);
    if (!desktopId.endsWith(QStringLiteral(".desktop")))
        desktopId += QStringLiteral(".desktop");

    const QString iconExtension = app->icon.endsWith(QStringLiteral(".png"), Qt::CaseInsensitive)
        ? QStringLiteral("png") : QStringLiteral("svg");
    const QString iconName = QStringLiteral("org.clavis.AppStore.%1.%2").arg(app->id, iconExtension);
    const QString iconPath = QDir(iconRoot).filePath(iconName);
    const QString iconResource = QStringLiteral(":/qt/qml/AppStore/assets/icons/%1").arg(app->icon);
    QFile::remove(iconPath);
    if (!app->icon.isEmpty())
        QFile::copy(iconResource, iconPath);

    QString browser;
    const QStringList candidates = {
        QStringLiteral("google-chrome-stable"), QStringLiteral("google-chrome"),
        QStringLiteral("chromium"), QStringLiteral("brave-browser"),
        QStringLiteral("vivaldi"), QStringLiteral("microsoft-edge"),
        QStringLiteral("firefox")
    };
    for (const QString &candidate : candidates) {
        browser = QStandardPaths::findExecutable(candidate);
        if (!browser.isEmpty())
            break;
    }

    const QString url = app->homepage.isEmpty() ? QStringLiteral("https://chatgpt.com") : app->homepage;
    QString executable;
    if (browser.isEmpty() || browser.endsWith(QStringLiteral("firefox"))) {
        const QString opener = QStandardPaths::findExecutable(QStringLiteral("xdg-open"));
        executable = QStringLiteral("\"%1\" %2").arg(opener.isEmpty() ? QStringLiteral("xdg-open") : opener, url);
    } else {
        executable = QStringLiteral("\"%1\" --app=%2").arg(browser, url);
    }

    QString entry;
    entry += QStringLiteral("[Desktop Entry]\n");
    entry += QStringLiteral("Type=Application\n");
    entry += QStringLiteral("Version=1.0\n");
    entry += QStringLiteral("Name=%1\n").arg(app->name);
    entry += QStringLiteral("Name[zh_CN]=%1\n").arg(app->name);
    entry += QStringLiteral("Comment=%1\n").arg(app->subtitle);
    entry += QStringLiteral("Exec=%1\n").arg(executable);
    if (!app->icon.isEmpty())
        entry += QStringLiteral("Icon=%1\n").arg(iconPath);
    entry += QStringLiteral("Terminal=false\n");
    entry += QStringLiteral("Categories=Network;\n");
    entry += QStringLiteral("StartupNotify=true\n");
    entry += QStringLiteral("X-AppStore-Managed=true\n");

    QFile desktop(QDir(applications).filePath(desktopId));
    if (!desktop.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
        fail(QStringLiteral("无法写入桌面启动项"));
        return;
    }
    desktop.write(entry.toUtf8());
    desktop.close();

    QProcess::startDetached(QStringLiteral("update-desktop-database"),
                            QStringList{applications});
    finalizeSuccess();
}

void Installer::uninstallWebApp()
{
    setPhase(QStringLiteral("正在卸载"));
    setProgress(-1);
    setStatus(QStringLiteral("正在删除 Web 应用启动项…"));
    setAppState(QStringLiteral("uninstalling"), -1, QStringLiteral("正在卸载"));

    const QString applications = QStandardPaths::writableLocation(QStandardPaths::ApplicationsLocation);
    const QString iconRoot = QStandardPaths::writableLocation(QStandardPaths::GenericDataLocation)
        + QStringLiteral("/icons/hicolor/scalable/apps");
    QString desktopId = m_task.appId;
    if (const AppEntry *app = m_catalog->model()->entry(m_task.appId)) {
        if (!app->desktopId.isEmpty())
            desktopId = app->desktopId;
    }
    if (desktopId.isEmpty())
        desktopId = QStringLiteral("org.clavis.AppStore.%1.desktop").arg(m_task.appId);
    if (!desktopId.endsWith(QStringLiteral(".desktop")))
        desktopId += QStringLiteral(".desktop");

    QFile::remove(QDir(applications).filePath(desktopId));
    for (const QString &extension : {QStringLiteral("svg"), QStringLiteral("png")})
        QFile::remove(QDir(iconRoot).filePath(
            QStringLiteral("org.clavis.AppStore.%1.%2").arg(m_task.appId, extension)));

    QProcess::startDetached(QStringLiteral("update-desktop-database"),
                            QStringList{applications});
    finalizeUninstall();
}

void Installer::uninstallAppImage()
{
    setPhase(QStringLiteral("正在卸载"));
    setProgress(-1);
    setStatus(QStringLiteral("正在删除应用目录…"));
    setAppState(QStringLiteral("uninstalling"), -1, QStringLiteral("正在卸载"));

    const QDir applications(m_catalog->applicationsDir());
    const QString targetDir = applications.filePath(m_task.appId);
    const QString directImage = applications.filePath(m_task.appId + QStringLiteral(".AppImage"));

    if (QFileInfo::exists(targetDir) && !QDir(targetDir).removeRecursively()) {
        fail(QStringLiteral("无法删除应用目录：%1").arg(targetDir));
        return;
    }
    if (QFileInfo::exists(directImage) && !QFile::remove(directImage)) {
        fail(QStringLiteral("无法删除应用文件：%1").arg(directImage));
        return;
    }

    const QString applicationsPath = QStandardPaths::writableLocation(QStandardPaths::ApplicationsLocation);
    QFile::remove(QDir(applicationsPath).filePath(
        QStringLiteral("org.clavis.AppStore.%1.desktop").arg(m_task.appId)));

    const QString iconRoot = QStandardPaths::writableLocation(QStandardPaths::GenericDataLocation)
        + QStringLiteral("/icons");
    QDirIterator iconIterator(iconRoot,
                              QStringList{QStringLiteral("org.clavis.AppStore.%1.*").arg(m_task.appId)},
                              QDir::Files, QDirIterator::Subdirectories);
    while (iconIterator.hasNext())
        QFile::remove(iconIterator.next());

    QProcess::startDetached(QStringLiteral("update-desktop-database"),
                            QStringList{applicationsPath});
    finalizeUninstall();
}

void Installer::finalizeSuccess()
{
    const QString appId = m_task.appId;
    const QString name = m_task.name;
    const bool wasUpdate = m_task.update;

    QString version = m_task.version;
    if (version.isEmpty() || version == QStringLiteral("新版本")) {
        if (const AppEntry *app = m_catalog->model()->entry(appId))
            version = app->version;
    }

    m_catalog->model()->markInstalledAfterInstall(appId, version);
    setProgress(1);
    setStatus(QStringLiteral("已完成"));
    setAppState(QStringLiteral("idle"), 1, QString());
    appendLog(QStringLiteral("success %1 %2").arg(appId, version));

    emit toast(wasUpdate ? QStringLiteral("「%1」已更新").arg(name)
                         : QStringLiteral("「%1」已安装").arg(name),
               false);

    setPhase(QString());
    setStatus(QString());
    setProgress(0);
    setBusy(false);
    emit currentChanged();

    if (m_batch && !m_queue.isEmpty()) {
        QTimer::singleShot(350, this, &Installer::nextQueuedTask);
    } else {
        if (m_batch)
            m_batch = false;
        m_catalog->refresh();
    }
}

void Installer::finalizeUninstall()
{
    const QString appId = m_task.appId;
    const QString name = m_task.name;

    m_catalog->model()->markUninstalledAfterUninstall(appId);
    setStatus(QString());
    setAppState(QStringLiteral("idle"), 0, QString());
    appendLog(QStringLiteral("uninstalled %1").arg(appId));

    emit toast(QStringLiteral("「%1」已卸载").arg(name), false);
    setPhase(QString());
    setProgress(0);
    setBusy(false);
    emit currentChanged();
    m_catalog->refresh();
}

void Installer::fail(const QString &message)
{
    m_networkKind = NoNetwork;
    if (m_downloadFile) {
        m_downloadFile->close();
        delete m_downloadFile;
        m_downloadFile = nullptr;
    }
    if (m_reply) {
        QNetworkReply *reply = m_reply;
        m_reply = nullptr;
        reply->disconnect(this);
        reply->abort();
        reply->deleteLater();
    }
    m_pendingPassword.clear();

    appendLog(QStringLiteral("failure %1: %2").arg(m_task.appId, message));
    setAppState(QStringLiteral("idle"), 0, message);
    setPhase(QString());
    setStatus(QString());
    setProgress(0);
    m_waitingForAuth = false;
    setBusy(false);
    emit currentChanged();
    emit toast(message, true);

    if (m_batch && !m_queue.isEmpty()) {
        QTimer::singleShot(500, this, &Installer::nextQueuedTask);
    } else {
        if (m_batch) {
            m_batch = false;
            m_catalog->refresh();
        }
    }
}

void Installer::requestAuth(const QString &message)
{
    m_waitingForAuth = true;
    setPhase(QStringLiteral("等待管理员授权"));
    setProgress(-1);
    setStatus(message);
    setAppState(QStringLiteral("waiting"), -1, message);
    emit authRequired(m_task.appId, m_task.name, message, m_task.update);
}

void Installer::nextQueuedTask()
{
    if (m_queue.isEmpty()) {
        if (m_batch) {
            m_batch = false;
            m_catalog->refresh();
        }
        return;
    }

    const QString appId = m_queue.dequeue();
    QTimer::singleShot(150, this, [this, appId]() {
        startTask(appId, true);
    });
}

bool Installer::sudoAvailable() const
{
    QProcess process;
    process.start(QStringLiteral("sudo"), {QStringLiteral("-n"), QStringLiteral("true")});
    if (!process.waitForFinished(1500))
        return false;
    return process.exitStatus() == QProcess::NormalExit && process.exitCode() == 0;
}

QString Installer::outputTail() const
{
    QString combined = m_processError.trimmed();
    if (combined.isEmpty())
        combined = m_processOutput.trimmed();
    const QStringList lines = combined.split(QLatin1Char('\n'), Qt::SkipEmptyParts);
    QString tail = lines.isEmpty() ? QString() : lines.last().trimmed();
    if (tail.size() > 320)
        tail = tail.right(320);
    if (tail.isEmpty())
        tail = QStringLiteral("未知错误");
    return tail;
}

void Installer::setBusy(bool busy)
{
    if (m_busy == busy)
        return;
    m_busy = busy;
    emit busyChanged();
}

void Installer::setPhase(const QString &phase)
{
    if (m_phase == phase)
        return;
    m_phase = phase;
    emit phaseChanged();
}

void Installer::setStatus(const QString &status)
{
    if (m_status == status)
        return;
    m_status = status;
    emit statusChanged();
}

void Installer::setProgress(double progress)
{
    progress = qBound(-1.0, progress, 1.0);
    if (qFuzzyCompare(m_progress, progress))
        return;
    m_progress = progress;
    emit progressChanged();
}

void Installer::setAppState(const QString &state, double progress, const QString &status)
{
    m_catalog->model()->setState(m_task.appId, state, progress, status);
}

void Installer::appendLog(const QString &message)
{
    const QString directory = QDir::homePath() + QStringLiteral("/.local/state/clavis-appstore");
    QDir().mkpath(directory);
    QFile file(QDir(directory).filePath(QStringLiteral("install.log")));
    if (!file.open(QIODevice::WriteOnly | QIODevice::Append))
        return;
    QTextStream stream(&file);
    stream << QDateTime::currentDateTime().toString(Qt::ISODate) << QLatin1Char(' ')
           << message << QLatin1Char('\n');
}
