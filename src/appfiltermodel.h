#pragma once

#include <QSortFilterProxyModel>

#include "appmodel.h"

class AppFilterModel : public QSortFilterProxyModel {
    Q_OBJECT
    Q_PROPERTY(QAbstractItemModel *sourceModel READ sourceModel WRITE setSourceModel NOTIFY sourceModelChanged)
    Q_PROPERTY(QString category READ category WRITE setCategory NOTIFY categoryChanged)
    Q_PROPERTY(QString mode READ mode WRITE setMode NOTIFY modeChanged)
    Q_PROPERTY(QString query READ query WRITE setQuery NOTIFY queryChanged)
    Q_PROPERTY(QString sortMode READ sortMode WRITE setSortMode NOTIFY sortModeChanged)
    Q_PROPERTY(int count READ count NOTIFY countChanged)

public:
    explicit AppFilterModel(QObject *parent = nullptr);

    QAbstractItemModel *sourceModel() const { return QSortFilterProxyModel::sourceModel(); }
    void setSourceModel(QAbstractItemModel *model);

    QString category() const { return m_category; }
    void setCategory(const QString &category);

    QString mode() const { return m_mode; }
    void setMode(const QString &mode);

    QString query() const { return m_query; }
    void setQuery(const QString &query);

    QString sortMode() const { return m_sort; }
    void setSortMode(const QString &sortMode);

    int count() const { return rowCount(); }

signals:
    void sourceModelChanged();
    void categoryChanged();
    void modeChanged();
    void queryChanged();
    void sortModeChanged();
    void countChanged();

protected:
    bool filterAcceptsRow(int sourceRow, const QModelIndex &sourceParent) const override;
    bool lessThan(const QModelIndex &left, const QModelIndex &right) const override;

private:
    void refreshFilter();
    AppListModel *appModel() const;

    QString m_category;
    QString m_mode;
    QString m_query;
    QString m_sort;
};
