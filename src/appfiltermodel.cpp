#include "appfiltermodel.h"

AppFilterModel::AppFilterModel(QObject *parent)
    : QSortFilterProxyModel(parent)
{
    setDynamicSortFilter(true);
    setFilterCaseSensitivity(Qt::CaseInsensitive);
    setSortCaseSensitivity(Qt::CaseInsensitive);

    connect(this, &QAbstractItemModel::rowsInserted, this, &AppFilterModel::countChanged);
    connect(this, &QAbstractItemModel::rowsRemoved, this, &AppFilterModel::countChanged);
    connect(this, &QAbstractItemModel::modelReset, this, &AppFilterModel::countChanged);
    connect(this, &QAbstractItemModel::layoutChanged, this, &AppFilterModel::countChanged);
}

void AppFilterModel::setSourceModel(QAbstractItemModel *model)
{
    if (sourceModel() == model)
        return;

    if (sourceModel())
        disconnect(sourceModel(), nullptr, this, nullptr);

    QSortFilterProxyModel::setSourceModel(model);

    if (model) {
        connect(model, &QAbstractItemModel::dataChanged, this,
                [this](const QModelIndex &, const QModelIndex &, const QList<int> &roles) {
            bool relevant = roles.isEmpty();
            if (!relevant) {
                const QList<int> filterRoles = {
                    AppListModel::CategoryRole,
                    AppListModel::InstalledRole,
                    AppListModel::UpdatableRole,
                    AppListModel::FeaturedRole,
                    AppListModel::NameRole,
                    AppListModel::ShortNameRole,
                    AppListModel::SubtitleRole,
                    AppListModel::DescriptionRole,
                    AppListModel::DeveloperRole,
                    AppListModel::PackageRole,
                    AppListModel::FlatpakIdRole
                };
                for (int role : roles) {
                    if (filterRoles.contains(role)) {
                        relevant = true;
                        break;
                    }
                }
            }
            if (!relevant)
                return;
            invalidateFilter();
            emit countChanged();
        });
        connect(model, &QAbstractItemModel::modelReset, this, [this]() {
            invalidateFilter();
            emit countChanged();
        });
    }

    emit sourceModelChanged();
    refreshFilter();
}

void AppFilterModel::setCategory(const QString &category)
{
    if (m_category == category)
        return;
    m_category = category;
    emit categoryChanged();
    refreshFilter();
}

void AppFilterModel::setMode(const QString &mode)
{
    if (m_mode == mode)
        return;
    m_mode = mode;
    emit modeChanged();
    refreshFilter();
}

void AppFilterModel::setQuery(const QString &query)
{
    const QString trimmed = query.trimmed();
    if (m_query == trimmed)
        return;
    m_query = trimmed;
    emit queryChanged();
    refreshFilter();
}

void AppFilterModel::setSortMode(const QString &sortMode)
{
    if (m_sort == sortMode)
        return;
    m_sort = sortMode;
    emit sortModeChanged();
    refreshFilter();
}

void AppFilterModel::refreshFilter()
{
    invalidateFilter();

    if (m_sort.isEmpty() || m_sort == QStringLiteral("default")) {
        QSortFilterProxyModel::sort(-1);
    } else {
        QSortFilterProxyModel::sort(0, Qt::AscendingOrder);
    }

    emit countChanged();
}

AppListModel *AppFilterModel::appModel() const
{
    return qobject_cast<AppListModel *>(sourceModel());
}

bool AppFilterModel::filterAcceptsRow(int sourceRow, const QModelIndex &sourceParent) const
{
    QAbstractItemModel *model = sourceModel();
    if (!model)
        return false;

    const QModelIndex index = model->index(sourceRow, 0, sourceParent);
    if (!index.isValid())
        return false;

    const QString category = index.data(AppListModel::CategoryRole).toString();
    const bool installed = index.data(AppListModel::InstalledRole).toBool();
    const bool updatable = index.data(AppListModel::UpdatableRole).toBool();
    const bool featured = index.data(AppListModel::FeaturedRole).toBool();

    if (m_mode == QStringLiteral("featured") && !featured)
        return false;
    if (m_mode == QStringLiteral("installed") && !installed)
        return false;
    if (m_mode == QStringLiteral("updates") && !(installed && updatable))
        return false;

    if (!m_category.isEmpty() && category != m_category)
        return false;

    if (m_mode == QStringLiteral("search") && m_query.isEmpty())
        return false;

    if (!m_query.isEmpty()) {
        const QString haystack = QStringList{
            index.data(AppListModel::NameRole).toString(),
            index.data(AppListModel::ShortNameRole).toString(),
            index.data(AppListModel::SubtitleRole).toString(),
            index.data(AppListModel::DescriptionRole).toString(),
            index.data(AppListModel::DeveloperRole).toString(),
            index.data(AppListModel::CategoryNameRole).toString(),
            index.data(AppListModel::PackageRole).toString(),
            index.data(AppListModel::FlatpakIdRole).toString(),
        }.join(QLatin1Char(' '));

        if (!haystack.contains(m_query, Qt::CaseInsensitive))
            return false;
    }

    return true;
}

bool AppFilterModel::lessThan(const QModelIndex &left, const QModelIndex &right) const
{
    if (m_sort == QStringLiteral("popularity")) {
        const int leftValue = left.data(AppListModel::PopularityRole).toInt();
        const int rightValue = right.data(AppListModel::PopularityRole).toInt();
        if (leftValue != rightValue)
            return leftValue > rightValue;
        return QString::localeAwareCompare(left.data(AppListModel::NameRole).toString(),
                                           right.data(AppListModel::NameRole).toString()) < 0;
    }

    if (m_sort == QStringLiteral("rating")) {
        const double leftValue = left.data(AppListModel::RatingRole).toDouble();
        const double rightValue = right.data(AppListModel::RatingRole).toDouble();
        if (!qFuzzyCompare(leftValue, rightValue))
            return leftValue > rightValue;
        return QString::localeAwareCompare(left.data(AppListModel::NameRole).toString(),
                                           right.data(AppListModel::NameRole).toString()) < 0;
    }

    if (m_sort == QStringLiteral("name")) {
        return QString::localeAwareCompare(left.data(AppListModel::NameRole).toString(),
                                           right.data(AppListModel::NameRole).toString()) < 0;
    }

    return left.row() < right.row();
}
