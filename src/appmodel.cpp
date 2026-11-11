#include "appmodel.h"

#include <QFile>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonParseError>
#include <QDebug>

namespace {
QString stringValue(const QJsonObject &object, const QString &key, const QString &fallback = QString())
{
    const QJsonValue value = object.value(key);
    return value.isString() ? value.toString() : fallback;
}

bool boolValue(const QJsonObject &object, const QString &key, bool fallback = false)
{
    const QJsonValue value = object.value(key);
    return value.isBool() ? value.toBool() : fallback;
}

double doubleValue(const QJsonObject &object, const QString &key, double fallback = 0.0)
{
    const QJsonValue value = object.value(key);
    return value.isDouble() ? value.toDouble() : fallback;
}

int intValue(const QJsonObject &object, const QString &key, int fallback = 0)
{
    const QJsonValue value = object.value(key);
    return value.isDouble() ? value.toInt() : fallback;
}
}

AppListModel::AppListModel(QObject *parent)
    : QAbstractListModel(parent)
{
}

int AppListModel::rowCount(const QModelIndex &parent) const
{
    return parent.isValid() ? 0 : m_apps.size();
}

QVariant AppListModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() < 0 || index.row() >= m_apps.size())
        return {};

    const AppEntry &app = m_apps.at(index.row());

    switch (role) {
    case Qt::DisplayRole:
    case NameRole:
        return app.name;
    case IdRole:
        return app.id;
    case ShortNameRole:
        return app.shortName.isEmpty() ? app.name : app.shortName;
    case SubtitleRole:
        return app.subtitle;
    case DescriptionRole:
        return app.description;
    case LongDescriptionRole:
        return app.longDescription;
    case CategoryRole:
        return app.category;
    case CategoryNameRole:
        return app.categoryName;
    case IconRole:
        return app.icon;
    case IconBg1Role:
        return app.iconBg1;
    case IconBg2Role:
        return app.iconBg2;
    case IconFullRole:
        return app.iconFull;
    case VersionRole:
        return app.version;
    case SizeRole:
        return app.size;
    case SourceRole:
        return app.source;
    case HomepageRole:
        return app.homepage;
    case MethodRole:
        return app.method;
    case PackageRole:
        return app.package;
    case GithubRepoRole:
        return app.githubRepo;
    case AssetHintRole:
        return app.assetHint;
    case DirectUrlRole:
        return app.directUrl;
    case FileNameRole:
        return app.fileName;
    case FlatpakIdRole:
        return app.flatpakId;
    case LaunchRole:
        return app.launch;
    case DesktopIdRole:
        return app.desktopId;
    case TerminalRole:
        return app.terminal;
    case RatingRole:
        return app.rating;
    case PopularityRole:
        return app.popularity;
    case FeaturedRole:
        return app.featured;
    case HeroTitleRole:
        return app.heroTitle;
    case HeroSubtitleRole:
        return app.heroSubtitle;
    case HeroTagRole:
        return app.heroTag;
    case HeroColor1Role:
        return app.heroColor1;
    case HeroColor2Role:
        return app.heroColor2;
    case DeveloperRole:
        return app.developer;
    case CompatibilityRole:
        return app.compatibility;
    case ArchitectureRole:
        return app.architecture;
    case WhatsNewRole:
        return app.whatsNew;
    case InstalledRole:
        return app.installed;
    case InstalledVersionRole:
        return app.installedVersion;
    case LatestVersionRole:
        return app.latestVersion;
    case UpdatableRole:
        return app.updatable;
    case InstallScopeRole:
        return app.installScope;
    case StateRole:
        return app.state;
    case ProgressRole:
        return app.progress;
    case StatusRole:
        return app.status;
    default:
        return {};
    }
}

QHash<int, QByteArray> AppListModel::roleNames() const
{
    return {
        {IdRole, "appId"},
        {NameRole, "name"},
        {ShortNameRole, "shortName"},
        {SubtitleRole, "subtitle"},
        {DescriptionRole, "description"},
        {LongDescriptionRole, "longDescription"},
        {CategoryRole, "category"},
        {CategoryNameRole, "categoryName"},
        {IconRole, "icon"},
        {IconBg1Role, "iconBg1"},
        {IconBg2Role, "iconBg2"},
        {IconFullRole, "iconFull"},
        {VersionRole, "version"},
        {SizeRole, "size"},
        {SourceRole, "source"},
        {HomepageRole, "homepage"},
        {MethodRole, "method"},
        {PackageRole, "packageName"},
        {GithubRepoRole, "githubRepo"},
        {AssetHintRole, "assetHint"},
        {DirectUrlRole, "directUrl"},
        {FileNameRole, "fileName"},
        {FlatpakIdRole, "flatpakId"},
        {LaunchRole, "launch"},
        {DesktopIdRole, "desktopId"},
        {TerminalRole, "terminal"},
        {RatingRole, "rating"},
        {PopularityRole, "popularity"},
        {FeaturedRole, "featured"},
        {HeroTitleRole, "heroTitle"},
        {HeroSubtitleRole, "heroSubtitle"},
        {HeroTagRole, "heroTag"},
        {HeroColor1Role, "heroColor1"},
        {HeroColor2Role, "heroColor2"},
        {DeveloperRole, "developer"},
        {CompatibilityRole, "compatibility"},
        {ArchitectureRole, "architecture"},
        {WhatsNewRole, "whatsNew"},
        {InstalledRole, "installed"},
        {InstalledVersionRole, "installedVersion"},
        {LatestVersionRole, "latestVersion"},
        {UpdatableRole, "updatable"},
        {InstallScopeRole, "installScope"},
        {StateRole, "state"},
        {ProgressRole, "progress"},
        {StatusRole, "status"},
    };
}

void AppListModel::load(const QString &path)
{
    QFile file(path);
    if (!file.open(QIODevice::ReadOnly)) {
        qWarning() << "App Store: cannot open catalog" << path << file.errorString();
        return;
    }

    QJsonParseError parseError;
    const QJsonDocument document = QJsonDocument::fromJson(file.readAll(), &parseError);
    if (parseError.error != QJsonParseError::NoError || !document.isObject()) {
        qWarning() << "App Store: invalid catalog" << parseError.errorString();
        return;
    }

    beginResetModel();
    m_apps.clear();
    m_index.clear();
    m_categories.clear();
    m_categoryById.clear();

    const QJsonArray categories = document.object().value(QStringLiteral("categories")).toArray();
    QHash<QString, QString> categoryNames;
    for (const QJsonValue &value : categories) {
        if (!value.isObject())
            continue;
        const QJsonObject object = value.toObject();
        QVariantMap category = object.toVariantMap();
        const QString id = stringValue(object, QStringLiteral("id"));
        if (id.isEmpty())
            continue;
        categoryNames.insert(id, stringValue(object, QStringLiteral("name"), id));
        m_categories.append(category);
        m_categoryById.insert(id, category);
    }

    const QJsonArray apps = document.object().value(QStringLiteral("apps")).toArray();
    m_apps.reserve(apps.size());
    for (const QJsonValue &value : apps) {
        if (!value.isObject())
            continue;
        const QJsonObject object = value.toObject();

        AppEntry app;
        app.id = stringValue(object, QStringLiteral("id"));
        if (app.id.isEmpty())
            continue;
        app.name = stringValue(object, QStringLiteral("name"));
        app.shortName = stringValue(object, QStringLiteral("shortName"));
        app.subtitle = stringValue(object, QStringLiteral("subtitle"));
        app.description = stringValue(object, QStringLiteral("description"));
        app.longDescription = stringValue(object, QStringLiteral("longDescription"), app.description);
        app.category = stringValue(object, QStringLiteral("category"));
        app.categoryName = categoryNames.value(app.category, app.category);
        app.icon = stringValue(object, QStringLiteral("icon"));
        app.iconBg1 = stringValue(object, QStringLiteral("iconBg1"), QStringLiteral("#0a84ff"));
        app.iconBg2 = stringValue(object, QStringLiteral("iconBg2"), QStringLiteral("#0057d9"));
        app.iconFull = boolValue(object, QStringLiteral("iconFull"));
        app.version = stringValue(object, QStringLiteral("version"));
        app.size = stringValue(object, QStringLiteral("size"));
        app.source = stringValue(object, QStringLiteral("source"));
        app.homepage = stringValue(object, QStringLiteral("homepage"));
        app.method = stringValue(object, QStringLiteral("method"), QStringLiteral("apt"));
        app.package = stringValue(object, QStringLiteral("package"));
        app.githubRepo = stringValue(object, QStringLiteral("githubRepo"));
        app.assetHint = stringValue(object, QStringLiteral("assetHint"));
        app.directUrl = stringValue(object, QStringLiteral("directUrl"));
        app.fileName = stringValue(object, QStringLiteral("fileName"));
        app.flatpakId = stringValue(object, QStringLiteral("flatpakId"));
        app.launch = stringValue(object, QStringLiteral("launch"));
        app.desktopId = stringValue(object, QStringLiteral("desktop"));
        app.terminal = boolValue(object, QStringLiteral("terminal"));
        app.rating = doubleValue(object, QStringLiteral("rating"));
        app.popularity = intValue(object, QStringLiteral("popularity"));
        app.featured = boolValue(object, QStringLiteral("featured"));
        app.heroTitle = stringValue(object, QStringLiteral("heroTitle"), app.name);
        app.heroSubtitle = stringValue(object, QStringLiteral("heroSubtitle"), app.subtitle);
        app.heroTag = stringValue(object, QStringLiteral("heroTag"));
        app.heroColor1 = stringValue(object, QStringLiteral("heroColor1"), app.iconBg1);
        app.heroColor2 = stringValue(object, QStringLiteral("heroColor2"), app.iconBg2);
        app.developer = stringValue(object, QStringLiteral("developer"));
        app.compatibility = stringValue(object, QStringLiteral("compatibility"),
                                        QStringLiteral("Ubuntu 24.04 或更高版本 · arm64"));
        app.architecture = stringValue(object, QStringLiteral("arch"),
                                       stringValue(object, QStringLiteral("architecture"),
                                                   QStringLiteral("arm64")));
        app.whatsNew = stringValue(object, QStringLiteral("whatsNew"));
        app.uninstallCommand = stringValue(object, QStringLiteral("uninstallCommand"));

        m_index.insert(app.id, m_apps.size());
        m_apps.append(app);
    }

    endResetModel();
    emit countsChanged();
    qInfo() << "App Store: loaded" << m_apps.size() << "apps in" << m_categories.size() << "categories";
}

int AppListModel::rowForId(const QString &id) const
{
    return m_index.value(id, -1);
}

const AppEntry *AppListModel::entry(const QString &id) const
{
    const int row = rowForId(id);
    return row >= 0 ? &m_apps.at(row) : nullptr;
}

AppEntry *AppListModel::entry(const QString &id)
{
    const int row = rowForId(id);
    return row >= 0 ? &m_apps[row] : nullptr;
}

QString AppListModel::categoryName(const QString &id) const
{
    return m_categoryById.value(id).value(QStringLiteral("name"), id).toString();
}

QString AppListModel::categorySubtitle(const QString &id) const
{
    return m_categoryById.value(id).value(QStringLiteral("subtitle")).toString();
}

int AppListModel::categoryCount(const QString &id) const
{
    int count = 0;
    for (const AppEntry &app : m_apps) {
        if (app.category == id)
            ++count;
    }
    return count;
}

QVariantMap AppListModel::toMap(const AppEntry &app) const
{
    QVariantMap map;
    map.insert(QStringLiteral("appId"), app.id);
    map.insert(QStringLiteral("name"), app.name);
    map.insert(QStringLiteral("shortName"), app.shortName.isEmpty() ? app.name : app.shortName);
    map.insert(QStringLiteral("subtitle"), app.subtitle);
    map.insert(QStringLiteral("description"), app.description);
    map.insert(QStringLiteral("longDescription"), app.longDescription);
    map.insert(QStringLiteral("category"), app.category);
    map.insert(QStringLiteral("categoryName"), app.categoryName);
    map.insert(QStringLiteral("icon"), app.icon);
    map.insert(QStringLiteral("iconBg1"), app.iconBg1);
    map.insert(QStringLiteral("iconBg2"), app.iconBg2);
    map.insert(QStringLiteral("iconFull"), app.iconFull);
    map.insert(QStringLiteral("version"), app.version);
    map.insert(QStringLiteral("size"), app.size);
    map.insert(QStringLiteral("source"), app.source);
    map.insert(QStringLiteral("homepage"), app.homepage);
    map.insert(QStringLiteral("method"), app.method);
    map.insert(QStringLiteral("packageName"), app.package);
    map.insert(QStringLiteral("githubRepo"), app.githubRepo);
    map.insert(QStringLiteral("assetHint"), app.assetHint);
    map.insert(QStringLiteral("directUrl"), app.directUrl);
    map.insert(QStringLiteral("fileName"), app.fileName);
    map.insert(QStringLiteral("flatpakId"), app.flatpakId);
    map.insert(QStringLiteral("launch"), app.launch);
    map.insert(QStringLiteral("desktopId"), app.desktopId);
    map.insert(QStringLiteral("terminal"), app.terminal);
    map.insert(QStringLiteral("rating"), app.rating);
    map.insert(QStringLiteral("popularity"), app.popularity);
    map.insert(QStringLiteral("featured"), app.featured);
    map.insert(QStringLiteral("heroTitle"), app.heroTitle);
    map.insert(QStringLiteral("heroSubtitle"), app.heroSubtitle);
    map.insert(QStringLiteral("heroTag"), app.heroTag);
    map.insert(QStringLiteral("heroColor1"), app.heroColor1);
    map.insert(QStringLiteral("heroColor2"), app.heroColor2);
    map.insert(QStringLiteral("developer"), app.developer);
    map.insert(QStringLiteral("compatibility"), app.compatibility);
    map.insert(QStringLiteral("architecture"), app.architecture);
    map.insert(QStringLiteral("whatsNew"), app.whatsNew);
    map.insert(QStringLiteral("uninstallCommand"), app.uninstallCommand);
    map.insert(QStringLiteral("installed"), app.installed);
    map.insert(QStringLiteral("installedVersion"), app.installedVersion);
    map.insert(QStringLiteral("latestVersion"), app.latestVersion);
    map.insert(QStringLiteral("updatable"), app.updatable);
    map.insert(QStringLiteral("installScope"), app.installScope);
    map.insert(QStringLiteral("state"), app.state);
    map.insert(QStringLiteral("progress"), app.progress);
    map.insert(QStringLiteral("status"), app.status);
    return map;
}

void AppListModel::setInstalled(const QString &id, bool installed, const QString &version,
                                const QString &scope)
{
    AppEntry *app = entry(id);
    if (!app)
        return;
    if (app->installed == installed && app->installedVersion == version && app->installScope == scope)
        return;

    app->installed = installed;
    app->installedVersion = version;
    app->installScope = scope;
    if (!installed) {
        app->updatable = false;
        app->latestVersion.clear();
    }

    const int row = rowForId(id);
    const QModelIndex modelIndex = index(row, 0);
    emit dataChanged(modelIndex, modelIndex,
                     {InstalledRole, InstalledVersionRole, InstallScopeRole,
                      UpdatableRole, LatestVersionRole});
    emit entryChanged(id);
    emit countsChanged();
}

void AppListModel::setUpdate(const QString &id, bool updatable, const QString &latest)
{
    AppEntry *app = entry(id);
    if (!app)
        return;
    if (app->updatable == updatable && app->latestVersion == latest)
        return;

    app->updatable = updatable;
    app->latestVersion = latest;

    const int row = rowForId(id);
    const QModelIndex modelIndex = index(row, 0);
    emit dataChanged(modelIndex, modelIndex, {UpdatableRole, LatestVersionRole});
    emit entryChanged(id);
    emit countsChanged();
}

void AppListModel::setState(const QString &id, const QString &state, double progress,
                            const QString &status)
{
    AppEntry *app = entry(id);
    if (!app)
        return;
    if (app->state == state && qFuzzyCompare(app->progress, progress) && app->status == status)
        return;

    app->state = state;
    app->progress = progress;
    app->status = status;

    const int row = rowForId(id);
    const QModelIndex modelIndex = index(row, 0);
    emit dataChanged(modelIndex, modelIndex, {StateRole, ProgressRole, StatusRole});
    emit entryChanged(id);
}

void AppListModel::markInstalledAfterInstall(const QString &id, const QString &version)
{
    AppEntry *app = entry(id);
    if (!app)
        return;

    app->installed = true;
    app->installedVersion = version.isEmpty() ? app->version : version;
    app->latestVersion = app->installedVersion;
    app->updatable = false;
    app->state = QStringLiteral("idle");
    app->progress = 1.0;
    app->status.clear();

    const int row = rowForId(id);
    const QModelIndex modelIndex = index(row, 0);
    emit dataChanged(modelIndex, modelIndex,
                     {InstalledRole, InstalledVersionRole, LatestVersionRole,
                      UpdatableRole, StateRole, ProgressRole, StatusRole});
    emit entryChanged(id);
    emit countsChanged();
}

void AppListModel::markUninstalledAfterUninstall(const QString &id)
{
    AppEntry *app = entry(id);
    if (!app)
        return;

    app->installed = false;
    app->installedVersion.clear();
    app->latestVersion.clear();
    app->updatable = false;
    app->installScope.clear();
    app->state = QStringLiteral("idle");
    app->progress = 0.0;
    app->status.clear();

    const int row = rowForId(id);
    const QModelIndex modelIndex = index(row, 0);
    emit dataChanged(modelIndex, modelIndex,
                     {InstalledRole, InstalledVersionRole, LatestVersionRole,
                      UpdatableRole, InstallScopeRole, StateRole, ProgressRole, StatusRole});
    emit entryChanged(id);
    emit countsChanged();
}

void AppListModel::clearInstalled()
{
    bool changed = false;
    for (int row = 0; row < m_apps.size(); ++row) {
        AppEntry &app = m_apps[row];
        if (!app.installed && app.installedVersion.isEmpty() && app.installScope.isEmpty()
            && !app.updatable && app.latestVersion.isEmpty())
            continue;
        app.installed = false;
        app.installedVersion.clear();
        app.updatable = false;
        app.latestVersion.clear();
        app.installScope.clear();
        changed = true;
        const QModelIndex modelIndex = index(row, 0);
        emit dataChanged(modelIndex, modelIndex,
                         {InstalledRole, InstalledVersionRole, LatestVersionRole,
                          UpdatableRole, InstallScopeRole});
    }
    if (changed)
        emit countsChanged();
}

int AppListModel::installedCount() const
{
    int count = 0;
    for (const AppEntry &app : m_apps) {
        if (app.installed)
            ++count;
    }
    return count;
}

int AppListModel::updateCount() const
{
    int count = 0;
    for (const AppEntry &app : m_apps) {
        if (app.installed && app.updatable)
            ++count;
    }
    return count;
}
