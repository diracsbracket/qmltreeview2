#ifndef TREEMODELADAPTOR_H
#define TREEMODELADAPTOR_H
//
//  W A R N I N G
//  -------------
//
// This file is not part of the Qt API.  It exists purely as an
// implementation detail.  This header file may change from version to
// version without notice, or even be removed.
//
// We mean it.
//
#include <QSet>
#include <QPointer>
#include <QAbstractItemModel>
#include <QItemSelectionModel>

QT_BEGIN_NAMESPACE
class QAbstractItemModel;
class TreeModelAdaptor : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(QAbstractItemModel *model READ model WRITE setModel NOTIFY modelChanged)
    Q_PROPERTY(QModelIndex rootIndex READ rootIndex WRITE setRootIndex RESET resetRootIndex NOTIFY rootIndexChanged)
    struct TreeItem;

public:
    explicit TreeModelAdaptor(QObject *parent = 0);
    QAbstractItemModel *model() const;
    const QModelIndex &rootIndex() const;
    void setRootIndex(const QModelIndex &idx);
    void resetRootIndex();
    enum {
        DepthRole = Qt::UserRole - 5,
        ExpandedRole,
        HasChildrenRole,
        HasSiblingRole,
        ModelIndexRole
    };
    QHash<int, QByteArray> roleNames() const;
    int rowCount(const QModelIndex &parent = QModelIndex()) const;
    QVariant data(const QModelIndex &, int role) const;
    bool setData(const QModelIndex &index, const QVariant &value, int role);
    void clearModelData();
    bool isVisible(const QModelIndex &index);
    bool childrenVisible(const QModelIndex &index);
    const QModelIndex &mapToModel(const QModelIndex &index) const;
    Q_INVOKABLE QModelIndex mapRowToModelIndex(int row) const;
    Q_INVOKABLE QItemSelection selectionForRowRange(const QModelIndex &fromIndex, const QModelIndex &toIndex) const;
    void showModelTopLevelItems(bool doInsertRows = true);
    void showModelChildItems(const TreeItem &parent, int start, int end, bool doInsertRows = true, bool doExpandPendingRows = true);
    int itemIndex(const QModelIndex &index) const;
    void expandPendingRows(bool doInsertRows = true);
    int lastChildIndex(const QModelIndex &index);
    void removeVisibleRows(int startIndex, int endIndex, bool doRemoveRows = true);
    void expandRow(int n);
    void collapseRow(int n);
    bool isExpanded(int row) const;
    Q_INVOKABLE bool isExpanded(const QModelIndex &) const;
    void dump() const;
    bool testConsistency(bool dumpOnFail = false) const;

signals:
    void modelChanged(QAbstractItemModel *model);
    void rootIndexChanged();
    void expanded(const QModelIndex &index);
    void collapsed(const QModelIndex &index);

public slots:
    void expand(const QModelIndex &);
    void collapse(const QModelIndex &);
    void setModel(QAbstractItemModel *model);

private slots:
    void modelHasBeenDestroyed();
    void modelHasBeenReset();
    void modelDataChanged(const QModelIndex &topLeft, const QModelIndex &bottomRigth, const QVector<int> &roles);
    void modelLayoutAboutToBeChanged(const QList<QPersistentModelIndex> &parents, QAbstractItemModel::LayoutChangeHint hint);
    void modelLayoutChanged(const QList<QPersistentModelIndex> &parents, QAbstractItemModel::LayoutChangeHint hint);
    void modelRowsAboutToBeInserted(const QModelIndex & parent, int start, int end);
    void modelRowsAboutToBeMoved(const QModelIndex & sourceParent, int sourceStart, int sourceEnd, const QModelIndex & destinationParent, int destinationRow);
    void modelRowsAboutToBeRemoved(const QModelIndex & parent, int start, int end);
    void modelRowsInserted(const QModelIndex & parent, int start, int end);
    void modelRowsMoved(const QModelIndex & sourceParent, int sourceStart, int sourceEnd, const QModelIndex & destinationParent, int destinationRow);
    void modelRowsRemoved(const QModelIndex & parent, int start, int end);

private:
    struct TreeItem {
        QPersistentModelIndex index;
        int depth;
        bool expanded;
        explicit TreeItem(const QModelIndex &idx = QModelIndex(), int d = 0, int e = false)
            : index(idx), depth(d), expanded(e)
        { }
        inline bool operator== (const TreeItem &other) const
        {
            return this->index == other.index;
        }
    };

    QPointer<QAbstractItemModel> m_model;
    QPersistentModelIndex m_rootIndex;
    QList<TreeItem> m_items;
    QSet<QPersistentModelIndex> m_expandedItems;
    QList<TreeItem *> m_itemsToExpand;
    mutable int m_lastItemIndex;
};

QT_END_NAMESPACE
#endif // TREEMODELADAPTOR_H

