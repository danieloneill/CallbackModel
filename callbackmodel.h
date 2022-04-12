#ifndef CALLBACKMODEL_H
#define CALLBACKMODEL_H

#include <QAbstractListModel>
#include <QHash>
#include <QList>
#include <QMutex>
#include <QQuickItem>
#include <QTimer>
#include <QVariant>
#include <QJSValue>

class CallbackModel : public QAbstractListModel
{
    Q_OBJECT
    Q_DISABLE_COPY(CallbackModel)

    // Properties:
    int         m_rowCount;
    bool        m_cache;
    int         m_cacheSize;
    int         m_requestDelay;
    QMutex      m_mutex;

    QHash< int, QVariant > m_records;
    QList< int > m_recordsNeeded;

    QTimer      m_requestTimer;

public:
    CallbackModel(QObject *parent = 0);
    ~CallbackModel();

    Q_PROPERTY( int requestDelay MEMBER m_requestDelay NOTIFY requestDelayChanged )
    Q_PROPERTY( int rows READ rows WRITE setRows NOTIFY rowCountChanged )
    Q_PROPERTY( bool cache MEMBER m_cache NOTIFY cacheChanged )
    Q_PROPERTY( bool cacheSize MEMBER m_cacheSize NOTIFY cacheSizeChanged )

    Q_INVOKABLE static CallbackModel *create() { return new CallbackModel(); }

    Q_INVOKABLE int rows() { return m_rowCount; }
    Q_INVOKABLE void setRows(int count);

    Q_INVOKABLE void setRecord( int index, QVariant record ); // 'record' should be convertable to QVariantList
    Q_INVOKABLE void setRecords( int first, QVariant records ); // 'records' should be convertable to QArray< QVariantList >

    Q_INVOKABLE QVariant get(int row) const;
    Q_INVOKABLE QJSValueList loadedIndexes() const;

    int rowCount(const QModelIndex & parent = QModelIndex()) const;
    QVariant data(const QModelIndex & index, int role = Qt::DisplayRole) const;
    bool hasIndex(int row, int column, const QModelIndex & parent = QModelIndex()) const;
    QHash<int, QByteArray> roleNames() const;
/*
    bool canFetchMore(const QModelIndex & parent) const;
    void fetchMore(const QModelIndex & parent);
*/
protected:
    void requestData( int row );

protected slots:
    void slotRequestData();

signals:
    void requestDelayChanged();
    void rowCountChanged();
    void cacheChanged();
    void cacheSizeChanged();

    void recordsRequested( int first, int last );
};

#endif // CALLBACKMODEL_H

