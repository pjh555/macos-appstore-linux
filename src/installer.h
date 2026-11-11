#pragma once

#include <QFile>
#include <QJsonArray>
#include <QNetworkAccessManager>
#include <QObject>
#include <QProcess>
#include <QQueue>
#include <QStringList>

class Catalog;
class QNetworkReply;

class Installer : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool busy READ busy NOTIFY busyChanged)
    Q_PROPERTY(QString currentAppId READ currentAppId NOTIFY currentChanged)
    Q_PROPERTY(QString currentName READ currentName NOTIFY currentChanged)
    Q_PROPERTY(QString phase READ phase NOTIFY phaseChanged)
    Q_PROPERTY(QString status READ status NOTIFY statusChanged)
    Q_PROPERTY(double progress READ progress NOTIFY progressChanged)
    Q_PROPERTY(QString action READ action NOTIFY actionChanged)

public:
    explicit Installer(Catalog *catalog, QObject *parent = nullptr);

    bool busy() const { return m_busy; }
    QString currentAppId() const { return m_task.appId; }
    QString currentName() const { return m_task.name; }
    QString phase() const { return m_phase; }
    QString status() const { return m_status; }
    double progress() const { return m_progress; }
    QString action() const;

    Q_INVOKABLE void install(const QString &appId);
    Q_INVOKABLE void updateAll();
    Q_INVOKABLE void uninstall(const QString &appId);
    Q_INVOKABLE void submitPassword(const QString &appId, const QString &password);
    Q_INVOKABLE void cancelAuth(const QString &appId);

signals:
    void busyChanged();
    void currentChanged();
    void phaseChanged();
    void statusChanged();
    void progressChanged();
    void actionChanged();
    void authRequired(const QString &appId, const QString &name,
                      const QString &message, bool update);
    void toast(const QString &message, bool error);

private:
    struct Task {
        QString appId;
        QString name;
        QString version;
        QString method;
        QString package;
        QString githubRepo;
        QString assetHint;
        QString directUrl;
        QString fileName;
        QString flatpakId;
        QString installScope;
        bool update = false;
        bool uninstall = false;
        QString uninstallCommand;
        QString url;
        QString filePath;
    };

    enum ProcessKind {
        NoProcess,
        AptProcess,
        FlatpakProcess,
        ExtractProcess,
        NpmProcess,
        ScriptProcess
    };

    enum NetworkKind {
        NoNetwork,
        GithubApi,
        Download
    };

    void startTask(const QString &appId, bool update, bool uninstall = false);
    void beginDownload(const QString &url, const QString &fileName);
    void resolveGitHub();
    void handleNetworkFinished(QNetworkReply *reply);
    void handleProcessFinished(int exitCode, QProcess::ExitStatus status);
    void handleProcessOutput(bool errorChannel);
    void startApt(const QString &password);
    void startFlatpak();
    void startFlatpakUserInstall();
    void startFlatpakUserUpdate();
    void startFlatpakUserUninstall();
    void startFlatpakSudo(const QString &password);
    void startNpm(bool uninstall);
    void startScript(bool uninstall);
    void installAppImage();
    void uninstallAppImage();
    void installWebApp();
    void uninstallWebApp();
    void createDesktopEntry(const QString &targetDir, const QString &appName);
    void finalizeSuccess();
    void finalizeUninstall();
    void fail(const QString &message);
    void requestAuth(const QString &message);
    void nextQueuedTask();
    void setBusy(bool busy);
    void setPhase(const QString &phase);
    void setStatus(const QString &status);
    void setProgress(double progress);
    void setAppState(const QString &state, double progress, const QString &status);
    void appendLog(const QString &message);
    bool sudoAvailable() const;
    QString outputTail() const;

    Catalog *m_catalog = nullptr;
    QNetworkAccessManager m_network;
    QNetworkReply *m_reply = nullptr;
    QFile *m_downloadFile = nullptr;
    QString m_downloadPath;
    NetworkKind m_networkKind = NoNetwork;

    QProcess m_process;
    ProcessKind m_processKind = NoProcess;
    QString m_processOutput;
    QString m_processError;
    QString m_pendingPassword;

    Task m_task;
    bool m_busy = false;
    bool m_waitingForAuth = false;
    bool m_batch = false;
    QQueue<QString> m_queue;
    QString m_phase;
    QString m_status;
    double m_progress = 0.0;
};
