#pragma once

#include <QObject>
#include <QProcess>
#include <QSet>
#include <QStringList>
#include <QVariantList>
#include <QVariantMap>

#include "appmodel.h"

class Catalog : public QObject {
    Q_OBJECT
    Q_PROPERTY(QAbstractItemModel *apps READ apps CONSTANT)
    Q_PROPERTY(QVariantList categories READ categories CONSTANT)
    Q_PROPERTY(int updateCount READ updateCount NOTIFY countsChanged)
    Q_PROPERTY(int installedCount READ installedCount NOTIFY countsChanged)
    Q_PROPERTY(bool scanning READ scanning NOTIFY scanningChanged)
    Q_PROPERTY(QString statusText READ statusText NOTIFY statusTextChanged)
    Q_PROPERTY(QString arch READ arch CONSTANT)
    Q_PROPERTY(QString downloadDir READ downloadDir CONSTANT)
    Q_PROPERTY(QString applicationsDir READ applicationsDir CONSTANT)
    Q_PROPERTY(bool darkTheme READ darkTheme CONSTANT)
    Q_PROPERTY(QString initialPage READ initialPage CONSTANT)
    Q_PROPERTY(QString initialCategory READ initialCategory CONSTANT)
    Q_PROPERTY(QString initialApp READ initialApp CONSTANT)

public:
    explicit Catalog(QObject *parent = nullptr);

    QAbstractItemModel *apps() { return &m_model; }
    QVariantList categories() const { return m_model.categories(); }
    int updateCount() const { return m_model.updateCount(); }
    int installedCount() const { return m_model.installedCount(); }
    bool scanning() const { return m_scanning; }
    QString statusText() const { return m_statusText; }
    QString arch() const;
    QString downloadDir() const;
    QString applicationsDir() const;
    bool darkTheme() const { return m_darkTheme; }
    QString initialPage() const { return m_initialPage; }
    QString initialCategory() const { return m_initialCategory; }
    QString initialApp() const { return m_initialApp; }

    AppListModel *model() { return &m_model; }
    const AppListModel *model() const { return &m_model; }

    Q_INVOKABLE QVariantMap appData(const QString &id) const;
    Q_INVOKABLE QString categoryName(const QString &id) const;
    Q_INVOKABLE QString categorySubtitle(const QString &id) const;
    Q_INVOKABLE int categoryCount(const QString &id) const;
    Q_INVOKABLE void refresh();
    Q_INVOKABLE void openUrl(const QString &url);
    Q_INVOKABLE void launchApp(const QString &id);

signals:
    void countsChanged();
    void scanningChanged();
    void statusTextChanged();
    void appChanged(const QString &id);
    void scanFinished();
    void toast(const QString &message, bool error);

private:
    enum ScanStage {
        NoStage,
        DpkgStage,
        FlatpakStage,
        AppImageStage,
        AptUpdatesStage,
        FlatpakUpdatesStage
    };

    void startScan();
    void startScanCommand(const QString &program, const QStringList &arguments, ScanStage stage);
    void handleScanFinished(int exitCode, QProcess::ExitStatus status);
    void handleScanError(QProcess::ProcessError error);
    void continueScan(ScanStage finishedStage, const QString &output);
    void finishScan();
    void setStatusText(const QString &text);

    AppListModel m_model;
    QProcess m_scanProcess;
    ScanStage m_scanStage = NoStage;
    QString m_scanOutput;
    QString m_scanError;
    bool m_scanning = false;
    bool m_refreshQueued = false;
    QString m_statusText;
    QStringList m_scanPackages;
    bool m_darkTheme = true;
    QString m_initialPage;
    QString m_initialCategory;
    QString m_initialApp;
};
