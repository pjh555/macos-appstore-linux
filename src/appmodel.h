#pragma once

#include <QAbstractListModel>
#include <QHash>
#include <QList>
#include <QStringList>
#include <QVariantList>
#include <QVariantMap>

struct AppEntry {
    QString id;
    QString name;
    QString shortName;
    QString subtitle;
    QString description;
    QString longDescription;
    QString category;
    QString categoryName;
    QString icon;
    QString iconBg1;
    QString iconBg2;
    bool iconFull = false;
    QString version;
    QString size;
    QString source;
    QString homepage;
    QString method;
    QString package;
    QString githubRepo;
    QString assetHint;
    QString directUrl;
    QString fileName;
    QString flatpakId;
    QString launch;
    QString desktopId;
    bool terminal = false;
    double rating = 0.0;
    int popularity = 0;
    bool featured = false;
    QString heroTitle;
    QString heroSubtitle;
    QString heroTag;
    QString heroColor1;
    QString heroColor2;
    QString developer;
    QString compatibility;
    QString architecture;
    QString whatsNew;
    QString uninstallCommand;

    bool installed = false;
    QString installedVersion;
    QString latestVersion;
    bool updatable = false;
    QString installScope;
    QString state = QStringLiteral("idle");
    double progress = 0.0;
    QString status;
};

class AppListModel : public QAbstractListModel {
    Q_OBJECT

public:
    enum Roles {
        IdRole = Qt::UserRole + 1,
        NameRole,
        ShortNameRole,
        SubtitleRole,
        DescriptionRole,
        LongDescriptionRole,
        CategoryRole,
        CategoryNameRole,
        IconRole,
        IconBg1Role,
        IconBg2Role,
        IconFullRole,
        VersionRole,
        SizeRole,
        SourceRole,
        HomepageRole,
        MethodRole,
        PackageRole,
        GithubRepoRole,
        AssetHintRole,
        DirectUrlRole,
        FileNameRole,
        FlatpakIdRole,
        LaunchRole,
        DesktopIdRole,
        TerminalRole,
        RatingRole,
        PopularityRole,
        FeaturedRole,
        HeroTitleRole,
        HeroSubtitleRole,
        HeroTagRole,
        HeroColor1Role,
        HeroColor2Role,
        DeveloperRole,
        CompatibilityRole,
        ArchitectureRole,
        WhatsNewRole,
        InstalledRole,
        InstalledVersionRole,
        LatestVersionRole,
        UpdatableRole,
        InstallScopeRole,
        StateRole,
        ProgressRole,
        StatusRole
    };
    Q_ENUM(Roles)

    explicit AppListModel(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    void load(const QString &path);
    int rowForId(const QString &id) const;
    const AppEntry *entry(const QString &id) const;
    AppEntry *entry(const QString &id);
    const QList<AppEntry> &entries() const { return m_apps; }
    QVariantList categories() const { return m_categories; }
    QString categoryName(const QString &id) const;
    QString categorySubtitle(const QString &id) const;
    int categoryCount(const QString &id) const;

    QVariantMap toMap(const AppEntry &app) const;

    void setInstalled(const QString &id, bool installed, const QString &version,
                      const QString &scope = QString());
    void setUpdate(const QString &id, bool updatable, const QString &latest);
    void setState(const QString &id, const QString &state, double progress,
                  const QString &status);
    void markInstalledAfterInstall(const QString &id, const QString &version);
    void markUninstalledAfterUninstall(const QString &id);
    void clearInstalled();

    int installedCount() const;
    int updateCount() const;

signals:
    void entryChanged(const QString &id);
    void countsChanged();

private:
    QVariantMap categoryMap(const QString &id) const;

    QList<AppEntry> m_apps;
    QHash<QString, int> m_index;
    QVariantList m_categories;
    QHash<QString, QVariantMap> m_categoryById;
};
